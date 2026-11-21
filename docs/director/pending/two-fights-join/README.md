# Parked: the sends that bring the fights together (2v2 step 4)

Encounter, 2026-11-02, on Game Design's "What brings the fights together on a full globe" (`docs/design/two-v-two.md`), with the ruling of the same day: not while a team is two on one. **Behind `outside.enabled`,** and only in a two-fight match with cross on. In a 1v1 the planner's new term is 0 and nothing changes.

**Apply after `../outside-blow/`:** `git -c core.autocrlf=false -c core.eol=lf apply two-fights-join.diff`.

## What it does

| | |
| :--- | :--- |
| **The clock of time apart** | Kept once, on the match's first body (the swing's anchor), in fight 0's tick. It runs while the pairs aren't together (`SimStage.together`: everyone within `swing.json` `apartReach` of the middle) |
| **After `join.afterSec` 60 s apart** | Every send scores the way of the other fight: `join.w` 8 for a landing a sixth of the loop nearer its middle, less for less, and the same against one that takes him away. Computer fighters too. It's a term in `DirLaunch.chooseLaunch` beside the rally's variety, so the planner still picks by everything else |
| **Two on one** | No pull: a fight with a KO means the fights have met |

The other fight's middle is taken from its own first body: an average from this fight splits across the half ring when they're opposite.

## Read

`outside_check`, the other fight a fifth of the way round:

| | Score of a landing 3,000 toward / away |
| :--- | :--- |
| Apart a moment | 0 / 0 |
| 70 s apart | **+0.94 / -0.94** |
| Two on one (a KO in the other fight) | 0 |

## Not done

- **QA's rows** decide whether 8 is enough: all four within about 15,000 units for 25 to 50% of a match, and 2 to 4 rescue flights a match. It needs a two-fight soak with the AI. The weight is Game Design's to tune.
- **The brink's call** (step 5) and **the finished fight** (step 3, after Simulation's match end and rejoin) are next.
