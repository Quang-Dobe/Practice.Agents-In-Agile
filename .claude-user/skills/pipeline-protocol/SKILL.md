---
name: pipeline-protocol
description: The shared artifact-ownership and approval contract for the feature crew — who owns what, who flips checkboxes, how to gate on APPROVE, template fidelity, no commits. Loaded by every feature-crew agent.
---

# Pipeline protocol skill

The single source of truth for the contract every feature-crew agent obeys. Capability skills hold the *how* of one artifact; this skill holds the *rules* shared by all.

## Ownership (one artifact, one owner)
| Artifact | Owner agent |
|---|---|
| `requirement.md` | business-analyst |
| `overview-plan.md`, `analyzed.md` | architect |
| `test.md` | tester |
| `plan.md` + production code + unit tests + e2e tests | software-engineer |
| (no file) brainstorm summary | product-owner |
| (no file) open-question punch list | workflow-step-planner |
| (no file) Current Behavior recon brief + stage-1 code-Q&A answers | architect (stage-1, wiki absent) |

You touch **only your own artifact(s)**. You never modify another role's file, the templates, or other features' files.

## Checkbox + status ownership (main Claude, not agents)
- You do **not** flip `[ ]` → `[X]`. Main Claude does that after the user types `APPROVE` (via `/workflow:step-approve` or the matching stage gate).
- You do **not** create or update `<feature>.status.md`. Main Claude initializes and maintains it.

## Approval + questions
- Surface unresolved decisions as numbered `[Waiting for Answer]` questions and wait for the user (relayed via main Claude) before writing. Follow-ups are fine — keep them numbered and tagged.
- After writing your artifact, end with a one-line hand-off naming the next stage and what is awaiting APPROVE.

## Template fidelity
- Mirror the matching `~/.claude/templates/feature.*.md` structure exactly. Copy verbatim the sections the template marks as verbatim (`## Rules`, `## Your Tasks`, etc.).

## No commits
- Never run `git commit` or `git push`. The user commits explicitly.

## Stage routing comes from the command, not from you
- The command that spawns you names the stage/target artifact. Map it to the matching preloaded capability skill and follow that skill. Do not enumerate stages or invent a procedure — the skills hold it.

## Stage-1 codebase recon (conditional)
- Triggered only when `/feature:structure` Stage 1 finds **both** `docs/domain/` and `docs/narrative/` absent. The architect runs a read-only `codebase-recon` pass and returns a Current Behavior Brief (no file). The BA persists it as the `## Current Behavior (Architect recon)` appendix in `requirement.md`.
- The BA **never reads source**. If the brief leaves code-level gaps, the BA raises numbered `[Architect Q]` questions; main Claude relays them to the architect (`stage-1-qa`) for **one** answer round only. No multi-round loop and no agent-to-agent channel — main Claude mediates every exchange.
