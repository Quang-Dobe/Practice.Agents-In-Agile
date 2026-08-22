# PR Review Loop — Turn review comments into rules that stick

This document explains the third workflow this kit ships: one AI agent and two
commands that take the comments people leave on your pull request, find the
code behind each one, and — after you fix them — write them into your repo as
standing rules the rest of the crew will read on the next feature.

It is written for someone who has been through a code review. You do not need
to know how to code to read the output; the page it produces is meant to be
read in a browser.

---

## The problem it solves

A reviewer says *"this service reaches into the database directly"*. You fix
it. Three weeks later, on a different feature, it happens again — because the
lesson never left the pull request.

Review comments die where they were written. That is the leak. Nothing carries
them forward into how the next feature gets planned and built.

This workflow closes that leak. It is called a **loop** because the last step
feeds the first step of your next feature.

---

## The big picture

```
   you paste review comments into a plain .md file
        │
        │   /pr-review:analyze
        ▼
   the analyst splits the prose into findings
   and finds the code behind each one          <- no verdict. you judge.
        │
        ▼
   ledger (.md)  --renders-->  card page (.html)
        │                          │
        │                          └─ you read it in a browser
        │
   you fix the code, then set  status: fixed  in the ledger
        │
        │   /pr-review:learn
        ▼
   rule drafts  == APPROVE ==>  your repo's .claude/skills/
        │
        └─> the crew reads those rules on the NEXT feature
                  │
                  └─── so the same comment never comes back ───┘
```

---

## What you get

You create one folder and one file. The kit fills in the rest.

```
docs/<feature>/pr-review/
├── round-1.md                        <- YOU write this. Free prose, no format.
├── round-1.pr-review.ledger.md       <- the record. you edit this.
├── round-1.pr-review.html            <- the page you read. never edit.
├── round-2.md                        <- a second review round, if there is one
├── round-2.pr-review.ledger.md
└── round-2.pr-review.html
```

One review file gives you one ledger and one page. Add a second round later and
it gets its own pair — the first pair is left alone.

---

## The cast

| Piece | Job | Writes files? |
| ----- | --- | ------------- |
| **pr-review-analyst** | Splits your prose into findings, hunts the code behind each one, drafts rule text later. | **No.** Read-only. |
| **`/pr-review:analyze`** | Runs the analyst, writes the ledger, renders the page. | Yes — ledger + page. |
| **`/pr-review:learn`** | Turns your fixed findings into rules in your own repo. | Yes — after `APPROVE`. |

The analyst can only read. Every write is done by the command that called it.
That is deliberate: an agent that both judges and writes is hard to audit.

---

## Phase 1 — You write the notes

Make the folder and drop your notes in it:

```
docs/payments-export/pr-review/round-1.md
```

There is **no format**. Paste the comment thread from GitHub or Azure DevOps.
Paste your own bullet list. Paste a wall of prose. The analyst splits it for
you.

Two things help, but neither is required:

- A marker such as `@alice` or `alice:` lets the analyst record who said it.
- A path such as `src/Foo/Bar.cs:112` gives it a head start on the hunt.

---

## Phase 2 — Analyse

```
/pr-review:analyze --feature payments-export --review round-1
```

Leave `--review` off and it does every review file in the folder at once.

The analyst reads your notes and, for each finding, searches your source code
for the thing the comment is about. It sets exactly one **evidence state**:

| State | Meaning | What you get |
| ----- | ------- | ------------ |
| **Located** | It found the code. | A `path:line-line`, a snippet, a root cause, and a suggested fix. |
| **Not code-locatable** | The point is real but has no single site — a missing test, a naming habit across the repo, a layering problem. | A suggested fix, but no root cause. |
| **Not found** | It searched and the thing is not there. | What it searched for. No root cause, no fix. |

Three states, not two. That matters: when there is no code evidence, the root
cause reads exactly `not established — no code evidence`. An empty box is a
correct answer. A slot that **must** be filled invites a made-up root cause,
which is worse than no answer at all.

**It never says a comment is right or wrong.** It shows the comment and the
code behind it. You judge. An agent that ranks review comments by correctness
has quietly made itself the reviewer, and nobody asked it to.

### The two files it writes

**The ledger** (`.md`) is the record. One `## PR-NN` section per finding,
holding a short title, the concern, the evidence state, the reviewer's exact
words, the snippet, the root cause, a suggested fix, and a few plain-word
hints. You own this file.

**The page** (`.html`) is a view of the ledger, rendered fresh each run:

- One collapsible card per finding, each at its own `#PR-01` link, so you can
  send a teammate a link to one finding.
