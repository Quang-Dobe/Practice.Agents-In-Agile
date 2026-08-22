# LLM Wiki — One living map of all your repos

This document explains the second workflow this kit ships: a small set of agents
that read your repositories and build one wiki across all of them. The wiki is
written in business language — "Order", "Customer", "Payment" — not engineering
jargon, and it tracks the code as the code changes.

It is written for someone with a light familiarity with Agile and the idea of
"the business side" vs "the technical side". You do not need to know how to code.

---

## The problem it solves

A system spread over six repositories has its knowledge spread over six
repositories. Nobody holds the whole picture. The person who did has left.

You can write a wiki by hand, and then it goes stale — usually within a sprint.

This workflow reads the code, writes the wiki, and refreshes it on demand. It
also answers questions from that wiki, so you do not have to read it end to end
to find one fact.

---

## What you get

The wiki lives **one level above** your repos, in the folder that contains them.

```
<the folder holding your repos>/
├── .claude/                     <- the kit you copied in
├── docs/
│   ├── references.md                 <- how the repos relate. the map.
│   └── memory/*.md                   <- the rollup: one file per topic
├── repo-a/
│   └── docs/
│       ├── narrative/                <- plain-language tour of repo-a
│       ├── domain/                   <- its business model, in detail
│       └── memory/                   <- what got learned about repo-a
├── repo-b/ ...
└── repo-c/ ...
```

Two levels, on purpose:

- **Per repo** — `docs/narrative/` reads like a tour, `docs/domain/` is the
  detailed model behind it. Both are produced for you; you never write them.
- **Across repos** — `docs/references.md` is the map, and `docs/memory/`
  **summarizes and links back** to each repo's own pages. It never copies them.
  One fact, one home.

It works with a single repo too. Point it at a folder holding one repo and you
get the same shape with one child.

---

## Setup

This part is **not** covered by `install.ps1`. Copy the kit into the folder that
holds your repos:

```powershell
# from the folder that contains repo-a/, repo-b/, ...
Copy-Item -Recurse .\path-to-this-scaffold\project\.claude .\.claude
```

Then open **that folder** in Claude Code — not a repo inside it. The commands
work across the repos, so the session has to sit above them.

---

## The three commands

| Command | When | What it does |
| ------- | ---- | ------------ |
| `/wiki:bootstrap` | once, first | Fills the gaps. Any repo with no wiki gets one; a repo that already has one is left alone. Then writes the rollup. |
| `/wiki:enhance` | after code changes | Full re-sync. Refreshes every repo, bootstraps any new one, rewrites the map. |
| `/wiki:ask <question>` | any time | Answers from the wiki. Reads code only as a last resort. |

All three take an optional path. Leave it off and they use the folder you are
in. Local paths only — a URL is refused with one line:

```
Remote URLs are not supported in v1. Pass a local filesystem path.
```

**No APPROVE gate anywhere in this workflow.** The agents write on their own.
That is a deliberate trade: the safety net is that writes are additive, deduped,
and fence-preserving — not a prompt. See *Things worth knowing*.

---

## Phase 1 — First run

```
/wiki:bootstrap
```

It looks at every folder one level down, skipping `docs/` and `.claude/`, and
sorts them into two piles: repos that already have a wiki, and repos that do not.

Then it asks you **two questions**:

1. **Scope** — all repos, or just some? It suggests a first batch.
2. **Speed** — one agent working through them in turn, or one agent per repo at
   the same time?

Pick, and it runs. For each repo with no wiki it produces the tour first, then
the detailed model. Repos that already have a wiki are **skipped** — bootstrap
fills gaps and nothing else. Then it writes the rollup at `docs/memory/`.

It also drafts `repo-layout.md` at the top folder if there is none. That file
declares which folders inside each repo hold real source, so scans skip build
output and vendored code. It is printed for you before it is written.

Bootstrap does **not** write `docs/references.md`. That is `enhance`'s job.

---

## Phase 2 — Keeping it fresh

```
/wiki:enhance
```

One pass, no questions asked. It:

- refreshes every repo that already has a wiki;
- bootstraps any repo that does not;
- updates `repo-layout.md` — adds source folders that showed up, and flags ones
  that have gone stale without deleting them;
- rewrites the rollup at `docs/memory/`;
- rewrites the map at `docs/references.md`.

Only pages whose content actually changed get rewritten. Run it on an unchanged
codebase and it writes nothing.

Use `bootstrap` once and `enhance` from then on. The difference that matters:
bootstrap **skips** a repo that has a wiki, enhance **refreshes** it.

