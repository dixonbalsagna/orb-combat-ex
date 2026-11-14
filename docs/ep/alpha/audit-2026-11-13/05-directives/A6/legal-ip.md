# A6: Legal & IP Compliance

Leads: none
Supports: none

Goal: No friend plays the candidate until every safety gate is green on that exact build, and every paper they read is true of it.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A6; "If a milestone misses its exit"; the "Standing exception" under "Change control"); `docs/ep/alpha/alpha-audit-specification.md` lines 169 and 199 (X-02, X-32); your gate list from A-LEGAL-03; your A5 sign-off rows in `docs/legal/review-log.md`; `docs/legal/alpha-tester-note.md`; `docs/legal/photosensitivity-note.md`; Tools' index of gate records for the candidate's commit, which the EP will send.
- A6 closes no register row. Your part is the re-read of the "before an outside tester plays" list and of the tester paperwork on the candidate's commit. Outside testers do not share the trusted second player's standing: every safety gate applies to them in full.

You own: `docs/legal/`.

Acceptance criteria (all on the candidate's commit, saved under `docs/legal/runs/<sha>/`, CD-22):
1. (X-02) Every gate on the list is read against its saved record for the candidate's commit: green with a record, or not green. A gate with a result but no saved output is "unverified", which is not green. Checked by: one table, gate by gate, with the path of each record.
2. (X-02) You give the EP one line: "clear for the two named testers on commit <sha>" or "not clear", with the gates that hold it. The one-line approval for outside testers is recorded only when the table is all green, and not before. Checked by: a row in `docs/legal/review-log.md`.
3. (X-32) Each paper a tester meets is re-read on the candidate: the AI disclosure up front; what a tester agrees to; the privacy line, the same words in the package, the game and the note; credits and third-party notices inside the build. Checked by: a sign-off row per item, naming the file and commit read.
4. (X-21, X-31) The report a tester sends and the itch.io page are read once more: nothing sent automatically; the page restricted, key-only, unlisted and unpromoted, under the working title as you ruled (A-LEGAL-09). Checked by: a row each.
5. (fix round) Each fix that changes what a tester sees or reads, or anything a gate measures, sends that gate or paper back through items 1 to 3 on the new commit before the friends get the update. Checked by: the table for the final candidate commit.
6. Anything not clear goes to Orb through the EP as one plain question. Questions on the one topic the EP keeps off Orb's page go to the EP only, with the safeguard already in place named. Checked by: the EP's record.

Constraints:
- Tokens: a small share of the milestone's 5M for verification (an estimate).
- State hash: no change.
- Machine: no Godot or browser runs are needed; you read saved records, you do not re-measure.
- Determinism: not touched.
- Originality: a last scan of names and text in the candidate against `docs/legal/never-use-words.md` and `docs/legal/originality-rules.md`.
- Orb's rules: your scope is names, whole-character likeness, trademarks, copied assets and real player safety; pose, gesture and look rules never block a gate. A figure in a safety record points at its saved output or is labelled "unverified" (`docs/ep/playbook.md:19`). Forward-facing text is seen by Orb before use.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Starts when Tools' index of gate records for the candidate's commit exists. The upload for the friends, and the invitation, wait on item 2. Item 5 repeats after the fix round. The freeze waits on the final table.
