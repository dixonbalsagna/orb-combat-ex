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

**A bigger cut, not built:** sweep only the buildings within every pane's view each frame, and the rest a slice a frame. It needs each pane's camera in the planet, and a building out of view would wait up to a few frames for its people.
