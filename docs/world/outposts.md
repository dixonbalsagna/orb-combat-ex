# Polar research outposts (World, 2026-10-16)

Owner: World and Environment. Orb (22b): "I like the idea of a remote research station." Cap size: "Hard to say, lets balance it further and see what it feels like in the game." **A design with a prototype placement; nothing in the game.** Picture: [L2](planet-slice/l2-research-outposts.svg), to scale with fighters. Sites and windows from `scratch-build/small-circles/outposts_dump.gd` on planet 7 (`WorldPlanet`).

## What an outpost is

A **third kind of place**, beside the city and the town: `KIND_OUTPOST`, a disc of about 700 units (a city's is 6,500, a town's 2,440), 6 to 9 buildings and a few tens of people. It gives a polar arena what it lacks, **something to break and a few people to get out**, without pretending the ice is a city. It carries a name by the grammar (the ice bank plus "-watch": Glasswatch, Rimewatch, Thawwatch) and counts as a place everywhere a place does: the wear list, the status, the people, the picker's held list.

| Site | Rule (placement, from the planet function) | On planet 7 |
| :--- | :--- | :--- |
| **A shelf station** | On the flat ice shelf (a sheet at about 36 units) with the sea within 2,500 units on one side and the dome rising on the other | Glasswatch, 61 degrees south |
| **A high station** | On the sheet above 1,300 units with bare rock within 3,000 units | Rimewatch, 76 degrees south, 1,450 units up |
| **A floe station** | On a floe: 8 of 8 directions at 700 units still sea ice (the middle of a big floe) | Thawwatch, 88 degrees north |

Placement is another keyed pass of `WorldPlanet`'s places (three sites a planet, a few hundred candidates each, deterministic from the seed), after the cities and towns, so it moves nothing already placed.

## What it holds (to scale, L2)

Buildings at the city's own scale (a house is 4 to 6 fighter heights): huts 300 to 360 wide and 260 to 300 tall, a lab block 700 by 520, two fuel tanks 150 by 400, a mast 800 tall. A station spans about 2,500 units, a little under a screen. **Its people** are an area weight like any place's (700 squared against 6,500 squared: 1/86 of a city), about 15 to 20 of a slice's 1,800: **the collateral shares barely move**, and the same ledger, status and wear rules apply (a station can be fallen).

## Rules it needs

- **The minimum.** An outpost is not a town: a loop round a pole (small-circles.md) has none of the cities or towns the strict minimum asks for. The picker's relaxed minimum counts **one outpost as a town in an arena that is at least half ice** (data), so a polar arena with a station is a legal pick. The picker finds one only when its candidates include the pole or a polar loop.
- **A station on a floe is on thin ice:** a crater through it should open the water under it (the thin-ice rule of `planet-ice.md`); a floe station is the likely first use.
- **People and Legal.** A research station is a place where people work, not a school, hospital or place of worship (c08). The people evacuate as any place's do.

## Work

One planet window after window 1: the third kind in the places list (data: the three site rules and the radius), the plan archetype `outpost` in `settlements.json` (shapes `shed`, `hall`, `chimney` and `mast` exist), the relaxed rule, names from Narrative's ice bank. No golden until a planet is a setup (windows 2 to 4).
