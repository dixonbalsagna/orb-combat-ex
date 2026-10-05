# Stances on the controls, and lunge control in the manoeuvre stance

Owner: Controls and Game Feel. Date: 2026-10-04. **A note only: no code, no data.** Two asks in one note. **Part A** is the input side of Orb's stances ("the default represents the characters' martial arts stance, LB represents defensive stance, RB is Energy arts stance, RT is the charging stance, LT is maneuver stance. All face buttons should have an appropriately broad moveset for each stance", `docs/ep/vision.md`, 2026-10-04): the mapping on pad, keyboard and touch, what happens to every current input, two stance buttons at once, the triggers, accessibility, and what the intent needs. Game Design's stance-by-button matrix says what each cell *is*; this note says how a player reaches it. **Part B** is the lunge and far-approach control Orb asked for ("the combat lunges should be a bit more controllable and easier to spot when they're being used against you, right now an opponent flying from very far away at max speed is very hard to judge"), written against LT as the manoeuvre stance, where the lunge control and air recovery live. Each press is a blow; mash, timed and held presses read differently (`docs/ep/prototypes/melee-trade-v2.html`: speed is mashed, tech is timed, heavy is held, a combo's last blow is the heavy that knocks back, block is never knocked back). Units in Part B: a body height (bh) is 75 units; a tick is 1/60 s; 4000 units a second is 66.7 units a tick, 0.89 bh a tick.

## Recommendations at a glance

| # | Question | Recommendation |
| :--- | :--- | :--- |
| 1 | The mapping | **The stance is what is held.** None: martial. **LB** defensive, **RB** energy, **RT** charging, **LT** manoeuvre. The four face buttons are **X, Y, B, A** and stay the four existing edges (`light`, `heavy`, `sig`, `context`); the move is the (stance, button) cell. Four of the five stance buttons already work this way in the built layouts |
| 2 | Two stance buttons at once | **A set, not a sequence**: the layout reports which of the four shoulder buttons are held and the sim looks the set up in a table. **A stance is exclusive until hybrids exist** (ruled 2026-10-04): the layout reports only one stance button's own state at a time, the newest. **RT dominates** (with RT down the set is RT alone). Exceptions: **RT's burst from a guard** and the **LT+RT transform chord**. Hybrids (LT+RB, LB+RB, LT+LB) are **data**, so switching one on needs no format change |
| 3 | The intent | **`stanceMask`: a 4-bit mask, one bit per shoulder button (LB 1, RB 2, RT 4, LT 8), bits 47 to 50**, and **`contextHeld`, one level bit at 51** (for martial A held, On the Chin), in one change: `BITS` 52, intent version **4**, **replays before it are refused**. **1 spare bit (52) remains** in a JSON-safe 53-bit integer; **Simulation does not have to split the record now** (A5) |
| 4 | Triggers | Digital with hysteresis as today (on 0.35, off 0.25); no analogue depth; RT is the charging stance, held; a 2-tick release debounce on all four stance buttons |
| 5 | Accessibility | A per-player **"stance buttons: hold or latch"** setting; on touch the default is a **one-shot latch** (tap a stance, then a face button; it clears after one blow or 90 ticks) |
| 6 | The Brawler preset | **Retire it** (its attacks sit on RB and RT, which are now stance buttons); a fighting-game player remaps Arena |
| 7 | LT, manoeuvre | **LT is the pilot's stance.** A lunge or charge started with LT held is **piloted** (steer, throttle, a free cancel before the commit point, at a ki cost); without LT it is the plain straight line. **Air recovery moves to LT**: tap at a bounce or tumble is the tech, hold in the air is the brake |
| 8 | Reading a lunge | A minimum travel time, a speed cap by distance, a range ceiling for charges, an ease-out, a marker on the defender and a tell before it starts (Part B) |

## Answers recorded (the EP for Orb, 2026-10-04, `docs/ep/stance-answers-2026-10-04.md`)

