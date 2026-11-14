# A4: Combat & Choreography

Leads: A-COMBAT-04
Supports: A-MODES-02, A-AI-01, A-ANIM-03

Goal: With either fighter, every held button with every face button (tap, mash, hold) does something, and the martial and energy rows give moves that are that fighter's own and different from each other.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4; the resize table's first row; decision 15); `docs/ep/alpha/audit-2026-11-13/02-areas/COMBAT.md` (finding F-COMBAT-04 and its verify note) and `02-areas/CONTROLS.md` (F-CONTROLS-03); `docs/ep/alpha/audit-2026-11-13/reads/RR-01.md` (the table as read from the code, lines 219-224 for the counts); `docs/design/pad-first-press.md`; `docs/design/moveset-rules.md`; `docs/ep/proposals/combat-variety-packet.html` (section 4, the cost of the stick's depth); `docs/combat/henchmen-grades.md`; `docs/ep/vision.md` (Orb's five stances and the signature inputs); the coverage probe's first reading from A1 (A-CONTROLS-06; the EP gives the path).
- A-COMBAT-04 (XL, blocker): the move table is incomplete for both fighters: 18 of 101 cells have no outcome, 65 reach the same entry as another cell, and the LB, LT and RT rows of the face buttons mostly repeat the no-stance row. Evidence: `sim/input/layout.gd:522`; `data/input/timing.json:48`; `docs/design/pad-first-press.md:23`; `sim/director/stance.gd:51-60`.
- From the audit's verification: RT + X, Y and A are empty by the code's own word (`sim/director/interrupt.gd:366-367`); LT + A, and plain A away from a grab, are empty (`interrupt.gd:376-377`). Two cells first called missing do exist: RB + A lays a mine (`sim/director/blast.gd:232-233`) and A on a held guard is the deflect or reversal (`blast.gd:230-231`).
- Supporting rows: A-MODES-02 and A-AI-01 (the weak enemies need a small moveset as data: `docs/combat/henchmen-grades.md:3` says nothing is built); A-ANIM-03 (Animation's coverage table is rebuilt from your files as they are on main).

You own: `data/atoms/`, `data/exchanges/`, `docs/combat/`.
- ask under NEEDS FROM EP for a grant: `data/combat/` (the moveset data; no director owns it)
- ask under NEEDS FROM EP for a grant: `data/input/timing.json` (only if a cell's press timing must change; Controls reads it)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (any data shape you change)
- Routing in `sim/director/` is Encounter's and `sim/input/` is Controls': list each cell that needs a routing or input change under NEEDS FROM EP, with the file and lines.

Acceptance criteria:
1. (A-COMBAT-04) Before any content: one table page in `docs/combat/` listing every cell for each fighter (held button by face button by way of pressing, plus the right stick's strikes and beams), what it does today, and what it will do. Cells that share an entry by design are marked as shared with the reason. The EP checks it against Game Design's rules, and Orb sees it.
2. (A-COMBAT-04, X-03) Written for the smaller version the path proposes: the pad-driven coverage probe, run in a live match for each fighter, reports no cell without an outcome; no duplicate inside the martial and energy rows; and the LB, LT and RT rows share entries only where the table page says so. Full version if Orb declines the proposal: every one of the 55 cells a fighter distinct and reachable, which puts the row back to XL or more and adds about a week to A4.
3. (A-COMBAT-04) The martial and energy rows differ between the two fighters: the probe's report for Grist and for Loupe is compared, and no cell in those rows resolves to the same entry for both.
4. (A-COMBAT-04) Every new cell is data (atoms, exchange templates, moveset entries), not code; CI's data job passes on the commit.
5. (A-COMBAT-04) Each new or changed move ships with a side-by-side against the reference build in `docs/ep/taste.md` (look gate, ADR 0010; `node tools/flash/side-by-side.mjs`), and the clip shows the button and whether it is a tap, a mash or a hold, so Orb can judge it.
6. (A-COMBAT-04) Specials and signatures cost stamina as well as energy and plain blows refill stamina, as Orb confirmed: each new cell's costs are in data and follow the model page from A3 (A-ENERGY-01).
7. (support, A-MODES-02 and A-AI-01) A weak enemy's moveset exists as data for the grades the horde page names, small enough that a wave reads at speed.
8. (support, A-ANIM-03) A list of every pool and piece the table uses is handed to the EP for Animation's coverage table.
9. Evidence: the probe's report per fighter, the data job's result and the side-by-sides are saved under `docs/combat/runs/<sha>/`.

Constraints:
- Tokens: about 8M as an estimate (XL); about 4M (L) for the smaller version. Quality per cell matters more than count: Orb called the mixed string "a long way from finished but right track".
- The row changes the sim's state hash. It lands only in golden window GW3, "Many bodies and the full fighter". A cell not ready when the window closes waits as a named remainder; it does not open another window.
- Machine: Godot headless only; at most 3 Godot processes for a short gate; long batches at below-normal priority; clips and stills only through Tools' launcher.
- Determinism: seeded RNG, fixed step, no rendering state in the sim; numbers in data, schema updated in the same commit as a shape change.
- Originality: every move, name and pose is our own; no move, catchphrase or signature pose from an existing franchise. Pose and look rules are Orb's creative rulebook (Art and Animation keep it), not a Legal gate.
- Orb's rules: each press is a blow; beams only from the right stick and the signature inputs Orb named (RT + RB + a flick for the energy signature, RT + a flick for the martial one); nothing drawn on, over or between the fighters; no dissolves or fades; must complement high-speed combat; move names a player reads are seen by Orb first; plain words.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: Orb's answer to decision 15 (the table's bar); A-COMBAT-02 (signatures on Orb's inputs) and A-ENERGY-01 (the stamina, energy and body loop) on main from A3; the coverage probe from A1. The table page and data can be worked ahead behind a switch from the day the signature inputs are fixed. Waiting on this: X-03's must-pass reading, Animation's rebuilt coverage table (A-ANIM-03), and A5's tuning window, which may change numbers but no rule.
