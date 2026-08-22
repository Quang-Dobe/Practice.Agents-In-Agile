---
name: wiki-diagram
description: What to draw at each effort level, and the write confinement, render loop, idempotency and page-slot rules for docs/references.diagram.excalidraw, docs/references.diagram.png and docs/references-diagram.html
version: 2
consumed_by: wiki-diagrammer agent, diagram:build command
---

## Purpose

The auditable manual for the **architecture diagram** that sits beside `docs/references.md`. It
says what to draw at each effort level, where the bytes may land, and when to skip the render.
Reloaded by the `wiki-diagrammer` agent at the start of every run, and by `/diagram:build` before its
optional HTML write.

**Drawing is its own command.** `/diagram:build` owns it — not `/wiki:*`. The wiki decides what is
true; this decides what a picture of it looks like. A redraw at a different effort costs nothing but
render passes, and re-walks no repo. `/wiki:enhance` only **recommends** the command when it
finishes.

This skill does **not** teach diagram design. That lives in
`.claude/skills/excalidraw-diagram/SKILL.md`, which the `wiki-diagrammer` also reloads.
Two skills, locked order: `wiki-diagram` first (what and where), `excalidraw-diagram`
second (how it should look).

## Scope — root node only

**One diagram per `/diagram:build` run**, at the root the command was pointed at. A branch node in a
nested tree gets its `docs/references.md` as text; point the command at it directly to draw it. This
is a cost bound: each diagram costs a headless Chromium render loop, 1 pass at `low` and up to 5 at
`high`.

No `docs/references.md` means no diagram. The command refuses rather than inventing a map, and
neither `/wiki:bootstrap` nor `/wiki:enhance` draws anything on its own.

## Output root (nested mode)

When the dispatch provides an `output_root`, every path below is read and written under
`<output_root>/docs/…` instead of the bare root `docs/…`, and the idempotency byte-compare
runs against `<output_root>/docs/…` too. Absent `output_root` → bare `docs/` of the working
directory. Set per the `wiki-orchestration` skill `## Output root (nested mode)`.

## Inputs (read-only)

| Input | Use | Absent → |
|---|---|---|
| `docs/references.md` `## Context Map` | **required.** The diagram's spine | skip the whole step, one-line advisory, never fabricate |
| `docs/references.md` `# System Overview` | the diagram title and its one-line subtitle | use the root folder name |
| `docs/references.md` `## Boundaries` | the labelled regions and the invariant printed under each | draw no regions, flat layout |
| `docs/references.md` `## Per-repo summaries` | node labels, per-node detail lines, grouping | fall back to repo folder names |
| repos' `docs/domain/` | real event and command names for the evidence artifacts | draw structure only, no evidence |
| the **effort level** from the dispatch | gates which of the above reach the canvas (`## Effort`) | treat as `low` |

Never modify an input. Never read repo source — the wiki tiers already hold every fact this
diagram needs.

## Effort

The dispatch carries an effort level: `low` (the default), `medium` or `high`. It decides **how much
of the map reaches the canvas**, and nothing else — never how carefully you draw it. A `low` diagram
is still hand-placed, still validated, still readable.

Each level is a strict superset of the one below:

| | `low` | `medium` | `high` |
|---|---|---|---|
| repo nodes, call edges (`==>`) | yes | yes | yes |
| ingress node **and its edges** | yes | yes | yes |
| regions, the invariant under each, **and the Members cell** | yes | yes | yes |
| **`[fallback: …]` / `[refuses: …]` / `[fail-fast: …]` on the seams that have one** | yes | yes | yes |
| other out-of-system edges (`~~>`) and their store / external nodes | **no** | yes | yes |
| per-node detail lines | no | yes, max 3 | yes, max 3 |
| `[config-pinned: …]` / `[config-selected: …]` / `[unscanned: …]` keys in labels | no | yes | yes |
| the notation key for those failure states — two lines | yes | yes | yes |
| annotation blocks — the map's own arguments and gaps | no | no | yes |
| legend block | no | no | yes |
| render passes | 1, plus a correction pass if the render comes back broken | 2–3 | 3–5 |

