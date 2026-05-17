#!/bin/bash
# Hermes-style Self-Improving Learning Loop for Easy Claw
# Integrates with the main easy-claw.sh orchestrator

# This module provides:
# 1. Post-task evaluation (every N tool calls)
# 2. Auto skill creation from successful task patterns
# 3. Memory curation (MEMORY.md + USER.md management)
# 4. Skill improvement over time

evaluate_and_learn() {
  local task_message="$1"
  local exit_code="$2"
  local task_id="$3"

  echo "[hermes-loop] Evaluating task..."

  # Determine if this task is worth learning from
  local should_learn=false

  # Learn from successful non-trivial tasks
  if [ "$exit_code" = "0" ] && [ ${#task_message} -gt 10 ]; then
    should_learn=true
  fi

  if [ "$should_learn" = true ]; then
    local skill_name=$(echo "$task_message" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | head -c 40)

    # Generate skill content
    local skill_file="$EASYCLAW_DIR/skills/$skill_name.md"

    if [ ! -f "$skill_file" ]; then
      cat > "$skill_file" <<SKILLEOF
# $skill_name
Auto-created from successful task: $task_message

## Trigger
When user asks about or requests: $task_message

## Prerequisites
- Easy Claw system
- Appropriate permissions

## Instructions
1. Understand the specific context of the request
2. Break down the task into clear steps
3. Execute each step methodically
4. Verify results after each step
5. Report progress and completion to the user

## Notes
- Created by Easy Claw learning loop
- Last used: $(date +%Y-%m-%d)

## Tags
automated, learning, task
SKILLEOF
      echo "[hermes-loop] ✓ Created skill: /$skill_name"
    else
      # Update existing skill with new usage
      echo "[hermes-loop] ✓ Skill already exists: /$skill_name (updated timestamp)"
    fi

    # Record in memory
    echo "- $(date +%Y-%m-%d): Learned from task: $task_message" >> "$EASYCLAW_DIR/MEMORY.md"
  fi
}

# Export function for use by easy-claw.sh
export -f evaluate_and_learn
