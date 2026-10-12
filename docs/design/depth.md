# Depth in the brawl: how a fight travels the band

Owner: Game Design. Date: 2026-10-11, revised 2026-10-12 against World's three streets and Rendering's sizes on screen. **Paper only.** Nothing here is built or run, and **every number is a first value.** Co-op is not designed here.

**Orb,** 2026-10-11: "In one of the prototypes for the depth axis I really liked how the brawl could get dragged gradually forwards and backwards relative to the camera. ideally, assuming a neighborhood with streets making up a perfect 4x4 grid the same depth as the Z axis, the fight could occur over any intersection." And, for the browser build: "at a minimum I want the updated Z axis to stand out as a new feature."

**What it builds on.** ADR 0009 (depth is real, and no depth control enters the control scheme). The plans for the band: `docs/architecture/fight-lanes.md`, `docs/director/fight-lanes-director.md`. The streets as they now stand, and World's reads: `docs/world/depth-streets.md`. What a fighter in depth looks like: `docs/rendering/fighters-in-depth.md`. The prototype Orb played: `research/band-proto/README.md`. The brawl's own rules: `brawl-second-pass.md`.

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
| The ease home | With no stick held, the brawl settles toward the middle of the street or the crossing it is in (§3) | Automatic, and never against a held stick |

**The line.**
- It is the line between the two fighters on the ground plan. Its angle is measured from the direction of the along-streets, which is the camera's plane, wherever the pair stands.
- **It never passes 30°,** so the two are always drawn side by side. At 30° they keep 87% of the gap between them on screen.
- **It is never under 10°.** A brawl that starts dead side-on is given 10° toward the side with more room. So every push has a little depth in it, and a push at a face always has somewhere to slide (§2).
- It starts at the angle the attacker came in at, held to those limits. A sidestep sets it. Nothing else turns it.
- **The share of a push that is depth** is the sine of the angle: 0.17 at 10°, and 0.5 at 30°.
- **The angle doesn't read on the bodies** (Rendering). A line turned 20° is a slope of 3° on screen, 6 pixels between their feet. So the limits aren't there for the look. They set how much of a push is depth, and they keep the pair's gap on screen. Rendering's mark on the ground under the pair, broader under the nearer fighter, is what shows which way a push will drag.

**Why this keeps Orb's rules.**
- **One press is one attack.** Nothing here adds a press or changes what one does.
- **The player always feels in control.** His stick moves the pair exactly as it does now, and nothing in depth ever moves him against a stick he holds. "Toward him" means his side, in every axis. To drag the fight the other way he sidesteps, and then pushes.

**Why depth has no stick of its own.**
- Orb decided it, after playing the prototype with a depth nudge on it (ADR 0009). The EP has put the question to Orb again, and §8 says how a lean would fit.
- A phone and the Simple layout have no spare stick, and the rule should be one rule (§7).
- In a side-on view a player can't read depth finely enough to steer it. He can read "his side" and "my side".

## 2. Where a brawl may stand

World's streets (option P, on main): three along-streets of 5 bh each, at depths 2.5 to -2.5, -11 to -16 and -24.5 to -29.5, in the same band of 32 bh. Two block rows of 8.5 bh lie between them. An avenue of 5 to 6 bh crosses the whole band between every two blocks, and each crossing is clear air to the sky.

| Where | The rule | World's read |
| :--- | :--- | :--- |
| **A street** | Anywhere along it. The centre keeps 0.5 bh clear of the kerb line, so a brawl has **4 bh of depth** in a street | `depthRoom` gives the lane |
| **A crossing, and an avenue** | The whole band is open in depth, from the front street to the back one. Along the street the centre keeps 0.5 bh clear of the block ends | `depthRoom` gives the band |
| **Over the roofs** | Open. Above the roof line a brawl drifts over the block rows freely, and it can come down onto a roof and stand there | `depthRoom` gives the band |
| **Inside a block row at street level** | Only in a wreck, where a launch left the defender. The brawl is fought there and eases out to the nearest street. This answers Encounter's open ask | `home`, kind 2 |
| **Open country** | The whole band | |
| **The band's edges** | The centre never passes them. Nobody enters the scenery rows | |

