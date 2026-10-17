# Ragdoll physics for entertaining combat: the paper (2026-10-16)

Owner: Animation. **Paper only: nothing is built, no data or code changed.** Orb (`docs/ep/vision.md`, d65c3439): "entertaining ragdoll physics-based combat should be a goal"; fighters recover in mid-air in a reasonable time; bigger blows send them flying backwards; "skidding in midair" to regain control "should be a thing to demonstrate velocity"; a launch into a building goes through a floor inside, bounces off the ceiling, then down through the next floor. Rule-of-cool outranks everything; the player keeps agency. This note is the animation side: where the ragdoll stands, what it lacks, the three new things (the mid-air skid, the floor-ceiling-floor chain, the hand-off) and what Game Design and World must give me as events. Joint limits hold throughout (section 6).

## 1. The pipeline as it stands

**One layer, `AnimRagdoll` (`render/anim/anim_ragdoll.gd`, `data/anim/ragdoll.json`).** Twelve angular degrees of freedom (head, spine, each arm's swing and sweep, each forearm, thigh and shin), each a spring and damper around the posed target, stepped once per sim tick, drawing no random number and writing nothing to the sim. It is *added on top of* the solved pose at a weight that fades in and out. What drives it:

| Driver | What it does | Where |
| :--- | :--- | :--- |
| **Streamer drag** | the body's velocity in its own frame pushes each limb back along the flight (drag per joint) | `step`: `drag` |
| **Inertial whip** | the body's acceleration (from the sim's velocity, without gravity) whips the limbs | `step`: `inertia` |
| **The shapes** | the fighter's own tuck, brace, skid and crumple targets (Art's silhouettes), mixed by controller weights | `data/anim/shapes.json` |
| **The flail** | the first 0.35 to 1.2 s of a launch: limbs thrown about at a per-joint frequency | `flail_amp`, `flail_hz`, `phase` |
| **Impulses** | `crumple` (a slam folds the body), `kick` (one joint), `hit` (the region table by blow direction and strength) | events: ground bounce, land, KO fall, hits, shock |

**The controller (`_rd_tick`)** picks the regime from the sim's state: `launched` or `dropped` (free 0.85, tuck by spin, flail by time, brace in the last 0.3 s before a landing), `slide` (the skid, free 0.55), `down` (crumple for 0.7 s). The body's orientation and spin are the sim's (`f.rot`, `f.spin`); the **flight lead** turns it head first along its velocity. The ground's events (`bounce`, `left_ground`, `land`, `tumble_end`, `embed`) trigger the `gc.bounce`, `gc.lip_launch` and `gc.tech_flip` sequences and the tumble's held brace (`data/anim/ground.json`).

**What it does well.** It is deterministic, replays at any frame rate, costs about nothing, and every turn it adds is cut to the largest share that stays inside the joint's range (`AnimJoints`; reduced motion halves the ranges). It reads speed, direction and a landing.

## 2. What "entertaining" needs, and what is missing

1. **It is two-dimensional.** The twelve degrees of freedom are all about the local z axis (the sagittal plane), plus the shoulders' sweep. There is no twist of the spine, no roll of the head, no swing of a limb out of the plane. A body that spins reads as a flat paper figure turning; a flailing one reads as a pendulum, never a rag.
2. **It has no weight.** The response is the same for any fighter and any blow of the same direction. A tier-4 blow that sends a body across a district moves the limbs as a tier-1 knock does, only faster. Weight reads as *lag and overshoot proportional to the blow*: the head snaps first, the trunk follows a few ticks later, the legs last, and the body rings for longer after a bigger blow. None of that is tied to the blow's tier or to the fighter's mass.
3. **Every launch flails the same.** `phase` is set once from the fighter's slot (`slot * 0.9`). A fighter flails identically in every launch of the match. The data to vary it exists (the launch number `n` is on every event of a journey): the phase should come from a hash of `(slot, n)`, with no random draw.
4. **No contact response of the limbs.** A hand does not plant, a foot does not scrape. The sim treats the body as one circle (`BODY_R` 60), so I cannot know a limb touched a surface. What can be faked, with only the events, is the *body's* reaction at the contact (section 4).
5. **A crumple does not know which side hit.** A bounce folds the body one way whatever part of it met the surface. A back against a ceiling must arch; a chest against a floor must fold over it. The render knows the body's facing and the event's normal, so it can choose.
6. **There is no hit-stop reading.** If the sim holds a contact for a few ticks (a punch-through), the body should freeze in its pose and release with the impulse on the last tick. The pose holds already (the held layer); the impulse does not know to wait.
7. **There is no air recovery pose.** The brake (hold Guard, `docs/controls/agency-input.md` 4a) bleeds speed in the sim, and nothing in the body shows it. The flight lead keeps the head leading while he brakes, which is the opposite of braking.

