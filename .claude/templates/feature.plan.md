# <Feature title> - Detailed Implementation Plan

> **Status:** [Waiting for Approval]

---

## Prerequisites

- Runtime / SDK requirements.
- NuGet (or other) packages.
- Any seed data, environment variables, or external services.
- Explicit *exclusions* (e.g., "no MediatR per `<feature>.analyzed.md` Resolved Decision X").

---

## Step A - <short title>

**Goal:** one sentence.

### Actions

1. ...
2. ...

### Deliverables

- ...

---

## Step B - <short title>

**Goal:** one sentence.

### Types to create

```
<module>/
  <Subfolder>/
    <Type1>.cs        # one-line description
    <Type2>.cs        # one-line description
```

### Rules applied

- Cite `dotnet-rules` Section X.Y when a rule pins a decision.

---

## Step C - <short title>

(Repeat the structure as needed - one section per step.)

---

## Step F - Tests

**Goal:** unit tests for Domain and Application; coverage targets per `dotnet-rules` Section 9.3.

| Test class | Project | Covers |
|---|---|---|
| `<Type>Tests` | `<Project>.Tests` | <bullet covering invariants> |

---

## Step G - End-to-End Validation (Manual)

Numbered manual steps to verify the feature end-to-end before sign-off.

---

## Implementation Order

| Order | Step | Dependency |
|---|---|---|
| 1 | Step A | None |
| 2 | Step B | Step A |
| ... | ... | ... |

---

## Resolved Decisions

| # | Question | Decision |
|---|---|---|
| 1 | <decision name> | <one line> |

> When a step's `[Waiting for Answer]` question is resolved, move it from "open" into this table or the matching `Resolved questions` block in `<feature>.status.md`.
