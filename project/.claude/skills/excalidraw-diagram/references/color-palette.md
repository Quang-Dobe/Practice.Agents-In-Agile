# Color Palette & Brand Style

**This is the single source of truth for all colors and brand-specific styles.** To customize
diagrams for your own brand, edit this file — everything else in the skill is universal.

> **This copy is dark-theme.** It is vendored into the project-tier wiki kit, where every
> reader-facing page is dark on first paint (`[R-HTML]`). The upstream copy of this skill
> ships a light palette; that is the only thing changed here. Table shapes and headings are
> unchanged so the rest of `SKILL.md` still resolves against them.

---

## Shape Colors (Semantic)

Colors encode meaning, not decoration. Each semantic purpose has a fill/stroke pair.

| Semantic Purpose | Fill | Stroke |
|------------------|------|--------|
| Primary/Neutral | `#16213a` | `#5b8def` |
| Secondary | `#14243d` | `#7aa7f5` |
| Tertiary | `#121e33` | `#9dc0fa` |
| Start/Trigger | `#2a1a05` | `#f0a500` |
| End/Success | `#0d2118` | `#22c47a` |
| Warning/Reset | `#2a1208` | `#f0803c` |
| Decision | `#241d02` | `#e0c341` |
| AI/LLM | `#1c1533` | `#9b7aff` |
| Inactive/Disabled | `#171e2b` | `#55657f` (use dashed stroke) |
| Error | `#2a0f12` | `#f05060` |

**Rule (inverted for dark):** always pair a **dark fill** with a **lighter stroke**. The
stroke carries the semantic color; the fill only lifts the shape off the ground.

---

## Text Colors (Hierarchy)

Use color on free-floating text to create visual hierarchy without containers.

| Level | Color | Use For |
|-------|-------|---------|
| Title | `#e6edf7` | Section headings, major labels |
| Subtitle | `#a9c0e8` | Subheadings, secondary labels |
| Body/Detail | `#8b9bb4` | Descriptions, annotations, metadata |
| On dark fills | `#e6edf7` | Text inside the semantic fills above |
| On accent fills | `#0e1420` | Text inside a bright accent shape |

---

## Evidence Artifact Colors

Used for code snippets, data examples, and other concrete evidence inside technical diagrams.

| Artifact | Background | Text Color |
|----------|-----------|------------|
| Code snippet | `#0b1017` | Syntax-colored (language-appropriate) |
| JSON/data example | `#0b1017` | `#22c47a` (green) |

---

## Default Stroke & Line Colors

| Element | Color |
|---------|-------|
| Arrows | Use the stroke color of the source element's semantic purpose |
| Structural lines (dividers, trees, timelines) | `#253044` (faint) or `#8b9bb4` (visible) |
| Marker dots (fill + stroke) | `#f0a500` |

---

## Background

| Property | Value |
|----------|-------|
| Canvas background | `#0e1420` |

The canvas color is used for the **PNG preview** during the render loop. When the diagram is
exported for the HTML page, the background is turned **off** (`--svg` passes
`transparent: true`), so the page ground shows through instead. Keep the two values in step:
`#0e1420` is also the page ground token in
`.claude/templates/references-diagram.html`.
