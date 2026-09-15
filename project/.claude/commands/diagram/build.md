---
description: Draw the system diagram from an existing wiki. Reads docs/references.md, writes a PNG, and optionally a self-contained HTML page. Gate-free.
argument-hint: "[root-path] [--effort low|medium|high] [--html]"
---

Draw the architecture diagram for the wiki at `[root-path]`. This command **reads** the wiki and
**writes only diagram files**. It never touches `docs/references.md`, a repo's `docs/narrative/`, a
repo's `docs/domain/`, `docs/memory/`, or `repo-layout.md`.

It is deliberately **separate from `/wiki:*`**. The wiki decides what is true; this command decides
what a picture of it looks like. You can redraw at a different effort as often as you like without
re-walking a single repo.

## Arguments

`$ARGUMENTS` — an optional path, then optional flags, in any order.

| Argument | Default | Meaning |
|---|---|---|
| `[root-path]` | the working directory | the wiki scan root — the folder holding `docs/references.md` |
| `--effort low\|medium\|high` | `low` | how much detail to draw. See `## Effort` |
| `--html` | off | also write the SVG and the reader-facing page. Without it, only the `.excalidraw` and the PNG are written |

Refuse a remote path (`^https?://` or `^git@`) with:

```
diagram: local paths only — got <arg>
```

Refuse an unknown flag rather than ignoring it:

```
diagram: unknown option <arg> — expected --effort low|medium|high or --html
```

`--effort` with no value, or a value outside the three, is an error, not a silent fallback to `low`.

## Steps

1. **Resolve the path.** Default to the working directory. `Resolve-Path` it. If it does not exist,
   error and stop.

2. **Pre-flight the input.** `<root>/docs/references.md` must exist and must contain a
   `## Context Map` section. If the file is missing:

   ```
   diagram: no wiki found at <root>/docs/references.md — run /wiki:enhance first.
   ```

   If the file exists but has no `## Context Map`, say so and stop. Never invent a map.

3. **Spawn the `wiki-diagrammer` agent, once.** Pass it: the resolved root, the **effort level**,
   whether `--html` was given, and `output_root` when the root is not the working directory.

   It writes `docs/references.diagram.excalidraw` and `docs/references.diagram.png` always, and
   `docs/references.diagram.svg` **only when `--html` was given** — the SVG exists to be inlined, so
   without a page there is nothing to inline into. It returns the paths, the effort it drew at, and
   its counts.

4. **`--html` only — write the page.** At **this command layer**, not inside `wiki-diagrammer` (that
   agent has no `Agent` tool), spawn a `model: "sonnet"` subagent per `[R-HTML-AGENT]` to write
   `docs/references-diagram.html` from `.claude/templates/references-diagram.html`.

   The page has exactly **two** slots: the **inlined SVG** and the `## Boundaries` table. Pass the SVG
   path and the `## Boundaries` rows — read that section from `references.md` at this layer, because
   the subagent sees none of this session.

   The page inlines the SVG rather than the PNG on purpose: a raster image softens the moment a reader
   zooms, and zooming is what the page's camera is for.

   Without `--html`, skip this step entirely and say so in the summary.

5. **Print a summary**: the files written, the effort used, node and edge counts, and any advisory.

## Effort

Effort controls **how much of the map reaches the canvas**, and with it the number of render passes.
Each level is a superset of the one below.

| | `low` (default) | `medium` | `high` |
|---|---|---|---|
| repo nodes + call edges | yes | yes | yes |
| ingress node and its edges | yes | yes | yes |
| regions, their invariants, and their members | yes | yes | yes |
| what happens when a seam's config key is missing | yes | yes | yes |
| other out-of-system edges — stores, model hosts, collectors | **no** | yes | yes |
| per-node detail lines — routes, owned stores, config keys | no | yes (max 3) | yes (max 3) |
| the config keys themselves, in labels | no | yes | yes |
| annotation blocks — the map's own arguments and gaps | no | no | yes |
| legend block | no | no | yes |
| render passes | **1**, plus a correction pass if the render breaks | 2–3 | 3–5 |

A seam's **failure state** is at `low` on purpose. Without it a cheap diagram draws confident arrows
for calls that do not happen when one environment variable is unset — an in-process stand-in answers
instead — and a reader cannot tell the difference. The config *key* can wait for `medium`; what
happens when it is missing cannot.

- **`low`** answers *how does a request flow, where are the boundaries, and what breaks if a key is
  missing*. It is the default because that is the question asked most often, and because it renders in
  one pass.
- **`medium`** adds the evidence — what each repo owns, which keys point where, what happens when a
  key is missing.
- **`high`** adds the map's own reasoning: the gaps it found, the groupings it rejected, the
  fail-fast-versus-degrades contrast. Slowest, and the only level worth sharing with someone who was
  not in the room.

**Effort also shapes the page.** The page always has the same two slots — diagram and boundaries —
but at `high` the artwork inside the first one carries every annotation, so the same page holds far
more. There is no separate HTML effort knob.

An unreadable diagram at `high` is worse than a clean one at `low`. If a level does not fit
legibly, say so in the summary rather than shipping a crowded canvas.

## Outputs

| File | Written when |
|---|---|
| `docs/references.diagram.excalidraw` | always — the drawing, and the render input |
| `docs/references.diagram.png` | always |
| `docs/references.diagram.svg` | `--html` only |
| `docs/references-diagram.html` | `--html` only |

**The SVG exists only to be inlined into the page**, so a bare run writes two files and nothing else.
The page inlines the SVG rather than embedding the PNG, because a raster image softens the moment a
reader zooms and zooming is the point of the page's camera.

## Page slots

`docs/references-diagram.html` is **fully regenerated** every run, and it is **disposable output** —
nothing on it survives. There is no human fence. A note worth keeping goes in `references.md`, inside
its own `<!-- human:begin -->` fence, where the `wiki-architecture` skill protects it.

The page has exactly **two** slots. Both are replaced every run:

| Slot | Filled from | Empty when |
|---|---|---|
| `<!-- diagram:begin:svg -->` / `end` | the exported `references.diagram.svg`, inlined verbatim | never — no SVG means no page was written |
| `<!-- table:begin:boundaries -->` / `end` | the `## Boundaries` rows of `references.md` — region, members, invariant — as a real `<table>` | that section is absent |

A slot whose source is absent gets **nothing between its markers**, and the page hides the
surrounding block. Never write "N/A", never invent a row, and never delete a marker pair — the next
run finds its slot by them.

**Two slots, deliberately.** The picture answers *how does a request flow*; the boundaries table
answers *what rule holds inside each region*. Ownership, edge state and per-repo prose all live in
`references.md`, which is the document to read when you want them. Duplicating them here would give
two places to go stale.

**Boundaries stays a real `<table>`, outside the artwork.** Its cells hold identifiers, config keys
and `file:line` references, and text baked into a diagram cannot be searched, selected, copied, or
read aloud.

## Posture

- **Gate-free.** No `APPROVE`. The safety net is single-owner write confinement plus the
  `wiki-diagrammer` pre-flight guard, which refuses to overwrite a file this kit did not write.
- **No auto-commit.** Leave every write as a working-tree change.
- **Local paths only.**
- **Idempotent.** A re-run at the same effort against an unchanged `references.md` rebuilds the same
  `.excalidraw` bytes, matches, and stops without a single render pass. A re-run at a *different*
  effort is a different diagram and does redraw.

## Examples

```
/diagram:build
/diagram:build --html
/diagram:build --effort high --html
/diagram:build ../other-workspace --effort medium
```
