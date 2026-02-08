#!/bin/bash
# Waits for a file to exist. Returns READY or TIMEOUT.
# Usage: wait_for_file.sh <filepath> [timeout_seconds]

set -e

FILEPATH=$1
TIMEOUT=${2:-1800}
ELAPSED=0

if [ -z "$FILEPATH" ]; then
    echo "ERROR: usage: wait_for_file.sh <filepath> [timeout_seconds]"
    exit 1
fi

while [ $ELAPSED -lt $TIMEOUT ]; do
    [ -f "$FILEPATH" ] && { echo "READY"; exit 0; }
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

echo "TIMEOUT"
exit 1
