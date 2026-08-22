---
name: present-requirement
description: Project a feature's requirement.md Goal into the Introduction tab (present-requirement.html). Text only; no wiki, no diagram. Used by the present-builder agent.
---

# present-requirement

Render the **Introduction** tab.

1. Read `docs/<feature>/<feature>.requirement.md`. Extract the feature title (the `# <title>` heading) and the `## Goal` section. Ignore `## Rules`, `## Your Requirements`, `## Your Tasks`, and the step checkboxes. Older files with no `## Goal` section → fall back to the intent prose. Never read `<feature>.requirement-trace.md` — it holds history, not the requirement.
2. Load the template `present-requirement.html` (project `.claude/templates/`).
3. Replace the `<!-- present:begin:content -->…<!-- present:end:content -->` slot with: an `<h2>` of the feature title and 1–2 `<p>` of the Goal. Preserve any `<!-- human:begin -->…<!-- human:end -->` fenced edits in the existing output byte-for-byte.
4. Write `docs/<feature>/present/present-requirement.html`. Copy `present.css` into that folder if absent.
5. Derive only from the artifact text — never invent scope. [R-EXPLORE].
