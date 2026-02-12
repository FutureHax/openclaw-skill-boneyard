#!/usr/bin/env bash
set -euo pipefail

# Boneyard — Post character death announcement to Discord
# Usage: post.sh <character_name> <level> [game_name]
#
# Posts a themed embed to the boneyard channel honoring a fallen character.
# If game_name is omitted, attempts to infer it from active Discord scheduled events.
#
# Returns JSON:
#   {"ok": true, "messageId": "...", "channelId": "..."}           — success
#   {"ok": false, "needsGame": true, "message": "..."}            — game inference failed
#   {"error": "..."}                                                — hard failure

CHARACTER_NAME="${1:?Usage: post.sh <character_name> <level> [game_name]}"
LEVEL="${2:?Usage: post.sh <character_name> <level> [game_name]}"
GAME_NAME="${3:-}"

BONEYARD_CHANNEL="1299781078931869716"
API="https://discord.com/api/v10"

# --- Environment checks ---

if [[ -z "${DISCORD_BOT_TOKEN:-}" ]]; then
  echo '{"error":"DISCORD_BOT_TOKEN is not set"}' >&2
  exit 1
fi

AUTH="Authorization: Bot ${DISCORD_BOT_TOKEN}"

# --- Infer game from active Discord scheduled events if not provided ---

if [[ -z "$GAME_NAME" ]]; then
  # Auto-detect guild ID from OpenClaw config
  DISCORD_GUILD_ID="${DISCORD_GUILD_ID:-}"
  if [[ -z "$DISCORD_GUILD_ID" ]]; then
    DISCORD_GUILD_ID=$(python3 -c "
import json, sys
try:
    with open('$HOME/.openclaw/openclaw.json') as f:
        c = json.load(f)
    guilds = c.get('channels',{}).get('discord',{}).get('guilds',{})
    print(list(guilds.keys())[0])
except:
    sys.exit(1)
" 2>/dev/null) || true
  fi

  if [[ -n "$DISCORD_GUILD_ID" ]]; then
    EVENTS=$(curl -sf --connect-timeout 5 --max-time 15 \
      -H "$AUTH" -H "Accept: application/json" \
      "${API}/guilds/${DISCORD_GUILD_ID}/scheduled-events" 2>/dev/null) || true

    if [[ -n "$EVENTS" ]]; then
      GAME_NAME=$(EVENTS_JSON="$EVENTS" python3 -c "
import json, os, sys

events = json.loads(os.environ['EVENTS_JSON'])

# Status 2 = ACTIVE (currently running)
active = [e for e in events if e.get('status') == 2]
if len(active) == 1:
    print(active[0].get('name', ''))
    sys.exit(0)

# If multiple active events, can't determine which one
if len(active) > 1:
    sys.exit(1)

# No active events — check SCHEDULED (status 1)
scheduled = [e for e in events if e.get('status') == 1]
if len(scheduled) == 1:
    print(scheduled[0].get('name', ''))
    sys.exit(0)

# Can't determine
sys.exit(1)
" 2>/dev/null) || true
    fi
  fi

  # If we still don't have a game name, signal back to the agent
  if [[ -z "$GAME_NAME" ]]; then
    echo '{"ok": false, "needsGame": true, "message": "Could not determine the game from Discord events. Please provide the game name."}'
    exit 0
  fi
fi

# --- Build embed ---

NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

EMBED=$(CHARACTER="$CHARACTER_NAME" LVL="$LEVEL" GAME="$GAME_NAME" TS="$NOW_ISO" python3 -c "
import json, os

char = os.environ['CHARACTER']
level = os.environ['LVL']
game = os.environ['GAME']
timestamp = os.environ['TS']

embed = {
    'title': f'\U0001f480 {char} Has Fallen',
    'description': f'**{char}** met their end in the realm of **{game}**.\n\nMay their memory echo through the ages.',
    'color': 9109504,
    'fields': [
        {'name': 'Character', 'value': char, 'inline': True},
        {'name': 'Level', 'value': str(level), 'inline': True},
        {'name': 'Game', 'value': game, 'inline': True},
    ],
    'footer': {'text': 'Zordon \u2022 The Boneyard'},
    'timestamp': timestamp,
}

print(json.dumps(embed))
")

# --- Send to boneyard channel (retry once on transient failure) ---

PAYLOAD=$(printf '{"embeds":[%s]}' "$EMBED")

RESPONSE=""
for _attempt in 1 2; do
  RESPONSE=$(curl -sf --connect-timeout 5 --max-time 15 \
    -X POST \
    -H "$AUTH" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "${API}/channels/${BONEYARD_CHANNEL}/messages" 2>&1) && break
  if [[ $_attempt -eq 1 ]]; then
    sleep 1
  else
    echo "{\"error\":\"Discord API request failed after 2 attempts\",\"details\":\"$RESPONSE\"}" >&2
    exit 1
  fi
done

# --- Return result ---

echo "$RESPONSE" | python3 -c "
import sys, json
try:
    msg = json.load(sys.stdin)
    if msg.get('id'):
        print(json.dumps({'ok': True, 'messageId': msg['id'], 'channelId': '${BONEYARD_CHANNEL}'}))
    else:
        print(json.dumps({'ok': False, 'error': msg.get('message', 'Unknown Discord error'), 'raw': msg}))
except Exception as e:
    print(json.dumps({'ok': True, 'raw': 'sent'}))
"