## 3. The additions, in order of cost and value

| # | What | Size | Cost to the pipeline |
| ---: | :--- | :--- | :--- |
| R1 | **The launch number varies the flail** (`phase = hash(slot, n)`, the per-joint frequencies jittered by the same hash) | a few lines, data for the jitter | none; deterministic |
| R2 | **Weight by tier and mass:** `ragdoll.json` gains `mass` per fighter (inertia and drag multiplier, settle time) and a tier curve (flail and hit-kick gain by the launch's tier, taken from the `launch` event's `tier` or the damage `ratio`); a **limb lag chain** (head 0, trunk +2 ticks, limbs +4, legs +6, as a delay line on the drive) so a hit travels down the body | 1 slice, 2 data blocks | per tick, a small delay buffer per fighter |
| R3 | **Six more degrees of freedom out of the plane:** spine twist, neck roll, and the two arms' twist, with the same limit machinery (`comfort_twist_deg`, `squeeze_arm_back`); a flail with a twist component reads as a rag | 1 slice, `ragdoll.json` rows, a new scan class (twist past comfort in a tumble) | N 12 to 18: well under a millisecond on the bench |
| R4 | **The side that hit:** `crumple` and the bounce sequences choose fold or arch from the event's normal and the body's facing | 1 small slice | none |
| R5 | **The hit-stop release:** the impulse waits for the sim's release tick (an event, section 5) | tiny | none |
| R6 | **The mid-air skid** (section 3a) | 3 shared poses, 1 layer, an exemption in `lead_scan` | the layer adds one pose mix |
| R7 | **The chain** (section 4) | 4 shared poses, a contact handler, a scan | events from World |

### 3a. The mid-air skid: the body braced against its velocity

**What it must show.** Deceleration, as a read of speed. The eye reads a skid by the body leaning *back against its direction of travel* with the feet toward it and the arms out and forward (air catching them), the torso upright or tilted, the head up, while the position keeps travelling on, then slowing; and by what trails: cloth, hair and the limbs stream forward past the body as it slows (the inertial whip already does that with a negative acceleration; it needs a bigger gain while braking).

**The pose set (shared on R1, three poses).** `ab.enter` (the spin removed: arms flung wide, one leg out ahead, a half-second of readable recovery from a tumble), `ab.hold` (the brace: torso leaned back 35 to 50 degrees against the velocity, knees bent, one foot ahead, both forearms up and forward, the head up and looking along the travel), `ab.exit` (the body returns to the air stance, arms in). A **blend weight** from the sim's brake: weight = deceleration over a reference, so a hard brake leans harder and the lean eases as speed falls. The lean angle is computed in the render from the velocity and the facing (no sim input beyond the brake state).

**How it joins what exists.**
- **The flight lead turns the head along the velocity. The skid wants the feet to meet it.** The lead scan (GB-006) forbids feet-first flight at speed. A braking body is the one case that is right: the scan needs an exemption keyed to the sim's brake state (a flag on the frame, not a speed threshold), and the lead layer must let go while the brake is down (a weight, as it already lets go of a tumble).
- **The ragdoll's `skid` shape** is the ground slide's (the feet scraping). An air skid takes its own shape row (`air_skid`) beside it.
- **Per fighter:** the Protagonist's skid is wide and open, the robe flaring forward as it slows; the Anti-hero's is narrow and cold, the plated shoulder leading the turn and no flourish, the coat held back by the speed. Poses are shared; each fighter's flavour is two pose overrides (the arm line and the head) in `fighters.json`.
- **VFX and Camera** show velocity too (a streak, a ring where the speed drops): theirs, from the same events.

**Joint limits.** The three poses pass stages A to D like any pose. The blend is two limit-clean poses mixed (hinges stay clean; the ball joints are scanned at 0, 0.25, 0.5, 0.75, 1). The ragdoll's cut-to-limit still runs on top.

## 4. The floor-ceiling-floor chain

