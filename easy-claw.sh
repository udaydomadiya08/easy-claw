#!/bin/bash
# Easy Claw — Ultimate Free Agentic System
# OpenCode models as the NL bridge. First run auto-setups. Zero config.

# Self-ensure executable (first run fix)
[ -x "$0" ] || chmod +x "$0" 2>/dev/null

EASYCLAW_DIR="$(python3 -c "import os,sys; print(os.path.dirname(os.path.realpath(sys.argv[1])))" "$0")"
OPENCLAW="${OPENCLAW_BIN:-openclaw}"
OPENCODE="${OPENCODE_BIN:-opencode}"
OPENCODE_PORT=15999
mkdir -p "$EASYCLAW_DIR/state"
OPENCODE_PIDFILE="$EASYCLAW_DIR/state/opencode.pid"

export EASYCLAW_DIR

load_config() {
  [ -f "$EASYCLAW_DIR/config.sh" ] && source "$EASYCLAW_DIR/config.sh"
}

for module in "$EASYCLAW_DIR/modules/"*.sh; do
  [ -f "$module" ] && source "$module"
done

# ─── OpenCode server management ────────────────────────────

cmd_start() {
  if [ -f "$OPENCODE_PIDFILE" ] && kill -0 "$(cat "$OPENCODE_PIDFILE")" 2>/dev/null; then
    echo "OpenCode server already running (PID $(cat "$OPENCODE_PIDFILE"))"
    return 0
  fi
  mkdir -p "$EASYCLAW_DIR/state"
  nohup "$OPENCODE" serve --port "$OPENCODE_PORT" --hostname 127.0.0.1 \
    > "$EASYCLAW_DIR/state/opencode.log" 2>&1 &
  echo $! > "$OPENCODE_PIDFILE"
  sleep 2
  echo "OpenCode server started (PID $(cat "$OPENCODE_PIDFILE")) on port $OPENCODE_PORT"
}

cmd_stop() {
  if [ -f "$OPENCODE_PIDFILE" ]; then
    kill "$(cat "$OPENCODE_PIDFILE")" 2>/dev/null && echo "Stopped" || echo "Not running"
    rm -f "$OPENCODE_PIDFILE"
  else
    echo "No server running"
  fi
}

cmd_restart() {
  cmd_stop
  sleep 1
  cmd_start
}

# ─── Execute task via OpenCode bridge (NL → command) ────────
EASYCLAW_SESSION_FILE="$EASYCLAW_DIR/state/.last_session"

cmd_task() {
  local message="$*"
  [ -z "$message" ] && { echo "Usage: easy-claw task <message>" >&2; exit 1; }

  run_hooks "pre-task" "$message" >/dev/null 2>&1

  # Ensure OpenCode server is running
  if [ ! -f "$OPENCODE_PIDFILE" ] || ! kill -0 "$(cat "$OPENCODE_PIDFILE")" 2>/dev/null; then
    cmd_start >/dev/null 2>&1
    sleep 1
    rm -f "$EASYCLAW_SESSION_FILE"
  fi

  # Check if we have a previous session to continue
  local continue_flag=""
  if [ -f "$EASYCLAW_SESSION_FILE" ]; then
    local sid
    sid=$(cat "$EASYCLAW_SESSION_FILE")
    if [ -n "$sid" ]; then
      continue_flag="--session $sid"
    fi
  fi

  # Build permissions flag
  local perm_flag=""
  [ "$EASYCLAW_SKIP_PERMISSIONS" = "true" ] && perm_flag="--dangerously-skip-permissions"

  # Send to OpenCode server (non-interactive, JSON output)
  local result
  result=$("$OPENCODE" run "$message" \
    --attach "http://127.0.0.1:$OPENCODE_PORT" \
    --model "$EASYCLAW_MODEL" \
    $continue_flag \
    --format json \
    $perm_flag 2>&1)

  local exit_code=$?

  # Save session ID from response for continuation
  echo "$result" | python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        e = json.loads(line)
        sid = e.get('sessionID', '')
        if sid:
            with open('$EASYCLAW_SESSION_FILE', 'w') as f:
                f.write(sid)
            break
    except:
        pass
" 2>/dev/null

  # Extract and display final text from JSON events
  echo "$result" | python3 -c "
import sys, json
last_text = ''
for line in sys.stdin:
  line = line.strip()
  if not line:
    continue
  try:
    event = json.loads(line)
    p = event.get('part', {})
    if p.get('type') == 'text':
      last_text = p.get('text', '')
  except json.JSONDecodeError:
    pass
if last_text:
  sys.stdout.write(last_text + '\n')
" 2>/dev/null

  # Show tool outputs (the actual command results)
  echo "$result" | python3 -c "
import sys, json
for line in sys.stdin:
  line = line.strip()
  if not line:
    continue
  try:
    event = json.loads(line)
    p = event.get('part', {})
    if p.get('type') == 'tool' and p.get('state', {}).get('status') == 'completed':
      out = p.get('state', {}).get('output', '')
      if out and out.strip():
        sys.stdout.write(out)
  except json.JSONDecodeError:
    pass
" 2>/dev/null

  run_hooks "post-task" "$message" "$exit_code" >/dev/null 2>&1
  cmd_learn "$message" >/dev/null 2>&1

  return $exit_code
}

