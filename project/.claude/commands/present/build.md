---
description: Build (or refresh) the present-* dossier for a feature from its planning artifacts. Wiki-gated, gate-free.
argument-hint: <feature> [unit...]
---

`$ARGUMENTS` = `<feature>` then optional unit names (`requirement` `overview-plan` `test` `analyzed` `plan`). If `<feature>` is missing, error: `specify a feature, e.g. /present:build payments-export`.

1. **Mode gate (replaces D11).** Detect the grounding mode in the working dir:
   - **project mode** — `docs/domain/` OR `docs/narrative/` exists non-empty.
   - **root mode** — none of those, but `repo-layout.md` OR `docs/memory/` OR `docs/references.md` OR a hand-written `docs/architecture.md` exists.
     Both architecture files count, and they are different things: `docs/references.md` is the wiki's **generated** cross-repo rollup, `docs/architecture.md` is the **human-authored** free-form seam the root-tier feature crew reads (the root tier's `project-seams` skill). Prefer `references.md` when both are present; it is derived from the wiki and stays in step with the code.
   - **neither** — print `present skipped: no grounding (project: docs/domain+docs/narrative | root: repo-layout.md / docs/memory / docs/references.md / docs/architecture.md) — run /project:overview + /project:explore, or /wiki:bootstrap.` and stop. Do not create `docs/<feature>/present/`.
   When **both** project and root signals exist, **project mode wins** (per-BC wiki is richer than the root rollup). Carry the detected mode + its grounding paths into every `present-builder` spawn so the diagram unit (`present-overview-plan`) reads the right source.
2. Verify `docs/<feature>/` exists with at least one planning artifact. If not, error: `feature '<feature>' not found at docs/<feature>/`.
3. Resolve the unit list: explicit units from `$ARGUMENTS`, else every unit whose source artifact exists (`requirement`→requirement.md, `overview-plan`→overview-plan.md, `test`→test.md, `analyzed`→analyzed.md, `plan`→plan.md).
4. Spawn the `present-builder` agent once per resolved unit (or once with the unit list), passing `<feature>` + unit name(s) **+ the detected mode and its grounding paths**.
5. After units are written, regenerate `docs/<feature>/present/present.html` from the index template `.claude/templates/present.html`: substitute `{{FEATURE}}`; rebuild the `present:tabs` block to list only units whose `present-<unit>.html` exists, in canonical order (Introduction, Workflow, E2E Test, Analyzed, Code Structure); set the first as `active` and the iframe `src`.
6. Print the written paths.

Gate-free: no APPROVE. Idempotent: rewrite only files whose bytes changed. Preserve `<!-- human:begin -->…<!-- human:end -->` fences.
