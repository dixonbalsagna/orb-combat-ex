# The rubble on the tile ground is small stones, not big grey squares

Parked by Rendering, 2026-11-02. `rubble_cells.diff` stacks on `2026-11-02a-fill-floor/fill_floor.diff`. Only with the tile ground's switch on; today's ground draws its rubble as before.

**The fault.** The EP, from Tools' reel (`docs/tools/img/page-reel-final2/sheet-5.png`, ticks 2410 to 3000): the rock on the right of the hill reads as big square patches, a blocky checker at gameplay zoom.

**What it was.** Not rock, a biome or a tile level. Three tests on a copy of Tools' kept stack tree (2b9dfe14), Tools' reel words, tick 2701:
- Each ground point painted by its biome: the whole hill is one id, and with the other layers off the slope shades smooth.
- The rubble tint switched off: the grey checker is gone, and the hill is plain sand.
- So it's the rubble the sim lays there (`rubble_at`), drawn the strip's way: a random grey for each 45-unit square of the strip's plane. On flat ground seen from the side those squares are thin slivers. On a hill face toward the camera they're big squares.

**The change.** On the tile ground the rubble's stones are 16-unit cells keyed to the planet in 3D (`v_q`, so they stay with the land through a swing), in three hard steps of value, plus or minus 6 percent (`rubble_cell`, a uniform in terrain.gdshaderinc). The heap's colour and how much of it shows are unchanged.

**Seen:** `docs/rendering/img/lookgate/rubble-stones/`, ticks 2401, 2601, 2701 and 2801, left before, right after, with the GIF. The heap is still there and still grey; it reads as stones, not a checker. Tried first and dropped: 16-unit cells at plus or minus 10 percent with no steps, which still read as a busy fine checker.

**Gates**, with a to z and 11-02a stacked on 8ea982c5's render, sim and data: golden byte-identical; tile, lake water, cover water and sweep checks pass; the 20 render gates exit 0; off 13 stills 0 differ (the change is inside `#ifdef TILE_GROUND`, so the off path and its flash clip are today's). The chain, 10-31a to 11-02b, applies on main 18852c72, apply check only.
