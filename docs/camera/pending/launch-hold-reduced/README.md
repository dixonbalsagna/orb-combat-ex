# Parked: under Reduce flashing, a fast launch flight holds the frame (launch-hold-reduced)

Camera, 2026-11-14, the EP's decision (a) on the clash reading (records: `docs/camera/runs/611c1c2b/flash/`; reduced mode is the tester-safety mode).

**Apply after** A-CAMERA-01, Rendering's globe-default and crater-look-default, and cd04 (the GW1a look stack): `git -c core.autocrlf=false apply launch-hold-reduced.patch` (sha1 b9bff998). It lands after GW1a.

| File | What |
| :--- | :--- |
| `render/camera/split_rig.gd` (mine) | `launch_hold_reduced`: the launch rule (`launch_hold`, eager) runs while Reduce flashing is on (`_lh_on()`) |
| `data/camera/swing.json` (mine, granted) | `pieces.launchHoldReduced`: true |
| `tools/schemas/camera-swing.schema.json` (Tools' grant) | the key |
| `render/core/main.gd` (Rendering's grant) | one line in the camera block |

## What it does

It runs the existing launch rule, built and checked earlier but off in shipped play. Under Reduce flashing only:
- **The hold.** When a launched fighter's flight is fast (the eager thresholds, `LH_ENGAGE_W_REDUCED`, `LH_BIG_REDUCED`), his pane holds its frame instead of streaming the scenery past.
- **The catch-up.** When he lands or slows, one catch-up cut takes the pane to him if he's far from the frame. The cut asks the flash register (cd04). Refused, it's an eased whip instead.
- **What it leaves alone:**
  - a flight high over the sky, and one through buildings: the follow takes those, as the rule always did;
  - normal play.
- No fade, no dissolve.

## Proof

| Run | Result |
| :--- | :--- |
| Clash, reduced, the two flight stretches (native, the same sim as the pixel clip; `clash-steps.txt`) | ticks over 0.045 of the width a tick: **93 to 20** (158 to 246) and **57 to 1** (1087 to 1125); two catch-up cuts, both granted |
| Every camera check, with this piece and launch-wide forced on (`docs/camera/runs/611c1c2b/launch-parks/gates.txt`) | all pass, cut_register_check 73 included. split_sweep's two rally rows tie (see launch-wide's README) |
| **The pixel reading** | **Owed:** read in the EP's next quiet window, clash both modes on the stack with both parks |
