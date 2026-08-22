---
name: pr-review-learning
description: Draft a rule section from a fixed PR-review finding and resolve which repo-tier rule skill it belongs in, including the mandatory Also load wiring for a new open concern. Returns drafts; writes no file. Used by the pr-review-analyst agent at /pr-review:learn.
---

# PR review learning skill

## Mission
Turn a fixed finding into one rule section that a future planning or implementation run will read, and name exactly where that section goes.

## Owned artifact
Writes no file. Returns drafts to main Claude, which writes them only after the user types `APPROVE`.

## Read scope
- Only the ledger rows the command names in the prompt — the command has already selected them by `status` exactly `fixed` — lowercase, matched exactly, so `done` and `resolved` do not count — and `promoted: no`. Read no other ledger under `docs/<feature>/pr-review/`; selection is the command's job alone, never this skill's.
- The repo's existing rule skills, discovered by concern name via `project-seams`: `architecture-rules`, `coding-rules`, `test-rules`, plus any open concern.
- `~/.claude/templates/project-rules.template.md` — the shape a rule skill follows.

## Procedure

1. **Read the target skill before drafting.** You need its existing section numbers and its `## Also load` list, if it has one.

2. **Draft one rule section per finding.** Match the shape of `project-rules.template.md`:
   - a statement, imperative and testable;
   - a one-line rationale;
   - one good example and one bad example.

   Write the rule as a general standing rule, not as a retelling of this one PR comment. A rule that names a single file is a bug report, not a rule.

3. **Resolve the target.**

   | Case | `action` | Target |
   |---|---|---|
   | fits a reserved concern the repo already has | `append` | that skill |
   | fits a reserved concern the repo does not have yet | `create-skill` | a new skill at that reserved concern's path. **No `## Also load` line** — the three reserved concerns are auto-discovered. |
   | fits an open concern the repo already has | `append` | that skill |
   | needs its own open concern | `create-skill` | a new `<concern>/SKILL.md` from the template |
   | process only — PR size, commit message, branch name | `drop` | none; log it and move on |

   A concern is created at most once per run. When a later finding in the same run also resolves to `create-skill` for a concern this run already created, change its action to `append` instead, targeting that just-created skill, with its section numbered after the first draft's rule (see step 4) — and produce no second `## Also load` line for that concern.

4. **Pick the section number.** Never renumber an existing section: planning artifacts cite them, for example `per coding-rules Section 3.2`, and renumbering breaks every citation.

   | Case | Number to pick |
   |---|---|
   | appending to a skill that already exists | the highest existing top-level number plus one, placed at the end of the file |
   | creating a new skill from the template | put the first rule in **Section 2**, delete the unused placeholder rule groups, and resolve the template's symbolic tail sections to `3` (Forbidden Patterns) and `4` (Overrides) |

   Accepted trade-off: after the first append to an existing skill, Forbidden Patterns and Overrides are no longer the last sections. A number that never moves is worth more than a tidy reading order, because every citation depends on it.

5. **Wire a new open concern — mandatory, not optional.** This step applies only when the new skill is an **open** concern. A newly created **reserved** concern (`architecture-rules`, `coding-rules`, `test-rules`) needs no wiring — those three are auto-discovered.

   An open concern is invisible until a reserved skill names it. Only the three reserved concerns are auto-discovered. So for every `create-skill` draft of an open concern, also produce the `## Also load` line and name its host:

   | Open concern is about | Host |
   |---|---|
   | a language or framework pattern | `coding-rules` |
   | layering, boundaries, dependency direction | `architecture-rules` |
   | test tooling or fixtures | `test-rules` |
   | more than one fits | `coding-rules` |

   State the chosen host in the draft so the user can override it at the gate. Depth is 1: the new skill's own `## Also load` would be ignored, so never rely on one.

6. **Compute the dedup key** for each draft:

   ```
   (concern, normalized rule statement)
   ```

   Normalize by lowercasing, then collapsing every run of whitespace to one space. Apply the same normalization to every existing rule statement already in the target skill before comparing — normalizing only the candidate and comparing it against raw existing text never matches, so the dedup would silently never fire. Skip a draft whose key already matches a rule in the target skill, or a draft already produced in this run from another ledger. Report each skip.

7. **Return the drafts.** One record per finding, fields in this order: `finding_id`, `target_path`, `section_number`, `section_title`, `rule_text`, `also_load_host`, `also_load_line`, `dedup_key`, `action`. Write nothing.

## Boundary
Writes no file — not the rule skill, not the ledger, not the `promoted` flag. Never writes into the root tier (`~/.claude/`): rules belong to the consuming repo's own `.claude/skills/`. Never renumbers an existing section, never edits a rule already present, and never commits. Does not segment reviews or hunt evidence; that is `pr-review-analysis`.
