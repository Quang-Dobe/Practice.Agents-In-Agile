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
| 2     | **Business Analyst**  | The requirement, plus the trace of how it was decided.       | Yes.          |
| 3     | **Architect (round 1)** | The overview plan — design and the canonical step list — plus its trace. | Yes.        |
| 4     | **Architect (round 2)** | The short analysis: per-step Severity, risks, rule overrides. | Yes.          |
| 5     | **Software Engineer** | The component-level build plan, then the actual code; also owns test execution and the final E2E validation gate. | Yes.          |
| 6     | **Tester**            | Authors `<feature>.test.md` at stage-2-overview (planning only, no runtime role). | Yes (`test.md`). |

The same agent plays Architect twice — once for the high-level plan and once
for the deeper analysis. This is intentional: the high-level plan is approved
first, so the analysis can lean on a stable set of steps.

---

## The big picture

```
You jot a rough idea  →  PO frames it   →  BA writes requirement (+ trace)  →
   Architect writes overview-plan (+ trace) + Tester writes test.md  →
      Architect rates each step (analyzed.md)  →
         Engineer writes the component plan  →
            [for each wave of components: Engineers build + tests → you APPROVE]
               →  final step: Engineer authors e2e tests from test.md and runs them
```

Every **final** file has a twin **trace** file: the final file says what we
build, the trace says how we decided it. You read the final file; the trace is
there when you ask "why did we do it that way?".

Between every arrow there is a moment where you read what was produced and
either type `APPROVE` or say "no, change X". Nothing moves forward without
your sign-off.

---

## Phase 1 — Brainstorming (no files yet)

You start by writing a single rough requirement file at
`docs/<feature-name>/<feature-name>.raw-requirement.md`. It can be one
paragraph or one page — whatever you have. Use kebab-case for the feature name
(for example, `payments-export`, not `Payments Export`).

This file is yours. No agent ever overwrites it, at any stage.

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

The **Business Analyst** agent reads your rough file, the PO's brainstorm
summary, and any architectural notes that already exist. It **pressure-tests**
the PO's assumptions — it openly disagrees, amends, or asks before writing.
It asks only what would change the text, and it keeps the list short.

It writes **two new files**. Your rough file is never touched.

| File | What is in it |
| --- | --- |
| `<feature>.requirement.md` | Goal · Current behavior (only if the feature changes something that exists) · In scope · Out of scope · Success criteria · Constraints. Nothing else. |
| `<feature>.requirement-trace.md` | One table: what was asked, what you answered, what it changed in the requirement. Plain words, no technical terms. |

Two things worth knowing:

- **Success criteria are happy-path only** — what you get when things go
  right. A limit ("max 10 000 rows") is a *Constraint*, not a criterion. The
  Tester turns limits into edge cases in the next stage.
- **A question that changed nothing is not recorded.** The trace file holds
  decisions, not chat history.

You review it, type `APPROVE`, and move on.

### Stage 2 (overview) — Architect writes the plan, Tester writes the test spec

This stage runs in parallel. The **Architect** agent writes
`<feature>.overview-plan.md` — the design in six short sections:

1. Purpose — the outcome, in one paragraph.
2. What is exposed — what a user or a caller sees: an API table, UI words, or
   a Job / CLI / Event line. Nothing exposed → "None — internal change."
3. Components — a table of what is new and what changes, plus a
   before → after diagram when the shape of the code changes.
4. Happy-path flow — what happens, step by step.
5. Key technical decisions — the final choices only, no options.
6. Steps — `Step A`, `Step B`, … the canonical list, each naming the success
   criterion it covers. From this point on, those step IDs do not change.

It also writes `<feature>.overview-plan-trace.md` — one row per technical
decision: what we looked at, what we chose, and why in one line. Same idea as
the requirement trace, for technical choices.

In parallel, the **Tester** agent writes `<feature>.test.md`:

- **Happy cases first**, each flagged `[Happy Case]`, at least one per success
  criterion.
- **Edge cases** after, each naming the requirement line it comes from (a
  Constraint, a scope line, a Current-behavior line).
- **Ad-hoc checks** last — things a human checks once by hand, never automated.

One combined `APPROVE` covers the overview plan and the test spec. Read them,
sanity-check that the steps cover the requirement, type `APPROVE`.

### Stage 2 (analysis) — Architect rates each step

The same Architect agent is invoked again. It writes `<feature>.analyzed.md` —
a short file with exactly three sections:

1. **Step Severity** (rule R7) — one row per step from the overview plan:

   | Step ID | Severity |
   | ------- | -------- |
   | A       | …        |

2. **Risks** — at most five, only risks inside this feature. "None seen." is a
   correct answer.
3. **Rule overrides** — only where this feature breaks one of your repo's own
   rules. "None." is a correct answer.

