---
description: Build a feature wave by wave - brief, spawn parallel engineers, one build run, one review, advance
argument-hint: <feature> [step-id] [--gate]
---

Build the feature described by `docs/<feature>/<feature>.plan.md`, one **wave** at a time. Main Claude (you) is the orchestrator: you pick the wave, spawn one engineer per component, collect their reports, apply the shared-file edits yourself, run the build once, dispatch one reviewer, and relay.

`$ARGUMENTS` is `<feature>` followed optionally by `[step-id]`. The optional `--gate` flag is a boolean: **absent = false**, so a wave that passes build, tests, and review closes on its own and the next one starts. Pass `--gate` to hold every wave for a human `APPROVE` as well. It is order-independent. If `<feature>` is missing, error: `specify a feature, e.g. /feature:implement payments-export`.

If `[step-id]` is provided (e.g. `C`), that single step is the wave.

If `docs/<feature>/<feature>.status.md` does not exist, error: `no status file at docs/<feature>/<feature>.status.md — run /feature:structure <feature> first`.

## What a wave is

A **wave** = every step in `status.md` whose status is `pending` and whose `Depends on` steps (from the `plan.md` Component map) are all `approved`.

- Steps with no dependency start together.
- The E2E gate is always the last wave, alone.
- A wave is **one unit**: one build, one test run, one review, one decision.

## Phase 1 — Brief the wave

1. Read `docs/<feature>/<feature>.status.md` — the **only** source of what is open. Never read `requirement.md` to find the next step; it tracks nothing.
2. Read `docs/<feature>/<feature>.plan.md` — the Component map (owned files, `Depends on`, `Provides to others`), the `Shared files` list, and the section of every step in the wave.
3. Read the Severity row of every step in the wave from `docs/<feature>/<feature>.analyzed.md` (2-column contract: `Step ID | Severity`, per R7).
4. Print one brief for the whole wave:

   **Wave:** `<step ids>`
   **Components:** one line each — `<id> — <component>: <job>`
   **Owned files:** per component, from the map.
   **Shared files:** the ones you will edit yourself after the reports come back (or `none`).
   **Severity:** one cell per step.
   **Next:** spawn one `software-engineer` per step, in parallel, each with `model: "sonnet"`.

5. Do **not** write code. Do **not** modify any file yourself. Then go straight to Phase 2 — the brief is a record, not a gate. Under `--gate`, stop here and wait for the user's go-ahead.

## Phase 2 — Build, in parallel

Spawn **one `software-engineer` per step in the wave, in a single message** (one `Agent` tool call each, so they run at the same time). Every spawn passes **`model: "sonnet"`** — the agent file's own header stays `opus`, which is what authors `plan.md`; the build runs on sonnet by this spawn-time override. The E2E gate spawn passes it too.

Each prompt carries, and nothing else:

| Item | From |
|---|---|
| The component's section, verbatim | `plan.md` |
| Its owned files (create / change) | Component map |
| The `Shared files` list, marked **read-only for you** | `plan.md` |
| The `Talks to` / `Provides to others` contracts of its neighbours | `plan.md` |
| Expected output: files + tests | Component map, and `<feature>.test.md` for what the E2E gate will assert |
| Rule seams to honor (`coding-rules`, `architecture-rules`, `test-rules` via `project-seams`) | the repo |
| The report format below | this file |
| The hard rule (`[R-AGENT]`) | **never edit a file outside the owned list.** A change needed elsewhere is a *request* in the final report, not an edit. There is no live channel back — the report is it |

Set the matching `status.md` rows to `in progress` before the spawns.

**Report format every engineer ends with:**

```markdown
## Done
- files created / changed (paths)

## Tests
- tests added. **You have no shell** (`tools: Read, Glob, Grep, Edit, Write`), so you cannot build or
  run anything — say `diff-reviewed; main Claude runs the build gate` and name what you traced by
  hand instead. Never claim a build or test result you did not observe.

## Requests to main
| # | File | Change needed | Why |
|---|---|---|---|
| R1 | <path> | <the edit> | <which step needs it> |

## Questions [Waiting for Answer]
- Q1 — <the question, and which document it may change> (or "none")
```

## Phase 2b — Collect, dispatch, build once

When every engineer in the wave has reported:

