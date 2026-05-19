# Practice — Agents In Agile

A reusable "team of AI agents" kit for software projects. Drop the `.claude/`
folder into any repository and you get a small crew of specialised AI assistants
that walk a feature from a rough idea, through structured planning, all the way
to code — and a second pair of agents that build and maintain a living
"map of the codebase" you can read like a wiki.

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

A second pair of agents builds and maintains a clean, human-readable wiki of
your codebase under `docs/domain/`. Think of it as the table of contents,
glossary, and "who-talks-to-whom" diagram for the code — written in plain
business language ("Order", "Payment", "Customer") instead of technical jargon.

There are only two commands:

- `/project:explore <path>` — used **once** when you first arrive at a repo.
  The agent reads the code, suggests groupings (called "bounded contexts" —
  basically "areas of the business this code is about"), asks you to APPROVE
  the groupings, then writes the wiki.
- `/project:enhance-wiki [path]` — run this whenever the code has changed.
  The agent figures out **what** changed, asks before adding any new area,
  preserves anything you wrote by hand (as long as it's wrapped in special
  marker comments), and only re-writes pages that actually differ. If
  nothing changed, it says so and exits cleanly.

The wiki you get back has a predictable shape: one folder per business area,
each with its aggregates (the main things — like an Order), events (things
that happen — like "Order placed"), commands (things you can do), services,
repositories, and a glossary of terms used in that area.

Full beginner-friendly walkthrough: [`docs/workflow-domain-wiki.md`](docs/workflow-domain-wiki.md).

---

## How to use this kit in your own project

1. Copy the `.claude/` folder into the root of your project.
2. Make sure you are on Windows + PowerShell 7+ (or adapt the hook scripts).
3. Make sure Python is on your PATH — two small hook scripts use it.
4. Open the project in Claude Code.
5. Pick the workflow you want:
   - To plan and build a new feature: run `/feature:new my-feature-name`.
   - To create a wiki of an existing codebase: run `/project:explore <path-to-that-codebase>`.

That's the whole setup. Everything else is the agents asking you questions
and waiting for `APPROVE`.

---

## What lives where

- `.claude/agents/` — the AI roles (one Markdown file per role).
- `.claude/commands/` — the slash commands you type.
- `.claude/skills/` — the "rules of the trade" each agent reloads at runtime.
- `.claude/templates/` — the document shapes each feature gets.
- `.claude/hooks/` — small Python scripts that run on session start and after
  certain edits (mostly for downstream .NET projects).
- `docs/<feature>/` — everything the feature pipeline produces, one folder
  per feature.
- `docs/domain/` — the living wiki the domain pipeline produces and updates.

---

## Two simple rules you should know

1. **Nothing is done until you type `APPROVE`.** Every step has a gate.
   Until you approve, no checkbox flips and no next step starts.
2. **Hand-written edits inside `docs/domain/` need fences.** If you
   personally edit a generated wiki page, wrap your edits like this
   so they survive the next update:

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
