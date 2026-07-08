---
description: Restructure a raw requirement.md, then draft overview-plan / analyzed / plan via explicit BA -> Architect -> Architect -> SE orchestration (APPROVE gates between stages)
argument-hint: <feature-name>
---

Explicit four-stage orchestrator. Main Claude (you) spawns one specialist per stage via the `Agent` tool.

`$ARGUMENTS` carries the feature name plus an optional `--present[=true|false]` flag (boolean, **default true**). Strip the flag first; the remaining token is the feature name. If the feature name is empty, error: `specify a feature name, e.g. /feature:structure payments-export`. `--present false` (or `--present=false`) disables the present-dossier seam for this run; otherwise it is on.

## Stage-to-checkbox mapping

| Stage | Spawned subagent(s) | Produces | Requirement row(s) flipped on APPROVE |
|---|---|---|---|
| Stage 1 | `business-analyst` | `<name>.requirement.md` (rewrites in place) | (none — pure gate) |
| Stage 2-overview | `architect` + `tester` (parallel) | `<name>.overview-plan.md` + `<name>.test.md` | Step 1 + Step 2 (one combined APPROVE) |
| Stage 2-analyzed | `architect` | `<name>.analyzed.md` | Step 3 |
| Stage 2-plan | `software-engineer` | `<name>.plan.md` | Step 4 |

## Stage 1 — Business Analyst authors `<name>.requirement.md`

1. Verify `docs/<name>/<name>.requirement.md` exists (a raw requirement file). If not, error: `raw requirement file docs/<name>/<name>.requirement.md not found — create it (or run /feature:new <name> first)`.
2. **Recon gate — check the domain wiki.** Test whether `docs/domain/` and `docs/narrative/` exist (non-empty) in the working repo.
   - **If EITHER exists** → skip the recon sub-flow. The BA grounds on the present wiki (current behavior). Go to step 4.
   - **If BOTH are absent** → run the recon sub-flow (step 3) first, so the BA gets current-behavior grounding without reading source itself.
3. **Recon sub-flow (only when both `docs/domain/` and `docs/narrative/` are absent):**
   a. Spawn the `architect` subagent via the `Agent` tool with `description: Architect: stage-1 recon for <name>` and a `prompt` containing: the feature name, `stage: stage-1-recon` (→ follow its `codebase-recon` skill), the raw requirement path, and that source reads are **optional / as-needed** — return a **Current Behavior Brief**, write no file.
   b. Capture the returned brief. Pass it verbatim into the BA spawn at step 4 as the recon grounding.
4. Spawn the `business-analyst` subagent via the `Agent` tool with `description: BA: author <name>.requirement.md` and a `prompt` containing: the feature name, the path to the raw requirement, the PO brainstorm summary if available (passed by the caller), **the Architect Current Behavior Brief if the recon sub-flow ran** (with the directive to persist it as the `## Current Behavior (Architect recon)` appendix), the instruction to author the structured requirement per its `requirement-authoring` skill, and the directive to read `docs/narrative/` if it exists (optional context; absent → the `/project:overview` advisory `docs/narrative/ not found - run /project:overview to generate it; proceeding without it.`, never blocks).
5. **Bounded Architect Q&A (only if the recon sub-flow ran AND the BA returned numbered `[Architect Q]` code-questions):** spawn the `architect` subagent again with `description: Architect: stage-1 Q&A for <name>` and `stage: stage-1-qa` (→ `codebase-recon`), passing the BA's questions. Relay the answers, then re-spawn the BA to finalize `requirement.md` folding them in. **One round only** — do not loop again.
6. Relay the BA's draft to the user. Mark it `[Waiting for Approval]` in chat.
7. Wait for the user to type `APPROVE`. Do not proceed otherwise.
8. After APPROVE: no checkbox flip (Stage 1 is a pure gate — the requirement file itself is the deliverable).

## Stage 2-overview — Architect authors `overview-plan.md`; Tester authors `test.md` (parallel)

1. Spawn **both** subagents in parallel (a single message with two `Agent` tool calls):
   - `architect` with `description: Architect: author <name>.overview-plan.md` and a `prompt` containing the feature name, `stage: stage-2-overview` (→ follow its `architecture-planning` skill), and the directive to read `docs/narrative/` + `docs/domain/` if present (symmetric advisory for whichever is absent; never blocks).
   - `tester` with `description: Tester: author <name>.test.md` and a `prompt` containing the feature name, `stage: stage-2-overview` (→ follow its `acceptance-spec-authoring` skill), and the directive to read `docs/narrative/` if present (advisory if absent; never blocks). The Tester reads only `requirement.md` (+ narrative + `test-rules`) — black-box, no source.
2. Relay **both** drafts together. Mark `[Waiting for Approval]`.
3. Wait for a single `APPROVE` covering both artifacts. If the user requests edits to one, re-spawn only that agent, re-present, then wait for the shared APPROVE.
4. After APPROVE — do BOTH, in order:
   a. Flip Step 1 **and** Step 2 in `<name>.requirement.md` from `[ ]` to `[X]`.
   b. **Present build** (unless `--present false`): invoke `/present:build <name> requirement overview-plan test`. Call it **unconditionally** — do NOT pre-judge whether grounding exists; `/present:build` self-detects mode and no-ops on its own. Skip only if `/present:build` does not resolve (kit not installed). This is a mechanical step, not optional.

## Stage 2-analyzed — Architect authors `<name>.analyzed.md` (with per-step Severity table per R7)

