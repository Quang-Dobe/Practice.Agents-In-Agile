---
name: project-seams
description: Discover and load optional repo-tier rule skills by concern, plus the soft docs/narrative and docs/domain inputs. Every seam is optional — absent means proceed, never block. Loaded by the engineering-context crew agents.
---

# Project seams skill

The root-tier kit (installed to `~/.claude/`) is stack-agnostic. A consuming repo supplies stack/rule content in its own `.claude/` tree. This skill is how a generic agent finds and honors those optional seams — and never blocks when they are absent.

## Reserved project skills (auto-discover)
For each concern this agent references, check `<repo>/.claude/skills/<concern>/SKILL.md`. Load and honor it if present; emit no error and proceed if absent.

| Concern | Governs | Referenced by |
|---|---|---|
| `architecture-rules` | layering, boundaries, allowed patterns, dependency direction | architect, software-engineer (context) |
| `coding-rules` | language/style conventions, forbidden patterns, naming | software-engineer |
| `test-rules` | test layout, naming, coverage targets, fixtures | tester, software-engineer (unit/e2e layout) |

## Open project skills
A repo may add more concern skills (e.g. `dotnet-patterns`, `react-patterns`, `db-rules`). Honor any concern in this agent's reference list using the same present-or-proceed rule. Cite sections precisely (`per coding-rules §3.2`); a same-named project skill **overrides** a generic one (project scope outranks user scope).

**Chained load — depth 1.** After loading a reserved skill, read its `## Also load` section if it has one. Load each concern listed there from `<repo>/.claude/skills/<concern>/SKILL.md`, same present-or-proceed rule. Stop there: a chained skill's own `## Also load` is ignored. This is the only path by which an open concern reaches a root agent, because the root `skills:` manifest is never edited per project.

## Soft documentation inputs

**Resolve the path before deciding the tree is missing.** A monorepo's wiki is written **per code leaf**, so the trees sit at `<leaf>/docs/narrative/` and `<leaf>/docs/domain/` — one pair per leaf, none at the working-directory root. A root-only test answers "no wiki" for a repo that has a complete one, and the agent then plans blind.

Resolve in this order, stop at the first hit:

1. **Root pair** — `docs/narrative/` or `docs/domain/` non-empty at the working directory.
2. **Declared leaves** — load the `repo-layout` skill, resolve each declared code root from `repo-layout.md`, and test `<root>/docs/narrative/` and `<root>/docs/domain/`. This is the reliable path in a monorepo; the manifest is there whenever the wrapping kit has run.
3. **Bounded glob** — no manifest: glob `*/docs/narrative/` and `*/*/docs/narrative/`, two levels deep. Never a repo-wide sweep.
4. **Absent** — nothing at any level. Only now is the tree missing.

The inputs:

- `docs/narrative/` — plain-language wiki overview. Absent everywhere → `docs/narrative/ not found at the working directory or one level down - run /project:overview to generate it; proceeding without it.`
- `docs/domain/` — canonical DDD schema. Absent everywhere → `docs/domain/ not found at the working directory or one level down - run /project:explore to generate it; proceeding without it.`

**Never emit a not-found advisory for a tree that resolved at a nested path.** It sends the user to bootstrap a second wiki over a repo that already has one. When the caller passes resolved paths in the spawn prompt, use them and skip the resolver.

Both remain soft: absent means proceed, never block.
- `docs/architecture.md` — free-form architecture notes (read by BA, architect, SE, tester).

Emit the symmetric one-line advisory for whichever tree is absent, then proceed. Optional inputs never block.

## Per-feature overrides
A feature may override a project rule in the `Project-Specific Rule Overrides` section of `<feature>.analyzed.md`, citing the rule skill + section. Honor the override over the rule for that feature.

## Invariant
Every seam is optional. Missing seam → no error, proceed. Never edit a project's `.claude/` content from a generic agent; treat it as read-only input.
