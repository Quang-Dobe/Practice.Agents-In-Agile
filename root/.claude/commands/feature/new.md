---
description: Brainstorm a new feature with the product-owner subagent (no files written)
argument-hint: <feature-name>
---

Brainstorm a new feature using the `product-owner` subagent. This command writes nothing - it produces an in-chat conversation only.

`$ARGUMENTS` is the feature name (kebab-case folder name under `docs/`). If empty, error: `specify a feature name, e.g. /feature:new payments-export`.

1. Verify `docs/<name>/<name>.raw-requirement.md` exists. If missing, error: `raw requirement not found at docs/<name>/<name>.raw-requirement.md - create it before running /feature:new`.

2. Spawn the `product-owner` subagent with these inputs:
   - Feature name: `<name>`
   - Raw requirement path: `docs/<name>/<name>.raw-requirement.md`

   - The narrative tree, **resolved first** — it is not always at the working-directory root. Try, in order: `docs/narrative/` at the working directory; then, per code root declared in `repo-layout.md` (via the `repo-layout` skill), `<root>/docs/narrative/`; then a bounded glob of `*/docs/narrative/` and `*/*/docs/narrative/`, two levels deep, never a repo-wide sweep. Pass the **resolved paths** into the spawn — never a bare `docs/narrative/`.

   The PO reads only the raw requirement file plus the narrative paths resolved above (optional product context). Absent at every level → the PO emits `docs/narrative/ not found at the working directory or one level down - run /project:overview to generate it; proceeding without it.` and proceeds — it never blocks. **Never emit that line when a nested narrative was found**; it would send the user to bootstrap a second wiki over a repo that already has one. Engineering-context reads are out of scope for the PO — they belong to the downstream Business Analyst / Architect / Software Engineer.

3. Relay the Product Owner's `[Waiting for Answer]` questions to the user. Continue Q&A rounds with the PO until it returns a final brainstorm summary.

4. Print the final summary in chat. Do **not** modify any file. Do **not** spawn any other subagent.

5. Recommend running `/feature:structure <name>` next (in this session for best context, or a fresh session if user prefers). There the Business Analyst pressure-tests the PO's framing and authors two **new** files — `<name>.requirement.md` (the final requirement) and `<name>.requirement-trace.md` (the decisions behind it). `<name>.raw-requirement.md` is never overwritten; it stays exactly as the user typed it.