- A card you still have to act on is **open**. A card you mark `fixed` or
  `rejected` is **collapsed**. So the list shrinks as you work through it.
- Collapsed, a card shows the title, the concern, the status, and whether the
  code was found. Enough to skip it or open it.
- Hard words get a small chip at the bottom of the card. Hover or press Tab for
  a plain meaning.
- Dark by default, and it follows your system theme.

---

## Phase 3 — You fix the code, then mark it

Open the page. Read it. Fix what deserves fixing.

Then, in the **ledger**, change the line by hand:

```
- status: open      ->      - status: fixed
```

Three values only: `open`, `fixed`, `rejected`. Nothing else. `fixed` is
matched exactly and in lower case, so a row reading `done` or `resolved` is
invisible to the next command.

Re-run `/pr-review:analyze` and the page re-renders from the ledger, with that
card now collapsed. No source is read on that path — it is a re-render, not a
re-analysis.

Use `rejected` freely. A review comment you disagree with is a normal outcome,
and recording the disagreement is worth more than deleting the row.

---

## Phase 4 — Learn

```
/pr-review:learn --feature payments-export
```

This picks up only the rows where `status: fixed` **and** `promoted: no`, then
drafts one rule section per finding and asks where it belongs:

| The finding is about | It becomes a rule in |
| -------------------- | -------------------- |
| naming, style, a forbidden pattern | `coding-rules` |
| layering, boundaries, dependency direction | `architecture-rules` |
| test layout, coverage, fixtures | `test-rules` |
| a framework or library pattern with no home yet | a new concern you name, e.g. `dotnet-patterns` |
| process only — PR size, commit message, branch name | nothing. It is logged and dropped. |

Every draft is shown to you. Nothing is written until you type `APPROVE`.
After that, the rule is appended to your own repo's
`.claude/skills/<concern>/SKILL.md`, and the ledger row flips to
`promoted: yes` so the same finding is never promoted twice.

**Rules land in your repo, never in the kit.** So one project's style rule
cannot leak into another project.

### One trap worth knowing

The first three concerns — `coding-rules`, `architecture-rules`, `test-rules` —
are found automatically. **Anything else is not.** A new concern such as
`dotnet-patterns` has to be named in an `## Also load` list inside one of those
three, or no agent will ever read it. The command produces that line for you
and tells you where it goes. Skip it and you have a rule file nobody reads.

---

## Things worth knowing

- **The ledger is upstream; the page is only a view.** Edit the ledger. The
  page is regenerated, so anything you type into the page is eaten on the next
  run.
- **The ledger owns the finding IDs.** Your notes are free prose, so re-reading
  them could split the same comment differently every time. Instead, a later
  run re-matches on the reviewer's exact words. That is why the quote is never
  reworded — it is the key.
- **The stored snippet goes stale, on purpose.** It records what the code
  looked like at review time, not now. That is the point.
- **Add comments to a file you already analysed?** Pass `--review <stem>`
  explicitly. That forces a re-read. Without it, an already-analysed file is
  skipped and your new comments are never seen.
- **No gate on analyse, one gate on learn.** `/pr-review:analyze` just runs.
  `/pr-review:learn` writes nothing until you type `APPROVE`.
- **No commits, ever.** Like the other two workflows, this one never runs
  `git commit` for you. You decide when.
- **Nothing is deleted.** A ledger with no matching notes file is reported and
  left alone. It holds your IDs and your decisions.

---

## How this differs from the other two workflows

| Aspect | Feature pipeline | Domain wiki pipeline | PR review loop |
| ------ | ---------------- | -------------------- | -------------- |
| Goal | Plan and build a new feature. | Explain an existing codebase. | Turn review feedback into rules. |
| You write first? | Yes — a rough requirement. | No. | Yes — your review notes. |
| Output location | `docs/<feature>/` | `docs/domain/`, `docs/narrative/` | `docs/<feature>/pr-review/` and your `.claude/skills/` |
| Cadence | Once per feature. | Bootstrap once, then on every code change. | Once per review round. |
| Number of roles | Five. | Three. | One, and it is read-only. |
| APPROVE gates | Many — one per stage and per step. | None. | One, on `learn` only. |
| Produces a `status.md`? | Yes. | No. | No. |

All three can live in the same repository. The review loop writes inside
`docs/<feature>/pr-review/`, which no other workflow touches.

It is also the only one of the three that writes into your repo's own
`.claude/skills/` — and only with your sign-off.

---

For the other two walkthroughs, see
[`workflow-feature-pipeline.md`](workflow-feature-pipeline.md) and
[`workflow-domain-wiki.md`](workflow-domain-wiki.md).
