# The clinch and the catch on A, sized (2026-10-16)

Owner: Animation. **Paper only: nothing is built, no data or code changed.** Orb picked "a hybrid between catch and clinch, rule in favor of clinch" (`docs/ep/vision.md`, 2026-10-16, homework 20). Combat is designing the rules (`docs/combat/grapple-pitches.md`: the clinch is its section 2, the catch its section 1; the throws are `docs/combat/pending/wave4-grabs.md`). This note answers what the animation side costs, per fighter, under the joint-limit rule, and what the four-body scans need. Counts are estimates in poses, code slices and scan classes, not days, in the style of `next-waves-sizing.md`.

## 1. What the rig already has, and what it lacks

**Has.**
- The contact solve puts a hand or foot on a region of the other body (`data/anim/sockets.json` regions, `_contact_one`), with a second limb (`limb2`), a reach clamp and `clamp_excess` so a limb ends short of a target rather than bend past a limit.
- A held layer that keeps a pose through the sim's wait (the wound blow's `_hold_coil`, the zip's `_held_layer`: `carried`, `lifted`).
- A free-arm layer (`_free_arm_slew`) that keeps the arm that is not striking near the guard.
- Ragdoll and the join smoothing (`_inertialise`) for a body that is thrown.
- The joint audit (stages A to D, `joint_scan`) and the lead scan, both with `--bodies=4`.

**Lacks.**
1. **A partner.** `AnimFighter._opponent(S, f)` returns the first other fighter. A clinch is the first state where the right other body is not the nearest and the contact solve must read "my hold partner".
2. **A grip that persists.** A blow's contact lasts a tick and the hand is released. A grip is a hand pinned to a moving point on the other body for 10 to 90 ticks while the rest of the body does something else (a pummel, a blow with the free limb, a step).
3. **Regions to hold.** Today's regions are the places to hit (head, jaw, chest, gut, legs, shins, the forearms). Legal's hold points (g01) are the collar, a shoulder, an upper arm, the body, the waist or an ankle.
4. **Two bodies that must not interpenetrate.** Nothing checks one body against the other: a blow ends at a surface, but a hold keeps two torsos 24 to 36 units apart for a second and more.
5. **Pair-aware scans.** `joint_scan` and `lead_scan` pose one body at a time against a dummy.

## 2. The method: the grip is solved, the pair is placed by the sim

Both bodies are posed by their own fighter. The two things that make it a pair are a **read from the sim** and a **grip layer** in the render. Nothing in the render moves a position.

