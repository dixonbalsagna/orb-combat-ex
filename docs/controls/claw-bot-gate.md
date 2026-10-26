# The claw-bot gate, and the dodge's left-stick read (spec, paper)

Controls, 2026-10-25, for GD's `right-stick-pitches.md` section 13 (R28 to R38, the step-1 table 13.4). **Paper and a pure-input test plan; the build waits for Orb's pick.** The law itself is `right-thumb.md`; this is the test that fails the build if a claw, back paddles or a keyboard ever beats a standard thumb, plus a check of R34's direction read.

## 1. What the gate proves

For every stick command in 13.4, **a player who issues the stick input and the face button with zero transfer (a claw) can start the blow no earlier, and get no different result, than a player who needs the fast standard transfer.** It is a property test, not a feel test: the same scripted intents are driven through the real hub and `SimCore`, as the T1 test is, with two thumb models.

| Model | Stick to button | Stands for |
| :--- | :--- | :--- |
| **CLAW** | 0 ticks (both on the same tick, or the button first) | a claw, paddles, a keyboard |
| **FAST** | `L` = 6 ticks | the fastest standard thumb (p10) |
| **SLOW** | 13 ticks | a slow standard thumb (p90) |

`L` and `W` are read from the data (`rightThumb.lockout` 6, `rightThumb.window` 36), so the capture tool's measured values can replace them without touching the test.

## 2. The assertions (A to I)

| # | Assertion | For which rows |
| :--- | :--- | :--- |
| **A. Start-tick parity** | A face press made at gap `g` after the stick input starts its blow on tick `max(g, L)`. So CLAW (g = 0) and FAST (g = 6) start on the same tick, and SLOW (g = 13) on tick 13. **Never earlier than `L`.** | every Step, Rush and Aim row |
| **B. Result-invariance** | For every `g` in `0..W` the blow's kind, region, ki cost and damage are identical, and so is the stick's own effect (the step's distance, the aim line's angle). Only the start tick may differ, by A | every row |
| **C. Hold lockout** | A press made at any tick **during** a hold queues and starts at `release + L`, whenever in the hold it was made; a press made after the release at `r >= L` starts at `r`. A press made inside the first `L` after release starts at `release + L` | the dash, orbit, wall run, skim |
| **D. Latched state** | A shot fired at gap `g` from the aim line's latch (g in `0..W`) leaves at the same angle; the lay lands where the latched flick said; a latched aim survives the thumb leaving the stick and clears on RB's release exactly as ruled | RB flick and hold, LB+RB flick |
| **E. Read** | A read set with LB plus a flick persists to 90 ticks or its first fire; a rival attack that starts **after** the set fires it identically whatever the face-button timing; a read set while the attack is already running does not fire; one read at a time; 3 ki once | the LB flick rows |
| **F. Mirror parity: the same tick** | The D-pad form, the arrow-key form and the swipe form of each row have the same ki, the same commitment `L` and act on **exactly the stick form's tick** (the stick's flick settles 2 ticks after the crossing, so the D-pad's command waits the same 2). Neither form is ever faster or slower | every row |
| **G. Reverse commitment** | A stick input made at gap `g` after a **face press** acts on tick `max(g, L)` after the press. CLAW (g = 0) and FAST (g = 6) act on the same tick; SLOW (g = 13) at 13. The flick's effect is identical for every `g` in `0..W` | every Step, Rush and Aim row, after each of X, Y, B and A |
| **H. Newest wins, nothing silent** | At most one stick command waits. Press, flick, flick: only the second flick acts. Flick, press: the flick is dropped. Every dropped command emits a **lapsed ack** on the tick it is dropped; none is dropped without one | every stick row |
| **I. A waiting flick acts on the tick its wait ends** | A flick that waited on the reverse commitment acts on the tick the wait ends, with **no extra tick** (the same tick a queued press would start), so the result at every gap is rule 2's | every stick row |

**A queued press is not lost.** The request queue is 3 deep and a request lives 36 ticks. A press queued behind a **hold** can outlive the queue's 36 ticks (a hold may run longer); in that case it expires, which only ever costs the claw (it must press again), so the gate asserts that expiry never makes a claw faster.

## 3. The rows (from GD's 13.4), and what the gate does for each

| Family | Command | Kind | Gate cases |
| :--- | :--- | :--- | :--- |
| Nothing held | Flick toward from beyond reach: the lunge | Rush | A and B with each face button at `g` in `{0, 3, 5, 6, 7, 13, 36, 37}`; the same-tick press wins (ruling 1) |
| | Flick toward in reach: a step in | Step | A, B, F |
| | Flick away: a step back (giving ground) | Step | A, B, F |
| | Flick up or down: a hop or a drop | Step | A, B, F |
| | Hold toward or away: the dash | Hold | C, F |
| | Hold up or down: the orbit; the cross-up in a brawl | Hold, rush | C, F |
| | Hold into a face: the wall run; hold down near the ground: the skim | Hold | C, F |
| RB | Flick: latch the aim line | Aim | D, F |
| | Hold: sweep the line | Aim | D, C (release lockout), F |
| | Hold while his beam is out: sweep the beam | Aim | no lockout (rooted): assert none |
| LB+RB | Flick: where the next lay goes | Aim | D, F |
| LB | Flick: a read | Read | E, F |
| LT, RT | nothing in step 1 | | assert a right-stick input does nothing under LT or RT |

**Added by GD's rulings 13 to 16 (2026-10-26):** G, H and I apply to **every stick row** above, whatever its other cases, and F now means the same tick.

