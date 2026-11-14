# Park: A-WORLD-01 and A-WORLD-14, the round planet as main's world, prepared for GW1a (World, 2026-11-14; A1 brief item 1)

Design and the switch table: `docs/world/world-default.md`. Runs: `docs/world/runs/a-world-01/`. Check: `sim/world/tools/world_default_check.gd` (`WORLDDEFAULT`, in CI). **Stacks after `globe-step2`** (it was built on it; the shared lists carry no line of it, the data flips touch water.json beside its flood block). **With the shipped data this changes nothing**: the mode is `arena`, a setup with no planet key plays the hand-made arena as it always has, and parity passes unchanged. GW1a lands the data flips in the order the EP set (the round planet fourth).

| File | What |
| :--- | :--- |
| `a-world-01.diff` | World's: `sim/world/default.gd` (`WorldDefault`) with its `.uid`, `data/biomes/world.json` (mode, the fixed planet, the quick match's draw) and `tools/schemas/biomes-world.schema.json` (+ the `map.json` entry), `world_default_check.gd` with its `.uid` and its line in `tools/world-checks.json` |
| `grant-simulation-sim.patch` | Simulation's `sim/core/sim.gd`, `beginMatch`: one line, `setup = WorldDefault.apply(setup, seed, true)` (a setup that names no planet gets the data's world; headless matches and tests take the fixed planet, never a draw) |
| `grant-rendering-main.patch` | Rendering's `render/core/main.gd`: `planet_part` returns the default for a menu that names no planet, drawing the quick match's planet from its own match seed (`_menu_seed`, kept from the menu's first ask to Start, so the planet made ahead is the planet that plays); the first match of a session plays the fixed planet (`_played_one`; UI persists it across sessions) |
| `data-switches-gw1a.diff` | **GW1a, World's rows**, off the shelf: `climate.json gen` 2, `water.json` (enabled, surface, floor on; `flowWarm.cols` 48), `contact.json settle.enabled`, `field.json plans.everywhere`, `rings.json turn.on`, and `world.json` mode `planet` with the draw on. Read off the 9 November build's packed data (see the table in `world-default.md`) |
| `data-switches-gw1a-others.patch` | **Not World's, for the EP to route**: `interrupts.json` `calmTurn.enabled` and `water.enabled` and `launch_biome.json` `biome.enabled`. Without the first the calm turn never happens; without the second a floor with no surfacing rule is a load error that turns the whole water module off (`WorldFill.floorProblem`) |

## Against the brief's acceptance

| # | Result |
| :--- | :--- |
| 1. Every world switch row reads as in the kept build, or has a line | The kept build's `data/biomes` differs from main in exactly five files (climate, contact, field, rings, water), and `data-switches-gw1a.diff` is those lines; every other World switch (plates B, rivers, craters by material, fire, collapse) is off in both, each with its reason in its park. Table in `world-default.md`. The EP's row count against the inventory is theirs |
| 2. A menu match with no key plays the round planet; a check reads back a generated planet; the arena stays reachable | `WORLDDEFAULT`: with the mode on `planet` a match with no planet key plays a generated planet (planet 7, generation 3, a frame) and with `world: "arena"` plays the hand-made arena; with the data as shipped it plays the arena. Passes on the shipped data and on the flipped data. Negative control: the draw made to ignore the match's seed fails the spread check (1 FAIL) |
| 3. Same seed, same planet; the run list on the new defaults, a verdict for each, arena-only checks listed | The same seed plays the same match twice (hash at tick 60). **The run list on the GW1a data** (`runs/a-world-01/flipped-data-checks.md`): 87 checks, **44 pass unchanged, 41 fail, 2 gave no verdict** (`wrecks_check` and `depthreads_check` were still running after an hour on a loaded machine and were stopped: they need a quiet window). Every failure names what the flip changed; nearly all are the shipped value pinned ("ships off", "the default generation is 1") or a hash recorded on the hand-made arena. None found a fault in the sim. They need re-pinning in GW1a: a World job of about 1M tokens, with the golden |
| 4. Decision 2 | Followed: a quick match draws from its seed (`random.enabled`, pool 7, 12, 3, 13, 17 at touches 1 to 3, each of the fifteen generates and plays: `WORLDDEFAULT`); the first match and the tests play the fixed planet 7 (touch 3, generation 3). The seed is in the setup and the replay, and `WorldDefault.describe(S)` gives the planet, generation and columns for the HUD and the report (UI's and Tools' lines) |
| 5. Look gate | Not run (no windows, no browser of mine): the EP's side-by-side against the 9 November build at GW1a. Nothing is meant to look different |
| 6. Supports | A-ENERGY-05 waits for decision 6 and is Simulation's; A-CODE-03: the planet entry on main is now `planet_part` with this grant, so the preview patch's `?planet=N` entry is not needed for a default match (Tools' to remove); A-PROCESS-03: `docs/world/uncommitted-2026-11-13.md` |
| Gates, shipped data | all 88 World checks pass (the stack of globe-step2, this park and planet-sizes, one Godot at a time; `checks-verdicts-all-88.txt`) · parity passes unchanged (9 matches, 174,798 ticks identical) · validate 0 errors (322 files) |

## Decisions I made (reverse any)

1. **The quick match's pool is the five planets QA has played** (7, 12, 3, 13, 17), at touches 1 to 3. A bigger pool is a data edit once each new seed has the same check (generates and plays 90 ticks at every touch).
2. **The sim never draws.** The sim hook applies the fixed planet; only the host's menu draws and names the planet. A test or a replay never depends on a draw, and the planet made ahead while the player decides is the one that plays.
3. **`world: "arena"` is the key for the hand-made arena** (the brief's "explicit key"). No check needs it today: at GW1a the ones that only ever saw the arena add it.
4. **The mode ships `arena`** and flips with the data switches in one window; there is no state in between.

## NEEDS FROM EP

- **Simulation:** `grant-simulation-sim.patch` (one line).
- **Rendering / UI:** `grant-rendering-main.patch`; UI persists the "first match" flag across sessions and prints the planet's seed in the HUD and the report (`WorldDefault.describe`). The host's planet entry (A-CODE-03) is Tools'.
- **EP, at GW1a:** route `data-switches-gw1a-others.patch` to its owners (Encounter, the director's file; Combat's planner file), and the golden's re-record. World re-pins the 41 checks in the same window (a `checks-gw1a` park).
- **A quiet window** for `wrecks_check` and `depthreads_check` on the flipped data.

## RISKS

- 41 checks fail on the flipped data until re-pinned; the sim underneath passed them (the failures are pins and arena hashes).
- Nothing was played on screen on the flipped data by me: Orb's build is the proof of the switches; the picture of a quick match's drawn planets (7, 12, 3, 13, 17) at touches 1 to 3 is Rendering's look gate.
- `?planet=7` shortcuts still work (an explicit planet wins).

## NEXT

GW1a. Then the 41 re-pins, and the planet sizes (the next park) behind the default's menu row.
