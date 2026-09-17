# <Feature title> — Analysis

> Status: [Waiting for Approval]

## 1. Step Severity

| Step ID | Severity |
|---|---|
| A | <minor / medium / major / risky / irreversible> |
| B | <...> |

<One row per step in `<feature>.overview-plan.md` §6, same IDs, same order. `minor` and `medium`
auto-approve under `/feature:implement --bypass-approval`; `major`, `risky`, and `irreversible` wait
for a human. E2E/acceptance cases are not here — they live in `<feature>.test.md`.>

## 2. Risks

| Risk | What we do about it |
|---|---|
| <risk inside this feature> | <the mitigation we take> |

<Max 5 rows. Only risks inside this feature. Nothing to report → `None seen.`>

## 3. Rule overrides

| Rule skill + section | Override | Why |
|---|---|---|
| <`coding-rules` §3.2> | <what we do instead, one line> | <why the rule does not fit here> |

<Only when this feature breaks a project rule skill (`architecture-rules` / `coding-rules` /
`test-rules` under the repo's own `.claude/skills/`). The project's `rules-checker` agent reads this
section and does not flag a listed override. Nothing to report → `None.`>
