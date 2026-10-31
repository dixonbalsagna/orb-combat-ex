# A bearing change at any time: the performance budget (Performance and Platform, 2026-10-30)

For the EP's ask on Orb's idea (the fight's bearing changes dynamically, up to continuously). Written into this folder at the EP's request (the folder is World's; only this file is mine). Measured on 12966cf4 with the preview's switches and `?planet=7`, in a stage-timer scratch tree (`docs/perf/preview-deform-launch-2026-10-30.md` has the method).

**Revised 2026-10-31 after a quiet re-run on HEAD e8a95e35 (section 2, and section 5 for Orb's turntable pick).** The first version was measured with the PC at 87 to 100% load; its swap figures were inflated about 1.7 times and are replaced below. The quiet run had the PC at 21 to 31% load, three native runs at a time at below-normal priority (best of 3 per frame; a repeat is the same work), then one browser at a time (RTX, x1). Nothing here was built or changed in the game.

## 1. The budget: what a change can spend on the laptop target

The laptop is a 30 fps machine (33.3 ms), stood in for by the dev PC's x4 CPU, which makes the whole frame **8.3 ms at p95 at x1** (budgets.md, ADR 0011). One dropped 30 fps frame on the laptop is **33 ms at x4, so 8 ms of added work at x1**. The hard limit is no frame over 50 ms.

| Row | Limit (x1) | Today, new planet, native best of 3 | So a change may add |
|---|---|---|---|
| Frame, p95 | 8.3 ms | AI match 6.1 to 7.0; a fight that digs 9.6 | **about 2 ms in a quiet fight, nothing in a digging one**. Web (load-skewed): script work p95 14 to 20 ms, no headroom |
| Frame, p99 | 12 ms | 8.5 to 10.5; 16.6 when digging | nothing |
| Sim tick | 0.4 mean, 1.0 p99 | 0.5 mean, 1.0 p95, 1.3 to 1.7 p99 | **nothing from the sim's average; a read of ~0.1 to 0.2 ms a tick on idle ticks at most** |
| Per-frame render add (average) | | | **at most 0.5 to 1 ms** (4 ms on the laptop CPU) |
| One-off spike (one frame) | 8 ms at x1, once in a while | | **8 ms**; beyond it the spike needs a cut's cover (ADR 0010: a hard cut, no dissolve) and then it still drops frames |

In the sim: World's ring read is **54 us a column native and 130 us on the web build (0.8 ms at the laptop's x4, `gen2-bench-2026-10-26.md`)**. At 0.2 ms a tick that is **about 4 columns a tick native and 1.5 on the web**, so a Half ring (2,400 columns) takes 600 ticks (10 s) native or 1,600 (27 s) on the web, and a Whole ring twice that, to read a new bearing at a spend the budget can bear (the first version of this note used the native rate for all targets). Today's warm reads 16 to 32 a tick (my timers: 0.19 ms mean and 5 to 10 ms at its worst tick native; 0.67 ms mean on the web build). A continuous bearing would be reading toward bearings in a queue, not at the rate the fight changes.

## 2. What today's swap really costs (quiet re-run, HEAD e8a95e35, 2026-10-31)

The swap is **the render rebuild**; the sim's step is small (World's prepared swap: 3 to 4 ms on a Half ring in my runs, 5 to 6 on a Whole one).

| Frame of the swap | Half ring (2,400) | Whole ring (4,800) |
|---|---|---|
| Native, best of 3 (`d_arenaturn`, the render rebuild) | **57 to 61 ms** (a first batch of 3 on the same tree, cold: 70 to 79) | **87 to 89 ms** (first batch: 100 to 104) |
| Web, RTX, x1 (`d_arenaturn`; 3 runs Half, 1 Whole) | **84 to 107 ms** | **102 ms** |
| Web, the swap frame's wall (normal frames: median 6 to 10 ms, p95 11 to 21) | 103 to 128 ms | 124 ms |
| Same tree, PC at 87 to 100% load (the first version of this note) | native 96 to 116; web 156 to 195 | native 157 to 202; web 273 |
| The 2026-10-23 measure (quiet, web, 89b604de) | 38 to 42 ms RTX, 186 to 233 at x4 | not measured |
| Estimate on the laptop CPU (x4 to x5, the 10-23 ratio was 5; **an estimate, not measured**) | **0.25 to 0.4 s** from native, **0.35 to 0.5 s** from web | **0.35 to 0.5 s** |

**The 4x is killed; 2.2 to 2.8x on the web is real.** Load inflated my native numbers 1.7 times. Against October's quiet web figure the swap is 2.2 to 2.8 times dearer (84 to 107 against 38 to 42 ms). It is **7 to 13 times the 8 ms spike allowance** on this PC, and 8 to 15 dropped frames on the 30 fps laptop (estimate).

Per piece of the swap frame (`PlanetView.build_steps`, timers around each step; ms, best of 3 per frame, native / web RTX; the web column is 3 runs Half, 1 run Whole):

| Piece | Half native | Half web | Whole native | Whole web |
|---|---|---|---|---|
| Free the old copies' nodes, re-table the far rows (step 0; far rows alone 3.2 to 5.5 native, 5.0 web) | 10.6 | 20.3 | 14.0 | 20.9 |
| **Props query and props mesh** (`_make_props`, the sim's `matchProps` over the ring) | **14.6** | **19.4** | **28.7** | **33.0** |
| Cover layer (`cover.build`) | 4.3 | 5.6 | 8.8 | 9.9 |
| Ground field data (`ground.rebuild`) | 1.8 | 2.2 | 3.6 | 4.6 |
| Make the new copies' nodes (step 5) | 13.7 | 16.0 | 14.9 | 13.7 |
| **Force refresh** (every building and the crowd, `refresh(S, true)`) | 9.0 | 17.5 | 12.3 | 15.1 |
| Setup (materials, stub textures) | 1.1 | 1.5 | 1.6 | 1.5 |
| `t_build`, the whole | 56 | 83 | 85 | 99 |

- **Node churn** (the frees in step 0 and step 5) is about 20 ms native (35%) on a Half ring and about 31 ms on the web. The **data work** (props, cover, ground, far rows, refresh) is about 35 ms native (60%) and about 50 ms on the web. October's note put churn at 59% of 38 to 42 ms, about 24 ms: **churn has grown about a quarter to a third; the data work about threefold**. The props and cover layers (and the ground) double from Half to Whole; the churn does not.
- **Props are the largest single piece** (25 to 33% of the swap) and a sim function: a new ring's props are laid by `WorldGround.matchProps` over the whole ring, 17 to 25 ms native by itself (21 web).
- **It does not last**: the October measure found the 45 ticks after the cut equal to a match with no turn, and nothing here contradicts it.
- **Both levers are needed**: keep the copy nodes or build them ahead (churn, Rendering), and shrink the props, cover and refresh work (data, Rendering and World). Either alone leaves 35 to 50 ms.

Whole-ring probes, native quiet, one call each at tick 200 of a live match (the web build agrees within 20%): props query **17 to 25 ms**, `refresh(S, true)` **16 to 19**, the ground field's full rebuild **3.8 to 4.9** (ten in a row 38 to 49), the far rows **3.2 to 5.5**.

## 3. What would multiply under a bearing that changes continuously

Today's costs are paid by the few dozen columns a crater or a slide touches, in about 1.5% of frames (8% of frames in a fight that digs). A new bearing replaces **every column's ground**.

| Cost found in the deformation and launch work | Today | Under a bearing change |
|---|---|---|
| **Ground field data** (`g_gcol`, `g_shore`, `g_concat`, the set of a 403 KB texture) | 1.2 ms mean, 4.2 p95 on a dig frame (a few dozen columns); 3.8 to 4.9 ms for all 4,800 once (full rebuild, quiet) | **Every frame a bearing moves, the whole texture is rebuilt and sent**: the concatenation of 15 arrays alone is 0.25 to 0.9 ms a frame; the full rebuild is 3.8 to 4.9 ms a step. **about 4 times a dig frame's** |
| **The building sweep** (`p_visit`: re-foot every building whose ground moved) | 1.0 ms mean, 4.1 p95 on a dig frame (35 buildings); the force refresh (all buildings, the crowd) is **16 to 19 ms** (quiet) | The footing of every building changes with the ground: **the whole sweep, every step: 16 to 19 ms, about 15 times a dig frame's 1.2** |
| **Props** (`WorldGround.matchProps`) | a launch's local query 1.1 ms; re-queried only for columns whose broken props changed | A new ring has **different props everywhere**: the whole-ring query, **17 to 25 ms** a step (quiet; a window of 512 to 4,096 u round the fighters: 0.2 to 0.8 ms, 6 to 11 props) |
| **The launch planner's PROP SMASH flight** (13 ms native, planet only) | once a launch plan | Not multiplied by the bearing, but it **reads the ground as it is now**: a plan made while the ground is being replaced is made on the old one. Correctness is World's and Combat's; the cost is unchanged |
| **VFX** (`h_vfx`, `r_vfxlayer`: the biggest steady block, +4 to 6 ms on a dig or launch frame) | event-driven | Not multiplied: the bearing change raises no events. It adds nothing, but it also does not make room |
| **Camera speed in a fast launch** (`r_panhaze`, `r_cull`) | 0.1 ms | Not multiplied |
| **Sim ring reads** (World's 54 us a column native, 130 us web) | 16 to 32 columns a tick for 75 to 150 ticks, once per turn | A continuous change is a read every tick: at 0.2 ms the budget allows 4 columns a tick native, 1.5 on the web (section 1) |

So the deformation costs multiply (ground data, building footing, props); the fast-launch costs do not (they are event- and view-driven), apart from the two worst frames landing together if a bearing step is applied during a launch.

## 4. What it means for the idea

- **A step you can apply in a frame cannot be a rebuild.** The ground, the buildings' footing and the props would have to change in the shader or in small patches, not in data rebuilt and sent whole: the only bearing change the budget affords is a **crossfade done by the GPU** between two rings already resident (ground rows already uploaded, props for both), or **a rebuild behind a cut** (ADR 0010; at 60 to 100 ms it still drops 4 to 7 frames at 60 Hz and 8 to 15 at the laptop, a bearing change every few seconds is out).
- **Frequency**: with a 60 to 100 ms swap the budget allows a swap about once a minute (as World's `turn` data does: 4 a fight, 60 s apart). Faster needs the rebuild cut to a spike of 8 ms: node reuse (Rendering), props and footing patched for the columns that differ (World, Rendering), and the ring read hidden in idle ticks (World, Simulation).
- **First thing to build, if Orb wants it: a measurement, not a feature.** With the October split in (nodes kept), re-measure the swap (done 2026-10-31, section 2); the props query (17 to 25 ms native), the force refresh (16 to 19) and the node churn (20) are the pieces to attack first, and all are Rendering's, the props query World's.

## 5. Turntable budget (Orb's pick of E and E2, 2026-10-31)

The picture to cost: the world visibly swings round the fighters at up to **30°/s for about 3 s**: 90° in 180 ticks at 60 Hz, 0.5° a tick. The sim's fight line stays a strip (`x` wraps, 4,800 columns) re-laid from a resident 2D field (Research's E and E2, `research.md` sections 3 and 4). Numbers are x1 on this PC unless said; the laptop is x4 to x5 of them. Measured on HEAD e8a95e35, quiet (section 2); **estimates are marked.**

### 5.1 What a turn may spend

| Row | Per tick or frame | Over the 180 ticks |
|---|---|---|
| Render, added to each frame (average) | **0.5 to 1 ms**; p95 headroom about 2 ms in a quiet fight, none in a digging one (frame p95 6.1 to 7.0 ms against 8.3; 9.6 when digging) | 90 to 180 ms in all: **one to two swaps' worth** |
| Sim, added to each tick | **0.2 ms**: 1.5 ring-read columns a tick on the web (130 us a column), 4 native (54 us) | 36 ms: 270 columns web, 670 native |
| A one-frame spike | **8 ms** (one dropped laptop frame), and not on a frame that already spikes (a launch plan's 13 ms, a VFX burst) | a few, not every tick |
| No frame over | 50 ms on the laptop: on a 6 ms (24 ms at x4) frame, about 6 ms of added work at x1 | |

### 5.2 If every view column changes every tick

A swing that **re-lays the strip every tick** (new ground, props and footing for the columns in view) pays, per tick, native quiet:

| Piece | Cost per tick | Against the 0.5 to 1 ms allowance |
|---|---|---|
| Ground field data, rebuilt and sent (`ground.rebuild`; 403 KB texture) | **3.8 to 4.9 ms** | 4 to 10 times by itself |
| Props, a 2,048 u window round the fighters (`matchProps`; 6 to 11 props; 4,096 u: 0.8 ms) | 0.55 ms | the allowance |
| Buildings' footing, 35 to 54 in view (`p_visit`; the dig-frame mean per 35) | about 1.0 ms | the allowance |
| Sim re-lay of about 256 columns from the resident field (**estimate**: 1 to 2 us a bilinear sample in GDScript; not measured) | 0.3 to 0.5 ms | half the allowance |
| Far rows, only if the biomes under the far land change (3.2 to 5.5 ms whole; the far land already turns by a uniform) | 0 to 5.5 ms | |
| **Sum** | **5.5 to 7 ms; 9 to 12 with far rows** | **6 to 12 times** |

On the laptop (frame 6 ms x1 = 24 ms x4, plus 5.5 to 7 x4 = 22 to 28) that is a frame of **46 to 52 ms, about 20 fps, for the whole swing**; with the far rows it is over the 50 ms limit. Over 180 ticks the work is 1.0 to 1.3 s at x1: **ten to twenty swaps' worth in three seconds.** Re-laying every tick is out.

**What multiplies**: the ground data (it is 4 times a dig frame's 1.2 ms and every tick), the footing sweep (1 ms a tick against 8% of frames today) and the sim re-lay. The props window is cheap (it is not linear in the span: 0.2 ms for 512 u, 17 to 25 ms for the ring). **What does not**: VFX, camera speed and the launch plan, as in section 3.

**Reads for the field are driven by flight, not by the swing.** The same ground lies round the pair at any bearing, so a swing in place reads nothing new. Reads a tick are (speed / spacing) x (field width / spacing): at 100 u a tick over an 8,192 u field, 512 u nodes give 3.1 (Research's E2 measured 2.8 mean, 58 at p99), 128 u nodes 50 (E: 43 mean, 337 at p99), and strip-grade 8 u nodes 12,800. At 130 us a column that is E2: 0.36 ms mean (1.8 times the 0.2 ms), 7.5 ms at p99 (46 ms at x4); E: 5.6 ms mean, 44 ms at p99. **Only a coarse field (512 u or more, detail added on the GPU) or a field read ahead in idle ticks fits.**

### 5.3 A resident 2D height texture rotated by the camera (an ESTIMATE; no prototype exists)

On the Compatibility renderer (GLES3, and WebGL2 in the browser):

| Row | Estimate | Basis |
|---|---|---|
| Per tick of the swing, CPU | **about 0**: a rotation uniform and one transform. No rebuild, no upload, no footing sweep, no props query | the far land already turns by uniforms (`drift_tan`, `ring_c/u/v`, `far_map`); `r_cull` is 0.01 ms |
| Memory | about 2 MB: a near level of 512 x 512 R32F at 8 u (+-2 km) and a mid level at 64 u (+-16 km), 1 MB each; `far_map` already resident | arithmetic |
| A dig | the same as today: a sub-rectangle upload (`g_texupdate` 1 to 5 us, `g_setdata` 2 to 6 us measured) | measured, swap frame |
| GPU, ground vertex stage | one `texelFetch` becomes about 4 a level (a hand bilinear: float32 linear filtering is optional in WebGL2; R16F filters in hardware at 11-bit precision), up to 8 where two levels blend; the crater loop (2 fetches a crater) is unchanged. **+0.2 to 1 ms on the laptop's iGPU, LOW confidence** | no vertex count or GPU timer exists: about 10 of the web frame's 21 ms mean is outside every timer |
| Filling it | the reads of 5.2, which dwarf the texture's own cost | formula above |

What it does **not** remove: (1) every instanced layer (buildings, trees, props, cover, crowd, water, craters) is keyed on the strip's `x` and `S.base`, so it would have to live in planet coordinates (Research's "largest migration"; the footing and props costs are then paid once per object entering the disc, not per tick); (2) the sim's strip, still re-laid from the field each tick near the pair (the 0.3 to 0.5 ms above); (3) the band's depth rows, which exist only toward the camera: a rotated view needs near ground on every side.

Net: **a swing by rotating resident fields could cost the 0.3 to 0.5 ms of sim plus 0.2 to 1 ms of GPU a frame, inside the 0.5 to 1 ms allowance only if the GPU lands at the low end**, against 5.5 to 12 ms a tick for re-laying. The swing is affordable only that way; the open costs are the field's reads and the layers' migration.

### 5.4 What I would measure next (not done; each about 15 minutes)

1. A vertex-fetch microbench in the web build on the Radeon and the RTX: the ground's vertex stage at 1, 4 and 8 fetches. This turns the GPU row from a guess into a number.
2. A bilinear re-lay of 256 columns from a 512 x 512 field in GDScript, native and web, to replace the 0.3 to 0.5 ms estimate.
