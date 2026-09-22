# Claude Workflow Scaffold

Reusable `root/.claude/` folder (agents, commands, skills, templates) that is the
**source-of-truth for the root tier** — installed to user scope (`~/.claude/`) via `install.ps1`,
not copied per-project. Agents are **thin**: each declares a `skills:` manifest and the harness
preloads those concern-named skills; the consuming repo supplies stack-specific rules under its own
`.claude/`. **No application source code lives here.** (See `docs/enhance-agent-skills/` for the
design rationale and `root/.claude/CONVENTIONS.md` for the two-tier model.)

This file covers `root/.claude/` — the crew — and nothing else.

> `project/.claude/` is a separate kit that wraps this one. It is **out of scope here**, and
> documented in `project/.claude/README.md`. Two facts about it are load-bearing on the crew,
> so they are stated where they apply below: its `/wiki:enhance` **calls** the crew's
> `/project:overview`, `/project:explore`, and `/project:update`, and it is the only writer of
> `repo-layout.md`. Change either seam and read that README first.

This scaffold ships three independent workflows:

1. **Feature pipeline** — five-role crew that drives a feature from raw idea to
   approved, step-by-step implementation plan and then through code-producing steps.
2. **LLM wiki pipeline** — three runtime agents that bootstrap and then keep a
   living wiki under `docs/narrative/` and `docs/domain/` in sync with the codebase.
3. **PR review loop** — a read-only analyst agent that turns hand-written PR
   review notes into evidenced findings, then, after you fix the code, into
   rule sections inside this repo's own `.claude/skills/`.

The three pipelines are independent. They share the same `docs/` root and never write each other's files.

## Feature/Workflow Pipeline

Five-role crew: Product Owner, Business Analyst, Architect, Software Engineer, Tester.

1. `/feature:new <NAME>` — Product Owner brainstorms intent (no files written), hands off to BA.
2. `/feature:structure <NAME>` — four stages with one APPROVE gate per stage. **No stage is tracked by a checklist**: the command reads which artifact files exist in `docs/<NAME>/`, and each artifact carries one `> Status:` line that main Claude flips to `APPROVED <date>`.
   - stage-1: Business Analyst authors **two new** files — `<NAME>.requirement.md` holding only the final requirement (Goal / Current behavior when existing behavior changes / In scope / Out of scope / Success criteria — happy-path outcomes only / Constraints), and `<NAME>.requirement-trace.md` holding one append-only `## Decisions` table in plain words. `<NAME>.raw-requirement.md` is **never overwritten**. Downstream agents plan and test from `requirement.md`; a trace file is never a planning input. **When both `docs/domain/` and `docs/narrative/` are absent**, the Architect first runs a read-only codebase recon pass (reads source as-needed) and hands the BA a plan-level Current Behavior Brief — business flow plus related components and their roles, no paths and no code; `path:line` stays in chat and is persisted nowhere. The BA never reads source, and an optional bounded `[Architect Q]` round (≤1) lets it ask the Architect. If either wiki tree exists, the BA grounds on it and no recon runs.
   - stage-2-overview: **parallel** — Architect authors `<NAME>.overview-plan.md` (Purpose / What is exposed / Components / Happy-path flow / Key technical decisions / the canonical Step A / B / … table with the `SC-n` each step covers) plus `<NAME>.overview-plan-trace.md` (one row per technical decision: options, chosen, why). Tester authors `<NAME>.test.md` — happy cases first, each flagged `[Happy Case]` and covering one `SC-n`, then edge cases the Tester explores from Constraints / scope / Current behavior (each citing its anchor line), then manual ad-hoc checks. One combined APPROVE covers overview-plan and test.
   - stage-2-analyzed: Architect authors the slim `<NAME>.analyzed.md` — exactly three sections: the per-step Severity table (`Step ID | Severity`; reads `test.md`), Risks (≤5), Rule overrides.
   - stage-2-plan: Software Engineer authors `<NAME>.plan.md` at component-design level — a Component map (owned files per component, disjoint; `State` column; `Depends on`; the contract each provides), a Shared files list owned by main Claude, one section per component, and a final E2E validation gate step.
   After stage-2-plan APPROVE, `<NAME>.status.md` is initialized mechanically from the template with one row per `plan.md` step — no planning rows.
