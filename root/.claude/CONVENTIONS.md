# Project-Level Rules & Skills Convention

The root tier — installed to **user scope (`~/.claude/`) via `install.ps1`, unchanged** (not
copied per-project) — is **stack-agnostic**. It ships no language-, framework-, or
architecture-specific rules. Each consuming project supplies its own rules in **its own `.claude/`
tree** — never inside the root tier. That keeps the kit pristine and reusable across every repo you open.

The crew reads these project-supplied artifacts as **optional seams**. When a seam is absent, the
agent proceeds without it and **never blocks**.

## Where project rules live

```
<your-project>/
  .claude/
    skills/
      architecture-rules/      <- you author (optional)
        SKILL.md
      coding-rules/            <- you author (optional)
        SKILL.md
      test-rules/              <- you author (optional)
        SKILL.md
  docs/
    architecture.md            <- optional free-form architecture seam

# root tier (this scaffold) lives at ~/.claude/, installed once via install.ps1 — NOT copied into the project
```

## Two tiers: generic (USER) vs project (REPO)

An agent carries its own procedure. It declares a `skills:` manifest only for what it **shares**
with other agents, and the harness preloads those at startup. Two kinds of skill exist:

- **Generic shared skills** — stack-agnostic, installed to user scope under `~/.claude/skills/`.
  They hold a concern **two or more agents load**, or that **two or more skills cite by heading**
  (`project-seams`, `prompt-defense`, `repo-layout`, `library-knowledge`, and the wiki skills).
  **Never edited per project.**
- **Project rule/pattern skills** — stack-specific, authored by the consuming repo under
  `.claude/skills/`. They hold *your* rules and framework patterns.

A generic agent reaches project skills through its preloaded `project-seams` skill: load if present,
proceed if absent. Agents reference project skills by **concern name**, never by path or stage.

## Project rule skills — reserved concerns

Named for **what they govern** (not for an agent). One rule has exactly one home; an agent may read
more than one skill. These three are **reserved** — the crew auto-discovers them by name:

| Rule skill | Governs | Referenced by |
|---|---|---|
| `architecture-rules` | layering, boundaries, allowed patterns, dependency direction | architect, software-engineer (as context) |
| `coding-rules` | language/style conventions, forbidden patterns, naming | software-engineer |
| `test-rules` | test layout, naming, coverage targets, fixtures | tester, software-engineer (unit/e2e layout) |

All three are optional and independent. Author only the ones your project needs.

## Project skills — open concern set

Beyond the three reserved concerns, a repo may add **any** kebab-case concern skill
(`dotnet-patterns`, `react-patterns`, `db-rules`, `a11y-rules`, …) under `.claude/skills/<concern>/`.
Because project scope outranks user scope, a same-named project skill **overrides** a generic one —
useful if a repo wants a stricter version of a generic skill.

### Wiring an open concern — required, it is not auto-discovered

Only the three reserved concerns are auto-discovered. A root agent's reference list **is** its
`skills:` manifest, and the root tier is never edited per project — so an open concern skill is
**never read** unless you wire it. Pick one:

| # | How | Cost |
|---|---|---|
| **1 — default** | **Name it from inside a reserved skill.** Add an `## Also load` section to `architecture-rules` / `coding-rules` / `test-rules` listing the open concerns. `project-seams` follows that list. | one line, no install, no root edit |
| 2 | Ship `<repo>/.claude/agents/<agent>.md` that overrides the root agent, with the open concern in its own `skills:` manifest. | you must keep that agent copy in sync with the root one |
| 3 | Drop the separate skill — fold its content into the reserved skill. | fewer files, one bigger file |

Pattern 1, inside `<repo>/.claude/skills/coding-rules/SKILL.md`:

```md
## Also load
- `dotnet-patterns`
- `react-patterns`
```

**Depth is 1.** A reserved skill may name open concerns. An open concern loaded this way may **not**
name more — its own `## Also load` is ignored. Keeps loading finite and easy to predict.

## Build and test commands

No crew agent has a shell. Main Claude runs the project's build and test commands itself and
keeps the raw log out of the thread by filtering in the command — tail it, or use the runner's
own quiet flag. If you want a PostToolUse build/test hook, add it to your project's
`.claude/settings.json` — the scaffold ships none.

## How to author a rule skill

1. Copy `~/.claude/templates/project-rules.template.md` to
   `.claude/skills/<concern>/SKILL.md` — use a reserved concern (`architecture-rules`, `coding-rules`,
   `test-rules`) or any open kebab-case concern (`dotnet-patterns`, `db-rules`, …).
