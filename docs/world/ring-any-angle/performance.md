# A bearing change at any time: the performance budget (Performance and Platform, 2026-10-30)

For the EP's ask on Orb's idea (the fight's bearing changes dynamically, up to continuously). Written into this folder at the EP's request (the folder is World's; only this file is mine). Measured on 12966cf4 with the preview's switches and `?planet=7`, in a stage-timer scratch tree (`docs/perf/preview-deform-launch-2026-10-30.md` has the method); the machine was at 87 to 100% load, so the **native numbers are best-of-3 per frame** (a repeat is the same work) and the **web numbers are RTX, 1 to 2 runs, upper bounds**. Nothing here was built or changed.

## 1. The budget: what a change can spend on the laptop target

The laptop is a 30 fps machine (33.3 ms), stood in for by the dev PC's x4 CPU, which makes the whole frame **8.3 ms at p95 at x1** (budgets.md, ADR 0011). One dropped 30 fps frame on the laptop is **33 ms at x4, so 8 ms of added work at x1**. The hard limit is no frame over 50 ms.

| Row | Limit (x1) | Today, new planet, native best of 3 | So a change may add |
|---|---|---|---|
| Frame, p95 | 8.3 ms | AI match 6.1 to 7.0; a fight that digs 9.6 | **about 2 ms in a quiet fight, nothing in a digging one**. Web (load-skewed): script work p95 14 to 20 ms, no headroom |
| Frame, p99 | 12 ms | 8.5 to 10.5; 16.6 when digging | nothing |
| Sim tick | 0.4 mean, 1.0 p99 | 0.5 mean, 1.0 p95, 1.3 to 1.7 p99 | **nothing from the sim's average; a read of ~0.1 to 0.2 ms a tick on idle ticks at most** |
| Per-frame render add (average) | | | **at most 0.5 to 1 ms** (4 ms on the laptop CPU) |
| One-off spike (one frame) | 8 ms at x1, once in a while | | **8 ms**; beyond it the spike needs a cut's cover (ADR 0010: a hard cut, no dissolve) and then it still drops frames |

In the sim: World's ring read is 54 us a column (gen 2). At 0.2 ms a tick that is **about 4 columns a tick**, so a Half ring (2,400 columns) takes about 600 ticks (10 s) and a Whole ring twice that, to read a new bearing at a spend the budget can bear; today's warm reads 16 to 32 a tick (my timers: 0.19 ms mean and 5 to 10 ms at its worst tick native; 0.67 ms mean on the web build). A continuous bearing would be reading toward bearings in a queue, not at the rate the fight changes.

## 2. What today's swap really costs

The swap is **the render rebuild**; the sim's step is small (World's prepared swap: 4 to 5 ms on a Half ring in my runs, 9 to 17 on a Whole one, 2.5 in World's quiet read).

| Frame of the swap | Half ring (2,400) | Whole ring (4,800) |
|---|---|---|
| Native, best of 3 (`d_arenaturn` = the render rebuild) | **96 to 116 ms** (the whole advance 103 to 125) | **157 to 202 ms** |
| Web, RTX, x1 (the swap frame's wall; normal frames read 6 to 24 ms) | **156 to 195 ms** (two runs; a quiet run's normal frame read 6 ms) | 273 ms (one run) |
| The 2026-10-23 measure (quiet, web, 89b604de) | 38 to 42 ms RTX, 186 to 233 at x4 | not measured |
| Estimate on the laptop CPU (x4; the 10-23 ratio of x4 to x1 was 5) | **0.8 to 1 s** (not measured) | **1.4 s** (not measured) |

- **That is 12 to 25 times the 8 ms spike allowance, and about 4 times what it measured a week ago.** The rebuild (`PlanetView.build`, every pane) is about 90% of the swap frame's advance. Something grew since the 10-23 note; the likely cause is the props layer (`aa300177`: the sim's props drawn for the whole ring), which a whole-ring probe puts at **30 to 44 ms** by itself: native best of 3 / web RTX, whole-ring: props query 30 / 35 to 44, `refresh(S, true)` 28 / 33 to 46, the ground field's full rebuild 6.3 / 7.5 to 9, the far rows 6 / 8.5 to 12. That is about 70 ms of data work, and the rest of the 96 to 116 (about 30 to 45 ms) is node churn (freeing and making the copies' nodes), which was 59% of it in October; the data work is now the larger part. **A quiet-machine re-run is needed before anyone budgets on the 4x**; the ratio between the parts holds under load, the absolute milliseconds may not.
- **It does not last**: the October measure found the 45 ticks after the cut equal to a match with no turn, and nothing here contradicts it.
- **The October split is still the lever**: keep the copy nodes or build them ahead (Rendering), and nothing but that takes the swap near a spike allowance; on its own it is not enough (node churn is now the smaller part of 100+ ms).

