---
name: repo-layout
description: Scan-scope contract for the wiki crew - resolves code roots, excludes, BC labels from repo-layout.md, and owns the built-in scan filters and read discipline.
version: 1
consumed_by: project-explorer agent, project-overview agent, project-update agent, wiki:bootstrap command, wiki:enhance command
---

## Purpose

The single source of truth for one question: **which folders of a repo are codebase worth exploring, and how much of each file lands in context?** It defines an opt-in central manifest, `repo-layout.md`, declaring per-repo code roots (an allowlist), extra excludes, and bounded-context labels. Crew agents load this skill and honour the declared scope; the project-tier wiki commands are its only writers. No manifest → built-in heuristics, byte-identical to runs before this skill existed. In nested mode a single declared root is addressable on its own (leaf-scope mode), so an orchestrator can fan a per-leaf crew run scoped to exactly that root.

This skill **owns** the built-in language whitelist + eight exclusion globs (`## Built-in scan filters`) and the never-read list (`## Read discipline`). It cites — never copies — the namespace/folder → BC mapping owned by the `project-explorer` skill (`### Grouping rule`). The filters live here so a reader that does not preload that skill still resolves them.

## The manifest: `repo-layout.md` at the scan root

One file named `repo-layout.md` at the **wiki scan root** — the directory the wiki is pointed at.

- **Multi-repo mode** (project-tier kit): the cross-repo root holding the depth-1 sibling repos plus `docs/` and `.claude/`. One entry per sibling repo.
- **Single-repo / monorepo mode** (standalone crew): the repo's own root. A single `repos:` entry with `path: .` whose `roots:` enumerate the sub-projects.

## Discovery (walk-up to the scan root)

Given the `<path>` a reader was invoked against, resolve deterministically. The walk-up is read-only and filesystem-only — no git, no remote, no cloning.

1. Check `<path>/repo-layout.md`, then each ancestor up to the drive root. The **first** hit is the scan root's manifest. Stop there.
2. In it, find the `repos[]` entry whose `path`, resolved relative to the manifest's own directory, equals `<path>`. In single-repo mode that entry is `path: .`.
3. **Match found** → apply that entry's scope (`## Scope resolution`).
4. **Leaf match (nested mode).** No `repos[]` entry matches, but `<path>` (relative to the scan root) equals a declared `roots[].path` **or that root's leaf home** (`## Leaf-home derivation`) → scope resolves to **that single root alone**: scan set = that subtree minus effective excludes, BC name = that root's `bc` label. This is *leaf-scope mode*; a whole-repo match in step 3 always wins over it.
5. **No manifest found** up to the drive root → emit the no-manifest advisory and use built-in heuristics.
6. **Manifest found, no matching entry** → emit the not-declared advisory and use built-in heuristics for that repo.

## Leaf-home derivation

A declared root's **leaf home** is where that root's nested wiki (`docs/`) lives — the project folder, not the source folder. Take the root's `path` and truncate immediately **before** the first segment named `src`; the remaining prefix is the leaf home. No `src` segment → the leaf home is the full root path.

Examples: `apps/web-client/src` → `apps/web-client`; `services/agent-service/src/asknanci_agent` → `services/agent-service`; `contracts/openapi` → `contracts/openapi`.

Leaf homes resolve relative to the owning `repos[].path`, then relative to the scan root. `wiki-orchestration`'s `buildNodeTree` cites this rule.

## Schema (schema: 1)

```yaml
---
schema: 1
defaults:
  exclude:                 # EXTENDS the built-in 8 globs (union); never replaces them
    - "**/vendor/**"
    - "**/target/**"
    - "**/.venv/**"
repos:
  - path: repoA            # directory relative to the scan root; "." in single-repo mode
    stack: dotnet          # optional hint: which DDD signal set (dotnet first-class, else best-effort)
    roots:                 # ALLOWLIST: only these subtrees are scanned
      - { path: src/Ordering, bc: Ordering }
      - { path: src/Billing,  bc: Billing }
    exclude: ["**/Migrations/**"]   # optional, repo-scoped, additive
  - path: repoB
    stack: node
    roots:
      - { path: packages/api, bc: Api }
      - { path: packages/web, bc: Web }
  - path: repoC            # an entry MAY omit `roots` -> "whole repo minus excludes"
    stack: go              # use this form to add excludes / pin a stack without enumerating roots
---
<!-- human:begin notes -->
Free-form human overrides / rationale. Preserved byte-for-byte across regeneration.
<!-- human:end -->
```

