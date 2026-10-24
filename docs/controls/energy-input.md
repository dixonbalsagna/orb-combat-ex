# Energy attacks overhaul: the input grammar (paper, proposal)

Controls, 2026-10-23, for Orb's brief (`docs/ep/vision.md`, "Energy attacks overhaul") and Game Design's spec (`docs/design/energy-overhaul.md`, not yet written when this was drafted). **Paper only: no code until the spec is ruled.** Every number below is a proposal; the damage, ki and charge lengths are Game Design's and Combat's. My part is whether the grammar can be pressed on a pad, a keyboard and a phone, and how it feels.

## 1. The idea in one paragraph

**The energy modifier changes what a press makes, not how a press is read.** The four face buttons already mean light, medium, heavy and grab (X, Y, B, A), and hold-the-modifier already means "energy" (RB on the Arena pad, Q on the solo keyboard, E and O on the shared ones, the Mode button on Full touch). So energy light, medium, heavy and grab are the same four buttons with the modifier held, and **tap, mash, hold and release are read by the same code and the same timings as the martial strengths** (`SimPressRead`: the wind-up and its 4-tick grace, the burst's slowing auto-fire, the mash read, the latch). One grammar to learn, one set of tests, and the rapid-fire Orb wants carried over is not a new rule: it is the light's existing rule.

## 2. What exists today (so we know the size of the change)

- `mode` is momentary (hold RB; a setting makes it a toggle). A face press lands in the mode of its own tick (`agency-input.md` section 2). Simple layouts have no mode control: the director picks blasts at range and melee close (`autoMode`).
- The signature (B) is the 45 ki beam, one shared beam. The Power layer (RT or LB held + a face button) carries the loadout specials and the signature.
- A held X is a burst of eight lights that slows (`burst_read`, starts at 16 ticks); Y and B are wind-ups (12 and 28 live ticks, plus 4 of grace) that resolve as a tap or a charge (`charge_read`); the latch setting turns every hold into press-on, press-off; charges-off makes every press a tap.
- The intent already carries everything the grammar below needs (`mode`, `guard`, the face edges and levels `lightHeld`, `heavyHeld`, `sigHeld`, `contextHeld`, and `waited` for edge time). **No new intent bit is expected.**

## 3. The press types, once, for every energy action

| Press | Read as (the same as the martial button) | What it makes with the modifier held |
| :--- | :--- | :--- |
| **Tap** (released before the button's decision point: X none, Y 16, B 32 live ticks) | one attack, on the press tick for X; at the wind-up's end for Y and B | the **uncharged** form: a small bolt (X), a lob (Y), the heavy technique at its short length (B) |
| **Mash** (taps closer than the decision point) | each press is its own attack (`mash_of`); a mash never charges | **rapid fire**: a stream of bolts (X), lobs (Y), short technique pulses (B) |
| **Hold** past the decision point | X: auto-fire that slows (the burst). Y and B: **charge** | X: a rapid-fire stream. Y: a **charged lob**. B: a **charged beam** (stages, section 6) |
| **Release** | ends the burst; fires the charge at the stage reached | the stream stops; the charged shot leaves |
| **Cancel** (Guard or a dodge press during a charge) | a charge is dropped without firing (proposed, GD to confirm) | the charge is spent only up to what Game Design rules (ki already paid or refunded) |

Two consequences. **X never charges** (its hold is rapid fire), so a beam charge belongs to the strengths that already wind up. And **a mash can never fire a beam**: a press shorter than the decision point is a tap, so "rapid-fire beams" are a stream of short beam pulses, one per press, the way a martial heavy mashed is a string of heavies.

## 4. Press by press, per action (Arena pad / solo keyboard / Simple touch)

M = the energy modifier held. Pad = Arena (RB held). Keys = solo keyboard (Q held). Touch = Simple touch, where Power held stands for M (see section 5).

| Action | Pad | Keys | Touch (Simple) | Tap | Mash | Hold | Release |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Energy light** | M + X | M + J | Power + Attack tap | one bolt, press tick | a bolt per press | auto-fire, slowing from 16 ticks | stops |
| **Energy medium** | M + Y | M + K | Power + Attack hold (12 ticks) | a lob after its 12-tick wind-up | a lob per press | a **charged lob** past 16 | fires at the charge reached |
| **Energy heavy (beam)** | M + B | M + L | Power + Attack swipe up | the technique, short, after 28 ticks | short pulses, one per press | a **charged beam** past 32, in stages | fires at the stage reached |
| **Energy grab** | M + A | M + I | Context (tap) | the technique's first beat: net, ring, ... (per fighter) | not defined (one beat per press) | held = the technique's carry or brace if it has one (GD) | ends the carry |
| **Trap (a guarded throw)** | Guard (LB), then any energy face button within the window; see section 5 | Shift, then M + a face key within the window | Guard, then Attack within the window | the blast leaves a mine where it lands | one mine per press, capped (GD) | the charged form leaves a bigger one | as the strength |

## 5. By device: can it be pressed? And the trap

| Device | The modifier M | Verdict |
| :--- | :--- | :--- |
| **Arena pad** | RB (index) | **Comfortable** for M + a face button. The left stick is the other thumb |
| **Solo keyboard** | Q | **Fine**: Q with J, K, L or I |
| **Shared keyboard** | E (P1), O (P2) | **Cramped**, as the shared layouts already are |
| **Simple pad** | none (the director's `autoMode`); RT held is the Power layer | **Reachable only if the Power layer becomes the energy layer** (below) |
| **Simple touch** | none (`autoMode`); Power is the layer | Same: Power + Attack tap, hold, swipe |
| **Full touch** (tablets) | the Mode button (tap latches, hold is momentary) | **Reachable** (Mode + a diamond button) |

**Simple layouts: the Power layer is the energy layer.** Simple has no mode control, and the director already chooses blasts at range and melee close. I propose that on Simple pad and Simple touch, **Power held means "energy" for the face buttons** (Attack tap, hold, swipe up map to light, medium, heavy; `special_auto` retires into those), and a Simple player who never touches Power gets the director's pick as today.

**The trap: not a chord (corrected 2026-10-23).** My first draft read "defensive blocks while hitting energy attacks" as Guard + modifier + a face button held together. **The input layer cannot do that:** the four shoulder stances are exclusive (ruled 2026-10-04: the newest wins and the older button's fields go neutral; `stance_test.gd` asserts it), so pressing RB while LB is down drops the guard. Allowing the chord would mean un-ruling that exclusivity in the layer, plus a director branch that keeps the guard through a blast, and on touch it is three right-hand fingers. The cheaper readings, in order:

1. **Recommended: the trap is a consequence of a block, read by the director, with no input change.** A fighter who has just *blocked* (a perfect block already opens a riposte window, 30 ticks in Game Design's rule) and throws an energy attack inside that window leaves a trap where the blast lands. "Blocking while hitting energy attacks" becomes "block, then answer with energy": press Guard, then an energy button. It works the same on every device including a phone (Guard tap, then Attack), needs no chord, no change to the exclusivity, no new intent bit and no new input state; the director needs only the block's tick, which it has for the riposte.
2. **If Orb wants it without a successful block: a recent guard.** The sim keeps the last tick the guard was down (`guardLast`, one hashed field beside `guardSince`: Simulation's grant), and an energy attack thrown within W ticks (about 12) of it leaves the trap. A guard tap, then a face button, is the whole input. No chord, but one new sim field.
3. **The explicit chord** (Guard + modifier + face together) as first drafted: only if Game Design wants the player to choose a trap at will. Cost: the exclusivity change in my layer, a director branch that holds the guard through a blast, and no touch form.

**A already lays a mine** (energy family held outside an exchange, `DirBlast.layMine`): that stays the deliberate, placed mine. The trap above is the other kind, a by-product of a guarded counter.

## 6. Beam or blast, and not misfiring

1. **Choose by button, not by hold on one button.** Light and medium are blasts; the heavy is the beam or technique. A player who wants a blast presses X or Y; a player who wants a beam presses B. There is no window in which a tap could become a beam.
2. **The charge starts only past the decision point** (32 ticks on the heavy). A tap or a mash never reaches it.
3. **A charge is released by the button or cancelled by Guard or a dodge press.** It is never fired by a timer: no auto-fire at full charge (I recommend this for accessibility, section 8), so a player who holds past full simply stays at full.
4. **A stage count, not a bar.** The charge has N stages (2 or 3, Game Design's); each stage is one **cue** (`charge_stage` with `k`, and `charge_full` at the last, which exists today). The HUD, Audio and rumble all follow the cue, so none of them reads the sim.
5. **Releasing before the first stage is a tap**, not a wasted charge: you get the uncharged technique.
6. **Under a latched charge** the next press is the release, as today; the cancel is still Guard.

## 7. Feedback, with no markers over the fighters

| Channel | Charge | Fire | Cancel | Owner |
| :--- | :--- | :--- | :--- | :--- |
| **Fighter's own body** | hands and body gather and glow, deeper with each stage | the release pose | a shake-off | Animation, VFX |
| **Screen-edge HUD** | an edge bar or stage ticks at the screen edge on the charger's side (not on the fighter) | the bar empties | the bar drops | UI |
| **Rumble** | a pulse at each stage, firmer each time, and `charge_full` at the last; a held charge never buzzes continuously | one thump scaled by the stage | one short tick | Controls (`SimHaptics`): a `charge_stage` kind scaled by stage over stages, `charge_full` exists |
| **Sound** | a rising tone, a step per stage | the release | a falling cut | Audio |

Rumble is never the only cue (UI, sound and the body say the same), is silent on a keyboard and on iOS Safari, and is gated by the haptics option. The only input-side requirement is the per-stage cue.

## 8. Accessibility: hold or toggle, one hand

- **The modifier:** the existing "Energy: hold or toggle" setting (default hold) stays; with toggle, a tap of RB latches energy until the next tap. The Simple layouts need no modifier.
- **Charges:** the existing latched-charge setting makes B press-on, press-off. A latched B charges until pressed again, then fires at the stage reached; **no auto-fire at full** is what makes this safe for a player who cannot time a release.
- **Charges off:** every press is a tap, so a player who cannot hold gets the uncharged technique and never a beam. Game Design should decide whether that is acceptable or whether a "charge for me" assist exists.
- **One hand:** the Simple layouts reduce the grammar to Attack + Power on the right and a stick on the left; a one-handed pad player is served by the latch (no held modifier, no held charge). The trap needs no chord (section 5), so nothing in the grammar asks for two held buttons from one hand beyond the modifier.
- **Left-handed and rebinding:** nothing here adds a control; remapping covers it.

## 9. Risks, and questions

- **The trap needs a trigger Game Design picks** (section 5): a block's riposte window (recommended, no input change), a recent guard (one sim field) or an explicit chord (un-rules the stance exclusivity and needs a director branch). The Guard-then-Attack input is the same for the first two.
- **Mash vs hold on the medium and heavy.** The decision points (16 and 32 ticks) are already used for martial and have the touch cost measured (a modelled 3.66% of touch taps read as a medium at 12). The same read applies to the energy strengths unchanged.
- **Keyboard ghosting** is no longer a trap risk (no chord); it stays where it was for the modifier plus a face key plus a move key.
- **Grab is the odd one.** "Each fighter treats it a bit differently" (net, ring, ...) means the grab has no common tap/hold meaning: a fighter's grab may be one beat, a hold or a placement. The input only guarantees tap, hold and release; each fighter's data must say which it uses.
- **Questions for Game Design:** which strengths charge (I recommend medium and heavy, never the light); the stage count and lengths; whether Guard or a dodge cancels a charge; no auto-fire at full; which of the three trap triggers in section 5; whether the old signature and the heavy technique are the same thing; and whether the Power layer replaces `special_auto` on Simple.

## 10. What building it would take (later, after the ruling)

Small, and mostly data: the energy light, medium and heavy use the existing reads, so the input side needs (a) the Power layer taken as the energy layer on the two Simple layouts (a layout data change and a few `SimTouch` lines), (b) a per-stage cue and a `charge_stage` rumble kind (a data addition to `SimHaptics`), (c) a `charge_cancel` read if Guard cancels (a few lines in `SimPressRead` and tests), and (d) tests for each row of section 4 on each layout. The director's side (what each press makes, the trap, the stages, the cancel) is Encounter's and Combat's.
