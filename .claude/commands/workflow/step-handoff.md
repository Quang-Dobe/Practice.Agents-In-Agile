---
description: End-of-session summary for a feature; drafts status.md update for the next session
argument-hint: <feature>
---

Produce an end-of-session handoff so the next session picks up cleanly.

`$ARGUMENTS` is `<feature>`. If missing, error: `specify a feature, e.g. /workflow:step-handoff payments-export`.

1. Run `git status` and `git diff` (against the last commit) to see what changed in this session.
2. Check the current task list state.
3. Identify the current step (the first non-`[X]` row in `docs/<feature>/<feature>.requirement.md`).
4. Draft a handoff block in this exact shape:

   **Session date:** today's date.
   **Step worked on:** `<step-id>`.
   **What got done:** bullet list of completed work (file paths included).
   **Open questions surfaced:** numbered, each marked `[Waiting for Answer]` if still unresolved, or "RESOLVED - `<short answer>`" if answered this session.
   **What's next:** one sentence describing the next concrete action.
   **Verification status:** build / test results, if relevant.

5. **Show the draft to the user first.** Do not write to `docs/<feature>/<feature>.status.md` until the user confirms.
6. After confirmation: append (or update) the relevant section in `docs/<feature>/<feature>.status.md` with the handoff block. Do NOT touch other sections.
7. Do NOT commit. The user commits explicitly.
