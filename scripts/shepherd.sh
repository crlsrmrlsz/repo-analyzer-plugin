#!/bin/bash
# Polls for .done completion markers. Returns one-line status.
# Usage: shepherd.sh <dir> <expected_count> [timeout_seconds]
#
# Watches a phase directory for agent completion markers (.*.done files).
# Excludes .briefer.done from the count since the briefer runs after agents.
# Returns: COMPLETE|done/expected|errors:N or TIMEOUT|done/expected|elapsed:Ns

set -e

DIR=$1
EXPECTED=$2
TIMEOUT=${3:-1800}
ELAPSED=0

if [ -z "$DIR" ] || [ -z "$EXPECTED" ]; then
    echo "ERROR|usage: shepherd.sh <dir> <expected_count> [timeout_seconds]"
    exit 1
fi

while [ $ELAPSED -lt $TIMEOUT ]; do
    DONE=$(find "$DIR" -maxdepth 1 -name ".*.done" ! -name ".briefer.done" 2>/dev/null | wc -l)
    if [ "$DONE" -ge "$EXPECTED" ]; then
        ERRORS=$(grep -rl "^error" "$DIR"/.*.done 2>/dev/null | wc -l)
        echo "COMPLETE|${DONE}/${EXPECTED}|errors:${ERRORS}"
        exit 0
    fi
    sleep 15
    ELAPSED=$((ELAPSED + 15))
done

DONE=$(find "$DIR" -maxdepth 1 -name ".*.done" ! -name ".briefer.done" 2>/dev/null | wc -l)
echo "TIMEOUT|${DONE}/${EXPECTED}|elapsed:${ELAPSED}s"
exit 1