**A face stops the part of the pair's motion that runs into it, and the rest slides on,** whichever way the face was met (`nearestFace`).
- **In a street** that keeps a brawl between the kerbs: the depth part of a push stops, and the push goes on along the street.
- **At a crossing there is no face,** so the depth part of a push carries on past the kerb line and into the avenue. **That is how a drifting brawl leaves a street.** About a third of a street's length is crossing.
- **In an avenue** a push runs into the block's end. The part along the street stops, and the depth part slides the pair down the avenue. So an avenue is a corridor, and a push in one drags the fight toward the next street.
- **Where nothing is left to slide,** in a corner, the pair goes up and over, as the stick slice has it. Otherwise going over a block is the player's own act: the stick held up.
- This refines the stick slice for a match with depth on. A tower is 20 to 40 bh tall, and a push shouldn't climb one by itself.

- **A drifting brawl never damages a building,** in depth as along the street. Only a flight does: a launch, a throw, a rush that ploughs.
- **A face gives no bonus.** There is no pin and no wall hit in a brawl.
- **Orb's four-by-four grid.** Three streets are in, which gives 15 crossings round downtown. The literal four streets need a deeper band, and World has costed that as option Q. It is a layout and not a rule: nothing here changes for it but the numbers in §3. It waits for Orb, after he has seen three streets with depth on.

## 3. How fast it drifts, and how it comes back

| What | First value | Key |
| :--- | :--- | :--- |
| The most a brawl's centre moves in depth, from every cause but a flight or a knock-back | **1.2 bh a second** | `depth.maxBhPerSec` |
| The ease home, toward the middle of the street or the crossing it is in | 0.5 bh a second, after 30 ticks with no stick held | `depth.homeBhPerSec`, `depth.homeWaitTicks` |
| The way out of a wreck | 1.2 bh a second, when he is next free | Encounter's rule |
| A sidestep | 1 bh, over the dodge's own ticks | `depth.sidestepBh`, `depth.sidestepDeg` 20 |
| The line's limits | 10° to 30° | `depth.lineMinDeg`, `depth.lineMaxDeg` |
| Clear of a face | 0.5 bh | `depth.faceMarginBh` |
| A free fighter easing toward his locked rival's depth, inside the mid band | 1 bh a second, where the way is open | `depth.magnetBhPerSec` |

- **Why 1.2, and not the 1.5 I had.** It is the most one push gives: a nudge is about 2.4 bh a second along the line, by my reading of Encounter's figures, and half of it is depth at 30°. Two sticks that agree don't double it. An ordinary push at 20° drags at 0.8 bh a second.
- **In a street** there are 4 bh of room. The fastest drag goes kerb to kerb in 3.3 s, and an ordinary one in 5 s. Left alone, a brawl is back in the middle of the street in about 4 s.
- **In an avenue** the room is the whole band, 32 bh. From the middle of one street to the next is 13.5 bh: 11 s at the cap, which is longer than most brawls. So a fight changes street by drift over two or three brawls, or at once by the send down the avenue (§5). A brawl left alone between two streets eases to the nearer one.
- **Flights are not held to it, and neither is a knock-back.** A launch, a throw and a zip cross depth at their own speed, and the camera has its own rules for them. A knock-back is one motion along the line, and its depth part goes with the rest of it: the shove, the blast, a charged heavy, a resting launcher, the double hit. Capped, a shove's depth part would trail behind the shove for most of a second (Simulation's question).

