# A5: QA & Balance

Leads: A-QA-01, A-QA-08
Supports: A-AI-02, A-QA-05, A-WORLD-05

Goal: A friend who has never seen the game can install it on a Steam Deck, play, and send a report by following one guide and ticking one checklist, and a normal match lasts 6 to 8 minutes at a difficulty that feels fair.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A5, and "Golden window GW4"); `docs/ep/alpha/alpha-audit-specification.md` lines 168 to 191 (X-01, X-06, X-13, X-18 to X-21); `docs/legal/alpha-tester-note.md`; `docs/tools/steam-deck.md`; `tools/desktop-package.mjs` lines 56 to 59; `docs/design/gauntlet-plan.md` section 2; `tools/feel/gauntlet.gd`; `docs/qa/runs/6a30b4c9/README.md`; `docs/ep/proposals/terrain-globe-plan.md` (the step table, step 4).
- A-QA-01 (blocker): no tester guide, tester checklist, Deck checklist or playtest protocol exists. Evidence: `docs/legal/alpha-tester-note.md:1-3` (the only tester-facing page; it covers age, privacy and reports, not installing); `tools/desktop-package.mjs:56-59` (the Deck gets one line after unpack-and-chmod steps); `docs/tools/steam-deck.md:13-25` (a developer table, not a checklist).
- A-QA-08: match length is not measured on the current build against the 6 to 8 minute target. Evidence: `docs/qa/runs/6a30b4c9/README.md:3` (Orb's one finished match, 19,388 ticks, about 5.4 minutes); `docs/qa/cloud-reports/2026-11-07-city-step-one-reread.md:36` (a masher's median of 226.9 s against Medium); `tools/feel/gauntlet.gd:91` (the gauntlet, Tools' scripted-player batch, already saves each match's length). The verifier's note: on the older record only the Orb's-scheme player ran long (mean 9.6 minutes); the masher's mean of 7.1 was inside the band.
- A-AI-02 (Game Design leads): Easy is too hard for a scripted player on Orb's scheme, 19 of 40. A-QA-05 (Game Design leads): a right-stick-only pad won 0 of 60 against Medium and 2 of 30 against Easy. Your part is the readings.
- A-WORLD-05 (Rendering leads): the ground drawn is not the ground stood on. Your part is the ten-seed reading in the plan's step 4.

You own: `qa/`, `prototype/tools/`.
- ask under NEEDS FROM EP for a grant: `docs/qa/` (the run records and the protocol page; the folder has no owner).
- The guide's install, key and update steps come from the A2 rehearsal and Deck session records; ask the EP for them, do not guess a step.
- Getting the guide and checklist into the package is Tools' file: ask under NEEDS FROM EP for a grant: `tools/desktop-package.mjs`, or hand the EP the text.

Acceptance criteria:
1. (A-QA-01) A tester guide exists under `qa/` in plain words: how to get and use a key on the itch.io page, install and start on a Steam Deck and on Windows, apply an update, what to try, how to make the report in one press and post it, and where to ask for help. Every step is one somebody did at the A2 Deck session or the A5 rehearsal. Checked by: Orb and Orb 2 (the trusted second player) complete the install and a first match from the guide alone, and each place they had to guess is fixed (X-18 and X-19 as a rehearsal).
2. (A-QA-01) A tester checklist exists as one page a tester ticks and posts with the report file: the seven newcomer steps, one row per mode offered, the settings-held-after-restart row, a five-minute bench row, and a free line. It needs no keyboard to complete on a Deck. Checked by: both rehearsal checklists come back with no blank row; saved under `docs/qa/runs/<sha>/`.
3. (A-QA-01) A playtest protocol exists for the EP and Orb: who gets a key, what is sent with it, what comes back, how a report becomes a bug-list row within a day, and what stops a session (any safety gate not green). Checked by: the EP reads it against the "before an outside tester plays" list from A-LEGAL-03.
4. (A-QA-01) The guide, the checklist and the words a tester reads carry the AI disclosure up front and the same privacy words as the game and the note. Checked by: Legal's sign-off row for each paper (X-32), and Orb has seen the text before it is used.
5. (A-QA-08) Match length is read on the A5 build's own packed data, beside every win-rate cell (Easy, Medium, Hard; Orb's-scheme player and masher; both fighters), with median and mean in minutes. After GW4 the Orb's-scheme median on Easy and Medium is inside 6 to 8 minutes. Checked by: the saved table under `docs/qa/runs/<sha>/`.
6. (supports A-AI-02, A-QA-05; exit X-06) The band table is read before and after Game Design's numbers, with the match count per cell that A-AI-11 set so neighbouring bands can be told apart: Orb's scheme, masher and stick-only at each level, and the balance band between the two fighters from A-QA-04 in the same window. Checked by: the saved tables, with the commit and the data hash, under `docs/qa/runs/<sha>/`. X-06 must pass here; a miss goes to the EP the same day.
7. (supports A-WORLD-05) Over 10 seeds, the height drawn and the height stood on under each fighter's feet are within 8 units, with zero craters popping into view, using Rendering's probe. Checked by: the saved reading under `docs/qa/runs/<sha>/`.

Constraints:
- Tokens: about 0.5M (two S rows), an estimate; the readings in items 6 and 7 are supporting work on other rows.
- State hash: your own files do not change the sim's state fingerprint. A-QA-08's fix is numbers, and those land only in golden window GW4 "Numbers only" at the end of the milestone: data values only, no rule change.
- Machine: Godot runs headless only; at most 3 Godot processes for a short gate; the band and length batches are long runs, started at below-normal priority; a reading taken while the machine was saturated is marked invalid, not reported.
- Determinism: seeded matches, fixed step; every reading names its seeds, commit and data hash; read the build's packed data, not a patched tree.
- Originality: nothing in the guide borrows another game's words or names.
- Orb's rules: plain words (say what you press and what you see); forward-facing text is seen by Orb before use; the AI disclosure is up front; no in-progress character art in anything a tester could pass on; "nothing leaves your PC unless you send it".

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Starts after A-LEGAL-05 (the tester note settled), A-TOOLS-02 (the itch.io page and keys rehearsed) and A-TOOLS-05 (the report folder works off Orb's PC) have landed in A2; the guide was drafted for the A2 session and is finished here once the menus stop changing at A4. The length and band readings need A-AI-04, A-AI-11 and A-QA-09 (A1) and the A4 build. Game Design's numbers wait on your first table; GW4 closes on your second. A6's two-friend session waits on items 1 to 4.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- A second table reads the team and horde bands and the horde's run length in GW4. On the tester checklist, the two-player rows are marked "if you have a second controller". (ORD-03, MIS-09)
