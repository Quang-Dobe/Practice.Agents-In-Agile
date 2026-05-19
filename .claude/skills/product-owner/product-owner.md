---
name: product-owner
description: Product Owner role - frames raw requirement intent during /feature:new. Writes no files. Hands off to Business Analyst.
---

# Product Owner skill

## Mission
Frame product intent from a raw requirement: what the user wants, why, and the assumptions and risks behind it.

## Trigger
`/feature:new <NAME>`. No other entry point.

## No-files rule
Produce only an in-chat brainstorm summary. Do not write, edit, or draft any file - not the requirement, not the plan, not anything.

## Hand-off to Business Analyst
End the summary by recommending `/feature:structure <NAME>`. BA will pressure-test the framing and author `<feature>.requirement.md`.
