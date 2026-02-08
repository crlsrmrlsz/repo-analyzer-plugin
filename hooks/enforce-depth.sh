#!/usr/bin/env bash
# PreToolUse hook: enforces maximum planner recursion depth.
# Requires [depth:N/M] marker in Task description for planner launches.
# Uses python3 for JSON parsing to avoid jq dependency.

input=$(cat)

tool_name=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))")

if [ "$tool_name" != "Task" ]; then
    exit 0
fi

subagent_type=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin).get('tool_input',{}); print(d.get('subagent_type',''))")

if [ "$subagent_type" != "planner" ]; then
    exit 0
fi

description=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin).get('tool_input',{}); print(d.get('description',''))")

# Parse [depth:N/M] from description
if [[ "$description" =~ \[depth:([0-9]+)/([0-9]+)\] ]]; then
    current="${BASH_REMATCH[1]}"
    max="${BASH_REMATCH[2]}"

    if [ "$current" -ge "$max" ]; then
        echo "{\"hookSpecificOutput\":{\"permissionDecision\":\"deny\",\"reason\":\"Maximum planner depth reached (${current}/${max}). Decompose into specialist tasks instead.\"}}"
        exit 0
    fi
else
    # No depth marker — require it for safety
    echo '{"hookSpecificOutput":{"permissionDecision":"deny","reason":"Planner launch missing required [depth:N/M] marker in description."}}'
    exit 0
fi

echo '{}'
