---
name: wiki-architecture
description: Cross-repo synthesis + context-map + fence-preservation write manual for docs/references.md, owned solely by the wiki-architect agent
version: 1
consumed_by: wiki-architect agent
---

## Purpose

The auditable manual for (re)authoring the root `docs/references.md` — the cross-repo
overview. It is the **only** write path to that file; the `wiki-memory` and `/wiki:ask`
paths are forbidden from touching it. Reloaded by the `wiki-architect` agent at the start of
every run.

## Output root (nested mode)

When the dispatch provides an `output_root`, this skill writes `docs/references.md` at `<output_root>/docs/references.md` instead of the bare root `docs/references.md`; the per-child inputs are the direct children the dispatch names. Human `<!-- human:begin --> ... <!-- human:end -->` fences are still preserved byte-for-byte. Absent `output_root` → today's root `docs/references.md`, byte-identical. The nested orchestrator sets this per the `wiki-orchestration` skill `## Output root (nested mode)`.

## Inputs (read-only)

Per qualifying repo: `docs/narrative/` (human walkthrough), `docs/domain/` (Evans-canonical
schema), and `docs/memory/` (per-repo learnings, soft input). Never modify any input.

**Neither tree is required for a Context Map.** `docs/domain/` is the richest source of event and
command names, but a system with no message bus has none, and `docs/narrative/` carries every
integration point, store and config key on its own. A missing `docs/domain/` narrows the evidence;
it never makes the map underivable (`## Output shape` item 2, the no-bus paragraph).

## Output shape

A full (re)generation of `docs/references.md`. It opens with the provenance frontmatter
from `## Pre-flight — never overwrite a file this kit did not write`, then these sections, in
order:

1. `# System Overview` — 3–6 sentence plain-language description of what the whole system
   does, synthesized across repos.
