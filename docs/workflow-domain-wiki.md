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
- `project-wiki-enhancer` refuses to bootstrap; when both `docs/narrative/` and `docs/domain/` are missing, the command layer refuses before the agent is spawned (see `## Step 2` sub-section 1). When exactly one tree is missing, the present-tree pass still runs and a one-line advisory points at the bootstrap command for the missing tree.

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

The enhancer is not a bootstrapper — it only updates what is already there.
Before doing anything else, the command checks which of the two trees
(`docs/narrative/` and `docs/domain/`) actually exist on disk. There are
three cases:

- **Both trees present** — the happy path. The command proceeds into the
  dual-pass refresh described in the next sub-sections.
- **Exactly one tree missing** — the command prints a one-line advisory
  pointing you at the right bootstrap command for the missing side, then
  proceeds with the pass for the tree that *is* present. You get a useful
  partial refresh and a clear hint about how to enable the other pass.
- **Both trees missing** — terminal refusal at the command layer (no agent
  is spawned). The command exits immediately with this message:

  ```
  Both docs/narrative/ and docs/domain/ are missing. Run /project:overview to bootstrap docs/narrative/, then /project:explore to bootstrap docs/domain/, then /project:enhance-wiki to update.
  ```

### 2. Two passes, one command

When both trees are present, `/project:enhance-wiki` runs **two passes in a
single command invocation**, in a fixed order:

1. The **narrative pass** refreshes `docs/narrative/` first.
2. The **domain pass** refreshes `docs/domain/` second.

The order is intentional and is not configurable — there are no
`--narrative-only` or `--domain-only` flags. The reason for narrative-first
is that the domain pass reads `docs/narrative/<bc>/walkthrough.md` as soft
input via the `project-explorer` skill's existing contract; running domain
first would force a second invocation to pick up any cross-tree fix-ups,
defeating the point of a single-command refresh.

### 3. Pick a smart vs safe strategy (per pass)

Each pass picks its own diff strategy independently against its own tree.
The agent looks at the metadata stamped on the existing wiki pages and
decides between:

- **Fast path (git)** — when the codebase is a git repository and the
  stamp on the wiki is still reachable from the current code state, the
  agent uses git to ask exactly which files changed. Quick.
- **Safe path (full walk)** — otherwise (no git, missing stamp, or the
  stamp was overwritten by a force-push), the agent walks the whole
  codebase and compares the existing wiki page-by-page against what the
  current code says it should be. Slower, but always correct.

You don't have to do anything — each pass picks its own strategy and prints
which path it picked so you can audit both decisions.

### 4. Classify changes (per pass)

In each pass, every changed file is placed into one of three buckets:

| Bucket               | Meaning                                                          |
| -------------------- | ---------------------------------------------------------------- |
| `BC-affecting`       | The file belongs to an existing business area. The agent will refresh that area's pages. |
| `infra — no BC impact` | The file is build output, tests, generated code, or otherwise not part of the business model. Ignored. |
| `new-namespace`      | The file looks like the start of a **new** business area the agent has never seen before. |

The same three-bucket classification runs once per pass, against that
pass's own tree.

### 5. APPROVE gates — up to two per run

Each pass has its **own auto-skipping APPROVE gate**. If — and only if —
that pass's third bucket has any files, the agent prints the candidate new
areas for that tree and asks you to APPROVE before creating any new
folders. The check is strict and exact-case, just like the bootstrap.

If no new areas are needed in a pass, that pass's gate is skipped silently.
Both buckets empty → zero prompts.

### 6. `--bypass-approval` for low-friction runs

For unattended scenarios (CI, post-merge hooks, batch refresh), you can
opt into `--bypass-approval`:

```
/project:enhance-wiki [path] --bypass-approval
```

This flag auto-approves non-critical changes so the run does not pause for
interactive input. **Four critical categories always escalate** even with
the flag set (named, not restated here — see the `project-wiki-enhancer`
skill's `## --bypass-approval semantics` for the canonical list): new BC,
BC renamed, BC removed, and any write that would land inside a fenced
human-edit block.

When a critical category fires under `--bypass-approval`, the run **exits 1
(not pause) with a locked diagnostic message**. The diagnostic itself lives
verbatim in the skill file; the walkthrough does not restate it. The
operator's remediation is to re-invoke `/project:enhance-wiki` *without*
the flag, which gives you the normal interactive APPROVE gate.

### 7. Note any disappeared areas (per pass, log-only)

If a business area used to exist but the underlying code has been removed
or renamed away, neither pass **deletes** the existing folder. Your notes
and history are preserved. Instead, each pass writes a single bullet into
its own context file:

- The narrative pass appends to `docs/narrative/architecture.md` under
  `## Skipped candidates`.
- The domain pass appends to `docs/domain/context-map.md` under
  `## Skipped candidates`.

You decide later whether to clean either side up by hand.

### 8. Regenerate, then preserve your hand-written notes (per pass)

Each pass regenerates its affected pages in memory. Before writing, the
agent looks at the existing file on disk for any "fenced human-edit zone" —
content you wrote yourself between two special marker comments:

```
<!-- human:begin -->
... your hand-written notes ...
<!-- human:end -->
```

Anything between those markers is preserved **byte-for-byte** when the page
is rewritten. Anything outside the markers is replaced by the freshly
regenerated content. Without fences, your edits will be overwritten — that
is the rule. The fence convention is now active in **both trees**: it has
always been load-bearing in `docs/domain/`, and as of this command it is
load-bearing in `docs/narrative/` too.

### 9. Write only what actually changed (per pass + cross-pass exit)

This is the nice part. In each pass, the agent compares the freshly
generated content (with your fenced edits spliced back in) against what is
already on disk, **byte for byte**. It writes a page only if the bytes are
different. If nothing changed, nothing is written.

When the **whole run** (both passes aggregated together) produced zero
writes, the agent prints exactly one line:

```
No changes detected. 0 files written.
```

…and exits. The zero-write exit message is emitted **once per run** as a
cross-pass aggregation, not once per pass. This makes it safe to run the
command on every commit, even when nothing relevant happened — you won't
get noise in your git history.

Otherwise, it prints a small summary: how many pages were written across
both passes, how many new areas were created, how many disappeared areas
were logged, and which strategy (fast vs safe) each pass used.

### 10. Reserved doctor coupling

**Reserved coupling — /project:doctor.** Once `/project:doctor` (the
cross-tree invariant checker) ships, `/project:enhance-wiki` will invoke it
as a default last step whenever any mismatch / conflict / out-of-date
signal is detected during the enhance run. No-op today; the future doctor
feature inherits this contract.

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
  page (in either `docs/domain/` or `docs/narrative/`), wrap your
  improvements in `<!-- human:begin -->` / `<!-- human:end -->`. Unfenced
  edits are at risk every time the enhancer runs. Fences are now
  load-bearing in BOTH trees.

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
