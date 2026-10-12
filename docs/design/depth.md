# Depth in the brawl: how a fight travels the band

Owner: Game Design. Date: 2026-10-11. **Paper only.** Nothing here is built or run, and **every number is a first value.** Co-op is not designed here.

**Orb,** 2026-10-11: "In one of the prototypes for the depth axis I really liked how the brawl could get dragged gradually forwards and backwards relative to the camera. ideally, assuming a neighborhood with streets making up a perfect 4x4 grid the same depth as the Z axis, the fight could occur over any intersection." And, for the browser build: "at a minimum I want the updated Z axis to stand out as a new feature."

**What it builds on.** ADR 0009 (depth is real, and no depth control enters the control scheme). The plans for the band: `docs/architecture/fight-lanes.md`, `docs/world/fight-lanes-world.md`, `docs/director/fight-lanes-director.md`. The prototype Orb played: `research/band-proto/README.md`. The brawl's own rules: `brawl-second-pass.md`.

## 0. The rule in one paragraph

**Depth has no control of its own, on any layout.** The left stick already moves a brawl along the line between the two fighters. That line may now sit at an angle in depth. So pushing the rival back drags the fight toward his side in all three axes, and giving way brings it back. The angle comes from how the fight got there, and a dodge with no direction changes sides. Everything else that moves a fight in depth is the fight's own: an approach, a knock-back, a launch.

## 1. What drags a brawl in depth

| The cause | What it does | Whose it is |
| :--- | :--- | :--- |
| **A push or a pull:** the left stick toward or away from the rival | Moves the brawl's centre along the fighters' line, as now. When the line is angled, a share of that is depth: up to half | **The player's** |
| The left stick up or down | Altitude, as now. Never depth | The player's |
| **A sidestep:** a dodge with no direction | He steps 1 bh in depth, and the line turns to 20° with him on that side. The director picks the side with more room | The player's press. The side is the director's |
| How the attacker came in | Sets the line's angle as the brawl starts | Automatic |
| The carry | The brawl keeps half the closing speed for 20 ticks, in all three axes | Automatic |
| A knock-back: the shove, the blast, a charged heavy, a resting launcher, the double hit | He goes along the line, so partly in depth. It stops at a face | It follows the player's blow |
| Giving ground | A stick away backs him off along the line. Reach is read in three axes | The player's |
| A launch | The stick picks its family, as now. Its depth is the planner's (§5) | The planner's |
| A zip, a rush, a lunge | Each homes on the rival in all three axes, in its own time | Automatic: attacks close |
| The ease home | With no stick held, the brawl settles toward the middle of the street it is in (§3) | Automatic, and never against a held stick |

**The line.**
- It is the line between the two fighters on the ground plan. Its angle is measured from the street's own direction.
- **It never passes 30°,** so the two are always drawn side by side and neither hides the other.
- **In a street it is never under 10°.** A brawl that starts dead side-on is given 10° toward the side with more room. So every push shows a little depth.
- It starts at the angle the attacker came in at, held to those limits. A sidestep sets it. Nothing else turns it.
- **The share of a push that is depth** is the sine of the angle: 0.17 at 10°, and 0.5 at 30°.

**Why this keeps Orb's rules.**
- **One press is one attack.** Nothing here adds a press or changes what one does.
- **The player always feels in control.** His stick moves the pair exactly as it does now, and nothing in depth ever moves him against a stick he holds. "Toward him" means his side, in every axis. To drag the fight the other way he sidesteps, and then pushes.

**Why depth has no stick of its own.**
- Orb decided it, after playing the prototype with a depth nudge on it (ADR 0009).
- A phone and the Simple layout have no spare stick, and the rule should be one rule (§7).
- In a side-on view a player can't read depth finely enough to steer it. He can read "his side" and "my side".

## 2. Where a brawl may stand

