# A4: World & Environment

Leads: A-WORLD-02, A-WORLD-09
Supports: none

Goal: A player sets up their own planet from a seed and three dials (how many cities, the climate, how much water), and a second PC given the same choices gets exactly the same planet.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4; the resize table's row for A-WORLD-02; X-11 under "Exit criteria this audit proposes to change"; decision 16); `docs/ep/alpha/audit-2026-11-13/02-areas/WORLD.md` (F-WORLD-02, F-WORLD-09 and its verify note) and `02-areas/MODES.md` (F-MODES-07, F-MODES-12); `docs/world/planet-overhaul.md` (section 4.4 on what joins the key; 4.5 on build order); `sim/world/planet.gd`; `sim/world/planet_world.gd`; `data/biomes/planet.json`; `data/biomes/climate.json`; `sim/world/tools/planet_digest.gd`; `sim/world/tools/planet_check.gd`; `tools/world-checks.json`; `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- A-WORLD-02 (L, blocker): custom planet setup has nothing under it: the generator takes a seed only, the planet's size is a constant, and city count, climate and water are fixed numbers in data files, not match settings. Evidence: `sim/world/planet.gd:328` (`make(seed)`: "a pure function of it and of the data"); `sim/core/constants.gd:21`; `data/biomes/planet.json:92` (`"cities": 12`); `render/core/main.gd:441-449` (the menu "has no such choice yet").
- A-WORLD-09 (S, major): the planet hash comparison X-11 asks for is not a check: the fingerprint tool prints lines with no verdict and is left out of CI, CI runs on Linux only, and no Windows-against-Linux comparison of a generated planet is on file. Evidence: `sim/world/tools/planet_digest.gd:2-4`; `tools/world-checks.json:32` ("no verdict"); `.github/workflows/ci.yml:389` (the world job runs on Linux). From the audit's verification: `planet_check` is in CI and compares a stored vectors file for seeds 7 and 11 with the Linux run (`planet_check.gd:388-390`), but it covers no chosen city count, climate or water, and nothing records which platform wrote the file.

You own: `sim/world/`, `data/biomes/`, `docs/world/`.
- ask under NEEDS FROM EP for a grant: `tools/world-checks.json` and `.github/workflows/ci.yml` (listing the digest as a check with a verdict; or ask for Tools to make the change)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (the dials change the shape of `data/biomes/planet.json` or of the match setup)
- The dials in the match key, the replay header and the state hash are Simulation's; the LAN handshake is Netcode's; the menu's planet row is UI's; `render/core/main.gd` (`planet_part`) is Rendering's. List what each must carry under NEEDS FROM EP: the names, types and ranges of the dials.

Acceptance criteria:
1. (A-WORLD-02) Written for the smaller version the path proposes: the generator takes a seed and three dials (city count, climate, water) at today's one size. With every dial at its default the planet is the one generated today, line for line in the digest. Full version if Orb declines the proposal: the size pick as well (A-WORLD-08, L), which joins this golden window and needs Steam Deck readings per size.
2. (A-WORLD-02) Each dial has a small set of named steps with ranges agreed with Game Design through the EP; the ranges and defaults are in data with a schema. At each end of each dial a generated planet passes the existing world checks (run with `--run`, not `--verify` alone): there is land to fight over, at least one city when the count is not zero, and water only where the base terrain is below sea level.
3. (A-WORLD-02, X-11) The dials are part of what identifies a planet: two different settings never give the same planet hash, and the same seed and settings always do. A check with a verdict line proves both and runs in CI.
4. (A-WORLD-02, X-11) On two LAN PCs, the same seed and choices give the same planet: the planet hash both PCs log is compared and recorded (the play itself is Orb's and the trusted second player's; the record is saved under `docs/world/runs/<sha>/`).
5. (A-WORLD-02) A still of the planet at each end of each dial, with a side-by-side against the reference build in `docs/ep/taste.md` for the default setting (look gate, ADR 0010; `node tools/flash/side-by-side.mjs`), before anything is committed. Stills come from the web build through Tools' launcher.
6. (A-WORLD-09) `planet_digest` ends in a verdict line: it compares its fingerprint against one pinned file per generation, says pass or fail, and records in that file which platform and commit wrote it. It is listed in `tools/world-checks.json` as a check and runs in CI.
7. (A-WORLD-09, X-11) The pinned file is written on Linux in CI and the same check is run headless on a Windows PC against it: the result (match, or the first differing line) is saved under `docs/world/runs/<sha>/`. At A4 this is a first reading: the tool exists and the reading is saved. The Windows-against-Linux comparison must pass from A5.
8. (A-WORLD-09) The digest covers at least the default planet and one non-default setting of each dial.
9. Evidence: world-check results, the digest files and the stills are saved under `docs/world/runs/<sha>/`.

Constraints:
- Tokens: about 4.25M as an estimate (L 4M + S 0.25M); about 1.45M if the smaller version of A-WORLD-02 stands (M).
- A-WORLD-02 changes the sim's state hash (the dials join the planet's data hash and the replay key). It lands only in golden window GW3, "Many bodies and the full fighter". A-WORLD-09 does not change the hash and can land as soon as the dials exist.
- The risk to watch: a dial that is not in the key puts two LAN PCs out of step. The check in criterion 3 is the guard; a float difference between Windows and Linux would show first in criterion 7.
- Machine: Godot headless only; at most 3 Godot processes for a short gate; a generation soak or cost measurement over about ten minutes runs at below-normal priority, and a reading on a saturated machine is invalid; stills only through Tools' launcher.
- Determinism: seeded RNG, fixed step, our own trig, shortest-arc wrap math; the planet stays a pure function of the seed, the dials and the data; numbers in data, schema updated in the same commit as a shape change.
- Originality: place and biome names are our own.
- Orb's rules: no dissolves or fades when a planet loads; plain words for the dial names (they are forward-facing text: Orb sees them before use); the terrain workshop of 2026-11-09 is after Alpha and is not part of this brief.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: A-WORLD-01 (the round planet is main's world, A1) and the A3 terrain rows on main; Orb's answer to decision 16 (a seed and three dials). A-WORLD-09 follows A-WORLD-02 inside the milestone. Waiting on this: UI's planet row and the mode smoke suite's custom-planet run (X-05), Netcode's handshake carrying the dials, and A5's required Windows-against-Linux comparison.
