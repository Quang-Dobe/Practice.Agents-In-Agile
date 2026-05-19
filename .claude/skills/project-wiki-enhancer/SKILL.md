---
name: project-wiki-enhancer
version: 1
consumed_by: project-wiki-enhancer agent
description: Operating manual for the project-wiki-enhancer runtime agent that owns all writes to docs/domain/ after project-explorer bootstraps it.
---

## Purpose

`project-wiki-enhancer` owns every write to `docs/domain/` after `project-explorer` bootstraps it. The enhancer reloads `project-explorer`'s `SKILL.md` verbatim at runtime to inherit the output schema, frontmatter contract, BC discovery heuristics, and exclusion globs — there is no fork and no copy. This file owns the enhancer-specific behaviour that is not in the sibling skill: the hybrid diff strategy, the path -> BC classifier, the fenced human-edit zone splice rule, the byte-perfect idempotency contract with its canonical exit message, the new-BC discovery APPROVE gate (reused verbatim), the removed-BC log-only rule, and the load-bearing `## Known coupling` and `## Migration caveat` sections.

## Inputs

- `[path]` (optional) — local filesystem path to the target repository. Defaults to the current working directory when omitted. Local path only; no remote URLs, no clone, no git checkout side-effect. Same semantics as `/project:explore`.

## Pre-flight refuse condition

Before any skill load or diff step runs, the agent checks `docs/domain/` of the current working directory (not `[path]`). If `docs/domain/` is missing or empty, the agent refuses with the literal message:

```
docs/domain/ is missing or empty. Run /project:explore first to bootstrap, then /project:enhance-wiki to update.
```

and exits before the skill-load step. This mirrors `project-explorer`'s refusal-points-at-sibling pattern in reverse: `project-explorer` refuses when `docs/domain/` is non-empty (pointing at this enhancer); this enhancer refuses when `docs/domain/` is missing/empty (pointing back at `project-explorer`).

## Operating procedure

Numbered steps 1-11. The agent must execute these in order. Each step mirrors `project-wiki-enhancer.overview-plan.md` Section 5 (Core Behaviour); later sections in this skill fill in the precise contract per step.