- **The sim places the pair.** It holds the two fighters within a grip envelope, walks the pair along the stick, and sends the throw to the launch planner. The render reads (`DirHold.read(S, f)`, shaped like the zip's `DirGrab.read`).
- **The grip layer** runs after the pose, before the contact solve. For each gripping hand it asks the region's point on the partner's body (as `_region_point` does for a blow) and runs the same IK, `ik_limb` with `clamp_excess` and `source_limits`. The hand lands within a gap budget or ends short. It never bends past a limit to make the gap.
- **The free limb plays on top.** A clinch blow is a normal key set with a `limb`, and the grip layer holds the other hand where it is. This is the zip's `limb2` generalised: one limb strikes, the other keeps its grip.
- **Grip grades are mixes, not poses.** The contest has five steps (two behind, one behind, even, one ahead, two ahead). Three are authored per fighter (behind, even, ahead) and the steps between are `_mix` weights in data. The same three serve both bodies: each fighter plays his own grade, the opposite signs on the two sides. The held fighter is not a special case: **there is no victim pose set**, because Orb's clinch is a contest and either side can be ahead.

## 3. Pieces and poses

Poses are shared on the one skeleton (R1) in a new wave `cl1` (prefix `cl`), and each fighter gets flavour poses in his own wave. The throws are not new here: they are Combat's wave 4 (`pair3`, prefix `zq`, 22 poses, already sized in `next-waves-sizing.md`), and the clinch takes **three** of them.

| Piece | What the body does | Shared | Per fighter | Notes |
| :--- | :--- | ---: | ---: | :--- |
| **Tie-up** (the tap) | the reach, the seat at the collar and the elbow (or the waist, g05), both bodies closing | 2 | 0 | The reach is the existing `reach` shape with a different target. The seat is the even grade. |
| **Grip grades** | behind, even, ahead: the shoulders, the head beside the other's, the weight forward or back | 3 | 1 | The flavour pose is the fighter's own grip habit (section 4). |
| **Pummel** | a step ahead for the grip: the swim of the free arm under, a shoulder turn | 2 | 0 | Left and right, alternating on the beat. Reuses `press_run` footwork (`march`). |
| **Brace** (the hold) | feet set, hips back, elbows in, the head down | 1 | 0 | A held pose with the strain layer (`tremor`, `twist_back`) that the held medium already has. |
| **Close blows** (vicious, up to four, by region) | a short knee to the gut, a short elbow to the head, a body hook to the chest, a stamp or low kick to the legs, and the vicious knee a battered region cannot take | 0 | 5 | These are the only per-fighter bulk. Aim mode and `limb2` exist. Each is a key set with the grip hand kept. A blow on a battered region reuses the wound-blow hold. |
| **Wall pin** | the holder walks the pair to a wall and presses: a forearm across the collar (never the throat), a shoulder in, the knee set | 2 | 0 | The pinned body leans on the wall's face, the blows wear 1.5 times as hard (Combat), and the hit reaction is amplified (existing `on_hit`). Combat's wall slam (`wall-slam.md`) is the throw from the pin. |
| **Carry** (the hold on A from the catch) | the holder drives the rival along the stick, up to 1.5 seconds | 2 | 0 | The carried body reuses the zip's `carried` pose with the free-arm struggle; the holder needs a drive pose and a strain pose. |
| **Throws out of it** | `hurl` (toward), `back_throw` (away) and the reversal throw from two behind | 0 | 0 | From `pair3`. The ragdoll takes the thrown body, with the join smoothing on the handoff tick. |
| **Whiff and break** | a refused grip (a dodge, a blow that landed first), the push apart at the 90 ticks, the stagger after | 2 | 0 | The whiff is the `miss` set's shape. The break reuses `s3.shoved`. |
| **Total new** | | **12** | **6** | |

**Per fighter, new poses:** 12 shared + 6 flavour. For the two fighters in hand that is **12 + 2 × 6 = 24 poses** (plus 5 of `pair3`'s 22, which must be posed first). A third fighter adds 6; a fighter with no flavour uses the shared set at once. At the bake's cost (about 1 ms a pose) this is nothing; the cost is review: every piece is a GIF pair seen from both bodies, and the joint and held lints (below).

## 4. Per fighter

| | The Protagonist | The Anti-hero |
| :--- | :--- | :--- |
| **Grip habit** | A boxer's tie-up: open hands at the collar and the elbow, the head tucked beside the other's, short and busy. The robe's ring on the back is the thing the rival sees over his shoulder. | Precise and cold. One hand takes the collar; **the other arm is a one-arm fold** (a single forearm across the body, the hand free or at the chin: Legal's h09 allows it, and forbids the crossed-arm fold as an idle, stand-off or intro pose or held for 12 ticks), so the free arm is a shoulder-height guard and the grip is lighter than the Protagonist's. The armoured shoulder leads into the pin. |
| **Pummel** | Quick and low, the swim of a sparring partner. | Short and exact: a step, a turn of the shoulder plate. |
| **Close blows** | Body hook, uppercut to the chin, a knee to the gut, a stamp, the finisher a knee. | A short elbow to the jaw (the glasses bend when the head is hit, Art's plan), a knee to the gut, a heel on the ankle. His blows end in the exact stop of his style. |
| **Brace** | Wide, and his feet slide: he is thrown less than he is pushed. | Narrow and still. Nothing moves but the grip hand. |
| **Throw look** | Open, athletic: the hip throw and the robe flaring. | Economical: the hand lets go at full reach and the arm stays out. |
| **The Press** (a future clamp fighter) | His forearm plates close on the body; the grip is two plates and no fingers, so his **grip layer holds a plate region, not a hand** (a `grip_limb` key in the fighter's row). | |

## 5. The joint-limit rule, with two bodies in contact

The rule stays: no joint past its limit in a drawn frame, on either body, with the final pass as the net, not the plan. A clinch is the hardest case because for the first time **the pose of one body depends on the position of the other**, and the sim, not the animator, picks the distance.

1. **Every authored pose passes alone.** The 24 new poses pass joint audit stages A to D and the held lint before they join a pair, as every wave does.
2. **The envelope is a contract.** The arm reaches about 36 units from the shoulder (16 + 15 + 5, `anim_rig.gd`). A grip on the collar is comfortable from 24 to 34 units between the bodies, a waist grip from 20 to 30, an upper arm from 22 to 34. A grip on an ankle needs a height difference the sim's carry gives. **Simulation holds the pair inside the envelope for the grip's region** (a table in `data/anim/clinch.json`, mine). Outside it the render never bends further: the hand ends short by up to a gap budget (3 units, data) and the gap is counted (`debug.grip_gap_max`).
3. **A wrist is the likeliest break.** Holding a collar needs a hand turned across; an ankle, a hand turned down. The twist is checked against `comfort_twist_deg` per grip (a new `grip_twist` class) and the grip chooses the hand and the turn that stay inside it.
4. **Mixes between limit-clean poses are clean for hinges** (elbow and knee), but a ball joint's slerp between two legal orientations is not guaranteed legal. Every grade mix is **scanned at 0, 0.25, 0.5, 0.75 and 1** of each step, and the final pass stays on for the thing the scan cannot see.
5. **Two bodies must not interpenetrate.** A new class `pair_clear`: the distance between every pair of bone capsules, one from each body, at least zero except at a grip's own contact (the hand on its region). A failure is a pose that needs re-posing, not a render nudge. Where the sim places the torsos closer than the bodies' thickness allows, the render takes a small **depth offset** (the two bodies pass in z by a few units, render-only, data, so they stand shoulder to shoulder in 2.5D) rather than pose through.
6. **Legal's rows are scan classes:** no hands laced (g02: a hand within 8 units of the other body's hand is a failure, apart from the free-arm struggle's own approach, which keeps 16 or more); no hold on the throat, the hair or the face (g01: a grip point is checked against the head and neck bones); a carry draws the whole body every tick (g03); nothing glowing at the hands.
7. **The handoff to the ragdoll** is where a held body is most likely to snap. The thrown body leaves its held pose through the join smoothing, with its limb limits trimmed as `_inertialise` already does, and the first ragdoll tick is scanned (stage C).

New scan classes in all: `grip_gap`, `grip_twist`, `pair_clear`, `laced`, `grip_region`, `handoff`.

## 6. What the four-body scans need

`--bodies=4` poses four fighters at once. A clinch needs these, all on paper until the read exists:

1. **`_opponent` becomes a partner pick:** the hold partner while a hold read says so, else the exchange's partner, else the nearest. This also fixes the "assumes two" in `nine-cells-look.md` (one function and its callers).
2. **A scripted scenario that does not need the sim's hold,** as the cue scenarios do: the scan writes a fake read (kind, phase, grade, regions, partner) into two of the four fighters and places them with the held offset, then the other two circle, guard and are flown past. It runs every grade, every grip region and every phase (tie-up, pummel, brace, a blow of each region, pin, carry, throw), both ways round.
3. **Asserts for four:**
   - each member's partner is his hold partner and no one else's;
   - the free bodies never read the pair as their opponent;
   - a body flown past the pair does not change either pair member's pose;
   - `pair_clear` also holds for each pair member against each free body;
   - the same pass with **two pairs held** at once, because co-op 4v1 is Orb's example (`vision.md`).
4. **A matching option in `lead_scan` and `joint_scan`:** `--clinch`, to pose the scenario and report per class.
5. **The live scan** (`_test_bends_live`) adds the new classes once the sim holds fighters.

## 6a. Legal's rows of 2026-10-16 (`docs/legal/homework8-review-screen.md`: g06 to g08, h09), which bind this work

- **g06 (tied):** heads and torsos apart by at least a forearm's length, hands free, never limp or bound. The collar envelope of section 5 reads as *at least 27 units* centre to centre (a forearm of 15 plus the two half-torsos), not 24: a `g06_apart` class in `pair_clear`.
- **g07 (pinned):** vertical against a surface, at the shoulder, collar or upper arm, hips apart, the pinned fighter's feet bearing weight and shown bracing or struggling; no ground pin, mount or straddle. One more shared pose, `pin.brace`, and a scan on the grip point and the hips.
- **g08 (carried):** over the shoulder or by collar and waist, never the head, neck, hair or tail; the body drawn whole in view; nothing glowing at the hands.
- **h09:** see the Anti-hero column above. A scan: no fold pose in an idle, stand-off or intro sequence.

The count becomes **25 new poses** (13 shared, with `pin.brace`, and 6 a fighter).

## 7. What Animation needs from the other directors

- **Simulation and Encounter:** the held state, as a read: `DirHold.read(S, f)` returning kind (tie_up, pummel, brace, blow, pin, carry, throw, apart, whiff), phase, tick into it and its length, the partner's slot, the side, the grade (-2 to 2), what each fighter grips and what he is gripped by (regions from Legal's list), and the wall (side and x) for a pin. The held offset every tick, **always inside the table of section 5, point 2**. A hit event in a hold names the region struck (as today). A `clinch` separation floor under the 45 `minSeparation` (the `wave4` note: the hold sits at 36).
- **Combat:** the phase lengths as data in ticks; which of the blows are per region; whether the Anti-hero's folded arm may release the guard in a pummel.
- **Legal:** rows g01 to g05 and s08 become scan classes on my side. I would like a look at the tie-up and the pin before they are posed, as Legal did for the zip.
- **Tools:** schema keys for the new `data/anim/clinch.json` and the new regions in `sockets.json`.
- **Rendering:** the depth offset for two bodies stood shoulder to shoulder and the keyline for two bodies in one silhouette.
- **Orb:** nothing for this paper. The tail question stays open for `pair3`.

## 8. Slices, and the order

| Slice | What | Needs |
| :--- | :--- | :--- |
| **C0** | the partner pick (`_opponent`) and the new regions in `sockets.json`, with the test | nothing |
| **C1** | `pair3`'s three poses (`hurl`, `back_throw`, the reversal) and the throw handoff | nothing |
| **C2** | the grip layer: IK pinned to a region for a read's length, the gap budget, the grade mixes; a fake read for the scan | C0 |
| **C3** | wave `cl1` (12 shared poses) and the fighters' flavour (12), `clinch.json` | C2 |
| **C4** | the pin (the wall pose and the amplified reaction) and the carry (extending `_zh`) | C2, Simulation's read |
| **C5** | the scan classes and `--clinch` for `joint_scan` and `lead_scan`, `--bodies=4` and two pairs | C0 and C2 |

**Order:** C0 and C1 now, then C2 and C5 together (the scan comes with the layer, not after), then C3, then C4 when the sim's read exists. Five code slices, 24 new poses, plus the 22 of `pair3` (the clinch takes 3 of them; the catch's tap throws want the rest), and a review pass of about 40 GIF pairs.

**What I would not do:** author a "victim" pose set (the contest has no victim), and let the render shave a distance to make a grip reach.

---

## 9. C0 and C1 built (2026-10-17; `docs/animation/pending/grapple-c0-c1.patch`)

- **C0, the partner and the regions.** The partner pick the paper asked for was already there from the many-bodies patch (the exchange's other fighter, else the nearest body by the arc: the nine-cells note that `_opponent` returns the first other fighter is out of date). C0 adds the one thing a clinch needs: `AnimFighter._opponent` takes a hold's partner first when the sim gives one (a view field `holdPartner` on the fighter; nothing sets it yet). **Ten hold regions** in `data/anim/sockets.json`: `collar_r`, `collar_l`, `shoulder_r`, `shoulder_l`, `upper_arm_r`, `upper_arm_l`, `waist`, `ankle_r`, `ankle_l` and `back` (the pin's side). The collar is the collar's side over the shoulder, never the throat: the test (g01) holds every collar, shoulder and arm region at least 7 units from the neck and 12 from the head on the guard stance.
- **C1, the throws.** A new wave `pair3` (prefix `zq`): the thrower's own side of Combat's eight throws, three poses each (load, release, follow), **24 poses**: `hurl` and `sling` (across, toward), `turn_throw` and `back_throw` (across, away), `drive_down` and `spike` (down), `lift` and `jolt` (up, the two new ones). `data/anim/throws.json` maps each send to each fighter's throw as Combat's table has it and names the region each hand takes. The held body is the sim's and the ragdoll's: these are only the thrower. **Checks (`_test_grapple_c0_c1`):** all 24 poses exist and are inside the joint limits; no arm is crossed (h09: the Anti-hero's throws use a one-arm fold, a single forearm across with the hand at the chin); the hands of the two-hand throws are 16 or more apart (Legal's g02 distance); every named region exists; with four bodies the partner is the nearest by the arc, and the exchange's other fighter when there is one. A sheet of all the new poses (the throws, the skid and the chain's) is `art/animation/review/ragdoll/poses-throws-skid-chain-sheet.png` (this PC only).
- **Not yet:** the grip layer (C2) that puts each hand on its region of the real body, the wave `cl1` (the tie-up, the grades, the pummel, the brace, the pin), and the held read from the sim.

---

## 10. C2 built: the grip layer and the wave `cl1` (2026-10-18; `docs/animation/pending/grip-layer.patch`)

- **The read.** The sim will send a hold as `AnimFighter.on_hold(read, T)` (`on_hold_end` ends it): `partner` (a fighter's slot), `kind` (tie, pummel, brace, pin, carry, strain, whiff, apart), `role` (`holder`, or `held` for the pinned body), `grade` (-2 to 2), `side` (the pummel's hand) and `grips` (each gripping hand to a region of the partner's body in `sockets.json`). Nothing sends it yet; the scan hands it to both bodies, as the chain's and the throws' scans do.
- **The layer** (`_grip_layer`, before the flight lead; `RenderAnim.grip_layer`, on, inert without a read; data `data/anim/clinch.json`): mixes the pose of the kind in over 6 ticks (a tie-up is the even seat mixed toward the ahead or the behind pose by the grade; the pinned body takes `cl.hold.pin_brace`), then puts each gripping hand on its region by IK, never bending past a limit (a shortfall is counted in `debug.grip_gap_max`). It moves no position: the one thing it shifts is a **render-only depth offset** of 7 units, the two bodies stepping out of the plane in opposite directions, so two arms reaching across pass without passing through one another (the orthographic camera cannot see it).
- **The wave `cl1`:** the thirteen shared poses (`cl.hold.tie_reach`, `seat`, `ahead`, `behind`, `pummel_l`, `pummel_r`, `brace`, `pin`, `pin_brace`, `carry`, `strain`, `whiff`, `apart`). The tie-up poses are upright (a lean of 2 to 6 degrees), because heads leaning in broke Legal's g06.
- **The spacing table the sim holds the pair to** (the scan, `_test_grip`, runs the tie-up at every grade and every spacing from 26 to 46 and keeps the ones where the hands land within the 3-unit budget, the bodies clear to within 1.5 units, no hands lace (g02: 8 or more apart; measured 10 to 18) and heads and torsos have a forearm of air (g06: 15; measured 17 to 28)):

  | Grade of the grip | Least spacing | Most spacing |
  | :--- | ---: | ---: |
  | behind (-1) | 28 | 36 |
  | even (0) | 28 | 38 |
  | ahead (+1) | 30 | 38 |

  **So Simulation can hold a pair 30 to 36 units apart, centre to centre, at every grade** (my paper's 24 to 34 was wrong on both ends: under 28 the thighs pass through one another, over 38 the arm no longer reaches). Past 38 the hand ends short and the shortfall is counted, not drawn through a limit.
- **Every kind of hold** (the pummel, the brace, the pin with the pinned body's brace, the carry, the strain, the refused grip, the push apart) is clean at 34 units: no NaN, no joint past a limit, the hands on their regions (the refused grip over-reaches by design).
- **Not built yet:** the six flavour poses a fighter (the Anti-hero's one-arm fold, the Protagonist's open hands), the pin against a real wall (it needs World's wall plane), the carry while the pair travels, and the sim's read.