3. `/feature:implement <NAME> [Step ID]` — the build loop, one **wave** at a time. A wave = every `pending` step in `status.md` whose `Depends on` steps are approved. **Phase 1** briefs the wave (read from `status.md` only — never `requirement.md`); **Phase 2** spawns one Software Engineer per step in a single message, each with `model: "sonnet"` overriding the agent's `opus` header (the Tester has no runtime role); **Phase 2b** merges their reports, applies the `Shared files` requests (main Claude is their only writer), relays a request to another finished agent via `SendMessage`, and runs build + tests **once**; **Phase 3** flips every row in the wave to `approved <date>` on one APPROVE — no partial approve — then moves to the next wave. Severity in `analyzed.md` drives `--bypass-approval`: a wave auto-approves only when every step in it is `minor` or `medium`. A blocking question is classified 0-3 by impact, the document it changes is updated, whatever sits below it is patched or regenerated (step IDs change or >1/3 rows change → regenerate, from the code as it is now), a trace row is recorded, and each changed document re-enters its own APPROVE gate. The feature's final step is the E2E validation gate: SE authors automated e2e tests from `<NAME>.test.md`, happy cases first, and runs them via the project test-runner.

Walkthrough: `docs/workflow-feature-pipeline.md`

## LLM Wiki Pipeline

**Prefix warning.** These three commands read `project:`, but they are **root-tier** commands living in `root/.claude/commands/project/`. The prefix does not mean the project tier. The project tier's own wiki commands are `/wiki:*`, and they are out of scope here.

Three runtime agents own everything under `docs/domain/` and `docs/narrative/`. The DDD canonical schema (bounded contexts, aggregates, events, commands, repositories, services, glossary, context map) lives under `docs/domain/` — owned by the `project-explorer` and `project-update` pair. The human-readable narrative tree (one-page repo overview + one walkthrough per bounded context) lives under `docs/narrative/` — owned by the new `project-overview` agent. All three are runtime-only and never produce planning artifacts. The pipeline runs in two passes: narrative first (so a non-tech reader can follow the business flow), then schema (with narrative as soft input where present).

All three domain-wiki agents are **fully agent-driven**: they print their bounded-context decisions for the audit trail and then write automatically — no APPROVE gate, no halt, no interactive pause anywhere in this pipeline. The only thing that stops a run is the idempotency / pre-flight refusal (bootstrap refuses on a non-empty tree; update refuses when both trees are missing).

1. `/project:explore <path> [branch]` — one-shot bootstrap. Spawns the
   `project-explorer` agent which walks the target repo, prints bounded-context
   candidates for the audit trail, then writes the full Evans-canonical tree under
   `docs/domain/` of the working directory. Refuses if `docs/domain/` already has
   content (it is not a re-runner). Reads `docs/narrative/architecture.md` and `docs/narrative/<bc>/walkthrough.md` as **soft input** when present, augmenting BC candidate ordering and per-aggregate description seeds; behaviour is byte-identical to today when `docs/narrative/` is absent.
2. `/project:overview <path> [branch]` — one-shot narrative bootstrap. Spawns the `project-overview` agent which walks the target repo, prints bounded-context candidates for the audit trail, then writes `docs/narrative/architecture.md` (one-page repo overview) plus `docs/narrative/<bc>/walkthrough.md` per detected BC (Mermaid sequence diagram + 3-paragraph intro + per-endpoint / handler / worker drill-down) under `docs/narrative/` of the working directory. Refuses if `docs/narrative/` already has content (it is not a re-runner; subsequent narrative refreshes are owned by `/project:update`).
3. `/project:update [path]` — **dual-pass**
   diff-aware update. Spawns the `project-update` agent which reloads
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

**Scan scope — `repo-layout.md` (opt-in).** A central `repo-layout.md` at the wiki scan root (cross-repo root in multi-repo mode; the repo root in single-repo mode) declares per-repo code roots (a strict allowlist), extra excludes, and bounded-context labels. The three crew agents load the cross-cutting `repo-layout` skill and scan only the declared roots; absent manifest → today's heuristics (byte-identical). **The crew never writes this file** — it is single-writer, and the writer is the wrapping kit. A new source-bearing dir not yet declared is provisionally scanned + flagged, never silently skipped.