1. **Resolve target.** Resolve `[path]` (defaults to the current working directory). Locate the current working directory's `docs/domain/`. If `docs/domain/` is missing or empty, refuse with the message pointing the user at `/project:explore` (see `## Pre-flight refuse condition` above) — bootstrap first, then enhance.
2. **Skill load (both).** The subagent loads its own `.claude/skills/project-wiki-enhancer/SKILL.md` first, then reloads `.claude/skills/project-explorer/SKILL.md` verbatim. Both are treated as authoritative for the run; enhancer-specific behaviour (diff strategy, fence handling, idempotency exit message) lives in this skill, output schema + frontmatter + BC heuristics live in the project-explorer skill. See `## Skill reload contract` for the explicit reload targets.
3. **Diff strategy selection (hybrid).** Read `last_generated_sha` from frontmatter (sample one file under `docs/domain/`; all frontmatter is treated as consistent — every file's `last_generated_sha` advances together on a successful run).
   - **Git fast path** fires when `[path]` is a git working tree AND `last_generated_sha` is present AND that SHA is reachable from HEAD. Command: `git diff --name-only <last_generated_sha>..HEAD`. Apply the exclusion globs verbatim. Map each surviving file to its owning BC via `project-explorer`'s namespace/folder heuristic.
   - **Full-walk fallback** fires when any git-fast-path precondition fails (no git, no `last_generated_sha`, or SHA unreachable — including the first enhancer run against a `project-explorer`-bootstrapped tree where `last_generated_sha` is absent). Walks every BC under `[path]` per `project-explorer`'s skill and compares every regenerated file in memory against the on-disk file.

   See `## Hybrid diff strategy` for the full contract and the auditability lines surfaced in run output.
4. **Classify changed files.** Bucket the diff output into exactly one of three classes per `## Path -> BC classifier`: (a) `BC-affecting` — survives the exclusion globs AND lives under a known BC folder/namespace; (b) `infra — no BC impact` — excluded by globs OR survives globs but is not under any known BC; (c) `new-namespace` — survives exclusion globs AND lives under a folder/namespace not mapped to any existing BC.
5. **New-BC discovery APPROVE gate.** If bucket (c) is non-empty, print the candidate new-BC list (rationale + aggregates detected, formatted per `project-explorer`'s `### Candidate report format`) and halt on the literal `APPROVE` token using `project-explorer`'s `### APPROVE gate contract` verbatim. No new `<bounded-context>/` folder is created until APPROVE is received. See `## New-BC discovery APPROVE gate`.
6. **Removed-BC logging.** For each existing `<bounded-context>/` folder under `docs/domain/` whose namespace is no longer present in source, append a bullet to `context-map.md`'s `## Skipped candidates` H2 section as `<bc-name>: namespace no longer present`. **Never delete** the folder. **Never delete** any file inside the folder. See `## Removed-BC logging`.
7. **Regeneration in memory.** For every BC in bucket (a) and the user-APPROVED subset of bucket (c), regenerate the per-file content per `project-explorer`'s `## Output schema` `### Per-file content contract`, scoped to that BC's slice of the tree. Generation is in-memory only at this point — no writes.
8. **Fenced human-edit zone preservation.** For each regenerated file, read the on-disk file. If it contains a `<!-- human:begin --> ... <!-- human:end -->` block, splice the on-disk fenced block (the lines from `<!-- human:begin -->` through `<!-- human:end -->` inclusive, content verbatim) into the regenerated content at the same anchor position; everything outside the fence is replaced with the regenerated agent-owned content. If no fence exists on disk, the regenerated content fully replaces the on-disk content (see `## Migration caveat`).
9. **Byte-perfect compare + selective write.** For each candidate file: serialize the regenerated content (post-fence-splice) and compare to the on-disk bytes. **Write only when bytes differ.** On a real content change, refresh the frontmatter per `## Frontmatter refresh rules` (`generated_at` to a new ISO-8601 UTC second-precision `Z`-suffixed timestamp, `skill_version` to the current `project-explorer` skill version, `branch_name` to the current arg or bare `null`, preserve `source_repo`, stamp `last_generated_sha` to current HEAD on the git path). Files whose content has not changed retain their prior `generated_at` even after a successful run.
10. **`last_generated_sha` advancement.** Regardless of whether any content changed, stamp `last_generated_sha` on every file the enhancer touches in step 9. On the full-walk fallback path with no git, `last_generated_sha` is omitted from frontmatter (next run will re-fallback). On the git path, `last_generated_sha` advances to current HEAD on every successful run, so subsequent runs take the fast path.
11. **Idempotency exit.** If zero files were written in step 9, the agent exits with the literal message `No changes detected. 0 files written.` and **no further output**. Otherwise the agent prints a per-run summary (files written count, new BCs created count, removed BCs logged count) and exits. See `## Idempotency exit`.

## Skill reload contract

The enhancer agent reloads two skills in this order, at the start of every run:

1. `.claude/skills/project-wiki-enhancer/SKILL.md` — this file. Loaded first.
2. `.claude/skills/project-explorer/SKILL.md` — loaded verbatim **after** this skill. Treated as authoritative for everything the enhancer regenerates.

The enhancer treats the sibling skill as authoritative for:

- The output schema — `project-explorer`'s `## Output schema` (file tree, per-file content contract, small-repo fallback variant, write order, hallucination guard).
- The frontmatter contract — `project-explorer`'s `## Frontmatter contract` (the four-field YAML block — `source_repo`, `branch_name`, `generated_at`, `skill_version`). This feature adds `last_generated_sha` on top per `## Frontmatter refresh rules` below.
- BC discovery heuristics — `project-explorer`'s `## BC candidate surfacing` (including `### Grouping rule`, which is the namespace -> folder mapping the classifier reuses).
- Exclusion globs — the eight globs enumerated under `project-explorer`'s `### Small-repo fallback detection`. Reused verbatim by `### Exclusion globs (verbatim)` below.
- The APPROVE gate format — `project-explorer`'s `### Candidate report format` and `### APPROVE gate contract`. Reused verbatim by the new-BC discovery gate.

This skill owns the enhancer-specific behaviour the sibling skill does not cover: the hybrid diff strategy, the path -> BC classifier with its three classification buckets, the fenced human-edit zone splice rule, `last_generated_sha` semantics, the removed-BC log-only rule, the byte-perfect idempotency contract with its canonical exit message, and the two load-bearing prose sections `## Known coupling` and `## Migration caveat`.

## Hybrid diff strategy

### Git fast path

Fires when **all three** preconditions hold, evaluated in this order:

1. `[path]` is a git working tree — detected by `git -C <path> rev-parse --git-dir` returning success.
2. `last_generated_sha` is present in the frontmatter of at least one file under `docs/domain/`. The enhancer samples **one** file (any file; the contract is that all frontmatter advances together on every successful run per `## Frontmatter refresh rules`, so sampling one file is sufficient).
3. `last_generated_sha` is reachable from HEAD — detected by `git -C <path> merge-base --is-ancestor <last_generated_sha> HEAD` returning success.

On success, the enhancer runs:

```
git -C <path> diff --name-only <last_generated_sha>..HEAD
```

then applies the exclusion globs from `### Exclusion globs (verbatim)` (globs first, terminal), then maps each surviving path to its owning BC via `### Namespace -> BC mapping`.

The chosen path is surfaced in run output as the literal line for auditability:

```
Diff strategy: git fast path (<last_generated_sha>..HEAD)
```

### Full-walk fallback

Fires when **any** of the three git-fast-path preconditions fails. The three triggers, evaluated in the same order as the git-fast-path preconditions:

1. `[path]` is not a git working tree (`git -C <path> rev-parse --git-dir` returns failure).
2. `last_generated_sha` is absent from the sampled `docs/domain/` frontmatter (legacy `project-explorer`-bootstrapped tree on first enhancer run, or a manually wiped field).
3. `last_generated_sha` is present in the sampled frontmatter but **unreachable** from HEAD — for example because the branch was force-pushed and the commit was orphaned, the branch was rebased and the commit was rewritten away, or the commit was deleted and is no longer in any ref-reachable history. Detected by `git -C <path> merge-base --is-ancestor <last_generated_sha> HEAD` returning failure.

On any trigger, the enhancer walks every BC under `[path]` per `project-explorer`'s skill and compares every regenerated file in memory against the on-disk file. The full-walk path is a strict superset of the git fast path's correctness — both produce byte-perfect idempotency; the git fast path is purely a speedup.

**Reason-token short-circuit (load-bearing).** When more than one precondition would fail at once, the enhancer evaluates the three preconditions in the order listed above and selects the reason token from the **first** failing precondition. First failure wins:

1. git-tree-check fails -> reason token is `missing-git` (the SHA-present check and reachability check are not run).
2. SHA-present-check fails -> reason token is `missing-sha` (the reachability check is not run; there is no SHA to test).
3. reachability-check fails -> reason token is `unreachable-sha`.

No compound tokens are ever emitted. The three reason tokens are mutually exclusive in any single run.

The chosen path is surfaced in run output as the literal line for auditability:

```
Diff strategy: full-walk fallback (reason: <missing-git | missing-sha | unreachable-sha>)
```

### last_generated_sha tolerate-missing

When `last_generated_sha` is absent from frontmatter — the case on the first enhancer run against any `project-explorer`-bootstrapped tree, because `last_generated_sha` is a new field introduced by this feature — the enhancer falls through to the full-walk fallback per the contract above with reason token `missing-sha`.

**First-run stamp lifecycle (git path).** On its first successful run against a git working tree, the enhancer stamps `last_generated_sha = <current HEAD SHA>` on every file it touches in step 9 (the selective writer in Step E). The literal current HEAD SHA — resolved at the start of the run — is written into the frontmatter of every touched file. Subsequent runs against the same repo read that stamped SHA from the sampled frontmatter, satisfy all three git-fast-path preconditions (the SHA is present and reachable from the new HEAD), and take the git fast path. This is a **one-time** legacy-repo cost per pre-enhancer-bootstrapped repo.

**No-git path lifecycle.** When trigger 1 of `### Full-walk fallback` fires (the directory is not a git working tree), the enhancer cannot resolve a HEAD SHA. The selective writer omits the `last_generated_sha` field from emitted frontmatter entirely. Every subsequent run against the same non-git directory takes the full-walk fallback again with reason `missing-git`. There is no transition to the fast path on the no-git path.

**Force-push / rebase recovery lifecycle.** When reason `unreachable-sha` fires, the selective writer re-stamps `last_generated_sha = <current HEAD SHA>` on every file it touches. The next run satisfies all three preconditions (the new SHA is reachable from the new HEAD) and takes the fast path again. Recovery is automatic; no user intervention required.

The enhancer never refuses on missing-SHA or unreachable-SHA; it never back-patches the sibling `project-explorer` skill to emit `last_generated_sha` on bootstrap.

## Path -> BC classifier

### Exclusion globs (verbatim)

The eight globs the classifier applies, verbatim:

- `**/bin/**`
- `**/obj/**`
- `**/node_modules/**`
- `**/dist/**`
- `**/*Tests/**`
- `**/*.Tests/**`
- `**/*.generated.*`
- `**/*Designer.cs`

These are the same globs `project-explorer`'s `SKILL.md` applies under `### Small-repo fallback detection`. Reused here to keep a single source of truth for "what counts as first-class source." See `.claude/skills/project-explorer/SKILL.md` `### Small-repo fallback detection` for the original list and its rationale; this enhancer never forks or duplicates the list — any future edit must be made there and audited here per `## Known coupling`.

**Ordering rule (load-bearing).** The classifier evaluates every path from the diff output in this exact order:

1. **Globs first.** Apply the eight exclusion globs verbatim. Every path matching any of the eight globs is bucketed as `infra — no BC impact` and skipped immediately.
2. **Namespace lookup second.** Only the paths that survive step 1 are evaluated against `### Namespace -> BC mapping` to decide between `BC-affecting` and `new-namespace`.

A path excluded by the globs in step 1 is **never** re-evaluated against the namespace mapping, the new-namespace detector, or any other rule. Glob exclusion is terminal.

**Q5 terminal-exclusion clarifier.** This terminal rule holds even when the excluded path lives under a brand-new folder/namespace that is not yet mapped to any `<bounded-context>/` under `docs/domain/`. Example: a changed `**/SomeNewBc/bin/Foo.dll` matches `**/bin/**` on the first comparison, is bucketed `infra — no BC impact`, and the new-namespace detector is **never** invoked for it. The candidate `SomeNewBc` does NOT surface in the `new-namespace (candidates: ...)` parenthetical, and no APPROVE gate fires for it. Glob exclusion always wins over new-namespace detection.

### Namespace -> BC mapping

The classifier reuses `project-explorer`'s `## BC candidate surfacing` `### Grouping rule` verbatim. Namespace tokens and folder paths trace from the candidate report straight into the classifier — no taxonomy invented here. See `.claude/skills/project-explorer/SKILL.md` `## BC candidate surfacing` `### Grouping rule`. Not duplicated here by design; cite-by-reference per `## Known coupling`.

**Bucket-assignment rule (applied only to paths that survived the glob filter — glob-excluded paths were already terminated upstream per `### Exclusion globs (verbatim)`):**

- A surviving path is bucketed as `BC-affecting` **iff** its folder/namespace matches an existing `<bounded-context>/` folder under `docs/domain/` (reverse lookup via `project-explorer`'s `### Grouping rule`: existing BC folder names trace back to namespace tokens and folder paths).
- A surviving path is bucketed as `new-namespace` **iff** its folder/namespace does not match any existing BC and the path lives under a recognizable namespace/folder structure that would itself qualify as a BC candidate per `project-explorer`'s `### Grouping rule`.
- A surviving path that lives under no recognizable namespace/folder structure (e.g., a top-level file with no BC-relevant context such as a repo-root `README.md`) is bucketed as `infra — no BC impact`.

### Classification buckets

Every file in the diff output is bucketed into exactly one of three classes:

| Bucket | Definition | Action |
|---|---|---|
| `BC-affecting` | Survives the exclusion globs AND lives under a known BC folder/namespace. | Add the owning BC to the re-walk set. |
| `infra — no BC impact` | Excluded by the globs OR survives the globs but is not under any known BC. | No re-walk; logged for auditability. |
| `new-namespace` | Survives the exclusion globs AND lives under a folder/namespace not mapped to any existing BC. | Fires the new-BC discovery APPROVE gate (see `## New-BC discovery APPROVE gate`). |

**Per-bucket count summary (auditability).** Immediately after the `Diff strategy:` audit line and before any subsequent step output, the agent prints the literal line:

```
Classified: <N> BC-affecting (BCs: <comma-separated, alphabetical>), <M> infra, <P> new-namespace (candidates: <comma-separated, alphabetical>)
```

Rules:

- The three nouns `BC-affecting`, `infra`, `new-namespace` are invariant — never singular/plural variants regardless of count.
- The BC list and the candidate list are sorted alphabetically (case-insensitive).
- The `infra` noun carries **no** parenthetical.
- An empty parenthetical (zero BCs in the `BC-affecting` parenthetical or zero candidates in the `new-namespace` parenthetical) renders as `(none)`.
- The count integer is always present even when zero (e.g., `0 BC-affecting (BCs: (none))`).
- The line is printed exactly once per run, immediately after the `Diff strategy:` line, before any subsequent step output.

## New-BC discovery APPROVE gate

The enhancer reuses `project-explorer`'s candidate-report + APPROVE-gate contract **verbatim**, unmodified. See:

- `.claude/skills/project-explorer/SKILL.md` `### Candidate report format` — for the markdown layout of the candidate list (rationale, aggregates detected, conflicts detected, fallback flag).
- `.claude/skills/project-explorer/SKILL.md` `### APPROVE gate contract` — for the literal prompt `Type APPROVE to write docs/domain/, or describe edits.`, the exact-case `APPROVE` token check (after trimming leading/trailing whitespace), and the edit-revision loop.

The enhancer adds nothing to the contract: same report format, same literal prompt, same exact-case `APPROVE` token check, same edit-revision loop with no round cap. No new `<bounded-context>/` folder is created under `docs/domain/` until the user types the literal `APPROVE`. Case variants (`approve`, `Approve`) and yes-equivalents (`ok`, `yes`, `sure`) are treated as edit instructions — never approval. v1 is TTY-only by design; no `--yes` flag exists or is planned for v1.

### Trigger

Fires when the `new-namespace` bucket from `### Classification buckets` is non-empty. If the `new-namespace` bucket is empty, this gate does not fire and the run proceeds to step 6 of `## Operating procedure` (removed-BC logging) without any candidate-report print or APPROVE prompt.

### Reused contract (verbatim)

The enhancer prints the candidate report using `.claude/skills/project-explorer/SKILL.md` `### Candidate report format` verbatim — same numbered `### BC candidates` list with per-candidate nested bullets for `Rationale` (folders / namespaces that contributed) and `Aggregates detected` (aggregate root + `file:line` citation as an inline-code span), same `### Fallback flag` line, same `### Conflicts detected` subsection (rendered as `(none)` when empty per the sibling skill).

The `### Fallback flag` line on an enhancer run is **always** the literal token `false`. The small-repo fallback is a `project-explorer` bootstrap-only signal; it never fires from the enhancer.

After the candidate report, the agent prints `.claude/skills/project-explorer/SKILL.md` `### APPROVE gate contract`'s literal prompt verbatim, byte-for-byte:

```
Type APPROVE to write docs/domain/, or describe edits.
```

### Acceptance check

The agent MUST NOT create any new `<bounded-context>/` folder under `docs/domain/` until the user's response, after trimming leading and trailing whitespace (trim is exact-case-preserving), matches the literal token `APPROVE` **exact-case**. Case variants (`approve`, `Approve`, `approve!`, `APPROVE!`), yes-equivalents (`ok`, `yes`, `sure`), and any other text are treated as edit instructions per the loop below — never as approval. This is the same exact-case check defined in `.claude/skills/project-explorer/SKILL.md` `### APPROVE gate contract`; the enhancer does not relax or rewrite it.

### Edit-revision loop

Any response that is not the literal exact-case `APPROVE` (after trim) is treated as a free-text edit instruction. The agent interprets the instruction (rename a candidate, merge two candidates, split one, drop or add a candidate), regenerates the candidate report with the change applied, prefixes with the `Applied edits:` preamble defined in `.claude/skills/project-explorer/SKILL.md` `### APPROVE gate contract` (including the canonical no-actionable-change preamble for case-variant / yes-equivalent responses — see the sibling skill for the literal preamble string; do not duplicate it here), then re-prints the literal APPROVE prompt. The loop has no round cap and iterates until the user types exact-case `APPROVE` or aborts the session.

### Post-APPROVE behaviour

Only after the trimmed response matches exact-case `APPROVE` does the enhancer create new `<bounded-context>/` folders under `docs/domain/` for the approved subset of the `new-namespace` bucket. The new folders are populated by the Step E writer (`## Regenerate -> fence-splice -> byte-compare -> selective write` and its `### Selective write + frontmatter refresh` subsection) per `.claude/skills/project-explorer/SKILL.md` `## Output schema` `### Per-file content contract` and `### Write order`. Every newly written file under a freshly created `<bounded-context>/` folder carries all five frontmatter fields stamped **fresh** per `## Frontmatter refresh rules`: `source_repo` (preserved from `<path>`), `branch_name` (current invocation's arg or bare `null`), `generated_at` (new ISO-8601 UTC second-precision `Z`-suffixed timestamp), `skill_version` (current integer of `.claude/skills/project-explorer/SKILL.md`'s `version` field), and `last_generated_sha` (current HEAD SHA on the git path; omitted on the full-walk fallback path with no git).

### Out-of-scope reminder

v1 is TTY-only by design. There is no `--yes` flag in v1 and none is planned for v1. The deferred git-hook follow-up (F1 / F2 in `docs/project-wiki-enhancer/project-wiki-enhancer.analyzed.md` Section 10) is the only known consumer of a non-interactive gate; shipping it has a hard prerequisite to design and ship `--yes` (or equivalent non-interactive gate) first. None of that machinery is in scope for v1.

## Removed-BC logging

For each existing `<bounded-context>/` folder under `docs/domain/` whose namespace is no longer present in source, the enhancer appends one bullet to `context-map.md`'s `## Skipped candidates` H2 section in the form:

```
<bc-name>: namespace no longer present
```

Rules:

- **Never delete** the `<bounded-context>/` folder.
- **Never delete** any file inside the `<bounded-context>/` folder (including the fenced human-edit zones inside those files).
- **Never touch** any file inside a removed-BC folder beyond the single `context-map.md` append described above.
- The removed-BC log entry is the only on-disk change the enhancer makes for a disappeared namespace.

### Detection

For each `<bounded-context>/` folder currently present under `docs/domain/`, the enhancer performs a **reverse lookup** against `.claude/skills/project-explorer/SKILL.md` `## BC candidate surfacing` `### Grouping rule`: take the on-disk folder name and check whether a corresponding namespace token or folder path still exists under `<path>` per the sibling skill's namespace -> BC mapping. A BC is "removed" iff its mapping returns no source match — that is, neither a namespace token nor a folder path in source maps to the on-disk `<bounded-context>/` folder name. The detection is independent of the diff strategy chosen (git fast path or full-walk fallback); both paths walk every `<bounded-context>/` folder under `docs/domain/` and apply the reverse lookup.

### Log target and bullet format

The append target is the existing `## Skipped candidates` H2 section in `docs/domain/context-map.md` (the `project-explorer` writer emits this section on every bootstrap; the enhancer never creates the section from scratch — only appends to it). The bullet format is exactly:

```
- <bc-name>: namespace no longer present
```

**Folder-name vs namespace-token disambiguation.** The `<bc-name>` is the on-disk `<bounded-context>/` folder name (e.g., `legacy` for `docs/domain/legacy/`) — **NOT** the source namespace token (e.g., `Acme.Legacy`). The folder name is the user-visible identifier the human reader recognises from their `docs/domain/` tree, and the namespace token may have already disappeared from source by the time this code runs. The folder name's case is preserved verbatim from the filesystem.

### Idempotency of the log

Before appending, the enhancer reads the body of the `## Skipped candidates` section and checks for an existing matching line. The duplicate check is:

- **Exact-line match** — the full literal line including the leading `- ` (hyphen + space) bullet prefix. A line `* legacy: namespace no longer present` (different bullet character) or `legacy: namespace no longer present` (missing prefix) does **not** match and would not suppress an append.
- **Case-sensitive** — `- Legacy: namespace no longer present` does **not** match `- legacy: namespace no longer present`.
- **Scoped** to the body between the `## Skipped candidates` H2 line and the next H2 line (or end-of-file when `## Skipped candidates` is the final H2). A matching line elsewhere in `context-map.md` (e.g., inside `## Conflicts detected`) does **not** count as a duplicate.

If a matching line already exists in that scope, the enhancer does **not** append. This keeps the section monotonically growing without re-appending on every run. Combined with the byte-compare contract in `### Selective write + frontmatter refresh`, a duplicate-suppressed append produces zero on-disk writes, and the canonical idempotency exit message applies when no other writes occurred in the run.

### `(none)` placeholder handling

If the body of the `## Skipped candidates` section is the literal single line `(none)` (the `project-explorer` placeholder when bootstrap found no skips), the enhancer replaces that one line **in place** with the first bullet on first append. The replacement applies only to a single line whose trimmed body is exactly `(none)`. Specifically:

- The `## Skipped candidates` heading line is preserved verbatim.
- Any blank line(s) between the heading and the `(none)` line are preserved.
- The single line `(none)` is **replaced** by the first bullet (`- <bc-name>: namespace no longer present`).
- Any blank line(s) between the (replaced) line and the next H2 / end-of-file are preserved.

Subsequent appends (on later runs that discover additional removed BCs) add bullets normally underneath the first one; the `(none)` placeholder rule does **not** re-fire because the body is no longer the literal single line `(none)`.

### Strict no-delete contract

The enhancer's contract for a removed namespace is **log-only**, reaffirmed here:

- The enhancer **never** deletes the `<bounded-context>/` folder for a removed BC. The folder stays on disk verbatim.
- The enhancer **never** deletes any file inside the `<bounded-context>/` folder (including the human-edited files inside `<!-- human:begin --> ... <!-- human:end -->` fences).
- The enhancer **never** rewrites any file inside the `<bounded-context>/` folder. No regeneration, no fence-splice, no frontmatter refresh — the folder is frozen until the human author decides to remove it manually. Every file under the removed BC's folder retains its prior `generated_at` value and prior `last_generated_sha` value byte-for-byte.
- The only on-disk write triggered by a removed BC is the single bullet append to `docs/domain/context-map.md` under `## Skipped candidates`, and that append is itself subject to the byte-compare contract in `### Selective write + frontmatter refresh` (no write if the bullet already exists per the idempotency-of-log rule above).

### Reason token (locked)

The reason text is exactly `namespace no longer present` — verbatim. No variants. Future reason tokens (for example `renamed to <new-bc>`, archival reasons, or merge-target reasons) are deferred to F7 in `docs/project-wiki-enhancer/project-wiki-enhancer.analyzed.md` Section 10 and **never** appear in v1. v1's bullet template is a single locked string with one placeholder (`<bc-name>`).

## Regenerate -> fence-splice -> byte-compare -> selective write

### Regenerate in memory

For every BC in the `BC-affecting` bucket plus the user-APPROVED subset of the `new-namespace` bucket, the enhancer regenerates the per-file content per `project-explorer`'s `## Output schema` `### Per-file content contract`, scoped to that BC's slice of the tree. Generation is **in-memory only** at this point — no writes have happened yet.

**Scope.** Regenerate per-file content for every BC in the `BC-affecting` bucket plus the user-APPROVED subset of the `new-namespace` bucket. BCs in the `infra — no BC impact` bucket are **not** re-walked. BCs that were detected as **removed** (no longer in source) are excluded from the regenerate set per `## Removed-BC logging`'s strict no-delete contract — the enhancer logs them and moves on; their `<bounded-context>/` folder is frozen.

**Output contract.** Each regenerated file's content is produced per `.claude/skills/project-explorer/SKILL.md` `## Output schema` `### Per-file content contract`, scoped to that BC. The exact set of files regenerated per BC is:

- `<bounded-context>/glossary.md`
- `<bounded-context>/aggregates/<aggregate>.md` (one file per detected aggregate root)
- `<bounded-context>/events.md`
- `<bounded-context>/commands.md`
- `<bounded-context>/repositories.md`
- `<bounded-context>/services.md`

In addition, the two repo-wide roll-up files `docs/domain/context-map.md` and `docs/domain/glossary.md` are regenerated whenever **any** BC changes, because their content is a roll-up across all BCs.

**In-memory only.** No file under `docs/domain/` is written at this stage. The output is held in memory as a `{ path -> regenerated-content-string }` mapping keyed by absolute file path. Writes happen exclusively in `### Selective write + frontmatter refresh` after `### Fenced human-edit zone splice` and `### Byte-compare` have run.

### Fenced human-edit zone splice

**Fence markers.** The exact byte sequences are `<!-- human:begin -->` and `<!-- human:end -->`, each on their own line. Leading and trailing whitespace on the marker line itself is tolerated (the scanner trims marker-line whitespace before matching). Content between the markers — including any blank lines, leading whitespace, and trailing whitespace — is preserved byte-for-byte.

**Per-file algorithm.** For each `(path, regenerated-content)` pair produced by `### Regenerate in memory`:

1. Read the on-disk file at `path`. If the file is missing (new file — e.g., a file under a freshly APPROVED new BC), **skip the splice**; the regenerated content is used as-is and proceeds straight to `### Byte-compare`.
2. Scan the on-disk content for the fence markers. **Zero fences** -> regenerated content used as-is (see `## Migration caveat`). **One fence pair** -> proceed to step 3 to splice. **Multiple fence pairs** -> loop step 3 for each pair, preserving all of them at their respective anchor positions.
3. For each fence pair found on-disk: locate the same anchor position in the regenerated content (the anchor is the line index of `<!-- human:begin -->` within the agent-owned content; if the regenerated content has no matching anchor at the expected position, splice the fenced block at the same line-index offset measured from the top of the regenerated content). Replace the lines from `<!-- human:begin -->` through `<!-- human:end -->` (inclusive) in the regenerated content with the verbatim on-disk fenced block (markers + content + any whitespace within, byte-for-byte).
4. The post-splice content string is the byte-compare candidate consumed by `### Byte-compare`.

Anchor drift across regenerations is a known limitation; users who care about exact placement should keep fenced blocks adjacent to stable headings (e.g., immediately after a `## ` H2).

If no fence exists on disk, the regenerated content fully replaces the on-disk content (see `## Migration caveat`).

**Never-touch invariant.** The agent's only obligation inside a fence is to splice the on-disk bytes verbatim into the regenerated content. Specifically:

- The agent **never** modifies content between `<!-- human:begin -->` and `<!-- human:end -->` — preserved byte-for-byte from the on-disk file.
- The agent **never** modifies the fence marker lines themselves (`<!-- human:begin -->` / `<!-- human:end -->`) — no normalisation, no whitespace rewrite, no re-emission.
- The agent's only obligation inside the fence is to splice the on-disk bytes verbatim into the regenerated content. Nothing else.

### Byte-compare

The enhancer serializes the post-fence-splice regenerated content to a string, reads the on-disk file as bytes, and compares. **The enhancer writes only when bytes differ.** A successful run against an unchanged file produces zero on-disk change for that file.

**Comparison input.** The post-splice regenerated content string (serialized to UTF-8 bytes) vs the on-disk file bytes (read as UTF-8). Both sides are raw byte sequences at the moment of comparison.

**Byte-perfect.** Comparison is byte-exact. There is **no normalization**: trailing newline differences, BOM differences, and CRLF-vs-LF line-ending differences are all **real differences** that trigger a write. The enhancer does not normalize line endings on read or on write — the regenerated content emits LF only (matching `project-explorer`'s output convention; see `.claude/skills/project-explorer/SKILL.md` `## Output schema`).

**Skip-write decision.** If the byte sequences are identical, the file is **skipped**: no write to disk, no frontmatter refresh, no `last_generated_sha` stamp on this file. Its prior `generated_at` and prior `last_generated_sha` are preserved byte-for-byte. Skip-write is the per-file foundation of the zero-write run that triggers `## Idempotency exit`'s canonical exit message.

### Selective write + frontmatter refresh

**Write trigger.** A file is written **iff** `### Byte-compare` returned "differ" for that file. Files whose bytes are byte-identical post-splice are not touched and retain their prior `generated_at` and prior `last_generated_sha` values verbatim.

**Frontmatter refresh order (4 numbered steps).** On a write:

1. **Strip** the existing frontmatter block from the regenerated content string (the regenerated content carries a placeholder frontmatter generated by the `project-explorer` writer; it is discarded before the new frontmatter is constructed).
2. **Construct** the new frontmatter block per `## Frontmatter refresh rules` below. All five fields are written in this order:
   - `source_repo` — **preserved** verbatim from the on-disk file's frontmatter (never refreshed by the enhancer).
   - `branch_name` — refreshed to the current invocation's branch arg, or bare YAML `null` token when omitted. `branch_name` follows `project-explorer`'s frontmatter contract: bare YAML `null` token when the invocation omits the arg, NOT the quoted string `"null"`. See `.claude/skills/project-explorer/SKILL.md` `## Frontmatter contract`.
   - `generated_at` — refreshed to the current ISO-8601 UTC second-precision `Z`-suffixed timestamp.
   - `skill_version` — refreshed to the current integer of `.claude/skills/project-explorer/SKILL.md`'s `version` field (the enhancer stamps the **project-explorer** skill version, not its own — output-schema versioning belongs to the schema owner).
   - `last_generated_sha` — stamped per the per-file rule below: on the git path (any of git-fast / `missing-sha` / `unreachable-sha`) the field is stamped to the current HEAD SHA; on the no-git full-walk fallback path the field is **omitted entirely**.
3. **Prepend** the new frontmatter block as the **first content** of the file — before any heading — per `.claude/skills/project-explorer/SKILL.md` `## Frontmatter contract`.
4. **Write** the final string to disk at `path` as UTF-8 with LF line endings and no BOM. Write order across files follows `.claude/skills/project-explorer/SKILL.md` `## Output schema` `### Write order`.

**`last_generated_sha` advancement (per-file, git path).** On the git path (fast or fallback), `last_generated_sha` is stamped to the **current HEAD SHA** on every file the enhancer writes in this step. Files the enhancer did **not** write retain their prior `last_generated_sha` value byte-for-byte. After a successful run where N out of M files changed, the N written files carry the new HEAD SHA and the M-N unwritten files carry their prior SHA — **both** are valid sampling points for the next run's `### Git fast path` precondition check (the sampled SHA only needs to be reachable from the new HEAD).

**`last_generated_sha` omission (per-file, no-git only).** On the full-walk fallback path **with no git** (reason token `missing-git`), `last_generated_sha` is **omitted from the frontmatter** of every written file — the YAML key does not appear in the block at all. The next run re-evaluates the precondition, fails the git-tree check again, and re-falls-back. Critical distinction: reasons `missing-sha` and `unreachable-sha` are **git-available** paths, so the writer **still stamps HEAD** on those paths (recovery is automatic; the next run takes the fast path). Only `missing-git` causes the writer to **omit the field entirely** — and only on every subsequent no-git run.

**New-file case.** For files in a freshly APPROVED new BC, there is no on-disk content to read; the splice and byte-compare steps are skipped (per `### Fenced human-edit zone splice` step 1's missing-file rule and `### Byte-compare`'s differ-by-default semantics). The write proceeds with a fresh frontmatter — all five fields stamped per the git-path rule above (`source_repo` derived from `<path>`; `branch_name` per the current invocation arg or bare `null`; `generated_at` fresh; `skill_version` fresh; `last_generated_sha` to HEAD on the git path, omitted on the no-git path) — and the regenerated content as-is (no fence to splice on a new file).

## Frontmatter refresh rules

| Field | Refresh trigger | Preserved when | Notes |
|---|---|---|---|
| `source_repo` | Never refreshed by the enhancer. | Always preserved. | Locked by `project-explorer`'s frontmatter contract. |
| `branch_name` | Refreshed on real-content change to the current invocation's branch arg (or bare `null` when omitted). | Untouched files retain prior value. | Same YAML scalar / bare `null` rules as `project-explorer`'s frontmatter contract. |
| `generated_at` | Refreshed (new ISO-8601 UTC second-precision `Z`-suffixed timestamp) only when the post-fence-splice bytes differ from on-disk bytes for **this specific file**. | Untouched files retain prior value even after a successful enhancer run. | Content-change semantics. Locked by D5 / BA resolution Q5/Q6. |
| `skill_version` | Refreshed on real-content change to the current integer of `.claude/skills/project-explorer/SKILL.md`'s `version` field. | Untouched files retain prior value. | The enhancer stamps the **project-explorer** skill version, not its own — output schema versioning belongs to the schema owner. |
| `last_generated_sha` | Stamped on every file the enhancer **touches** (writes) in the selective-write step on the git fast path; advances to current HEAD on every successful run regardless of content change. | Untouched files retain prior value. Files on the full-walk fallback path with no git omit the field entirely. | Run-tracker semantics. New field introduced by this feature. Tolerate-missing on first run (see `### last_generated_sha tolerate-missing`). |

## Idempotency exit

**Zero-write exit.** When `### Selective write + frontmatter refresh` wrote **zero** files across the entire run — including zero new BCs created and zero removed-BC bullets appended to `## Skipped candidates` — the agent prints **exactly one line**:

```
No changes detected. 0 files written.
```

and exits. **No summary, no banner, no `Diff strategy:` line, no `Classified:` line, no additional output.** Just the one literal line, then exit. This is the canonical signal downstream automation (git status checks, CI lint, future post-merge hooks) can grep for unambiguously.

**Non-zero-write exit.** When at least one write occurred (any combination of regenerated BC files, new-BC files, or a removed-BC bullet append to `context-map.md`), the agent prints this fenced summary and exits:

```
<N> files written.
<P> new BCs created: <comma-separated names or "(none)">.
<R> removed BCs logged: <comma-separated names or "(none)">.
Diff strategy: <git fast path (<sha>..HEAD) | full-walk fallback (reason: <token>)>
```

where `<N>`, `<P>`, `<R>` are integer counts; the two name lists render as `(none)` when their count is zero; and the `Diff strategy:` line is the same audit line surfaced earlier in the run by `## Hybrid diff strategy`.

**No-partial-exit rule.** If any step in the pipeline (regenerate, splice, compare, write) errors, the agent surfaces the error and exits non-zero. Partial state on disk is acceptable — the next run's byte-compare reconverges automatically. The canonical zero-write message above is emitted **only** on a successful zero-write run, never on a partial-failure run.

## Known coupling

This skill is load-bearing because the enhancer reloads the sibling `.claude/skills/project-explorer/SKILL.md` verbatim at runtime; an edit to any of the following contracts in that file silently changes enhancer behaviour. The human editor who touches `project-explorer`'s `SKILL.md` is obligated to run a paired enhancer audit against this file. No `skill_version` pin or `compatible_with` check exists or is planned — this section itself is the trip-wire.

The enhancer reloads, by name, the following five contracts from `.claude/skills/project-explorer/SKILL.md`:

- `## Output schema` (including `### Files written`, `### Per-file content contract`, `### Small-repo fallback variant`, `### Write order`, `### Hallucination guard`) — the full file tree + per-file content rules + small-repo fallback variant + write order + hallucination guard the enhancer regenerates against.
- `## Frontmatter contract` — the four-field YAML block (`source_repo`, `branch_name`, `generated_at`, `skill_version`); this feature adds `last_generated_sha` on top per `## Frontmatter refresh rules` above.
- `## BC candidate surfacing` `### Grouping rule` — the namespace -> BC mapping the path classifier reuses (see `### Namespace -> BC mapping` above).
- `### Small-repo fallback detection` — the eight exclusion globs enumerated there are the verbatim source for `### Exclusion globs (verbatim)` above.
- `### Candidate report format` and `### APPROVE gate contract` — reused verbatim by `## New-BC discovery APPROVE gate` for the candidate report layout, the literal `Type APPROVE to write docs/domain/, or describe edits.` prompt, the exact-case `APPROVE` token check, and the edit-revision loop.

Any edit to those sections in `.claude/skills/project-explorer/SKILL.md` silently changes enhancer behaviour. The editor is obligated to (a) re-read this skill end-to-end, (b) re-read `project-wiki-enhancer.analyzed.md` Section 3 for the coupling rationale, and (c) re-run the Step F acceptance pass against a known fixture before considering the edit complete.

## Migration caveat

> On first enhancer run against a `docs/domain/` tree authored by `project-explorer` (no human-edit fences present), any pre-existing human edits made directly to generated files will be overwritten by the regenerated content. To preserve edits, wrap them in `<!-- human:begin --> ... <!-- human:end -->` fences before invoking `/project:enhance-wiki`.
