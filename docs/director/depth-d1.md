# Depth, slice D1: the director's part, sized

Owner: Encounter Systems Director. Date: 2026-10-12, with section 9 added on 2026-10-13. **Sections 1 to 8 are the sizing. Section 9 is slice D1a as built in scratch and parked; nothing is applied.** It reads Game Design's `docs/design/depth.md` (as revised on 2026-10-12 for three streets), Simulation's `docs/architecture/pending/depth-core.md` and World's `docs/world/depth-streets.md` against my L4 plan, `docs/director/fight-lanes-director.md`. Main is 6d3a945d.

## 1. What main has today

| Layer | What is there | What D1 still needs |
| :--- | :--- | :--- |
| Sim core | `S.depthOn` (the setup's `depth`). A fighter's `z` and `zT`. A rush that homes in depth. In an exchange both fighters ease to the one `ex.z`. A flight's waypoint | Simulation's part (a): a depth velocity `vz` for a locked fighter, the cap and the contact rule where depth is integrated, the band read from World |
| World | Three streets of 5 bh, avenues every block. `WorldLanes.home`, `crossingNear`, `depthRoom`, `limits`, `clearLane`; `WorldStructures.nearestFace`, `blockedAt` | L3 (true collisions) and T applied |
| Director | **Nothing reads depth.** Nobody sets `ex.z`. Every distance is in x and y: `DirBands.dist` (20 calls in four files), and the brawl's own arithmetic in `_mid`, `_stepIn`, `_giveStep`, `_move` and `_walled` | Section 3 |

## 2. Where the rules change my L4 plan

| My L4 plan | The rules now | What follows |
| :--- | :--- | :--- |
| One depth for an exchange, the defender's | The pair's line sits 10° to 30° from the streets' direction | `ex.z` is the centre's depth. At 30° the two stand 0.39 bh apart in depth |
| `data/director/depth.json`, mine | `data/combat/depth.json`, Simulation's (the EP's ruling) | I read it. My keys go in it, listed for Simulation |
| The small deviation's side is a keyed draw that leans to the lane's middle | Its side is the line's | One draw fewer. The sizes stand, and a 5-bh street holds them |
| Nothing eases a fighter back | The centre eases to the middle of its street or crossing (`WorldLanes.home`), 0.5 bh a second after 30 ticks with no stick | One more cause in the sum |
| A face stops a drift | The core's contact rule stops the part that runs into a face and lets the rest slide. In a corner the pair goes up and over | **My stick slice's "up and over" narrows with depth on:** it is for a corner only. The slide is the core's |
| A dodge keeps `z` | A dodge with no direction is a sidestep of 1 bh, and sets the line to 20° | A new action in a brawl. Today that press is refused there |
| BUILDING SMASH is the only launch that leaves the lane | The send down the avenue; the send toward the camera (not in D1) | A new candidate in the planner |

## 3. The split with Simulation, and my answer to its question

**Yes, with two additions.**
- **Locked, in a brawl:** I set `vz` on both fighters where I set `vx` and `vy` (`carryOn`). The core damps, caps, moves and collides.
- **Free or charging:** I move his home `zT`: the ease home, the way out of a wreck. Nothing else.
- **A rush:** as today, it homes on the rival's depth.
- **Addition 1, the closing step and a blow's placement.** Inside a brawl a blow closes its gap as part of the blow, up to 0.53 bh in a tick, and I write `x` and `y` for it today. In three axes that step has a depth part, and it can't wait for the cap: at 1.2 bh a second a tick moves 1.5 units. It is an attack closing, as a rush is. So either I write `z` there as I write `x` and `y`, and call the core's contact rule after it, or the core gives me a "step to" call that does both. I would take the call.
- **Addition 2, the rush's end point.** The line needs the attacker to arrive a little to one side in depth (10° is 10 units over the 58 between them). The rush has an offset in x and none in depth. One number on the rush.
- **The sidestep and a shove** are faster than the cap too: 1 bh over a dodge's 15 ticks is 4 bh a second. Simulation has asked Game Design about the shove; the sidestep is the same question.

**What I keep, for the hash.** Not in my per-fighter integers: their count is hashed, so a new one moves every golden with depth off. In `DirS`, by Simulation's lines, hashed only with depth on:

