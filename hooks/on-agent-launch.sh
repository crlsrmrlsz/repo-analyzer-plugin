#!/bin/bash
# PostToolUse hook for Task: logs agent launch and registers background task_ids.

set -e

INPUT=$(cat)

AGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "unknown"')
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // ""')
RUN_IN_BG=$(echo "$INPUT" | jq -r '.tool_input.run_in_background // false')
AGENT_ID=$(echo "$INPUT" | jq -r '.tool_response.agent_id // ""')
PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // ""')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p .analysis/control

# Log launch with prompt excerpt
{
    echo "| $TIMESTAMP | LAUNCH | $AGENT_TYPE | $AGENT_ID | bg:$RUN_IN_BG | $DESCRIPTION |"
    echo "  Prompt: $(echo "$PROMPT" | tr '\n' ' ' | cut -c1-300)"
    echo ""
} >> .analysis/agent_log.md

# Register background agent task_ids for the TaskOutput guard
if [ "$RUN_IN_BG" = "true" ] && [ -n "$AGENT_ID" ]; then
    echo "{\"task_id\":\"${AGENT_ID}\",\"agent_type\":\"${AGENT_TYPE}\",\"timestamp\":\"${TIMESTAMP}\"}" >> .analysis/control/agent_registry.jsonl
fi

exit 0
