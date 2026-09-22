---
name: project-update
version: 1
consumed_by: project-update agent
description: Operating manual for the project-update agent - dual-pass diff-aware refresh of docs/narrative/ then docs/domain/.
---

## Purpose

`project-update` (the enhancer) owns every write to `docs/narrative/` and `docs/domain/` after the bootstrappers create them. It reloads the sibling skills verbatim for the output schema, frontmatter contract, BC heuristics, and exclusion globs — no fork, no copy. This file owns what the siblings do not cover: the hybrid diff strategy, the path -> BC classifier, the per-BC SHA pre-check, the fence splice, `last_generated_sha` semantics, the removed-BC log-only rule, the byte-perfect idempotency contract, and `## Known coupling` / `## Migration caveat`.

## Inputs

- `[path]` (optional) — local filesystem path to the target repo; defaults to the working directory. Local path only: no remote URLs, no clone, no checkout side-effect. Same semantics as `/project:explore`.

Fully agent-driven: every change, including a new bounded context, is written with no approval gate and no interactive pause. No `--bypass-approval` flag exists. Only `## Pre-flight refuse condition` stops a run.

## Scan scope + reconciliation (repo-layout manifest)

Resolve scan scope via the `repo-layout` skill before walking, and honour its `## Read discipline` for every file opened — identically to the bootstrap siblings. Walk up from `[path]` to the scan root, read the matching `repos[]` entry, scan declared roots minus effective excludes (allowlist), or whole repo minus excludes when the entry omits `roots`, or built-in heuristics + the matching advisory when no manifest/entry exists. No manifest -> output byte-identical to pre-manifest runs.

**Reader-side reconciliation — the enhancer is read-only on `repo-layout.md`** (`repo-layout` skill `## Reconciliation` reader half, `## Ownership (single writer, many readers)`):

- **Undeclared source-bearing dir** (survives effective excludes, contains first-class source, under no declared root) → provisionally include it this run and print the new-root advisory from `## Advisory literals`. It also classifies `new-namespace` and auto-creates its BC as usual. Never silently skipped — the allowlist narrows known noise, never new code.
- **Declared path absent on disk** → print the stale advisory. Informational only; persisting manifest changes is `/wiki:enhance`'s job.

## Pre-flight refuse condition

Before any skill load or diff step, check `docs/domain/` of the working directory (not `[path]`). Missing or empty → refuse with the literal message and exit before skill load:

```
docs/domain/ is missing or empty. Run /project:explore first to bootstrap, then /project:update to update.
```

This is `project-explorer`'s refusal in reverse: it refuses when `docs/domain/` is non-empty, this one when it is missing or empty.

## Output root (nested mode)

Given an `output_root`, target `<output_root>/docs/narrative/` and `<output_root>/docs/domain/` for the pre-flight check, the tree-presence advisories, and all writes. The scan `<path>` and every `file:line` citation are unaffected. Absent → bare `docs/` of the working directory. Set by the orchestrator per the `wiki-orchestration` skill `## Output root (nested mode)`.

## Tree-presence advisories

| Narrative | Domain | Behaviour |
|---|---|---|
| yes | yes | Both passes run and auto-write. Happy path. |
| yes | no | Domain-absent advisory; narrative pass only. |
| no | yes | Narrative-absent advisory; domain pass only. |
| no | no | Refused at the command layer before any agent spawn; that refusal is authoritative. |

Domain-absent advisory, printed literally:

```
Note: docs/domain/ not present. Run /project:explore first to enable schema enhancement.
```

Narrative-absent advisory, printed literally:

```
Note: docs/narrative/ not present. Run /project:overview first to enable narrative-informed domain regeneration.
```

## Dual-pass orchestration

- **Fixed order:** narrative pass first, then domain pass. No `--reverse-order`, `--narrative-only`, or `--domain-only` in v1.
- **Why:** the domain pass reads `docs/narrative/<bc>/walkthrough.md` as soft input. Narrative-first makes one invocation converge, because the narrative pass auto-writes before the domain pass reads it.
- **Both passes always run** for whichever trees are present. Neither can halt or escalate.
- **Shared run summary.** Counts aggregate across passes into one block, and the zero-write message fires **once per run** when both passes together wrote nothing (`## Idempotency exit`).

## Operating procedure

