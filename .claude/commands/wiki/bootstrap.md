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
6. **Ask the two questions** (orchestration skill, `## Two-question protocol`): scope
   (all/some, with the suggested first batch) and execution (one agent / sub-agent per repo).
7. **Per chosen repo → `ensureRepo(repo, "skip")`.** Empty repos get `/project:overview`
   then `/project:explore`; existing repos are **skipped** (bootstrap never refreshes).
   Sequential or parallel sub-agents per the execution answer.
8. **Roll up to root `docs/memory/`.** Hand off to the `wiki-bootstrapper`: summarize-and-link
   the **four** inputs per repo (`docs/architecture.md`, `docs/narrative/`, `docs/domain/`,
   `docs/memory/`) into root `docs/memory/`. Per the `wiki-memory` skill the rollup is
   create-or-additive and **ungated** (no gate) — safety net is append-only + dedup +
   fence.
9. **Missing-input advisories** (one line each, never block): absent `docs/architecture.md`;
   narrative-only / domain-only repo; zero qualifying repos; unavailable `project:*`.
10. **No auto-commit.** Leave new/modified files as working-tree changes.
