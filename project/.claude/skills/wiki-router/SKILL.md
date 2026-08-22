---
name: wiki-router
description: Classification + fixed retrieval-order checklist consumed inline by /wiki:ask (no sub-agent)
version: 2
consumed_by: /wiki:ask command
---

## Classify (manifest only — before any tier read)

Build the scope manifest from titles/headings ONLY — never file bodies:

- the `# <Topic title>` line of every root `docs/memory/*.md`
- the `#`/`##`/`###` heading lines of `docs/references.md`
- the `# <Topic title>` line of every `<repo>/docs/memory/*.md`

Body reads happen only after an in-domain decision, during tier retrieval — never here.

- **In-domain** = the question has a manifest anchor (a topic title or heading it is clearly about).
- **Out-of-domain** = no anchor. Decline with this **exact-case byte-for-byte** literal, emit the empty TRACE, open no tier, write nothing, stop:

```
This question is outside the wiki's domain (the systems documented under docs/memory/, docs/references.md, and the sibling repos). No retrieval was performed.
```

False-positives and false-negatives weigh **equally** — the manifest-anchor test is the deterministic call; no "search anyway when unsure" bias, and no "decline when unsure" bias either.

## Retrieve (in-domain only) — fixed order, stop once sufficient

Walk EXACTLY this order. Between tiers apply the stop-check: *found a citable artifact that answers? yes → cite it + stop; no → descend exactly one tier.* Never skip a tier; never read below an answering tier (no over-descent).

| Tier | Corpus |
|---|---|
| T1 | root `docs/memory/*` (curated rollup) |
| T2 | `docs/references.md` (cross-repo overview) |
| T3 | repos' `docs/narrative/` (per-repo walkthroughs) |
| T4 | repos' `docs/domain/` (Evans-canonical schema) |
| T5 | repos' `docs/memory/` (per-repo learnings from prior source reads) |
| T6 | repo source — last resort, only after T1–T5 each insufficient; triggers the write-back below |

## TRACE — one line, every outcome

```
wiki-trace: T1 -> T2 -> STOP@T2 (docs/references.md#billing)
```

- Literal greppable prefix `wiki-trace:`; consulted tiers in order, ` -> ` separated, starting at `T1`; `STOP@T<n>` at the answering tier; the citable artifact (repo-relative path, optional `#anchor`) in parentheses.
- Full descent: `wiki-trace: T1 -> T2 -> T3 -> T4 -> T5 -> T6 -> STOP@T6 (repo-a/src/Billing/OrderPaidPublisher.cs:42)`
- Out-of-domain (no tier consulted): `wiki-trace: (no tiers consulted)`

One line of text, never a multi-line block; emitted exactly once per question.

## T6 write-back — the only write path (lazy-loaded)

Load `.claude/skills/wiki-memory/SKILL.md` ONLY when T6 source was actually read to answer — never earlier. Then append the learning to `<repo>/docs/memory/<slug>.md` of **the repo whose source was read**, per that manual (ungated: append-only + same-`source-ref:` dedup + fence protection). Write rules are never inlined here.

- `wiki-memory` missing/malformed (cannot be read, YAML frontmatter does not parse, or required body sections absent) → still answer from the source read; write NOTHING; report the missing/malformed skill.
- T1–T5 answers: zero writes, zero source reads, no `APPROVE` prompt.
- Never write outside a `docs/memory/` tree; never the root `docs/memory/` from this path; never narrative/domain/architecture/source/`.claude/`; never commit.

(Historical note: v1 ran this checklist inside a `wiki-router` sub-agent that preloaded both skills on every question; v2 inlines it into `/wiki:ask` and lazy-loads the write manual to cut per-question overhead. Classification, tier order, TRACE, and all literals are unchanged.)
