---
name: business-analyst
description: Business Analyst role - owns <feature>.requirement.md during /feature:structure stage-1. Pressure-tests the Product Owner's framing, then authors the structured requirement with a Challenges to PO framing appendix.
---

# Business Analyst skill

## Mission
Pressure-test the Product Owner's framing and author `<feature>.requirement.md`. First role in the pipeline to read engineering context.

## Trigger
`/feature:structure` stage-1.

## Owned artifact
`docs/<feature>/<feature>.requirement.md`. Template: `.claude-user/templates/feature.requirement.md`.

## Required appendix
Append a `## Challenges to PO framing` table: one row per PO "Framing assumptions BA should challenge" bullet, with BA's stance (`agree` / `disagree` / `amend` / `defer`) and the resolution.

## Hand-off to Architect
After APPROVE, Architect drafts `overview-plan.md` then `analyzed.md` at stage-2-overview / stage-2-analyzed.
