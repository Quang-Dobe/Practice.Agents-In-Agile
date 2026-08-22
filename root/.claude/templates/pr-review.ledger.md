# PR Review Ledger — <stem>

source: <stem>.md

<!--
SHAPE FILE. `/pr-review:analyze` creates one ledger per review file at
docs/<feature>/pr-review/<stem>.pr-review.ledger.md

Who writes what:
  - The agent appends whole `## PR-NN` sections at the END. It never edits an
    existing section.
  - Exactly ONE machine edit exists: `/pr-review:learn` flips `promoted: no` to
    `promoted: yes` after you type APPROVE. Nothing else in an existing section
    is ever machine-written.
  - You own everything else. Merge sections, split sections, correct `concern`,
    flip `status`. The next run respects your edits.

`status` has exactly three values: `open`, `fixed`, `rejected`. Nothing else.
`/pr-review:learn` selects on `fixed`, lowercase, matched exactly — so a row
reading `done` or `resolved` is invisible to it.

The ledger is upstream. The HTML page is rendered FROM this file, never the
other way round. Flip `status` here and the next run re-renders the page.

Omit the `reviewer` line and the `reviewer-at` line when the prose gives no
clear marker. Never write `unknown`.

The `## PR-01` section below is a labeled example only, not a real finding.
A freshly created ledger starts with zero finding sections — the first one
is appended by `/pr-review:analyze`, never left over from this template. The
title's `<stem>` and the `source:` line's `<stem>` are both replaced with the
real review file's stem when the ledger is created.
-->

## PR-01

- title: <one line, max 60 chars, plain words. names the problem, not the fix.
  this is the only text shown when the card is collapsed on the page.>
- concern: <coding-rules | architecture-rules | test-rules | open-concern-name | none>
- evidence: <Located | Not code-locatable | Not found>
- evidence-detail: <path:line-line — or — no single site — scope: <area>>
- reviewer: <name, only when the prose marks one>
- reviewer-at: <path:line, only when the reviewer gave one>
- status: open
- promoted: no

### Quote (verbatim — dedup and re-match key)

> <the reviewer's words, copied exactly. never paraphrased. this text is the
> key that re-matches this finding on every later run, so it must not change.>

### Snippet

```
<the code at evidence-detail. 4 lines either side of the anchor, hard cap 12
lines, truncate with a single line holding …

Present only when evidence is Located. Stored here so the page can re-render
without reading source. It goes stale after you fix the code — that is
intended. It records what was wrong at review time.>
```

### Root cause

<derived from the snippet only. when evidence is NOT Located, this reads exactly:

not established — no code evidence>

### Proposed fix (unverified)

<what to change. never phrased as fact — the agent does not decide whether the
review is right.

when evidence is `Not found`, this reads exactly:

cannot propose a fix — code not located>

### Hints

<zero to four lines, one per hard word used in THIS section. shape:

- <term> — <plain meaning, max 12 words>

only terms that appear in this finding's own text. no hint for a word that is
already plain. a hint defines a word; it never argues the finding. zero hints is
a correct answer — omit the whole section then.>