**Three things sit at `low` that look like they belong higher. Each is there because leaving it out
makes the diagram *wrong*, not merely simpler.**

1. **The failure state of a seam.** A `low` diagram without it draws confident arrows for seams that,
   with one config key unset, do not exist at runtime — an in-process stand-in answers instead. A
   reader then believes A calls B when A may be talking to a scripted double. This is the cheapest
   high-value mark on the canvas: one short parenthetical on a label you are already drawing. The
   *key* can wait for `medium`; **what happens when it is missing cannot.**
2. **The ingress node's edges.** Drawing the ingress and then suppressing its edges leaves a floating
   box, contradicts the design skill's *Connections Required*, and — worse — makes the first two repo
   nodes read as directly connected when every request actually enters through the ingress. So
   ingress edges are the documented **exception** to "no out-of-system edges at `low`". Draw them;
   draw nothing else out-of-system.
3. **The region's Members cell.** Most invariants refer to members `low` does not draw — "the only
   repo that connects to that store", with no store on the canvas. Print the `## Boundaries` Members
   cell as a dim line under the region name so the invariant has something to point at. It comes from
   the same Boundaries row, so this stays inside `low` and is not a back door to store nodes.

- **`low`** answers *how does a request flow, and where are the boundaries*. One pass, no loop. It is
  the default because that is the question asked most, and because a diagram nobody waits for is a
  diagram people actually use.
- **`medium`** adds the evidence: what each repo owns, which key points where, what happens when a key
  is missing.
- **`high`** adds the map's own reasoning — the gaps, the rejected groupings, the fail-fast contrast.

**Regions are in every level, including `low`.** They are the cheapest high-value thing on the canvas:
one rectangle and two lines of text turn a topology into an argument. Dropping them to save a pass
would gut the diagram at exactly the level most people see.

**Never draw above the requested level.** If `high` would be crowded, say so in the report rather than
quietly drawing `medium` — and never quietly draw `high` detail on a `low` run because the map looked
thin. The caller chose.

## What to draw

**The bar.** This diagram has to be worth opening instead of reading `references.md`. A row of
boxes joined by arrows is not — a reader learns nothing from it that the file's own bullet list
does not already say. What earns the pixels is the four things prose is bad at: **where the
boundaries are**, **which edges are real today**, **what crosses each edge**, and **who owns
what**. Draw all four or the page is decoration.

### Edges — style is the legend

Three edge kinds (the `wiki-architecture` skill `## Output shape` item 2) and a state marker:

| Context Map line | Means | Draw it as |
|---|---|---|
| `Publisher --EventName--> Consumer` | asynchronous, fire and forget | **solid** arrow |
| `Caller ==InterfaceOrRoute==> Callee` | a blocking call, the caller waits | **dashed** arrow (`strokeStyle: "dashed"`) |
| `Repo ~~WhatItIs~~> Resource` | leaves the system | **dotted** arrow (`strokeStyle: "dotted"`), thinner |
| any line marked `[planned]` | registered but nothing calls it | its own style at **`opacity: 40`** |
| any line marked `[fallback: Name]` | absent config keeps the call in-process — a stand-in **answers** | same style, and `(fallback: Name)` in the label |
| any line marked `[refuses: Name]` | a stand-in is registered and **denies** every call | same style, and `(refuses: Name)` in the label |
| a seam the map reports as failing fast | absent config registers nothing; the host does not start | same style, and `(fail-fast: process does not start)` in the label |

**Give the three failure states three different label colours** — they are the reason a reader
trusts or distrusts an arrow, and reading them off the text is faster than reading the words. A
stand-in that answers is the dangerous one, so make it the loudest.

**A failure state may not be spelled as a marker in the input.** `references.md` carries
`[fallback: …]` and `[refuses: …]` inline, but a map may report fail-fast only in prose — its
`### Fail fast or degrade quietly` table, or a sentence under a seam. Derive it from there and label
the seam anyway. Waiting for a marker the author did not use loses the fact.