2. Fill in numbered sections so planning artifacts can cite them precisely
   (e.g. "per `coding-rules` Section 3.2"). Stable section numbers = stable citations.
3. For a long ruleset, keep `SKILL.md` as a thin loader and put the full text in a sibling
   `.md` file the loader points to.

## How to author a crew capability skill (root tier)

A **capability skill** holds the *how* of one artifact or one concern for a crew agent
(`project-seams`, `repo-layout`, `library-knowledge`, …). Home:
`root/.claude/skills/<concern>/SKILL.md` in the scaffold repo → `~/.claude/skills/<concern>/` after
`install.ps1`. Rule skills (section above) are the **project** tier — different home, different job.

**Read this section before you create or edit any skill an agent names in its `skills:` manifest.**
It outranks generic skill-writing guidance (e.g. `superpowers:writing-skills`) on tier, placement,
naming, and manifest wiring. That guidance still governs file shape and description wording.

1. **One concern per skill.** Name it for the concern, not the agent — `repo-layout`, not
   `wiki-agent-skill`. Kebab-case. Documented exception: the wiki skills are named after the agent
   that owns the output (`project-explorer` skill ↔ `project-explorer` agent) even though the other
   two wiki agents also load them.
2. **Stack-agnostic.** No language, framework, test runner, or repo-specific path. Anything
   stack-specific belongs in the consuming repo's `.claude/skills/` (reserved + open concerns above).
3. **Frontmatter:** `name` (matches the folder) and `description` (what it authors, which agent uses
   it, which stage invokes it). Nothing else.
4. **Body sections, in this order:**

   | Section | Holds |
   |---|---|
   | `## Mission` | one sentence — what this skill produces |
   | `## Owned artifact` | exact output path + its template, or "writes no file" |
   | `## Read scope` | every input, one per line |
   | `## Procedure` | numbered steps, last step = the hand-off line |
   | `## Boundary` | what this skill must NOT do, and which skill owns that instead |

5. **A skill file exists only when it is shared** — either **two or more agents load it**, or **two
   or more other files cite it by heading**. A procedure used by exactly one agent and cited by no
   other file lives **inside that agent's own file**, using the same body sections as above, and gets
   no skill folder: splitting a single-owner contract across two files buys nothing and lets the two
   halves drift. The second clause counts **any** file — a skill, an agent, or a command. It is why
   `project-update` stays a skill (`project-overview` cites its sections by name instead of restating
   them), and why `wiki-architecture` does (the `wiki-diagrammer` agent cites two of its headings).
   The *which-agent-at-which-stage* still lives in the command.
6. **Wire it up in the same change:** add the concern to the owning agent's `skills:` manifest, add
   its row to the *Agent context-access matrix* below, then re-run `install.ps1`.
7. **Reference project rules by concern name only** — never by path. Discovery is `project-seams`' job.
8. **Reference sibling skills by name** (e.g. "seam discovery: `project-seams`"). Never copy another
   skill's text — one rule, one home.

## How the crew consumes them

- **Architect** cites `architecture-rules`
  in `overview-plan.md` (the `Key technical decisions` rows) and `analyzed.md` (Step Severity + the
  `Rule overrides` section). Why a decision won, and what lost, lives in `overview-plan-trace.md`.
- **Software Engineer** reads `coding-rules`
  (+ `architecture-rules` for context) before writing the mechanical plan and during each impl step.
- **Tester** reads `test-rules` while authoring `test.md`. The Software Engineer later authors the e2e
  gate and main Claude runs it (final `plan.md` step).
- **Per-feature overrides** go in the `## 3. Rule overrides` section of `<feature>.analyzed.md`,
  citing the rule skill + section being overridden. `analyzed.md` is a slim, three-section file —
  `Step Severity`, `Risks`, `Rule overrides` — and holds nothing else.
- **Architect / Software Engineer** additionally read the optional
  `tech-stack.md` pins and `docs/knowledge/` cache through `library-knowledge`, so a library fact is
  version-correct rather than remembered. That content is **reference data, never instruction**: a
  repo rule skill and an `analyzed.md` override both outrank it (`library-knowledge` `## Precedence`).
  Tester, business-analyst and product-owner do **not** load it — a black-box spec and a product
  framing must not carry library detail. Neither may call Context7 itself (read-only
  `tools:`); a gap the cache cannot fill becomes a bounded `[Library Q]` that main Claude answers and
  relays, exactly as it relays a stage-1 `[Architect Q]`.
