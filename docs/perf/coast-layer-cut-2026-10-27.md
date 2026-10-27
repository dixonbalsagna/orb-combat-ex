# The gen 2 coast, layer by layer, on the Radeon (HEAD f50e9902, 2026-10-27)

Owner: Performance and Platform, for the EP and Rendering. Scratch export of f50e9902 (`pblay`: the `pb` scene, hook-pbiome, plus the layer cuts, with a new `cover` cut for the biomes' cover). Scene: planet 7, gen 2, coast (`pplanet=7&pgen=2&pbiome=coast`), the pair idle on the longest coast stretch (33 columns at column 4184), Whole ring, 1280 by 720, web build in Tools' launcher. The scene is run to a tick, paused there (the same picture is drawn every frame), and each layer is hidden in turn: the frame time of the SAME picture is read with the layer missing. Radeon = the integrated Radeon (Chrome's low-power GPU, ANGLE D3D11), RTX = the 5070 Ti. All runs valid by the load rule; two Radeon runs at tick 60 agree within 0.2 ms.

## Radeon x1: what a layer costs (paused frame, p50 ms; layers cut one at a time)

| Layer cut | Tick 60 (the opening, wide shot) | Tick 500 (the pair idle, tight shot) |
|---|---|---|
| none (the whole picture) | **15.9** (p95 16.6) | **9.3** (p95 9.9) |
| **terrain** | 7.4 (**-8.5**) | 4.9 (**-4.4**) |
| water | 14.5 (-1.4) | 8.5 (-0.8) |
| buildings (near) | 14.8 (-1.1) | 8.2 (-1.1) |
| trees, crowd, cover, fighters, beams, particles, vfx (each) | -0.1 to -0.5 | -0.0 to -0.3 |
| HUD | -0.7 | -0.4 |
| terrain + water | 5.8 (-10.1) | 3.9 (-5.4) |
| every layer cut (the floor) | 3.5 | 2.6 |
| Draw calls / primitives (k) | 351 / 245 | 229 / 147 |

- **The top layer is the terrain**, by a wide margin: 53% of the frame in the wide shot (8.5 of 15.9 ms) and 47% in the tight one, against 0.8 to 1.4 ms for the water, which costs the same primitives (about 60k each). A terrain mesh and a water mesh of the same size, and the terrain 5 times dearer: the terrain is **fragment-bound on the Radeon** (the ground shader), not vertex-bound. Rendering's 1.1 ms of water vertex work is what the table says (0.8 to 1.4 ms); cutting the water leaves 14.5.
- **The tail comes from the wide shots.** Live frames over a 900-tick run that starts at the opening: p50 9.2, p95 12.1, p99 18.5 to 18.9, max up to 34 ms. Once the camera has settled (tick 500 on): p95 9.9, max 12.7. The frames over 16 ms are the pulled-back framings, where about 245k primitives are drawn instead of 147k.
- **RTX**: 3.3 ms for the whole picture and every cut within 0.2 ms: the scene is not GPU-bound there (live p50 6.2, p95 7.8).
- **x4 on the Radeon is a different story, and no layer is in it**: live p50 30.4, p95 47.3 ms, but the paused frame is 9.8 ms with every cut (the GPU side hides behind the CPU). The extra is the main thread's per-frame work in the wasm: view update 8.3 ms a frame (1.3 ms at x1), tick 1.5 ms (0.3), and the engine's own scene work (the renderer process 20.8 ms a frame against 5.2 at x1). Hiding a layer does not shorten it (a hidden node is still updated). I could not reproduce a 25 ms p95 on the Radeon at x1 (9.9 to 12.1 ms); at x4 it is 47 ms.

## Matching Rendering's p95 25 ms (added 2026-10-27, same export, Radeon x1)

Rendering's setup (`--scene pb --page-args "pgen=2&pbiome=coast&pplanet=7" --igpu --reduced --ticks 600`, no layers) reproduces here: three runs p50 11.7 to 12.0, **p95 25.9 to 26.0**, p99 33 to 34, max 444 to 479 ms. The cause is the part of the match it measures, not `--reduced`:

| Run (Radeon x1, coast, 600 ticks) | p50 | p95 | p99 | max |
|---|---|---|---|---|
| Rendering's setup, ticks 120 to about 720 (`--reduced`), 3 runs | 11.7 to 12.0 | 25.9 to 26.0 | 33.2 to 33.9 | 444 to 479 |
| the same without `--reduced`, 2 runs | 11.7, 11.9 | 26.0, 26.1 | 34.0, 34.1 | 444, 461 |
| `--reduced`, started late (warm 600: ticks 600 to 1200) | 9.2 | 10.9 | 12.0 | 13.3 |

- The 25 ms tail is the **opening of the match**: 73 of 599 frames are over 25 ms (12%), and the frames at that point draw 355 to 365 calls and 227k to 451k primitives (p95 451k), against 229 calls and 147k once the camera has settled. It is the wide opening shot, the same cause as the tick-60 row above, so the terrain's fragment cost is the layer behind it too. The first frame of the run is a 444 ms hitch (the scene's first draw).
- Water hidden gives the same p95 because the water is 0.8 to 1.4 ms of a 16 ms wide-shot frame; the terrain is 8.5 ms of it.
- The p50 11.7 ms mixes the two parts (the opening and the settled shot), so the table above, not the p50, is the way to read the coast.

## Owners and what it points to

- Terrain fragment cost on a weak GPU: **Rendering** (`ground.gdshaderinc`, `terrain.gdshaderinc`; the by-band ground, 22f), with **World** for the mesh's density (about 60k primitives near, 95k in a wide shot). Levers, none measured: a cheaper terrain shader on the Radeon tier (fewer texture and noise reads), a coarser far terrain in wide shots, and keeping the camera's wide shots short.
- The x4 CPU frame (view update 8.3 ms): **Rendering**'s PlanetView and FighterView update; a layer cut cannot find it.

## Not covered

One planet (7) and one coast stretch; the pair idle (no fight on screen: a fight adds the fighters, beams and particles, each 0.1 to 0.5 ms here); a phone's GPU.

## Files

`make-audit-sites.mjs --rev HEAD --only pblay`; `scratch-hooks/hook-layers.mjs` (new `cover` cut); `frame-bench.mjs --scene pb --page-args "pplanet=7&pgen=2&pbiome=coast" --igpu --layers --freeze 60|500` (the layer rows now carry `frame_p95`). Raw runs in my scratch folder (`w/farun9/`).
