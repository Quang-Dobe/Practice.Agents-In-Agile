---
description: Brief Claude on the current open step of a feature (reads requirement + plan + status + Test Strategy row)
argument-hint: <feature> [step-id]
---

Begin work on the current open requirement step of a feature.

`$ARGUMENTS` is `<feature>` followed optionally by `[step-id]`. If `<feature>` is missing, error: `specify a feature, e.g. /workflow:step-start payments-export`.

If `[step-id]` is provided (e.g., `C`), force that step. Otherwise:

1. Read `docs/<feature>/<feature>.requirement.md` and find the first row whose checkbox is NOT `[X]`.
2. Read the matching section in `docs/<feature>/<feature>.plan.md` for that step.
3. Read `docs/<feature>/<feature>.status.md` for relevant resolved-question history (especially the previous step's "Resolved questions" section, since it often constrains the next step).
4. Read the Test Strategy row for that step from `docs/<feature>/<feature>.analyzed.md` (4-col contract: `Step ID | Goal | Test kind | Owner`, per R7). If `analyzed.md` is absent (planning steps 1-3 of `requirement.md` — overview-plan / plan / analyzed authoring), treat as `skip Tester` and continue.
5. Spawn the `workflow-step-planner` subagent with the feature name + step name, so it can return the open-question punch list.
6. Print a focused brief in this exact shape:

   **Step:** `<step-id>` - `<short title>`
   **Goal:** one sentence.
   **Open questions to resolve before coding:** the punch list returned by `workflow-step-planner`, each marked `[Waiting for Answer]`.
   **Inputs from prior steps:** the constraints / DTOs / interfaces this step builds on.
   **Test Strategy (from analyzed.md):** the verbatim `Test kind` cell for this step (or `skip Tester` if absent / explicit).
   **Spawn order after go-ahead:** either `Tester -> Software Engineer` (when `Test kind` is a concrete instruction) or `Software Engineer only` (when `Test kind` is literally `skip Tester` or the step is a planning step 1-3 with no `analyzed.md`).
   **First action:** what should happen as soon as the user gives the go-ahead.

7. Do **not** write code. Do **not** modify any files. Wait for the user's response.

When the user gives the go-ahead and all `[Waiting for Answer]` items are resolved, main Claude proceeds per the printed **Spawn order**:

- **Tester -> Software Engineer:** spawn the `tester` subagent first with `<feature>` + Step ID + the Test Strategy row. Tester drafts test cases (TDD red phase). Then spawn `software-engineer` to execute the step's substeps.
- **Software Engineer only:** spawn `software-engineer` directly with `<feature>` + Step ID.

Neither branch flips `[X]` — the user types `APPROVE` and main Claude flips it via `/workflow:step-approve`.

If no non-`[X]` row exists, say "All requirement steps for `<feature>` are approved" and stop. Then offer the end-of-feature Tester acceptance pass: spawn `tester` once with context `end-of-feature` to verify every concrete Test Strategy row was honored before final hand-off.

If `docs/<feature>/<feature>.requirement.md` does not exist, error: `feature '<feature>' not found at docs/<feature>/`.
