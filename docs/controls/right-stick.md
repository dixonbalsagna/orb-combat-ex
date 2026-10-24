# The right stick: the input side of every pitch (paper)

Controls, 2026-10-23, for Orb's brief (verbatim in the EP's message; "attack, mobility, or a hybrid by which inputs are held; a quick flick versus a steady hold; free-form patterns like a skateboarding game's tricks; another way of commanding your fighter"). Game Design writes the combat pitches; Research may prototype. **This is the input side**: what can be read deterministically, how reliably, how it maps per held modifier, what the keyboard and the phone do, and what it costs. Paper only. The misread rates come from a **model of synthetic thumb traces** (`docs/controls/right-stick-model.py`), not from people; QA's real traces replace them.

## 1. Short answer

- **A hybrid by held modifier is feasible, and a flick-or-hold read is reliable for a practised thumb.** Direction is the weak point for a casual thumb: eight directions read right about three times in four, four directions about 99 in 100. So **flicks should be four-way commands**; eight-way and analogue belong to aim.
- **Patterns are feasible but should be the garnish, not the staple.** Circles read near-perfectly for a practised thumb and 45 to 70% for a casual one; zig-zags and pumps are worse for casual play. So no pattern may gate anything essential (defence, escape), every pattern has a single-button equivalent, and a "loose" setting widens them.
- **The hard physical fact: on a pad the right thumb is also the face-button thumb.** The right stick and X, Y, B, A cannot be used in the same instant (barring a claw grip, back paddles or a Steam Deck's rear buttons). So the right stick is a **"set, then let go"** control: commands that position the fighter or set an aim *between* attacks, never "hold the stick while pressing a face button". Everything below respects that.
- **Orb's history respected.** On 2026-10-05 Orb did not pick "the right stick calling the launch", and ADR 0009 says no depth control enters the scheme. Nothing here calls a launch or moves depth; the right stick commands the player's own fighter.

## 2. What the stick is today

Unused in play (`input-scheme.md` section 2.1: "reserved for hints and emotes; the right stick for the free camera in replays"). R3 (the click) is Escape on Arena. An **optional stance radial** (hold RB, flick the right stick: up/right/down/left) is specced and off by default; with the hybrids on (the energy overhaul's LB+RB) it must stay optional and is dropped first if it collides.

## 3. The read: deterministic, per tick, same for every device

**Where it runs.** In the layout layer (mine), before the intent, as every other gesture does (the touch flick, the swipe). The recognizer is a pure function of one quantised sample per fixed tick; the intent carries its output, so the replay and rollback carry the result and not the samples, and **keyboard and touch feed the same recognizer** (below). Per tick the host takes the **peak deflection in that tick's polling interval**, so a one-frame flick at 144 Hz is not lost to a 60 Hz tick.

**Pipeline.** Radial dead zone 0.25 (setting 0.15 to 0.45, for drift), rescaled to 0 to 1, quantised to 1/16, then:

| Stage | Number (first values, in data) | Why |
| :--- | :--- | :--- |
| Deflected on / off (hysteresis) | on at 0.60, off at 0.35 | a thumb recentring overshoots into the opposite side at 0.1 to 0.45; the gap swallows it |
| **Flick** | the stick goes from at-rest (0.2) to deflected in 3 ticks or fewer (a setting, 2 to 5) | the speed of the onset, not its size, makes a flick |
| Flick direction | the sector 2 ticks after the crossing, four-way (up, right, down, left), 45 degrees either side | the thumb is still sweeping at the crossing; waiting 2 ticks (33 ms) settles it |
| **Hold** | deflected 10 ticks, then a level every tick: direction (eight or sixteen sectors for aim), magnitude (3 bands) | a steady direction is a command that continues |
| A quick push that stays | **a flick, then a hold** (both) | by design: the commands below are chosen so that the flick at the start of a hold agrees with it, so the fuzzy edge costs nothing |
| **Pattern** | collected from the first deflection to the close: the stick at rest for 5 ticks, or 12 ticks without a new sector. Matched by **angle accumulated** (circles) and **stroke reversals** (zig-zags) | sector tokens alone misread slow circles; angle and strokes tolerate sloppy aim |
| Quarter circle | 65 degrees or more, steady turning (80% of the path in one direction), 70 ticks or fewer | |
| Half circle | 140 degrees or more | |
| Full circle | 300 degrees or more | |
| Zig-zag | 3 or more strokes, each at least 0.6 of the radius, each reversing the last, 60 ticks or fewer | |
| Pump | a zig-zag on the vertical axis (up-down-up-down) | |

**Latency.** A flick fires its direction 2 ticks after it crosses (about 33 ms after the thumb starts, inside the 50 ms budget); a hold begins at 10 ticks; a pattern commits **about 5 ticks after the stick settles** (up to 83 ms after the last stroke). So patterns are for commands that are not reflexes; the commands that need to be instant are flicks and holds.

**Cost in the intent.** Output is: a hold level (active, direction, 3 magnitude bands) and an event (none, flick, quarter, half, full, zig-zag, pump) with its direction or orientation. That is about 10 bits, and the packed intent has **53 of 63 usable bits used**, so it fits exactly with nothing left for other work, and a 16-way aim direction does not fit. **Recommend a second packed word (intent v5)** carrying the right stick, so the first stays as it is. That is Simulation's and Tools' change (pack, unpack, hash, replay JSON, schema), not mine to make.

## 4. Misread rates (modelled; two skills; 1,000 traces per cell)

Synthetic thumbs: min-jerk strokes with timing and angle noise (practised: 8 degrees, casual: 18 degrees and 1.5 times slower), a 50% recentring overshoot after flicks, stick drift of up to 0.08, 1/16 quantisation. **These are not people.** They say how the thresholds behave and where to look; QA's capture of real thumbs on a pad, a Steam Deck and a phone replaces them.

| Intended | Practised thumb | Casual thumb | Reading |
| :--- | :--- | :--- | :--- |
| **Flick** (read as a flick) | 100% (rise 3) | 96% | |
| Flick direction, **eight-way** | 99% | **76%** | adjacent sector, 22.5 degrees is too narrow for 18 degrees of error |
| Flick direction, **four-way** | 99% | ~99% (analytic, 45 degrees either side) | **so flicks are four-way** |
| **Steady hold** read as a hold | 100% | 100% | |
| A slow hold also read as a flick (onset 7 to 16 ticks) | 40% at rise 3, **4% at rise 2** | 5% | the tuning dial: a tighter rise costs flicks (casual: 80% at rise 2) but saves holds. Rise 3 default, 2 to 5 a setting; harmless by design (flick-then-hold agrees) |
| Quarter circle | 100% | **45%** | a casual quarter is a short arc; widen to 55 degrees on "loose" |
| Half circle | 100% | 72% (14% read as another circle) | |
| Full circle | 100% | 70% (15% as another circle) | |
| Zig-zag (3 strokes) | 91% | **46%** | fast casual strokes are small and uneven |
| Pump (4 strokes, vertical) | 92% | 53% | |
| Sloppy aim (no pattern meant), **false pattern per second of wander** | 6% | 5% | **patterns must be off in any stance where the stick aims**, or a sweep fires one every 15 to 20 seconds |
| Idle (drift only) | 0% | 0% | the dead zone and hysteresis hold |

What to do with them: flicks four-way; patterns **armed only where the stick is not aiming**; a pattern's wrong match costs a harmless command (never a damaging one); every pattern has a single-button equivalent; a "loose" setting (looser angles, 1.5 times the windows, 55-degree quarters) for casual thumbs; and the real-thumb capture before any pattern ships.

## 5. What the stick means per held modifier (illustrative; Game Design's pitches decide)

The input rule is **one reading per stance**, so the thumb never has to guess: **Step** (flick and hold, patterns on), **Aim** (hold sets a latched aim line, patterns off) or **Off**. Commands below are examples that fit the existing sim (no new systems); the pitches choose.

| Held | Mode | Flick (four-way) | Hold | Patterns | Why this mode |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **None** (martial) | Step | a step-dodge in that direction | drift or orbit that way, relative to the rival | zig-zag a weave (evasive series); pump a bob or feint; half circle a swooping arc into reach; full circle a flourish or taunt | positioning and style between exchanges |
| **Guard** (LB, mask 1) | Step | a slip or parry toward that side | a lean that sets the guard's facing | pump a brace | defence in a direction; patterns kept small |
| **Energy** (RB, mask 2) | **Aim** | sets the aim line for the next shot (it stays) | sweeps the aim and a held beam | **off** | the stick is the aim; the face buttons fire, so aim must persist after the thumb leaves |
| **Power** (RT, mask 4) | Off, or Step | release direction of a charged shot | | pump: pump the charge (rhythm), optional | the charge already uses the face buttons |
| **Manoeuvre** (LT, mask 8) | Step | a burst of boost that way | the boost vector, independent of the left stick | full circle a roll | `hold LT to boost in any direction` already; the right stick can aim the boost while the left flies |
| **Lay** (LB+RB, mask 3) | Aim | sets where the next lay goes (up to the 3 bh or 6 bh of E71) | | off | the lay needs the thumb on the face buttons |

A consequence of "set, then let go": **aim latched by a flick** is the design that makes the right stick usable for energy on a pad at all. A twin-stick shooter fires on a trigger; here fire is on the face buttons, so the aim cannot be held while firing.

## 6. Parity: keyboard and touch (Orb's rule: gamepad and keyboard are equal)

The recognizer takes **sector tokens and a magnitude**. Digital input produces them exactly (a key is a full-deflection token), so every right-stick action has a keyboard form with **no new recognizer**.

| Device | The right stick | Flick | Hold | Patterns |
| :--- | :--- | :--- | :--- | :--- |
| **Pad (Arena, Simple)** | the right stick | a quick throw | held | drawn on the stick |
| **Steam Deck, pads with back buttons** | the right stick | | | and the back paddles may carry the face buttons for a claw grip |
| **Solo keyboard** | **the arrow keys** (free; eight-way digital) | tap | hold | key sequences: left-right-left a zig-zag; up, right, down, left a circle: exact, often easier than analogue |
| **Shared keyboard** | no free cluster for two | one command key per player per direction is not available; each command also has a **single key** (default unbound, rebindable) | | each pattern's single-key form |
| **Touch, tablet (Full)** | a **second floating stick** in the upper right, above the diamond | swipe | hold | drawn with the finger |
| **Touch, phone (Simple)** | a **gesture pad** in the empty upper-right area (about 120 dp square), or none | swipe | hold | drawn with the finger: touch is the natural device for patterns |
| **Any device** | | | | **every command also has a button equivalent** (the capability is the same on every device, as the project's parity rule requires) |

Constraint for the phone: the right thumb already owns Attack, Guard and Power, so the gesture pad competes with attacking exactly as the pad's right stick does. The Simple phone layouts may leave the right stick to the director (autoMode performs the step commands as part of its picks), as they do the mode and the burst.

## 7. Accessibility

- **No pattern is required** for any essential action; patterns are style and optional positioning. Defence and escape never depend on one.
- **Every command has a button form**, rebindable, on every device (the single-key equivalents above).
- **Sensitivity:** flick rise 2 to 5 ticks, dead zone 0.15 to 0.45, a "loose" pattern preset, an option to restrict to four-way, and a longer pattern window.
- **Latched hold:** a flick sets a direction that persists until the next flick or the stick's click, for a thumb that cannot hold a deflection; the aim line already works this way.
- **One hand:** the single-key forms and the latch make every command reachable without the right stick; the pattern wheel (hold a button and tap a direction) is the alternative for a thumb that cannot draw.
- **Reduced motion and clarity:** the stick's gestures never cause flashing; feedback is the fighter's own body and the screen-edge HUD, nothing over the fighters (Orb's rule).
- **Settings text and glyphs** are UI's (a stick glyph exists; add a flick and a circle).

## 8. What this costs, and who

| Item | Owner |
| :--- | :--- |
| The recognizer, its data (thresholds as data in `timing.json` with a schema patch), tests, the keyboard and touch sources | Controls (about as large as the touch layer, mostly pure functions) |
| A second packed word for the right stick (pack, unpack, hash, replay, version) | Simulation, Tools |
| Reading the right-stick axes (pad axes 2 and 3) and feeding the layer | Rendering (host) |
| What each gesture does per stance, the ki costs and the timing of the step, the weave, the aim line | Game Design, Encounter, Combat |
| The gesture pad, the glyphs, the settings | UI |
| **Real thumb traces** on a pad, a Steam Deck and a phone, replacing the model | QA, with Research |

**Risks.** The right thumb conflict (section 1) is a physical limit, not a tuning problem, and the "set, then let go" rule is the answer. Pattern misreads are the largest feel risk for casual players (section 4). The intent's bit budget is full. A pattern's 5-tick commit is slow for anything reflexive.

## 9. Next

On the EP's word: (1) the real-trace capture (a one-page scratch tool in the repo that records 60 Hz stick samples while a person performs a scripted list: flicks, holds, each pattern; Research or QA runs it on their pads); (2) once Game Design picks which commands exist, I fix the thresholds from the traces, write the data and schema, the recognizer, the keyboard and touch sources and the tests; (3) the second word with Simulation and Tools. No code until then.

## 10. Reconciled to Game Design's pitches (2026-10-23, `docs/design/right-stick-pitches.md`, R1 to R10 and section 2)

Naming first: **GD's "pump" is a double flick the same way** (stronger flick, 18 ticks). What I called a pump above (up-down-up-down) is a vertical zig-zag. From here on, GD's names.

| GD's read (section 2) | My constraint | Why (modelled; assumed thumb speeds) |
| :--- | :--- | :--- |
| **Flick: out past 80% and back inside the dead zone within 8 ticks, 8 ways, acts at the peak** | A flick is read by **onset speed** (at rest to 0.60 rescaled in 3 ticks or fewer, setting 2 to 5), not by returning: acts at the crossing plus 2 ticks (33 ms), **never waits for the return**. "Back within 8 ticks" must go: it would reject a flick that stays, which is exactly R4 (a hold is its flick, continued). Threshold: 0.60 after the dead zone is rescaled (about 0.70 raw) | the return is not needed and costs R4 |
| **Eight directions** | **Four-way for every command a casual thumb must hit** (toward, away, up, down: 99%); **eight-way as extras whose neighbour is harmless** (a hop-toward misread as toward is still a burst): casual eight-way is 76% exact, an adjacent sector the rest of the time. Offer an eight-way setting for practised thumbs | 18 degrees of error against 22.5 degrees of sector |
| **Directions relative to him (toward, away)** | The layer gives **screen directions** (the sector) and the sim maps toward and away from the rival's side, as it does for the left stick. The layer never knows where the rival is | keeps the layer pure |
| **Hold: out past 50% for 10 ticks** | Hold on at **0.60**, off at **0.35** (hysteresis), 10 ticks; level each tick: direction in **16 sectors** (for aim) and **3 magnitude bands**. 50% with no hysteresis would flicker | flicker at the threshold |
| **Pump = two flicks the same way within 18 ticks** | Fine, and **it commits with no wait**: the second flick's event upgrades the first. A recentring overshoot (10 to 45%) stays under the 0.60 threshold, so it is not a flick | modelled |
| **Zig-zag: three or more reversals within 30 ticks** | Three reversals is four strokes. Modelled spans: a practised thumb **median 25 ticks (99% inside 30)**, a casual one **median 35 (21% inside 30)**. Ask: **two reversals (three strokes), inside 48 ticks**, each stroke at least 0.6 of the radius. As R5 says, **each reversal acts as a flick as it is drawn**, so the upgrade fires at the third stroke with no resting wait | the model's timings |
| **Half-circle: 180 degrees plus or minus 30, within 20 ticks, read where it ends** | A practised thumb: median span 26 ticks (25% inside 20); a casual one 36 (about 1% inside 20). Ask: **140 to 250 degrees, steady turning, inside 36 ticks**; anything over 300 is the circle, and the gap between is a half-circle. Commits when the sweep stops turning or the stick rests (about 5 ticks) | assumed speeds; real traces replace them |
| **Circle: 330 degrees or more within 30 ticks** | Practised median 28 (66% inside 30), casual 50 (9%). Ask: **300 degrees or more inside 48 ticks** | |
| **Five patterns, no more** | Agreed; I add that **patterns are read only in a family whose command set uses them** (never in an Aim family, where a sweep would fire one every 15 to 20 seconds) | modelled false rate |
| **R9: gestures read from the recorded history, deterministic** | **They are read in the layout layer, before the intent**, from one quantised sample per fixed tick, all in **integers** (a 16-way sector table by comparing |x| and |y| to 0.4142 of each other; circles by summing 22.5-degree steps of the sector change; no trig), so every platform agrees. The intent carries the result, so the replay and rollback never re-read samples. The AI emits the same fields | determinism and parity |
| **R1: one thumb, a face button plus the stick is not comfortable** | Agreed and encoded: the **family is fixed at the first deflection** and held until the stick returns to rest, so releasing a shoulder mid-gesture does not switch family; Aim latches after a flick so the thumb can go back to the face buttons | the physical limit |
| **R10: R3 stays the transform, held to confirm** | **Stale:** today **R3 is Escape** on Arena and Simple (a tap; transform is LT+RT, or the Simple RB hold). The real hazard is that **hard flicks sometimes click the stick**: I ignore an R3 edge while the right stick is beyond 0.9 or within 6 ticks of such a deflection | an accidental Escape mid-gesture |
| **Under mask 3 a flick sets where the next lay goes (up to 6 bh); during his own beam the stick steers the sweep** | Both are the right stick's Aim reading. E17 has the **left** stick sweeping a beam: GD to say which stick wins when both are held (the intent carries both) | |

**Touch swipes.** The same recognizer on a **floating virtual stick** (radius 56 dp, as the left stick). On a **tablet (Full)**: a second floating stick in the upper right. On a **phone (Simple)**: the empty **middle band** of the right half (about 42% to 68% of the width, lower 70% of the height) is a floating gesture stick that appears under the thumb; the upper-right corner has no room at 667 x 320. Because the right thumb also owns the buttons, **a phone has no held shoulder to pick the family**: the family there is a **latched Guard** (the approved Guard toggle) and **the director's energy at range**; on Simple the director performs the flight family otherwise. A flick is a drag of 0.7 of the radius in 3 ticks or fewer; lift is the release.

**Keyboard and mouse.** Digital input gives the recognizer exact sectors. **Solo keyboard: the arrow keys** are the right stick (a tap is a flick, a hold a hold, a key sequence a pattern). **Shared keyboard:** no free cluster for two humans, so each command has a single key (rebindable). **Mouse (not an input device of the game today, an option):** hold the right mouse button and drag; the press point is the stick's centre and the drag is the vector, with the same 56 dp-equivalent radius, so the mouse is a floating stick exactly like touch and needs no new recognizer. For **aim** only, an alternative is the cursor's offset from the fighter (absolute, 360 degrees, no flick); the host computes that vector and the layer reads it as a hold. Both need Rendering to feed a vector and a request to Orb whether the mouse is a supported device.

**Intent fields and version.** A **second packed word** (intent v5), zero in every old replay: `rsHold` (active 1 bit, 16-way direction 4, magnitude 2 = 7 bits); `rsEvent` (type 3: none, flick, pump, zig-zag, half-circle, circle; direction 3 or orientation, plus 1 for a turning or axis bit = 7 bits); `rsLag` (2 bits: ticks since the onset, like `waited`). About 16 bits, the rest reserved. The events are one-tick edges, pending through a hit freeze like every edge; **the gesture windows count real host ticks** (the sim does not step in a freeze), as the touch layer does. The hash includes the word only when the right stick is switched on for the match (`switches.rightStick`, off by default), so every existing replay and checkpoint is unchanged.

**What I still need from Game Design.** The command set per family and per gesture (so the 4-way against the 8-way split above can be fixed command by command); the left-stick against right-stick rule for a beam's sweep and for aim; and whether the first step (Flight and Energy with flicks and holds only, GD's recommended build order) needs any pattern at all: if not, **step 1 needs no recognizer beyond flick and hold**, which is small and safe to build first.

## 11. Step 1, fixed against GD's command set (`right-stick-pitches.md` section 11, R21 to R25)

Step 1 has **no patterns**: it needs only the flick and the hold, the family lock, the R3 guard and an aim angle. Nothing in it needs the pattern recognizer, which waits for the real-thumb capture (R20). Held until Orb picks.

**The numbers (data: a `rightStick` block in `timing.json`, schema by patch, behind `switches.rightStick`, off).**

| Key | Value | Notes |
| :--- | :--- | :--- |
| `deadZone` | 0.25 radial | setting 0.15 to 0.45; rescaled to 0 to 1, quantised to 1/16 |
| `on`, `off` | 0.60, 0.35 | hysteresis on the rescaled magnitude |
| `flickRise` | 3 ticks | rest (0.2) to `on`; setting 2 to 5 |
| `flickSettle` | 2 ticks | the flick's direction is taken 2 ticks after the crossing; the event fires then |
| `holdTicks` | 10 | a hold's level starts here (R4: the flick came first) |
| `flickDirs` | 4 | screen up, down, left, right, 45 degrees either side; a tie goes to the vertical (integer compare `|y| > |x|`) |
| `holdDirs` | 32 | 11.25-degree steps for the aim sweep; **Flight reads a hold as four-way with 8 degrees of hysteresis at the 45-degree edges**, so a thumb near a diagonal does not flip between the dash and the orbit |
| `r3GuardMag`, `r3GuardTicks` | 0.9, 6 | an R3 click is ignored while the stick is past 0.9 or within 6 ticks of it (R24) |
| `familyLock` | at the first deflection | until the stick rests (R23); the next gesture reads the new family |

**What the layer emits, by family (the family is the stance mask at the first deflection).**

| Mask at the first deflection | Family | The layer emits |
| :--- | :--- | :--- |
| 0 (nothing held) | Flight | a flick event (4 screen directions) and a hold level (4-way with hysteresis) |
| 2 (RB) | Energy aim | a flick event (4 directions) and a hold level (32-way angle) |
| 3 (LB+RB) | Lay aim | a flick event (4 directions) and a hold level (32-way angle) |
| 1, 4, 8, 10, 9, 5... | none in step 1 | nothing (the R3 guard still applies) |

The layer emits **screen directions**; the sim turns them into toward, away, up and down for the rival's side (R25's "directions are relative to him"), converts a 32-way hold angle into the aim line's angle off the line to him, and does the latching, the clearing (a toward flick, or RB let go), the seeking within 30 degrees and the beam sweep. The layer holds none of that, so the aim line follows him because the sim computes it from the current line to him each tick.

**Both sticks sweep a beam (R25).** The intent carries both sticks, the left as today and the right as the hold level; "out of the dead zone" is the right stick's `hold` being active. The sim picks (the right wins if both are out). No rule is needed in the layer.

**Sources, step 1.** Pad: the right stick (Rendering feeds pad axes 2 and 3 to the hub; one line, a host patch). Solo keyboard: the arrow keys (four directions; two arrows held give the diagonals for the aim sweep, in 45-degree steps; a tap is a flick, a hold is a hold). Shared keyboards: single keys, default unbound. Touch: a floating gesture stick (tablet: upper right; phone: the middle band); on a phone the family is the latched Guard and the director's energy at range, and on Simple the director performs Flight. Mouse is an option only if Orb makes it a supported device.

**The build (after Orb picks, behind `switches.rightStick`).**
1. `SimStickRead` (pure, in `sim/input/`): the flick, the hold, the dead zone, the family lock and the R3 guard, integers only; the tests (every row above, four-way accuracy on scripted noisy flicks, hysteresis at the diagonals, the family lock mid-gesture, the guard, freeze and pending edges, determinism).
2. The hub and layout: a right-stick sample per slot per tick (`hub.right_stick(slot, x, y)`), the keyboard and touch sources, and the output into the intent.
3. **Intent v5** (Simulation and Tools): the second word `rsHold` 7 bits, `rsEvent` 7 bits, `rsLag` 2 bits, the hash only with the switch on, the replay and schema. A 32-way hold angle is 5 bits, so `rsHold` becomes 8 bits: about 17 bits in all.
4. The schema patch (`rightStick` block, `switches.rightStick`), the gate list, and the switch-off equivalence run.
5. Encounter: the commands in the table above; Rendering: the axis line; UI: glyphs and the sensitivity settings.
