# The band between the camera and the fight stays clear

Parked by Rendering, 2026-11-01. `band.diff` stacks on the tile ground, near towers, far tiles, water sheet and fighters at sea. Only with the tile ground's switch on.

**The fault.** With places-everywhere on, a wall of buildings filled the frame and the fighters showed through a hole.

**The cause.** `globe_near` only lowered a building a swing had brought nearer than its plan. Far places have plans that say nothing about where the fight is (depths up to about 36,000), so buildings between the camera and the fight stayed up at rest. The view draws all of `S.buildings`, so World's front limit alone doesn't change the picture (tested).

**What it does (`globe_tower`, mode 3; `RenderLook.TILE_BAND`, -150, -30, +150):**
- A building comes down to its kept base as its front face goes from -150 to -30 of depth, at rest too. It's read from the anchor and the depth, so nothing leans at rest. The front face matters: a building centred behind the band can still reach past the plane, and that's what hid the fighters at ticks 1741 to 1861.
- The kept base shrinks to nothing from -30 to +150, and past +150 the building is gone, so no base lies across the frame near the lens. Small things past +150 are gone too.
- A part stacked on another (a roof, a crown) comes down with the building's own base and no longer hangs in the air. That's the risk the near-tower README flagged.

**World's half:** `front-limit` tests the same front face at -150 (`plans.indexFrontBH` -2.0), so what can be struck and what stands agree. The first ring's blocks stop at -187, nearest centre -322.

**Gates**, on the EP's tree s400 plus the parks above, this diff and the crater diff: golden byte-identical, tile, lake water, cover water and sweep checks pass, the render gates all exit 0.

**Seen:** `docs/rendering/img/lookgate/building-band-before-after.png`, planet 7, seed 12345, left before, right after. In a stack that also has World's limit by hand. Fighters clear in stills every 60 ticks to 3421.

**Not checked:**
- The per-tick look of a building coming down in a swing: stills every 6 ticks only, on the version before bases shrink.
- The clash scene with the roof over the meeting point (Tools' `still-000320.jpg`) hasn't been run.
- Flash: none, as the switch is off and private.

**Known:** a building whose base has shrunk to nothing drops out at +150 with nothing left to see, and with no fade.
