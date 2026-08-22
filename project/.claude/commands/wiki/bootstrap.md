---
description: Orchestrate per-repo project:overview/explore (gap-fill) then roll up into root docs/memory/
argument-hint: [root-path]
---

Orchestrate gap-fill per-repo wiki bootstrapping across sibling repos, then roll up into
the root `docs/memory/`. For each chosen repo without a wiki, runs `/project:overview`
then `/project:explore`. For repos that already have a wiki, skips them (bootstrap is
gap-fill only). Then hands off to the `wiki-bootstrapper` to summarize-and-link four
inputs per repo into root `docs/memory/`. Gate-free; writes are left as uncommitted
working-tree changes.

`[root-path]` is **optional** (default: current working directory). Local filesystem paths
only.

## Procedure

1. **Parse `[root-path]` (optional).** If omitted, use the current working directory.
2. **Local-paths-only guard.** If `[root-path]` matches `^https?://` or `^git@`, refuse with
   the literal one-line message and **stop**:
   ```
   Remote URLs are not supported in v1. Pass a local filesystem path.
   ```
3. **Resolve to absolute.** PowerShell: `Resolve-Path $rootPath`.
4. **Load the orchestration core.** Reload `.claude/skills/wiki-orchestration/SKILL.md`. If
   missing/malformed, stop and report it (no partial orchestration against an undefined
   contract). Reload `.claude/skills/wiki-memory/SKILL.md` before any rollup write; if
   missing/malformed, stop before writing and report it.
5. **Discover repos (read-only).** Per the orchestration skill: depth-1 children except
   `docs/` and `.claude/`; classify each empty/existing.
6. **Draft `repo-layout.md` (writer — gap-fill only).** Reload `~/.claude/skills/repo-layout/SKILL.md`. If a `repo-layout.md` already exists at the resolved root, leave it untouched (it is the human-reviewed contract; only `/wiki:enhance` reconciles it). If it is absent, draft one per the `repo-layout` skill `## Drafting heuristics (writer only)`: infer one `repos[]` entry per discovered repo with `roots` seeded from `.gitignore` + ecosystem manifests, print the inferred layout for the audit trail, and write `repo-layout.md` at the root. Proceed in the same run (no gate). This is the only point in bootstrap that writes the manifest.
7. **Ask the two questions** (orchestration skill, `## Two-question protocol`): scope
   (all/some, with the suggested first batch) and execution (one agent / sub-agent per repo).
8. **Per chosen repo.** If the repo's manifest entry expands into a node tree (`wiki-orchestration` skill `## Node tree (nested mode)`), run the **nested walk** (`## Nested walk`) in `mode = "skip"`: bootstrap every empty leaf (`/project:overview` then `/project:explore`, each dispatched with `output_root = leaf home`), then build `docs/memory/` bottom-up at every branch and the root node via the `wiki-bootstrapper` (bootstrap does **not** author `references.md` — that is enhance's job). Otherwise run `ensureRepo(repo, "skip")` as today. Sequential or parallel sub-agents per the execution answer (leaves are independent — each writes only its own `docs/`).
9. **Roll up to root `docs/memory/`.** In **multi-repo mode**, hand off to the `wiki-bootstrapper` to summarize-and-link the four inputs per repo entry as today. In **single-repo nested mode**, the root-node rollup from step 8 already IS the root `docs/memory/` — do not double-roll; this step only confirms the root-node memory exists. Per the `wiki-memory` skill the rollup is create-or-additive and ungated.
10. **Missing-input advisories** (one line each, never block): absent `docs/references.md`;
   narrative-only / domain-only repo; zero qualifying repos; unavailable `project:*`.
11. **No auto-commit.** Leave new/modified files as working-tree changes.