---

## Phase 3 — Asking it things

```
/wiki:ask "where is OrderPaid published?"
```

The answer comes back in the chat. There is no sub-agent and no file written on
a plain question.

First it decides whether the question is about your system at all. If it is not,
it says so and stops — nothing is opened.

If it is, it walks six places **in a fixed order** and stops at the first one
that can answer:

| Order | Where it looks | Why it is this early |
| ----- | -------------- | -------------------- |
| 1 | root `docs/memory/` | already summarized across repos — cheapest answer |
| 2 | `docs/references.md` | the cross-repo map |
| 3 | each repo's `docs/narrative/` | the plain tour |
| 4 | each repo's `docs/domain/` | the detailed model |
| 5 | each repo's `docs/memory/` | what was learned about that repo before |
| 6 | the repo's actual source | last resort, and the only step that costs a code read |

Every answer prints a one-line trace naming the places it opened and where it
stopped, so you can see whether it answered from the wiki or had to read code.

**Only step 6 writes anything.** When it had to read source, it appends what it
learned to that repo's `docs/memory/`, so the next person asking gets the answer
at step 5 instead.

Ask nothing and it refuses with one line:

```
Ask a question, e.g. /wiki:ask "where is OrderPaid published?"
```

---

## Who owns what

| File | Who writes it |
| ---- | ------------- |
| `docs/references.md` | the agent, on every `enhance`. Full rewrite. |
| `<repo>/docs/narrative/`, `<repo>/docs/domain/` | the agent. Fully agent-controlled. |
| root `docs/memory/`, `<repo>/docs/memory/` | **shared.** See below. |
| `repo-layout.md` | the agent drafts and reconciles it; you review it. |

`docs/memory/` is the one shared file set, under a lopsided rule:

- **You are the owner.** Edit, reorganise, delete — anything.
- **The agent may only add.** It creates new topic files and appends new
  entries. It never overwrites or edits a line that is already there.

So your notes in `docs/memory/` are safe by default. Everywhere else, a
regeneration wins — unless you fence it:

```
<!-- human:begin -->
... your words, kept byte for byte ...
<!-- human:end -->
```

Fences work in **every** generated file. Outside them, hand edits are at risk on
the next run.

---

## Things worth knowing

- **Local paths only.** A URL is refused. Pass a folder on your own machine.
- **It never commits.** Everything lands as uncommitted changes in your working
  tree. You read the diff and decide.
- **It never edits your code.** Source is read-only to every agent here.
- **No status file.** Unlike the feature pipeline, this workflow produces no
  `status.md`. It is a tool you run, not a plan you work through.
- **No gate is a real trade.** Nothing pauses for `APPROVE`. What protects you
  instead: writes to `docs/memory/` only ever add, repeated facts are dropped,
  fenced text survives, and unchanged pages are not rewritten at all.
- **Many wikis in one tree.** If one repo turns out to hold several sub-projects,
  each sub-project gets its own wiki, and every folder above them gets its own
  rollup and map. This turns on by itself — you do not ask for it.
- **A repo with only half a wiki** gets a one-line note and is still processed.
  Missing input never stops the run.
- **Under the hood** it drives per-repo agents to write `docs/narrative/` and
  `docs/domain/`. Those are outputs you read, not commands you type. The three
  commands above are the whole interface.
- **The same kit also ships `/present:build <feature>`** — turns a feature's
  planning files into a browsable HTML dossier at `docs/<feature>/present/`.
  Unrelated to the wiki; it just travels in the same folder.

---

## How this differs from the other two workflows

| Aspect | Feature pipeline | LLM Wiki | PR review loop |
| ------ | ---------------- | -------- | -------------- |
| Goal | Plan and build a new feature. | Explain what already exists. | Turn review feedback into rules. |
| Where you run it | inside one repo | in the folder **above** your repos | inside one repo |
| Setup | `install.ps1` | copy `project/.claude/` by hand | `install.ps1` |
| Cadence | Once per feature. | Once, then after each code change. | Once per review round. |
| APPROVE gates | Many — one per stage and per step. | **None.** | One, on `learn` only. |
| Produces a `status.md`? | Yes. | No. | No. |
| Writes your source? | Yes — that is the point. | Never. | Never. |

All three can live in the same repository. They never write each other's files.

---

For the other two walkthroughs, see
[`workflow-feature-pipeline.md`](workflow-feature-pipeline.md) and
[`workflow-pr-review-loop.md`](workflow-pr-review-loop.md).
