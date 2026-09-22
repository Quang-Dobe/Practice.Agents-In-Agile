# <Feature title> — Analysis

> Status: [Waiting for Approval]

## 1. Step Severity

| Step ID | Severity |
|---|---|
| A | <minor / medium / major / risky / irreversible> |
| B | <...> |

<One row per step in `<feature>.overview-plan.md` §6, same IDs, same order. a wave of `minor` and
`medium` steps closes on its own once build, tests, and the wave review are clean; `major`, `risky`,
and `irreversible` wait for a human. E2E/acceptance cases are not here — they live in `<feature>.test.md`.>

## 2. Risks

| Risk | What we do about it |
|---|---|
| <risk inside this feature, tied to a step above `medium`> | <the mitigation we take> |

<**Entry rule: one row only for a step whose Severity in §1 is above `medium`** — `major`, `risky`,
or `irreversible`. No row for a `medium` or `minor` step; §1 already ranked it, and a second mention
says nothing new while diluting the rows that matter. No row that is not tied to a step.

This keeps §2 and the manual-gate list the same list: a step here is exactly a step that will stop a
wave in `/feature:implement`.

Max 5 rows. Every step `medium` or below → `None seen.`, which is a real answer, not a gap.

A concern that is **not** a step risk — an unconfirmed assumption, a deferred decision — does not
belong here. It is already recorded under open assumptions in `<feature>.overview-plan-trace.md`.>

## 3. Rule overrides

| Rule skill + section | Override | Why |
|---|---|---|
| <`coding-rules` §3.2> | <what we do instead, one line> | <why the rule does not fit here> |

<Only when this feature breaks a project rule skill (`architecture-rules` / `coding-rules` /
`test-rules` under the repo's own `.claude/skills/`). The `code-reviewer` reads this section and
does not flag a listed override. Nothing to report → `None.`>
