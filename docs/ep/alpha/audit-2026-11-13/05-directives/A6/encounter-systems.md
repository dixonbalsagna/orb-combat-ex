# A6: Encounter Systems

Leads: none
Supports: none

Goal: The computer opponent behaves on the candidate exactly as it did when the numbers closed, through two hours of matches and two friends' first evenings, and anything it does wrong is fixed without changing what a match is.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A6, "Change control"; "One director's queue sets the date"); `docs/ep/alpha/alpha-audit-specification.md` lines 173, 180, 183 and 184 (X-06, X-13, X-16, X-17); your run records from GW4 under `docs/director/runs/`; QA's candidate readings and the testers' reports, which the EP will send.
- A6 closes no register row. Your part is to explain any reading that involves the computer's play, and to hold the fix round's director-side fixes to ones that do not move the sim's fingerprint.

You own: `sim/director/`, `data/director/`, `docs/director/`.

Acceptance criteria:
1. (X-06, X-13, X-16, X-17) For each of QA's candidate readings that involves the computer's play, you confirm from the debug feed that the result came from the shipped data and not from a leftover switch: one line per reading in `docs/director/`. Checked by: the page; each line points at a saved feed or record under `docs/director/runs/<sha>/` (CD-22).
2. (X-17) The standing check that the computer uses only inputs a player has (A-AI-07) passes on the candidate's commit. Checked by: the saved output.
3. (X-25) Any hang, script error or stuck match the soak finds in director code gets a cause and a fix within the fix round, with a seeded replay that reproduces it before and passes after. Checked by: the replay and the saved outputs.
4. (fix round) Every fix you propose states one of two things first: "does not change the state fingerprint" (shown by the same seeded matches giving the same fingerprints before and after), or "changes it", in which case you stop and tell the EP, because the candidate would go back to A5's numbers window. Checked by: the fingerprints saved with each fix.
5. (testers) For each tester remark about the computer (too hard, too passive, unfair, stuck), you give the EP the cause in one plain line and whether it is broken, tuning, or an idea. Checked by: the list.

Constraints:
- Tokens: a share of the milestone's 5M for verification (an estimate); fixes draw on the 8M fix reserve, through the EP.
- State hash: no change is allowed in A6. Rules and numbers are frozen from the end of A5.
- Machine: headless Godot only; at most 3 Godot processes for a short gate while QA's soak or bands are running; anything over about ten minutes at below-normal priority.
- Determinism: seeded RNG, fixed step, no rendering state in the sim; numbers live in data; no data shape change.
- Originality: not touched.
- Orb's rules: the computer plays by the same rules as a player; new behaviour is a new idea and goes to the ideas log.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Starts when QA's candidate readings are saved. Item 3 waits on the soak; item 5 on the two friends. QA's re-read after the fix round waits on your fixes.
