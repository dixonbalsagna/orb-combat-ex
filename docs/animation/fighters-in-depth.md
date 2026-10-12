# Fighters in depth: what the bodies need at an angle (Animation's side)

Owner: Animation. Date: 2026-10-12. Brief (the EP): read `docs/design/depth.md`, `docs/rendering/fighters-in-depth.md` and `docs/camera/city-in-depth.md` section 6; say what the pair's poses need at an angle, design the sidestep in depth (15 ticks; a step round him, not a slide), and say what a fighter sliding along a building's face or going up and over a corner should look like. **Paper first, then what is safe and inert with depth off, built in scratch and parked.** Render only; the gameplay hash is untouched. Every number is a first value. Headless only.

## 0. In short

- At the line's real angles (10 to 30 degrees) **the ground barely shows it** (Rendering: 6 pixels between the feet, 3 percent between the sizes). So **the bodies must carry it**: each turned toward the other's depth, so a fight at 20 degrees reads as two bodies facing along a line and not as two cut-outs on a street that happen to be at different heights.
- Three things change in the pose, and only three: **where the body faces** (a yaw, built), **where the feet find the ground** (each at his own depth, built) and **how far a hand must reach** (the distance in three axes, built).
- The sidestep is a **crossover step with the body turning through it**: two footfalls in 15 ticks, the hips going over each foot, the yaw swinging to the new line. The step layer that does it by distance moved is built and also serves a drift and a slide.
- A fighter pressed along a face **shuffles** (a sidle, cadence by speed, a lean into the face and no recoil): "a face gives no bonus" must also be true of the body. Going up and over a corner is a **flight** (a pitched body, a hand on the edge at the crest): paper only, it needs a read from the sim.
- With depth off every new field is 0 and nothing is posed: the picture is today's, bit for bit (`_test_depth`).

## 1. What the pair's poses need at an angle

The rig is a true 3D skeleton in the model's space, facing +x, put on the plane by Rendering. Every pose, sequence and blow in the library was authored and checked **side-on**. At an angle three assumptions break.

### 1.1 Facing

| Question | Answer |
| :--- | :--- |
| What turns | The whole body about the vertical, toward the rival's depth: `AnimFighter.depth_yaw`, radians, **positive turns his front toward the camera** (z is positive toward it). The two fighters get opposite signs. |
| How much | `atan2(dz, |dx|)`, the line's angle to the street, **capped at 0.6 rad (34 degrees)** (the sim's cap is 30), and **faded to 0 as the pair part along the street**: full inside 300 units, none past 700 (a far fighter is not looking at a depth he cannot reach). |
| How fast | Eased with a time constant of 0.12 s: a line that turns (a sidestep) turns the bodies with it, and a jittered line does not shake them. |
| When not | Launched, dropped or down: the sim's own rotation (`rot`, `spin`) owns the body there; the yaw is 0. |
| Who applies it | **Rendering**, by `AnimBody.set_yaw(depth_yaw)` each frame (built here: rotation about y, sign handled; a body Rendering faces left by a half turn needs `-depth_yaw`, from `AnimFighter.vface`). I do not turn the body in the solve: the bones are in model space and the mesh, the keyline and the hybrid projection's anchor turn with the node. |

Why a body turn and not a camera trick: two bodies turned 20 degrees toward each other show their chests a little to the camera and the far one's shoulder behind the near one's. That is what tells the eye the near one is nearer. The hybrid projection keeps the plane's scale, so a turned body's reach on screen is its true reach times cos of the turn (0.94 at 20 degrees): the side-on poses stay readable at every angle the line may take, and at the cap (30 degrees, cos 0.87) a straight punch is 13 percent shorter on screen than in the plane. That is the honest price of the angle, and it is the right sign: a fight in depth is a little smaller across the street, which is what the pair is.

### 1.2 Foot planting

- **Each fighter's feet stand on the ground at his own depth.** All 17 ground reads in the solve (`WorldTerrain.groundY(S, x, ...)`) now pass the fighter's own `z` (and the rival's, where a blow's target is on the ground). With depth off `z` is 0 and the call is the plane's, as before.
- **The sim has eight rows of ground across the band; the renderer's ground field does not read them yet** (Rendering's table, section 3: "the ground at depth"). Where a crater lies in depth the feet will follow the row and the drawn ground will not. That is Rendering's, and it is the one place an animation fix cannot hide a seam.
- The footfall's own lock and slip reads (the heel/toe and slide guard, `ground_feet`) work in the fighter's own frame and need nothing for depth.

### 1.3 Reach and contact when the two are not side by side