# ─── Send message to OpenClaw agent ──────────────────────────
cmd_agent() {
  local message="$*"
  [ -z "$message" ] && { echo "Usage: easy-claw agent <message>"; exit 1; }
  $OPENCLAW agent --agent main --message "$message" 2>&1
}

# ─── Cron management via OpenClaw ────────────────────────────
cmd_cron() { $OPENCLAW cron "$@"; }

# ─── Skill management ────────────────────────────────────────
cmd_skill() {
  local action="$1"
  shift 2>/dev/null || true
  case "$action" in
    list|ls)
      echo "=== Easy Claw Skills ==="
      for skill in "$EASYCLAW_DIR"/skills/*.md; do
        [ -f "$skill" ] || continue
        name=$(basename "$skill" .md)
        desc=$(head -5 "$skill" | grep "^#" | head -1 | sed 's/^#* *//')
        echo "  /$name  — $desc"
      done
      echo ""
      echo "=== OpenClaw Bundled Skills ==="
      $OPENCLAW skills list
      ;;
    create)
      local name="$1"
      shift
      local desc="$*"
      [ -z "$name" ] && { echo "Usage: easy-claw skill create <name> [description]"; exit 1; }
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
      [ -z "$name" ] && { echo "Usage: easy-claw skill info <name>"; exit 1; }
      if [ -f "$EASYCLAW_DIR/skills/$name.md" ]; then
        cat "$EASYCLAW_DIR/skills/$name.md"
      else
        $OPENCLAW skills info "$name"
      fi
      ;;
    *) cmd_help ;;
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
      [ -n "$msg" ] && echo "- $(date +%Y-%m-%d): $msg" >> "$EASYCLAW_DIR/MEMORY.md" && echo "Added to MEMORY.md"
      ;;
    search)
      $OPENCLAW memory search "$@"
      ;;
    index)
      $OPENCLAW memory index --force
      ;;
    *) echo "Usage: easy-claw memory <list|add|search|index> [args]" ;;
  esac
}

# ─── Channel management via OpenClaw ─────────────────────────
cmd_channel() { $OPENCLAW channels "$@"; }

