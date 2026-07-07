---
name: present-test
description: Project a feature's test.md acceptance cases + scope into the E2E Test tab (present-test.html). Text only. Used by the present-builder agent.
---

# present-test

Render the **E2E Test** tab.

1. Read `docs/<feature>/<feature>.test.md`. Collect each `E2E-n` block (title, Covers, Given, When, Then) and the "Out of scope" list.
2. Load `present-test.html`; fill the content slot with a table (one row per `E2E-n`) followed by the out-of-scope bullets. Preserve human fences.
3. Write `docs/<feature>/present/present-test.html`. Ensure `present.css` is in the folder.
4. Derive only from the artifact. [R-EXPLORE].
