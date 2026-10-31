# Terrain deformation and fast launches in the private preview: cost by stage (2026-10-30)

Owner: Performance and Platform, for the EP. Brief: the EP, 2026-10-30 (Orb on the private preview: "performance issues during terrain deformation and high speed launches"). Build: **12966cf4**, the commit Orb's preview was built from, with the preview's six switches on and `?planet=7` (`tools/preview/switches.mjs`, the scratch tree of `docs/perf/tools/make-stage-tree.mjs`; the repo tree was not touched). The new planet first, then the hand-made world.

## Result in one paragraph

Both complaints are real and both are mostly **not the sim**. The sim's dig, relax and water fill cost 0.4 ms on a dig frame (`s_dig`), 0.5 ms a tick overall. What costs is what the picture does about them: **VFX** (event consumer plus its layer) is the biggest block in both cases; on a dig frame the **planet view** (building re-footing sweep and the ground field's rebuild of its data) is the next, and on the new planet it is eight times the hand-made world's; and a **high-speed launch** has one single-frame spike of its own, the **launch planner's PROP SMASH flight simulation** (13 ms native at best, 33 to 100+ ms on the laptop target). In the web build half a frame is outside every script timer (engine draw, GPU, browser): 9 to 10 ms of a 21 ms mean frame on both GPUs.

## The top three, ranked by frame gained (on the laptop budget, ADR 0011)

| # | Fix | Owner | What it takes off | Evidence |
|---|---|---|---|---|
| 1 | **Launch planner: PROP SMASH's flight simulation runs whole in one frame** (`DirLaunch._propFlight`, called for every aim force of every PROP SMASH candidate; it steps `WorldContact` up to `TICK_CAP` ticks each). Bound it (coarser stride, an early out past the reach, one aim force not three), or run it in the wind-up ticks before the beat when the state is the same. | Combat (launch planner), Simulation for the determinism rule | A **13 ms native (best of 2; 84 ms in the other) single frame at the launch**, which is the worst frame of the whole AI match (24.8 ms against a p99 of 8.5). x2 to 3 in wasm, x4 on the laptop CPU: **a 50 to 100 ms hitch at the launch**. | `chooseLaunch` 17 to 19 ms of which `_biomeCands` 15 ms of which `_propFlight` 13.2; `predictFlight` 2 to 3 ms; cliff, tree line, skim, downhill, props near and targets 1.4 ms in all. Planet only (`WorldGround.live()`), once per launch plan |
| 2 | **VFX: the event consumer and the layer** (`h_vfx`, `r_vfxlayer`). A profile inside both, then the cuts. | VFX | **+4 to 6 ms a dig or launch frame** (web: dig 3.1 + 1.8 ms against 1.1 + 1.5 on a normal frame; fast launch 2.1 + 3.5 against 1.1 + 1.5), **p95 +6 to 8 ms** (dig: 7.3 + 4.6 ms against 2.8 + 3.4; fast camera: 4.0 + 9.7 against 2.8 + 3.4), and its own single-frame spikes (34 ms layer, 14 ms consumer) | every class table below; six of the 12 worst frames of the web stress run are led by a VFX stage |
| 3 | **Deformation's reaction in the planet view**: the building sweep re-footing every building on moved ground (`p_refresh`, `p_visit`), and the ground field's data (`g_shore` re-levelling, `g_gcol`, and `g_concat`, which joins 15 arrays of 4,800 floats into a new one every frame the ground changes, then sets the whole 21-row texture). Keep the data in one array and write the changed rows; re-foot only the buildings whose own columns moved; shore levels for the columns that moved. | Rendering (planet_view, ground_field), World for the shore levels | A dig frame's `r_planetupdate`: **3.3 ms mean, 9.5 p95 native; 5.2 mean, 16.8 p95 on the web build**, against 0.55 / 1.4 (native) and 0.87 / 2.4 (web) on a normal frame. 8% of frames in a fight that digs re-send the ground | the dig and "ground re-sent" tables |