Each step's severity is what later drives `/feature:implement
--bypass-approval`: low-severity steps can be auto-approved, higher-severity
steps still require your explicit sign-off.

Why this file explains nothing: the *why* behind every decision already lives
in `overview-plan-trace.md`. One fact, one home.

Read it, type `APPROVE`.

### Stage 2 (plan) — Software Engineer writes the build plan

The **Software Engineer** agent writes `<feature>.plan.md` — the build plan,
one section per **component** (a service, a screen, a job — a unit of code
with one job).

It starts with a **Component map**: which files each component owns, what it
depends on, and what contract it gives the others. Two rules make parallel
work safe later:

- No two components own the same file.
- A file that several components need is listed under **Shared files**, and
  only the main assistant edits it.

Each component section says: the job, the files, what changes, how it works,
who it talks to, what to test, and when it is done. Not full code — enough
that an engineer who has never seen the repo can build it.

The plan has **no Severity column** (that lives in the analysis file), no
implementation-order table (order is the "depends on" column), and no commit
steps — you commit. Its final step is the E2E validation gate.

Read it, type `APPROVE`.

### After Stage 2 — status file is born

Once all four stages are approved, the kit automatically initialises
`<feature>.status.md` from a template. This is the "where am I" file:

- Last updated date.
- Current step.
- One row per build step: `pending`, `in progress`, `waiting approval`,
  `approved <date>`, `reopened`, or `blocked`.

Planning stages are **not** rows here. Each planning file carries its own
one-line `> Status:` header, and the command sees which stage you are on from
which files exist on disk.

You will never edit this by hand. The kit updates it for you.

---

## Phase 3 — Building, one wave at a time

Now the planning is done and you are ready to build. Work does **not** go one
step at a time any more. It goes one **wave** at a time.

A wave = every step that is still `pending` and whose "depends on" steps are
already approved. Steps that depend on nothing start together.

| Wave | Steps | What runs |
| --- | --- | --- |
| 1 | A, B | two engineers, at the same time |
| 2 | C | one engineer |
| 3 | E2E gate | one engineer, alone |

### 1. Start the wave

```
/feature:implement payments-export
```

The kit:

1. Reads `status.md` to find the wave — which steps are open and ready.
2. Reads the build plan: each component's job, the files it owns, the shared
   files, and each step's Severity from the analysis file.
3. Briefs you with the whole wave, then waits for your go-ahead.

### 2. Engineers build, in parallel

On your go-ahead, one **Software Engineer** is started per component in the
wave, all in one go. Each one runs on the faster model (sonnet); the planning
roles stay on the slower, more careful one.

Two rules keep them out of each other's way:

- Each engineer edits **only the files its component owns**.
- If it needs a change somewhere else, it does not make it. It writes a
  **request** in its report, and the main assistant applies it — or passes it
  to the engineer that owns that file.

When every engineer has reported, the main assistant applies the requests,
runs the build and tests **once** for the whole wave, and shows you the result.

### 3. You approve the wave

Read the changes. When you are happy, type:

```
APPROVE
```

That approves the **whole wave** — all its rows flip to `approved` in
`status.md`, the "current step" pointer moves on, and you get a `git status`
so you can decide when to commit. **The kit never commits for you.**

If one component is wrong, do not type `APPROVE`. Say what is wrong. The main
assistant sends the fix back to that engineer, rebuilds, and shows you the
wave again. There is no "approve all except B" — the wave was built and tested
as one set, so it is approved as one set.

Then it goes straight to the next wave. One command runs the whole loop.

### 4. When a question changes the plan

An engineer may hit something the plan did not answer. It stops and asks. When
your answer changes a document, the kit says how deep the change goes and you
confirm in one word:

| Depth | What changes | What happens |
| --- | --- | --- |
| nothing | — | you get the answer, work continues, nothing is written |
| the build plan | one component | that section is fixed; its row reopens |
| the overview plan | a step or a design choice | the Architect updates it, the build plan is redone below it |
| the requirement | scope, a criterion, a limit | the BA updates it, the test spec follows, then everything below |

Each changed document comes back to you for a fresh `APPROVE`. Code that is
already written and approved stays; only documents and the work still ahead
change. A component whose plan changed shows as `reopened`.

### 5. Final wave — E2E validation gate

The last wave is the E2E validation gate, alone. The **Software Engineer**
turns every case in `<feature>.test.md` into an automated test — happy cases
first — and runs them. The feature is done when every `[Happy Case]` is green.
When present, the SE hands off to the project's optional test-runner agent
(`.claude/agents/test-runner.md`), which runs the suite and returns only the
failures. The "ad-hoc" checks are not automated: you get them as a short
"please check by hand" list.

---

## The two golden rules

1. **Nothing marks itself done.** Every move from "in progress" to "done"
   needs you to type `APPROVE`. If you have not approved, the agent will not
   move on.
2. **Done code stays; documents may change — but only through the gate.**
   When an answer mid-work changes the requirement or the plan, we accept it:
   the document is updated, whatever sits below it is redone, a trace row
   records the decision, and the changed document is shown to you for a fresh
   `APPROVE`. A component whose plan changed shows up as `reopened` in
   `status.md`. Nothing is ever rewritten silently behind your back.

---

## When to use this workflow

Use the feature pipeline when:

- You have a new feature to plan and build.
- You want a structured paper trail (requirement → overview plan + test spec →
  analysis → build plan → status, each with its trace file) for the team or for
  auditing later.
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
