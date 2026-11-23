# A tile's data level kept apart from its layer number

Parked by Rendering, 2026-11-01. `layer.diff` stacks on `2026-11-01r-fill-slice/slice.diff`. Only with the tile ground's switch on. **Land it with `2026-11-01p-tile-pool`:** without this, the bigger pool draws floating plates.

**The fault.** A tile told the shader its layer and data level as one number, `layer + level * 0.125`. Past layer 256 the level read wrong, and past 512 worse, so a tile fetched its heights from the wrong place in its own data and drew ground that wasn't its own. It builds up over a match, because layers fill as play goes on.

**The evidence.**
- A pool that settled at exactly 256 layers (pause at tick 541) never showed it. With 800 layers, large plates floated over the hill with sky under them, seen from below: `docs/rendering/img/lookgate/tile-plates-after-pool-fix.png`, and by level, `tile-levels-paint.png`.
- Each level's stored heights agreed with the planet's: the data was right.
- A ray through a grid of pixels found every ground pixel covered by a drawn tile: nothing was missing from the list, and the plates sat above where the data says the ground ends.
- With this diff, same pause and tick: the plates are gone and the outline is whole: `tile-level-fix-before-after.png`, left without, right with.

That the engine keeps instance data as 16-bit floats is inferred from this pattern. The engine's code wasn't read. The change is right either way.

**The change.** The custom data's first value is the layer alone. The fourth is `level * 16 + width / 1000`; the width is under 16, so the shader reads the level with `floor(a / 16)` and the skirt's width with `mod(a, 16)`.

**Not shown.**
- **Orb's shot wasn't reproduced:** the house undersides on Orb's paused hill never appeared on this stack. At Orb's pool of 430 the bug only touches layers 256 and up at the odd levels 1 and 3. The check is Orb's replay or hillside, paused for a minute, on a build with this diff.
- It wasn't run alone at 430. It's written not to depend on `p`, but that's not been tested.
- The brown ribbed face in the same frame stays. It sits in a continuous hill now. Its saw-toothed top edge is where the rock tone starts, a look question, not fixed here.

**Gates**, with a to t stacked on 8ea982c5's render, sim and data: golden byte-identical; tile, lake water, cover water and sweep checks pass; off 13 stills 0 differ. The 20 render gates exit 0, but run without the tile word. Main has moved; the chain applies on ab7f2572, apply check only.
