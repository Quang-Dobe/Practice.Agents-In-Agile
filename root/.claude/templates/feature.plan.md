# <Feature title> — Implementation plan

> Status: [Waiting for Approval]
> Baseline: <only on a regenerated plan — "regenerated <date> after Q<n>. In code already: Steps A, C."
> Omit this line on the first plan.>

## Prerequisites

<Packages, environment variables, seed data, external services — only if any. Else `None.`>

## Component map

| Step | Component | State | Owns files (new ★ / changed) | Depends on | Provides to others |
|---|---|---|---|---|---|
| A | <component> | none | ★ `<path>`<br>★ `<test path>` | — | <the contract others call: method, route, event, table> |
| B | <component> | none | `<path>`<br>`<test path>` | A | <contract> |
| <last> | E2E gate | none | ★ `<e2e test path>` | <all> | — |

<`Owns files` renders **one path per line**, using `<br>` as the separator so the table still renders.
This is the whole column, not just the rows with many files — a row stacked next to three rows inline
reads worse than either. A nine-path cell on one line cannot be scanned, counted, or diffed against
another row.

Take the file list from `<feature>.overview-plan.md` §3's tree — it is already settled and approved.
Do not invent files it does not have, and do not drop any it does, including the guard tests §3 asked
you to search for.

`State` = how much of this component is in code today: `none` / `partial` / `done`. First plan: all
`none`. A `done` row with no section = nothing left to do. A `done` row with a section = the design
changed; the section describes only the change.

**Owned file sets must not overlap** — a file two components touch goes to `Shared files`. One
exception: when the steps sharing a file sit on a **strict dependency chain**, so no two of them can
ever be in the same wave, the overlap is safe and the file stays with its steps. Say so in one line
under the table. Moving a feature's main file to `Shared files` would make main Claude its author,
which is worse than the overlap the rule guards against.>

## Shared files

<Files two or more components touch. Main Claude edits these, not the component engineers.
None → `None.`>

- <path> — <what is added there, one line>

## Step A — <component>

- What changes:
  - <bullet — the behavior after the change, naming the file it lands in>
  - <bullet>
- How it works: <short paragraph or ≤10 lines of pseudocode. For an endpoint named in the
  overview-plan §2, the request / response shape is written here, not there.>

## Step B — <component>

<**Exactly these two fields, never more.** One section per component, roughly 10-25 lines each.

Five fields that look useful are deliberately absent, because each one echoes something already
written and then drifts from it:

| Not here | Where it already is |
|---|---|
| `Job` | the section heading, and the overview-plan §6 Steps row |
| `Files` | the Component map above — a pointer to a table one screen up earns nothing |
| `Talks to` | inside `How it works`, with the same names |
| `Tests` | `<feature>.test.md`, which the E2E gate runs — a second looser list only drifts from it |
| `Done when` | a restatement of `Tests` |

If a field has nothing to put in it but a pointer, it should not be a field.>

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
