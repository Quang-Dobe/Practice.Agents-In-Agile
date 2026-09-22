# <Feature title> — Status

Last updated: <YYYY-MM-DD>
Current step: Step <ID> — <component>

| Step | Component | Status | Note |
|---|---|---|---|
| A | <component> | pending | |
| B | <component> | pending | |
| <last> | E2E gate | pending | |

<One row per step in `<feature>.plan.md` — same IDs as the overview-plan Steps table. Planning stages
are not tracked here: each planning artifact carries its own `> Status:` line, and the commands find
the stage from which files exist on disk.>

<Status values: `pending` · `in progress` · `in review` · `waiting approval` · `approved <date>` · `reopened`
(was approved, then a plan change touched it — the code stays, the row is open again) · `blocked`
(a `[Waiting for Answer]` question — the Note says which one).>

<Note: one line, optional — `blocked by Q2`, `reopened after plan change #3`, `E2E-5 skipped by user`.
Never a paragraph.>
