#!/usr/bin/env python3
"""PreToolUse hook: enforces read-only behavior for analysis agents.

Guards three tools:
  Write → allow only if resolved path contains /.analysis/
  Edit  → block unconditionally (no agent declares it)
  Bash  → block if command matches git-mutating or destructive-file regex

Prints '{}' to allow, or a deny JSON response to block.
Fails open on parse errors (safety net, not primary defense).
"""

import json
import os
import re
import sys

BASH_BLOCKLIST = re.compile(
    r"\b("
    r"git\s+(push|commit|add|reset|rebase|merge|cherry-pick|revert|clean|stash|tag|checkout|switch|restore|branch\s+-[dDmM])"
    r"|rm\b|rmdir\b|mv\b|chmod\b|chown\b"
    r")"
)


def deny(reason: str) -> None:
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        },
        sys.stdout,
    )


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        print("{}")
        return

    tool = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {})

    if tool == "Edit":
        deny("Edit is not permitted during analysis — all output goes to .analysis/ via Write.")
        return

    if tool == "Write":
        raw_path = tool_input.get("file_path", "")
        resolved = os.path.realpath(raw_path)
        if "/.analysis/" not in resolved and not resolved.endswith("/.analysis"):
            deny(f"Write blocked — path '{raw_path}' is outside .analysis/. Analysis agents must not modify repository files.")
            return
        print("{}")
        return

    if tool == "Bash":
        command = tool_input.get("command", "")
        match = BASH_BLOCKLIST.search(command)
        if match:
            deny(f"Bash blocked — '{match.group()}' is a mutating operation. Analysis agents must not alter the repository.")
            return
        print("{}")
        return

    # Unknown tool matched by regex — allow
    print("{}")


if __name__ == "__main__":
    main()