**A `[fallback: …]` row is not its own edge.** The input often writes the stand-in as a separate row
pointing at something like `(nothing leaves the process)`. That is not a node and not a second seam:
it is the other half of the row above it. Merge it onto the real arrow's label. Drawing it as its own
arrow to its own box invents both.
| any line marked `[config-pinned: KEY]` or `[config-selected: KEY]` | config decides the target, or which target | same style, and the key in the label |
| any line marked `[unscanned: Library]` | the call is real, its code was outside every scan scope | same style at **`opacity: 65`**, and `via <Library>` in the label |

**Never draw an `[unscanned: …]` library as a node.** It is the reason the edge exists, not a
participant. Several repos reaching one collector through one shared library is several edges into
**one** resource box. Give the resource its own node and let each edge carry the `via` label — a
library box would invent a hop that does not exist, and merging the edges would hide how many repos
depend on it.

Stroke style is the legend, so no key box is needed for the three kinds. **`[planned]` does need
one** — a faded arrow is not self-explanatory — so print one line of legend text for it, and only
for it, and only when a `[planned]` edge exists.

**`opacity: 40` on a `[planned]` edge overrides the design skill.** `excalidraw-diagram` says to
always use `opacity: 100`, in its aesthetics section and again in its quality checklist. This skill
wins on that one point, for `[planned]` elements only, because fading is the only way to say
"registered but nobody calls it" without a second arrow style. Every other element stays at 100.

**Label placement for a store or external edge.** A store hangs off its owner on a short stub with no
room for text beside it, so its `[config-pinned: KEY]` or `[config-selected: KEY]` key goes **inside
the store node**, under its name, at a smaller size. Same for a `[fallback: Name]` on such an edge.
The `### Per-node detail` cap of three lines is about repo nodes; a store node carries its driver and
its key and that is not a detail stack.

**A config-selected set of alternatives is one seam, not N edges.** One arrow from the owner to a
junction dot, then a short bus with a tick into each named alternative. Label the seam with the
selecting key and the `[fallback: …]`. Drawing N arrows fanning out would contradict the very
invariant such a region usually carries — that there is only one path to that kind of resource. The
alternatives earn a tick, not an arrow, so they are not caught by "a node that earns no arrow does not
belong".

**Label what crosses, not just the interface.** `IAuthzClient / POST auth-context/resolve-identity`
names the pipe. `X-Auth-UserId — an identifier, never a credential` says what goes through it, which
is the thing a reader cannot get from the route. When the Context Map or a per-repo summary gives
you both, put the interface on the first line and what crosses on the second. Never invent the
second line.

### Nodes — class decides shape

Give every node a class, and let the shape carry it, so a reader sees the kind before reading a
word:

| Class | What it is | Shape |
|---|---|---|
| **repo** | one of the repos in `repos[]` | rounded rectangle |
| **ingress** | a gateway, OIDC proxy, or load balancer in front of the system | rectangle, square corners |
| **store** | database, cache, relationship store, warehouse | ellipse |
| **external** | model host, telemetry collector, identity provider, browser, upstream pipeline | ellipse, dimmer stroke |

Only the **repo** class comes from `repos[]`. The other three come from the `### Out of the system`
dependency edges. A resource that two or more repos reach is drawn **once**, with an arrow from
each — duplicating it hides the fact that it is shared, which is usually the interesting part.

### Regions — the invariant is the point

Draw one enclosing rectangle per `## Boundaries` row: `backgroundColor: "transparent"`,
`strokeStyle: "dashed"`, a dim stroke, behind its members. Label it with three things, in this order:
the region **name**, its **Members** cell in smaller dim text, then the **invariant** in smaller dim
text. The invariant is why the box exists — a region labelled only `Authorization` is a box, while
one labelled *"the only holder of OpenFGA credentials"* is an argument. The Members line is what the
invariant points **at**: most invariants name a store or an external that `low` does not draw, and
without the members line they refer to nothing on the canvas.

