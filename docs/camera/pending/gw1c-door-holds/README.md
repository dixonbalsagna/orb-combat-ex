# Parked: the slam's door holds, and the merge goes on from the picture on the screen (gw1c-door-holds)

Camera. First cut 2026-11-23; **re-cut 2026-11-25 to parts 1 and 2 only.** The EP's call: part 3, the slam-only travel budget under Reduce flashing, is off. It failed Game Design's condition 1 (`docs/design/rulings-2026-10-30f.md`): 73 extra out-of-pane ticks on small's collapse clip at 1024x768. A re-test with a bounded catch-up and a per-pane yield still had 32, and small went back to OVER GATE 3. So small stays held, and this park brings big back in its own window after GW1c.

**Apply on main or the GW1c stack** (the stack's camera piece, gw1c-keep-human-vertical, applies before or after it): `git -c core.autocrlf=false apply gw1c-door-holds.patch` (sha1 fba137e3, 124 lines). Two files, mine: `render/camera/split_rig.gd`, `render/camera/camera_params.gd`. Records: `docs/camera/runs/54474b97/gw1c-door-holds-12/` (this cut) and `docs/camera/runs/8e7d81d9/gw1c-door-holds/` (the first cut, with part 3).

## What was wrong

The slam is the 12-frame door that shuts the rusher's pane over the other one, timed to the contact.

1. **The door opened again in one tick (a fault, both modes).** On big, a lock re-timed the rush, moving its end from 0.03 s away to 0.2 s away. The door's place was worked out from the rush's time left on every tick, so it went from 0.96 shut to wide open in one tick (pane 0 jumped 0.2 of the width). Then it shut a second time over 12 frames: two sweeps and a snap for one slam. That was big's worst second.
2. **The merge drew a different picture (both modes).** When the door shuts over pane 0, the one view is always pane 0's, but the screen had been pane 1's. Pane 0 took over at its own zoom (big: 0.51 against the 0.60 on the screen, a step of a sixth of the picture). The display's in-between frames also blended the two cameras and the door from 0.97 shut to open: a half-and-half frame.

## The change

| What | Where |
| :--- | :--- |
| **The door holds.** Once begun, the door never opens again. If the rush's end moves later, the door waits where it is and shuts on the contact. `slam_door_holds` (on), `_slam_p` | `_slam_run` |
| **The handover.** When the door shuts with the rusher's pane holding the screen (`e >= SLAM_HEIR_E`, 0.9), pane 0 takes that pane's drawn camera and its filters' memory, so the one view goes on from the picture that was on the screen. The frame the display blends from is that picture too. A contact before the door had shut (both panes still on the screen) hands nothing over | `_slam_handover`, the frame after `_make_frame` |

Both modes. No travel budget anywhere in it.

## Proof (this cut; `docs/camera/runs/54474b97/gw1c-door-holds-12/`)

On k0, main 54474b97 with the GW1c stack's 28 pieces (World's bury fix and gw1c-keep-human-vertical in; the cap's data row off), against k1, k0 with this park. The collapse clip, worst of 4 (primary / area-15% / 2 s memory):

| Clip | k0 | k1 |
| :--- | :--- | :--- |
| big, reduced | OVER GATE 3 / 3 / 2 | **PASS 2.5 / 2.5 / 1.5** |
| big, normal | PASS 2 / 2 / 1.5 | PASS 2 / 2 / 1.5 |
| small, reduced | (held) | FAIL 3 / 4 / 2: small stays held |

The gates (every camera check and split_sweep, Rendering's 20 render gates, the golden) and medium are in `gates.txt`.

## The look

Side-by-sides from the first cut: `big-door-reduced`, `big-door-normal` and `small-merge-normal` in `docs/camera/img/default-view-stack/gw1c-merge/` (ignored: fighters). Those parts of the code are unchanged here.
- **Big:** the base's door snaps open in one tick and shuts again (in normal at 1024x768 the lower right of the frame jumps 16 to 23 levels a tick). The fix's door holds still and shuts once.
- **The merge:** the one view goes on from the picture on the screen, with no zoom step. Every move eased; no cut, fade, dissolve or blur.

## Not the camera, still open

- **The collapse scene's blast at 390/393** flattens the near forest in one frame. This was Rendering's "merge's cut".
- **The sky changes on the merge tick.** Each pane keeps its own eased sky, which is Rendering's.
