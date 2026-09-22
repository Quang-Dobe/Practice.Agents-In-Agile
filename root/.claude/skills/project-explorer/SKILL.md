---
name: project-explorer
description: Operating manual for the project-explorer agent - bootstraps the Evans-canonical DDD wiki under docs/domain/.
version: 1
consumed_by: project-explorer agent
---

## Purpose

The operating manual the `project-explorer` agent reloads at the start of every run and treats as authoritative: DDD code signals, ubiquitous-language extraction, known failure modes, conflict resolution, and the Evans-canonical output schema. The co-located `research.md` carries the long-form citations and per-category enumerations this file cites by reference.

## Inputs

- `<path>` (required) — local filesystem path to the target repo. No remote URLs, no cloning, no git invocation; read-only.
- `[branch-name]` (optional) — recording-only, written to `branch_name` in each file's frontmatter. The user checks out the branch themselves; the agent never switches branches.

## Scan scope (repo-layout manifest)

Before the repo walk, resolve scan scope via the `repo-layout` skill. Walk up from `<path>` to the scan root and read the matching `repos[]` entry (`## Discovery (walk-up to the scan root)`):

- **Entry with `roots`** → walk ONLY the declared subtrees minus effective excludes (`## Scope resolution`). Each root's `bc` label pins its bounded-context name, overriding `### Grouping rule` namespace inference for signals under that root.
- **Entry without `roots`** → whole repo minus effective excludes.
- **No manifest, or no entry** → emit the matching advisory from `## Advisory literals` and walk with built-in heuristics; output byte-identical to pre-manifest runs.

**Safety net (load-bearing).** Even under an allowlist, an undeclared directory containing first-class source (passes the whitelist in the `repo-layout` skill `## Built-in scan filters`, not matched by effective excludes) is **provisionally scanned this run and flagged** with the new-root advisory — never silently skipped. Persisting the candidate to the manifest is `/wiki:enhance`'s job, not this read-only agent's.

## Output root (nested mode)

Given an `output_root`, write under `<output_root>/docs/domain/` and run the idempotency guard against that path instead of the bare `docs/domain/`. The scan `<path>` and every `file:line` citation are unaffected. Absent → bare `docs/domain/` of the working directory. Set by the orchestrator per the `wiki-orchestration` skill `## Output root (nested mode)`.

## Idempotency guard

Before reloading this skill, check `docs/domain/` of the **working directory** (not `<path>`).

**Refuse** when `docs/domain/` exists AND contains at least one non-hidden file, searched recursively. "Hidden" means a leading `.` — the POSIX convention, not the Windows attribute; `.git`, `.DS_Store`, `.gitkeep` do not trigger refusal. **Proceed** when the folder is missing, or exists with no non-hidden file; empty subtrees alone never refuse.

On refusal, print the literal message and exit before the skill-load step — no repo walk, no candidate surfacing, no writes:

```
docs/domain/ is not empty. project-explorer is a one-shot bootstrapper. Use project-update for updates.
```

## Operating procedure

Steps 1-7, in order. Later sections give the precise contract per step.

1. **Idempotency guard.** Resolve `<path>`; check the working directory's `docs/domain/`. Non-empty → refuse and exit before anything else runs.
2. **Skill load.** Reload this `SKILL.md` as the operating manual. Do not proceed if it is missing or malformed.
3. **Repo walk.** Resolve scan scope per `## Scan scope (repo-layout manifest)`, then scan in-scope source for the signals in `## Code signals` — aggregates, repositories, events, services, value objects, ubiquitous-language tokens. .NET signals are first-class; other stacks best-effort. Excludes test projects, generated files, `bin/`, `obj/`, `node_modules/`, `dist/` per the `repo-layout` skill `## Built-in scan filters`. Every file opened is governed by that skill's `## Read discipline` — never-read globs are hard, signatures come from `Grep`, files over 400 lines are read with `offset` / `limit`, and generated contracts are grepped rather than read.
4. **Narrative soft input.** Read `docs/narrative/` when present per `## Soft input: docs/narrative/`; absent → no-op.
5. **BC candidate surfacing** per `## BC candidate surfacing`. Names must trace to a real namespace or folder path; no invented taxonomy.
6. **Print candidate report (non-blocking)**, then proceed. No approval, no halt.
7. **Output generation + frontmatter.** Write the Evans-canonical tree per `## Output schema`; every file carries the four-field YAML block per `## Frontmatter contract`.

## BC candidate surfacing

The full contract for steps 5 and 6. The runtime agent consults this section verbatim — the spec lives here, not in the agent's body.

