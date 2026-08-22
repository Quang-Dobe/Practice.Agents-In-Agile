---
name: present-overview-plan
description: Project a feature's overview-plan into the Workflow tab — a Workflow diagram and a Component Design diagram scoped to the Architect-named bounded contexts, drawn via present-draw-diagram. Component Design grounds on docs/domain+narrative (project mode) or docs/references.md+memory (root mode). Used by the present-builder agent.
---

# present-overview-plan

Render the **Workflow** tab. Grounding depends on the mode the command gate detected and passed in:
- **project mode** — read the scoped BCs from `docs/domain/` + `docs/narrative/`.
- **root mode** — no per-BC wiki; ground the Component Design diagram on `docs/references.md` (+ `docs/memory/` rollups), scoped by the Affected-BC list. When `references.md` is absent but a hand-written `docs/architecture.md` is present, ground on that instead — it is the root-tier human seam, not a stale copy of the rollup.

The Workflow flow diagram and the text content come from the feature's own `overview-plan.md` and render in **both** modes.

1. Read `docs/<feature>/<feature>.overview-plan.md`. Take the **Affected bounded contexts** list as the scope key. In **project mode** read those BCs from `docs/domain/` + `docs/narrative/`; in **root mode** read their coverage from `docs/references.md` (+ `docs/memory/`), falling back to a hand-written `docs/architecture.md` when the rollup is absent. Ignore unrelated BCs.
2. **Workflow diagram:** from the overview-plan "Core Behaviour (MVP)" steps, build a flow graph. Hand the node/edge design to the `present-draw-diagram` skill (follow its Steps 1–6); embed the returned `<svg>` fragment into the `<!-- present:begin:diagram --> … <!-- present:end:diagram -->` slot.
3. **Component Design diagram:** from the scoped BCs/components (resolved per the mode in step 1) + the "Solution / Module Structure", build an architecture graph; draw it via `present-draw-diagram`; append it in the same `<!-- present:begin:diagram --> … <!-- present:end:diagram -->` slot under an `<h2>Component Design</h2>`. If **neither** grounding source resolves the scoped BCs, skip Component Design, note the gap in the slot, and still emit the Workflow flow diagram + content.
4. Fill the content slot with the Purpose paragraph and the High-Level Goals table. Preserve human fences.
5. Write `docs/<feature>/present/present-overview-plan.html`; ensure `present.css` is present.
6. Code/wiki is the single source of truth; comments only seed naming. [R-EXPLORE].
