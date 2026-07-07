# Practice — Agents In Agile

A reusable "team of AI agents" kit for software projects. Install it once to your
user profile (`~/.claude/`) via `install.ps1` and every repository you open gets a
small crew of specialised AI assistants that walk a feature from a rough idea,
through structured planning, all the way to code — and a second group of agents that
build and maintain a living "map of the codebase" you can read like a wiki.
A third, optional kit (`project/.claude/`) sits one level **above** your repositories and
turns all those per-repo maps into one cross-repo "LLM Wiki" you can ask questions.

This repository is the kit itself. It does not contain any application code.

---

## Who this is for

- **Product folks** who want their fuzzy idea turned into a clear plan before
  any code is written.
- **Engineers** who want each step of a feature to be reviewed and approved
  before the next one begins — no surprises, no runaway changes.
- **Newcomers to a codebase** who want a friendly, up-to-date "domain wiki"
  that explains what the code is actually about, instead of guessing from file
  names.

You do not need to be a developer to read this README. The two linked workflow
guides at the bottom are also written for non-technical readers.

---

## The three workflows at a glance

### 1. The Feature Pipeline — "Idea → Plan → Code"

Like a small agile team in a box. Five "roles", each played by a different AI
agent, take turns:

```
   raw idea
      │  /feature:new
      ▼
┌──────────────────┐
│  Product Owner   │  frames the why / what (writes nothing)
└────────┬─────────┘
         ║ APPROVE
         ▼
┌──────────────────┐
│ Business Analyst │  writes requirement.md
└────────┬─────────┘
         ║ APPROVE
         ▼
┌──────────────────┐    ┌──────────────────┐
│    Architect     │    │      Tester      │  (in parallel)
│ overview-plan.md │    │     test.md      │
│ + analyzed.md    │    │ (e2e spec)       │
└────────┬─────────┘    └────────┬─────────┘
         ║ APPROVE               │
         ▼                       │
┌──────────────────┐             │
│ Software Engineer│             │
│ plan.md + code,  │             │
│ step by step     │             │
└────────┬─────────┘             │
         │  /workflow:step-start │
         ▼                       │
    ┌──────────┐  step-approve   │
    │  step OK │◄────────────────┘
    └────┬─────┘   (loop each step; the final step
         │          runs the E2E tests from test.md)
         ▼
   all steps done + E2E green = approved code

   ║ = APPROVE gate (you type APPROVE; nothing advances until then)
```



| Role               | What they do                                                                |
| ------------------ | --------------------------------------------------------------------------- |
| Product Owner      | Asks the why and the what. Frames the idea. Writes nothing.                 |
| Business Analyst   | Pressure-tests the framing. Writes the formal requirement.                  |
| Architect          | Decides the shape of the solution. Writes the high-level plan and analysis. |
| Software Engineer  | Writes the step-by-step mechanical plan, then implements each step.         |
| Tester             | Drafts test cases before code is written, then verifies at the end.         |

Between every role there is one **APPROVE gate** — you read what the agent
produced, and only when you type `APPROVE` does the next role start. Nothing
sneaks past you.

**Brownfield note.** If the repo has no domain wiki yet (`docs/domain/` and
`docs/narrative/` both missing), Stage 1 adds a quick step: the Architect reads
the existing code and hands the Business Analyst a short "current behavior" brief
so the requirement is grounded in how the code works today. The Business Analyst
never reads code itself — it asks the Architect (one bounded round) if it needs
more. The brief is saved into `requirement.md`. If a wiki already exists, this
step is skipped.

You drive it with these slash commands:

- `/feature:new <name>` — start a fresh brainstorm with the Product Owner.
- `/feature:structure <name>` — turn the brainstorm into requirement, plan,
  analysis, and detailed plan files.
- `/workflow:step-start <name>` — start the next implementation step.
- `/workflow:step-approve <name>` — mark the current step as done.
- `/workflow:step-handoff <name>` — write a short summary when you stop
  for the day, so the next session picks up cleanly.

Full beginner-friendly walkthrough: [`docs/workflow-feature-pipeline.md`](docs/workflow-feature-pipeline.md).

### 2. The Domain Wiki Pipeline — "Living map of your codebase"

A trio of agents builds and maintains a clean, human-readable map of your codebase. There are two trees: `docs/narrative/` (the friendly tour — one page about the repo as a whole, then one walkthrough per "area of the business") and `docs/domain/` (the canonical DDD schema — bounded contexts, aggregates, events, commands, repositories, services, glossary, context map). Read narrative first when you arrive at a new codebase; drill into the schema when you need precise structure.

