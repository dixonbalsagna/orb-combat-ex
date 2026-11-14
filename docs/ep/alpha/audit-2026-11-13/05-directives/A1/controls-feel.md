# A1: Controls & Game Feel Director

Leads: A-CONTROLS-02, A-CONTROLS-06
Supports: A-COMBAT-05, A-COMBAT-11, A-COMBAT-08, A-MODES-08, A-PROCESS-03

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: A build made plainly from main gives Orb the same pad they played on 9 November, with no private switch table in between, and a scripted pad can press every cell of the move table and say which presses do nothing.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1, golden window GW1, the X-03 line in "Exit criteria this audit proposes to change"); `docs/ep/alpha/audit-2026-11-13/02-areas/CONTROLS.md`; `docs/ep/alpha/audit-2026-11-13/01-inventory/I-08-data-schemas-switches.md` lines 96-128 (the input switches: main against the two kept builds).
- A-CONTROLS-02: the pad as Orb plays it is not the default in data: eleven input switches are off on main and on in both played builds only through the private page's switch table. Evidence: `data/input/timing.json:50-62`; the packed `data/input/timing.json` of the two kept builds; `tools/preview/switches.mjs:127-204`. The earlier flip of twelve input switches needed a patch across 15 files and re-recorded reference matches (`docs/controls/pending/landing/README.md:13-16`).
- A-CONTROLS-06: no moveset coverage probe exists. The nearest tool taps every face button under eight held layers and flicks the stick per layer, but for one fighter, for 90 ticks, with no report of empty or repeated cells, not in CI, and its only saved result is from a tree of 1 November. Evidence: `sim/input/tools/audit_probe.gd` (lines 65-74, 95-109, 161); `docs/controls/controls-audit.md:3`, `:53`.
- Supports: A-COMBAT-05 (a released stick beam fires up to 90 ticks late: `sim/director/beam_move.gd:266-272`) and A-COMBAT-11 (RT + B stays a signature with no time limit: `sim/director/brawl.gd:3178-3179`), both Encounter's. A-COMBAT-08 (QA's probes for X-03, X-04, X-13, X-16 and the X-17 count). A-MODES-08 (Tools' mode smoke suite drives the menus with a pad). A-PROCESS-03 (the uncommitted working tree; `docs/controls/` has uncommitted pages).
- Spike S4 is Combat's, with you: the coverage count on the played build's own data.

You own: `sim/input/`, `docs/controls/`.
- ask under NEEDS FROM EP for a grant: `data/input/timing.json` (and any other file under `data/input/` a switch row names)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (only if a data shape changes)
- ask under NEEDS FROM EP for a grant: `tools/preview/switches.mjs` (Tools removes each row once main's data carries it; you name the rows)
- Input switches whose data sits in `data/director/` are Encounter's rows and ones in `data/fight/` have no owner line: list them under NEEDS FROM EP.

Acceptance criteria:
1. (A-CONTROLS-02, X-29) Every input switch row in the inventory table reads the same on main as in the played build's packed data, or has a written line saying why it stays as it is. Checked by the EP's row count and by reading the first desktop build's packed `timing.json`.
2. (A-CONTROLS-02) Every test under `sim/input/test/` passes on main's new defaults, with no test pinned to the old ones without a reason. Result saved under `docs/controls/runs/<sha>/`.
3. (A-CONTROLS-02, look and feel) The pad on main is compared with the 9 November build on one of Orb's saved play files: the same inputs give the same actions. Any visible difference names the look gate (ADR 0010): a side-by-side against the reference build (`node tools/flash/side-by-side.mjs`) before the EP commits. Nothing is meant to feel or look different.
4. (A-CONTROLS-06, X-03, first reading) A probe under `sim/input/tools/` drives a scripted pad through every cell of today's move table in a live match: each held button (none, LB, RB, RT, LT) by each face button by each way of pressing, plus the right stick's strikes and beams, for both fighters. It reads the build's packed data, not main's loose files, and writes one line per cell: the outcome, "no outcome", or "same as cell ...". The tool existing and one reading saved under `docs/controls/runs/<sha>/` closes this item; the number is expected to fail. From A2 the reading is taken on every build.
5. (A-CONTROLS-06) The probe's cell list matches Combat's (routed through the EP), so "empty by design" is told apart from "empty by accident", and a note says how to add a cell when the table changes in A4.
6. (Supports) A-COMBAT-05 and A-COMBAT-11: input tests cover a released beam that cannot start and RT + B at the last tick of its window and one tick after; your feel note on beams being refused more often goes in your report. A-COMBAT-08 and A-MODES-08: QA's and Tools' scripted pads use Orb's scheme (right-stick attacks, LB guard) through `sim/input/`, with no private copy of the mapping. A-PROCESS-03: each uncommitted file under `sim/input/` and `docs/controls/` is marked keep or ignore in one list for the EP.
7. Records: every gate result quoted is a saved file under `docs/controls/runs/<sha>/` (corrective item CD-22).

Constraints:
- Tokens: about 2.4M as an estimate (two rows of size M at 1.2M). The spike's cost is in the 4.5M set aside for the five spikes.
- State hash: A-CONTROLS-02 changes the sim's state fingerprint and lands only in golden window GW1, "Main is the game". The probe changes nothing.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; a run over about ten minutes at below-normal priority; stop only your own processes by PID; no browser of your own (captures only through Tools' launcher, asked for through the EP).
- Determinism: input to intent is deterministic and replayable; seeded RNG, fixed step. Numbers live in data; a data shape change updates its schema in the same commit.
- Originality: nothing from an existing franchise.
- Orb's rules: the left stick moves and defends, the right hand attacks; beams come only from the right stick, apart from the signature inputs Orb named; nothing drawn on, over or between the fighters; clips Orb judges for controls show the button and whether it is a tap, a mash or a hold; plain words. No new input behaviour in A1: this is the 9 November pad, made the default.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before A-CONTROLS-02: Orb's yes to decision 1, the working tree committed or deliberately ignored (A-PROCESS-03), and the played build's patches on main (A-CODE-03). The pad is the first switch group to land in step 4 of A1's order. The probe starts on day one on a scratch copy. Waiting on this: A-CODE-01 and the golden record (A-CODE-02); Encounter's two input fixes in the same window; QA's scripted player on Orb's scheme (A-QA-09) and the first win-rate readings; Tools' mode smoke suite; and in A4 the move table (A-COMBAT-04), which is measured by your probe.
