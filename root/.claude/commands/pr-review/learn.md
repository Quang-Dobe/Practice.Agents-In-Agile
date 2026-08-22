---
description: Turn a feature's fixed PR-review findings into rule sections inside this repo's own .claude/skills/. APPROVE-gated.
argument-hint: --feature <feature> [--review <stem>]
---

Promote the review findings you already fixed into rules the crew reads next time.

`$ARGUMENTS` carries two named flags. They are order-independent.

| Flag | Required | Value |
|---|---|---|
| `--feature` | yes | kebab-case folder name under `docs/` |
| `--review` | no | review file stem, no `.md` extension |

1. **Parse and validate.** Stop with the matching literal:
   - `--feature` missing → `specify a feature, e.g. /pr-review:learn --feature payments-export --review round-1`
   - `docs/<feature>/` missing → `feature '<feature>' not found at docs/<feature>/`
   - `docs/<feature>/pr-review/` missing → `no pr-review folder at docs/<feature>/pr-review/`
   - `--review <stem>` given but its ledger missing → `ledger '<stem>.pr-review.ledger.md' not found — run /pr-review:analyze --feature <feature> --review <stem> first.`

2. **Resolve the ledger set.** `--review <stem>` → that one ledger. Omitted → every `*.pr-review.ledger.md` under `docs/<feature>/pr-review/`.

3. **Report any orphan.** For each `*.pr-review.ledger.md` with no matching `<stem>.md`, print `orphaned ledger: <file> has no matching <stem>.md — left untouched.` Advisory only; its rows are still eligible. This scan runs before the row selection below, so it still prints even when that selection turns out empty — the one case where it is the only thing telling you your ledger's IDs and statuses are still there.

4. **Select the rows.** Take every finding where `status: fixed` **and** `promoted: no`. This key is this command's alone — the reviewed / not-reviewed rule belongs to `/pr-review:analyze`. If the selection is empty, print `no fixed, unpromoted findings — nothing to promote.` and stop.

5. **Spawn `pr-review-analyst`** with `description: PR review: draft rules for <feature>` and a `prompt` carrying: the feature name, `stage: learn`, every selected finding with its global ID `<stem>#PR-NN`, and the paths of the repo's existing rule skills. It follows its `pr-review-learning` skill and returns drafts. **It writes nothing.**

6. **Show every draft and wait.** Print, per draft:
   - the global finding ID `<stem>#PR-NN`;
   - `action` — `append`, `create-skill`, or `drop`;
   - the target path, for example `.claude/skills/coding-rules/SKILL.md`;
   - the section number and title;
   - the exact rule text, verbatim;
   - for a `create-skill` draft of an **open** concern, the `## Also load` host and the line to add. A `create-skill` draft for an absent **reserved** concern carries neither — those three are auto-discovered;
   - any dedup skip, with its key.

   Mark it `[Waiting for Approval]`. Wait for the user to type `APPROVE`. Do not write otherwise. If the user rejects or edits a draft, re-present and wait again. A message that both approves and rejects — for example `APPROVE all except PR-03` — is a **rejection round**, not an approval: drop or amend the named drafts, re-present the reduced set, and wait again. A bare `APPROVE` writes only the drafts currently shown, unchanged.

7. **After APPROVE, write.** Main Claude does this — the gate never moves to a subagent.
   - **Append** each section at the END of its target skill. **Never renumber an existing section**: planning artifacts cite them, for example `per coding-rules Section 3.2`.
   - **Create** a missing target skill from `~/.claude/templates/project-rules.template.md`, then place its first rule per the `pr-review-learning` skill's step 4 — Section 2, with the template's symbolic tail sections resolved. Do not append a brand-new skill's first rule at the end of the file. Also resolve every angle-bracket placeholder in the template's frontmatter and headings to the real concern name and this project's name, and delete the template's own copy-me instruction comment — a placeholder left in place will not match its folder and will never resolve, a silent dead rule the gate cannot catch.
   - **Wire** every new open concern into a reserved skill's `## Also load` list. Without that line no agent ever reads the new skill — a silent dead rule.
   - **Never write into the root tier** (`~/.claude/`). Rules belong to this repo's `.claude/skills/`. Per `~/.claude/CONVENTIONS.md`: the root tier is never edited per project.
   - **Skip** any draft whose dedup key `(concern, normalized rule statement)` already matches a rule in the target, and say so.
   - **Drop** writes nothing at all. Log it and move on.
   - **Flip** `promoted: no` to `promoted: yes` on every selected row this run acted on, whichever way it acted — written, dropped, or deduped alike. That is still the only edit any command makes to an existing ledger section; it now just covers all three outcomes instead of one, so a dropped or deduped row reaches a terminal state too and is never re-drafted or re-shown at a future gate.

8. **Print the summary.** Sections appended, skills created, `## Also load` lines added, drafts dropped, drafts deduped, and the ledger rows flipped. Then run `git status` so the user can see the change.

**Never commits.** The user commits.

**Note:** flipping `promoted` makes the ledger newer than its page. The next `/pr-review:analyze` sweep re-renders that page from the ledger — a ledger read only, no re-analysis.
