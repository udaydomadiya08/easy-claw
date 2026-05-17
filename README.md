# 🦞 Easy Claw

**The Ultimate Free Agentic System — OpenCode as the bridge, everything as the backend.**

Easy Claw is a unified, free, open-source agentic system that integrates the best features from **OpenClaw**, **Hermes Agent**, **Claude Code**, and **Claude Desktop** — powered by OpenCode models as the core reasoning engine.

```bash
git clone https://github.com/udaydomadiya08/easy-claw.git
cd easy-claw
./easy-claw.sh task "what time is it"
```

## Quick Start

### Prerequisites

- **OpenCode** — `npm install -g opencode@latest`
- **Ollama** (optional) — for 100% local privacy

### Install

```bash
git clone https://github.com/udaydomadiya08/easy-claw.git
cd easy-claw
./easy-claw.sh task "what time is it"
```

> No `chmod +x`, no `ln -s`, no `setup` needed. First run asks you to pick a model (OpenCode cloud or your local Ollama models), saves it, and runs your task. Every subsequent task continues the same session — context preserved, output clean.

To use `easy-claw` from anywhere:

```bash
ln -s "$PWD/easy-claw.sh" ~/.opencode/bin/easy-claw
```

### First Run Demo

```
$ ./easy-claw.sh task "what time is it"
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

**Auto-interactive:** If the model needs more info, it automatically asks and waits:

```
$ ./easy-claw.sh task "send a message to uday"
Which channel should I use? (whatsapp/telegram)
> whatsapp
WhatsApp not configured. Run: openclaw channels login --channel whatsapp
> exit          ← type exit/quit/bye/stop/q to force exit
```

> Empty input (just pressing enter) keeps waiting. The session exits automatically once the task is done (model gives a final answer without asking more).

### Commands

```bash
# Models
./easy-claw.sh models                         # List all models (OpenCode + Ollama)
./easy-claw.sh model set 3                    # Select by index
./easy-claw.sh model set ollama/qwen2.5:7b    # Or by full name

# Tasks
./easy-claw.sh task "check disk space"        # NL → command execution
./easy-claw.sh task "what is my username"
./easy-claw.sh task "what was my first question"  # Context preserved

# If the model needs more info (asks a question), it auto-prompts:
# Type your response. Empty input = hold. exit/quit/bye/stop/q = force exit.
./easy-claw.sh task "send a message to uday"
# → "Which channel should I use?"
# > whatsapp
# → "WhatsApp not configured. Run: openclaw channels login --channel whatsapp"

# Privacy
./easy-claw.sh privacy                        # Show where data goes
./easy-claw.sh privacy local                  # Switch to local Ollama

# OpenClaw (messaging, cron, plugins)
easy-claw channel login
easy-claw agent "send a reminder on telegram"
easy-claw cron add --name "daily-scan" --cron "0 9 * * *" \
  --message "run system health check"

# Skills & Memory
easy-claw skill list
easy-claw skill create deploy "Deploy to production"
easy-claw memory add "user prefers zsh over bash"

# Hooks & MCP
easy-claw hook create notify-me
easy-claw mcp add github "npx -y @modelcontextprotocol/server-github"

# Status
easy-claw status
```

## Why Easy Claw?

Every agentic system today is siloed. OpenClaw has messaging. Hermes has self-improvement. Claude Code has skills and hooks. Claude Desktop has MCP.

**Easy Claw combines ALL of them** into one unified framework:

| Feature | Origin | Implementation |
|---|---|---|
| Bridge Engine | OpenCode | Core reasoning & execution via OpenCode models |
| Gateway Daemon | OpenClaw | Background LaunchAgent/systemd service |
| Multi-Channel | OpenClaw | WhatsApp, Telegram, Discord, Slack, Signal, iMessage, +15 |
| Learning Loop | Hermes Agent | Post-task auto-creates skills, updates memory |
| 3-Layer Memory | Hermes Agent | MEMORY.md, USER.md, SQLite |
| Skills System | Claude Code | /command SKILL.md files, auto-discovered |
| Lifecycle Hooks | Claude Code | Pre/post-task automation |
| MCP Connectors | Claude Desktop | Filesystem, DB, API, browser |
| Cron Scheduler | OpenClaw | Background tasks with channel delivery |
| Plugin System | OpenClaw | 50+ bundled plugins (GitHub, 1Password, etc.) |
| Free & Private | OpenCode/Ollama | Cloud models (free) or local (private) |

## Architecture

```
                    ┌──────────────────────┐
                    │    Easy Claw CLI     │
                    │ task/cron/skill/...  │
                    └──────────┬───────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                 ▼
       ┌──────────┐     ┌──────────┐     ┌──────────────┐
       │ OpenCode │     │ OpenClaw │     │   Ollama     │
       │ (Bridge) │     │(Backend) │     │ (Local LLM)  │
       └──────────┘     └──────────┘     └──────────────┘
           │                 │
           ▼                 ▼
    ┌──────────┐     ┌──────────────────────────┐
    │ Execute  │     │ Telegram, Discord,       │
    │ Tasks    │     │ WhatsApp, Signal,        │
    │ Hooks    │     │ iMessage, Email, SMS...  │
    │ Skills   │     │ Cron, Plugins, Memory    │
    │ Subagents│     │ MCP, Webhooks            │
    └──────────┘     └──────────────────────────┘
