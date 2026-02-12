# openclaw-skill-boneyard

An [OpenClaw](https://clawd.bot) agent skill: Post character death announcements to the boneyard Discord channel with themed embeds.

## Installation

Copy the skill to the OpenClaw skills directory:

```bash
# Shared (all agents)
scp -r boneyard your-vps:~/.openclaw/skills/boneyard

# Per-agent
scp -r boneyard your-vps:~/.openclaw/workspaces/<agent>/skills/boneyard
```

Restart the gateway after installing:

```bash
openclaw gateway restart
```

## Skill contents

```
boneyard/
├── SKILL.md           # Skill definition and agent instructions
├── README.md          # This file
└── tools/             # Implementation scripts
    └── post.sh        # Post character death embed to Discord
```

## License

MIT
