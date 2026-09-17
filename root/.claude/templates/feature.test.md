# <Feature title> — Acceptance tests

> Status: [Waiting for Approval]

## Happy cases — must pass

### E2E-1 [Happy Case] <short title>

- Covers: SC-1
- Given: <starting state, ≤20 words>
- When: <the action, ≤20 words>
- Then: <the visible result, ≤20 words>

### E2E-2 [Happy Case] <short title>

- Covers: SC-<n>
- Given: <...>
- When: <...>
- Then: <...>

<One happy case per `SC-n` at least. Every happy heading carries `[Happy Case]`; nothing else does.>

## Edge cases — explored from Constraints, scope, and Current behavior

### E2E-3 <short title>

- Covers: Constraint — <the requirement line this comes from>
- Given: <...>
- When: <...>
- Then: <...>

<The Tester explores these from the requirement's `Constraints`, `In scope` / `Out of scope`, and
`Current behavior` lines. Each case names the line it comes from (`Constraint — …`, `In scope — …`,
`Out of scope — …`, `Current behavior — …`). No anchor line → not a case. Never cites an `SC-n`.
Soft cap: no more edge cases than happy cases.>

## Ad-hoc checks — manual, not automated

- <one check a human does once by hand>

<Not automated, not part of the E2E gate. May be empty — `None.`>

---

<Plain words. Given / When / Then: one line each, no code, no file names, no step IDs. The Software
Engineer turns every `E2E-n` above into an automated test at the final `plan.md` step (happy cases
first); the feature is done when they are green.>
