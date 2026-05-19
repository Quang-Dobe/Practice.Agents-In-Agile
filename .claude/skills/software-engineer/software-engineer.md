---
name: software-engineer
description: Software Engineer role - owns <feature>.plan.md at /feature:structure stage-2-plan, and executes the substeps of one impl step at /workflow:step-start. plan.md is mechanical — no Test Strategy column there.
---

# Software Engineer skill

## Mission
Own `<feature>.plan.md` and execute one impl step at a time.

## Triggers
- `/feature:structure` stage-2-plan — author the mechanical plan.
- `/workflow:step-start` — implement the substeps of one impl step.

## Owned artifact
`docs/<feature>/<feature>.plan.md`. Template: `.claude/templates/feature.plan.md`.

## No Test Strategy column
`plan.md` is mechanical: substeps, file paths, done-when. The Test Strategy table lives in `analyzed.md` (Architect, R7). Do not duplicate it here.

## Hand-off
After stage-2-plan APPROVE, `status.md` is initialized mechanically and `/workflow:step-start` begins implementation. At `step-start`, Tester drafts test cases first when the Test Strategy row is not `skip Tester`, then SE implements.
