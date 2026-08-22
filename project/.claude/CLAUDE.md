# Project-Tier Session Rules

Loaded automatically when a Claude Code session runs at the multi-repo root where
this kit is installed as `.claude/`. One rule lives here.

## [R-WIKI-FIRST] — every question goes through the wiki

`/wiki:ask` is the explicit, forced entry point. This rule makes the same path the
**default for any question the user asks in conversation** — no slash command needed.

Whenever the user asks a question (any phrasing: "where is X?", "how does Y work?",
"why does Z happen?"):

1. Load `.claude/skills/wiki-router/SKILL.md` and classify the question exactly as
   `/wiki:ask` would (titles/headings manifest, in-domain vs out-of-domain).
2. **In-domain** → answer from the wiki using the fixed retrieval order
   (root `docs/memory/*` → `docs/references.md` → repos' `docs/narrative/` →
   repos' `docs/domain/` → repos' `docs/memory/` → repo source, last resort),
   stopping at the first tier that answers. Emit the one-line `wiki-trace:`.
   Never jump to raw source while a wiki tier can answer.
3. **Repo source actually read (T6)** → lazy-load `.claude/skills/wiki-memory/SKILL.md`
   and append the learning to that repo's `docs/memory/` per the write manual.
4. **Out-of-domain** → answer normally. The out-of-domain decline literal belongs to
   the explicit `/wiki:ask` command only — never decline an organic question.

Surface the `[R-WIKI-FIRST]` tag in the response disclosure prefix whenever this rule
routed the answer.
