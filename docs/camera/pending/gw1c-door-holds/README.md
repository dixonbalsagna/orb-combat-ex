# Parked: the slam's door holds, and the merge goes on from the picture on the screen (gw1c-door-holds)

Camera, 2026-11-23. The EP's GW1c brief: the collapse clip's merge on the small and big planets fails the flash check in Reduce flashing. Cut on main 8e7d81d9 (GW1b landed). Records: `docs/camera/runs/8e7d81d9/gw1c-door-holds/`.

**Apply on main** (the GW1c stack touches no camera file): `git -c core.autocrlf=false apply gw1c-door-holds.patch` (sha1 233061fb, 160 lines). Two files, mine: `render/camera/split_rig.gd`, `render/camera/camera_params.gd`.

## What was wrong

The slam is the 12-frame door that shuts the rusher's pane over the other one, timed to the contact.

1. **Big: the door opened again in one tick (a fault, both modes).** A lock re-timed the rush, moving its end from 0.03 s away to 0.2 s away. The door's place was worked out from the rush's time left on every tick, so it went from 0.96 shut to wide open in one tick (pane 0 jumped 0.2 of the width). Then it shut a second time over 12 frames. That made two sweeps and a snap for one slam: big's worst second (ticks 992 to 1045).
2. **The merge drew a different picture (both modes).** When the door shuts over pane 0, the one view is always pane 0's, but the screen had been pane 1's. Pane 0's own camera took over at its own zoom (big: 0.51 against 0.60 on the screen, a step of a sixth of the picture). The display's in-between frames also blended pane 0's camera and the door from 0.97 shut to open, giving a half-and-half frame.
3. **Small: the rusher's pane scrolled into the door at 0.05 of the width a tick (Reduce flashing).** That is over the 0.03 the travel budget allows under Reduce flashing. The budget is built but switched off (Game Design's ruling of 2026-10-30, row 8).

**Not the camera: the scene's blast.** Rendering's "merge's cut" at 391/394 is the collapse scene's staged blast at ticks 390 and 393 (`_stage_collapse`, every 150 ticks from 90). It flattens the near forest in one frame (the top of the frame drops 30 to 50 levels). The camera holds still through it.

## The change

| What | Where | Mode |
| :--- | :--- | :--- |
| **The door holds.** Once begun, the door never opens again. If the rush's end moves later, the door waits where it is and shuts on the contact. `slam_door_holds` (on), `_slam_p` | `_slam_run` | both |
| **The handover.** When the door shuts with the rusher's pane holding the screen (`e >= SLAM_HEIR_E`, 0.9), pane 0 takes that pane's drawn camera and its filters' memory, so the one view goes on from the picture that was on the screen. The frame the display blends from is that picture too. A contact before the door had shut (both panes still on the screen) hands nothing over | `_slam_handover`, the frame after `_make_frame` | both |
| **The slam's budget.** Under Reduce flashing (or reduced motion), the travel budget's 0.03 holds while a slam (its lean and its door) moves the picture. It stays on until the drawn camera has caught up, so it lets go without a jump. It does not apply to an ordinary split's opening or closing: an escape must be followed (split_sweep's escape rows). `slam_budget` (on) | `_slam_budget_on`, `_travel_budget` | Reduce flashing only |

Normal mode gets only the first two (they mend a jump). The budget changes the default look (Reduce flashing is on by default), so the look gate applies. See below.

## Proof (`docs/camera/runs/8e7d81d9/gw1c-door-holds/`: readings.txt, gates.txt)

The collapse clip, worst of 4 readings (primary / area-15% / 2 s memory). h0 is the landing tree (main with GW1b + the GW1c stack, the cap's data row off); h1 is h0 with this park.

| Clip | h0 | h1 |
| :--- | :--- | :--- |
| small, reduced | FAIL 3 / 4 / 2 | **PASS 2.5 / 3 / 2** |
| big, reduced | OVER GATE 3 / 3 / 2 | **PASS 2.5 / 2.5 / 1.5** |
| small, normal | PASS 2 / 3 / 2 | PASS 2 / 3 / 2 |
| big, normal | PASS 2 / 2 / 1.5 | PASS 2 / 2 / 1.5 (1024x768: 2 to 1.5) |
| medium, reduced | PASS 2 / 2 / 1.5 | PASS 2 / 2 / 1.5 (one of its four readings 1 / 1 / 1.5 to 2 / 2 / 1) |
| medium, normal | PASS 1 / 1 / 1 | PASS 1 / 1 / 1 |

- **Small's merge window** (ticks 355 to 395): six alternating events become two. Its worst second is now at 859, outside the slam. The blast's pair at 391/395 is still there; it's the scene's (see above).
- **Gates, h0 and h1 alike, line for line:** every camera check and split_sweep, Rendering's 20 render gates, and the golden (same hash).
  - `own_pane_check` fails on both (launchai, ticks 3003 to 3018). That is the GW1c stack's, not this park's (reported to the EP separately).
- **Measured on the stack without Rendering's tile-marks fixes** (fix 2 shelved, fix 1 not parked), as the EP asked.

## The look gate (Reduce flashing is the default look)

Side-by-sides, base left and fix right, in `docs/camera/img/default-view-stack/gw1c-merge/` (ignored: fighters):
- `small-slam-reduced` (ticks 330 to 400): the slam's lean, door and catch-up;
- `big-door-reduced` and `big-door-normal` (1015 to 1060);
- `small-merge-normal` (360 to 390).

- **Small, reduced:** the rusher's pane pans into the door more slowly (at 362 the fix still shows the city where the base had reached the trees). The door shuts on the same framing, and the one view after it is nearly the same picture. Every move eased; no cut, fade, dissolve or blur.
- **Big:** the base's door snaps open in one tick and shuts again (1033 to 1045; in normal at 1024x768 the lower right of the frame jumps 16 to 23 levels a tick). The fix's door holds still and shuts once.
- **Small, normal:** the same picture to the merge tick, then under one level of mean difference (the handover).
- The sky still changes on the merge tick when pane 0's world takes over from pane 1's. Each pane keeps its own eased sky, which is Rendering's. It moved no reading here; noted for Rendering.

## Not decided here

- **The slam's budget changes the default look** (Reduce flashing). It is the travel budget's own rule, scoped to the slam. Game Design's ruling of 2026-10-30 (row 8) keeps the budget off unless its trip table calls for it. This is narrower than turning it on, but it is the budget, so it is the EP's call with Game Design, and Orb's taste through the look gate. `slam_budget = false` leaves the door fix alone; small then fails, and big passes.
- **The R_SPLIT question (due 2026-11-28)** doesn't touch this: the slam's door and budget act after the split has opened, whatever the split line is.
