#!/bin/bash
set -e

INPUT=$(cat)

AGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "unknown"')
MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // "default"')
TOOL_USE_ID=$(echo "$INPUT" | jq -r '.tool_use_id // ""')
SUCCESS=$(echo "$INPUT" | jq -r '.tool_response.success // "unknown"')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p .analysis

{
  echo "| $TIMESTAMP | END   | $AGENT_TYPE | $MODEL | $TOOL_USE_ID | $SUCCESS |"
} >> .analysis/agent_log.md

exit 0
