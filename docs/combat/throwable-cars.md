# Throwable cars: the moveset side

Owner: Combat and Choreography. Date: 2026-10-17. Paper only: nothing is built.

**Orb** (homework 22, `docs/ep/vision.md`, d65c3439): "Cars: scenery cars, and throwable cars too."

**The rules already written:**
- **The pick-up** is A's context out of reach: a liftable object within 2 bh (`control-rules.md`, row 5). The next attack press throws it, a heavy press slams it down, and the power tier caps the object's size.
- **A thrown object's outcomes** against every state are in `control-rules.md`'s table: damage by size, blocked at the guard's rate, a stagger from tier 3, dodged.
- **Rule of cool 17** (`rule-of-cool.md`): cars at any tier, lorries and boats from tier 2, ships from tier 3. At tone 6 of 10, people bail out first, played for comedy.
- **World's plan** (`docs/world/crowd-cars-buildings.md`): moving cars are dressing, and parked cars can become props in the sim. A car holds no one, so the collateral numbers don't move.

This page is what picking one up and throwing it looks like, and what each fighter does with it.

## 1. The pick-up and the throw, as pieces

| Beat | What the body does | One press is one attack |
| :--- | :--- | :--- |
| **The lift** (A, a car within 2 bh) | He sets under it and lifts. It is a held moment of about 12 ticks, the tell everyone can read | The press is the lift |
| **The hold** | He carries it at the shoulder or overhead and can fly with it. The stick moves him as it always does. A blow that lands on him makes him drop it | No press |
| **The throw** (X or Y) | By the stick, as a launch is aimed: toward across, up a lob, away a throw behind him | The press is the throw |
| **The slam** (B) | He brings it down on the rival in reach, or on the ground in front of him | The press is the slam |

- **The throw is a plain send of an object.** The planner stages its flight, and it is never a launch of the rival. A car that hits him is a thrown object's hit, which damages by size.
- **A car that hits a building** carves as a thrown body of its size does, by the thrower's tier, and counts against the same collateral budget. A car holds no one, so no civilian is counted from the car itself.

## 2. By identity

| | The Protagonist (the guardian, playful and technical) | The Anti-hero (exact and punishing; he feeds on collateral) |
| :--- | :--- | :--- |
| **The lift** | Two open hands under the chassis, the knees bent: a careful, athletic lift | One arm: the forearm plate slid under the frame like a fork, and up |
| **The throw** | A turning heave, sent up or turned, away from people (his care term picks the line) | A straight hurl on a line, across, through whatever stands behind the rival |
| **The slam** | He sets it down hard in front of the rival as a wall between them, rather than on him | He brings it down on the rival |
| **His own use** | **The catch:** a perfect block of a thrown car takes it, and he sets it down or sends it back (his tier-2 art is the redirecting kind, `fighter-pipeline.md` §8). It is the one move only he has | **The street as ammunition:** when the brawl is beside parked cars, the AI picks one up more often than he picks up anything else |
| **The AI** | Picks a car up when a street is empty of people, and rarely | Picks a car up whenever one is in reach and a building is behind the rival |

## 3. Pieces, a fighter (estimate; Animation's figure to come through the EP)

| Piece | The Protagonist | The Anti-hero |
| :--- | ---: | ---: |
| The lift | 1 | 1 |
| The hold, at the shoulder and overhead | 1 | 1 |
| The throw: across, up, behind | 2 | 2 |
| The slam | 1 | 1 |
| The catch and the set-down | 2 | 0 |
| **A fighter** | **7** | **5** |

- **The car itself is not a fighter's piece.**
  - It is a prop body for Simulation, a hashed parked car, World's option B.
  - Its wreck states are Art's.
  - Its no-flash wreck is VFX's, checked against Legal's flash rows, since a car's explosion is a bright event.
- **The moveset generator needs no new kind for this.** These are context pieces under A, like the pick-up today, and each fighter's are named in his row.

## 4. For others

- **Legal:**
  - A lift of a vehicle has no row today. The g03 rows (a lift drawn whole, the body in view) are written for people.
  - Rule of cool's "people bail out first, played for comedy" at tone 6 needs Legal's word against the rating target. World's plan has cars hold no one, which avoids the question.
- **Game Design:**
  - The size caps by tier (rule of cool 17).
  - Whether the throw is X and Y and the slam B, as `control-rules.md` row 5 has it ("the next attack press throws it, a heavy press slams it").
  - The catch's rule: a perfect block of a thrown object.
  - How often the AI may pick one up.
- **World and Simulation:** parked cars as props (World's option B), with the kerb slots by lane.
