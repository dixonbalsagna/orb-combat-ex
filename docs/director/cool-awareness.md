# The choreographer's eye for cool: what it watches, how it picks, where it may steer (paper)

Owner: Encounter Systems Director. Date: 2026-10-16. **Paper only: nothing is built.**

It answers Orb's direction of 2026-10-16 evening (`docs/ep/vision.md`, "Orb answers homework 22, 22b, 23 and 26"): rule of cool takes precedence; the player's agency is respected, but when rule of cool demands it the fight choreographer decides the direction the fight takes; and the choreographer should always be aware of cool scenarios as the fight goes and use the combat alchemy system to choose emergent situations.

## 1. The rule, in one paragraph

**The player chooses what to do; the choreographer chooses how it plays out.**
- A press is one attack, its button is his, and its timing is his.
- When the press leaves a choice open, the choreographer makes it, and makes it for the scene. That means the send of a launch, the line of a throw, which building takes the body, whether the flight bounces off a ridge or skids along a street.
- **Rule of cool steers inside the choice the player made, never against it.** The one place it may go further is the fight's direction: where the fight travels next, toward the city, up the mountain, out over the sea. That is the choreographer's to pick between exchanges.

This is how the launch planner already behaves: the stick's quarter (up, toward, down, away) limits the candidates, and the planner scores among them (`DirLaunch.chooseLaunch`). The paper widens that habit to every open choice, and gives the scoring an eye for the scene.

## 2. What it watches

