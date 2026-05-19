---
description: Diff-aware update to docs/domain/ after project-explorer bootstraps it.
argument-hint: [path]
---

Run a diff-aware update of the DDD domain wiki under `docs/domain/` of the working directory by re-exploring a local repository at `[path]`. `project-explorer` must have already bootstrapped `docs/domain/` (see `/project:explore`); this command refuses if `docs/domain/` is missing or empty.

`[path]` is optional and defaults to the current working directory when omitted. It must be a local filesystem path.

1. Parse `[path]` (optional) from the slash-command args. If `[path]` is empty or omitted, silently default to the current working directory — do not prompt, do not error.

2. If `[path]` matches `` `^https?://` `` or `` `^git@` ``, refuse with the literal one-line message `Remote URLs are not supported in v1. Pass a local filesystem path.` and stop — do not spawn the agent.

3. Resolve `[path]` to an absolute filesystem path before spawning.

4. Spawn the `project-wiki-enhancer` subagent via the `Agent` tool with `description: "project-wiki-enhancer: update docs/domain/"` and a `prompt` containing: the resolved absolute `[path]`, and the instruction that the agent must reload `.claude/skills/project-wiki-enhancer/SKILL.md` **first** and then reload `.claude/skills/project-explorer/SKILL.md` **second**, both before any other action.

5. The subagent will execute its `## Operating procedure` (pre-flight refuse, resolve target, dual skill load, diff strategy selection, classify changed files, new-BC discovery APPROVE gate, removed-BC logging, regenerate in memory, fenced human-edit zone splice, byte-compare + selective write + frontmatter refresh, idempotency exit) and update `docs/domain/` in place — writing only files whose post-fence-splice bytes differ from the on-disk bytes.