Steps 0-12, in order. Later sections give the precise contract per step.

0. **Run-mode dispatch.** Read `## Tree-presence advisories`; plan narrative pass first, domain pass second, for whichever trees exist.
1. **Resolve target.** Resolve `[path]` (default: working directory). Apply `## Pre-flight refuse condition`.
2. **Skill load (all three), locked order.** `project-update` (this file) → `project-overview` → `project-explorer`. See `## Skill reload contract`.
3. **Diff strategy selection.** Sample one file's `last_generated_sha`; pick git fast path or full-walk fallback per `## Hybrid diff strategy`.
4. **Classify changed files** into exactly one of `BC-affecting` / `infra — no BC impact` / `new-namespace` per `## Path -> BC classifier`.
5. **New-BC discovery.** If the `new-namespace` bucket is non-empty, print the candidate report, then auto-create the folders. See `## New-BC discovery (auto-write)`.
6. **Removed-BC logging.** Append one bullet per disappeared namespace to `context-map.md`'s `## Skipped candidates`. Never delete anything. See `## Removed-BC logging`.
7. **Per-BC SHA pre-check (domain).** For each `BC-affecting` BC, decide SKIP or fall-through per `## Per-BC SHA pre-check`.
8. **Regenerate in memory** every bucket-(a) BC the pre-check did not SKIP plus every bucket-(c) candidate. No writes yet.
9. **Fenced human-edit zone splice.** Splice on-disk fenced blocks into the regenerated content verbatim.
10. **Byte-compare + selective write.** Write only when bytes differ; refresh frontmatter per `## Frontmatter refresh rules`.
11. **`last_generated_sha` advancement.** Stamp it on every file written in step 10; omit it entirely on the no-git path.
12. **Idempotency exit** per `## Idempotency exit`.

## Skill reload contract

Three skills reload at the start of every run, in this locked order:

1. the `project-update` skill — this file.
2. the `project-overview` skill — authoritative for the narrative-side output schema, frontmatter contract, fence convention, and the `## Diff-aware update mode` sub-sections.
3. the `project-explorer` skill — authoritative for everything both passes regenerate against: `## Output schema`, `## Frontmatter contract`, `## Comment policy (code is the single source of truth)`, `## BC candidate surfacing` (`### Grouping rule` feeds `### Namespace -> BC mapping`; `### Candidate report format` feeds the new-BC audit trail).

The eight exclusion globs and the read discipline come from the `repo-layout` skill (`## Built-in scan filters`, `## Read discipline`), which all three agents preload.

**Two files are read on demand, not preloaded** — they were moved out of the sibling skills so the one-shot bootstrappers stop carrying update-only text in every request's preamble. The enhancer is their only consumer:

- the `project-overview` skill's `./references/diff-update.md` — the eight `## Diff-aware update mode` contracts in full. Read **before the narrative pass begins**. The sibling's headings are forwarding stubs, so every citation of the form "the `project-overview` skill `## <heading>`" still resolves.
- the `project-explorer` skill's `./references/reverse-mapping.md` — `### Reverse mapping (BC -> source paths)` in full. Read **before `## Per-BC SHA pre-check`** runs, on both passes.

Inferring a moved contract from its stub instead of reading the file is a stop condition.

## Hybrid diff strategy

A global sample-one fast path decides whether there is any change to act on; the per-BC `## Per-BC SHA pre-check` then decides, per BC, whether that BC's slice moved.

### Git fast path

Fires when **all three** preconditions hold, evaluated in this order:

1. `[path]` is a git working tree — `git -C <path> rev-parse --git-dir` succeeds.
2. `last_generated_sha` is present in the frontmatter of at least one file under `docs/domain/`. Sample **one** file: all frontmatter advances together on every successful run.
3. That SHA is reachable from HEAD — `git -C <path> merge-base --is-ancestor <last_generated_sha> HEAD` succeeds.

On success run:

```
git -C <path> diff --name-only <last_generated_sha>..HEAD
```

then apply `### Exclusion globs (verbatim)` (globs first, terminal), then map survivors via `### Namespace -> BC mapping`. Surface the audit line:

```
Diff strategy: git fast path (<last_generated_sha>..HEAD)
```

### Full-walk fallback