# ─── Hook management ─────────────────────────────────────────
cmd_hook() {
  local action="$1"
  shift 2>/dev/null || true
  case "$action" in
    list|ls)
      echo "=== Easy Claw Hooks ==="
      for hook in "$EASYCLAW_DIR"/hooks/*.sh; do
        [ -f "$hook" ] && echo "  $(basename "$hook" .sh)"
      done
      ;;
    create)
      local name="$1"
      [ -z "$name" ] && { echo "Usage: easy-claw hook create <name>"; exit 1; }
      cat > "$EASYCLAW_DIR/hooks/$name.sh" <<'HOOKEOF'
#!/bin/bash
echo "[hook] $EASYCLAW_HOOK_PHASE: $EASYCLAW_HOOK_MESSAGE"
HOOKEOF
      chmod +x "$EASYCLAW_DIR/hooks/$name.sh"
      echo "Created hook: $name"
      ;;
    *) echo "Usage: easy-claw hook <list|create>" ;;
  esac
}

# ─── Status ──────────────────────────────────────────────────
cmd_status() {
  echo "=== Easy Claw Status ==="
  echo ""
  echo "--- OpenCode Server ---"
  if [ -f "$OPENCODE_PIDFILE" ] && kill -0 "$(cat "$OPENCODE_PIDFILE")" 2>/dev/null; then
    echo "Running (PID $(cat "$OPENCODE_PIDFILE")) on port $OPENCODE_PORT"
  else
    echo "Not running"
  fi
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
  [ "$exit_code" != "0" ] && return 0

  echo "🔄 Learning from task..."
  local skill_name=$(echo "$task_message" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | head -c 40)

  echo "- $(date +%Y-%m-%d): Completed task: $task_message" >> "$EASYCLAW_DIR/MEMORY.md"

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
    [ -f "$hook" ] && [ -x "$hook" ] && bash "$hook"
  done
}

# ─── MCP management ─────────────────────────────────────────
cmd_mcp() {
  local action="$1"
  shift 2>/dev/null || true
  case "$action" in
    list|ls)
      [ -f "$EASYCLAW_DIR/mcp/servers.json" ] && cat "$EASYCLAW_DIR/mcp/servers.json" || echo "No MCP servers configured."
      ;;
    add)
      local name="$1"
      local command="$2"
      [ -z "$name" ] || [ -z "$command" ] && { echo "Usage: easy-claw mcp add <name> <command>"; exit 1; }
      local sf="$EASYCLAW_DIR/mcp/servers.json"
      [ ! -f "$sf" ] && echo '{"mcpServers":{}}' > "$sf"
      if command -v jq &>/dev/null; then
        jq --arg n "$name" --arg c "$command" '.mcpServers[$n] = {"command": $c}' "$sf" > "${sf}.tmp" && mv "${sf}.tmp" "$sf"
      fi
      echo "Added MCP server: $name"
      ;;
    *) echo "Usage: easy-claw mcp <list|add>" ;;
  esac
}

# ─── Setup wizard ────────────────────────────────────────────
cmd_setup() {
  echo "=== Easy Claw Setup Wizard ==="
  echo ""

  # Check OpenCode
  if command -v "$OPENCODE" &>/dev/null; then
    echo "✓ OpenCode found: $OPENCODE"
  else
    echo "✗ OpenCode not found. Install: npm install -g opencode@latest"
    exit 1
  fi

  # Check OpenClaw (optional)
  if command -v "$OPENCLAW" &>/dev/null; then
    echo "✓ OpenClaw found: $OPENCLAW"
    $OPENCLAW gateway health &>/dev/null && echo "✓ Gateway running" || echo "⚠ Gateway not running"
  else
    echo "○ OpenClaw not found (optional — for messaging/cron)"
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

  # Start OpenCode server
  echo ""
  echo "Starting OpenCode server..."
  cmd_start

  echo ""
  echo "✓ Easy Claw setup complete!"
  echo "Try: easy-claw task 'what is the current date and time'"
}

# ─── List available models with indices ─────────────────
MODEL_LIST_FILE="$EASYCLAW_DIR/state/.model_list"

cmd_models() {
  local filter="${1:-}"
  if [ -n "$filter" ]; then
    "$OPENCODE" models "$filter" 2>&1
    return
  fi

    "$OPENCODE" models > "$MODEL_LIST_FILE" 2>&1
  echo "Available OpenCode models ($(wc -l < "$MODEL_LIST_FILE" | tr -d ' ')):"
  awk '{print NR")", $0}' "$MODEL_LIST_FILE"
  echo ""
  echo "Current model: $EASYCLAW_MODEL"
  echo "Set with: easy-claw model set <number>"
}

# ─── Model management (set by index or name) ────────────
cmd_model() {
  local action="$1"
  shift 2>/dev/null || true

  # Rebuild model list if missing
  if [ ! -f "$MODEL_LIST_FILE" ]; then
    "$OPENCODE" models > "$MODEL_LIST_FILE" 2>&1
  fi

  case "$action" in
    set)
      local input="$1"
      [ -z "$input" ] && { echo "Usage: easy-claw model set <number|provider/model>"; echo "See: easy-claw models"; exit 1; }

      local model=""
      if [[ "$input" =~ ^[0-9]+$ ]]; then
        # Always pull fresh list so index always matches current OpenCode models
        "$OPENCODE" models > "$MODEL_LIST_FILE" 2>&1
        model=$(sed -n "${input}p" "$MODEL_LIST_FILE" 2>/dev/null)
        [ -z "$model" ] && { echo "Invalid index: $input"; exit 1; }
      else
        model="$input"
      fi

      if grep -q "^export EASYCLAW_MODEL=" "$EASYCLAW_DIR/config.sh" 2>/dev/null; then
        sed -i '' "s|^export EASYCLAW_MODEL=.*|export EASYCLAW_MODEL=${model}|" "$EASYCLAW_DIR/config.sh"
      else
        echo "export EASYCLAW_MODEL=${model}" >> "$EASYCLAW_DIR/config.sh"
      fi
      echo "✓ Model set to: $model"
      ;;
    show|"")
      echo "$EASYCLAW_MODEL"
      ;;
    list)
      cmd_models
      ;;
    *)
      echo "Usage: easy-claw model set <number|provider/model> | easy-claw model show | easy-claw model list"
      exit 1
      ;;
  esac
}

# ─── Security settings ──────────────────────────────
cmd_security() {
  local action="$1"
  case "$action" in
    toggle)
      local current
      current=$(grep "^export EASYCLAW_SKIP_PERMISSIONS=" "$EASYCLAW_DIR/config.sh" | cut -d= -f2 | tr -d '"')
      if [ "$current" = "true" ]; then
        sed -i '' 's/^export EASYCLAW_SKIP_PERMISSIONS=true/export EASYCLAW_SKIP_PERMISSIONS=false/' "$EASYCLAW_DIR/config.sh"
        echo "⚠ Permission prompts ON — OpenCode will ask before each command"
      else
        sed -i '' 's/^export EASYCLAW_SKIP_PERMISSIONS=false/export EASYCLAW_SKIP_PERMISSIONS=true/' "$EASYCLAW_DIR/config.sh"
        echo "✓ Permission prompts OFF — all commands auto-approved"
      fi
      ;;
    on)
      sed -i '' 's/^export EASYCLAW_SKIP_PERMISSIONS=false/export EASYCLAW_SKIP_PERMISSIONS=true/' "$EASYCLAW_DIR/config.sh" 2>/dev/null
      echo "✓ Permission prompts OFF"
      ;;
    off)
      sed -i '' 's/^export EASYCLAW_SKIP_PERMISSIONS=true/export EASYCLAW_SKIP_PERMISSIONS=false/' "$EASYCLAW_DIR/config.sh" 2>/dev/null
      echo "⚠ Permission prompts ON"
      ;;
    show|"")
      if [ "$EASYCLAW_SKIP_PERMISSIONS" = "true" ]; then
        echo "Status: auto-approve (all commands run without asking)"
        echo "To enable prompts: easy-claw security off"
      else
        echo "Status: ask before each command"
        echo "To disable prompts: easy-claw security on"
      fi
      ;;
    *)
      echo "Usage: easy-claw security [on|off|toggle|show]"
      exit 1
      ;;
  esac
}

# ─── Privacy — data handling info ───────────────────
cmd_privacy() {
  local action="$1"
  case "$action" in
    local|local-only)
      echo "Switching to local-only mode..."
      echo "Make sure Ollama is running with a model (e.g. qwen2.5-coder)"
      echo ""
      local local_model="${2:-ollama/qwen2.5-coder:latest}"
      sed -i '' "s|^export EASYCLAW_MODEL=.*|export EASYCLAW_MODEL=${local_model}|" "$EASYCLAW_DIR/config.sh"
      echo "✓ Model set to: $local_model (100% local, zero data leaves your machine)"
      ;;
    status|"")
      local model="$EASYCLAW_MODEL"
      echo "Current model: $model"
      case "$model" in
        opencode/*)
          echo "Data:     sent to OpenCode cloud server"
          echo "Privacy:  your queries/task data leave this machine"
          echo ""
          echo "For local-only: easy-claw privacy local"
          echo "  (requires Ollama with a model like qwen2.5-coder)"
          ;;
        ollama/*)
          echo "Data:     stays on this machine (local Ollama)"
          echo "Privacy:  zero data leaves your machine"
          ;;
        *)
          echo "Privacy:  depends on model provider"
          ;;
      esac
      ;;
    *)
      echo "Usage: easy-claw privacy [status|local [model]]"
      echo "  status     — show current model privacy status"
      echo "  local      — switch to local Ollama model (default: qwen2.5-coder)"
      echo "  local <m>  — switch to specific local model"
      exit 1
      ;;
  esac
}

# ─── Help ────────────────────────────────────────────────────
cmd_help() {
  cat <<'EOF'
Easy Claw v1.0 — Ultimate Free Agentic System
https://github.com/udaydomadiya08/easy-claw

OpenCode models as the NL bridge.
Say "check the time" — Easy Claw runs `date`. No hardcoding.

Usage: easy-claw <command> [options]

Commands:
  task <msg>     Say what you want — Easy Claw figures it out
  start          Start OpenCode server (background daemon)
  stop           Stop the server
  restart        Restart the server
  cron           Manage scheduled tasks (requires OpenClaw)
  skill          Manage skills (list, create, info)
  memory         Manage memory store
  channel        Manage messaging channels (requires OpenClaw)
  hook           Manage lifecycle hooks
  status         Show system status
  mcp            Manage MCP connectors
  models [prov]  List available OpenCode models
  model set|show Set/show the active model
  security       Toggle/show permission prompts
  privacy        Show data handling and switch to local-only
  version        Show version
  setup          One-time setup (first run auto-runs this)

Examples:
  easy-claw task "what time is it"
  easy-claw task "check disk space"
  easy-claw task "who am i"
  easy-claw task "how much memory is free"
  easy-claw task "list files in current directory"
EOF
}

# ─── Main dispatcher ─────────────────────────────────────────
main() {
  load_config
  local cmd="${1:-help}"
  shift 2>/dev/null || true

  case "$cmd" in
    help|--help|-h) cmd_help ;;
    version|--version|-v)
      echo "Easy Claw v1.0 — MIT License"
      echo "https://github.com/udaydomadiya08/easy-claw"
      ;;
    start) cmd_start ;;
    stop) cmd_stop ;;
    restart) cmd_restart ;;
    task|run) cmd_task "$@" ;;
    agent) cmd_agent "$@" ;;
    cron) cmd_cron "$@" ;;
    skill) cmd_skill "$@" ;;
    memory) cmd_memory "$@" ;;
    channel) cmd_channel "$@" ;;
    hook) cmd_hook "$@" ;;
    status) cmd_status ;;
    learn) cmd_learn "$@" ;;
    mcp) cmd_mcp "$@" ;;
    setup) cmd_setup ;;
    models) cmd_models "$@" ;;
    model) cmd_model "$@" ;;
    security) cmd_security "$@" ;;
    privacy) cmd_privacy "$@" ;;
    *)
      echo "Unknown command: $cmd"
      cmd_help
      exit 1
      ;;
  esac
}

main "$@"
