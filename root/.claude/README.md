# `root/.claude/` — Root-tier feature + domain-wiki crew

`root/.claude/` is the **root-tier** toolset, distinct from the project-tier `project/.claude/` kit. Where `project/.claude/` is drop-copied to the **system root** above many sibling repos and operates **across** all of them, `root/.claude/` is installed **once** to user scope (`~/.claude/`) and operates **inside** whichever single repository the session is opened in. It ships three independent pipelines: a five-role **feature crew** (Product Owner → Business Analyst → Architect + Tester → Software Engineer) that walks a feature from raw idea to approved plan to code behind explicit `APPROVE` gates, a three-agent **domain-wiki pipeline** (`project-overview` / `project-explorer` / `project-update`) that bootstraps and then diff-maintains a living wiki under the consuming repo's `docs/narrative/` and `docs/domain/` with no gates at all, and a gate-free **PR review loop** (`pr-review-analyst`) that turns hand-written review notes into evidenced findings, then, after a fix, into rule sections inside the consuming repo's own `.claude/skills/`.

## Install instruction

Do **not** drop-copy this folder per repo. `root/.claude/` is not a discovery root — agent `skills:` manifests resolve skill **names** only from `~/.claude/skills/` or a repo's own `.claude/skills/`. Install it once to user scope via the script at the repo root:

```powershell
# From the scaffold repo root
pwsh -File .\install.ps1            # per-file mirror: replaces files at the same relative path
pwsh -File .\install.ps1 -WhatIf    # preview: lists what would be written, writes nothing
```

Re-running syncs the target with the scaffold: each scaffold file replaces its same-path counterpart, so edits propagate. Folders are merged, never wiped — target-only files (your own skills, agents, ...) survive. Local edits to *installed scaffold files* are overwritten; make changes in this repo instead.

## Install-target layout

After install, every repo you open gets the crew. The crew reads the repo and writes only under its `docs/`:

```
~/.claude/                            ← install target (user scope)
├── agents/                                ← 10 thin agents (identity + skills: manifest only)
├── commands/{feature,pr-review,project}/   ← the slash commands you type
├── skills/                                ← 7 shared skills (the actual "how")
├── templates/                             ← feature document shapes
└── CONVENTIONS.md                         ← seam contract for repo-tier authors

<your-repo>/                          ← any repo you open in Claude Code
├── .claude/skills/*-rules/               ← OPTIONAL repo-tier rule skills (yours)
├── docs/<FEATURE>/                       ← feature pipeline output (gated)
├── docs/narrative/                       ← wiki output: plain-language tour (gate-free)
└── docs/domain/                          ← wiki output: DDD canonical schema (gate-free)
```

Roles of the outputs:
- `docs/<FEATURE>/` — `raw-requirement.md` (yours, never overwritten), `requirement.md`, `requirement-trace.md`, `overview-plan.md`, `overview-plan-trace.md`, `test.md`, `analyzed.md`, `plan.md`, `status.md`. Each final artifact is authored by its owning role and carries one `> Status:` line that main Claude flips on `APPROVE`. Each **trace** file is an append-only `## Decisions` table — what was asked, what was answered, what it changed — and is never a planning input.
- `docs/narrative/` — one `architecture.md` + one `walkthrough.md` per bounded context; bootstrapped by `/project:overview`, refreshed by `/project:update`.
- `docs/domain/` — Evans-canonical schema (bounded contexts, aggregates, events, commands, repositories, services, glossary, context map); bootstrapped by `/project:explore`, refreshed by `/project:update`.

## Conventions

