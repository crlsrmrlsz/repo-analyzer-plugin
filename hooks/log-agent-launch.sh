#!/bin/bash
# PreToolUse hook for Task — logs agent launch with background detection.
set -e

INPUT=$(cat)

AGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "unknown"')
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // ""')
MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // "default"')
RUN_IN_BG=$(echo "$INPUT" | jq -r '.tool_input.run_in_background // false')
TOOL_USE_ID=$(echo "$INPUT" | jq -r '.tool_use_id // ""')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p .analysis

{
  echo "| $TIMESTAMP | LAUNCH | $AGENT_TYPE | $MODEL | $TOOL_USE_ID | bg:$RUN_IN_BG | $DESCRIPTION |"
} >> .analysis/agent_log.md

exit 0
