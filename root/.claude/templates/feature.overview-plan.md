# <Feature title> — Overview plan

> Status: [Waiting for Approval]

## 1. Purpose

<One paragraph. The user-facing outcome. Not the implementation.>

## 2. What is exposed

<Outside view only: what a caller or a user sees. One `### <Kind> — <short description>` sub-section
per kind of exposure. Nothing exposed → one line: `None — internal change.`
An internal logic or architecture change is not exposure — its picture goes in §3.>

### API — <short description>

| Method | Route | Input | Output | Purpose |
|---|---|---|---|---|
| <METHOD> | <route> | <what goes in> | <what comes back> | <why a caller uses it> |

<One row per endpoint. One line per cell. No schemas — they live in `plan.md`.>

### UI — <short description>

- Screen: <where the user is>
- Change: <what is new or different>
- User sees: <the visible result>

<Plain words. ≤5 lines. No pixel detail.>

### Job / CLI / Event — <short description>

- Name: <name>
- Trigger: <when it runs, or what raises it>
- Result: <what it produces, or who reacts>

<Same three lines per item. ≤5 items per kind.>

## 3. Components

| Component | New or changed | Job (one line) |
|---|---|---|
| <name> | new / changed | <what it does after this feature> |

<Only when structure or logic changes: one before → after diagram here. Mermaid (ASCII fallback),
≤12 boxes, ≤3 lines of words under it. No structural change → table only, no diagram.
"changed" rows start from the requirement's `## Current behavior`.>

## 4. Happy-path flow

1. <one sentence>
2. <one sentence>

## 5. Key technical decisions

| Concern | Decision |
|---|---|
| <concern> | <the decision — cite `architecture-rules` §n when a rule pins it> |

<Final decisions only, ≤7 rows. No options, no why — those live in `<feature>.overview-plan-trace.md`,
one trace row per row of this table.>

## 6. Steps

| Step | Component(s) | What | Depends on | Covers |
|---|---|---|---|---|
| A | <component> | <one line> | — | SC-1 |
| B | <component> | <one line> | A | SC-2 |
| <last> | E2E gate | Run every case in `<feature>.test.md` | <all> | all |

<This is the **canonical** step list. `analyzed.md`, `plan.md`, `status.md`, and `/feature:implement`
all key on these IDs — do not rename or renumber them afterwards. `Covers` names the `SC-n` the step
serves; a step that covers no SC does not belong here. The final step is always the E2E gate.
Severity, Risks, and Rule overrides are not here — they live in `<feature>.analyzed.md`.>
