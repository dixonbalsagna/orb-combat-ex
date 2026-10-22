# The arena's length (Rendering, 2026-10-22)

World's shifting arena (`docs/world/shifting-arena-design.md`, window 1) plays a match on a ring of the planet: 4,800 columns for the great circle (153,600 units), 2,400 (76,800) or 1,200 (38,400). `SimConst.W`, `NC` and `HALF` are set per match, so the render follows them.

## What follows the arena's length

- **The ground is made again when the length changes.** `PlanetView.build` compares the length its ground was made for (`_built_nc`) with `SimConst.NC`. When they differ, it makes:
  - a new `GroundField` (its height texture, crater lists, far rows and water rows are sized by the length);
  - the ground and water meshes;
  - the materials that read them (`nc`, `world_w`, the textures).

  A second pane takes the first's, and panes are built first pane first. Before this, everything was made once for the 4,800-column planet at startup, and a shorter ring drew the wrong ground: the height texture failed to upload, the shaders wrapped at the wrong length, and copies a planet long overlapped.
- **The copies keep their reach in world units.** The ground and water are drawn `copies_each_side()` planets either side of the camera: `PLANET_COPIES` (2) whole-planet lengths, so 2 on the great circle, 4 on a ring of 2,400 and 8 on a ring of 1,200. The props reach one whole-planet length: 1, 2 and 4. Camera's zoom floor is untouched.
- **The ground chunks take a partial last chunk** when the length is not a multiple of `CHUNK_COLS` (320), so a ring of 2,400 or 1,200 has no missing strip and no overlap. A ring's length must be a multiple of the largest stride (8). World's 4,800, 2,400, 1,600, 1,200 and 600 all are.
- **ImpactFx's heat** is resized on a new match.

The far fog needs nothing. At play zooms the far horizon is 117,000 to 184,000 units wide (16:9 to 21:9), inside the copies' reach on every ring.

## Checked

- **A probe** (one game, rings of 1,200, 4,800, 2,400, 1,200 and 4,800 in turn): after each match the heat, the materials' `nc` and `world_w`, the near chunks, the ground's reach and the copies all follow the ring, with no image errors. Before this, each match on a short ring logged the height texture's size error.
- **Stills** (seed 4, Reduce flashing on as the demo has it):
  - `img/arena-1200-before-after.png`: the 1,200 ring before and after;
  - `img/arena-1200-d3f1ca0e.png` and `img/arena-2400-d3f1ca0e.png`: against d3f1ca0e.

  All uncommitted.

## The turn (World's window 3, 2026-10-22)

At a calm moment World turns the ring about the pair (`docs/world/calm-turn-world.md`). On that tick the sim emits `arena_turn`, with fields `n`, `x` (the pivot), `amount` (the bearing) and `k` (the drift). Within `x` plus or minus 12,000 units the ground, craters, buildings and people stay as they were; the ground fades into the new ring's across the zone's outer three quarters; beyond it, everything is new.

- **The render follows on that tick, as a hard cut.** Main's `_arena_turn` has every pane (the split's two and Camera's inset) build its planet again from the new world in the same frame. There is no dissolve, fade or wipe (ADR 0010). Camera decides the cut's moment and shot, so its cut must be on the `arena_turn` tick. At the turn's frame the ridges behind the fight change while the fighters and the near ground hold, which reads as a pop under a still camera. The rebuild covers:
  - **the ground:** the height texture (base heights, marks, water, biome), the far rows and the crater lists;
  - **the buildings and the crowd** (the swap renumbers them), with their lanes and open faces;
  - **the sky's towns** (`SkyDrive.towns_again`), each taking the glow of the old town round it, so the towns near the pair stay lit;
  - **ImpactFx's heat**, which fades across the zone as World fades the marks and is gone beyond it.
- **The ground's meshes carry no biome colour any more.** The terrain shader reads each column's biome from the ground texture's biome row, as the far land already did. So a new world on the same length is a texture upload, never new meshes. Making the meshes again cost 160 to 330 ms; the whole rebuild now costs 17 to 26 ms.
- **The far rows' smoothing is a running sum:** 2 to 3 ms, where it was 30 to 55.
- **The ring is warmed in the sim, not here.** World reads the picked ring inside `WorldEpoch.tick`, at the rate stored on the pick, in hashed state, so a replay is the same. Rendering never writes the sim, so the host takes no part in it. When the swap comes the ring is read, and the turn's frame is the render's rebuild plus World's swap (under 10 ms warm).
- **A fix on the way: the ground follows the world, not only its length.** `_built_cols` keys the far rows on `S.planetCols`. Before this, a planet match after another on the same length drew the first world's ground colours and far relief: in the probe, 2,298 of 2,400 columns were wrong.