### Grouping rule

BC candidates MUST derive from observable repo namespacing, top-level project boundaries, or folder structure seen during the repo walk. Each candidate name MUST trace to a real namespace token or folder path; names that do not trace to source MUST be rejected before the report is printed — the agent does not invent taxonomy.

When namespace and folder structure disagree, prefer the namespace as the canonical name and record the folder path in the candidate's rationale.

### Reverse mapping (BC -> source paths)

Update-path only — the strict inverse of `### Grouping rule`, consumed by the `project-update` per-BC SHA pre-check and by nothing on the bootstrap path. The full contract lives in `./references/reverse-mapping.md`; read that file at the point of use rather than carrying it in every run's preamble. It is unchanged: deterministic re-application of `### Grouping rule` against the working tree, repo-root-relative POSIX pathspecs as output, empty/unresolvable (and always `module-map`) degrading to "cannot determine slice" -> no skip -> full regen, never persisted to frontmatter.

### Candidate report format

A markdown block printed for the audit trail before writing:

1. `### BC candidates` — numbered list, one item per candidate, with nested bullets:
   - **Rationale** — one line naming the contributing folders / namespaces (e.g. `folder: src/Ordering`, `namespace: eShop.Ordering`).
   - **Aggregates detected** — bulleted; each names the aggregate root and cites `file:line` as an inline-code span (e.g. `` `src/Ordering/Order.cs:42` ``).
2. `### Fallback flag` — one line with the boolean and the triggers that fired (see `### Small-repo fallback detection`).
3. `### Conflicts detected` — every divergent definition the walker found, per `## Conflict resolution`, each citing both definitions by `file:line`. Renders `(none)` when empty. The agent never silently picks a side without listing the conflict here.

### Small-repo fallback detection

Three independent triggers; any one match flips the flag to `true`:

1. Total first-class source files in `<path>` are `< 20`. First-class source is resolved by the language whitelist and the built-in 8 exclusion globs owned by the `repo-layout` skill `## Built-in scan filters` — cited, not restated here, so a reader that does not preload this skill still resolves them. `.py` files anywhere under `<path>` that survive the exclusion globs do count.
2. Only one top-level namespace or project exists across the walked source set. Zero namespaces counts as `<= 1` and fires this trigger.
3. BC candidate count after grouping is `<= 1`.

Report the flag as `true` / `false` with an explanation enumerating which triggers fired — e.g. `triggers fired: (i) total source files = 7 < 20; (iii) BC candidate count = 1`. When `true`, the report includes the literal token `FALLBACK: single-BC module-map` on its own line. The fallback path writes automatically like any other run.

### Auto-write contract

Fully agent-driven: after printing the candidate report the agent proceeds directly to output generation under `docs/domain/`. No APPROVE gate, no halt, no edit-revision loop — the report is the audit trail, then it writes. Only `## Idempotency guard` stops a run, and that is a re-run safety check, not an approval gate.

## Code signals

Concrete observable code patterns per DDD category. See `./research.md#ddd-code-signals` for the full enumeration (5 categories, >=3 signals each, .NET first-class, other stacks best-effort).

## Ubiquitous-language heuristic

Heuristic for extracting candidate glossary terms from code. See `./research.md#ubiquitous-language-extraction-heuristic` for the named heuristic and step-by-step recipe.

## Comment policy (code is the single source of truth)

**Code is the only source of truth for behaviour.** Every aggregate, invariant, event, command, repository, service row, and every `file:line` citation MUST derive from executable code — control flow, types, signatures, call graph, data shape. The agent reads code to learn what the system *does*; it does not read a comment to learn that.

**Comments, docstrings, and XML-doc are advisory seeds, never authority.** They MAY seed a plain-language glossary definition or per-aggregate description — the same advisory status narrative text holds. They MUST NOT:

- assert an invariant, event, command, repository, or service the code does not exhibit;
- supply or alter a `file:line` citation (it always points at the code construct, never the comment line);
- decide a bounded-context boundary (that traces to namespace / folder per `### Grouping rule`).

**Comments lose every conflict with code.** A stale `// returns null on failure` over a method that now throws, or a doc-comment naming an old aggregate — follow the **code** and record the divergence per `## Conflict resolution`. A comment never silently overrides a code-derived fact.

This is the comment-side companion to `### Hallucination guard` and `### Hallucination guard (narrative variant)`: input that is not executable code seeds naming and description only, never adds a row to the output schema, never invents a citation. The `project-overview` skill mirrors this section under the same heading; edit both together.

