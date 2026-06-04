---
name: wiki-memory
description: Append-only / dedup / provenance / fence write-path operating manual for the root docs/memory/ LLM-Wiki
version: 1
consumed_by: /wiki:ask command, wiki-bootstrapper agent
---

## Purpose

This skill is the **auditable write manual** for every write into `docs/memory/`. It is
reloaded by its **two** consumers before they touch a single byte of
the wiki: the `/wiki:ask` command — lazy-loaded only when source is read at T6 and it
hands off to the memory-append path — and the `wiki-bootstrapper` when it
bootstraps/refreshes the store. Both reload this skill before writing. Neither inlines these rules —
this file is the single source of truth for
write confinement, the create-or-append disposition, `source-ref:` provenance, the dedup
guard, and the ordered write procedure.

The other root-tier skills do the reading and classifying; this one governs the writing.
A write that does not follow this manual is a bug. If this file is **missing or
malformed** (see `## Well-formedness`), the consuming agent **stops before any write** to
`docs/memory/`, still answers the question, and reports the missing/malformed skill —
this skill is what makes that stop-condition concrete.

## Write confinement

Every write this manual authorizes lands **only** under a `docs/memory/` tree — either the
root `docs/memory/` (rollup) **or** a per-repo `<repo>/docs/memory/` (learnings). There are
**no** other exceptions.

- The write target is `<docs/memory-root>/<slug>.md`, where `<docs/memory-root>` is either
  the root `docs/memory/` or a single repo's `<repo>/docs/memory/`. Nothing else is ever
  created or modified.
- **Never** write to `docs/architecture.md` (that file is owned solely by the
  `wiki-architect` agent / `wiki-architecture` skill, never this path).
- **Never** write into any repo's `docs/narrative/` or `docs/domain/` tree.
- **Never** write into repo source (any `repo-*/src/**` or other repo file).
- **Never** write into `.claude/` (this toolset, including this skill, the agents,
  commands, templates, or the fixtures used to test them).

Before any write, the agent confirms the target path is under a `docs/memory/` tree
(root docs/memory/ OR a per-repo <repo>/docs/memory/). If a candidate target resolves
anywhere else, the write is refused — there is no fallback that writes outside a
`docs/memory/` tree.

## Create-or-append policy

A source-derived learning is recorded as a single **entry** appended to a topic file. The
agent MAY create a new topic file AND/OR append to an existing one, per the routing rule
below. All writes are **append-only within any file**: the agent never overwrites,
reorders, or removes prior content.

### Entry shape

An agent-written entry **reuses the fenced-code-block shape** from
`.claude/templates/memory-topic.md` and carries exactly **two REQUIRED fields** and
nothing else:

1. a **one-line summary** of what was learned, and
2. a **`source-ref:` line** (the provenance composite — see `## Provenance ref`).

```
One-line summary of what was learned.
source-ref: <repo>@<commit> <repo-relative-path>:<line>
```

The agent does **NOT** auto-write a `<!-- human:begin --> / <!-- human:end -->` pair. That
fence pair is a **human-only curation slot**: a human may add one inside an entry later,
but the agent never emits, duplicates, or pre-seeds it. The agent also writes **no**
timestamp and **no** triggering-question field — exactly the two required fields, no more.

### Topic routing — which file

The entry appends to the topic **slug that classified the question** — the matched
`docs/memory/` topic title or `docs/architecture.md` heading from the `/wiki:ask`
classification manifest. Slug derivation: the
bounded-context / heading name lowercased into a slug (e.g. `Billing` → `billing`).

The `<docs/memory-root>` is supplied by the caller: `/wiki:ask` uses the
`<repo>/docs/memory/` of the repo whose source it read at T6; the `wiki-bootstrapper`
uses the root `docs/memory/`.

- If `<docs/memory-root>/<slug>.md` **exists** → **append** the new entry (disposition =
  append).
- If `<docs/memory-root>/<slug>.md` **does not exist** → **create** it from
  `.claude/templates/memory-topic.md` (a `# <Title>` heading, a one-line summary, a
  `## Sources` section, and a `## Entries` section), then add the entry into its
  `## Entries` section (disposition = create).

### Append-only enforcement

Writes insert **STRICTLY at the END of the `## Entries` section** of the target file, and
touch **nothing else**. The agent never edits, reorders, or removes a single byte of:

- the `## Sources` section (its links and their order),
- the topic summary line under the `# <Title>` heading,
- any prior entry already in `## Entries`, or
- any `<!-- human:begin --> ... <!-- human:end -->` fenced region (see the inline
  fence-protection rule below).

A T6 source-read append is an **`## Entries`-only** operation. It **never** adds, removes,
or refreshes a `## Sources` link — maintaining `## Sources` is the bootstrapper's job,
not the write path's. Provenance for a source-read finding lives in the entry's
`source-ref:` field, not in `## Sources`.

### Gate posture — all writes ungated

Every write through this manual is **ungated — NO `APPROVE` prompt**, for **all** callers
(`/wiki:ask` T6 write-back, `wiki-bootstrapper` rollup). The append is incidental to
answering / rolling up, not operator-invoked. The safety net is **append-only + same-ref
dedup `(repo, path, line)` + fence protection** — not a gate. (Historical note: an earlier
version gated the bootstrap rollup; that gate is retired.)

### Fence protection (inline)

Never write **inside** a `<!-- human:begin --> ... <!-- human:end -->` region, and never
alter the bytes of any fenced region. Agent entries always land **after** the last
existing content of `## Entries`; an append never splits, wraps, relocates, or re-indents
a human fence. The asymmetric co-ownership rationale and the
ownership table live in `## Co-ownership contract` and `## Fence convention` below.

## Provenance ref

Every appended entry records a single `source-ref:` line. It is the **diff-ready**
provenance shape a future staleness feature can compare against HEAD. **v1 stores
the ref only and does not diff it.**

Serialization (matches `.claude/templates/memory-topic.md`):

```
source-ref: <repo>@<commit> <repo-relative-path>:<line>
```

- `<repo>` — the repo the fact was read from (e.g. `repo-a`).
- `@<commit>` — the commit the workspace was at when the fact was read. **Optional** —
  omit when unknown.
- `<repo-relative-path>` — the source file path, repo-relative (e.g.
  `repo-a/src/Billing/ChargeSettlementService.cs`). **Required** — provenance always
  carries at least the path.
- `:<line>` — the line the fact sits on. **Optional but recorded when known** — when the
  source fact is at a known line (the common T6 case), the line MUST be included.

**Omit the parts you do not have**, but never omit the path. The components are written in
a single, parseable shape so both the dedup guard (below) and a future HEAD diff can read
them mechanically. The worked illustrative shape used by the fixtures is
`repo-a/src/Billing/ChargeSettlementService.cs:29@abc1234` — the same `(repo, path, line)`
tuple; whatever the surface layout, the normalized tuple is what dedup keys on.

## Dedup guard

**Before** appending, scan the target topic's `## Entries` for an existing entry with the
**same normalized key**. If found, **skip** the append and **report the skip**. The guard
is a cheap exact-key match, not semantic dedup.

### Normalized key

The dedup key is the tuple:

```
(<repo>, <repo-relative-path>, <line>)
```

derived from the candidate's `source-ref:` by **stripping the `@<commit>` suffix**. The
commit is **ignored** for dedup. Two entries are DUPLICATES iff their normalized keys are
equal.

- **Same `file:line` at a NEW commit → DUPLICATE → skip.** Stripping `@<commit>` means
  `…ChargeSettlementService.cs:29@abc1234` and `…ChargeSettlementService.cs:29@def5678`
  normalize to the **same** key `(repo-a, src/Billing/ChargeSettlementService.cs, 29)`.
  This is the sharp branch: it is NOT a full-composite byte-match (which would wrongly
  treat the new commit as new).
- **DIFFERENT line, same file → NOT a duplicate → append.** The line **is** part of the
  key, so `:30` ≠ `:29` for the same file is a genuinely new fact and the append proceeds.
- **Missing-line refs match only other missing-line refs for the same path.** A ref with
  **no** `:<line>` normalizes to `(<repo>, <repo-relative-path>, ∅)`. It dedups only
  against another missing-line entry for the **same path**. A `∅`-line key never matches a
  specific-line key: `(…, ∅)` ≠ `(…, 29)`, so a specific-line candidate is never deduped
  against a missing-line entry, and vice versa.

Dedup suppresses **only the write**. The question is still answered to the user even when
the append is skipped.

## Procedure

The ordered write algorithm. Both consuming agents follow it for every candidate entry.

1. **Build the candidate entry.** Assemble the one-line summary and the `source-ref:`
   line (the two required fields, in the fenced-code-block entry shape from
   `.claude/templates/memory-topic.md`). Do not add a timestamp, a
   triggering-question, or a `<!-- human:* -->` fence.