**Put that text block beside its node, not under it.** Under is the obvious placement and it is a
trap: any arrow leaving a node's bottom face then crosses several lines of region prose, which costs
a whole render pass to discover. Beside the node, inside the box, the hazard does not exist.

**Overlapping regions nest.** When two `## Boundaries` rows share a member, draw the wider one as the
outer box and the narrower one inside it rather than letting two borders cross. Crossing borders read
as a third region that no row supports.

No `## Boundaries` section, or a region with no invariant → **draw no box**. An unexplained
grouping reads as a claim the diagram cannot support.

### Layout — the canvas draws topology, the page carries the boundaries

**On the canvas:**

1. **The request path.** Follow the call edges from the entry point. Regions drawn around their
   members. Stores and externals hang **off** their owner, not in the main chain, so the request path
   stays one readable line.

   **Pick the direction from the content, and prefer top-down once regions carry text.** A
   left-to-right row of seven nodes, each with a region name, members line and invariant beside it,
   needs roughly 3900 canvas units and then needs the crop workflow from `## Render loop` to judge at
   all. The same content top-down fits in about 1100 units wide, is readable in one full-frame render,
   and gives every arrow a clear vertical channel. Left-to-right is right for a short chain with thin
   labels; it stops being right at about four nodes with region text.
2. **A short state note**, at **every** effort level, whenever any edge carries a failure state or a
   `[planned]` marker: one or two free lines saying what `(fallback: X)`, `(refuses: X)`,
   `(fail-fast: …)` or a faded arrow mean. Two lines, not a block.

   This is **not** one of the annotation blocks that `## Effort` gates to `high`. Those blocks carry
   the map's *arguments* — the gaps it found, what it rejected. This note is a **key to notation
   already on the canvas**, and notation nobody can read is worse than notation left off. A reader
   who has looked at the picture and moved on will never find the explanation anywhere else.

**Not on the canvas** — `## Boundaries` as a table. The regions are drawn, but their invariants are
also rendered as a real HTML `<table>` on the page (`## Page slots`), because those cells hold
identifiers, config keys and `file:line` references that a reader needs to search, select and copy.

**Also not on the canvas** — `## Ownership`, the per-repo prose, and the full state list. Those stay
in `references.md`. The page deliberately carries only the picture and the boundaries; anything else
would be a second copy with its own way of going stale.

Keeping the argument on the canvas rather than in the page also means a reader who shares only the
PNG shares a complete picture, not a cropped one.

### Per-node detail — the third zoom

Under each repo node, up to **three** dim lines from its `## Per-repo summaries` paragraph: its
inbound entry points, the stores it owns, its config keys. This is the design skill's *evidence
artifact* rule — real route strings and real key names, never a description of them. Three lines is
the cap; a node needing more is a sign the summary is doing the diagram's job.

Shape maps straight onto the pattern library:

| Context Map shape | Pattern from `excalidraw-diagram` |
|---|---|
| one upstream, many downstream | **fan-out** |
| many upstream, one downstream | **convergence** |
| a chain A to B to C | **assembly line** |
| an edge that returns to its origin | **cycle** |
| repos with no edge between them | **gap / break** — separate them visually |

Rules that bind here, on top of the design skill:

- **Derived, never invented.** Every node is a repo, a bounded context, or a resource named in
  `references.md`. Every arrow is a line in the `## Context Map`. Every region is a
  `## Boundaries` row. An arrow, box or label with no line behind it is a bug, however good it looks.
- **One arrow per pair, not per row.** A `## Context Map` that gives four rows for one caller-callee
  pair is four routes over **one** seam, so draw one arrow and stack every route literal as label
  lines. Four near-identical parallel arrows in one gap is unreadable and claims four seams that do
  not exist. The rule forbids inventing arrows; merging rows that share a pair invents nothing, and
  losing a route literal is the only thing that would.
