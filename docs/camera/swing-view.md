# The camera in a swing: what's built (Camera, 2026-10-31)

Orb's order for the night: "a working version with the 3d world". The design is `docs/world/ring-any-angle/camera.md`; this page is what was built from it, in six parks, each off and byte-identical with the tile switch off. **It has run on Simulation's real frame and swing, and on Encounter's DirSwing in AI fights,** on a scratch stack. With `tiles=1` the camera's switches come on by themselves (park 6).

| Park | What | Needs |
| :--- | :--- | :--- |
| `swing-1-places` | The rig reads places through the sim's frame, and hands Rendering the frame | Nothing: off gen 3 `S.frame` is null |
| `swing-2-shot` | The swing's shot: low angle, lean, held size, stand-downs, motion setting, a correction's ease | |
| `swing-3-peak` | The upward launch's shot, the ladder and the meteor | A launch that earns it, a trail |
| `swing-4-sim` | `DirSwingRead`, by grant, with its `read` block in Encounter's `data/director/swing.json`. **Encounter calls it,** at Game Design's weight of 6 | Encounter's swing |
| `swing-5-real` | The real API, far buildings, Accessibility's rulings, UI's two words, `peakRate` in data | The first four |
| `swing-6-grant` | `main.gd` and `tile_ground.gd`, Rendering's: the switches and the shown heading | The tile park |

**One rate law, Simulation's** (the EP's ruling): my curve is now `SimSwing.at`, `SimSwing.mostFor` and `data/fight/swing.json`.

## 1. Places

`render/camera/cam_places.gd` is the one door. It's pure and holds no match state, and **it's the only camera file that names Simulation's API** (`docs/architecture/field-ground.md`). It finds `SimField` softly, so a park can land before or after it.

| Read | How |
| :--- | :--- |
| `S.frame` | `px, py, pz, tx, ty, tz, x0`. Null off gen 3, so the rig reads the strip as today, even with the switch on |
| `S.swing` | `active`, `cause`, `left` (signed degrees; above 0 turns toward the camera, as `CamPlaces.turned`: read on the real thing, off by 0.000°). Read on a swing's first tick only; after that the camera measures the frame |
| A building, at rest | `b.x`, `b.z` |
| A building, in a running swing | Its planet point, `S.bDir`. **The sim poses only those near the pivot until rest:** 173 of 263 were stale mid-swing in the check, and the door reads all of them exactly |
| A mark | Its strip `x` until it has a planet point. Give it an `anchor` and it reads through the frame with no rig change |
| Tall land | `SimField.placeAt` and `heightOf` on the bake, 16 points on two rings, at a swing's start and its shot's start only |
| Biome | `WorldBiomes.biomeAt`, which follows the frame on a field world. Only the landscape and angle shots read it, and both stand down in a swing |

| Rig read | Through the frame |
| :--- | :--- |
| The wreck's side (`_wreck_scan`): craters, buildings, slides | Distance along the view |
| The near tower (`_face_ahead`) | View distance and depth, with the building's round bound, since it stands at any angle |
| What a high angle shows (`_ground_shows`) | Craters and buildings; **scorch and cracks are left out once the line has turned,** being by the strip's columns |
| A landmark coming into the frame (`_scape_tick`) | In front of the plane isn't in frame; behind it, the frame's width grows with depth |
| Biome by the pair | `CamPlaces.biome` |
| The rig's six `groundY` reads | Unchanged: `groundY` reads through the frame itself (Simulation, section 8) |

## 2. The shot

The sim runs the turn and the camera measures it from the frame (`CamPlaces.turn_between`), so no camera timer can part from the sim. Numbers are `CamParams.SWING_*`.

