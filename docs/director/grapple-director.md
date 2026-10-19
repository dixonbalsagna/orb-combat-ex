# The grapple's director side: the catch, the clinch and the carry (sketch)

Owner: Encounter Systems Director. Date: 2026-10-16. **A sketch on paper: nothing is built.**

It carries Game Design's rules (`docs/design/grapple.md`, Orb's pick in homework 20: "hybrid between catch and clinch, rule in favor of clinch") into the director. Controls' reads are in `docs/controls/grapple-input.md`, and the press function is `SimPressRead.struggle_press`, built 2026-10-16. Every number is Game Design's first value, in data.

## 1. Where it sits

**The clinch is a mode of the brawl, not a new exchange.**
- The brawl already owns the pair, their lines, the run and the openings.
- A clinch freezes both lines, locks the two together, and swaps the brawl's blows for the clinch's pummels and vicious blows.
- When it ends, the brawl goes on, or hands over what the exit gives: an opening, a send, a parting.
- One module, `DirGrapple` (`sim/director/grapple.gd`), is called from the brawl's tick while either fighter is in a catch, a clinch or a carry. Its state is a dozen integers a fighter in the brawl's slots, so it is hashed and replays like the rest:
  - the mode: none, the catch's tell, the clinch, or the carry;
  - its start tick;
  - the grip (−2 to +2, the catcher's way);
  - the pulses claimed, and a voided flag;
  - the vicious blows, and the last place struck (s08 counts places, not regions);
  - the brace's start and its rest;
  - the shared grab lockout, and the no-regrab time.

**One pulse rule for every timed contest.** The beam struggle (`pending/beam-struggle/`) already scores presses on a 20-tick pulse with a 4-tick window, a sharp 2, one claim a pulse and a stray that voids the next. The clinch's pummel and the carry's break use the same rule. I would lift it out of `DirBeam` into a small `DirPulse` before the clinch is built, so the beam struggle, the clinch, the carry and later the fist clash and the grapple lock judge a press one way. It changes nothing in play, which a golden byte for byte proves.

## 2. The presses, through Controls' function

Each tick, for each player in a catch, a clinch or a carry, the director asks `SimPressRead.struggle_press(prev, intent, opts)`. `prev` is the last consumed intent's levels, kept in his slots.

| Its answer | In the clinch | In the carry | During the catch's tell |
| :--- | :--- | :--- | :--- |
| `"surge"`: X, Y or B (every layout, a Simple Attack by its rising level, a latched button by its level change, `special` 1 and 2 under RT) | A vicious blow on the region his stick leans to | Nothing (the carrier walks; the carried has only the break) | The catcher: nothing, one press one attack. The caught: a blow that lands in the tell stops the catch |
| `"letgo"`: A | A pummel on the pulse, or the push-off (with the stick away) | The carried fighter's break, on the pulse | The caught: the tech, within 8 ticks |

- **One catch for Simple.** On a Simple slot `struggle_press` also reads Guard (`guardPress`) as the let-go, which is right for the beam struggle. But Controls rules that **Guard is not A in a clinch** (A is LB on the Simple pad). So the clinch needs `opts` to say "A only", or it reads `context` itself for a Simple slot. I would ask Controls for the option, so the layout rules stay in their one tested function.
- **The catch or the carry** is decided at the catch's landing by `SimPressRead.charge_read`, with the context wind-up at 10. Still down 10 live ticks after the press plus 4 of grace is the carry; up by then is the catch. That is the same line Controls sets for the brace: `contextHeld` past 14 live ticks.
- **The brace** is A held past that line in the clinch, for 40 ticks at most, then 20 of rest.
  - With the latched charge, A toggles it, and every press still pummels.
  - With charges off there is no brace: Game Design to rule whether a charges-off slot gets a free brace while it presses nothing (Controls' suggestion).
- **The AI** never goes through `struggle_press`. Its pummels are drawn when the clinch starts (keyed), as in the beam struggle: 40, 65 and 85% of pulses by level, 3 or 4 ticks off the pulse, so never sharp.

## 3. The clinch, as the director runs it

- **The tie-up** starts the pulse clock: a pulse every 20 ticks, four at most, a cap of 90 ticks. The grip starts even, or one ahead for the catcher on a guarding, winding or charging rival, or for a perfect catch.
- **On each pulse,** each fighter's pummel inside 4 ticks claims it.
  - A pummel moves the grip one step his way; if both pummel, the sharper one (inside 2) takes the step, and equal sharpness moves nothing.
  - A stray (A off the pulse, or a second A in its window) moves nothing and voids his next pummel.
  - A pummel at two ahead is the throw.
- **Vicious blows:**
  - half a light's damage and three times its wear, on the region his stick leans to;
  - four a fighter a clinch, never more than two in a row to the same place (Legal s08, by its own wording, as Game Design re-ruled on 2026-10-17 and Combat's hybrid counts it, generator v21). A region has two or three places (head and jaw, chest and gut, legs and shins), so a stick held on one wound keeps working it, the blows alternating places;
  - half again as hard for a fighter one or two ahead, or at a pin (at most ×1.5 together);
  - each landed one counts one toward his run, as a light does.
- **Moving:** the fighter ahead walks the pair along his stick at half walking speed; the other keeps half his nudge. Walked into a building that holds, it is a pin.
- **In the air:** the clinch needs no ground.

## 4. The exits, and what each hands the brawl

| Exit | The director's part |
| :--- | :--- |
| **The throw** (two ahead, or the catch's quick throw on an open fighter) | **The send is the planner's, inside the thrower's stick:** down, up, or across (toward, away or none). It is a plain send, never a launch, so it never starts the launcher's rest. It is scored as every open send is (`cool-awareness.md`): a building's side, a wall, a ridge. |
| **The throw down** | The bury: an opening of 20 ticks. B is the launcher, or the hammer while it rests. This is the chain: clinch, throw, launch |
| **The throw up** | Open in the air for 16 ticks, 4 bh up: B there is a launch in the air |
| **The throw across** | 8 bh. Into a building that holds: the wall slam, a 24-tick stagger, an opening. Into open ground: the thrower's first move (45 ticks) and the chase |
| **The reversal** | The one two behind, with a sharp pummel on the same pulse as the leader's throw, throws instead, by his own stick |
| **A broken region** | The clinch ends, and the broken fighter staggers 24 ticks: an opening |
| **The push-off, the time, the tech, a burst** | Both part (3 bh for the push-off, with a 20-tick first move; 1.5 bh otherwise). The grab lockout starts for both |
| **An interjection** (one versus many) | A ring blow that lands on him in a clinch breaks it, and both part. The ring's rule holds: one partner, the ring's single blows |

**The lockout:** one grab lockout of 90 ticks, shared by every grab, from each attempt; a thrown fighter can't be grabbed for 120 ticks; a press in the lockout sends the refused cue and does nothing.

## 5. The carry

- A held A that lands drives the rival along the stick's line for 90 ticks at most.
- It ends when he lets go (the throw, by his stick), at the cap (the throw), or at the first surface on the line: a building's wall slam, or the ground, where both crater and the rival staggers 24 ticks.
- The carried fighter's A on the carry's pulse breaks it into the clinch, even. A stray voids his next try.
- Legal's g03: the carried body is in view every tick, and moves no more than 3 bh a tick.

## 6. The AI

- **Pummels** as in section 2.
- **Ahead:** vicious blows at the region its stick would choose.
- **Two behind:** it braces half the time at medium.
- **The tech:** its level's share (0.15, 0.3, 0.45), decided by a keyed draw when the tell begins, and pressed no sooner than its reaction time after the tell begins. Never at the catch's landing (Game Design's hard row).
- **The catch:** it catches guards, turtles and charges.
- **The throw:** its line by personality and care, through the planner: the hero away from people, the Anti-hero into a building.

## 7. The cues for the views

All `cue` events, by the cue list's rules (`pending/return/cues.md`): `n` an absolute tick, `k` a count, `text` the moment. To be added to that list when built.

| `kind` | `text` | Fields |
| :--- | :--- | :--- |
| `grapple_catch` | `tell` | `n` the landing tick |
| `grapple_clinch` | `start` | `k` the grip (−2 to +2, the actor's way) |
| `grapple_pulse` | none | `k` the pulse, `n` its tick, `amount` the grip |
| `grapple_pummel` | `step`, `sharp` or `void` | `k` the grip after it |
| `grapple_stray` | none | |
| `grapple_vicious` | the place struck | `k` his count |
| `grapple_brace` | `on` or `off` | |
| `grapple_carry` | `start`, `break` or `end` | |
| `grapple_end` | `throw_down`, `throw_up`, `throw_across`, `reversal`, `broken`, `push_off`, `time`, `tech`, `burst` or `interject` | |
| `grapple_refused` | `lockout` | `n` the tick the lockout ends |

UI draws the grip's five steps and the refused cue, Audio the creak on the pulse, Controls the pad pulse.

## 8. The order I would build it in

1. **`DirPulse`,** lifted out of the beam struggle. Byte for byte.
2. **The catch and the clinch:** the tell, the tie-up, the pummel, the stray, the grip, the time, the tech, the push-off, the lockout.
3. **Vicious blows, the brace, moving and the pin.**
4. **The carry.**
5. **The throws through the planner,** and the openings they hand over.
6. **The AI.**
7. **One versus many:** the interjection breaks a clinch.

Each step comes with Game Design's QA rows that apply to it (`grapple.md` §7): a stray never moves the grip; a masher of A wins no more grip than a fighter who doesn't press; the clinch's length; no regrab inside 120; the AI's tech never inside its reaction time; throws a match; a throw's opening followed by a launch in 15 to 40% of them.

## 9. What it needs from others

- **Controls:** the "A only" option on `struggle_press` for a Simple slot in a clinch.
- **Combat:** the throws by stick for each fighter, the vicious blows' pieces, and the catch's reach.
- **Animation:** the key sets (about 12 a fighter for the clinch, and the throws).
- **UI and Audio:** the views above.
- **Game Design:** the charges-off brace.
- **The data:** a `grapple` block in `data/director/interrupts.json`, by Game Design's §8, and its schema (Tools').
