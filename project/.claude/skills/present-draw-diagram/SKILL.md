---
name: present-draw-diagram
description: Create visually distinctive SVG diagrams with animated flow particles and a dark-mode design system. Invoked by present-overview-plan and present-plan to render a feature's scoped diagrams into its present HTML file. Use for workflow diagrams — flow graphs, LangGraph/XState/Redux state machines, architecture diagrams (services + data flows), process flows with decisions, and ER/schema diagrams. DO NOT use for sequence diagrams (participant swimlanes with time flowing downward) — those should use Mermaid instead.
---

# present-draw-diagram

Produce a self-contained SVG diagram: SVG on the left, companion explanation panel on the right, optional full-width table below. Dark ground, accent colors that carry semantic meaning, animated `<animateMotion>` particles on the critical path.

## Step 1 — Pin the subject

Before touching code, state aloud:
- **What** is being diagrammed (one sentence)
- **Type**: flow graph / architecture / sequence / process / ER
- **Layout**: top-down / left-right / hub-and-spoke / grid
- **Single job**: what does the viewer understand in 10 seconds?

If the input is ambiguous, ask one question. If it's clear from context, proceed.

## Step 2 — Commit the design token system

Reason through the palette once, write it down, then transcribe it into CSS — never reinterpret mid-code. This is the same discipline as the `artifact-design` skill.

### Palette (4–6 named hexes)

```
ground:   #XXXXXX   dark slate, HSL lightness < 20
surface:  #XXXXXX   node backgrounds
text:     #XXXXXX   primary labels
muted:    #XXXXXX   sub-labels, edge labels, footnotes
accent:   #XXXXXX   primary/critical path (amber #f0a500 is the default)
accent-2: #XXXXXX   secondary semantic color (teal, red, purple, green…)
```

Accent colors should carry meaning — not just look nice. Examples that work:
- amber = primary flow / decision spine
- teal = classifier / router / selector
- red/danger = error, refusal, failure path
- purple/plaid = data, storage, external systems
- green = success, connected, healthy

### Typography — system fonts only (CSP blocks external CDN)

```css
--mono: ui-monospace, 'Cascadia Code', 'Fira Code', monospace;  /* node labels, data, edge labels */
--sans: system-ui, -apple-system, BlinkMacSystemFont, sans-serif; /* body copy, sub-labels */
```

### ASCII wireframe

Sketch node positions and layout BEFORE coding. Finalize approximate (x, y) coordinates here — this prevents endless coordinate-tweaking once you're in the SVG.

```
Example:
  [START] (260, 40)
      ↓
  [classify] (260, 140)   ──first turn──→  [generate_title] (420, 220)
      ↓
  [respond] (260, 320)
   /        \
[refuse]   [specialist ×8] (420, 460)
```

## Step 3 — Build the SVG

### Page structure

```html
<header>                     <!-- eyebrow + headline + subtitle -->
<div class="scroll-wrap">    <!-- overflow-x: auto — wide diagrams must scroll, not overflow body -->
  <div class="layout">       <!-- CSS grid: graph-col | detail-col -->
    <div class="graph-col">
      <svg viewBox="0 0 W H" ...>...</svg>
    </div>
    <div class="detail-col"> <!-- steps, callouts, legends -->
    </div>
  </div>
</div>
<section class="tbl-section">  <!-- optional full-width table -->
```

### SVG layer order — non-negotiable

Render in exactly this order so node backgrounds cover path endpoints:

1. `<defs>` — markers, filters
2. Edge `<path>` elements
3. Animated particle `<circle>` elements
4. Node `<rect>` / `<circle>` / `<polygon>` elements
5. Node `<text>` elements

### Arrowhead marker — define once, reuse everywhere

```svg
<defs>
  <marker id="arr" viewBox="0 0 10 10" refX="9" refY="5"
          markerWidth="5" markerHeight="5" orient="auto-start-reverse">
    <path d="M0,0 L10,5 L0,10 z" fill="#2e3d55"/>
  </marker>
</defs>
```

`orient="auto-start-reverse"` rotates the arrowhead to match any path direction automatically — you never have to calculate angles.

