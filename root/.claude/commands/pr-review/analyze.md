---
description: Read a feature's PR review notes, attach code evidence to each finding, and render one HTML card page per review file. Gate-free.
argument-hint: --feature <feature> [--review <stem>]
---

Turn hand-written PR review notes into evidenced findings you can judge.

`$ARGUMENTS` carries two named flags. They are order-independent.

| Flag | Required | Value |
|---|---|---|
| `--feature` | yes | kebab-case folder name under `docs/` |
| `--review` | no | review file stem, no `.md` extension |

1. **Parse and validate.** Stop with the matching literal:
   - `--feature` missing → `specify a feature, e.g. /pr-review:analyze --feature payments-export --review round-1`
   - `docs/<feature>/` missing → `feature '<feature>' not found at docs/<feature>/`
   - `docs/<feature>/pr-review/` missing → `no pr-review folder at docs/<feature>/pr-review/`
   - `--review <stem>` given but `docs/<feature>/pr-review/<stem>.md` missing → `review '<stem>' not found at docs/<feature>/pr-review/<stem>.md`

2. **Report any orphan.** For each `*.pr-review.ledger.md` with no matching `<stem>.md`, print `orphaned ledger: <file> has no matching <stem>.md — left untouched.` Advisory only — never delete a ledger and never stop the run. A ledger holds the user's IDs and status. This scan runs before the target set below is resolved, so it still prints even when that set turns out empty — the one case where it is the only thing telling you your ledgers are still there.

3. **Resolve the target set.**
   - `--review <stem>` given → that one review file. **It always re-processes**, skipping every rule in step 4. Without this escape hatch, comments you add to an already-analysed file would be ignored forever.
   - `--review` omitted → **sweep mode**: every `.md` in `docs/<feature>/pr-review/` that is not a `*.pr-review.ledger.md`. If that set is empty, print `no review files found at docs/<feature>/pr-review/` and stop.

4. **Sweep skip rule — sweep mode only.** Per review file:

   | On disk | Do |
   |---|---|
   | no ledger | full analyse (steps 5-7) |
   | ledger, no HTML | render the HTML from the ledger (step 6 only) |
   | ledger newer than the HTML | render the HTML from the ledger (step 6 only) |
   | ledger, HTML current | skip |

   "Newer" means the ledger's file modification timestamp is later than the HTML's. Equal timestamps count as current — skip.

   The re-render path reads the ledger and nothing else. No source read, no re-analysis. This is what carries your `status: fixed` edit onto the page.

5. **Spawn `pr-review-analyst`** once per review file being analysed, with `description: PR review: analyse <stem>` and a `prompt` carrying: the feature name, the stem, `stage: analyze`, the review file path, the ledger path if it exists, and the directive to read `docs/narrative/` and `docs/domain/` if present as soft context (symmetric advisory for whichever is absent; never blocks). It follows its `pr-review-analysis` skill and returns findings. It writes nothing.

6. **Write the ledger, then render the page. Always in that order.** The ledger is upstream; the page is derived from it.
   a. Append each **new** finding to `docs/<feature>/pr-review/<stem>.pr-review.ledger.md` as a whole `## PR-NN` section, mirroring `~/.claude/templates/pr-review.ledger.md`. New findings carry `status: open` and `promoted: no`. Append-only: never edit an existing section, and skip any finding whose quote already appears in the ledger.
      Create the ledger from the template when it does not exist — the template's `## PR-01` section is a labeled example only, so a freshly created ledger starts with zero finding sections, and the title's and the `source:` line's `<stem>` placeholder is replaced with this review file's real stem.
   b. Spawn a subagent with `model: "sonnet"` to write `docs/<feature>/pr-review/<stem>.pr-review.html` from `~/.claude/templates/pr-review.html`. The subagent sees none of this session, so its prompt must carry:
      - the exact output path;
      - the template path;
      - every token value — with `&`, `<`, and `>` escaped to `&amp;`, `&lt;`, and `&gt;` in every token except `{{EVIDENCE_STATE}}`, `{{STATUS}}`, `{{DETAILS_OPEN}}`, `{{COUNT_LOCATED}}`, `{{COUNT_NOT_LOCATABLE}}`, and `{{COUNT_NOT_FOUND}}` — those six are fixed enums or numbers with no free text. `{{EVIDENCE_DETAIL}}`, `{{ROOT_CAUSE}}`, `{{PROPOSED_FIX}}`, `{{TITLE}}`, and `{{HINT_TIP}}` are agent-written prose about code and need this as much as `{{QUOTE}}` and `{{SNIPPET}}` do — a stray `<` or `>` would corrupt the page. **No token value may carry HTML tags.** The page's own markup is the template's job alone;
      - one card's worth of content per finding, in ledger order;
      - `{{DETAILS_OPEN}}` per card: the literal `open` when `status` is `open`, and an empty string when `status` is `fixed` or `rejected`. Unfixed work is expanded on first paint; settled work is collapsed;
      - the nested hint block per card: one copy of the `<!-- pr-review:hints -->` block per hint line in the ledger's `### Hints` section, filling `{{HINT_TERM}}` and `{{HINT_TIP}}`. Zero hints → delete the whole hint row from that card;
      - the dark-default plus theme-aware contract;
      - the rule that the page is rewritten only when its bytes actually change.

7. **Print the audit output.**
   - every written path;
   - the counts per evidence state, as `located: <n> · not code-locatable: <n> · not found: <n>`;
   - in sweep mode, one line naming the skipped stems: `skipped (up to date): <comma-separated stems, or (none)>`.
   - any overlap the analyst reported, in the form `overlap: <stem>#PR-NN overlaps new candidate "<short quote excerpt>…" — no new ID minted, your call.` The existing finding is named by its ID; the new candidate has none to name — that is the whole point of this rule — so it is named by a short, truncated excerpt of its quote text instead.

   A silent skip reads as "it worked", so the skip line is never omitted.

**Gate-free.** No `APPROVE`. Reads source but never edits it. Never commits — you commit.

**Next:** read the page, fix the code, then set `status: fixed` by hand in the ledger. Run `/pr-review:learn --feature <feature>` to turn those fixes into rules.