## 3. What would multiply under a bearing that changes continuously

Today's costs are paid by the few dozen columns a crater or a slide touches, in about 1.5% of frames (8% of frames in a fight that digs). A new bearing replaces **every column's ground**.

| Cost found in the deformation and launch work | Today | Under a bearing change |
|---|---|---|
| **Ground field data** (`g_gcol`, `g_shore`, `g_concat`, the set of a 403 KB texture) | 1.2 ms mean, 4.2 p95 on a dig frame (a few dozen columns); 6.3 ms for all 4,800 once (full rebuild) | **Every frame a bearing moves, the whole texture is rebuilt and sent**: the concatenation of 15 arrays alone is 0.25 to 0.9 ms a frame; the full rebuild is 6.3 ms a step. **about 5 times a dig frame's** |
| **The building sweep** (`p_visit`: re-foot every building whose ground moved) | 1.0 ms mean, 4.1 p95 on a dig frame (35 buildings); the force refresh (all buildings, the crowd) is **28 ms** | The footing of every building changes with the ground: **the whole sweep, every step: 28 ms, about 23 times a dig frame's 1.2** |
| **Props** (`WorldGround.matchProps`) | a launch's local query 1.1 ms; re-queried only for columns whose broken props changed | A new ring has **different props everywhere**: the whole-ring query, **30 to 44 ms** a step |
| **The launch planner's PROP SMASH flight** (13 ms native, planet only) | once a launch plan | Not multiplied by the bearing, but it **reads the ground as it is now**: a plan made while the ground is being replaced is made on the old one. Correctness is World's and Combat's; the cost is unchanged |
| **VFX** (`h_vfx`, `r_vfxlayer`: the biggest steady block, +4 to 6 ms on a dig or launch frame) | event-driven | Not multiplied: the bearing change raises no events. It adds nothing, but it also does not make room |
| **Camera speed in a fast launch** (`r_panhaze`, `r_cull`) | 0.1 ms | Not multiplied |
| **Sim ring reads** (World's 54 us a column) | 16 to 32 columns a tick for 75 to 150 ticks, once per turn | A continuous change is a read every tick: at 0.2 ms the budget allows 4 columns a tick (section 1) |

So the deformation costs multiply (ground data, building footing, props); the fast-launch costs do not (they are event- and view-driven), apart from the two worst frames landing together if a bearing step is applied during a launch.

## 4. What it means for the idea

- **A step you can apply in a frame cannot be a rebuild.** The ground, the buildings' footing and the props would have to change in the shader or in small patches, not in data rebuilt and sent whole: the only bearing change the budget affords is a **crossfade done by the GPU** between two rings already resident (ground rows already uploaded, props for both), or **a rebuild behind a cut** (ADR 0010; at 100+ ms it still drops 3 to 6 frames at 60 Hz and 20+ at the laptop, a bearing change every few seconds is out).
- **Frequency**: with a 100+ ms swap the budget allows a swap about once a minute (as World's `turn` data does: 4 a fight, 60 s apart). Faster needs the rebuild cut to a spike of 8 ms: node reuse (Rendering), props and footing patched for the columns that differ (World, Rendering), and the ring read hidden in idle ticks (World, Simulation).
- **First thing to build, if Orb wants it: a measurement, not a feature.** With the October split in (nodes kept), re-measure the swap on a quiet machine; the props query (30 to 44 ms) and the force refresh (28 ms) are the two pieces to attack first, and both are Rendering's.
