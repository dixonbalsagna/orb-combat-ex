# Right-hand attacks: "the left hand survives, the right hand hurts" (pitch 4a, built behind a switch)

Controls. First written 2026-10-28 for the EP's workshop, which recommended 4c+; **re-cut 2026-10-30 for Orb's pick of pure 4a** (`docs/ep/vision.md`, last section): the stick's strikes are their own class of moves. Game Design's numbers (`docs/design/right-hand-attacks-rulings.md`) are being amended for 4a; every number below is **data** (`data/input/timing.json`, blocks `strike` and `leftHand`), so a change of numbers is a data edit. The reader, the law, the left-hand upgrade, the hybrids, the swap and the gate are **built and parked behind `switches.rightStick`, which is off** (section 9). The arithmetic model of the first version stays in `right-hand-attacks-model.mjs`.

Name used throughout: **directional-charge strikes** (a strike chosen by the stick's direction, quick on a flick, charged by holding).

## 0. Short answer

- **Orb's picks.** (1) 4a: stick strikes are their own class, not pooled with B and not costed as the heavy. (2) Accessibility and customisable controls are assumed, **including left-handed players who swap the pad around**: so the left and right roles swap *as a whole* (section 8), the D-pad mirror is a setting, and remap covers the strike controls.
- **Martial: four strikes (up, down, toward, away) of the stick's own class.** A push is a request; a stick back at rest before `dwell` (12 live ticks) is the **quick strike** (level 0); a stick still out is a **charge** through three levels (12, 30, 50 first values) and the return to rest throws it. Levels 1 to 3 are the class's own, with their own numbers when Game Design sets them: the input side carries only "level 0 to 3" and the direction.
- **Energy (RB held): the stick is the beam** (snap on a quick, charge on a hold, steer while out), with blasts on the face buttons. **Power (RT held) and the lay (LB + RB): the stick is inert** (pure 4a: no stick signature, no fourth special; the signature stays RT + B). Both are data (`strike.inertMasks`), so 4c's stick signature is one data line if Orb ever wants it.
- **One reader for everything.** The stick is a fifth "button" with a direction. No flick-speed test is needed (the stick has nothing else to do), which removes the flick-versus-hold misread of `right-stick.md` section 4.
- **The left hand does all defence, with no right-hand input in any of it:** LT + a flick is the slip, LB + a flick is the brace (v2's read, moved), LB + LT together is the vanish (an upgrade of the dodge that sends `escape`). R3 is freed.
- **Zero claw advantage holds** by the law of section 6 (K1 to K7), proven on the real layout by a gate (262 checks), on a pad, on a keyboard, on the swapped pad and keyboard presets and through the D-pad mirror and the strike button.
- **Swap (`hand_layout`).** A swapped layout is a **preset**: `<pad preset>-swapped` for every pad preset (the whole-pad mirror of `SimSwap`: sticks, shoulders, face buttons with the D-pad) and `kb-solo-swapped` for the keyboard. The default left-handed layout is the **full mirror** (Research's check agrees: it keeps the one-thumb structure, where a sticks-only swap would put movement and defence flicks on the face-button thumb). The law is written on actions, so a swapped layout gives the **identical intent stream** to the standard one for the same hands, with the swapped thumb's own lockouts in data (`swapLockout`, `swapReverseLockout`, default equal to the unswapped, never faster). The whole gate runs on both presets.
- **Accessibility's routes** (`docs/accessibility/right-hand-controls.md`): a **strike button** on the pad whose direction is the left stick's (one-stick play), a **brace button** (timing-free; `brace_style` flick or press), the **single-control vanish** (Escape bindable to any control), `strike_style`, and Remap rows for all of them.

## 1. The strike read (built: `sim/input/strike_read.gd`)

Where it lives: the layout layer, before the intent. Pure and engine-agnostic. Data block `strike` (all first values).

| Stage | Rule | Why |
| :--- | :--- | :--- |
| **Start** | the stick crosses `on` (0.60 of the rescaled, quantised deflection; dead zone 0.25, 1/16 steps) -> a request that **starts `settle` = 2 ticks later**. Any speed of push counts | the right stick does nothing else in play, so there is no flick/hold ambiguity; slow pushes are strikes too |
| **Layer** | the stance mask **of the build in which the stick crossed**, locked until the stick rests (shoulders are sampled first, whatever order the events came in) | one layer per push; a tie resolves the same for every grip |
| **Direction** | four-way in **screen terms** (up, down, left, right), 45 degrees each, a tie to the vertical; **taken at the settle** (the stick as it is then, or its peak if it already came back) and locked. The director turns left/right into toward/away with the fighter's facing at the throw | a thumb wandering during a charge cannot change the strike; the input layer needs no world state |
| **Quick** | the stick is back under `off` (0.35) before `dwell` live ticks -> the quick strike, level 0, thrown at the start (a flick shorter than the settle starts and throws together) | the thumb's flick-and-return is 4 to 8 ticks |
| **Charge** | still out at `dwell` -> a charge; levels at `strike.levels` live ticks since the start (12, 30, 50; beams and the signature `beamLevels` 12, 30, 54). **Live ticks**: a hit freeze does not charge | one ladder; a held stick and a held B flash on the same step |
| **Release** | the stick back under `off` -> thrown at the level reached, in the locked direction; the edge keeps until a step takes it and carries its lag | true-tick throw inside a hit-stop |
| **Cancel** | only the left hand's: a guard press or a dodge ends a started charge with no throw (`rsCancel`); the stick must rest before the next request | a wiggle is never a free feint; a kept charge would make the left hand a free shield |
| **Struggle** | the host says each tick (`hub.set_struggle(slot, on)`) that the fighter is in a struggle (a beam clash, the finisher's contest): a started strike is cancelled (an edge, no throw), the stick is ignored until it rests, the faces are free at once and nothing queued comes out as a surge (Game Design: in a struggle the stick does nothing, and a sweep beside the surges would pair the stick and a button in one beat) | the surges are face presses on a pulse; K3 must never eat one |
| **Inert layers** | on a mask in `strike.inertMasks` (pure 4a: RT held 4, the lay 3) the push is ignored until the stick rests, and the faces stay free | 4a has no stick on those layers |
| **Toggle style** | `strike_style` "toggle" (accessibility, `hold-toggles.md`'s mechanism): a push starts the charge, the stick may rest, the **next** push throws it | one-thumb and tremor |
| **Strike key** | a key with no stick (the shared keyboard): a full push with whatever movement keys are held; none held is a request with direction 0, which the director reads as "toward him" | section 5 |
| **After a pause** | a stick still out fires nothing until it has rested | nothing pressed during a pause fires |

**The intent's second word** (built: `SimIntent.pack2`, 26 bits, `BITS2`; `pack()` is untouched, so a replay recorded with the switch off is the same integer): `rsHeld`, `rsStart`, `rsRelease`, `rsCancel` (bits 0 to 3), `rsDir` (0 to 4), `rsLevel` (0 to 3), `rsMask` (the layer, 4 bits), `rsAim` (the stick's 32-way sector now: the beam's sweep), `rsLag` (0 to 15 ticks an edge waited through a freeze), and the left hand's `brace` + `braceDir`. All neutral while the switch is off. **Simulation and Tools own wiring it into the hash and the packed replay** (`sim/core/hash.gd` INTENT list, `tools`), under `switches.rightStick`.

## 2. The left hand: slip, brace, vanish (built: `sim/input/left_hand.gd`)

The left thumb was never on the buttons, so no claw question arises. A flick only adds a direction: LT alone is the dodge, LB alone is the guard.

| Input | Read (as built) | What it makes |
| :--- | :--- | :--- |
| **LT tap + a left flick** | nothing new: the dodge edge on the press tick, the stick over the next 6 ticks (R34) | the slip: up sways over a low blow, down ducks, toward slips in, away backs off |
| **LT held** | sprint, as today | |
| **LB + a left flick from rest** | the stick sat at rest `braceRest` = 10 ticks, rose past `on` within `braceRise` = 3 of leaving rest (a lean is slower), LB down; the direction is taken `settle` = 2 after the crossing and the read goes out then; one at a time (the stick must rest before the next) | `brace` edge with `braceDir` (up his heavy, down his flurry, the two sides his grab or his shot, by facing); 3 ki and 90 ticks are Game Design's and the sim's |
| **Keyboard** | a **tap** of a direction key (down and up inside `braceTap` = 8 ticks) with Shift down; walking guarded is a hold, not a tap | the same edge |
| **Brace button** (`brace_key`; keyboard default X, X and Period on the other layouts; unbound on a pad, a Remap row) | pressed, it takes the direction held on the left stick or the movement keys over `settle` = 2 ticks (the strongest push) and sets the read then; with no direction held the read is set with direction 0 and the director picks. No LB, no flick speed, no second press. **`brace_style` "press"** (hub `set_brace_style`) turns the flick and tap reads off and leaves only the button | the same `brace` edge; cost and time are Game Design's and the sim's (3 ki, 90 ticks) |
| **LB + LT within `vanishWindow` = 6 ticks, either order, both still down** | resolves at the later of (first press + 6) and (second press + 2) with the strongest direction of the gather (a flick that began before the second press counts) | an `escape` edge with the stick vector (a neutral stick sends zero, which the sim reads as away). **The dodge's press-tick start is untouched** (T1): the vanish is an upgrade, not a replacement |
| LT pressed more than 6 after LB | not a chord | the ordinary dodge out of guard |
| LB or LT let go before it resolves | no vanish | a dodge and a guard |
| **Single-control vanish** | `escape` is a bindable action: bound to any control (the pad leaves it unbound; the keyboards have C, X, Quote), one press sends `escape` on its own tick with the stick's direction at the press. A toggled guard plus LT is a plain dodge, so a toggle user reaches the vanish by this button | Accessibility's row 7 |
| **R3 and L3** | the shipped Escape on them is dropped while the switch is on (`strike.freeR3`); the player may still bind Escape to either | row R: R3 never produces an escape by default |

The keyboard's single-key Escape mirrors (C; X and Quote on the shared halves) stay: a one-key vanish with a neutral direction.

## 3. Every shoulder combination

Four shoulders, 15 non-empty sets plus none. LB and LT are the left index finger, RB and RT the right. The stance mask is `LB 1, RB 2, RT 4, LT 8`; RT always dominates (`stance.gd`). **Keep 9, reject 7.**

| Held | Mask | Meaning | + left stick | + right stick (4a) | Verdict and reason |
| :--- | ---: | :--- | :--- | :--- | :--- |
| none | 0 | martial | move | **strikes (4 directions, own class)** | **Keep.** Today's base |
| LB | 1 | guard, tap = perfect block | brace (flick), guard lean (hold) | a strike thrown from guard carries the guard stance, as a face press does (the layer is `rsMask`) | **Keep** |
| LT | 8 | dodge tap, sprint hold | slip (tap + flick), steer (hold) | a strike on the move (the manoeuvre stance) | **Keep** |
| RB | 2 | energy, momentary | move | **beams** (snap, charge, sweep) | **Keep** (E11) |
| RT | 4 | power: burst tap, channel hold | move | **inert** (4a); the signature stays RT + B | **Keep** |
| LB + LT | 9 | a chord event within 6 ticks, not a stance (hybrid 9 stays off) | vanish | | **Keep as a chord, reject as a hold.** The one deliberate two-trigger left-hand input |
| LB + RB | 3 | the **lay** (E70): mines and traps, guard persists | | **inert** (4a; 4c would place the lay) | **Keep, hybrid 3 on** |
| LT + RB | 10 | the **kite**: sprint persists while energy is on, so blasts and snap-beams fire on the move | | beams while sprinting | **Keep, hybrid 10 on.** The paradigm in one state |
| LT + RT | | the transform chord, 0.5 s | | | **Keep unchanged** |
| LB + RT | 5 | guard + power | | | **Reject.** A guarded charge is a turtle, and RT dominates |
| RB + RT | | energy + power | | | **Reject.** One index finger, two triggers |
| LB + LT + RB | | vanish chord with energy held | | | **Reject as a state.** A right-hand input is never part of a defence |
| LB + LT + RT, LB + RB + RT, LT + RB + RT, all four | | | | | **Reject.** Three triggers; RT dominates or collides with the transform chord |

Hybrids 3 and 10 come on **with the switch** (`stances.json` `withRightStick`); 9 does not.

## 4. The maps (pitch 4a)

### 4.1 Arena (the default)

| Control | Today | 4a |
| :--- | :--- | :--- |
| Left stick | move | move; with LT, LB or both, a defence flick (section 2) |
| LT | dodge tap, sprint hold | **evade**: tap = dodge, tap + flick = slip, hold = sprint |
| LB | guard, tap = perfect block | **guard**; + flick = brace |
| LB + LT (chord) | none | **vanish** (sends `escape`) |
| RB | energy, momentary | unchanged (hold or toggle) |
| RT | burst tap, power hold | unchanged |
| X, Y, A | light, medium, grab (energy: bolt, lob, his grab) | unchanged |
| B | heavy (energy: heavy blast, hold = beam) | martial heavy unchanged; **energy: heavy blast, hold = a bigger blast; the beam leaves B** (Game Design Q5) |
| RT + X, Y, A / RT + B | specials 1 to 3 / signature | unchanged |
| **Right stick, martial** | none | **four own-class strikes** |
| **Right stick, RB held** | none | **beams**: snap on a quick, charge on a hold, aim = the locked direction, steer (`rsAim`) while out |
| Right stick, RT held / LB + RB | none | **inert** |
| LT + RB | exclusive | **kite on** (hybrid 10) |
| R3 | Escape | **freed** (a target swap, or nothing); the vanish replaces it |
| D-pad | reserved | the **mirror** of the right stick (section 5.3), a setting |
| LT + RT, 0.5 s | transform | unchanged |
| Start, View | pause, hints | unchanged |

### 4.2 Brawler (retired)

Attacks on the shoulders, so the shoulders cannot also be the stance mask. If Orb brings it back: left hand as Arena (LT evade, LB guard, LB + LT vanish), RB light, RT heavy, X mode, Y power; the right stick as Arena with the layer chosen by X and Y held; no hybrids. The thumb problem is worse there (X and Y are also thumb buttons). Recommendation unchanged: leave it retired.

### 4.3 Simple (six buttons)

Simple's defence is on the **right thumb** today (B guard, A dodge), which a thumb charging a stick strike cannot reach. So stick strikes are **off by default** on Simple, and **Simple-S** (strikes on) moves defence to LT and LB. The Simple presets carry no strike binding (built: no `strikeBindings`, so `rs_on` is false there); Simple-S is a later preset. The match header records it with the other assist flags (`autoMode`, `autoBurst`).

| Control | Today | Strikes off (default) | **Simple-S (later)** |
| :--- | :--- | :--- | :--- |
| X, Y | attack (tap light, hold heavy), signature | unchanged | unchanged |
| B / A | guard / dodge | unchanged | **context / unbound** |
| LT / LB | none / context | unchanged | **dodge, sprint, slip / guard, brace** |
| Right stick | none | none | **one big move, the director picks the flavour** |

## 5. Keyboard and the D-pad mirror

### 5.1 Solo keyboard (built)

| Pad | Key |
| :--- | :--- |
| Left stick | W A S D |
| LT / LB / RB / RT | Space / Shift / Q / E |
| X, Y, B, A | J K L I |
| **Right stick** | the **arrow keys** (`kb-solo` `strike` binding, a remappable four-key row): tap = quick, hold = charge, release = throw; two arrows take the vertical |
| Brace | Shift + a **tap** of a direction key (down and up inside 8 ticks) |
| Vanish | Shift + Space inside 6 ticks, a direction key tapped inside the gather; C is the single-key mirror (neutral = away) |
| Beam | Q + arrows |

### 5.2 Shared keyboard, two players (built)

No free cluster for two. A **strike key + the player's own movement keys** is the form here: the direction is the movement key held at the press; none held strikes toward him. **T is a system key (new match, `RESERVED_KEYS`), so the keys are not the ones the overnight draft named:**

| Action | P1 | P2 |
| :--- | :--- | :--- |
| Strike key (`strike_key`, remappable) | **B** | **BracketLeft** (`[`; Quote is P2's single-key Escape) |
| Beam | E (mode) + B | O (mode) + `[` |
| Brace key (`brace_key`, remappable) | **Z** | **BracketRight** |
| Brace, vanish chord | Shift / Space / both + a tap of WASD | Semicolon / Period / both + a tap of IJKL |

Capability is lower than a pad's (the direction is the movement key); the recommended pairing stays one keyboard plus one pad, or two pads. Section 6 holds on the keyboard exactly as on a pad (row P).

### 5.3 The D-pad mirror (built: `strike_mirror`, a pad binding of the four D-pad buttons)

The mirror is for a player who cannot use the right stick: tap = quick, hold = charge, release = throw, on the D-pad under the **left** thumb. It leaves the left stick for movement, which is the price of the accessibility form and never faster than the stick. **A setting** (`hub.set_mirror("auto" | "on" | "off")`, default "auto"): auto is on only for a pad the host says has no right stick (`hub.set_pad_has_right_stick(dev, false)`). The controls screen should offer it first thing. The mirror's four buttons are fixed rows in the remap screen. Under the swap the mirror sits on the face buttons (section 8).

**The brace button (a pad's default, 2026-10-31).** `brace_key` is **L3** on Arena (R3 on Arena swapped), so choosing the assist `brace_style` = "press" ("Button only") never strands a pad player with no control. The direction is the left stick's at the press; the brace costs what the flick brace costs. It is on in both styles, so a click of L3 sets a read in the default "flick" style too (a deliberate click, not a flick). Remap can move it; Simple has no strikes and no brace button.

**The strike button (Accessibility's one-stick form, `strike_key` on a pad).** A player who must keep the left stick for movement binds one free control (L3 is the natural one, but the brace button has it: see below; so the strike button ships unbound and is a Remap row, and a player who wants both moves one) as a strike button: held, it is the push, and the direction is the left stick's at the settle, none held being toward him. It reaches the same reader on the same tick as the stick (row V), costs the same, and the law applies unchanged. It is the pad's twin of the shared keyboard's strike key. Game Design rules the equal tick through the EP.

## 6. The no-claw law (built: `sim/input/strike_law.gd`, proved by `strike_gate_test.gd`)

`right-thumb.md` rules 1 and 2 were written for a stick that **set a state**. The stick now **throws blows**, so rule 3 (commitment and lockout) carries the load and K3 to K6 are new. `L` = 6, `R` = 8 (data `strike.lockout`, `strike.reverseLockout`). The law is applied **to the intent, on actions, never on device names**.

| # | Rule | As built |
| :--- | :--- | :--- |
| K1 | **No pairing in a beat.** Same tick: the face press wins, the strike starts R later | the law filters the faces by what the strike was *before* this build's step, so a press on the crossing tick (or before the start) goes through and sets the strike's floor |
| K2 | **Symmetric commitment.** A face press after a stick command waits `L`; a stick command after a face press waits `R`; at most one waits; newest wins | `stick_until` = the tick the thumb left the stick + L; the reader's `floor_tick` = the last face press + R |
| K3 | **A stick hold makes the face buttons inert.** A press queues (3 deep, 36 ticks) and goes out in its order, one a build, the first tick the stick is quiet. Held levels are off too | from the strike's start until the stick rests + L, whether it was thrown or cancelled |
| K4 | **The strike is committed from its settle.** Direction locked, no free cancel | only a guard or dodge press cancels (K5's other side) |
| K5 | **Defence purity.** No right-hand input is part of a defence or alters its result | the left-hand reads look at no right-hand field; row O proves it |
| K6 | **Layer by the mask of the crossing build; shoulders before the stick** | row N |
| K7 | **Mirrors act on the stick's tick** | the arrows, the D-pad and the strike key feed the same reader (row P) |

### 6.1 The gate (rows J to S), on the real layout

`sim/input/test/strike_gate_test.gd` drives the pad (and the keyboards) with scripted thumbs and asserts on the intent stream. **The whole pad battery runs twice, on `arena` and on `arena-swapped`** (Accessibility's rule 8), and the keyboards' battery on `kb-solo`, `kb-shared-p1` and `kb-solo-swapped`: 262 checks. With the switch on:

| Row | Assertion | Result |
| :--- | :--- | :--- |
| J | strike then X, Y, B, A and face then strike, at every gap 0 to 40 (30): the second never overlaps the first; the claw's best equals the fast thumb's (21 after a 10-tick start for a face after a strike; 18 for a strike after a face), and the law does not slow the fast thumb | pass |
| K | a claw tapping X every 6 ticks through charges of 12, 30 and 54: no face edge and no held level while the strike is in the sim's hands, none before the throw + L, at most the queue's 3 afterwards; an old press expires | pass |
| L | a stick that wanders after the settle throws in the locked direction; one deflection is one strike | pass |
| M | same tick, both orders of events: the face goes at the tick, the strike starts at +R | pass |
| N | the layer for RB a tick before, on, and a tick after the crossing, in both event orders, for LB held, and nothing | pass |
| O | noise on the right hand (face presses, the strike stick, RB) leaves a slip's dodge tick, a brace's tick and direction, and a vanish's tick and vector where they were | pass |
| P | the arrow keys, the D-pad mirror and the strike key start on the stick's tick with the stick's direction and throw on its tick; mirror off = the D-pad is nothing; a face key on the keyboard waits for the throw + L | pass |
| Q | the vanish: LB then LT, LT then LB, same tick, 6 apart (resolves 2 after the second), 7 apart (a dodge out of guard), let go early (none), neutral (zero vector), one escape per chord; the dodge still starts on LT's press tick; the keyboard form | pass |
| R | R3 and L3 produce no escape once freed; the keyboard's C still does; with the switch off R3 is Escape as before | pass |
| S | the swap: eight random 600-tick scripts give the **identical** intent stream (both words) on a mirrored pad; the mirror is its own inverse; Start and the keyboard are left alone; through the hub the physical right stick moves and the left strikes | pass |
| T | switch off: the intents equal the layout without the strike bindings on five random scripts, the second word is 0, the arrows strike nothing | pass |
| U | switch on: hybrids 3 and 10 come on and 9 does not; off, none | pass |
| inert | RT held and the lay: no strike, faces free, a push under RT that outlasts it fires nothing until it rests; RB, the kite and LT do strike with their layer | pass |
| V, W, X | the strike button on a pad starts on the stick's tick in the stick's direction and the law applies to it; the brace button sets the read 2 ticks after the press with the held direction (none: direction 0), once per press, unchanged by right-hand noise, and `brace_style` press turns the flick off; the single-control vanish sends `escape` on its press tick with the stick's direction, and is reachable with a toggled guard | pass |
| struggle | `set_struggle(true)`: a started strike is cancelled on that tick with no throw; a push inside it starts nothing; the surges go on their own press ticks with the stick out; a press queued before it does not come out inside it as a surge | pass |
| cancel, toggle, pause | a guard or dodge press cancels with an edge and the faces wait for the stick's rest + L; the toggle style; a pause | pass |

### 6.2 The model

`right-hand-attacks-model.mjs` (arithmetic) is unchanged in method; its strike commitments were placeholders (4a 14). With Game Design's 16 for the quick strike the lockout is still hidden inside the blow for every face button except X-then-stick (X commits 6, `R` is 8): the one link where a naive claw gains 2 ticks, closed by K2. The **charge** was the real hole (+2 to +9 free blows), closed by K3.

## 7. What happens to what exists

| Item | Becomes |
| :--- | :--- |
| **v2's reads** (LB + right flick, 90 ticks, 3 ki) | **Moved to the left thumb** (section 2). The persistence and gap-invariance machinery is no longer needed for claw reasons |
| v2's **aim latch** (RB flick sets the aim line for the face buttons) | **Retired.** RB + stick is the beam itself. Blasts fire toward him |
| v2's **lay aim** (LB + RB flick) | Inert in 4a; 4c would place the lay by the stick |
| v2's **step commands** (flick = step, hold = dash, orbit, skim) | **Dropped.** The right stick is attack-only; flight and LT own those moves |
| **R3 Escape** | **Freed**; the vanish chord replaces it. C, X and Quote stay as single-key mirrors |
| The **stance radial** | **Retired** (RB + stick is the beam) |
| **E11** (RB = energy, hold or toggle), **E12** (the four weights), **E13** (tap, mash, hold, release) | Unchanged; E13 is now the stick's grammar too |
| E70 to E72 (the lay, hybrid 3) | Hybrid 3 on; the lay is placed by the face buttons as today |
| `hold_style` | Gains `strike_style` (hub `set_strike_style`) |

## 8. Customisation: hand_layout, the swap as presets, and remap

Orb, 2026-10-30: accessibility settings and customizable controls are assumed, including left-handed players who swap their pad. The design rule: **roles are bound to actions, never to a hand**, so a swap is a renaming of controls and nothing else (Accessibility's rule 1: every string says defence hand and attack hand, or names the control).

**`hand_layout` is a preset choice** (Accessibility's rule 3, the EP's decision: as presets, keyboard included). Per player, `hub.set_hand_layout("standard" | "swapped", slot)`:
- **Pad:** `SimInputData` derives `<id>-swapped` for every pad preset from the shipped one (`SimSwap.mirror_preset`: left stick with right, LB with RB, LT with RT, L3 with R3, the four face buttons with the D-pad positionally; Start, Back untouched), tagged `hand: "swapped"`. It is **the full mirror**, the default left-handed layout: the hand that holds the stick that moves is the other one, and each thumb keeps the one-thumb structure of its stick plus its buttons. (A sticks-only swap would put movement and the defence flicks on the face-button thumb, a cost the sim does not model; Research's `claw-4a-swap.mjs` agrees.) It has its own remap, and Reset goes back to the mirror.
- **Keyboard:** `kb-solo-swapped` is shipped data in `layouts.json`: the arrows move, WASD is the strike stick, F G R V are the faces (V context), Q and E stay mode and power, Space and Shift stay dodge and guard (both are bilateral keys), Space + E or U transforms, Quote is Escape, Period is the brace key. The right hand moves and defends, the left hand attacks. The shared keyboard's halves have no swapped preset (remap them); touch is parked.
- **What changes in the sim: nothing.** The swapped preset is a layout; the stance mask, the strike reader, the law, the left-hand reads and the intent are the same code and the same numbers, and `SimLayout` takes the swapped thumb's lockouts from the preset's `hand` tag.

**The no-claw timing under a swap.** The law is written on actions, so it is the same law; the gate runs every row on the swapped preset and the swapped keyboard (section 6.1), and row S proves a mirrored pad gives the identical intents. The one thing that depends on the hand is how fast a thumb crosses between its stick and its face buttons (`L`, `R`, `W`) and the strike dwell `D`: the left thumb between the left stick and the D-pad is a different transfer from the right thumb between the right stick and the face buttons. So the law takes **its own numbers for a swapped layout** (`strike.swapLockout`, `strike.swapReverseLockout`), defaulting to the unswapped ones so a swapped layout is never faster. **QA's capture page needs a second measurement of the same protocol, run left-handed and on the D-pad** (Accessibility's row 2); until then the bar is the conservative one. Research's run on placeholder numbers shows zero claw gain with the swap.

**Remap (built: `sim/input/remap.gd`).** Every new control is a row: a keyboard's arrows (`strike`, a four-key row like `move`), the shared keyboards' strike keys and all three keyboards' brace keys (single-key rows), the swapped presets like any preset. The pad's right stick and D-pad mirror are fixed; the pad's strike button, brace button and Escape are **optional rows** (`SimInputRemap.OPTIONAL`: a row with no control while the switch is on, so the screen has somewhere to bind them). Conflicts, the diff to the player's file, overrides and the `layout-pair` rule cover all of it (checked: the shared halves share nothing).

**Settings the controls screen should offer** (UI): hand layout (standard or swapped, per player), the D-pad mirror (auto, on, off), the strike style (hold or toggle), the brace style (flick or press). Hub calls: `set_hand_layout`, `set_mirror`, `set_strike_style`, `set_brace_style`, `set_pad_has_right_stick`. **What the second push does in each strike style:** hold: the stick coming back throws it (quick under 12 live ticks, a charge after); toggle: the first push starts it and the **next** push throws it, with the stick free to rest between (a beam throws as the beam, a martial charge as the strike at the level reached). In both a guard or dodge press cancels a started charge with nothing thrown. Persisting the choices is the settings file's job (UI).

**Not built, and why.** A keyboard mirror by rule (there is no symmetric key layout; the swapped preset is authored); widened chord or slip windows as assists (they change outcomes, so they are gameplay assists recorded in the match settings and replay header: Game Design and Orb decide, ranked and online use included, through the EP); touch (ADR 0011).

## 9. What is built, behind what, and what it needs

- **Switch:** `data/input/timing.json` `switches.rightStick`, **false**. With it off no input path changes: the existing 24 input tests pass untouched, and a gate row (T) proves the intents are bit-identical to the layout without the strike bindings.
- **New files (`sim/input/`):** `strike_read.gd` (SimStrikeRead), `strike_law.gd` (SimStrikeLaw), `left_hand.gd` (SimLeftHand), `swap.gd` (SimSwap). **Changed:** `intent.gd` (the second word), `layout.gd`, `hub.gd` (`pad_stick_right`, the settings, `set_hand_layout`, `set_struggle`), `input_data.gd` (`right_stick_on`, `strikeBindings`, the derived swapped pad presets, hybrids), `remap.gd`.
- **Data:** `timing.json` (`switches.rightStick`, blocks `strike` and `leftHand`), `layouts.json` (`strikeBindings` on Arena, `kb-solo`, the swapped solo keyboard and the two shared halves; the preset `kb-solo-swapped`), `stances.json` (`withRightStick`).
- **Tests:** `strike_read_test.gd`, `left_hand_test.gd`, `strike_gate_test.gd` (262), `strike_hub_test.gd` (57) (listed in `input-gates.md`).
- **Needs from others (parked as patches in `docs/controls/pending/right-hand/`):** **one more host line that cannot be a patch yet:** `hub.set_struggle(slot, <the fighter is in a struggle>)` each tick, like `set_sent` (Simulation or Encounter names the flag; without it K3 can queue a surge while the stick is out). **UI's `ui/data/settings.json`** needs a name for the new keyboard preset (`remap.layouts`: `"kb-solo-swapped"`), or `validate` warns ("has no name in layouts") and the Remap screen cannot list it; the swapped pad presets (`arena-swapped`, `simple-pad-swapped`) are derived in code and need names there too. The schemas (Tools' `tools/schemas/input-timing`, `input-stances`, `input-layouts`: the data fails `validate` without them) and one host feed (`render/core/main.gd`: the right stick's axes to `hub.pad_stick_right`). **Simulation** reads the second word (hash, replay, the director's use of `rsStart`/`rsRelease`/`rsLevel`/`rsDir`/`rsMask`, `brace`/`braceDir`, the vanish on `escape`). **Combat and Encounter** author the strikes and beams. **UI** the legend, the settings rows and the how-to-play.

## 10. Open items

1. **Game Design's amended numbers** (the ladder, the quick strike's stun, the strike levels' own numbers): data, no code.
2. **Real-thumb numbers** for `L`, `R`, `W` (right thumb) and the swap side's, and `D` (the strike dwell, flick-and-return): the capture page (Tools).
3. **Accessibility** (via the EP): the list in `docs/accessibility/right-hand-controls.md` is built except rows 2 (the swapped thumb's capture: QA), 9 and 11 (UI), 12 (Accessibility). Open for Game Design / Orb: the widened-window assists and whether they may be used in ranked and online play; the equal tick of the strike button.
4. **Pure 4a leaves the power layer's stick and the lay's inert.** If Game Design wants the signature on the stick or the lay placed by it, that is `strike.inertMasks` and a sim read.
5. **xref-input** does not check `strikeBindings` yet (Tools).