### Edge paths — the CSS class rule

**All stroke colors go in CSS classes. Never set `stroke` as a bare SVG attribute on elements where CSS also applies stroke — the CSS class wins and the attribute is silently ignored.**

```css
/* Base — shared by all edges */
.edge { fill: none; stroke-width: 1.5; marker-end: url(#arr); }

/* Semantic variants — add one of these alongside .edge */
.e-primary { stroke: rgba(240,165,0,.35); }           /* amber: main flow */
.e-teal    { stroke: rgba(45,212,191,.3); stroke-dasharray: 5 3; }  /* optional/parallel */
.e-gray    { stroke: rgba(255,255,255,.07); stroke-dasharray: 4 3; } /* secondary */
.e-danger  { stroke: rgba(240,80,96,.2); }             /* error/refusal */
.e-data    { stroke: rgba(155,122,255,.3); }           /* storage/external */
```

Apply: `<path class="edge e-primary" d="..."/>`

To override stroke in an SVG attribute (e.g. for a one-off line), use `style="stroke:..."` — inline styles beat CSS classes.

### Bezier curves

Use `C x1 y1, x2 y2, x y` for branches. Pull the first control point in the departure direction, pull the second toward the destination:

```svg
<!-- node at (260,348) branching right to (400,396) -->
<path d="M 348 348 C 430 348 400 390 400 396" class="edge e-data"/>
<!--        start     ctrl-1    ctrl-2  end -->
<!--  ctrl-1 pulled right (same y), ctrl-2 pulled toward landing -->
```

### Animated particles — the aesthetic anchor

At least one particle traveling the critical path. More on secondary paths with different colors + staggered timing:

```svg
<!-- glow filter for primary particles -->
<filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
  <feGaussianBlur stdDeviation="2.5" result="b"/>
  <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
</filter>

<!-- particle travels the same path as its edge -->
<circle r="3.5" fill="#f0a500" filter="url(#glow)">
  <animateMotion path="M 260 60 L 260 114" dur="0.5s"
    begin="0s" repeatCount="indefinite" calcMode="linear"/>
</circle>
<circle r="3.5" fill="#f0a500" filter="url(#glow)">
  <animateMotion path="M 260 168 L 260 322" dur="1s"
    begin="0.5s" repeatCount="indefinite" calcMode="linear"/>
</circle>
```

The `begin` offset makes them look like a stream of packets, not a synchronized pulse. Stagger roughly by each edge's `dur` so a particle enters the next edge when the previous one completes.

Add a second wave with `begin="4s"` (or whatever the total cycle is) and `opacity="0.7"` to reinforce the stream effect without doubling the visual noise.

```css
@media (prefers-reduced-motion: reduce) {
  circle { animation: none; }
}
```

### Node shapes

```svg
<!-- Rectangular node -->
<rect x="170" y="114" width="180" height="54" rx="7" class="n-primary"/>
<text x="260" y="139" text-anchor="middle" class="lbl">node name</text>
<text x="260" y="155" text-anchor="middle" class="sub">sub-label</text>

<!-- Terminal node (circle) -->
<circle cx="260" cy="40" r="22" class="n-terminal"/>
<text x="260" y="44" text-anchor="middle" class="tlbl">START</text>

<!-- Decision diamond (process diagrams) -->
<polygon points="260,80 310,120 260,160 210,120" class="n-decision"/>
```

Node CSS — fill from CSS class, same reason as edges:
```css
.n-primary  { fill: #191500; stroke: var(--accent); stroke-width: 1.5; }
.n-teal     { fill: #0f1f12; stroke: var(--teal);   stroke-width: 1.5; }
.n-danger   { fill: #200e0e; stroke: rgba(240,80,96,.3); stroke-width: 1; }
.n-data     { fill: #12172a; stroke: rgba(155,122,255,.35); stroke-width: 1; }
.n-terminal { fill: #141c28; stroke: #2e3d55; stroke-width: 1.5; }
.n-decision { fill: #1a1400; stroke: rgba(240,165,0,.4); stroke-width: 1.5; }
```

