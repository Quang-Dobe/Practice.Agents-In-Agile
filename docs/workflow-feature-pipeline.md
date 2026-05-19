# Feature Pipeline — Idea to Code, step by step

This document explains how a new feature travels from a rough sentence in your
head all the way to working code, using the five AI "roles" this kit provides.

It is written for someone who has heard of Agile, sprints, and user stories
but is not an engineer. There are zero technical pre-requisites — just the
willingness to read what each role produced and type `APPROVE` when you are
happy with it.

---

## The cast

Think of the pipeline as a tiny agile team. Each role only has one job, and
no role steps on another role's toes.

| Order | Role                  | What they own                                                | Writes files? |
| ----- | --------------------- | ------------------------------------------------------------ | ------------- |
| 1     | **Product Owner**     | Framing the idea: what & why, in/out of scope, assumptions.  | No.           |
| 2     | **Business Analyst**  | Turning the framing into a structured requirement document.  | Yes.          |
| 3     | **Architect (round 1)** | The high-level plan — what steps will get us there.        | Yes.          |
| 4     | **Architect (round 2)** | The analysis: why this approach, plus a Test Strategy table. | Yes.          |
| 5     | **Software Engineer** | The detailed step-by-step plan, then the actual code.        | Yes.          |
| 6     | **Tester**            | Drafts the test cases before code, verifies at the end.      | Yes (tests).  |

The same agent plays Architect twice — once for the high-level plan and once
for the deeper analysis. This is intentional: the high-level plan is approved
first, so the analysis can lean on a stable set of steps.

---

## The big picture

```
You jot a rough idea  →  PO frames it   →  BA writes requirement  →
   Architect writes plan  →  Architect writes analysis  →
      Engineer writes detailed plan  →
         [for each step: Tester drafts tests → Engineer writes code → you APPROVE]
            →  Tester does final acceptance pass
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

### Stage 2 (overview) — Architect writes the high-level plan

The **Architect** agent writes `<feature>.overview-plan.md`. This is the
"big steps" document. It defines `Step A`, `Step B`, `Step C`, etc. — the
canonical list of implementation steps. From this point on, those step IDs
do not change.

Read it, sanity-check that the steps cover the requirement, type `APPROVE`.

### Stage 2 (analysis) — Architect writes the analysis

The same Architect agent is invoked again. It writes
`<feature>.analyzed.md` — the "why this approach" document. It explains the
trade-offs, the risks, the decisions, and any project-specific overrides to
the default engineering rules.

This file also carries a **Test Strategy table** with one row per step from
the overview plan:

| Step ID | Goal | Test kind | Owner |
| ------- | ---- | --------- | ----- |
| A       | …    | …         | …     |

For each step, the table says either a concrete test instruction
(meaning the Tester will draft tests for that step) or the literal phrase
`skip Tester` (meaning no test agent is needed for that step). This table
is the contract that decides whether the Tester gets invoked later.

Read it, type `APPROVE`.

### Stage 2 (plan) — Software Engineer writes the detailed plan

The **Software Engineer** agent writes `<feature>.plan.md`. This is the
mechanical, file-by-file, function-by-function blueprint. One section per
step from the overview plan, listing the files to create or change and the
"done-when" conditions.

The detailed plan has **no Test Strategy column** — testing decisions
already live in the analysis file from the previous stage.

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
   Test Strategy row for that step.
3. Briefs you with: the step goal, the open questions you must answer
   before coding, the inputs from previous steps, the test strategy, and
   what will happen as soon as you give the go-ahead.

You answer the open questions in chat.

### 2. Tester drafts tests (if needed)

If the Test Strategy row is **not** `skip Tester`, the **Tester** agent goes
first. It writes failing test cases that describe what the code must do.
This follows the classic "red phase" of test-driven development — the tests
exist before the code does, and they fail because the code does not exist yet.

If the row is `skip Tester`, this step is, well, skipped.

### 3. Engineer writes the code

The **Software Engineer** agent then implements the substeps from the
detailed plan, editing only the files listed there. When it finishes, it
hands you a short summary of what changed and what to verify.

### 4. You approve

Read the changes (and the tests if there were any). When you are happy:

```
/workflow:step-approve payments-export
```

The kit flips the step's checkbox to `[X]`, updates the status file's
"current step" pointer, and shows you `git status` so you can decide when to
commit. **The kit never commits for you — you commit explicitly.**

Repeat for every step.

### 5. End-of-feature Tester pass

When every step is approved, the kit offers one final acceptance pass: the
**Tester** agent re-reads the original requirement and every Test Strategy
row, and verifies that everything was actually exercised. For .NET projects,
it can hand off to a `test-runner` helper agent which runs the test suite
and returns only the failures.

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

For the other workflow this kit provides — building and maintaining a
living domain wiki of an existing codebase — see
[`workflow-domain-wiki.md`](workflow-domain-wiki.md).
