---
description: Turn a raw requirement into the approved planning set - requirement, overview-plan, test spec, analysis, implementation plan (APPROVE gate per stage)
argument-hint: <feature-name>
---

Explicit four-stage orchestrator. Main Claude (you) spawns one specialist per stage via the `Agent` tool.

`$ARGUMENTS` carries the feature name plus an optional `--present[=true|false]` flag (boolean, **default true**). Strip the flag first; the remaining token is the feature name. If the feature name is empty, error: `specify a feature name, e.g. /feature:structure payments-export`. `--present false` (or `--present=false`) disables the present-dossier seam for this run; otherwise it is on.

## Where the run starts — read the folder, not a checklist

No file tracks planning progress. Look at which files exist in `docs/<name>/` and at the one
`> Status:` line each artifact carries:

| Files present in `docs/<name>/` | Stage to run |
|---|---|
| `<name>.raw-requirement.md` only | Stage 1 — BA writes `requirement.md` + `requirement-trace.md` |
| + `requirement.md` | Stage 2-overview — Architect + Tester in parallel |
| + `overview-plan.md` (+ trace) + `test.md` | Stage 2-analyzed — Architect writes the slim `analyzed.md` |
| + `analyzed.md` | Stage 2-plan — SE writes `plan.md` |
| + `plan.md` | initialize `status.md`, then `/feature:implement` |

An artifact whose `> Status:` line still reads `[Waiting for Approval]` re-enters **its own** gate —
relay it again and wait. An artifact at `> Status: APPROVED <date>` is done; move to the next stage.
On APPROVE you flip that one line in that one file. Nothing else is ever flipped.

## Stage-to-artifact map

| Stage | Spawned subagent(s) | Produces | Status line flipped on APPROVE |
|---|---|---|---|
| Stage 1 | `business-analyst` | `<name>.requirement.md` + `<name>.requirement-trace.md` (both new) | `requirement.md` |
| Stage 2-overview | `architect` + `tester` (parallel) | `<name>.overview-plan.md` + `<name>.overview-plan-trace.md` + `<name>.test.md` | `overview-plan.md` **and** `test.md` (one combined APPROVE) |
| Stage 2-analyzed | `architect` | `<name>.analyzed.md` | `analyzed.md` |
| Stage 2-plan | `software-engineer` | `<name>.plan.md` | `plan.md` |

Trace files carry no Status line — they are append-only history, not gated artifacts.

## Resolving the wiki — do this once, before Stage 1, and reuse the answer

Every stage below tells its agent to read `docs/narrative/` and `docs/domain/`. **Those are not always at the working-directory root.** A monorepo's wiki is written per code leaf, so the trees live at `<leaf>/docs/narrative/` and `<leaf>/docs/domain/` — one pair per leaf, none at the root. A root-only existence test answers "no wiki" for a repo that has a complete one, and then the whole pipeline plans blind.

Resolve it in this order and stop at the first hit:

1. **Root pair** — `docs/narrative/` or `docs/domain/` non-empty at the working directory. Single-repo shape; use it.
2. **Declared leaves** — `repo-layout.md` at the working directory declares each repo's code roots. Load the `repo-layout` skill, resolve the roots, and test `<root>/docs/narrative/` and `<root>/docs/domain/` for each. This is the reliable path in a monorepo, and the manifest is already there whenever the wrapping kit has run.
3. **Bounded glob** — no manifest: glob `*/docs/narrative/` and `*/*/docs/narrative/` under the working directory, capped at two levels. Never a repo-wide sweep.
4. **Genuinely absent** — nothing at any level. Only now is the wiki missing.

Print one line saying what you found, and carry the resolved paths into **every** agent spawn from here on:

