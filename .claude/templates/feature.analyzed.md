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

## N+2. Project-Specific Overrides of `dotnet-rules`

If this feature requires deviating from a rule in `.claude/skills/dotnet-rules/dotnet-rules.md`, list each override here with:

- The rule section being overridden.
- The override (one line).
- The justification (why the rule does not apply here).

The `dotnet-rules-checker` agent reads this section before flagging violations and will not flag listed overrides.

---

## N+3. Approval Checklist

- [ ] All decisions in Section 1 have a recorded rationale.
- [ ] All risks in the Risks section list a chosen mitigation.
- [ ] Overrides (if any) are scoped to specific rule sections and justified.
- [ ] Amendments to already-approved planning docs (if any) are listed in a `[Waiting for Approval]` block at the bottom.
