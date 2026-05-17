# Easy Claw Configuration
# Override defaults by setting env vars before running easy-claw

# OpenCode bridge binary
export OPENCODE_BIN="${OPENCODE_BIN:-/Users/uday/.opencode/bin/opencode}"

# OpenClaw backend binary
export OPENCLAW_BIN="${OPENCLAW_BIN:-openclaw}"

# Default model (local Ollama)
export EASYCLAW_MODEL="${EASYCLAW_MODEL:-ollama/qwen2.5-coder:latest}"

# Data directories
export EASYCLAW_SKILLS_DIR="${EASYCLAW_DIR}/skills"
export EASYCLAW_HOOKS_DIR="${EASYCLAW_DIR}/hooks"
export EASYCLAW_MCP_DIR="${EASYCLAW_DIR}/mcp"
export EASYCLAW_STATE_DIR="${EASYCLAW_DIR}/state"

# Self-improvement loop
export EASYCLAW_AUTO_LEARN="${EASYCLAW_AUTO_LEARN:-true}"

# OpenClaw gateway
export OPENCLAW_GATEWAY_URL="${OPENCLAW_GATEWAY_URL:-ws://127.0.0.1:18789}"
export OPENCLAW_GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-}"
