# A6: Game Design

Leads: none
Supports: none

Goal: Easy, Medium and Hard feel like three different things to Orb and to two newcomers, and nothing in the fight's rules or numbers moves while they find out.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A6, "Change control", "After the freeze"); `docs/ep/alpha/alpha-audit-specification.md` line 173 (X-06) and line 180 (X-13); your numbers sheet and design note from GW4 in `docs/design/`; `docs/design/gauntlet-plan.md` section 2; QA's band and length tables on the candidate, and the two testers' checklists, which the EP will send.
- A6 closes no register row. Your part is to judge the candidate's readings and the testers' words against the design, and to keep what they provoke out of the build.

You own: `docs/design/`.

Acceptance criteria:
1. (X-06) A one-page verdict in `docs/design/` on QA's candidate tables: for each level, the band, the reading, the interval, and "holds" or "misses", for the Orb's-scheme player, the masher and the stick-only player; the team and horde bands from A4 beside them. Checked by: the page, each number pointing at QA's saved table.
2. (X-06, X-13) Orb's own answer after one match at each difficulty (do they feel like three different things; did a match feel the right length) is set beside the numbers, verbatim, and any disagreement between the feel and the band is named, not smoothed over. Checked by: the page.
3. (testers) Each tester remark about difficulty, length or rules is sorted into one of three: broken (a fix), tuning inside the data's existing shape (allowed after the freeze, but not before the candidate passes), or a new idea (the ideas log). You propose; the EP and Orb decide. Checked by: the sorted list.
4. If a band misses on the candidate, you give the EP the smallest data-only change that would bring it in, with what else it moves, and you say plainly that landing it sends the candidate back to A5's numbers window. You do not route it yourself. Checked by: the note under NEEDS FROM EP.
5. (X-33) Every design idea raised in A6, yours included, is in the ideas log with a date and the speaker's words. Nothing is designed "ready for later" into the game's data. Checked by: the log.

Constraints:
- Tokens: a small share of the milestone's 5M for verification (an estimate); any fix draws on the 8M reserve, through the EP.
- State hash: no change. There is no golden window in A6; a fix that would change the fingerprint sends the candidate back to A5's window, and that is said out loud.
- Machine: you run no batches; QA does.
- Determinism: numbers live in data; you propose values, and no shape changes.
- Originality: not touched.
- Orb's rules: after the freeze, new ideas wait unless Orb lifts one in as a scope change (decision 23); whatever returns must suit high-speed combat; plain words on any page Orb reads.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Starts when QA's candidate tables are saved. Item 2 waits on Orb's play; item 3 on the two friends. The fix round's list and the freeze wait on your sorted list.