Fires when **any** git-fast-path precondition fails: no git working tree; `last_generated_sha` absent from the sampled frontmatter (legacy bootstrap or wiped field); or the SHA present but unreachable (force-push, rebase, or deleted commit).

Walk every BC under `[path]` per the `project-explorer` skill and compare every regenerated file in memory against disk. The fallback is a strict superset of the fast path's correctness — both are byte-perfect idempotent; the fast path is purely a speedup.

**Reason-token short-circuit (load-bearing).** Evaluate the three preconditions in the order above and take the reason token from the **first** failure — git-tree fails → `missing-git` (later checks not run); SHA-present fails → `missing-sha`; reachability fails → `unreachable-sha`. Never a compound token. Surface the audit line:

```
Diff strategy: full-walk fallback (reason: <missing-git | missing-sha | unreachable-sha>)
```

### last_generated_sha tolerate-missing

Absent `last_generated_sha` — a tree bootstrapped before the `project-explorer` frontmatter contract carried the field, or any no-git path — falls through to the full-walk fallback with reason `missing-sha`. The enhancer never refuses on a missing or unreachable SHA. A freshly bootstrapped tree no longer reaches this path: the sibling stamps the field at bootstrap per the `project-explorer` skill `## Frontmatter contract`.

Per-path lifecycle:

| Path | Writer behaviour | Next run |
|---|---|---|
| Git, first run (`missing-sha`) | Stamp `last_generated_sha = <current HEAD SHA>` on every file written. | Fast path **only if that run wrote at least one file**. A zero-change refresh writes nothing, so the field stays absent and every later run pays the walk again — legacy trees need a backfill to escape. |
| Git, after force-push (`unreachable-sha`) | Re-stamp to current HEAD. | Fast path. Recovery is automatic, no user action. |
| No git (`missing-git`) | Omit the field entirely — the YAML key does not appear. | Full-walk fallback again. No transition to the fast path exists. |

## Path -> BC classifier

### Exclusion globs (verbatim)

The eight globs the classifier applies, verbatim — owned by the `repo-layout` skill `## Built-in scan filters` and never forked here:

- `**/bin/**`
- `**/obj/**`
- `**/node_modules/**`
- `**/dist/**`
- `**/*Tests/**`
- `**/*.Tests/**`
- `**/*.generated.*`
- `**/*Designer.cs`

**Ordering rule (load-bearing).** Globs first, terminal: every path matching any of the eight is bucketed `infra — no BC impact` immediately and is **never** re-evaluated against the namespace mapping, the new-namespace detector, or any other rule. Only survivors reach `### Namespace -> BC mapping`.

This holds even under a brand-new folder. A changed `**/SomeNewBc/bin/Foo.dll` matches `**/bin/**`, buckets `infra — no BC impact`, and `SomeNewBc` never surfaces in the `new-namespace (candidates: ...)` parenthetical.

### Namespace -> BC mapping

Reuses the `project-explorer` skill `## BC candidate surfacing` `### Grouping rule` verbatim; no taxonomy is invented here. Applied only to paths that survived the glob filter:

- `BC-affecting` **iff** the folder/namespace matches an existing `<bounded-context>/` folder under `docs/domain/` (reverse lookup through the grouping rule).
- `new-namespace` **iff** it matches no existing BC but lives under a namespace/folder structure that would itself qualify as a BC candidate.
- `infra — no BC impact` when it lives under no recognizable namespace/folder structure (e.g. a repo-root `README.md`).

### Classification buckets

| Bucket | Definition | Action |
|---|---|---|
| `BC-affecting` | Survives the globs AND lives under a known BC. | Add the owning BC to the re-walk set. |
| `infra — no BC impact` | Excluded by the globs OR survives them but is under no known BC. | No re-walk; logged for auditability. |
| `new-namespace` | Survives the globs AND lives under a namespace not mapped to any existing BC. | Auto-creates the BC after printing the candidate report. Under a manifest, also print the new-root advisory when the path is under no declared root. |

**Per-bucket count summary.** Immediately after the `Diff strategy:` line and before any later output, print exactly once:

```
Classified: <N> BC-affecting (BCs: <comma-separated, alphabetical>), <M> infra, <P> new-namespace (candidates: <comma-separated, alphabetical>)
```