| Case | The line, and what agents are told |
|---|---|
| root pair | `wiki: docs/narrative/ + docs/domain/ at the working directory.` |
| nested | `wiki: nested per leaf — <n> leaves under <roots>. Passing resolved paths to each agent.` List the paths in the spawn prompt; never let an agent conclude the wiki is missing. |
| one tree only | Name which, proceed with it. Symmetric advisory, never a block. |
| absent | `docs/narrative/ and docs/domain/ not found at the working directory or one level down - run /project:overview + /project:explore, or /wiki:bootstrap; proceeding without them.` |

**Never tell the user to run `/project:overview` when a nested wiki exists** — that bootstraps a second wiki over a repo that already has one.

## Stage 1 — Business Analyst authors `requirement.md` + `requirement-trace.md`

1. Verify `docs/<name>/<name>.raw-requirement.md` exists. If not, error: `raw requirement not found at docs/<name>/<name>.raw-requirement.md — create it (or run /feature:new <name> first)`. **Never overwrite this file** — no stage writes to it.
2. **Recon gate — resolve the wiki first, then check it.** See **Resolving the wiki** above: the trees may be at the working-directory root, or nested one level down per code leaf. Resolve the real paths before testing anything — a root-only test answers "no wiki" in a monorepo that has ten.
   - **If EITHER tree is found, at the root or nested** → skip the recon sub-flow. The BA grounds on the present wiki (current behavior). Go to step 4, passing it the resolved paths.
   - **If BOTH are genuinely absent everywhere** → run the recon sub-flow (step 3) first, so the BA gets current-behavior grounding without reading source itself.
3. **Recon sub-flow (only when the resolver found no wiki anywhere):**
   a. Spawn the `architect` subagent via the `Agent` tool with `description: Architect: stage-1 recon for <name>` and a `prompt` containing: the feature name, `stage: stage-1-recon` (→ follow its Stage 1 section), the raw requirement path, and that source reads are **optional / as-needed** — return a **Current Behavior Brief** at plan level (business flow + related components with roles, plus open unknowns; `path:line` in chat only), write no file.
   b. Capture the returned brief. Pass it into the BA spawn at step 4 as the current-behavior grounding.
4. Spawn the `business-analyst` subagent via the `Agent` tool with `description: BA: author <name>.requirement.md` and a `prompt` containing: the feature name, the path to `<name>.raw-requirement.md` (read-only — it is never overwritten), the PO brainstorm summary if available (passed by the caller), **the Architect Current Behavior Brief if the recon sub-flow ran**, the instruction to author **both** files as **new** files per its own Procedure, and **the wiki paths resolved above** (optional context, but pass the real resolved paths — never a bare `docs/narrative/`; absent everywhere → the advisory from the resolver table, never blocks).
5. **Bounded Architect Q&A (only if the recon sub-flow ran AND the BA returned numbered `[Architect Q]` code-questions):** spawn the `architect` subagent again with `description: Architect: stage-1 Q&A for <name>` and `stage: stage-1-qa`, passing the BA's questions. Relay the answers, then re-spawn the BA to finalize `requirement.md` folding them in. **One round only** — do not loop again.
6. Relay the BA's draft. Mark it `[Waiting for Approval]` in chat and run the **relay checks** below.
7. Wait for the user to type `APPROVE`. Do not proceed otherwise.
8. After APPROVE: flip the `> Status:` line in `<name>.requirement.md` to `> Status: APPROVED <today>`. Nothing else changes.

**Relay checks (Stage 1).** State the result in one line each; a failure is a re-spawn, not a silent fix.

- `requirement.md` holds only Goal, Current behavior (or `None — new behavior.`), In scope, Out of scope, Success criteria, Constraints — no rules block, no step checklist, no task list.
- `SC-n` are happy-path outcomes only. A limit or an error rule sitting in an SC belongs in Constraints.
- `## Current behavior` carries no file path, no code, no method name.
- The decisions landed in `<name>.requirement-trace.md`, and every row there changed something.
- `<name>.raw-requirement.md` is unchanged on disk.

