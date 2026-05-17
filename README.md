# 🦞 Easy Claw

**The Ultimate Free Agentic System — OpenCode as the bridge, everything as the backend.**

Easy Claw is a unified, free, open-source agentic system that integrates the
best features from **OpenClaw**, **Hermes Agent**, **Claude Code**, and
**Claude Desktop** — powered by OpenCode models as the core reasoning engine,
running entirely on local models via Ollama with zero API costs.

```bash
# One-line install
git clone https://github.com/udaydomadiya08/easy-claw.git
cd easy-claw
chmod +x easy-claw.sh hooks/*.sh modules/*.sh
ln -s "$PWD/easy-claw.sh" "$(dirname "$(command -v opencode)")/easy-claw"
easy-claw setup
easy-claw task "what time is it"   # First task!
```

## Why Easy Claw?

Every agentic system today is siloed. OpenClaw has messaging. Hermes has
self-improvement. Claude Code has skills and hooks. Claude Desktop has MCP.

**Easy Claw combines ALL of them** into one unified framework:

| Feature | From | How Easy Claw Implements It |
|---|---|---|
| **Bridge Engine** | OpenCode | Core reasoning & execution via OpenCode models |
| **24/7 Gateway Daemon** | OpenClaw | Background LaunchAgent/systemd service |
| **Multi-Channel Messaging** | OpenClaw | WhatsApp, Telegram, Discord, Slack, Signal, iMessage, +15 more |
| **Self-Improving Loop** | Hermes Agent | Post-task evaluation auto-creates/updates skills |
| **3-Layer Memory** | Hermes Agent | MEMORY.md (curated), USER.md (preferences), SQLite (full history) |
| **Skills System** | Claude Code | `/command` invocable SKILL.md files, auto-discovered |
| **Lifecycle Hooks** | Claude Code | Pre/post-task hooks for automation |
| **MCP Connectors** | Claude Desktop | Filesystem, DB, API, browser — any MCP server |
| **Cron Scheduler** | OpenClaw | Scheduled background tasks with channel delivery |
| **Subagent Delegation** | Hermes/Claude | Isolated child agents for parallel work |
| **Plugin System** | OpenClaw | 50+ bundled plugins (GitHub, 1Password, Apple Notes, etc.) |
| **100% Free & Local** | Ollama | Runs on local models, zero API costs |

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        Easy Claw CLI                         │
│  easy-claw task/cron/skill/memory/hook/mcp/channel/agent    │
└──────────────────┬───────────────────────────────────────────┘
                   │
    ┌──────────────┼──────────────┐
    ▼              ▼              ▼
┌──────────┐ ┌──────────┐ ┌──────────────┐
│ OpenCode │ │ OpenClaw │ │  Ollama      │
│ (Bridge) │ │(Backend) │ │ (Local LLM)  │
└──────────┘ └──────────┘ └──────────────┘
    │              │
    ▼              ▼
