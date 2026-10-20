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

**Step 1, fighter size: measured, not changed.** The drawn height of each fighter in the pane that shows him (`clip_digest.gd` SIZE): median 61 to 86 px at 720p per scene, p10 32 to 56 px. Splitting sooner (R_SPLIT 0.035 to 0.055 or 0.07), a relaxed scroll governor (0.045 to 0.07), no divider slam and a shorter wide hold while the pair parts each moved the small share (under 40 px) by at most a point. The small moments are the rush's door (the slam), the launch shot (the opponent far in the background) and the wide hold while a pair flies apart. They are the shots of steps 4 and 6 (the speed and lead whips), not a constant.

**Step 2 and 3, the intent reader and anticipation (parked: docs/camera/pending/director-1-anticipation.patch, on top of feel-4-brink.patch).** Each tick the rig reads the running exchange's scheduled beats (`S.dirS.ex.beats`, read only) for the next contact within 18 ticks that weighs: a launch or a launch ender (weight 1), a heavy (0.7); lights and mediums do not. Before it, in the plain one view, the focus leans a quarter of the way to the contact point (both fighters kept inside 0.42 of the width) and the view tightens: 20% before a heavy, 6% before a launch (a launch is followed by a chase or a split, and the split's opening must start near the pane's size). In fast (0.1 s), out slower (0.25 s); the blow push lands on top at the contact. Not in a clash, a layout change, a solo shot, the intro or reduced motion. `SplitRig.anticipation`, `intent_now` (the read, for the debug feed), `CamParams.ANT_*`. About 11 a minute in an AI match. Encounter's `cam_intent` (docs/director/camera-intent.md) will replace the reading of the beats when it lands. Gates on both patches over a2b6b5dd's tree: split sweep, seam sweep, pane check, determinism plain and --intro: pass. Clips: homework/camera/6-anticipation/ (left step 5, right this: a mash, launches in an AI match).

**Step 4a, the launched body at fight size (parked: docs/camera/pending/director-2-launch-at-size.patch, on top of director-1).** The chase zoomed a launched body out with the scroll governor (the flash count's rule of 2026-10-12: the scenery no faster than 0.045 of the width a tick), so the subject of the most exciting shot was the smallest thing on screen. The governor is off for a launched body now (`SplitRig.launch_governor` false; on restores it) and the chase size is the fight size (`R_LAUNCH` 0.08 to 0.11): the body stays near his anchor at fight size and the background carries the speed (VFX's streaks will sell it, docs/camera/director.md section 9). The launched body's drawn height at 720p, median before and after: ai 4 47 to 71 px, ai 7 51 to 71, ai 39 50 to 77, rushcity 39 to 78, signaturecity 46 to 82; the time a fighter is outside the picture up 2 to 5%. Gates: split sweep, seam sweep, pane check, determinism plain and --intro: pass. Clips: homework/camera/7-launch-at-size/ (left step 6, right this).
