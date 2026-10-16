# The beam struggle's inputs: the surge, the stray and the let-go, on every layout (paper)

Controls, 2026-10-16, for `docs/design/rule-of-cool.md` section 2 (the beam struggle, redesigned) and its "one rule for the inputs". Nothing is built. **No intent bit, no version bump, no change to `sim/input` is needed for it**: everything below is read from the edges and levels the intent already carries. The director's reading (the pulse, the window, the stray) is Encounter's; this is what the input layer delivers and what it must not be asked to do.

## The rule being carried

Both fighters press on the same pulse (one every 20 ticks). **X, Y and B surge alike**: a press inside 4 ticks of the pulse moves the point 10% (inside 2 ticks, 15%). **A press off the pulse, or a second press in its window, moves nothing and voids his next surge** (a stray). **A held button doesn't overpower.** **A is the let-go**: on the pulse (inside 4 ticks) he slips aside; off it, he is caught and overwhelmed. Mashing feeds nothing.

## Where each press sits, by layout

| Layout | Surge (X, Y, B alike) | Let-go (A) |
| :--- | :--- | :--- |
| **Arena (pad)** | the press edges `light` (X), `heavy` (Y) and `sig` (B), each on the tick of its own press, with `waited` for a freeze | `context` (A, south) |
| **Keyboards** (solo, shared P1 and P2) | the same edges from J, K, L (solo), F, G, R (P1), H, M, U (P2) | `context` from I (solo), V (P1), comma (P2) |
| **Full touch** | the same edges from the Light, Heavy and Signature widgets, on touch-down | `context` from the Context widget |
| **Simple pad** | **Attack (X) and Y**: by the **rising level** `lightHeld` or `sigHeld`, not by their edges (below). B is Guard | **Guard (B, east): `guardPress`**; LB (Context, A's cell) also lets go |
| **Simple touch** | **Attack**, by the rising `lightHeld`; the Attack's swipe up is Y (see the trap) | **Guard, `guardPress`** (the swipe up on Guard is Escape, a different edge) |

**Why Simple surges by the rising level and not by the edge.** On Simple, Attack is one button for three weights, so its blow is an edge sent **on the release** (the hold was the wind-up). A surge timed to a pulse with that edge would be late by the tap's length (3 to 11 ticks), which is more than the window. The press itself is already in the intent: **the tick Attack goes down, `lightHeld` rises**, with no edge until the release. So for a Simple slot the director counts a press as a **level rising** on `lightHeld`, `heavyHeld` or `sigHeld`, and **ignores the release edge**. That edge always has its level OFF (the rule that tells an already-wound blow from a press), so "an edge with its level off is never a press" is also the rule that stops one tap counting twice (a press and its release) as a stray.

**How the director knows a slot is Simple:** the intent already says so. Simple layouts (pad and touch) send `mode = -1` (the director picks the energy family); every other layout sends 0 or 1. Nothing new is needed.

**Why Guard is the let-go on Simple.** Simple has no A in the Arena sense (its south button is Dodge, and touch has no Context button). Guard is a button with an immediate press edge (`guardPress`, on the tick, with `waited`), reachable on both pad and touch, and unused by a struggle (nobody guards in a locked beam). A Simple player is told "LET GO" on it. On the other layouts a Guard press is ignored in a struggle, so a Simple-only rule keyed on `mode == -1`. **A flick-to-dodge must not be the let-go on touch:** a nudge begun with a fast thumb is read as a flick (`phone-touch.md` section 4), so in a struggle it would catch the player letting go off the pulse. The stick's lean toward the rival is the nudge and carries nothing here.

## What the layouts must not do (and where they already don't)

- **A press is one edge on its tick.** Debounce (2 ticks) merges a worn contact's bounce into the same press, so hardware chatter is not a second press. A freeze keeps the edge with its true tick (`waited`), so a press on the pulse inside a hit-stop is graded where it was made.
- **A turbo pad gains nothing, by the rule and not by the layout.** A press every 6 ticks puts one inside every window, but also one just before it: that second press in the window is a stray, and the surge after it is void. The input layer adds no repeat of its own (the hold-to-flurry option is not built), and **no key repeat reaches the intent** (the layouts take press and release only).
- **The pairs:** two adjacent face buttons inside 3 ticks are a pair in normal play. In a struggle they are **two presses**, so the second is a stray. A struggle should not use `pair_read` at all (a pair is a power attack, not a surge), which is the director's choice.
- **Slow-button settings.** *Charges off* sends a press as an edge on its tick only, so it surges normally. *The latched charge* makes **every second press of Y, B or A a release with no edge**, so a player using it would lose every other surge. In a struggle the director should count **a level change (rise or fall) on a latched button as a press**; `hub.latch_charge_of(slot)` tells it which. (A is the same: a latched A's second press is no edge, so its let-go would be missed. The let-go on a latched A is a level fall.)
- **Touch window.** The window is 8 ticks and 10 on touch (`rule-of-cool.md`). The sim cannot see the device, and the interrupts data notes that the touch's two extra ticks "need the slot's layout in the sim". The existing route for this is a setup **assist flag per slot** (`SimAct.ASSISTS`: `autoBurst`, `specialAuto`, `perfectBlockAssist`, `autoCharge`): a new flag `touchTiming`, set from the touch presets' `slot` block in `layouts.json` (mine), would let the director use 10. Adding the name to `ASSISTS` is `sim/core/act.gd`, Simulation's gate. Until then touch players get the pad's window.

## Traps from the input side

1. **A swipe up on Simple touch is two presses.** The touch-down raises `lightHeld` and the swipe then sends Y's `signature` edge (level on): two presses in one window, a stray. UI should teach a plain tap in a struggle; a director that wants the swipe forgiven can ignore a `signature` edge arriving within the swipe window of a `lightHeld` rise on the same touch.
2. **A press that began before the struggle.** A Simple Attack still held when the struggle starts raises no new level and so is no press, which is right ("held doesn't overpower"). A held Y is the same.
3. **Level rises in a freeze.** An edge keeps its true tick through a hit freeze (`waited`); a level that rises inside a freeze is seen only on the first live tick. The struggle's pulses are 20 ticks apart and are not expected to sit in a freeze, but a Simple press made in one reads as made at its end.
4. **Reading the stance.** In the charging stance (RT held) the face buttons are the layer: X, Y and A become `special` 1, 2 and 3 and B stays `sig`. A player who is holding RT when the struggle starts would surge with specials. The director should read `special` 1, 2 and 3 as X, Y and A in a struggle (the cell table `pair_read` uses), or the layout can be asked to ignore the layer while a struggle runs; reading `special` is the smaller change.

## What I would build, if asked

Nothing is needed for the surge or the let-go on any layout. Small and optional, all pure or data: a `SimPressRead.struggle_press(prev_intent, intent)` that returns "surge", "letgo" or "none" for a slot by the rules above (so Encounter, QA's scripted players and the AI read one function and the Simple, latched and layer cases are tested once); the `touchTiming` assist flag in the touch presets; and UI's "LET GO" label on the Guard button in a struggle.

## For the other directors

- **Encounter:** read a Simple slot (`mode == -1`) by level rises, ignore level-off edges, take `guardPress` as the let-go for it; count `special` 1 to 3 as X, Y and A under RT; count a latched button's level change as a press; the window for touch needs the assist flag.
- **UI:** "LET GO" on the Guard button (Simple, pad and touch) and on A (the others) while a struggle runs; teach a tap, not a swipe, on touch.
- **QA:** a scripted turbo (a press every 6 ticks) must gain nothing over a fighter who doesn't press; a Simple tap must count once, not twice.
- **Simulation:** `touchTiming` in `ASSISTS`, if the touch window is wanted.