Think of the narrative as a friendly tour with diagrams and plain-words intros, and the schema as the table of contents, glossary, and "who-talks-to-whom" diagram for the code — both written in plain business language ("Order", "Payment", "Customer") instead of technical jargon.

```
                     your codebase
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
/project:overview  /project:explore    /project:update
     (once)             (once)          (every change)
        │                  │                  │
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│   project-    │  │   project-    │  │   project-    │
│   overview    │  │   explorer    │  │    update     │
│     agent     │  │     agent     │  │     agent     │
└───────┬───────┘  └───────┬───────┘  └───────┬───────┘
        │                  │                  │  diff-aware,
        ▼                  ▼                  │  fence-safe
╔═══════════════╗   ╔══════════════╗          │
║docs/narrative/║··►║ docs/domain/ ║          │
║  plain tour   ║   ║  DDD schema  ║          │
╚═══════▲═══════╝   ╚══════▲═══════╝          │
        │                  │                  │
        └──────────────────┴──────────────────┘
            update refreshes both trees

  ··► = /project:explore reads the narrative as a soft hint
  No APPROVE gate — agents write automatically.
  Hand edits survive only inside <!-- human:begin/end --> fences.
```



There are only two commands:

- `/project:overview <path>` — used **once** when you first arrive at a repo, **before** `/project:explore`. The agent reads the code, detects the "areas of the business" (bounded contexts) just like `/project:explore` does, prints them for the audit trail, then writes a plain-language tour at `docs/narrative/` automatically (no APPROVE gate) — one short `architecture.md` for the whole repo, one `walkthrough.md` per area with a diagram, a 3-paragraph intro, and a per-endpoint / per-worker drill-down. Optional but recommended for non-technical readers.
- `/project:explore <path>` — used **once** when you first arrive at a repo.
  The agent reads the code, suggests groupings (called "bounded contexts" —
  basically "areas of the business this code is about"), prints the groupings
  for the audit trail, then writes the wiki automatically (no APPROVE gate). If you ran `/project:overview` first, it also reads that narrative as a hint to better order and describe the areas; without it, `/project:explore` works exactly as before.
- `/project:update [path]` — run this whenever the code has changed.
  The agent figures out **what** changed and auto-creates any new area after
  printing the candidate report (no APPROVE gate),
  preserves anything you wrote by hand (as long as it's wrapped in special
  marker comments), and only re-writes pages that actually differ. If
  nothing changed, it says so and exits cleanly.

The two trees have predictable shapes. `docs/narrative/` carries one `architecture.md` (overview, file structure, dependencies, endpoints, workers) plus one `<bc>/walkthrough.md` per area (Mermaid sequence diagram + 3-paragraph intro + per-endpoint / per-worker drill-down). `docs/domain/` carries one folder per business area, each with its aggregates (the main things — like an Order), events (things that happen — like "Order placed"), commands (things you can do), services, repositories, and a glossary of terms used in that area.

Full beginner-friendly walkthrough: [`docs/workflow-domain-wiki.md`](docs/workflow-domain-wiki.md).

### 3. The LLM Wiki — "one wiki across many repos"

The two workflows above live **inside** a single repository. The third one lives
**one level above** them: copy the `project/.claude/` folder (as `.claude/`) to the parent directory that
contains all your sibling repos, and three `/wiki:*` commands build a cross-repo
knowledge base there. It never copies content — it **summarizes and links back**
to the per-repo wikis the domain pipeline already produced.

```
    repo-a/docs/              repo-b/docs/              repo-c/docs/
 narrative + domain        narrative + domain        narrative + domain
          │                         │                         │
          └─────────────────────────┼─────────────────────────┘
                                    │   /wiki:bootstrap  (first time)
                                    │   /wiki:enhance    (full re-sync)
                                    ▼
                   ┌─────────────────────────────────┐
                   │  summarize + link (never copy)  │
                   └──────┬───────────────────┬──────┘
                          ▼                   ▼
                    docs/memory/    docs/architecture.md
                    (root rollup)     (cross-repo map)
                          │
                          ▼
                 /wiki:ask <question>
        answered inline from the wiki, in a fixed
        retrieval order; raw repo code is read only
        as a last resort, and what was learned is
        saved back to that repo's docs/memory/

  No APPROVE gate — same fence rule as the domain wiki.
```

The three commands:

- `/wiki:bootstrap` — first-time setup. Asks two short questions (which repos,
  run now or in background), fills any gaps (it calls `/project:overview` and
  `/project:explore` for repos that have no wiki yet), then writes the root
  rollup under `docs/memory/`.