**What it does on screen, and what I need from Camera** (Rendering's measures at a close brawl).
- A drift at the old cap changed a fighter's size by about 10% a second. I had said 3%, and I was wrong. At 1.2 bh a second it is about 8%.
- Across the front street he goes from 119% of his size to 86%. Rendering finds that comfortable, and it reads as depth.
- In the middle street he is 54% of his size, and in the back street 37%. That is too small to fight at.

| What I need | First value |
| :--- | :--- |
| **A fight in any street is drawn at fight size.** In a brawl a fighter is never under 85% of the size he has on the plane | 85%, which is the front street's own range |
| How it is done is Camera's: it closes on the pair's depth, or it zooms | |
| **The follow is eased, so a drift still reads.** The street slides under the pair, and his size changes by no more than about 5% a second | 5% a second |
| **At a crossing and in an avenue the pair is kept near the middle of the frame,** so the view down the avenue is clear and nothing has to be opened | |
| Behind a tower, Orb's pick: open floors | Rendering is building it |

## 4. Never out of range

- **Every attack closes in all three axes.** A rush, a lunge and a zip home on where the rival is, and take no extra time for depth. **No attack ever misses because of depth** (a hard test).
- **The attacker moves.** A brawl is fought at the defender's depth, wherever he is.
- **Lock-on doesn't change.** It holds whatever the rival's depth. The close band, the mid band, a blow's reach and the closing rule are all read on the distance in three axes.
- **Free fighters come together gently.** Inside the mid band a free fighter eases toward his locked rival's depth, where the way is open. That is the prototype's soft magnet, and it is what makes a bolt read true.
- **Shots.** A shot is fired at where the rival is, in three axes, and a seeking shot homes in all three. Until shots carry depth, a shot hits by its place along the street and its height, as today.

## 5. Launches, beams and collateral

**What L4 plans.**
- **Every knock-back and launch leaves on the line's side.** Encounter's small deviation stands, at its sizes (0.3 to 1.0 bh for a shove, 0.3 to 1.2 for a vertical launch, 0.6 to 2.5 for a long one). Its sign is the line's, and not a draw. In a street 5 bh wide it stays inside the lane, as Encounter has it.
- **The stick picks the family, and never the depth.** The planner picks among these by its scores: care, variety and the collateral budget.

| The send | When it is a candidate | What it costs |
| :--- | :--- | :--- |
| **Along the street** | Always | What stands on the path |
| **Down the avenue** | The brawl's centre is within 3 bh of a crossing (`crossingNear`). He is sent along the avenue to the next street, deeper or nearer, and lands at that crossing | Nothing: an avenue is clear all the way. A fighter who cares prefers it |
| **Into the row behind** | The building smash, as planned | The building, by the brunt rules |
| **Toward the camera** | Only from the middle street, the back street or an avenue, and ending in a street nearer the camera. Never from the front street: it is the band's front edge, and nobody is thrown at the lens | What stands on the path |

- **Collateral is true.** A flight hits only the footprints it really crosses. The chain limits by tier stand: 2, 2, 3 and 4 buildings.
- **The protector goes over, and the feeder ploughs.** A fighter with care above 0 arcs his rush over a roof within 6 bh of its path, at no cost. This answers Encounter's other open ask.

**What waits for L5: beams in depth.**
- Until then a beam runs along the street at the firer's depth. Rendering now draws it there.
- **During its tell the firer eases to the target's depth,** at up to 6 bh a second, so that the beam is true when it fires.
- If the tell is too short for the gap, the beam still hits by its place along the street and its height, as today. That is a known falsehood, and L5 removes it.

## 6. The first playable slice

**D1, the drifting brawl.** It is L4 cut small, and it needs L3 and T applied first: no build has fighters at depth over ground that is one trench across the band.

| In D1 | Why |
| :--- | :--- |
| Every approach homes in three axes | Without it a fight at another depth can't start |
| The brawl's centre in three axes: the line, the push and pull, the carry, the cap, the faces, the ease home | This is the drift Orb described |
| The sidestep in depth | It is the player's one way to change sides |
| **The send down the avenue** | It is the one big mover. A drift alone takes two or three brawls to change street, so without the send the feature wouldn't show in a short session |
| Encounter's small deviation on every flight | It is L4's base |
| **One sum, one cap.** Every cause of depth in §1 goes through one place that adds them, holds them to the cap and the faces, and applies the ease | So that a cause can be added later without touching the rest (§8) |

Not in D1: the free fighters' easing, the send toward the camera, beams in depth (L5), props (P1).

**To show it in the web build,** the demo starts astride a crossing. World has that as a scenario option, off by default.

**Before depth is switched on,** from Rendering's list: the sim's effect particles carry a depth, or every hit off the plane is drawn in the wrong place; and the camera holds the fight's size (§3).

**What it must not break in versus.** The switch-on re-baselines every band, as planned. These hold through it:

| Row | The bound |
| :--- | :--- |
| The X masher against medium, and the pair's win rate, with depth on against depth off on the same seeds | Within 3 points of each other |
| Giving ground's two hard rows; the closing rule's 0.6 bh a tick; no blow from beyond reach | As they are, read in three axes |
| No live tick of a brawl with a dead stick | As it is. A push at a face slides, and in a corner goes up and over |
| Launches a match; the match's length; the first brink | Their bands |
| The collateral rows | Read again. True collisions change what a launch hits, so QA says which move |

**QA's new rows.**

| Row | Kind | The bound |
| :--- | :--- | :--- |
| An attack that misses because of depth | Hard | None |
| A brawl's centre, in depth, outside a flight or a knock-back | Hard | Never over 1.2 bh a second |
| The line's angle; the two fighters apart on screen in a brawl | Hard | Never over 30°; never under 0.5 bh |
| A brawl's centre inside a standing footprint at street level, or outside the band | Hard | Never |
| Depth moving the pair with a stick held, other than along the line | Hard | Never |
| A fighter in a brawl drawn under 85% of his size on the plane | Hard, and Camera's | No tick, after the camera's ease |
| A fighter hidden by a building with nothing opened | Hard | No tick |
| Brawl time off the front street, in an avenue or another street, in a city | Band | 15 to 40%. Under it, the feature doesn't show |
| City brawls that stand over a crossing at some point | Reported, then a band | First guess 30 to 60%: a third of a street is crossing |
| Sends down an avenue a match, in a city | Reported, then a band | First guess 1 to 3 |
| How far a brawl drifts in depth, and how often it changes street | Reported | |

## 7. Phone and Simple

- **Depth needs no button and no stick on any layout,** so there is nothing to map. A pad, a keyboard, a phone and Simple all play the same rule.
- **The sidestep is the dodge** with no direction: A on the Simple pad, and the Dodge button or the ring on touch. It is already there.
- The line's angle can't be seen on the bodies on any screen. Rendering's mark on the ground carries it, for every layout, and its look is UI's, VFX's and Art's.

## 8. If a depth lean is added later

The EP has put the question to Orb. Nothing here assumes the answer.

- **D1 is cut so that it can be added.** Every cause of depth goes through one sum, under one cap, the same faces and the same ease home (§6). A lean on a pad's right stick would be one more row in §1's table: it moves the centre in depth at up to the cap, or it turns the line. No other rule in this page changes, and no QA row.
- **What it would cost parity, in one line:** a pad or keyboard player could choose the drag's direction at will, while a phone or Simple player would still have only the sidestep, so a match between them would need the flag that already separates Simple's assists.

## 9. What it asks of the others

| Who | What |
| :--- | :--- |
| **Encounter** | D1 as cut above, on its L4 plan and World's four reads. The planner's two new sends |
| **World** | L3 and T applied. The demo's start at a crossing. Option Q waits for Orb |
| **Simulation** | The brawl's centre moved in depth each tick, by the mechanisms L2 has. A depth on the effect particles, before the switch-on |
| **Camera** | The four needs in §3. Whether a drift of 1.2 bh a second can be followed without a bob |
| **Rendering** | The mark is built. Open floors, and the patch through every row in front of the action |
| **Animation** | The pair drawn at the line's angle, up to 30°. A sidestep in depth |
| **UI, VFX and Art** | The mark's look. VFX's own layers off the plane |
| **Legal** | The opening of a tower, through the flash check |
| **QA** | The rows above |

**One point for the EP.** ADR 0009 says the player never steers depth. Here he still has no depth control, but his push moves the fight in depth along the line. If that sentence of the ADR needs amending, it is the EP's and Orb's to do.
