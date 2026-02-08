#!/bin/bash
# PreToolUse hook for TaskOutput: blocks reading agent output into orchestrator context.
# Allows non-agent task_ids through (e.g., background Bash wait commands).

set -e

INPUT=$(cat)

TASK_ID=$(echo "$INPUT" | jq -r '.tool_input.task_id // ""')

if [ -z "$TASK_ID" ]; then
    exit 0
fi

REGISTRY=".analysis/control/agent_registry.jsonl"

if [ ! -f "$REGISTRY" ]; then
    exit 0
fi

# Block if this task_id belongs to a registered background agent
if grep -q "\"task_id\":\"${TASK_ID}\"" "$REGISTRY" 2>/dev/null; then
    echo "BLOCKED: Agent output must not enter orchestrator context. Read .analysis/pN/briefing.md instead."
    exit 2
fi

exit 0
