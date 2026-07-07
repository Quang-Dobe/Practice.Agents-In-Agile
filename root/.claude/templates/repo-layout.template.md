<!--
COPY ME. This is a TEMPLATE for the central repo-layout.md scan contract.
Place the live file as `repo-layout.md` at your wiki scan root:
  - multi-repo workspace -> the cross-repo root (holds the sibling repos + docs/ + .claude/)
  - single repo          -> the repo root (use one entry with `path: .`)
The crew agents (project-explorer / project-overview / project-update) read it and scan
ONLY the declared roots (minus excludes). Absent file -> built-in heuristics (no change).
Only /wiki:bootstrap (draft) and /wiki:enhance (reconcile) write the live file.
See ~/.claude/skills/repo-layout/SKILL.md for the full contract. Delete this comment in the live file.
-->
---
schema: 1
defaults:
  exclude:
    - "**/vendor/**"
    - "**/target/**"
    - "**/.venv/**"
    - "**/__pycache__/**"
    - "**/coverage/**"
    - "**/.next/**"
repos:
  - path: example-dotnet-repo
    stack: dotnet
    roots:
      - { path: src/Ordering, bc: Ordering }
      - { path: src/Billing,  bc: Billing }
    exclude: ["**/Migrations/**"]
  - path: example-node-repo
    stack: node
    roots:
      - { path: packages/api, bc: Api }
      - { path: packages/web, bc: Web }
  - path: example-unbounded-repo
    stack: go
---
<!-- human:begin notes -->
Record overrides and rationale here. This fenced block survives regeneration byte-for-byte.
<!-- human:end -->
