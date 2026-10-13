# The wall slam's damage: Combat's number

Owner: Combat and Choreography. Date: 2026-10-12. For World's `wallSlamMul` and Game Design's `docs/design/buildings.md` section 2. It is arithmetic on the constants in the tree, not a run: the line is not in the sim yet.

**The number: 2.0.** A launched body that a building holds takes twice the building's hit. Game Design's first value stands, and here is why it is the right one and not only a first one.

**What it sits among,** at World's reference launch (speed 2,000; a tower that is gone through keeps 0.7 of the speed):

| What happens to him | Damage |
| :--- | ---: |
| A light, a medium, a heavy that land in a brawl | 8, 20, 48 |
| He lands on open ground | 36 |
| He goes through one tower, then lands | 49 |
| **A tower holds him: the wall slam at 2.0** | **48** |
| At tier 2: through one tower, held by the next | 58 |
| A chain of three with the lodge, at tier 3 | 61 |
| A chain of four with the lodge, at tier 4 | 67 |

A fighter has 1,600.

**Three reasons.**
1. **It hurts like a heavy.** At the reference launch a wall slam is 48 and a landed heavy is 48. A player can feel that without a table: being put into a wall you cannot break is one more heavy.
2. **It beats open ground by a third, so aiming is a choice.** At 1.5 the wall equals the ground (36 and 36) and there is nothing to aim for. At 2.0 the wall gives a third more, before the 24 ticks he is staggered there and the first move it gives the attacker. That is enough to make a tower worth the stick at tiers 1 and 2, and the fighter who cares still pays for it in the people inside.
3. **It stays under the chain, so power still has weight.** At 2.5 a tier-1 wall is 60, the same as a tier-3 chain of three towers. At 2.0 the order holds: a wall, then a punch and a wall, then the chains.

**Two riders, both small.**
- **Once a launch.** If he comes off one wall into another in the same flight, the second is a plain building hit. Otherwise a narrow street pays twice for one blow.
- **No new rule for where it lands.** The slam wears him as a launch impact does today. It names no region of its own.

**What would change it.** The slam scales with his speed, as the building's hit does, so a slow launch slams softly; that is meant. If QA's rows show towers taking nearly every tier-1 launch in town, the lever is the planner's score for a wall and not this number: at 2.0 the wall is worth a third more than the ground, and no more.