- **Real names.** The arrow label is the event name or the interface / route exactly as the
  Context Map writes it — `OrderPaid`, `IAgentClient`, `GET /v1/scope` — never `Event 1` or
  `calls`. This is the design skill's *Education test* applied to this diagram.
- **Direction is the caller's, not the data's.** A call edge points from caller to callee
  even when the payload comes back the other way. Flipping it to follow the response makes
  the diagram lie about who depends on whom.
- **Empty Context Map is a valid outcome.** If `references.md` found no edge of either
  kind, draw the repos as an unconnected side-by-side row and say so in the diagram subtitle.
  Do not invent an arrow to make the picture look finished. But an empty map on a system that
  obviously has traffic is a bug in `references.md`, not a drawing to ship — say that in
  the returned report.
- **Three zoom levels** per the design skill — with one carve-out. On a map of **8 nodes or fewer**
  the separate summary flow strip is **optional and usually wrong**: the whole picture already *is*
  the flow, so a strip above it can only restate the same edges, and it has no Context Map line of
  its own to derive from. Restating them in new words breaks **Derived, never invented**. Below that
  size, treat the node graph itself as the summary and the edge labels plus any notes as the detail.
- **Node-interior evidence text is exempt from the design skill's under-30% container ratio.** Not
  argued from arrow binding — stated. This skill *requires* up to three detail lines inside each repo
  node, and a store or external node needs its driver and config key inside it too, so a full map
  routinely puts well over half its text elements inside a shape. That is the design working, not a
  violation. The ratio binds **annotations** — notes, legends, callouts, the state note — which stay
  free-floating.

## Output shape

Up to four files, all under `<output_root>/docs/`. **Three belong to the `wiki-diagrammer` agent; the
fourth does not.**

| File | Written by | Written when | Role |
|---|---|---|---|
| `references.diagram.excalidraw` | `wiki-diagrammer` | always | the drawing, and the render input |
| `references.diagram.png` | `wiki-diagrammer` | always | the diagram. What the loop reads, and what a human shares |
| `references.diagram.svg` | `wiki-diagrammer` | **`--html` only** — never on a bare run | the markup the page inlines |
| `references-diagram.html` | the **command layer**, per `[R-HTML-AGENT]` | `--html` only | the reader-facing page |

**The SVG exists only to be inlined.** Without `--html` there is no page, so there is nothing to
inline into and the SVG is not written. A bare run leaves exactly two files.

**The page inlines the SVG, never the PNG.** A raster image softens the moment a reader zooms, and
zooming is the whole point of the page's camera. Vector markup stays sharp at any scale and carries
its fonts as base64 inside its own `<defs>`, so the page is still self-contained. The PNG is for
sharing and for the render loop's own eyes.

The agent's writable set is the **first three**. It has no `Agent` tool, so it cannot perform the
delegated HTML write at all (`## HTML write is delegated`). Everything this skill says about the
`.html` is addressed to the command layer, not to the agent.

The `.excalidraw` must satisfy `render_excalidraw.py`'s own validator: `type` is
`"excalidraw"`, and `elements` is a non-empty array.

**The `.excalidraw` is kit-owned, not co-owned.** Open it at excalidraw.com to read it, or to fork
it. Do not hand-edit it in place expecting the edit to last: `## Idempotency` rebuilds it from the
Context Map, so the next run whose map differs overwrites it. To keep hand work, save the fork under
a different name — the kit only ever writes the four names above. The co-owned surface is the page's
`<!-- human:begin -->` fence, which **is** preserved byte-for-byte.

## Render loop

```
# every pass while looping — cheap and readable
uv run python render_excalidraw.py <abs>/docs/references.diagram.excalidraw --scale 1 --width 5000
# --html only, once, after the PNG is accepted
uv run python render_excalidraw.py <abs>/docs/references.diagram.excalidraw --svg
```

The script writes **next to its input**, so both commands land in `<output_root>/docs/` on their own;
no `-o` is needed.