**What happens (Orb, and World's floors in `docs/world/b2-plan.md` section 9).** A launched body breaks the building's face (`building_hit`), goes through a floor inside it (`floor_hit` `outcome: punch`: the floor's bit is cleared), meets the ceiling above (the underside of the next floor up), rebounds down, and falls through the floor below. Today World has the face, the punch and the lodge (`lodge`: he ends inside, held 0.5 to 0.9 s). It has **no interior contacts after the first** and no ceiling.

**What the body does at each contact** (the sim has one point; these are what I draw):

| Contact | The body | The ragdoll | The pose |
| :--- | :--- | :--- | :--- |
| **The face** (`building_hit`) | stops against the wall, then goes through (tier 3 and up) or rebounds (tier 1 and 2) | a hard crumple by `vn`, the side that hit (R4), limbs trailing back out of the hole | a short held brace for the sim's stop (15 ticks, Game Design's), then `gc.bounce`-style release |
| **A floor slab, going through** | the slab breaks around the waist: the body folds over the edge for 3 to 5 ticks and goes on | a small crumple and a spine kick; limbs streamed along the velocity | no new pose: the streamer and the flail carry it, a short pose weight |
| **The ceiling** | the head or back meets the underside, the body compresses, then drops | `crumple` in the opposite sign to a floor's (arched back for a back hit, folded forward for a chest hit); a tangent kick (`vt`) for the spin | `ce.slam` (the compress against the ceiling) and `ce.rebound` (the body falling away, limbs up); two shared poses |
| **The second floor, falling** | the same break, now head or feet first down the shaft | as the first floor, with more fall velocity so the streamer is stronger | none |
| **A floor that holds** (a crack or a dent, `floor_hit` `crack`) | a bounce off the slab: the ground bounce, rotated | `bounce` with the slab's normal | `gc.bounce`, turned to the normal |
| **The end** | the lodge (held inside), or out of the building, or onto the street | see the hand-off | see below |

The pose count is 2 shared poses for the ceiling plus the 3 of the skid: **5 new poses**, no per-fighter ones (the flavour is the existing shape rows).

**The hand-off back to a fighter.** Four endings:
1. **Lodge** (existing): held 0.5 to 0.9 s inside, then control. The render adds `lg.climb` (a shared pose: he pushes himself out of the breach, one hand on the edge) and the join is the existing inertialise; the ragdoll's `free` decays at 18 per second and `out_w` fades at 8, so nothing snaps.
2. **Out of the building's far face** into the air: the flight lead takes over; the brake (3a) is available again; the recovery is the ordinary one.
3. **Onto the street:** the ground events already play (`bounce`, `land`, `tumble_end`).
4. **Reasonable time:** the sim's journey cap (4 s, 8 contacts, `journey_end` `capped`) is the upper bound. For the chain I ask Game Design for a **hard cap on the ragdolled time of a chain** (2.5 s from the face to the hand-off, first value) so the player has control back in a time that reads as reasonable, and for the brake to be live from the first tick after the last contact.

**Camera and Rendering.** The chain is inside a building: **Rendering's open floors** (the tower's lowest floors cut away across its width) are what let the chain be seen; the chain climbs, so a floor-by-floor cutaway that follows the body is theirs to say. Legal's g03 principle (a body drawn whole and in view every tick) applies by analogy: a chain through a building the render hides is a vanish.

## 5. What Game Design and World must give me, as events

All carry `actor`, `x`, `y`, `z`, `n` (the launch number) and `speed`, like the ground events.

