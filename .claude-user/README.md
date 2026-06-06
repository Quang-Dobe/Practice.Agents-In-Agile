# `.claude-user/` — User-tier feature + domain-wiki crew

`.claude-user/` is the **user-tier** toolset, distinct from the root-tier `.claude/` kit. Where `.claude/` is drop-copied to the **system root** above many sibling repos and operates **across** all of them, `.claude-user/` is installed **once** to user scope (`~/.claude/`) and operates **inside** whichever single repository the session is opened in. It ships two independent pipelines: a five-role **feature crew** (Product Owner → Business Analyst → Architect + Tester → Software Engineer) that walks a feature from raw idea to approved plan to code behind explicit `APPROVE` gates, and a three-agent **domain-wiki pipeline** (`project-overview` / `project-explorer` / `project-update`) that bootstraps and then diff-maintains a living wiki under the consuming repo's `docs/narrative/` and `docs/domain/` with no gates at all.

## Install instruction

Do **not** drop-copy this folder per repo. `.claude-user/` is not a discovery root — agent `skills:` manifests resolve skill **names** only from `~/.claude/skills/` or a repo's own `.claude/skills/`. Install it once to user scope via the script at the repo root:

```powershell
# From the scaffold repo root
pwsh -File .\install.ps1            # add-only: copies missing files, never overwrites
pwsh -File .\install.ps1 -DryRun    # report-only: prints [add]/[skip] per file, writes nothing
```

Re-running is safe: existing target files are kept untouched (local edits survive), new scaffold files flow through. Edits to an already-installed file do **not** propagate — delete the target file first or hand-merge.

## Install-target layout

After install, every repo you open gets the crew. The crew reads the repo and writes only under its `docs/`:

```
~/.claude/                            ← install target (user scope)
├── agents/                                ← 9 thin agents (identity + skills: manifest only)
├── commands/{feature,project,workflow}/   ← the slash commands you type
├── skills/                                ← 15 concern-named skills (the actual "how")
├── templates/                             ← feature document shapes
└── CONVENTIONS.md                         ← seam contract for project-tier authors

<your-repo>/                          ← any repo you open in Claude Code
├── .claude/skills/*-rules/               ← OPTIONAL project-tier rule skills (yours)
├── docs/<FEATURE>/                       ← feature pipeline output (gated)
├── docs/narrative/                       ← wiki output: plain-language tour (gate-free)
└── docs/domain/                          ← wiki output: DDD canonical schema (gate-free)
```

Roles of the outputs:
- `docs/<FEATURE>/` — `requirement.md`, `overview-plan.md`, `test.md`, `analyzed.md`, `plan.md`, `status.md`; each authored by its owning role, each behind an `APPROVE` gate.
- `docs/narrative/` — one `architecture.md` + one `walkthrough.md` per bounded context; bootstrapped by `/project:overview`, refreshed by `/project:update`.
- `docs/domain/` — Evans-canonical schema (bounded contexts, aggregates, events, commands, repositories, services, glossary, context map); bootstrapped by `/project:explore`, refreshed by `/project:update`.

## Conventions

