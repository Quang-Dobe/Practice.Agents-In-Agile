# Practice — Agents In Agile

A reusable "team of AI agents" kit. Install it once to your user profile
(`~/.claude/`) via `install.ps1` and every repository you open gets a crew that
takes a feature from rough idea to code, plus agents that build and maintain a
living wiki of your codebase. An optional third kit works one level above your
repos and joins all their wikis into one.

This repository is the kit itself — no application code lives here.

---

## 1. Feature Pipeline — "Idea → Plan → Code"

Five roles, one APPROVE gate between each. You read what an agent produced;
nothing advances until you type `APPROVE`.

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
│ Business Analyst │  requirement.md (final) + requirement-trace.md (history)
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

Commands:

- `/feature:new <name>` — brainstorm with the Product Owner.
- `/feature:structure <name>` — produce requirement, plans, analysis, test spec.
- `/workflow:step-start <name>` — implement the next step.
- `/workflow:step-approve <name>` — mark the current step done.
- `/workflow:step-handoff <name>` — end-of-day summary for the next session.

If the repo has no wiki yet, Stage 1 adds one extra step: the Architect reads the
code and hands the Business Analyst a short "current behavior" brief, so the
requirement matches how the code works today.

Walkthrough: [`docs/workflow-feature-pipeline.md`](docs/workflow-feature-pipeline.md)

---

## 2. Domain Wiki — "Living map of your codebase"

Three agents keep two trees fresh: `docs/narrative/` (plain-language tour) and
`docs/domain/` (canonical DDD schema). No APPROVE gate — they write automatically.

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

Commands:

- `/project:overview <path>` — once, first. Plain-language tour at `docs/narrative/`.
- `/project:explore <path>` — once. DDD schema at `docs/domain/`.
- `/project:update [path]` — after any code change. Refreshes both trees,
  only rewrites pages that actually differ.

Walkthrough: [`docs/workflow-domain-wiki.md`](docs/workflow-domain-wiki.md)

---

## 3. PR Review Loop — "Never get the same review twice"

You write the review comments down. The kit finds the code behind each one,
shows you a page you can work through, and — after you fix them — turns the
lessons into rules the crew reads on your next feature.

```
   you paste review comments into
   docs/<feature>/pr-review/round-1.md          (free prose, no format)
      │  /pr-review:analyze --feature <f>
      ▼
┌──────────────────────────┐
│  pr-review-analyst       │  splits the prose into findings
│  (read-only)             │  finds the code behind each one
└────────┬─────────────────┘  no verdict — you judge
         ▼
   round-1.pr-review.ledger.md   ← the record. you edit this.
         ▼  rendered from the ledger, never the other way round
   round-1.pr-review.html        ← the page you read

   you fix the code, then set  status: fixed  in the ledger
      │  /pr-review:learn --feature <f>
      ▼
   rule drafts shown  ══ APPROVE ══>  .claude/skills/coding-rules/SKILL.md
                                      .claude/skills/architecture-rules/...
                                      .claude/skills/test-rules/...
         ▼
   next feature: each rule file goes to the role that owns it — architecture
   rules to the Architect, coding rules to the Engineer, test rules to the Tester
```

Commands:

- `/pr-review:analyze --feature <name> [--review <stem>]` — build the ledger and
  the page. Leave `--review` off to do every review file at once.
- `/pr-review:learn --feature <name> [--review <stem>]` — turn your fixed
  findings into rules. Nothing is written until you type `APPROVE`.

Three things to know:

1. **The kit never says a review is right or wrong.** It shows every comment and
   the code behind it. You decide.
2. **The ledger is the record, the page is just a view.** Edit the ledger; the
   page re-renders itself on the next run.
3. **Rules land in your repo, never in the kit.** So one project's style rule
   never leaks into another project.

The page is one file you open in a browser. It holds one card per finding:

- Each card sits at its own `#PR-NN` anchor, so you can link to a single finding.
- A card you still have to act on is **open**. A card you set to `fixed` or
  `rejected` is **collapsed**, so the list shrinks as you work through it.
- Collapsed, a card shows a short title, its concern, its status, and whether
  the code was found. That is enough to skip it or open it.
- Open, it adds the reviewer's exact words, the code site and snippet, the root
  cause, and a suggested fix.
- Hard words get a small chip at the bottom of the card. Hover or tab to it for
  a plain meaning.
- A side rail lists every finding. Buttons expand or collapse them all, or show
  only one status.

---

## 4. LLM Wiki — "One wiki across many repos"

Copy `project/.claude/` (as `.claude/`) to the folder that contains your repos.
It summarizes and links back to the per-repo wikis — never copies content.

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

Commands:

- `/wiki:bootstrap` — first-time setup; fills wiki gaps per repo, writes the root rollup.
- `/wiki:enhance` — full re-sync of every repo's wiki + the cross-repo map.
- `/wiki:ask <question>` — answers from the wiki first; reads source only as a
  last resort and saves what it learned.

The same kit also ships `/present:build <feature>` — renders a feature's planning
artifacts into a browsable HTML dossier at `docs/<feature>/present/`.

Details: [`project/.claude/README.md`](project/.claude/README.md)

---

## Setup

1. From this repo: `pwsh -File ./install.ps1` (copies `root/.claude/` → `~/.claude/`). One-time.
2. Windows + PowerShell 7+, Python on PATH.
3. Open any project in Claude Code and run a command from the pipelines above.

---

## Two rules to remember

1. **Feature pipeline: nothing is done until you type `APPROVE`.**
   (The wiki agents never gate — they write automatically.)
2. **Hand edits to generated wiki pages need fences**, or the next update
   rewrites them:

   ```
   <!-- human:begin -->
   ... your edits ...
   <!-- human:end -->
   ```
