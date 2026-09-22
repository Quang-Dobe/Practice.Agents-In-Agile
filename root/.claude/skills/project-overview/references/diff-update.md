---
name: diff-update
description: Narrative-pass diff-aware update contract - the eight sections /project:update's narrative pass consumes. Read on demand by the project-update agent; never preloaded by the project-overview bootstrap agent.
owner: project-overview skill
---

# Narrative diff-aware update contract

These sections were moved out of `../SKILL.md` because **only** the `project-update` agent's narrative pass consumes them. The `project-overview` bootstrap agent never enters update mode, so carrying them in its preamble cost tokens on every request of every bootstrap run and bought nothing.

**Citation compatibility.** Every heading below keeps its exact name, and `../SKILL.md` keeps a forwarding stub under each. An existing citation of the form "the `project-overview` skill `## <heading>`" therefore still resolves — it now names a stub that points here. The contracts themselves are unchanged.

## Diff-aware update mode

This section and every section below cite-by-reference contracts from the `project-update` skill and are loaded by the `project-update` agent when the narrative pass runs. The bootstrap `project-overview` agent ignores everything under this heading; the bootstrap agent's contract is fully described in `../SKILL.md` `## Operating procedure` and finishes at `## Stop conditions`.

## Hybrid diff strategy (narrative)

See the `project-update` skill `## Hybrid diff strategy` for the full contract (git fast path / full-walk fallback / reason-token short-circuit / first-failure-wins ordering / `last_generated_sha` tolerate-missing). The narrative pass samples ONE file under `docs/narrative/` for `last_generated_sha`; the sampled file is `architecture.md` or any `<bc>/walkthrough.md` (NOT `<bc>/glossary.md`, which exists only under `docs/domain/`).

The narrative pass surfaces the same `Diff strategy:` audit lines verbatim as the enhancer prints them for the domain pass — one line per run depending on which path fires:

```
Diff strategy: git fast path (<last_generated_sha>..HEAD)
```

```
Diff strategy: full-walk fallback (reason: <missing-git | missing-sha | unreachable-sha>)
```

## Path -> BC classifier (narrative)

See the `project-update` skill `## Path -> BC classifier` (including `### Exclusion globs (verbatim)`, `### Namespace -> BC mapping`, `### Classification buckets`, and the per-bucket count-summary audit line). The narrative pass reuses the same three buckets (`BC-affecting` / `infra — no BC impact` / `new-namespace`) and the same eight exclusion globs without modification.

## Per-BC SHA pre-check (narrative)

See the `project-update` skill `## Per-BC SHA pre-check` for the full per-BC pre-check contract (per-BC source-path resolution via the reverse mapping, per-BC SHA gather, conservative any-missing/any-unreachable/unresolvable -> no-skip gates, oldest-wins `min(reachable)` base, empty->SKIP / non-empty->fall-through). The narrative pass uses the **identical algorithm** — same gates, same oldest-wins base; only the inputs differ, not the logic. It does **not** fork or restate the gate logic, the SHA-gather loop, the reachability test, or the diff command — the enhancer section owns those literals and the narrative pass borrows them by reference.

**Narrative-side source slice.** The narrative pass resolves the **narrative** source slice for a BC — the endpoints / handlers / workers its `walkthrough.md` drills into — which is **distinct** from the domain slice (the aggregates / events / commands / repositories / services its schema rows cite). Same algorithm, different inputs. The narrative pass gathers per-file `last_generated_sha` from the BC's narrative output under `docs/narrative/<bc>/` (the narrative tree's **own** frontmatter), **not** from `docs/domain/<bc>/`. `architecture.md` is the repo-wide narrative roll-up and is **out of per-BC scope**, mirroring how `context-map.md` / `glossary.md` are roll-ups on the domain side. For which narrative files carry `last_generated_sha` and how the narrative pass samples them, see `## Hybrid diff strategy (narrative)` above (the sampled file is `architecture.md` or any `<bc>/walkthrough.md`) — that fact is not redefined here.

**Per-pass independence.** The narrative pass and the domain pass each own their **own** pre-check decision — independent decisions, not coupled. In a **single run** the narrative pass MAY **SKIP** a BC while the domain pass **REGENERATES** the same BC, **or vice versa** (the domain pass SKIPs a BC the narrative pass regenerates). This divergence is **expected and correct, NOT a bug**, and MUST NOT be "fixed" by coupling the two decisions — coupling would force regen of a tree whose own slice is unchanged, re-introducing the exact waste this feature removes. The two trees carry **independent** `last_generated_sha` values and **independent** source slices, which is the structural reason the decisions diverge.

**Reuse the skip line with `pass=narrative`.** The narrative SKIP reuses the **same** skip-line literal defined in the `project-update` skill `### Skip log line (verbose/debug only)` (cited by exact heading name); it does **not** redefine the parameterized literal. The narrative-side application emits the concrete instance:

```
SKIP bc=<name> pass=narrative (sha unchanged)
```

The **same** verbose/debug-only emission condition applies: the line is emitted only under verbose/debug mode, once per SKIPPED BC; a **normal** narrative-pass run stays **silent** for a skipped BC. The locked `No changes detected. 0 files written.` cross-pass exit is **unchanged** — per `## Idempotency exit (narrative)` it fires **once per run** across both passes, so the narrative SKIP introduces no new normal-run line.

## Fenced human-edit zone splice (narrative)

See the `project-update` skill `### Fenced human-edit zone splice` for the per-file algorithm, never-touch invariant, and anchor-drift limitation. The narrative pass uses the identical algorithm. The narrative fences have the two canonical placements defined in `../SKILL.md` `## Human-edit fences`; both placements survive the splice unchanged because the algorithm is anchor-position based, not section-name based.

## Removed-BC logging (narrative)

The narrative-side equivalent of the `project-update` skill `## Removed-BC logging`. For each existing `<bc>/` folder under `docs/narrative/` whose namespace is no longer present in source, the enhancer appends one bullet to the log target described below. **Never delete** the `<bc>/walkthrough.md` file. **Never delete** the `<bc>/` folder. **Never touch** any file inside a removed-BC folder beyond the single `architecture.md` append.

- **Log target.** The append target is the `## Skipped candidates` H2 section in `docs/narrative/architecture.md`. The bootstrap writer (operating procedure step 6) MUST also emit this `## Skipped candidates` section as part of the per-file content contract for `architecture.md`, rendering the body as `(none)` when bootstrap detected no skips — same convention as the domain side's `context-map.md`.
- **Bullet format.** Identical to the domain side. The bullet template is exactly `- <bc-name>: namespace no longer present` (single locked reason token per the `project-update` skill `### Reason token (locked)`).
- **Folder-name vs namespace-token disambiguation.** The `<bc-name>` is the on-disk folder name under `docs/narrative/<bc>/`, NOT the source namespace token. Case preserved verbatim from the filesystem. The folder name is the user-visible identifier the human reader recognises from their `docs/narrative/` tree; the source namespace token may already have disappeared by the time this code runs.
- **Idempotency of the log.** Before appending, the enhancer reads the body of the `## Skipped candidates` section and checks for an existing matching line. The duplicate check is **exact-line match** (the full literal line including the leading `- ` bullet prefix), **case-sensitive**, scoped between the `## Skipped candidates` H2 and the next H2 (or EOF). Verbatim per the `project-update` skill `### Idempotency of the log`. Note: in `docs/narrative/architecture.md`, `## Skipped candidates` IS the final H2 (it is inserted after `## Logic overview` per `../SKILL.md` `### Per-file content contract`), so the EOF clause of the scope rule is the one that fires for this file in practice.
- **`(none)` placeholder handling.** If the body of `## Skipped candidates` is the literal single line `(none)` (the bootstrap placeholder when no skips were detected), the enhancer replaces that line **in place** with the first bullet on first append. Identical replacement-in-place rule per the `project-update` skill `` ### `(none)` placeholder handling ``.
- **Strict no-delete contract.** Never delete `<bc>/walkthrough.md`. Never delete the `<bc>/` folder. Never rewrite any file inside a removed-BC folder beyond the single `architecture.md` append. The folder is frozen until the human author decides to remove it manually.
- **Tolerate-missing on first run.** If `## Skipped candidates` is absent from a pre-feature `docs/narrative/architecture.md` (bootstrapped before this feature shipped), the updater emits the section with the first bullet (or with `(none)` if no removed BCs were detected this run).

## Byte-compare + selective write + frontmatter refresh (narrative)

See the `project-update` skill `### Byte-compare` (UTF-8 byte-exact comparison; no normalization; skip-write decision) and `### Selective write + frontmatter refresh` (4-numbered-step refresh order; preserved `source_repo`; refreshed `branch_name`; refreshed `generated_at`; refreshed `skill_version`; `last_generated_sha` per the per-file git-path rule). The narrative pass writes only files whose post-fence-splice bytes differ from the on-disk bytes, exactly as the domain pass does. Frontmatter refresh stamps `skill_version` from this `project-overview/SKILL.md`'s `version` field (NOT the enhancer's), because output-schema versioning belongs to the schema owner — same rule the enhancer applies for the domain pass against the `project-explorer` skill version.

## Idempotency exit (narrative)

See the `project-update` skill `## Idempotency exit` for the zero-write exit message literal (`No changes detected. 0 files written.`), the non-zero-write summary format, and the no-partial-exit rule. **Cross-pass aggregation rule (load-bearing):** the canonical zero-write exit message is emitted **once per run**, NOT once per pass. It fires only when both passes (narrative + domain) together wrote zero files. On any non-zero-write run, the summary line aggregates counts across both passes — every write the narrative pass made plus every write the domain pass made contributes to the single run-summary line.