Not in the three, for the record: the Animation first-use hitch: in 6 of the 11 single native runs checked, `d_anim` had a 28 to 175 ms frame at tick 265 to 281 (the first time something is posed), but it is 4 to 6 ms in the best of three, so it is a cold-start cost that load inflates (**needs a quiet-machine run before anyone fixes it**); `r_fighters` 1.2 ms (2.1 on the web build) every frame, steady; the water fill windows (open in 17 to 27% of frames, 1 ms or less); the three switches' own cost (+0.7 ms a frame, +1.3 on a dig frame).

## What is measured, and how (and what load may skew)

- **A stage-timer tree of 12966cf4** with the preview's switches and planet entry, plus `docs/perf/tools/scratch-hooks/hook-stages.mjs`: 75 inclusive `Time.get_ticks_usec()` pairs around the sim's sub-steps, the host's event consumers, the frame, `render_view`, `PaneWorld.render`, `PlanetView.update` and `refresh`, `GroundField`; one CSV row a frame with gauges (craters, fill windows, fastest body, launched bodies, camera speed in units a frame, buildings swept). Not in the repo. `make-stage-tree.mjs`, `stage-run.mjs` (native, `--headless`, 1280 x 720 set in the tree, 60 fps fixed, below-normal), `stage-web.mjs` (the web export in Tools' guarded browser, a real window, RTX and `--igpu` Radeon, vsync off), `stage-report.mjs`.
- **The sim is deterministic, so a repeat is the same work frame for frame.** The report takes **each frame's minimum over the repeats**: load only adds time, so the minimum is the frame's own cost, and a spike that is real (the same frame in every run) stays while a preemption does not. Native: 3 repeats; web: 2.
- **Scenes.** (a) The AI match, seeds 4 and 12 (2 minutes), where the AI digs 3 to 6 craters in all and launches rarely. (b) **A stress: a ground-level power-up every 75 frames** (tiers 2 to 4, through `SimFighter.tierUp`, so the crater, area damage, debris, dust and every event take the game's own path), about 16 craters in 3,600 frames, three times what the AI digs; the AI plays the rest and launches as it does. A scripted first player (key presses) was tried; it took the slot but the charge never powered up, and it is not used.
- **Load.** The PC was at 87 to 100% for all of it (other sessions' Godot, Chrome and Python). The native minimums of 3 are the least skewed; I would not put them 15% off. **The web numbers are upper bounds**: 2 repeats, a browser competing at below-normal priority, and the RTX runs read heavier than the Radeon's (11.0 against 9.4 ms a frame of work) which is the load and my own native runs alongside, not the GPUs. Read the web tables for their ratios between classes, not for their absolute milliseconds; these runs' wall time is 15 to 21 ms mean (best of 2) where the quiet audit of 2026-10-16 read 6.5 ms p50 on other scenes.
- **What the timers do not see.** The frame's `wall` minus its script `work` is the engine's draw and the GPU and browser: **mean 10 ms (RTX), 9 ms (Radeon) in the web stress run**, p95 23 and 18. It has no per-stage timers (they would need GPU timestamp queries); the draw-call and primitive audit of 2026-10-16 (budgets.md) is its last reading.

## Where a frame goes (planet 7, the stress scene)

Native, best of 3, ms of script work in the frame (`work` = advance + render + HUD + audio play):

| Class (share of frames) | Mean | p95 | p99 | Worst |
|---|---|---|---|---|
| All frames | 5.75 | 9.63 | 16.6 | 44.1 |
| **A crater is dug** (1.5%) | **13.3** | **30.3** | 44.1 | 44.1 |
| The ground is re-sent (8%) | 9.55 | 19.9 | 30.8 | 44.1 |
| A fill window is open (17%) | 7.02 | 12.4 | 19.5 | 23.6 |
| **Camera fast**, the top 5% by units a frame | 9.47 | 18.5 | 22.0 | 30.8 |
| A body is launched (6%) | 8.49 | 19.1 | 22.5 | 30.9 |
| (The AI match, seed 4, all frames) | 4.06 | 6.10 | 8.52 | 24.8 |
| (The AI match, seed 12, fast camera) | 7.23 | 14.1 | 17.1 | 19.2 |

Web build, RTX, best of 2, stress scene (work / wall, ms; wall is frame to frame):

| Class | Work mean | Work p95 | Wall mean | Wall p95 | Wall p99 | Wall worst |
|---|---|---|---|---|---|---|
| All frames | 11.0 | 20.4 | 21.0 | 37.4 | 51.4 | 109 |
| A crater is dug | 22.8 | 46.6 | 20.5 | 38.0 | 45.5 | 45.5 |
| The ground is re-sent | 17.4 | 32.3 | 25.8 | 40.9 | 67.2 | 83 |
| Camera fast | 17.2 | 31.0 | 31.8 | 56.8 | 105 | 109 |
| A body is launched | 15.1 | 30.6 | 27.8 | 47.1 | 66.9 | 67.2 |

Radeon (integrated, `--force_low_power_gpu`; "the nearer stand-in"), same scene: work 9.4 / p95 16.9; wall 18.0 / p95 32.2 / p99 46.8 / worst 152; fast camera wall 28.3 / p95 47.6 / p99 72.9; a body launched 25.1 / 46.3 / 73.4. The AI match, seed 12, first 1,500 frames: RTX wall 15.4 / p95 25.9 / p99 33.4; Radeon 12.1 / 19.2 / 25.1 (fast camera 19.3 / p95 28.3).

## Terrain deformation: a dig frame, stage by stage

Native, best of 3, ms (mean / p95) on the new planet against the hand-made world, and the web build (RTX):

| Stage | New planet, native | Hand-made, native | New planet, web RTX | A normal frame, planet native |
|---|---|---|---|---|
| **Work** | **13.3 / 30.3** | 7.90 / 15.8 | 22.8 / 46.6 | 5.75 / 9.63 |
| Sim step (`SimCore.step`) | 0.83 / 2.66 | 0.46 / 0.90 | 1.25 / 4.10 | 0.56 / 1.09 |
| of which the dig (inclusive) | 0.35 / 1.12 | | | 0.01 |
| VFX event consumer (`h_vfx`) | 2.25 / 6.01 | 1.20 / 4.15 | 3.14 / 7.30 | 0.64 / 1.45 |
| **Planet view update** | **3.26 / 9.53** | 0.88 / 4.10 | **5.15 / 16.8** | 0.55 / 1.39 |
| of which the ground field | 1.24 / 4.21 | 0.44 / 3.34 | 1.78 / 6.70 | 0.09 / 0.67 |
| of which the building refresh | 1.20 / 4.42 | 0.14 / 0.23 | 2.15 / 8.10 | 0.28 / 0.57 |
| Fighters' views | 1.55 / 2.24 | 1.46 / 2.06 | 2.63 / 7.00 | 1.20 / 1.96 |
| VFX layer | 1.11 / 2.55 | 0.68 / 1.71 | 1.79 / 4.60 | 0.86 / 1.89 |

- **The sim is 6% of a dig frame.** The dig itself 0.35 ms, the relax and neighbour rows included; the water fill (`s_fillwin` 0.6 ms, `s_fillopen` 1.5 ms at worst, 0.17 mean on a dig frame). Nothing here needs Simulation.
- **The ground field's cost is data movement, not maths**: `g_shore` (shore levels for the moved columns) 0.59 ms mean, 2.2 p95 on a dig frame; `g_gcol` 0.26; `g_concat` 0.25 (0.4 on the 8% of frames that re-send), the join of 15 arrays into one of 403 KB (21 rows of 4,800 floats), set into the image whole; the texture update call (`g_texupdate`) is 0.0 to 0.1 ms on the web build (the GPU's copy is behind it, in the unmeasured part of the frame). So the CPU copies are the measured cost.
- **The new planet doubles-to-triples the reaction** (13.3 against 7.9 mean) because 35 buildings are swept on a dig frame (the sweep is 16 at its floor in the hand-made world); the building refresh is 8 times the hand-made world's. The three switches add +0.7 ms a frame and +1.3 on a dig frame (switches off, same scene: 5.01 / 12.0).
- **Wall time on the dig frame is not worse than a normal frame's** on the web build (20.5 against 21.0 ms mean): the dig's extra script work is spent where a normal frame spends it on the engine's draw; the **worst** dig frames are what a player feels (p95 work 46.6 ms, 3 frames of 60 Hz).

## High-speed launches

- **The frames.** A launch that sends the camera across the planet (up to 240 units a frame; the planet's whole ring is 4,800 columns of 32 units): `r_vfxlayer` 1.2 ms mean and 3.0 p95 in the fast-camera class native against 0.3 and 1.0 on all frames (seed 12); web RTX 3.55 mean, **9.7 p95**, **19 p99**. `h_vfx` and `r_planetupdate` roughly double (the sweep covers up to 56 buildings in the fast frames against a mean of 18; `p_startle` and `r_cull` reach 0.5 ms at p95 from nothing).
- **The launch plan's own frame** (above, #1): 13 ms of flight simulation at best. In AI play one call in 6,000 frames reaches it (the AI mostly launches by the old paths), so the AI match understates it; a player who lands a finisher on the new planet calls it every time. **Not measured with a human**; the count of calls per minute needs Orb's play or Game Design's number.
- **Camera speed's own cost is small**: `r_panhaze` 0.01 ms, `r_cull` 0.1 ms; there is no per-frame cost in the camera.

## Spikes, as the brief asked: p95 and worst

- Native planet stress: work p95 9.6 ms (budget for the whole frame at p95: 8.3 ms at x1, ADR 0011), p99 16.6, worst 44.1 (a dig frame with a tier-4 power-up).
- Native AI match: p95 6.1 / 7.0, p99 8.5 / 10.5, worst 24.8 (the launch plan) / 23.0.
- Web RTX stress: wall p95 37.4, p99 51.4, worst 109 (load-skewed; the 109 ms frame is not explained by a script timer). Web Radeon: p95 32.2, p99 46.8.
- **Vs the limits** (budgets.md): "no frame over 50 ms after the warm-up" is broken in every web scene here, on both GPUs, by a handful of frames a minute; the p95 at the laptop stand-in is 3 to 4 times its 8.3 ms. The sim-side rows hold: sim tick 0.5 ms mean, 1.0 p95, 1.3 to 1.7 p99 (the row's p99 limit is 1.0: at it on the planet).

## Not covered

A real old laptop or Linux/Deck; the engine's own draw and GPU time per stage (the 10 ms outside the timers); a human playing the preview (the stress is a stand-in for deformation, and no scene here is a human launching); the quiet-machine re-run of everything above (all of this was taken at 87 to 100% load; `stage-run.mjs` and `stage-web.mjs` reproduce it in a quiet window with no change); the Animation first-use hitch; the VFX layer's inside.

## Files and recipe

`docs/perf/tools/`: `make-stage-tree.mjs` (a scratch tree of a revision, preview switches on or `--off`, the hooks, imported), `stage-run.mjs` (native run, `--planet`, `--stress N`, `--seed`, `--frames`, `--turn`, `--arenacols`, `--ringcost`), `stage-web.mjs` (`export`, then `run` with `--igpu`), `stage-report.mjs` (per-frame minimum over repeats, class tables, the worst frames); `scratch-hooks/`: `hook-stages.mjs`, `hook-script.mjs` (the stress and the key script), `hook-launch.mjs` (the launch planner's pieces), `hook-turn2.mjs` and `hook-ringcost.mjs` (the calm-turn and whole-ring probes, used in `docs/world/ring-any-angle/performance.md`). Recipe: `node docs/perf/tools/make-stage-tree.mjs --out <new dir> --rev 12966cf4`, then `node docs/perf/tools/stage-run.mjs --tree <dir> --out <csv> --seed 4 --frames 3600 --planet 7 --stress 75` three times, then `node docs/perf/tools/stage-report.mjs --runs a.csv,b.csv,c.csv`. Raw CSVs are in my scratch folder (`pv/runs/`).
