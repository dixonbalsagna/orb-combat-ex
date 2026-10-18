# Throwables: the moveset side

Owner: Combat and Choreography. First version 2026-10-17 (a73ed41d). **This version (2026-10-18) follows Game Design's ruling,** "Throwables, ruled" in `docs/design/rule-of-cool.md` (1e06319b), with Art's mass classes from `docs/art/cars.md`. Paper and a parked data file (`pending/throwables/throwables.json`); nothing is built.

**Orb** (homework 22, `docs/ep/vision.md`): "Cars: scenery cars, and throwable cars too."

## 1. The rules (Game Design's), and what changed here

| | The ruling |
| :--- | :--- |
| **What a tier can lift** | Tier 1: mass 4 at most (a bike 1, a sedan 3, a van 4). Tier 2: 8 at most (a bus, lorries and boats). Tier 3 and up: ships |
| **The pick-up** | A's context: an object within 2 bh, while he is free and the rival is beyond striking reach |
| **X, Y and B** | **X** tosses it along the stick, quick and low. **Y** throws it in full. **B** slams it down on a rival in reach, or onto the ground in front of him. Holding an object, B is never a launcher |
| **The catch** | A perfect block of a thrown object within the catcher's tier catches it. He holds it, and his next X or Y throws it back, worth a quarter more. Above his tier's mass the perfect block swats it aside along his stick: no damage to him, and where it lands is on the thrower's account. A plain guard blocks it at the guard's rate |
| **The AI** | In 10, 20 or 30% of its chances by level. The Anti-hero takes half again as many. The hero only when the throw's line is clear of people. QA's band: 0.5 to 3 thrown objects a match, AI against AI. No cap and no cooldown |

**What changed from my first version:**
- **The catch is everyone's,** not the Protagonist's alone. What is his is how it looks.
- **X and Y are a toss and a throw,** and B is the slam.
- **The lift has three sizes** (below), because a bike, a van and a bus can't be lifted the same way.

## 2. The pieces by size, and by fighter

| Piece | The Protagonist (the guardian, playful and technical) | The Anti-hero (exact and punishing) |
| :--- | :--- | :--- |
| **The lift, light** (a bike) | One hand under the frame, swung up to the shoulder | Picked up by the frame in one hand |
| **The lift, heavy** (a sedan, a van) | Two open hands under the chassis, the knees bent, stood up with it | The forearm plate slid under the frame like a fork, and up on one arm |
| **The lift, huge** (a bus at tier 2, a ship at tier 3) | Under the middle with both arms, the back straight, raised overhead in two steps | The plate under and the free hand on top, both arms, to the shoulder |
| **The hold** (he can fly with it) | At the shoulder, or overhead | Out on the plate at shoulder height |
| **X, the toss** | A side-arm skim, low and flat, on a quarter turn | A short straight push off the plate, low |
| **Y, the throw** (along the stick, for both) | A turning heave, one full turn and the release | A straight hurl on a line |
| **B, the slam** (on a rival in reach, else the ground in front, for both) | Brought down with both hands and a turn of the hips; on the ground, it is left standing as a wall between them | Brought straight down off the plate; on the ground, slammed flat |
| **The catch** (a perfect block) | Open hands meet it and give with it, a turn taking the speed, and it is held at the shoulder | Stopped dead on the plate, no give, held there |
| **The swat** (above his tier) | A palm on its side and a turn, deflecting it along his stick | A backhand of the plate, aside |
| **The throw back** (X or Y while holding a catch) | As his toss or throw | As his toss or throw |

- **The rules are the same for both.** A slam lands on a rival in reach and otherwise on the ground; a throw goes along the stick; a catch is a catch. What differs is the look, and what each fighter's AI prefers when it aims: the hero's line is away from people (and it picks an object up only when that line is clear), the Anti-hero's through what stands behind the rival.
- **A thrown object is a plain send of an object.** The planner stages its flight, and it is never a launch of the rival. It damages by size (the table in `control-rules.md`). Against a building it carves by the thrower's tier, on the same collateral budget. A car holds no one, so nothing is counted from the car itself.

## 3. Poses a fighter (estimate; Animation's figure to come through the EP)

| Piece | Poses |
| :--- | ---: |
| The lift, three sizes | 3 |
| The hold | 1 |
| The toss | 1 |
| The throw | 1 |
| The slam | 1 |
| The catch | 1 |
| The swat | 1 |
| **A fighter** | **9** |

- **The object is not a fighter's piece.**
  - It is a prop body for Simulation, a hashed parked car (World's option B in `docs/world/crowd-cars-buildings.md`).
  - Its wreck is Art's: a thrown car that lands becomes the wreck, with no people in or around it.
  - Its no-flash smash is VFX's.
- **The moveset generator needs no new kind.** These are context pieces under A, named for each fighter in `throwables.json`.

## 4. For others

- **Legal:** no row covers a lift or throw of a vehicle; g03 and g04 are written for people. A row for a lifted or thrown object is asked: drawn whole and in view, no person in it. World's and Art's cars already hold no one.
- **Animation:** its figure for the nine poses a fighter, and whether the huge lift's two steps read at fight speed.
- **World and Simulation:** parked cars as props, with the kerb slots by lane.
