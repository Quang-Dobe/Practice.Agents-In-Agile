---
name: pr-review-analysis
description: Segment a free-prose PR review file into findings, hunt code evidence for each one, and classify the rule concern it belongs to. Returns findings; writes no file. Used by the pr-review-analyst agent at /pr-review:analyze.
---

# PR review analysis skill

## Mission
Turn one free-prose review file into a list of findings, each carrying code evidence and a classified concern, so the human can judge every one of them.

## Owned artifact
Writes no file. Returns findings to main Claude, which owns the ledger write.

## Read scope
- The review file: `docs/<feature>/pr-review/<stem>.md`.
- The existing ledger if present: `docs/<feature>/pr-review/<stem>.pr-review.ledger.md`.
- Production source, read-only, for the evidence hunt.
- The repo's rule skills by concern name (`architecture-rules`, `coding-rules`, `test-rules`, plus any open concern) via `project-seams`, so classification can name a skill that already exists.

## Procedure

1. **Read the ledger first, when it exists.** Every `## PR-NN` section already there is settled. Collect its `### Quote` text and its ID.

2. **Segment the review prose into candidate findings.** One reviewer point is one finding. Split where the subject changes; do not split a single point across two findings just because it spans two sentences.

3. **Re-match, then assign IDs.**
   - **How to compare.** Compare the candidate's quote to each ledger quote as an exact string, after trimming leading and trailing whitespace. Do not normalize case, punctuation, or inner whitespace.
   - A candidate whose quote text matches a quote already in the ledger **is** that existing finding. Keep its ID. Do not re-segment it and do not append it again.
   - **Overlap is not a new finding.** If a candidate overlaps an existing quote without equalling it — one contains the other, or the two share a sentence — do **not** mint a new ID. Report the overlap and leave the decision to the human.
   - Only a genuinely new candidate gets a new ID, continuing from the highest `PR-NN` in the ledger.
   - IDs are ledger-local (`PR-01`). The global form used in output and on the page is `<stem>#PR-01`.

4. **Copy the quote verbatim.** Never paraphrase, shorten, or fix the reviewer's spelling. This text is the re-match key: change it and the finding duplicates on the next run.

4b. **Write a short title.** One line, **max 60 characters**, plain words at CEFR B1–B2 level. It names the problem, not the fix. It is the only text shown when the card is collapsed, so a reader must be able to skip or open the card from the title alone. Never reuse the raw quote as the title — the quote is long and the title is a label.

5. **Extract the reviewer name only on a clear marker** — `@alice`, `alice:`, `Reviewer: alice`. No marker means the field is omitted. Never emit `unknown`.

6. **Hunt evidence in code.** Derive every `file:line` fact from executable code only. A comment, docstring, or README may seed a search term but loses every conflict with code. Set exactly one state:

   | State | When | `evidence_detail` |
   |---|---|---|
   | `Located` | the code exists and you found it | `path:line-line` |
   | `Not code-locatable` | the point is real but has no single site — missing tests, naming across the repo, layering, PR size | `no single site — scope: <area>` |
   | `Not found` | you searched and found nothing matching | say what you searched for |

7. **Capture the snippet, only when `Located`.** Four lines either side of the anchor, hard cap 12 lines. Truncate with a single line holding `…`. It is stored so the page can re-render without reading source.

   `evidence_detail` and the snippet may cover **different widths**, and often do. `evidence_detail` names the full range the claim rests on; the snippet shows only what fits under the 12-line cap, centred on the anchor. A wider `evidence_detail` than snippet is correct, not a mismatch — do not shrink the range to match the cap, and do not raise the cap to match the range.

8. **Write the root cause only when the state is `Located`.** Derive it from the snippet. For every other state the value is exactly:

   ```
   not established — no code evidence
   ```

   Do not fill this slot to avoid an empty box. Empty is a correct answer.

9. **Draft the proposed fix.** Label it `proposed fix (unverified)`. Never phrase it as fact. Draft one for `Located` and for `Not code-locatable` — a fix such as adding tests for an untested area is real work even with no single code site. When the state is `Not found`, do **not** draft one; the value is exactly:

   ```
   cannot propose a fix — code not located
   ```

10. **Classify the concern.** Map the finding to the rule bucket it would feed:

    | Finding is about | Concern |
    |---|---|
    | language or style convention, naming, forbidden pattern | `coding-rules` |
    | layering, boundary, dependency direction | `architecture-rules` |
    | test layout, coverage, fixtures | `test-rules` |
    | a framework or library pattern with no reserved home | an open concern name, kebab-case |
    | process only — PR size, commit message, branch name | `none` |

    Prefer a concern skill the repo already has. Propose a new open concern only when no existing one fits.

11. **Collect hint terms.** Zero to four per finding. A hint term is a word in this card that a reader outside the team would not know — a domain noun, a library name, a config key, a protocol code. Each one gets a plain meaning of **at most 12 words**, CEFR B1–B2. Rules:
    - Only terms that actually appear in this card's own text.
    - No hint for a word already plain (`retry`, `row`, `stream`).
    - No hint that repeats the root cause or the fix. A hint defines a word; it does not argue a point.
    - Zero hints is a correct answer. Do not invent one to fill the row.

12. **Keep every prose field short.** Hard caps, because the page shows them in small boxes:

    | Field | Cap |
    |---|---|
    | `title` | 60 characters |
    | `evidence_detail` | 2 sentences |
    | `root_cause` | 2 sentences |
    | `proposed_fix` | 3 sentences |

    Plain words, CEFR B1–B2. Code, identifiers, paths, config keys, and quoted error text stay exact and never count against the reading level.

13. **Return the findings.** One record per finding, fields in this order: `id`, `title`, `quote`, `reviewer`, `reviewer_at`, `concern`, `evidence`, `evidence_detail`, `snippet`, `root_cause`, `proposed_fix`, `hints`. Report which IDs are new and which were re-matched.

## Boundary
Never judges a review comment valid or invalid — that is the human's call, and this skill only retrieves evidence and context. Writes no file, edits no source, flips no `status`, and never commits. Does not draft rule text; that is `pr-review-learning`.
