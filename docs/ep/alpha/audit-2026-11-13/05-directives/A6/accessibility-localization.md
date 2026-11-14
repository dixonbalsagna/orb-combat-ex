# A6: Accessibility & Localization

Leads: none
Supports: none

Goal: A friend who needs a comfort setting finds it, it does what it says, and it is still set the next time they play.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A6); `docs/ep/alpha/alpha-audit-specification.md` lines 169, 187 and 189 (X-02, X-20, X-22); `docs/accessibility/audit-2026-10-28.md`; your pass and run records from A2 (A-ACCESS-01); `ui/data/options.json` (the options marked `"accessibility": true`), to read only; UI's 1280 by 800 sweep and settings round-trip records for the candidate, which the EP will send.
- A6 closes no register row. Your part is the accessibility items of the "before an outside tester plays" list, re-read on the candidate's commit.

You own: `docs/accessibility/`, `localization/`.
- The settings and their words are UI's; a problem you find is reported under NEEDS FROM EP, not fixed in `ui/`.

Acceptance criteria (all on the candidate's commit, saved under `docs/accessibility/runs/<sha>/`, CD-22):
1. (X-02) Each accessibility item on the gate list is read against the candidate: green with a saved record, or not green. Checked by: one table with the path of each record.
2. (X-20) Every comfort setting a tester can reach does something a player can see, hear or feel, and none is a control with no effect (the Hit pause slider was one, A-ACCESS-02). Checked by: a row per setting naming the code that reads it and the record that shows its effect.
3. (X-20) Comfort settings and remapped controls survive a restart on Windows and on Linux, and a safety setting that is locked on stays on. Checked by: your read of UI's round-trip output for the candidate.
4. (X-22) At 1280 by 800 no text is clipped or overlapping and nothing is under 9 px; you list what is under 12 px and whether it matters for reading at arm's length on a Deck. Checked by: your read of UI's sweep stills.
5. (testers) Any tester remark about reading, comfort or controls is sorted into broken, tuning or idea, with the gate item it touches. Checked by: the list returned to the EP.
6. The tester guide says the game is English only at Alpha. Checked by: the line.

Constraints:
- Tokens: a small share of the milestone's 5M for verification (an estimate).
- State hash: no change.
- Machine: you read saved records and stills; if you need a still that does not exist, ask the EP: stills come only through Tools' launcher.
- Determinism: not touched.
- Originality: not touched.
- Orb's rules: safety concerns are met with warnings and settings, never by degrading the default look (ADR 0010); no cue is drawn on, over or between the fighters; plain words in anything Orb reads. Questions on the one topic the EP keeps off Orb's page go to the EP only.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Starts when UI's sweep and round-trip records for the candidate are saved. Legal's gate table waits on your item 1. Item 5 waits on the two friends. Repeats on the final commit after the fix round for any item a fix touched.
