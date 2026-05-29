---
description: Bootstrap docs/memory/ LLM-Wiki from docs/architecture.md + repos' docs/narrative and docs/domain
argument-hint: [root-path]
---

Bootstrap (or additively refresh) the root-tier LLM-Wiki under `docs/memory/` of the
system root. The wiki **summarizes and links** the knowledge already produced per repo —
the root `docs/architecture.md` plus every sibling repo's `docs/narrative/` and
`docs/domain/` — it never duplicates source bodies. Every write is gated behind the
exact-case token `APPROVE` and confined to `docs/memory/`.

`[root-path]` is **optional**. It is the system root that contains the sibling repos and
the root `docs/`. When omitted, the current working directory is used. Only local
filesystem paths are accepted.

## Procedure

1. **Parse `[root-path]` (optional).** If omitted, use the current working directory as
   the system root.

2. **Local-paths-only guard.** If `[root-path]` matches `^https?://` or `^git@`, refuse
   with the literal one-line message and **stop** — do not discover, do not spawn the
   agent, do not write:

   ```
   Remote URLs are not supported in v1. Pass a local filesystem path.
   ```

   (mirroring `.claude-user/commands/project/explore.md`.)

3. **Resolve to absolute.** Resolve `[root-path]` to an absolute filesystem path. In
   PowerShell: `Resolve-Path $rootPath`.

4. **Input discovery (read-only).** All discovery is structure-based, not name-prefix-based:
   - **Repos:** enumerate the **depth-1 child directories** of `[root-path]` only (do not
     recurse into nested sub-repos). A child **qualifies as a repo iff** it contains
     `docs/narrative/` **OR** `docs/domain/`. A child with neither tree does **not**
     qualify and produces no topic.
   - **Ignore** the root's own `docs/` directory and the `.claude/` directory — they
     are never treated as repos even though they sit at depth 1.
   - **Architecture file:** locate the root `docs/architecture.md`. It is an independent,
     optional input — its absence does not block the run.

     Example (PowerShell):

     ```powershell
     Get-ChildItem -Path $rootPath -Directory `
       | Where-Object { $_.Name -notin @('docs', '.claude') } `
       | Where-Object {
           (Test-Path (Join-Path $_.FullName 'docs/narrative')) -or `
           (Test-Path (Join-Path $_.FullName 'docs/domain'))
         }
     ```

5. **Forward-dependency stop-condition (write-discipline manual).** The write rules
   (summarize-and-link, additive create-or-append, provenance, fence protection) are
   **not** inlined here. They live in `.claude/skills/wiki-memory/SKILL.md`.
   Reload that skill **before any write**. If it is **missing or malformed**
   (cannot be read, YAML frontmatter does not parse, or required body sections are absent),
   **stop before writing anything** to `docs/memory/` and report that the `wiki-memory`
   skill is missing/malformed. Do not write a partial topic file against an undefined
   contract (mirroring the `project-explorer` stop-conditions).

6. **Spawn the worker (primary shape).** Spawn the `wiki-bootstrapper` subagent via the
   `Agent` tool with `description: "wiki-bootstrapper: bootstrap docs/memory/"` and a
   `prompt` containing: the resolved absolute `[root-path]`, the discovered qualifying-repo
   set, the located (or absent) `docs/architecture.md`, and the instruction that the agent
   must reload `.claude/skills/wiki-memory/SKILL.md` before any other action. This
   mirrors the `explore.md` → `project-explorer` pattern.

   **Inline fallback.** If the worker agent is unavailable, the command performs the work
   itself with identical behaviour and guarantees: reload the skill first (honoring step 5),
   then build the topics and write directly.

7. **Build topics — summarize-and-link (no verbatim copies).** Shape every topic against
   `.claude/templates/memory-topic.md`: one `# <Topic title>` heading, exactly one
   one-line summary, a `## Sources` section, and a `## Entries` section. Produce:
   - **One per-BC topic per bounded context** discovered across the repos. Filename is the
     lowercased BC slug (e.g. `docs/memory/billing.md`, `docs/memory/catalog.md`); the
     topic title is the BC name (e.g. `# Billing`). For each BC, `## Sources` links the
     matching `docs/architecture.md` section **and** that BC's narrative file **and** that
     BC's domain file — but **only the trees that actually exist** (see step 9).
   - **One cross-cutting topic** derived from `docs/architecture.md` (e.g.
     `docs/memory/architecture.md`), summarizing the cross-repo relationships (e.g.
     Catalog → Billing) and linking the `docs/architecture.md` section(s). Produce this
     topic **only when `docs/architecture.md` exists** — never fabricate it from an absent
     source.

   The summary is a paraphrase, never a lifted multi-line block. Do not paste the Mermaid
   diagram, full aggregate tables, or any run of ≥ 2 consecutive non-trivial source lines.
   Links use stable repo-relative paths under the shared root (e.g. from
   `docs/memory/billing.md` the narrative link is
   `../../repo-a/docs/narrative/architecture.md`). Link only to source files that exist;
   never invent a link to a non-existent file.