| Event | From | Fields | Why |
| :--- | :--- | :--- | :--- |
| `interior_contact` | World | `b`, `floor`, `surface` (`face`, `floor`, `ceiling`, `wall`), `nx`, `ny` (the normal), `vn`, `vt`, `keep`, `punch` (bool), `k` (the contact's number in the chain), `stop` (ticks held, 0 if none) | each contact of the chain, in order, with its normal so I can choose fold or arch and pick the pose |
| `interior_end` | World | `end` (`lodge`, `exit`, `fall_out`, `capped`), `contacts`, `t` | the hand-off |
| `air_brake` | Simulation (Game Design's rule) | `phase` (`start`, `end`), `reason` (`released`, `speed`, `ki`, `hit`), `speed`, `dir` (the velocity's angle) | the mid-air skid's weight and the lead layer's exemption; the per-tick speed is already on the fighter |
| `hit_stop` | Simulation | `ticks`, `tier` | R5: the body's impulse waits for the release |
| `launch` `tier` | Simulation | `tier` (the launch's power tier 1 to 4) | R2's weight curve, and the flail's gain |

**From Game Design, as values (first values, mine to be corrected):** the ceiling's `keep` (0.4), the floor-through `keep` (0.7), the number of bounces a chain may have (3), the face stop in ticks (15, already in `buildings.md`), the cap on a chain's ragdolled time (2.5 s), whether the brake works inside a chain (I would say no until the last contact), and which tier chains reach the ceiling.

## 6. Joint limits throughout

- **Every added turn is cut to the largest share that stays inside** (existing). The six new degrees of freedom (R3) use the same machinery plus the comfort-twist rule, and a tumble that saturates a twist limit is the new scan class (`rd_twist`): it counts frames where a twist joint sits at its limit for more than a tenth of a second.
- **The new poses** (`ab.*`, `ce.*`, `lg.climb`) pass the joint audit A to D and the held lint before they join, and are scanned for `wing`, `hyper`, `overfold` and `kneein` in the bend scans (`_test_bends`).
- **A new frame class:** the skid's feet-first frames carry a `braking` flag the lead scan reads, and the live scan reports them separately so an exemption cannot hide a real feet-first flight.
- **The chain is a live-scan case:** a scripted launch through a three-floor building with a fake `interior_contact` series (before World has one) at every tier, scanned at four bodies for the joint classes and the hand-off's continuity (no bone turns more than 35 degrees in a tick across it).
- **Reduced motion** halves the ranges and the drive as today; the chain's pose weights go to 0.6 and the flail's twist components to 0.

## 7. Slices and order

| Slice | What | Needs |
| :--- | :--- | :--- |
| **RG0** | R1 (the launch number varies the flail) and R4 (fold or arch by the side that hit) | nothing |
| **RG1** | R2 (mass, tier, the lag chain) | `launch` `tier` |
| **RG2** | R6: `ab.*` poses, the layer, the lead exemption, `air_brake` | Simulation's `air_brake` |
| **RG3** | R3: six out-of-plane degrees of freedom, the twist scan | nothing |
| **RG4** | R7: `ce.*`, `lg.climb`, the contact handler, the chain scan | World's `interior_contact` and `interior_end` (a fake series first) |
| **RG5** | R5: the hit-stop release | `hit_stop` |

**Order:** RG0 first (nothing blocks it and it removes the "same flail every launch" fault), then RG3 (the biggest look change, in the render alone), then RG1, then RG2 and RG4 as the events land. Five code slices, 5 new shared poses, about 6 new scan checks, and a review pass of about 30 GIF pairs (each tier, each surface, the skid at three speeds).

## 8. For the clinch doc: Legal's new rows

Legal's `homework8-review-screen.md` rows bind `clinch-sizing.md`:
- **g06 (tied):** heads and torsos apart by at least a forearm's length, the held fighter's hands free and never limp or bound. My collar grip envelope (24 to 34 units centre to centre) must be read as *at least 27* (a forearm of 15 plus the two half-torsos). The `pair_clear` scan gets a `g06_apart` class.
- **g07 (pinned):** vertical against a surface only, at the shoulder, collar or upper arm; no forearm across the throat or face; hips apart; the pinned fighter's feet bear weight and he is shown struggling or bracing; **no ground pin, mount or straddle**. The pin's held poses need a bracing pose for the pinned body (`pin.brace`), which adds **1 shared pose**, and a scan for the grip point against the throat and for the hips' distance.
- **g08 (carried):** over the shoulder or by collar and waist, never the head, neck, hair or tail; drawn whole and in view; no glow at the hands.
- **h09 (the Anti-hero's folded arms):** the crossed-arm fold may not be an idle, stand-off or intro pose and not held for 12 ticks or more. The clinch doc's "the other arm stays folded high" becomes **a one-arm fold** (a single forearm across the body, the other hand free or at the chin), which h09 allows, and a scan that no fold pose appears in an idle, stand-off or intro sequence.

The clinch's pose count becomes 25 (13 shared with `pin.brace`).

## 9. The su_hammer step (to hunt, when the quiet window ends)

The facts: `ru.su_hammer`'s striking hand at 6 ticks after the contact reads 73.3 with the free hand's contact target at x 22 and 76.9 with it at x 23 or more, the same for every forward value. The method I will use, with one Godot process: play the `su_hammer` scene with the target at 22 and at 23, dump every bone's pose each tick for 12 ticks around the contact, and diff the two runs. The first bone other than the free arm's that differs, and the tick it first differs, name the coupling. Candidates I will check in that order: the free-arm slew's deadline (`ttc`) reading a shared counter; the contact solve's `hold_t` and `ci_end` release tick moving with the pose's measured reach; the join smoothing (`_inertialise`) carrying a bone offset from the free arm into the spine; the bake's `hunch_auto` shifting a clavicle that the striking arm's chain also reads.
