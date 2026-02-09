#!/usr/bin/env bash
# PreToolUse hook: enforces maximum planner recursion depth.
# Requires [depth:N/M] marker in Task description for planner launches.
# Uses python3 for JSON parsing to avoid jq dependency.
# Logs depth-check decisions to .analysis/debug/agent-log.jsonl.
# Scoped to Task tool calls via matcher in hooks.json.

input=$(cat)

subagent_type=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin).get('tool_input',{}); print(d.get('subagent_type',''))")

if [ "$subagent_type" != "planner" ]; then
    exit 0
fi

description=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin).get('tool_input',{}); print(d.get('description',''))")

# Log a depth-check event to the shared JSONL log
log_decision() {
    local decision="$1" current="$2" max="$3"
    mkdir -p .analysis/debug
    python3 - "$description" "$decision" "$current" "$max" <<'PYEOF'
import json, sys, os
from datetime import datetime, timezone
desc, decision, current, maxd = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
entry = {
    "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "event": "depth-check",
    "agent": "planner",
    "description": desc,
    "decision": decision,
}
if current:
    entry["depth_current"] = int(current)
    entry["depth_max"] = int(maxd)
log_path = os.path.join(".analysis", "debug", "agent-log.jsonl")
with open(log_path, "a", encoding="utf-8") as f:
    f.write(json.dumps(entry, ensure_ascii=False) + "\n")
PYEOF
}

# Parse [depth:N/M] from description
if [[ "$description" =~ \[depth:([0-9]+)/([0-9]+)\] ]]; then
    current="${BASH_REMATCH[1]}"
    max="${BASH_REMATCH[2]}"

    if [ "$current" -ge "$max" ]; then
        log_decision "deny:max-reached" "$current" "$max"
        echo "{\"hookSpecificOutput\":{\"permissionDecision\":\"deny\",\"reason\":\"Maximum planner depth reached (${current}/${max}). Decompose into specialist tasks instead.\"}}"
        exit 0
    fi

    log_decision "allow" "$current" "$max"
else
    # No depth marker — require it for safety
    log_decision "deny:missing-marker" "" ""
    echo '{"hookSpecificOutput":{"permissionDecision":"deny","reason":"Planner launch missing required [depth:N/M] marker in description."}}'
    exit 0
fi

echo '{}'
