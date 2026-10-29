# The view update on the gen 2 coast (Rendering, 2026-10-27)

Performance's coast layer-cut (`docs/perf/coast-layer-cut-2026-10-27.md`) found the x4 frame on the integrated Radeon held by the main thread: the view update was 8.3 ms a frame (1.3 at x1). This page says where that time goes, by owner, and what Rendering cut of its own.

## Where it goes

**Method.** Per-part timers (`docs/rendering/tools/prof-hook.mjs`) on a scratch web export with Performance's pb hooks; the frame bench on the gen 2 coast (planet 7, `--igpu --reduced --ticks 600`), at x1 and x4.

**The view at x4 (main's render and UI's advance; means, ms a frame):**

| Owner | ms | Parts |
| :--- | :--- | :--- |
| Rendering | about 4.2 | the fighter views' own work 1.0; the planet's update 1.25 (the sweep of every building 0.7, the trees 0.15); the sky 0.6; the chunk culling 0.37; occlusion 0.29; cues and the rest 0.6 |
| UI | 2.75 | `ui_hud.advance` 1.54, `UiSimBridge.patch` 1.22 |
| Animation | 1.2 | `RenderAnim.solve` |
| VFX | 0.54 | `vfx_layer.update` |
| Camera | 0.3 | `split_rig.frame`, the compositor's present |

**The tick's fx step** (outside the view; 7.5 ms at x4) is mostly the drain's listeners:
- `RenderAnim.consume`: 4.5 ms at x4. This is the incremental bake's slice, running through the measured window at x4 (p50 4.5) and mostly done at x1 (p50 0.1).
- Camera's `split_rig.step`: 1.1 ms.
- VFX's consume: 1.0 ms.

The EP routed the other owners' parts to them.

## Rendering's cuts (`PlanetView.view_fast`; main's `--noviewfast` for the A/B)

- **The building sweep** (`PlanetView.refresh`).
  - A building as it was last set is not set again: standing or fallen as before, the same floors, the same hit points while standing, not sinking, its ground unchanged.
  - Its height is what it was, because `WorldStructures.curH` reads only those and what generation fixed. Only its people are looked at.
- **The culling** (`cull_to`). A copy wholly on one side of the pane's line, whose chunks are all already on that side, is passed over.
- **Typed records.** The trees' and the buildings' records are read typed (`SimState.TreeState`, `SimState.Building`).

**Measured** on the coast at x4. Both runs were marked invalid by the frame bench: the machine was saturated by other sessions, at 59 to 77% load. They are upper bounds, read side by side:

| | Without | With |
| :--- | :--- | :--- |
| the building sweep | 1.09 ms | 0.78 ms |
| the culling | 0.39 ms | 0.26 ms |
| the planet's update | 1.63 ms | 1.32 ms |

At x1 the sweep goes from 0.16 to 0.14 ms.

**The look is unchanged.** The cuts skip only work whose result was already in place:
- the 19 render gates and `split_sweep` pass;
- the collapse and signature clips read the same as main in both modes;
- the collapse clip's frames differ from main's only as two runs of the same code differ from each other: a band of a few hundred pixels that the capture does not repeat byte for byte.

## The sweep by view (`PlanetView.pane_sweep`, 2026-10-29; main's `--nopanesweep` for the A/B)

Each frame the source planet's refresh visits only the buildings that can matter this frame, not every building on the planet.

**What is visited:**
- **What a pane can show.** Each pane hands in its view as soon as its camera is placed for the frame (`PaneWorld.render`, before the planet's update).
  - The view is the pane camera's frustum, cut to the depths the props stand at (`view_span`). It is a span of the planet's x, at any height.
  - A building counts when its x is within `_reach` of the span: the farthest any building's parts or figures' spots stand from its x, plus `RenderLook.SWEEP_PAD` (200 units: a figure's own size at the crowd's largest boost, and room to spare).
  - The first pane's view goes to its refresh (`see`). A second pane, and Camera's inset, draw after it: what they can show that the refresh did not visit is visited in their own draw (`see_more`), before anything is drawn.
  - A view that cannot be placed, or one that reaches round the planet, visits everything.
- **What this frame changed, wherever it stands:**
  - every building an event names (a floor hit, a brunt, a lodge, a stage, a fall, a pancake, people fleeing it or sheltering in it);
  - every building the sim's damage threw debris from (`WorldStructures.damageBuilding` throws it from the building's own x);
  - hits, sinks and drops under way, and buildings still owed figures (people on their way to shelter there);
  - the district flight while it runs (`WorldCollateral.tick` moves people every tick without an event for each): its buildings and its shelter, this frame's and the last's;
  - buildings on ground that changed (the ground's dirty columns).
- **A slice of the rest:** `RenderLook.SWEEP_SLICE` (16) a frame in turn. It is a safety net for a change that comes with no event; on the planets measured it passes over every building in about 8 frames.
- **Everything** on a build, when the sim's tick goes back, and after `unseen()`. A host that restores and re-runs the sim without draining the re-run's events to the planet calls `unseen()`. Online play does not draw yet; when it does, Netcode's restore calls it.

**What may wait.** Only a building out of every view whose people changed with no event, and only until the slice reaches it. In the check below no building out of view was ever behind.

**The proof** is `render/tools/sweep_check.gd`. A twin planet view sweeps every building every frame from the same match and the same events. After every frame, for every building in any pane's view, it compares:
- the last transform and colour written to each instance;
- the cut floors' and windows' texels;
- the drawn height, stage, top and footing, and the marks, spread, drop and sink;
- the figures at home;
- every runner, wherever it is.

Headless Godot keeps no MultiMesh data, so both views record what they write (`PlanetView.record_writes`, `RenderCrowdChunks.record`, tools only).

The check also tests the views with geometry of its own: a building whose parts or figures overlap a camera's frustum seen from above must be in that pane's view.

**Scenes:** the hand-made world with the pair set down by its tallest tower at tier 3 (the city comes down in view; its people flee and shelter), and gen 2's planet 7 as it plays. Both with the split attached, at 1 and at 4 ticks a frame, seeds 4 and 12345: every frame of 2,400 ticks each.

**Two failing controls** must fail, and do:
- the sweep cut to its slice (`ctl_slice_only`) gives thousands of differences in view;
- the props' depths narrowed gives buildings a camera sees that the view leaves out.

**Measured** on the gen 2 coast (planet 7, the pb scene, `--igpu --reduced --ticks 600`), 2026-10-29 at 40d5ee92 plus the sweep. The three builds are one export, switched by page words (`prof-hook.mjs` lets a scratch page set `noviewfast` and `nopanesweep`). Every run was marked INVALID by the frame bench: the machine was at 52 to 77% load from other sessions' batches. Read the rows side by side, as upper bounds. Means, ms a frame:

| | old (`noviewfast`, `nopanesweep`) | 27l (`nopanesweep`) | the sweep by view |
| :--- | :--- | :--- | :--- |
| buildings visited a frame | 122 | 122 | 22 |
| x1: the planet's update | 0.69 | 0.46 | 0.26 |
| x1: the building sweep (the refresh less the trees) | 0.52 | 0.30 | 0.09 |
| x4: the planet's update | 4.23 | 2.71 | 1.61 |
| x4: the building sweep | 3.02 | 1.66 | 0.56 |
| x4: the view hand-off (`pv_see`: the frustum's span) | | | 0.21 |
| x4: the view (p50) | 15.5 | 13.0 | 11.8 |

The sweep's cost now follows what is in view and what changed, not the planet: 22 visits a frame (16 of them the slice) against 122. Re-bench in a quiet window for numbers to quote.
