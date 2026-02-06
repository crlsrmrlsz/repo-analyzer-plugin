#!/bin/bash
set -e

INPUT=$(cat)

AGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // "unknown"')
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // ""')
MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // "default"')
PROMPT=$(echo "$INPUT" | jq -r '.tool_input.prompt // ""')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p .analysis

{
  echo "| $TIMESTAMP | $AGENT_TYPE | $MODEL | $DESCRIPTION |"
} >> .analysis/agent_log.md

exit 0
