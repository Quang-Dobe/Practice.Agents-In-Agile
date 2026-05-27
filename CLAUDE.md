# Claude Workflow Scaffold

Reusable `.claude/` folder (agents, commands, hooks, skills, templates) intended to be
copy-dropped into new projects. **No application source code lives here.**

This scaffold ships two independent workflows:

1. **Feature pipeline** — five-role crew that drives a feature from raw idea to
   approved, step-by-step implementation plan and then through code-producing steps.
2. **Domain wiki pipeline** — two runtime agents that bootstrap and then keep a
   living DDD wiki under `docs/domain/` in sync with the codebase.

The two pipelines are independent but share the same `docs/` root — with **one documented exception**: `/workflow:step-handoff` invokes `/project:enhance-wiki` at session close to keep the wiki in sync (see the carve-out under *When to use which workflow*).

## Feature/Workflow Pipeline

Five-role crew: Product Owner, Business Analyst, Architect, Software Engineer, Tester.

1. `/feature:new <NAME>` — Product Owner brainstorms intent (no files written), hands off to BA.
2. `/feature:structure <NAME>` — four stages with one APPROVE gate per stage:
   - stage-1: Business Analyst authors `<NAME>.requirement.md` (with `Challenges to PO framing` appendix).
   - stage-2-overview: Architect authors `<NAME>.overview-plan.md` (canonical Step A / B / … list).
   - stage-2-analyzed: Architect authors `<NAME>.analyzed.md` including the 5-column Test Strategy table per R7 (`Step ID | Goal | Test kind | Owner | Severity`).
   - stage-2-plan: Software Engineer authors mechanical `<NAME>.plan.md` (no Test Strategy column there).
   After stage-2-plan APPROVE, `<NAME>.status.md` is initialized mechanically from the template.
3. `/workflow:step-start <NAME> [Step ID]` — brief for the current open step. If the step's Test Strategy row in `analyzed.md` is not `skip Tester`, spawn Tester (drafts test cases / red phase) then Software Engineer; otherwise Software Engineer only. After every requirement step is `[X]`, offer one end-of-feature Tester acceptance pass.
4. `/workflow:step-approve <NAME>` — flip current step to `[X]` after user types APPROVE.
5. `/workflow:step-handoff <NAME>` — end-of-session status update.

## Domain Wiki Pipeline

Three runtime agents own everything under `docs/domain/` and `docs/narrative/`. The DDD canonical schema (bounded contexts, aggregates, events, commands, repositories, services, glossary, context map) lives under `docs/domain/` — owned by the `project-explorer` and `project-wiki-enhancer` pair. The human-readable narrative tree (one-page repo overview + one walkthrough per bounded context) lives under `docs/narrative/` — owned by the new `project-overview` agent. All three are runtime-only and never produce planning artifacts. The pipeline runs in two passes: narrative first (so a non-tech reader can follow the business flow), then schema (with narrative as soft input where present).

1. `/project:explore <path> [branch]` — one-shot bootstrap. Spawns the
   `project-explorer` agent which walks the target repo, surfaces bounded-context
   candidates for human APPROVE, then writes the full Evans-canonical tree under
   `docs/domain/` of the working directory. Refuses if `docs/domain/` already has
   content (it is not a re-runner). Reads `docs/narrative/architecture.md` and `docs/narrative/<bc>/walkthrough.md` as **soft input** when present, augmenting BC candidate ordering and per-aggregate description seeds; behaviour is byte-identical to today when `docs/narrative/` is absent.
2. `/project:overview <path> [branch]` — one-shot narrative bootstrap. Spawns the `project-overview` agent which walks the target repo, surfaces bounded-context candidates for human APPROVE, then writes `docs/narrative/architecture.md` (one-page repo overview) plus `docs/narrative/<bc>/walkthrough.md` per detected BC (Mermaid sequence diagram + 3-paragraph intro + per-endpoint / handler / worker drill-down) under `docs/narrative/` of the working directory. Refuses if `docs/narrative/` already has content (it is not a re-runner; subsequent narrative refreshes are owned by `/project:enhance-wiki`).
3. `/project:enhance-wiki [path] [--bypass-approval]` — **dual-pass**
   diff-aware update. Spawns the `project-wiki-enhancer` agent which reloads
   its own skill, then the `project-overview` skill, then the
   `project-explorer` skill (three skills, locked order), picks a per-pass
   git fast-path or full-walk fallback, refreshes `docs/narrative/` first
   then `docs/domain/`, classifies changed files
   (`BC-affecting` / `infra — no BC impact` / `new-namespace`), gates any
   new BC on APPROVE (per pass, auto-skipping when empty), preserves
   `<!-- human:begin -->`/`<!-- human:end -->` fenced edits byte-for-byte
   in **both** trees, and writes only files whose bytes actually changed.
   `--bypass-approval` is an opt-in flag that auto-approves non-critical
   changes for low-friction / CI runs and exits 1 with a locked diagnostic
   when any of the four critical categories fires (new BC, BC renamed, BC
   removed, write inside a fenced block). Refuses at the command layer
   when **both** `docs/narrative/` and `docs/domain/` are missing; prints
   a one-line symmetric advisory when exactly one is missing and proceeds
   with the present-tree pass. F1 (the deferred narrative diff-aware
   updater) is shipped as part of this command.

