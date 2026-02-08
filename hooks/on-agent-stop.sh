#!/bin/bash
# SubagentStop hook: tracks agent completion and assembles phase briefing.
#
# For each managed agent (has OUTPUT_DIR in launch prompt):
#   1. Writes .done marker
#   2. Logs completion to agent_log.md
#   3. Counts .done files vs .manifest
#   4. When all done: concatenates summaries → briefing.md

set -e

INPUT=$(cat)

AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "unknown"')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.agent_transcript_path // ""')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Only process managed agents with a transcript
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
    exit 0
fi

# Extract OUTPUT_DIR from agent's launch prompt in transcript
OUTPUT_DIR=$(grep -oP 'OUTPUT_DIR: \K[^\s"\\]+' "$TRANSCRIPT" 2>/dev/null | head -1)

if [ -z "$OUTPUT_DIR" ]; then
    # Not a managed agent (no OUTPUT_DIR convention), skip
    exit 0
fi

# 1. Write .done marker
mkdir -p "$OUTPUT_DIR"
echo "ok" > "${OUTPUT_DIR}/.${AGENT_TYPE}-${AGENT_ID}.done"

# 2. Log completion
mkdir -p .analysis
echo "| $TIMESTAMP | DONE | $AGENT_TYPE | $AGENT_ID | $OUTPUT_DIR |" >> .analysis/agent_log.md

# 3. Count .done vs .manifest
MANIFEST="${OUTPUT_DIR}/.manifest"
[ -f "$MANIFEST" ] || exit 0

EXPECTED=$(tr -d '[:space:]' < "$MANIFEST")
DONE_COUNT=$(find "$OUTPUT_DIR" -maxdepth 1 -name ".*.done" 2>/dev/null | wc -l)

# 4. When all done: assemble briefing from summaries
if [ "$DONE_COUNT" -ge "$EXPECTED" ]; then
    SUMMARY_DIR="${OUTPUT_DIR}/summaries"
    BRIEFING="${OUTPUT_DIR}/briefing.md"

    {
        echo "# Phase Briefing — ${DONE_COUNT}/${EXPECTED} agents complete"
        echo ""
    } > "$BRIEFING"

    if [ -d "$SUMMARY_DIR" ] && ls "$SUMMARY_DIR"/*.md >/dev/null 2>&1; then
        for f in "$SUMMARY_DIR"/*.md; do
            cat "$f" >> "$BRIEFING"
            echo -e "\n---\n" >> "$BRIEFING"
        done
    else
        echo "No summaries found. Check agent output." >> "$BRIEFING"
    fi
fi

exit 0
