# A1: QA & Balance

Leads: A-AI-03, A-AI-04, A-AI-11, A-COMBAT-08, A-QA-03, A-QA-04, A-QA-07, A-QA-09, A-SAVES-01
Supports: A-COMBAT-05, A-AI-10, A-CODE-02, A-CODE-04, A-CONTROLS-06, A-MODES-08, A-PERF-07, A-PROCESS-03

Goal: for the first time the team can say, with saved numbers from the game Orb actually plays, how hard each difficulty is for someone who plays like Orb, whether the two fighters are even, and which of the match's promised moments do not happen yet.

Context: read first `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1 and "The tool rule"), `02-areas/QA.md`, `02-areas/AI.md`, `reads/RR-06.md`, `reads/RR-08.md`, `docs/design/gauntlet-plan.md`, `tools/feel/gauntlet.gd` (Tools' "gauntlet": one scripted pad playing whole seeded matches against the computer), `qa/known-bugs.md`, `docs/ep/alpha/alpha-audit-specification.md` lines 166 to 201 (X-03, X-04, X-06, X-13, X-16, X-17, X-27).
- A-COMBAT-08 (M): no tool measures X-04 (forms reached), X-13 (every pillar in one match) or X-16 (beam escape), and X-17's beam trace has no count. Evidence: `qa/godot/beam_trace.gd:1-4`; `sim/director/tools/stance_check.gd:1-3`; `.github/workflows/ci.yml:221`. (X-03's pad-driven coverage probe is Controls' row A-CONTROLS-06.)
- A-QA-04 (M): balance between the two fighters is not measured on the build Orb plays. Evidence: `docs/qa/chain-3198301f.md:67`; `docs/qa/main-0ca6f670.md:13` (and `:40`, the newest both-slots figure); `inventory.md:51` (72 of 92 switch rows differ).
- A-AI-04 (S): no win rate has been measured on the played build's own packed data. Evidence: `docs/director/runs/6eec6a75/hitstop-row/final/cells.txt:1-2`; `tools/feel/gauntlet.gd:2-3`; `reads/RR-06.md:97`. The verifier's note: one earlier build was read on its own tree (`docs/tools/runs/1931a0f8/b1-gauntlet.txt:1`); build 6a30b4c9 has none.
- A-AI-03 (S): Medium and Hard have no win-rate record for Orb's scheme on the played build. Evidence: `reads/RR-06.md:117`; `docs/design/gauntlet-plan.md:20-22`; `docs/tools/runs/1931a0f8/b1-gauntlet.txt:5-6` (0% of 40 at each, an earlier build).
- A-AI-11 (S): forty matches a cell cannot tell neighbouring bands apart. Evidence: `docs/director/runs/6eec6a75/hitstop-row/table.txt:2`; `docs/design/gauntlet-plan.md:131`; `alpha-audit-specification.md:168`.
- A-QA-09 (S): the scripted player that matches Orb's scheme lives in Tools' gauntlet, plays slot 0 only, and fired no beam in the recorded cells. Evidence: `tools/feel/gauntlet.gd:4`, `:6`, `:187-206`; `docs/director/runs/6eec6a75/hitstop-row/final/cells.txt:4`.
- A-SAVES-01 (S): no record shows a replay saved by the baseline build verifying to its last tick on that build. Evidence: `docs/qa/runs/6a30b4c9/README.md:5`; no "BLACKBOX OK" under `docs/*/runs/6a30b4c9`; `tools/preview/blackbox-verify.mjs:5`.
- A-QA-03 (S): the bug list holds 1 of the 52 problems Orb reported in play from 2026-11-01 to 2026-11-09. Evidence: `reads/RR-08.md:81-83`, `:18`; `qa/known-bugs.md:200`.
- A-QA-07 (S): the bug list has no severity field and its title still names the prototype. Evidence: `qa/known-bugs.md:1`, `:16`, `:18`.

You own: `qa/`, `prototype/tools/`.
- ask under NEEDS FROM EP for a grant: `docs/qa/` (your reports and `docs/qa/runs/<sha>/`)
- ask under NEEDS FROM EP for a grant: `tools/feel/gauntlet.gd` (only if you change it in place; preferred is a copy of the "orbs" player under `qa/godot/`, handed over by Tools through the EP)
- CI changes are Tools' (`.github/`): name the job you need under NEEDS FROM EP.

Acceptance criteria:
1. (A-QA-09) The scripted player on Orb's scheme (right-stick attacks, LB held to guard) lives under `qa/godot/`, plays both slots, and uses the stick beam at a stated pace. Check: a saved run where the player's beam count is above zero in both slots.
2. (A-AI-11) One page states how many matches a cell needs to tell the X-06 bands apart, with the interval method named; every win rate you report from now on carries its interval and the tree or build it was read on. Check: the page; no later table without both.
3. (A-AI-04) The win-rate batch runs on a build's own packed data, with no patches laid over the tree. First on the kept 9 November build's tree, then on the first desktop build when Tools delivers it. Check: the saved run names the build and shows the data hash it read.
4. (A-AI-03, X-06 first reading) Win rates for Orb's scheme at Easy, Medium and Hard on that packed data, at the sample size from criterion 2. A number outside the proposed bands is an acceptable first reading: the criterion is that the reading is saved under `docs/qa/runs/<sha>/`, not that it passes. If Medium or Hard is still near 0%, say so in RISKS in one plain line.
5. (A-QA-04) A both-slots balance reading (each fighter in each slot) on the same packed data, at least 100 matches a side, with its interval. First reading saved.
6. (A-COMBAT-08, first readings) Three tools exist and each has produced one saved reading, pass or fail: a count of beams started by any input other than the right stick or RT + B, over the scripted set and Orb's saved play files (X-17; the aim is 0 and it must pass from A2); a checklist read from a match's event feed that marks each pillar seen or not seen (X-13); a scripted defender sidestep at three ranges (X-16; expected to fail until the beam is rebuilt in A3). The forms-reached probe (X-04) is written with Simulation and Encounter through the EP; your part is the scripted match and the saved reading. Write each against today's game, and read the build's packed data, not main's.
7. (A-SAVES-01, X-27) One of Orb's saved play files from the baseline build passes `tools/preview/blackbox-verify.mjs` to its last tick on that build's tree, and the first real LAN save has been put through the report tool. Saved: the "BLACKBOX OK" line, or the failure and its reason, under `docs/qa/runs/6a30b4c9/`.
8. (A-QA-03) The bug list holds every problem in `reads/RR-08.md` with a status (fixed in which commit, open, cannot reproduce, or by design), and it agrees with the EP's owed list. Check: the EP compares the two lists; a count of 52 accounted for.
9. (A-QA-07) Every entry carries a severity beside its release horizon and closing step; the title names the game, not the prototype.
10. Supports: a count of late-firing and refused stick beams before and after Encounter's fix (A-COMBAT-05); the computer's perfect-block rate against charged attacks measured on the played build before Encounter re-cuts it (A-AI-10); the QA batch run once with the switches as shipped, for the new golden record (A-CODE-02); the list of QA scripts that must run in a workflow, to the EP for Tools (A-CODE-04); the match script the mode smoke plays (A-MODES-08); your part of the coverage probe's reading (A-CONTROLS-06); a memory reading at 5 and 30 minutes of computer-against-computer play for Performance (A-PERF-07); your three uncommitted tool edits listed as commit or drop (A-PROCESS-03).

Constraints: about 4.15M tokens at the register's size classes (2 M, 7 S), an estimate. None of this changes the sim's state hash: probes and batches only read. Headless Godot only; at most 3 Godot processes for a short gate; a batch longer than about ten minutes runs at below-normal priority; a reading taken while the machine was saturated is marked invalid, not reported; make sure every run exits and stop only your own processes by PID. Seeded matches, fixed step; every batch records its seeds so it can be repeated. No browser of your own: stills or clips only through Tools' launcher. Orb's play files are private: quote ticks and counts, never publish a file. Plain words in every report; no flash talk in anything bound for Orb. All test content original.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: criteria 1 and 2 start at once. A-AI-03 needs A-AI-04. Criteria 3 to 5 are read first on the kept build's tree and repeated on the first desktop build, which needs A-TOOLS-01 (step 6 of A1). The X-17 count should exist before Encounter's stick-beam fix lands in golden window GW1, so the before and after can be compared. A-NET-05 (the build id in a replay, Simulation's) lands before GW1; re-run criterion 7 after it. Waiting on you: the A2 rule that X-17 must pass; tuning in A5 (which uses your sample size); the EP's single backlog (A-PROCESS-02), which takes the bug list as an input.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- The bug list's severity field (A-QA-07) also serves the proposed criterion X-35: no open bug of the top severity on the candidate, and every open bug of the next severity seen by Orb and carried by name. Define the two severities here. (MIS-03)