A **scene read** at each decision point, not every tick. It is a pure function of the state, cheap, deterministic, and shown in the debug feed so every pick is explainable (the architecture's rule). Most of it exists in pieces today.

| What | What it reads | Where it is today |
| :--- | :--- | :--- |
| **Buildings on the line** | For each candidate send, the first building the predicted flight meets: its height, its floors, whether it holds or is gone through, people inside, a landmark | The planner's predictor (BUILDING SMASH, the chain through several); World's brunt and floors |
| **A wall in reach** | A building within a body height or two that holds: a wall slam, a pin in a clinch | World's wall slam (579dd984) |
| **Height** | Both fighters' altitude and ground clearance; a ridge or cliff in reach; water under the line | UPPERCUT's altitude term, MOUNTAINSIDE, CRATER SLAM, the water term |
| **Power** | Tiers, forms, ki, a charge's level, a beam ready; the act and the brink | The tier terms; the mood's acts |
| **The crowd** | People near the landing and inside the building; the collateral budget left in the window and under the ceiling | The personality term (care, menace); World's budget |
| **The fighters' states** | His run and gauge, an opening, a stagger, in the air, returning, the chain of perfects, a duel's level, a clinch's grip | The brawl's slots |
| **The frame** | Whether a send keeps the pair in one view or splits it, and how far the body flies | Camera's rig (read only) |
| **The recent past** | What was staged in the last minute: which set pieces, which sends, how long since the last big moment | The variety term (the last two launches) |

## 3. The situations it can steer toward

Each is an emergent set piece the systems already make, or are about to, when the conditions line up. The choreographer doesn't script them. It notices when one is in reach, and weighs the open choice toward it.

| Situation | When it is in reach | What the choreographer picks | Built? |
| :--- | :--- | :--- | :--- |
| **A chain through a building** (Orb: through a floor, off the ceiling, down through the next) | A launch or a throw whose line meets a building's side at floor height, with budget left | The send and the force that put the body in at a floor, not over the roof | The chain exists; floor-by-floor bounces are World's to build |
| **The wall slam** | A building that holds within reach of a knock-back, a throw across or a carry | The across send toward it | Yes |
| **The ridge or the cliff** | A mountain face in reach on the line | MOUNTAINSIDE, a bounce off the face | Yes |
| **The crater** | High in the air over open ground | CRATER SLAM, a drive down | Yes |
| **The sky juggle and the chase** | Open sky above, the attacker free to follow | UPPERCUT, and the chase's beatdown | Uppercut yes; the chase is the tenth round, to build |
| **The skim and the splash** | Water under a long send | A flat send across it | Yes (the landing mix) |
| **The duel and the cash-in** | A chain of perfects | The level's staging; the amplified send's line | The tenth round, to build |
| **The beam struggle with a view** | Two beams that meet over a city, a ridge or the sea | Nothing in the outcome (the presses decide it). The overwhelm's line, inside the winner's stick | Built (parked, window 4) |
| **One hit, many bodies** | A guard on the line of a send in a 3v1 | A send that carries him into another guard or the Empress | To build with stages 2 and 3 |
| **The clinch at a wall** | A clinch walked into a building that holds | Nothing: the leader walks it. The throw's line from the pin | The grapple, to build (`grapple-director.md`) |

## 4. How it scores and picks

**The planner's score, made general.** For every open choice, each candidate gets:

    score = base + scene + personality + drama by act + novelty − cost + a keyed draw

- **Base:** the candidate's own worth, as the planner's table has it now.
- **Scene:** what section 2 found on its line. A building at floor height scores more than one it would sail over, a wall more than open ground, a ridge more than a flat field, height more than none.
- **Personality:** who is in the way. The hero spares people, and the villain seeks them. The care and menace terms, as today: personality decides, drama only adds.
- **Drama by act:** the bigger set pieces weigh more as the fight climbs. The act and the brink scale the scene term, so act 1 is mostly brawling and the climax brings the city down.
- **Novelty:** a set piece just seen weighs less; one not seen for a while weighs more. That is the variety penalty, widened from the last two launches to the last minute of set pieces.
- **Cost:** the collateral budget (no chain that would break the window or the ceiling), a send that throws the pair out of every frame, a landing in the sea when the fight has just come out of it.
- **The draw:** a keyed draw, so the same scene doesn't always pick the same answer, and a replay picks it again.

**The pick** is the top score, as today. The top three show in the feed with their terms, as the planner's launches do now.

**Pacing:** at most one big set piece in a stretch of fight, so the cool moments stay moments. The window's length is data. A big set piece is a chain, a wall slam, a mountainside or a juggle that leads into a chase.

## 5. Where it may steer the player, and where never

**Never:**
- **Whether a press is a blow, which blow, and when.** One press is one attack (Orb), its button picks the cell, and its timing is his: the beat, the perfect window, the pulse.
- **His defence.** A guard, a dodge, a perfect block, an escape, a tech, a let-go. Nothing the choreographer does turns these into anything else.
- **His target** in one versus many: his stick picks it, else the nearest (Orb's homework 19).
- **The outcome of a contest the presses decide:** the beam struggle, the clinch's grip, the finisher's struggle, a duel. It stages them, and never moves them.
- **His flight.** A free fighter's movement is his.
- **Against his stick's quarter.** A stick held up is never turned into a send across or down; toward is never away.

**May:**
- **Inside his stick's quarter, the exact line.** A stick toward is a send across, and the choreographer may pick which of the across sends, its rise within a band, and its force within a band, to put the body into the building's side at a floor. This is the planner today, made aware of floors and walls.
- **With the stick neutral, the whole choice.** No aim is a request to be shown something.
- **Between exchanges, the fight's direction:** where the next stretch of fight goes. A send that carries the pair toward a town, a ridge or a lake, chosen for the scene and by personality. This is the "when rule of cool demands it, the choreographer decides the direction" Orb named. It moves the stage, not the player's hands.
- **Everything about the AI's side,** within the AI's own rules (it never reads a release, it never reacts faster than its level allows).
- **The staging:** freeze, camera emphasis, the cues the views read.

**One open question for Game Design:** whether a *strong* scene may bend a send past the quarter's edge, say 20 degrees, when the stick is near that edge. I would start with no: the quarter is a promise, and a near miss of a building is a fine moment too.

## 6. What it needs from others

- **Game Design:** the launch-anywhere rules (no four-in-a-row gate, no cooldowns, a launcher started and aimed at any point in a string). My next launcher window replaces window 1's rest and gate with them when they land. Also the pacing window's first value, and the open question above.
- **World:** the floor-by-floor chain (in through a floor, off the ceiling, down through the next floor), and a predictor the planner can ask for the floors a line enters, so it can score them.
- **Simulation and Animation:** the mid-air recovery in a reasonable time and the mid-air skid, so a big send reads as speed and the sent fighter is back in control soon. The director's part is the air tech's timing and the chase's window.
- **Camera:** a read of whether a send keeps the pair framed, for the cost term.
- **Combat:** which moves hit everyone in reach, for "one hit, many bodies".

## 7. What QA would measure

| Row | Bound |
| :--- | :--- |
| A send outside the stick's quarter | Never (hard) |
| A big set piece within the pacing window of another | Never (hard) |
| Big set pieces a minute, the AI against itself | A first band from the first read |
| Set pieces by kind | No kind above 40% of them |
| Chains that break the collateral window or ceiling | Never (hard, as today) |
| The top three of every pick, with their terms, in the feed | Always |

## 8. The order I would build it in

1. **The scene read,** pure and in the feed, beside today's planner. Nothing changes in play.
2. **The planner's terms moved to data,** under one score: the scene, the drama by act, the widened novelty. The golden moves once.
3. **The same score for the throws** (the grapple), **the enders and the knock-backs,** so every open send is chosen one way.
4. **Pacing** of the big set pieces.
5. **The fight's direction** between exchanges.
6. **The launch-anywhere rules** when Game Design lands them, in the launcher window.
