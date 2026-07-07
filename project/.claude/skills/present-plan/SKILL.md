---
name: present-plan
description: Project a feature's plan.md into the Code Structure tab — blueprint (file tree + per-file intent) during planning, real file content after implementation. Optional structure diagram via present-draw-diagram. Used by the present-builder agent.
---

# present-plan

Render the **Code Structure** tab.

1. Read `docs/<feature>/<feature>.plan.md`. Collect the per-step "Types to create" trees and Deliverables.
2. **Blueprint mode (default):** fill the content slot with the intended file tree (`<pre>`) and a per-file intent table.
3. **Real-content mode (post-implementation):** for files that now exist on disk (named in the plan), read them and embed their actual content in `<pre>` blocks, replacing the blueprint for those files. Derive from the real file, not the plan prose. [R-EXPLORE].
4. Optional: if the plan defines a notable module structure, draw it via `present-draw-diagram` into the `<!-- present:begin:diagram --> … <!-- present:end:diagram -->` slot.
5. Preserve human fences. Write `docs/<feature>/present/present-plan.html`; ensure `present.css` is present.