Accepted as written except four. **Struggles** start only when two heavy commitments meet (signature against signature, a held heavy or a string's ender against the same, a beam breaking a shield); light, flurry and skill blows that meet trade. **Signatures:** one per stance and hybrid is the target, the five base stances ship first; tiered cost; no per-match cap; a shared cooldown of at most 3 s. **Move list** first, generated from the moveset data; practice mode later. **Build order:** the intent's stance field **once as a 4-bit mask** (this note), then the martial stance for both fighters, the other four stances, hybrids, the choreographer's settings; hybrids and their signatures, the special loadout, practice mode and per-stance choreographer granularity are **deferred** (presets first). **Brawler is retired** with a migration to Arena. **Answer 5** (the dodge on entering manoeuvre) stands and is flagged for a revisit after Orb plays it: the fix if it annoys is a dodge on a **tap only**.

**Rulings after Game Design's matrix (the EP, 2026-10-04, recorded in `melee-press-feel.md` section 10):** (1) **`contextHeld`**, bit 51, in the same version 4 change as the mask; (2) **a stance is exclusive until hybrids exist**, with RT's burst from a guard and the transform chord as the exceptions, and **sprint with a channel dropped for now**; (3) **Simple:** RT+LB is the utility special, the sim takes the director's stance for a Simple slot, and the wording is "the transform action"; (4) the **20-tick lock after a hit stays** (B4). **Build:** the tree for the mask and `contextHeld` comes once Encounter's brawl plan says where the director reads them; nothing before.

# Part A: stances on the controls

## A1. The mapping

A stance is a **held state**, not a mode you switch and forget: the physical stance buttons are the four shoulder controls. Face presses read the stance **on the tick they land**, so the order is "hold the stance, then press the blow" and nothing waits (Rule 1: a tap fires on press).

| Stance | Held on a pad (Arena) | The control it already is | What it already does |
| :--- | :--- | :--- | :--- |
| **Martial** (the fighter's default) | nothing | none | the blows and the director's choreography as built |
| **Defensive** | **LB** | `guard` (hold, and a tap for the perfect block) | guard; a fresh press in a wind-up is a perfect block |
| **Energy** | **RB** | `mode = 1` while held (built 2026-10-02; the toggle is the accessibility setting) | the attacks are energy blasts |
| **Charging** | **RT** | `power` (hold; a tap is the burst; held 12 ticks is the channel) | with RT held a face press is a special or the signature (the built power layer) |
| **Manoeuvre** | **LT** | `dodge` (a tap is the dodge, held 12 ticks is the sprint and the boost) | flight at will, the dodge, the boost; **new: a face press with LT held is a manoeuvre** |

The four face buttons are **X (west) `light`**, **Y (north) `heavy`**, **B (east) `sig`**, **A (south) `context`**, positional on every pad family, as today. That gives a 5 by 4 grid of cells. The grid is Game Design's; the existing `context` rules are already a small stance matrix (guarding: reversal or deflect; sprinting: tackle; energy: shove; in the air: dive grab), and the power layer is the charging row (X, Y, A are the three specials and B the signature).

**The stance buttons keep their own jobs.** Holding LB still guards; holding RT still channels; holding LT still dodges, sprints and boosts; holding RB still makes the attacks energy. The stance only adds what a face press means. Nothing a shoulder button does today is taken away **while it is the stance**; if a newer stance button is pressed over it, it goes neutral until the newer one is let go (A2: a stance is exclusive until hybrids exist).

### Keyboard, one player (solo)

| Stance | Key | Face buttons |
| :--- | :--- | :--- |
| Defensive | **Shift** | **J** (X), **K** (Y), **L** (B), **I** (A) |
| Energy | **Q** | |
| Charging | **E** | |
| Manoeuvre | **Space** | |

Movement is WASD. The keys are the current ones; only their meaning is named.

### Keyboard, two local players (shared)

| | Player 1 (left half) | Player 2 (right half) |
| :--- | :--- | :--- |
| Defensive | Shift | Semicolon |
| Energy | E | O |
| Charging | Q | Slash |
| Manoeuvre | Space | Period |
| Face X, Y, B, A | F, G, R, V | H, M, U, Comma |
| Move | W A S D | I J K L |

A player's heaviest hold is two movement keys, one stance key and one face key: **four normal keys (five with Shift), the same as today's sprint with a diagonal and an attack**, so stances add no ghosting burden (`two-player-feel.md`: eight normal keys at the extreme for two players, six typical). Holding **two stance keys** adds one key per player; the layout does not need it.

### Touch

| | Simple touch | Full touch |
| :--- | :--- | :--- |
| Defensive | the Guard button, held | Guard (left edge) |
| Energy | director's choice (auto) | Mode (hybrid: tap latches, hold is momentary) |
| Charging | Power, held | Power |
| Manoeuvre | the floating stick's outer ring held, or a flick (the dodge) | Dodge (left edge), and the same flick |
| Face buttons | Attack (tap light, hold heavy), the signature swipe, Context | the diamond: Light (W), Heavy (N), Signature (E), Context (S) |

A touch player cannot hold a stance with the left thumb and fly with it, so touch uses a **one-shot latch** (A5). Simple has two face buttons' worth of moves per stance, not four; Game Design's matrix needs a Simple column (Attack and Signature per stance, with Context where it applies).

### The Simple pad layout

Its six buttons are one stance each plus the face moves: **B** guard (defensive), **A** dodge and sprint (manoeuvre), **RT** power (charging), **X** attack (tap light, hold heavy), **Y** signature, **LB** context, and **the sim takes the director's stance for a Simple slot** (`autoMode`, `mode` -1): the director picks the energy stance, and for a Simple slot it may replace the mask's stance for a blow (it never overrides a stance button the player is holding). **The charging row on Simple:** RT held with **X is `special_auto`** (the director picks one of the three specials), with **Y the ultimate**, and with **LB the utility special** (ruled 2026-10-04), so a Simple player can reach all three kinds. Simple's other face moves are X and Y per stance, and LB is its A.

### The Brawler preset: retire it

Its attacks are on **RB** (light) and **RT** (heavy), and its mode button is X. Orb's mapping makes RB and RT stance buttons, so the Brawler preset has no stance spine. Its reason for existing, fighting-game players who want attacks on the shoulders, is met by remapping Arena (the remap screen lets any control take any action). **Recommendation: remove the preset** and migrate a saved Brawler choice to Arena; this needs Orb's agreement and UI's settings text.

## A2. Two stance buttons held at once

The layout reports the **set of held stance buttons** (after hold, latch, debounce and the one-shot, A4 and A5); the sim reads it as a number and looks the stance up in a data table. Order does not matter.

**The mask.** Four bits, one per shoulder button: **LB 1 (defensive), RB 2 (energy), RT 4 (charging), LT 8 (manoeuvre)**. 0 is the martial stance. The reported values and what they mean:

| Mask | Held | Stance |
| ---: | :--- | :--- |
| 0 | nothing | martial |
| 1 | LB | defensive |
| 2 | RB | energy |
| 4 | RT | charging (RT dominates: it is the only bit reported while RT is down) |
| 8 | LT | manoeuvre |
| 10 | LT + RB | **hybrid, evasive energy** (data-enabled; deferred) |
| 3 | LB + RB | **hybrid, defensive ki** (data-enabled; deferred) |
| 9 | LT + LB | **hybrid, terrain while flying** (data-enabled; deferred) |

Every other combination is **never reported**: RT with anything reports 4; LB with RT, RB with RT and the like are RT. A set the data has not enabled reports **only the newest held bit** (a small recency rule in the layout, which keeps the number a base stance until hybrids ship).

1. **The transform chord comes first.** LT and RT pressed within 6 ticks (the chord window) are the transform chord whether or not a form is ready (today's rule 3), and the transform action on every layout (LT+RT on a pad, RB held on Simple, the Transform button on touch). While it is pending or held, **no stance changes**: the layout leaves the chord's two bits out of the mask and reports what it did before the chord. If a form is not ready the chord does nothing but its cue, as now.
2. **A stance is exclusive until hybrids exist** (ruled 2026-10-04). Each stance button owns its own fields: **LB** `guard`, `guardPress`; **RB** `mode` (1 while held); **RT** `power`, `powerPress`, `powerTap`; **LT** `dodge` (the edge on its press) and `sprint`. While a stance button is physically held but another, newer one is the reported stance, **the older button's fields report their neutral value** (`guard` false, `mode` 0 rather than 1, `sprint` false, `power` false). So a player who presses LB while holding RB is defensive with no energy attacks and a guard; one who presses LB while boosting stops boosting and guards. This makes the stance prices true by construction ("no guard while RB is held", "no guard in manoeuvre", "charging is nearly still"): no sim rule has to catch the contradiction.
   - **Letting go of the newer button hands the stance back to the older one that is still held**, but **no new edge fires on the resume** (no fresh `guardPress`, so no accidental perfect block).
   - **RT dominates**: with RT down the mask is 4 and the face presses read the charging stance, whatever else is held; the held LB's `guard` is neutral from the tick RT goes down (a charging fighter is exposed).
   - **The exception, RT's burst from a guard**: RT's own press edges always report. `powerPress` fires the burst when the fighter is threatened and `powerTap` on a quick release, even though the guard it came from has gone neutral on the same tick. The sim sees a burst from a guard because the edge is the burst, not because `guard` is still true.
   - **The other exception is the transform chord** (item 1).
3. **Sprint with a channel is dropped for now.** LT then RT more than 6 ticks apart: RT is the newest stance and dominates, `sprint` goes neutral, and `power` is true. A player who wants to fly while charging does not get both until a hybrid exists.
4. **Hybrids are enabled in data.** A new `data/input/stances.json` (Tools' schema) lists the enabled hybrid masks. The three hybrids and their signatures are **deferred** (answer 33): the five base stances ship first, with the mask format already carrying the hybrids, so turning one on later is a data change and **needs no second format break**.

Why a set and not recency: with hybrids the order a player presses two shoulders in must not matter, and a set lets Game Design add or remove a hybrid without touching the layout or the format. Recency survives only as the fallback for sets that are not yet hybrids.


## A3. What happens to every current input

| Input | Today | Under stances |
| :--- | :--- | :--- |
| **light (X), heavy (Y)** | an exchange request each; heavy by hold or upgrade; the press log reads them | the X and Y cells of the current stance; the press reads as one blow of that stance; mash, timed and held reading unchanged (`press_read.gd`), with the **stance recorded on each log entry** (A5) |
| **signature (B)** | the signature request, 45 ki; also RT and B | the B cell of the stance; martial and charging keep the signature; the others are Game Design's |
| **context (A)** | grab and throw, provoke, shove, reversal, tackle, dive grab by situation | the A cell of the stance; the situation list becomes the table |
| **guard (LB)** | guard, a tap is the perfect block | unchanged **and** it is the defensive stance; the perfect block is untouched |
| **dodge, sprint (LT)** | a tap dodges on press, held 12 ticks sprints; boost drains ki | unchanged **and** it is the manoeuvre stance from the first tick; the dodge on press still fires (see below) |
| **power (RT)** | channel; a tap is the burst; RT with a face is a special | unchanged **and** it is the charging stance; the specials are its row |
| **energy (RB)** | hold for energy attacks (built) | unchanged **and** it is the energy stance |
| **specials chord (RT + face)** | `special` 1 to 3 on X, Y, A; the signature on B | unchanged for now: the layout keeps emitting `special` and `sig`, and also the mask with the RT bit (4), so the director can read either until the matrix lands; **no layout change until Game Design's matrix is ruled** |
| **escape (R3)** | the Escape edge | unchanged: a control of its own, not a stance (its release is never a stance change) |
| **flight boost on LT** | hold 12 ticks to sprint; drains ki | unchanged |
| **transform (LT + RT, the transform action)** | the chord, 30 ticks | unchanged; Simple's RB hold and touch's Transform button are the same action; the chord suppresses stance changes while pending (A2) |

**One thing to say plainly: LT's dodge fires on press, and LT is now also a stance button.** Entering the manoeuvre stance fires the dodge on the first tick (outside an exchange it is the free lunge; **inside an exchange as the defender it is the dodge-cancel, 15 ki and the 3 s cooldown**). I considered delaying the dodge to the release so that holding LT could be a pure stance; that costs the dodge its no-latency tap, which the whole scheme is built on. So: **the manoeuvre stance begins with a dodge**, the way a fighting game's dash begins a dash attack, and a face press during the hold is the manoeuvre. A player who wants the stance without a dodge-cancel inside an exchange should hold LB or RB instead; Game Design should decide whether a stance entered while threatened is charged the dodge-cancel (the proposal is yes: it is a dodge).

## A4. The triggers

- **Digital, with the existing hysteresis:** a trigger is down at 0.35 and up at 0.25 (`stick.triggerOn`, `triggerOff`). The stance reads on the tick it crosses 0.35, so a half-pull is enough and a shallow resting finger (below 0.35) never changes the stance.
- **No analogue depth.** Several pads (Switch Pro, some generic pads) report their triggers as buttons; a design that needs half and full pulls would not work on them and would differ between pads. RT as the charging stance is a held digital state: `power` is true from the tick it crosses; the channel (charge accumulation) starts after the 12-tick hold as today; a quick release is the burst when not threatened.
- **Debounce:** a trigger or shoulder release followed by a re-press within **2 ticks** of the same stance button is one continuous hold (a light-pull flutter must not flicker the stance). The same rule the attack buttons have. It does not change the dodge edge, which is the press itself.
- **A sensitivity setting** (accessibility): the on threshold from 0.2 to 0.6 for players who cannot pull a trigger far or cannot resist a partial pull. Off stays 0.1 below on.

## A5. Accessibility, one-handed play, and the intent

**Hold against latch, per player.** The setting "Stance buttons: hold or latch" (default hold on pad and keyboard) lets a player tap a stance button to latch it and tap again, or another stance button, to change it. The shoulder buttons' own states follow the latch: a latched LB is a continuous guard (with the risk that gives); a latched RT is a continuous channel. This is the energy toggle (built) generalised to the four buttons.

**One-shot latch (default on touch, an option elsewhere).** A tap on a stance button arms it **for one blow**: the next face press reads that stance and the latch clears; it also clears after **90 ticks** (the press window's idle lapse) if no face press comes. A hold is momentary as usual. A tap on the same button while armed cancels it. On touch a visible badge on the armed stance button is required (UI).

**One-handed play.**
- On a pad, **the D-pad can arm a stance** for a player who cannot hold a shoulder button: up energy, left defensive, right charging, down manoeuvre, with the one-shot latch. The D-pad is unused in play today. (It takes the left thumb off the stick for the tap, so it is a fallback, not the way to play.)
- On the keyboard, the stance keys are on the movement hand's side in both halves, so one hand can fly, hold a stance and press a face key (four normal keys).
- **The Simple layouts** are the one-handed design: guard, dodge, power and attack with the director choosing the energy stance.
- Remap: any control can take any stance action; a one-handed player can put the four stances on the face buttons' side and the moves on the shoulder buttons through the remap screen, as long as the layout still has one control per stance (the remap rules, `remap.md`, apply: no two actions on one control).

**The intent.**

| | |
| :--- | :--- |
| New fields | **`stanceMask`**, a **4-bit mask** (A2): LB 1, RB 2, RT 4, LT 8, **bits 47 to 50**; and **`contextHeld`**, a level (true while a Context button is down, any layer), **bit 51**, for martial A held (the rival's On the Chin; ruled 2026-10-04), the way `lightHeld` and `heavyHeld` are. `BITS` becomes **52**. The mask is resolved by the layout for hold, latch, debounce, one-shot, exclusivity (A2), the RT and chord rules, so replays and the AI carry one number; the sim maps it to a stance with a data table. Named `stanceMask` (`SimIntent.stanceMask`) to avoid the clash with today's legacy `stance` float, which I3 removes |
| Kept | `guard`, `guardPress`, `dodge`, `sprint`, `power`, `powerPress`, `powerTap`, `mode`, `light`, `lightHeld`, `heavy`, `heavyHeld`, `sig`, `special`, `context`, `escape`, `waited`, `transform`: each shoulder button still reports its own state, **but only while it is the reported stance** (exclusivity, A2); `mode` equals "RB is the stance", not merely held |
| Room left | **1 spare bit (52)** in a JSON-safe 53-bit integer (JSON numbers are exact below 2^53). **Simulation does not have to split the record now.** Hybrids need no more bits (masks 3, 9 and 10). A further field of more than one bit would force a second integer: the replay's input entries are `[tick, slot, packed]`, and a split would add a fourth element `packed2`, with a format bump, the pack, unpack and hash changes and a golden. **I3 frees 5 bits when it removes the legacy `stance` (3 bits), `dash` and `charge` (bits 35 to 39)**, but that renumbers the record and is a format break of its own. **Recommendation: no split until a field needs it, and decide at I3; record the decision when the next field is asked for** |
| Replays | **Replays recorded before this stop playing back.** The intent version goes to **4**; `SimReplay.play` refuses another version (reason `format`). An old packed intent would unpack fine (the new bits are zero, martial), but the sim plays differently once a stance means something, so a silent replay would diverge |
| Hash and golden | `stanceMask` and `contextHeld` appended to `INTENT` in `sim/core/hash.gd`; the golden regenerates once; the pack test in `parity.gd` covers masks 0 to 15 and `contextHeld`, and the first invalid integer moves to `1 << 52` |
| The AI | writes the same record: Encounter's AI sets the mask for its blows to be stance moves (0, martial, is what it writes today); it may write any mask the player could (the hybrids when enabled) |
| The press log | each entry gains the **stance mask** (0 to 15) beside `mode` (energy is mask 2): the classifier's mix counts (light, heavy, sig, energy) become counts by stance and by button; `classify` keeps its style, timing and grades; the hybrid masks are just more stances |
| Tests | the layout tests for A2 (the mask for every held set, exclusivity and the neutral fields of the older button, the resume with no new edge, RT dominance, the burst from a guard, the chord exception, newest-bit fallback, hybrids switched on by data), `contextHeld` on pad, keyboard and touch, the Simple special row, the touch one-shot latch, the debounce, the pack round trip for masks 0 to 15; about a day on my side once the tree is handed over |

**Do not build before Game Design's matrix exists** (the EP's order, 2026-10-04). **Build the mask once, as the whole 4-bit field, so hybrids never need a second format break;** then the martial stance for both fighters, the other four, the hybrids, the choreographer's settings. The field is useful only when the director reads it; adding it earlier changes a format for nothing.

# Part B: lunges and far approaches, in the manoeuvre stance

## B1. What the data does today, and why a far flight is unreadable

`bands`: close within 3 bh, mid to 12.5 bh, far beyond (`closeBh`, `midBh`). A mid press is a **lunge** (4000 u/s, 3 to 20 ticks). A far press taps to taunt (45 ticks) or, held (8 ticks light, 16 heavy), becomes a **charge**: light 4000 u/s clamped to 18 to 60 ticks, heavy 3000 u/s clamped to 30 to 84 ticks. The flight ends 2.5 bh from the rival and the wind-up follows (15 ticks light, 20 heavy).

The clamp is the problem. Past the distance the speed can cover in the maximum time, the sim does not slow the flight, it **speeds it up to arrive in the maximum time**:

| Distance | Light charge today | Speed it flies at | Heavy charge today | Speed it flies at |
| ---: | ---: | ---: | ---: | ---: |
| 12 bh | 14 ticks, clamped up to 18 | 3 000 u/s | 30 ticks (the minimum) | 1 800 u/s |
| 40 bh | 45 ticks | 4 000 u/s | 60 ticks | 3 000 u/s |
| 53 bh | 60 ticks (the maximum) | 4 000 u/s | 80 ticks | 3 000 u/s |
| 100 bh | 60 ticks | **7 500 u/s** | 84 ticks | 5 400 u/s |
| 200 bh | 60 ticks | **15 000 u/s** | 84 ticks | **10 700 u/s** |
| 600 bh (a 99th percentile exchange, slice 2) | 60 ticks | **45 000 u/s** | 84 ticks | **32 100 u/s** |

So a charge from across a planet crosses it in one second at up to eleven times its nominal speed. The defender cannot read how long it will take, the closing rate changes with the distance, and the only warning is the hold. Slice 3's own measurement is a charge flight median of 40 ticks with the fast tail at 19 (p10): a third of a second.

## B2. Two kinds of approach: unpiloted and piloted

With stances the control of a flight has a natural home: **LT, the manoeuvre stance, is the pilot's stance.**

- **Unpiloted** (the press is made in the martial, defensive or energy stance, or with LT up): the approach is the director's straight line, as built. The attacker's choices are the ones slice 3 gave (release cancels a light charge; a heavy is committed and a Dodge stops it at 15 ki). It costs **no ki**. The speed cap, minimum travel time and range ceiling below apply to it.
- **Piloted** (the approach's press is made **with LT held, and LT stays held**): the attacker flies the approach within limits. It costs **ki per tick at the boost's rate** (LT held is the boost, and Orb confirmed it drains ki: Game Design's number).

| Control (piloted) | Rule | Numbers |
| :--- | :--- | :--- |
| **Steer** | the end point's height follows the stick's vertical axis, so the attacker can come in above or below the rival (a slam from above, an uppercut from below). The lateral side stays the attacker's own (the end point's current rule, so a crossup is not offered) | up to **±4 bh** from the rival's height, at most **0.25 bh a tick**; none in a mid lunge (too short) |
| **Throttle** | the stick toward the rival speeds the flight, away slows it, within the cap | **±20%** of the nominal speed, never above the cap or below the minimum time |
| **Cancel and brake** | **release LT before the commit point**: the attacker decelerates to a stop in 8 ticks and the approach ends with no exchange and no further cost. The free feint. After the commit point a release does nothing | the commit point is the last **15 ticks** of a light charge, **20** of a heavy, **4** of a mid lunge |
| **Commit** | after the commit point the attack is coming; only a Dodge stops it, at the dodge-cancel's full cost (15 ki and the 3 s cooldown): re-tapping LT, or Escape (R3) | as slice 3's heavy charge, applied to every approach at its last stretch |
| **Weight** | light is the fast, feintable charge; heavy is slower, armoured, committed from takeoff (slice 3, unchanged); a piloted heavy is the same, it only adds steer and throttle | light 4 000 u/s, heavy 3 000 u/s nominal |

**Why LT.** The control of a flight is manoeuvring, and LT is already the flight button (boost, dodge, sprint). Holding it through an approach is a visible, deliberate commitment (a cost in ki and in a held finger), and releasing it is a feint a player can feel. An unpiloted lunge is cheap and predictable; a piloted one is flexible and costs ki, which is the trade a "more controllable lunge" should have. It also answers "easier to spot when they're used against you": the defender can see which kind is coming.

**Inputs by layout:** pad Arena: LT held with the attack press, kept held; keyboard: Space (or Period for P2) held through the flight; touch Full: the Dodge button held; touch Simple: the stick's outer ring held (the sprint ring) with the Attack press; Simple pad: A held. The steer and throttle are the left stick (or WASD). **No new intent field**: the sim reads the mask's LT bit (8) at the press and each tick.

## B3. What the defender needs to read it

| Need | Rule | Numbers |
| :--- | :--- | :--- |
| **A tell before it starts** | The hold is the tell: a charge pose and glow from the first tick of the press, a distinct colour per weight (light blue-white, heavy amber), a rising tone, and an **off-screen arrowhead** at the screen edge pointing at the charger while he is beyond the camera's frame. A piloted approach has its own trail (a clean blue streak with a flicker at the boost) against the unpiloted warm streak, so the defender knows a feint is still possible | already 8 ticks (light) and 16 (heavy) of hold; the takeoff flash at tick 8 and 16 |
| **A minimum travel time** | Any far charge flies at least this long, so the closing never pops | light **30** ticks (now 18), heavy **42** (now 30); a mid lunge **8** ticks with a **4-tick crouch** before it (now 3 ticks, no tell) |
| **A speed cap by distance** | The speed never rises above a cap, whatever the distance. Travel time is `distance / speed`, clamped between the minimum above and a longer maximum | light nominal 4 000 u/s rising to a cap of **6 000 u/s**, heavy 3 000 rising to **4 500**; maximum time **90** ticks light, **108** heavy |
| **A ceiling on charge range** | Beyond the range the cap and the maximum time can cover, a far press is the **taunt only** (the charge needs the player to close with free flight or boost first) | light **120 bh** (90 ticks at 6 000 u/s); heavy **108 bh** (108 ticks at 4 500 u/s) |
| **A smooth arrival** | The flight eases out over its last 12 ticks to half speed, so the engage never pops | speed ×1.0 down to ×0.5 across the last 12 ticks (the end point still follows the rival each tick) |
| **A marker and a countdown** | A ring appears on the **defender** at the engage point when the flight begins and closes toward it; it turns red at the commit point and the attacker's trail changes: from then on the attack is coming | ring from takeoff to engage; red at the commit point; a short lock-on click |
| **The wind-up as the second tell** | Unchanged: the exchange starts at the wind-up, 15 ticks light and 20 heavy | no change |

**The reading budget (first visible cue to the first blow),** against a guard or dodge decision of about 12 to 15 ticks:

| | Today (median) | Proposed minimum |
| :--- | ---: | ---: |
| Mid lunge | 3 to 20 ticks plus 15 or 20 of wind-up | 4 crouch + 8 + 15 or 20 = **27 to 32** ticks |
| Far light charge | 8 hold + 19 to 60 flight + 15 = 42 to 83 | 8 + 30 + 15 = **53** ticks |
| Far heavy charge | 16 hold + 30 to 84 flight + 20 = 66 to 120 | 16 + 42 + 20 = **78** ticks |

Flights as proposed (time `d / speed` clamped to the minimum and maximum, speed capped):

| Distance | Light flight | Light speed | Heavy flight | Heavy speed |
| ---: | ---: | ---: | ---: | ---: |
| 12 bh | 30 ticks | 1 800 u/s | 42 ticks | 1 290 u/s |
| 40 bh | 45 ticks | 4 000 u/s | 60 ticks | 3 000 u/s |
| 80 bh | 90 ticks | 4 000 u/s | 108 ticks | 3 330 u/s |
| 120 bh | 90 ticks | 6 000 u/s | 108 ticks (the heavy's range ends at 108 bh) | 4 500 u/s |
| beyond 120 bh | taunt only | | taunt only | |

## B4. Air recovery moves to the manoeuvre stance

Orb's ruling was "hold to brake at a ki cost" (not the dodge tap); the button was my proposal (Guard, `agency-input.md` 4a). With LT now the manoeuvre stance, **LT is the better button and replaces Guard**: one finger, one verb, "LT gets you out of knockback":
- **Tap LT at a bounce or in a tumble: the tech** (the dodge tap of balance-targets §20, unchanged: 4 ticks before to 8 after a bounce's contact, any time in a tumble; 15 ki, the dodge-cancel cooldown).
- **Hold LT in the air (a launched fighter): the brake.** Speed bleeds off while it is held, ki drains each tick (the boost's rate), and the fighter returns to free flight when the speed is gone, the button is released or the ki runs out. **Not in the first 20 ticks after the last hit** (the lock, so a juggle still pays); a hold already down when the lock ends starts braking on that tick. The manoeuvre stance is immediate (no 12-tick sprint wait), which a 20-tick lock needs.
- **Guard held in a knockback** is the defensive stance's, not the brake: Game Design's matrix decides (an air block, a reversal). A fresh guard press during a knockback is still not a perfect block.
- **Simple:** A (dodge) held; **touch:** the Dodge button held or the outer ring.
- **Cost of the choice:** a player who holds LT in a juggle also dodges on the press (the dodge is the first tick of the stance). Inside a launched state the dodge edge is only a tech (at its windows) or ignored, so there is no dodge-cancel; Game Design to confirm.

## B5. Measures for QA and Encounter

- Far charge flight: **p10 at least 30 ticks** (light), **median at least 45**; no flight above the cap (6 000 u/s light, 4 500 heavy).
- **No far charge from beyond 120 bh (light) or 108 bh (heavy)**: those presses are taunts (count them).
- **No free cancel after the commit point** (zero), piloted or not.
- Piloted approaches: share of approaches, ki spent, and cancels before the commit point (the feint rate); report beside the unpiloted share.
- A defender's guard or dodge taken during an approach: **share of approaches answered** should rise from today's figure.
- Match length and collateral move a little (flights are longer; slice 2 measured the approach at 11% of the time already); the budget is a median not more than 10 seconds longer.

## What each director needs

| Who | What |
| :--- | :--- |
| **Game Design** | the stance-by-button matrix (5 by 4, plus the Simple column); whether hybrids exist; whether a stance entered while threatened pays the dodge-cancel; the brake's and the piloted flight's ki per tick; the charge ceiling; whether Brawler is retired; whether a longer approach is acceptable for eight-minute matches |
| **Simulation** | `stanceMask` (bits 47 to 50) and `contextHeld` (bit 51) in the intent, intent version 4, the hash line, the pack test, one golden; **the 53-bit record needs no split now** (1 spare bit; split when a field of more than one bit is asked for, or decide at I3, which frees 5); the director's stance for a Simple slot (`mode` -1) |
| **Encounter** (`bands.gd`, `interrupts.json` `bands`) | read the mask; the piloted approach (steer, throttle, release-cancel, commit point, ki); the minimum and maximum times, speed cap, range ceiling, ease-out; the AI writes the mask; the press log keeps it |
| **Controls** | the layout's stance stack and one-shot latch, the touch badge states, the trigger debounce and sensitivity setting, the D-pad one-shot, the tests; migrating a Brawler choice; no code until the matrix exists |
| **UI** | the stance badge (which stance is active, the armed one-shot), the settings ("Stance buttons: hold or latch", the trigger sensitivity), the off-screen arrowhead, the Brawler removal text |
| **Animation** | one stance pose per stance; the 4-tick crouch before a mid lunge; the charge and takeoff poses per weight |
| **VFX** | the engage-point ring on the defender, red at the commit point; the piloted and unpiloted trails; the takeoff flash |
| **Camera** | frame the attacker while a far approach is on (an inset or a zoom-out that keeps the charger on screen); no shake: the flight is the read |
| **Audio** | the rising tone through the hold, the lock-on click at the commit point, a stance-entry cue per stance |
