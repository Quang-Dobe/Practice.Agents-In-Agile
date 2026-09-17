# <Feature title> — Implementation plan

> Status: [Waiting for Approval]
> Baseline: <only on a regenerated plan — "regenerated <date> after Q<n>. In code already: Steps A, C."
> Omit this line on the first plan.>

## Prerequisites

<Packages, environment variables, seed data, external services — only if any. Else `None.`>

## Component map

| Step | Component | State | Owns files (new ★ / changed) | Depends on | Provides to others |
|---|---|---|---|---|---|
| A | <component> | none | ★ <path> · ★ <test path> | — | <the contract others call: method, route, event, table> |
| B | <component> | none | <path> · <test path> | A | <contract> |
| <last> | E2E gate | none | ★ <e2e test path> | <all> | — |

<`State` = how much of this component is in code today: `none` / `partial` / `done`. First plan: all
`none`. Owned file sets must not overlap — a file two components touch goes to `Shared files`.
A `done` row with no section = nothing left to do. A `done` row with a section = the design changed;
the section describes only the change.>

## Shared files

<Files two or more components touch. Main Claude edits these, not the component engineers.
None → `None.`>

- <path> — <what is added there, one line>

## Step A — <component>

- Job: <one sentence — what this component does>
- Files: see map.
- What changes:
  - <bullet — the behavior after the change>
  - <bullet>
- How it works: <short paragraph or ≤10 lines of pseudocode. For an endpoint named in the
  overview-plan §2, the request / response shape is written here, not there.>
- Talks to: <who calls this component and through what; what this component calls and through what>
- Tests: <what to cover — ≤6 bullets. What, not how.>
- Done when: <1-3 checks>

## Step B — <component>

<Same fields. One section per component. Roughly 20-40 lines each.>

## Step <last> — E2E gate

- Turn every `E2E-n` in `<feature>.test.md` into an automated test. `[Happy Case]` cases first, then
  edge cases.
- Run them through the project's `test-runner` agent when the repo ships one.
- Done when: every `[Happy Case]` is green; edge cases green, or skipped by the user in chat (noted
  in the `status.md` Note column).
- The gate always covers the **whole** feature, also on a regenerated plan.

---

<Rules for this file: no full method bodies or class listings — if a section could be pasted into a
file and compile, it is too detailed. No implementation order table (order = `Depends on` above), no
resolved-decisions table (history lives in `<feature>.overview-plan-trace.md`), no red/green TDD
ceremony (tests ship with their component), no commit steps (the user commits), no Severity column
(it lives in `<feature>.analyzed.md`). Step IDs match `<feature>.overview-plan.md` §6 exactly.>
