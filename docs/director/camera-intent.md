# The camera-intent feed: what the choreographer knows ahead, for the camera (paper, 2026-10-19)

Owner: Encounter Systems Director. Paper first; the park follows (`pending/camera-intent/`).

**Orb, 2026-10-19:** a "dynamic, directed, emergent cinematic storyteller that works with the combat choreographer so every camera movement feels purposeful and not distracting". The choreographer is this director. It decides each exchange before it plays, so it can tell the camera what is coming: a camera that knows the next beat can move before it, not after.

**The rule:**
- The feed is a render-only cue stream.
- The director writes it, the camera reads it, and nothing in play reads it back.
- It is outside the gameplay hash, like every cue, behind a data switch until Camera reads it.

## 1. What the director knows ahead of time, and how far

| What | Where it is decided | Known how far ahead | In today's cues |
| :--- | :--- | :--- | :--- |
| **The exchange**: its template, kind, attacker and defender | `DirExchange._start` | at its start: the whole exchange | `exchange` (the template's id), no schedule |
| **The beat schedule**: every strike, launch, window and set piece, with its time | `DirExchange.schedule`, as each beat is planned | a planned template: all its beats at the start (up to 1 to 3 s). A brawl: each blow at its press | none for a template's beats; the brawl's `blow` (`n` its landing) and `windup` (`n`, `dur`) |
| **Impact ticks** | a beat's time; the brawl's `CONTACT` | a template: from its start. A brawl: 4 to 14 ticks (a light to a launcher), 28 for a heavy, more for a charge | the brawl's blows only |
| **The climax** | the template's decisive beat; in a brawl the close (his run at its points: `_closes` at the throw), the launcher, the double hit, a finisher | a template: from its start. A brawl's close: at the closing blow's press, 4 to 12 ticks. The launcher: its 14-tick wind-up | `launcher_open`, `stagger` at the moment, not ahead |
| **The launch plan**: the send chosen, its kind, its vector (`ux`, `uy`), its force and power, the predicted landing (`x`, water or ground), the travel, the flight's duration, a building aimed at and the chain's links | `DirLaunch.chooseLaunch` at the send | at the send. Before it, the launcher's throw knows the kind the stick asks and its contact tick (14 ticks ahead) | `launch_plan` (the names only), `launch` (speed, direction), `launch_power` (behind launch anywhere) |
| **Chain and parry windows** | the template's window beats; the brawl's riposte window | a template: from its start | `window_open` at the opening |
| **Who wins the read** | a perfect block is marked at the guard press, before the contact; a sure launcher always lands; a template's outcome (dodge and counter, a heavy clash won) is chosen at the start | perfect block: up to 10 ticks (its window). A template: from its start | `perfect_block` at the contact |
| **The grapple's clock** | the catch's tell; the tie-up; the pulses every 20 ticks; the time at 90 | the tell: 10 ticks. Each pulse: from the tie-up | `grapple_catch` (`n` the landing), `grapple_pulse` at each |
| **The return** | `bands.return`, the first blow back | its tell (10 ticks) | `windup` with `return` |

**Not known ahead:**
- a player's next press;
- a beam struggle's winner;
- a trade's breaker before the limit;
- a launch's exact landing among buildings it isn't aimed at;
- where a ragdoll ends.

The feed says only what is decided.

## 2. The stream (v2: one plan an exchange)

One cue kind, `cam_intent`, by the cue list's rules (`pending/return/cues.md`): `n` is the absolute tick it happens on, `dur` a length in ticks, `k` a count, `text` the item. Research's recommendation 1 asks for one event at each exchange's start, so v2 sends one `plan` where v1 sent a cue a beat. The plan rides on the cue as Object metadata (`plan`): outside the event's fields, so nothing that hashes or reads fields sees it.

| `text` | Sent | Scalars | Metadata |
| :--- | :--- | :--- | :--- |
| `plan` | a planned exchange's start, once the alchemist has dressed it; each brawl blow the director decides, at its throw; the AI's string as it starts it; the double hit; the clinch's tie-up | `source` the template (or `brawl`, `string`, `double`, `clinch`); `actor` the attacker, `target` the defender; `n` the last beat's tick; `dur` the span; `k` the story weight | `plan`, below |
| `launch` | the send, from the plan | `source` the candidate; `k` its kind (0 up, 1 across, 2 down, 3 behind, 4 a building); `ux`, `uy`; `x` the predicted touchdown; `n` its tick; `amount` the travel; `dur` the flight; `y` 1 in water | `launch`: the name, kind, vector, the building flag, `land` {x, n}, `rest` {x} (where he comes to rest, an estimate), travel, water |
| `read` | a perfect block marked at the guard press | `n` the contact it turns; `actor` the blocker | |

**The plan:**
- `beats`: [{n, op, kind, w, a, d}], each beat's tick, its op, its kind (light, medium, heavy, launch, window, set, move, pulse), its weight 0 to 4, and the two slots. A beat's tick counts the hit-stops of the strikes before it.
- `contacts`: the ticks that strike.
- `pauses`: [[from, to]]: each strike's hit-stop, and the breaths between beats 12 ticks or more apart.
- `noCut`: [[from, to]]: runs of strikes under 12 ticks apart, a beam's fire to its impact, the clinch.
- `launch`: {n} when a launch is planned, plus the launcher's safety and the stick's aim in a brawl. The vector and landing come with the send's `launch` cue.
- `set`: true for a set piece. `story`: {w, tags}, tags from first_blood, reversal, decisive, finisher, comeback, crippling (Research's rec 16).

**What it costs:** only the cues' writes. It reads what is decided, draws nothing and changes nothing, so play can't move. The golden's checkpoints stay equal with the feed on (11 of 11 cases). Its "light" digest folds every fx event, cues included, so it differs with the feed on and is byte-identical with it off.

**How far ahead (10 AI matches of 3 min, 11,094 landed hits):**

| | Hits | Told before contact | Told 8 ticks or more ahead |
| :--- | ---: | ---: | ---: |
| All | 11,094 | 86.8% | 30.2% |
| Matched to the AI's string plan | 4,675 | | 68% |
| Matched to a brawl blow's plan | 4,901 | | 2% |
| Strikes during a planned exchange | 102 | 50% | 50% (every one told is 8 or more ahead) |
| A launch's touchdown | | | at the send: the tick and x predicted exactly, hit-stop included |

- **A player's light can't be told 8 ticks ahead.** It lands 2 ticks after its press, and the press is the player's. Waiting 6 more ticks would break the press feel Orb approved (each press is a blow). So Camera reads a light from its `blow` cue, and the plan for strings, wound blows, launchers, planned exchanges and sends. Research's 8-tick test holds for those.
- **A planned exchange's untold half** are strikes scheduled after its start, not yet broken down. A plan sent at the start can't carry them; a later plan per added beat would.
- **Hits outside any plan:** shots (360), a beam's ticks of damage (38), and a launch's impacts (241). An impact's tick is the send's `launch` cue (`n`, the touchdown), not a plan contact.

## 3. Launch speed curves: ruled, waiting on Simulation's curve

Game Design ruled the curve (`rulings-2026-10-19.md` 1, `rulings-2026-10-19b.md` 4d, `fight-feel.md` §1):
- the stop, 14 ticks (16 for a full launch);
- the kick, a 5-tick ramp to the peak held for 3;
- the glide, eased to 0.4 of the peak over ticks 8 to 30, then held;
- the arrival, a 10-tick ramp to 0.6.

A full launch flies 1.0 to 1.6 s; in a small arena the cruise is scaled so a send never carries more than a sixth of the loop.

**The planner's side.** Three predictors integrate today's flight the way `SimFighter.stepLaunched` flies it: `DirLaunch.predictFlight` (mine), `WorldBrunt.flightTo`, and World's `chainPlan` and `next`. With a curve, all of them must fly the same curve, or the plan and the flight part. So Simulation's curve has to come as functions that the step and the three predictors call:

| What | Where | For |
| :--- | :--- | :--- |
| The speed factor at live tick k of a send whose touchdown is predicted at tick n | Simulation | the step, and every predictor |
| One tick of the curved flight, on plain numbers (x, y, vx, vy, the traversal factor, k, n), with no state | Simulation | the predictors |
| The send's predicted touchdown tick, worked out at the send by the same function and kept on the body | Simulation | the arrival's ramp (it needs the end in advance) |

**Mine, once those exist:**
- `predictFlight` steps Simulation's tick instead of its own drag and gravity;
- the camera feed's `launch` cue keeps its fields, with the curve's flight;
- the brake's start window and the chase are re-read with QA.

Nothing of mine moves before Simulation's curve does.

## 4. Orb's back and forth (homework 6)

**Orb:** "more back and forth, impacts, dynamic clashing. both fighters should be backflipping out of strikes, ricocheting off of environmental elements."

**What the director needs, and from whom:**

| Need | The director's part | From others |
| :--- | :--- | :--- |
| **Recoil exits:** both spring apart, flipping, out of a heavy trade, a clash, a turned heavy or the double hit, instead of a launch or a hold | a new end of the brawl, the recoil: both are sent 2 to 4 bh apart, no damage, and the one who won the exchange has the first move. Chosen by rule: a heavy against a heavy, a clash, the double hit (today's "thrown apart") | **Combat:** flip-out pieces per fighter (backflip, back handspring, cartwheel out). **Animation:** their keys and a landing. **Camera:** the frame for two bodies leaving opposite ways |
| **Ricochets:** a sent body rebounds off a slope, a crater's lip or a building's face and flies on | the planner predicts the bounce, and may choose a ricochet (a send angled to come back off a face) | **World:** a bounce rule for an outside face, like the knocked-about rule for a held slab (900 or more, 40 to 70°: a bounce), in the deterministic flight the planner can predict. **Simulation:** the flight carries it. **Camera:** frames the rebound |
| **Back and forth:** momentum traded, not one fighter sending the other again and again | after a recoil exit both re-engage: the return's rule, with the first move to the winner; a clash of two rushes meeting in the air (the meeting exists) staged as a clash, then a recoil | **Game Design:** how often a recoil replaces a launch; whether a clash always recoils |

## 5. World's finding: the planner almost never starts the interior chain

World reads the AI's tower sends at 3 to 22°, while the chain's gate is 15 to 60°.
- The angle is World's aim's: `WorldBrunt.aim` takes the first `uy` in `AIM_UY` (0.05 to 0.4) that hits the building, so a near tower is hit low.
- The planner only scores what aim returns.

**Built, parked (`pending/interior-aim/`), behind `launch.json interiorAim.enabled` (false).**
- **World's part (a grant).** `WorldBrunt.aimInside` aims as `aim` does, over the planner's own angles (`interiorAim.uy`: 0.3, 0.45, 0.65, 0.9). It takes the first flight whose arrival fits `WorldInterior`'s band. `aim` itself is unchanged.
- **The planner's part.** With it on and World's `interiorChain` on, each building the planner can aim at also offers the inside send, when the low aim wouldn't start the chain itself. It is scored as any building send, plus `interiorAim.score` by personality: the Anti-hero +8, the hero −8 (by the care's sign, or the role at care 0). So the Anti-hero takes a tower from the inside and the hero keeps to its face. Off, there is no candidate and no draw.

## 6. The park

`pending/camera-intent/`: the stream of §2 (v2), behind `cameraIntent.enabled` (false) in `data/director/interrupts.json`. With it off the golden is byte-identical.
- §3 is now Game Design's curve (`rulings-2026-10-19.md` 1): the planner predicts with Simulation's shared flight function once it exists.
- §4 is Game Design's fight-feel rules: recoil flips first (`pending/recoil-flips/`), then ricochets and wall kicks, then clashes.
- §5 is parked in `pending/interior-aim/`, with World's grant.