┌──────────┐ ┌──────────────────────────────┐
│ Execute  │ │ Channels: Telegram, Discord, │
│ Tasks    │ │ WhatsApp, Signal, iMessage.. │
│ Hooks    │ │ Cron: Scheduled tasks        │
│ Skills   │ │ Memory: Persistent storage   │
│ Subagents│ │ Skills: 50+ bundled plugins  │
└──────────┘ └──────────────────────────────┘
```

## Quick Start

### Prerequisites

- **OpenCode** — `npm install -g opencode@latest`
- **OpenClaw** — `npm install -g openclaw@latest`
- **Ollama** — Download from [ollama.com](https://ollama.com) (for free local models)

### Install

```bash
git clone https://github.com/udaydomadiya08/easy-claw.git
cd easy-claw
chmod +x easy-claw.sh hooks/*.sh modules/*.sh
ln -s "$PWD/easy-claw.sh" ~/bin/easy-claw
easy-claw setup
```

### Usage

```bash
# Execute a task (uses OpenCode as bridge)
easy-claw task "check system health"
easy-claw task "backup my documents to ~/backups"
easy-claw task "summarize the project in this directory"

# Send message via any channel (requires OpenClaw channel setup)
easy-claw channel login
easy-claw agent "send a reminder to myself on telegram"

# Schedule recurring tasks
easy-claw cron add --name "daily-scan" --cron "0 9 * * *" \
  --message "run system health check and store results"

# Manage skills
easy-claw skill list
easy-claw skill create deploy "Deploy my project to production"
easy-claw skill info system-health

# Memory
easy-claw memory list
easy-claw memory add "user prefers zsh over bash"
easy-claw memory search "project config"

# Lifecycle hooks
easy-claw hook create notify-me

# MCP connectors
easy-claw mcp add github "npx -y @modelcontextprotocol/server-github"

# Full system status
easy-claw status
```

## Features in Detail

### 🧠 Self-Improving Learning Loop
Inspired by Hermes Agent. After every successful task, Easy Claw:
1. Evaluates if the task pattern is worth capturing
2. Auto-creates a skill file in `skills/` for future reuse
3. Updates MEMORY.md with lessons learned
4. Gets faster and smarter over time — no fine-tuning needed

### 💬 Multi-Channel Messaging
Powered by OpenClaw gateway. Connect 20+ messaging platforms:
- Telegram, Discord, Slack, WhatsApp, Signal
- iMessage (via BlueBubbles), SMS (via Twilio)
- Matrix, Mattermost, DingTalk, Feishu, WeChat
- Email, IRC, Google Chat, and more

```bash
openclaw channels login telegram  # Interactive QR code
easy-claw agent "list my tasks for today"
```

### 📋 Skills System
Skills are markdown files in `skills/` directory. They follow the
open AgentSkills standard and can be:
- Invoked manually: `easy-claw skill list`
- Auto-invoked by the learning loop
- Shared across the community

### 🔌 MCP Support
Connect any MCP server for extended capabilities:

```bash
easy-claw mcp add filesystem "npx -y @modelcontextprotocol/server-filesystem /path"
easy-claw mcp add github "npx -y @modelcontextprotocol/server-github"
```

### ⏰ Cron Scheduler
Schedule background tasks with delivery to any channel:

```bash
easy-claw cron add --name "morning-briefing" --cron "0 8 * * *" \
  --message "give me a morning briefing" --channel telegram
```

### 🪝 Lifecycle Hooks
Scripts that fire on events (pre-task, post-task, on-error).
Create your own:
```bash
easy-claw hook create my-hook
# Edit hooks/my-hook.sh
```

## File Structure

```
easy-claw/
├── easy-claw.sh           # Main CLI entry point
├── config.sh              # User configuration
├── EASYCLAW.md            # System identity prompt
├── MEMORY.md              # Dynamic memory store
├── USER.md                # User preferences
├── README.md              # This file
├── LICENSE                # MIT License
├── hooks/                 # Lifecycle hook scripts
│   ├── pre-task.sh
│   └── post-task.sh
├── skills/                # Skill documents
│   ├── system-health.skill.md
│   └── messaging.skill.md
├── modules/               # Integration modules
│   └── hermes-loop.sh     # Self-improving loop
├── mcp/                   # MCP server configs
│   └── servers.json
├── agents/                # Subagent configs
└── state/                 # Runtime state
```

## Requirements

- **macOS**, **Linux**, or **Windows (WSL2)**
- **Node.js** 22+ (for OpenCode and OpenClaw)
- **Ollama** (for free local models — or any OpenAI/Anthropic API key)

## The Vision

Easy Claw is built on one belief: **AI agents should be free, local, and
unified.** Not a dozen different tools with different configs, different
memory, different skills — but ONE system that does everything.

OpenCode models are the bridge. OpenClaw is the backbone. Hermes-style
learning makes it smarter over time. Claude Code-style skills make it
extensible. And it all runs on your machine, for free, with your data
staying yours.

## License

MIT — do whatever you want. Go build.

## Acknowledgments

- **[OpenCode](https://opencode.ai)** — The bridge engine
- **[OpenClaw](https://openclaw.ai)** — Gateway, channels, cron, plugins
- **[Hermes Agent](https://hermes-agent.ai)** — Memory architecture, learning loop
- **[Claude Code](https://code.claude.com)** — Skills, hooks, subagents system
- **[Anthropic](https://anthropic.com)** — Claude Desktop & Code inspiration
- **[Nous Research](https://nousresearch.com)** — Hermes Agent
- **ollama/OpenAI** — Local model serving
