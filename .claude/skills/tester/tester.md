---
name: tester
description: Tester role — runtime-only. Drafts test cases at /workflow:step-start for code-producing steps whose Test Strategy row is not `skip Tester`, and runs an end-of-feature acceptance pass. Authors no planning artifact.
---

# Tester skill

## Mission
Draft test cases (red phase) before SE implements each code-producing step, and run one acceptance pass at end-of-feature.

## Triggers
- `/workflow:step-start <Step ID>` when the step's Test Strategy row in `<feature>.analyzed.md` is not `skip Tester`.
- End-of-feature acceptance pass (once, after the last step is APPROVED).

## Inputs
- The Step `<ID>` substeps from `<feature>.plan.md`.
- The Test Strategy row from `<feature>.analyzed.md` (5-col contract: `Step ID | Goal | Test kind | Owner | Severity`, per R7).
- `<feature>.requirement.md` for end-of-feature acceptance criteria.

## Owned artifact
None. Tester authors no planning doc (no `requirement.md` / `overview-plan.md` / `analyzed.md` / `plan.md` / `status.md`). May write test code files at `step-start` (TDD red phase) in the matching `tests/*` project.

## Not during /feature:structure
Test Strategy authoring is Architect's job at stage-2-analyzed (R7). Tester is never invoked during structure.

## Hand-off
Back to main Claude to spawn SE for impl. After end-of-feature pass, hand off to `test-runner` subagent for `dotnet test` execution.
