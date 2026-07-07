#!/usr/bin/env python3
"""
Stop hook (present kit) — deterministic backstop that the present dossier gets
built. Fires when the assistant finishes a turn; if a feature has finished
planning (<feature>.plan.md exists) but its dossier
(docs/<feature>/present/present.html) is missing, it BLOCKS the stop and tells
the model to run /present:build — so the build can't be silently skipped.

Why block, not auto-build: building spawns the present-builder agent and
authors SVG + HTML — an LLM action a script cannot perform. The hook guarantees
the model is forced to do it before the turn can end.

Loop-safe: honors `stop_hook_active` (never blocks twice in a row), so a
genuinely un-buildable miss stops after one nudge instead of looping.

Scoped so it never nags where present does not apply:
  - present kit installed (.claude/commands/present/build.md), and
  - wiki grounding exists (same two-mode detect as /present:build), and
  - the feature has no docs/<feature>/.no-present opt-out marker.
"""
import json
import os
import sys

DOCS = "docs"
RESERVED = {"domain", "narrative", "memory"}


def has_content(path: str) -> bool:
    return os.path.isdir(path) and any(os.scandir(path))


def grounding_exists() -> bool:
    # mirror /present:build's mode-detect (project mode | root mode)
    project = has_content(os.path.join(DOCS, "domain")) or has_content(
        os.path.join(DOCS, "narrative")
    )
    root = (
        os.path.isfile("repo-layout.md")
        or has_content(os.path.join(DOCS, "memory"))
        or os.path.isfile(os.path.join(DOCS, "architecture.md"))
    )
    return project or root


def find_misses():
    misses = []
    for entry in sorted(os.listdir(DOCS)):
        if entry in RESERVED:
            continue
        sub = os.path.join(DOCS, entry)
        if not os.path.isdir(sub):
            continue
        if os.path.isfile(os.path.join(sub, ".no-present")):
            continue
        plan = os.path.join(sub, f"{entry}.plan.md")
        present_index = os.path.join(sub, "present", "present.html")
        if os.path.isfile(plan) and not os.path.isfile(present_index):
            misses.append(entry)
    return misses


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except Exception:
        data = {}
    # already continuing because of this hook — do not block again (loop guard)
    if data.get("stop_hook_active"):
        return 0
    if not os.path.isdir(DOCS):
        return 0
    if not os.path.isfile(os.path.join(".claude", "commands", "present", "build.md")):
        return 0
    if not grounding_exists():
        return 0

    misses = find_misses()
    if not misses:
        return 0

    cmds = "; ".join(f"/present:build {m}" for m in misses)
    reason = (
        "Present dossier missing for: " + ", ".join(misses) + ". "
        "Planning finished (plan.md exists) but docs/<feature>/present/present.html is absent. "
        "Run " + cmds + " now — it self-detects project/root grounding mode and writes the "
        "dossier — then you may stop. If present was intentionally disabled for a feature, "
        "create docs/<feature>/.no-present to silence this."
    )
    print(json.dumps({"decision": "block", "reason": reason}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
