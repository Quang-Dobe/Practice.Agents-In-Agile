# Practice — Agents In Agile

A reusable "team of AI agents" kit for software projects. Install it once to your
user profile (`~/.claude/`) via `install.ps1` and every repository you open gets a
small crew of specialised AI assistants that walk a feature from a rough idea,
through structured planning, all the way to code — and a second pair of agents that
build and maintain a living "map of the codebase" you can read like a wiki.

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

## The two workflows at a glance

### 1. The Feature Pipeline — "Idea → Plan → Code"

Like a small agile team in a box. Five "roles", each played by a different AI
agent, take turns:

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

---

## How to use this kit in your own project

1. Install the kit to your user profile: from this repo run `pwsh -File ./install.ps1`
   (copies `.claude-user/` → `~/.claude/`). One-time — every repo you open then has the crew.
2. Make sure you are on Windows + PowerShell 7+ (or adapt the hook scripts).
3. Make sure Python is on your PATH — two small hook scripts use it.
4. Open the project in Claude Code.
5. Pick the workflow you want:
   - To plan and build a new feature: run `/feature:new my-feature-name`.
   - To create a wiki of an existing codebase: run `/project:overview <path-to-that-codebase>` first (optional but recommended — gives you a plain-language tour at `docs/narrative/`), then `/project:explore <path-to-that-codebase>` to produce the canonical schema at `docs/domain/`.

That's the whole setup. In the feature pipeline, the rest is the agents asking
you questions and waiting for `APPROVE`; the domain-wiki agents run on their own
and write automatically.

---

## What lives where

- `.claude-user/agents/` — the AI roles (one Markdown file per role).
- `.claude-user/commands/` — the slash commands you type.
- `.claude-user/skills/` — the "rules of the trade" each agent reloads at runtime.
- `.claude-user/templates/` — the document shapes each feature gets.
- `.claude-user/hooks/` — a small Python script that runs on session start (the
  scaffold is stack-agnostic; downstream projects add their own hooks via
  `.claude/settings.json`).
- `.claude/` — a **separate** root-tier LLM-Wiki kit (works across many repos, not
  part of the crew above). See `.claude/README.md` and the `/wiki:*` commands.
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
