# system-health
Check system health: disk, memory, CPU, uptime, and services

## Trigger
When user asks about system health, status, diagnostics, or monitoring

## Instructions
1. Run `uptime` to check system load
2. Run `df -h /` to check disk usage
3. Run `vm_stat` to check memory
4. Check OpenClaw gateway health
5. Check Ollama is running
6. Store results in MEMORY.md
7. Report summary to user
