# Project-Level Rules & Skills Convention

`.claude-user/` is **stack-agnostic** and copied into new projects **unchanged**. It ships no
language-, framework-, or architecture-specific rules. Each consuming project supplies its own
rules in **its own `.claude/` tree** — never inside `.claude-user/`. That keeps the kit pristine
and re-copyable.

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
    agents/
      rules-checker.md         <- you author (optional)
      test-runner.md           <- you author (optional)
  .claude-user/                <- COPIED UNCHANGED from this scaffold
  docs/
    architecture.md            <- optional free-form architecture seam
```

## Rule skills — named by concern

Three skills, named for **what they govern** (not for an agent). One rule has exactly one home; an
agent may read more than one skill. This avoids duplicating a shared rule across files.

| Rule skill | Governs | Read by |
|---|---|---|
| `architecture-rules` | layering, boundaries, allowed patterns, dependency direction | architect, workflow-step-planner, software-engineer (as context) |
| `coding-rules` | language/style conventions, forbidden patterns, naming | software-engineer |
| `test-rules` | test layout, naming, coverage targets, fixtures | tester |

All three are optional and independent. Author only the ones your project needs.

## Optional project agents

| Agent (`.claude/agents/`) | Job | Replaces the old scaffold's |
|---|---|---|
| `rules-checker.md` | Read-only audit of a diff against the rule skills; returns a punch list, never auto-fixes. Honors the `Project-Specific Rule Overrides` block in `<feature>.analyzed.md`. | `dotnet-rules-checker` |
| `test-runner.md` | Runs the project's test command, returns ONLY failures + build errors (keeps raw output out of the main thread). | `test-runner` |

If you also want a PostToolUse build/test hook (the old `post-cs-edit.py`), add it to your project's
`.claude/settings.json` — the scaffold no longer ships one.

## How to author a rule skill

1. Copy `.claude-user/templates/project-rules.template.md` to
   `.claude/skills/<concern>-rules/SKILL.md` (use one of the three concern names above).
2. Fill in numbered sections so planning artifacts can cite them precisely
   (e.g. "per `coding-rules` Section 3.2"). Stable section numbers = stable citations.
3. For a long ruleset, keep `SKILL.md` as a thin loader and put the full text in a sibling
   `.md` file the loader points to.

## How the crew consumes them

- **Architect** cites `architecture-rules` in `overview-plan.md` (Architecture row) and
  `analyzed.md` (decisions + Step Severity).
- **Software Engineer** reads `coding-rules` (+ `architecture-rules` for context) before writing the
  mechanical plan and during each impl step.
- **Tester** reads `test-rules` while authoring the `test.md` e2e/acceptance spec (planning-only —
  no source, no runtime role). The Software Engineer later runs the e2e gate via the project
  `test-runner` (final `plan.md` step), and `rules-checker` audits diffs if present.
- **Per-feature overrides** go in the `Project-Specific Rule Overrides` section of
  `<feature>.analyzed.md`, citing the rule skill + section being overridden.

## Invariants

- `.claude-user/` is never edited per project. All project rules live under `.claude/`.
- Every seam is optional. Missing seam → agent emits no error, proceeds.
- `docs/architecture.md` is a free-form complement to the rule skills, not a replacement.

## Agent context-access matrix

Per-agent read/write scope, derived from each agent's `tools:` frontmatter and its "What you read" /
"What you do NOT do" contract under `.claude-user/agents/`. Two repos are in play: the **working repo**
(the feature being built — where the planning crew operates) and the **target repo** (the `<path>` a
wiki agent documents — always read-only to it; its writes land in the working repo's `docs/` trees).

Legend: **R** = read · **W** = write/edit · **—** = no access · **(opt)** = optional, never blocks.

### Planning crew (feature pipeline)

| Agent | `tools:` | `docs/narrative/` | `docs/domain/` | Source code | Feature docs `docs/<feature>/` | Rule skills `.claude/skills/` | Owns / writes |
|---|---|---|---|---|---|---|---|
| **product-owner** | R only | R (opt) | — | — | R (raw requirement only) | — | **nothing** (writes no file) |
| **business-analyst** | R + W | R (opt) | — | — | R raw + others' `status.md`; **W** `requirement.md` | — | `requirement.md` |
| **architect** | R + W | R (soft) | R (soft) | — | R requirement/overview; **W** `overview-plan.md` + `analyzed.md` | R `architecture-rules` | `overview-plan.md`, `analyzed.md` |
| **software-engineer** | R + W | R (soft) | R (soft) | **R + W** | R requirement/overview/analyzed/**test.md**; **W** `plan.md` | R `coding-rules` + `architecture-rules` | `plan.md` + **production code + unit tests + e2e tests** |
| **tester** | R + W | R (opt) | — | — | R requirement; **W `test.md`** | R `test-rules` | `test.md` (e2e/acceptance spec); planning-only, no source, no runtime |
| **workflow-step-planner** | R only | — | — | — | R plan/status/analyzed | R `architecture-rules` + `coding-rules` | **nothing** (surfaces questions only) |

- `docs/architecture.md` is read by business-analyst, architect, software-engineer, tester — not by product-owner (narrative-only carve-out) or workflow-step-planner.
- Product-owner is the only role walled off from all engineering context (no domain, no architecture, no status).
- Software-engineer is the only role that writes source (production + unit + e2e tests). Tester writes no source — it authors the requirement-keyed `test.md` e2e/acceptance spec; SE turns it into automated e2e tests at the final plan step.
- "soft" = optional domain context; the agent emits a one-line advisory and proceeds if the tree is absent.

### Wiki runtime agents (domain / narrative pipeline)

| Agent | `tools:` | `docs/narrative/` | `docs/domain/` | Target repo source (`<path>`) | Owns / writes |
|---|---|---|---|---|---|
| **project-explorer** | R + W | R (soft, opt) | **W** (bootstrap; refuses if non-empty) | R (read-only walk; no git, no mutate) | `docs/domain/` |
| **project-overview** | R + W + Bash | **W** (bootstrap; refuses if non-empty) | — (neither reads nor writes) | R (read-only walk) | `docs/narrative/` |
| **project-wiki-enhancer** | R + W + Bash | **R + W** (diff-update, fence-preserving) | **R + W** (diff-update, fence-preserving) | R (read-only; git diff for fast-path) | both trees |

- All three treat the target repo as strictly read-only — never clone, checkout, or mutate.
- None read or write feature planning docs (`docs/<feature>/`); none emit a `status.md`.
- project-overview is walled off from `docs/domain/`; the enhancer also treats the explorer/overview skill files as read-only.
