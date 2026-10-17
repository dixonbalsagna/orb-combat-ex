# The grapple's inputs: the catch and the clinch, A on every layout (paper)

Controls, 2026-10-16, for Orb's pick (`docs/ep/vision.md`, "grappling on A": a hybrid of catch and clinch, the rule in favour of the clinch) and Game Design's rules (`docs/design/grapple.md`). Nothing is built. **No intent bit, no version change, and no change to `sim/input` is needed for the grapple on any layout except one choice for touch Simple (section 3).** Everything below is read from the edges and levels the intent already carries; the rules (the tell, the pulse, the grip, the stray) are Encounter's.

## The rule being carried

**Tap A: the catch** (a 10-tick tell, one press one attack). **A held: the catch and the carry.** If the catch lands, a held A keeps the grip and drives the rival along the stick; a tap that lands is the clinch (or the throw at once on an open fighter). **In the clinch the pulse comes every 20 ticks; A on the pulse (inside 4 ticks, sharp inside 2) pummels, moving the grip a step; X, Y or B throw a vicious blow on the region the stick leans to; A held is the brace** (he can't be thrown while he holds it, and he can't pummel or strike; at most 40 ticks, then 20 to rest). **A stray (A off the pulse, or a second A in its window) moves nothing and voids the next pummel.** A tap of A within 8 ticks of being caught techs it. Out of reach a held A is the tackle (unchanged); out of reach a tap is Context.

## Where each press sits, by layout