### Grouped panel nodes

For sub-agents, tool lists, or table columns — draw a containing `<rect>`, a separator `<line>`, then list items:

```svg
<rect x="334" y="396" width="180" height="190" rx="7" class="n-data"/>
<text x="424" y="416" text-anchor="middle" class="lbl" ...>group title ×N</text>
<line x1="342" y1="422" x2="506" y2="422" stroke="rgba(155,122,255,.12)" stroke-width="1"/>
<!-- items at y=434, 453, 472 … (19px spacing works well) -->
<circle cx="347" cy="434" r="3" fill="#22c47a"/>
<text x="356" y="438" class="sp-item">item_name</text>
```

## Step 4 — Layout recipes

### Scope — what this skill covers

Use this skill for **workflow diagrams**: structures where nodes represent states, services, or entities and edges represent transitions, calls, or relationships.

**Use Mermaid instead** for sequence diagrams (participant swimlanes, time flowing downward, request/response chains). Mermaid's `sequenceDiagram` syntax handles those cleanly without SVG coordinate math.

### Flow graph / state machine
- Vertical spine for the happy path
- Errors/refusals branch left, parallel/optional branch right
- 9px muted edge labels on each branch
- Group sub-nodes inside a panel rect with a header + separator + list

### Architecture diagram
- Left-to-right reading direction
- Group by tier using faint horizontal bands (`<rect fill="rgba(255,255,255,.015)">`)
- Solid edges = sync calls; dashed = async/events
- Label edges with protocol (POST, SSE, AMQP…)

### ER diagram
- Grid layout; one rect per table
- Column list inside each rect (PK row in accent color)
- Edge lines connect FK to PK; label with cardinality (1, N, 0..1)

### Process flow
- Top-down spine with diamond decisions
- Color-code outcomes: green = success path, red = failure, amber = conditional
- Annotate decision diamonds with the condition text

## Step 5 — Detail panel

The right column explains the diagram. Keep it secondary — the SVG does the work. Use these building blocks:

**Numbered steps** (for processes):
```html
<div class="step"><span class="step-n">1</span>
  <div><h3>Step title</h3><p>One or two sentences.</p></div>
</div>
```

**Key insight callout** (for "the graph decides, not the model" type facts):
```html
<div class="insight">
  <strong>The key fact.</strong> Supporting detail.
</div>
```
Style: `border-left: 3px solid var(--accent); background: var(--surface); padding: 14px 16px;`

**Limits / capacity table** (for recursion limits, timeouts, counts):
```html
<div class="limits">
  <div class="lim-hdr">SECTION TITLE</div>
  <div class="lim-row">
    <span class="lim-name">thing_name</span>
    <div class="lim-track"><div class="lim-fill" style="width:83%"></div></div>
    <span class="lim-val">10</span>
    <span class="lim-note">explanation</span>
  </div>
</div>
```

**Legend pills**:
```html
<div class="pills">
  <span class="pill p-green">● Clover (POS)</span>
  <span class="pill p-blue">● QuickBooks</span>
</div>
```

## Step 6 — Design checklist

Before publishing, verify:
- [ ] Ground color HSL lightness < 20 (actually dark)
- [ ] System fonts only — no `@import` or CDN URLs
- [ ] `overflow-x: auto` on `.scroll-wrap`
- [ ] `prefers-reduced-motion` CSS block present
- [ ] All edge strokes via CSS classes, not bare SVG attributes
- [ ] Edges drawn before nodes in SVG source
- [ ] `marker-end: url(#arr)` in `.edge` CSS class
- [ ] At least one `<animateMotion>` particle on the critical path
- [ ] `<title>` tag set to a stable, descriptive name
- [ ] One visual element that could not be mistaken for a generic template

## Step 7 — Hand back to the calling unit

Do NOT call the `Artifact` tool. Return the finished `<svg>...</svg>` (plus any companion detail-panel markup) as a self-contained fragment. The calling present-* unit skill embeds it into its `present-<unit>.html` between the `<!-- present:begin:diagram -->` / `<!-- present:end:diagram -->` markers. System fonts only; no CDN.