| Number | What |
| :--- | :--- |
| `lineSin` | The sine of the line's angle, 0.17 to 0.5. Kept as a sine so the sim needs no inverse trig |
| `lineSide` | +1 or -1: which fighter is nearer the camera |
| `carryZ`, with the carry's ticks I have | The depth part of the speed the brawl began with |
| `homeWait` | Live ticks since a stick was held, for the ease home |
| `sideLeft`, `sideDir` | The sidestep's ticks left, and its way |

## 4. What I build in D1

Sizes: S is a day of this session's work, M two or three, L more.

| # | Piece | Where | Size |
| ---: | :--- | :--- | :--- |
| 1 | The depth file's reads (Simulation's file, my keys listed) | `sim/director/depth.gd` (new) | S |
| 2 | **Distance in three axes.** One function for the bands, a blow's reach, the closing rule and giving ground. With depth off it returns today's number by today's arithmetic | `bands.gd`, `brawl.gd`, `zip.gd`, `bury.gd`, `blast.gd` | M |
| 3 | An approach homes in three axes: `requestAttack` sets `ex.z`, and the rush's end point has its offset in depth | `exchange.gd`, `bands.gd` | S |
| 4 | **The line:** set as the brawl starts from the way the attacker came in, held to 10° and 30°, on the side with more room (`depthRoom`); set to 20° by a sidestep | `brawl.gd` | S |
| 5 | **One sum, one cap.** Every cause of depth adds into one number in the brawl's movement: the push and pull's share (the sine), the carry, the ease home, the way out of a wreck, the sidestep. It is held to 1.2 bh a second, and then it is the pair's `vz` | `brawl.gd` `_move`, `carryOn` | M |
| 6 | The corner: when the core has stopped both parts of a player's push, the pair goes up, as the stick slice has it. And the stick slice's floor holds in three axes | `brawl.gd` | S |
| 7 | **The sidestep:** the neutral dodge inside a brawl | `interrupt.gd`, `brawl.gd` | M |
| 8 | **The send down the avenue:** a candidate when `crossingNear` finds a crossing within 3 bh; he lands at the next street's crossing | `launch.gd`, on L3 and Simulation's flight | L |
| 9 | The small deviation on every flight (L4 §1), its side the line's, held inside `depthRoom` | `launch.gd`, `melee.gd` | S |
| 10 | Reads and cues: `DirBrawl.centre` gains `z`, `vz`, the line's sine and side; a `sidestep` cue; the feed lines of L4 §5 | `brawl.gd` | S |
| 11 | The probe and the proofs of section 6 | `sim/director/tools/` | M |

**The order.**
- **D1a, the drift:** pieces 1 to 6, 10 and 11, on Simulation's part (a). This is what Orb described.
- **D1b, the sidestep:** piece 7.
- **D1c, the send:** pieces 8 and 9, on L3.

## 5. What I need

