---
name: wiki-orchestration
description: Shared per-repo ensure/refresh orchestration core + scope/execution protocol consumed by /wiki:bootstrap and /wiki:enhance; derives and walks a content-driven nested node tree (leaves + bottom-up rollups) when a repo entry resolves to >=2 leaf homes
version: 1
consumed_by: wiki:bootstrap command, wiki:enhance command
---

## Purpose

The auditable core both project-tier wiki entrypoints share: how to bring each sibling repo to
a usable per-repo wiki state (`ensureRepo`), how `/wiki:bootstrap` asks its two operator
questions, and how either command fans work across repos. It writes nothing itself — it
drives the crew's `project:*` slash commands and then hands the rollup to the
`wiki-bootstrapper` and (for `/wiki:enhance`) the `wiki-architect`.

## Repo discovery (read-only)

**Manifest-first.** If a `repo-layout.md` exists at the system root (the scan root), the
authoritative repo set is its `repos[]` list — each entry's `path` resolved relative to the
root — per the `repo-layout` skill `## Schema (schema: 1)` and `## Discovery (walk-up to the
scan root)`. Each `project:*` invocation then scans only that repo's declared roots (the crew
agents enforce this via their own `repo-layout` scope step). Directories present on disk but
**absent** from the manifest's `repos[]` are surfaced with the not-declared advisory from the
`repo-layout` skill `## Advisory literals` and reconciled by `/wiki:enhance` (the single
writer), never silently dropped.

**Fallback (no manifest).** When no `repo-layout.md` is present, enumerate the **depth-1
child directories** of the system root. A child **qualifies as a repo iff** it is not `docs/`
or `.claude/`. Behavior is byte-identical to pre-manifest runs (the `repo-layout` skill
`## Backward compatibility`).

Tree state per repo (both paths):

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
  - `mode = "refresh"` (enhance) → run `/project:update <repo>`.

If the crew `project:*` commands are **unavailable** (only this wiki kit installed, the
root-tier crew absent from `~/.claude/`), emit the one-line advisory and **skip orchestration** for that repo,
proceeding to rollup with whatever trees already exist:
```
Advisory: project:overview/explore/update not available — skipping per-repo orchestration for <repo>; rolling up existing trees only.
```

When the caller's repo entry expands into a node tree (`## Node tree (nested mode)`), the caller runs `## Nested walk` instead of a single `ensureRepo`, calling `ensureRepo(leaf, mode)` per leaf at the leaf's CWD.

## Node tree (nested mode)

A `repos[]` entry that declares **≥2 roots resolving to ≥2 distinct leaf homes** is expanded into a **node tree** instead of a single `ensureRepo` run. `buildNodeTree(entry)`:

- **Leaf** — one declared root, located at its **leaf home** (the `repo-layout` skill `## Leaf-home derivation`). A leaf has its own source → narrative + domain.
- **Branch** — a directory (relative to the entry's `path`) that is a proper ancestor of **≥2** leaf homes and is not itself a leaf home. No own source → rollup only (memory + architecture.md).
- **Root node** — the entry's `path`. Always a rollup node. If `path` is also a declared root (own source at the root) it is additionally a leaf.
- **Collapse** — a directory that is the ancestor of exactly **one** leaf is NOT a node; that leaf attaches to the nearest branch/root above it.

A `repos[]` entry resolving to **≤1** leaf home (or with `roots` omitted) is **not** expanded — it runs the single `ensureRepo` path unchanged.

`buildNodeTree` prints the resolved tree (leaves, branches, collapses, direct-child sets) for the audit trail before any write.

## Output root (nested mode)

Spawned sub-agents resolve relative paths against the **session root**; the Agent tool has **no per-sub-agent CWD switch**. So the nested walk cannot place output by changing CWD — it directs each writer by **path** instead.

Every runtime writer the nested walk drives — the crew (`project-overview`, `project-explorer`, `project-update`) and the rollup agents (`wiki-bootstrapper`, `wiki-architect`) — accepts an optional **`output_root`** in its dispatch prompt:

- **Provided** → the writer writes its tree under `<output_root>/docs/…` and runs its idempotency / pre-flight check against `<output_root>/docs/…` (NOT bare `docs/`). Scan `<path>` and `file:line` citations are unaffected; `output_root` changes only WHERE the tree is written and checked.
- **Absent** → today's behavior exactly: bare `docs/` of the working directory, byte-identical to pre-nested runs.

`output_root` is a session-root-relative (or absolute) directory. The nested walk sets `output_root = <node home>` for every node it drives. It is purely additive and only ever set by the nested orchestrator.

## Nested walk

For an entry expanded into a node tree, the walk replaces the single `ensureRepo` call:

1. **Leaves first.** For each leaf, run `ensureRepo(leaf, mode)` by dispatching the crew **agent directly** (`project-overview` then `project-explorer` for bootstrap; `project-update` for enhance) — not the bare slash command, which has no `output_root` arg — with **`output_root` = the leaf home** (per `## Output root (nested mode)`), scan `<path>` = the leaf home, and the locked skill-reload instruction. The `repo-layout` leaf match scopes each run to that one root; `## Leaf-scope confinement (nested mode)` keeps sibling-root changes out of scope. Leaves are therefore independent and MAY fan out in parallel — each writes only its own `docs/`.
2. **Branches + root, deepest-first.** For each rollup node (deeper branches before shallower; root last), dispatching the rollup agent with **`output_root` = the node home** (per `## Output root (nested mode)`):
   - run the `wiki-bootstrapper` over the node's **direct children** → writes `<node>/docs/memory/`.
   - **enhance only:** also run the `wiki-architect` over the node's direct children → writes `<node>/docs/architecture.md`.

   A rollup node reads each direct child's four inputs (`docs/architecture.md`, `docs/narrative/`, `docs/domain/`, `docs/memory/`). A **leaf** child contributes narrative + domain; a **branch** child contributes architecture.md + memory. Missing trees are tolerated (the existing four-input rule in `## After per-repo work — rollup hand-off`). Rollup recursion is bottom-up: a branch summarizes its leaves; the root summarizes branch memories + direct leaves, linking (never copying) per-child memory.

## Dirtiness (enhance refresh only)

A nested `/wiki:enhance` runs `/project:update` on every leaf and the rollup agents (`wiki-bootstrapper` then `wiki-architect`) at every branch and the root node — it does **not** pre-compute a dirty set. Correctness and the byte-perfect idempotent run come from **downstream idempotency**, applied per node:

- `/project:update` on an unchanged leaf emits the locked `No changes detected. 0 files written.` and writes nothing (the `project-update` skill `## Idempotency exit`).
- `wiki-bootstrapper` is append-only + dedup; `wiki-architect` preserves human fences and writes only changed bytes. A rollup over unchanged children writes **zero** bytes.

Consequences: a **first** enhance authors `docs/architecture.md` at every rollup node (bootstrap created only `docs/memory/`); editing one leaf rewrites that leaf and its ancestor rollups only; untouched leaves and untouched rollups write nothing. No node is skipped at the agent level — skipping is unnecessary because every unchanged write is a byte-compare no-op.

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

**Nested mode.** When a `repos[]` entry was expanded into a node tree (`## Node tree (nested mode)`), its per-node rollups (`## Nested walk` step 2) already produced `docs/memory/` (+ architecture.md on enhance) at every branch and at the entry's root node. In **single-repo mode** the entry's root node IS the scan root, so its rollup IS the root `docs/memory/` rollup — there is no separate cross-repo rollup; this hand-off is a no-op beyond confirming the root-node memory exists. In **multi-repo mode**, each repo entry's tree rolls up internally first, then the cross-repo scan root rolls up the repo entries as today (each repo contributes its root-node four inputs).

## Invariants

- **Gate-free.** No `APPROVE` anywhere. Safety net is the downstream write paths'
  append-only + dedup + fence rules.
- **Local paths only.** Refuse `^https?://` / `^git@` at the command layer.
- **No auto-commit.** Leave all writes as working-tree changes.
- **Confinement is delegated.** This skill writes nothing; each downstream agent enforces
  its own write confinement (`wiki-memory` → `docs/memory/` trees; `wiki-architecture` →
  `docs/architecture.md`; crew `project:*` → narrative/domain).