The three nouns `BC-affecting`, `infra`, `new-namespace` are invariant — never pluralised. Name lists sort alphabetically, case-insensitive. `infra` carries **no** parenthetical. An empty parenthetical renders `(none)`. The count integer is always present even at zero (e.g. `0 BC-affecting (BCs: (none))`).

## Per-BC SHA pre-check

A per-BC speedup sitting **in front of** regen, on top of the global fast path. For each `BC-affecting` BC it decides whether that BC's source slice moved since its pages were written; unchanged → **SKIP** the whole BC (no regen, no splice, no byte-compare, no write). It never under-skips: every ambiguous or incomplete input degrades to over-regen.

**Scope.** Only the `BC-affecting` bucket. New-namespace candidates, removed-BC folders, and the roll-ups `docs/domain/context-map.md` + `docs/domain/glossary.md` are out of scope and keep the full path — a new namespace has no prior SHA, a removed BC regenerates nothing, and the roll-ups are cross-BC aggregates with no per-BC slice.

**Source-path resolution.** Resolve each BC's `<bc-source-paths>` via the `project-explorer` skill `## BC candidate surfacing` `### Reverse mapping (BC -> source paths)` (full text in that skill's `./references/reverse-mapping.md`). Cited by exact heading name; the mechanics are never restated here.

**SHA gather.** Gather `last_generated_sha` from **every** file under `docs/domain/<bc>/` — explicitly **not** the sample-one approach of `### Git fast path`, because a partial prior run can leave divergent per-file SHAs inside one BC.

**Gate 1 — any missing or unreachable SHA → no skip.** Any file with a missing SHA (legacy bootstrap, wiped) or an unreachable one falls the BC through to regen. Reachability uses the same test as the hybrid strategy: `git -C <path> merge-base --is-ancestor <sha> HEAD`. No new reachability test is invented.

**Gate 2 — empty or unresolvable path set → no skip.** When the inversion returns nothing resolvable — renamed, merged, or split BC; ambiguous spread; or the `module-map` fallback token — regen fully. Ambiguity degrades to over-regen; a false SKIP is impossible by construction.

**Base selection — oldest-wins.** When every SHA is present and reachable, base = `min(reachable SHAs)` across the BC's files. A partial prior run leaves divergent per-file SHAs, so anchoring to the most-stale file catches any change since the earliest write; sample-one or newest-wins could pick a freshly-advanced SHA and miss it.

**Decision.** Run:

```
git -C <path> diff <base>..HEAD -- <bc-source-paths>
```

- **Empty diff → SKIP the whole BC.** Nothing regenerated, spliced, compared, or written. Emit the verbose skip line under verbose/debug mode only; a normal run stays silent.
- **Non-empty diff → fall through** to `## Regenerate -> fence-splice -> byte-compare -> selective write`, where byte-compare remains the correctness net.

**Per-pass independence.** The domain pass decides independently of the narrative pass: in one run it MAY SKIP a BC the narrative pass regenerates, or vice versa. The trees carry independent SHAs and independent source slices. Expected, not a bug. Narrative mirror: the `project-overview` skill `## Per-BC SHA pre-check (narrative)`.

### Skip log line (verbose/debug only)

Defined exactly once, byte-for-byte:

```
SKIP bc=<name> pass=<domain|narrative> (sha unchanged)
```

`<name>` is the on-disk `<bounded-context>/` folder name, case preserved verbatim — the same identifier the removed-BC log and the `Classified:` line use. The domain pass emits `pass=domain`; the narrative pass reuses this same literal with `pass=narrative` by citing this heading, and never redefines it.

**Emission.** Verbose/debug mode only, once per SKIPPED BC, at the moment of the decision. A normal run emits nothing for a skipped BC.

**Not a stable contract.** It is a test-fixture aid, deliberately not an always-on audit line — promoting it would add output to the zero-write run and break the silent-on-zero-write contract. The three locked surfaces are unchanged by it: `No changes detected. 0 files written.`, `Diff strategy:`, and `Classified:`.

## New-BC discovery (auto-write)

### Trigger

Fires when the `new-namespace` bucket is non-empty. Empty → no candidate report; proceed to step 6 (removed-BC logging).

### Reused contract (verbatim)

