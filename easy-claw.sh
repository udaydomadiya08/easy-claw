#!/bin/bash
# Easy Claw — Ultimate Free Agentic System
# OpenCode bridge + OpenClaw backend + Hermes learning loop + Claude Code skills

set -e

EASYCLAW_DIR="$(python3 -c "import os,sys; print(os.path.dirname(os.path.realpath(sys.argv[1])))" "$0")"
OPENCLAW="${OPENCLAW_BIN:-openclaw}"
OPENCODE="${OPENCODE_BIN:-opencode}"

# ─── Configuration ───────────────────────────────────────────
export EASYCLAW_DIR

load_config() {
  if [ -f "$EASYCLAW_DIR/config.sh" ]; then
    source "$EASYCLAW_DIR/config.sh"
  fi
}

# Source modules
for module in "$EASYCLAW_DIR/modules/"*.sh; do
  [ -f "$module" ] && source "$module"
done

# ─── Commands ────────────────────────────────────────────────

cmd_help() {
  cat <<'EOF'
Easy Claw v1.0 — Ultimate Free Agentic System
https://github.com/udaydomadiya08/easy-claw

Usage: easy-claw <command> [options]

Commands:
  help           Show this help
  task <msg>     Execute a task via OpenCode
  agent <msg>    Send message to OpenClaw agent
  cron           Manage scheduled tasks
  skill          Manage skills (list, create, edit)
  memory         Manage memory store
  channel        Manage messaging channels
  hook           Manage lifecycle hooks
  status         Show system status
  learn          Run self-improvement learning loop
  mcp            Manage MCP connectors
  setup          Run initial setup wizard

Configuration:
  EASYCLAW_DIR   Easy Claw installation directory
  OPENCLAW_BIN   OpenClaw binary path
  OPENCODE_BIN   OpenCode binary path
EOF
}

# ─── Execute task via OpenCode bridge ────────────────────────
cmd_task() {
  local message="$*"
  if [ -z "$message" ]; then
    echo "Usage: easy-claw task <message>"
    exit 1
  fi

  # Pre-task hooks
  run_hooks "pre-task" "$message"

  echo "🦞 Easy Claw executing: $message"
  echo "───────────────────────────────────────────────"

  # Route through OpenClaw local agent (uses whatever model is configured)
  # The agent handles NL: "check the time" → runs date and returns result
  $OPENCLAW agent --agent main --local --message "$message" --thinking low 2>&1

  local exit_code=$?

  # Post-task hooks
  run_hooks "post-task" "$message" "$exit_code"

  # Self-improvement loop (learn from task)
  cmd_learn "$message"

  return $exit_code
}

# ─── Send message to OpenClaw agent ──────────────────────────
cmd_agent() {
  local message="$*"
  if [ -z "$message" ]; then
    echo "Usage: easy-claw agent <message>"
    exit 1
  fi
  $OPENCLAW agent --message "$message" --expect-final
}

# ─── Cron management via OpenClaw ────────────────────────────
cmd_cron() {
  $OPENCLAW cron "$@"
}

# ─── Skill management ────────────────────────────────────────
cmd_skill() {
  local action="$1"
  shift 2>/dev/null || true

  case "$action" in
    list|ls)
      echo "=== Easy Claw Skills ==="
      for skill in "$EASYCLAW_DIR"/skills/*.md; do
        if [ -f "$skill" ]; then
          name=$(basename "$skill" .md)
          desc=$(head -5 "$skill" | grep "^#" | head -1 | sed 's/^#* *//')
          echo "  /$name  — $desc"
        fi
      done
      echo ""
      echo "=== OpenClaw Bundled Skills ==="
      $OPENCLAW skills list
      ;;
    create)
      local name="$1"
      shift
      local desc="$*"
      if [ -z "$name" ]; then
        echo "Usage: easy-claw skill create <name> [description]"
        exit 1
      fi
      cat > "$EASYCLAW_DIR/skills/$name.md" <<SKILLEOF
# $name
${desc:-"A skill for Easy Claw."}