## Stage 2-overview — Architect authors `overview-plan.md` + its trace; Tester authors `test.md` (parallel)

1. Spawn **both** subagents in parallel (a single message with two `Agent` tool calls):
   - `architect` with `description: Architect: author <name>.overview-plan.md` and a `prompt` containing the feature name, `stage: stage-2-overview` (→ follow its Stage 2-overview section), the directive to write **both** `overview-plan.md` and `overview-plan-trace.md` (one trace row per Key-technical-decisions row), and **the wiki paths resolved above** for both trees (symmetric advisory for whichever is absent; never blocks).
   - `tester` with `description: Tester: author <name>.test.md` and a `prompt` containing the feature name, `stage: stage-2-overview` (→ follow the Read scope + Procedure in its own agent file), and **the wiki paths resolved above** (advisory if absent; never blocks).
2. Relay **both** drafts together. Mark `[Waiting for Approval]` and run the relay checks below.
3. Wait for a single `APPROVE` covering both artifacts. If the user requests edits to one, re-spawn only that agent, re-present, then wait for the shared APPROVE.
4. After APPROVE — do BOTH, in order:
   a. Flip the `> Status:` line in **both** `<name>.overview-plan.md` and `<name>.test.md` to `APPROVED <today>`.
   b. **Present build** (unless `--present false`): invoke `/present:build <name> requirement overview-plan test`. Call it **unconditionally** — do NOT pre-judge whether grounding exists; `/present:build` self-detects mode and no-ops on its own. Skip only if `/present:build` does not resolve (kit not installed). This is a mechanical step, not optional.

**Relay checks (Stage 2-overview).**

- `## 6. Steps` exists, every step names the `SC-n` it covers, and the final step is the E2E gate over `test.md`. These IDs are canonical from here on.
- `## 2. What is exposed` has one `### <Kind>` sub-section per real kind, in the fixed shape, or the single line `None — internal change.` An `### API` block is the schema form — `API URL` / `METHOD` / optional `HEADER` / `QUERY` or `BODY` / `RESPONSE` / `REFUSAL`, one field per line as `name: type - description`. **A table here is a re-spawn** — it has no room for a field's type.
- `## 3. Components` opens with the **file tree**, every leaf tagged `added` / `edited` / `deleted` with a one-line note, and **no line over 100 characters** — a wrapped line breaks the tree. No separate per-file ownership list underneath, and no before/after section: the delta lives in §4.
- The tree includes any existing test that pins a global invariant this feature breaks — route surface, DI registration, contract or snapshot, architecture fitness. Ask for it by name if the tree has none; a missed one becomes a build failure no component owns.
- `## 4. Happy-path flow` carries the workflow diagram and, where an existing flow changes, the per-step table naming each step's external call, its data read in plain words, its validation → refusal, and whether it is new or already runs today.
- `## 5. Key technical decisions` holds final decisions only (≤7 rows), and `overview-plan-trace.md` has one row per decision.
- `test.md`: happy cases first, each flagged `[Happy Case]`, at least one per `SC-n`; edge cases each cite a requirement line, never an `SC-n`; ad-hoc checks are manual.

## Stage 2-analyzed — Architect authors the slim `<name>.analyzed.md`

1. Spawn the `architect` subagent again via the `Agent` tool with `description: Architect: author <name>.analyzed.md` and a `prompt` containing: the feature name and `stage: stage-2-analyzed` (→ follow its Stage 2-analyzed section), the directive to read the approved `<name>.test.md` (to inform Severity), and **the wiki paths resolved above** for both trees (symmetric advisory; never blocks).
2. Relay the draft. Mark `[Waiting for Approval]`. Confirm the file has **exactly three sections** — `Step Severity`, `Risks`, `Rule overrides` — and that Severity is a 2-column table (`Step ID | Severity`) with one row per step in `overview-plan.md` `## 6. Steps`. **`Risks` holds one row per step whose Severity is above `medium`, and nothing else** — no row for a `medium` or `minor` step, no row that is not tied to a step. That keeps `Risks` and the manual-gate list the same list. Empty Risks (`None seen.`) or empty overrides (`None.`) are correct answers, not gaps.
3. Wait for `APPROVE`.
4. After APPROVE — do BOTH: (a) flip the `> Status:` line in `<name>.analyzed.md` to `APPROVED <today>`; (b) **present build** (unless `--present false`): invoke `/present:build <name> analyzed` **unconditionally** (it self-gates; skip only if `/present:build` does not resolve). Mechanical step, not optional.