| Report item | What you do |
|---|---|
| Request touches a **shared file** | you edit it yourself — these files have no component owner |
| Request touches **another component's owned file**, that agent has finished | `SendMessage` to that agent with the request; it keeps its context and applies the change |
| Request touches a component in a **later** wave | hold it; attach it to that step's prompt when its wave starts |
| Request reveals a **gap in the plan** | human gate — see the impact levels below |
| A `[Waiting for Answer]` question | human gate; set that row to `blocked`, Note = the question number. The other steps in the wave may still finish |
| An engineer edited a file outside its owned list | revert that hunk and re-send it as a request to the owning agent. Say so in the relay |
| All clear | run build + tests **once** for the whole wave, via the project `test-runner` agent when the repo ships one. The engineers cannot do this — they have no shell — so the build is yours, and a compile error is a normal outcome, not a failure of the protocol. Green → Phase 2c |
| A test fails that the wave did **not** touch | check the change set before calling it ours. Name it pre-existing only when no file this wave touched could reach it, and say so in the relay with the reasoning — `git` may not help if the tree is untracked |
| A test fails because the feature broke a **global invariant guard** (route surface, DI registration, contract snapshot, architecture fitness) and the file is in nobody's owned list | this is a plan gap, not a request. Level 1 — patch the owning step's file list in `plan.md`, add one `overview-plan-trace.md` row, then `SendMessage` the engineer to fix it |

Set the wave's rows to `in review` and go to Phase 2c.

## Phase 2c — Review the wave

Build and tests are green. Spawn **one** `code-reviewer` (`subagent_type: "code-reviewer"`) over the whole wave — `model: "sonnet"` for a narrow or mechanical wave, `model: "opus"` when the wave is wide or any step is `major` / `risky` / `irreversible`. It is read-only and has no shell, so hand it the build result you observed.

Its prompt carries, and nothing else:

| Item | From |
|---|---|
| Each step's section, verbatim | `plan.md` |
| Each component's owned files | Component map |
| Every file the engineers reported as created / changed | the `## Done` block of each report |
| The `Provides to others` contracts inside the wave | Component map |
| The Severity cell of each step | `analyzed.md` |
| The build + test result you observed | Phase 2b |
| The report format | the agent file |

**Acting on its report:**

| Finding | What you do |
|---|---|
| `Critical` / `Important`, file owned by a step in this wave | `SendMessage` that step's engineer with the finding — it keeps its context and applies the fix |
| `Critical` / `Important`, file under `## Shared files` | you fix it yourself |
| `Critical` / `Important` that is really a gap in the plan | human gate — the impact levels below |
| `Minor` | record it in the relay. It never blocks a wave |

After any fix: run build + tests once more, then spawn **one scoped re-review** carrying only the findings and the files that changed since. At most **3 rounds**. Still `needs fixes` after round 3 → stop, relay the open findings, and wait for the user, whatever the flag says.

## Phase 3 — Close the wave

The unit is the **wave**, never a single component. There is no partial close.

**A wave closes on its own when all three hold:**

1. build + tests green;
2. the reviewer's verdict is `ready`, or every `Critical` and `Important` was fixed and re-reviewed;
3. every step in the wave is `minor` or `medium` in `analyzed.md`.

**A human decides instead when any of these fire:**

| Trigger | What happens |
|---|---|
| A step in the wave is `major`, `risky`, or `irreversible` | relay the wave and the review, then wait for `APPROVE` |
| `--gate` was passed | the same — every wave waits |
| `needs fixes` after 3 review rounds | relay the open findings and stop |
| A `[Waiting for Answer]` question | human gate; that row → `blocked`, Note = the question number. The other steps in the wave may still finish |
| Build or tests still failing | relay and stop |
| The user says something is wrong before you advance | `SendMessage` that component's engineer, rebuild, re-review, relay again |

Relay either way: what each component changed, the build/test result, the review verdict with its `Critical` / `Important` / `Minor` counts, and anything you applied yourself.

When the wave closes:

1. Update `docs/<feature>/<feature>.status.md`: the wave's rows → `approved <today>`, `Last updated` → today, `Current step` → the first `pending` step of the next wave. **Nothing is written to `requirement.md`** — it tracks nothing.
2. Run `git status` to show what changed. Do **not** `git add`, do **not** commit — the user does that.
3. Print one line: `Wave <ids> of <feature> closed. Next wave: <ids>.`
4. Return to Phase 1 for the next wave.

