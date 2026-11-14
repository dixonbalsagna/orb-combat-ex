# The tile ground at five planet sizes: plan and cost (Rendering, A1 → GW1c)

For the EP, on Orb's five sizes: World's `docs/world/pending/planet-sizes/` and the stand-in's planet design (`docs/ep/proposals/planet-a1-design.md` §3.2, §3.7). A1's exit needs **small, medium and big drawn and measured**; tiny and huge may follow. Order: after the clipping parks (feet-ground, marks-baked), and on top of World's size park and Simulation's `setPlanet` grant (GW1c).

## The sizes

A column is 32 units, so the radius is columns × 32 / 2π and a face edge of World's cube is a quarter of the way round (columns × 8).

| Size | Columns | Radius | Face edge | World's lattice (128 units a node) | A1 |
|---|---:|---:|---:|---:|---|
| tiny | 1,280 | 6,519 | 10,240 | 80 | may follow |
| small | 2,560 | 13,038 | 20,480 | 160 | **drawn and measured** |
| medium | 4,800 | 24,446 | 38,400 | 300 | **today's, byte for byte** |
| big | 9,600 | 48,892 | 76,800 | 600 | **drawn and measured** |
| huge | 19,200 | 97,784 | 153,600 | 1,200 | may follow |

## What reads the size already, and what doesn't

Already per match (no work beyond a check at each size):
- the tile field's radius (`tile_field.gd:104`, `SimField.R`);
- the far land's `planet_r` (`far_land.gd:132`, the planet's own `R`);
- the planet's copies round the strip (`planet_view.gd:570-575`): they read `SimConst.PLANET_NC`, which becomes a per-match value with Simulation's `setPlanet`. They're computed per call, not cached.

Hard-coded to medium, all in `render/core/tile_field.gd`:
- `38400.0`, the face edge (lines 371, 447, 456, 624): becomes `PLANET_NC × COL / 4`;
- `300`, World's lattice size (lines 515, 522): becomes the field's own node count;
- **the level ladder:** `LEVEL0` 3 tiles to a face edge and `LEVELS` 5 give node spacings of 512 down to 32 units at medium only. The rule is to keep the finest spacing at 32 and the coarsest near 512, so the level count follows the size: tiny 3, small 4, medium 5, big 6, huge 7;
- **the tile key** (level, then i and j at 7 bits each) caps a level at 127 tiles to a face edge. Big's finest level has 96 and huge's 192, so i and j widen to 9 bits (3 + 9 + 9 bits, well inside an int). Medium's keys keep their values.

Elsewhere:
- `look.gd`'s far cities follow World's place list, whose counts Game Design ruled by the square root of the area. Check at each size; there's no constant to change if they're read from the list.
- `render/vfx/meteor.gd`'s radius is World's grant (`grant-rendering-meteor.patch`). That's VFX's path; the change is right.

## The work, in order

1. **Size from the match:** the face edge, the lattice size, the level count and the wider key, all from `PLANET_NC` and the field. Medium must come out byte-identical; the tile, sweep and ground checks, the render gates and the feet check show it.
2. **Small and big:** the tile check, the feet check and the render gates at each, through a test word that picks the size (World's setup key). A still of each against medium at the same seed and tick, through Tools' launcher.
3. **Measured:** Performance's frame readings at small, medium and big, in a quiet window. My part is the scratch export and the size words. The tile pool (800 layers today) may need about 300 more at big for the sixth level's ring, about 2 MB; that shows in the reading.
4. **Tiny and huge,** when Orb's answer comes:
   - Tiny is a look question first. A tower 4,875 units tall on a radius of 6,519 reads as a spike on a ball, and the horizon curves hard. That's Art's relief cap (World's plan) and Orb's look, from stills, before it's offered.
   - Huge needs the seventh level and World's lattice memory (below).
5. **The look gate per size:** a side-by-side for medium showing nothing changed, and a first still of each other size. These are new pictures, not changes to the shipped look, so the stills go to the EP with the size words.

## Memory

- **The ground lattice is the risk,** and it's World's (`WorldField.of`): 11 MB at medium, 46 MB at big, 182 MB at huge with three planets kept. The design page's fix is one planet's lattice from big upward, or a face reserved only when first read.
- **The tile ground's own memory** barely grows: about 5 MB at every size (800 layers of 28 × 28), plus about 2 MB of pool at big and 4 MB at huge.
- **GroundField's per-column rows** grow with the columns: about 0.5 MB at medium, 1 MB at big, 2 MB at huge.

## Cost (tokens, estimates)

| Step | Estimate |
|---|---|
| 1. Size from the match, the ladder and the key (medium byte-identical) | ~0.8M |
| 2. Small and big: checks, feet check, stills | ~0.8M |
| 3. Performance's readings: exports and words | ~0.2M |
| **A1's exit (small, medium, big)** | **~1.8M** |
| 4. Tiny and huge: checks, stills, the look question | ~0.9M |
| 5. Look gate pictures for all five | ~0.5M |
| **All five** | **~3.2M** |

It needs, on a scratch stack before step 1:
- World's `planet-sizes` park;
- Simulation's `setPlanet` grant (`grant-simulation-sizes.patch`);
- the size's setup key.

Tiny also needs Art's relief cap.
