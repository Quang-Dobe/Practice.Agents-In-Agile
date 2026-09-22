---
description: Fetch and write per-library cheatsheets into docs/knowledge/ from the pinned tech-stack.md
argument-hint: [library-name]
---

Fetch a Context7 cheatsheet for one or every library pinned in `tech-stack.md` and write it to
`docs/knowledge/<slug>.md`. `[library-name]` is optional; omit it to sweep every pinned library.

1. Resolve scope the same way as `/knowledge:refresh` steps 1-2, to find the scan root holding
   `tech-stack.md`.

2. **Guard.** If no `tech-stack.md` exists at the scan root, refuse with the literal
   `No tech-stack.md found at <path> - run /knowledge:init first.` and stop.

3. Read `tech-stack.md`. Build the target list:
   - `[library-name]` given → the single matching library across all repo entries
     (case-insensitive name match). No match → refuse with the literal
     `<library-name> not found in tech-stack.md.` and stop.
   - No arg → every library across every repo entry.

4. For each targeted library, in order:
   - `library_id: unresolved` → skip, print
     `<name>: unresolved library_id - cannot cache. Run /knowledge:refresh after fixing the dependency name if this is a false negative.`
   - `cache` path exists as a file on disk AND its frontmatter `detected_version` equals the
     manifest's `detected_version` for this library → skip, print
     `<name>: cache already fresh (detected_version <version>).`
   - Otherwise → call `mcp__plugin_context7_context7__query-docs` with the pinned `library_id`
     and the fixed prompt `Summarize setup/installation, key configuration, the most commonly
     used APIs, and common usage patterns for this library version.` Organize the response under
     2-6 `##` headings that fit the content (no fixed heading list), preceded by frontmatter:

     ```markdown
     ---
     library_id: <library_id>
     detected_version: <detected_version>
     fetched_at: <today's date, YYYY-MM-DD>
     ---
     ```

     Write to the library's `cache` path, creating `docs/knowledge/` if it does not exist yet.
     This command never writes `tech-stack.md` — separate ownership from `/knowledge:init` and
     `/knowledge:refresh`.

5. Report a one-line summary: libraries cached, skipped-fresh, skipped-unresolved.
