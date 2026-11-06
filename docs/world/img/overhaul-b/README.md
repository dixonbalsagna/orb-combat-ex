# Planet 7, today against B on gen 3 (World, 2026-11-02)

Orb's question 4 (docs/world/planet-overhaul.md): see a new planet first. **Left or top is today (`land.json` `b.enabled` false, as shipped); right or bottom is B (the plates on).** Nothing in the game or the data was changed: B was switched on for these pictures only, in a scratch copy of the kept build's tree (a `?b=1` page word added to its scratch main.gd).

| Picture | What it shows |
| :--- | :--- |
| `globe-today-vs-b.png` | The globe from orbit, both centred on the same point (the touch-down of touch 1 today), sun from the upper left. Today: broad green plains, a few big grey massifs, a sea on the left. B: an ocean basin with a coast, a desert, ranges in the north, a lake chain. |
| `map-today-vs-b.png` | The whole planet flat (red cross = the touch-down each version's picker gives for touch 1). Sea is 35% of the planet today, 48% with B. |
| `ring-coast-today-over-b.png` | The fight's ring side-on, all 4,800 columns (squeezed to 2,400): ground height from -2,500 to 5,500 units, sea line, biome colours. Today at touch 14, B at touch 1: each version's nearest thing to a coast. |
| `ring-range-today-over-b.png` | The same for a range: today touch 36 (the highest, 5,700 units), B touch 4 (5,250, with ridges around it). Where the ground is under sea level but the water is shallow it shows as a thin blue band over brown. |
| `fight-coast-today-vs-b.png`, `fight-range-today-vs-b.png` | Two fight-level frames from the web build, 1280 x 720 each: touch 14 and touch 1 (coast), touch 36 and touch 4 (range). |

## Read this before judging them

- **The place is not the same.** B changes the planet's land and sea, so the touch-down picker (which redraws until it lands on land) puts touch N somewhere else. Touch 1 is a plain today and a cliff coast with B. I picked, from a scan of touches 0 to 39 in each version, the best coast and the best range each one offers. Only the globes and maps are the same view. Today has hardly any coast in its first 40 touches (13 and 14 are the only ones with sea within 1,600 units, 7% and 18%); B has seven over 20% sea (0, 1, 11, 16, 24, 27, 29).
- **The fight frames are one instant**, about 20 seconds into a live AI fight, so the fighters have moved from the touch-down (the B coast frame is on a hilltop, not at the water; today's coast frame is a flooded street). The ring pictures are the truth of the place; the frames are only the look of the ground and the buildings on it.
- **What B changes at fight level:** B has more relief: within 1,600 units of the start the ground spans over 1,500 units in 14 of the 40 touches (today: 1 of 40), so slopes are steeper and a ridge more often cuts the sky. The look of the ground, the sky, the buildings and the fighters is unchanged (the renderer is the same).
- Heights are the planet's own ground (`WorldTerrain.baseAt`) with the buildings' pads laid; the globe and map read the planet function (`WorldPlanet.surfAt`), which does not include the match's pads and craters.
- Cost, from section 8 of the overhaul plan: B is 1.5 times the cost of a node.

## How they were made

Scratch scripts, deleted after (not in the repo): a headless Godot script for the globe, map and ring images; a scan of touches 0 to 39 in each version; a web export of the kept build's tree (commit 3d99738, 92 parks) with `?b=1`, captured through `tools/machine/capture.mjs` (session `world`, one capture at a time, 25% CPU cap, below normal) with a scripted click on the flashing-effects notice's button; a second scratch Godot script for the side-by-sides.
