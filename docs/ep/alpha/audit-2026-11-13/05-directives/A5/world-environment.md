# A5: World & Environment

Leads: none
Supports: A-WORLD-05

Goal: The trenches and scars a fight leaves on the planet can be drawn exactly where the fighters stand, and the same seed and choices give the same planet on Windows and on Linux.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A5, exit line X-11; decision 3); `docs/ep/proposals/terrain-globe-plan.md` (item 9 at lines 56 to 59, and steps 2 and 4 of the step table); `docs/rendering/pending/2026-11-01h-store-bowls/README.md`; `tools/world-checks.json` and `tools/world-checks.mjs`.
- A-WORLD-05 (Rendering leads): the ground drawn is not the ground stood on. Evidence: `render/core/look.gd:596` (only the 16 nearest crater bowls are drawn); `docs/ep/proposals/terrain-globe-plan.md:54-58` (planet trenches and beam scars are not drawn, but feet and props stand on them); `docs/ep/vision.md:1690` and `:1695` (Orb's reports of clipping, humps in a crater and a flat brown crater).
- Exit line X-11 (no row of its own in A5): the planet fingerprint must match between Windows and Linux in CI. The check was made a real check with a verdict in A4 (A-WORLD-09); here it must pass.

You own: `sim/world/`, `data/biomes/`, `docs/world/`.
- In A5 you change no sim behaviour. If Rendering needs a read-only way to list trench and scar records that does not exist, write the smallest one and say under NEEDS FROM EP that it must be shown not to change the state fingerprint before it lands.
- The CI job is Tools' file: ask under NEEDS FROM EP for a grant: `.github/workflows/` (name the file), or hand the EP the step to add.

Acceptance criteria:
1. (supports A-WORLD-05) A one-page note in `docs/world/` tells Rendering, through the EP, which records the store holds after terrain step 2 (craters, trenches, scars and the rest), how each is read without writing, and which height the sim uses under a fighter's feet at a planet point. Each statement points at a file and line. Checked by: the EP reads it; Rendering's probe uses it.
2. (supports A-WORLD-05) If a read-only accessor is added, the same seeded match gives the same state fingerprint with and without it, and the determinism lint passes. Checked by: the two fingerprints and the lint output saved under `docs/world/runs/<sha>/` (CD-22).
3. (exit X-11) The planet fingerprint for the fixed test seeds, with the three dials (city count, climate, water) at two settings each, is identical on the Windows and Linux runners in CI on the A5 commit. Checked by: the CI run's verdict lines, copied as text into `docs/world/runs/<sha>/`. A mismatch goes to the EP the same day: it is a must-pass line.
4. (exit X-11) `tools/world-checks` is run with `--run`, not only verified, and every check prints a verdict line. Checked by: the saved output.

Constraints:
- Tokens: no row of its own; plan on about 0.25M of supporting work, an estimate.
- State hash: no change is allowed. A5's only golden window (GW4) takes numbers, not rules, and none of them are World's. Anything that would change the fingerprint is reported, not made.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; a planet sweep over many seeds is a long run at below-normal priority.
- Determinism: seeded RNG, fixed step, our own trig, no rendering state in the sim; numbers live in data and a data shape change updates its schema in `tools/schemas/` in the same commit.
- Originality: planets, biomes and place names are our own.
- Orb's rules: the terrain workshop of 2026-11-09 is after Alpha (decision 3); Alpha gets craters and trenches drawn where you stand, no more.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: A-WORLD-03 (terrain step 2, A3) and A-WORLD-09 and A-WORLD-02 (the fingerprint check and the three dials, A4) must be on main first. Rendering's drawing work waits on item 1. A6 re-reads X-11 on the candidate.