## Soft input: docs/narrative/

### When narrative is read

After the repo walk and before BC candidate surfacing, check the working directory's `docs/narrative/` for `architecture.md` and any `<bc>/walkthrough.md`. Filesystem-only — no git, no remote, no cloning. Neither path exists → skip this entire section and surface candidates with no narrative input.

### Backward-compat invariant

Narrative absent or empty → behaviour is **byte-identical** to runs before this section existed. Output schema, frontmatter contract, write order, hallucination guard, and auto-write all run unchanged. A repo that never invoked `/project:overview` MUST produce the same `docs/domain/` tree (modulo `generated_at` and a moved `last_generated_sha`). Any divergence is a regression.

### How narrative augments BC candidate surfacing

- **(a) Candidate ordering.** When `architecture.md` has a `## Logic overview` listing BCs, use that order as the **display order** in the candidate report. Which BCs surface is unchanged — only the order.
- **(b) Description seeds.** When `<bc>/walkthrough.md` has drill-down sections for a detected endpoint or handler, its plain-language description may seed the BC's per-aggregate description in the rationale line. A suggestion only: the agent still cites `file:line` for the detection itself, and prose without a citation is never elevated to the canonical aggregate doc.
- **(b-marker) Rationale-line marker.** When narrative augmented this candidate (rule (a) or (b) applied to THIS bc), the `Rationale` line gains a third comma-separated entry of the literal form `narrative: docs/narrative/<bc>/walkthrough.md` (relative path, lowercase). Existing `folder: ...` and `namespace: ...` entries stay byte-identical and precede it, in source-of-truth order: folder, namespace, narrative. When narrative did not augment this candidate — absent, malformed, or no rule applied — the `narrative:` entry is omitted entirely. This is the grep-able marker for augmentation.
- **(c) Name preference (advisory).** When `docs/narrative/<bc>/` exists as a folder and its name disagrees with the namespace token, the folder name may be preferred as the display name. No narrative folder → fall back to the namespace token. Advisory: `### Grouping rule` itself is unchanged.

### Hallucination guard (narrative variant)

Soft input is *input*, not *source of truth*. Code remains authoritative for every `file:line`, every aggregate detection, and every row in the output schema. Never invent a citation, aggregate, event, or BC because the narrative says so. Narrative shifts display order and seeds descriptions; it never adds rows. A BC the narrative claims and the code walk does not detect is logged in `context-map.md`'s `## Skipped candidates` as `<narrative-claimed-bc>: not detected by code walk (narrative said exists; no namespace / folder match)` and is NOT promoted to a `<bounded-context>/` folder.

### Malformed narrative degraded path

If a narrative file exists but its YAML frontmatter does not parse — missing block, malformed YAML, or fewer than the four sibling-parity fields `source_repo` / `branch_name` / `generated_at` / `skill_version` — log the literal line `narrative file at <absolute-path>: malformed (frontmatter does not parse); skipping soft-input augmentation` with the real absolute path, and proceed as if that file did not exist. No stop condition fires. `last_generated_sha` is tolerate-missing and does not count toward the four required fields.

## Output schema

An Evans-canonical tree under `docs/domain/` of the working directory.

### Files written

```
docs/
  domain/                           # OUTPUT TARGET (written at runtime, not at scaffold-author time)
    context-map.md
    glossary.md
    <bounded-context>/
      glossary.md
      aggregates/<aggregate>.md
      events.md
      commands.md
      repositories.md
      services.md
```

### Per-file content contract

All `file:line` citations use paths relative to the `<path>` root. Empty sections render as `(none)` rather than being omitted, preserving the locked file shape for downstream `project-update`. Every file carries the four-field YAML block from `## Frontmatter contract` as its first content.

