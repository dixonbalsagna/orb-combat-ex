# Grappling on A: the hybrid of the catch and the clinch

Owner: Combat and Choreography. Date: 2026-10-16. Status: parked. Nothing is built in the sim or in `data/`. Paper, plus the clinch's vicious blows generated for every row (`pending/movegen`, `pending/roster`).

**Orb's pick** (homework 20, `docs/ep/vision.md`): a "hybrid between catch and clinch, rule in favor of clinch". Orb's note: "I see it as a way to set up combo chains and create varied combat scenarios".

So the clinch is the heart. The catch adds one thing: a grip that has been won can be carried somewhere. Everything below builds on `grapple-pitches.md` and on Game Design's A (`docs/design/brawl-second-pass.md` §4). Every number is a first value; the rules are Game Design's to rule (section 7).

## 1. The controls

| Press | Out of the clinch, in reach | Inside the clinch |
| :--- | :--- | :--- |
| **A tapped** | **The tie-up.** A 10-tick reach. It lands as a collar-and-elbow or waist hold (Legal g05), and the clinch starts with the grip even | **A on the beat is the pummel:** a step ahead for the grip. **A off the beat gives a step away.** Each press is one try |
| **A mashed** | (The tie-up's second press is already inside the clinch) | Mashing is pressing off the beat, so **mashing is how the grip is lost** |
| **A held** | Game Design's tackle, unchanged | **Ahead, the carry** (from the catch): he drives the pair along the stick for up to 1.5 s, and letting go throws him. **Even or behind, the brace:** he can't be thrown, carried or pinned, and his grip can't fall, but he does nothing else |
| **X, Y, B** | The brawl, as today | **Vicious close blows** on the region the stick leans to: up the head, toward (or no stick) the core, down the legs, away the arms. Four in a clinch at most, and never more than two in a row to one place (Legal s08). **X** is the quick one. **Y** wears hardest. **B is the break-off:** with the grip even or ahead, it ends the clinch and staggers him, an opening |
| **A at two ahead** | | **The throw,** on any press of A. The stick picks the send |

- **The grip** runs from two behind to two ahead. It's one meter seen from both sides: his step ahead is the other's step behind.
- **The beat** is the brawl's own, the one the perfect follow-up reads (§16). So a player who can time a follow-up can time a pummel.
- **Near a wall it is a pin.** When the pair's back is against a building's face, his vicious blows wear one and a half times as hard. A throw from the pin is the wall slam at once, with no flight in between.
- **The clinch lasts 90 ticks at most** (Game Design had 45). Then both are pushed 1.5 bh apart.

## 2. The exits, and what each hands the brawl

The point of the hybrid is what comes after it. Every exit but the escape hands the holder something the brawl already uses.

| Exit | How | What it hands the brawl |
| :--- | :--- | :--- |
| **The throw** | A at two ahead | A launch by the stick's quarter, through the planner. If the launcher is resting, a knock-back of 8 bh, which the chase can follow (the tenth round: his own send, a held X) |
| **The carry, let go** | Held A while ahead, then released | The throw, at the end of the carry |
| **The carry into a wall** | The carry meets a surface | **The wall slam** (twice the building's hit), and he is left staggered 24 ticks in its crater. **That is an opening, so B is the launcher,** or the hammer if the launcher is resting |
| **The pin's throw** | A at two ahead with his back to a wall | The wall slam at once, then the same opening |
| **The break-off** | B with the grip even or ahead | A stagger of 12 ticks, an opening, so the next B is the launcher. **The shortest chain the hybrid has: tie-up, pummel, break-off, launch** |
| **The reversal** | The held fighter, two behind, presses A on the beat | His throw, by his stick |
| **The time-out** | 90 ticks | Both pushed apart. Nobody gains |
| **The escape** | Section 3 | Both pushed apart, and the escaper has the first move |

**How it joins the perfect follow-up and the nine cells:**
- **A vicious blow on the beat is a perfect.** It is free, it is a link of the chain, and it steals the beat (Game Design's pitch for vicious blows, `pitch-third-blow.md`).
- **A clinch entered from a chain keeps the chain's count.**
- **A throw at two ahead after two perfects is the chain's ender.** The director shapes it as for a perfect B: into a building it is a wall slam, from a height a spike, into open sky an uppercut, and on the brink the biggest send there is.
- **One chain, start to finish:** a light, its perfect follow-up, the tie-up, two pummels on the beat, a vicious knee on the beat, then the throw. The player decides when it ends, and the director decides how it looks.
- **Inside the clinch the three buttons keep their strengths' roles:** X is quick, Y is the grind, and B is the hammer that breaks it off. The mashed and held readings of X, Y and B are not used in the clinch: each press is one vicious blow.

## 3. Orb's rules

- **One press is one attack.** Each press of A is one try for the grip, each press of X, Y or B one blow, and the throw one press.
- **Grabs can't be spammed:**
  - the one grab lockout, 90 ticks, shared with the tackle and the seize, counted from the clinch's end;
  - a thrown fighter can't be tied up again for 120 ticks;
  - four vicious blows a clinch;
  - 90 ticks at most.
- **The held fighter always has a way out:**
  1. **The tech:** his own tap of A within 8 ticks of the tie-up breaks it, and both are pushed 1.5 bh apart (Game Design's rule).
  2. **The grip goes both ways:** his pummels on the beat take it back.
  3. **The brace:** he can't be thrown while he holds A.
  4. **The reversal:** at two behind, A on the beat throws the holder.
  5. **Against the carry,** each press of A takes a fifth off what is left of it.
  6. **A burst** breaks any hold (Game Design).
  7. **He keeps half his nudge** of the pair throughout (§1).

## 4. Identity: the Protagonist playful and technical, the Anti-hero exact and punishing

| | The Protagonist | The Anti-hero |
| :--- | :--- | :--- |
| **The tie-up** | Collar and elbow, open-handed: he catches the rival's lead arm as a partner would | A collar tie with the forearm plate across the collarbone. He takes the waist when the rival is lower |
| **The pummel** | Hand-fighting: a wrist turned, an elbow lifted, a palm slid under the chin | Pressure: the plate ground down onto the collar, the head kept in tight |
| **His vicious blows** (generated, below) | Pointed, not cruel: palms and blade hands to the joints and the chin, a shoulder check, knees to the thigh | An elbow into the same bruise, a knee to the gut, a headbutt, the plate ground in |
| **The carry** | A turning walk: he swings the pair round and sends the rival away from people | A straight march: he drives the rival back into the nearest wall |
| **His throws** (the director's sends, `fighter-pipeline.md` §8) | Up, and away, with a turn | Down and back, into buildings and the ground |
| **The exit he favours** | The reversal and the throw: he wins the grip by timing | The pin and the break-off: he wins by wearing one region down |

- **What the moveset can and can't do.** It gives these looks and these favourites. How much better each fighter is at his favourite (a wider beat, a harder pin) is a number for Game Design, if it wants one at all.
- **The vicious blows** are generated for each row by a new cell, `martial.a.clinch`, under his identity and Legal's rows. A fighter's own blow is never lent. Each region of the stick has at least two, and the core, the no-stick region, three or more. In a hold one arm may be on the grip, so a hand blow is one hand.
- **Steering.** His row's quotas and a new per-cell ban (`cellNever`, generator version 20) steer the clinch only, and leave his open brawl as it was. The Protagonist bans a blow down onto the head, a swing to the head and a headbutt. The Anti-hero bans an open or bladed hand.

| The Protagonist | Region | The Anti-hero | Region |
| :--- | :--- | :--- | :--- |
| A palm under the chin (`palm_lift`) | head | A short elbow to the jaw | head |
| A blade-hand jab | head | A headbutt | head |
| A rising palm to the gut | core | An elbow dropped on the chest | core |
| A heaving palm to the chest | core | A knee lifted to the gut; a short knee to the gut | core |
| A blade hand hooked to the gut | core | A rising fist to the chest | core |
| A shoulder check | core | | |
| A knife chop to the arm; the heel of the hand chopped on the arm | arms | The forearm plate dropped on the arm; a fist chopped on the arm | arms |
| A knee hooked to the thigh; a short knee to the thigh | legs | A knee hooked to the thigh; a short knee to the thigh | legs |

- **No new key set.** Every one plays on a key set that exists: each fighter's ten are posed, apart from a re-aim of the short knee to the thigh and one hand-state swap. Five of each fighter's ten are his alone.
- **Floors.** Game Design's floors of a fighter's own are ruled for X, Y and B. In this new cell a tier-1 newcomer may start on common vicious blows, as he may borrow heavies, so the four sketches generate.

## 5. Pieces per fighter, and Animation's cost

The clinch is paired motion, as Animation laid it out (`docs/animation/brawl-second-pass-view.md` §3):
- Two sequences run on one timeline, the holder's and the held's.
- An anchor for each phase: the holder's hand or forearm to a socket of the held body.
- The grip is solved by the contact IK, not authored.
- The held body's position is the sim's.

My estimate a fighter, to confirm with Animation:

| Phase | The holder | The held | Reused |
| :--- | ---: | ---: | :--- |
| The reach and the tie-up | 2 | 1 (tied) | |
| The grip, behind, even and ahead | 3 | 0 | His own three poses serve both sides: one fighter's ahead is the other's behind |
| The pummel | 1 | 0 | |
| The brace | 1 | 0 | |
| The carry | 1 | 0 | The carried pose of the zip's tackle |
| The pin | 1 | 1 (his back to the wall) | |
| The throws, one for each send: up (a heave), down (a drive), across (a hip throw), turned (a turn throw) | 4 | 0 | The thrown body is the ragdoll the sim launches |
| The break-off, the vicious blows | 0 | 0 | The generated pieces above |
| The escape's push | 0 | 0 | The shove's two poses, if they are drawn |
| **A fighter** | **13** | **2** | |

- **The total is about 30 poses for the two fighters, an estimate.** Animation's earlier figure for the whole of A (the clinch, the trip, the throw, the shove and the tackle) was about 20. The hybrid adds the carry, the pin and four sends.
- **The code is the paired sequence and the held state.** For the sim the held state is `heldBy`, the phase, the grip, and the held body's offset each tick (Simulation and Encounter).
- **The pairs as data are in `pending/grapple/hybrid.json`:** each phase's ticks, anchors and poses, and each fighter's look. Animation asked my generator for a `pair` kind of part, to compose these from the existing vocabulary. It isn't built: that file is the input it would read.

## 6. Legal

- **The grab rows:**
  - the clinch takes the collar and the elbow, or the waist (g01, g05);
  - no hands locked or laced, and nothing glowing at the hands (g02);
  - the carry is drawn whole, at least 4 ticks and at most 3 bh a tick (g03, g04);
  - a throw is a launch through the planner, never a vanish (g03).
- **Vicious blows:** s08 for them, which the generator's places map follows.
- **The headbutt** is the Anti-hero's posed key set, already screened.
- **The held poses (tied, pinned, carried)** need Legal's screen before they are drawn, as Animation noted for the zip's carried poses.

## 7. For Game Design: the rules to rule

1. **The beat.** The brawl's own beat, read for the pummel exactly as for a perfect follow-up? The window's width? The AI's share of pummels on the beat, by level?
2. **The grip meter.** Five steps, from two behind to two ahead? Does every press off the beat cost a step? Do vicious blows leave the grip where it is? (Proposed: yes, except that one on the beat steals the next beat.)
3. **The escapes.**
   - The tech's 8 ticks.
   - The carry's fifth a press.
   - What the brace costs. Proposed: nothing but time; a fighter braced to the end reaches the time-out.
   - The escaper's first move.
4. **The shove.** The tie-up takes the tap of A. Does the shove become the clinch's push apart? And does the tie-up take the shove's job against a winding heavy, landing on it and smothering it?
5. **A held A out of the clinch.** Proposed: the tackle stays as ruled.
6. **The pin.** How close to a building's face? Vicious ×1.5, and the throw from a pin the wall slam at once?
7. **The break-off.** B with the grip even or ahead ends the clinch with a 12-tick stagger, an opening?
8. **The chain.** A vicious blow on the beat is a free perfect and a link; a throw at two ahead after two perfects is the chain's ender?
9. **The length.** 90 ticks at most, where §4 had 45?

## 8. Also ruled here: Animation's ranges and the retreats

- **The three heavies' range offsets: accepted as Animation measured them.** They are `pu.su_edge_step` 66, `pu.su_edge_unwind` 58 and `ru.su_heel` 72 (`docs/animation/pulled-frames.md`). They are the ranges the poses were drawn for. No table of Combat's reads a piece's range: the sim's contact offset is one number, 58. The closing rule's range is Encounter's, and Animation says it doesn't change. `ru.su_heel` at 72 is 14 beyond the contact offset, so it will usually close with the body stepping back. That suits a falling heel thrown from a long leg.
- **The kick's step back, up to 30 (`limbs.foot` 28 and 30): kept.** At close range a kick should give ground rather than pull a thigh through its limit.
- **The hand blow's step back, up to 20 (`limbs.hand.min_fwd` 14, `retreat_max` 20): kept on at Animation's values.**
  - It brings the Anti-hero's straight hands 1.6 short of the rival where they were 6.6, and the Protagonist's 1.9 where they were 2.6.
  - It moves the body only when the rival is inside the shoulder. A small shuffle back to make room for a jab reads as a fighter's habit, and an exact one suits the Anti-hero.
  - These keys exist only in Animation's parked sixth patch, which already carries 14 and 20. So nothing needs setting: the ruling is to leave `min_fwd` at 14.