## Stage 2-plan — Software Engineer authors `<name>.plan.md` (component level; final step is the E2E gate)

1. Spawn the `software-engineer` subagent via the `Agent` tool with `description: SE: author <name>.plan.md` and a `prompt` containing: the feature name, `stage: stage-2-plan` (→ follow its stage-2-plan section), the reminder that `plan.md` has no Severity column (that lives in `analyzed.md`), the directive that the **final** step MUST be the E2E validation gate (every `E2E-n` from `<name>.test.md`, happy cases first, run via the project `test-runner`), and **the wiki paths resolved above** for both trees (symmetric advisory; never blocks).
2. Relay the draft. Mark `[Waiting for Approval]` and run the relay checks below.
3. Wait for `APPROVE`.
4. After APPROVE — do BOTH: (a) flip the `> Status:` line in `<name>.plan.md` to `APPROVED <today>`; (b) **present build** (unless `--present false`): invoke `/present:build <name> plan` **unconditionally** (it self-gates; skip only if `/present:build` does not resolve). Mechanical step, not optional.

**Relay checks (Stage 2-plan).** These protect the parallel build later — run them every time.

| Check | Action if it fails |
|---|---|
| Step IDs match `overview-plan.md` `## 6. Steps` exactly | re-spawn the SE |
| The owned files, taken together, match `overview-plan.md` §3's tree — nothing invented, nothing dropped | re-spawn the SE |
| Every component's owned files are **disjoint** from every other component's — **unless** the steps sharing a file sit on a strict dependency chain, so they can never be in one wave, and the plan says so in one line | genuine overlap moves to `## Shared files` — re-spawn the SE. Never move a feature's main file there: that makes main Claude its author |
| `Owns files` renders one path per line (`<br>`), across the whole column | re-spawn the SE |
| Each step section holds **only** `What changes` and `How it works` — no `Job`, `Files`, `Talks to`, `Tests`, or `Done when` | re-spawn the SE |
| Final step is the E2E gate and points at every `E2E-n` in `test.md` | re-spawn the SE |
| Every map row with `State` other than `done` has a section; a `done` row with a section describes only the change | re-spawn the SE |
| No section holds a full method body or class body | ask "trim, or keep?" — soft |
| No `Implementation Order`, `Resolved Decisions`, `Phase 2`, or "later" heading | ask "trim, or keep?" — soft |

## After Stage 2-plan — mechanically initialize `<name>.status.md`

No agent involved. Main Claude (you) does this directly.

1. Read `~/.claude/templates/feature.status.md`.
2. Write `docs/<name>/<name>.status.md` from the template:
   - `# <Feature title> — Status` — title from `<name>.requirement.md`.
   - `Last updated:` — today's date.
   - `Current step:` — the first step in the `plan.md` Component map.
   - One table row per **`plan.md` step** (same IDs as the overview-plan Steps table), all `pending`.
     **No planning rows** — planning stages are not tracked here.
3. **Present dossier verify** (unless `--present false`): confirm `docs/<name>/present/present.html` now exists. If `/present:build` resolves and it does NOT exist, invoke `/present:build <name>` once and re-check.
4. **Report the present outcome** in your closing summary — one of: `present: built`, `present: skipped (no kit)`, `present: skipped (no grounding)`, or `present: off (--present false)`. A silent miss must never pass unnoticed.
5. Recommend `/feature:implement <name>` to begin implementation.

