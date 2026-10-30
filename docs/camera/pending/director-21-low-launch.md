# director-21: the launch chase low over open ground (parked)

Camera, 2026-10-28, from the EP's signature-clip brief. **The failure is not a cut.** Tools' signature clip (seed 12345) has two fast launches that skim the desert:
- **Tick 70:** 15,062 u/s. It opens the split.
- **Tick 603:** 10,240 u/s. The one view's launch shot follows it.

The rig makes no cut at either: no line sets `_cut_now` between ticks 600 and 630. The launch shot chases the body at his own speed, about 170 units a tick, roughly 0.16 of the width. That is the design since 2026-10-19 (director.md step 4a: `launch_governor` off, so the body is chased at fight size and the background carries the speed). A body low over the ground is framed on the ground under him (`LOW_AIR_DEAD`), so at that speed the camera's height also follows each dune (138 to -51 and back over ticks 612 to 620). The near ground streams past and swaps tone across about 60k pixels a tick.

`director-21-low-launch.patch` applies to c5e94322 (render/camera/split_rig.gd and camera_params.gd). It adds two switches, both on in the patch. Neither acts while a rally is live, so the rally keeps its own framing:
- `launch_ground_ease`: a low chase frames on the ground height under him eased (`LOW_GROUND_TAU` 0.25 s), never above him.
- `launch_low_gov`: the scroll governor on a launched body only while he is low (his weight under `LOW_AIR_DEAD` x 1.5), floor `LAUNCH_FLOOR`. High flights stay at fight size.
- **The rally exemption** (the EP, 2026-10-28): a rally is live from a `rally_link` cue to `rally_end`, or RALLY_GAP after the landing. This is read from Encounter's cues whatever `rally_framing` says, so the rally rows' framing-off arm is untouched too.

## The rows (check-clip; primary / area-15% / 2 s memory)

| Build | signature-normal | signature-reduced | collapse-normal | collapse-reduced |
| :--- | :--- | :--- | :--- | :--- |
| main c5e94322 | 3.5 / 5 / 3 FAIL | 2.5 / 3 / 2 PASS | | |
| V1: ease only | 3 / 4.5 / 3 FAIL | 3 / 3 / 2.5 OVER GATE | | |
| V2: ease and low governor | 2.5 / 3 / 2.5 PASS | 2 / 2 / 2.5 PASS | 2 / 2.5 / 1 PASS | 2 / 2.5 / 2 PASS |
| **V4: V2 with the rally exempt (the patch, 2026-10-28)** | **2.5 / 3 / 2.5 PASS** | **2 / 2 / 2.5 PASS** | 2 / 2.5 / 1 PASS | 2 / 2.5 / 2 PASS |
| V3: low governor only | 2.5 / 3.5 / 2 FAIL | 2.5 / 3 / 2 PASS | 2 / 2.5 / 1 PASS | 2 / 2.5 / 1 PASS |

- **Where the readings fall:**
  - main's normal primary 3.5 is at tick 71, the opening launch, and its memory 3 is at 609;
  - V2's reduced memory 2.5 is at ticks 133 to 144, also the opening launch.
- **V2 changes both low launches**, ticks 81 to 314 and 604 onward; nothing else in the clip (camera digests, both modes). Normal passes only because both are changed.
- **Not met:** reduced's 2 s memory is 2.5 against the brief's 2 (its primary and area are better than main's).

## Costs

- **The body is smaller while he skims.** At ticks 603 to 624 the zoom eases from 1.21 to 0.66, so he is drawn at about 60% of main's size at the low point, then back by tick 680. Peak scroll is about 138 px a tick, against main's 198. This goes against step 4a's "chased at fight size" for low flights only. That is Orb's call. Side-by-side: `docs/camera/img/low-launch/low-launch-sig-600-680.gif`.
- **split_sweep passes with the patch on (V4).** Its rally lines are byte-identical to main's. (V2, without the exemption, failed 6 rally checks by one tick: the governor improved the rows' framing-off arm.) With the switches off, the patch changes nothing by construction (the new state is written but not read). That case was not run.

Proof run: the signature clip in both modes on main, V1, V2, V3 and V4; collapse in both modes on V2, V3 and V4; split_sweep on V2, V4 and main; camera digests main against V2. The 19 render gates and determinism were not run.
