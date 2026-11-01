# Every button on the pad, for the first playable

Owner: Game Design. 2026-11-01. Rulings on Controls' audit (`docs/controls/controls-audit.md`), for Orb's order: "the underlying mechanics and features of the controller layout fully fleshed out". **The test for each button: press it in a fight, and you can feel it did something. A button that can't pass yet leaves the pad hints, and it behaves as something that works.** Unplayed, and first values.

## Build for the first press

In the order a player will hit them.

| Control | Today | The ruling | Smallest version | Owner |
| :--- | :--- | :--- | :--- | :--- |
| **Right stick's four directions** | Same damage and result | **Build.** This is the stick's whole point: "the stick puts him where you aimed" (`right-hand-attacks-rulings.md` §2) | Same worth, and a different result: up floats him, down drives him to the floor, toward drives him back, away turns him past. Combat's pieces go live for the look | Encounter, Combat |
| **A swallowed stick press** | 59% of requests in the mash soak do nothing, silently | **Build.** No press is silent (E3) | Controls' short refusal cue on the pad | Controls |
| **A** | Nothing with no context on offer | **Build.** It's one of four face buttons | In reach, the grab. Out of reach, the taunt (`melee-press-feel.md` §10). Land the parked first stage of the grapple. If it can't land in time, a plain throw stands in | Encounter, Combat |
| **RB + B: the Driver** | The signature beam, which is what Orb's note rules out | **Build.** Orb: beams belong to the right stick, and B is kinetic | Tap: a straight, heavy shot. Hold: three levels, with level 3 a full send (E124 to E126). Built from the shots we already have. **Leave for later:** recoil, the kits' level 2 forms and the meteor from range | Encounter, VFX |
| **RB + Y: the lob** | A blast | **Build.** Orb: Y is explosive lobs | Row 34's far lob and wider burst (E123, E142), already parked. In reach, the point-blank blast stays | Combat |
| **LB + LT: the vanish** | Only throws a dodge | **Build.** It's the showy one, and two shoulders together should be worth something | The blink with its directions, at its 20 ki (rulings §4) | Encounter |
| **LB and LT + X and Y** | The same blow as no stance, against a standing foe | **Build, after one read.** Controls didn't isolate a foe who reacts, so read that first. If they're still the same, the smallest felt difference is below | LB + X, the check: a quick blow with the guard staying up. LB + Y, the push: he's shoved back. LT + X, the step strike: you move through the blow. Combat's parked stance split gives the looks | Encounter, Combat |

## Leave off, with no pad hint

| Control | Why | What a press does until then |
| :--- | :--- | :--- |
| **RT + X, Y, A: specials** | They need each fighter's three specials, which is content and not a switch. **They aren't cut.** RT's charge and RT + B's signature work | The plain blow, and the charge drops. So it's never a dead press |
| **Brace** (LB + flick, or L3) | It's a subtle read, and first-time players won't miss it. Vanish is the left hand's better first upgrade. It's next | LB + flick is just the guard, which works. L3 does nothing and has no hint |
| **The beam's sweep** | It needs the carve to follow, which is row 31. **First in line after the first playable.** If Encounter says the aim alone is cheap, take that | The stick's aim is fixed as it fires, as it is now |
| **Transform chord** (LT + RT) | `data/fight/forms.json` is off, so there's nothing for it to do | Dodge and charge, with no hint. **See below** |
| **Pulses, snap or push, trigger depth, focus, the lean** | Pitches and workshops | Nothing changes |

## Cut from the layout

**R3, Escape: cut, on the right-hand layout, and leave it unbound.** The vanish replaced it by ruling, and a stick that's clicked in the middle of a flick shouldn't do anything anyway. The D-pad stays as it is: the mirror's off by default, with no hint.

## One thing it changes

**The meteor's "at least two transformations each" gate** (`game-design.md` §12) can't be met with forms off. So while they're off, the gate is both at tier 4, with the rest as ruled. It goes back when forms go on.

## Orb's calls

These don't hold up the build. Everything's on a switch.

1. **The Driver is my pick for B's hold, and Orb hasn't confirmed it.** Their clips are in the homework. I'm building it now because Orb's already ruled that B can't be a beam, and something has to go there.
2. **No transformations in the first press.** Forms are off, and Orb's order is the pad and the globe, so I've left them off. Orb may want them sooner: it's a big part of the game's promise, and turning them on brings its own balance read.
3. **Specials being off** means RT has less to do at first. Orb should simply be told, as it's not a question.
