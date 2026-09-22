---
description: Bootstrap tech-stack.md by auto-detecting dependencies from repo-layout.md scope
argument-hint: [path]
---

Bootstrap `tech-stack.md` by auto-detecting each repo's dependencies and pinning them against
Context7. `[path]` is optional; default to the current working directory.

1. Resolve `[path]` (or the current working directory) to an absolute filesystem path.

2. Load the `repo-layout` skill and run its `## Discovery (walk-up to the scan root)` procedure
   against the resolved path. Note: unlike `repo-layout`'s own callers, which resolve to the
   single matched entry for `<path>`, these knowledge commands use Discovery only to locate the
   scan root and its manifest, then act on **every** `repos[]` entry in it — pinning is a
   whole-scan-root operation, not scoped to the invoked path.
   - Manifest found → note the scan root and every `repos[]` entry's `path`, scoped per that
     skill's `## Scope resolution`. For each entry: if it declares a `stack:` hint, use it
     directly; if it omits `stack:` (the `repo-layout` skill's own optional field), run the
     filesystem-inference ladder below against that entry's own scan set (rooted at its `path`,
     honoring its `roots` when declared) instead of the scan root.
   - No manifest found up to the drive root → print the literal
     `No repo-layout.md found - treating <path> as a single implicit repo with best-effort stack detection.`,
     treat the resolved path as the scan root, and build one implicit repo entry `path: .`, then
     run the same filesystem-inference ladder below against the scan root.
   - **Filesystem-inference ladder** (used above for the no-manifest fallback, and for any
     manifest-declared entry that omits `stack:`): check, in order, for `*.csproj`/`*.fsproj`
     (→ `dotnet`), else `package.json` (→ `node`), else `requirements.txt` or `pyproject.toml`
     (→ `python`), else `go.mod` (→ `go`); first match wins. No match at all → set
     `stack: unknown` — not an error, a valid starting point; once a dependency manifest
     appears in that scan set, `/knowledge:refresh` re-detects the stack fresh (this same
     ladder reruns every invocation) and is not blocked by this earlier value.

3. **Idempotency guard.** If `tech-stack.md` already exists at the scan root, refuse with the
   literal `tech-stack.md already exists at <path> - use /knowledge:refresh to update it.` and
   stop — do not proceed to step 4.

4. For each repo entry, parse its dependency manifest per its `stack`:
   - `dotnet` → every `<PackageReference Include="..." Version="..." />` in each `*.csproj` /
     `*.fsproj` under the entry's scan set, plus `packages.config` `<package id="..." version="..." />`
     entries.
   - `node` → `package.json` `dependencies` and `devDependencies` keys/values (strip a leading
     `^` or `~` from the version string).
   - `python` → `requirements.txt` lines matching `name==version`, and `pyproject.toml`
     `[project.dependencies]` entries.
   - `go` → `go.mod` `require` block lines (the module path's last path segment is the name, the
     second token is the version).
   - `unknown`, absent, or unrecognized `stack` → skip parsing for that entry, print
     `<repo path>: stack not recognized - libraries left empty.`, continue to the next entry.

5. For every extracted dependency name, call `mcp__plugin_context7_context7__resolve-library-id`
   with that name.
   - A confident single match → pin `library_id` to the returned Context7 id.
   - No confident match, or the tool call errors → pin `library_id: unresolved`. Never invent an
     id and never guess a version segment.

6. Print, per repo entry, the full list of dependencies with their resolved `library_id` (or
   `unresolved`) — this is the audit trail, printed before any file is written.

7. For a library whose `library_id` resolved (not `unresolved`), compute its `cache` path as
   `docs/knowledge/<slug>.md`, where `<slug>` is the library name lowercased with every run of
   non-alphanumeric characters replaced by a single `-`; this command never creates the file at
   that path, only records where one would go. For a library whose `library_id` is `unresolved`,
   set `cache: null` instead — there is nothing yet to cache.

   If the same library name resolves under more than one `repos[]` entry, they intentionally
   share one `docs/knowledge/<slug>.md` cache file — whichever entry is processed last (in the
   order `repos[]` lists them) determines the `library_id`/`detected_version` a subsequent
   `/knowledge:cache` run pins that file to. This is a known v1 limitation of the shared,
   non-repo-qualified cache namespace, not a bug: most single-purpose scaffolds have one
   `repos[]` entry, and the collision only matters when two repos in the same scan root
   genuinely depend on a library of the same name.

8. Write `tech-stack.md` at the scan root with this `schema: 1` shape (no `<!-- human:begin -->`
   fence — this file is a derived pin list regenerated by `/knowledge:refresh`, not hand-edited):

   ```yaml
   ---
   schema: 1
   repos:
     - path: repoA
       stack: dotnet
       libraries:
         - name: MediatR
           detected_version: 12.4.1
           library_id: /jbogard/mediatr/v12.4.1
           cache: docs/knowledge/mediatr.md
         - name: SomeInternalOnlyPackage
           detected_version: 3.2.0
           library_id: unresolved
           cache: null
   ---
   ```

9. Report a one-line summary: repo count, total libraries pinned, unresolved count.
