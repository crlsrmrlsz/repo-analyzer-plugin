#!/bin/bash
# SubagentStop hook: writes .done completion marker when a managed agent finishes.
# Reads the DONE_MARKER path from the agent's launch prompt in its transcript.
# Non-managed agents (no DONE_MARKER in prompt) are approved without action.
#
# Convention: orchestrator includes "DONE_MARKER: .analysis/pN/.agent_name.done"
# in every agent launch prompt. This hook greps for it and writes the file.

set -e

INPUT=$(cat)

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
    # No transcript available — approve stop
    echo '{"decision": "approve"}'
    exit 0
fi

# Extract DONE_MARKER path from the agent's launch prompt in the transcript.
# The DONE_MARKER line is included by the orchestrator in every managed agent prompt.
DONE_PATH=$(grep -oP 'DONE_MARKER: \K[^\s"\\]+' "$TRANSCRIPT" 2>/dev/null | head -1)

if [ -z "$DONE_PATH" ]; then
    # Not a managed agent (no DONE_MARKER convention), let it stop
    echo '{"decision": "approve"}'
    exit 0
fi

mkdir -p "$(dirname "$DONE_PATH")"
echo "ok" > "$DONE_PATH"

echo '{"decision": "approve"}'
exit 0
