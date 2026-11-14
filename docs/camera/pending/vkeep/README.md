# Parked: the one view keeps both fighters in height (vkeep)

Camera, 2026-11-07, for the EP's chase_rush_check fails on a8bc66e2. There are three, all "the view flapped": the energy model at base, seed 1, at 0 and 8 after the send, and at shares 0.7 and 0.0.

**Apply on main** (cut on a8bc66e2; `git apply --check --cached` passes on 808a83ab): `git -c core.autocrlf=false apply vkeep.patch` (sha1 246e9415).
- Files: `render/camera/split_rig.gd` and `render/camera/camera_params.gd`, both mine.
- The two-fighter ratchet is unchanged (365).

## Whose it is

**The camera's, and it's old.**
- The three cases fail the same way on the batch's parent ef4ca0b1, on 85884449 and on d5582dbd.
- They are the energy-model rows. The check runs them only when `data/fight/power.json` exists, and it landed in d5582dbd (power-core). So they've failed since they existed. On 3c9005ac the check has 40 cases, all passing.
- Neither the morning batch nor my travel-point or cross-ko parks caused it: with split_rig and camera_params set back to ef4ca0b1's, the batch still fails the same 3.
- Orb's build doesn't meet these cases: the energy model is off there (`power.json` "enabled": false; on only with the page's `?power=1`). The one-view framing this fixes is in every build, though (the look clip below is an ordinary AI match).

## The cause

The one view puts the pair's midpoint at 0.7 of the height (`PLANE_Y`). Its zoom fits the pair as if they were centred, and it is often held closer than the fit (the readable size, a push). So a pair far apart in height put the lower fighter low in the frame.

In the case:
- The rival is sent up and the player rides up with him: the split opens (out of frame).
- The rival is turned down and away. The split closes at tick 74 and the view is one picture by 105, with the zoom on the readable floor.
- He lands at 119, 458 units across and 334 below. The one view had him at 0.93 of the height, a hair from 0.96, where the split opens at once.
- At 124 he settles 39 units, the edge is crossed, and the split opens: one picture for 19 ticks, under the check's 30.

## The fix

At the end of the one view's target (`_merged_target`, straight on), both fighters' chests are kept between `VKEEP_TOP` (0.08) and `VKEEP_BOT` (0.88) of the height. If they can't both fit, they are centred.
- It's a target, so it moves only as they move, and the camera eases to it as it always does: no cut and no snap.
- It changes nothing while both are inside the band, which is almost all the time.
- A switch (`vkeep`, on), so it can be turned off for a comparison.

## Proof

| Run | Result |
| :--- | :--- |
| `chase_rush_check` | **130 of 130** (main: 3 fail) |
| `split_sweep` | passes |
| `cross_ko_check` | 21 of 21 |
| `launch_shots_check` 635, `peak_shot_check` 24, `peak_retry_check` 1, `split_vision_check` 11, `split_share_check` 26, `swing_places_check` 33, `swing_read_check` 14,420, `swing_real_check` 48, `swing_shot_check` 164 | all pass |
| `flight_shots_check` | 1 of 521 fails, the same on main without the park (close brawl, a 0.237 jolt at tick 2048 in a launch follow). Not this park's; reported |
| `clip_digest`, 1v1 | **changes 537 of 48,600 frames**: ai seed 38 ticks 731 to 842 and 2032 to 2181 (both modes), and signaturecity ticks 616 to 632 (reduced). Expected: those are the frames where the lower fighter sat below 0.88 |
| Flash register, the park, every tick of each changed span, both modes | **PASS**: ai 700 to 880, 1 / 1; ai 2000 to 2200, 1 / 2.5; signaturecity 590 to 670, 0.5 / 0.5 |

## Look gate

`docs/camera/img/vkeep/`: main on the left (blue bar), the park on the right (orange). The web build through the capture hook, HUD off, default world.

The files:
- `vkeep-ai-a.gif`: ai seed 38, ticks 721 to 820.
- `vkeep-ai-b.gif`: ai seed 38, ticks 2021 to 2110.
- Stills `t00760.jpg`, `t00784.jpg`, `t02054.jpg`, `t00618.jpg` (signaturecity, reduced).

What they show:
- **760 and 784:** the AI's beam goes down at the rival. Main has the beam's target off the bottom of the screen. The park has both fighters, the target low in the frame and in view.
- **2054:** the lower fighter, at the bottom edge on main, sits a little higher on the park.
- **618:** a small shift during the split's opening.
- No cut, no fade, nothing over the fighters.

## RISKS

- Under a pitched camera (`_pitch_now` not 0) the keep isn't applied: the pitch's own placement runs instead. The case and the clips are straight on.
- A pair taller than the band can hold is centred, so both reach the edges together instead of only the lower one. The split still opens on its own rules.

## With the energy model on (Sunday's page default), 2026-11-07 night

The EP asked for this ahead of Sunday: with the energy model on, the view mustn't flap. vkeep is the fix (the three energy-model rows of chase_rush_check were the flaps it was made for). No new park is needed.
- **Gates** (`docs/camera/runs/b34e32e1/sunday-energy/`, on main b34e32e1 + vkeep + land-release):
  - chase_rush_check 130/130 (its rows with the model off and on); main alone fails 3;
  - flight_shots 778, launch_shots 1,029, split_sweep, cross_ko 21, peak_shot 24, peak_retry 1, split_vision 11, split_share 26, swing_shot 164, swing_places 33, swing_real 48 and swing_read 14,420 all pass.
- **Look** (`docs/camera/img/vkeep-energy/`): a real AI match on the web build with `power=1`, seed 38 (main left, blue bar; vkeep right, orange).
  - `vkeep-energy-ai38.gif`: ticks 704 to 980, every 6th.
  - Stills 788, 848, 902.
  - At 788 the AI's beam goes down at the rival: main has the fighter firing it off the bottom of the screen, vkeep has both.
  - At 848 main has opened the split; vkeep holds one view of both.
  - No cut, nothing over the fighters.
  - Where the builds differ: `real-match-diff.txt`. Seed 38, ticks 734 to 1208; seed 4 never differs.