## Soft size targets — ask once, never block

When you relay a draft, compare it with the target below. Over target → ask **once**, in one line:
"this is about `<n>`x the target — trim, or keep?". The user decides. A "keep" is final; never
re-ask, never refuse to proceed.

| Artifact | Target |
|---|---|
| `requirement.md` | ≤60 lines |
| `overview-plan.md` | ≤120 lines |
| `test.md` | ≤15 cases |
| `plan.md` | ≤60 lines per component |
| `status.md` | ≤30 lines |
| trace files | no cap — they grow by design |

Same soft treatment for speculation words. Scan each draft for `might`, `could later`,
`in the future`, `future-proof`, `scalable`, `extensible`, `generic`, `pluggable`, `abstraction`,
`for now`, `phase 2`, `eventually`, `just in case`. A hit with no matching requirement line → say
which line, ask "trim, or keep?". Never edit the agent's file yourself to fix it — re-spawn or let
the user decide.

## A question that changes an approved document

An agent may raise a numbered `[Waiting for Answer]` question mid-stage. When the user's answer
changes a document that is already approved, say which level it is in one line and let the user
confirm with one word:

| Level | The answer changes… | What happens |
|---|---|---|
| 0 | nothing | relay the answer, continue. Nothing is written anywhere |
| 2 | `overview-plan.md` (a step, a component, a tech decision) | re-spawn the Architect for the change + one `overview-plan-trace.md` row; anything already written below it is re-authored; each changed artifact re-enters its own APPROVE gate |
| 3 | `requirement.md` (scope, an SC, a constraint) | re-spawn the BA for the change + one `requirement-trace.md` row; re-spawn the Tester if an SC changed; then the level-2 cascade |

Done work is never silently invalidated: the changed document is shown again and waits for `APPROVE`,
exactly as the first time.

## Present dossier — flag + contract (the triggers are the inline steps above)

The present builds are triggered **inline**, inside each stage's *After APPROVE* step and the `status.md`-init section — deliberately framed as the same kind of mechanical step as flipping a Status line or writing `status.md`, which never get skipped. This section is only the contract those steps obey:

- **`--present` flag** — default **true**. `--present false` → skip every inline present build this run. (The flag is already stripped from `$ARGUMENTS` during feature-name parsing at the top.)
- **Unconditional call.** When `--present` is on, call `/present:build` for the stage's units **without** pre-checking grounding yourself. `/present:build` self-detects **project** (`docs/domain/` / `docs/narrative/`) or **root** (`repo-layout.md` / `docs/memory/` / `docs/architecture.md`) mode and silently no-ops when neither exists. Skip the call **only** if `/present:build` does not resolve (kit absent).
- **Unit map:** stage-2-overview → `requirement overview-plan test` · stage-2-analyzed → `analyzed` · stage-2-plan → `plan`.

**Final verification (mandatory).** After stage-2-plan, if `--present` is on and `/present:build` resolves: confirm `docs/<name>/present/present.html` now exists. If it does **not**, run `/present:build <name>` once more and re-check before reporting the pipeline complete. **Report the present outcome** (built / skipped-no-kit / skipped-no-grounding) in your closing summary so a silent miss can never pass unnoticed.

## Notes

- **Resume after mid-stage session close.** Read which artifact files exist in `docs/<name>/` and each one's `> Status:` line (table at the top). Resume at the first artifact that is missing, or at the first one still `[Waiting for Approval]`. Never redo an approved stage.
- **No commits.** The user commits explicitly. Do not run `git commit`.
- **Live-spawn note.** The four named subagents (`business-analyst`, `architect`, `tester`, `software-engineer`) must be installed at user scope (`~/.claude/agents/`, via `install.ps1`). They are loaded by Claude Code at session start; if you renamed or replaced any of them mid-session, restart the session before running this command.
