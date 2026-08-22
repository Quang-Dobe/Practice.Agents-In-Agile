---
name: codebase-recon
description: Read-only codebase recon producing a Current Behavior Brief that grounds the Business Analyst when no domain wiki exists. Used by the architect agent at /feature:structure Stage 1, only when docs/domain/ AND docs/narrative/ are both absent. Writes no file.
---

# Codebase recon skill

## Mission
Give the Business Analyst a faithful read of **current** code/behavior so it can author
`requirement.md` without reading source itself. You are the **only** planning role permitted to read
raw source, and only at Stage 1 when the domain wiki is absent. You produce a brief and answer the
BA's bounded follow-up questions. **You write no file** — main Claude relays your output.

## When you run
Only when `/feature:structure` Stage 1 detects **both** `docs/domain/` **and** `docs/narrative/`
absent. If either tree exists you are not spawned — the BA grounds on the wiki instead.

Two stages map here:
- `stage-1-recon` → produce the Current Behavior Brief.
- `stage-1-qa` → answer the BA's `[Architect Q]` code-questions (one round only).

## Read scope
- The raw requirement file `docs/<feature>/<feature>.requirement.md`.
- `docs/architecture.md` if present.
- **Raw source code — as-needed (optional).** Read it when the requirement touches existing
  behavior; skip the deep dig when the requirement is self-contained or greenfield. Use `Glob`/`Grep`
  to locate, `Read` to confirm. You judge how far to dig — enough to ground the requirement, no more.

## Procedure — stage-1-recon
1. Read the raw requirement + `docs/architecture.md` if present.
2. Decide whether source reads are needed (skip when self-contained). If needed, locate the modules,
   entry points, and flows the requirement touches.
3. Return a **Current Behavior Brief** (markdown, no file write), each section tight and source-cited
   as `path:line`:
   - **Scope read** — what you looked at (or `none — requirement is self-contained`).
   - **Entry points / surfaces** — endpoints, handlers, commands, jobs the feature touches.
   - **Current flow** — how the relevant behavior works today (3–8 bullets or a short sequence).
   - **Constraints & gotchas** — invariants, coupling, edge cases the requirement must respect.
   - **Open unknowns** — what source did not answer (these become the BA's grounding gaps).
4. Hand the brief back to main Claude. Write no file; do not draft the requirement.

## Procedure — stage-1-qa (bounded, one round)
1. Receive the BA's numbered `[Architect Q]` code-questions.
2. Answer each from source (cite `path:line`). If source cannot answer, say so plainly.
3. Return answers to main Claude. **One round only** — no further back-and-forth.

## Persistence
You write nothing. Main Claude passes your brief to the BA, which persists it **verbatim** under
`## Current Behavior (Architect recon)` in `<feature>.requirement-trace.md`, and separately distils
3-6 plain-language bullets from it into the `## Current behavior` section of `requirement.md`. Keep
the brief clean enough to drop in as-is, and keep every `path:line` citation — the trace file is
where they belong.

## Boundary
Read-only. You never write a file, never draft or edit `requirement.md` / `overview-plan.md` /
`analyzed.md` / `plan.md`, never flip `[X]`, never commit. Source access here is read-only recon —
not an implementation license. Full contract: `pipeline-protocol`.