8. **APPROVE preview (before any write).** Present a preview that lists, **per proposed
   topic file**:
   1. the target **repo-relative path** (e.g. `docs/memory/billing.md`);
   2. the **create-vs-append disposition** (`create` if the file is absent, `append` if it
      already exists);
   3. the **topic title + one-line summary**;
   4. the **full `## Sources` link list** for that topic;
   5. an **entry/append count** (how many `## Entries` sub-blocks or `## Sources` links this
      run would add).

   The preview **must not** contain the full body of any topic file. No file under
   `docs/memory/` is written at preview time.

   Require the operator to type the **exact-case** token `APPROVE`. Any other response —
   including `approve`, `Approve`, `yes`, `ok`, empty input, or edit feedback such as
   "link catalog to repo-b only" — is treated as an **edit request**: write nothing,
   incorporate the feedback, and **re-prompt**. Never silently exit, never write on a
   non-`APPROVE` response.

9. **Write — additive, confined to `docs/memory/`.** On exact-case `APPROVE`, the write is
   **create-or-additive only**:
   - **Create** missing topic files from the template shape.
   - For an **existing** topic file: **ADD** missing `## Sources` links (appended after the
     existing links, preserving their original order) and **ADD** new `## Entries`
     sub-blocks. **Never** rewrite an existing summary line, **never** reorder or remove an
     existing `## Sources` link, and **never** touch text inside a
     `<!-- human:begin --> ... <!-- human:end -->` fence (it survives byte-for-byte).
   - Every write lands **only** under `docs/memory/`. The command **never** writes to
     `docs/architecture.md`, any repo's `docs/narrative/` or `docs/domain/`, repo source,
     or `.claude/`.

10. **Missing-input advisories (noted, not fabricated).** Each input is independent; a repo
    is included on narrative **OR** domain. Emit a **one-line** advisory per missing/partial
    input and **continue** — never block, never fabricate a link to a missing tree.
    Use these stable phrasings:
    - **Absent `docs/architecture.md`:** `Advisory: docs/architecture.md not found at the root — noted, not fabricated; continuing with the repo inputs that exist.`
    - **Narrative-only repo `<repo>`:** `Advisory: <repo> has no docs/domain/ — noted, not fabricated; linking its narrative only.`
    - **Domain-only repo `<repo>`:** `Advisory: <repo> has no docs/narrative/ — noted, not fabricated; linking its domain only.`
    - **Zero qualifying repos:** `Advisory: no qualifying repos found (no depth-1 child has docs/narrative/ or docs/domain/) — noted, not fabricated; not inventing any per-BC topic.`

11. **No auto-commit.** After the write, do **not** run `git add` or `git commit`. The new
    or modified `docs/memory/*.md` files are left as uncommitted working-tree changes for
    the operator to review and commit.
