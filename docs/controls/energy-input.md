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
| **Trap (Guard + energy)** | LB held + M + a face button | Shift held + M + a face key | see section 5 | the strength's blast leaves a mine where it lands | one mine per press, capped (GD) | the charged form leaves a bigger one | as the strength |

## 5. By device: can it be pressed?

| Device | The modifier M | Guard + M + a face button | Verdict |
| :--- | :--- | :--- | :--- |
| **Arena pad** | RB (index) | LB + RB (both index) + a face button (thumb) | **Comfortable.** The left stick is the other thumb; three buttons, three digits, no re-grip |
| **Solo keyboard** | Q | Shift + Q (left hand) + J, K, L or I (right hand) | **Fine, at the edge of ghosting** on a cheap board (Shift + Q + J + a move key). The latch and "energy: toggle" settings are the relief |
| **Shared keyboard** | E (P1), O (P2) | Shift + E + F/G/R (P1); Semicolon + O + H/M/U (P2) | **Cramped**, as the shared layouts already are. Guard + energy is the weak point of two humans on one keyboard |
| **Simple pad** | none (the director's `autoMode`); RT held is the Power layer | Guard is B (east) | **Reachable only if the Power layer becomes the energy layer** (below). Guard + RT + X is two thumbs and an index: possible, tight |
| **Simple touch** | none (`autoMode`); Power is the layer | Guard + Power + Attack = three right-hand fingers | **Not reachable as a chord.** The trap must be one modifier or none: see below |
| **Full touch** (tablets) | the Mode button (tap latches, hold is momentary) | Guard (left stack) + Mode (right) + a diamond button | **Reachable on a tablet** (two thumbs and an index), tight on a phone |

**Simple layouts: the Power layer is the energy layer.** Simple has no mode control, and the director already chooses blasts at range and melee close. I propose that on Simple pad and Simple touch, **Power held means "energy" for the face buttons** (Attack tap, hold, swipe up map to light, medium, heavy; `special_auto` retires into those), and a Simple player who never touches Power gets the director's pick as today. That is one rule, and it keeps the layout at the four buttons the thumb already has.

**The trap on touch has no chord.** I recommend the second of Orb's two readings: **a Guard held while an energy attack is thrown leaves the trap as the blast lands** ("defensive blocks while hitting energy attacks would leave mines"). On touch the player holds Guard with one finger and attacks with the thumb, which is the guard-and-attack case the phone doc already flags as the hard one (`phone-feasibility.md` section 2), but it needs no third finger. A one-finger form is a **Context tap that appears only when a trap can be laid**, using the same availability event as the transform. Game Design to rule which.

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
- **One hand:** the Simple layouts reduce the grammar to Attack + Power on the right and a stick on the left; a one-handed pad player is served by the latch (no held modifier, no held charge). The guard chord is the one thing a single hand cannot do: it needs the "Guard held while an energy attack is thrown" rule (section 5) to be satisfied by a guard toggle, which the phone doc already proposes.
- **Left-handed and rebinding:** nothing here adds a control; remapping covers it.

## 9. Risks, and questions

- **Guard held + an attack press (Encounter).** I have not checked what the director does with a face press while Guard is held. For the trap to work it must keep the guard (stance DEFENSIVE) and throw the attack, not drop the guard. If it drops it today, that is a director change, not an input one.
- **Mash vs hold on the medium and heavy.** The decision points (16 and 32 ticks) are already used for martial and have the touch cost measured (a modelled 3.66% of touch taps read as a medium at 12). The same read applies to the energy strengths unchanged.
- **Keyboard ghosting** on Shift + modifier + a face key + a move key. The shared keyboard is worst. Not new, but the trap adds a fourth key.
- **Grab is the odd one.** "Each fighter treats it a bit differently" (net, ring, ...) means the grab has no common tap/hold meaning: a fighter's grab may be one beat, a hold or a placement. The input only guarantees tap, hold and release; each fighter's data must say which it uses.
- **Questions for Game Design:** which strengths charge (I recommend medium and heavy, never the light); the stage count and lengths; whether Guard or a dodge cancels a charge; no auto-fire at full; whether a trap is a chord or a consequence of throwing while guarding; whether the old signature and the heavy technique are the same thing; and whether the Power layer replaces `special_auto` on Simple.

## 10. What building it would take (later, after the ruling)

Small, and mostly data: the energy light, medium and heavy use the existing reads, so the input side needs (a) the Power layer taken as the energy layer on the two Simple layouts (a layout data change and a few `SimTouch` lines), (b) a per-stage cue and a `charge_stage` rumble kind (a data addition to `SimHaptics`), (c) a `charge_cancel` read if Guard cancels (a few lines in `SimPressRead` and tests), and (d) tests for each row of section 4 on each layout. The director's side (what each press makes, the trap, the stages, the cancel) is Encounter's and Combat's.