```

## Features

### 🧠 Self-Improving Learning Loop

After every successful task, Easy Claw evaluates the result, auto-creates a skill file for reuse, and updates MEMORY.md with lessons learned. Gets smarter over time — no fine-tuning.

### 💬 Multi-Channel Messaging

Connect 20+ messaging platforms via OpenClaw gateway:

Telegram · Discord · Slack · WhatsApp · Signal · iMessage · SMS · Email · Matrix · Mattermost · DingTalk · Feishu · WeChat · IRC · Google Chat · + more

```bash
openclaw channels login --channel telegram
./easy-claw.sh task "send a reminder on telegram"
```

### 📋 Skills System

Skills are markdown files in `skills/`. Created manually or auto-generated by the learning loop. Follow the AgentSkills standard.

### 🔌 MCP Support

Plug into any MCP server:

```bash
./easy-claw.sh mcp add filesystem "npx -y @modelcontextprotocol/server-filesystem /path"
./easy-claw.sh mcp add github "npx -y @modelcontextprotocol/server-github"
```

### ⏰ Cron Scheduler

Schedule tasks with delivery to any channel:

```bash
./easy-claw.sh cron add --name "morning-briefing" --cron "0 8 * * *" \
  --message "give me a morning briefing" --channel telegram
```

### 🪝 Lifecycle Hooks

Scripts that fire on pre-task, post-task, on-error events:

```bash
./easy-claw.sh hook create my-hook
# Edit hooks/my-hook.sh
```

## Privacy & Data Handling

| Model Type | Data Leaves Your Machine? | API Key Needed? |
|---|---|---|
| `opencode/*` (cloud) | Yes — sent to OpenCode servers | No |
| `ollama/*` (local) | No — 100% local | No |

```bash
# Check current model privacy
./easy-claw.sh privacy

# Switch to local
./easy-claw.sh privacy local
```

> For sensitive data, use `ollama/*` models. For zero-setup convenience, use `opencode/*`.

## File Structure

```
easy-claw/
├── easy-claw.sh           # CLI entry point
├── config.sh              # Configuration
├── EASYCLAW.md            # System identity
├── MEMORY.md              # Memory store
├── USER.md                # User preferences
├── hooks/                 # Lifecycle hooks
│   ├── pre-task.sh
│   └── post-task.sh
├── skills/                # Skill documents
├── modules/
│   └── hermes-loop.sh     # Learning loop
├── mcp/
│   └── servers.json       # MCP configs
└── state/                 # Runtime state
```

## Requirements

- macOS, Linux, or Windows (WSL2)
- Node.js 22+
- OpenCode — `npm install -g opencode@latest`
- Ollama (optional) — for local-only privacy

## The Vision

AI agents should be free, local, and unified. Not a dozen tools with different configs, different memory, different skills — but **one system that does everything**.

OpenCode models are the bridge. OpenClaw is the backbone. Hermes-style learning makes it smarter. Claude Code-style skills make it extensible. And it all runs on your machine, for free, with your data staying yours.

## License

MIT — do whatever you want. Go build.

## Acknowledgments

- [OpenCode](https://opencode.ai) — Bridge engine
- [OpenClaw](https://openclaw.ai) — Gateway, channels, cron, plugins
- [Hermes Agent](https://hermes-agent.ai) — Memory, learning loop
- [Claude Code](https://code.claude.com) — Skills, hooks, subagents
- [Anthropic](https://anthropic.com) — Claude Desktop inspiration
- [Nous Research](https://nousresearch.com) — Hermes Agent
