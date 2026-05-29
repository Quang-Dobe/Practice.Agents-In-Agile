---
description: Ask the root LLM-Wiki a question; routes via the wiki-router sub-agent
argument-hint: <question>
---

Ask the root-tier LLM-Wiki a question. The question is routed to the `wiki-router`
sub-agent, which classifies it in-domain vs out-of-domain and — when in-domain —
answers from the wiki using the fixed retrieval order (`docs/memory/*` →
`docs/architecture.md` → repos' `docs/narrative/` → repos' `docs/domain/` → repo source,
last resort), stopping at the first tier that answers. The router reads the wiki first
and repo source last; it never writes on a pure read/answer path.

`<question>` is the natural-language question to answer. This command takes a **question**,
not a path — there is no remote-URL guard.

## Procedure

1. **Parse `<question>`.** Read the question from the slash-command argument.

2. **Refuse empty input — stop before spawning the router.** If `<question>` is empty or
   whitespace-only, refuse with this **exact-case** literal one-line message and **stop**
   — do not spawn the `wiki-router` sub-agent and do not consult any tier:

   ```
   Ask a question, e.g. /wiki:ask "where is OrderPaid published?"
   ```

3. **Spawn the router.** Otherwise, spawn the `wiki-router` subagent via the `Agent` tool
   with `description: "wiki-router: answer a wiki question"` and a `prompt` containing:
   - the operator's `<question>`;
   - the instruction that the agent must **reload both skills before acting**, in this
     order: `.claude/skills/wiki-router/SKILL.md` first (classification + fixed
     retrieval order), then `.claude/skills/wiki-memory/SKILL.md` (the write
     manual, used only on a source-read hand-off; if it is missing/malformed the agent
     still answers but stops before any write and reports the missing skill).

   The router classifies the question, answers from the wiki (or declines if
   out-of-domain), emits its one-line `wiki-trace:` line, and — only if it had to read
   repo source — names the memory-append hand-off by path. This mirrors the
   `/wiki:bootstrap` → `wiki-bootstrapper` and `/project:explore` → `project-explorer`
   spawn patterns. A question answered from the wiki (no source read) produces zero
   writes and presents no `APPROVE` prompt; the router only ever writes via the
   `wiki-memory` write path, after a source read, with that skill loaded and valid.
