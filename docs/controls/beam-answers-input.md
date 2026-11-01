# Beam answers on the pad: the fit check (Controls, 2026-11-01; paper only, nothing run)

For Game Design (`docs/design/beam-answers.md` does not exist yet, so this reads the packet `docs/controls/pad-packet.html`, Orb's order in `docs/ep/vision.md`, and the live data: `data/director/interrupts.json` `beamPlays`). Orb: beams come only from the right stick; the answers are a dodge, a powerful block, a fire-back, walking into it, swatting it away, anything else cool. The test for each: which hand, what it collides with, the no-claw law, the D-pad mirror, the swapped layout, and one hand playing alone.

## The window, in ticks (what an answer has to fit)

A signature front takes **36 to 60 ticks** (hand to arrival; `beamPlays.front.rows`), the shooter's hand lights **48 ticks** before. The dodge counts **18 ticks before the front arrives to 2 after** (`dodgeBefore` 18, `dodgeAfter` 2): 20 ticks, a third of a second. A human takes about **15 ticks** (250 ms) to react to something they see. So on a signature front a **reaction** can answer; but a snap (floor 6, ceiling 20), a level 1 (10 to 30) and a level 2 (14 to 40) front is shorter than the dodge window plus a reaction, so those are **reads off the charge**, not reactions, until the front's flight is 34 ticks or more. Press-to-result on my side: LT or LB press reaches the sim on the **press tick (0)**; a right-stick flick starts a request at **tick 1 to 3** (the crossing; quick read; the thumb's ramp decides), so a stick answer needs about 3 ticks of lead over a button one. Judge a stick answer on the **request's start tick (`rsStart`)**, not on the blow's contact (start + 9): the contact would make every swat a prediction a third of a second ahead.

## Which inputs are free

| Input | Today | As an answer |
| :--- | :--- | :--- |
| **RT + the right stick** | inert (pure 4a); the packet lists it as a candidate for the signature beam | free, but it is also where a power charge sits: an answer here would fire for anyone charging when a beam arrives |
| **LB, LT, RB + A** | A with a shoulder is "not set" (the grab and the taunt are A alone) | free. A is a face press, so the law holds: a flick before it waits L = 6, an A before a flick makes the flick wait R = 8; a stick answer then an A answer cannot both land inside a window |
| **L3** | unbound (the brace button was removed for the first press) | free, but a click under the left thumb while it steers is clumsy; only for a "stand and take it" |
| **R3** | unbound on purpose (a hard flick can click it) | keep unbound |
| **D-pad** | nothing (mirror off); the mirror turns it into the right stick | free when the mirror is off, and **not free on a swapped pad**, where the D-pad carries the face buttons' actions |
| **Trigger depth (half pull)** | not built | free (pitch 4) |
| **Back, Start** | hints, pause | no |

## The ideas, one by one

Hands: the **left hand** is the left stick + LB + LT; the **right hand** is the right stick + RB + RT + the faces. "Swapped" mirrors everything (sticks, shoulders, face and D-pad), so a left-hand answer lands on the right hand and the reverse; every answer below survives that because each is built from one stick and one shoulder, never a face button. No answer uses a face button and the stick together, so the no-claw law has nothing to gate.

| Idea | Input | Hand | Collides with | Mirror (D-pad) | One hand alone | Press to result |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Dodge** | LT tap, left stick for the side | left | nothing (LT + LB is the vanish, off) | n/a | left only: yes | 0 |
| **Fire back** | RB + right stick toward them (a flick: level 1 at once; a hold: charge, then release) | right (index + thumb) | LB + RB held is the lay and makes the stick inert, so **you cannot guard and fire back at once**: by design | D-pad toward, with RB: same tick | right only: yes | flick starts at 1 to 3, the beam leaves the same tick |
| **Powerful block** | a **fresh** LB press as the front arrives | left | **A held guard has no fresh press**: a player already guarding gets nothing, which is the point, but **a toggled guard** (the accessibility style) turns off on the press. The window should count a press edge that arrives while a toggled guard is already up, or the style cannot play it | n/a | left only: yes | 0; the window must be at least 6 ticks wide for a pad (100 ms), wider with an assist |
| **Walk into it** | hold LB, left stick toward them | left, both digits | nothing: guard and move already coexist | n/a | left only: **the best one-handed answer** | continuous |
| **Swat it away** | right stick **flick**, no layer, into the front, its direction picks the way it is knocked | right thumb | in the window a no-layer flick toward them is otherwise a strike on the shooter: the window must say which. The layer (none) separates it from fire back (RB) | D-pad: same tick, four fixed directions | right only: yes | 1 to 3; judge on `rsStart`; a window of 8 ticks before to 2 after |
| **Split it** | LB fresh press, then a right flick within the window | both | none in the law: LB is a shoulder, the flick is the stick; **two hands, one thumb each** | D-pad flick works | no (needs both) | LB at 0, flick at +1 to 3 after it |
| **Slip and close** | LT tap (the dodge) and **keep holding LT** with the stick to the flank | left | none: a hold is already a sprint after the dodge, so this is the dodge followed by what the hand already does. The kick (instant 80%) makes the close quick | n/a | left only: yes | 0 |
| **Eat it** | RT as the front arrives | right index | **RT held is the power charge**, so anyone charging when a beam arrives would eat it by accident. Make it a **fresh RT press** (`powerPress`) in the window, not a hold | n/a | right only | 0 |
| **Blast the front** | RB + right stick flick | right | **the same input as fire back** (RB + a flick toward them). Both cannot be on it. Keep fire back; let a blast be what a fire-back becomes when the fronts meet small (a snap cannot open a struggle) | same | right only | 1 to 3 |

## Can the window read the stick differently? Yes, and it does not need the layout to change

The intent already carries everything the director needs: `rsStart` (the tick), `rsRelease`, `rsLevel` (0 flick, 1 to 3 held), `rsDir`, `rsAim`, and the layer (`rsMask`: none, LB, RB, LT). A window-aware read is the director's alone. My suggestion, which keeps one rule per layer and so no ambiguity:

| In the answer window | No layer | RB | LB |
| :--- | :--- | :--- | :--- |
| **Flick** | **swat** (aimed by its direction) | **fire back**, level 1 at once | **split** (guard strike), after a fresh LB |
| **Hold** | a normal charged strike (nothing special) | **fire back charged**, released at the return: level 1 at 12 ticks, 2 at 30, 3 at 54 | a charged guard strike |

So "a flick is a swat and a hold is a fire-back" works **only with RB for the fire-back**: without RB a held stick is a charged strike. The reason to keep RB: it is the energy layer (it pays the ki, `answerKi` 40) and it is how every other beam is fired; dropping it for the window would make the same held stick mean two things on either side of the arrival. A charged fire-back is possible inside a signature window (levels 1 and 2 fit, level 3 at 54 ticks only if the charge started with the shooter's lit hand).

## More answers that fit

- **Cover** (zero input): the beam carves what it meets, so a tower between them eats it. The left stick and the dodge already put you behind one; it is World's and Encounter's, with no pad cost.
- **Dodge direction as a prize**: the dodge's direction (up or down past the line) picks where you end up, and a strike from above or below is the follow-up. Left hand only.
- **Stand and take it** (L3, optional): a click to plant instead of dodging, taking guard damage with a bonus for staying. Only if a "stand" needs a button; walking into it already is one.
- **Sub-window feel for every answer**: the pad cue `incoming_beam` (built, parked) already crescendos to arrival; a refused answer (not enough ki) should use the refusal knock, so it never fails silently.

## Packet corrections (made in `docs/controls/pad-packet.html`)

LB + X ("Check"), LB + Y ("Push") and LT + X ("Step strike") were tagged **IN BUILD**; the audit measured all three as the same blow as with nothing held, so they are now tagged **OFF** with the plan stated. Everything else in the packet matches the live layout: the dodge window (18 before, 2 after) and the signature row (36 to 60) match `beamPlays.front`; the table's LB flick, RB flick and hold, B rows, A row and the "also off" list match the audit and the first-press ruling. One caveat on the table's first row ("four directions, four results"): that needs Encounter's stick-directions park, which is not in a build until it lands.
