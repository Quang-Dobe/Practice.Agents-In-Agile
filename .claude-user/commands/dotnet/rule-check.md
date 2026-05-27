---
description: Audit the current diff against dotnet-rules.md via the dotnet-rules-checker subagent
argument-hint: [diff-spec or file paths]
---

Audit the current C# changes against `.claude-user/skills/dotnet-rules/dotnet-rules.md`.

1. Determine the input:
   - If `$ARGUMENTS` is provided, treat it as either a diff spec (e.g., `HEAD~3..HEAD`) or a list of file paths.
   - Otherwise, default to `git diff` against the last commit.
2. Spawn the `dotnet-rules-checker` subagent with that input. Pass the diff text directly so the agent does not need to re-read every file.
3. The subagent returns a structured punch list. Print it inline in this shape:

   ```
   <severity> <file>:<line>  Section <N> - <rule>
     Fix: <one-line suggestion>
   ```

   Where `<severity>` is `BLOCKER` | `WARN` | `INFO`.
4. If the subagent returns no findings, print: `dotnet-rules: no findings on <N> changed files`.
5. Do **not** auto-fix anything. The user (or main Claude in a follow-up turn) decides what to act on.
