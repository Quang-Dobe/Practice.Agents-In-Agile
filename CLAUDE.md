# Claude Workflow Scaffold

Reusable `.claude-user/` folder (agents, commands, hooks, skills, templates) intended to be
copy-dropped into new projects. **No application source code lives here.**

This repo holds **two sibling kits**:

- `.claude-user/` — the per-project feature + domain-wiki crew documented below.
- `.claude/` — a separate **root-tier cross-repo LLM-Wiki** kit (`wiki-bootstrapper` + `wiki-router` agents, `/wiki:bootstrap` and `/wiki:ask`); writes only `docs/memory/`. Independent of the crew below; see `.claude/README.md`.

Everything in this file describes the `.claude-user/` crew unless stated otherwise.

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
   - stage-2-overview: **parallel** — Architect authors `<NAME>.overview-plan.md` (canonical Step A / B / … list) and Tester authors `<NAME>.test.md` (e2e/acceptance spec, Given/When/Then, from the requirement). One combined APPROVE covers both.
   - stage-2-analyzed: Architect authors `<NAME>.analyzed.md` including the per-step Severity table (`Step ID | Severity`; reads `test.md`).
   - stage-2-plan: Software Engineer authors mechanical `<NAME>.plan.md` (no Severity column there); its final step is the E2E validation gate.
   After stage-2-plan APPROVE, `<NAME>.status.md` is initialized mechanically from the template.
3. `/workflow:step-start <NAME> [Step ID]` — brief for the current open step, then spawn the Software Engineer (the Tester has no runtime role). SE writes production code + unit tests per step; the step's Severity in `analyzed.md` drives `--bypass-approval`. The feature's final implementation step is the E2E validation gate: SE authors automated e2e tests from `<NAME>.test.md` and runs them via the project test-runner.
4. `/workflow:step-approve <NAME>` — flip current step to `[X]` after user types APPROVE.
5. `/workflow:step-handoff <NAME>` — end-of-session status update.

## Domain Wiki Pipeline

Three runtime agents own everything under `docs/domain/` and `docs/narrative/`. The DDD canonical schema (bounded contexts, aggregates, events, commands, repositories, services, glossary, context map) lives under `docs/domain/` — owned by the `project-explorer` and `project-wiki-enhancer` pair. The human-readable narrative tree (one-page repo overview + one walkthrough per bounded context) lives under `docs/narrative/` — owned by the new `project-overview` agent. All three are runtime-only and never produce planning artifacts. The pipeline runs in two passes: narrative first (so a non-tech reader can follow the business flow), then schema (with narrative as soft input where present).

All three domain-wiki agents are **fully agent-driven**: they print their bounded-context decisions for the audit trail and then write automatically — no APPROVE gate, no halt, no interactive pause anywhere in this pipeline. The only thing that stops a run is the idempotency / pre-flight refusal (bootstrap refuses on a non-empty tree; enhance-wiki refuses when both trees are missing).

1. `/project:explore <path> [branch]` — one-shot bootstrap. Spawns the
   `project-explorer` agent which walks the target repo, prints bounded-context
   candidates for the audit trail, then writes the full Evans-canonical tree under
   `docs/domain/` of the working directory. Refuses if `docs/domain/` already has
   content (it is not a re-runner). Reads `docs/narrative/architecture.md` and `docs/narrative/<bc>/walkthrough.md` as **soft input** when present, augmenting BC candidate ordering and per-aggregate description seeds; behaviour is byte-identical to today when `docs/narrative/` is absent.
2. `/project:overview <path> [branch]` — one-shot narrative bootstrap. Spawns the `project-overview` agent which walks the target repo, prints bounded-context candidates for the audit trail, then writes `docs/narrative/architecture.md` (one-page repo overview) plus `docs/narrative/<bc>/walkthrough.md` per detected BC (Mermaid sequence diagram + 3-paragraph intro + per-endpoint / handler / worker drill-down) under `docs/narrative/` of the working directory. Refuses if `docs/narrative/` already has content (it is not a re-runner; subsequent narrative refreshes are owned by `/project:enhance-wiki`).
3. `/project:enhance-wiki [path]` — **dual-pass**
   diff-aware update. Spawns the `project-wiki-enhancer` agent which reloads
   its own skill, then the `project-overview` skill, then the
   `project-explorer` skill (three skills, locked order), picks a per-pass
   git fast-path or full-walk fallback, refreshes `docs/narrative/` first
   then `docs/domain/`, classifies changed files
   (`BC-affecting` / `infra — no BC impact` / `new-namespace`), auto-creates any
   new BC after printing the candidate report, preserves
   `<!-- human:begin -->`/`<!-- human:end -->` fenced edits byte-for-byte
   in **both** trees, and writes only files whose bytes actually changed.
   Refuses at the command layer
   when **both** `docs/narrative/` and `docs/domain/` are missing; prints
   a one-line symmetric advisory when exactly one is missing and proceeds
   with the present-tree pass. The narrative diff-aware update is part of this command.

Both commands accept a local filesystem path only — remote URLs are refused in v1.
Neither command writes outside its own output tree (`/project:overview` writes only `docs/narrative/`; `/project:explore` and `/project:enhance-wiki` write only `docs/domain/`).

