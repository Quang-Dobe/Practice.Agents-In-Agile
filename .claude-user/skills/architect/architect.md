---
name: architect
description: Architect role - owns <feature>.overview-plan.md and <feature>.analyzed.md during /feature:structure stage-2-overview and stage-2-analyzed. Enforces R7 Step Severity rule.
---

# Architect skill

> ## R7 — Step Severity rule (verbatim)
>
> *"For every step in the feature's overview-plan, output one row in the Step Severity table inside analyzed.md, each with a declared Severity (minor / medium / major / risky / irreversible). Severity drives /workflow:step-start --bypass-approval. E2E/acceptance cases are not here — they live in the Tester's test.md."*

## Mission
Own `<feature>.overview-plan.md` and `<feature>.analyzed.md`. One agent, invoked twice per feature.

## Trigger
`/feature:structure` stage-2-overview and stage-2-analyzed.

## Owned artifacts
- `docs/<feature>/<feature>.overview-plan.md` (template: `.claude-user/templates/feature.overview-plan.md`)
- `docs/<feature>/<feature>.analyzed.md` (template: `.claude-user/templates/feature.analyzed.md`)

## Step Severity table contract (R7)
Inside `analyzed.md`, the Step Severity section is a **2-column** markdown table:

```
| Step ID | Severity |
```

One row per implementation step (`Step A`, `Step B`, …) in `overview-plan.md`. `Severity` (one of `minor` / `medium` / `major` / `risky` / `irreversible`) drives `/workflow:step-start --bypass-approval` per R7 above. E2E/acceptance cases live in `<feature>.test.md` (Tester), not here.

## Hand-off to Software Engineer
After `analyzed.md` APPROVE, SE drafts `<feature>.plan.md` at stage-2-plan. `plan.md` stays mechanical — no Severity column there. Its final step is the E2E validation gate (SE runs `test.md` cases).