| Where | The rule |
| :--- | :--- |
| **A street, a cross street, an intersection** | Anywhere on open ground. The centre keeps 1 bh clear of every face |
| **Over an intersection** | It is where a brawl changes street. The ease home pulls to the middle of the crossing, so a fight left alone there stays there |
| **A building's face, met in depth** | The part of the drift that runs into the face stops, and the rest carries on: the brawl slides along the street. Where the face ends, at a cross street, the drift goes on into it |
| **A building's face, met by the player's own push** | Up and over, as the stick slice has it. His own push climbs; a by-product of it slides |
| **Over the roofs** | Open. Above the roof line a brawl drifts over the block rows freely, and it can come down onto a roof and stand there |
| **Inside a block row at street level** | Only in a wreck, where a launch left the defender. The brawl is fought there and eases out to the nearest street, 1 bh in from the kerb. This answers Encounter's open ask |
| **Open country** | The whole band |
| **The band's edges** | The centre never passes them, and eases to 1 bh inside. Nobody enters the scenery rows |

- **A drifting brawl never damages a building,** in depth as along the street. Only a flight does: a launch, a throw, a rush that ploughs.
- **A face gives no bonus.** There is no pin and no wall hit in a brawl.
- **Orb's four-by-four grid** is a layout: a neighbourhood whose band holds four streets. These rules ask nothing of the count. Today's band holds two streets and two block rows, so the grid is World's to lay out.

## 3. How fast it drifts, and how it comes back

| What | First value | Key |
| :--- | :--- | :--- |
| The most a brawl's centre moves in depth, from every cause but a flight | **1.5 bh a second** | `depth.maxBhPerSec` |
| The ease home, toward the middle of the street or the crossing it is in | 0.5 bh a second, after 30 ticks with no stick held | `depth.homeBhPerSec`, `depth.homeWaitTicks` |
| The way out of a wreck | 1.5 bh a second, when he is next free | Encounter's rule |
| A sidestep | 1 bh, over the dodge's own ticks | `depth.sidestepBh`, `depth.sidestepDeg` 20 |
| The line's limits | 10° to 30° | `depth.lineMinDeg`, `depth.lineMaxDeg` |
| Clear of a face | 1 bh | `depth.faceMarginBh` |
| A free fighter easing toward his locked rival's depth, inside the mid band | 1 bh a second, where the way is open | `depth.magnetBhPerSec` |

- **Why 1.5.** Across the front street is 9 bh, so a push drags a fight from kerb to kerb in six seconds. That is gradual. At the camera's angle it changes a fighter's size by about 3% a second and shifts him a third of a body height a second on screen. Camera says whether it can follow that without a bob.
- **The see-through foreground** has to open and close over ticks and never at once. Its fade is Camera's and Rendering's number, and Legal's flash check reads it.
- **Flights are not held to it.** A launch, a throw and a zip cross depth at their own speed, and the camera has its own rules for them.

## 4. Never out of range

- **Every attack closes in all three axes.** A rush, a lunge and a zip home on where the rival is, and take no extra time for depth. **No attack ever misses because of depth** (a hard test).
- **The attacker moves.** A brawl is fought at the defender's depth, wherever he is.
- **Lock-on doesn't change.** It holds whatever the rival's depth. The close band, the mid band, a blow's reach and the closing rule are all read on the distance in three axes.
- **Free fighters come together gently.** Inside the mid band a free fighter eases toward his locked rival's depth, where the way is open. That is the prototype's soft magnet, and it is what makes a bolt read true.
- **Shots.** A shot is fired at where the rival is, in three axes, and a seeking shot homes in all three. Until shots carry depth, a shot hits by its place along the street and its height, as today.

## 5. Launches, beams and collateral

**What L4 plans.**
- **Every knock-back and launch leaves on the line's side.** Encounter's small deviation stands, at its sizes (0.3 to 1.0 bh for a shove, 0.3 to 1.2 for a vertical launch, 0.6 to 2.5 for a long one). Its sign is the line's, and not a draw.
- **The stick picks the family, and never the depth.** The planner picks among these by its scores: care, variety and the collateral budget.

| The send | When it is a candidate | What it costs |
| :--- | :--- | :--- |
| **Along the street** | Always | What stands on the path |
| **Down the cross street** | The brawl's centre is within 3 bh of a crossing. He is sent along the cross street and lands at the next crossing | Nothing: a cross street is clear all the way. A fighter who cares prefers it |
| **Into the row behind** | The building smash, as planned | The building, by the brunt rules |
| **Toward the camera** | Only from the back street or a cross street, ending in the front street. Never from the front street: the band has 5 bh left there, and nobody is thrown at the lens | What stands on the path |

