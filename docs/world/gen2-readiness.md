# What it takes to switch gen 2, water v2, B and rivers on by default (World, 2026-10-26)

A readiness list, not a plan to flip: nothing is flipped. State at main d51c6757: every switch below is off. What I measured myself is marked; what I only know from the docs or have not checked is marked "to confirm".

## The switches and what each changes

| Switch (data) | Now | On means | Moves the golden? |
| :--- | :--- | :--- | :--- |
| `climate.json` `gen` | 1 | every planet match (a setup with `planet`) is made by gen 2: climate, fine biomes (15), ground profiles, trees, sites, lakes, the calm turn's gen 2 steps. The hand-made prototype world (no `planet`) is not affected | **Yes**: the golden's planet recipes (`PLANET_TICK0`, `PLANET_MATCH`, `golden_recipes.gd`) and every recorded planet replay change; EP regenerates |
| `land.json` `b.enabled` | false | a gen 2 planet's ground is Research's B plates (taller, richer ranges, rifts, islands); climate.json's `b` block moves the mountain and highland lines; B's volcanic score makes the volcanic fields | No (gen 2 only) |
| `water.json` `enabled` | false | water v2: holes fill from the sea, lakes and the water table; the pebble skip stays on flooded scars; wading; the crater wave; the douse; cues `water_fill`, `water_wave`, `water_douse` | No (a match that never digs near water is unchanged; one that does is a different match) |
| `water.json` `surface.enabled` | false | a launched body in water surfaces set within 30 ticks | Only matches that launch into water |
| `rivers.json` `enabled` | false | gen 2 rings get narrow shallow rivers where they cross a drainage line; the flow field is a step of the planet job | No (gen 2 only) |

Flipping any of them changes the data hash a replay carries, so older replays do not load into the new data: say so before the flip.

## Gates, in the order I would take them

1. **Gen 2 alone.** Already proved on the parked stack: all World tools, `run-all` 5 of 5, a 12-match soak (reproducible, with turns). Still to do: the EP's golden regeneration; QA's gen 2 baseline (below); Performance's bench (below); Orb's look (below).
2. **B.** Needs Orb's choice of look (the stills, `docs/world/stills/gen2-b-vs-w3-maps.png`; homework "plate mountains and rivers"). Cost: +36% per sample (51 against 38 µs, measured), no new hitch.
3. **Water v2 (and surfacing).** Needs Orb's three answers (homework 47). The cues are drawn (Rendering's `water_*` handling is on main); VFX's foam and steam: to confirm. Surfacing needs Encounter to confirm nothing else reacts to the old sink end (the `sink` event is the same, now at the surface).
4. **Rivers.** After B (a river's valleys follow the ground it was routed on) and after gen 2. Needs Orb's yes (cosmetic; homework "plate mountains and rivers"). The far land's ribbon is Rendering's, optional.

## What flipping gen 2 needs from each owner

- **EP / Simulation:** the golden regeneration; a decision on the lobby default (which planet gen a new run or the demo uses, `setup.planetGen` per setup or the data's); the cold make: `SimRun.beginGround` makes a planet in steps (landed), but a match start with a cold gen 2 planet (`newMatch`) is one synchronous call of about 1.1 s on this PC (measured), so a menu or load screen must make the planet first (`WorldPlanet.makeJob`).
- **Performance:** a bench of gen 2 on the three tiers: the planet make (1.1 s native; about ten times that on a phone by the audit's factor: to confirm by measuring), a match start, the first warm tick of a calm turn (about 300 ms against 110 ms for gen 1: measured, a pick hitch that predates the rivers), the turn's preparation ticks (the dearest after the first, 1.9 ms: measured), the water step with fills open (220 to 540 µs with four open, 0.2 to 0.4 µs idle: measured), the flow field (100 ms once a planet: measured), and memory (the climate grid, flow arrays and the far map's layers). Budgets: `docs/perf/budgets.md` rows for the planet slice and the frame.
- **QA** (new rows, none measured yet on gen 2 with the new switches): the AI-vs-AI bands on gen 2 planet matches (match length, collateral share, structures lost, craters, win rate: the bands were set on gen 1 and the prototype world); the landing-class mix on gen 2 grounds (the water class band 5 to 15% was 3% on gen 1, and surfacing and rivers change it); calm turns on gen 2 (cost per tick, no pop at the seam); water v2 on (fills open per match, the skip count, the wade rule never slows a fighter); rivers on (a river in a quarter of rings: 6 of 12 test rings had one; no fighter slowed by one).
- **Rendering and Art:** the fine biomes read as the stored biome they alias until the renderer learns them (the 15 ids and their palettes are on main: to confirm the renderer uses them); trees are still drawn as cones; fine-biome plumes (VFX reads `S.fineCols`: to confirm landed); rivers draw as lakes from `S.water` (no new art).
- **Audio:** biome sounds by fine biome (on main with Audio's biomes-fine: to confirm).
- **Game Design:** rulings for the open items: how a river along the ring counts (done: row 13), the skate hand-over (ruling 12, behind `skate.json`, off), the surfacing for a drop (not built).

## Orb's homework answers this waits on

`homework/planet-world-water/`: **47 water that fills holes** (switch it on now or after the clips; a desert hole by the sea; the crater wave's size), **plate mountains and rivers** (the look; rivers wanted in the first flip), **new planets and Everhold**, **planet names and homes**; and `LATER` items (drift speed and far land, biome sounds). None of the switches needs more than a yes, except the look choices.

## Not built, and would show

Trees only die (no burning: the `burn` field exists in the tree state and nothing sets it: see window 18), no ash beside vents, a drop into water has no surfacing rule, rivers have no ribbon on the far land yet in the renderer, the lobby has no planet pick.

## Suggested order and the one-line exit for each

Gen 2 (golden regenerated, bench inside budget, QA's gen 2 baseline in band) then B (Orb picks the look) then water v2 with surfacing (Orb's answers, VFX's cues seen) then rivers (Orb's yes). Each is one data line; none is flipped here.
