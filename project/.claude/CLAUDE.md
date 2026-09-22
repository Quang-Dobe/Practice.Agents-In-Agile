# Project-Tier Session Rules

Loaded at the multi-repo root where `install.ps1` placed this file. One rule lives here.

## [R-WIKI-FIRST] — every question goes through the wiki

Any question the user asks in conversation takes the `/wiki:ask` path — no slash command needed.

1. Classify the question as `/wiki:ask` does — steps 3-5 of `.claude/commands/wiki/ask.md`.
2. **In-domain** → answer from the wiki, stopping at the first tier that answers: root
   `docs/memory/*` → `docs/references.md` → repos' `docs/narrative/` → `docs/domain/` →
   `docs/memory/` → repo source, last resort. Emit the one-line `wiki-trace:`.
3. **Repo source actually read (T6)** → lazy-load `.claude/skills/wiki-memory/SKILL.md` and append
   the learning to that repo's `docs/memory/` per the write manual.
4. **Out-of-domain** → answer normally. Never decline an organic question; the decline literal
   belongs to the explicit `/wiki:ask` command only.

Tag `[R-WIKI-FIRST]` in the disclosure prefix whenever this rule routed the answer.
