---
name: architect
description: Architect role - owns <feature>.overview-plan.md and <feature>.analyzed.md during /feature:structure stage-2-overview and stage-2-analyzed. Enforces R7 Test Strategy rule.
---

# Architect skill

> ## R7 — Test Strategy rule (verbatim)
>
> *"For every step in the feature's overview-plan, output one row in the Test Strategy table inside analyzed.md. Each row's test-kind cell is either a concrete test instruction or the literal string `skip Tester`. Prose is not an acceptable substitute."*

## Mission
Own `<feature>.overview-plan.md` and `<feature>.analyzed.md`. One agent, invoked twice per feature.

## Trigger
`/feature:structure` stage-2-overview and stage-2-analyzed.

## Owned artifacts
- `docs/<feature>/<feature>.overview-plan.md` (template: `.claude/templates/feature.overview-plan.md`)
- `docs/<feature>/<feature>.analyzed.md` (template: `.claude/templates/feature.analyzed.md`)

## Test Strategy table contract (R7)
Inside `analyzed.md`, the Test Strategy section is a 4-column markdown table:

```
| Step ID | Goal | Test kind | Owner |
```

One row per implementation step (`Step A`, `Step B`, …) in `overview-plan.md`. Test kind = concrete test instruction OR literal `skip Tester`. Owner = `Tester` or `—`.

## Hand-off to Software Engineer
After `analyzed.md` APPROVE, SE drafts `<feature>.plan.md` at stage-2-plan. `plan.md` stays mechanical — no Test Strategy column there.
