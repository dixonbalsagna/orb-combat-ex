# The fight's feel in the core: the launch's curve and hit-stop by weight

Owner: Simulation and Engine. 2026-10-19. The core's build of Game Design's launch flight and hit-stop table (`docs/design/fight-feel.md` sections 1 and 6; `rulings-2026-10-19.md` item 1 and `rulings-2026-10-19b.md` section 4), from Research's recommendations 9 and 10 (`docs/research/cinematic-storytelling.md`), for the camera. **Applied in c09c3bef (2026-10-20).** Two data switches, both off: with them off, every match, replay and checkpoint is the same to the bit.

## 1. The launch's curve (`data/fight/flight.json`, `sim/core/flight.gd`)

| Phase (Game Design's) | As built |
| :--- | :--- |
| **The stop:** 14 ticks for a launch, 16 for a full one | Hit-stop by weight (section 2): the launching blow names `launch` or `launch_full`, or the director holds it at the send (`SimHitstop.hold`) |
| **The kick:** a ramp to the peak over 5 ticks, then the peak for 3 | Live ticks 1 to 5 show 0.2, 0.4 ... 1.0 of the peak; 6 to 8 the peak. The peak is the send's own speed at the send |
| **The glide:** eased to 0.4 of the peak over ticks 8 to 30, then held | A smoothstep from the peak to 0.4, reached at tick 30 |
| **The arrival:** a rise to 0.6 of the peak, ramped over the last 10 ticks | When his course meets the ground, the water or the building he is aimed at within 10 ticks at the speed he shows (his course marched a tick at a time in his velocity's direction; the aimed building's face on a straight line), the curve ramps from where it is to 0.6 over those ticks |

**How it is built: the curve paces the body along its path.** The path is the one the launch gave it (the launch planner's aim, the same gravity, drag, contacts and buildings). Each live tick of the first leg, his flight's physics steps by `dt × k`, where `k` makes his speed on screen the curve's share of the peak. So **where a launch goes and where it lands do not change:** only how fast he travels along it. The planner's targets, the building aim, the chains and the brake's rules all keep working.

- **`k` is held between 0.05 and 3** (`pace`). Near the top of a very steep send, where his physics speed is small, he slows into the apex rather than leaping through it (Research's "a short apex ease").
- **The first leg** runs from the send to the first contact. It ends at a ground or water contact, a slide, a building struck, water, or the air brake. From there his journey's own physics runs as today: the bounce, the skid, the chain inside a tower.
- **At the brake,** his velocity takes the speed he shows, so the brake starts from what the camera saw.
- **Not paced:** a knock-back's slide on the feet (`fight-feel.md`: "its own slide, as now") and a set piece's send (a signature's, a finisher's or a break's), whose timing is the director's.
- **The cue for the camera:** a `flight` event (`fx-events.md`) at the kick (with the peak), the glide, the arrival (its contact is the arrival's ticks ahead) and the end (contact, brake, or sent again).

**My readings, for Game Design to confirm:**
- **The curve sets the timing, and the path sets the distance.** A full launch's 1.0 to 1.6 s and its 2,400 to 3,600 units are QA's to measure. If a send flies too far or too short, that is the planner's force and aim, not the curve.
- **The arrival is predicted** by marching his course at the speed he shows, at most 11 ticks ahead. His path bends down under gravity and the ramp speeds him up, so the contact comes a little sooner than predicted, and the ramp ends a tick or two short. A contact that comes later holds him at 0.6 until it does.
- **Set pieces are not paced** until the director says which of them should be.
- **The smaller arenas' cap** (a send never carries more than a sixth of the loop) waits for the arena length to reach the core with the shifting arena.

## 2. Hit-stop by weight (`data/fight/hitstop.json`, `sim/core/hitstop.gd`)

| Rule (Game Design's) | As built |
| :--- | :--- |
| **The table:** a mashed or burst light 2 to 3; a tapped light 4; a medium 7; a heavy 10; a launch or a close 14, a full launch 16; decisive 24; the KO's cap 30 | `ticks` by weight. A hit names its weight in its options (`o.weight`: `light_mash`, `light`, `medium`, `heavy`, `launch`, `launch_full`, `decisive`), and its stop is the table's in place of the stop it passed. **A hit that names none keeps the stop it passed,** so each moment of the director's moves to the table when its owner names it |
| **Decisive:** a finisher's last, a duel of perfects' send, a blow that breaks a region | The director names the first two. **The core holds `decisive` itself for a blow that breaks a region** (a region reaching stage 3 in that hit) |
| **The KO: 30, the cap** | The core holds `ko` in `SimDamage.ko`, the one place a match ends (since the wounds model, HP no longer ends it; the finisher's path calls `ko`) |
| **Both bodies freeze** | As every hit-stop does today: the whole sim holds. The struck body's shake is Animation's |
| **The budget:** frozen time at most 12% of a minute of fight; overlapping stops merge and don't add; over the budget the mashed and burst lights go to 2 first | Every frozen tick of a hit-stop is counted in the live second it falls in, over the last 60 live seconds (432 ticks of budget). Over it, `light_mash` holds 2 (`mashFloor`); otherwise 3. Stops merge by the longer one, as today |
| **No window shortens** (the perfect and parry windows end at least 5 live ticks after the freeze) | Encounter's |

- **`SimHitstop.hold(S, weight)`** holds a weight's stop at any other moment of the director's, merged the same way: the send of a launch, a perfect's duel.
- **My reading:** "the mashed and burst lights go to 2 first" shrinks only them. Nothing else shrinks over the budget until Game Design names the next step.

## 3. In the core

| Where | What |
| :--- | :--- |
| `flight.gd`, `hitstop.gd` (new) | `SimFlight` and `SimHitstop` |
| `state.gd` | `S.flightOn`, `S.hitstopOn`, `S.hs` (`StopState`: the budget's buckets); `FlightState`; `Fighter.flt` |
| `sim.gd` | The switches and states at a new match; the budget counts each frozen and each live tick in the step |
| `fighter.gd` | `stepLaunched` takes its dt from `SimFlight.pace` while the curve is on |
| `damage.gd` | A hit's stop from its weight; after the damage, a broken region's; the KO's in `ko` |
| `hash.gd` | `FlightState` and the budget's state, each only while on; the `flight` event's fields |
| `replay.gd` | Each file in a replay's data hash, only for a match with it on |
| `fx.gd`, `view/fx.gd` | The `flight` event |
| `tools/parity.gd` | Two checks (section 4) |

**Every expression is today's with the switches off.** The new lines run only under `S.flightOn` or `S.hitstopOn`.

## 4. The proof

**"the launch's curve":**
- Off: no flight state, and the replay's data hash takes the file only with it on.
- The curve's shape: 0.2 at tick 1, the peak at 5 and 8, between at 19, 0.4 at 30 and after.
- A shallow send: its speed at ticks 1, 5, 8 and 31 within 7% of 0.2, 1, 1 and 0.4 of the peak; the arrival told about 10 ticks before the contact, and its speed near 0.6 by then. The largest change in a tick is a ramp step, where the same send without the curve jumps to the peak in one. **It lands where it does without the curve** (within 5% of its travel), later.
- A steep send lands where it does without the curve (in the proof, to the unit, 3 ticks sooner: the curve carries him through the slow apex).
- The cues: kick on tick 1, then arrive and end once each.
- With the brake held, the curve's end is told on the brake's start tick, with kind brake.
- A match of 3,600 ticks with the curve and hit-stop by weight on paces its launches, carries both files and plays back.

**"hit-stop by weight":**
- Off: a hit naming a weight holds the stop it passed.
- On: each weight's ticks; a hit naming none keeps its own; a heavy and a light in one tick hold the heavy's 10.
- The budget is 432 ticks. Over it, a mashed light holds 2 and a tapped one 4. A minute of fight later the budget is back, at 3, and its state is in the hash.
- The step counts a 10-tick stop as 10 frozen ticks.
- A broken region holds 24; the KO's blow 30.

**Results:** every check passed on the applied commit (c09c3bef), and with the other parks of its batch (parity 67 of 67, the full gates and Rendering's 15 checks).

## 5. Not in this window

| What | Whose |
| :--- | :--- |
| Naming each hit's weight (`o.weight`) and holding the launch's stop at the send | Encounter |
| The windows that must not shorten (4c); the AI's free-flight approach capped near the whip limit (4d); the planner's prediction with the curve | Encounter, with Camera's limit |
| The push, the whip, the glide's framing and the arrival's hold, from the `flight` cue | Camera |
| The struck body's larger shake | Animation |
| The cap of a sixth of the loop in a smaller arena | Simulation, with the shifting arena's length |
| QA's rows: a full launch's 1.0 to 1.6 s, the frame's share, the frozen time a minute | QA |
| The schemas for the two files | Tools (applied with c09c3bef) |

## 6. The curve shared with the predictors (parked at `pending/shared/`)

Encounter's ask (`docs/director/camera-intent.md` section 3): the planner (`DirLaunch.predictFlight`) and World's predictors (`WorldBrunt.flightTo`, `chainPlan`, `next`) must fly the same curve as the step, or the plan and the flight part.

**What they need is the timing, not the path.** The curve paces the body along its physics path, so the path the predictors integrate today stays right with the curve on. What changes is when he gets there.

| Function (`SimFlight`) | What |
| :--- | :--- |
| `share(t, arr, from)` | The share of the peak at live tick `t`: the curve, or the arrival's ramp from `from` once it started on tick `arr` |
| `kOf(c, peak, vx, vy)` | The pace: the factor his physics steps by to show `c` of the peak, held between `kMin` and `kMax` |
| `toFloor(S, x, y, vx, vy, shown, aimB)` | Live ticks until a course meets the ground, the water or the aimed building's face (the arrival's march) |
| `track(x, y, vx, vy, aimB)` and `tick(S, track)` | A send's first leg on plain numbers (a `Track`, no fighter and no state in `S`), stepped one live tick at a time **with the step's own arithmetic, to the bit:** the share, the arrival's march, the pace, the first leg's gravity and drag |
| `predict(S, x, y, vx, vy, aimB)` | The curved flight run to its touchdown on the ground or the water: the live tick and where. Buildings are the caller's, as in the flight: step `tick` and test them |

- **The live step uses the same functions** (`pace` calls `share` and `kOf`, `toContact` calls `toFloor`), so a predictor and the flight cannot drift apart.
- **No touchdown is stored on the body.** The arrival comes from the march, and the march is in `tick`, so a predictor finds the same arrival tick the flight will. The camera's launch cue can take its touchdown tick from `predict` at the send.
- **The stop at the send** (14, or 16 for a full launch) is hit-stop by weight's (`SimHitstop.hold`), before the first live tick.
- **A match in its KO slow motion** steps by less than a live tick: `tick` takes the dt.

**The check** ("the curve's shared functions, the brake's control back, the camera feed"):
- `share` and `kOf` by their rule.
- For a shallow and a steep send, a track stepped beside the live flight equals it to the bit every tick (position, velocity, tick, arrival, pace).
- `predict` names the flight's touchdown tick.
- `SimBrake.controlBack` ends a flight; a `cam_intent` cue leaves the light digest as it was and another cue moves it; the feed on twice gives the same cues.

Two of Encounter's other asks ride in the same park:
- **`SimBrake.controlBack`**, the brake's control back under a public name, for the recoil flip with ground contact off.
- **A `cam_intent` cue is left out of the light digest** (`SimHash.hashFx`), so switching the camera feed on moves no golden. The feed is the view's: it reads, draws nothing and writes nothing hashed. Out of the digest, its own determinism is held by my check: one AI match run twice with the feed on gives the same cues on the same ticks, and the same play.
