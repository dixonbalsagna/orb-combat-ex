# The intro gestures: Narrative's ten intents, for the launch pair (2026-10-06)

Owner: Animation. Source: `docs/narrative/dynamic-intros.md` section 11 (a gesture intent is a meaning; Animation maps it to the fighter's own small motion; a missing one is a silent skip). Status: built and tested against a **staged event**; nothing sends it yet (Simulation's composer will). The poses are parked (baked with the fighters' `more` lists, played only by the event).

## 1. How a gesture plays

- **The event:** the sim's `intro_gesture {actor, intent, at}`. `RenderAnim.consume` reads it as an `FxEvent` of type `intro_gesture` with `actor` the fighter's slot, **`kind` the intent** and **`text` the point** (`land_first`, `land_second`, `look_start`, `look_end`; the body does not need it). If Simulation names the intent field `intent`, the render reads that first. In the intro the sim's clock is frozen at 0 and the intro runs on the tick, so a gesture started while the fighter's state is `intro` plays on the tick clock; in a stand-off it plays on the match clock.
- **The table:** `data/anim/pair_live.json`, `roles.<fighter>.gestures`: for each of the ten intents, `seq` (a sequence or a pose), `w` (a weight), `mask` (the groups of bones it plays on, from `gesture_groups`: head, torso, arms, legs) and `hold` (seconds, for a pose). **An intent a fighter has no entry for plays nothing** (a silent skip, counted in `debug.gesture_skips`), and so does a fighter who is not one of the pair.
- **The layer:** `AnimFighter.on_gesture(intent, T, tick_clock)` starts it and `_gesture_layer` plays it after the energy layer: the sequence is played over whatever the fighter is standing in, only the masked bones take it (a bow does not move the feet), eased in over 6 ticks and out over 9, at the entry's weight (0.6 of it with reduced motion). It stops if he is launched, knocked down or in an exchange.
- **The flag:** `RenderAnim.intro_gestures`, on by default and inert until the event exists (`--no-intro-gestures` switches it off).

## 2. The ten intents on the launch pair

| Intent | The Protagonist | The rival |
| :--- | :--- | :--- |
| acknowledge | `pg.taunt_nod`, half weight, head and torso (reused) | **new** `ri.acknowledge` |
| appraise | **new** `pi.appraise` | `rw.taunt_head_tilt` (reused) |
| dismiss | **new** `pi.dismiss` | `rw.taunt_back_turned` (reused) |
| defer | **new** `pi.defer` | **new** `ri.defer` |
| brace | `in.hold.tense`, the intro's tense hold (reused) | the same |
| ease | `pg.taunt_bounce`, half weight (reused) | `rw.taunt_dust_plate` (reused) |
| claim | **new** `pi.claim` (the legs take it too: the stance widens) | `rw.taunt_stillness` (reused) |
| check | **new** `pi.check` | **new** `ri.check` |
| soften | **new** `pi.soften` | **new** `ri.soften` |
| harden | `pg.taunt_fist_palm` (reused) | `rw.drop_the_act` (reused) |

**Ten are new** (waves `protag9`, prefix `pi`, six sequences and 12 poses; `rival6`, prefix `ri`, four sequences and 8 poses), each a two-pose motion of 16 to 24 ticks. The reused ones are the existing taunt and intro poses, some at half weight and on a mask so they read as a gesture and not a challenge.

## 3. Legal's list: each new gesture with its hand positions

Positions are in the pose's own coordinates (x forward, y up, z toward the camera for the right hand), in rig units; the shoulder width is 20. "Apart" is the 3D distance between the two hand targets, in shoulder widths. The hip zone is x 14 or less at height 24 to 44 (open hands); every hand below is outside it. Every hand is an **open** hand (no fist, no claw, no pointed or two-finger state: the rig's open hand has no curl); every gesture is one head or arm motion and none has a crossed forearm or a hand to the forehead. The poses carry `hands_open_or_claw` and `not_at_hip` (the rival's also `no_cross_hold`), and `pose_lint` passes all 20.

| Gesture | Pose | Right hand | Left hand | Apart | The motion | Note for Legal |
| :--- | :--- | :--- | :--- | ---: | :--- | :--- |
| **pi.appraise** | low / high | (16, 50, 16) | (16, 50, -16) | 1.6 | the head down 20 degrees, then up level (-8) | hands loose at his sides, open |
| **pi.dismiss** | turn / shake | (16, 48, 18) | (16, 48, -18) | 1.8 | the head turned 38 degrees away, a small shake (26) | **not a taunt:** no hand moves, no pointing, no wave; it is a turned head |
| **pi.defer** | bow / rise | (22, 38, 15) then (16, 50, 16) | (22, 38, -15) then (16, 50, -16) | 1.5, 1.6 | a short bow (spine 14, head 22) and back | hands low and apart; x 22, outside the zone |
| **pi.claim** | plant / breath | (10, 52, 26) then (12, 50, 22) | (10, 52, -26) then (12, 50, -22) | 2.6, 2.2 | the chest up, the feet widened, a breath out | **not a taunt:** the hands are open and away from the body at waist height, no fist, nothing raised; it is a stance |
| **pi.check** | up / back | (16, 50, 16) | (16, 50, -16) | 1.6 | a glance up and aside (head -24, yaw 30), then back | the hands are still |
| **pi.soften** | drop / rest | (20, 46, 24) then (16, 48, 20) | (20, 46, -24) then (16, 48, -20) | 2.4, 2.0 | the shoulders dropping, both open palms turned out a little | hands apart and open at waist height |
| **ri.acknowledge** | dip / up | (18, 54, 12) | (14, 54, -10) | 1.1 | a short dip of the chin (16), back up | hands where they were |
| **ri.defer** | bow / rise | (20, 48, 18) then (18, 54, 12) | (14, 58, 2) then (14, 54, -10) | 1.2, 1.1 | a half bow (spine 12, head 18), one open hand laid flat on the coat | one hand on the coat, the other loose; no crossed forearms; this is the pose to look at |
| **ri.check** | cuff / up | (18, 54, 16) then (18, 54, 12) | (26, 56, -6) then (16, 54, -10) | 1.2, 1.1 | a glance down at his own forearm plate, the forearm raised a little, then up and aside | the forearm is at chest height, not at the forehead; no beckon |
| **ri.soften** | drop / rest | (16, 48, 18) then (14, 52, 14) | (14, 50, -14) then (14, 54, -10) | 1.6, 1.2 | the guard hand dropping, the head tilting back a little | hands open, below the shoulder |

No gesture is held: the longest peak is 14 ticks, and each eases back to the idle. The reused ones were screened as taunts already (RL-067 for the close taunt, the taunt gates in `pair_live.json`).

## 4. The checks

`gesture_lab.gd` (`render/anim/tools/`) stages the event and plays each intent over the idle, the idle alone on the left: `art/animation/review/gestures/gestures-protagonist.gif` and `gestures-antihero.gif` (the ten in a row, each labelled new or reused). `--measure` prints, per intent, how far it moves the pose, the joint violations on screen (0 for every intent on both fighters) and whether it is a silent skip.

`anim_check` (`_test_gestures`): all ten intents play on both fighters over their idles; masked gestures leave the legs where the idle has them (under 0.05 rad); no joint past its limit reaches the screen; a gesture plays on the intro's tick clock; a fighter with no table and an unknown intent are silent skips; the flag off plays nothing.

## 5. What Simulation's composer must send

`intro_gesture` with `actor` (the slot), `kind` the intent (one of the ten) and `text` the point; sent at the gesture's tick. Nothing else: the body knows the rest (its own motion, its length, its mask). For a fighter outside the launch pair the ten entries are a table to fill (the table is the work list; eight of the ten are head, shoulder and hand motions that retarget by name across humanoid builds, and `harden` and `dismiss` are authored per fighter).

## 6. Not done

Narrative's `who` (`first`, `second`, `left`, `right`, `both`) is the composer's: it resolves it to actors and sends one event each. The gestures at the four timing points play wherever the sim places them; I have not seen them in a live intro because none sends them. The two reused gestures with a long own length (`rw.drop_the_act`, 90 ticks) run their length and are not cut.
