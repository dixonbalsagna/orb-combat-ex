# The camera director (Camera, 2026-10-19, design)

Owner: Camera and Cinematography. Orb, 2026-10-19: "a dynamic, directed, emergent cinematic storyteller that works with the combat choreographer so every camera movement feels purposeful and not distracting", with "different forms of whip panning, creative use of angles... a robust and dynamic camera system that doesn't lose track of fighters", and launch speeds rebalanced if that helps. This paper builds on Research's `docs/research/cinematic-storytelling.md` (its 19 rules and shot vocabulary are the basis; this page says how we build them on the rig we have, in what order, and what each needs from others). Rules: ADR 0010, `docs/ep/taste.md`, against d3f1ca0e. No fades, no dissolves, no frame-rate cost, nothing over the fighters.

## 1. What we have and what is missing

**Built and on main** (the placement and motion layer): the split screen and its layouts, pane and one-view follows with lag bounds, the launch chase, the blow push by weight (feel step 2), the one view's lead (step 4), the chase-not-hold launch (step 3), set pieces (building smash, transformation, crippling close-up, finisher, cut-in strips), the merge lookahead, the scroll governor, pitch shots. Parked: the brink in the beam clash (step 5).

**Missing:** the camera reacts to positions and to events after they happen. It never knows that a heavy lands in 9 ticks, that a launch will be sent east toward a tower, or that this exchange is the comeback. So it cannot anticipate, it cannot pace, and its set pieces are triggered by single events with fixed rules. That is the director.

## 2. The shape

| Layer | What it does | State |
| :--- | :--- | :--- |
| **Intent** | What the choreographer plans next: contact ticks, kinds and weights, pauses, launch vector and destination, story weight | Read today from `S.dirS.ex` (section 3, phase A); Encounter's `cam_intent` event later (phase B) |
| **Pacing** | Relax, build, peak, fade: from the mood band and act (they exist in `S.mood`), exchange density and story weight, with dwell and hysteresis. Sets hold lengths, the palette and push strength | New |
| **Editing** | Idioms per exchange template and set piece choose shots from the vocabulary (section 4) with a scorer: story weight, freshness, the variety rule (section 6). A committing tracker holds a shot its minimum time unless a heavier beat pre-empts it | New; today's set pieces become idioms |
| **Placement and motion** | The rig: frames a shot with springs, bounds and the split | Built |

All render-side, stepped on the fixed tick, seeded: a replay reproduces the camera, and it never writes the sim. A debug feed line per decision ("shot: exchange medium, beat heavy at +9 ticks, weight 0.6, held 0.8 s") goes to the existing debug overlay, as the director's own.

## 3. The intent feed

**Phase A, no new fields (Camera alone).** Render may read sim state. The running exchange is `S.dirS.ex` (`SimState.Exchange`): its `beats` are scheduled with their `t` on the exchange clock `ex.t`, with ops `strike`, `launch`, `rush`, `rushLand`, `press`, `beamArrive`, `beamImpact`, `clashResolve` and others; `ex.tpl` and `ex.branch` name the template; `ex.loser` is known when the branch favours one side; `S.dirS.stop` is the hit-stop in force. From that the camera knows the next contact (`strike` beat `t - ex.t` ticks ahead), whether a launch is coming, and the template. The clash already carries its outcome (`Clash.aw`), used by step 5. The mood (`S.mood.band`, `act`), the brink (`startBrink`), battered limbs and `act_change`, `decisive`, `finisher_start`, `last_stand_ready` give the story. Phase A is enough to build anticipation and pacing now.

**Phase B, asks for Encounter (through the EP).** One `cam_intent` event at each exchange start (Research rec 1), so the camera need not reverse-read the director:

| Field | Meaning |
| :--- | :--- |
| `n`, `tpl`, `branch` | the exchange |
| `beats: [{tick, kind, weight, actor, target}]` | each contact on the sim's tick clock, its kind (light, medium, heavy, guard_break, launch, beam) and weight 0 to 1 |
| `pauses: [tick]` | the bridging beats between phrases: where a reframe or a cut may go |
| `hold: [[from, to]]` | do-not-cut spans (multi-hit strings, grapples) |
| `launch: {tick, ux, uy, speed, dest_x, dest_y, building}` | the planned send: its vector, speed, where it should end (the planner's chosen candidate) and the building, if any |
| `story` | first_blood, reversal, crippling, comeback, decisive, finisher, or none |
| `focus` | the slot the story is about (the one being turned on, or the one turning it) |

And on a press-driven blow (the brawl, where nothing is scheduled ahead): the wind-up's start tick and expected contact tick (`attack` already carries kind and template; the contact tick is the missing part).

## 4. Shot vocabulary for high-speed combat

The default is the **two-shot** (both full-body, action and reaction in one frame, Research rule 2); every other shot returns to it within 1.5 s outside set pieces. On top of Research's table (5.2), the motion shots Orb asked for:

| Shot | What it does | When | Never |
| :--- | :--- | :--- | :--- |
| **Anticipation lean** | 4 to 8 ticks before a planned heavy or launch contact, the frame eases toward the contact point and tightens 2 to 4% | A `strike` or `launch` beat of weight ≥ 0.5 in the intent | Mid-burst reframes (it starts in the pause before) |
| **Speed whip** | The camera snaps into the launched body's velocity over 4 to 6 ticks (an ease, not a cut) and rides with him; he stays near a fixed screen point, the background carries the speed (VFX's streaks and parallax, never over him) | Launches the chase can match (section 5) | Any blur or fade on the frame |
| **Lead whip** | The camera leaves first: at the launch tick it travels toward the planned destination and arrives ahead of the body, which flies into a frame already waiting (the arrival wide) | Launches with a known destination (a building, the ground at a known point), from `cam_intent.launch` | When the destination is unknown or under 1.5 screens away (a chase is better) |
| **Return whip** | From the arrival back to the pair, fast and direction-matched (east stays right) | After the arrival hold, when the launcher is far | Crossing the pair (screen direction law) |
| **Arrival hold** | Wide enough for the damage, 0.3 to 0.6 s | Landing, `building_hit`, `lodge` | Holding while the next exchange starts |
| **Low angle** | The camera drops (pitch up toward the fighter, ground line low in frame) | Power-ups, a brink, a decisive approach | More than twice a minute |
| **High angle** | Pitch down a few degrees, the ground and the crater in frame | A fighter grounded or bested; the aftermath of a big send | Over a fighter at the frame's top (lost) |
| **Depth tilt** | The pitch shot that opens the street's depth (exists, Alt+F9's views) | Fights in depth (the depth window) | Flat fights |
| **Dutch tilt** | A cant of 4 to 8 degrees, eased in and levelled on the resolution | Peak pacing on a climax (decisive, the brink, a finisher) and menace high | Every exchange; any cant in reduced motion |

Rules for all of them: the subject is where the eye is (same screen position or the centre across a change); no cut and no reframe mid-move (only at a motion onset or in a pause); never lose a fighter (each shot names who must stay in frame; the existing out-of-pane watch is the guard, the sweep counts it).

