# The round planet as main's world: A-WORLD-01 and A-WORLD-14 (World, 2026-11-13)

Brief: `docs/ep/alpha/audit-2026-11-13/05-directives/A1/world-environment.md` (read to its end). Park: `docs/world/pending/a-world-01/`. Check: `sim/world/tools/world_default_check.gd` (`WORLDDEFAULT`). Data: `data/biomes/world.json`. **The park changes nothing with the shipped data** (mode `arena`): the hand-made arena plays as it always has, and parity passes unchanged. GW1a flips it, with the data switches below, in one window.

## The mechanism

`WorldDefault` (`sim/world/default.gd`) answers one question: *what world does a match play when its setup names none?*
- **mode** `arena` (shipped): the hand-made arena. `planet` (GW1a): the round planet.
- An explicit key always wins: a setup with `planet` plays that planet; a setup with `world: "arena"` plays the hand-made arena (what the tests that need it say: none need it today, because the data says arena; at GW1a the ones that only ever saw the arena add the key).
- **fixed** (Orb's build's planet: 7, touch 3, generation 3): a newcomer's first match, the tests and every headless match.
- **random** (Orb's decision 2, accepted): a quick match plays a planet drawn from **its own match seed** out of a pool of planet seeds that generate and play (`WorldDefault.draw`: `SimRng.keyed`, no stream, so the same seed is the same planet on every machine). The pool is the five planets QA has played (7, 12, 3, 13, 17), each landing at touch 1, 2 or 3: `world_default_check` generates and plays every one of the fifteen. A bigger pool is a data edit once each new seed has the same check.
- **Who draws.** The sim's hook (`SimCore.beginMatch`, one line) applies the *fixed* planet to a setup that names none, so a test or a replay never depends on a draw. The host's menu (`planet_part`, Rendering's `main.gd`) draws the quick match's planet itself, names it in the setup, and makes it ahead while the player decides; the seed it drew from is the match's seed, kept from the menu's first ask to Start (`_menu_seed`), so the planet that was made ahead is the planet that plays. The seed of the planet is in the setup, the replay and (`WorldDefault.describe(S)`: planet, generation, columns) whatever Tools' report and UI's HUD choose to print.

## What GW1a flips (World's half; the EP's order puts the round planet fourth, after the pad, the computer opponent and the match-ending rules)

Taken by diffing `data/` of main against the 9 November build Orb played (`homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/tree`, the kept build). Every `data/biomes` file that differs, and nothing else in `data/biomes` does:

| File and key | Main | Kept build | In `data-switches-gw1a.diff` |
| :--- | :--- | :--- | :--- |
| `climate.json` `gen` | 1 | 2 | yes |
| `water.json` `enabled`, `surface.enabled`, `floor.enabled` | false | true | yes (three lines) |
| `water.json` `flowWarm.cols` | 0 | 48 | yes |
| `contact.json` `settle.enabled` | false | true | yes |
| `field.json` `plans.everywhere` | false | true | yes (`warm.radius` 10000.0 against 10000 is the same number) |
| `rings.json` `turn.on` | 0 | 1 | yes |
| `world.json` `mode`, `random.enabled` (new) | arena, false | (the page word `?planet=7`) | yes |

Two of these need switches in files that are not mine, or they do nothing or refuse to load: `rings.json turn.on` needs `data/director/interrupts.json` `calmTurn.enabled` (without it the turn never happens: QA found it, 2026-10-31); `water.json floor.enabled` needs `interrupts.json` `water.enabled` and `surface.enabled` (`WorldFill.floorProblem`: a floor without both halves of the surfacing rule is a load error that turns the whole water module off). `data/combat/launch_biome.json` `biome.enabled` (the planner reads the ground) is the planet's too. The kept build also flips the pad, the computer opponent, the camera's `splitShare` and a score of director and combat switches: those are the other directors' rows of the same table, not World's, and I did not touch them.

Every other World switch reads the same on main and in the kept build: plates B (`land.json` `b.enabled`), erosion and rivers (`rivers.json` `enabled`), `craters.json` `enabled`, the fire, the collapse, the places' switches: **off in both, by choice, and each has its own written reason in its park**. The new switches this window adds (`globe.*`, `flood`, `sizes.json`) are off or medium in both.

## What I could not close in this window

- **The look gate (acceptance 5).** Nothing is meant to look different, but a menu match on main against the 9 November build at the same ticks is the EP's side-by-side at GW1a (`node tools/flash/side-by-side.mjs`): no Godot windows and no browser of my own.
- **The checks that only ever saw the arena.** Run on the flipped data: see the park README's table.
- **A-ENERGY-05** (the building-fall feed to the old meters): waits for Orb's decision 6 and is Simulation's lines; the feed in `sim/world/collateral.gd` is data-switchable once they say.