**Many wikis in one tree.** A caller may run these commands once per sub-project, each with `CWD` set to that sub-project's folder. The crew commands are unchanged by that — each run sees one repo and writes one pair of trees under its own `CWD`. Nothing here needs to know how many nodes the caller walks.

Both commands accept a local filesystem path only — remote URLs are refused in v1.
Neither command writes outside its own output tree (`/project:overview` writes only `docs/narrative/`; `/project:explore` and `/project:update` write only `docs/domain/`).

**Called from outside.** These three commands are also invoked by the wrapping kit as one pass of a bigger sync. That caller writes trees of its own (`docs/memory/`, `docs/references.md`) which the crew never touches — so never assume a `docs/` folder the crew did not write is stale.

**Migration story (no-op for existing trees).** Nothing existing moves. The canonical schema continues to live at `docs/domain/` exactly as before; no rename, no folder shift, no path change to any frontmatter field. The only visible difference for a downstream repo is the *appearance* of a new tree at `docs/narrative/` *if and only if* the user opts in by invoking `/project:overview`. Repos that never invoke the new command are byte-identical before and after this change. The fences inside `docs/narrative/` are now load-bearing on the diff path (no longer inert).

**Drawing is a separate command.** `/diagram:build [root] [--effort low|medium|high] [--html]` reads
`docs/references.md` and writes only diagram files — `references.diagram.excalidraw` and
`references.diagram.png` always, plus `references.diagram.svg` and `references-diagram.html` under
`--html`. Effort defaults to `low`. `/wiki:enhance` draws nothing; it finishes by recommending the
command and listing its options.

Walkthrough: `docs/workflow-llm-wiki.md`

## PR Review Loop

Two root-tier commands turn PR review feedback into durable, repo-local rules.

1. `/pr-review:analyze --feature <feature> [--review <stem>]` — reads the hand-written notes under `docs/<feature>/pr-review/`, spawns the read-only `pr-review-analyst` to segment them and attach `file:line` evidence, appends findings to `<stem>.pr-review.ledger.md`, then has a `sonnet` subagent render `<stem>.pr-review.html`. Gate-free. Gives **no** validity verdict — every finding is shown and the human judges.
2. `/pr-review:learn --feature <feature> [--review <stem>]` — takes ledger rows where `status: fixed` and `promoted: no`, has the analyst draft one rule section each, shows every draft, and after `APPROVE` appends them to the **consuming repo's** `.claude/skills/<concern>/SKILL.md`. Never writes a rule into the root tier.

Load-bearing rules of this pipeline:

- **The ledger is upstream.** The HTML is always rendered from the ledger, never edited directly. A sweep re-renders whenever the ledger is newer than the page.
- **The ledger owns finding IDs.** Input is free prose, so a later run never re-segments a finding already in the ledger — it re-matches on the verbatim quote text. Only new comments get new IDs.
- **Evidence has three states**, not two: `Located`, `Not code-locatable`, `Not found`. Root cause is written **only** when the state is `Located`; otherwise the literal `not established — no code evidence`. A slot that must be filled invites fabrication.
- **The stored snippet goes stale after the fix, on purpose.** It records what was wrong at review time.
- **`evidence-detail` and the snippet may cover different widths.** `evidence-detail` names the full range the claim rests on; the snippet shows only what fits under the 12-line cap, centred on the anchor. A wider range than snippet is correct, not a mismatch.
- **`status` drives what the page shows collapsed.** The page is one HTML file holding one card per finding, each at its own `#PR-NN` anchor. An `open` finding is expanded on first paint; `fixed` and `rejected` are collapsed. So the list shrinks as you work through it, and flipping `status` in the ledger is the only thing you need to do to change the page.
- **Every finding carries a short `title`.** Max 60 characters, plain words, names the problem and not the fix. It is the only text a collapsed card shows, so a bad title makes a card unskippable.
- **Hints are optional and bounded.** Zero to four per finding, each a hard word from that card with a plain meaning of at most 12 words. Zero is a correct answer — a hint invented to fill the row is noise.
- **A new open concern must be wired** into a reserved skill's `## Also load` list. Only the three reserved concerns are auto-discovered; an unwired skill is a silent dead rule.
- Design record: `docs/superpowers/specs/2026-08-05-pr-review-loop-design.md` — **untracked**. `docs/` is git-ignored, so this file is local to your clone and will not be there in a fresh one.