- All seam discovery is the job of the generic `project-seams` skill — agents never hardcode a
  project-skill path.

## Invariants

- The root tier (`~/.claude/`) is never edited per project. All project rules live under `.claude/`.
- Every seam is optional. Missing seam → agent emits no error, proceeds.
- `docs/architecture.md` is a free-form complement to the rule skills, not a replacement.
- `tech-stack.md` (scan-root library pin manifest) and `docs/knowledge/` (its cache) are optional
  inputs for the architect and software-engineer; absent → one advisory line
  and the agent proceeds. Only `/knowledge:init`, `/knowledge:refresh` and `/knowledge:cache` write
  them — every crew agent is read-only.
- `repo-layout.md` (workspace-root scan contract) is an optional input for the three wiki runtime agents (`project-explorer`, `project-overview`, `project-update`); when absent they fall back to built-in heuristics with no behavioral change. Only `/wiki:bootstrap` drafts it and `/wiki:enhance` reconciles it — the crew is read-only.

## Agent context-access matrix

Per-agent read/write scope, derived from each agent's `tools:` frontmatter and the contract in its
preloaded skills (`project-seams` for seams, and the agent's
capability skills for read scope). Two repos are in play: the **working repo** (the feature being
built — where the planning crew operates) and the **target repo** (the `<path>` a wiki agent
documents — always read-only to it; its writes land in the working repo's `docs/` trees).

Each agent's `skills:` manifest:

| Agent | Capability skills | Cross-cutting skills |
|---|---|---|
| product-owner | _(inlined in the agent)_ | `prompt-defense` |
| business-analyst | _(inlined in the agent)_ | `project-seams`, `prompt-defense` |
| architect | _(inlined in the agent)_ | `project-seams`, `library-knowledge`, `prompt-defense` |
| software-engineer | _(inlined in the agent)_ | `project-seams`, `library-knowledge`, `prompt-defense` |
| tester | _(inlined in the agent)_ | `project-seams`, `prompt-defense` |
| pr-review-analyst | _(inlined in the agent)_ | `project-seams`, `prompt-defense` |
| html-generator | _(inlined in the agent)_ | `prompt-defense` |
| project-explorer | `project-explorer` | `repo-layout`, `prompt-defense` |
| project-overview | `project-overview` | `repo-layout`, `prompt-defense` |
| project-update | `project-update`, `project-overview`, `project-explorer` (locked reload order) | `repo-layout`, `prompt-defense` |

**The bootstrappers do not preload each other.** `project-overview` used to load the whole `project-explorer` skill for two contracts; carrying a 27k-character sibling in the preamble of every request was the pipeline's largest avoidable cost. `## BC candidate surfacing` and `## Comment policy (code is the single source of truth)` are now **mirrored** in both bootstrap skills — edit the two copies in the same change. The language whitelist, the built-in 8 exclusion globs, and the never-read list moved to the `repo-layout` skill (`## Built-in scan filters`, `## Read discipline`), the one skill all three preload.

**A `SKILL.md` is preloaded on every request; a `references/*.md` is not.** Anything one caller needs at one point in a run belongs in a co-located reference file read on demand, cited from a forwarding stub that keeps the original heading name so existing citations still resolve. Current split: `project-overview/references/diff-update.md` and `project-explorer/references/reverse-mapping.md` (update-pass only — `project-update` reads both), `repo-layout/references/drafting.md` (writer-only — the project-tier kit reads it).

Legend: **R** = read · **W** = write/edit · **—** = no access · **(opt)** = optional, never blocks.

### Planning crew (feature pipeline)

| Agent | `tools:` | `docs/narrative/` | `docs/domain/` | Source code | Feature docs `docs/<feature>/` | Rule skills `.claude/skills/` | Owns / writes |
|---|---|---|---|---|---|---|---|
| **product-owner** | R only | R (opt) | — | — | R (raw requirement only) | — | **nothing** (writes no file) |
| **business-analyst** | R + W | R (opt) | — | — | R raw + others' `status.md`; **W** `requirement.md` + `requirement-trace.md` | — | `requirement.md`, `requirement-trace.md` |
| **architect** | R + W | R (soft) | R (soft) | R (recon; both wiki trees absent) | R requirement/overview; **W** `overview-plan.md` + `overview-plan-trace.md` + `analyzed.md` | R `architecture-rules` | `overview-plan.md`, `overview-plan-trace.md`, `analyzed.md` |
| **software-engineer** | R + W | R (soft) | R (soft) | **R + W** (build mode: **owned files only**) | R requirement/overview/analyzed/**test.md**; **W** `plan.md` | R `coding-rules` + `architecture-rules` | `plan.md` + **production code + unit tests + e2e tests** |
| **tester** | R + W | R (opt) | — | — | R requirement; **W `test.md`** | R `test-rules` | `test.md` (e2e/acceptance spec); planning-only, no source, no runtime |
| **code-reviewer** | R only | — | — | **R** (the wave's changed files) | R the step sections + severity carried in its prompt | R `coding-rules` + `architecture-rules` + `test-rules` | **nothing** (returns findings + one verdict) |
| **pr-review-analyst** | R only | R (soft) | R (soft) | **R** (evidence hunt) | R `docs/<feature>/pr-review/*.md` + `*.pr-review.ledger.md` | R all concerns via `project-seams` | **nothing** (returns findings + rule drafts) |

- `docs/architecture.md` is read by business-analyst, architect, software-engineer, tester — not by product-owner (narrative-only carve-out).
- Product-owner is the only role walled off from all engineering context (no domain, no architecture, no status).
- **Final file / trace file split.** Every planning artifact that carries decisions has a sibling trace:
  `requirement.md` ↔ `requirement-trace.md` (BA-owned), `overview-plan.md` ↔ `overview-plan-trace.md`
  (architect-owned). The final file holds what we build, in decided wording. The trace holds one
  append-only `## Decisions` table — the question, the answer, and what it changed. A trace is never
  a planning input; downstream agents read the final file only. Trace files carry no `> Status:` line
  and are never gated.
  - `requirement.md` = Goal, Current behavior (only when existing behavior changes), In scope, Out of
    scope, Success criteria (happy-path outcomes only), Constraints. No process blocks, no step
    checklist: planning progress is read from which files exist and each file's `> Status:` line.
  - `<feature>.raw-requirement.md` is the user's own prose and is **never overwritten**. The BA writes
    `requirement.md` as a new file, and no trace keeps a verbatim copy.
  - `requirement-trace.md` is plain words — no code, no paths, no technical term the user did not use.
    `overview-plan-trace.md` is *about* technical choices, so technical nouns are fine there; code,
    paths, and identifiers are not.
- **Main Claude may append trace rows.** When a human-gate answer changes an approved document,
  main Claude appends the row to the matching trace file itself — the same mechanical write it does
  on `status.md`. Authoring a trace file is still the owning agent's job; appending one row is not
  worth a re-spawn.
- Software-engineer is the only role that writes source (production + unit + e2e tests). Tester writes no source — it authors the requirement-keyed `test.md` e2e/acceptance spec; SE turns it into automated e2e tests at the final plan step.
- **One agent, two modes.** The software-engineer header stays `model: opus` — that is the model that
  authors `plan.md` and any regenerate. `/feature:implement` spawns the *same* agent with
  `model: "sonnet"` for every build step, including the E2E gate. The mode is chosen by the command
  that spawns, exactly as the agent's context table already works. Ownership does not move: one owner
  per artifact, whichever model runs it.
- **Parallel build, one owner per file.** A wave is every `pending` step whose dependencies are
  approved; main Claude spawns one engineer per step in a single message. The `plan.md` Component map
  gives each component a **disjoint** owned-file set; a file two components touch is listed under
  `## Shared files` and **main Claude is its only writer**. An engineer that needs a change outside
  its owned list files a *request* in its final report — main applies it, or relays it to the owning
  agent with `SendMessage`. There is no live channel between running agents; the report is the channel.
- **Close unit is the wave.** One build + test run, one review, one decision; every row in the wave
  flips together. No partial close. A wave closes with no human when build, tests, and the review
  are clean and every step in it is `minor` or `medium`. `--gate`, or one `major` / `risky` /
  `irreversible` step, holds it for `APPROVE`.
- **Review is a spawn, not the orchestrator's job.** Once a wave builds green, main Claude spawns
  one read-only `code-reviewer` over it. It checks the contracts between components first — the
  engineers in a wave never spoke to each other, so the seam is where parallel work fails — then
  plan alignment, rule skills, quality, tests. It writes nothing and routes nothing: findings come
  back with an `Owner step` column and main Claude relays each with `SendMessage`, at most 3 fix
  rounds. A whole-feature pass on `opus` runs before the E2E gate. Review lives in the root tier on
  purpose: a project seam may be absent, and review may not.
- **`status.md` is main Claude's file.** No agent writes it. It holds one row per `plan.md` step and
  no planning rows.
- **Stage-1 recon carve-out.** When `/feature:structure` Stage 1 finds **both** `docs/domain/` and `docs/narrative/` absent, the architect runs a read-only codebase recon pass (`stage-1-recon`) and may read source **as-needed** to produce a Current Behavior Brief — the only path by which a planning role reads raw source, and it writes no file. The brief is written at **plan level**: today's business flow plus the related components and their roles, ready to drop into the requirement's `## Current behavior` section, plus a list of open unknowns. `path:line` citations live in chat only, for the bounded Q&A round — they are persisted nowhere, and the architect re-reads the code at stage 2 when it needs the detail. The BA itself **never** reads source. An optional bounded `[Architect Q]` round (`stage-1-qa`, ≤1) lets the BA ask the architect instead. When either wiki tree exists, no recon runs and the architect's "Source code" access reverts to `—`.
- "soft" = optional domain context; the agent emits a one-line advisory and proceeds if the tree is absent.
- **pr-review-analyst** is the second role that reads raw source, after the stage-1 recon carve-out. Its reads are read-only and its output is a finding list, never a file. It gives no validity verdict on a review comment: it retrieves `file:line` evidence and the human judges. Rule text it drafts is written by main Claude into the **consuming repo's** `.claude/skills/` only, behind an `APPROVE` gate — never into the root tier.

### Cross-pipeline agent (any command, any tier)

| Agent | `tools:` | `model:` | Reads | Owns / writes |
|---|---|---|---|---|
| **html-generator** | R + W | `sonnet` | only what its prompt carries; the target file on an edit | the **one** `.html` / `.htm` path in its prompt |

- Spawned per `[R-HTML-AGENT]` for every `.html` / `.htm` write, at any size, from any pipeline.
- **Spawn it by `subagent_type: "html-generator"`, never as a bare `model:` override.** A
  `subagent_type: "fork"` ignores `model:` and runs on the caller's model — "spawn a sonnet subagent"
  then silently returns a copy of main Claude. The named agent pins the model in its own frontmatter.
- It belongs to no pipeline and reads no wiki tree, no rule skill, and no feature doc. Every fact the
  page shows arrives in the prompt; it invents none and verifies none — checking every number stays
  with the caller.
- It writes one file. Anything else it needs goes back as a request — see the spawn contract below.

### Spawn contract — owned files and requests

Binds **every** agent spawn in this kit, planning or runtime, and any ad-hoc spawn a command makes.
It is the kit-side half of `[R-AGENT]`; the global rule states it for spawns outside the kit too.

- **Every spawn prompt names the agent's owned files**, as a list of paths, and says that everything
  else is read-only. A prompt without that list is a defect in the prompt.
- **An agent writes only inside its owned list.** Not a shared config, not a neighbour's file, not a
  file it "had to touch to compile".
- **A change it needs elsewhere is a request, not an edit.** It finishes what does not depend on the
  change, files it under `## Requests to main` in its **final report** — file, exact change, why —
  and stops.
- **The report is the only channel back.** No crew agent carries `SendMessage`; a running agent
  cannot reach main Claude. Main reads the report, then applies the change itself or relays it with
  `SendMessage` to the agent that owns that file.
- **An agent that edited outside its list:** main reverts that hunk and re-sends it as a request to
  the real owner, and says so in the relay.

Where each pipeline already spells this out: `plan.md`'s `## Shared files` (main Claude is their only
writer), the software-engineer's `## Requests to main` report block, and `/feature:implement` Phase 2b.

### Wiki runtime agents (domain / narrative pipeline)

| Agent | `tools:` | `docs/narrative/` | `docs/domain/` | Target repo source (`<path>`) | Owns / writes |
|---|---|---|---|---|---|
| **project-explorer** | R + W | R (soft, opt) | **W** (bootstrap; refuses if non-empty) | R (read-only walk; no git, no mutate) | `docs/domain/` |
| **project-overview** | R + W + Bash | **W** (bootstrap; refuses if non-empty) | — (neither reads nor writes) | R (read-only walk) | `docs/narrative/` |
| **project-update** | R + W + Bash | **R + W** (diff-update, fence-preserving) | **R + W** (diff-update, fence-preserving) | R (read-only; git diff for fast-path) | both trees |

- All three treat the target repo as strictly read-only — never clone, checkout, or mutate.
- None read or write feature planning docs (`docs/<feature>/`); none emit a `status.md`.
- project-overview is walled off from `docs/domain/`; the enhancer also treats the explorer/overview skill files as read-only.
