#!/usr/bin/env python3
"""
SessionStart hook — walks docs/*/ and lists each feature's current step
so Claude does not need to re-read every status file at every session start.
"""
import json
import os
import re
import sys


def parse_status(path: str):
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
    except OSError:
        return None
    current_step_m = re.search(r"\*\*Current step:\*\*\s*(.+)", content)
    if not current_step_m:
        return None
    current_step = current_step_m.group(1).strip()
    last_updated_m = re.search(r"\*\*Last updated:\*\*\s*(.+)", content)
    last_updated = last_updated_m.group(1).strip() if last_updated_m else "unknown"
    if re.search(r"all\s+(steps\s+)?approved", current_step, re.IGNORECASE):
        return None  # feature is fully done; do not list
    return current_step, last_updated


def main() -> int:
    docs_root = "docs"
    if not os.path.isdir(docs_root):
        return 0

    rows = []  # list of (feature_name, current_step, last_updated)
    for entry in sorted(os.listdir(docs_root)):
        sub = os.path.join(docs_root, entry)
        if not os.path.isdir(sub):
            continue
        status_file = os.path.join(sub, f"{entry}.status.md")
        parsed = parse_status(status_file)
        if parsed is None:
            continue
        current_step, last_updated = parsed
        rows.append((entry, current_step, last_updated))

    if not rows:
        return 0

    name_w = max(len(r[0]) for r in rows)
    lines = ["## In-flight features", ""]
    for name, step, updated in rows:
        lines.append(f"- {name.ljust(name_w)} - {step}, updated {updated}")
    lines.append("")
    lines.append(
        "For full context on a feature: read docs/<feature>/<feature>.status.md."
    )
    banner = "\n".join(lines)

    output = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": banner,
        }
    }
    print(json.dumps(output))
    return 0


if __name__ == "__main__":
    sys.exit(main())
