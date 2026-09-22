---
description: Diff-aware refresh of tech-stack.md against current dependency manifests
argument-hint: [path]
---

Diff-aware refresh of an existing `tech-stack.md` against each repo's dependency manifest as it
stands today. `[path]` is optional; default to the current working directory.

1. Resolve `[path]` (or the current working directory) to an absolute filesystem path.

2. Load the `repo-layout` skill and run the same discovery as `/knowledge:init` step 2 (manifest
   found → its `repos[]`; absent → the same implicit single-repo fallback with the same advisory
   literal).

3. **Guard.** If no `tech-stack.md` exists at the scan root, refuse with the literal
   `No tech-stack.md found at <path> - run /knowledge:init first.` and stop.

4. Read the existing `tech-stack.md`.

5. For each repo entry (matched by `path`):
   a. Re-parse its dependency manifest using the same per-stack rules as `/knowledge:init` step 4.
   b. Dependency present in the fresh parse but not in the existing entry's `libraries[]` →
      resolve its `library_id` via `mcp__plugin_context7_context7__resolve-library-id` (same
      never-guess rule as `/knowledge:init`), add it with `cache` set the same way `/knowledge:init`
      step 7 sets it: `docs/knowledge/<slug>.md` when resolved, `null` when `unresolved`.
   c. Dependency present in the existing entry but absent from the fresh parse → drop its row.
      If its `cache` path exists on disk as a file, delete that file. Print the literal
      `DROPPED: <library> no longer in <repo>'s dependency manifest - removed from tech-stack.md, and cache file deleted.`
      (omit the `, and cache file deleted` clause when there was no cache file on disk).
   d. Dependency present in both → compare `detected_version`.
      - Version changed AND the existing `library_id` was `unresolved` → re-run
        `resolve-library-id`.
      - Version changed AND `library_id` was already resolved → keep the same `library_id`, only
        update `detected_version`.
      - Version unchanged → leave the row untouched.
   e. A repo entry present in `repo-layout.md`'s scope but absent from the existing
      `tech-stack.md` → add it fresh, populated exactly as `/knowledge:init` steps 4-7 would.

6. Print the full diff (added / dropped / version-changed rows) per repo before writing — same
   audit-trail convention as `/knowledge:init`.

7. Write the updated `tech-stack.md`.

8. Report a one-line summary: libraries added, dropped, version-changed.