- `schema` — integer version. v1 is the only version.
- `defaults.exclude` — globs unioned into every repo's effective excludes.
- `repos[].path` — directory relative to the scan root; `.` is the scan root itself.
- `repos[].stack` — optional hint selecting the DDD signal set (`dotnet` first-class, others best-effort). Absent → inferred as today.
- `repos[].roots` — **strict allowlist** of subtrees, each `{ path: <repo-relative dir>, bc: <bounded-context label> }`. The `bc` label **pins** the BC name for that root, overriding the inferred namespace token from `project-explorer`'s `### Grouping rule`.
- `repos[].roots` omitted → declared but unbounded: whole repo minus effective excludes.
- `repos[].exclude` — repo-scoped globs, unioned into that repo's effective excludes.

The body below the frontmatter is human-owned prose inside `<!-- human:begin --> ... <!-- human:end -->` fences, preserved byte-for-byte — the same rule as `docs/narrative/` and `docs/domain/`.

## Built-in scan filters

Canonical single source of truth for "what counts as first-class source". The `project-explorer` skill `### Small-repo fallback detection` cites this section rather than restating it.

- **Language whitelist:** `*.cs`, `*.fs`, `*.vb`, `*.ts`, `*.js`, `*.py`, `*.java`, `*.go`.
- **Built-in exclusion globs (the "built-in 8"):** `**/bin/**`, `**/obj/**`, `**/node_modules/**`, `**/dist/**`, `**/*Tests/**`, `**/*.Tests/**`, `**/*.generated.*`, `**/*Designer.cs`.

Files match the whitelist **after** the exclusion globs, so markdown / config / generated files never count. The set is fixed: `defaults.exclude` and `repos[].exclude` union into it, and `## Read discipline` layers on top, but neither shrinks it and neither moves the small-repo fallback count.

## Scope resolution

For the matched `repos[]` entry:

1. **Effective excludes** = the built-in 8 (`## Built-in scan filters`) ∪ `defaults.exclude` ∪ this entry's `exclude`. Union only; the built-in set is never shrunk.
2. **`roots` present** → scan set = the declared subtrees (relative to the entry's `path`) − effective excludes. Everything outside them is **not scanned**.
3. **`roots` absent** → scan set = the whole repo at the entry's `path` − effective excludes.
4. A scanned root carrying a `bc` label names its bounded context with that label verbatim, overriding both the namespace-token inference **and the small-repo `module-map` fallback token** — a pinned root that triggers the fallback names its single output folder with the `bc` label, never `module-map`. Roots without a label, and the whole-repo case, fall back to `project-explorer`'s `### Grouping rule`, using `module-map` when the fallback fires.

## Read discipline

Scope decides **which folders** are in play; this decides **how much of an in-scope file lands in context**. It binds every crew agent that loads this skill.

### Never-read globs

Never `Read` a path matching any of these, even when it survives the effective excludes and even when a `Glob` surfaced it. Resolve the fact from the source file that produced it instead.

`**/bin/**`, `**/obj/**`, `**/node_modules/**`, `**/dist/**`, `**/.venv/**`, `**/__pycache__/**`, `**/coverage/**`, `**/*.deps.json`, `**/*.runtimeconfig.json`, `**/*.lock`, `**/*-lock.json`, `**/*.min.*`, `**/*.map`, `**/*.generated.*`, `**/*Designer.cs`.

This governs `Read` only. It does **not** change `## Built-in scan filters`, so it does not move the small-repo fallback count.

### Grep before Read

1. **Signatures come from `Grep`, not `Read`.** Endpoint routes, handler types, aggregate roots, event records, worker registrations — locate each with one `Grep` carrying `-n` and `-C 3`. That yields the `file:line` citation and enough surrounding text for the prose. Open the body only when the contract you must write cannot be derived from the hit.
2. **Bound every large file.** A file over **400 lines** is read with `offset` / `limit` centred on the `Grep` hit — never whole. Two bounded reads beat one unbounded one.
3. **Generated contracts are grepped, never read.** OpenAPI / Swagger documents, protobuf descriptors, lockfiles, and `*.g.*` output are surveyed with `Grep` for the paths or symbols you need. A 2,000-line contract file is never a `Read` target.
4. **Read each path at most once per run.** The first result is still in context.
5. **Batch reads.** Issue the reads a step needs in one request rather than one per request.

### Why this is load-bearing

An agent's token cost is `requests × context size`, and context only grows within a run. One unbounded read of a build artifact or a generated contract inflates every later request of that agent — so the never-read list is a hard rule, not a preference.

## Precision instrument + discovery safety net

The manifest is the **precision instrument** for known scope; the built-in whitelist + 8 globs remain the **discovery safety net**. They compose:

- A strict allowlist suppresses **known** noise — undeclared dirs are out of steady-state scope.
- The safety net guarantees **new** code still surfaces: an undeclared directory containing at least one whitelisted file not matched by the effective excludes is **provisionally scanned this run and loudly flagged** (the new-root advisory). Never silently skipped.
- An undeclared directory that is pure noise — every file excluded, or no whitelisted source — is ignored. That is the noise win.

The allowlist is strict for known noise and can never blind the agent to newly added code.

## Leaf-scope confinement (nested mode)

In **leaf-scope mode** the safety net narrows: a source-bearing directory under **another** declared root — of this or any `repos[]` entry — is out of this leaf's scope and is **not** a new-root candidate; it belongs to its own node. Only a directory declared under **no** root anywhere remains a candidate, and it bubbles to the writer (`/wiki:enhance`), never to a leaf-scoped run.

So a leaf-scoped `/project:update` stays confined to its own root: sibling-root changes are never absorbed into this leaf's `docs/domain/` and never flagged as a new root by it.

## Reconciliation

Diffs the manifest against the filesystem, in two halves:

- **Reader half** (crew agents — they never write the manifest): undeclared source-bearing dir → provisionally scan it this run and emit the new-root advisory. Declared path gone from disk → emit the stale advisory and do nothing further.
- **Writer half** (`/wiki:bootstrap`, `/wiki:enhance`): persist each flagged candidate as a draft `roots` entry (or a new `repos[]` entry for a brand-new repo); leave stale declared paths in place, flagged and never auto-deleted; preserve human-fenced content byte-for-byte.

## Ownership (single writer, many readers)

```
WRITER (exactly one):  /wiki:bootstrap drafts repo-layout.md  ->  /wiki:enhance reconciles it
READERS (never write): project-explorer · project-overview · project-update · wiki-orchestration
```

One writer means no concurrent-write race on the central file, and crew agents stay strictly read-only on it — preserving the "each command writes only its own output tree" invariant. A standalone single-repo user either hand-authors `repo-layout.md` at the repo root or runs with no manifest.

## Drafting heuristics (writer only)

Writer-only. Every crew agent that preloads this skill is **read-only** on `repo-layout.md` (`## Ownership (single writer, many readers)`), so these heuristics live in `./references/drafting.md`. The writer — the project-tier wiki kit — reads that file when it drafts or reconciles the manifest.

## Backward compatibility

No `repo-layout.md` found by the walk-up, or no entry for the current repo → every consumer uses built-in heuristics and produces **byte-identical** output to runs before this skill existed (modulo timestamps). Purely opt-in: a workspace that never adds a manifest sees zero behavioral change.

**Nested-mode exception.** A *matching* `repos[]` entry resolving to ≥2 leaf homes triggers nested-mode regeneration (the `wiki-orchestration` skill `## Node tree (nested mode)`): a unified wiki an earlier flat run produced is rebuilt as a tree. This is the one documented departure from "byte-identical when not asked for" — opt-in via the manifest's own structure, and an existing flat `docs/` must be cleared to adopt the tree form.

## Advisory literals

One line each, never blocking. Emit the matching literal verbatim:

- No `repo-layout.md` found at the scan root:
  ```
  No repo-layout.md found at the scan root - using built-in heuristics. Run /wiki:bootstrap to generate one.
  ```
- Repo present on disk but not declared in the manifest:
  ```
  <repo> not declared in repo-layout.md - using built-in heuristics for this repo.
  ```
- New source-bearing dir discovered during reconciliation:
  ```
  NEW root candidate: <dir> (contains source, not in repo-layout.md) - provisionally scanned; run /wiki:enhance to persist.
  ```
- Declared path no longer exists:
  ```
  STALE: repo-layout.md declares <path> which no longer exists - left in manifest; review.
  ```
