---
name: boneyard
description: Post character death announcements to the boneyard Discord channel. Honors fallen heroes with a themed embed card.
metadata: {"openclaw":{"requires":{"env":["DISCORD_BOT_TOKEN"]}}}
---

# The Boneyard

Post character death announcements to the boneyard memorial channel when a player's character falls during a game session.

## CRITICAL — Always use post.sh, always auto-post

**You MUST use `post.sh` to post boneyard entries.** Do NOT build the embed yourself. Do NOT use discord-embed directly. Do NOT ask which channel to post to. The tool handles everything — it builds the embed and posts it to the boneyard memorial channel automatically.

When the user says to post it, or confirms the details, **run the tool immediately**. No further questions.

## When to use

Use this skill when:
- A player reports that their character has died
- Someone asks to "add to the boneyard" or "record a death"
- A GM announces a character death or TPK (total party kill)
- Anyone mentions "boneyard" in the context of a fallen character

## Required information

You need **three pieces of information** before you can post. If the user didn't provide all of them, **ask for each missing piece** before calling the tool. Never call `post.sh` with incomplete data.

1. **Character Name** — the name of the fallen character
2. **Level** — the character's level at the time of death
3. **Game Name** — which game/campaign the character was in

### How to gather missing info

If the user says something like *"my character died"* without details, walk through the gaps:

- **Missing character name** → Ask: *"What was the character's name?"*
- **Missing level** → Ask: *"What level were they?"*
- **Missing game name** → Ask: *"Which game were they in? (If you're not sure, I can try to detect it from the active Discord event.)"*

You can ask for multiple missing fields in a single message — no need to ask one at a time.

### Game inference

If the user doesn't know or doesn't specify the game, you can omit the game argument when calling `post.sh`. The tool will:

1. Check for active Discord scheduled events in the server
2. If exactly one active event is found, use that event's title as the game name
3. If it can't determine the game (no events or multiple events), it returns `"needsGame": true`

If the tool returns `"needsGame": true`, **ask the user** which game it was — don't guess.

## How to post

Once you have the required info and the user confirms (or tells you to post), run the tool **immediately**:

```bash
bash /home/marvin/.openclaw/skills/boneyard/tools/post.sh "<character_name>" "<level>" "[game_name]"
```

**Arguments:**
- `character_name` (required) — Name of the fallen character
- `level` (required) — Character level at time of death
- `game_name` (optional) — Game/campaign name; auto-inferred from Discord events if omitted

The tool posts directly to the boneyard memorial channel. **Do NOT ask which channel.** The channel is hardcoded. Just run it.

## Examples

### User provides everything

> User: "Thorn Ironheart died in Where Evil Lives, he was level 7"

Confirm, then run immediately:

```bash
bash /home/marvin/.openclaw/skills/boneyard/tools/post.sh "Thorn Ironheart" "7" "Where Evil Lives"
```

### User says "post it"

When the user says "post it", "do it", "send it", or any confirmation — **run the tool right away**. Do not ask for a channel. Do not offer choices.

### User provides partial info

> User: "RIP my character"

Ask: *"Sorry for your loss! What was the character's name, what level were they, and which game were they in?"*

> User: "Kael, level 4"

Ask: *"Which game was Kael in? I can try to detect it from the current Discord event if you're not sure."*

> User: "just check the event"

Run without game arg (triggers auto-detection):

```bash
bash /home/marvin/.openclaw/skills/boneyard/tools/post.sh "Kael" "4"
```

### TPK (multiple deaths)

For a total party kill, post **one entry per character**. Gather info for each character and post them individually.

## Guidelines

- **Always confirm** details with the user before posting (character name spelling, level, game)
- Use the **character's name**, not the player's name
- For a TPK, post one entry per character — don't combine them into one embed
- **NEVER ask which channel** — the tool always posts to the boneyard memorial channel
- **NEVER build the embed yourself** — always use `post.sh`
- Keep your text response brief after posting; the embed speaks for itself
- If the tool returns an error, report it to the user and offer to retry
