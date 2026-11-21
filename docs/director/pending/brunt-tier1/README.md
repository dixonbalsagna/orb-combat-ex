# Parked: the building preference from tier 1

Encounter, 2026-10-31. `docs/world/ring-any-angle/game-design.md` section 15, its first lever. **One live number, not behind a switch:** `data/director/launch.json` `town.bruntFromTier` goes from 2 to 1. It works on every world.

**Stacks on:** `../swing-buildings/`, though it touches nothing else.

**Apply in a scratch export:** `git -c core.autocrlf=false -c core.eol=lf apply brunt-tier1.diff`. Then copy.

## What it does

With a building on the line and no stick held, the planner adds `bruntPrefer` (40) from tier 1 instead of tier 2. Every planned launch in a 2-minute AI fight is tier 1, so today's opening has no preference at all.

## Proof

| Gate | Result |
| :--- | :--- |
| Golden | **Doesn't move:** light digests and tick counts identical to `../swing-buildings/`'s |
| Full gate list and Rendering's checks | **Running.** This table is updated when they finish |

## What it reads

| | Tier 2 | Tier 1 |
| :--- | ---: | ---: |
| Gen 2, 8 fights: BUILDING SMASH chosen, bodies into buildings | 6, 5 | 7, 6 |
| Gen 3, 8 fights | 5, 5 | 6, 6 |

Small, and within noise on 8 fights. With a building in reach and the pair placed by it, the planner takes it 82 to 86% of the time at this setting, on 1,600 plans. **So this won't reach section 15's 4 to 8 sends alone:** most launch beats never reach the planner.
