---
description: Non-interactive full sync — refresh existing repo wikis, bootstrap missing ones, roll up docs/memory/, and auto-author docs/references.md
argument-hint: [root-path]
---

Full-sync the project-tier LLM-Wiki across all sibling repos in one non-interactive pass.
Existing repo wikis are refreshed, missing ones are bootstrapped, the root `docs/memory/`
rollup is updated, and `docs/references.md` is (re)authored. Gate-free; writes are left as
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
   report if any is missing/malformed when its write path is reached. **Not** the
   `wiki-diagram` skill — this command draws nothing; `/diagram:build` owns that and loads it
   itself.
4. **Refuse only when nothing to do.** If **no** depth-1 repo has narrative/domain AND no
   repo is bootstrappable (empty), emit the zero-repos advisory and stop. Otherwise proceed.
5. **Discover repos** (orchestration skill): depth-1 children except `docs/` and `.claude/`;
   classify empty/existing.
6. **Per repo (all repos, non-interactive).** If the repo's manifest entry expands into a node tree (`wiki-orchestration` skill `## Node tree (nested mode)`), run the **nested walk** in `mode = "refresh"` (`## Nested walk` + `## Dirtiness (enhance refresh only)`): run `/project:update` on each leaf dispatched with `output_root = leaf home`; then, deepest-first, run the `wiki-bootstrapper` + `wiki-architect` at every branch and the root node (downstream idempotency makes unchanged nodes a zero-byte no-op, and a first enhance authors the missing `docs/references.md`; `## Dirtiness (enhance refresh only)`). Untouched subtrees are not rewritten. Otherwise: empty repo → `ensureRepo` (`/project:overview` then `/project:explore`); existing repo → `/project:update <repo>`. Sequential or sub-agent per repo (each writes only its own subtree).
7. **Reconcile `repo-layout.md` (writer).** Reload `~/.claude/skills/repo-layout/SKILL.md`. After the per-repo runs, persist the new source-bearing dirs the crew flagged during their walks (as a new `roots` entry, or a new `repos[]` entry for a brand-new repo, seeded per `## Drafting heuristics (writer only)`); leave stale declared paths in place (flagged, never auto-deleted); preserve `<!-- human:begin --> ... <!-- human:end -->` content byte-for-byte. Apply the `repo-layout` skill `## Reconciliation`, `## Drafting heuristics (writer only)`, and `## Ownership (single writer, many readers)` sections. If no manifest exists, draft one exactly as `/wiki:bootstrap` does (`## Drafting heuristics (writer only)`). Print the reconciliation summary for the audit trail and proceed in the same run (no gate). This is the only point that writes the manifest. Nested mode does not change reconciliation: the manifest stays flat (`roots[]`), and the node tree is derived from it at read time — `repo-layout.md` is never rewritten with tree structure.
8. **Roll up to root `docs/memory/`.** In **multi-repo mode**, hand off to the `wiki-bootstrapper` over the repo entries as today. In **single-repo nested mode**, the root-node rollup from step 6 already produced/refreshed the root `docs/memory/` (a clean re-enhance writes zero bytes via downstream idempotency) — do not double-roll.
9. **Author `docs/references.md`.** In **multi-repo mode**, the `wiki-architect` authors the root `docs/references.md` over the repo entries as today (full regen, human fences preserved). In **single-repo nested mode**, the root-node `wiki-architect` run from step 6 already authored/refreshed the root `docs/references.md` — do not double-author. Ungated.
10. **Advisories** (one line each, never block): absent inputs, narrative-only/domain-only
   repo, unavailable `project:*`, empty context map.
11. **Recommend the diagram.** This command does not draw one. Drawing is `/diagram:build`, a separate
   command that reads `docs/references.md` and writes nothing else. Print this block verbatim, as a
   list — never collapsed onto one line, because the options are the point:

   ```
   Wiki updated. To draw it:

     /diagram:build

   Options:
     --effort low      request path, boundaries and their invariants. One render pass. (default)
     --effort medium   adds stores, model hosts, config keys and per-node detail.
     --effort high     adds the map's own arguments: the gaps it found, what it rejected.
     --html            also write a zoomable page next to the PNG.

   Examples:
     /diagram:build                        PNG only, low effort
     /diagram:build --html                 PNG + page
     /diagram:build --effort high --html   everything
   ```

   Skip the block only when `docs/references.md` was not authored on this run — with no map there is
   nothing to draw, and recommending a command that will refuse is noise.
