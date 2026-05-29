---
name: wiki-router
description: Classification + fixed retrieval-order operating manual for the wiki-router runtime agent
version: 1
consumed_by: wiki-router agent
---

## Purpose

This skill is the operating manual the `wiki-router` runtime agent reloads at the
start of **every** run. It is the auditable source for two things and only two
things: (a) how the router decides a question is **in-domain** vs **out-of-domain**,
and (b) the **fixed, deterministic retrieval order** the router walks for an
in-domain question, with the stop-once-sufficient rule and the one-line TRACE it
emits.

This skill performs **no writes** itself. It is read + classify + retrieve + answer +
name-the-hand-off only. The write RULES (create-or-append, dedup, `source-ref:`
provenance, `<!-- human:begin/end -->` fence protection) live in a **separate** skill,
`.claude/skills/wiki-memory/SKILL.md`. When source is read at
T5 the router hands off to that skill **by path** — it never inlines write rules here.

## Classification

Classification runs **before any tier retrieval**. The router decides
in-domain vs out-of-domain from a **cheap scope manifest** built from
**titles and headings only** — never from full file bodies:

- **`docs/memory/` topic TITLES** — the `# <Topic title>` heading (one per topic file)
  of every `docs/memory/*.md`. Read the title line only; do not read the topic body.
- **`docs/architecture.md` HEADINGS** — the `#`/`##`/`###` heading lines of the root
  `docs/architecture.md`. Read the heading lines only; do not read the section bodies.

The manifest is the set of these titles + headings (e.g. `Billing`, `Catalog`,
`Service relationships`). Building it must **not** open the body of `billing.md`,
the body of `architecture.md`, or any narrative/domain/source file. Body reads happen
**only after** an in-domain decision, during tier retrieval — never as part of the
classify step.

- **In-domain** = the question has a corpus anchor in the manifest: a memory topic
  title or an architecture heading the question is clearly about (e.g. a "Billing"
  question when a `Billing` topic title and/or a `## Billing` heading exist).
- **Out-of-domain** = general-knowledge / unrelated-tech with **no** manifest anchor
  (e.g. "How do I center a div in CSS?", "What is the boiling point of water?").
  The absence of a manifest match IS the out-of-domain condition.

**Error weighting.** v1 weights false-positives and false-negatives
**equally** — no asymmetric tuning. There is no bias toward "search anyway when unsure"
nor toward "decline when unsure". v1 uses the manifest-anchor test as the deterministic call.

## Fixed retrieval order

For an **in-domain** question only, walk these five tiers in this **exact** order.
A **stop-check** sits between every tier. A tier is **sufficient** when it yields a
**concrete citable artifact** (a matching memory topic/entry, an architecture section,
a narrative file, a domain file, or — at T5 — the source file) that **answers the
question**. The rule is: **found a citable answer? yes → cite it + stop; no → descend
exactly one tier.** Never skip a tier; never read a lower tier once a higher tier was
sufficient (no over-descent).

1. **T1 — `docs/memory/*`** (the curated wiki). Look for a memory topic/entry that
   answers the question. *Found a citable answer? yes → answer citing the
   `docs/memory/<topic>.md` artifact + STOP@T1. no → descend to T2.*
2. **T2 — `docs/architecture.md`** (cross-repo overview). Look for an architecture
   section that answers the question. *Found a citable answer? yes → answer citing the
   `docs/architecture.md` section + STOP@T2. no → descend to T3.*
3. **T3 — repos' `docs/narrative/`** (per-repo human-readable walkthrough). Look across
   the qualifying repos' narrative files. *Found a citable answer? yes → answer citing
   the `<repo>/docs/narrative/...` file + STOP@T3. no → descend to T4.*
4. **T4 — repos' `docs/domain/`** (Evans-canonical per-repo schema). Look across the
   qualifying repos' domain files. *Found a citable answer? yes → answer citing the
   `<repo>/docs/domain/...` file + STOP@T4. no → descend to T5.*
5. **T5 — repo source code** (last resort only). Read raw repo source **only** because
   every wiki tier T1–T4 above was insufficient. Answer from the source file and
   STOP@T5. Reading source here triggers the source-last hand-off below.

### One-line TRACE format

The router emits **exactly one** TRACE line per question (for every outcome —
in-domain stop, full descent, or out-of-domain). It is the auditable, greppable surface
for the retrieval order. Use this **stable** format:

```
wiki-trace: T1 -> T2 -> STOP@T2 (docs/architecture.md#billing)
```

- Prefix is the literal token `wiki-trace:` (greppable; a future regression check can
  pin on it).
- The tiers consulted are listed **in order**, separated by ` -> `, starting at `T1`.
- The tier that answered carries the stop marker `STOP@T<n>`; the citable artifact that
  answered follows in parentheses (repo-relative path, optionally `#anchor`).
- Examples:
  - Stop at T1: `wiki-trace: T1 -> STOP@T1 (docs/memory/billing.md)`
  - Mid-tier stop at T2: `wiki-trace: T1 -> T2 -> STOP@T2 (docs/architecture.md#billing)`
  - Full descent to source: `wiki-trace: T1 -> T2 -> T3 -> T4 -> T5 -> STOP@T5 (repo-a/src/Billing/ChargeSettlementService.cs)`
  - **Out-of-domain (no tier consulted):** `wiki-trace: (no tiers consulted)`

The TRACE is **one line of text** — never a multi-line block. It always appears, once,
for every routing outcome.

## Source-last contract

Repo source (T5) is read **only** when every wiki tier above (T1–T4) was insufficient.
T5 is never reached before T1–T4 have each been checked and found insufficient.

When T5 source **is actually read to answer**, that read triggers the **memory-append
hand-off**. The router does **not** write here. It references the write manual
**by its literal path**:

```
.claude/skills/wiki-memory/SKILL.md
```

All write RULES (create-or-append, same-`source-ref:` dedup, provenance, fence
protection) live in that skill. This skill never inlines
them and never writes a topic file. If that skill is **missing or malformed** at runtime
(cannot be read, YAML frontmatter does not parse, or required body sections absent), the
router **stops before any write** to `docs/memory/`, **still answers** the question from
the T5 source read, and **reports** that `.claude/skills/wiki-memory/SKILL.md` is
missing/malformed (mirrors the `wiki-bootstrapper` / `/wiki:bootstrap` stop-condition).

## Out-of-domain handling

An **out-of-domain** question is declined **without searching any tier** — no
`docs/memory/` body, no `docs/architecture.md` body, no `repo-*/docs/**`, no source is
opened. The classification (manifest titles/headings) already
determined there is no corpus anchor, so no retrieval is performed.

The router responds with this **exact-case verbatim literal** (reproduce byte-for-byte):

```
This question is outside the wiki's domain (the systems documented under docs/memory/, docs/architecture.md, and the sibling repos). No retrieval was performed.
```

For an out-of-domain question the TRACE is **empty** — no tier IDs:

```
wiki-trace: (no tiers consulted)
```

No file is read beyond the manifest surface, and no file is written.