**What the rig needs for these:** the speed whip and arrival hold are rig work (Camera). The lead whip needs the destination (phase B, or the building the B2 planner aims at, which the rig already reads for its building lead). The low and high angles use the pitch the rig already drives. **The dutch tilt needs a roll in `CameraRig` and the panes (Rendering)**: today the pane camera has no roll.

## 5. Launch speeds: what the camera can frame

Measured launches (the sweep's set, from QA): p10 1,677, p50 10,816, p90 26,718, max 45,606 units a second, reached in one tick. At 720p the fight size (R_FIGHT 0.11, 1.06 px a unit) and the floor (R_FLOOR 0.032, 0.31 px a unit):

| Speed (u/s) | Screen widths a second at fight size | at the floor | What the camera can do |
| :--- | :--- | :--- | :--- |
| 1,700 | 1.4 | 0.4 | follow smoothly, both in frame |
| 2,500 | 2.1 | 0.6 | ride with him (speed whip); the eye's ceiling at fight size |
| 5,000 | 4.1 | 1.2 | ride with him only; background must streak |
| 10,800 | 8.9 | 2.6 | ride with him; nothing in the background reads; a cut is cleaner |
| 26,700 | 22 | 6.4 | nothing reads; today: the chase snaps or the pane cuts |

The eye tracks smoothly up to about 0.6 widths a second on a monitor and has a ceiling near 1.9 (Research section 4). So a body at the median launch speed is a smear the camera can only chase or cut away from.

**The ask (Game Design, Encounter, Simulation, through the EP): a launch in four parts**, distance and airtime kept so the planner's destinations and the destruction still work:
1. **Hit-stop** by weight (Research rec 10: 14 to 18 ticks for a launch);
2. **Snap:** full speed for 4 to 6 ticks, the "huge force" read, the camera's speed whip starts on it;
3. **Glide:** eased down to a readable speed, about 2,000 to 3,000 units a second, for most of the flight (the camera rides at fight size; the body readable, the background carrying speed);
4. **Arrival:** a short ease into the impact, then the arrival hold.

For a long send (a tower three blocks away) the glide is where the lead whip goes ahead to the destination. If the flight time must stay as it is, a shorter snap and a slightly faster glide (3,000 to 4,000) is the second-best; above 5,000 the camera can only cut.

## 6. Emergence and variety

- **Context picks the variant:** stakes (health, the brink, story weight), tier, biome (city: low angles against the towers; ocean: high angles on the water; mountains: the ridge), distance, altitude, the stance pair. The most specific rule wins (Research 5.3).
- **The variety rule:** no two expensive shots of one type in a row unless continuing the beat; a cooldown per type (the same angle family at most twice a minute, a whip type not twice in 10 s); an overexposure penalty with a freshness bonus; a repeat only as a callback on a decisive beat. Ties break on the render's seeded stream (replays match).
- **Pacing drives the palette:** relax uses the two-shot and lead; build adds the anticipation lean and exchange mediums; peak adds whips, angles and the cant; fade returns wide (re-establish) and levels.

## 7. Fighter size (the EP's note on step 4)

The fighters are about 30 px tall in wide city shots because the one view zooms out until a fighter is 3.5% of the screen height (R_SPLIT, 25 px at 720p) before it splits, and the scroll governor zooms out further at speed (SCROLL_MAX, set for the flash count). Proposal, as its own step with a side-by-side: split sooner (R_SPLIT 0.035 to about 0.055, R_MERGE 0.047 to about 0.07: fighters at least 40 px in one view), and relax the governor's limit (0.045 to about 0.07 of the width a tick: fewer zoom-outs at speed). Each pane shows its fighter at fight size; the split screen is what Orb liked.

## 8. Build order (each step parked with a side-by-side against d3f1ca0e, split_sweep, seam, pane, determinism)

1. **Fighter size** (section 7): two constants and the governor; measured by drawn height per scene.
2. **Intent reader (phase A)** and the debug feed line: the next contact, the template, the launch beat, from `S.dirS.ex`; no visible change, a probe.
3. **Anticipation lean and pacing machine** (relax, build, peak, fade from mood and density).
4. **Speed whip and arrival hold** on launches (needs nothing from others; better with the launch-speed ask).
5. **Angles:** low and high by context; the dutch tilt when Rendering adds roll.
6. **Lead whip and return whip** (phase B's destination, or the B2 building).
7. **Variety rule and idioms** over all of it; a clip set of seeded matches judged against d3f1ca0e.

## 9. Asks, in one list (for the EP to route)

| Who | Ask |
| :--- | :--- |
| **Encounter** | `cam_intent` at exchange start (section 3, phase B); the wind-up start and contact tick of a press-driven blow |
| **Game Design, Encounter, Simulation** | Launches in four parts (section 5): hit-stop, a 4 to 6 tick snap, a glide at 2,000 to 3,000 u/s, an arrival ease; distance and airtime kept. Hit-stop by weight (Research rec 10) |
| **Rendering** | A camera roll in `CameraRig` and the panes, for the dutch tilt (4 to 8 degrees, eased) |
| **VFX** | Background streaks and parallax during a speed whip, keyed off the camera's frame (never over a fighter) |
| **UI** | Whether the off-screen chip shows for the winner at a beam clash's brink (step 5) |

## 10. Built so far

**Step 1, fighter size (parked: docs/camera/pending/director-step1-fighter-size.patch, on b3a3aa74).**
- The one view now splits before a fighter gets small: `R_SPLIT` 0.035 to 0.055 (40 px at 720p) and `R_MERGE` 0.047 to 0.07.
- The wide "flying around the world" hold while a pair parts is shorter: `WIDE_HOLD` 1.0 to 0.4 s.
- The scroll governor under Reduce flashing (the shipped default) is relaxed: `SCROLL_MAX_REDUCED` 0.03 to 0.045, the ordinary mode's figure. It was the flash count's rule, and the flash work is paused.
- The ordinary mode's 0.045 stays. At 0.07 the sweep's `scroll governor fast` row kept a fighter off the screen for 93 ticks against a bound of 77.

Measured (`clip_digest.gd` SIZE, reduced, 3,600 ticks), as the share of time a fighter is drawn under 40 px, before and after:

| Scene | Before | After |
| :--- | ---: | ---: |
| rushcity | 14.3% | 9.7% |
| ai 7 | 8.4% | 5.4% |
| signaturecity | 5.3% | 3.0% |
| ai 4 | 3.0% | 1.7% |

- The p10 in rushcity rises from 35 to 40 px. The medians don't change: the fight size is already 61 to 86 px.
- The time a fighter is outside the picture falls in ai 7 from 205 to 90 fighter-ticks.
- The cost is 2 to 3 more layout changes in 3,600 ticks.
- What is left under 40 px is the split line itself (the one view at about 39.6 px just before it splits), the rush's divider slam, a layout change's own frames and the launch shot's far opponent.

Gates: split sweep, seam sweep, pane check, determinism plain and --intro all pass. Clips: homework/camera/9-fighter-size/. Each scene has two clips: main against this, and d3f1ca0e against this (a rush in the city, an AI match).

**The inset's first render (parked: docs/camera/pending/inset-warm.patch).** Rendering found a first-use hitch at tick 238 of the AI match: the inset viewport's first render, when the first strip opens. The compositor now draws the inset once (`UPDATE_ONCE`) on the first frame after it is made, where pane 0 looks. Nothing on screen shows that frame. So that cost comes at the match's start, and the first strip draws a viewport that has already rendered. The pane check passes (a scratch probe saw `UPDATE_ONCE` on the first frame and `UPDATE_DISABLED` on the next), as do determinism plain and --intro. Performance should time it.

**Phase A on Encounter's feed (parked: docs/camera/pending/director-5-intent-feed.patch).** The rig reads `cam_intent` cues (docs/director/camera-intent.md), which are on main behind `cameraIntent.enabled`:
- From a `plan`: its told contacts (launch, heavy, a set piece's strike), its do-not-cut spans and its story weight and tags.
- From a `launch`: the predicted touchdown {x, n} per sent slot, kept for the lead whip.
- Once a cue has come in a match, anticipation takes its next contact from the feed. Without the feed it reads `S.dirS.ex`'s beats as before.
- A discretionary split or merge waits while a do-not-cut span runs. A fighter out of the frame or knocked apart still opens at once.
- Fields for the debug feed and the climax shots: `intent_src` (feed or ex), `intent_now`, `story_w`, `story_tags`, `nocut_holds`.

Measured with the feed on, across ai 4, 7 and 39, mashcity, rushcity and clashcity (3,600 ticks each):
- Anticipations are within 1 or 2 per scene of the old reader.
- Cuts, layout changes and the time outside the picture are unchanged.
- 0 to 3 layout changes per scene fall inside a do-not-cut span. All of them were forced (holds 0), so the rule is a guard these scenes didn't need.
- `clip_digest.gd` prints INTENTFEED: the plans, the spans and the changes inside them.

There is no visible change, so there are no clips (build order step 2: a probe). Gates with the feed on and off: split sweep, seam sweep, pane check, determinism plain and --intro all pass. With all three patches together: split sweep, pane check and determinism pass.

**Step 2 and 3, the intent reader and anticipation (on main, 02a37e53).** Each tick the rig reads the running exchange's scheduled beats (`S.dirS.ex.beats`, read only) for the next contact within 18 ticks that weighs: a launch or a launch ender (weight 1), a heavy (0.7); lights and mediums do not. Before it, in the plain one view, the focus leans a quarter of the way to the contact point (both fighters kept inside 0.42 of the width) and the view tightens: 20% before a heavy, 6% before a launch (a launch is followed by a chase or a split, and the split's opening must start near the pane's size). In fast (0.1 s), out slower (0.25 s); the blow push lands on top at the contact. Not in a clash, a layout change, a solo shot, the intro or reduced motion. `SplitRig.anticipation`, `intent_now` (the read, for the debug feed), `CamParams.ANT_*`. About 11 a minute in an AI match. Encounter's `cam_intent` (docs/director/camera-intent.md) will replace the reading of the beats when it lands. Gates on both patches over a2b6b5dd's tree: split sweep, seam sweep, pane check, determinism plain and --intro: pass. Clips: homework/camera/6-anticipation/ (left step 5, right this: a mash, launches in an AI match).

**Step 4a, the launched body at fight size (on main, 6bb89cef).** The chase zoomed a launched body out with the scroll governor (the flash count's rule of 2026-10-12: the scenery no faster than 0.045 of the width a tick), so the subject of the most exciting shot was the smallest thing on screen. The governor is off for a launched body now (`SplitRig.launch_governor` false; on restores it) and the chase size is the fight size (`R_LAUNCH` 0.08 to 0.11): the body stays near his anchor at fight size and the background carries the speed (VFX's streaks will sell it, docs/camera/director.md section 9). The launched body's drawn height at 720p, median before and after: ai 4 47 to 71 px, ai 7 51 to 71, ai 39 50 to 77, rushcity 39 to 78, signaturecity 46 to 82; the time a fighter is outside the picture up 2 to 5%. Gates: split sweep, seam sweep, pane check, determinism plain and --intro: pass. Clips: homework/camera/7-launch-at-size/ (left step 6, right this).

**Step 4b, the launch curve's camera (on main, 77f6c71f).** Game Design's ruling (docs/design/rulings-2026-10-19.md): "Push at the stop, whip on the kick, frame the glide, hold the arrival." With Simulation's curve on (`data/fight/flight.json`, `hitstop.json`), the beats map as follows:
- **The stop:** the launch's blow push (step 2), held for the launch's hit-stop.
- **The kick and the glide:** the chase at fight size (step 4a). With the curve on, the chase's travel is smooth: about 0.105 of the width a tick on the kick, 0.037 on the glide and 0.041 on the arrival. With the curve off, the same launch travels unevenly from tick to tick.

The new piece is the **arrival hold**. From Simulation's `flight` cue `arrive` (the contact about 10 ticks ahead), the chased body's pane widens by 15% over 0.15 s to take in where he lands. It holds 0.45 s past the contact (`end`) and lets go over 0.35 s. A new `kick` cancels it. It is off in reduced motion. `SplitRig.arrival_hold`, `arrivals`, `CamParams.ARR_*`.

With the curve on, the split sweep failed in three real-match rows by a hair: pane 1's zoom rate reached 2.51 to 2.52 e-folds a second against 2.47. This happened with the curve alone and no camera change. The cause was the launch's blow push easing out while the chased body's pane opened, on top of the opening's own zoom at its comfort rate. The push now holds through a layout change and lets go once the layout is still.

QA's row (the sent body in frame for at least 95% of the flight) measures 100% in ai 4, 7, 9, 39 and rushcity, in both modes. Cuts, layout changes and the time outside the picture are unchanged. The arrival takes the launched body's median from 71 to 68 px in ai 4 and from 71 to 66 px in ai 7.

Gates were run on 84951962 with steps 4a and 4b and Simulation's feel park, curve on and curve off: split sweep, seam sweep, pane check, determinism plain and --intro all pass. Clips: homework/camera/8-launch-curve/. The left side is the curve on with main's camera (a), the right side is the curve on with this patch (b): a curved launch in ai 4 and a short one in ai 7.

**The speed cut: built in scratch, measured, looked at, not shipped (2026-10-22).** Game Design's ruling 19b says a cut is the only answer above 5,000 units a second. I built it as follows:
- A pane chasing a send still faster than 5,000 u/s as it nears the touchdown Encounter's feed predicts (`launch` cue: x and n, exact) cuts to a still frame.
- The frame puts the touchdown at 0.70 of the width from the side he comes from, with him already in it. It holds through the impact, then cuts back in.

What happened:
- **The fighter slides out.** He keeps sliding 2,000 or more units past the touchdown, so the first version lost him: launched-body in-frame fell to 71-85%. Ending the still once he nears its edge brought it back to 100%.
- **The geometry leaves too little time.** At a readable size the still frame is 1,500 to 2,500 units wide. At 9,000 to 20,000 u/s it can hold him only for the last 4 to 15 ticks before the touchdown. Any earlier cut loses him, which breaks QA's 95% row.
- **At the floor size it fires but looks worse.** The still frame came 9 ticks ahead, and the fighter was a speck at 23 px.
- **At 36 px it rarely fits.** It never fired in the web capture at 1024 x 768.

Looked at side by side in ai 7, the chase at fight size with VFX's flight streaks (steps 4a and 4b) reads better than either still. So above 5,000 u/s the answer stays the chase. Simulation's curve brings the glide to 2,000-3,000 u/s, and then only the 8-tick kick is above 5,000, which is the whip. A cut to the destination needs the body to be allowed out of the frame. That is a ruling for Game Design and QA, not a camera change.

**Combat's four camera events (2026-10-22).** Only `recoil` exists. It is Encounter's park (docs/director/pending/recoil-flips/, `recoilFlip`, off) with its `counter_rush` cue. Ricochet, clash_meet and turn are not built yet.

I applied the recoil park in scratch with the feed on: 8 recoil cues in 12 minutes of AI play (ai 4, 7, 9 and 106), 5 flips, 2 flourishes and 1 counter-rush. Across the windows from each cue to 20 ticks past its landing, the existing camera keeps both fighters in the picture on every tick and changes layout once in 8 windows. An exit is 1 to 4 body heights, and that fits inside the one view's fight-size frame.

I built a framing that takes in the striker, the recoiler and his landing from the cue, and holds the layout through the counter window. It changed nothing measurable, so it is not parked. The cue is read again when ricochets (a body leaving the frame) and B meets (`big`) exist.

**Story slots for the roll (parked: docs/camera/pending/story-slots.patch).** `story_a` and `story_d`, the running plan's attacker and defender slots, sit next to `story_w` and `story_tags`. Rendering's dutch tilt can then roll toward the plan's defender on story_w of 3 or more or the decisive and finisher tags. Gates on 5fe08207, feed on and off: split sweep, determinism plain and --intro, and pane check pass.

**Lead and return, measured (2026-10-22; no build).** These numbers are from `clip_digest.gd` SEND, over 19 sends the feed announced in 8 scenes:
- **Lead.** The feed's touchdown is the first ground contact, and most flights reach it in 1 to 18 ticks. The chase keeps 0.44 to 0.72 of the width ahead of the body. The landing comes into view 0 to 6 ticks before the touchdown. Only 2 of the 19 flights are longer than 30 ticks. The building lead (`_aim`) already shows a building send's target, so ground and mountain sends need nothing more.
- **Return.** In human play the opponent keeps a pane. After a far send the pair is back in one view in 58 to 120 ticks, with 0 to 8 fighter-ticks outside the picture (rushcity). In AI against AI the launch shot shows only the sent body by design.
- **Off the table** unless Orb asks: the lead whip that pans ahead of him, like the destination cut, because QA's in-frame row rules it out.

**The variety rule, measured (no build yet).** `clip_digest.gd` SHOTS counts the expensive shots: strips, cut-ins, transformation shots and the divider slam.
- An AI match has 6 to 9 in 2 minutes. At most one same-type pair falls within 10 s per match. The pairs within 3 s are one clash beat: the signature strip, then the clash strip.
- The repeats are the rush's divider slam in rushcity (11 in 2 minutes), which is the rush's own door.
- The existing rationing (strip priority and earned gap, the cut-in cooldown and per-minute cap) already keeps variety. A shared ledger would change nothing today, so it waits for the next shot types (angles, whips).

**The zoom floor on the ring (parked: docs/camera/pending/director-6-ring-floor.patch).** `SplitRig.z_min(vw)` is `ZOOM_MIN`, or the zoom at which a pane shows `RING_SHOW` (0.9) of World's ring, whichever is larger. It applies wherever the floor clamps.
- In play the widest pane shows at most 0.19 of a 600-column ring and 0.11 of a 1,200-column ring, so the floor never binds there.
- A forced fold (a probe on planet 7) is where it matters. With a radius of 8,000 on a 600-column ring the pane showed 1.73 rings, so the ground repeated. A radius of 30,000 showed 5.31. With the floor both are 0.89.
- No sim code sends `fold_start` today; the floor guards the fold and the composed wides.
- `clip_digest.gd` takes `--arena=N` and prints WIDEST.
- Gates: split sweep, seam sweep, pane check, determinism plain and --intro all pass.

**Pacing (parked: docs/camera/pending/director-7-pacing.patch, on the ring floor).** `SplitRig.pace` is relax, build, peak or fade (render-only, read by the debug feed and, later, the shot choices):
- **Peak:** a decisive event, a launch, a transformation, a finisher or a strip-worthy moment in the last second, a running plan of story 4 or more, or the brink.
- **Build:** 3 blows in 2 s, a lean or a clash.
- **Fade:** 1.5 s after a peak when the blows stop.
- **Relax:** the rest.
- Each state holds at least 0.5 s.
- Blow density alone is not a peak, because an AI brawl lands 8 blows in 2 s most of the time. In the first cut peak was 25 to 50% of the time.

Measured share of time: in AI matches peak 12 to 27%, build 55 to 70% and relax 6 to 21%; rushcity and clashcity are mostly relax.

What pacing changes:
- **Blow push weight:** relax 0.6, build 1.0, peak 1.3, fade 0.8.
- **One-view size:** the reference size in relax and build, 1.05 at a peak and 0.93 in the fade after it. It is eased over 0.6 s, in the plain one view only, and held under a cut-in. A strip is drawn over the main view, so the size eases on under it. About 7 peaks a minute reach the one view.

Tried and dropped:
- Weighting the anticipation push by pace moved the main view under a strip.
- Sizing relax at 0.95 changed the reference framing the sweep holds.

The sweep's `_watch_first` now starts the display-frame chain afresh on a re-seed. A re-seed is a new match: the panel rows run twice from one rig, and the pace size of the first run made a jump between them that no player sees.

Cuts, layout changes and the time outside the picture are unchanged. The effect is subtle on purpose: a few percent of framing. Gates: split sweep, seam sweep, pane check, determinism plain and --intro all pass. Clips: homework/camera/10-pacing/ (two AI-match segments around a peak and its fade against main, and ai 7's opening against d3f1ca0e).

**The ring's turn: a motivated cut (parked: docs/camera/pending/director-8-arena-turn.patch, on babc83d8).** At a calm moment World turns the ring about the pair (window 3), and Rendering rebuilds every pane's ground on the `arena_turn` tick (22d).

On that tick every camera hard-cuts (snapped, as a relocation is) to a low wide:
- every shown pane at 0.6 of its size;
- pitched up 6 degrees, limited as the transformation's low angle is so the camera stays above the ground at the pair's feet;
- the far land against the sky. That is the only land the turn changes: past 12,000 units.

The wide holds 1.2 s and cuts back to the fight's framing. The pitch returns on the same tick, so there is no second cut. No dissolve, fade or wipe. Under a still camera the ridges behind change on that tick (148,000 pixels at fight framing, Rendering), so the cut is what hides the pop. `SplitRig.turn_cut`, `turn_cuts`, `CamParams.TURN_*`.

Tried and dropped:
- **A plain dolly out** only shrank the fighters: the far land barely changes with the camera's distance.
- **A high angle (+18 degrees)** looked into the slope behind the pair, with no sky and none of the new land.

Measured:
- The sweep's new rows (`arena turn, one view` and `arena turn, split`, a synthetic event) check that the cut is on the tick, each shown pane is at least 20% wider, both fighters are on the screen, the wide holds still, the cut back comes at tick 72 ±1 and the framing returns within 5%.
- A real turn is forced in the digest: `--arena=2400 --turn-at=4800` asks World on planet 7 and takes the widest bearing, as Rendering's stills did. In ai 4 the turn came at tick 4939 and in ai 39 at 4917. Each time the cut flag was on that frame and no fighter was outside the picture in the wide. ai 7 found no calm before tick 5400.
- In the web capture the build with the cut and the one without differ first at tick 4939.

Gates on main plus World's window 3, Rendering's 22d and VFX's arena-turn park: split sweep, seam sweep, pane check, determinism plain and --intro all pass. Clips: homework/camera/11-arena-turn/. One is the same turn with the still camera against the cut. The other is d3f1ca0e's ai 4 for the look against the cut (d3f1ca0e has no planet world, so it is a different moment).

**Angles by context (parked: docs/camera/pending/director-9-angles.patch; it applies before or after director-8 in either order).** A decisive moment (a peak by the pace's own rule) in the plain one view gets a hard cut to an angle:
- **The triggers:** a knockback, a guard break, an interrupt, a barrage, a beam or a clash.
- **The conditions:** no strip, cut-in, shot or lunge of its own.
- **The angle comes from the ground under the pair:**
  - low (-7 degrees, ground-limited) in the city, the towns and the mountains;
  - high (+10) over the ocean and the forest;
  - on open ground it alternates with the last angle used.
- **The shot:** held 1.0 s while the camera keeps following, then a hard cut back. Both cuts snap the cameras.
- **The variety ledger:** one angle shot in 20 s at most.

`SplitRig.angles`, `angle_shots`, `angle_now`, `CamParams.ANGLE_*`.

Measured:
- About 7 decisive moments a minute reach the plain one view in AI play, nearly all knockbacks, so the ledger is the rationing.
- Angle shots were 2 to 3 per 2-minute scene: ai 4 low at 356 (desert) and high at 2023; ai 39 low at 840 and high at 3007 (forest); collapse low at 151 and 2201 (city). Each adds two cuts.
- Size and the time outside the picture are unchanged.
- Looked at: the low angle sets the pair against the sky with the horizon low. The high angle looks down on the field, where the ground's cracks and scorches read.

Gates on babc83d8: split sweep (also with director-8 stacked), seam sweep, pane check, determinism plain and --intro all pass. Clips: homework/camera/12-angles/ (a low angle in the desert and a high one over the forest, each against main, and d3f1ca0e against this).

**The high angle, re-cut (2026-10-22, the EP's look gate).** At +10 degrees the sky was gone and a flat brown ground plane filled half the frame. The camera's vertical field is 30 degrees, so looking down by p puts the horizon 1.866 tan p of the height above the middle. +5.5 degrees keeps about a third of the frame for the horizon and the sky (+10 kept a sixth, before ridges).

The high angle is now used only where the ground has something to show:
- **The test:** within 1,000 units of the pair, a crater, a building, or 8 columns scorched or cracked (`_ground_shows`, `CamParams.ANGLE_SHOW_*`).
- **Elsewhere:** the ground-limited low angle, or none.

The low angle (-7, ground-limited) is unchanged. In ai 4, 39 and 7 the high angles fired at 2023 (desert, among craters), 3007 (forest, scorched) and 2244, each at +5.5 degrees. Clips: homework/camera/12-angles/4 and 5 (the re-cut, forest and desert craters, against main). The +10 version was removed.

**An escaping fighter (2026-10-22; a guard row, no camera change).** As the game ships (the travel budget off), the camera keeps an escaper in the picture that shows him:

| Escape speed | Ticks off of 180, both modes |
| :--- | ---: |
| 2,500 to 6,000 u/s | 0 |
| 9,000 u/s | 5 |
| 12,685 u/s | 0 |
| 20,000 u/s | 9 (a short catch-up) |

My first report said the opposite. The probe was a split_sweep row, and split_sweep runs with the travel budget on (`budget_on`), which the game does not ship. The escaper's median drawn height is 46 to 47 px above 4,500 u/s. That size comes from the one view widening as the pair parts before the split, not from the scroll governor (the chase at size moved it to 50 px), so no change was made.

The guard is parked as docs/camera/pending/escape-row.patch: the split_sweep rows `escape 2500 to 5000`, normal and reduced, with the row setting the shipped budget off itself. Each fighter may be outside the picture at most 6 ticks in 3 s.

**The inset warm-up, withdrawn (2026-10-22; parked: docs/camera/pending/inset-warm-removal.patch).** The warm-up above never drew the match's inset. The compositor attaches and warms before `main.start_match`, which builds every pane again. A frame-bench from tick 0 shows no frame over 187k primitives before the first strip, while a strip frame is about 650k.

Re-armed at each match, it drew the inset at tick 0 (52.6 ms there), and tick 238 did not drop. On a quiet machine Performance found that the strip adds nothing measurable at tick 238: the hitch is the first crater's first use, which Rendering's boot warm-up (22e) clears. So the warm-up is removed: the patch restores the code as it was before it. Pane check and determinism plain and --intro pass.

## 11. Smoothness: every instant change, eased, whipped or justified (2026-10-23)

Orb, 2026-10-22 (docs/ep/vision.md): "the camera looks like it snaps too fast, all dynamic camera movement should be smooth, no instant movement unless well justified by real cinematography theory". Research's docs/research/cuts-and-eases.md gives the frame: every change is an ease, a cut or a crisp whip (8 to 15 frames, a hard ease at both ends, no blur: Orb's taste rejects blur). A cut needs one of five reasons and meets its conditions. Parked: docs/camera/pending/director-10-smooth.patch.

**How the audit was done.** Each place the rig cuts or snaps carried a counter in a scratch copy. Nine scenes were digested in both modes, 3,600 ticks each (ai 4, 7 and 39, rushcity, signaturecity, collapse, mashcity, clashcity, transform).
- The angle shots were the most frequent visible cuts: two per shot, two or three shots per 2-minute scene.
- The follow's catch-ups fired only at a scene's first tick.
- The side swap's cut flag carries no visible move.

**Eased now (no cut):**

| Change | Before | Now | Research's range |
| :--- | :--- | :--- | :--- |
| The angle shot | a hard cut to the angle and back | a crane tilt: in over 27 frames, held 1 s, back over 36 frames; at most 0.4 degrees a tick (`ANGLE_IN`, `ANGLE_OUT`) | reframe, 18 to 36 |
| A change of angle | any pitch change marked the frame a cut | only a jump over 1 degree in a tick is a cut (`PITCH_CUT_DEG`): the authored shots' jumps | |
| The arena turn's way back | a hard cut back after 1.2 s | eased back to the fight's size and level over 30 frames (`TURN_OUT`) | return, 18 to 30 |
| The blow push | up in 3 frames | up in 7 frames, a fast start and a soft landing (ease-out); back over 15 frames as before (`BLOW_UP`) | impact push, in 5 to 10, back 15 to 25 |
| The transformation's live punch-in | a 6-frame triangle | a 12-frame eased pulse, peak at 6 (`LIVE_PUNCH_LEN`) | impact push |
| The anticipation lean | a 0.10 s ease in | a 0.18 s ease in (`ANT_TAU_IN`) | reframe |

**No jump when moves overlap.** An eased angle (an angle shot, the turn's way back) keeps the angle while it eases. A shot that starts or ends meanwhile (a launch shot, a merge) leaves it to ease out instead of setting it level at once (`_pitch_in_move`). The first web capture of the eased build caught it: a launch at tick 2106 under a high angle jumped 5.5 degrees in a tick (102,656 pixels). It is gone, and in five scenes no pitch jump over 1 degree is left in play.

**Whipped now (no cut):** the follow's catch-ups. A fighter more than a screen from his anchor (the lag bound, a rush ended early, a launch hold let go) is reached by a crisp whip of 12 frames (`WHIP_TICKS`, smootherstep, hard at both ends, no blur), up to 3 widths. Research: "the framing target jumped is not a reason". Beyond 3 widths a move would only smear: that is a change of space, and it cuts (`WHIP_MAX`, `_catch_up`). The sweep's launch rows whip (2.9 widths) and pass. In five scenes of play none fired.

**Kept as cuts, each with its reason (Research's five) and its conditions:**

| Cut | When | Reason | Conditions |
| :--- | :--- | :--- | :--- |
| The arena turn's cut in | World turns the ring; Rendering rebuilds the ground on that tick | 3, a scene change: the world beyond the pair is a new one, and under a still or eased camera the ridges pop (148,000 pixels at fight framing) | 1.67 times the scale (a shot size); at a calm pause the director holds; the pair stay at the centre. Its way back is eased |
| The transformation's break and settle (full version, ordinary mode) | the break's beat and the settle's | 5, a shock beat (a transformation's release); 1, on the break's onset | an authored low angle, a shot size; on the beat. Under Reduce flashing it is eased with no cut |
| The building smash insert, in and back | a big building's first hit | 1, cut on action, and 4, the reveal of the damage; the return ends the insert | a wide of the wall, more than a shot size; at the impact; the return to where he was |
| The rush pin | a rush longer than a screen | 3, a jump a move would only smear (a blitz): the departure matched to the arrival | the pane at the arrival; at the rush's onset |
| The hold's cut to the victim (launch_follow "hold", an option, off) | the impact | 1, cut on action at the impact | |
| A relocation, a replay seek | the sim moves the pair | 3, a change of space or time | |
| The intro's face cuts and two-shot | the staredown | 3, into and out of an authored set piece (shot and reverse shot) | |
| A shot over another (the KO's wreck after the close-up) | the KO's beats | 3, an authored set piece's shots | |
| A catch-up beyond 3 widths | a scene's first tick, a subject on the far side | 3, a change of space | |
| The side swap's cut flag in one view | the pair change sides | Not a visible change: the divider is not shown in one view | |

**Not mine, suggested:** Rendering's roll eases in over 0.25 s (`RenderLook.ROLL_TIMES.x`), which is 15 frames. Research's dutch roll is 30 to 90 frames; 0.5 s would sit in it.

**Unchanged and already eased:** the split's openings and closings morph at the comfort rates, the panes blended by smootherstep of the separation. The divider slam was a 0.14 s door that closed on the rusher's impact; since follow-up 2 (below) it is a 12-frame crisp whip. Research's reason: a move across a gap a cut would make, on the action (the rush's contact), eased hard at both ends, no blur.

**Measured** (`clip_digest.gd` STATS, cuts in 3,600 ticks, reduced / ordinary):

| Scene | Main | This |
| :--- | ---: | ---: |
| ai 4 | 5 / 7 | 1 / 3 |
| ai 7 | 7 / 9 | 3 / 5 |
| ai 39 | 5 / 7 | 1 / 3 |
| rushcity | 22 / 20 | 16 / 14 |
| signaturecity | 10 / 10 | 5 / 5 |
| transform | 5 / 7 | 2 / 4 |

- Sizes, layout changes and the time outside the picture are unchanged.
- In the web captures (960 x 540) the new build has no frame-to-frame jump over 150,000 pixels in the angle segments. In the turn it has only the cut in (142,000 at tick 4939); main also cut back (148,000 at 5010).
- New split_sweep rows:
  - `angle shot`: the tilt reaches its angle and returns to level, never steps more than 1 degree a tick, and never cuts.
  - `arena turn`: the cut in is on the tick and the wide holds still; the way back has no cut, keeps the zoom step under the comfort rate, keeps both fighters on screen and returns within 5%.

Gates on 6ef1e3f1: split sweep, seam sweep, pane check, determinism plain and --intro all pass. Clips: homework/camera/13-smooth/.

**Each pane's visible half-plane, for Rendering's culling (2026-10-23; parked: docs/camera/pending/pane-visible-half-plane.patch).** The integrated GPU's 33 ms stretches in the city beam (Performance, ticks 470-563 and 1162-1316) are not a wide shot. Read from the camera, no pane in any scene is wider than 4,160 units. At those ticks the camera is in the split. Each split pane renders the whole world full-screen while only its side of the divider is shown, so the terrain is drawn twice (205k to 211k triangles against 132k).

`SplitFrame.visible_half_plane(i)` returns:
- `{"all": true}` when pane i fills the screen;
- `{"none": true}` when it is not drawn;
- else `{"n", "d"}`: a screen point p can show in pane i only if n.dot(p) >= d.

It is the compositor's own test (`weight1`), widened by the feather, half the line, the largest shake (4.2% of the height: a pane's jitter moves its picture, not the divider) and 8 px (`VIS_MARGIN_PX`).

Rendering culls or coarsens the terrain chunks that fall wholly outside it. A split_sweep check on every display frame of every row confirms that no sampled point a pane shows falls outside its plane. Gates: split sweep, seam sweep, pane check, determinism plain and --intro all pass.

**The speed lead (2026-10-23; parked: docs/camera/pending/director-11-speed-lead.patch).** The framing leads the faster fighter's travel. Every part is eased and none of it cuts (section 11).
- **One view.** The lead (`merged_lead`, step 4) worked only when the pair moved the same way. Now, when only one fighter is moving away from the other (a dash out, an escape), the focus leads his travel by half his speed (the pair's midpoint moves at half his speed) times 0.3 s (`MERGED_LEAD_FAST`). The same cap applies, and both fighters stay inside the middle 80% of the width.
- **Split panes.** They had no lead room for a free fighter. Each pane now leaves room ahead of its own free fighter: his speed times 0.3 s, at most 0.08 of the width, faded in between 600 and 2,500 u/s, eased over 0.35 s (`PANE_LEAD_*`, `_update_pane_lead`). It is never closer to the divider than 0.6 of the rest anchor's distance from it, and it is off in a shot, a chase, an expansion, a layout change and reduced motion.

Measured (`clip_digest.gd`, reduced, 3,600 ticks), the room ahead of a fighter faster than 1,200 u/s as a share of the width, main then this:

| Scene | Split pane | One view, the faster moving away |
| :--- | :--- | :--- |
| ai 4 | 0.769 to 0.785 | (none) |
| ai 7 | 0.780 to 0.833 | 0.230 to 0.261 |
| ai 39 | 0.780 to 0.793 | (none) |
| rushcity | 0.640 to 0.670 | 0.328 to 0.349 |
| signaturecity | 0.774 to 0.810 | 0.457 to 0.469 |

- Cuts, layout changes and the time outside the picture are unchanged. Zoom reversals are the same, except rushcity's (39 to 41).
- The effect is modest. The split's anchors already sit a fighter on the outer side, and in one view keeping both fighters inside 80% limits it.
- To watch: in the split, the left pane's fighter may sit about 30 px nearer the screen's left edge, where the key help is drawn.

Gates on 97ec9985: the 18 headless render checks pass (after, city, cue --profile=spaced, depth, flash, flash_reg, flight, ground, hud_words, lane, open, pane, patch, shape, sky, stage, seam sweep at 1280x720, determinism; outline and cull need a window and were not run), as do split_sweep and determinism --intro. Clips: homework/camera/14-speed-lead/ (a rush in the city, main against this, and d3f1ca0e against this).

**The flight follow's mass (2026-10-23, window 1; on main in 4cbf8b37).** Orb: "rides the action with mass". The follow's springs aimed well, but each pane's camera could change its velocity at once: a fighter turning, a lead switching on, the pair's midpoint jumping as one fighter dashed. A last stage in `_outputs` (`_mass_stage`, before the travel budget, which keeps the last word) now gives the drawn camera a mass:
- Its velocity changes by at most 0.006 of the width a tick, each tick (`MASS_ACC`). It speeds up into travel and settles out of it, rather than stepping.
- It never strays more than 0.05 of the width from where the follow aims (`MASS_DEV`). Beyond that it gives way at once: framing comes first.
- It is off where another part of the rig owns the move: a layout morph, a slam, a cut-in, a stage, a building aim, an opening (the expansion), the intro, the fold and reduced motion. In a shot it applies only to a launch's follow. A cut or a snap starts it again from where it lands.
- No cut is added and none is kept. The braking lag is the mass itself; the lead into travel is the speed lead (director-11, on main).

Measured (`clip_digest.gd` with a scratch probe, reduced, on 0c782165): steps in a pane's camera velocity over 0.01 of the width a tick, main then this (over 0.02 in brackets):

| Scene | Main | This |
| :--- | ---: | ---: |
| ai 4 | 78 (37) | 57 (27) |
| ai 7 | 119 (47) | 87 (40) |
| ai 39 | 50 (36) | 34 (25) |
| rushcity | 110 (62) | 83 (53) |
| signaturecity | 72 (55) | 51 (37) |
| mashcity | 8 (8) | 8 (8) |

- Cuts, layout changes, strips, blow pushes and the time outside the picture are identical in every scene. Launched bodies stay in the frame.
- Most of what is left is in the slam and the split's morph (`slam//morph`, `opening//morph`), which the mass leaves alone. That is window 4.

Before/after: docs/camera/img/flight-mass/flight-mass-before-after.gif (main on the left, the mass on the right; ai 4 and ai 7, real web build, Tools' launcher).

**The shot grammar for the big moments (2026-10-23, window 2; on main in b8e759ed).** The EP's brief: launches follow the sent body and reframe on the return; beam struggles push in slowly as they build, then release; transformations and power-ups get a low hero angle and a crane up; KOs get a held wide. Two were built, one was already there, and two were changed:
- **Transformations.** Before, the full version's break was a hard cut to a -8 degree low angle and the settle a hard cut back. Under Reduce flashing (shipped on) the break was calm and had no angle at all. Now:
  - The low hero angle eases in over the whole gather (smoothstep, at most 0.35 degrees a tick). The fighter sinks to 0.74 of the height with the sky above him.
  - The break holds it.
  - The settle cranes up to level and back to the pose over 85% of the half it still runs (`TRANSFORM_CRANE`). The angle reaches level before the shot ends.
  - The short version gets half the angle (`HERO_PITCH_SHORT`, -4), craned up over its break.
  - The angle is a move, so the calm break keeps it too. One cut is left: the full version's break in ordinary mode, a shock beat on the break's onset (section 11). The angle no longer jumps at it. The settle's cut back is gone.
  - Reduced motion: no angle.
- **Power-ups.** A tier-up outside a transformation, in the plain one view, now asks the angle ledger for a low angle whatever the ground (`ANGLE_*`: in over 0.45 s, held 1 s, craned up to level over 0.6 s; one angle in 20 s at most).
- **Beam struggles.** The push used to tighten only in the last 40% of the struggle's time (4%). It now builds over the whole clash, 8% (`STRUGGLE_BUILD`), timed on the clash's own length (1.6 s) instead of a 3 s guess. The lean's push near a fighter is as before. The release lets go with an ease out: fast first, soft landing (the weight squared on the way out, over `STRUGGLE_FADE`). Reduce flashing halves the push, as before.
- **Launches.** Already in the grammar: the launch shot follows the sent body (`solo_kind` launch, trailing anchor), and its return eases back to the layout the pair needs over `T_SETTLE`. Window 1's mass now rides the follow too. No change.
- **KOs.** Already a held wide: the loser's close-up, then the wreck's pull back to the winner small in the wreckage (`R_WRECK`, 29 px at 720p), held until the match resets. Its one cut is a set piece's shot (section 11). No change.

New and changed split_sweep rows:
- `shot transformation full`: one cut at the break; the angle eases in (-3.5 at tick 30, -8.0 at 58) and steps at most 0.35 degrees a tick; the crane reaches level by the shot's end at tick 134.
- `transformation calm` (both): no cut, the angle down to -8 with steps of at most 0.35.
- `shot transformation short`: no cut, the angle down to -4, back to level.
- `power-up angle`: -7.0, steps of at most 0.39, no cut, back to level.
- `beam struggle build and release`: x1.043 at 1.4 s, x1.080 at the end, released fast (a third in 8 ticks against about a quarter for an ease both ways), back to x1.000, no cut.

Gates on 4cbf8b37 with the patch: the 18 headless render checks (city: its oks, no failures), split_sweep and determinism plain and --intro pass. The flash collapse clip reads the same as main in both modes (normal 3 / 3.5, reduced 3 / 3.5, main's own FAIL).

Before/after: docs/camera/img/shot-grammar/shot-grammar-before-after.gif. It shows the transform scene's full transformation (tick 60, Reduce flashing on, so a calm break), then clashcity's beam clash (from tick 984).

**The landscape shot (2026-10-23, window 3; on main in bf34d1d4).** The EP's brief: "a short eased establishing frame when a fight crosses into a new biome or set piece, never costing readability". World's gen 2 biomes and the settlements' landmarks give it real places. `_scape_tick` and `CamParams.SCAPE_*`:
- **Triggers.**
  - The pair's middle enters a new biome and stays 0.5 s (`SCAPE_SETTLE`, no flicker at a border).
  - Or a standing landmark (`Building.landmark`) first comes into the frame; each landmark once a match.
  - A relocation (the middle jumping more than half the view) adopts the new ground silently: it is a cut of its own. The match's first ground is the intro's to show.
- **When.**
  - The plain one view only: no split, shot, cut-in, strip, clash, ring turn, intro or fold.
  - A calm pace (relax or fade), no anticipation of contact.
  - Not while the scroll governor holds the view or a fighter travels faster than 1,200 u/s: a chase is action.
  - None within 3 s of a peak or of a building's fall (a fall fills the frame with dust and light), one in 30 s at most. A crossing not shown within 4 s is let pass.
- **The shot.**
  - The view eases out to 0.72 of its size, never taking a fighter under 0.06 of the height (43 px at 720p) or under his size before.
  - A slight low angle (-4 degrees, ground-limited), because a dolly alone barely changes the far land.
  - A lean of 0.15 of the width toward the new ground or the landmark, both fighters kept inside 0.42 of the width.
  - In over 0.6 s, held 1 s, back over 0.6 s. No cut.
  - A hit (a peak or a build), the anticipation of one, a shot or the split lets it go at once, eased. Another shot that takes the angle takes it; the view still eases back.

Measured (`clip_digest.gd`, both modes, on b8e759ed): one landscape shot each in ai 39 (a biome, tick 1910), rushcity (a landmark, tick 505) and collapse (a landmark, tick 1310); none in ai 4, ai 7 or signaturecity (its landmark comes into the frame among falling buildings). Cuts, layout changes, strips, the time outside the picture and the share of fighters under 40 px are identical to main's.

Flash: the first build had no hold after a building's fall. Its shot in the collapse clip came at tick 1290, among the falls, and raised the collapse count to 3.5 in both modes. With the hold the shot comes at 1310, after them, and the clip reads normal 3 / 3.5 (main's 3 / 3.5) and reduced 2.5 / 3.5 (main's 3 / 3.5). These readings were taken with director-15 on top.

split_sweep rows:
- `landscape shot`: a flight from village to plains at 480 u/s. One shot at tick 304, widest x0.723, angle -4.0 with steps of 0.17, smallest fighter 63 px (from 86), no cut, both on screen, back within 2% of the same flight with it off.
- `landscape shot let go by a hit`: a peak in the hold eases it out.
- A fix to the sweep: a re-seed also clears the travel scan's last frame (a row that seeds twice compared its second flight with the first one's end).

Before/after: docs/camera/img/landscape-shot/landscape-shot-before-after.gif (rushcity's landmark, ticks 489 to 619).

Gates: on b8e759ed with director-14 (and the since-withdrawn director-15 on top, which changes only the closing's shape), the 18 headless render checks (city: its oks, no failures), split_sweep and determinism plain and --intro pass. The EP's own gates ran director-14 alone. On main in bf34d1d4.

**Split grace, first try (2026-10-23, window 4): withdrawn.** It eased the split's separation `sep` (first the opening, the closing and the takeovers, then the closing alone) on the belief that the divider moved at one speed from the first tick to the last. It did not. The split's opening and closing were already eased on the screen:
- `_outputs` blends each pane's camera with the shared one by `_smootherstep(sep)`.
- The feather narrows by the same curve.
- The divider line itself stays at the centre during an opening or a closing.

So an eased `sep` only reshaped a curve that already started and landed at rest. Its before/after barely differed. The eased opening's regression (rushcity: a third more camera steps, 127 to 169 fighter-ticks outside the picture) came from easing twice: the blend started too slowly while a fighter flew out of the view. The EP withdrew director-15 before it landed.

What does move the divider at one speed is the expansion `e` (a pane taking the screen for a shot, or giving it back) and the slam's door. Those are the follow-ups below.

**The takeover's divider, eased (2026-10-23, follow-up 1; on main in e2cbcc49).** When a pane takes the screen for a shot from the split, or gives it back (the expansion `e`), the divider's centre moved by `e` times the half extent: one speed from the first tick to the last. Meanwhile the panes' anchors moved by `smoothstep(e)` (`_anchor`), so line and framing were out of step mid-sweep. The divider now sweeps by `smoothstep(e)` too, in step with the anchors. The slam's door keeps its own shape (follow-up 2).
- In play the sweep happens a few times a match: ai 4 at ticks 1866, 2218 and 2537; ai 7 at 309 (a transformation) and 1904; signaturecity at 484.
- The cameras do not change: the digests' camera hashes, STATS, SIZE, LAUNCHED and the mass probe are identical to main's in six scenes.
- New split_sweep row, `takeover divider eased`: a transformation takes the screen from the split and gives it back. First step 10 px a tick, largest 36, against the linear 24 every tick.

Before/after: docs/camera/img/takeover-divider/takeover-divider-before-after.gif. Gates: as director-17's. The flash collapse clip reads the same as main's in both modes.

**The slam's door as a crisp whip (2026-10-23, follow-up 2; on main in e2cbcc49).** The door is the rusher's pane taking the screen as he closes on the other fighter. It took 0.14 s (8 frames) with the takeover as p cubed: a slow start and all its speed at the stop. Its last frame moved the divider 202 px (at 1024 wide), the largest single step the split makes. It is now Research's crisp whip:
- 12 frames (`SLAM_TIME` 0.2), the takeover and the separation by smootherstep (a hard ease at both ends), landing on the contact.
- No blur, no feather beyond the compositor's own.
- The reason it is a whip and not a cut: the rusher crosses a gap a move would only smear, on the action (the contact). Reduced motion keeps its near-cut (`SLAM_TIME_REDUCED`).

Measured:
- split_sweep's new `slam door whip` row: 12 frames, first and last steps 3.3 px, largest 98 px, landing one tick before the contact. The old door read 8 frames, 2.9 px first, 202 px last.
- Mass probe, steps in a pane's camera velocity over 0.01 (and 0.02) of the width a tick, main then this: ai 4 57 (27) to 51 (22); ai 7 87 (40) to 79 (36); ai 39 34 (25) to 37 (25); rushcity 83 (53) to 73 (43); signaturecity 51 (37), unchanged; transform 35 (24) to 29 (18).
- Cuts, layout changes, strips and the time outside the picture are identical to main's; the share of fighters under 40 px moves by 0.1%.

Gates on main's camera (668aa2ed, with the half-plane) with director-16 and director-17: the 18 headless render checks (city: its oks, no failures), split_sweep and determinism plain and --intro pass.

The flash collapse clip, main (with the half-plane), then director-16, then director-17:
- Normal: primary 3, 3, 3; area-15% 3.5, 3.5, 4.5; 2 s memory 2, 2, 1.5.
- Reduced: primary 2.5, 2.5, 2; area-15% 3.5, 3.5, 3.5; 2 s memory 3, 3, 1.

The whip's longer sweep counts one more change at the lower area threshold in normal mode. Every other reading is equal or better.

Before/after: docs/camera/img/slam-whip/slam-whip-before-after.gif.

**The rally's camera (2026-10-25; on main; the design is docs/camera/rally-framing.md).** Game Design's rulings 23d and Combat's rally kits. The design, the cue contract asked of Encounter, the numbers and the proof are in docs/camera/pending/rally/README.md. In short:
- the sell pushed in and held through the sold blows, with an eased punch on each;
- the launch shot persisting from link to link, taking in the chaser when both fit at 43 px or more;
- the anchor on a critically damped spring for the overtake and the spike;
- a grab in flight holding the size (Legal e12);
- the turn handed to the new body with no cut.

It is inert until Encounter's cues come: the camera digests are byte-identical.
