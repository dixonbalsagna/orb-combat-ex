# The air brake in the core

Owner: Simulation and Engine. 2026-10-17. The core's build of Game Design's air brake (`docs/design/buildings.md` section 7.2, ruled 2026-10-17), with the `air_brake` event Animation asked for (`docs/animation/ragdoll-physics-paper.md` section 5). **Built and proved in scratch, parked at `pending/brake/`; nothing is in the tree.** Behind one data switch that is off: with it off, every match, replay and checkpoint is the same to the bit.

## 1. The rule as built

| Rule (Game Design's) | As built |
| :--- | :--- |
| **The control:** LT held while sent, the manoeuvre stance's hold; Guard held on Simple and touch | The core reads one bit: `SimIntent.stanceMask` 8, the manoeuvre stance's hold. Controls' layouts set it from Guard held on Simple and touch while he is sent (Controls owns the read). The AI's use is Encounter's (20, 50 and 80% of its chances by level) |
| **When he can start it:** 8 ticks after the send at power 0.55 or less, 20 at power 1, straight-line between | `SimBrake.window`. Until the launcher's power (`launch-anywhere.md` section 4) reaches the core, a send's power is its own speed over a full launch's (`fullSpeed`, at most 1), as Game Design rules for a send with no launcher's power |
| **Air sense:** 25% sooner for each mark of the send's kind | `BrakeState.marks`, set by the sender before the send; 0 until launch-anywhere's marks are built |
| **The rate:** fixed; at most 0.6 s of braking even from the hardest send | `rate = (1 − 1/3) × hardSpeed / maxBrakeS`: the hardest send falls to a third of its speed in 0.6 s. Every speed is the send's own, with the launch's traversal factor divided out (as `SimFighter.impact` reads it), and the brake keeps his direction |
| **Control back:** under a third of the send's speed | He is free in the air, with his own speed. With ground contact on, World ends his journey (`WorldContact.brakeEnd`: `journey_end`, kind brake) |
| **Its cost:** 20 ki a second held; with no ki, half the rate | As ruled. Ki never goes under 0 |
| **Never:** a finisher's send, a crippling blow's send, a hard impact, inside a building's chain | A special send (`launchSpecial`: a signature's, a finisher's or a break's) is a set piece and never brakes, until the director marks finishers and crippling blows alone. Nothing brakes inside a building chain (`chainEvt`), and the brake works only in the air, so a hard impact ends it |
| **A new send** while braking | Ends the brake (reason hit) and starts the new send's window |

**My first values, for Game Design** (`data/fight/brake.json`):
- **`fullSpeed`** is 5,000, the speed of a full launch, for the power fallback. AI matches on ff68e994 gave sends' own speeds a median of 2,570 and a 90th percentile of 5,380 at tier 1. So a median send has the 8-tick window, and a full one 20.
- **`hardSpeed`** is 7,000, the hardest send's own speed, which sets the rate (about 7,800 units a second per second). The largest send measured was 6,240, at tier 3 and below; tier 4's launch gain comes on top of that.
- **The set-piece rule is wider than Game Design's.** It covers every special send, signatures included, until Encounter can mark finishers and crippling blows alone.
- **Steering in the air** (the stick bending his path by up to 15°) is not in this build: no flight steering exists in the sim today.

## 2. The event

| Event | Fields | When |
| :--- | :--- | :--- |
| `air_brake` | actor, text, kind, amount, ux, uy | `text` start or end. `kind` is the reason: held at the start; at the end, speed (his control back), released, ground (the journey met the ground, water or a building) or hit (a new send). `amount` is his own speed, and `ux`, `uy` his flight's direction |

It is sent only while the brake is on, and it is hashed (`FX_FIELDS`). With the brake off no event is sent, so no digest moves.

## 3. In the core

| Where | What |
| :--- | :--- |
| `brake.gd` (new) | `SimBrake`: the data, the window, the tick, the event, control back |
| `state.gd` | `S.brakeOn`; `BrakeState` (the send's launch number, ticks since it, its speed, the window, set piece, braking, marks); `Fighter.brk` |
| `sim.gd` | The switch and each fighter's brake state in `newMatch` |
| `hash.gd` | `BrakeState` hashed only while the brake is on; the event's fields |
| `fighter.gd` | `SimBrake.tick` at the top of `stepFighter`, before the state's branch: a send is seen by its launch number moving (`WorldBrunt.arm` raises it at every send), on his first tick in the air before anything moves him |
| `replay.gd` | `data/fight/brake.json` in a replay's data hash, only with the brake on |
| `fx.gd`, `view/fx.gd` | The event |
| `tools/parity.gd` | "the air brake" |
| World's `contact.gd` | One function, `brakeEnd` (`pending/brake/grant_world.py`: World's to apply or grant) |

## 4. The proof

**The check, "the air brake".**
- Off: a match has no brake state, and a replay carries no brake data. With the brake on, its data joins the replay's data hash.
- The window by power: 8, 8, 14, 20 and 20 ticks for speeds of 0.3, 0.55, 0.775, 1 and 2 times `fullSpeed`, and 15 with one mark.
- A send of 2,400 force with the brake held:
  - it starts on its window's tick, and not before;
  - it slows every tick, and costs 20 ki a second;
  - it ends with reason speed, under a third of the send's speed, inside 0.6 s;
  - he is free on that tick, and World's `journey_end` says brake.
- With no ki it takes about twice as long. Letting go ends it, with reason released. A special send never brakes.
- A brake match of 2,400 ticks replays.

**Results:** in `pending/brake/README.md`.
