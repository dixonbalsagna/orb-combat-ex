# The tile ground at five planet sizes: plan and cost (Rendering, A1)

For the EP, on Orb's five sizes (World's parks: tiny, small, medium, big, huge; medium is today's to the byte) and the stand-in's planet design (`docs/ep/proposals/planet-a1-design.md` §3.2, §3.7). Order: after the clipping parks (feet-ground, marks-baked).

## What's hard-coded to medium today

All of these are in `render/core/`:
- **`tile_field.gd`**:
  - `300` is World's lattice, in nodes to a face edge (`_field_node`, `WorldField.ensure` and `dirOf` calls);
  - `1200` is its sub-node lattice, 4 × 300;
  - `38400.0` is a face edge's arc at medium's radius, π/2 × 24,446 (the tile's reach in `ask_around`, `_start`, `_records_reach`, the near test).
- **The level ladder:** `LEVEL0` 3 tiles to a face edge and `LEVELS` 5 give node spacings of 512 down to 32 units at medium only. At huge (4 × the radius) the same ladder gives 2,048 down to 128, so there's no 32-unit ground near the camera. At tiny it gives 136 down to 8, finer than any data.
- **The tile key's bits:** level, then i and j at 7 bits each, which caps a level at 127 tiles to a face edge. Huge needs two more levels for the same near ground (3 × 2⁶ = 192), so the key must widen (i and j at 9 bits; 3 + 3 + 9 + 9 bits still fits an int).
- **`planet_view.gd:570-575`:** the strip's copies round the planet, from `PLANET_NC`. Read from the match.
- **`look.gd`:** far-city counts (`FAR_CITY`) for medium's places. They scale with World's place counts (the square root of the area).

## The work, in order

1. **Read the size from the match,** as the sim does: the radius, World's lattice size and the level count from it. Keep the near ground's spacing (32 units at the finest level) and the far ground's (about 512 at level 0) by choosing `LEVEL0` and `LEVELS` per size, and widen the key. Medium must come out byte-identical, which the tile, sweep and ground checks and the render gates show.
2. **Big and huge** should then draw correctly, since the tiles are rings round the camera. Check: the tile check and the feet check at each size, and a still of each against medium.
3. **Tiny and small are a look question.** A tower 4,875 units tall on a planet of radius 6,519 reads as a spike on a ball, and the horizon curves hard. That's Art's relief cap (World's plan) and Orb's look, from stills, before either is offered.
4. **The look gate per size:** a side-by-side for medium showing nothing changed, and a first still of each other size.

## Memory

The ground lattice is the risk (11 MB at medium, 46 MB at big, 182 MB at huge with three planets kept), and it's World's (`WorldField.of`). The design page's fix is one planet's lattice from big upward, or a face reserved only when first read. The tile ground's own memory doesn't grow with the size: 800 layers of 28 × 28 heights and ids, about 5 MB at every size. GroundField's per-column rows grow with the columns: about 0.5 MB at medium, 1.8 MB at huge.

## Cost (tokens, estimates)

| Step | Estimate |
|---|---|
| 1. The size read from the match, the ladder and the key | ~0.8M |
| 2. Gates and the feet check at five sizes | ~1.2M |
| 3 and 4. Stills and the look gate per size | ~1.5M |
| **Total** | **~3.5M** |

It needs World's size parks on main first (the sim side), and Art's relief cap for tiny.