## Usage
Invocable via \`/$name\`

## Instructions
(Add instructions here)
SKILLEOF
      echo "Created skill: /$name"
      ;;
    info)
      local name="$1"
      if [ -z "$name" ]; then
        echo "Usage: easy-claw skill info <name>"
        exit 1
      fi
      if [ -f "$EASYCLAW_DIR/skills/$name.md" ]; then
        cat "$EASYCLAW_DIR/skills/$name.md"
      else
        $OPENCLAW skills info "$name"
      fi
      ;;
    *)
      cmd_help
      ;;
  esac
}

# ─── Memory management ───────────────────────────────────────
cmd_memory() {
  local action="$1"
  shift 2>/dev/null || true

  case "$action" in
    list|ls)
      echo "=== MEMORY.md ==="
      cat "$EASYCLAW_DIR/MEMORY.md"
      echo ""
      echo "=== USER.md ==="
      cat "$EASYCLAW_DIR/USER.md"
      echo ""
      echo "=== OpenClaw Memory ==="
      $OPENCLAW memory status
      ;;
    add)
      local msg="$*"
      if [ -n "$msg" ]; then
        echo "- $(date +%Y-%m-%d): $msg" >> "$EASYCLAW_DIR/MEMORY.md"
        echo "Added to MEMORY.md"
      fi
      ;;
    search)
      $OPENCLAW memory search "$@"
      ;;
    index)
      $OPENCLAW memory index --force
      ;;
    *)
      echo "Usage: easy-claw memory <list|add|search|index> [args]"
      ;;
  esac
}

# ─── Channel management via OpenClaw ─────────────────────────
cmd_channel() {
  $OPENCLAW channels "$@"
}

# ─── Hook management ─────────────────────────────────────────
cmd_hook() {
  local action="$1"
  shift 2>/dev/null || true

  case "$action" in
    list|ls)
      echo "=== Easy Claw Hooks ==="
      for hook in "$EASYCLAW_DIR"/hooks/*.sh; do
        if [ -f "$hook" ]; then
          echo "  $(basename "$hook" .sh)"
        fi
      done
      ;;
    create)
      local name="$1"
      if [ -z "$name" ]; then
        echo "Usage: easy-claw hook create <name>"
        exit 1
      fi
      cat > "$EASYCLAW_DIR/hooks/$name.sh" <<'HOOKEOF'
#!/bin/bash
# Easy Claw Hook
echo "[hook] $EASYCLAW_HOOK_PHASE: $EASYCLAW_HOOK_MESSAGE"
HOOKEOF
      chmod +x "$EASYCLAW_DIR/hooks/$name.sh"
      echo "Created hook: $name"
      ;;
    *)
      echo "Usage: easy-claw hook <list|create>"
      ;;
  esac
}

# ─── Status ──────────────────────────────────────────────────
cmd_status() {
  echo "=== Easy Claw Status ==="
  echo ""
  echo "--- OpenClaw ---"
  $OPENCLAW gateway health 2>&1 || echo "Gateway not running"
  echo ""
  echo "--- Skills ---"
  cmd_skill list
  echo ""
  echo "--- Cron ---"
  $OPENCLAW cron list 2>&1 || echo "No cron jobs"
  echo ""
  echo "--- Memory ---"
  $OPENCLAW memory status 2>&1 | head -5
  echo ""
  echo "--- Hooks ---"
  cmd_hook list
}

# ─── Self-improvement learning loop (Hermes-style) ──────────
cmd_learn() {
  local task_message="$*"
  local exit_code="${EASYCLAW_HOOK_EXIT_CODE:-0}"

  # Only learn from successful tasks
  [ "$exit_code" != "0" ] && return 0

  echo "🔄 Learning from task..."

  # Check if a skill should be created from this task
  local skill_name=$(echo "$task_message" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | head -c 40)

  # Add to memory
  echo "- $(date +%Y-%m-%d): Completed task: $task_message" >> "$EASYCLAW_DIR/MEMORY.md"

  # If task matches known patterns, auto-create skill
  if echo "$task_message" | grep -qiE "(deploy|build|setup|install|configure|migrate|backup|monitor|check|audit|scan|test)"; then
    if [ ! -f "$EASYCLAW_DIR/skills/$skill_name.md" ]; then
      cat > "$EASYCLAW_DIR/skills/$skill_name.md" <<SKILLEOF
# $skill_name
Auto-created from task: $task_message

## Trigger
When user asks to: $task_message

## Instructions
1. Understand the context
2. Execute step by step
3. Verify the result
4. Report completion

## Created
$(date +%Y-%m-%d)
SKILLEOF
      echo "  ✓ Created skill: /$skill_name"
    fi
  fi
}

# ─── Run hooks ──────────────────────────────────────────────
run_hooks() {
  local phase="$1"
  local message="$2"
  local exit_code="${3:-0}"

  export EASYCLAW_HOOK_PHASE="$phase"
  export EASYCLAW_HOOK_MESSAGE="$message"
  export EASYCLAW_HOOK_EXIT_CODE="$exit_code"

  for hook in "$EASYCLAW_DIR/hooks/"*.sh; do
    if [ -f "$hook" ] && [ -x "$hook" ]; then
      bash "$hook"
    fi
  done
}

# ─── MCP management ─────────────────────────────────────────
cmd_mcp() {
  local action="$1"
  shift 2>/dev/null || true

  case "$action" in
    list|ls)
      if [ -f "$EASYCLAW_DIR/mcp/servers.json" ]; then
        cat "$EASYCLAW_DIR/mcp/servers.json"
      else
        echo "No MCP servers configured."
      fi
      ;;
    add)
      local name="$1"
      local command="$2"
      if [ -z "$name" ] || [ -z "$command" ]; then
        echo "Usage: easy-claw mcp add <name> <command>"
        exit 1
      fi
      local servers_file="$EASYCLAW_DIR/mcp/servers.json"
      if [ ! -f "$servers_file" ]; then
        echo '{"mcpServers":{}}' > "$servers_file"
      fi
      # Simple JSON append (requires jq ideally, fallback to basic)
      if command -v jq &>/dev/null; then
        jq --arg name "$name" --arg cmd "$command" \
          '.mcpServers[$name] = {"command": $cmd}' "$servers_file" > "${servers_file}.tmp" \
          && mv "${servers_file}.tmp" "$servers_file"
      else
        echo "jq not available. Add manually to $servers_file"
      fi
      echo "Added MCP server: $name"
      ;;
    *)
      echo "Usage: easy-claw mcp <list|add>"
      ;;
  esac
}

# ─── Setup wizard ────────────────────────────────────────────
cmd_setup() {
  echo "=== Easy Claw Setup Wizard ==="
  echo ""

  # Check OpenClaw
  if command -v "$OPENCLAW" &>/dev/null; then
    echo "✓ OpenClaw found: $OPENCLAW"
    $OPENCLAW gateway health &>/dev/null && echo "✓ Gateway running" || echo "⚠ Gateway not running (start with: openclaw gateway)"
  else
    echo "✗ OpenClaw not found. Install: npm install -g openclaw@latest"
  fi

  # Check OpenCode
  if command -v "$OPENCODE" &>/dev/null; then
    echo "✓ OpenCode found: $OPENCODE"
  else
    echo "✗ OpenCode not found."
  fi

  # Check Ollama
  if curl -s http://127.0.0.1:11434/api/tags &>/dev/null; then
    echo "✓ Ollama running"
  else
    echo "⚠ Ollama not detected. Start with: ollama serve"
  fi

  # Create default hooks
  for hook in pre-task post-task; do
    if [ ! -f "$EASYCLAW_DIR/hooks/$hook.sh" ]; then
      cat > "$EASYCLAW_DIR/hooks/$hook.sh" <<'HOOKEOF'
#!/bin/bash
echo "[easy-claw] $(date): $EASYCLAW_HOOK_PHASE — $EASYCLAW_HOOK_MESSAGE"
HOOKEOF
      chmod +x "$EASYCLAW_DIR/hooks/$hook.sh"
    fi
  done
  echo "✓ Default hooks created"

  # Create OpenClaw cron integration
  $OPENCLAW cron list &>/dev/null && echo "✓ Cron accessible" || echo "⚠ Cron not available"

  echo ""
  echo "Easy Claw setup complete!"
  echo "Try: easy-claw task 'check system health'"
}

# ─── Main dispatcher ─────────────────────────────────────────
main() {
  load_config
  local cmd="${1:-help}"
  shift 2>/dev/null || true

  case "$cmd" in
    help|--help|-h)
      cmd_help
      ;;
    version|--version|-v)
      echo "Easy Claw v1.0 — MIT License"
      echo "https://github.com/udaydomadiya08/easy-claw"
      ;;
    task)
      cmd_task "$@"
      ;;
    agent)
      cmd_agent "$@"
      ;;
    cron)
      cmd_cron "$@"
      ;;
    skill)
      cmd_skill "$@"
      ;;
    memory)
      cmd_memory "$@"
      ;;
    channel)
      cmd_channel "$@"
      ;;
    hook)
      cmd_hook "$@"
      ;;
    status)
      cmd_status
      ;;
    learn)
      cmd_learn "$@"
      ;;
    mcp)
      cmd_mcp "$@"
      ;;
    setup)
      cmd_setup
      ;;
    *)
      echo "Unknown command: $cmd"
      cmd_help
      exit 1
      ;;
  esac
}

main "$@"