1. Spawn the `architect` subagent again via the `Agent` tool with `description: Architect: author <name>.analyzed.md` and a `prompt` containing: the feature name and `stage: stage-2-analyzed` (→ follow its `risk-severity-analysis` skill), the directive to read the approved `<name>.test.md` (to inform Severity), and to read `docs/narrative/` + `docs/domain/` if present (symmetric advisory; never blocks).
2. Relay the draft. Mark `[Waiting for Approval]`. Confirm to the user that the `## N. Step Severity` section is present and is a 2-column table (`Step ID | Severity`) with one row per implementation step in `overview-plan.md`.
3. Wait for `APPROVE`.
4. After APPROVE — do BOTH: (a) flip Step 3 in `<name>.requirement.md` to `[X]`; (b) **present build** (unless `--present false`): invoke `/present:build <name> analyzed` **unconditionally** (it self-gates; skip only if `/present:build` does not resolve). Mechanical step, not optional.

## Stage 2-plan — Software Engineer authors `<name>.plan.md` (mechanical; final step is the E2E gate)

1. Spawn the `software-engineer` subagent via the `Agent` tool with `description: SE: author <name>.plan.md` and a `prompt` containing: the feature name, `stage: stage-2-plan` (→ follow its `implementation-planning` skill), the R7 reminder (`plan.md` has no Severity column — that lives in `analyzed.md`), the directive that the **final** step of `plan.md` MUST be the E2E validation gate (author automated e2e tests from `<name>.test.md`, run via the project `test-runner`, done-when all green), and to read `docs/narrative/` + `docs/domain/` if present (symmetric advisory; never blocks).
2. Relay the draft. Mark `[Waiting for Approval]`. Confirm to the user that `plan.md` contains no Severity column, that Step IDs match `overview-plan.md` exactly, and that the final step is the E2E validation gate referencing `test.md`.
3. Wait for `APPROVE`.
4. After APPROVE — do BOTH: (a) flip Step 4 in `<name>.requirement.md` to `[X]`; (b) **present build** (unless `--present false`): invoke `/present:build <name> plan` **unconditionally** (it self-gates; skip only if `/present:build` does not resolve). Mechanical step, not optional.

## After Stage 2-plan — mechanically initialize `<name>.status.md`

No agent involved. Main Claude (you) does this directly.

1. Read `~/.claude/templates/feature.status.md`.
2. Write `docs/<name>/<name>.status.md` from the template:
   - `# <Feature title> - Status` header — extract title from `<name>.requirement.md`.
   - `**Last updated:**` — today's date.
   - `**Current step:**` — the first implementation step (`Step A`) from `<name>.overview-plan.md`.
   - `Snapshot` — one paragraph summarizing what the four planning artifacts contain and what the next implementation move is.
   - `Step status table` — Steps 1-4 marked `**APPROVED <today>**`, plus one row per implementation step (`Step A`, `Step B`, …) from `overview-plan.md`, all pending.
3. **Present dossier verify** (unless `--present false`): confirm `docs/<name>/present/present.html` now exists. If `/present:build` resolves and it does NOT exist, invoke `/present:build <name>` once and re-check.
4. **Report the present outcome** in your closing summary — one of: `present: built`, `present: skipped (no kit)`, `present: skipped (no grounding)`, or `present: off (--present false)`. A silent miss must never pass unnoticed.
5. Recommend `/workflow:step-start <name>` to begin implementation.

## Present dossier — flag + contract (the triggers are the inline steps above)

The present builds are triggered **inline**, inside each stage's *After APPROVE* step and the `status.md`-init section — deliberately framed as the same kind of mechanical step as flipping a checkbox or writing `status.md`, which never get skipped. This section is only the contract those steps obey:

- **`--present` flag** — default **true**. `--present false` → skip every inline present build this run. (The flag is already stripped from `$ARGUMENTS` during feature-name parsing at the top.)
- **Unconditional call.** When `--present` is on, call `/present:build` for the stage's units **without** pre-checking grounding yourself. `/present:build` self-detects **project** (`docs/domain/` / `docs/narrative/`) or **root** (`repo-layout.md` / `docs/memory/` / `docs/architecture.md`) mode and silently no-ops when neither exists. Skip the call **only** if `/present:build` does not resolve (kit absent).
- **Unit map:** stage-2-overview → `requirement overview-plan test` · stage-2-analyzed → `analyzed` · stage-2-plan → `plan`.

**Final verification (mandatory).** After stage-2-plan, if `--present` is on and `/present:build` resolves: confirm `docs/<name>/present/present.html` now exists. If it does **not**, run `/present:build <name>` once more and re-check before reporting the pipeline complete. **Report the present outcome** (built / skipped-no-kit / skipped-no-grounding) in your closing summary so a silent miss can never pass unnoticed.

## Notes

- **Resume after mid-stage session close.** Detect partial state by checking which Step 1/2/3/4 rows are `[X]` in `<name>.requirement.md` and which planning artifact files exist on disk. Resume from the next pending stage rather than redoing prior ones.
- **No commits.** The user commits explicitly. Do not run `git commit`.
- **`/workflow:step-approve` parity.** Each APPROVE in Stage 2 mirrors `/workflow:step-approve <name>`'s logic for flipping the requirement checkbox.
- **Live-spawn note.** The four named subagents (`business-analyst`, `architect`, `tester`, `software-engineer`) must be installed at user scope (`~/.claude/agents/`, via `install.ps1`). They are loaded by Claude Code at session start; if you renamed or replaced any of them mid-session, restart the session before running this command.