Print the candidate report using the `project-explorer` skill `### Candidate report format` verbatim — the numbered `### BC candidates` list with per-candidate `Rationale` and `Aggregates detected` (aggregate root + `file:line` as an inline-code span), the `### Fallback flag` line, and the `### Conflicts detected` subsection (`(none)` when empty). Informational only: the agent never prompts and never waits. No approval-gate contract is reused; that contract was removed from the sibling skill.

On an enhancer run the `### Fallback flag` is **always** the literal token `false` — the small-repo fallback is a bootstrap-only signal.

### Auto-write behaviour

Create a `<bounded-context>/` folder under `docs/domain/` for **every** candidate, then populate it through the normal writer path per the `project-explorer` skill `## Output schema` `### Per-file content contract` and `### Write order`. Every file in a fresh folder carries all five frontmatter fields stamped fresh per `## Frontmatter refresh rules`.

## Removed-BC logging

For each `<bounded-context>/` folder under `docs/domain/` whose namespace is gone from source, append one bullet to `context-map.md`'s `## Skipped candidates` H2 section:

```
<bc-name>: namespace no longer present
```

Never delete the folder, never delete or rewrite any file inside it, never touch anything beyond that single `context-map.md` append. That append is the only on-disk change a disappeared namespace causes.

### Detection

For each `<bounded-context>/` folder currently on disk, reverse-look-up the folder name against the `project-explorer` skill `## BC candidate surfacing` `### Grouping rule`: does a namespace token or folder path under `<path>` still map to it? No match → removed. Detection is independent of the diff strategy; both paths walk every folder and apply the lookup.

### Log target and bullet format

Append to the existing `## Skipped candidates` H2 section in `docs/domain/context-map.md` — the bootstrap writer emits that section, and the enhancer only appends to it. Bullet format, exactly:

```
- <bc-name>: namespace no longer present
```

`<bc-name>` is the on-disk folder name (e.g. `legacy` for `docs/domain/legacy/`), **not** the source namespace token (e.g. `Acme.Legacy`) — the folder name is what the reader sees in their tree, and the namespace may already be gone from source. Case preserved verbatim.

### Idempotency of the log

Before appending, read the section body and check for an existing match:

- **Exact-line match** including the leading `- ` bullet prefix. `* legacy: namespace no longer present` or a prefix-less line does **not** match.
- **Case-sensitive** — `- Legacy: ...` does not match `- legacy: ...`.
- **Scoped** to the body between `## Skipped candidates` and the next H2 (or EOF). A match elsewhere in `context-map.md` does not count.

A match suppresses the append, so the section grows monotonically and a suppressed append produces zero on-disk writes.

### `(none)` placeholder handling

When the section body is the literal single line `(none)` (the bootstrap placeholder), replace that one line in place with the first bullet. The heading line and any blank lines above and below are preserved verbatim. Later appends add bullets underneath normally; the rule does not re-fire, because the body is no longer the literal `(none)`.

### Strict no-delete contract

Log-only, reaffirmed: never delete the folder, never delete any file inside it (including fenced human-edit zones), never rewrite any file inside it — no regen, no splice, no frontmatter refresh. Every file under a removed BC retains its prior `generated_at` and `last_generated_sha` byte-for-byte. The folder is frozen until a human removes it.

### Reason token (locked)

Exactly `namespace no longer present`, verbatim, no variants. Future tokens (`renamed to <new-bc>`, archival or merge reasons) are deferred and never appear in v1. The bullet is one locked string with one placeholder, `<bc-name>`.

## Regenerate -> fence-splice -> byte-compare -> selective write

### Regenerate in memory

Regenerate per-file content for every `BC-affecting` BC the pre-check did not SKIP plus every `new-namespace` candidate, per the `project-explorer` skill `## Output schema` `### Per-file content contract`, scoped to that BC's slice. `infra — no BC impact` BCs are not re-walked; removed BCs are excluded entirely.

Files regenerated per BC: `<bounded-context>/glossary.md`, `<bounded-context>/aggregates/<aggregate>.md` (one per aggregate root), `<bounded-context>/events.md`, `<bounded-context>/commands.md`, `<bounded-context>/repositories.md`, `<bounded-context>/services.md`. The roll-ups `docs/domain/context-map.md` and `docs/domain/glossary.md` regenerate whenever **any** BC changes.

**In-memory only.** Nothing is written at this stage; output is held as a `{ path -> regenerated-content-string }` map keyed by absolute path.

### Fenced human-edit zone splice

