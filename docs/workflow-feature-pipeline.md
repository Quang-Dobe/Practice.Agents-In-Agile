# Feature Pipeline — Idea to Code, step by step

This document explains how a new feature travels from a rough sentence in your
head all the way to working code, using the five AI "roles" this kit provides.

It is written for a non-engineer: read what each role produces and type
`APPROVE` when you are happy with it.

---

## The cast

Think of the pipeline as a tiny agile team. Each role only has one job, and
no role steps on another role's toes.

| Order | Role                  | What they own                                                | Writes files? |
| ----- | --------------------- | ------------------------------------------------------------ | ------------- |
| 1     | **Product Owner**     | Framing the idea: what & why, in/out of scope, assumptions.  | No.           |
| 2     | **Business Analyst**  | Turning the framing into a structured requirement document.  | Yes.          |
| 3     | **Architect (round 1)** | The high-level plan — what steps will get us there.        | Yes.          |
| 4     | **Architect (round 2)** | The analysis: why this approach, plus a per-step Severity table. | Yes.          |
| 5     | **Software Engineer** | The detailed step-by-step plan, then the actual code; also owns test execution and the final E2E validation gate. | Yes.          |
| 6     | **Tester**            | Authors `<feature>.test.md` at stage-2-overview (planning only, no runtime role). | Yes (`test.md`). |

The same agent plays Architect twice — once for the high-level plan and once
for the deeper analysis. This is intentional: the high-level plan is approved
first, so the analysis can lean on a stable set of steps.

---

## The big picture

```
You jot a rough idea  →  PO frames it   →  BA writes requirement  →
   Architect writes plan + Tester writes test.md  →  Architect writes analysis  →
      Engineer writes detailed plan  →
         [for each step: Engineer writes code + unit tests → you APPROVE]
            →  final step: Engineer authors e2e tests from test.md and runs them
```

Between every arrow there is a moment where you read what was produced and
either type `APPROVE` or say "no, change X". Nothing moves forward without
your sign-off.

---

## Phase 1 — Brainstorming (no files yet)

You start by writing a single rough requirement file at
`docs/<feature-name>/<feature-name>.requirement.md`. It can be one paragraph
or one page — whatever you have. Use kebab-case for the feature name (for
example, `payments-export`, not `Payments Export`).

Then run:

```
/feature:new payments-export
```

The **Product Owner** agent reads your rough requirement and asks you 3-5
focused questions. The questions cover:

- Scope (what is in, what is out).
- Success criteria (what does "done" look like for the user).
- Risks and unknowns.
- Assumptions the PO is making that **you should disagree with if needed**.

You answer in chat. The PO produces a short, structured brainstorm summary.
It does not touch any file — it just hands you a clean piece of "intent" for
the next role.

---

## Phase 2 — Structuring (four sub-stages, four APPROVE gates)

Next you run:

```
/feature:structure payments-export
```

This is a four-stage process. Each stage produces one file and waits for you
to type `APPROVE` before the next stage starts. If you close your laptop
mid-way, the next session detects which stage you were on and resumes.

### Stage 1 — Business Analyst writes the requirement

The **Business Analyst** agent reads the rough requirement, the PO's
brainstorm summary, and any architectural notes that already exist. It
**pressure-tests** the PO's assumptions — meaning it openly disagrees,
amends, or asks more questions before writing anything.

It then writes `docs/<feature>/<feature>.requirement.md`, replacing your
rough file with a structured one. The new file contains:

- A title and rules section.
- A short list: the three planning artefacts that come next.
- Your original rough prose, preserved verbatim as an appendix.
- A "Challenges to PO framing" appendix — a table of every assumption the
  PO made, what stance BA took (agree / disagree / amend / defer), and what
  you actually decided.

You review it, type `APPROVE`, and move on.

### Stage 2 (overview) — Architect writes the high-level plan, Tester writes the test spec

This stage runs in parallel. The **Architect** agent writes
`<feature>.overview-plan.md` — the "big steps" document. It defines `Step A`,
`Step B`, `Step C`, etc. — the canonical list of implementation steps. From
this point on, those step IDs do not change.

In parallel, the **Tester** agent writes `<feature>.test.md` — a black-box,
requirement-keyed acceptance spec (Given/When/Then) derived from the
requirement. The Tester has no runtime role; this file is its only output.

