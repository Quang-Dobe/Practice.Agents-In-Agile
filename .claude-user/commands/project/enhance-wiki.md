---
description: Dual-pass diff-aware update to docs/narrative/ then docs/domain/ after the bootstrap commands have run.
argument-hint: [path] [--bypass-approval]
---

Run a dual-pass diff-aware update of the runtime wiki trees of the working directory by re-exploring a local repository at `[path]`. The narrative tree at `docs/narrative/` is refreshed first; the domain tree at `docs/domain/` is refreshed second. `/project:overview` and `/project:explore` must have already bootstrapped the respective trees; this command refuses when **both** trees are missing (see below). When exactly one of the two trees is missing, the present tree is refreshed and a single advisory line points the user at the bootstrap command for the missing tree. `--bypass-approval` is an optional flag that auto-approves non-critical changes for low-friction or CI runs; it always escalates to a human on the four critical categories (new BC, BC renamed, BC removed, write inside a `<!-- human:begin --> ... <!-- human:end -->` block) and exits 1 with a locked diagnostic if any critical category fires. `[path]` is optional and defaults to the current working directory when omitted. It must be a local filesystem path. **Reserved coupling:** once `/project:doctor` ships, this command will invoke it as a default last step whenever any mismatch / conflict / out-of-date signal is detected during the enhance run. No-op in v1; the future doctor feature inherits this contract.

1. Parse `[path]` (optional) and `--bypass-approval` (optional flag) from the slash-command args. If `[path]` is empty or omitted, silently default to the current working directory — do not prompt, do not error. The `--bypass-approval` flag is a boolean; absence means false.

2. If `[path]` matches `` `^https?://` `` or `` `^git@` ``, refuse with the literal one-line message `Remote URLs are not supported in v1. Pass a local filesystem path.` and stop — do not spawn the agent.

3. Before spawning the agent, check whether **both** `docs/narrative/` and `docs/domain/` of the working directory are missing or empty (same emptiness rule as the existing agent pre-flight refuse condition; recursive non-hidden-file check). If both are missing, refuse with the literal one-line message and stop — do not spawn the agent. The locked literal message is:

   ```
   Both docs/narrative/ and docs/domain/ are missing. Run /project:overview to bootstrap docs/narrative/, then /project:explore to bootstrap docs/domain/, then /project:enhance-wiki to update.
   ```

   Single-tree-missing (only one of the two trees missing) is **not** a refusal at the command layer; that case is handled by the agent's symmetric advisory branch (see `.claude-user/skills/project-wiki-enhancer/SKILL.md` `## Tree-presence advisories`).

4. Resolve `[path]` to an absolute filesystem path before spawning.

5. Spawn the `project-wiki-enhancer` subagent via the `Agent` tool with `description: "project-wiki-enhancer: dual-pass update docs/narrative/ then docs/domain/"` and a `prompt` containing: (a) the resolved absolute `[path]`, (b) the `--bypass-approval` flag value (true/false), and (c) the instruction that the agent must reload three skills in the locked order — `.claude-user/skills/project-wiki-enhancer/SKILL.md` **first**, `.claude-user/skills/project-overview/SKILL.md` **second**, `.claude-user/skills/project-explorer/SKILL.md` **third** — all before any other action.

6. The subagent will execute its `## Operating procedure` (run-mode dispatch, pre-flight tree detection + advisory, three-skill load in locked order, narrative-pass execution then domain-pass execution per `## Dual-pass orchestration`, per-pass diff strategy selection, classify changed files, per-pass new-BC discovery APPROVE gate with `--bypass-approval` critical-category override per `## --bypass-approval semantics`, removed-BC logging into the per-tree target, regenerate in memory, fenced human-edit zone splice, byte-compare + selective write + frontmatter refresh, cross-pass idempotency exit) and update `docs/narrative/` then `docs/domain/` in place — each pass writing only files whose post-fence-splice bytes differ from the on-disk bytes.