Walkthrough: `docs/workflow-pr-review-loop.md`

## Layout

- `root/.claude/agents/` — subagent definitions (product-owner, business-analyst, architect, software-engineer, tester, project-explorer, project-update, project-overview, pr-review-analyst, html-generator)
- `root/.claude/commands/` — slash commands under `feature/`, `pr-review/`, `project/`
- `root/.claude/skills/` — **shared** skills only, one folder per skill: `project-seams`, `prompt-defense`, `repo-layout`, `library-knowledge`, plus the three wiki skills (`project-explorer`, `project-overview`, `project-update`). A procedure used by exactly one agent lives inside that agent's own file — see `CONVENTIONS.md` rule 5.
- `root/.claude/templates/` — `feature.requirement.md`, `feature.requirement-trace.md`, `feature.overview-plan.md`, `feature.overview-plan-trace.md`, `feature.test.md`, `feature.plan.md`, `feature.analyzed.md`, `feature.status.md`, `project-rules.template.md` (copy-me example for a project rule skill), `pr-review.ledger.md`, `pr-review.html`
- `root/.claude/output-styles/` — versioned output styles installed to `~/.claude/output-styles/`: `ELI5.md` (the globally active style `[R-COMMUNICATE]` defers to)
- `root/.claude/settings.json` — declares only `outputStyle: ELI5`; `install.ps1` merges it key by key into `~/.claude/settings.json` (never replaces it, so your `model` / `enabledPlugins` / `theme` survive)
- `root/.claude/CLAUDE.md` — versioned **Global Engagement Rules** (general R-XX rules only, no kit docs; source of truth for `~/.claude/CLAUDE.md`). `install.ps1` replaces the profile copy on every run (previous version kept as `CLAUDE.md.bak` when content changes).
- `root/.claude/CONVENTIONS.md` — how a consuming project supplies its own rule skills + optional agents under its `.claude/` tree (the stack-specific seam this kit deliberately omits); also holds the per-agent context-access matrix
- `docs/<FEATURE>/` — feature pipeline artifacts: `<FEATURE>.raw-requirement.md` (yours, never overwritten), `.requirement.md` (final requirement, flat), `.requirement-trace.md` (the decisions behind it), `.overview-plan.md`, `.overview-plan-trace.md`, `.test.md`, `.analyzed.md`, `.plan.md`, `.status.md`. Each final artifact carries one `> Status:` line; each trace file is one append-only `## Decisions` table.
- `docs/domain/` — the LLM wiki's canonical DDD schema tree, owned by the project-explorer / project-update agents. Bootstrapped once, then diff-updated on every subsequent run.
- `docs/narrative/` — human-readable narrative tree owned by the `project-overview` agent at bootstrap and by `/project:update` on every subsequent code change. One file per bounded context (`<bc>/walkthrough.md`) plus a top-level `references.md`.
- `root/.claude/agents/project-overview.md` — runtime agent definition for the narrative bootstrap. Mirrors the `project-explorer` / `project-update` sibling pattern.
- `root/.claude/commands/pr-review/` — `analyze.md`, `learn.md`
- `root/.claude/agents/pr-review-analyst.md` — read-only agent for the PR review loop
- `root/.claude/templates/pr-review.ledger.md`, `root/.claude/templates/pr-review.html` — ledger shape + card page shell
- `docs/<FEATURE>/pr-review/` — your review notes, plus the generated ledger and card page per review file
- `project/.claude/` — the wrapping kit. **Out of scope for this file**; see `project/.claude/README.md`.

## Conventions

