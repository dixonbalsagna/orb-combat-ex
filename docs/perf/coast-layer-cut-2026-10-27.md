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

## Owners and what it points to

- Terrain fragment cost on a weak GPU: **Rendering** (`ground.gdshaderinc`, `terrain.gdshaderinc`; the by-band ground, 22f), with **World** for the mesh's density (about 60k primitives near, 95k in a wide shot). Levers, none measured: a cheaper terrain shader on the Radeon tier (fewer texture and noise reads), a coarser far terrain in wide shots, and keeping the camera's wide shots short.
- The x4 CPU frame (view update 8.3 ms): **Rendering**'s PlanetView and FighterView update; a layer cut cannot find it.

## Not covered

One planet (7) and one coast stretch; the pair idle (no fight on screen: a fight adds the fighters, beams and particles, each 0.1 to 0.5 ms here); a phone's GPU.

## Files

`make-audit-sites.mjs --rev HEAD --only pblay`; `scratch-hooks/hook-layers.mjs` (new `cover` cut); `frame-bench.mjs --scene pb --page-args "pplanet=7&pgen=2&pbiome=coast" --igpu --layers --freeze 60|500` (the layer rows now carry `frame_p95`). Raw runs in my scratch folder (`w/farun9/`).
