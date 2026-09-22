---
name: drafting
description: How the single writer of repo-layout.md drafts and updates it. Read on demand by that writer only; never preloaded, because every crew agent that loads the repo-layout skill is read-only on the manifest.
owner: repo-layout skill
---

## Drafting heuristics (writer only)

When a writer drafts or extends the manifest, it infers `repos` / `roots` from signals that already exist and do not drift:

- `.gitignore` — what is **not** source (build output, deps, caches).
- Ecosystem manifests for where code roots **are**: `*.sln` / `*.csproj` (dotnet), `go.mod` (go), `package.json` workspaces (node), `pyproject.toml` / `setup.cfg` (python), `pom.xml` / `build.gradle` (java), `Cargo.toml` (rust).
- Top-level project/service folders (`src/<Project>`, `packages/*`, `apps/*`, `services/*`).

The writer prints the inferred layout for the audit trail and **proceeds in the same run** using the draft — no halt, no approval gate (preserves the domain-wiki pipeline's gate-free invariant). Each `bc` label is seeded from the project/namespace name; the human edits later inside the manifest's human fences.