**Markers.** Exactly `<!-- human:begin -->` and `<!-- human:end -->`, each on its own line. Marker-line leading/trailing whitespace is tolerated (trimmed before matching). Content between markers is preserved byte-for-byte, blank lines and whitespace included.

**Per-file algorithm.** For each `(path, regenerated-content)` pair:

1. Read the on-disk file. Missing (a new file under a fresh BC) → skip the splice; the regenerated content goes straight to `### Byte-compare`.
2. Scan for markers. Zero fences → use the regenerated content as-is (`## Migration caveat`). One pair → step 3. Multiple pairs → loop step 3 for each, preserving all at their anchor positions.
3. Locate the same anchor position in the regenerated content (the line index of `<!-- human:begin -->` within the agent-owned content; with no matching anchor, splice at the same line-index offset from the top). Replace `<!-- human:begin -->` through `<!-- human:end -->` inclusive with the verbatim on-disk block.
4. The post-splice string is the byte-compare candidate.

**Never-touch invariant.** The agent never modifies content between the markers, and never modifies the marker lines themselves — no normalisation, no whitespace rewrite, no re-emission. Splicing the on-disk bytes verbatim is its only obligation inside a fence.

Anchor drift across regenerations is a known limitation; keep fenced blocks adjacent to a stable heading (e.g. immediately after an H2) if exact placement matters.

### Byte-compare

Serialize the post-splice content to UTF-8 bytes, read the on-disk file as bytes, compare. **Write only when bytes differ.**

**Byte-exact, no normalization:** trailing-newline, BOM, and CRLF-vs-LF differences are all real differences that trigger a write. The enhancer never normalizes line endings; regenerated content emits LF only.

Identical bytes → the file is skipped: no write, no frontmatter refresh, no SHA stamp; prior `generated_at` and `last_generated_sha` preserved byte-for-byte. This is the per-file foundation of the zero-write run.

### Selective write + frontmatter refresh

**Write trigger.** A file is written **iff** byte-compare returned "differ".

**Refresh order on a write:**

1. **Strip** the placeholder frontmatter from the regenerated content string.
2. **Construct** the new block, five fields in this order, per `## Frontmatter refresh rules`:
   - `source_repo` — preserved verbatim from the on-disk frontmatter; never refreshed.
   - `branch_name` — the current invocation's arg, or the bare YAML `null` token when omitted (never the quoted string `"null"`).
   - `generated_at` — a fresh ISO-8601 UTC second-precision `Z`-suffixed timestamp.
   - `skill_version` — the current integer of the **`project-explorer`** skill's `version` field, not this skill's; output-schema versioning belongs to the schema owner.
   - `last_generated_sha` — current HEAD SHA on any git path (`missing-sha` and `unreachable-sha` are git-available, so they still stamp); **omitted entirely** only on the no-git `missing-git` path.
3. **Prepend** the block as the first content of the file, before any heading.
4. **Write** as UTF-8, LF, no BOM, in the `project-explorer` skill `### Write order`.

Files the enhancer did not write keep their prior `last_generated_sha`. After a run where N of M files changed, both the N new-SHA files and the M-N old-SHA files are valid sampling points next run — the sampled SHA only has to be reachable from the new HEAD.

**New-file case.** No on-disk content to read, so splice and byte-compare are skipped and the write proceeds with fresh frontmatter and the regenerated content as-is.

## Frontmatter refresh rules

| Field | Refresh trigger | Preserved when | Notes |
|---|---|---|---|
| `source_repo` | Never refreshed by the enhancer. | Always. | Locked by the `project-explorer` frontmatter contract. |
| `branch_name` | On real content change, to the invocation's arg or bare `null`. | Untouched files keep prior value. | Same YAML scalar rules as the sibling contract. |
| `generated_at` | Only when post-splice bytes differ for **this specific file**. | Untouched files keep prior value even after a successful run. | Content-change semantics. |
| `skill_version` | On real content change, to the `project-explorer` skill's `version`. | Untouched files keep prior value. | The schema owner's version, not the enhancer's. |
| `last_generated_sha` | Stamped on every file written, advancing to current HEAD each successful git-path run regardless of content change. | Untouched files keep prior value; no-git runs omit the field entirely. | Run-tracker semantics; tolerate-missing on first run. |

## Idempotency exit

