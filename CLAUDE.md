# Claude Workflow Scaffold

Reusable `.claude/` folder (agents, commands, hooks, skills, templates) intended to be
copy-dropped into new projects. **No application source code lives here.**

This scaffold ships two independent workflows:

1. **Feature pipeline** — five-role crew that drives a feature from raw idea to
   approved, step-by-step implementation plan and then through code-producing steps.
2. **Domain wiki pipeline** — two runtime agents that bootstrap and then keep a
   living DDD wiki under `docs/domain/` in sync with the codebase.

The two pipelines are independent but share the same `docs/` root.

## Feature/Workflow Pipeline

Five-role crew: Product Owner, Business Analyst, Architect, Software Engineer, Tester.

1. `/feature:new <NAME>` — Product Owner brainstorms intent (no files written), hands off to BA.
2. `/feature:structure <NAME>` — four stages with one APPROVE gate per stage:
   - stage-1: Business Analyst authors `<NAME>.requirement.md` (with `Challenges to PO framing` appendix).
   - stage-2-overview: Architect authors `<NAME>.overview-plan.md` (canonical Step A / B / … list).
   - stage-2-analyzed: Architect authors `<NAME>.analyzed.md` including the 4-column Test Strategy table per R7 (`Step ID | Goal | Test kind | Owner`).
   - stage-2-plan: Software Engineer authors mechanical `<NAME>.plan.md` (no Test Strategy column there).
   After stage-2-plan APPROVE, `<NAME>.status.md` is initialized mechanically from the template.
3. `/workflow:step-start <NAME> [Step ID]` — brief for the current open step. If the step's Test Strategy row in `analyzed.md` is not `skip Tester`, spawn Tester (drafts test cases / red phase) then Software Engineer; otherwise Software Engineer only. After every requirement step is `[X]`, offer one end-of-feature Tester acceptance pass.
4. `/workflow:step-approve <NAME>` — flip current step to `[X]` after user types APPROVE.
5. `/workflow:step-handoff <NAME>` — end-of-session status update.

## Domain Wiki Pipeline

Two runtime agents own everything under `docs/domain/` (the DDD wiki — bounded
contexts, aggregates, events, commands, repositories, services, glossary, context
map). They are runtime-only and never produce planning artifacts.

1. `/project:explore <path> [branch]` — one-shot bootstrap. Spawns the
   `project-explorer` agent which walks the target repo, surfaces bounded-context
   candidates for human APPROVE, then writes the full Evans-canonical tree under
   `docs/domain/` of the working directory. Refuses if `docs/domain/` already has
   content (it is not a re-runner).
2. `/project:enhance-wiki [path]` — diff-aware update. Spawns the
   `project-wiki-enhancer` agent which reloads both its own skill and the
   `project-explorer` skill, picks a git fast-path or full-walk fallback, classifies
   changed files (`BC-affecting` / `infra — no BC impact` / `new-namespace`),
   gates any new BC on APPROVE, preserves `<!-- human:begin -->`/`<!-- human:end -->`
   fenced edits byte-for-byte, and writes only files whose bytes actually changed.
   Refuses if `docs/domain/` is missing or empty (points the user back at
   `/project:explore`).

Both commands accept a local filesystem path only — remote URLs are refused in v1.
Neither command writes outside `docs/domain/` of the working directory.

## Layout

- `.claude/agents/` — subagent definitions (product-owner, business-analyst, architect, software-engineer, tester, workflow-step-planner, dotnet-rules-checker, test-runner, project-explorer, project-wiki-enhancer)
- `.claude/commands/` — slash commands under `dotnet/`, `feature/`, `project/`, `workflow/`
- `.claude/skills/` — skills (one folder per skill, name matches owning concept)
- `.claude/templates/` — `feature.requirement.md`, `feature.overview-plan.md`, `feature.plan.md`, `feature.analyzed.md`, `feature.status.md`
- `.claude/hooks/` — `post-cs-edit.py` (PostToolUse for `Edit|Write|MultiEdit`), `session-start-banner.py`
- `docs/<FEATURE>/` — feature pipeline artifacts: `<FEATURE>.requirement.md`, `.overview-plan.md`, `.plan.md`, `.analyzed.md`, `.status.md`. Raw requirements also start here.
- `docs/domain/` — domain wiki output owned by the project-explorer / project-wiki-enhancer agents. Bootstrapped once, then diff-updated on every subsequent run.

## Conventions

- Skill folder names mirror their owning agent where applicable (e.g. `dotnet-rules` skill ↔ `dotnet-rules-checker` agent; `project-explorer` skill ↔ `project-explorer` agent; `project-wiki-enhancer` skill ↔ `project-wiki-enhancer` agent).
- `/dotnet:rule-check` and the `test-runner` agent are tooling for **downstream C# projects** that consume this scaffold — they do not run against this repo.
- The two domain-wiki agents are also tooling for downstream repos; they are runtime, never planning, and never emit a `status.md`.
- Human edits to generated `docs/domain/` files must live inside `<!-- human:begin --> ... <!-- human:end -->` fences to survive `/project:enhance-wiki`. Unfenced edits are overwritten on next enhance.

## When to use which workflow

- New product feature, need to plan & build it → **Feature pipeline** (`/feature:new` then `/feature:structure`).
- Onboarding a new repo, want a living domain wiki → **Domain wiki pipeline** (`/project:explore` once, then `/project:enhance-wiki` whenever code changes).
- Both can be used in the same repo. The feature pipeline writes under `docs/<FEATURE>/`; the wiki pipeline writes under `docs/domain/`. They never touch each other's files.

## Environment

- Windows + PowerShell 7+. Use `$env:VAR`, `$null`, backtick line-continuation.
- Hooks are Python (`python .claude/hooks/*.py`) — Python must be on PATH.
