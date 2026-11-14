# Two of my checks on the GW1a stack (flash_reg_check, flight_check): check parks for GW1a

Rendering, 2026-11-14, at the EP's word, ahead of the queue. Simulation attributed both on the GW1a stack (main + every GW1a park, the EP's scratch tree s422). I ran them on a copy.

## 1. flash_reg_check, two camera rows: re-read (`flashreg_settle.diff`, sha1 83860a10, 47 lines, `render/tools/flash_reg_check.gd`)

They pass without Simulation's `data-fight-gw1a` and fail with it. Both read the camera in a match's first frames, and GW1a's opening (the 9 November switches: kick, brake, slip, budget) pulls the zoom faster than their 5% in a frame:
- **the scale row:** the register got 0.48 (the camera at the frame's interpolation point) against the tick's camera at 0.4766 (× 768 / 720 = 0.51);
- **the depth row:** the register's distance, a frame old, was 2,819 against 2,650 this frame.

The code is right; the rows measured too early. The re-read:
- **`_settle`:** step one tick a frame until the zoom moves less than 0.2% in a frame (at most 240 frames), then read.
- **The scale row:** a frame consumes its tick's events, where the register takes the scale, before its render sets this frame's scale. So the register holds the scale the frame before set. The row notes that value and checks the register holds exactly it one frame later; it used to compare against the current value, which only matched while the camera stood still.

Result: 34 of 34 rows pass on the GW1a stack and on main + `look-recut/` (without GW1a's data).

## 2. flight_check: a fix (`flight_zone.diff`, sha1 4bde6a95, 11 lines, `render/core/planet_view.gd`)

It fails both ways, so it predates the grant. With it, 20 rows: building 239 shows 5 standing with 4 people. Without, building 236 shows 1 standing with 0 people.

- **The cause:** the sim's gradual flight (`WorldCollateral`, near the heavy fighting) lowers a building's people by fractions every tick, and sends its event only once a lot has gathered. The planet view re-reads those buildings through the sweep's flight zone. That zone was read through `_along`, the sweep's index of each building's x at build. On a field world that doesn't follow the swing's pose (`S.bX`), so after the line swung, the view stopped re-reading buildings the sim was emptying.
- I noted on 6 November that the zone still used `_along` when I moved the startle to `_near_x`; GW1a's data (its scatter radius, its swings) brings it out.
- **The fix:** the zone reads `_near_x`, the poses as the sim has them. One line. It isn't World's people: World's numbers are right, and the view read the wrong buildings.
- **Result:** `flight_check` passes on the GW1a stack and on main + `look-recut/`.

## 3. sweep_check's control A: re-read (`sweep_ctl.diff`, sha1 1460a871, 39 lines, `render/tools/sweep_check.gd`), found by this park's own gate run

On the GW1a stack, control A fails before any park of mine too (checked with the flight-zone line taken out).
- Control A cuts the sweep to its slice and must find what that misses, so it needs a match whose buildings change.
- Under GW1a's fight data, the city at tier 3 on seed 4 changes no building in 1,800 ticks.
- **The re-read:** it tries a further seed at a time, up to six, until one has something to miss. A seed with nothing prints a "note", and only the last can fail.
- **Result:** on the GW1a stack seeds 4 and 5 have nothing, and seed 6 finds 186 differences; on main + `look-recut/`, seed 4 finds them as before. `sweep_check` passes on both.

## Proof

On the GW1a stack with the first two (`docs/rendering/runs/809e93e5/gw1a-checks.txt`):
- `golden.json` is byte-identical to the stack's own;
- the tile, lake water, cover water and ground checks pass; `sweep_check` passes with the third (the same record);
- the render gates pass 19 of 20, with `flash_reg_check` and `flight_check` passing.

The one that fails is Camera's `split_sweep`, the energy-on failure already routed to Camera (`docs/rendering/runs/611c1c2b/split-sweep-energy-on.txt`).
