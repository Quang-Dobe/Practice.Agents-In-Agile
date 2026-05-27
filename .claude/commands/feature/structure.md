---
description: Restructure a raw requirement.md, then draft overview-plan / analyzed / plan via explicit BA -> Architect -> Architect -> SE orchestration (APPROVE gates between stages)
argument-hint: <feature-name>
---

Explicit four-stage orchestrator. Main Claude (you) spawns one specialist per stage via the `Agent` tool.

`$ARGUMENTS` is the feature name. If empty, error: `specify a feature name, e.g. /feature:structure payments-export`.

## Stage-to-checkbox mapping

| Stage | Spawned subagent | Produces | Requirement row flipped on APPROVE |
|---|---|---|---|
| Stage 1 | `business-analyst` | `<name>.requirement.md` (rewrites in place) | (none — pure gate) |
| Stage 2-overview | `architect` | `<name>.overview-plan.md` | Step 1 |
| Stage 2-analyzed | `architect` | `<name>.analyzed.md` | Step 2 |
| Stage 2-plan | `software-engineer` | `<name>.plan.md` | Step 3 |

## Stage 1 — Business Analyst authors `<name>.requirement.md`

1. Verify `docs/<name>/<name>.requirement.md` exists (a raw requirement file). If not, error: `raw requirement file docs/<name>/<name>.requirement.md not found — create it (or run /feature:new <name> first)`.
2. Spawn the `business-analyst` subagent via the `Agent` tool with `description: BA: author <name>.requirement.md` and a `prompt` containing: the feature name, the path to the raw requirement, the PO brainstorm summary if available (passed by the caller), and the instruction to author the structured requirement per the BA agent spec, and the directive to read `docs/narrative/` if it exists (optional context; absent → the `/project:overview` advisory `docs/narrative/ not found - run /project:overview to generate it; proceeding without it.`, never blocks).
3. Relay the BA's draft to the user. Mark it `[Waiting for Approval]` in chat.
4. Wait for the user to type `APPROVE`. Do not proceed otherwise.
5. After APPROVE: no checkbox flip (Stage 1 is a pure gate — the requirement file itself is the deliverable).

## Stage 2-overview — Architect authors `<name>.overview-plan.md`

1. Spawn the `architect` subagent via the `Agent` tool with `description: Architect: author <name>.overview-plan.md` and a `prompt` containing: the feature name and `stage: stage-2-overview`, and the directive to read both `docs/narrative/` and `docs/domain/` if they exist (optional context; symmetric advisory for whichever is absent — `docs/narrative/ not found - run /project:overview to generate it; proceeding without it.` and/or `docs/domain/ not found - run /project:explore to generate it; proceeding without it.`, never blocks).
2. Relay the draft. Mark `[Waiting for Approval]`.
3. Wait for `APPROVE`.
4. After APPROVE: flip Step 1 in `<name>.requirement.md` from `[ ]` to `[X]`.

## Stage 2-analyzed — Architect authors `<name>.analyzed.md` (with Test Strategy table per R7)

1. Spawn the `architect` subagent again via the `Agent` tool with `description: Architect: author <name>.analyzed.md` and a `prompt` containing: the feature name and `stage: stage-2-analyzed`, and the directive to read both `docs/narrative/` and `docs/domain/` if they exist (optional context; symmetric advisory for whichever is absent — `docs/narrative/ not found - run /project:overview to generate it; proceeding without it.` and/or `docs/domain/ not found - run /project:explore to generate it; proceeding without it.`, never blocks).
2. Relay the draft. Mark `[Waiting for Approval]`. Confirm to the user that the `## N. Test Strategy` section is present and is a 5-column table (`Step ID | Goal | Test kind | Owner | Severity`) with one row per implementation step in `overview-plan.md`.
3. Wait for `APPROVE`.
4. After APPROVE: flip Step 2 in `<name>.requirement.md` to `[X]`.

## Stage 2-plan — Software Engineer authors `<name>.plan.md` (mechanical, no Test Strategy column)

1. Spawn the `software-engineer` subagent via the `Agent` tool with `description: SE: author <name>.plan.md` and a `prompt` containing: the feature name, `stage: stage-2-plan`, and the R7 reminder (`plan.md` has no Test Strategy column — that lives in `analyzed.md`), and the directive to read both `docs/narrative/` and `docs/domain/` if they exist (optional context; symmetric advisory for whichever is absent — `docs/narrative/ not found - run /project:overview to generate it; proceeding without it.` and/or `docs/domain/ not found - run /project:explore to generate it; proceeding without it.`, never blocks).
2. Relay the draft. Mark `[Waiting for Approval]`. Confirm to the user that `plan.md` contains no Test Strategy column anywhere, and that Step IDs match `overview-plan.md` exactly (no renumbering).
3. Wait for `APPROVE`.
4. After APPROVE: flip Step 3 in `<name>.requirement.md` to `[X]`.

## After Stage 2-plan — mechanically initialize `<name>.status.md`

No agent involved. Main Claude (you) does this directly.

1. Read `.claude/templates/feature.status.md`.
2. Write `docs/<name>/<name>.status.md` from the template:
   - `# <Feature title> - Status` header — extract title from `<name>.requirement.md`.
   - `**Last updated:**` — today's date.
   - `**Current step:**` — the first implementation step (`Step A`) from `<name>.overview-plan.md`.
   - `Snapshot` — one paragraph summarizing what the four planning artifacts contain and what the next implementation move is.
   - `Step status table` — Steps 1-3 marked `**APPROVED <today>**`, plus one row per implementation step (`Step A`, `Step B`, …) from `overview-plan.md`, all pending.
3. Recommend `/workflow:step-start <name>` to begin implementation.

## Notes

- **Resume after mid-stage session close.** Detect partial state by checking which Step 1/2/3 rows are `[X]` in `<name>.requirement.md` and which planning artifact files exist on disk. Resume from the next pending stage rather than redoing prior ones.
- **No commits.** The user commits explicitly. Do not run `git commit`.
- **`/workflow:step-approve` parity.** Each APPROVE in Stage 2 mirrors `/workflow:step-approve <name>`'s logic for flipping the requirement checkbox. `status.md` is **not** updated mid-stage — only after Stage 2-plan APPROVE (mechanical init), then by `/workflow:step-approve` for implementation steps.
- **Live-spawn note.** The four named subagents (`business-analyst`, `architect`, `software-engineer`) must be present in `.claude/agents/`. They are loaded by Claude Code at session start; if you renamed or replaced any of them mid-session, restart the session before running this command.
