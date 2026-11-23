# 2026-10-30j: the crowd's cycles read the sim's tick (Rendering). UNFINISHED: do not land yet

`clock.diff`, sha1 4d411e58, cut on 12966cf4, on top of `2026-10-30i`. Paused by Orb's quiet time on 2026-10-30.

**What.** Tools found the wall-clock leak in flash captures: `crowd.gdshader` read `TIME`. It now reads `crowd_now`, which is `S.tick * SimConst.DT`, sent per pane by `PlanetView._send_crowd_clock` and reset when a match rebuilds the materials. `S.tick` runs through a hit-stop and an intro, as the wall clock did.

**Behaviour changes.** Crowds now hold in a real pause, where they kept moving before. Above 60 Hz they step at the tick rate rather than between ticks. The comment in `render/tools/flash_capture.gd` saying the crowd runs on the shader's clock is removed. `docs/tools/flash-check.md` line 216 says the same, and that's Tools' file, so it still needs changing.

**Measured:** collapse, seed 12345, 1500 frames, 1024x768, compared by bytes.
- Without the clock (d219a46c with the stack): two captures differ in 1224 frames.
- With the clock and the bend (12966cf4): three captures, 6, 5 and 3 frames differ between the pairs.
- An earlier clock-only build had one frame differ, frame 583: one pixel, by one level, outside the crowd band. The frames in the latest three captures haven't been looked at (137, 143, 1022, 1265, 1428, 1431, 1447 among them). So it isn't byte-identical across the clip yet, and the rest may be a different cause, not the crowd.

**Passed:** as in `2026-10-30i`; `pane_check` checks each pane's clock and that the shader holds no `TIME`.

**Not done.**
- Look at those frames' differing pixels: `scratchpad\ln\cr_px.mjs` on `scratchpad\ln\crcap\cb_a`, `cb_b`, `cb_c` in the session's scratchpad.
- Collapse clip in both modes on the final build: not run. A clock-only build read PASS 2 / 2.5 / 1 in both modes.
- A side-by-side of crowd frames.
