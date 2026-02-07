#!/bin/bash
# PreToolUse hook for TaskOutput — blocks reading agent output into orchestrator context.
# Allows shepherd/wait script task IDs through; blocks registered agent task IDs.
#
# Reads the agent registry at .analysis/control/agent_registry.jsonl to determine
# whether a task_id belongs to a background agent (blocked) or a utility script (allowed).

set -e

INPUT=$(cat)

TASK_ID=$(echo "$INPUT" | jq -r '.tool_input.task_id // ""')

if [ -z "$TASK_ID" ]; then
    # No task_id — allow (shouldn't happen but don't block on edge cases)
    echo '{"decision": "allow"}'
    exit 0
fi

REGISTRY=".analysis/control/agent_registry.jsonl"

if [ ! -f "$REGISTRY" ]; then
    # No registry exists — allow (plugin may not have initialized yet)
    echo '{"decision": "allow"}'
    exit 0
fi

# Check if this task_id is registered as a background agent
if grep -q "\"task_id\":\"${TASK_ID}\"" "$REGISTRY" 2>/dev/null; then
    echo '{"decision": "block", "reason": "BLOCKED: TaskOutput on agent task_id. Agent output must not enter orchestrator context. Use briefing files in .analysis/pN/briefing.md instead."}'
    exit 0
fi

# Not a registered agent — allow (shepherd, wait_for_file, etc.)
echo '{"decision": "allow"}'
exit 0