**Zero-write exit.** When the run wrote **zero** files — zero regenerated files, zero new BCs, zero removed-BC bullets — print **exactly one line** and exit:

```
No changes detected. 0 files written.
```

No summary, no banner, no `Diff strategy:` line, no `Classified:` line, nothing else. This is the canonical signal downstream automation can grep for.

**Non-zero-write exit.** When at least one write occurred, print this summary and exit:

```
<N> files written.
<P> new BCs created: <comma-separated names or "(none)">.
<R> removed BCs logged: <comma-separated names or "(none)">.
Diff strategy: <git fast path (<sha>..HEAD) | full-walk fallback (reason: <token>)>
```

`<N>`, `<P>`, `<R>` are integers; empty name lists render `(none)`; the `Diff strategy:` line repeats the earlier audit line.

**No partial exit.** If any pipeline step errors, surface the error and exit non-zero. Partial on-disk state is acceptable — the next run's byte-compare reconverges. The zero-write message is emitted only on a successful zero-write run, never on a partial failure.

## Known coupling

The enhancer reloads two sibling skills verbatim, so an edit to any contract below silently changes enhancer behaviour. Whoever edits a sibling must re-read this skill end-to-end before calling the edit done. No `skill_version` pin or `compatible_with` check exists or is planned — this section is the trip-wire.

Reloaded by name from the `project-explorer` skill:

- `## Output schema` (`### Files written`, `### Per-file content contract`, `### Small-repo fallback variant`, `### Write order`, `### Hallucination guard`).
- `## Frontmatter contract` — the five-field block, `last_generated_sha` included since the sibling stamps it at bootstrap; this skill refreshes the block per `## Frontmatter refresh rules`.
- `## Comment policy (code is the single source of truth)` — code-only derivation for every regenerated logic, invariant, and `file:line` fact. The narrative pass inherits the mirrored copy in the `project-overview` skill `## Comment policy (code is the single source of truth)`.
- `## BC candidate surfacing` `### Grouping rule` — feeds `### Namespace -> BC mapping`.
- `## BC candidate surfacing` `### Reverse mapping (BC -> source paths)` — feeds `## Per-BC SHA pre-check`. It is the **strict inverse** of the grouping rule and shares its single source of truth, so any edit to `### Grouping rule` changes the inverted path set, the `<bc-source-paths>` fed to `git diff`, and the SKIP decision. Re-derive it on every grouping-rule edit.
- `### Small-repo fallback detection` and, through it, the `repo-layout` skill `## Built-in scan filters` — the verbatim source of `### Exclusion globs (verbatim)`.
- `### Candidate report format` — reused by `## New-BC discovery (auto-write)`.

Reloaded from the `project-overview` skill: `## Diff-aware update mode` and its six sub-sections (`## Hybrid diff strategy (narrative)`, `## Path -> BC classifier (narrative)`, `## Fenced human-edit zone splice (narrative)`, `## Removed-BC logging (narrative)`, `## Byte-compare + selective write + frontmatter refresh (narrative)`, `## Idempotency exit (narrative)`), whose full text lives in that skill's `./references/diff-update.md`. The narrative pass uses them; the domain pass does not.

**Mirrored, not inherited.** The `project-overview` agent no longer preloads the `project-explorer` skill, so `## BC candidate surfacing` and `## Comment policy (code is the single source of truth)` exist in both bootstrap skills and must be edited in both in the same change. The enhancer preloads both, so drift surfaces here first.

## Migration caveat

> **At the moment regen fires, the original contract still holds.** A human edit made **outside** a `<!-- human:begin --> ... <!-- human:end -->` fence is overwritten by the regenerated content, exactly as before. Wrap an edit in fences before invoking `/project:update` to keep it.
>
> **What the per-BC pre-check shifts.** Regen no longer fires for a BC whose source slice is unchanged, so an outside-fence edit now survives until that slice changes — then regen fires and overwrites it exactly as before, just deferred.
>
> **The durable-across-source-change invariant is unchanged.** Fences remain the **only** way to make an edit durable across a source change. An outside-fence edit gets a reprieve while its BC's slice is still, not durability in general.
>
> This is a deliberate, accepted contract shift, not a regression: the pre-check narrows *when* overwrite happens, and the wording above states that truthfully instead of leaving the old always-overwrite description in place.