- `/wiki:enhance` — full re-sync, no questions asked. Refreshes every repo's
  wiki (via `/project:update`), re-rolls the root `docs/memory/`, and regenerates
  the cross-repo `docs/architecture.md`.
- `/wiki:ask <question>` — ask anything about your codebases. It answers from
  the wiki first, in a fixed and auditable order; only when the wiki can't answer
  does it read raw source — and then it appends what it learned to that repo's
  `docs/memory/` so the next ask is faster.

`docs/memory/` is **co-owned**: you may edit, curate, and delete freely; the
agent only ever appends — it never rewrites your text.

Full details: [`project/.claude/README.md`](project/.claude/README.md).

### 4. The Present Dossier — "browsable HTML view of a feature"

Once a feature has planning artifacts, `/present:build <feature>` (part of the `project/.claude/` kit) renders them into a browsable HTML dossier at `docs/<feature>/present/` — one tab per artifact (Introduction, Workflow, E2E Test, Analyzed, Code Structure), with diagrams drawn for the Workflow and Code Structure tabs. It grounds on whichever wiki tree is present (per-repo `docs/domain`/`docs/narrative`, or the root `docs/architecture.md`/`docs/memory`) and is gate-free and idempotent. Details: [`project/.claude/README.md`](project/.claude/README.md#presentbuild--feature-dossier).

---

## How to use this kit in your own project

1. Install the kit to your user profile: from this repo run `pwsh -File ./install.ps1`
   (copies `root/.claude/` → `~/.claude/`). One-time — every repo you open then has the crew.
2. Make sure you are on Windows + PowerShell 7+ (or adapt the hook scripts).
3. Make sure Python is on your PATH — a small hook script uses it.
4. Open the project in Claude Code.
5. Pick the workflow you want:
   - To plan and build a new feature: run `/feature:new my-feature-name`.
   - To create a wiki of an existing codebase: run `/project:overview <path-to-that-codebase>` first (optional but recommended — gives you a plain-language tour at `docs/narrative/`), then `/project:explore <path-to-that-codebase>` to produce the canonical schema at `docs/domain/`.
   - To build one wiki across many repos: copy `project/.claude/` (as `.claude/`) to the
     folder that contains your repos, then run `/wiki:bootstrap` there (see
     `project/.claude/README.md`).

That's the whole setup. In the feature pipeline, the rest is the agents asking
you questions and waiting for `APPROVE`; the domain-wiki agents run on their own
and write automatically.

---

## What lives where

- `root/.claude/agents/` — the AI roles (one Markdown file per role).
- `root/.claude/commands/` — the slash commands you type.
- `root/.claude/skills/` — the "rules of the trade" each agent reloads at runtime. Includes `root/.claude/skills/repo-layout/SKILL.md`, the cross-cutting scan-scope contract; pair it with an opt-in `repo-layout.md` at the wiki scan root to declare exactly which folders the wiki agents should walk.
- `root/.claude/templates/` — the document shapes each feature gets.
- `root/.claude/hooks/` — a small Python script that runs on session start (the
  scaffold is stack-agnostic; downstream projects add their own hooks via
  their own `.claude/settings.json`).
- `project/.claude/` — a **separate** project-tier LLM-Wiki kit (works across many repos, not
  part of the crew above). See `project/.claude/README.md` and the `/wiki:*` commands. Also
  ships `/present:build`, which renders a feature's dossier at `docs/<feature>/present/`.
- `docs/<feature>/` — everything the feature pipeline produces, one folder
  per feature.
- `docs/domain/` — the living wiki the domain pipeline produces and updates.
- `docs/narrative/` — the plain-language tour the new narrative pipeline produces. Optional; only appears if you run `/project:overview`.

---

## Two simple rules you should know

1. **In the feature pipeline, nothing is done until you type `APPROVE`** — every
   planning stage and step has a gate. Until you approve, no checkbox flips and no
   next step starts. (The domain-wiki agents are fully agent-driven and do not gate.)
2. **Hand-written edits inside `docs/domain/` and `docs/narrative/` need fences.** If you personally edit a generated wiki page (either tree), wrap your edits like this so they survive the next update:

   ```
   <!-- human:begin -->
   ... your edits ...
   <!-- human:end -->
   ```

   Anything outside the fence may be re-written by the agent.

---

## Workflow deep-dives

The two documents below walk through each workflow step-by-step, in everyday
language. Read them in order if you are new:

- [Feature Pipeline — Idea to Code, step by step](docs/workflow-feature-pipeline.md)
- [Domain Wiki Pipeline — Build and maintain a living map of your codebase](docs/workflow-domain-wiki.md)
- [LLM Wiki — One wiki across many repos](project/.claude/README.md) (reference-style, written for operators)
