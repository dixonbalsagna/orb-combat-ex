# Pitch: the left hand survives, the right hand hurts (EP, 2026-10-28)

Orb's direction (2026-10-28, chat):
- The left stick stays movement. The right stick belongs to attacks.
- Slips and dodges move to the left stick: a left shoulder (LT, LB, or both) plus a flick.
- In martial mode, the right stick throws powerful directional strikes: hold toward a direction to charge, flick for a quick, stunning blow. This is a directional-charge strike, a platform-fighter convention, but only the convention, never a franchise's moves.
- The right stick may also deliver beams, which leaves blasts and other projectiles to the face buttons.
- Orb leans to the stick strikes being their own class, outside light, medium and heavy, but could be convinced to pool them with B (heavy).
- The ask: one consistent paradigm for how the face buttons and every needed attack are chosen with the four shoulder buttons.

This page is the EP's starting pitch for the overnight workshop. Controls leads the spec, Game Design rules the game side, and Research prototypes it so Orb can play the variants. Today's layout is `docs/controls/input-scheme.md` §2.1 (Arena), with `energy-input.md` and `right-thumb.md`.

## 1. The paradigm, one sentence per part

- **Left hand: survive and go.** The left stick moves; LB guards; LT evades. A left shoulder plus a left flick is a defensive move in that direction. No right-hand input is ever part of a defence.
- **Right hand: hurt.** The face buttons are the quick moves of the current mode (martial: light, medium, heavy, grab; energy: blasts by strength). The right stick is the big directional move of the current mode (martial: stick strikes; energy: beams).
- **The right shoulders choose the layer.** RB held = energy mode (as today, momentary). RT = power (tap burst, hold charge, and held with a press: the power layer of specials and the signature).
- **Chords are rare, deliberate and the same everywhere.** LT + RT held is transform (as today).

Why it answers the claw worry: the right thumb picks the stick or a button, never both at once. Nothing asks you to hold the stick while pressing a button. Every link between a stick move and a button move (or back) waits out right-thumb.md's lockouts (L = 6 ticks, R = 8), so a claw grip is never faster. A stick move is itself a commitment (a wind-up or a charge), so the lockout hides inside it.

## 2. Today's layout and what it changes (Arena)

| Control | Today | Pitch |
| :--- | :--- | :--- |
| Left stick | move | move; with a left shoulder, a flick is a directional defence |
| LT | dodge tap / sprint hold | **evade**: tap = dodge, or LT + left flick = a slip that way; hold = sprint |
| LB | guard hold / perfect block tap | **guard**: hold = guard, tap = perfect block; LB + left flick = a **brace** (the old "reads", moved to the left hand) |
| LB + LT + left flick | (none) | **vanish**: the genre's afterimage escape, a short blink in the flick's direction for ki; this replaces R3 Escape |
| RB | mode (momentary energy) | unchanged |
| RT | burst tap / power hold | unchanged |
| X, Y, B, A | light, medium, heavy, grab (energy: the blast family) | unchanged |
| Right stick | unused in play | **martial: stick strikes. Energy (RB held): beams** |
| RT held + face | specials 1-3, signature | unchanged |
| RT held + right stick | (none) | **signature-class moves aimed by the stick** (see 4c) |
| R3 | escape | freed: a target or lock-on swap, or nothing |
| LT + RT 0.5 s | transform | unchanged |
| D-pad | reserved | **the mirror**: every right-stick command at the same tick (right-thumb.md rule 4) |

## 3. The left hand: slips, braces and the vanish

| Input | Up | Down | Toward | Away |
| :--- | :--- | :--- | :--- | :--- |
| LT + flick (slip) | sway over a low blow | duck under a high blow | slip in past his fist, so a counter is ready | back-step off the line |
| LB + flick (brace) | brace high: his heavy is read | brace low: his flurry is read | brace wide: his grab breaks | turn side-on: his shot is sidestepped |
| LB + LT + flick (vanish) | blink up | blink down | blink through to his back | blink away (the escape) |

- LT alone is today's neutral dodge, and LB alone is today's guard. The flick only adds a direction, so a beginner who never flicks plays as today.
- A brace is Research's v2 "read", now on the left thumb. It costs the same 3 ki, lasts the same, and shows on the body the same way.
- The left thumb was already on the stick, so there is no claw question on the left hand at all.

## 4. The right stick, three pitches

**4a. Stick strikes as their own class (Orb's lean).** In martial mode a flick is a quick, stunning blow toward the flick: up a rising strike, down a spike or sweep, toward a body blow that stuns, away a turning blow that knocks him off. Hold the stick past about 8 ticks to charge, in 2 or 3 levels, and release to throw it. It has its own recovery and its own stun rules, outside light, medium and heavy.
- For: a fourth weight that a player chooses by direction, a strong identity, and room for each fighter's own four.
- Against: four more moves per stance for Combat's generator and Animation to author, and a new balance axis.

**4b. Pooled with heavy (B).** B is the neutral heavy, and the right stick is the directional heavy: the same family and the same recovery band, with the direction choosing the variant. Holding the stick is the heavy's hold, and a charged stick strike is a charged heavy.
- For: no new class. The generator's heavy slot simply gains directions, and the balance stays one axis.
- Against: the stick and B then do near-duplicate jobs, and the "powerful" read is shared rather than special.

**4c. Mode-symmetric, the EP's recommendation.** The stick is always "the big move of the current mode":
- martial: stick strikes as in 4a, but they draw on the heavy's budget, its recovery and its ki, so they aren't strictly better than B;
- energy (RB held): beams, aimed by the stick. Flick for a quick snap-beam, and hold to channel and charge (the beam struggle uses the existing mash and hold reads);
- RT held + stick: the signature, aimed by the stick. The signature then has one home, B is free in the power layer for a fourth special, and the beam lives where Orb wants it.

One sentence to learn: buttons are quick, the stick is big, the shoulders pick which. It's its own class on screen but costed like heavy, which is the middle of Orb's two options.

## 5. Other shoulder pitches considered

- **RB as a toggle, not a hold** (already a setting). It frees the right index finger, at the cost of a mode the player must remember.
- **RT held as "stick strikes become charge-only".** Rejected: it makes RT mean two unrelated things.
- **LB + RB = "both guards" (a full block).** Rejected: a cross-hand chord for a defence breaks "no right-hand input in a defence".
- **Flick the left stick with no shoulder for a step.** Rejected: it fights movement. Every left-flick defence needs a shoulder.
- **Brawler layout** (attacks on the shoulders): RB light and RT heavy stay. The right stick is the same as in Arena, and the power layer moves to Y held, as today.
- **Simple layout:** the right stick is one stick strike that the director picks from the direction (or off), and beams stay automatic.

## 6. What it costs and what it asks of the team

- **Controls:** the layout and the reads in sim/input; the claw bot gate (`claw-bot-gate.md`) on every stick-to-button link; keyboard parity (a strike key plus WASD for the direction, held to charge); and the D-pad mirror.
- **Game Design:** 4a, 4b or 4c; the stun on a flick strike; the charge levels; the beam on the stick versus the signature; and the vanish's cost.
- **Combat and Encounter:** stick strikes as a generator class (or heavy's directions), and beams as the energy stick's family.
- **Animation:** up to four directional strikes and a charge pose per fighter.
- **UI:** the legend and the how-to-play.
- **Research:** a playable prototype with all three pitches switchable, and clips.

## 7. Open questions for Orb, after the workshop

1. 4a, 4b or 4c.
2. Should the vanish replace R3 Escape?
3. Should the D-pad mirror be on by default, or a setting?