- **Windows + PowerShell 7+.** Wherever shell is shown, use PowerShell idioms (`$null`, `$env:VAR`, backtick line-continuation).
- **Thin agents + concern-named skills.** Agents hold no procedure — only identity, a `skills:` manifest, and an ownership boundary. The *how* lives in skills; the *which-agent-at-which-stage* lives in the commands. (The three wiki skills mirror their owning agent's name because each is single-owner.)
- **Stack-agnostic by design.** No `.NET` rules, no language-bound test runner. The consuming repo supplies stack rules in **its own** `.claude/` tree using reserved concerns (`architecture-rules`, `coding-rules`, `test-rules`) — see `CONVENTIONS.md`. The crew reads these seams when present and proceeds without them; it never blocks.
- **Gates only in the feature pipeline.** Every planning stage and implementation step waits for a literal `APPROVE`. The three wiki agents are fully agent-driven: they print their bounded-context decisions for the audit trail, then write automatically.
- **Local filesystem paths only.** The wiki commands refuse remote URLs in v1.
- **Fences are load-bearing.** Hand edits inside generated `docs/narrative/` and `docs/domain/` files survive regeneration only inside `<!-- human:begin --> / <!-- human:end -->` fences, byte-for-byte, in both trees.
- **`repo-layout.md` is opt-in and read-only for the crew.** A workspace-root scan contract (single-writer: `/wiki:bootstrap` drafts, `/wiki:enhance` reconciles) that the three wiki agents read via the `repo-layout` skill to scope their walk to declared code roots. Absent → today's heuristics, byte-identical.

## PR review loop

Two commands close the gap between a PR review and the next feature's plan.

```
/pr-review:analyze --feature <f> [--review <stem>]     gate-free
    your notes  ->  findings + code evidence  ->  ledger  ->  card page

        you read the page, fix the code, set `status: fixed` in the ledger

/pr-review:learn   --feature <f> [--review <stem>]     APPROVE-gated
    fixed findings  ->  rule drafts  ->  APPROVE  ->  .claude/skills/
```

- One review `.md` gives one ledger and one HTML page, named from the same stem.
- The ledger is upstream. The page is always rendered from it, never edited directly. Flip `status` in the ledger and the next sweep re-renders the page — a ledger read only, no re-analysis.
- The agent gives **no** validity verdict. It attaches evidence; you judge every finding.
- Rules land **only** in this repo's `.claude/skills/`, behind `APPROVE`. Never in the root tier.
- A new open-concern skill is always wired into a reserved skill's `## Also load` list, or no agent would ever read it.

## Boundary

The feature pipeline writes `docs/<FEATURE>/` plus the source code its steps produce. `/project:overview` writes only `docs/narrative/`; `/project:explore` writes only `docs/domain/`; `/project:update` writes both. Neither pipeline touches the other's files — run `/project:update` yourself when code changes and you want the wiki refreshed. Nothing in this tier writes inside `root/.claude/`, and nothing writes inside the consuming repo's `.claude/` — with one exception: `/pr-review:learn` appends rule sections under `<repo>/.claude/skills/`, and only after the user types `APPROVE`.

## Who owns what

| Artifact | Owner |
|---|---|
| `<FEATURE>.requirement.md` (final requirement), `<FEATURE>.requirement-trace.md` (its decisions) | business-analyst |
| `<FEATURE>.overview-plan.md`, `.overview-plan-trace.md` (its decisions), `.analyzed.md` (Severity, Risks, Rule overrides) | architect |
| `<FEATURE>.test.md` (Given/When/Then acceptance spec, happy cases first) | tester (planning-only; no runtime role) |
| `<FEATURE>.plan.md` (component design) + all source code | software-engineer |
| `<FEATURE>.status.md`, the `Shared files` edits, and trace rows appended at a human gate | main Claude (mechanical — no agent writes them) |
| `<FEATURE>.raw-requirement.md` | you — no agent ever writes it |
| `docs/narrative/` | project-overview (bootstrap), project-update (every refresh) |
| `docs/domain/` | project-explorer (bootstrap), project-update (every refresh) |
| `<stem>.pr-review.ledger.md` | `/pr-review:analyze` appends findings; the human owns `status`; `/pr-review:learn` flips `promoted` |
| `<stem>.pr-review.html` | rendered from the ledger by a `sonnet` subagent; never edited by hand |
| rule sections in `<repo>/.claude/skills/` | `/pr-review:learn`, written by main Claude only after `APPROVE` |

The product-owner writes nothing.

## Index — files in this tier

| Path | Role |
|---|---|
| `agents/product-owner.md` | Frames raw idea into product intent via Q&A; writes no files. |
| `agents/business-analyst.md` | Pressure-tests the PO framing; authors the requirement + its trace. |
| `agents/architect.md` | Authors overview-plan + its trace, and the slim analyzed (Severity, Risks, Rule overrides). |
| `agents/tester.md` | Authors the e2e/acceptance spec from the approved requirement. |
| `agents/software-engineer.md` | Authors the component-level plan; builds every component (code + tests). |
| `agents/project-overview.md` | Wiki runtime: bootstraps `docs/narrative/`. |
| `agents/project-explorer.md` | Wiki runtime: bootstraps `docs/domain/`. |
| `agents/project-update.md` | Wiki runtime: dual-pass diff-aware refresh of both trees. |
| `commands/feature/new.md` | Start a brainstorm with the Product Owner. |
| `commands/feature/structure.md` | Four APPROVE-gated stages: requirement → overview-plan + test → analyzed → plan. The stage is read from which files exist on disk. |
| `commands/feature/implement.md` | The build loop, wave by wave: brief, spawn one sonnet engineer per component in parallel, one build run, one `APPROVE`, advance. |
| `commands/project/overview.md` | One-shot narrative bootstrap (refuses on non-empty tree). |
| `commands/project/explore.md` | One-shot schema bootstrap (refuses on non-empty tree). |
| `commands/project/update.md` | Diff-aware dual-pass refresh (refuses when both trees missing). |
| `commands/pr-review/analyze.md` | Read PR review notes, attach code evidence, render one card page per review file. Gate-free. |
| `commands/pr-review/learn.md` | Promote fixed findings into this repo's own rule skills. `APPROVE`-gated. |
| `agents/pr-review-analyst.md` | Read-only: returns evidenced findings, then rule drafts. Gives no validity verdict. |
| `agents/html-generator.md` | Belongs to no pipeline. Writes every `.html` / `.htm` file, at any size, per `[R-HTML-AGENT]`. Pins `model: sonnet` in its own frontmatter and carries the dark-default / theme-aware / plain-words rules, so a caller passes only the path and the facts. |
| `skills/` — 4 cross-cutting skills | `project-seams` (optional repo-tier rules), `prompt-defense`, `repo-layout` (opt-in scan-scope contract; read-only for the crew), `library-knowledge` (opt-in pinned library docs via Context7; read-only for the crew). |
| `skills/` — 3 wiki skills | `project-overview`, `project-explorer`, `project-update`. Shared across the wiki agents; `project-update` also has its sections cited by `project-overview`. |
| `templates/feature.*.md` | Document shapes for the eight feature artifacts (five final files, two traces, one status). |
| `templates/project-rules.template.md` | Copy-me example for a repo-tier rule skill. |
| `templates/pr-review.ledger.md` | The ledger shape: one `## PR-NN` section per finding, each carrying a short `title` and an optional `### Hints` list. |
| `templates/pr-review.html` | The card page shell. One collapsible card per finding at its own `#PR-NN` anchor, plus a sticky link rail. Open findings expand, `fixed` and `rejected` collapse. Dark default, theme-aware, all CSS and JS inlined. |
| `CONVENTIONS.md` | Two-tier model + agent→skill map + how a repo authors rule skills. |
