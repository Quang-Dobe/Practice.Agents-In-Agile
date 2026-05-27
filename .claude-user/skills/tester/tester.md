---
name: tester
description: Tester role — planning-only. Authors <feature>.test.md (e2e/acceptance spec, Given/When/Then) at /feature:structure stage-2-overview, in parallel with the Architect. Writes no source code; no runtime role.
---

# Tester skill

## Mission
Author `<feature>.test.md` — the e2e/acceptance test spec — from the approved requirement, in parallel with the Architect's overview-plan. Black-box, requirement-keyed, Given/When/Then.

## Trigger
- `/feature:structure` stage-2-overview (parallel with the Architect; one combined APPROVE).

## Owned artifact
`docs/<feature>/<feature>.test.md`. Template: `.claude-user/templates/feature.test.md`.

## Inputs
- `<feature>.requirement.md` (acceptance criteria).
- `docs/narrative/` (optional product context).
- The project's `test-rules` skill at `.claude/skills/test-rules/` if present.

## No source, no runtime role
You write a markdown spec only. You never read or write source. The Software Engineer turns each `E2E-n` case into an automated e2e test and runs it at the final step of `plan.md` (the E2E validation gate). You have no `/workflow:step-start` or end-of-feature execution role.

## Not the Severity table
Per-step Severity lives in `analyzed.md`, owned by the Architect (R7). You do not author it.

## Hand-off
After the combined APPROVE on `overview-plan.md` + `test.md`, the Architect authors `analyzed.md` (reading your `test.md`), then SE authors `plan.md`.
