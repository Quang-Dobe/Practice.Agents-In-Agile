---
name: requirement-authoring
description: Pressure-test the Product Owner's framing, then author the flat <feature>.requirement.md (final requirement only) plus its sibling <feature>.requirement-trace.md history file. Used by the business-analyst agent at /feature:structure stage-1.
---

# Requirement authoring skill

## Mission
Pressure-test the Product Owner's framing, gather any missing scope or success criteria, then write **two** files: a flat requirement holding only the final wording, and a trace file holding how it was reached. This is the **first** role in the pipeline to read engineering context.

## Owned artifacts
Two files, both yours, both written in the same stage-1 run:

| File | Holds | Template |
|---|---|---|
| `docs/<feature>/<feature>.requirement.md` | the **final requirement only** | `~/.claude/templates/feature.requirement.md` |
| `docs/<feature>/<feature>.requirement-trace.md` | the **history** behind it | `~/.claude/templates/feature.requirement-trace.md` |

**The split rule.** If a line answers *"what are we building?"* it goes in `requirement.md`. If it answers *"how did we land on that?"* it goes in `requirement-trace.md`. Never both. `requirement.md` carries no raw prose, no dropped options, no stance table, no verbatim recon brief — every downstream agent plans and tests from it, so bulk there is cost paid on every read.

## Inputs
- Feature name and path to the raw requirement (`docs/<feature>/<feature>.requirement.md`).
- The Product Owner's six-section brainstorm summary, if available (sections: Intent / In scope / Out of scope / Open questions / Framing assumptions BA should challenge / Recommended next action).
- The Architect's **Current Behavior Brief** (markdown), passed by main Claude **only when `docs/domain/` and `docs/narrative/` are both absent** (the Stage-1 recon grounding). Absent otherwise — you ground on the wiki instead.

## Read scope
- The raw requirement file and **both** templates (`feature.requirement.md`, `feature.requirement-trace.md`).
- `docs/architecture.md` if it exists — always check.
- Other features' `docs/<feature>/<feature>.status.md` — skim for in-flight context and conflicts.
- Optional soft inputs (`docs/narrative/`) and project skills via `project-seams`.
- **NEVER read raw source code.** You are walled off from source (CONVENTIONS.md matrix — BA "Source code" = `—`). When the domain wiki is absent, your current-behavior grounding comes **only** from the Architect's recon brief passed in your prompt — not from the codebase. If the brief leaves gaps, raise numbered `[Architect Q]` questions (≤1 round) instead of reading source.

## Procedure
1. Read the raw requirement, the PO summary (if present), `docs/architecture.md`, other features' status files, **and the Architect Current Behavior Brief if main Claude passed one** (wiki absent).
2. **Pressure-test PO's "Framing assumptions BA should challenge" bullets.** Each gets a stance: `agree` / `disagree` / `amend` / `defer`. For `disagree` or `amend`, post a numbered `[Waiting for Answer]` question to the user before writing.
3. Surface any missing scope, success criteria, or constraints as numbered `[Waiting for Answer]` questions. Wait for answers.
3b. **Bounded Architect Q&A (only when a recon brief was provided).** If the brief leaves code-level gaps that block the requirement, raise numbered `[Architect Q]` questions; main Claude relays them to the Architect for **one** answer round, then re-spawns you to finalize. Fold the answers in. **Never read source yourself.**
4. **Write the trace file before you touch `requirement.md`.** Stage 1 overwrites `requirement.md` in place, so the raw prose has no other copy — once overwritten it is unrecoverable. Trace first, always.
5. Write `docs/<feature>/<feature>.requirement-trace.md` matching its template:
   - `## Original raw requirement` — the user's original prose, verbatim.
   - `## Challenges to PO framing` — one row per PO challenge bullet (`# | PO assumption | BA stance | Resolution`). No PO run / no challenges → the template's `_No PO framing challenges …_` line.
   - `## Decisions from Q&A` — one row per numbered `[Waiting for Answer]` or `[Architect Q]` you asked (`# | Question asked | Answer | What it changed in the requirement`). No questions → the template's `_No open questions …_` line.
   - `## Current Behavior (Architect recon)` — the Architect brief verbatim with its `path:line` citations, **only when main Claude passed one**. No recon → the template's `_Not run — a domain wiki was present …_` line.
6. Write `docs/<feature>/<feature>.requirement.md` matching its template exactly — **flat, short, final wording only**:
   - `# <Feature title>` from the framing, plus the template's "final requirement only" note.
   - `## Goal` — 2-4 sentences. What changes, for whom, why. Decided wording, present tense.
   - `## In scope` / `## Out of scope` — one item per line. `Out of scope` states what will **not** be built; it does not narrate what was dropped or why.
   - `## Success criteria` — numbered `SC-n`, each observable and checkable. These are the Tester's acceptance hooks — one per behavior worth testing.
   - `## Constraints` — hard limits only, or `None.`
   - `## Current behavior` — 3-6 plain-language bullets, **only when the feature changes something that already exists**. Distil it from the wiki or the Architect brief; carry no `path:line` and no file names — the Tester reads this file black-box. Greenfield → delete the section.
   - `## Rules` — copy verbatim from template.
   - `## Your Requirements` — the four steps, always in this order:
     - `[ ] Step 1: Create docs/<feature>/<feature>.overview-plan.md`
     - `[ ] Step 2: Create docs/<feature>/<feature>.test.md` (e2e/acceptance spec; authored in parallel with Step 1)
     - `[ ] Step 3: Create docs/<feature>/<feature>.analyzed.md`
     - `[ ] Step 4: Create docs/<feature>/<feature>.plan.md`
     (Implementation steps `A`, `B`, `C`, … live in `overview-plan.md`, not here.)
   - `## Your Tasks` — copy verbatim from template.
   - The closing trace pointer line — copy verbatim from template.
7. **Self-check before handing off.** `requirement.md` contains no verbatim raw prose, no stance table, no `path:line`, and no sentence of the form "we first considered X". Any such line belongs in the trace file. Fix it before you report.
8. Save both via `Write`. Hand off per `pipeline-protocol`: "Stage 1 complete. Awaiting user APPROVE on the restructured `<feature>.requirement.md` (history in `<feature>.requirement-trace.md`)."

## Boundary
Does not draft `overview-plan.md` / `analyzed.md` / `plan.md`, flip `[X]`, create `status.md`, start implementation, **or read raw source code** (current-behavior grounding comes from the wiki or the Architect recon brief). Does not put history in `requirement.md` or requirements in `requirement-trace.md`. Full contract: `pipeline-protocol`.