### The turn, checked

- **A probe** (planet 7, touch 3, a ring of 2,400; the turn forced as World's `turn_dump` does) compares each pane's ground with the world:
  - the biome the GPU holds for every column, the far rows, the base heights in the texture, and the buildings drawn against the sim's;
  - after a planet match that follows another, and after a turn, all match, and the split's second pane and the inset share pane 0's meshes;
  - with World's window 3 alone, after a turn 837 of 2,400 columns showed the old biome, the far rows and base heights were the old world's, and 71 buildings were drawn where the sim had 64;
  - the sky's towns had raised a script error (a building index past the end), which is gone;
  - the heat is kept at the pivot, is 0.26 at 9,000 units and is gone half the ring away.
- **What a warm-up costs a frame, on the web build** (World's read of the ring at `k` columns a tick; the transformation scene, AI against AI with three form steps, 600 frames; Performance's `frame-bench` through Tools' guarded launcher with its perf hook; a scratch switch reads planet 7's ring of 4,800 at `k` columns every tick throughout, through the same `WorldPlanet.RingJob`; two rounds in turned order, every run valid by the bench's load rule except one of the baselines):

  | | k 0 | k 32 | k 64 |
  | :--- | :--- | :--- | :--- |
  | RTX 5070 Ti, p50 / p95 ms | 4.9 / 9.4 | 8.1-8.2 / 10.8-11.2 | 12.0-12.3 / 16.3-16.6 |
  | RTX, frames over 16.7 ms | 2-7 | 2 | 24-28 |
  | Radeon iGPU (`--igpu`), p50 / p95 ms | 8.7-8.8 / 19.1-32.5 | 9.0-9.3 / 19.2-20.3 | 12.4-12.9 / 19.6-30.9 |
  | iGPU, frames over 16.7 ms | 62-88 | 65-73 | 72-88 |

  - The read is CPU work in the page: about 0.11 to 0.12 ms a column here (k 32 about 3.7 ms a tick, k 64 about 7.6).
  - On the RTX the frame is CPU-bound, so it all shows.
  - On the iGPU the frame is GPU-bound, so k 32's read overlaps the GPU's work: plus 0.3 to 0.5 ms at the median, its long frames within the baseline's spread.
  - **So k 32 holds the iGPU's frame time, and warms a ring of 4,800 in 150 ticks, inside a full form pause (180).**
  - The CPU here is fast (a 9800X3D). The old-laptop bound is the iGPU with Chrome's CPU throttle at 4 (two rounds, all valid):

    | | k 0 | k 16 | k 32 |
    | :--- | :--- | :--- | :--- |
    | p50 / p95 ms | 22.5-23.0 / 36-40 | 30.9-42.4 / 53-80 | 46.7-46.9 / 63.5 |
    | frames over 16.7 ms (of 600) | 517 | 599 | 599 |

    - There the scene alone is over 16.7 ms, and the read costs about 0.75 ms a column a tick: k 16 adds 8 to 19 ms, and k 32 adds 24 ms (about 21 frames a second for the 2.5 s it reads).
    - No `k` that fits a form pause holds that bound. To stay within about 2 ms there, a ring of 4,800 would take half a minute to read.
- **Time** (machine load 12 to 19%):
  - the render's rebuild is 12 to 20 ms for pane 0, 4 to 6 ms for the two followers and under 1 ms for the sky;
  - with the ring warmed, the whole turn frame was 29 ms on a ring of 2,400;
  - cold (the swap one tick after the pick) it was 330 ms, nearly all of it World's read of the ring.
- **The look:**
  - The default world and a planet world are pixel-identical with the biome moved into the shader: 0 of 518,400 pixels differ at seed 4.
  - `gates9` (17 checks) and `cue_check` pass with 0 script errors.
- **Stills** (seed 4, the hook's AI match on planet 7, touch 3, a ring of 2,400, Reduce flashing on as the demo has it). A scratch switch asks for the turn at tick 4800; World finds calm and turns at tick 4939, 2.3 s later. Both stills are uncommitted:
  - `img/turn-4939-d3f1ca0e-play.png`: d3f1ca0e on the left, then ticks 4938 and 4939 at the fight's own framing. At the cut the ridges behind change: 148,000 pixels, against 10,000 to 30,000 on an ordinary frame.
  - `img/turn-4939-wide.png`: the same two ticks, with a scratch pin of the zoom at 0.02 pixels a unit (48,000 units across). Past the zone the land, the strip of sand, a tower and the fields are the new ring's.
