# A tile in use is never evicted, and the pool fits two panes

Parked by Rendering, 2026-11-01. `pool.diff` stacks on `2026-11-01o-ice-value/ice.diff`. Only with the tile ground's switch on.

**The fault.** In split screen the view wants more tiles than the pool can hold. Read in a real pause (tick 3301, seed 12345, planet 7, reel's stack): the two panes want 393 tiles, the pool has 376 reusable layers. With the sim frozen it never settles: stores climbed 713 to 1,500 and evictions of wanted tiles 14 to 408. Refills go nearest first, so far tiles lose, and a missing child sends its parent's whole area back to the coarse level.

**The change.**
- `POOL` 800, about 746 reusable. Each layer holds 28 by 28 of height and of ids, about 6 KB, so about 2.3 MB more texture, plus the heights kept on the CPU, about 1.2 MB.
- Each pane records the tiles its current selection uses. A layer in any pane's set can't be evicted. When none is free the field stops fetching and keeps what's drawn; what's missing is asked for again when the view moves.

**Result, same pause:** stores stop at 674, evictions of wanted tiles 0, nothing missing, 390 wanted and fitted.

**Warning. This uncovers a fault it doesn't fix.** With every tile present, level-2 tiles show as plates floating over the hill: `docs/rendering/img/lookgate/tile-plates-after-pool-fix.png`, and painted by level `tile-levels-paint.png`. Don't land this before that's understood.

**Not measured:**
- A wide shot, or 70/30. The size is by reasoning: nearly twice the 393.
- WebGL2 only promises 256 array layers, and the pool was already past that at 430. An old GPU's limit isn't checked.
- A pane that stops drawing without being dropped keeps its tiles pinned until it's dropped or selects again.

**Gates**, with a to r stacked on 8ea982c5's render, sim and data: golden byte-identical; tile, lake water, cover water and sweep checks pass; off 13 stills 0 differ. The 20 render gates exit 0, but run without the tile word.
