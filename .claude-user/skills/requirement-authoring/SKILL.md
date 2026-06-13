---
name: requirement-authoring
description: Pressure-test the Product Owner's framing, then author the structured <feature>.requirement.md with a Challenges to PO framing appendix. Used by the business-analyst agent at /feature:structure stage-1.
---

# Requirement authoring skill

## Mission
Pressure-test the Product Owner's framing, gather any missing scope or success criteria, then write the structured requirement file. This is the **first** role in the pipeline to read engineering context.

## Owned artifact
`docs/<feature>/<feature>.requirement.md`. Template: `~/.claude/templates/feature.requirement.md`.

## Inputs
- Feature name and path to the raw requirement (`docs/<feature>/<feature>.requirement.md`).
- The Product Owner's six-section brainstorm summary, if available (sections: Intent / In scope / Out of scope / Open questions / Framing assumptions BA should challenge / Recommended next action).
- The Architect's **Current Behavior Brief** (markdown), passed by main Claude **only when `docs/domain/` and `docs/narrative/` are both absent** (the Stage-1 recon grounding). Absent otherwise — you ground on the wiki instead.

## Read scope
- The raw requirement file and the requirement template.
- `docs/architecture.md` if it exists — always check.
- Other features' `docs/<feature>/<feature>.status.md` — skim for in-flight context and conflicts.
- Optional soft inputs (`docs/narrative/`) and project skills via `project-seams`.
- **NEVER read raw source code.** You are walled off from source (CONVENTIONS.md matrix — BA "Source code" = `—`). When the domain wiki is absent, your current-behavior grounding comes **only** from the Architect's recon brief passed in your prompt — not from the codebase. If the brief leaves gaps, raise numbered `[Architect Q]` questions (≤1 round) instead of reading source.

## Procedure
1. Read the raw requirement, the PO summary (if present), `docs/architecture.md`, other features' status files, **and the Architect Current Behavior Brief if main Claude passed one** (wiki absent).
2. **Pressure-test PO's "Framing assumptions BA should challenge" bullets.** Each gets a stance: `agree` / `disagree` / `amend` / `defer`. For `disagree` or `amend`, post a numbered `[Waiting for Answer]` question to the user before writing.
3. Surface any missing scope, success criteria, or constraints as numbered `[Waiting for Answer]` questions. Wait for answers.
3b. **Bounded Architect Q&A (only when a recon brief was provided).** If the brief leaves code-level gaps that block the requirement, raise numbered `[Architect Q]` questions; main Claude relays them to the Architect for **one** answer round, then re-spawns you to finalize. Fold the answers in. **Never read source yourself.**
4. Once framing is solid, write `docs/<feature>/<feature>.requirement.md` matching the template exactly:
   - `# <Feature title>` from the framing.
   - `## Rules` — copy verbatim from template.
   - `## Your Requirements` — the four steps, always in this order:
     - `[ ] Step 1: Create docs/<feature>/<feature>.overview-plan.md`
     - `[ ] Step 2: Create docs/<feature>/<feature>.test.md` (e2e/acceptance spec; authored in parallel with Step 1)
     - `[ ] Step 3: Create docs/<feature>/<feature>.analyzed.md`
     - `[ ] Step 4: Create docs/<feature>/<feature>.plan.md`
     (Implementation steps `A`, `B`, `C`, … live in `overview-plan.md`, not here.)
   - `## Your Tasks` — copy verbatim from template.
   - `## Original raw requirement` — paste the user's original prose verbatim.
   - `## Challenges to PO framing` — appendix table, one row per PO challenge bullet:

     ```
     | # | PO assumption | BA stance | Resolution |
     |---|---|---|---|
     | 1 | <verbatim PO assumption> | agree / disagree / amend / defer | <one-line outcome — what the user decided, or "n/a (agreed)"> |
     ```

     If `/feature:new` was not run or PO produced no challenges, write: `_No PO framing challenges - /feature:new was not invoked or PO surfaced no assumptions to challenge._`
   - `## Current Behavior (Architect recon)` — **only when main Claude passed an Architect recon brief** (both wiki trees absent). Paste the brief verbatim (light formatting only); keep its `path:line` citations. **Omit this section entirely** when a wiki was present / no brief was passed.
5. Save via `Write`. Hand off per `pipeline-protocol`: "Stage 1 complete. Awaiting user APPROVE on the restructured `<feature>.requirement.md`."

## Boundary
Does not draft `overview-plan.md` / `analyzed.md` / `plan.md`, flip `[X]`, create `status.md`, start implementation, **or read raw source code** (current-behavior grounding comes from the wiki or the Architect recon brief). Full contract: `pipeline-protocol`.
