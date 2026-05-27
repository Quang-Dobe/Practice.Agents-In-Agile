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
  `analyzed.md` (decisions + Test Strategy).
- **Software Engineer** reads `coding-rules` (+ `architecture-rules` for context) before writing the
  mechanical plan and during each impl step.
- **Tester** reads `test-rules` for test layout/coverage and hands the end-of-feature run to
  `rules-checker` / `test-runner` if present.
- **Per-feature overrides** go in the `Project-Specific Rule Overrides` section of
  `<feature>.analyzed.md`, citing the rule skill + section being overridden.

## Invariants

- `.claude-user/` is never edited per project. All project rules live under `.claude/`.
- Every seam is optional. Missing seam → agent emits no error, proceeds.
- `docs/architecture.md` is a free-form complement to the rule skills, not a replacement.
