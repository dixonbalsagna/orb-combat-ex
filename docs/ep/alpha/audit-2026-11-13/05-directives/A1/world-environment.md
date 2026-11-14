# A1: World & Environment Director

Leads: A-WORLD-01
Supports: A-ENERGY-05, A-CODE-03, A-PROCESS-03, A-WORLD-14

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: Starting a match from the menu of a build made plainly from main puts the fighters on the round planet Orb plays on, with its water and climate, not on the old hand-made arena.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1, golden window GW1, decisions 2 and 3); `docs/ep/alpha/audit-2026-11-13/02-areas/WORLD.md`; `docs/ep/alpha/audit-2026-11-13/01-inventory/I-08-data-schemas-switches.md` (the world rows of the switch table); `tools/world-checks.json`; `docs/ep/vision.md` line 1719.
- A-WORLD-01 (blocker): on main a match with no planet setup key plays the old hand-made arena, the menu never sets that key, and Orb's globe build gets it from a preview patch plus world data switches that main ships off. Evidence: `sim/core/sim.gd:183`; `render/core/main.gd:441-449`, `:1644`; `tools/preview/stack-preview.mjs:6`; also `data/biomes/water.json:4`, `data/biomes/climate.json:4` and the same two lines in the kept build's packed data. The register's cost note counts about seven data switches.
- A-WORLD-14 (Orb's decision 2): no default world is decided. Orb's solo copy opens on planet 7 through a shortcut's page word, LAN fixes planet 7, and main's menu matches play the hand-made arena. Evidence: `docs/ep/vision.md:1719`; `net/lan.gd:30`; `docs/ep/alpha/audit-2026-11-13/reads/RR-03.md:84-86`. Recommendation on the table: a new random planet each quick match with the seed shown and saved in reports; one fixed planet for a newcomer's first match and for tests.
- A-ENERGY-05 (Simulation leads): the world still feeds the backburnered hero and villain meters on every building fall. Evidence: `sim/world/collateral.gd:406-466`.
- A-CODE-03 (Tools leads): the played build's planet entry exists only as a patch to a scratch copy of the main scene. Evidence: `tools/preview/switches.mjs:7-8`, `:1027`.
- A-PROCESS-03 (EP leads): 14,805 uncommitted paths, world files among them.

You own: `sim/world/`, `data/biomes/`, `docs/world/`.
- ask under NEEDS FROM EP for a grant: `sim/core/sim.gd` (Simulation's path: the default at line 183 when a match has no planet setup key)
- ask under NEEDS FROM EP for a grant: `render/core/main.gd` (Rendering's path: lines 441-449 and 1644, where the game passes the planet to the match)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (only if a data shape changes)
- The menu row that sets the planet is UI's and the preview patch is Tools': list what you need under NEEDS FROM EP.

Acceptance criteria:
1. (A-WORLD-01, X-05, X-13) Every world switch row in the inventory table reads the same on main as in the played build's packed data, or has a written line saying why it stays as it is. Checked by the EP's row count and by reading the first desktop build's packed `water.json` and `climate.json`.
2. (A-WORLD-01) A match started from the menu on main, with no launch word and no patch, plays the round planet. A check starts a match with no planet setup key and reads back a generated planet, not the arena. The old arena stays reachable for tests by an explicit key.
3. (A-WORLD-01, X-11) The same seed gives the same planet twice on one PC (a planet hash compared across two runs); the cross-platform comparison is a later milestone's. The run list in `tools/world-checks.json` runs on the new defaults with a verdict line for every check; any check that only ever saw the arena is listed. Results saved under `docs/world/runs/<sha>/`.
4. (A-WORLD-14) Once Orb answers decision 2, the default follows it: if the recommendation stands, a quick match draws a new seed from the match's seeded RNG and the seed is readable by the HUD and by the report; the first match and the tests use one fixed planet. If Orb has not answered when the window opens, the default is the fixed planet the played build used, and the question stays open by name in your report.
5. (Look gate, ADR 0010) The menu match on main is compared with the 9 November build on the same planet at the same ticks: a side-by-side against the reference build (`node tools/flash/side-by-side.mjs`) before the EP commits. Nothing is meant to look different; the 9 November build's known picture faults are not part of the comparison.
6. (Supports) A-ENERGY-05: once Orb answers decision 6, the feed in `sim/world/collateral.gd` to the old meters is zeroed in data or switched off, and building falls still count for everything else. A-CODE-03: the planet entry Tools moves onto main needs nothing from a preview patch. A-PROCESS-03: each uncommitted file under `sim/world/`, `data/biomes/` and `docs/world/` is marked keep or ignore in one list for the EP.

Constraints:
- Tokens: about 1.2M as an estimate (one row of size M).
- State hash: A-WORLD-01 changes the sim's state fingerprint (the world a match plays on) and lands only in golden window GW1, "Main is the game"; the reference matches are re-recorded once when the window closes.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; the full world check list is a long run, started at below-normal priority; stop only your own processes by PID; no browser of your own (captures only through Tools' launcher, asked for through the EP).
- Determinism: planet generation is seeded and repeatable; fixed step; all distances use shortest-arc wrap math; no rendering state in the sim. Numbers live in data; a data shape change updates its schema in the same commit.
- Originality: every biome, landform and place name is our own.
- Orb's rules: no civilian deaths (bystanders bounce or scatter); destruction is big and lasting; no dissolves or fades; plain words. The terrain workshop of 2026-11-09 is not part of this brief: Alpha gets craters and trenches drawn where you stand, later.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: Orb's yes to decisions 1 and 2, the working tree committed or deliberately ignored (A-PROCESS-03), and the planet entry on main (A-CODE-03). In step 4 of A1's order the round planet lands after the pad, the computer opponent and the match-ending rules, and before the camera and the look. Waiting on this: Camera's and Rendering's defaults (they ride on the globe ground); A-CODE-01 and the golden record (A-CODE-02); the first desktop build; in A4 the custom planet (A-WORLD-02).

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- The seed-only Windows-against-Linux planet comparison is read in A1 through Tools' CI step; A-WORLD-09 no longer waits on the dials. (ORD-11)