## The final review

Before the E2E-gate wave — always the last wave, always alone — spawn one `code-reviewer` on **`model: "opus"`** in final-feature mode. Its prompt carries every step section of the feature, the changed-file list across all waves, and the `## Success criteria` of the approved `requirement.md`. Handle its findings exactly as a wave review's, then run the E2E gate.

When no `pending` row is left, say "All steps for `<feature>` are approved" and stop. The feature's acceptance is the E2E gate (the last step of `plan.md`), authored by the Software Engineer and run by you at the wave's build gate — there is no separate end-of-feature Tester pass.

## A question that changes a document (the human gate)

An engineer's `[Waiting for Answer]` may need a decision that changes a planning document. Say which level it is in one line; the user confirms with one word.

| Level | The answer changes… | Who updates it | What is redone below | Where the decision is recorded |
|---|---|---|---|---|
| **0** | nothing | nobody | nothing | nowhere — chat only |
| **1** | one component section in `plan.md` | the SE (spawned as **opus**) for a real change; you, for a one-line patch | that component's row → `pending` or `reopened` | `overview-plan-trace.md` |
| **2** | `overview-plan.md` — a step, a component, a tech decision | the `architect` (opus) | `plan.md` patched or regenerated by the SE (opus); `status.md` rebuilt | `overview-plan-trace.md` |
| **3** | `requirement.md` — scope, an `SC-n`, a constraint | the `business-analyst` (opus); the `tester` too if an `SC-n` changed | the full level-2 cascade | `requirement-trace.md`, plus `overview-plan-trace.md` for the technical fallout |

A decision is recorded **only** when it changed a document, and only in the trace of the highest document it changed. A level-0 answer leaves no paper.

**Patch or regenerate `plan.md`?**

| Signal | Action |
|---|---|
| Step IDs change — a step added, removed, or split | regenerate |
| More than 1/3 of the Steps table rows change | regenerate |
| Otherwise | patch the touched sections only |

Say which rule fired. A **regenerated** `plan.md` is written against the code **as it is now**: the SE reads the current source first, every section describes only the work left, components already built stay in the Component map with `State: done` and get no section, and the E2E gate still covers the **whole** feature.

**Rebuild `status.md` after a regenerate** — one row per Component map row:

| Map row | Status row |
|---|---|
| `done`, no section | keeps `approved <date>` |
| `done`, with a section (design changed) | `reopened` |
| `partial` | `pending`, Note `part in code` |
| `none` | `pending` |
| step no longer in the map | row deleted |

`Current step` → the first `pending` row.

Every changed document re-enters its own `APPROVE` gate, exactly as the first time. A document change always waits for a human, flag or no flag — it is never `minor`.

## Gate mode (`--gate`)

**Default is ungated.** A wave that passes build, tests, and review closes on its own, and the next wave's Phase 1 follows immediately. `--gate` restores a human `APPROVE` on every wave, and also makes Phase 1 stop for a go-ahead before each wave's spawns.

**Severity source.** For each wave, read the `Severity` cell of **every** step in it from the 2-column R7 table in `docs/<feature>/<feature>.analyzed.md`.

**Severity gates whatever the flag says.** One `major`, `risky`, or `irreversible` step → the **whole wave** waits for a human. Nothing auto-closes those, and nothing ever closes part of a wave.

**Five stop conditions (the loop halts on the first of):**
1. a wave holding a step whose `Severity` is `major` / `risky` / `irreversible`;
2. no `pending` row is left;
3. an engineer posts a `[Waiting for Answer]` — nothing answers a question on the human's behalf (see the human gate above);
4. a build or test failure;
5. a review verdict still `needs fixes` after 3 fix rounds.

On any stop condition the loop halts and control returns to the human.

## Notes

- **Ownership.** The Software Engineer owns `plan.md` and all source, whichever model runs it. The `code-reviewer` owns nothing and writes nothing. You own `status.md`, the `Shared files` edits, and the trace rows you append during a human gate.
- **Routing is yours.** The reviewer never messages an engineer, and the engineers never see each other. Every finding travels through you.
- **No commits.** The user commits explicitly.
- **Live-spawn note.** `software-engineer` and `code-reviewer` must be installed at user scope (`~/.claude/agents/`, via `install.ps1`) and are loaded at session start; if you replaced one mid-session, restart the session before running this command.
