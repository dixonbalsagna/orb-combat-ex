# The meteor's crater (World, 2026-11-01)

Encounter's call, through the EP: the meteor's landing digs the special size as a first value, not `launchSpecial` (that flag also turns off the brake and the chase). The size is data, so it can come down if the dig hitches. Park: `docs/world/pending/meteor-crater/`.

## What it is

`WorldCrater.dig(S, x, E, cause, "impact", dirx, vert, special, z, shape, meteor)`: a last argument, `meteor`, false by default (every existing call is unchanged; `meteor_crater_check` proves it). With it on:
- the energy is times `craters.json meteor.eMult` (9, the specials' multiplier), and the radius is held only by `meteor.rMax` (6,100), not by the ordinary 8 bh (600) or the special flag's cap;
- no repeat-blow merge (`_repeat`); everything else is the impact's dig: the store record at the planet point, the event, trees, the water and low-ground refresh.

At Encounter's landing (8,570 units a second, tier 4: E 158.7) that is a bowl **6,046 units in radius and 1,330 deep, with a rim 532 high** (80.6 bh, 17.7 bh, 7.1 bh). A tier-4 power-up's bowl is about 1,470; the ordinary cap 600. Lowering `meteor.rMax` lowers it (checked at 3,000). The numbers are in `data/biomes/craters.json`, read whether or not the material module is on, with the schema.

## What it does to the terrain's readability

- **Slope.** The wall is a smooth bowl (the same profile as every crater), steepest at 0.58 of the radius where it is 0.34, **19 degrees**. The floor is nearly flat: within 0.3 of the radius (3,600 units across) it is within 17% of the full depth. So on the screen it does not read as a crater but as the ground having sunk into a wide basin, with a ridge 7 bh high round its lip. What reads at the moment of impact is the event, the rim and the debris; afterwards it reads as a valley.
- **Share of the ring.** One bowl spans 12,100 units across, 7.9% of the planet's circumference; apron included, 15.8%. Three a match is 24% of the ring (or 47% with the aprons) if they do not overlap. The ground's height stops being a landmark over a quarter of the ring, and a basin below the sea fills (the dig calls the water job over the whole span).
- **Towns inside it.** A standing building's base follows the ground: a 2,700-high tower 500 units from the centre went from base 2,437 to 1,132 and stood on, alive and undamaged (hp 3,038 of 3,038). The bowl does not hurt a building; Encounter's pass-through (`brunt-through`) does along the path, and anything inside the bowl wants a blast of its own if it should fall.
- **Trees** within 1.05 radii fall (a felling per dig: 0 to 39 on the two planets tried).

## Timing (for Performance)

`sim/world/tools/meteor_crater_prof.gd` (profile, no verdict, in `world-checks.json`'s leave-out list):
```
godot --headless --path . --script res://sim/world/tools/meteor_crater_prof.gd -- --planet=7 --touch=1 [--rmax=3000] [--n=3]
```
It prints, per dig: the dig call in microseconds, the bowl, the trees felled, the events, and the tick times (mean, p50, p99, max) for the 120 ticks before, the 120 after, and the next 240.

First reading (shared PC at 64 to 100% load, so indicative; run it in a quiet window for numbers to quote):

| rMax (radius) | dig call, planet 7 and 12 |
| :-- | :-- |
| 1,500 | 1.4 to 2.8 ms |
| 3,000 | 4.5 to 7.4 ms |
| **6,100 (the first value)** | **12.9 to 17.1 ms** |

The cost goes with the columns the bowl spans (about 2.5 ms for each 1,000 units of radius): a one-tick spike, the live path writes no strip bowl. The ticks after are within the noise on planet 7. On planet 12 (half sea) two digs were followed by a 16 to 20 ms tick: probably the water job over 1,500 columns, not isolated. If it hitches, 3,000 (a quarter of the area, 5 ms) is the first step down.

`meteor_crater_check` (METEORCRATER) 0 failed: the data's values, the ordinary dig held at 600, the meteor's radius and depth, one record, the ground lower by the depth at the centre and unchanged at 2.2 radii, the match steps on, rMax lowers the bowl, meteor off equals the old dig.