`--scale 1 --width 5000` is the loop form, and also the form that produces the final PNG. The default
viewport cap is `--width 1920`, which squeezes a wide canvas before you ever see it, and the default
`--scale 2` then makes a multi-megabyte image that gets downscaled again to be looked at. Raising the
width and dropping the scale gives a true 1:1 frame in a smaller file.

The `--svg` pass runs **last and only under `--html`**, after the PNG is accepted. Skip it on a bare
run: nothing would read the output.

**Pass the diagram path as an absolute path.** The `cd` is required — `uv` resolves the project from
the working directory — but it also means any relative argument is now relative to `references/`, not
to the output root. With an `output_root` set, the relative form is four levels up
(`../../../../docs/…`), which is easy to get wrong and fails silently as a missing-file error. Use an
absolute path and the `cd` stops mattering.

Both renders write **next to the input**, so the output lands in `<output_root>/docs/` on its own; no
`-o` flag is needed.

First run only, once per machine:

```
cd .claude/skills/excalidraw-diagram/references
uv sync
uv run playwright install chromium
```

**Pass `--scale 1` while looping.** The default is `2`, which on a wide canvas produces an image of
several thousand pixels a side and multiple megabytes — slower to write, and no easier to judge, since
it gets downscaled to be looked at anyway. Scale up only for a final PNG somebody will zoom into.

**On a canvas wider than roughly 2500 units, a full-frame render is too small to judge.** Overlaps and
text collisions disappear at that reduction. Render x-window crops of the region under review into a
scratchpad file and read those instead — the whole-canvas image is for balance and dead space, the
crops are for collisions.

The PNG pass is what the loop looks at: render, `Read` the PNG, fix the JSON, render again.
Follow the design skill's `## Render & Validate` checks. Typically 2–4 passes. The `--svg`
pass runs **last**, once the PNG is accepted, because its output is what the page inlines.

`--svg` passes `transparent: true`, so the SVG carries no background rect and the page's own
dark ground shows through. Keep the `.excalidraw` canvas color in step with the page ground
token so the PNG preview and the page agree.

**Renderer unavailable** (`uv` missing, Chromium not installed, `esm.sh` unreachable) → write
the `.excalidraw` anyway, skip the SVG and PNG, skip the HTML write, emit one line naming the
missing piece, and do not block the rest of the run. The `.excalidraw` alone is still useful:
a human can open it.

## Idempotency

The byte-compare is a **gate at the entry to the run**, not a check before each individual write.
It has to be: the render loop takes 2 to 4 passes, so the accepted `.excalidraw` is never the first
candidate, and a literal compare-before-every-write would block passes 2 and 3.

1. **Entry gate.** Build the first candidate `.excalidraw` from the Context Map, before rendering
   anything. If its bytes equal the file on disk, the map has not moved: **write nothing, render
   nothing, tell the command layer to skip the HTML, stop.** Print one line saying the diagram is
   unchanged. A clean re-enhance must cost zero Chromium passes.

   **This only works if the candidate is byte-reproducible**, which means `seed` and `versionNonce`
   must be **deterministic** — derived from the section namespace and the element's position in it,
   never random. A diagrammer that seeds randomly produces different bytes from the same Context Map,
   fails the gate every run, and pays the full render loop to arrive back where it started. Fixed
   seeds are what make this section true rather than aspirational.
2. **Past the gate.** Write the `.excalidraw` and run the loop freely — each pass rewrites the
   `.excalidraw` and the `.png` on purpose. Write the `.svg` last, from the accepted candidate.
3. **The HTML** is the command layer's call, and it rewrites only when the inlined SVG bytes changed
   or when the harvested fence moved.

This mirrors the `wiki-architect` posture: a run that changes nothing writes nothing.

## Page slots

**This section addresses the command layer, not the `wiki-diagrammer` agent.** The agent cannot write
the `.html` (`## HTML write is delegated`); the command layer reloads this skill before its own HTML
write.

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

## Pre-flight — never overwrite a file this kit did not write

Same rule as the `wiki-architecture` skill
`## Pre-flight — never overwrite a file this kit did not write`, applied to the four files in
`## Output shape`. Each is fully regenerated, so each needs a provenance marker before it may be
overwritten:

| File | Marker |
|---|---|
| `references.diagram.excalidraw` | `"customData": { "generated_by": "wiki-diagrammer" }` on **every** element the kit writes |
| `references-diagram.html` | `<!-- generated_by: wiki-diagram -->` as the first line |
| `references.diagram.png` / `.svg` | none needed — both are render output of the `.excalidraw`, rewritten whenever it changes. The `.svg` is only written under `--html` |

A target that exists **without** its marker means a human put it there. Refuse that one file,
write nothing to it, emit one line naming it, and carry on with the rest:

```
Refusing to overwrite <path> — no wiki-diagram provenance marker, so this kit did not write it.
```

The name collision is unlikely, not impossible. Losing someone's diagram to a name clash is worse
than a skipped write.

**Never use the JSON root's `source` key for this.** `source` is Excalidraw's own origin field and
the upstream `excalidraw-diagram` skill `## JSON Structure` mandates `"source": "https://excalidraw.com"`
there. Two skills claiming one key is the smaller half of the problem: `source` is also **rewritten
by Excalidraw itself** the moment anyone opens the file at excalidraw.com and saves. A marker stored
there would be silently replaced by the URL, and the next run would then refuse the kit's own file as
human-authored. Element-level `customData` is the documented host-data extension point and survives
that round trip.

Read the marker as: **some** element carries it → the kit wrote this file. **No** element carries it
→ a human did, refuse.

## Write confinement

The **only** writable paths are the four files listed in `## Output shape`, under
`<output_root>/docs/` — and the `wiki-diagrammer` agent may write only the first three. Before any
write, confirm the target resolves to one of those. On a run without `--html`, the writable set
narrows again: the `.excalidraw` and the `.png`, nothing else.

Never write:

- `docs/references.md` — owned solely by the `wiki-architect` agent / `wiki-architecture`
  skill. This skill is read-only on it.
- `docs/memory/` — root or per-repo. Owned by the `wiki-memory` write path.
- any repo's `docs/narrative/` or `docs/domain/`.
- `repo-layout.md` — owned by the `/wiki:bootstrap` + `/wiki:enhance` manifest writer.
- repo source, or anything under `.claude/`.

There is no fallback that writes outside the four paths.

## Gate + commit posture

Ungated — no `APPROVE`, matching every other write in this tier. The safety net is
single-owner confinement + the byte-compare + fence preservation. Never `git add` or
`git commit`; leave the files as working-tree changes.

## HTML write is delegated

Per `[R-HTML-AGENT]`, the `.html` write goes to a subagent with `model: "sonnet"`. It cannot happen
inside `wiki-diagrammer`: that agent is itself a subagent and has no `Agent` tool, and this harness
does not nest subagents. So the HTML write sits at the **command layer**, in `/diagram:build` step 5,
after `wiki-diagrammer` returns — and only when `--html` was passed.

The spawn prompt must carry, because the subagent sees none of the session:

| Must pass | Why |
|---|---|
| the `[R-HTML]` dark-default + theme-aware contract | else the page ships light |
| `[R-WORDS]`, `[R-VISUAL]`, `[R-SCOPE]` | the page is an artifact; these bind it |
| the exact output path and the template path | else it writes the wrong file |
| the SVG path, and that its markup is inlined verbatim | it cannot read the render output for you, and it must not strip the base64 fonts in the SVG's own `<defs>` |
| the `## Boundaries` rows | else it has to parse `references.md` to find them |
| `{{SYSTEM_NAME}}` and `{{GENERATED_AT}}` values | it cannot derive them |

Nothing about a human fence, because the page has none.

## Well-formedness

Well-formed for write iff the frontmatter parses as YAML with `name: wiki-diagram` +
`version` + `consumed_by`, **and** the body contains `## Output shape`, `## Idempotency`,
`## Page slots`, and `## Write confinement`. If malformed, the `wiki-diagrammer`
agent stops **before any write** and reports it.
