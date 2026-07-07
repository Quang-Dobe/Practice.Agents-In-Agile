---
name: repo-layout
description: Cross-cutting scan-scope contract. Reads the central repo-layout.md manifest at the wiki scan root and resolves each repo's allowlisted code roots, excludes, and bounded-context labels. Loaded by the project-explorer / project-overview / project-update crew agents and the wiki orchestration core. Absent manifest means today's heuristics (backward compatible); in nested mode also resolves a single declared root as an addressable leaf.
version: 1
consumed_by: project-explorer agent, project-overview agent, project-update agent, wiki:bootstrap command, wiki:enhance command
---

## Purpose

This skill is the single source of truth for one question: **which folders of a repo are codebase worth exploring?** It defines an opt-in central manifest, `repo-layout.md`, that a workspace places at its wiki scan root to declare per-repo code roots (an allowlist), extra excludes, and bounded-context labels. The crew agents load this skill and honor the declared scope; the project-tier wiki commands are the only writers. When no manifest is present, every consumer falls back to today's built-in heuristics and behaves byte-identically to runs before this skill existed. In nested mode it also makes a single declared root addressable on its own (leaf-scope mode), so an orchestrator can fan a per-leaf crew run scoped to exactly that root.

The skill cites — never copies — two contracts owned by the `project-explorer` skill: the built-in language whitelist + eight exclusion globs (`### Small-repo fallback detection`) and the namespace/folder → BC mapping (`### Grouping rule`). Those remain the single source of truth for "what counts as first-class source" and "how a path maps to a BC"; this skill layers scope selection on top.

## The manifest: `repo-layout.md` at the scan root

**Unifying rule — the scan root.** The manifest is one file named `repo-layout.md` living at the **wiki scan root**: the directory the wiki is pointed at.

- **Multi-repo mode** (project-tier kit): the cross-repo root that holds the depth-1 sibling repos plus `docs/` and `.claude/`. The manifest declares one entry per sibling repo.
- **Single-repo / monorepo mode** (standalone crew): the repo's own root. The manifest carries a single `repos:` entry with `path: .` whose `roots:` enumerate the sub-projects inside that one repo.

One rule, both modes.

## Discovery (walk-up to the scan root)

A reader resolves the manifest deterministically, given the `<path>` it was invoked against:

