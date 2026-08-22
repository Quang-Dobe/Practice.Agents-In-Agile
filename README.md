# Practice — Agents In Agile

A reusable "team of AI agents" kit. Three things you can run:

| | What you get | Setup |
| --- | --- | --- |
| **1. Feature Pipeline** | a crew that takes a feature from rough idea to code | `install.ps1`, once |
| **2. LLM Wiki** | a living map of your repos, in business language | copy one folder |
| **3. PR Review Loop** | review comments become rules the crew obeys next time | `install.ps1`, once |

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

## 2. LLM Wiki — "One living map of all your repos"

Two commands build a wiki of your codebase and keep it fresh. It is written in
business language — "Order", "Customer", "Payment" — not engineering jargon, and
it tracks the code as the code changes. No APPROVE gate; the agents write on
their own.

```
   repo-a/              repo-b/              repo-c/
      │                    │                    │
      └────────────────────┼────────────────────┘
                           │   /wiki:bootstrap   (once, first)
                           │   /wiki:enhance     (after code changes)
                           ▼
          ┌──────────────────────────────────────┐
          │  reads every repo, then summarizes   │
          │  and links back — never copies       │
          └──────┬────────────────────────┬──────┘
                 ▼                        ▼
      each repo's own wiki          the map across repos
      docs/narrative/  plain tour   docs/architecture.md
      docs/domain/     DDD schema   docs/memory/
                 │
                 ▼
          /wiki:ask <question>
   Answered from the wiki first, in a fixed order.
   Raw source is the last resort, and what it learns
   is saved back into that repo's docs/memory/.

  No APPROVE gate — agents write automatically.
  Hand edits survive only inside <!-- human:begin/end --> fences.
```

Commands:

- `/wiki:bootstrap` — once, first. Reads every repo and writes the wiki.
- `/wiki:enhance` — after any code change. Full re-sync of every repo plus the
  cross-repo map. Only rewrites pages that actually differ.
- `/wiki:ask <question>` — answers from the wiki, reads source only as a last
  resort, and saves what it learned.

Where it lives: copy `project/.claude/` from this repo (as `.claude/`) into the
folder that holds your repos. See [Setup](#setup).

It works on one repo too — point it at a folder holding a single repo.

Walkthrough: [`docs/workflow-llm-wiki.md`](docs/workflow-llm-wiki.md)

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

Walkthrough: [`docs/workflow-pr-review-loop.md`](docs/workflow-pr-review-loop.md)

---

## Setup

Windows + PowerShell 7+, Python on PATH.

**For the feature pipeline and the PR review loop** — one-time, from this repo:

```powershell
pwsh -File ./install.ps1     # copies root/.claude/ -> ~/.claude/
```

Then open any repo in Claude Code and run a command from sections 1 and 3.

**For the LLM Wiki** — `install.ps1` does **not** set this one up. Copy it into
the folder that holds your repos, then open *that folder* in Claude Code:

```powershell
# from the folder containing repo-a/, repo-b/, ...
Copy-Item -Recurse .\path-to-this-scaffold\project\.claude .\.claude
```

Local paths only. Both kits refuse a URL.

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
