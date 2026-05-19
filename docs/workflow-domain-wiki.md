# Domain Wiki Pipeline — Build and maintain a living map of your codebase

This document explains the second workflow this kit ships: two AI agents that
build, and then keep up-to-date, a friendly map of a codebase under
`docs/domain/`. The map is written in business language — "Order",
"Customer", "Payment" — not engineering jargon, and it stays in sync with
the code as the code evolves.

It is written for someone with a light familiarity with Agile and the idea
of "the business side" vs "the technical side". You do not need to know how
to code.

---

## What you get

After running this workflow, a fresh `docs/domain/` folder appears in your
working directory. Inside, you get a predictable shape:

```
docs/domain/
├── context-map.md            ← The "areas of the business" overview
├── glossary.md               ← Terms used across the whole codebase
└── <area-of-business>/       ← One folder per area
    ├── glossary.md           ← Terms used only inside this area
    ├── aggregates/           ← The main "things" (e.g. Order, Customer)
    │   └── <thing>.md
    ├── events.md             ← Things that happen (e.g. "Order placed")
    ├── commands.md           ← Things you can ask the system to do
    ├── repositories.md       ← Where data is fetched / stored
    └── services.md           ← Helper behaviours that don't belong to one thing
```

Each page links back to the actual code with a clickable `file:line` reference,
so when something in the wiki looks wrong, you can jump straight to the place
in the source.

The whole structure follows a classic way of organising software thinking
called **Domain-Driven Design (DDD)**, but you do not need to know DDD to
read or use the output. The key word to remember is **"bounded context"** —
that's the formal name for "an area of the business". You'll see this term
in the agent's questions.

---

## The two agents

| Agent                    | Job                                                      | When to run                          |
| ------------------------ | -------------------------------------------------------- | ------------------------------------ |
| **project-explorer**     | Bootstrap the wiki from scratch.                         | **Once**, when starting on a repo.   |
| **project-wiki-enhancer** | Update the wiki to reflect new code changes.            | Whenever the code has changed.       |

They are siblings: one builds the wiki for the first time, the other keeps
it in sync. They politely refuse to do each other's job:

- `project-explorer` refuses if `docs/domain/` already has content.
- `project-wiki-enhancer` refuses if `docs/domain/` is missing or empty.

---

## Step 1 — Bootstrap with `/project:explore`

The very first time, you run:

```
/project:explore <path-to-the-codebase> [branch-name]
```

- `<path>` is a folder on your computer. The agent only reads local paths —
  it never clones from the internet.
- `[branch-name]` is optional and is just recorded into the wiki's metadata.
  You are responsible for checking out the branch yourself before running
  the command.

Here is what happens, in plain English:

### 1. Safety check

The agent first peeks inside `docs/domain/` of your current working directory.
If there is already content there, it refuses with a polite message that
points you at `/project:enhance-wiki`. This is intentional — bootstrap is a
one-shot operation, and you don't want to accidentally wipe a wiki you've
already built up.

### 2. Read the code

The agent walks through the target codebase and looks for the building
blocks of a domain model — the "things" (called **aggregates**, like Order
or Customer), the "things that happen" (called **events**), the "things you
can do" (called **commands**), the data accessors (called **repositories**),
and the helper behaviours (called **services**). Test code, build output,
and auto-generated files are ignored.

### 3. Propose the business areas

The agent groups what it found into candidate **bounded contexts** — its
best guess at how the code is divided into business areas. It then prints
the candidates back to you, showing:

- The name it suggests for each area.
- Why it picked that name (which folders or namespaces fed into it).
- The main "things" detected inside each area, each with a `file:line`
  citation so you can verify.
- A list of any disagreements it spotted inside the code (where two parts
  of the codebase contradict each other on the same concept).

If the codebase is very small, the agent automatically falls back to a
single area called `module-map` instead of forcing made-up subdivisions.
It tells you when this fallback is active.

### 4. APPROVE gate (this is the important one)

Nothing is written yet. The agent prints exactly this prompt:

```
Type APPROVE to write docs/domain/, or describe edits.
```

You have three sensible responses:

- **Type `APPROVE`** (capital letters, exactly) — the agent writes the wiki.
- **Type edit instructions** — e.g. "rename `Billing` to `Payments`",
  "merge `Orders` and `Cart`", "drop `Legacy`". The agent re-prints the
  candidate list with your edits applied, then re-asks for APPROVE.
- **Anything else** (lowercase `approve`, `ok`, `yes`, etc.) — treated as
  "please clarify", and the agent re-asks. This is on purpose — the agent
  is very strict to prevent accidental approvals.

The edit loop has no round limit. You can iterate as many times as you want.

### 5. Write the wiki

After APPROVE, the agent writes the full tree under `docs/domain/`. Every
page is stamped at the top with a small block of metadata: where the
codebase was, which branch, the timestamp, and which version of the
agent's rule-book produced the file. This metadata is what makes the next
workflow possible.

---

## Step 2 — Keep it in sync with `/project:enhance-wiki`

Once the bootstrap is done, every time the code changes you run:

```
/project:enhance-wiki [path]
```

`[path]` is optional — if you leave it out, the current working directory
is used.

Here is what happens, in plain English:

### 1. Safety check (in reverse)

The agent checks `docs/domain/`. If it is missing or empty, it refuses with
a message pointing you at `/project:explore`. The enhancer is not a
bootstrapper — it only updates what is already there.

### 2. Pick a smart vs safe strategy