2. `## Context Map` — the cross-repo flow, **derived mechanically**. **Three** edge kinds.
   Put the first two under `### Between repos`, grouped by the upstream repo, and the third
   under `### Out of the system`, grouped by the owning repo. Keeping them apart is what stops
   a dozen datastore arrows from burying the service-to-service story.

   - **Event edge** — `Publisher --EventName--> Consumer`. For each event or command in a
     repo's `docs/domain/`, find the consuming repo.
   - **Call edge** — `Caller ==InterfaceOrRoute==> Callee`. For each cross-repo synchronous
     integration point named in a repo's `docs/domain/` or `docs/narrative/`: a typed HTTP
     client, a gRPC stub, an anti-corruption-layer adapter, or a configured base address
     that names another repo. The label is the name as written in code (`IAgentClient`,
     `GET /v1/scope`), never a made-up event name.
   - **Dependency edge** — `Repo ~~WhatItIs~~> Resource`. Everything a repo reaches that is
     **not one of the repos**: a database, a cache, a relationship store, a broker, a model
     host, a telemetry collector, an identity provider, a gateway or an OIDC proxy sitting in
     front of the system. Name the resource as its narrative names it (`PostgreSQL`,
     `OpenFGA`, `Redis`, `Azure OpenAI`, `Kong`) and label the edge with the **config key or
     client type** the code uses to reach it.

   Read all four integration-inventory tables of each narrative `architecture.md` (the
   `project-overview` skill `### Integration inventory contract`), not just its prose:
   `## Outbound dependencies` and `## Stores owned` give dependency edges; `## Config-swapped seams`
   gives the `[fallback: …]` state on both edge kinds; `## Exposed endpoints` gives the inbound half
   of the join rule below.

   **A mediator row is still an edge, but never an unmarked one.** `## Out-of-scope mediators` lists
   outbound calls a repo makes through a shared library whose source nobody could scan. Emit those as
   dependency edges on **each consuming repo**, labelled `via <library>`, and marked
   `[unscanned: <library>]`. Do **not** draw the library as a node — it is not a participant, it is
   the reason the edge exists. Five hosts each exporting telemetry through one shared library is five
   edges and no new box. Dropping them because no repo's own source names the collector is how a
   system ends up looking like it has no observability at all.

   **A mediator row is never an outbound row.** The marker is the whole point: `[unscanned: ...]`
   says a real call probably leaves here, through code nobody could read. An unmarked edge claims the
   repo's own source makes the call. Emitting a mediator *without* the marker is the error — not
   emitting the edge. A repo that reads a feature flag and stamps two span attributes, while a
   third-party tracer does any uploading, gets `via <library>` plus `[unscanned: ...]` and never a
   bare arrow.

   **Only emit a mediator row that opens a target no other row already has.** A library that merely
   *modifies* an existing edge — stamping a header, adding retries, owning the table names behind a
   connection already emitted with its own config key — gets no row. It would double-count an edge
   that is already drawn.

   Arrow forms are the legend: `-->` asynchronous, `==>` blocking call, `~~>` out of the
   system. Nothing else may use those forms.

   **Every edge carries a state.** Append one marker:

   | Marker | Means | Derived from |
   |---|---|---|
   | *(none)* | live — the call happens on the normal path | the default |
   | `[config-pinned: KEY]` | the target **is** a runtime config value, not named in code | a base address read from configuration |
   | `[config-selected: KEY]` | the target is named in code, but config picks **which** target | a provider registry keyed on a setting, an SDK default endpoint reached with only an API key |
   | `[fallback: Name]` | absent config swaps in a stand-in that **answers**, and no call leaves the process | an in-memory store, a scripted model, a hermetic tool double |
   | `[refuses: Name]` | absent config swaps in a stand-in that is **registered and denies** — the host boots, every call gets an error | an `Unconfigured*` / `NotConfigured` type that throws a 503 |
   | `[fail-fast: KEY]` | absent config registers **nothing** and the process does not start | a startup throw on a blank key |
   | `[planned]` | the client or route exists but nothing on a request path calls it | a registration with no live caller |
   | `[unscanned: Library]` | the call is real but its code was outside every scan scope | an `## Out-of-scope mediators` row |

   **Classify by behaviour, never by the type's name.** `UnconfiguredAuthzClient` looks like a
   fallback and is a `[refuses: ...]`: it is registered, the host starts, and every call gets a 503.
   An in-memory store is a true `[fallback: ...]`: it starts *and answers*, with data that is wrong
   rather than absent. Those are opposite operational stories, and the more dangerous one is the
   fallback -- a refusal is loud, a hermetic double is silent. Collapsing them into one marker hides
   exactly the case worth paging someone about.

   `[fail-fast: KEY]` is not a `[fallback: ...]`. Nothing answers, so there is no second
   implementation to name. Emit it on the seam it guards so a reader can see which repos refuse to
   run half-wired, and say in the overview which repos chose which -- no repo can see that about
   itself, and it is one of the more useful things this document can say.

   `[config-pinned]` and `[config-selected]` are different claims and mixing them misleads. A base
   address read from configuration means the code does not know its callee. An API key naming no
   endpoint means the code **does** know its callee — the SDK default — and configuration only chose
   between several it knows.

   **A config-swapped seam gets two rows, not one.** One config key with a real client on one side
   and a stand-in on the other is two mutually exclusive states of the same seam, and no single
   marker can say both. Emit the live edge with its `[config-pinned: KEY]` or `[config-selected: KEY]`
   marker, then the same seam again with its `[fallback: Name]`, `[refuses: Name]` or
   `[fail-fast: KEY]`. Never pick whichever state looks normal and drop the other — that silently
   deletes exactly the line this section calls the most useful one it has.

   Two rows for one seam are still **one seam**. A reader, and any diagram drawn from this file, has
   to be able to tell rows that split a seam from rows that are separate seams — so keep a seam's
   rows adjacent and label them with the same interface.

   **When two markers both fit one row, precedence is:** `[fail-fast: KEY]`, then `[refuses: Name]`,
   then `[fallback: Name]`, then `[unscanned: Library]`, then `[config-pinned: KEY]` /
   `[config-selected: KEY]`. The earlier marker answers "what happens when this is wrong", which a
   reader needs before "where does this point". Put the loser in the line's prose rather than
   dropping it.

   A `[fallback: …]` edge is the single most useful line in this section, and the one a
   hand-drawn diagram always gets wrong: it is the difference between what the system does and
   what it does when someone forgot an environment variable. Never drop the marker to tidy a
   line up.

   A system with **no message bus** has only call and dependency edges. That is a complete
   Context Map, not a degraded one — most request/response systems look like this, and a map
   that reports nothing because it only looked for events is wrong, not empty.

   All three kinds are derived, never invented: every line traces to something named in an
   input tree. This section is the load-bearing artifact (a future staleness check can
   re-derive it).

   **How to find an edge at all — the join rule.** Each input tree was written under leaf-scope
   confinement (`repo-layout` skill `## Leaf-scope confinement (nested mode)`), so **no repo's tree
   can name its own callee.** A caller's tree holds its route literal and config key; the callee's
   tree holds the routes it registers. The edge exists only in the correlation, and nothing finds it
   for you:

   1. Collect every **outbound** integration point per repo — interface or client type, route
      literal, config key.
   2. Collect every **inbound** entry point per repo — the registered route.
   3. Match a caller's route literal against a callee's registered route. That match is the edge.
   4. When no route literal exists on either side, fall back to **protocol plus uniqueness**: a
      caller holding only a whole-URL config value, and exactly one repo in the system speaking that
      protocol, is a match. Say in the line that it was matched by protocol, not by route.
   5. When the base address is a runtime value and no code names the target, still emit the edge from
      the route match, marked `[config-pinned: KEY]`.

   Skip this and you find only the edges a caller happens to name in code, which on a typical
   configuration-driven system is very few of them.

   **Tie-break: nearest hop wins.** One caller literal can match two registrations — a relay's
   catch-all and, deeper, the service that really answers. Draw the edge to the callee the caller
   reaches in **one** hop, and record the deeper match as relay evidence in the line. Taking both
   draws a phantom edge that skips the hop actually in the path.

   **Both kinds of unmatched route are findings, and the file must carry both.** `[planned]` covers a
   registration nobody calls. The inverse has no marker, because it is not an edge state — it is a
   **live call whose target no tree registers**. Record it on the edge it does match, and say plainly
   that the relayed literal matches no registered route anywhere. That is usually the more urgent of
   the two: a registration with no caller is dead code, a call with no registration is a 404 waiting
   for a user. Never drop either to tidy the map, and never invent an upstream to give an orphaned
   registration an arrow.