- **A swing under 18 ticks is a jolt or a correction and gets no shot** (a 15° one is 7 to 11 ticks).
- **Longer:** pitch -4°, -6° with tall land near, in over 0.5 s; a lean of 0.04 of the width toward what's arriving, both fighters kept inside 0.42; out over 0.7 s after a 0.35 s hold on the rest.
- **The angle is the swing's own, `swing_angle`,** beside `_shot_pitch` rather than in it. Real fights showed why: another shot's ending zeroed it, 6° in a tick. With a shot's own low angle the lower of the two wins; a high angle adds.
- **Stand-downs:** no angle or landscape shot in a swing, or a landscape shot straight after. A strip closes with its wipe and none opens (Game Design's section 9, row 2).
- **Size:** no zoom in on a body in the air. With tall land near, no pull out.
- **Bank:** not built. The roll is off by default (`CAMERA_ROLL_ON`), so it waits on clip 7. Never under the setting.
- **A rollback's correction:** a turn over 5° in a tick stays out of the picture and eases away at no more than 60°/s, landing soft. Under the setting it holds until the next cut.

**Cuts instead of swings** (`docs/accessibility/swing-motion.md`): UI's `world_turning`, where auto follows Reduced motion, full turns, cut cuts. Any playback above 1x is cuts whatever it says (`SplitView.set_playback`; a replay viewer calls it).

| Swing | Under the setting |
| :--- | :--- |
| A launch | A plain cut on its release to where it ends, then held |
| A chase | The same, if 4 s have passed since the last cut (`SWING_CUT_GAP`). Otherwise held |
| Under 15°, or `small` | Never cut. Held, and folds into the next cut |
| A form's pause | Held, a cut at its end |
| A brawl's | Held. Past a standing fighter's foot limit (`r × 0.5 × angle > 10`) it waits for a hit-stop: **never a cut on its own** |
| A seek, a scrub, a join | `SplitRig.cut` snaps the heading |

A plain cut is `_cut_now` only. The rig still computes `SplitFrame.fade` on some other reduced-motion cuts, but nothing draws it: `SplitView.cut_dip` and `cut_dissolve` are off, since Orb's word of 2026-10-18.

## 3. The peak launch

Any steep launch where the view would widen by over 1.3 times, with the lower of the two tiers above 1. **It reads the flight, not a rule: the sim's send sets the height, and the width follows,** so the meteor and a lesser launch are one shot at different sizes. So it needs no event from the sim, and the rule that earns it stays Game Design's and Encounter's.

| Beat | What the camera does |
| :--- | :--- |
| Release | Nothing until the hit-stop ends. No whip, no solo, no cut. It takes the screen over 0.2 s from the framing that was there |
| Climb | The width follows at up to 3 e-folds a second, the rate up over 6 ticks. The launcher goes to 0.85 of the height |
| Last second | The launcher cranes to 0.6, so the planet comes up |
| Hang | Width at the ladder's top, settling |
| Descent | The frame follows him, and the launcher may leave it. Width down to 8,000 |
| Landing | Eases to 8,000 through a 0.5 s hold, then a 1.3 s return |

**Ends:** a landing (`down`, or under 60 units up), a brake (1.5 s), a catch (within 1,400 both ways, 0.6 s), a KO or finisher (0.5 s). **Under the motion setting:** a cut on release, still, a cut at the end. One frame all through; the trigger stands down until the return, so the normal split can open in the return.

**Ladder:** 4,200 (no shot), 8,000, 16,000, 53,000, scaled by the ring. Tier 4's 32,000 comes from its send's height, as Game Design has it. Height for height at other screen shapes.

**Numbers are in `CamParams`,** the camera's habit, except the zoom rate: `peakRate` in `data/camera/swing.json`, so a reading can lower it (Accessibility). The record says `peak_launch` while the shot has the screen, and UI's chips go off.

## 4. The read

**`DirSwingRead.read(S, quietS, swingS, turn)`:** -1 to +1, returns its terms for the feed; `text()` makes the line. `quietS` is DirSwing's to keep, since the read holds nothing. **Tall land forward reads along the line only** for now. **Weak spots:** `both_airborne` is true on 38 to 91% of AI ticks by seed, since these fights hover, and `anticipation` meets the rig's own 56% of the time, since the rig gates its tightening on more than the beat.

## 5. Calls I made

1. Everything of Simulation's is read in one file. No sim field added.
2. `swing_view` and `peak_launch` are separate switches, both set by `tiles` (park 6): the peak shot would run on today's ground, but its widest view needs the globe.
3. The peak shot reads the flight rather than asking for a sim event.
4. Landing on the width of 8,000, not the camera racing him down: the blast reads whole, and the launcher can leave the frame. So at impact, 13,200 units apart, only he is in frame.
5. The `flight` curve is off, so a real send takes 11.5 s of arc, not Game Design's 6.2 s. The shot's beats follow his state, so it fits either.
6. A form's hold under the motion setting has no foot limit, since nobody's feet move in a pause. A launch's and a chase's cut don't either; a chase where one lands first is still open.

## 6. What to run

```
godot --headless --path . --script res://render/camera/tests/swing_places_check.gd
godot --headless --path . --script res://render/camera/tests/swing_shot_check.gd
godot --headless --path . --script res://render/camera/tests/peak_shot_check.gd
godot --headless --path . --script res://render/camera/tests/swing_read_check.gd
```

Each ends on a verdict line. Off proof: `clip_digest` and `split_sweep` identical to HEAD.

## 7. What's been read

On a scratch stack of 20bfd69e, tile.diff 9c5cf23a (Rendering's fore tone), Encounter's 295f228b, and these parks.

| Read | Result |
| :--- | :--- |
| `clip_digest` (48,600 lines) and `split_sweep`, switches off | Identical to the stack without these parks |
| `determinism`, `seam_sweep`, `pane_check`, `flight_check`, `sky_check`, `validate` | Pass, 0 errors |
| `swing_real_check`, real `SimSwing` | 49 pass. Both signs, `left` off the frame by 0.000°, a real 90°: 60°/s, -4°, worst 0.2° a tick, no cuts |
| `swing_fight_check`, DirSwing on, 3 AI seeds | Pass. 4 to 9 swings in 2 minutes; the swing's angle at most 0.3° a tick |
| `peak_shot_check`, 6,600 u/s at 60° | Most width 52,490, landing 8,056, foe in frame 668 of 685 ticks, no split or cut |

## 8. Flash

**The tile ground's hard tones in front of the plane were the swing's flash, not buildings, the near line or the rate.** One export, each piece alone, first 300 ticks (the meteor 180), on the earlier tile cut, primary reading, limit 3:

| Clip | Tiles | Buildings hidden | At 30°/s or a zoom of 1.5 | One tone in front |
| :--- | ---: | ---: | ---: | ---: |
| Launch + 90° swing | 9 | 10.5 | 10 | 1.5 |
| Turn alone | 14.5 | 14.5 | | 1 |
| Launch only | 5 (today's ground 2) | | | 1.5 |
| Meteor | 8.5 (shot off 1.5; today's ground 1) | 6 | 7.5 | 1 |

A facet close to the lens moves fastest, by `z / (D − z)`, and its tone step turns a block of pixels at once: 13.8% of the frame in a tick. Pixel map: `img/swing/flash-turning-pixels.png`; stills: `img/swing/fore-tone-look.png`.

**Full clips with Rendering's fore tone, primary / area 15% lower / 2 s memory:**

| Clip | 960x540 normal | Reduced | 1024x768 normal | Reduced |
| :--- | ---: | ---: | ---: | ---: |
| Launch + 90° swing, staged, 420 ticks | 2.5 / 2.5 / 0.5 | 2.5 / 2.5 / 0.5 | 3 / 3 / 1.5 | 3 / 3 / 1.5 |
| Meteor, staged, 900 ticks | 1 / 1 / 1 | 1 / 1 / 1 | 1.5 / 2 / 0.5 | 1.5 / 2 / 1 |
| Turn alone, 420 ticks | 1 / 1 / 0.5 | | 2 / 2 / 0.5 | |
| Real AI fight, DirSwing on, 3,000 ticks | Seed 1: 5 / 5 / 4. Seed 2: 3.5 / 4 / 2.5 | | | |

Reduce flashing reads the same on the staged clips: its levers aren't on this path. **The fights fail, and the worst second isn't a swing's in seed 1.** No trail in any of these.

**Clips:** `img/swing/real-launch-swing.gif` and `real-brawl-swing.gif` are DirSwing's own, with presses and the swing at the edge; the small corner square is a search mark. `peak-staged-globe.gif` is staged by a scratch hook: no fight earns it yet, so its edge shows no press. `peak-staged.gif` is the same on today's ground.