One combined `APPROVE` covers both. Read them, sanity-check that the steps
cover the requirement, type `APPROVE`.

### Stage 2 (analysis) — Architect writes the analysis

The same Architect agent is invoked again. It writes
`<feature>.analyzed.md` — the "why this approach" document. It explains the
trade-offs, the risks, the decisions, and any project-specific overrides to
the default engineering rules.

This file also carries a per-step **Severity table** (rule R7) with one row
per step from the overview plan:

| Step ID | Severity |
| ------- | -------- |
| A       | …        |

Each step's severity is what later drives `/workflow:step-start
--bypass-approval`: low-severity steps can be auto-approved, higher-severity
steps still require your explicit sign-off.

Read it, type `APPROVE`.

### Stage 2 (plan) — Software Engineer writes the detailed plan

The **Software Engineer** agent writes `<feature>.plan.md`. This is the
mechanical, file-by-file, function-by-function blueprint. One section per
step from the overview plan, listing the files to create or change and the
"done-when" conditions.

The detailed plan has **no Severity column** — per-step severity already
lives in the analysis file from the previous stage. Its final step is the
E2E validation gate.

Read it, type `APPROVE`.

### After Stage 2 — status file is born

Once all four stages are approved, the kit automatically initialises
`<feature>.status.md` from a template. This is the "where am I" file:

- Last updated date.
- Current step.
- A one-paragraph snapshot of progress.
- A status table that marks the four planning stages as approved and lists
  every implementation step as pending.

You will never edit this by hand. The kit updates it for you.

---

## Phase 3 — Implementing step by step

Now the planning is done and you are ready to actually build. For each
implementation step (`Step A`, `Step B`, …) you do this loop:

### 1. Start the step

```
/workflow:step-start payments-export
```

The kit:

1. Finds the first un-approved step.
2. Reads the requirement, the detailed plan, the status file, and the
   step's Severity row from the analysis file.
3. Briefs you with: the step goal, the open questions you must answer
   before coding, the inputs from previous steps, and
   what will happen as soon as you give the go-ahead.

You answer the open questions in chat.

### 2. Engineer writes the code

At runtime only the **Software Engineer** runs. It implements the substeps
from the detailed plan, editing only the files listed there, and writes unit
tests for that step. When it finishes, it hands you a short summary of what
changed and what to verify.

### 3. You approve

Read the changes (and the tests if there were any). When you are happy:

```
/workflow:step-approve payments-export
```

The kit flips the step's checkbox to `[X]`, updates the status file's
"current step" pointer, and shows you `git status` so you can decide when to
commit. **The kit never commits for you — you commit explicitly.**

Repeat for every step.

### 4. Final step — E2E validation gate

The feature's final implementation step is the E2E validation gate. The
**Software Engineer** authors automated e2e tests from `<feature>.test.md`
and runs them; the step is done when they all pass green. When present, the
SE hands off to the project's optional test-runner agent
(`.claude/agents/test-runner.md`), which runs the suite and returns only the
failures.

---

## Phase 4 — Stopping for the day

If you have to walk away mid-feature:

```
/workflow:step-handoff payments-export
```

The kit drafts a one-screen summary: what got done this session, what's
next, what's still open. You confirm, it appends the summary to the status
file, and the next session can pick up cleanly.

---

## The two golden rules

1. **No checkbox flips itself.** Every transition from "in progress" to
   "done" requires you to type `APPROVE`. If you have not approved, the
   agent will not move on.
2. **Steps that are `[X]` are frozen.** Once a step is approved, no agent
   may re-edit its logic, plan, or markdown. If a previously approved step
   needs to change, the agent must propose the change as a new question
   and wait for your sign-off — not silently rewrite.

---

## When to use this workflow

Use the feature pipeline when:

- You have a new feature to plan and build.
- You want a structured paper trail (requirement → plan → analysis → detailed
  plan → status) for the team or for auditing later.
- You want the AI to behave like a careful team, not a one-shot code generator.

Skip it when:

- You just want to fix a typo or run a tiny one-off task.
- The change is small enough that the planning ceremony costs more than the
  change itself.

For the other two walkthroughs, see
[`workflow-llm-wiki.md`](workflow-llm-wiki.md) — building and maintaining a
living wiki of an existing codebase — and
[`workflow-pr-review-loop.md`](workflow-pr-review-loop.md) — turning PR review
comments into rules the crew obeys next time.