- **Thin agents + concern-named skills.** Feature-crew agents hold no procedure — only identity, a `skills:` manifest, and an ownership boundary. The *how* lives in concern-named skills (one capability per skill); the *which-agent-at-which-stage* lives in the commands. One agent loads many skills, and a skill may be shared by many agents. (The three **wiki** skills still mirror their owning agent name — `project-explorer` skill ↔ `project-explorer` agent — because each is a single-owner runtime skill.)
- **Stack-agnostic by design.** This scaffold ships **no** stack- or architecture-specific skills (no `.NET` rules, no language-bound test runner, no per-language edit hook). The generic tier is installed to user scope **unchanged**; the consuming project supplies rules in **its own `.claude/` tree** — never inside `root/.claude/`. Project skills use **reserved** concerns (`architecture-rules`, `coding-rules`, `test-rules`) plus an **open** set (`dotnet-patterns`, `react-patterns`, …); see `root/.claude/CONVENTIONS.md`. The crew reads these optional seams (proceeds, never blocks, when absent):
  - `docs/references.md` — free-form architecture notes.
  - Concern-named rule skills under `.claude/skills/`: `architecture-rules` (architect, SE), `coding-rules` (SE), `test-rules` (tester).
  - Optional project agents `.claude/agents/rules-checker.md` and `.claude/agents/test-runner.md`.
  - Full convention + agent→skill map: **`root/.claude/CONVENTIONS.md`**. Author a rule skill by copying `root/.claude/templates/project-rules.template.md` into `.claude/skills/<concern>-rules/SKILL.md`.
- **HTML is written by one agent.** `html-generator` belongs to no pipeline. Every `.html` / `.htm` write, at any size, goes to it via `subagent_type: "html-generator"` per `[R-HTML-AGENT]` — never a bare `model: "sonnet"` spawn, because `subagent_type: "fork"` ignores `model:` and hands back a copy of main Claude. It pins `model: sonnet` in its own frontmatter and carries the dark-default / theme-aware / plain-words rules inline, so a caller passes only the output path and the facts the page must show.
- **Every spawn names its owned files** (`[R-HTML-AGENT]`). An agent writes only inside that list; a change it needs elsewhere goes back under `## Requests to main` in its **final report**, and main Claude applies it or relays it with `SendMessage`. No crew agent has `SendMessage` — there is no live channel back, the report is it. Operative contract: `root/.claude/CONVENTIONS.md` `## Spawn contract`.
- **No comments in generated code by default.** The Software Engineer writes production code **without** explanatory comments unless the user explicitly asks for them (self-documenting names + structure instead). Operative contract lives in the `software-engineer` agent; this bullet is the doc pointer.
- **Code is the single source of truth for the wiki crew.** `project-explorer`, `project-overview`, and `project-update` derive every logic / invariant / `file:line` fact from **code only** — never assume behaviour from a comment, docstring, or XML-doc. Comments may *seed* naming / plain-language descriptions but **lose every conflict** with code. Operative contract: the `project-explorer` skill `## Comment policy (code is the single source of truth)`, cited by reference from the other two.
- The three domain-wiki agents (`project-explorer`, `project-update`, `project-overview`) are tooling for downstream repos; they are runtime, never planning, and never emit a `status.md`.
- Human edits to generated `docs/domain/` and `docs/narrative/` files must live inside `<!-- human:begin --> ... <!-- human:end -->` fences to survive any future regeneration. Fences are load-bearing in BOTH trees: `docs/domain/` fences survive `/project:update`'s domain pass, and `docs/narrative/` fences survive its narrative pass byte-for-byte.
- **`repo-layout.md` is the opt-in scan contract.** Lives at the wiki scan root, read through the cross-cutting `repo-layout` skill. **Crew agents are read-only on it** — the wrapping kit is its only writer. Human edits inside `<!-- human:begin --> ... <!-- human:end -->` survive reconciliation. Absent → built-in heuristics, byte-identical to pre-manifest runs.

## When to use which workflow

- New product feature, need to plan & build it → **Feature pipeline** (`/feature:new` then `/feature:structure`).
- Onboarding a new repo, want a living wiki → **LLM wiki pipeline**. Run `/project:overview` first to produce a plain-language narrative under `docs/narrative/` (skip if you only want the canonical schema). Then run `/project:explore` once to produce the canonical schema under `docs/domain/` (it will read the narrative as soft input when present). Use `/project:update` whenever code changes to refresh both `docs/narrative/` and `docs/domain/` in one command.
- Both can be used in the same repo. The feature pipeline writes under `docs/<FEATURE>/`; the wiki pipeline writes under `docs/domain/`. They never touch each other's files, and neither invokes the other — run `/project:update` yourself when you want the wiki caught up with code a feature changed.

## Environment

- Windows + PowerShell 7+. Use `$env:VAR`, `$null`, backtick line-continuation.
