# `.claude/` — Root-tier LLM Wiki toolset

`.claude/` is the **root-tier** toolset, distinct from the per-repo `.claude-user/` kit. Where `.claude-user/` is drop-copied **into** a single repository and operates against that one repo, `.claude/` is drop-copied to the **system root** that sits **one level above** many sibling repos and operates **across** all of them. It builds and serves a cross-repo "LLM Wiki": a `docs/memory/` store that summarizes and links back to (never duplicates) the knowledge already produced per repo — the root `docs/architecture.md` plus every sibling repo's `docs/narrative/` and `docs/domain/`. A router sub-agent then answers in-domain questions from that wiki using a fixed, auditable retrieval order, falling through to raw repo source only as a last resort.

## Drop-copy instruction

Copy this `.claude/` folder **verbatim** to the system root that contains your sibling repos. At that root it is the `.claude`-equivalent: a Claude Code session whose working directory is the system root will discover its commands, agents, and skills exactly the way a per-repo session discovers `.claude-user/`.

```powershell
# From the system root that contains repo-a/, repo-b/, ... and docs/
Copy-Item -Recurse .\path-to-scaffold\.claude .\.claude
```

## Drop-target layout

Once copied, the root tier operates against this layout. Everything except `docs/memory/` is **read-only input**:

```
<system-root>/
├── .claude/                         ← copy of this folder
├── docs/
│   ├── architecture.md                   ← read-only input (consumed, not generated)
│   └── memory/*.md                       ← the ONLY write target (this tier's output tree)
├── repo-a/docs/{narrative,domain}/       ← read-only inputs
├── repo-b/docs/{narrative,domain}/       ← read-only inputs
└── repo-c/ ...
```

Roles of the inputs:
- `docs/architecture.md` — cross-repo relationship overview (super-architect authored, consumed read-only).
- `repo-*/docs/narrative/` — human-readable per-repo walkthrough.
- `repo-*/docs/domain/` — Evans-canonical per-repo schema.
- repo source — last-resort ground truth, read only when every wiki tier above is insufficient.

## Conventions

- **Windows + PowerShell 7+.** Wherever shell is shown, use PowerShell idioms (`$null`, `$env:VAR`, backtick line-continuation).
- **Exact-case `APPROVE` on every write.** No file is written under `docs/memory/` until the operator types the exact-case token `APPROVE`. Any other response is treated as an edit request and re-prompts.
- **Local filesystem paths only.** Remote inputs are refused: any path matching `^https?://` or `^git@` is rejected with a one-line message and the run stops.
- **No auto-commit.** This tier never commits on the operator's behalf.

## Boundary

The root tier is **read-only against every input tree** — `docs/architecture.md`, every repo's `docs/narrative/` and `docs/domain/`, and repo source are never modified. Its **sole output** is `docs/memory/`. No write ever lands outside `docs/memory/`.

## Who owns docs/memory/

`docs/memory/` is **co-owned** under a strict, asymmetric contract. The human is the curator/owner with full edit, curate, and delete authority. The agent is an append-only contributor: it may create new topic files and append new entries (gated by the same-source-ref dedup guard) but **never** overwrites or edits existing human or prior text. This asymmetry applies **only** to `docs/memory/` — `docs/narrative/` and `docs/domain/` remain fully agent-controlled. For the authoritative ownership table and the `<!-- human:begin --> / <!-- human:end -->` fence rules, see the `## Co-ownership contract` and `## Fence convention` sections in `skills/wiki-memory/SKILL.md`.

## `consumed_by` convention

Skill frontmatter declares the agents that load it using a **comma-separated scalar on one line**:

```yaml
consumed_by: wiki-router agent, wiki-bootstrapper agent
```

Use this exact shape (one line, comma-separated, never a YAML list) for every skill in this tier.

## Index — files in this tier

| Path | Role |
|---|---|
| `.claude/commands/wiki/bootstrap.md` | Operator-invoked slash command that bootstraps/refreshes `docs/memory/` by summarizing-and-linking the inputs, gated behind `APPROVE`. |
| `.claude/agents/wiki-bootstrapper.md` **(optional)** | Bootstrap worker sub-agent the command spawns to perform the summarize-and-link write. |
| `.claude/agents/wiki-router.md` | Router sub-agent: classifies in-domain vs out-of-domain, runs the fixed retrieval order, answers from the wiki, falls through to source last. |
| `.claude/commands/wiki/ask.md` **(optional)** | Entry slash command that routes a question to the `wiki-router` sub-agent. |
| `.claude/skills/wiki-router/SKILL.md` | Classification + fixed retrieval-order operating manual reloaded by the router each run. |
| `.claude/skills/wiki-memory/SKILL.md` | Append-only / dedup / provenance / fence write-path operating manual reloaded by the router and the bootstrapper. |