| Layout | A (tap, pummel, tech) | A held (carry, brace) | Vicious (X, Y, B) |
| :--- | :--- | :--- | :--- |
| **Arena** | `context` edge (south), on the tick of the press | `contextHeld` level | `light`, `heavy`, `sig` edges |
| **Keyboards** | `context` from I (solo), V (shared P1), comma (shared P2) | `contextHeld` | J, K, L; F, G, R; H, M, U |
| **Full touch** | the Context widget, an edge on touch-down | `contextHeld` while the finger is down | the Light, Heavy and Signature widgets |
| **Simple pad** | **LB (Context, A's cell)**, an edge on the press | `contextHeld` | Attack (a rising level) and Y (`sig` edge, level on) |
| **Simple touch** | **no A button today** (its fourth slot is Transform): see section 3 | see section 3 | Attack and the swipe's Y |

Under RT (the charging stance) the face buttons are the layer: A is `special` 3, X and Y are `special` 1 and 2, B stays `sig`; the reads treat them as the cells (as the struggle's `struggle_press` does).

## Reading each press (what the director does with the intent)

1. **The catch and the carry share one press, so the decision is at the catch's landing.** A is pressed (an edge, on its tick) and the tell runs 10 ticks. **Still down at the landing (10 live ticks after the press) plus a 4-tick grace: the carry. Let go by then: the catch (the clinch, or the throw).** That is exactly `SimPressRead.charge_read` with the context wind-up at 10: the director passes `params()` with `windupContext` 10 for an A pressed in reach (out of reach A keeps 12 and its coil at 16, which is the tackle's). The grace is for every device, so a touch tap (5 to 12 ticks) is a catch and never a carry. The live clock stops in a hit freeze and a release made in one is read at the point it was made (`windup-read.md` section 1), as for every slow button.
2. **A on the pulse (the pummel) is the same `context` edge,** graded at its true tick (`waited`) against the pulse. A **stray** is the director's to judge, as in the struggle. Because the window is 4 ticks, **a press must be sent on its tick, never on a release**: that holds on every layout above except touch Simple (section 3).
3. **The tech** (a tap within 8 ticks of the catch) is the same edge, graded against the catch's landing.
4. **The brace is A held: `contextHeld` still true past a decision point.** A press on the pulse is a pummel at its tick; if the player then keeps it down it becomes the brace. **I would set that line at the catch's, 14 live ticks (10 plus the 4 of grace)**, so the same number tells a tap from a hold for the catch, the carry and the brace and a touch tap (up to 12) never braces. The brace ends when the level falls; the 40-tick cap and the 20-tick rest are the director's.
5. **Vicious blows are the struggle's surge set:** `SimPressRead.struggle_press` already reads them correctly on every layout (a Simple Attack by its rising level, Y by its edge with the level on, a latched button by its level change), so it can serve as "a X, Y or B press" for the clinch with no change. A is the let-go in a struggle and the pummel in a clinch: the clinch's director asks for the same read and treats `"letgo"` as "A pressed" and `"surge"` as "a vicious press".
6. **The stick** is the nudge and the carry's direction and the vicious blow's region. The leader walks the pair along it; the other keeps half the nudge (`nudge_ramp`). A flick-to-dodge on touch is a dodge and nothing here; **a touch player who tries to carry with a fast push is read as a flick** (the misread of `phone-touch.md` section 4), which is a dodge-cancel: a reason for the stricter flick, or for the director to refuse a dodge-cancel from inside a carry or a clinch (it already breaks only by a burst).
7. **A pair in a clinch is two presses.** A+B (the seize), X+A (the slip) and the rest are power attacks in the open; in a clinch a director should not call `pair_read` (A and X together would be a pummel and a vicious blow, a pair of presses, not a power attack).

## What this does to the settings

- **Latched charge on A.** A is a slow button, so with the latch a press of A sets its level and the next press clears it. In a clinch that is **a toggled brace**: the first press is a pummel (an edge) and the brace is on; the next press is a pummel (a level fall, no edge) and the brace is off. Each press still pummels, and a player who cannot hold can brace by toggling. The director must count the level change as a press (`hub.latch_charge_of(slot)`), as `struggle_press` does with `latched`. **The carry cannot be started from a latch**: a latched A is "held" from the press, which would carry on every catch; the carry should need a hold the player really makes, so for a latched slot the catch always clinches and a carry is off. (A latched player still walks the pair as the leader.)
- **Charges off.** A reports held on its press tick only, so there is **no brace and no carry**: a charges-off player ties up, pummels and throws vicious blows. The missing brace is the cost, and a fighter two behind has no way to wait out a throw. I would give a charges-off slot a **free brace while it presses nothing** (the director's call), or accept it as the price; Game Design to rule.
- **The assist window.** The pulse's window is 8 ticks and 10 on touch; the sim cannot see the device, and the route is the `touchTiming` assist flag from the touch presets (Simulation adds the name to `SimAct.ASSISTS` when the touch window is wanted).

## Keyboards

- **Solo:** A is I (middle finger, above K), X J, Y K, B L. A pummel is a tap of I on the pulse and a vicious blow is a tap of J, K or L: all neighbouring fingers. A held I (the brace) with the stick keys W, A, S, D in the left hand and Shift or Space is four or five keys down, which can ghost on a cheap board (the same trap as the charge). **The latched charge is the answer for a keyboard that ghosts.**
- **Shared P1** (left hand: A is V, X is F, Y is G, B is R, one hand's reach) and **P2** (right hand: A is comma, X H, Y M, B U): a brace holds V or comma while the other fingers press vicious blows and the stick keys; the cramped cluster is the shared layouts' known weakness (the one-key pair actions are the relief, and they do not touch the clinch). The brace is where a shared player is at a disadvantage; the latched charge helps.
- **No default changes.** Nothing new needs a key.

## Simple and touch: the recommended mapping

**Simple pad.** A is **LB (Context)**, a shoulder button with an immediate edge, so every A read above works unchanged: tap LB to catch, LB on the pulse to pummel, LB held to carry or brace. Attack (X) and Y are the vicious blows, Guard (B) is **not** an A and does nothing in a clinch (so it can't be confused with the let-go in a beam struggle). The `A` is the one thing a Simple pad player has not had to learn before: it is taught as "LB: grab".

**Simple touch has no A button, so it needs a rule.** Three options, for Orb:
1. **A tap on the Transform button is Context** (a hold of 30 ticks stays Transform), the mapping already proposed for the mine (`phone-touch.md` section 3). The catch is a tap, so sending it on the release (5 to 12 ticks late) is fine: the catch has its own 10-tick tell. **But the pulse needs a press on its tick**, which a release edge cannot give, and a held Transform button is the Transform ring, not a brace. So with this mapping a touch Simple player **ties up** with the tap and then, in the clinch, **uses Guard as A: a Guard press on the pulse is the pummel and a held Guard is the brace** (the same stand-in as the beam struggle's let-go; Guard has an immediate `guardPress` edge and a held level, and nothing else uses it in a clinch). The carry is not offered on touch Simple (the leader walks the pair along the stick anyway). **This is my recommendation.**
2. **A fifth button, A, on the right.** The cleanest read, but the right side is already four buttons, and at 667 x 320 there is no room without shrinking them below the 48 dp floor.
3. **The director grapples for a Simple player** (no A at all): it ties up when a catch opens and pummels on the beat for them, as it picks the rest of Simple's spectacle (Orb's Q13). Accessible, and no grapple skill; the pulse becomes a shown beat the player cannot affect.

**Full touch** has the Context widget: every row above works, with the thumb on Context for the brace (one thumb cannot also steer; the latched charge is for that).

## Haptics for the clinch

The pulse is "a flex of the grip, a creak, a pad pulse" (`grapple.md` section 2). The same hardware rules as the struggle apply (`haptics.md`): a floor of 20 ms on a pad, a pulse that carries nothing alone, none on a keyboard or iOS Safari. I would **add `clinch_pulse` to the data** with the struggle beat's numbers softened (a low thud, strong 0.3, 20 ms) and a `clinch_grip` for a pummel that moves the grip (30 ms, strong 0.3, weak 0.4), for UI to raise from the grip's cues. Not built until UI names the signal.

## What I would build, if asked

- **`SimPressRead.catch_read(entry, live_now, p)`**: "tell", "tap" or "carry" for an A pressed in reach (a one-line wrapper of `charge_read` with `windupContext` 10 and the grace), and **`brace_read`** (A still down 14 live ticks after the press, on the live clock): both pure, with tests, so Encounter, QA and the AI read one function. Data: `read.catchTell` 10 and `read.braceStart` 14.
- **Retire `SimPressRead.a_read`'s shove and clinch-by-mash readings** (the second A inside the shove's wind-up, the vicious tap count), which the grapple replaces; the tackle's coil stays.
- **The Transform-tap as Context** on touch Simple, and the stricter flick, if Orb takes option 1.
- **`clinch_pulse` and `clinch_grip`** in the haptics data.

## For the other directors

- **Encounter:** the catch, carry, brace and tech from the reads above; the director passes `windupContext` 10 for an A pressed in reach; count a latched A's level change as a press; do not read pairs in a clinch; treat a latched slot's carry as off.
- **UI:** "GRAB" on LB (Simple pad) and the Context widget; on touch Simple, the Transform button labelled "TAP: GRAB / HOLD: TRANSFORM" and **Guard relabelled "PUMMEL / BRACE" during a clinch**; the pulse and the grip's five steps.
- **Game Design:** touch Simple's A (option 1, 2 or 3); the charges-off player's brace; the latched A's toggled brace.
- **Orb:** touch Simple's grapple (the three options above).
