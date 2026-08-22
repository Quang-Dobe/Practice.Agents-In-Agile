---
description: Ask the root LLM-Wiki a question; classifies and answers inline in the main thread (no sub-agent)
argument-hint: <question>
---

Ask the project-tier LLM-Wiki a question. The question is classified and answered **inline
in the main thread** — no sub-agent is spawned. An in-domain question is answered from
the wiki using the fixed retrieval order (root `docs/memory/*` → `docs/references.md`
→ repos' `docs/narrative/` → repos' `docs/domain/` → repos' `docs/memory/` → repo source,
last resort), stopping at the first tier that answers. The wiki is read first and repo
source last; a pure read/answer path never writes.

`<question>` is the natural-language question to answer. This command takes a **question**,
not a path — there is no remote-URL guard.

## Procedure

1. **Parse `<question>`.** Read the question from the slash-command argument.

2. **Refuse empty input.** If `<question>` is empty or whitespace-only, refuse with this
   **exact-case** literal one-line message and **stop** — do not load any skill and do
   not consult any tier:

   ```
   Ask a question, e.g. /wiki:ask "where is OrderPaid published?"
   ```

3. **Load the retrieval checklist — and only that.** Reload
   `.claude/skills/wiki-router/SKILL.md` — the operating manual for classification
   (titles/headings-only manifest), the fixed 6-tier retrieval order, the
   stop-once-sufficient rule, the one-line TRACE format, and the out-of-domain decline
   literal. If it is **missing or malformed** (cannot be read, YAML frontmatter does not
   parse, or required body sections absent), **stop before any retrieval** and report the
   missing/malformed skill. Do **NOT** load `wiki-memory` here — it is lazy-loaded only
   if T6 is actually reached (step 6).

4. **Classify, then retrieve, per the skill.** Build the titles/headings manifest and
   decide in-domain vs out-of-domain. Out-of-domain → emit the decline literal plus the
   empty TRACE (`wiki-trace: (no tiers consulted)`) and stop — no tier opened, nothing
   written. In-domain → walk T1 → T6 in the exact order, stopping once sufficient, and
   emit the one-line `wiki-trace:` naming the tiers consulted with the `STOP@T<n>` marker.

5. **Answer came from the wiki (T1–T5) → done.** Cite the tier artifact (memory topic /
   architecture section / narrative file / domain file / per-repo memory topic) and stop.
   No source read, no write, no `APPROVE` prompt.

6. **T6 source read → lazy-load the write manual, then append.** Only when repo source
   was actually read to answer: load `.claude/skills/wiki-memory/SKILL.md` and append the
   learning to **that repo's** `<repo>/docs/memory/` per the write manual (ungated:
   append-only + dedup + fence). If `wiki-memory` is missing/malformed, still deliver the
   answer, write nothing, and report the missing skill.

(Historical note: v1 spawned a `wiki-router` sub-agent that preloaded both skills on
every question; v2 answers inline and lazy-loads the write manual — same classification,
tier order, TRACE format, literals, and write rules.)