**Counts.** About 14 stick rows by 4 face buttons (X, Y, B, A) by 8 gaps is roughly 450 short runs for each of A and B, and the same again for G (the press first, the stick after), plus the hold, mirror and newest-wins cases (H and I, a few dozen sequences): about 1,000 runs of about 60 ticks, still a few seconds of headless sim.

## 4. The fight check (the whole thing, not one pair)

A seeded script drives a fixed list of commands, **alternating stick and face inputs as a claw would**, against a **scripted dummy** that throws blows at fixed ticks. Two timing models run the same list: the STANDARD run spaces each stick command and the next face press by the transfer (13 ticks); the CLAW run issues each next input at the earliest tick it can (0 transfer). The gate asserts that **over 600 ticks the CLAW run's damage dealt, ki spent, blows started and reads fired are no better than the FAST run's, on every seed (50 seeds)**, and that the two end in the same state when the CLAW run is slowed to FAST's spacing. This catches an interaction the single-pair cases miss (a step's lockout stacking with a read, a queued press behind a dash).

## 5. What the build needs first

1. **The commands must exist in the sim** (Encounter: the step, rush, hold and read behaviour, the lockout `L` and the post-hold lockout on the request queue; Simulation and Tools: intent v5, the `rightStick` and `rightThumb` data and their schema; `switches.rightStick`). The gate is an integration test over those, so it lands with them and is red until they are green.
2. **Data keys** `rightThumb.lockout` 6, `rightThumb.window` 36, the three thumb-model transfers.
3. **A scripted dummy** (Encounter or QA already have idle and scripted rivals; I reuse the T1 test's scene).
4. **Order of work:** the gate's harness and cases can be written and run against a *stub* director that implements only A and C (a queue with a lockout) before the real commands land, so the test is proven to fail a deliberately broken stub (a lockout of 0) and pass the correct one.

## 6. The dodge's left-stick read (R34): misreads against today's nudge

R34 reads the left stick at LT's dodge edge: neutral, away, toward, up or down. Modelled with synthetic thumbs (`docs/controls/dodge-dir-model.py`; **assumed, not measured people**), left stick dead zone 0.20, a lean counts at 0.60 or more after the dead zone, the vertical wins only when `|y| >= 1.5 |x|`:

| Case | Read at the edge tick only | Read over the edge plus 3 ticks | plus 4 | plus 5 | plus 6 | plus 8 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **A lean held steady, then the tap** (practised / casual) | 100% / 97% | same | | | | |
| **A flick made at the same moment as the tap** (practised) | 14% | 53% | 72% | 86% | **95%** | 100% |
| **The same, casual** | 24% | 51% | 63% | 73% | **81%** | 91% |
| **A plain dodge while flying** (no direction meant): how often a direction is read anyway | 39% | 39% | 39% | 39% | 39% | 39% |

What this says:

1. **A deliberate lean read at the edge is fine** (97 to 100%). But **a flick made at the same moment as the tap is read right only 14 to 24% of the time at the edge tick**, because the thumb has not arrived. A decision window after the edge fixes it: **6 ticks (100 ms) gives 95% practised and 81% casual**, 8 ticks 100% and 91%.
2. **The dodge must still start on the press tick** (T1). So: the dodge begins at once, and **the direction resolves over the next 6 ticks**, taking the thumb's largest deflection if it is still deflected at tick 6 and the last deflected sample otherwise. The slip's lateral part starts at tick 6; the first 6 ticks are the common start (the crouch). That matches the 6-tick `L` and the 4-tick slip frames, and the exchange's dodge window is 12 ticks, so the direction is known before any template needs it. Animation should draw the first 6 ticks as the same gather for every direction.
3. **Today's nudge is the hazard.** A player pressing in or giving ground already holds the left stick toward or away; in my assumed movement mix **39% of dodges made while flying would be read as directional**, though no direction was meant. For "toward" that is benign (a slip in past the blow, the dodge-and-counter template). **For "away" it is not: a dodge with the stick away already leaves a brawl today** (`melee-press-feel.md`: it breaks the brawl; a dodge costs 15 ki and 3 seconds when he is threatened), so R34's "away" is the existing exit and not a new slip. Encounter should confirm the intended pairing: either R34's "away" **is** the exit (consistent), or the brawl's exit stays a separate rule and R34's away only applies outside a brawl.
4. **Thresholds I recommend:** a lean counts at 0.60 after the dead zone; the vertical wins only when `|y| >= 1.5 |x|` (a diagonal reads horizontal, since vertical slips are the rarer, deliberate case); the decision window 6 ticks; the intended directional use of a held lean is kept (the cheap fix for the 39% is not to ignore held leans but to make every directional slip a **harmless variant of the same dodge** at the same cost, as R34 says: "the same dodge in every case").
5. **What would reduce the 39% if it bites:** require a **fresh deflection** (the stick moved at least 0.5 within the window) for the directional slip, so a steady movement lean reads neutral. The cost is that a deliberate "lean then tap" becomes neutral too. I would not do it unless the real captures show players surprised by directional slips.

## 7. For the other directors

- **Encounter:** the lockout and post-hold lockout on the request queue; the 6-tick direction window on the dodge edge (a field in the exchange, not a new intent bit: `mx` and `my` are already in every intent); confirm "away".
- **Animation:** the first 6 ticks of every dodge are one gather; the branch starts at tick 6.
- **Simulation and Tools:** intent v5, data and schema.
- **Controls (me):** the gate's harness, cases and the stub proof, once the switch is on; `dodge-dir-model.py` is the reference until QA's real captures.
