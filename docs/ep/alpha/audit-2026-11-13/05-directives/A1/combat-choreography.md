# A1: Combat & Choreography Director

Leads: A-COMBAT-14
Supports: A-CONTROLS-06

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: The mixed string Orb called "a long way from finished but right track" plays from main itself, not from files kept outside it, and Orb gets an honest map of which button presses do nothing today with a price for filling them.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1; the A-COMBAT-04 line in "Rows proposed smaller for Alpha"; decision 15); `docs/ep/alpha/audit-2026-11-13/02-areas/COMBAT.md` and `CONTROLS.md`; `docs/ep/alpha/audit-2026-11-13/reads/RR-01.md` lines 219-224 (the cell count).
- A-COMBAT-14: the mixed string's switch reads "on" in the played build but no game code on main reads its data file; the feature comes from parked files (finished work waiting outside main). Evidence: `data/combat/mixed.json:4`; `docs/tools/runs/6a30b4c9/switch-list.txt:88`; `tools/preview/switches.mjs:229`; also `tools/preview/stack.json:40`.
- Spike S4 (a throwaway trial; nothing lands), yours with Controls & Game Feel: run the coverage count on the played build's own data. The register's figures, read from main's data: per fighter 101 cells were tabulated, 18 have no outcome and 65 reach the same entry as another cell; the LB, LT and RT rows of the face buttons mostly repeat the no-stance row. Evidence for A-COMBAT-04 (the A4 row this spike sizes): `sim/input/layout.gd:522-524`; `data/input/timing.json:48-49`; `docs/design/pad-first-press.md:23`; also `sim/director/brawl.gd:719`, `docs/ep/proposals/combat-variety-packet.html` (section 4 prices the stick's depth alone). The area file notes Orb's ruling gives 55 cells a fighter for the face buttons (three ways of pressing for X, Y and B, a press and a hold for A, by five stances), plus the stick.
- A-CONTROLS-06 (Controls leads): no probe presses every cell of the move table. Evidence: `sim/input/tools/audit_probe.gd`; `docs/controls/controls-audit.md:3`, `:53`.

You own: `data/atoms/`, `data/exchanges/`, `docs/combat/`.
- ask under NEEDS FROM EP for a grant: `data/combat/mixed.json` (and any other file under `data/combat/` the parked string needs)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (only if a data shape changes)
- The director code that reads the string sits in `sim/director/` (Encounter's), and the park list sits in `tools/preview/stack.json` (Tools'). Name the lines under NEEDS FROM EP; the EP routes them.

Acceptance criteria:
1. (A-COMBAT-14) A build made from main with no park applied plays the mixed string: the code that reads `data/combat/mixed.json` is on main, the park's entry is gone from the build tool's list, and the switch row either reads the same on main as in the played build or is removed because it no longer describes a choice. Checked by a director check that plays the string on main's data and by reading the first desktop build's packed data. Results saved under `docs/director/runs/<sha>/` (the check is Encounter's) with your note in `docs/combat/`.
2. (A-COMBAT-14, look) The string on main is compared with the 9 November build at the same ticks: a side-by-side (`node tools/flash/side-by-side.mjs`) against the reference build before the EP commits it (the look gate, ADR 0010). Nothing is meant to look different.
3. (Spike S4) One page in `docs/combat/`: the count of empty and repeated cells per fighter on the played build's packed data (not main's), cell by cell; the price in tokens of the smaller table and of the full table; and the question for Orb. Smaller version proposed for Alpha: no dead cell anywhere, the martial and energy rows complete and distinct for each fighter, and the LB, LT and RT rows may share entries where the design page says so, written down. Full version if Orb declines the proposal: every cell of the full table (55 cells a fighter plus the stick) distinct at Alpha, back to extra-large or more, with A4 about a week longer.
4. (Supports, A-CONTROLS-06) Controls has from you, through the EP, the list of cells of today's table and what each is meant to do, so the probe can tell "empty by design" from "empty by accident".
5. Records: the spike's count is saved as a file beside the page, with the build it was read from named by commit.

Constraints:
- Tokens: about 0.25M as an estimate (one row of size S), plus your share of the 4.5M set aside for the five spikes.
- State hash: A-COMBAT-14 changes the sim's state fingerprint and lands only in golden window GW1, "Main is the game". The spike changes nothing.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; long runs at below-normal priority; no browser of your own (captures only through Tools' launcher, asked for through the EP).
- Determinism: seeded RNG, fixed step. Content is data: atoms and exchanges are data files, and a data shape change updates its schema in the same commit.
- Originality: every move, name and pose is our own; nothing from an existing franchise.
- Orb's rules: nothing drawn on, over or between the fighters; clips Orb judges for moves show the button and whether it is a tap, a mash or a hold; plain words. No new moves are authored in A1: the table's content is A4's work and waits for Orb's answer.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before A-COMBAT-14: Orb's yes to decision 1, the working tree committed or deliberately ignored (A-PROCESS-03), and Encounter's part of the string on main in the same window. The spike starts on day one and reads the kept build's data. Waiting on this: A-CODE-01 (no row differs); decision 15 (the move table's bar) and, in A4, the move table itself (A-COMBAT-04), which is the last large item on the critical path.
