#!/usr/bin/env python3
"""PreToolUse / PostToolUse hook: logs agent lifecycle events to JSONL.

Usage:
    python3 log-agents.py start   # PreToolUse  — logs start + prompt
    python3 log-agents.py stop    # PostToolUse — logs finish

Appends to .analysis/debug/agent-log.jsonl relative to the working directory.
Only logs Task tool calls; silently skips everything else.
PreToolUse must print '{}' to allow the call through.
"""

import json
import os
import sys
from datetime import datetime, timezone


def main() -> None:
    if len(sys.argv) < 2 or sys.argv[1] not in ("start", "stop"):
        sys.exit(0)

    event = sys.argv[1]

    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        if event == "start":
            print("{}")
        sys.exit(0)

    # Only log Task tool calls
    if payload.get("tool_name") != "Task":
        if event == "start":
            print("{}")
        sys.exit(0)

    tool_input = payload.get("tool_input", {})
    tool_use_id = payload.get("tool_use_id", "")

    entry = {
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "event": event,
        "tool_use_id": tool_use_id,
        "agent": tool_input.get("subagent_type", ""),
        "description": tool_input.get("description", ""),
    }

    if event == "start":
        entry["model"] = tool_input.get("model", "")
        entry["prompt"] = tool_input.get("prompt", "")

    log_dir = os.path.join(".analysis", "debug")
    os.makedirs(log_dir, exist_ok=True)
    log_path = os.path.join(log_dir, "agent-log.jsonl")

    with open(log_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")

    # PreToolUse must emit '{}' to allow the call
    if event == "start":
        print("{}")


if __name__ == "__main__":
    main()