The agent looks at the metadata stamped on the existing wiki pages and
decides between two strategies:

- **Fast path (git)** — when the codebase is a git repository and the
  stamp on the wiki is still reachable from the current code state, the
  agent uses git to ask exactly which files changed. Quick.
- **Safe path (full walk)** — otherwise (no git, missing stamp, or the
  stamp was overwritten by a force-push), the agent walks the whole
  codebase and compares the existing wiki page-by-page against what the
  current code says it should be. Slower, but always correct.

You don't have to do anything — the agent picks. It also prints which path
it picked so you can audit it.

### 3. Classify changes

Every changed file is placed into one of three buckets:

| Bucket               | Meaning                                                          |
| -------------------- | ---------------------------------------------------------------- |
| `BC-affecting`       | The file belongs to an existing business area. The agent will refresh that area's pages. |
| `infra — no BC impact` | The file is build output, tests, generated code, or otherwise not part of the business model. Ignored. |
| `new-namespace`      | The file looks like the start of a **new** business area the agent has never seen before. |

### 4. APPROVE gate (only if there are new business areas)

If — and only if — the third bucket has any files, the agent uses the
**same APPROVE gate** as the bootstrap. It prints the candidate new areas
and asks you to APPROVE before creating any new folders. The check is
strict and exact-case, just like before.

If no new areas are needed, this step is skipped silently.

### 5. Note any disappeared areas (log-only)

If a business area used to exist but the underlying code has been removed
or renamed away, the agent **does not delete** the existing folder. Your
notes and history are preserved. Instead, the agent writes a single bullet
into `context-map.md` saying "namespace no longer present". You decide
later whether to clean it up by hand.

### 6. Regenerate, then preserve your hand-written notes

The agent regenerates each affected page in memory. Before writing, it
looks at the existing file on disk for any "fenced human-edit zone" —
content you wrote yourself between two special marker comments:

```
<!-- human:begin -->
... your hand-written notes ...
<!-- human:end -->
```

Anything between those markers is preserved **byte-for-byte** when the page
is rewritten. Anything outside the markers is replaced by the freshly
regenerated content. Without fences, your edits will be overwritten — that
is the rule.

### 7. Write only what actually changed

This is the nice part. The agent compares the freshly generated content
(with your fenced edits spliced back in) against what is already on disk,
**byte for byte**. It writes a page only if the bytes are different. If
nothing changed, nothing is written.

When the whole run produced zero writes, the agent prints exactly one
line:

```
No changes detected. 0 files written.
```

…and exits. That's it. This makes it safe to run the command on every
commit, even when nothing relevant happened — you won't get noise in your
git history.

Otherwise, it prints a small summary: how many pages it wrote, how many
new areas were created, how many disappeared areas were logged, and which
strategy (fast vs safe) it used.

---

## A typical day with the wiki

```
Monday morning, fresh clone of a repo:
    /project:explore C:\src\my-company-repo
        → review the suggested business areas
        → describe a few edits ("merge X and Y", "rename Z")
        → type APPROVE
        → wiki appears under docs/domain/

Wednesday afternoon, after some feature work:
    /project:enhance-wiki
        → "1 file written. Diff strategy: git fast path."

Friday, after a teammate added a whole new business area:
    /project:enhance-wiki
        → agent surfaces the new area, asks for APPROVE
        → type APPROVE
        → new folder appears with all its pages

Tuesday next week, you re-run on an unchanged codebase:
    /project:enhance-wiki
        → "No changes detected. 0 files written."
```

---

## Things worth knowing

- **Only local paths.** Both commands refuse remote URLs in v1. Pass a path
  on your own machine.
- **The agents are read-only against the target codebase.** They never
  modify the code they explore. They only write under `docs/domain/` of
  the working directory.
- **No commits.** Like the feature pipeline, these agents never run git
  commit on your behalf. After the wiki is written or updated, you decide
  when to commit.
- **No status files.** Unlike the feature pipeline, the domain-wiki agents
  do not produce a `status.md`. They are runtime tools, not planning
  artefacts.
- **APPROVE is exact-case.** Everywhere this kit asks for `APPROVE`, the
  match is strict and case-sensitive. `approve`, `Approve`, `ok`, `yes`,
  `sure` — none of these count. This is deliberate — it prevents
  accidental approvals when you're skimming.
- **Wrap your edits in fences.** If you personally improve a generated
  page, wrap your improvements in `<!-- human:begin -->` / `<!-- human:end -->`.
  Unfenced edits are at risk every time the enhancer runs.

---

## How this differs from the feature pipeline

| Aspect              | Feature pipeline                          | Domain wiki pipeline                      |
| ------------------- | ----------------------------------------- | ----------------------------------------- |
| Goal                | Plan and build a new feature.             | Explain an existing codebase.             |
| Output location     | `docs/<feature>/`                         | `docs/domain/`                            |
| Cadence             | Once per feature.                         | Bootstrap once, then on every code change. |
| Produces a `status.md`? | Yes.                                  | No.                                       |
| Number of roles     | Five (PO, BA, Architect, SE, Tester).     | Two (project-explorer, project-wiki-enhancer). |
| APPROVE gates       | Many — one per planning stage and per step. | Up to one per run (only if new areas are detected). |

The two pipelines can absolutely live side-by-side in the same repository.
They never touch each other's folders.

For the feature pipeline walkthrough, see
[`workflow-feature-pipeline.md`](workflow-feature-pipeline.md).
