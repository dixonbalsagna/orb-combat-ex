# Right-hand attacks: one pad paradigm, "the left hand survives, the right hand hurts" (paper)

Controls, 2026-10-28, overnight workshop, for the EP's pitch (`docs/ep/right-hand-attacks-pitch.md`, Orb's words at its top). **Paper and one pure-arithmetic model** (`right-hand-attacks-model.mjs`, run with `node`); no sim code. Every tick count below is a first value for data, 60 Hz. Thumb timings are the **modelled** ones of `right-thumb.md` section 3 until the capture tool measures real thumbs.

Name used throughout: **directional-charge strikes** (a strike chosen by the stick's direction, quick on a flick, charged by holding).

## 0. Short answer

- **Recommend 4c+ (section 8): the stick is always "the big move of the current mode", and its strikes are their own class on screen but costed as heavy.** Martial: four strikes (up, down, toward, away). Energy (RB): beams. Power (RT): the signature, held and released. Buttons are quick, the stick is big, the shoulders pick which.
- **One reader for everything.** The stick is a fifth "button" with a direction, read by the same grammar as the face buttons (tap = quick, mash = capped repeats, hold = charge, release = throw; `energy-input.md` E13). Quick strike = charge level 0 of the same ladder. No flick-speed test is needed (the stick has no other job in play), which removes the flick-versus-hold misread of `right-stick.md` section 4.
- **The left hand does all defence, with no right-hand input in any of it:** LT + a flick = slip, LB + a flick = brace (v2's "read", moved), LB + LT together + a flick = vanish (replaces R3 Escape).
- **Zero claw advantage holds, and the law is lighter than before.** The model (section 6.3): with the lockouts off a claw gains 2 to 5 blows in ten seconds of alternating stick and face blows and 2 to 9 free blows during a charge; with them on it gains **none, in every pitch**. Almost all of the lockout is hidden inside the blows' own commitment; the real hole is the **charge**, closed by one rule (face presses are inert while the stick is held).
- Shoulders: 16 states listed in section 3. **Keep 9, reject 7.** Two hybrids come on by data (LB+RB lay, LT+RB kite); the rest stay exclusive.
- **Brawler is retired** (`input-scheme.md` amendment 2026-10-04); its map is given for completeness (section 4.2).

## 1. The strike read (the same for every pitch)

Where it lives: the layout layer, before the intent, integers only, as `right-stick.md` section 3. Reuses its dead zone 0.25, quantise 1/16, `on` 0.60 and `off` 0.35 (rescaled), `flickSettle` 2. New data block `strike` (all first values).

| Stage | Rule | Why |
| :--- | :--- | :--- |
| **Start** | the stick crosses `on` -> a strike request at crossing + 2 ticks. **Any speed of push counts** | the right stick does nothing else in play, so there is no flick/hold ambiguity to resolve; slow pushes are strikes too |
| **Layer** | the stance mask **at the crossing tick** (shoulders sampled before the stick), locked until the stick rests | martial / energy / power / lay; `right-stick.md` family lock (R23) |
| **Direction** | four-way relative to him (up, down, toward, away), 45 degrees each, a tie goes to the vertical; **locked at the settle** | four-way reads right 99% even for a casual thumb, eight-way 76%. A thumb wandering during a charge cannot change the strike |
| **Quick** | the stick is back under `off` before `D` = 12 ticks after the crossing -> the quick strike (level 0), thrown at its own wind-up end | the thumb's flick-and-return is 4 to 8 ticks (p90 about 10) |
| **Charge** | still deflected at `D` -> a charge; stages at D, D+18, D+42 (12, 30, 54), one cue per stage (`charge_stage`, as energy-input section 7); 3 levels for beams and strikes | one ladder, one HUD, one rumble |
| **Release** | the stick back under `off` -> thrown at that tick, at the level reached, in the locked direction; a true-tick edge even inside a hit-stop | as E13 |
| **Mash** | each new crossing is its own request, capped per strike like a face blow's mash cap | `SimPressRead` already does this |
| **No auto-fire, no free feint** | nothing throws by timer; returning to rest always throws (quick or charged). The only exits are the left hand's guard or dodge (section 8 Q4) | a stick wiggle must not be a free feint; a thumb that cannot time a release stays at full |
| **Accessibility** | `strike_style` hold or toggle, exactly `hold-toggles.md`'s mechanism: toggle = a deflection starts the charge, the **next** deflection throws | one-thumb and tremor |
| **R3 guard** | an R3 click is ignored while the stick is past 0.9 or within 6 ticks of it (kept; with R3 freed, section 7, the click does nothing anyway) | hard flicks click the stick |

**Beams and the signature on the stick.** Energy layer: the same read; the direction is the **aim** (relative to him: toward = at him, up and down = 45 degrees, away = behind), latched at the settle for a snap or charged beam. During his own beam the stick **steers the sweep** 32-way (R25, kept; he is rooted, so both thumbs are free). Power layer: the signature is **hold-and-release only**; a flick that returns before `D` fires nothing, costs nothing and shows a "hold to cast" cue, so a grazed stick never spends 45 ki. An unfunded hold is refused at once (`input-scheme.md` 4.5).

**Cost in the intent.** Intent v5's second word (already planned: `rsHold`, `rsEvent`, `rsLag`): active 1 bit, locked direction 2 bits (4-way) or 5 bits (the beam's 32-way sweep), start and release edges with lag. About 12 bits. The level is the sim's, counted from ticks. Simulation and Tools own the word; the hash includes it only under `switches.rightStick`.

## 2. The left hand: slip, brace, vanish

The left thumb was never on the buttons, so no claw question arises. All three keep today's rule that **a flick only adds a direction**: LT alone is the dodge, LB alone is the guard.

| Input | Read | What it makes | Cost |
| :--- | :--- | :--- | :--- |
| **LT tap + a left flick** (inside the 6-tick decision window) | R34 unchanged: the dodge starts on the press tick, the direction resolves over the next 6 ticks (95% practised, 81% casual, `claw-bot-gate.md` section 6) | up: sway over a low blow. down: duck under a high one. toward: slip in past the fist (dodge and counter). away: back-step off the line | the dodge's |
| **LT held** | sprint, as today (a deflection after tick 12 is steering) | | |
| **LB + a left flick from rest** | a quick onset (rise 3) from a stick at rest 10+ ticks while LB is down, **not** a held lean | the v2 read: up = his heavy, down = his flurry, toward = his grab, away = his shot; lasts 90 ticks or its first fire; one at a time | 3 ki when set |
| **LB + LT, down within 6 ticks (either order), then a flick or lean inside the same 6-tick window** | the vanish **upgrades the dodge**: the first 6 ticks are the common gather, so the dodge's press-tick start (T1) is untouched; at tick 6 the direction picks the blink | blink up, down, through to his back (toward), away (the escape). Sends the existing `escape` edge with the direction; `mx`, `my` already carry the rest | GD |
| LT pressed while LB has been held **more than 6 ticks** | not a chord | the ordinary dodge out of guard, as today | |

Guard walking is the misfire risk of the brace: a guarded player who pushes the stick quickly sets a read for 3 ki. Mitigation, in the read and not in a rule: a held lean never sets one (the guard's `nudge.guard` lean stays), and the rise setting 2 to 5 applies. If real play shows it bites, the fallback is a double flick (GD's "pump"). **Keyboard form:** a *tap* of a direction key (down and up inside 8 ticks) with Shift down; walking guarded is a hold.

## 3. Every shoulder combination

Four shoulders, 15 non-empty sets plus none. LB and LT are the left index finger, RB and RT the right. The stance mask is `LB 1, RB 2, RT 4, LT 8`; **RT always dominates** (`stance.gd`). "Right-hand never part of a defence" is the rule that rejects most of the unkept rows.

| Held | Mask | Meaning | + left stick | + right stick | Verdict and reason |
| :--- | ---: | :--- | :--- | :--- | :--- |
| none | 0 | martial | move | strikes (4 directions) | **Keep.** Today's base |
| LB | 1 | guard, tap = perfect block | brace (flick), guard lean (hold) | a strike thrown from guard carries the guard stance, as a face press does | **Keep** |
| LT | 8 | dodge tap, sprint hold | slip (tap + flick), steer (hold) | a strike from the manoeuvre stance (GD: lane in the director) | **Keep** |
| RB | 2 | energy, momentary | move | beams (snap, charge, sweep) | **Keep** (E11) |
| RT | 4 | power: burst tap, channel hold | move | **4c: the signature, held and released**; 4a, 4b: inert | **Keep** |
| LB + LT | 9 | not held as a stance (hybrid 9 "terrain" stays off); a **chord event** within 6 ticks | vanish | | **Keep as a chord, reject as a hold.** The only deliberate two-trigger left-hand input |
| LB + RB | 3 | the **lay**: mines and traps (E70), guard persists | | 4c+: the stick places it (toward = ahead, away = behind, up, down; charge = farther, E71) | **Keep, hybrid 3 on** |
| LT + RB | 10 | **kite**: sprint persists while energy is on, so blasts and beams fire while strafing | | beams while sprinting | **Keep, hybrid 10 on (GD).** It is the paradigm in one state: the left hand survives while the right hurts. Today RB's press ends the sprint |
| LT + RT | | the transform chord, 0.5 s | | | **Keep unchanged.** Pressed more than 6 apart it is a sprint with a channel, as today |
| LB + RT | 5 | guard + power | | | **Reject.** A guarded charge is a turtle, and RT dominates anyway; charging inside a defence breaks the pillar |
| RB + RT | | energy + power | | | **Reject.** One index finger on two triggers; RT dominates, so it would be a second way to say power |
| LB + LT + RB | | vanish chord with energy held | | | **Reject as a state.** The right shoulder passes through; a right-hand input is never part of a defence |
| LB + LT + RT | | | | | **Reject.** Three triggers, and LT+RT is the transform chord |
| LB + RB + RT | | | | | **Reject.** RT dominates; same as power |
| LT + RB + RT | | | | | **Reject.** Transform chord with a third trigger: ambiguous |
| all four | | | | | **Reject** |

## 4. The maps

Rows marked "all" are identical in 4a, 4b and 4c. The three pitches differ in what the stick means (4a own class, 4b pooled with heavy B, 4c mode-symmetric, my recommendation 4c+).

### 4.1 Arena (the default)

| Control | Today | All pitches | 4a | 4b | 4c / 4c+ |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Left stick | move | move; with LT, LB or both, a defence flick (section 2) | | | |
| LT | dodge tap, sprint hold | **evade**: tap = dodge, tap + flick = slip, hold = sprint | | | |
| LB | guard, tap = perfect block | **guard**; + flick = brace | | | |
| LB + LT (chord) | none | **vanish** (sends `escape`) | | | |
| RB | energy, momentary | unchanged (hold or toggle setting) | | | |
| RT | burst tap, power hold | unchanged | | | |
| X, Y | light, medium (energy: bolt, lob) | unchanged | | | |
| **B** | heavy (energy: heavy blast, hold = beam) | martial heavy unchanged | energy: heavy blast; hold = a bigger blast (GD, Q5); **beam leaves B** | energy: unchanged (tap blast, hold charges the beam); the stick is the **aimed** beam: same family | energy: as 4a |
| A | grab (energy: his grab) | unchanged | | | |
| RT + X, Y, A | specials 1 to 3 | unchanged | | | |
| **RT + B** | signature | | signature | signature | **4th special** (the signature moves to the stick) |
| **Right stick, martial** | none | | four own-class strikes: own recovery and stun rules, own charge ladder | four **directional heavies**: B's request with a direction; B's wind-up, recovery, ki and ladder | four strikes drawing on the heavy's **budget, recovery and ki**; own class on screen |
| **Right stick, RB held** | none | **beams**: snap on a quick, charge on a hold, aim locked at the settle, steer while out | | one family with B's beam | |
| **Right stick, RT held** | none | | inert | inert | **signature**, hold and release |
| LB + RB + a face button | lay (E70) | unchanged | | | |
| LB + RB + right stick | | | inert | inert | **4c+: the stick places the lay** |
| LT + RB | exclusive | **kite on (hybrid 10)**: sprint persists | | | |
| R3 | Escape | **freed** (target swap, or nothing); the vanish replaces it | | | |
| L3 | none | none | | | |
| D-pad | reserved | the **mirror** (section 5.3), setting | | | |
| LT + RT, 0.5 s | transform | unchanged | | | |
| Start, View | pause, hints | unchanged | | | |

### 4.2 Brawler (retired; if Orb brings it back)

Attacks on the shoulders, so the shoulders cannot also be the stance mask. Left hand as Arena: **LT evade, LB guard, LB + LT vanish, left flicks as section 2**. **RB light, RT heavy**, X mode (energy), Y power (hold) / burst (tap), B signature, A context, Y held + RB / RT / X = specials, Y held + B = signature. **Right stick: as Arena** in all three pitches, with the layer chosen by X (mode) and Y held (power) instead of RB / RT. The lay and the kite need a stance mask, which this layout does not have: **no hybrids on Brawler**. The right-thumb problem is worse here (X and Y are also thumb buttons, and the shoulders are attacks), so Brawler would need the law and nothing else. Recommend leaving it retired.

### 4.3 Simple (six buttons)

Today Simple's defence is on the **right thumb** (B guard, A dodge). A thumb that is charging a stick strike cannot react on A or B, which is exactly the problem the left-hand defence solves. So:

| Control | Today | Stick strikes off (default) | **Stick strikes on (Simple-S)** |
| :--- | :--- | :--- | :--- |
| Left stick | move | move | move; + LT or LB a defence flick |
| X, Y | attack (tap light, hold heavy), signature | unchanged | unchanged |
| B | guard | guard | **context** (grab and the rest) |
| A | dodge | dodge | unbound |
| LT | none | none | **dodge / sprint; + flick = slip** |
| LB | context | context | **guard, tap = perfect block; + flick = brace** (the director also sets reads at a modest rate) |
| RT | power | power | power |
| RB held 0.5 s | transform | transform | transform |
| Right stick | none | none | **one big move, the director picks its flavour** (4c's autoMode rule): close = a strike by direction, at range = a beam; hold = charge; signature stays on Y |
| LB + LT | | | vanish |

Simple-S is Arena without the mode and the burst. The match header records it with the other assist flags (`autoMode`, `autoBurst`). 4a / 4b / 4c change only what the close-range strike is.

## 5. Keyboard and the D-pad mirror

### 5.1 Solo keyboard (one human, two hands)

| Pad | Key | Note |
| :--- | :--- | :--- |
| Left stick | W A S D | |
| LT / LB / RB / RT | Space / Shift / Q / E | unchanged |
| Slip | Space + a **tap** of W, A, S or D | the direction read is the same 6-tick window |
| Brace | Shift + a tap of W, A, S or D (down and up in 8 ticks) | walking guarded is a hold, not a tap |
| Vanish | Shift + Space (within 6 ticks) + a tap | the single-key forms C, X and Quote (today's Escape) stay as **mirrors** of the chord; neutral = away. Same tick as the chord |
| X, Y, B, A | J K L I | |
| **Right stick** | the **arrow keys** | tap = quick, hold = charge, release = throw; two arrows give the 8-way beam aim; four-way strikes take the first pressed, a tie goes to the vertical |
| Beam | Q + arrows | |
| Signature (4c) | E + arrows, hold and release | |
| Assist: strike toward the movement keys | an unbound key (suggest U) | one-handed or no-arrow-cluster players: the direction is the WASD held at the press. Capability is lower (movement and strike direction are coupled), so it is an option and not the default |

The right hand moves between J K L I and the arrows, which is a transfer like a thumb's. The law lives in the sim, so the keyboard is **held to the same lockouts** and stays equal. Rebinding the arrows next to the attack keys is a Remap matter.

### 5.2 Shared keyboard, two players (one hand each)

No free cluster for two. The **strike key + the player's own movement keys** is the default here (the assist form of 5.1), and a second hand is not needed.

| Action | P1 (left hand) | P2 (right hand) |
| :--- | :--- | :--- |
| Strike (key + movement keys held) | **T** | **Quote** (confirm in `RenderKeys`; else BracketLeft) |
| Beam | E (mode) + T | O (mode) + Quote |
| Signature (4c) | Q (power) + T, hold and release | Slash (power) + Quote |
| Slip / brace / vanish | Space / Shift / both + a tap of WASD | Period / Semicolon / both + a tap of IJKL |
| Escape mirrors | C | the P2 key already bound to Escape |

A strike key with no direction held strikes **toward** him. Capability is lower than a pad's (the direction is the movement key), which matches the shared layout being a fallback. The recommended local pairing stays one keyboard plus one pad, or two pads.

### 5.3 The D-pad mirror (pad), per pitch

The D-pad is under the **left** thumb. The mirror is for a player who cannot use the right stick, so leaving the left stick costs movement; that is the price of the accessibility form and it is never faster than the stick.

| Stick command | D-pad form | Same tick |
| :--- | :--- | :--- |
| Strike (any layer) | a D-pad direction: tap = quick, hold = charge, release = throw. Two directions pressed: the first wins, a tie goes to the vertical | the D-pad waits the same 2 ticks of settle the stick does |
| Beam aim | the D-pad's 8 ways, stepped | |
| Signature (4c) | RT + D-pad hold | |
| Lay placement (4c+) | LB + RB + D-pad | |
| Slip / brace / vanish | LT, LB or both + a D-pad direction | the lateral part starts at tick 6 in every form (the common gather) |

Applies to 4a, 4b and 4c equally; only the table's right column differs (what the command does). **The mirror ships as a setting, default off** (a brush of the thumb against the D-pad while moving would throw an unwanted charged strike, which costs ki and position; the downside is asymmetric). It is on automatically on a pad that reports no right stick, and the controls screen offers it first thing.

## 6. The no-claw law, rerun

### 6.1 The law, restated for strikes

`right-thumb.md` rules 1 and 2 were written for a stick that **set a state**. The stick now **throws blows**, so rule 3 (commitment and lockout) carries the load and two rules are new. `L` = 6, `R` = 8, `W` = 36 as before.

| # | Rule |
| :--- | :--- |
| K1 | **No pairing in a beat** (kept). No command needs stick and face button together; a button never changes a strike in flight, a stick never changes a blow in flight. A same-tick pair: the face press wins, the strike starts R later |
| K2 | **Symmetric commitment** (kept). A face press after a stick command waits `L`; a stick command after a face press waits `R`; both act on the tick the wait ends; at most one waits; newest wins with a lapsed ack |
| K3 | **A stick hold makes the face buttons inert** (new in force). A face press during a charge queues; it starts at release + `L` or expires (queue 3 deep, 36 ticks). Nothing about a charge can be changed by a face button |
| K4 | **The strike is committed from its settle** (new). Direction locked, no free cancel by wiggling; the only cancels are the left hand's (guard, dodge) |
| K5 | **Defence purity** (new). No right-hand input (face, stick, RB, RT) is part of a defence or alters its result |
| K6 | **Layer by the mask at the crossing tick; shoulders before the stick.** Shoulders are index fingers, so they are not a transfer, but a tie must resolve the same for every grip |
| K7 | **Mirrors act on the stick's tick** (kept) |

### 6.2 Every link, with L and R

| Link | Claw gain, law off | Law on | Rule |
| :--- | :--- | :--- | :--- |
| quick strike -> X, Y, B, A | 0 if the strike commits 6 or more (all do) | 0 | K2 |
| charged strike thrown -> face | 0 (the recovery is far over 6) | 0 | K2, K3 |
| **stick held -> face press during the charge** | **+2 to +9 blows** | **0 (inert)** | **K3** |
| face -> stick: **X (commits 6)** | **2 ticks per link** (+2 to +5 blows in ten seconds) | 0 | K2 (R = 8) |
| face -> stick: Y (12), B (24), RT + face special | 0 | 0 | K2 |
| same tick, face and stick | strike 8 ticks early | strike at R | K1 |
| stick -> stick | none (same device, same settle) | none | |
| beam sweep -> face | none: he is rooted, attacks are locked | none | rooted |
| RB, RT -> stick | none: index finger; mask read at the crossing | none | K6 |
| LB, LT -> any right-hand input | none: left hand; the guard or dodge may cancel a charge by GD's ruling | none | K5 |
| Simple: A or B defence while charging | the thumb is busy: a *standard* thumb loses the defence | fixed by Simple-S: defence on LT and LB | section 4.3 |

### 6.3 The model run

`docs/controls/right-hand-attacks-model.mjs` (arithmetic over the lockouts; the strike commitments are assumptions: 4a 14, 4b 28, 4c 20 ticks; face blows commit at their mash caps X 6, Y 12, B 24). Last line: "every claw check holds with the law ON".

| Pitch, alternating strike and face blow | Blows in 600 ticks, law off: claw / fast / p50 / slow | Law on | Claw gain over fast (off, on) |
| :--- | :--- | :--- | :--- |
| 4a with X | 60 / 55 / 50 / 42 | 55 / 55 / 50 / 42 | +5, +0 |
| 4b with X | 35 / 33 / 32 / 28 | 33 / 33 / 32 / 28 | +2, +0 |
| 4c with X | 47 / 43 / 40 / 35 | 43 / 43 / 40 / 35 | +4, +0 |
| any pitch with Y or B | no gain | no gain | +0, +0 |

What it shows:
1. **The lockout bites only on X-then-stick** (X commits 6, `R` is 8). Every other single link is hidden inside the blow's own commitment. 4b (a 28-tick directional heavy) is claw-safe almost by itself; 4a, the quickest, depends on the law most.
2. **The charge is the big hole**: a charge of 54 ticks with X at its cap is 9 free blows for a claw. K3 closes it completely.
3. A slow standard thumb loses 15 to 25% of the blows against fast. That is the standard grip's own cost, not a claw advantage; the bar is claw against the **fast** standard thumb.
4. Mirror parity and the same-tick rule pass in the model.

### 6.4 What the real gate must add

`claw-bot-gate.md` assertions A to I stay. New rows once the strikes exist in the sim (the model is a prototype of them):

| # | Assertion |
| :--- | :--- |
| J | Strike then face, face then strike, for X, Y, B, A and RT + face, at `g` in 0..36, claw / fast / slow: the second starts on `max(g, L)` or `max(g + 2, R)` and the result is identical |
| K | **Charge**: any face press during a stick hold starts no earlier than release + `L`, whenever in the hold; a press the hold outlasts expires; the claw's blows in a charge window equal fast's (zero) |
| L | Direction lock: a stick that wanders after the settle throws in the locked direction; one deflection past `off` and back is one strike |
| M | Same tick: face wins, strike at `R` |
| N | Layer: RB / RT pressed on the crossing tick, a tick before and a tick after, give the same layer for claw, fast and slow orders |
| O | Defence purity: any right-hand noise (face presses, stick, RB, RT) during a slip, brace or vanish leaves its outcome and tick unchanged |
| P | Mirror: D-pad, arrow and key forms act on the stick's tick and cost the same, for strikes, beams, signature and lay |
| Q | Vanish: LB + LT within 6 ticks (either order) upgrades the dodge; 7 apart gives a dodge and a guard; LT after LB held more than 6 ticks is a plain dodge; the dodge still starts on its press tick |
| R | R3 never produces an `escape` once freed |

About 700 more short runs, still seconds of headless sim.

## 7. What happens to what exists

| Item | Becomes |
| :--- | :--- |
| **v2's reads** (LB + right flick, 90 ticks, 3 ki) | **Moved to the left thumb**: LB + a left flick (section 2). Same costs and effects; the persistence and gap-invariance machinery is no longer needed for claw reasons (a left thumb is not a claw issue) but the *prediction* design stays Game Design's |
| v2's **Aim latch** (RB flick sets the aim line for the face buttons) | **Retired.** RB + stick is the beam itself. Blasts fire toward him; an optional arc from the **left** stick's lean at the press is GD's Q11 |
| v2's **lay aim** (LB + RB flick) | Becomes the lay placement on the stick (4c+), or inert in 4a and 4b |
| v2's step commands (flick = step, hold = dash, orbit, skim) | **Dropped.** The right stick is attack-only. The dash, orbit and skim remain the left stick and LT's (flight already has them); nothing is lost that the left hand did not own |
| The law (`right-thumb.md`) | Restated in 6.1: rules 3 and 4 carry it, plus K3 to K6 |
| **R3 Escape** | **Freed.** Hard flicks click the stick, and with the right stick now the main attack input an accidental Escape mid-fight is a real harm; the R3 guard rule stays only as insurance. Escape becomes the **vanish chord**, which sends the same `escape` edge with a direction. R3 may be a target swap, or nothing. C, X and Quote on the keyboards stay as the single-key mirror |
| The **stance radial** (RB + right flick picks a stance) | **Retired**: RB + stick is beams. It was off by default and "dropped first on collision" |
| **E11** (RB = energy, momentary, hold or toggle) | Unchanged |
| **E12** (X, Y, B, A = the four weights) | Unchanged. B's energy hold-beam moves to the stick in 4a and 4c (4b keeps both) |
| **E13** (tap, mash, hold, release) | Unchanged, and now the stick's grammar too: one reader, the stick as a fifth button with a direction |
| E70 to E72 (the lay, hybrid 3) | Hybrid 3 on; the lay can be placed by the stick |
| `hold_style` (hold or toggle) | Gains `strike_style`; the same mechanism |

## 8. Recommendation: 4c+

**Choose 4c, with these settings** (the "+"):
1. **One ladder.** The quick strike is level 0 of the charge ladder, read by the existing press grammar. No second reader.
2. **Direction locks at the settle**; returning to rest always throws; the cancel is the left hand's.
3. **K3**: the face buttons are inert while the stick is held.
4. **Signature on RT + stick, hold-and-release only**, with B free in the power layer for a fourth special.
5. **Hybrids 3 (lay) and 10 (kite) on by data; 9 stays off.** The vanish is a chord event, not a stance.
6. **R3 freed, the radial retired, the aim latch retired.**
7. **Simple-S** (stick strikes on) moves defence to LT and LB.

**Why 4c over 4a and 4b**
- **4a (own class)** matches Orb's lean and is the quickest, but it is the one that leans hardest on the law (the model: +5 blows without it), adds a balance axis, and costs the most authoring (four moves a stance, outside light, medium and heavy).
- **4b (pooled with B)** is claw-safe almost for free and is the cheapest, but a directional heavy's wind-up (28 ticks) is not "a quick stunning blow", the stick and B do near-duplicate jobs, and "powerful" becomes a shared read. It loses the thing Orb asked for.
- **4c** keeps 4a's identity (a quick own-class blow chosen by direction) and 4b's economy (costed as heavy, so one balance axis), and is the only pitch where each layer's stick means the same thing ("the big move of the mode"), which is the one sentence Orb asked for. It also gives the beam its home on the stick and frees B.

**Variants found.** (V1) the kite hybrid (LT + RB), the cleanest use of "the left hand survives while the right hurts"; (V2) the vanish as an *upgrade of the dodge* rather than a separate action, so T1 is untouched; (V3) a stick that places the lay; (V4) `strike_style` toggle; (V5) the shared-keyboard strike key; (V6) Simple-S. None is required by 4c.

**Reasons in one line each.** Zero claw advantage by the model; one reader and one ladder (small build); no right-hand input in any defence; B and the face buttons stay exactly what every player already knows; keyboard parity without a new recogniser.

## 9. Questions for Game Design (with my recommendation)

1. 4a, 4b or 4c. **4c+.**
2. The stun and recovery of a quick strike; does it stun on hit or only on a clean one?
3. The charge ladder: 3 levels and 12 / 30 / 54, or fewer?
4. Does a guard or a dodge press cancel a charge, and is the charge kept or lost? **Cancel, lose it; the dodge pays its ki.** A kept charge would make the left hand a free shield for the right.
5. With the beam on the stick, what is B in the energy layer, tap and hold? **A heavy blast; hold = a bigger two-level blast.**
6. The signature on RT + stick, hold-and-release only, and a fourth special on RT + B. **Yes.**
7. The vanish: ki cost, cooldown, what it does inside a brawl or a clinch, and does it replace R3 Escape. **Replace; the dodge-with-stick-away brawl exit stays.**
8. Is the brace available while stunned, and is a wrongly set read still a 3 ki loss?
9. Hybrids 3 and 10 on, 9 off.
10. The stance lane of a strike thrown from guard or from the manoeuvre stance: the director's stance table gets the mask at the crossing tick, as a face press does.
11. Blast aim: toward him always, or an arc from the left stick's lean at the press?
12. Simple: stick strikes default off; on, defence moves to the shoulders.

**For Orb after the workshop** (EP's list): 4a, 4b or 4c; the vanish replacing R3 Escape (**yes**); the D-pad mirror (**a setting, default off**, automatic on a pad with no right stick).

## 10. What it costs and next

- **Controls:** the strike reader (pure, in `sim/input/`), the left-hand upgrade rules, the hybrids' data lines and the extended gate (J to R). About as large as step 1 was.
- **Simulation and Tools:** intent v5's second word, data and schema (`strike`, `switches.rightStick`).
- **Encounter and Combat:** strikes as a generator class (4c: costed as heavy), the beam as the energy stick's family, the vanish as an upgrade of the dodge; Animation: up to four directional strikes and a charge pose per fighter.
- **UI:** legend, how-to-play, glyphs, `strike_style` row.
- **Research:** a prototype with the three pitches switchable can use this page's section 1 as the reader.
- **Tools / QA:** the capture page's "transfer" block still decides `L`, `R` and `W`; the strike dwell (flick-and-return) is a second measurement for `D`.
- **No code until Game Design rules and Orb picks.**
