# Energy attacks overhaul: the input grammar (paper)

Controls, 2026-10-23, for Orb's brief (`docs/ep/vision.md`, "Energy attacks overhaul") and Game Design's frame (`docs/design/energy-overhaul.md`, E1 to E117). Reconciled to the frame the same day: where this and the frame differ, the frame rules and the difference is a constraint listed in section 9. **Paper only: no code until the spec is ruled.** My part is whether the grammar can be pressed on a pad, a keyboard and a phone, and how it reads and feels.

## 1. The idea in one paragraph

**The energy modifier changes what a press makes, not how a press is read.** X, Y, B and A are already light, medium, heavy and grab (E12), and RB held is already the energy stance (E11). So energy light, medium, heavy and grab are the same four buttons with the stance held, and **tap, mash, hold and release (E13) are read by the same code as the martial strengths** (`SimPressRead`: a wind-up and its 4-tick grace, the slowing burst, the mash read, the latch). One grammar to learn, one set of tests, and the rapid fire Orb wants carried over is the light's existing rule.

## 2. What exists today (the size of the change)

- `mode` is momentary (hold RB; a setting makes it a toggle that latches). A face press lands in the mode of its own tick. Simple layouts have no mode control: the director picks blasts at range and melee close (`autoMode`).
- The stances are the four shoulder bits (LB 1, RB 2, RT 4, LT 8), **exclusive** (ruled 2026-10-04: the newest wins, the older button's own fields go neutral), "until hybrids exist". **The hybrid mechanism is built and tested but switched off:** `data/input/stances.json` holds `"hybrids": []`, and `stance_test.gd` runs LB+RB (mask 3), LT+RB (10) and LT+LB (9) when they are listed.
- A held X is a burst that slows (starts at 16 live ticks); Y and B are wind-ups that resolve as a tap or a charge at wind-up plus 4 ticks of grace on the live clock (`charge_read`); the latch makes every hold press-on, press-off; charges-off makes every press a tap; a one-shot latch arms a stance for one blow or 90 ticks.
- The intent already carries what the grammar needs (`mode`, `guard`, `stanceMask`, the edges and the levels `lightHeld`, `heavyHeld`, `sigHeld`, `contextHeld`, `waited`). **No new intent bit is expected.**

## 3. The gestures (E13, E14) and how they are read

| Gesture | The frame | The read | Constraint |
| :--- | :--- | :--- | :--- |
| **Tap** | released inside the window | one attack: X on the press; Y, B and A at the window's end | window = the wind-up (Y 12, B 16, A 10) **plus 4 ticks of grace**, live ticks, every device: the **hold decision is Y 16, B 20, A 14** |
| **Mash** | a press within 9 ticks of his last | each press is its own attack, capped (X 6, Y 12, B 24 ticks) | measured on true press ticks (`waited`); a press under the cap fires nothing but still gets a press-ack |
| **Hold** | still down at the decision point | X: the stream (from the burst start, 16). Y: charges 2 levels. B: charges 3 (the beam). A: charges or aims the grab | a cue per charge level; none auto-fires |
| **Release** | the button comes up | ends the stream; throws the charged lob; fires the beam at the level reached (before level 1 it is the heavy blast); throws the held grab | an edge at its true tick, even inside a hit-stop; level OFF |

Two details. **A's 14 is the catch's number** (tell 10 plus grace 4), so one figure serves the catch, the carry, the brace and the energy grab's hold. And **the energy windows differ from the martial ones** (Y 12, B 28, A 12 martial; Y 12, B 16, A 10 energy), so `windup_for` becomes mode-aware: data keys `windupEnergyHeavy` 16 and `windupEnergyGrab` 10, the mode read from the press (a request already carries the mode of its own tick).

## 4. Press by press, per action (frame E15)

M = the energy stance (RB on Arena, Q on the solo keyboard, E and O on the shared ones, the Mode button on Full touch; held or toggled). Simple has no M: see section 5.

| Action | Pad (Arena) | Keys (solo) | Tap | Mash | Hold | Release |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **X: light** | M + X | M + J | a bolt, on the press tick | a bolt a press, one per 6 ticks | the stream, fires while held (from 16) | ends it |
| **Y: medium** | M + Y | M + K | a lob after its 12-tick window | a barrage, one lob a press | charges the lob, 2 levels (past 16) | throws it |
| **B: heavy** | M + B | M + L | the heavy blast (most devastating single shot) | one per press, every 24 ticks | charges the beam, 3 levels (past 20) | fires at the level reached; before level 1 it is the blast |
| **A: grab** | M + A | M + I | his energy grab, thrown | (in a catch, A is the payoff, E65) | charges or aims his grab (past 14) | throws it |
| **Mine or trap (E70)** | LB + RB + a face button | Shift + M + a face key | one mine of that weight, laid nearby | one per press (X at most 1 per 6 ticks) | held past the lay it goes farther, set on release (E71) | sets it |

## 5. By device: can it be pressed? And the lay (mask 3)

| Device | The stance M | The lay (LB + RB + face) | Verdict |
| :--- | :--- | :--- | :--- |
| **Arena pad** | RB (index) | LB + RB (both index) + a face button (thumb) | **Comfortable.** The stick is the other thumb |
| **Solo keyboard** | Q | Shift + Q + J, K, L or I | **Awkward while moving**: Shift, Q and WASD are all the left hand, and Shift + Q + a move key + J can ghost on a cheap board. **Toggle or latch is the recommended keyboard form**: energy latched, then Shift + a face key |
| **Shared keyboard** | E (P1), O (P2) | Shift + E + F/G/R; Semicolon + O + H/M/U | **Cramped**, as the shared layouts already are. Toggle or latch |
| **Simple pad** | none (the director's `autoMode`) | no RB to hold | the lay is **Guard (B) held, or tapped as a one-shot, plus a face button while the director is in energy mode** (range) |
| **Simple touch** | none (`autoMode`) | no chord is reachable | **tap Guard (the one-shot latch arms it for one blow or 90 ticks), then tap Attack at range**: a lay. One finger at a time |
| **Full touch** (tablets) | the Mode button (tap latches, hold is momentary) | Mode latched + Guard held + a diamond button | **Reachable** (two thumbs, or one if Guard is latched) |

**Mask 3 can be switched on without breaking the exclusivity ruling.** The ruling is "exclusive *until hybrids exist*"; the mechanism is built (`SimStance.resolve`, `stances.json`, `stance_test.gd`). `"hybrids": [3]` makes the layout report LB+RB as mask 3 with `guard` and `mode` both live; every other pair stays newest-wins (RT still dominates). Cost on my side: one data line and one test assertion (the one that says no hybrid is enabled). Both press orders give mask 3 and nothing is dropped; a one-shot tap on each also arms both; LB pressed with RB held still fires its perfect-block edge. The guard stays held in the input for the whole lay: the sim drops it for the lay frames (E72), which is the director's.

**Toggle mode is the one-hand lay.** With energy latched, holding LB alone is mask 3. It also fixes what a toggled player has today: guarding replaces the energy stance, because the newest button wins.

**Simple layouts have no energy half to press.** The director supplies it at range, so for a Simple slot Guard (held or one-shot) plus a face button at range is the lay, read by the director with no input change. I have withdrawn my earlier idea of the Power layer as the energy layer: it made a lay three fingers (Guard, Power, Attack). On Simple touch, Attack picks the weight by its hold and swipe (tap light, hold medium, swipe up heavy), so a hold there cannot also mean "stream": **rapid fire on Simple touch is a mash of taps**, and the stream, the charged lob and the beam are pad, keyboard and Full-touch features, except that a swipe-up-and-hold can charge the beam (the finger stays down after the swipe).

An alternative trigger, if Game Design prefers it to mask 3: **the lay as a consequence of a block**: an energy attack thrown inside a perfect block's 30-tick riposte lays the trap. Same input on every device (Guard, then the face button), no hybrid and no new state. The mask-3 route is now cheap enough that it is Game Design's call.

## 6. Beam or blast, and not misfiring

1. **Choose by button.** X and Y are blasts; B is the heavy blast or the beam. No window exists in which a tap could become a beam: B tapped is the blast, B held past 20 ticks charges.
2. **The charge starts only past the decision point** (B 20, Y 16). A tap or a mash never reaches it. A release before level 1 fires the heavy blast, not a wasted charge.
3. **A charge is released by the button.** It is never fired by a timer (no auto-fire at full), so a player who cannot time a release stays at full.
4. **The cancel** (Guard or a dodge press during a charge) is a Game Design question; if wanted I add a `charge_cancel` read.
5. **Under a latched charge** the next press is the release; under charges-off every press is a tap, so the player gets the blast and never the beam (Game Design: acceptable, or a "charge for me" assist?).
6. **A swallowed press** (faster than a button's cap) gets a press-ack, so a mashing finger sees why nothing fired.

## 7. Feedback, with no markers over the fighters

| Channel | Charge | Fire | Owner |
| :--- | :--- | :--- | :--- |
| **The fighter's own body** | the hand gathers on the press (E14), deeper with each level | the release | Animation, VFX |
| **Screen-edge HUD** | stage ticks at the screen edge on the charger's side | empties | UI |
| **Rumble** | a pulse at each level, firmer each time, `charge_full` at the last; a held charge never buzzes continuously; a mine lay, a mine arming flare on the player's own device | one thump scaled by the level | Controls: a `charge_stage` kind scaled by level over levels (data), `charge_full` exists |
| **Sound** | a rising tone, a step per level | the release | Audio |

Rumble is never the only cue, is silent on a keyboard and on iOS Safari, and is gated by the haptics option. **The input-side need is a cue per charge level** (`charge_stage`, `k`) from the director, so the HUD, Audio and rumble all follow one event.

## 8. Accessibility: hold or toggle, one hand

- **The stance:** the existing "Energy: hold or toggle" setting stays (E11). With toggle, RB latches; LB alone is then mask 3.
- **Charges:** the latch makes B press-on, press-off, fired by the next press. No auto-fire at full is what makes it safe.
- **Charges off:** every press is a tap (the blast, never the beam).
- **One hand:** on a pad, toggle plus LB reaches every lay with one thumb free; on touch, the one-shot Guard then Attack; on Simple layouts the director holds the energy half.
- **Rebinding and left-handed:** nothing here adds a control.

## 9. Constraints sent to Game Design, and open questions

1. The hold decision is window plus 4 ticks of grace on live ticks on every device (Y 16, B 20, A 14), or touch taps misread as holds.
2. `windup_for` becomes mode-aware (two data keys); no new intent field.
3. X fires on the press everywhere **except Simple touch**, where it goes out on the release (3 to 12 ticks late); the gather on touch-down is the mitigation and a separate Light button the fix (`phone-feasibility.md`).
4. A swallowed press under a cap still gets a press-ack.
5. A cue per charge level (`charge_stage`, `k`).
6. Mask 3 on by data, as section 5 says; mines and traps are lays on the keyboards best made by toggle or latch; on Simple and touch the lay is Guard (held or one-shot) plus a face button at range.
7. Questions for Game Design: whether Guard or a dodge cancels a charge; whether charges-off should give a "charge for me" assist; whether the riposte-window trigger is wanted instead of mask 3; whether the old signature and the heavy blast are the same thing.
8. A fighter's grab is one beat, a held carry or a placement (E63 and E64): the input only guarantees tap, hold and release, so each fighter's data must say which it uses.

## 10. What building it would take (after the ruling)

Small, and mostly data: `"hybrids": [3]` and the test assertion; the energy windows (two keys) and a mode-aware `windup_for`; a `charge_stage` rumble kind; a `charge_cancel` read if Guard cancels; the Simple guard-at-range rule is the director's; and tests per row of section 4 on each layout. What each press makes (the shots, the mines, the stages, the cancel) is Encounter's and Combat's.