| File | Required content |
|---|---|
| `context-map.md` | Numbered list of confirmed BCs (one per `<bounded-context>/` folder); one short paragraph per BC describing relationships to other BCs (upstream / downstream / shared kernel / partnership / customer-supplier / open-host service / anti-corruption layer). Ends with a `## Conflicts detected` H2 (bulleted `<conflict-description>: <file:line>, <file:line>`; `(none)` when empty) and a `## Skipped candidates` H2 (bulleted `<candidate-name>: <reason for omission>`; `(none)` when empty). |
| `glossary.md` (repo-wide) | Term -> definition table from the ubiquitous-language heuristic (`research.md#ubiquitous-language-extraction-heuristic`). Header row `\| Term \| Definition \|`. Terms appearing across `>= 2` BCs go here; BC-local terms go in the per-BC glossary. `(none)` when no cross-BC terms. |
| `<bounded-context>/glossary.md` | Same table scoped to that BC, same header row. `(none)` when no BC-local terms. |
| `<bounded-context>/aggregates/<aggregate>.md` | `# <AggregateName>` H1 + bulleted invariants, at least one per file, each citing `file:line` as an inline-code span (e.g. `` `src/Ordering/Order.cs:42` ``). With no behavioural invariants detected the file is still emitted with the single bullet `(no invariants detected; see <ServiceName> at \`file:line\` for likely behaviour)` per the anemic-domain-model failure mode (`research.md#known-failure-modes`). The `aggregates/` directory is emitted even when empty, with no placeholder file inside. |
| `<bounded-context>/events.md` | Table `\| Name \| Emitting aggregate \| file:line \|`, one row per detected domain event. `(none)` body when none. |
| `<bounded-context>/commands.md` | Table `\| Name \| Target aggregate \| file:line \|`, one row per detected command. `(none)` body when none. |
| `<bounded-context>/repositories.md` | Table `\| Name \| Target aggregate \| file:line \|`, one row per detected repository interface. `(none)` body when none. |
| `<bounded-context>/services.md` | Table `\| Name \| Behavior summary \| file:line \|`, one row per detected domain service. `(none)` body when none. |

### Small-repo fallback variant

With the fallback flag `true`, emit the same file shape with exactly **one** `<bounded-context>/` folder named `module-map` — or named with the scanned root's manifest `bc` label when the root is pinned, which overrides the token. Throughout this section `module-map` denotes that single folder; substitute the `bc` label when pinned. All `### Per-file content contract` rules still apply inside it. The `context-map.md` body begins with the single line `Fallback active: single-BC module-map. See \`module-map/\` for module-by-module breakdown.`, replacing the numbered BC list. The `## Conflicts detected` and `## Skipped candidates` H2 sections are emitted as in multi-BC mode.

### Write order

Top-level files first, then each `<bounded-context>/` folder alphabetically:

1. `docs/domain/context-map.md`
2. `docs/domain/glossary.md`
3. Per BC, in this order: `<bounded-context>/glossary.md`, then `<bounded-context>/aggregates/<aggregate>.md` (alphabetical by aggregate name), then `<bounded-context>/events.md`, `<bounded-context>/commands.md`, `<bounded-context>/repositories.md`, `<bounded-context>/services.md`.

In fallback mode the single folder follows the same per-BC ordering.

### Hallucination guard

Every multi-BC `<bounded-context>/` folder name MUST match a real namespace token or folder path observed during the walk (`### Grouping rule`). Names with no source MUST NOT be emitted; log each omission in `context-map.md` under `## Skipped candidates` as `<candidate-name>: <reason for omission>`. That section renders `(none)` when nothing was rejected.

The rule applies in multi-BC mode only. In fallback mode the single folder is emitted with the literal name `module-map` whether or not the repo has such a namespace — it is an explicit fallback-mode token, not a discovered BC, and is exempt from trace-to-source. **Exception (manifest `bc` pin):** a scanned root carrying a `bc` label in `repo-layout.md` names the fallback folder with that label instead. `module-map` is used only when no pin applies.

## Frontmatter contract

Every file under `docs/domain/` carries a four-field YAML block as its **first content**, before any heading. A heading before the block means the file is malformed.

- **`source_repo`** — `<path>` resolved to an absolute path, normalized to POSIX forward slashes, trailing slashes stripped. UNC paths and symlinks pass through as the OS resolves them.
- **`branch_name`** — the `[branch-name]` argument as a YAML scalar (e.g. `branch_name: main`), or the bare YAML `null` token when omitted — never the quoted string `"null"`.
- **`generated_at`** — ISO-8601 UTC, second precision, literal `Z` suffix, e.g. `2026-05-18T10:30:00Z`. No sub-second precision; always UTC.
- **`skill_version`** — integer matching this file's frontmatter `version` (currently `1`). A future bump is stamped by the writer; there is no auto-track magic.

```yaml
---
source_repo: C:/repos/eShopOnContainers
branch_name: main
generated_at: 2026-05-18T10:30:00Z
skill_version: 1
---
```

## Failure modes

Known DDD modeling failure modes to watch for during the walk. See `./research.md#known-failure-modes`.

## Conflict resolution

What to do when two parts of the codebase disagree on the same invariant. See `./research.md#what-to-do-when-code-as-source-of-truth-conflicts-with-itself`.
