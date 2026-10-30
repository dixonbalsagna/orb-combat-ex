# Density: more buildings on a planet ring (World, W7, 2026-10-29)

Owner: World and Environment. Data: `data/biomes/density.json` (schema `tools/schemas/biomes-density.schema.json`). Code: `sim/world/density.gd` (`WorldDensity`), one call in `WorldPlanetWorld.settle`. Check: `sim/world/tools/density_check.gd`. Ruling: Game Design `rulings-2026-10-28.md` item 1 (a Half ring stands at least 60 structures, aiming for 80; denser settlements, not more sites; the kinds stay as today).

## What it does

A planet ring's places (the stored planet's cities and towns on the line) are laid by two archetypes, Bellgate for a city and the outskirts village for a town. On a gen 2 ring the archetype is made denser before it is laid:

| | gapMul | widthMul | rows |
| :--- | :--- | :--- | :--- |
| city | 0.4 | 0.8 | 1, 2, 3 |
| town | 0.3 | 0.6 | 1, 2, 3 |

- `gapMul` shortens the space between neighbours in a row (every district's `gap_bh`).
- `widthMul` narrows every district's and kind's `width_bh`, so a house is 60% as wide in a town and a tower 80% as wide in a city.
- `rows` are the lane rows a district builds in. The foreground row 0 stays empty (`settlements.json` `foreground: false`); a village that built rows 1 and 2 builds the back street, row 3, as well.

No site is added: the planet's places are the planet's (the stored function, shared with gen 1), so the route's site rules hold. No kind changes (c08). Landmarks are laid by the same rule, in the rows they name.

## What it does not touch

- It applies only when `WorldClimate.genNow()` is 2 or more. Gen 1, gen 1 planet rings and the hand-made world never reach it: they are laid as before, and `density_check` holds a gen 1 ring equal with the module on and off.
- `settlements.json` is untouched, so the replay header's data hash (`WorldSettle.dataHash`) does not move. The module has its own file and is not hashed into the header; a gen 2 replay's buildings follow the data in the build that plays it.
- A calm turn lays its new places through the same `settle`, so a turned ring is as dense as a first one.

## Numbers (QA's 40 gen 2 rings: planets 3, 7, 11, 13, 17, 19, 23, 25, 29, 31; touches 0 to 3; 2,400 columns)

See the report, `docs/world/cloud-reports/2026-10-28-biomes-w7.md`, for the table, the densest screen and QA's arm.

## Why these numbers

The archetypes already pack a downtown (gaps of 0.4 to 1.4 fighter heights), so a gap alone barely changes a city; the width does. A town's houses, 3 to 5 fighter heights wide with 2 to 6 between, gain most from both. Tried on the 40 rings (mean structures): 0.5 / 0.8 city and 0.4 / 0.75 town 68; 0.4 / 0.7 and 0.35 / 0.65 79; 0.3 / 0.6 both 89; 0.2 / 0.5 both 112. The shipped pair reads about 78 on QA's rings and keeps a tower 80% as wide, so the skyline's height rule (`aspect_max`) trims it little.

## Known limits

- A ring with few places stands few: the mean follows the planet's places, and 2 of QA's 40 rings have none (planet 11 touch 3 and planet 23 touch 1). Density cannot fill a ring that has no place; a ring picker's minimum (1 city, 2 towns on a Half ring) does.
- One of QA's rings (planet 29, touch 2) plays the hand-made world, not a planet ring: the planet function gives no slice for it, `WorldPlanetWorld.gen` returns false and the match falls back. It stands the hand-made world's 120 structures, which lifts the mean by about 1 whatever density does. Not a density matter; noted for QA.

## The replay header

`WorldDensity.enabled()` is the switch and `WorldDensity.dataHash()` the hash of the parsed data without the `_` notes, made once. A gen 2 replay's buildings follow `density.json`, so Simulation folds the hash in for a gen 2 setup (`WorldClimate.genFor(setup)`: the setup's `planetGen`, else climate.json's `gen`, never `genNow()`, which is a tool's choice or the last match's). `WorldPlanet.dataHash(gen)` takes that generation (0, the default, is the one in force, as every caller so far).