1. Check `<path>/repo-layout.md`, then each ancestor directory up to and including the drive root. The **first** `repo-layout.md` found is the scan root's manifest. Stop at the first hit.
2. In that manifest, find the `repos[]` entry whose `path` — resolved relative to the scan root (the manifest's own directory) — equals `<path>`. In single-repo mode the matching entry is `path: .`.
3. **Match found** → apply that entry's scope (see `## Scope resolution`).
4. **Leaf match (nested mode).** No `repos[]` entry's `path` equals `<path>`, but `<path>` (relative to the scan root) equals a declared `roots[].path` **or that root's leaf home** (see `## Leaf-home derivation`) of some `repos[]` entry → resolve scope to **that single root alone**: scan set = that one root subtree minus effective excludes; bounded-context name = that root's `bc` label. This is *leaf-scope mode*. The whole-repo `repos[]` match (step 3) always takes precedence; leaf match is consulted only when no whole-repo entry matches.
5. **No `repo-layout.md` found** up to the drive root → emit the no-manifest advisory (`## Advisory literals`) and use built-in heuristics.
6. **Manifest found but no matching `repos[]` entry** for `<path>` → emit the not-declared advisory and use built-in heuristics for that repo.

The walk-up is read-only and filesystem-only — no git, no remote, no cloning.

## Leaf-home derivation

A declared root's **leaf home** is the directory where that root's nested wiki (`docs/`) lives — the project folder, not the source folder:

- Take the root's `path`. Truncate it immediately **before** the first path segment named `src`. The remaining prefix is the leaf home.
- If the path has no `src` segment, the leaf home is the full root path.

Examples: `apps/web-client/src` → `apps/web-client`; `services/agent-service/src/asknanci_agent` → `services/agent-service`; `contracts/openapi` → `contracts/openapi`.

Leaf homes are resolved relative to the owning `repos[].path` (the repo root), then relative to the scan root. This is the single source of truth for the rule; `wiki-orchestration`'s `buildNodeTree` cites it by reference.

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

**Field semantics.**

- `schema` — integer schema version. v1 is the only version.
- `defaults.exclude` — optional list of globs unioned into every repo's effective excludes.
- `repos[].path` — directory relative to the scan root. `.` means the scan root itself (single-repo / monorepo mode).
- `repos[].stack` — optional hint selecting the DDD signal set (`dotnet` first-class; others best-effort). Absent → inferred as today.
- `repos[].roots` — **strict allowlist** of subtrees to scan. Each item is `{ path: <repo-relative dir>, bc: <bounded-context label> }`. The `bc` label **pins** the bounded-context name for that root, overriding the inferred namespace-token name from `project-explorer`'s `### Grouping rule`.
- `repos[].roots` omitted → the repo is declared but unbounded: scope = whole repo minus effective excludes (today's behavior, optionally tightened by extra excludes / a stack hint).
- `repos[].exclude` — optional repo-scoped globs, unioned into that repo's effective excludes.

The body below the frontmatter is human-owned prose inside `<!-- human:begin --> ... <!-- human:end -->` fences. Writers preserve fenced content byte-for-byte (same rule as `docs/narrative/` and `docs/domain/`).

## Scope resolution

For the matched `repos[]` entry, a reader computes scope as:

1. **Effective excludes** = the built-in 8 globs (from the `project-explorer` skill `### Small-repo fallback detection`) ∪ `defaults.exclude` ∪ this entry's `exclude`. Union only — the built-in set is never shrunk.
2. **If `roots` present** → scan set = (the declared root subtrees, resolved relative to the entry's `path`) − (effective excludes). Everything outside the declared roots is **not scanned** (the allowlist).
3. **If `roots` absent** → scan set = (the whole repo at the entry's `path`) − (effective excludes). This is today's behavior tightened only by any extra excludes.
4. For each scanned root carrying a `bc` label, the bounded-context name for signals under that root is the `bc` label verbatim (it overrides the namespace-token inference **and the small-repo `module-map` fallback token — a pinned root that triggers the small-repo fallback names its single output folder with the `bc` label, never `module-map`**). Roots without a `bc` label, and the whole-repo case, fall back to `project-explorer`'s `### Grouping rule` for naming, and use `module-map` when the small-repo fallback fires.

## Precision instrument + discovery safety net

The manifest is the **precision instrument** for known scope; the built-in language whitelist + 8 exclusion globs remain the **discovery safety net**. They compose:

- A strict allowlist suppresses **known** noise — undeclared dirs are out of steady-state scope.
- The safety net guarantees **new** code still surfaces. An undeclared directory that **contains source** — at least one file passing the built-in language whitelist and not matched by the effective excludes — is **provisionally scanned this run and loudly flagged** (the new-root advisory in `## Advisory literals`). It is never silently skipped.
- An undeclared directory that is **pure noise** — every file matched by the effective excludes, or no whitelisted source at all — is ignored. This is the noise win.

Consequence: the allowlist is strict for known noise but can never blind the agent to newly added code.

## Leaf-scope confinement (nested mode)

When a reader resolves **leaf-scope mode** (the `## Discovery` leaf match), the discovery safety net is narrowed: a source-bearing directory under **another** declared root — of this or any `repos[]` entry — is **out of this leaf's scope and is NOT a new-root candidate**. It is owned by its own node. Only a source-bearing directory declared under **no** root anywhere in the manifest remains a new-root candidate, and such a candidate bubbles to the writer / reconciliation (`/wiki:enhance`), never to a leaf-scoped run.

Consequence: a leaf-scoped `/project:update` stays confined to its own root. Changes under sibling roots are out-of-scope — never absorbed into this leaf's `docs/domain/`, never flagged as a new root by this leaf.

## Reconciliation

Reconciliation diffs the manifest against the filesystem. It has a reader half and a writer half.

- **Reader half** (crew agents — they do NOT write the manifest):
  - Undeclared source-bearing dir → provisionally scan it this run + emit the new-root advisory.
  - Declared path that no longer exists on disk → emit the stale advisory; do not act on it further.
- **Writer half** (`/wiki:bootstrap`, `/wiki:enhance` — see `## Ownership`):
  - Persist each flagged new-root candidate as a draft `roots` entry (or a new `repos[]` entry for a brand-new repo).
  - Leave stale declared paths in the manifest (flagged, never auto-deleted) and preserve human-fenced content byte-for-byte.

## Ownership (single writer, many readers)

```
WRITER (exactly one):  /wiki:bootstrap drafts repo-layout.md  ->  /wiki:enhance reconciles it
READERS (never write): project-explorer · project-overview · project-update · wiki-orchestration
```

A single writer means no concurrent-write race on the central file. Crew agents are strictly read-only on the manifest, preserving the existing "each command writes only its own output tree" invariant. A standalone single-repo user who never runs the project-tier kit either hand-authors `repo-layout.md` at the repo root or runs with no manifest (built-in heuristics + the no-manifest advisory).

## Drafting heuristics (writer only)

When a writer drafts or extends the manifest, it infers `repos` / `roots` from signals that already exist and do not drift:

- `.gitignore` — what is **not** source (build output, deps, caches).
- Ecosystem manifests for where code roots **are**: `*.sln` / `*.csproj` (dotnet), `go.mod` (go), `package.json` workspaces (node), `pyproject.toml` / `setup.cfg` (python), `pom.xml` / `build.gradle` (java), `Cargo.toml` (rust).
- Top-level project/service folders (`src/<Project>`, `packages/*`, `apps/*`, `services/*`).

The writer prints the inferred layout for the audit trail and **proceeds in the same run** using the draft — no halt, no approval gate (preserves the domain-wiki pipeline's gate-free invariant). Each `bc` label is seeded from the project/namespace name; the human edits later inside the manifest's human fences.

## Backward compatibility

When no `repo-layout.md` is found by the walk-up, OR the manifest has no entry for the current repo, every consumer uses today's built-in heuristics and produces **byte-identical** output to runs before this skill existed (modulo timestamps). The feature is purely opt-in. A workspace that never adds a manifest sees zero behavioral change.

**Nested-mode exception.** A *matching* `repos[]` entry that resolves to ≥2 leaf homes triggers nested-mode regeneration (the `wiki-orchestration` skill `## Node tree (nested mode)`): a single unified wiki that an earlier flat run produced is rebuilt as a tree. This is the one documented departure from "byte-identical when not asked for" — it is opt-in via the manifest's own structure (declaring ≥2 roots), accepted per the nested-wiki design; an existing flat `docs/` must be cleared to adopt the tree form.

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
