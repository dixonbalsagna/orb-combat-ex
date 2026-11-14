# A6: QA & Balance

Leads: none
Supports: none

Goal: Two friends finish the tester checklist on their Steam Decks on the same build that passed every measured check, and that build is the Alpha candidate.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A6, "If a milestone misses its exit", "Change control"); `docs/ep/alpha/alpha-audit-specification.md` lines 168 to 201 (the criteria table); your tester guide, checklist and protocol from A5 (A-QA-01); your saved tables from GW4 under `docs/qa/runs/`; `tools/world-checks.mjs`.
- A6 closes no register row. It is each exit criterion re-read on one commit, the second tester round, one round of fixes, and the freeze. The measuring tools were built in earlier milestones and are named below by the row that built them.

You own: `qa/`, `prototype/tools/`.
- ask under NEEDS FROM EP for a grant: `docs/qa/` (run records; the folder has no owner).
- Probes owned by other directors (Controls' move coverage probe, Tools' mode smoke suite, World's checks) are run for you through the EP, or with the EP's written word that you may run them unchanged. You change none of them.

Acceptance criteria (all on the candidate's commit, each saved under `docs/qa/runs/<sha>/`, CD-22):
1. (X-01) Two outside testers on Steam Decks return completed checklists for the candidate, posted with their report files. You read both the same day, turn every problem into a bug-list row with a severity, and give the EP a one-page summary: what stopped a newcomer step, what was confusing, what was only rough. Checked by: the two checklists with no blank row, and the summary.
2. (X-06) On the candidate's packed data, the scripted Orb's-scheme player wins inside each band (Easy 60 to 80%, Medium 35 to 55%, Hard 10 to 30%) at the match count per cell set by A-AI-11, and the team and horde bands from your A4 scripts (A-QA-06) hold. Checked by: the saved tables with commit and data hash.
3. (X-25) Two hours of computer against computer on Windows and on Linux, using the soak from A-QA-02, with no crash, hang or script error and memory growth under 10% against the baseline from A-PERF-07; and the same soak on one friend's Deck, started from the tester package. Checked by: the three result files.
4. (X-03, X-04, X-13, X-16, X-17) The probes from A-COMBAT-08 (forms reached, the pillars in one match, beam escape, and the beam count for X-17) and the move coverage probe from A-CONTROLS-06 are re-run, because the numbers moved at the end of A5: no move-table cell without an outcome (to the bar Orb chose); each form reached; every pillar seen in one normal match of 6 to 8 minutes, on scripted matches and on Orb's saved play files; a beam missed by stepping off its line at three ranges; zero beams or signatures started by an unintended input. Checked by: each probe's saved output.
5. (X-05, X-14) The mode smoke suite (A-MODES-08) passes for each mode offered on Windows and on Linux, and World's checks pass with `--run`, the tier ratio included. Checked by: the saved outputs.
6. (X-27) Every replay saved by the candidate verifies to its last tick on the candidate, and a replay from the A4 build is refused with a plain message, not a crash. Checked by: the saved test output (A-SAVES-01, A-NET-05).
7. A finding from a tester that stops a newcomer step (cannot install, start, finish a match or report) goes to the EP at once and is re-tested on the fixed build by you before the tester is asked again. After the fix round, every criterion a fix could have touched is re-read on the new commit, and the candidate is the last commit on which all of them were read. Checked by: the re-read list.

Constraints:
- Tokens: your runs come from the milestone's 5M for verification (an estimate across all directors); fixes draw on the 8M fix reserve, through the EP.
- State hash: none of this changes the sim's state fingerprint. There is no golden window in A6. If a fix would change it, you say so out loud: the candidate goes back to A5's numbers window and every reading above is taken again.
- Machine: headless Godot only; the soak and the bands are long runs at below-normal priority, one at a time, never while a frame reading is being taken; at most 3 Godot processes for a short gate; a reading on a saturated machine is void, not reported.
- Determinism: every reading names seeds, commit and data hash, and reads the build's packed data.
- Originality: not touched.
- Orb's rules: outside testers do not share the trusted second player's standing, so no tester plays until every safety gate is green on that commit; plain words in anything a tester or Orb reads; the ideas a tester has go to the ideas log, not into the build.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Starts on the commit GW4 landed on, after A5's exit passed and the candidate is on the itch.io page. Items 2 to 6 run before the friends are invited; item 1 waits on people (allow one to two weeks). The fix round waits on your summary. The freeze waits on item 7.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- A tester's raw report and speed-test files are never committed: they live in a git-ignored folder, and only the team's own reading of them (numbers, no quoted notes) is saved under `docs/*/runs/<sha>/`. A tester's request to delete is carried out on that folder and on the report server. (PC-02)
- Added: X-35, no open bug of the top severity on the candidate, and every open bug of the next severity seen by Orb and carried by name. For X-27: a replay saved by the Linux build verifies on the Windows build. X-18 and X-19 are read on the two held-back newcomers if Orb has them; if not, say in the record that the readers were experienced testers. (MIS-03, MIS-04, MIS-02)
