<!-- TEMPLATE — this is the shape of a docs/memory/<topic>.md file, NOT live memory.
     The bootstrap and memory-append paths both write against this contract.
     Copy the shape, fill in real content, and delete every line marked EXAMPLE. -->

# <Topic title>

One-line summary of what this topic covers. Summarize and link — never paste large verbatim copies of the source.

## Sources

Bulleted links back to the source files this topic summarizes. The **links are the load-bearing artifact** — each bullet is a stable, repo-relative path under the shared system root. No verbatim copies live here.

- [docs/architecture.md](../architecture.md) — cross-repo relationship overview
- [repo-a/docs/narrative/architecture.md](../../repo-a/docs/narrative/architecture.md) — human-readable walkthrough
- [repo-a/docs/domain/<bc>/aggregate.md](../../repo-a/docs/domain/<bc>/aggregate.md) — Evans-canonical schema

## Entries

The **append target**. Agents add new learnings here only — one fenced sub-block per learning, carrying a one-line summary, a `source-ref:` provenance field, and a `<!-- human:begin --> / <!-- human:end -->` pair where a human may curate that entry.

<!-- EXAMPLE entry — delete this whole fenced sub-block in a real topic file. -->
```
One-line summary of what was learned (e.g. "OrderPaid event is published by the Billing worker, not the API").
source-ref: repo-a@9f3c1ad repo-a/src/Billing/OrderPaidPublisher.cs:42
<!-- human:begin -->
Human curation for this entry goes between these fences. The agent never writes inside a
fence and never alters fenced text byte-for-byte.
<!-- human:end -->
```
<!-- END EXAMPLE -->

> The `source-ref:` line is a single composite field: `source-ref: <repo>@<commit> <repo-relative-path>:<line>`. Omit the parts you do not have (e.g. drop `@<commit>` or `:<line>` when unknown). Its shape is diff-ready so a future staleness feature can compare the stored ref against HEAD; v1 stores the ref only and does not diff.

---

**Append rule.** Agent appends land **only** in `## Entries`. The agent never overwrites the `## Sources` section and never alters any `<!-- human:begin --> ... <!-- human:end -->` fenced text. (The create-or-append / dedup / fence rules live in `skills/wiki-memory/SKILL.md`.)