3. `## Boundaries` — the named regions of the system, one per row, and for each the
   **invariant that makes it a boundary**. A region is only worth naming when something is
   true of everything inside it and false outside:

   ```
   | Region | Members | The invariant |
   |---|---|---|
   | Authorization | authz-service, OpenFGA, nanci schema | the only holder of OpenFGA credentials |
   | Data access | query-service, warehouse | the only component that scopes rows |
   ```

   Derive a region from a narrative that says "the only", "sole writer", "never reaches", or
   from a datastore exactly one repo connects to. **A grouping with no invariant is not a
   boundary** — leave it out rather than inventing a rule to justify a box.
4. `## Ownership` — a two-column table of *what data or decision* → *which repo owns it*,
   derived from each repo's aggregates and its exclusively-held stores. This is the section a
   reader checks when they want to know who to talk to, so keep the left column concrete
   ("the conversation transcript", "row-level scope decisions"), never a layer name.
5. `## Per-repo summaries` — one short paragraph per repo (name + responsibility + key
   aggregates), paraphrased from its narrative/domain. Name the repo's inbound entry points
   and the stores it owns; those are what the diagram's per-node detail is drawn from. No
   verbatim multi-line copies.

Keep prose terse. Do not paste Mermaid bodies, full aggregate tables, or runs of ≥2
consecutive non-trivial source lines from any input.

## Pre-flight — never overwrite a file this kit did not write

`docs/references.md` is **fully regenerated**, so a first run against a repo that already keeps
a hand-written `docs/references.md` would destroy it. Fence preservation does not save that
file: a human who never heard of this kit has no reason to have written a fence.

So every generated `docs/references.md` opens with a provenance block, before the
`# System Overview` heading:

```yaml
---
generated_by: wiki-architect
skill_version: 1
generated_at: <ISO-8601 UTC>
---
```

Read the target before writing — **the target resolved through `output_root`**
(`## Output root (nested mode)`), never the bare root path — and branch on what is there:

| Target state | Action |
|---|---|
| absent | write |
| present, frontmatter carries `generated_by: wiki-architect` | regenerate, preserving fences |
| present, no such frontmatter | **refuse — write nothing** |

The refusal is one line, names the file, and never blocks the rest of the run:

```
Refusing to overwrite <path> — no `generated_by: wiki-architect` frontmatter, so this kit did not write it. Move it aside, or wrap the parts worth keeping in `<!-- human:begin -->` fences, then re-run.
```

Both escapes stay open to the human: keep the hand-written file under another name, or move its
prose inside a fence and let the kit own the rest. Neither is chosen for them.

## Fence preservation (load-bearing)

Even though this path **fully regenerates** `docs/references.md`, any
`<!-- human:begin --> ... <!-- human:end -->` region in the **existing** file is preserved
**byte-for-byte**: read the current file first, extract every fenced region with its
anchoring context, and re-emit those bytes unchanged in the regenerated output at the same
relative position (matched by the heading or marker immediately preceding the fence).

**The anchor is weakest under `## Per-repo summaries`**, where the paragraphs carry no headings of
their own. A fence there has no stable heading to re-match against, and if the repo set changes
between runs its position is genuinely ambiguous. Two rules for that case: anchor on the **repo
name** that opens the paragraph, and if the repo no longer exists, re-emit the fenced bytes at the
**end of the section** under a `<!-- orphaned fence: <repo> -->` line rather than dropping them.
Losing a human's words is the one failure this whole section exists to prevent, so an ugly
placement beats a clean deletion. The
agent never writes inside a fence and never alters fenced bytes. Everything **outside** the
fences is regenerated.

## Write confinement

The sole write target is `docs/references.md`, **resolved through `output_root`** — that is
`<output_root>/docs/references.md` when the dispatch sets one, and the bare `docs/references.md`
of the working directory when it does not (`## Output root (nested mode)`). Before writing,
confirm the target path resolves to exactly that. Do not read this as "the root
`docs/references.md`" — in nested mode the file legitimately sits at a node home, and a literal
root-only check refuses every nested write.

Never write to `docs/memory/` (root or per-repo), any repo's `docs/narrative/` / `docs/domain/`,
repo source, or `.claude/`.

## Gate + commit posture

Ungated (no `APPROVE`); safety net is fence preservation + single-owner confinement. Never
`git add` / `git commit`; leave the file as a working-tree change.

## Well-formedness

Well-formed for write iff frontmatter parses as YAML with `name: wiki-architecture` +
`version` + `consumed_by`, AND the body contains `## Output shape`,
`## Pre-flight — never overwrite a file this kit did not write`, `## Fence preservation`,
and `## Write confinement`. If malformed, the `wiki-architect` agent stops before writing
`docs/references.md` and reports it.