| From | What |
| :--- | :--- |
| **Simulation** | Part (a) as planned, and the two additions of section 3. The `DirS` numbers of section 3 and their hash lines. The depth file's keys of mine listed in it |
| **World** | L3 and T applied. Its four reads are on main and are enough for D1a and D1b. For the send: the next crossing along an avenue, deeper or nearer, from a point; and that an avenue is clear along its whole depth |
| **Game Design** | Is the sidestep held to the cap (with the shove's question)? Does a give-ground step, which moves one fighter alone along the line, count under the cap? |
| **Camera** | Following the centre; the fight's size held in a far street. It reads piece 10 |
| **Animation** | The contact solve with the two at different depths; the sidestep's piece |
| **Controls** | Nothing new: the neutral dodge exists |
| **Tools** | The depth file's schema, with Simulation |
| **QA** | The rows of depth.md §6 |

## 6. What stays the same with depth off

- **Every match, and every golden, bit for bit.** Each new path is behind `S.depthOn`. No draw is taken from `S.rng`; the keyed draws have keys of their own. The three-axis distance returns today's value by today's arithmetic. My new state is in `DirS` and hashed only with depth on, so the count of my integers doesn't change.
- **With depth on,** depth.md's bounds: the X masher and the pair's win rate within 3 points of depth off on the same seeds; giving ground's two hard rows, the closing rule's 0.6 bh a tick and the 68-unit rule, each read in three axes; no live tick with a dead stick.

## 7. The scratch prototype

**What it is.** Thirty lines in the brawl's movement, on a scratch copy of main 6d3a945d, never parked (`depth/x1.cjs` in my scratch). With depth on, the brawl's centre gains a depth: the push's share by the line's sine, then the ease home, held to 1.2 bh a second and to World's `depthRoom`. The core has no depth velocity yet, so the prototype moves `ex.z`, which both fighters ease to; they trail the centre by up to 0.57 bh, which the real build doesn't have. The line's angle is a keyed draw between 10° and 30° for each brawl. No sidestep, no send, no deviation.

**What I see.** Eight matches each, the pair astride a crossing, a presser against the medium AI.

| | He pushes 2.5 s, pulls 2.5 s, in turn | He pushes all the time | No stick |
| :--- | ---: | ---: | ---: |
| A brawl's travel in depth: median, 90th percentile, most | 1.7, 3.0, 4.0 bh | 1.7, 9.0, 22.8 bh | 0.9, 1.9, 3.6 bh |
| Brawls that stood over a crossing | 38 of 70 | 30 of 70 | 29 of 72 |
| Brawls that ended in another street | 0 | 14 of 70 | 0 |
| Brawl time off the front street | 0.2% | 19.8% | 0.3% |
| Brawl time over 1 bh from its street's middle | 27% | 81% | 7% |
| The centre's fastest tick in depth | 1.2 bh a second | 1.2 | 1.2 |

- **The drift is there and it is gradual.** A push and a pull move a brawl 1.7 bh in depth, inside a street 4 bh deep. Left alone it sits within 1 bh of the middle 93% of the time, and the AI's own nudges still move it 0.9 bh.
- **A crossing is where it leaves.** A quarter of brawl time stands in an avenue's column. A player who keeps pushing there is carried down the avenue: 14 of 70 brawls ended in another street, the longest after 22.8 bh.
- **In a street a held push pins the fight at the kerb** (81% of the time off the middle). That is the slide working, and it is also where a player will feel the face.
- **Without a held push no brawl changes street.** Game Design's point stands: the send down the avenue is what will show the feature in a short session. The drift alone reads 0.2% off the front street against a band of 15 to 40%.
- **The cap held on every tick,** by construction, and every match ended in a KO.

## 8. Risks and open points

- **Reach at the edges.** A reach read in three axes turns a few hits into misses and back. The 68-unit row and the two giving-ground rows have to be proved again with the line at 30°.
- **The cap against the closing rule.** A blow may move its attacker 0.6 bh in a tick and the cap is 1.5 units a tick. They meet in section 3's first addition, and it has to be settled before D1a is built.
- **The send toward the camera, the free fighters' easing, beams in depth and props are not in D1.**
- **A depth lean, if Orb adds one,** is one more cause in piece 5's sum.

## 9. D1a as built in scratch (2026-10-13, on the nine cells' chain): the drift

**What it stands on.** A fresh export of main (710b6905) with the nine cells' chain built on it, then Simulation's parked part (a) (`docs/architecture/pending/depth-a/depth_a.py` and its checks), then my `d1a.cjs`. All three apply clean, in that order. Not applied anywhere. D1a is parked as its script, because it rewrites `brawl.gd`, `bands.gd` and `exchange.gd` on top of the chain: it is run again on whatever main holds when its window opens.

**The idea: the line's frame.** A brawl's rules are written in two axes, along the pair and up: reach, the closing rule, giving ground, the 68-unit rule. With a line at 10 to 30 degrees the pair stands in three. Section 4's piece 2 would have rewritten each rule's arithmetic. The build does one thing in its place.
- For the director's part of a tick the pair is put in the line's own frame: each fighter's x becomes his distance along the line from the pair's middle, and both take the middle's depth (`DirBrawl.lineEnter`, called by `DirExchange.tick` before the brawl's part).
- Every rule then runs as written, on true distances. Nothing in them changed.
- At the end of the director's part each fighter is put back on the line in the world, from where he stood, through `SimFighter.stepTo` (`lineLeave`). So a face stops him as it stops any step, and he is back on his line by the next tick.
- The pair's velocity is turned the same way: along the line (`vx` by the line's cosine), plus the drift in depth, written to `f.vz`.

**One sum, one cap** (`_moveZ`): the push and pull's share along the line (the pair's speed by the line's sine), the carry's depth part as it fades, and the ease home after `homeAfterTicks` with no stick, at `homeBhPerSec`. It is held to the core's cap, and then to World's `depthRoom`, so the pair's middle never goes where a body has no room.

**The line** (`_lineStart`): from the way the attacker came in, held between 10 and 30 degrees, on the side he came in on. Two who start at one depth take the smallest angle, with the attacker on the side that has more room. An approach ends a little to one side in depth (`Rush.offZ`, from `DirBrawl.arriveOff`), about 20 degrees, so he arrives on a line.