- **Windows + PowerShell 7+.** Wherever shell is shown, use PowerShell idioms (`$null`, `$env:VAR`, backtick line-continuation). Hooks are Python — Python must be on PATH.
- **Thin agents + concern-named skills.** Agents hold no procedure — only identity, a `skills:` manifest, and an ownership boundary. The *how* lives in skills; the *which-agent-at-which-stage* lives in the commands. (The three wiki skills mirror their owning agent's name because each is single-owner.)
- **Stack-agnostic by design.** No `.NET` rules, no language-bound test runner. The consuming repo supplies stack rules in **its own** `.claude/` tree using reserved concerns (`architecture-rules`, `coding-rules`, `test-rules`) — see `CONVENTIONS.md`. The crew reads these seams when present and proceeds without them; it never blocks.
- **Gates only in the feature pipeline.** Every planning stage and implementation step waits for a literal `APPROVE`. The three wiki agents are fully agent-driven: they print their bounded-context decisions for the audit trail, then write automatically.
- **Local filesystem paths only.** The wiki commands refuse remote URLs in v1.
- **Fences are load-bearing.** Hand edits inside generated `docs/narrative/` and `docs/domain/` files survive regeneration only inside `<!-- human:begin --> / <!-- human:end -->` fences, byte-for-byte, in both trees.

## Boundary

The feature pipeline writes `docs/<FEATURE>/` plus the source code its steps produce. `/project:overview` writes only `docs/narrative/`; `/project:explore` writes only `docs/domain/`; `/project:update` writes both. Neither pipeline touches the other's files, with **one documented seam**: `/workflow:step-handoff` invokes `/project:update` at session close to keep the wiki in sync (it no-ops or refuses gracefully when both wiki trees are missing). Nothing in this tier writes inside `.claude-user/` or the consuming repo's `.claude/`.

## Who owns what

| Artifact | Owner |
|---|---|
| `<FEATURE>.requirement.md` | business-analyst |
| `<FEATURE>.overview-plan.md`, `.analyzed.md` (incl. Severity table) | architect |
| `<FEATURE>.test.md` (Given/When/Then e2e spec) | tester (planning-only; no runtime role) |
| `<FEATURE>.plan.md` + all source code | software-engineer |
| `<FEATURE>.status.md` | mechanical (template-initialized, flipped by step-approve) |
| `docs/narrative/` | project-overview (bootstrap), project-update (every refresh) |
| `docs/domain/` | project-explorer (bootstrap), project-update (every refresh) |

The product-owner writes nothing; the workflow-step-planner only drafts open questions.

## Index — files in this tier

| Path | Role |
|---|---|
| `agents/product-owner.md` | Frames raw idea into product intent via Q&A; writes no files. |
| `agents/business-analyst.md` | Pressure-tests the PO framing; authors the requirement. |
| `agents/architect.md` | Authors overview-plan + analyzed (risk + per-step Severity). |
| `agents/tester.md` | Authors the e2e/acceptance spec from the approved requirement. |
| `agents/software-engineer.md` | Authors the mechanical plan; implements every step (code + tests). |
| `agents/workflow-step-planner.md` | Drafts open questions + rule implications before a step starts. |
| `agents/project-overview.md` | Wiki runtime: bootstraps `docs/narrative/`. |
| `agents/project-explorer.md` | Wiki runtime: bootstraps `docs/domain/`. |
| `agents/project-update.md` | Wiki runtime: dual-pass diff-aware refresh of both trees. |
| `commands/feature/new.md` | Start a brainstorm with the Product Owner. |
| `commands/feature/structure.md` | Four APPROVE-gated stages: requirement → overview+test → analyzed → plan. |
| `commands/workflow/step-start.md` | Brief + spawn the SE on the current open step. |
| `commands/workflow/step-approve.md` | Flip the current step to done after `APPROVE`. |
| `commands/workflow/step-handoff.md` | End-of-session status update; invokes `/project:update` (the one seam). |
| `commands/project/overview.md` | One-shot narrative bootstrap (refuses on non-empty tree). |
| `commands/project/explore.md` | One-shot schema bootstrap (refuses on non-empty tree). |
| `commands/project/update.md` | Diff-aware dual-pass refresh (refuses when both trees missing). |
| `skills/` — 9 capability skills | `feature-intake`, `requirement-authoring`, `architecture-planning`, `risk-severity-analysis`, `acceptance-spec-authoring`, `implementation-planning`, `step-execution`, `e2e-validation`, `open-question-drafting`. |
| `skills/` — 3 cross-cutting skills | `pipeline-protocol` (gates + handoff), `project-seams` (optional project-tier rules), `prompt-defense`. |
| `skills/` — 3 wiki skills | `project-overview`, `project-explorer`, `project-update` (single-owner, mirror their agents). |
| `templates/feature.*.md` | Document shapes for the six feature artifacts. |
| `templates/project-rules.template.md` | Copy-me example for a project-tier rule skill. |
| `hooks/session-start-banner.py` | Session-start banner (wired via `settings.json`). |
| `settings.json` | Hook registration for this scaffold repo only (not installed). |
| `CONVENTIONS.md` | Two-tier model + agent→skill map + how a repo authors rule skills. |
