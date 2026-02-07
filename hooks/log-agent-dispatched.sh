#!/bin/bash
# PostToolUse hook for Task — logs agent dispatch and registers background agent task_ids.
# Background agents are registered in .analysis/control/agent_registry.jsonl
# so the TaskOutput guard can block reading their output into orchestrator context.

set -e

INPUT=$(cat)

AGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "unknown"')
MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // "default"')
TOOL_USE_ID=$(echo "$INPUT" | jq -r '.tool_use_id // ""')
SUCCESS=$(echo "$INPUT" | jq -r '.tool_response.success // "unknown"')
RUN_IN_BG=$(echo "$INPUT" | jq -r '.tool_input.run_in_background // false')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Extract the task_id from the tool response for background agents
# The Task tool response includes a task_id field when run_in_background=true
TASK_ID=$(echo "$INPUT" | jq -r '.tool_response.task_id // .tool_response.id // ""')

mkdir -p .analysis/control

# Log the dispatch
{
  echo "| $TIMESTAMP | DISPATCHED | $AGENT_TYPE | $MODEL | $TOOL_USE_ID | bg:$RUN_IN_BG | $SUCCESS |"
} >> .analysis/agent_log.md

# Register background agent task_ids for the TaskOutput guard
if [ "$RUN_IN_BG" = "true" ] && [ -n "$TASK_ID" ]; then
    echo "{\"task_id\":\"${TASK_ID}\",\"agent_type\":\"${AGENT_TYPE}\",\"tool_use_id\":\"${TOOL_USE_ID}\",\"timestamp\":\"${TIMESTAMP}\"}" >> .analysis/control/agent_registry.jsonl
fi

exit 0
