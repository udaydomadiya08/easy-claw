# 🦞 Easy Claw

**The Ultimate Free Agentic System — OpenCode as the bridge, everything as the backend.**

Easy Claw is a unified, free, open-source agentic system that integrates the
best features from **OpenClaw**, **Hermes Agent**, **Claude Code**, and
**Claude Desktop** — powered by OpenCode models as the core reasoning engine,
running entirely on local models via Ollama with zero API costs.

🦞 Easy Claw — pick a model to get started

1) opencode/big-pickle
2) opencode/deepseek-v4-flash-free
3) opencode/minimax-m2.5-free
4) opencode/nemotron-3-super-free
5) opencode/qwen3.6-plus-free
6) ollama/qwen2.5:3b
7) ollama/qwen2.5:7b

Enter number (1-7): 2
✓ Model set to: opencode/deepseek-v4-flash-free

Sun May 17 18:26:46 IST

$ ./easy-claw.sh task "and what day is it"
Sunday

$ ./easy-claw.sh task "what was my first question"
Your first question was: "what time is it"
```

## Why Easy Claw?

Every agentic system today is siloed. OpenClaw has messaging. Hermes has
self-improvement. Claude Code has skills and hooks. Claude Desktop has MCP.

**Easy Claw combines ALL of them** into one unified framework:

| Feature | From | How Easy Claw Implements It |
|---|---|---|
| **Bridge Engine** | OpenCode | Core reasoning & execution via OpenCode models (free, no API key needed) |
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
| **100% Free & Model Choice** | OpenCode | Free built-in models, no API key or Ollama required |

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

- **OpenCode** — `npm install -g opencode@latest` (includes free models — no API key needed)

### Install

```bash
git clone https://github.com/udaydomadiya08/easy-claw.git
cd easy-claw
./easy-claw.sh task "what time is it"
# First run → picks model once, auto-starts server, runs task → clean answer
```

> **No `chmod +x`, no `ln -s`, no `easy-claw setup` needed.** First run asks you to pick a model (from OpenCode cloud or your local Ollama models), saves it, and runs your task. Every subsequent task continues the same session — context preserved, output clean, no noise.

To add to PATH for `easy-claw` from anywhere:
```bash
ln -s "$PWD/easy-claw.sh" ~/.opencode/bin/easy-claw
```

### Usage

```bash
# List available models (OpenCode cloud + your local Ollama models)
./easy-claw.sh models                         # Shows all with numbers
./easy-claw.sh model set 3                    # Select by index
./easy-claw.sh model set ollama/qwen2.5:7b    # Or by full name

# Execute tasks — clean output, just the answer
./easy-claw.sh task "what time is it"
./easy-claw.sh task "check disk space"

# Session continuation — context preserved across tasks
./easy-claw.sh task "what is my username"     # → uday
./easy-claw.sh task "what was my first question"  # → "what is my username"

# Privacy — see where your data goes, switch to local-only
./easy-claw.sh privacy                        # Show current model data handling
./easy-claw.sh privacy local                  # Switch to local Ollama model

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
- **Node.js** 22+ (for OpenCode)
- **OpenCode** — `npm install -g opencode@latest` (free cloud models built-in)
- **Ollama** (optional) — for 100% local privacy, no data leaves your machine

## Privacy & Data Handling

Easy Claw supports two types of models:

| Model Type | Data Leaves Your Machine? | API Key Needed? |
|---|---|---|
| `opencode/*` (cloud) | Yes — sent to OpenCode servers | No |
| `ollama/*` (local) | No — runs entirely local | No |

First run shows all available models from both sources. Pick whichever you prefer:

```bash
# See current model's privacy status
./easy-claw.sh privacy

# Switch to local-only (requires Ollama)
./easy-claw.sh privacy local
# Shows your installed Ollama models, prompts you to pick one
```

> **Tip:** For sensitive data, use `ollama/*` models. For convenience with zero setup, use `opencode/*` models.

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
