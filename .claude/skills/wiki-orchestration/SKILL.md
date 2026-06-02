---
name: wiki-orchestration
description: Shared per-repo ensure/refresh orchestration core + scope/execution protocol consumed by /wiki:bootstrap and /wiki:enhance
version: 1
consumed_by: wiki:bootstrap command, wiki:enhance command
---

## Purpose

The auditable core both root-tier wiki entrypoints share: how to bring each sibling repo to
a usable per-repo wiki state (`ensureRepo`), how `/wiki:bootstrap` asks its two operator
questions, and how either command fans work across repos. It writes nothing itself — it
drives the crew's `project:*` slash commands and then hands the rollup to the
`wiki-bootstrapper` and (for `/wiki:enhance`) the `wiki-architect`.

## Repo discovery (read-only)

Enumerate the **depth-1 child directories** of the system root. A child **qualifies as a
repo iff** it is not `docs/` or `.claude/`. Tree state per repo:

- **empty** — has **neither** `docs/narrative/` **nor** `docs/domain/`.
- **existing** — has `docs/narrative/` **OR** `docs/domain/` (or both).

`docs/memory/` (per-repo learnings) **never** affects the empty/existing test — it is a
separate tree.

## `ensureRepo(repo, mode)`

The single per-repo routine both commands call.

- **empty repo →** run `/project:overview <repo>` then `/project:explore <repo>` (in that
  order). These crew commands are fully agent-driven (no gate) and each refuses on a
  non-empty target, so calling them only on **empty** repos never trips their refusal.
- **existing repo →** caller decides:
  - `mode = "skip"` (bootstrap) → do nothing (bootstrap is gap-fill only; it never
    refreshes existing trees).
  - `mode = "refresh"` (enhance) → run `/project:enhance-wiki <repo>`.

If the crew `project:*` commands are **unavailable** (only `.claude/` installed, not the
`.claude-user/` crew), emit the one-line advisory and **skip orchestration** for that repo,
proceeding to rollup with whatever trees already exist:
```
Advisory: project:overview/explore/enhance-wiki not available — skipping per-repo orchestration for <repo>; rolling up existing trees only.
```

## Two-question protocol (bootstrap only)

`/wiki:bootstrap` asks the operator exactly two questions before any orchestration. Use the
`AskUserQuestion` tool, one call, both questions.

1. **Scope** — *all repos* or *some repos*. Alongside the choice, print the agent's
   **suggested first batch**, ranked by this heuristic:
   1. repos with **neither** tree (empty) first — they have no wiki at all;
   2. then repos with only one of the two trees;
   3. ties broken by inbound cross-repo dependency count if derivable from existing
      `docs/domain/` events, else alphabetical.
2. **Execution** — *one agent (sequential)* or *sub-agent per repo (parallel fan-out)*.
   Parallel needs **no** git worktree: each repo writes only its own `docs/` subtree, so
   concurrent `ensureRepo` calls never conflict.

`/wiki:enhance` does **not** ask these — it runs over **all** repos, sequentially or with
sub-agents at the implementer's discretion, non-interactively.

## After per-repo work — rollup hand-off

Both commands, once per-repo trees are settled:

1. Hand off to the `wiki-bootstrapper` to **summarize-and-link** into the **root**
   `docs/memory/`. Inputs are now **four** read-only trees per repo plus the root file:
   `docs/architecture.md`, each repo's `docs/narrative/`, `docs/domain/`, **and**
   `docs/memory/` (per-repo learnings). The rollup links per-repo memory; it never copies
   entry bodies.
2. `/wiki:enhance` **additionally** hands off to the `wiki-architect` to (re)author
   `docs/architecture.md` (see the `wiki-architecture` skill). `/wiki:bootstrap` does
   **not** author architecture.md.

## Invariants

- **Gate-free.** No `APPROVE` anywhere. Safety net is the downstream write paths'
  append-only + dedup + fence rules.
- **Local paths only.** Refuse `^https?://` / `^git@` at the command layer.
- **No auto-commit.** Leave all writes as working-tree changes.
- **Confinement is delegated.** This skill writes nothing; each downstream agent enforces
  its own write confinement (`wiki-memory` → `docs/memory/` trees; `wiki-architecture` →
  `docs/architecture.md`; crew `project:*` → narrative/domain).
