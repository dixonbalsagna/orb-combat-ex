# A5: Encounter Systems

Leads: none
Supports: A-AI-02, A-QA-05, A-QA-08

Goal: The computer opponent on Easy, Medium and Hard plays at the levels Game Design has set, so a newcomer wins most first matches on Easy and a match lasts 6 to 8 minutes.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A5, "Golden window GW4"); `data/director/ai.json` (the `levels` block and its notes); `data/director/stick.json`; `docs/design/gauntlet-plan.md` section 2 and line 132 (the Easy pace lever, `brawl.paceMatch`); Game Design's numbers sheet for GW4, which the EP will send with this brief.
- A-AI-02 (Game Design leads): Easy is too hard for a scripted player on Orb's scheme. Evidence: `docs/director/runs/6eec6a75/hitstop-row/final/table.txt:4` (19 of 40); `docs/director/runs/6eec6a75/hitstop-row/final/cells.txt:1-4`; `docs/design/gauntlet-plan.md:22`.
- A-QA-05 (Game Design leads): a right-stick-only pad loses almost every match. Evidence: `docs/qa/cloud-reports/2026-11-07-city-step-one-reread.md:38` (0 of 60 against Medium); `docs/qa/cloud-reports/2026-11-02-kept-build.md:9` (2 of 30 against Easy; the computer wins trade breaks on a stick player 4.22 times a minute on Easy against 0.04 on a masher).
- A-QA-08 (QA leads): match length is not measured against 6 to 8 minutes. Evidence: `docs/qa/runs/6a30b4c9/README.md:3`; `tools/feel/gauntlet.gd:91`.

You own: `sim/director/`, `data/director/`, `docs/director/`.
- In this window you change values in `data/director/` only. No code in `sim/director/`.
- If Game Design's sheet names a value in a file you do not own: ask under NEEDS FROM EP for a grant: `data/combat/stick.json` (or the file named on the sheet).

Acceptance criteria:
1. (supports A-AI-02, A-QA-05, A-QA-08) Every value on Game Design's sheet is applied exactly as written, in existing keys, as one change set. Checked by: a diff of `data/director/` that shows values only (no key added, removed or renamed), and the data job in CI green on that commit.
2. (supports A-AI-02) Before the sheet is applied, you send the EP a one-page answer for Game Design: which existing keys move Easy for a paced player without moving the masher, which keys set how often the computer breaks a trade against a stick player, and which keys set match length; for each, its present value on main and what it is known to do, from your own run records. Checked by: the page in `docs/director/`, each claim pointing at a saved record or marked "unverified".
3. (supports all three) The director's own checks pass on the changed data, and the results are saved as small text under `docs/director/runs/<sha>/` (CD-22). The computer still uses only inputs a player has (the standing check from A-AI-07).
4. (supports all three) The golden records are re-recorded once, in GW4, by the owner of the golden record; you confirm the before and after fingerprints differ only because of the values on the sheet (apply the sheet to a clean copy and compare). Checked by: the two fingerprints and the diff, saved in the same runs folder.
5. If a band cannot be reached with values alone, you say so under NEEDS FROM EP with the smallest rule change that would do it and its cost. You do not make it.

Constraints:
- Tokens: no row of its own; plan on about 0.25M of supporting work, an estimate, counted against the three rows' classes.
- State hash: yes, the values change the sim's state fingerprint. One landing, in golden window GW4 "Numbers only", at the end of A5. No rule may change in this window; after it the numbers are frozen for the candidate.
- Machine: headless Godot only; at most 3 Godot processes for a short gate while QA's long batches are running; anything over about ten minutes at below-normal priority.
- Determinism: seeded RNG, fixed step, no rendering state in the sim; numbers live in data; a shape change (which would need a schema update in `tools/schemas/` in the same commit) is not allowed in this window.
- Originality: nothing borrowed from another game's computer opponent.
- Orb's rules: the Easy computer changes when it throws, never what its blows are worth (`docs/design/gauntlet-plan.md:130`); whatever is tuned must suit high-speed combat.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Item 2 starts as soon as the A4 build is on main. Item 1 waits on Game Design's sheet, which waits on QA's first table. QA's second table and the close of GW4 wait on item 1. Nothing else of yours lands in A5: the rules closed with GW3.