Both commands accept a local filesystem path only — remote URLs are refused in v1.
Neither command writes outside its own output tree (`/project:overview` writes only `docs/narrative/`; `/project:explore` and `/project:enhance-wiki` write only `docs/domain/`).

**Migration story (no-op for existing trees).** Nothing existing moves. The canonical schema continues to live at `docs/domain/` exactly as before; no rename, no folder shift, no path change to any frontmatter field. The only visible difference for a downstream repo is the *appearance* of a new tree at `docs/narrative/` *if and only if* the user opts in by invoking `/project:overview`. Repos that never invoke the new command are byte-identical before and after this change. The fences inside `docs/narrative/` are now load-bearing on the diff path (no longer inert).

## Layout

- `.claude/agents/` — subagent definitions (product-owner, business-analyst, architect, software-engineer, tester, workflow-step-planner, dotnet-rules-checker, test-runner, project-explorer, project-wiki-enhancer, project-overview)
- `.claude/commands/` — slash commands under `dotnet/`, `feature/`, `project/`, `workflow/`
- `.claude/skills/` — skills (one folder per skill, name matches owning concept)
- `.claude/templates/` — `feature.requirement.md`, `feature.overview-plan.md`, `feature.plan.md`, `feature.analyzed.md`, `feature.status.md`
- `.claude/hooks/` — `post-cs-edit.py` (PostToolUse for `Edit|Write|MultiEdit`), `session-start-banner.py`
- `docs/<FEATURE>/` — feature pipeline artifacts: `<FEATURE>.requirement.md`, `.overview-plan.md`, `.plan.md`, `.analyzed.md`, `.status.md`. Raw requirements also start here.
- `docs/domain/` — domain wiki output owned by the project-explorer / project-wiki-enhancer agents. Bootstrapped once, then diff-updated on every subsequent run.
- `docs/narrative/` — human-readable narrative tree owned by the `project-overview` agent at bootstrap and by `/project:enhance-wiki` on every subsequent code change. One file per bounded context (`<bc>/walkthrough.md`) plus a top-level `architecture.md`.
- `.claude/agents/project-overview.md` — runtime agent definition for the narrative bootstrap. Mirrors the `project-explorer` / `project-wiki-enhancer` sibling pattern.

## Conventions

- Skill folder names mirror their owning agent where applicable (e.g. `dotnet-rules` skill ↔ `dotnet-rules-checker` agent; `project-explorer` skill ↔ `project-explorer` agent; `project-wiki-enhancer` skill ↔ `project-wiki-enhancer` agent; `project-overview` skill ↔ `project-overview` agent).
- `/dotnet:rule-check` and the `test-runner` agent are tooling for **downstream C# projects** that consume this scaffold — they do not run against this repo.
- The three domain-wiki agents (`project-explorer`, `project-wiki-enhancer`, `project-overview`) are tooling for downstream repos; they are runtime, never planning, and never emit a `status.md`.
- Human edits to generated `docs/domain/` and `docs/narrative/` files must live inside `<!-- human:begin --> ... <!-- human:end -->` fences to survive any future regeneration. Fences are load-bearing in BOTH trees: `docs/domain/` fences survive `/project:enhance-wiki`'s domain pass, and `docs/narrative/` fences survive its narrative pass byte-for-byte.

## When to use which workflow

- New product feature, need to plan & build it → **Feature pipeline** (`/feature:new` then `/feature:structure`).
- Onboarding a new repo, want a living domain wiki → **Domain wiki pipeline**. Run `/project:overview` first to produce a plain-language narrative under `docs/narrative/` (skip if you only want the canonical schema). Then run `/project:explore` once to produce the canonical schema under `docs/domain/` (it will read the narrative as soft input when present). Use `/project:enhance-wiki` whenever code changes to refresh both `docs/narrative/` and `docs/domain/` in one command.
- Both can be used in the same repo. The feature pipeline writes under `docs/<FEATURE>/`; the wiki pipeline writes under `docs/domain/`. They never touch each other's files.
  - **Carve-out (the single coupling seam).** The feature pipeline does not otherwise write the wiki trees, with exactly one exception: `/workflow:step-handoff` unconditionally invokes `/project:enhance-wiki` at session close (Ask 3 of the `enhance-workflow-step-start` feature). That invocation is subject to `/project:enhance-wiki`'s own missing-both-trees refusal, and it **blocks handoff finalization** if `/project:enhance-wiki` exits 1 or is APPROVE-pending. Outside this one documented seam, the pipelines remain independent and the 'never touch each other's files' invariant holds.

## Environment

- Windows + PowerShell 7+. Use `$env:VAR`, `$null`, backtick line-continuation.
- Hooks are Python (`python .claude/hooks/*.py`) — Python must be on PATH.
