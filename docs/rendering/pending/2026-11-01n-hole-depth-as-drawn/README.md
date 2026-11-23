# The building shader's depth tests read the depth as drawn

Parked by Rendering, 2026-11-01. `hole.diff` stacks on `2026-11-01m-building-plan-depth/depth.diff`. **Land it with m:** m exposes the fault this fixes. Only with the tile ground's switch on.

**The fault.** A soft pale round halo around the fighters, over a tall glass building (`docs/tools/img/page-reel-minute/sheet-2.png`, ticks 990 to 1065).

**What it is.** The round see-through hole around each fighter, which is dithered with a hard cut, not a fade. The pale colour is the ground behind the cut building. On the reel's stack at tick 1035, the patch radius reads 0 and the hole radius 95 px, matching the picture.

**The cause.** The hole should cut only what stands nearer the camera than the fighter. Building 496's front face is 91 behind the fighters, so it should not be cut. The test read `VERTEX.z`, which on the tile ground is the mesh's flat plan place, while the planet's turn draws it somewhere else. After a swing the two disagree. m put meshes on their plan, so m almost certainly exposed this. Neither the reel without m nor this building's plan depth was read; the evidence is that this fix removes the halo.

**The change.** With tiles on, the vertex stage hands the fragment the depth as drawn, in a second component of the existing `v_gz` varying, so the varying count stays 17. The hole's test and the two near-lens thinning tests read it. With tiles off they read `-VERTEX.z`, as before.

**Seen:** `docs/rendering/img/lookgate/hole-misfire-before-after.png`, reel's stack, ticks 931, 991, 1006, 1036, left before. The halo is gone and the fighters are clear against the whole building.

**Not shown:**
- A building truly in front of a fighter should still be cut. That case wasn't shot.
- The two near-lens tests changed too; no frame was checked for them.
- Stills of only ticks up to 1036 were taken with this diff.

**Gates**, on 8ea982c5's render, sim and data with all my diffs: golden byte-identical; tile, lake water, cover water and sweep checks pass; off 13 stills 0 differ. The 20 render gates exit 0, but run without the tile word.
