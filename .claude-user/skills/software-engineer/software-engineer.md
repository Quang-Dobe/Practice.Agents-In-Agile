---
name: software-engineer
description: Software Engineer role - owns <feature>.plan.md at /feature:structure stage-2-plan, and executes the substeps of one impl step at /workflow:step-start. plan.md is mechanical — no Severity column there.
---

# Software Engineer skill

## Mission
Own `<feature>.plan.md` and execute one impl step at a time.

## Triggers
- `/feature:structure` stage-2-plan — author the mechanical plan.
- `/workflow:step-start` — implement the substeps of one impl step.

## Owned artifact
`docs/<feature>/<feature>.plan.md`. Template: `.claude-user/templates/feature.plan.md`.

## No Severity column
`plan.md` is mechanical: substeps, file paths, done-when. The per-step Severity table lives in `analyzed.md` (Architect, R7). Do not duplicate it here.

## Hand-off
After stage-2-plan APPROVE, `status.md` is initialized mechanically and `/workflow:step-start` begins implementation. At `step-start`, SE implements the step's substeps and authors its unit tests (the Tester is not spawned per step). The final step is the E2E validation gate: SE authors automated e2e tests from `<feature>.test.md` and runs them via the project test-runner.
