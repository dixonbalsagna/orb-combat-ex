# Parked: a planet's load runs slices until 14 ms of a frame has gone

Simulation, by the EP's order, in Rendering's files (a grant: `render/core/sim_host.gd`, `render/core/look.gd`). From Performance's `docs/perf/page-load-2026-10-31.md`: 573 frames of one slice each, about 7 ms of engine, draw and browser a frame, 4.2 s of 11.3.

`load-pace.patch`: `SimHost.load_step` runs `load_job.step(SimRun.planetUnitsPerRead)` until `RenderLook.LOAD_STEP_MS` (14) has gone. A slice's size is unchanged. Where a slice stops changes no value: `field_load_check` and World's whole-against-stepped checks prove that of the job. Apply in a scratch export with `git -c core.autocrlf=false apply`, then copy.

**Proof:** UI's `load_check` 28 of 28; `open_check`, `pane_check` and `stage_check`, the gates that start a match through the host. The sim isn't touched, so the golden can't move.

**Not measured:** the gain. Performance's estimate is about -2.5 to -3 s on a cold web load, and it needs Performance's probe. With World's caches a warm load is about 74 steps, so warm gains little. A very long single slice (the ring's 0.85 s) isn't changed.

After it lands: delete this folder.