2. **Compute the normalized key.** Strip `@<commit>` from the candidate's `source-ref:`
   to get the tuple `(<repo>, <repo-relative-path>, <line>)`; a missing `:<line>`
   normalizes to `(…, ∅)`.
3. **Resolve the target topic.** Derive the slug from the classifying BC / heading
   (lowercased), giving `<docs/memory-root>/<slug>.md`. Confirm the target path is
   under `docs/memory/` (`## Write confinement`).
4. **Scan for a duplicate.** Read the target topic's `## Entries` (if the file exists) and
   compute the normalized key of each existing entry. If any equals the candidate key →
   **DUPLICATE**.
5. **If duplicate → skip + report.** Do **not** write. Report the skip (dedup hit),
   distinct from a successful append. The file is left byte-for-byte unchanged. The
   question is still answered.
6. **Else create-or-append.**
   - If `<docs/memory-root>/<slug>.md` does not exist → create it from
     `.claude/templates/memory-topic.md`, then insert the entry at the end of its
     `## Entries`.
   - If it exists → insert the entry **strictly at the END of `## Entries`**, after the
     last existing entry / fenced region.
   - Touch **nothing else**: never edit the summary, `## Sources`, prior entries, or any
     human fence; never add a `## Sources` link.
7. **Never commit.** Leave the new/modified `docs/memory/*.md` as an uncommitted
   working-tree change. The write path never runs `git add` or `git commit`.

## Well-formedness

This section makes the **malformed** stop-condition concrete and testable,
so the `/wiki:ask` and `wiki-bootstrapper` stop-before-write conditions ("cannot be
read, YAML frontmatter does not parse, or required body sections absent") have a precise
schema to check.

A `.claude/skills/wiki-memory/SKILL.md` is **well-formed for write** iff **both** of
the following hold:

**Required frontmatter keys** (frontmatter must parse as YAML AND contain all three):

- `name: wiki-memory`
- `version`
- `consumed_by`

**Required body sections** (all 5 must be present):

- `## Write confinement`
- `## Create-or-append policy`
- `## Provenance ref`
- `## Dedup guard`
- `## Procedure`

A skill is **malformed** (and the consuming agent MUST **stop before any write** to
`docs/memory/`, while still answering the question and reporting the failing reason) when:

- its frontmatter fails to parse as YAML, OR
- its frontmatter is missing any of `name: wiki-memory` / `version` / `consumed_by`, OR
- its body is missing ANY of the 5 required sections above.

**Not in the required-for-write set.** The `## Co-ownership contract` and
`## Fence convention` sections are **NOT** required for the write path. A skill missing
**only** those two is **well-formed for write** — the write proceeds normally.

## Co-ownership contract

`docs/memory/` is **co-owned** under a strict, asymmetric contract. The human is the
**curator/owner** with full edit/curate/delete authority; the agent is an **append-only
contributor** gated by the same-source-ref dedup guard. This is the resolution of the
documented human-vs-agent ownership contradiction: the human "manages" `docs/memory/`
(edit, reorganize, prune), and the agent may still "add" to it without ever destroying
human curation.

| Actor | May create files? | May append? | May overwrite/edit existing text? |
|---|---|---|---|
| Agent | Yes (new topic files) | Yes (append-only) | **No** — never overwrites human (or prior) text |
| Human | Yes | Yes | Yes (full edit/curate/delete authority) |

This contract is **distinct** from `docs/narrative/` + `docs/domain/`, which remain fully
agent-controlled. The asymmetry applies **only** to `docs/memory/`.

## Fence convention

A `<!-- human:begin --> ... <!-- human:end -->` pair marks a **human-curated region**. The
agent **never** writes inside a fence and **never** alters fenced bytes — fenced text
survives any number of agent appends byte-for-byte.

The two safety properties are not the same strength:

- **Append-only is the HARD guarantee.** It is the load-bearing safety property and holds
  for the entire file, fenced or not — the agent never overwrites, reorders, or removes
  prior content anywhere, and always lands a new entry strictly at the end of
  `## Entries`.
- **The fence is the RECOMMENDED explicit-intent marker.** It is the recommended way for a
  human to mark a region as curated, making human intent unambiguous; but human text is
  protected by append-only even outside a fence.

Because append-only is the hard guarantee, human-authored text in `docs/memory/` is never
destroyed by an agent append regardless of fencing; the fence simply makes the
human-curated boundary explicit.