- **Collateral is true.** A flight hits only the footprints it really crosses. The chain limits by tier stand: 2, 2, 3 and 4 buildings.
- **The protector goes over, and the feeder ploughs.** A fighter with care above 0 arcs his rush over a roof within 6 bh of its path, at no cost. This answers Encounter's other open ask.

**What waits for L5: beams in depth.**
- Until then a beam runs along the street at the firer's depth.
- **During its tell the firer eases to the target's depth,** at up to 6 bh a second, so that the beam is true when it fires.
- If the tell is too short for the gap, the beam still hits by its place along the street and its height, as today. That is a known falsehood, and L5 removes it.

## 6. The first playable slice

**D1, the drifting brawl.** It is L4 cut small, and it needs L3 and T applied first: no build has fighters at depth over ground that is one trench across the band.

| In D1 | Why |
| :--- | :--- |
| Every approach homes in three axes | Without it a fight at another depth can't start |
| The brawl's centre in three axes: the line, the push and pull, the carry, the 1.5 bh cap, the faces, the ease home | This is the drift Orb described |
| The sidestep in depth | It is the player's one way to change sides |
| **The cross-street send** | It is the one big mover. Without it the two rarely end up more than 2 bh apart in depth, and the feature wouldn't show |
| Encounter's small deviation on every flight | It is L4's base |

Not in D1: the free fighters' easing, the send toward the camera, beams in depth (L5), props (P1).

**To show it in the web build,** the demo should start within reach of a crossing, in a neighbourhood with at least two streets in the band. That is World's and the EP's.

**What it must not break in versus.** The switch-on re-baselines every band, as planned. These hold through it:

| Row | The bound |
| :--- | :--- |
| The X masher against medium, and the pair's win rate, with depth on against depth off on the same seeds | Within 3 points of each other |
| Giving ground's two hard rows; the closing rule's 0.6 bh a tick; no blow from beyond reach | As they are, read in three axes |
| No live tick of a brawl with a dead stick | As it is |
| Launches a match; the match's length; the first brink | Their bands |
| The collateral rows | Read again. True collisions change what a launch hits, so QA says which move |

**QA's new rows.**

| Row | Kind | The bound |
| :--- | :--- | :--- |
| An attack that misses because of depth | Hard | None |
| A brawl's centre, in depth, outside a flight | Hard | Never over 1.5 bh a second |
| The line's angle; the two fighters apart on screen in a brawl | Hard | Never over 30°; never under 0.5 bh |
| A brawl's centre inside a standing footprint at street level, or outside the band | Hard | Never |
| Depth moving the pair with a stick held, other than along the line | Hard | Never |
| A fighter hidden by a building with no see-through | Hard | No tick |
| Brawl time more than 2 bh from the front street's middle, in a city | Band | 20 to 50%. Under it, the feature doesn't show |
| City brawls that stand over a crossing at some point | Reported, then a band | First guess 15 to 40% |
| Cross-street sends a match, in a city | Reported, then a band | First guess 1 to 3 |

## 7. Phone and Simple

- **Depth needs no button and no stick on any layout,** so there is nothing to map. A pad, a keyboard, a phone and Simple all play the same rule.
- **The sidestep is the dodge** with no direction: A on the Simple pad, and the Dodge button or the ring on touch. It is already there.
- On a small screen the line's angle is hard to see. A mark on the ground under the pair, a shadow for each and a short stroke for the line, is asked of UI and VFX for every layout.

## 8. What it asks of the others, and what is open

| Who | What |
| :--- | :--- |
| **Encounter** | D1 as cut above, on its L4 plan. The planner's two new sends |
| **World** | L3 and T applied. A read for "the middle of the street or crossing at this point" and "the nearest face". A neighbourhood with four streets in the band, for Orb's grid |
| **Simulation** | The brawl's centre moved in depth each tick, by the mechanisms L2 has |
| **Camera and Rendering** | Following a drift of 1.5 bh a second; the see-through foreground's fade; the pair framed when the line is angled |
| **Animation** | The pair drawn at the line's angle, up to 30°. A sidestep in depth |
| **UI and VFX** | The mark on the ground |
| **Legal** | The see-through's fade, through the flash check |
| **QA** | The rows above |

**One point for the EP.** ADR 0009 says the player never steers depth. Here he still has no depth control, but his push moves the fight in depth along the line. If that sentence of the ADR needs amending, it is the EP's and Orb's to do.
