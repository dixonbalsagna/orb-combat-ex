# Research's B plates in gen 2 (World, window 12, 2026-10-23)

For the EP's item: "Research's B plates as a window behind a land.json switch ... port round 2, tune by eye against compare-s*.png". Source: `research/planet-gen/gen/plates.mjs` (round 2, about 3.4x the octaves and 4.3x the time of today's ground, not 6.7x), described in `docs/research/planet-gen.md` section 2.

## What it is, in plain words

A planet gets 14 plates (and 30 Voronoi cells, the 16 extra joining their nearest plate so outlines bend), each with a drift, some continental and some oceanic. Where two plates close, the ground rises in a range (continent on continent), or a trench opens beside an arc of volcanic islands (an ocean plate going under). Where they part, a mid-ocean ridge, or on land a rift valley in offset segments. Hotspots leave island chains. The coasts come from a low-frequency crust noise levelled to 60% land, so they wander inside plates instead of tracing plate edges. The result is the richer map in Research's compare images: dense belts of mountains along real boundaries, offset rifts, fjord-like coasts, and islands where they would form.

## The switch

`data/biomes/land.json` `b.enabled` (shipped false). Off, `WorldPlanet.ground` takes exactly the path it took and nothing in `plateb.gd` runs: gen 1 and gen 2 as parked are bit for bit. On, a gen 2 planet's `ground()` is `WorldPlateB.ground(P, x, y, z)` and nothing of window 3's landforms is applied (its plates, ranges, rifts, shoreline, plateaus and canyons; B has its own coast noise, rift segments and old worn ranges). The stored planet's polar zone (north pack sea, south ice sheet, with window 3's ragged edge) still applies past its edge; B's own fades bring its landforms down before it. `WorldLand.dataHash()` carries `plates-b.json` only while the switch is on, so the planet memo and the ring-slice memo key on it.

The numbers are Research's `PB`, one for one, in `data/biomes/plates-b.json` (generated from `plates.mjs` by the maker in the park folder, so they cannot drift); a key the file lacks keeps Research's default. Schema `tools/schemas/biomes-plates-b.schema.json` (Tools', granted), a map rule and three invalid cases.

## Fidelity

`sim/world/tools/b_check.gd` compares against `b_vectors.json`, made by `b_vectors.mjs` from Research's own file: the plates' cells, crust lift, first centre and first hotspot are equal; 720 ground reads (3 seeds, 240 points each, between y -0.4 and 0.3) differ by at most 4.5e-13 in height and 3e-17 in the volcanic score, 89% to the last bit. Two deliberate differences from the JS: the polar fades read plain y (the JS reads the poles' own warped y, tied to `poles.mjs`'s sinking north and lifted south, which gen 2's stored polar logic replaces), and there is no coarse read (the climate march of the JS is the climate grid here, built from the full ground). The check also proves: gen 1 ground is unchanged with the switch on, a fresh planet object reads the same, no step over 900 units between neighbouring columns on 18 rings (the largest was 484).

## Cost

A sample (`surfAt` plus the biome, as `planet_map.gd` times it) on this busy machine: gen 1 13 us, window 3's gen 2 38 us, gen 2 with B 51 us. A bare ground read is 54 to 63 us. So B adds about a third to a gen 2 sample (not 4.3x: gen 2's climate, trees and sites are already most of it). Planet set-up: the plates are made once per planet (2,000 crust reads, a few ms).

## By eye, against `compare-s*.png`

Seeds 7, 11 and 42 (the map tool's `--b`, stills in the scratch folder): the continents, seas, island chains, offset rifts and mountain belts are Research's B column's, place for place. Differences you will see: the poles (ours are the stored pack sea and ice sheet, Research's the sunk north and lifted south), and the biomes: gen 2's climate was tuned on window 3's ground and reads drier on B (more savanna and desert, fewer forest greens than Research's own climate gives its B). That is `climate.json`'s to retune once B is the choice; nothing in B itself needs it.

## Not in this window

- The volcanic fields (`State.volc`, 0 to 1 per point, a side output of each ground read) are not yet a biome: gen 2's volcanic fine biome still comes from the climate's own noise. Wiring it is one call in `WorldClimate.plain` (read `WorldPlateB` volc at the same point) and a decision on how it replaces the noise.
- Research's round-2 C (erosion, rivers) is not touched.
- The turn's calm swap and the lakes read the ground as before; the 12-match soak with B on (turns included) is clean and reproducible.