**Migration story (no-op for existing trees).** Nothing existing moves. The canonical schema continues to live at `docs/domain/` exactly as before; no rename, no folder shift, no path change to any frontmatter field. The only visible difference for a downstream repo is the *appearance* of a new tree at `docs/narrative/` *if and only if* the user opts in by invoking `/project:overview`. Repos that never invoke the new command are byte-identical before and after this change. The fences inside `docs/narrative/` are now load-bearing on the diff path (no longer inert).

## Layout

- `.claude-user/agents/` — subagent definitions (product-owner, business-analyst, architect, software-engineer, tester, workflow-step-planner, project-explorer, project-wiki-enhancer, project-overview)
- `.claude-user/commands/` — slash commands under `feature/`, `project/`, `workflow/`
- `.claude-user/skills/` — skills (one folder per skill, name matches owning concept)
- `.claude-user/templates/` — `feature.requirement.md`, `feature.overview-plan.md`, `feature.test.md`, `feature.plan.md`, `feature.analyzed.md`, `feature.status.md`, `project-rules.template.md` (copy-me example for a project rule skill)
- `.claude-user/CONVENTIONS.md` — how a consuming project supplies its own rule skills + optional agents under its `.claude/` tree (the stack-specific seam this kit deliberately omits); also holds the per-agent context-access matrix
- `.claude-user/hooks/` — `session-start-banner.py`
- `docs/<FEATURE>/` — feature pipeline artifacts: `<FEATURE>.requirement.md`, `.overview-plan.md`, `.plan.md`, `.analyzed.md`, `.status.md`. Raw requirements also start here.
- `docs/domain/` — domain wiki output owned by the project-explorer / project-wiki-enhancer agents. Bootstrapped once, then diff-updated on every subsequent run.
- `docs/narrative/` — human-readable narrative tree owned by the `project-overview` agent at bootstrap and by `/project:enhance-wiki` on every subsequent code change. One file per bounded context (`<bc>/walkthrough.md`) plus a top-level `architecture.md`.
- `.claude-user/agents/project-overview.md` — runtime agent definition for the narrative bootstrap. Mirrors the `project-explorer` / `project-wiki-enhancer` sibling pattern.
- `.claude/` — the sibling root-tier LLM-Wiki kit (out of scope for this file). Documented in `.claude/README.md`.

## Conventions

- Skill folder names mirror their owning agent where applicable (e.g. `project-explorer` skill ↔ `project-explorer` agent; `project-wiki-enhancer` skill ↔ `project-wiki-enhancer` agent; `project-overview` skill ↔ `project-overview` agent).
- **Stack-agnostic by design.** This scaffold ships **no** stack- or architecture-specific skills (no `.NET` rules, no language-bound test runner, no per-language edit hook) and is copied into new projects **unchanged**. The consuming project supplies rules in **its own `.claude/` tree** — never inside `.claude-user/`. The crew reads these optional seams (proceeds, never blocks, when absent):
  - `docs/architecture.md` — free-form architecture notes.
  - Concern-named rule skills under `.claude/skills/`: `architecture-rules` (architect, step-planner, SE), `coding-rules` (SE), `test-rules` (tester).
  - Optional project agents `.claude/agents/rules-checker.md` and `.claude/agents/test-runner.md`.
  - Full convention + agent→skill map: **`.claude-user/CONVENTIONS.md`**. Author a rule skill by copying `.claude-user/templates/project-rules.template.md` into `.claude/skills/<concern>-rules/SKILL.md`.
- The three domain-wiki agents (`project-explorer`, `project-wiki-enhancer`, `project-overview`) are tooling for downstream repos; they are runtime, never planning, and never emit a `status.md`.
- Human edits to generated `docs/domain/` and `docs/narrative/` files must live inside `<!-- human:begin --> ... <!-- human:end -->` fences to survive any future regeneration. Fences are load-bearing in BOTH trees: `docs/domain/` fences survive `/project:enhance-wiki`'s domain pass, and `docs/narrative/` fences survive its narrative pass byte-for-byte.

## When to use which workflow

- New product feature, need to plan & build it → **Feature pipeline** (`/feature:new` then `/feature:structure`).
- Onboarding a new repo, want a living domain wiki → **Domain wiki pipeline**. Run `/project:overview` first to produce a plain-language narrative under `docs/narrative/` (skip if you only want the canonical schema). Then run `/project:explore` once to produce the canonical schema under `docs/domain/` (it will read the narrative as soft input when present). Use `/project:enhance-wiki` whenever code changes to refresh both `docs/narrative/` and `docs/domain/` in one command.
- Both can be used in the same repo. The feature pipeline writes under `docs/<FEATURE>/`; the wiki pipeline writes under `docs/domain/`. They never touch each other's files.
  - **Carve-out (the single coupling seam).** The feature pipeline does not otherwise write the wiki trees, with exactly one exception: `/workflow:step-handoff` unconditionally invokes `/project:enhance-wiki` at session close. That invocation is subject to `/project:enhance-wiki`'s own missing-both-trees refusal. Because `/project:enhance-wiki` is fully agent-driven (no gate), it never blocks handoff finalization except on an unexpected error; it either succeeds (writes / clean no-op) or refuses for missing-both-trees (noted, handoff continues). Outside this one documented seam, the pipelines remain independent and the 'never touch each other's files' invariant holds.

## Environment

- Windows + PowerShell 7+. Use `$env:VAR`, `$null`, backtick line-continuation.
- Hooks are Python (`python .claude-user/hooks/*.py`) — Python must be on PATH.
