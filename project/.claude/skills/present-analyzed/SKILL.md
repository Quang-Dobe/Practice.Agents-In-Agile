---
name: present-analyzed
description: Project a feature's analyzed.md steps, severity, decisions and residual flags into the Analyzed tab (present-analyzed.html). Text only. Used by the present-builder agent.
---

# present-analyzed

Render the **Analyzed** tab.

1. Read `docs/<feature>/<feature>.analyzed.md`. Collect: the Decision Summary table, the Step Severity table, and the Risks/Residual rows.
2. Load `present-analyzed.html`; fill the content slot with those three tables under `<h2>` sub-headings. Preserve human fences.
3. Write `docs/<feature>/present/present-analyzed.html`. Ensure `present.css` is in the folder.
4. Derive only from the artifact. [R-EXPLORE].
