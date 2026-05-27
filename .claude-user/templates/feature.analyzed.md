# <Feature title> - Approach Analysis & Rationale

> **Status:** [Waiting for Approval]
>
> **Purpose:** capture *why* the design in `<feature>.overview-plan.md` and `<feature>.plan.md` was chosen over realistic alternatives, and surface trade-offs being accepted.

---

## 1. Decision Summary

| # | Decision | Alternative considered | Why this one |
|---|---|---|---|
| D1 | <decision> | <alt> | <one-line rationale> |
| D2 | <decision> | <alt> | <one-line rationale> |

---

## 2. <First load-bearing decision>

Detailed rationale. Cover: what was considered, why the chosen option wins for this feature, and what trade-off is accepted.

---

## 3. <Second load-bearing decision>

Same shape as Section 2.

---

## N. Risks & Trade-offs Explicitly Accepted

| Risk | Mitigation chosen | Mitigation rejected (and why) |
|---|---|---|
| <risk> | <mitigation> | <rejected option + reason> |

---

## N+1. Out of Scope - Filed Follow-Ups

| # | Follow-up | Trigger |
|---|---|---|
| F1 | <deferred work> | <when to revisit> |

---

## N+2. Project-Specific Rule Overrides

If this feature deviates from a rule in a project rule skill (`architecture-rules` / `coding-rules` / `test-rules` under `.claude/skills/` — this scaffold ships none; see `.claude-user/CONVENTIONS.md`), list each override here with:

- The rule skill + section being overridden.
- The override (one line).
- The justification (why the rule does not apply here).

The project's rules-checker agent at `.claude/agents/rules-checker.md` (if it ships one) reads this section before flagging violations and will not flag listed overrides.

---

## N+3. Test Strategy

> Per R7: one row per implementation step in `overview-plan.md`. `Test kind` = concrete test instruction OR literal `skip Tester` (never prose). `Owner` = `Tester` or `—`. `Severity` = one of `minor` / `medium` / `major` / `risky` / `irreversible`, declared per step up front; minor/medium auto-approve under `/workflow:step-start --bypass-approval`, major/risky/irreversible hard-stop and wait for a human.

| Step ID | Goal | Test kind | Owner | Severity |
|---|---|---|---|---|
| A | <goal copied from overview-plan> | <concrete instruction OR `skip Tester`> | <`Tester` or `—`> | <`minor`/`medium`/`major`/`risky`/`irreversible`> |

---

## N+4. Approval Checklist

- [ ] All decisions in Section 1 have a recorded rationale.
- [ ] All risks in the Risks section list a chosen mitigation.
- [ ] Overrides (if any) are scoped to specific rule sections and justified.
- [ ] Test Strategy table is the 5-column R7 shape (`Step ID | Goal | Test kind | Owner | Severity`) with one row per implementation step and a justified Severity each.
- [ ] Amendments to already-approved planning docs (if any) are listed in a `[Waiting for Approval]` block at the bottom.
