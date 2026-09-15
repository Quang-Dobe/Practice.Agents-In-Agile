---
name: present-builder
description: Project-tier runtime agent. Builds the per-unit present-*.html files for a feature from its planning artifacts (and the wiki, for diagram units). Gate-free; runs in project mode (docs/domain+docs/narrative) or root mode (docs/references.md+docs/memory) — /present:build detects the mode and passes it in.
tools: Read, Glob, Grep, Write, Edit
skills:
  - present-draw-diagram
---

# present-builder

Runtime agent. Given a feature name, one or more unit names, **and the grounding mode** (`project` or
`root`, passed by `/present:build`), render each named unit to
`docs/<feature>/present/present-<unit>.html` by following its section below.

## Every unit — the shared contract

1. Load the matching template `present-<unit>.html` from the project `.claude/templates/`.
2. Fill the `<!-- present:begin:content -->…<!-- present:end:content -->` slot with that unit's
   content, described below.
3. Preserve any `<!-- human:begin -->…<!-- human:end -->` fenced edits in the existing output
   **byte-for-byte**.
4. Write `docs/<feature>/present/present-<unit>.html`. Copy `present.css` into that folder if absent.
5. Derive every fact from the artifact text — and, for diagram units, from the grounding source.
   Never invent scope; code and the wiki are the single source of truth and comments only seed
   naming. [R-EXPLORE].

**Diagram units** (`overview-plan`, `plan`) hand their node/edge design to the preloaded
`present-draw-diagram` skill (follow its Steps 1–6) and embed the returned `<svg>` fragment into the
`<!-- present:begin:diagram --> … <!-- present:end:diagram -->` slot.

## `requirement` — the Introduction tab

Read `docs/<feature>/<feature>.requirement.md`. Extract the feature title (the `# <title>` heading)
and the `## Goal` section. Ignore `## Rules`, `## Your Requirements`, `## Your Tasks`, and the step
checkboxes. Older files with no `## Goal` section → fall back to the intent prose. **Never** read
`<feature>.requirement-trace.md` — it holds history, not the requirement.

Content: an `<h2>` of the feature title and 1–2 `<p>` of the Goal. Text only; no wiki, no diagram.

## `overview-plan` — the Workflow tab

Grounding depends on the mode the command gate detected and passed in:
- **project mode** — read the scoped BCs from `docs/domain/` + `docs/narrative/`.
- **root mode** — no per-BC wiki; ground the Component Design diagram on `docs/references.md`
  (+ `docs/memory/` rollups), scoped by the Affected-BC list. When `references.md` is absent but a
  hand-written `docs/architecture.md` is present, ground on that instead — it is the root-tier human
  seam, not a stale copy of the rollup.

The Workflow flow diagram and the text content come from the feature's own `overview-plan.md` and
render in **both** modes.

1. Read `docs/<feature>/<feature>.overview-plan.md`. Take the **Affected bounded contexts** list as
   the scope key, and resolve those BCs per the mode above. Ignore unrelated BCs.
2. **Workflow diagram:** from the "Core Behaviour (MVP)" steps, build a flow graph and draw it.
3. **Component Design diagram:** from the scoped BCs/components (resolved per the mode in step 1) plus
   the "Solution / Module Structure", build an architecture graph; draw it and append it in the same
   diagram slot under an `<h2>Component Design</h2>`. If **neither** grounding source resolves the
   scoped BCs, skip Component Design, note the gap in the slot, and still emit the Workflow flow
   diagram + content.
4. Content: the Purpose paragraph and the High-Level Goals table.

## `test` — the E2E Test tab

Read `docs/<feature>/<feature>.test.md`. Collect each `E2E-n` block (title, Covers, Given, When,
Then) and the "Out of scope" list.

Content: a table, one row per `E2E-n`, followed by the out-of-scope bullets. Text only.

## `analyzed` — the Analyzed tab

Read `docs/<feature>/<feature>.analyzed.md`. Collect the Decision Summary table, the Step Severity
table, and the Risks/Residual rows.

Content: those three tables under `<h2>` sub-headings. Text only.

## `plan` — the Code Structure tab

Read `docs/<feature>/<feature>.plan.md`. Collect the per-step "Types to create" trees and Deliverables.

- **Blueprint mode (default):** content is the intended file tree (`<pre>`) plus a per-file intent table.
- **Real-content mode (post-implementation):** for files that now exist on disk (named in the plan),
  read them and embed their actual content in `<pre>` blocks, replacing the blueprint for those files.
  Derive from the real file, not the plan prose.

Optional: if the plan defines a notable module structure, draw it into the diagram slot.

## Boundary

Writes only under `docs/<feature>/present/`. Never authors planning artifacts. No APPROVE gate.
