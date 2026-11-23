# A fighter's shadow lies along the slope on the tile ground

Parked by Rendering, 2026-11-02. `shadow_tilt.diff` stacks on `2026-11-02c-burnt-charcoal/burnt.diff`. Only with the tile ground's switch on; today's ground keeps its flat shadow.

**The fault.** One of the low hills' leftovers: a fighter's ground shadow is a flat quad at the ground's height under him, so on a slope across it part of it sinks under the land, and the depth test cuts it to a hairline.

**The change.** On the tile ground's land the quad lies along the ground's slope, read at its four edges (`ground_at`, four reads a fighter a pane), and is lifted by however much its edges' mean stands above its centre, so a hollow under him doesn't bury the edges. Over water or a roof it lies flat as before. Size, strength, fade and lift are unchanged.

**Seen:** `docs/rendering/img/lookgate/shadow-on-slope/`: the low scene on rolling grass (planet 7, x 87,400, both fighters on the ground), left before, right after, and the feet at tick 241 enlarged four times. The change is small: the shadow shows a little more of itself where the ground rises across it, and nothing gets worse.

**Gates**, with 10-31a to 11-02c stacked on 8ea982c5's render, sim and data: golden byte-identical; tile, lake water, cover water and sweep checks pass; the 20 render gates exit 0; off 13 stills 0 differ. The chain applies on main 10d8b8cf, apply check only.
