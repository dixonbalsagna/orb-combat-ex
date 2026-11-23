# A burnt-out glass wall is charcoal on the tile ground, not black

Parked by Rendering, 2026-11-02. `burnt.diff` stacks on `2026-11-02b-rubble-stones/rubble_cells.diff`. Only with the tile ground's switch on (`globe_r > 0`); today's ground keeps its look.

**The fault.** Director's beam-hold stills (`docs/director/img/shove-t00055.png` to `t00085`): from about tick 55, a black block with a square top at the foot of the building behind the fighters.

**What it is.** A glass tower's damage, spreading up from where it's hit in square steps, a window cell at a time. Where it has spread, the wall goes toward the tower's inside colour by `pattern_budget` (0.085), which leaves it at the inside's own near-black (about #12131a). The building's comment says why: a burnt-out tower is dark. At that value the spread's stepped front reads as a black block with nothing in it, at the foot first, then over the whole tower.

**The change.** On the tile ground a burnt-out wall stays `burnt_budget` (0.14, `RenderLook.BURNT_BUDGET`) from the inside instead: charcoal, with the window grid still showing. The spread itself, its steps and its timing are unchanged.

**Seen:** `docs/rendering/img/lookgate/burnt-charcoal/`, the city signature scene on a copy of Tools' kept tree (2b9dfe14), ticks 81, 91, 201 and 231, with the GIF (every 10 ticks, 1 to 241). Left before, right after: the burnt tower top right at 91 and the building in the right pane at 231 read as charcoal, not black. No dissolve, fade or marker.

**Gates**, with 10-31a to 11-02b stacked on 8ea982c5's render, sim and data: golden byte-identical; tile, lake water, cover water and sweep checks pass; the 20 render gates exit 0; off 13 stills 0 differ. The chain applies on main 10d8b8cf, apply check only.