- A blow is "reach the rival's region" by the contact IK. At 90 units apart on a line of 20 degrees the two stand 33 units apart in depth, so the true distance is 96 and the plane's is 90.
- **Built:** with depth on, the contact IK takes the **three-axis distance** to the target (`sqrt(dx^2 + dz^2)`, with the street's sign), so a body turned along the line reaches along its own front and the hand lands on the region, not at the plane's shadow of it. With depth off the line is not taken and the number is the plane's, exactly.
- **What this does not do:** the sim's contact offset is 58 units in x only and reads nothing of z. A fight at the cap has the hands meet where the sim says the blow lands in x; the extra 5 to 15 units of depth are in the bodies' turn and in the arms' length, never in a different hit. That is right: the animation is not allowed to make a hit land or miss.
- **Hit reactions** are authored side-on and applied to a body already turned: a flung head goes along the body's own front, which is within 30 degrees of the street. Nothing to do. A launch's own direction is the sim's.

### 1.4 Overlap and who is in front

The depth buffer sorts the bodies (Rendering's table, section 2). The nearer fighter's back and shoulder will cover the farther one's chest in a close exchange at 25 to 30 degrees: that is the point of the angle, and it needs a rule for the far fighter's hands (they must not vanish behind the near fighter's body for a whole blow). That is **Camera's** to look at, not a pose's: the camera's dolly to the pair's depth, and at the cap the pair's split. I would see it in the clip before asking for anything.

## 2. The sidestep in depth: 15 ticks, a step round him

**What it is in the sim** (depth.md): a dodge with no direction, 1 bh (75 units) in depth over the dodge's own 15 ticks, the line turning to 20 degrees with him on that side. The director picks the side with more room. The motion is the sim's; the body only has to say what the sim did.

**What it must not look like:** a slide. A body that changes depth with its feet flat and parallel is a cut-out dragged across the street, and at 5 units a tick it is also fast enough that the eye catches it.

**What it is drawn as, in 15 ticks** (a step round him, not away from him):

| Ticks | Body | Why it reads |
| ---: | :--- | :--- |
| 0 to 2 | The near foot unweights, the hips drop 5 and shift over the far foot | The step is *started by the body*, not the ground moving |
| 2 to 8 | The near foot lifts and **crosses in front of the far one**, the hips going over it; the yaw swings toward the new line | A crossover is how a person sidesteps while facing something; a shuffle with no cross is a slide |
| 8 to 13 | The far foot catches up wide, the hips low between the feet | The second footfall: two feet, two landings, a step and not a glide |
| 13 to 15 | The body settles on the new line, guard as it was | The bodies' turn is already at the new angle: it has not snapped |

- **The yaw does half the work.** The body turns from the street to the line's new angle across the step (0.12 s ease, so most of it lands by tick 8): the sidestep reads as a body going round, and the slope the ground cannot show is in the shoulders.
- **The arms stay the guard.** The step is legs, pelvis and a little spine (the `dp.cross_a` and `dp.cross_b` poses, wave `depth1`, 2 poses, prefix `dp`); a blow, a cue or a reaction draws over it. So a sidestep out of a dodge lands in the guard it was in.
- **Footfalls are by distance, not by tick:** one footfall every 36 units moved (`_depth_step_layer`), alternating the two poses, mirrored for the other direction (toward or away from the camera, by his face). The sidestep's 75 units are **two footfalls in 15 ticks**, 7 ticks each; a slow drift's 1.2 bh a second is one every 24 ticks. A decelerating step lengthens the last footfall by itself.
- **It reads his speed in depth from his depth, tick to tick** (`depth_vz`), so it needs no cue and no sim change. Under 0.25 units a tick (a settle) it draws nothing; it ramps to 85 percent by 2.0 units a tick.
- **Where it plays:** while he is free and on the ground. A sidestep taken from inside an exchange (the dodge template) plays the dodge's own atoms, and the step layer is not drawn over them (a dodge's pose already moves the legs).

**What I would still want from the sim** (asks, section 5): a cue `sidestep` (direction, 15 ticks) at the start, so the body can play an authored 4-phase sequence instead of reading the distance: the table above, with the hips and the first footfall *ahead* of the ground's motion by 2 ticks. The distance-driven layer is the safe version that works today, and it lags the start of the step by about a tick.

## 3. A fighter along a building's face, and going over a corner

depth.md section 4: a face stops the part of the pair's motion that runs into it and the rest slides on; in a street the depth part stops and the push goes on along the street; in an avenue the part along the street stops and the depth part slides down the avenue; **where nothing is left to slide, in a corner, the pair goes up and over.** "A face gives no bonus: there is no pin and no wall hit in a brawl."

### 3.1 Sliding along a face

**What it must look like:** a body that *walks* along something it is pushing against, and does not hit it. No pin, no recoil, no wall-slam pose: the body states the rule.

| What | How |
| :--- | :--- |
| The feet | The sidle: the crossover cycle of the sidestep, at the cadence of the speed (a footfall every 36 units), so a slide at the cap is a shuffle of about three steps a second. **Never a glide** |
| The body | A lean of up to 5 degrees **into the face** (the shoulder toward it), the head level, the guard as it was. The lean is what says "I am pushing against it", and it is the only difference from a plain step |
| The hands | No contact with the building. Contacts are for blows; a hand on a wall is a pin, which the rule denies |
| The yaw | As always: toward the rival's depth, not toward the face. A fighter slides along a face *looking at the other fighter* |
| In a street (the depth part stopped, the push going on along the street) | The ordinary walk. Nothing new |
| In an avenue (the depth part slides the pair down the avenue) | The sidle above, in depth. This is the new picture, and the step layer already draws it |

**Built:** the sidle is the step layer (distance-driven cadence, alternating footfalls). **Not built:** the lean into the face: it needs to know which face (a read of `nearestFace`'s side from World; Rendering has no such read). It is a 5 degree lean on the spine and costs no poses.

### 3.2 Going up and over a corner

Where nothing is left to slide, the pair is sent up and over (the stick slice's rule). That is a flight, not a step: both fighters leave the ground and the existing flight poses carry them. What the bodies need is small and specific:

| Beat | Body | Poses |
| :--- | :--- | :--- |
| The leave | A push off the ground at the corner: the existing launch-off / take-off from the flight set | existing |
| The climb | The body pitched to the climb along the face (head leading, 25 to 35 degrees), the legs trailing, the guard held | existing flight + a root pitch from the velocity (Rendering's `_pitch`, or `AnimFighter` from `f.vy` over `f.vx`) |
| The crest | At the top the body rolls over the edge: one hand on the roofline for a tick, the legs swung over: **the only new pose**, `wall_crest` (3 shared poses: the hand placed, the swing, the drop) | proposed, 3 poses, shared |
| The return | Out of the flight into the plane at the new street's depth: a normal landing or hover | existing |

- **Why a hand on the roofline and not a clean flight:** a tower is 20 to 40 bh. Without a touch the pair passes through a wall's top as if it were not there. One hand on the edge for the crest tick tells the eye the building is real and that the pair *went over* it. It is also the one place a contact with a building is correct: it is the player's own act (the stick held up), not a pin.
- **What it needs:** a read that says "this fighter is going over a face" (the climb's start, the crest, the end) and the face's side. None exists; section 5.

## 4. What is built (scratch, parked, inert with depth off)

| Piece | Where | Size |
| :--- | :--- | :--- |
| `depth_on`, `depth_yaw`, `depth_line`, `depth_vz`, and the depth read | `anim_fighter.gd` | about 35 lines |
| The yaw hook | `AnimBody.set_yaw(y)` (anim_body.gd) | 5 lines |
| The ground reads at the fighter's own depth | `anim_fighter.gd` (16 calls), `render_anim.gd` (1) | the calls only |
| Three-axis contact reach | `_contact_one` in `anim_fighter.gd` | 4 lines |
| The step layer | `_depth_step_layer` | about 20 lines |
| Two poses of the step | wave `depth1` (`dp.cross_a.step`, `dp.cross_b.step`), `waves/depth1.mjs`, prefix `dp` in `wave_gen.mjs`, `pair_live.json` shared | 2 poses, 2 sequences |
| Test | `anim_check` `_test_depth` | depth off: nothing; depth on: turns and signs, cap, the layer draws only when his depth changes |

## 5. What others need to do

- **Rendering:** call `AnimBody.set_yaw(depth_yaw)` for each body each frame (sign by his face); read `depth_line` for the pair's mark if it wants the angle; read the eight ground rows for the ground field (their table). Nothing else of mine touches their files.
- **Simulation / Encounter:** (a) a cue `sidestep` with the direction and 15 ticks, so the authored sequence of section 2 can replace the distance-driven one; (b) a read for the face a pushed fighter is sliding along (its side) and for the climb: start, crest, end (a cue `over_corner`, or three fields on the fighter). Neither is needed for what is built.
- **Camera:** nothing of mine; the dolly's `focus_z` and the yaw both read the same `z`.
- **Tools:** the new keys (none for the schema: `depth1` is a wave, the schema for waves is unchanged).
- **Orb's eye:** the turn is the first look change that is in the body and not the camera. It must be seen in a clip with depth on (the flash clip first: both modes), at 10, 20 and 30 degrees. The body turns by at most 34 degrees; if it reads as a stiff turn at the pair's closest approach, the fade (300 to 700 units) and the ease (0.12 s) are the two numbers to move.

## 6. Risks

1. **The step layer's poses are first values and unseen on the web build** (checked by the headless tests only: signs, caps, the depth-off identity). They want a still and a short clip before anyone calls them right.
2. **The distance-driven step lags the sim's start by about a tick.** Not visible at 15 ticks; visible if the cue comes.
3. **The yaw and a close camera:** a turned body's near shoulder can cover the far fighter's blow (section 1.4). Camera's to look at in the clip.
4. **The corner's pose is paper.** Nothing is built, and the sim has no read for it.
