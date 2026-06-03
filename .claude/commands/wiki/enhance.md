---
description: Non-interactive full sync — refresh existing repo wikis, bootstrap missing ones, roll up docs/memory/, and auto-author docs/architecture.md
argument-hint: [root-path]
---

Full-sync the root-tier LLM-Wiki across all sibling repos in one non-interactive pass.
Existing repo wikis are refreshed, missing ones are bootstrapped, the root `docs/memory/`
rollup is updated, and `docs/architecture.md` is (re)authored. Gate-free; writes are left as
uncommitted working-tree changes.

`[root-path]` is **optional** (default: current working directory). Local filesystem paths
only.

## Procedure

1. **Parse `[root-path]`** (default cwd). **Local-paths-only guard:** refuse `^https?://` /
   `^git@` with the one-line message and stop:
   ```
   Remote URLs are not supported in v1. Pass a local filesystem path.
   ```
2. **Resolve to absolute** (`Resolve-Path`).
3. **Load skills.** Reload `.claude/skills/wiki-orchestration/SKILL.md` (per-repo core),
   then `.claude/skills/wiki-memory/SKILL.md` (rollup write), then
   `.claude/skills/wiki-architecture/SKILL.md` (architecture write). Stop-before-write and
   report if any is missing/malformed when its write path is reached.
4. **Refuse only when nothing to do.** If **no** depth-1 repo has narrative/domain AND no
   repo is bootstrappable (empty), emit the zero-repos advisory and stop. Otherwise proceed.
5. **Discover repos** (orchestration skill): depth-1 children except `docs/` and `.claude/`;
   classify empty/existing.
6. **Per repo (all repos, non-interactive):**
   - **empty →** `ensureRepo`: `/project:overview <repo>` then `/project:explore <repo>`.
   - **existing →** `/project:update <repo>` (refresh narrative + domain).
   Sequential, or sub-agent per repo at the implementer's discretion (each writes only its
   own subtree — no worktree needed).
7. **Roll up** to root `docs/memory/` via the `wiki-bootstrapper`: summarize-and-link the
   four inputs per repo (`docs/architecture.md`, `docs/narrative/`, `docs/domain/`,
   `docs/memory/`). Ungated.
8. **Author `docs/architecture.md`** via the `wiki-architect` agent (full regen, human
   fences preserved). Ungated.
9. **Advisories** (one line each, never block): absent inputs, narrative-only/domain-only
   repo, unavailable `project:*`, empty context map.
10. **No auto-commit.**
