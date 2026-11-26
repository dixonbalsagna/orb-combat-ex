# Park: five planet sizes (World, 2026-11-13; A1 brief item 2; Orb: "five different planet sizes")

**Landed in GW1c (2026-11-25, content 558270b2). The patches are removed from this folder (git history has them); this page stays as the record of the hold, and takes the un-hide list when small comes back.**

Design, numbers and what is not built: `docs/world/planet-sizes.md`. Runs: `docs/world/runs/planet-sizes/`. Check: `sim/world/tools/size_check.gd` (`SIZES`, in CI). **Stacks after `globe-step2` and `a-world-01`** (it was built on both: three of its files, `store.gd`, `sim/core/sim.gd` and the two shared lists, carry their lines); the three apply in that order and reproduce the scratch tree byte for byte (checked from a clean export of HEAD def3445a). Nothing is applied. The state's fingerprint changes only for a match that names a size other than medium; **medium is byte for byte today's** (parity passes unchanged at 4,800).

| File | What |
| :--- | :--- |
| `planet-sizes.diff` | World's: `sim/world/size.gd` (`WorldPlanetSize`) with its `.uid`, `data/biomes/sizes.json` and `tools/schemas/biomes-sizes.schema.json` (+ the `tools/schemas/map.json` entry), the place counts per size read in `planet.gd`, the planet memo's key, the slice memo's key, `WorldField.cells()` and the bake stride by size, the grid keys of the store and the water records, the planet disk cache's key, `size_check.gd` and `size_probe.gd` with their `.uid`s and the two lines in `tools/world-checks.json` (the probe under leaveOut) |
| `grant-simulation-sizes.patch` | Simulation's: `constants.gd` (`PLANET_NC` a static, `PLANET_NC_MEDIUM`, `setPlanet`), `state.gd` (`planetNC`), `sim.gd` (set at the top of the match, bound again every piece and every tick like the arena's length, the arena's default), `field.gd` (the match key's memo), `planet_load.gd` (the host's loader asks and makes the planet at the setup's size and puts the host's static back) |
| ~~`grant-rendering-meteor.patch`~~ | **Removed 2026-11-21 (EP): VFX's `planet-sizes-meteor` is the one that lands at GW1c** (it fixes the same `const` radius in `render/vfx/meteor.gd`, and only one of the two can go in). Without one of them the project does not compile once `PLANET_NC` is a variable |

## The hold (2026-11-23; the EP's GW1c decision: medium alone, the others held, not cut; big joined the held on the same day, it fails the flash check in the default look until Camera's split-merge fix)

`data/biomes/sizes.json` has **tiny, small, big and huge `offered: false`** (colossal was already). **Only medium is offered.** `offered` now means **reachable**: the menu lists the offered ones (UI reads the file) **and `WorldPlanetSize.nameOf` plays only an offered size**: a setup that names a held size (a replay, a setup constant, a probe, a hand-edited file) plays **medium, with a push_error**, and `WorldPlanetSize.heldHits` counts it. Un-hiding a size is the one data line `"offered": true`: the code and the data of all five sizes land now, the flag is what is held.
- **`WorldPlanetSize.heldOverride`** (static, tests and probes only; the game never sets it): a size the data has but does not offer plays as named. `size_check` proves no file outside a `tools` or `tests` folder (and size.gd) names it.
- **`WorldPlanetSize.isHeld(setup)`**: true when a setup names a size the data has and does not offer (data only, no error). What a replay's or a handshake's refusal line would call.
- **`WorldPlanetSize.hashData()`**: the table without `offered`. Simulation's replay-sizes (`replay.gd` hashes the whole table for a setup that names a size, and the menu names one on every planet match) must take this, not `data()`, or un-hiding a size changes the replay data hash of every match that names one (**NEEDS FROM EP**, below).
- **The rows** (`SIZES`, 0 failed. **The record on the tree that landed is the EP's gate: `size_check` inside `world-checks --run` on s438, 2026-11-25, all 96 passed.** My records in `docs/world/runs/planet-sizes-hold/` are earlier readings; those of 13:29 and 14:12 are superseded: big was still offered): as shipped only medium is offered and the other five (tiny, small, big, huge, colossal) play medium with an error each time (10 asks, 10 counted); a match naming small is the medium match byte for byte; the replay row (below); nothing draws a size (the quick match's draw, 2,000 seeds, never names one); nothing outside tools and tests sets the override; flipping tiny, small, big and huge in memory makes small play at 2,560 columns and big at 9,600 and moves no hash (a medium match at tick 120, `hashData`, the replay data hash of a setup naming medium and of a setup naming none) with a control that the raw table does change. **Negative control** (the hold taken out of `nameOf`): 3 FAIL.
- **A replay that names a held size.** Recorded with the way in open (small, 120 ticks, a checkpoint at 60 and a final hash), checked as shipped: the error is raised and `SimReplay.play` fails it, **reason `checkpoint` at tick 60 on the stack as it is, and `data` before its first tick with Simulation's `replay-sizes`** (its header is made and checked at the size the setup plays, medium). `SimReplay.refusal` (the header alone) says `data` in both trees. **The gap on the stack as it is:** an unfinished replay (no checkpoint, no final hash: under a second) made at small plays back **ok at medium, with only the error to say so** (`replay-sizes` closes it: `data`). A replay made *while small is held* records the match that ran, medium, and plays back ok: it is faithful. Nothing was widened for it: the later item for UI and Simulation is a refusal at the header, `WorldPlanetSize.isHeld(rp.setup)`.
- **Every other piece of the stack was re-cut for the flag, and applies strictly in the same order:** `gw1c-world.diff` (it rewrites the size rows and the `_about`, so its `-` and `+` lines carry `false`, and the schema's description line is its context), `relief-cap-data.diff` (the tiny and small rows), `relief-cap.diff` (`relief_cap_check` sets the override: it names tiny and small).
- **Could it move a picture?** No. Medium alone is offered, so what a player can reach is the medium planet of GW1b's list; the held sizes cannot be reached, so nothing is drawn for them. Medium named plays byte for byte the medium unnamed (row and parity). Rendering's medium reading applies as it stands.

## The five

**Tiny 1,280, small 2,560, medium 4,800, big 9,600, huge 19,200 columns round** (a column is 32 units: 41 thousand to 614 thousand units; radius 6.5 to 98 thousand; a lap flat out at Orb's 3,500 a second 12 s to 176 s). Colossal (38,400) stays a row of data with `offered: false`, unproven. I propose these because the plan's colossal needs three pieces that are not built (windowed places, a ring that is not a great circle, a coarser bake), and the field world cannot hold a ring shorter than the planet (the frame maps the line to a closed great circle): so the arena is the planet's whole round at every size, and huge's per-column state is 4 times medium's (672 KB). Selectable from data: the menu offers `WorldPlanetSize.names(true)`; a setup names one as `planetSize`; a different five is an edit of `sizes.json`.

## Against the brief

| | Result |
| :--- | :--- |
| Each size generates | `SIZES`: planet 7, touch 1, all five on a field world with a frame, fighters on finite ground, 600 ticks played, the same setup twice gives the same match hash (tiny and big), a size the data does not have plays medium |
| Medium unchanged | `SIZES`: medium named plays byte for byte the match medium unnamed plays (hash at tick 120). **parity passes with the golden as it is on main** (9 matches, 174,798 ticks identical; planet worlds identical), on the tree with this park, a-world-01 and globe-step2 |
| The host's strict loader | `SIZES` makes a big planet through `SimPlanetLoad` (not made, not ready, load, ready, a strict match starts with `planetNC` 9600), and every call leaves the host's own static as it found it |
| Negative control | the store's grid offset kept at medium's 64 on the huge planet: 1 FAIL (two boxes of the huge planet that share a key) |
| Frame cost per size | not measured: the machine was shared (Performance reads it in a quiet window). By count, tick cost does not grow with the size (0.3 to 1.2 ms at every size on a loaded machine; medium 0.7 at the same load). Start times, cold, one machine, loaded: tiny 1.9 s, small 0.9, big 3.4 to 7.6, huge 7.9 to 9.7 (planet make for big 3.3 s, 112 places): void as measurements |
| World checks (88 with these, shipped data) | all 88 pass, on the stack of globe-step2, a-world-01 and this park (`checks-verdicts-all-88.txt`); validate 0 errors (323 files) |

## Decisions I made (reverse any)

1. **Five: tiny, small, medium, big, huge** (above). Tiny and small are 1,280 and 2,560, not the plan's 1,200 and 2,400: a face edge is `cols / 16` nodes of 128 units and the 512-unit bake needs that to be a multiple of 4, so a size is a multiple of 64 columns (the loader says so).
2. **Place counts per size are by about the square root of the area**, not the area (`sizes.json` `places`): tiny 2 cities and 4 towns, small 4 and 12, medium 12 and 44, big 24 and 88, huge 48 and 176, with the ring's minimums lowered on tiny and small. A planet function has absolute feature sizes, so a tiny planet cannot hold twelve cities of 6,500 units radius; the plan's by-area counts (a quarter of a million buildings at colossal) are the windowed-places work I did not build. It is Game Design's call (the plan's 4.3), and a data edit.
3. **The arena is the planet's whole great circle at every size.** The plan wanted a ring cap on big and huge; the field world cannot have one. Netcode prices the snapshot (672 KB a column set at huge).
4. **A size is a distance.** Nothing else moves: a column is 32 units, speeds, launches and bodies are absolute, so a lap goes with the loop. Per-size tuning of launches and the swing's read budget is Game Design's (the plan's step 6).

## NEEDS FROM EP

- **Simulation (2026-11-23, the hold):** `replay-sizes.patch` (`docs/architecture/pending/replay-sizes/`), `sim/core/replay.gd`: `FighterData._canon(h, WorldPlanetSize.data())` becomes `FighterData._canon(h, WorldPlanetSize.hashData())` (one word). Its parity row names `"planetSize": "tiny"` and needs `WorldPlanetSize.heldOverride = true` before it and `= false` after (tiny is held). The patch's `parity.gd` hunk no longer applies on HEAD (line 111); `replay.gd` does.
- **Director:** `docs/director/pending/arc-by-size/arc-by-size.diff` line 137 names `"planetSize": size`: set `WorldPlanetSize.heldOverride = true` before the first `newMatch` of the probe.
- **Rendering:** `docs/rendering/pending/planet-sizes/feet_check_size.gd` line 91 (`main.start_match(..., {"planetSize": SIZE})`): set the override first when `SIZE` is held.
- **Camera:** `render/tools/open_probe.gd` (`docs/camera/runs/d55c612f/opening-clear/open_probe.gd.txt` line 50, `ws["planetSize"] = SIZE`): the same one line.
- **UI:** nothing: the menu reads `offered`. With one offered size the menu's size row (`world-menu.patch`) still shows, as a cycle row of one choice ("Planet size: Medium") that steps to itself: it reads as a control that does nothing. UI's `ui_menu.gd` lines that append `psize` (and the summary line) test `UiModes.sizes().is_empty()`; testing `.size() < 2` hides it until a second size is offered (one token in each place).

- **Simulation:** `grant-simulation-sizes.patch` (five files). Before colossal is ever offered: `SimField._boxKey`'s offset (a radius past 131,000 units aliases), the same fix the store got.
- **Rendering:** the look of every size (the meteor file is VFX's `planet-sizes-meteor`). `render/core/tile_field.gd` hard-codes the medium planet (the face edge 38,400 and 300 cells at lines 371, 447, 456, 508 to 522, 624), `planet_view.gd` 570 to 575 (the copies of the planet), `look.gd` far-city counts. The sim plays big and huge; no picture of them has been made.
- **UI:** a size row in the menu (`WorldPlanetSize.names(true)`, the setup key `planetSize`); with a random quick match the size is the data's or the menu's.
- **Netcode:** the handshake's setup comparison names the size (it is in the setup), and the snapshot at huge.
- **Art and Game Design:** tiny's relief against its radius (a 4,875 tower on a 6,519 radius) and the per-size tuning.
- **Performance:** the frame, load and snapshot readings per size, in a quiet window.

## RISKS

- Start time at big and huge is 4 to 10 s cold on a loaded machine (the planet's make is most of it): a loading screen, not a hitch. The disk cache has per-size keys (medium's are unchanged).
- The picture is untested at every size but medium (above).
- Only planet 7 (touch 1) was played at every size, and planet 12 touch 2 at big through the loader: each size's own pool of planets that generate and play is a later check, like the quick match's pool.
- A planet at a size is a different planet from the same seed at medium (the function is absolute, so a tiny 7 is a small piece of the medium 7's land).

## NEXT

After the gate: Rendering's tile work, UI's row, Performance's readings. Then the world's ranges, rivers and coasts (the planet's engineering, planet-overhaul section 5) can be built on a size knob that exists.

**2026-11-21:** World's meteor grant is taken out of the GW1c list (VFX's lands instead). The stage runs of `docs/world/planet-stack-recut.md` used World's only to make the scratch tree compile.

**2026-11-23 (the GW1c gate red, `validate.js --self-test`: "coverage: biomes-sizes.schema.json: at least three invalid cases, has 0"):** `grant-tools-sizes-cases.patch` (Tools' file, `tools/fixtures/cases.json`): five invalid cases for `biomes-sizes.schema.json` (`sizes-unknown-top-key`, `sizes-offered-not-boolean`, `sizes-missing-offered`, `sizes-building-share-zero`, `sizes-spawn-reach-negative`), appended after the `/random/enabled` case, in the file's own shape. Applies after UI's `schema-feedback-world.patch` (checked both with it and on bare HEAD). On the full GW1c stack (`docs/ep/reviews/GW1c-stack.txt`, 22 pieces, strict) plus UI's grant: before, self-test 10170 of 10171 (that one coverage row); after, **10177 of 10177**, `validate` 325 files 0 errors. Negative control (the `minimum` of `spawnReach` removed): the matching case fails. **Tools already parks six cases for the same schema (`docs/tools/pending/world-schema-cases/`, ids `biomes-sizes-*`): land one of the two, not both** (they append at the same line; Tools' hunk fails after this one). The `sizes-*` ids differ from Tools', so nothing collides by name.

## Small and big coming back (parked 2026-11-26, the EP's order; NOT applied to main)

**`unhide-small-big.diff`**: `data/biomes/sizes.json` `offered: true` for **small and big** (and its `_about` sentence), with `size_check`'s rows for that state. **Tiny, huge and colossal stay held.** Cut on HEAD; two files.

**It lands with `grant-ui-unhide-sizes.patch`** (UI's `ui/tools/hud_check.gd`, three lines): with the flip alone, UI's HUD check fails 2 rows. One read the shipped file as the list with no sizes; the other did not know that Left and Right on the size row change `planet_size`. Both are test gaps the one-size build hid. The grant passes with the flip and without it, so it can land first.

**It lands only when Camera's and Rendering's readings on the combined tree pass** (Rendering's sky-handover takes small to a pass; Camera's door-holds does the same for big).

**Run on the flipped tree** (records `docs/world/runs/unhide-small-big/`): all 96 World checks, the golden check (unmoved), `validate` and its self-test, and the HUD check with the grant. **What the check proves with it** (`SIZES`): small, medium and big are offered; tiny, huge and colossal play medium with an error; a match naming tiny is the medium match byte for byte; the replay rows (now at tiny); **small and big coming back moved no hash on the landed code** (with them held again, as GW1c shipped, a medium match's state at tick 120, `hashData` and the replay data hash of a setup naming medium or naming none are the same), with a control that the raw tables differ; every offered size's spawn is within reach of a place.

**What a player sees change:** the setup page gains a "Planet size" row with three choices (the HUD hides it only while one size is offered). Medium's play and the golden do not move.

### Before the flip, or with it (the un-hide list of `docs/ep/reviews/GW1c-medium-prelanding.md`, read against the landed code)

| # | What | Whose | Bites the small-and-big flip? |
| :--- | :--- | :--- | :--- |
| 1 | **The planet made ahead ignores the size.** `SimHost.planet_key` (`render/core/sim_host.gd`) is planet, generation, touch-down and arena, with no size. The menu prefetches for the choice; picking another size leaves the key the same, so Start can take up the job made for the size picked before. "New match" from the pause menu (`render/core/main.gd`, `new_match_requested`) also names no size and plays medium. Read from the code; not run | Rendering / Simulation | **Yes. Do this first**: it is the one a player can walk into from the menu |
| 2 | **Relief-cap rows: stamp only the played size.** A replay's header and the online match key take the whole size table (`hashData`, `sim/core/replay.gd`), so any edit to one size's numbers (`relief-cap-data.diff`: small's and tiny's height caps) changes the stamp of every match that names a size, medium from the menu included. Hash the played size's row only, with a check row that edits another size's row and shows the stamp still | Simulation | The flip itself moves no stamp. **Small's height cap does**, so this goes before the cap rows. Decide with Camera and Rendering whether their small reading wants the cap: it is not in this diff |
| 3 | **Nothing calls `WorldPlanetSize.isHeld`.** A saved match naming a held size plays medium and fails later, or passes if it has no checkpoints | UI and Simulation | Not for small and big (they stop being held). Still needed before a saved-match loader or an online lobby reaches players |
| 4 | **The override scan** (`size_check`) trusts any path with `tests` or `tools` in it, and the exports do not leave `render/camera/tests/` out. Nothing there sets `heldOverride` today | World (the scan), Tools (the export filters) | No: a guard to tighten |
| 5 | **Huge and colossal cannot be drawn.** `render/core/tile_field.gd` keeps 800 picture layers and never frees the coarsest; huge needs 864, colossal 3,456 (medium 54, big 216) | Rendering | No: they stay held. Before either is offered |
| 6 | The menu's own reading of `sizes.json` is tested only through stand-in lists, never against the shipped file (`ui/tools/hud_check.gd`) | UI | **Yes, in part**: the flip turns two rows red (the grant above fixes them). A row against the shipped file is still worth having |
| 7 | The camera fixes for small and for big | Camera, Rendering | The gate on this diff |

Words to change when it lands (not in the diff, not World's): `docs/ui/menus-a1.md` (it says medium alone) and the status rows that say big and small are held.

**`relief-cap-gw1c/relief-cap-data.diff` does not apply on top of this flip** (its context is small's held row). It needs a re-cut when its turn comes, after item 2.