**Also in it.** `DirBands.dist` reads three axes when the two depths differ and a home depth is set (only depth on sets one; a flight into a building moves a fighter's depth with depth off too, and that read must stay today's). `DirBrawl.centre` gains `z`, `vz`, `lineSin` and `lineSide`. `ex.z` is the middle's depth. Every ground and face read in `brawl.gd` is made at the middle's depth while the frame is open.

**What changed from section 3's plan.**
- No new number in `DirS` was needed beyond Simulation's six, and of those the build uses `lineSin`, `lineSide`, `carryZ` and `homeWait`. `sideT` and `sideWay` wait for D1b.
- The closing step and a blow's placement need no call of their own: they move a fighter along the line in the frame, and `lineLeave` puts him in the world through `stepTo`.
- The give-ground step is not capped in depth as built: it moves him along the line, and the line's depth part goes with it. Game Design's question on it stands.

**My numbers for `data/combat/depth.json`,** for Simulation to add under `director`: `lineSinMin` 0.1736, `lineSinMax` 0.5, `arriveSin` 0.342, `homeAfterTicks` 30, `homeBhPerSec` 0.5.

**Limits.**
- Inside the frame a fighter's x is up to about 4 units from his true x (half the pair's separation by one less the line's cosine), so an event sent from inside it carries that x. A launch that starts inside the frame starts from it too.
- `DirMelee`, `DirBands` and `DirExchange` still read the plane's ground outside the brawl.
- The corner rule (up and over when both parts of a push are stopped) is the stick slice's, read at the middle's depth; it has not been seen to fire in a street.
- No sidestep, no send down an avenue, no small deviation on a flight: D1b and D1c.

**Proof and rows.**

**With depth off it is the chain, to the bit.** On the chain with part (a) and D1a applied and depth off: the golden regenerated is the chain's own golden, byte for byte (9 matches and 2 replays, about 173,500 ticks); Simulation's parity checks pass, with its two for depth; determinism passes. The validator reads the tree clean.

**With depth on** (a forced setup in my probe `depth2.gd`, scratch): a player who presses X every 8 ticks against the medium AI, from the crossing start, 8 matches each, about 75,000 live ticks of brawl a row.

| Row | No stick | Toward and away in turn | Toward, held | Bound |
| :--- | ---: | ---: | ---: | :--- |
| A brawl's travel in depth: median; 9 in 10; most | 0.84; 1.74; 2.23 bh | 1.56; 2.70; 3.73 bh | 2.04; 10.13; 17.38 bh | |
| Brawls that end in another street than they began | 1 of 55 | 2 of 56 | 12 of 57 | |
| Brawl time over 1 bh from its street's middle | 2.5% | 23% | 82% | |
| Brawl time in no street (the stretch of an avenue between two) | 0% | 1.3% | 22% | |
| Ticks the pair stood outside 10 to 30 degrees | 0 | 0 | 0 | None |
| The most a fighter stood off his line, as a sine | 0.00 | 0.06 | 0.10 | |
| The drift's most, bh a second | 1.2 | 1.2 | 1.2 | 1.2, the cap |
| Ticks the pair's middle stepped further in depth than the cap allows | 0.1% | 0.3% | 0.4% | See below |
| The furthest the two stood apart in a brawl | 168 units | 173 units | 164 units | The leash |

- **The drift holds its cap, and the line holds its angle,** on every tick of all three.
- **The middle steps past the cap on 3 ticks in 1,000,** by up to 5.7 bh a second for one tick. Every one is a blow's closing step or its placement (counted by what the mover was doing: a flurry blow or a light of the player's, closing 10 to 40 units along the line). The core's `stepTo` moves those with no cap by its own rule, as a rush closes. So it is as built, and a question only if the cap is meant for the eye and not for the drift.
- **Held toward the rival, the stick walks a brawl down an avenue.** 12 brawls of 57 end in another street, the furthest 17 bh from where it began, and a fifth of the brawl time is spent in the avenue between two streets. With the stick worked both ways it is 2 of 56, and with none 1 of 55. That is the rule of `docs/design/depth.md` section 2: at a crossing there is no face, and that is how a drifting brawl leaves a street. **For Game Design:** section 3 expected a change of street by drift to take two or three brawls, since the 13.5 bh takes 11 s at the cap. A pressed brawl against the medium AI often outlasts 11 s, so one brawl in five does it alone when the stick is held toward throughout.
- **No brawl went through a face.** The pair's middle was in a street or an avenue on every tick.
