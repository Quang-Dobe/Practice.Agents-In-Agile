---
name: wiki-architecture
description: Cross-repo synthesis + context-map + fence-preservation write manual for docs/architecture.md, owned solely by the wiki-architect agent
version: 1
consumed_by: wiki-architect agent
---

## Purpose

The auditable manual for (re)authoring the root `docs/architecture.md` — the cross-repo
overview. It is the **only** write path to that file; the `wiki-memory` and `/wiki:ask`
paths are forbidden from touching it. Reloaded by the `wiki-architect` agent at the start of
every run.

## Output root (nested mode)

When the dispatch provides an `output_root`, this skill writes `docs/architecture.md` at `<output_root>/docs/architecture.md` instead of the bare root `docs/architecture.md`; the per-child inputs are the direct children the dispatch names. Human `<!-- human:begin --> ... <!-- human:end -->` fences are still preserved byte-for-byte. Absent `output_root` → today's root `docs/architecture.md`, byte-identical. The nested orchestrator sets this per the `wiki-orchestration` skill `## Output root (nested mode)`.

## Inputs (read-only)

Per qualifying repo: `docs/narrative/` (human walkthrough), `docs/domain/` (Evans-canonical
schema — the source of cross-repo events/commands), and `docs/memory/` (per-repo learnings,
soft input). Never modify any input.

## Output shape

A full (re)generation of `docs/architecture.md` with these sections, in order:

1. `# System Overview` — 3–6 sentence plain-language description of what the whole system
   does, synthesized across repos.
2. `## Context Map` — the cross-repo flow, **derived mechanically** from domain events:
   for each event/command in a repo's `docs/domain/`, find the consuming repo and emit a
   line `Publisher --EventName--> Consumer`. Group by publisher. This section is the
   load-bearing artifact (a future staleness check can re-derive it).
3. `## Per-repo summaries` — one short paragraph per repo (name + responsibility + key
   aggregates), paraphrased from its narrative/domain. No verbatim multi-line copies.

Keep prose terse. Do not paste Mermaid bodies, full aggregate tables, or runs of ≥2
consecutive non-trivial source lines from any input.

## Fence preservation (load-bearing)

Even though this path **fully regenerates** `docs/architecture.md`, any
`<!-- human:begin --> ... <!-- human:end -->` region in the **existing** file is preserved
**byte-for-byte**: read the current file first, extract every fenced region with its
anchoring context, and re-emit those bytes unchanged in the regenerated output at the same
relative position (matched by the heading or marker immediately preceding the fence). The
agent never writes inside a fence and never alters fenced bytes. Everything **outside** the
fences is regenerated.

## Write confinement

The sole write target is `docs/architecture.md`. Never write to `docs/memory/` (root or
per-repo), any repo's `docs/narrative/` / `docs/domain/`, repo source, or `.claude/`. Before
writing, confirm the target path resolves to the root `docs/architecture.md`.

## Gate + commit posture

Ungated (no `APPROVE`); safety net is fence preservation + single-owner confinement. Never
`git add` / `git commit`; leave the file as a working-tree change.

## Well-formedness

Well-formed for write iff frontmatter parses as YAML with `name: wiki-architecture` +
`version` + `consumed_by`, AND the body contains `## Output shape`, `## Fence preservation`,
and `## Write confinement`. If malformed, the `wiki-architect` agent stops before writing
`docs/architecture.md` and reports it.
