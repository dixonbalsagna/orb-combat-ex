# Crater width by tier (A-WORLD-06, X-14): the rule, the data and the check (World, 2026-11-14)

Orb's X-14 asks for about three times the crater width at the top tier. Game Design ruled the numbers (`docs/design/buildings.md` section 6.2). Park: `docs/world/pending/crater-tiers/`. Check: `sim/world/tools/tier_ratio_check.gd` (`TIERRATIO`, in CI). Data: `data/biomes/craters.json` `tier`, `data/biomes/blast.json` `tierEnergy`.

## The two paths

| | The number | Where |
| :--- | :--- | :--- |
| **Energy model on** | **No tier table; the model decides.** A fresh base fighter's full send digs 356, a top-tier one's 1,245 (the plan's 356 and 1,244): **3.50 times.** Tier for tier at equal power, tier 4 over tier 1: **2.72 times** | `SimPower` (Simulation's) through `WorldCrater.impactEnergy` with `S.powerOn`: v squared, no tier term. Unchanged; this park only asserts it |
| **Energy model off** (old arenas, tests, anything the model does not cover) | **A table of energy multipliers by tier: 1, 2.1, 4.3, 9.** The radius goes with the square root: 1, 1.45, 2.07, **3.00** times (today: 25 percent a tier, 1.32 times at tier 4) | `craters.json tier.energy`, read with `tier.on`; `WorldCraters.tierEnergy(tier)` is linear between whole tiers |
| **Shots, model off** (an energy shot's crater) | The same table in place of today's 1, 1.3, 1.7, 2.2 | `blast.json tierEnergy`: data only |
| **Shots, model on** (Game Design's ruling, buildings.md section 9) | The kind's own base (today's `craterE`, as level 0) times 12.25 to the level: 3.5 times the radius from a fresh base fighter to a full top tier, tier for tier 2.72, as a beam's groove does | `WorldBlast.craterEnergy(S, f, k, charge)`: the model's `SimPower.energyTop ^ SimPower.level(f)`; the table is not read |

## What the check asserts (`TIERRATIO`)

- Model on: base to top at full power at least 3 times (reads 3.50); tier 4 over tier 1 at equal power, at powers 0, 25, 50, 75 and 100, between 2.5 and 3.5 (reads 2.72).
- Model off: tier 4 is 3.0 times tier 1 within 5 percent (reads 3.000); tiers 2 and 3 are 1.45 and 2.07 within 0.03.
- The data's table is Game Design's four numbers; shots' `tierEnergy` is today's or the table, and follows `tier.on`.
- Shots, model on: for each of the six kinds a fresh base fighter's shot is the kind's `craterE` and a full top tier's digs 3.50 times the radius; tier for tier at equal power between 2.5 and 3.5 (2.72). Model off: tier 4 over tier 1 is the square root of `tierEnergy`'s last over its first (1.483 today, 3.0 with the table).
- Negative control (the code before this park): 3 rows fail (the table rows read 1.32, 1.12 and 1.23 times). Shot control (`craterEnergy` ignoring the model): 2 rows fail (1.48 times).

## Switch and state

`tier.on` ships **false**: today's behaviour bit for bit (the golden is unchanged). The data row (`crater-tiers-data.diff`: `tier.on` true and `blast.json tierEnergy`) is a crater-size change, so it flips in a window with the other crater rows (GW1b or GW2: Simulation's call). Two checks assume today's tier term and are either-state now: `power_world_check` (the tier-4 row reads the table when it is on) and `meteor_crater_check` (pinned to 25 percent a tier, which its numbers were taken at).

## Shots under the model (ruled by Game Design, 2026-11-14; behind a switch, shipped off, 2026-11-23)

**The rule is `blast.json shotModel` (absent or false shipped).** Off, a shot's crater under the energy model is the kind's base times `tierEnergy[tier]`, exactly as the 9 November build and main have it (the golden does not move). The data row that turns it on (`crater-tiers-shots-data.diff`) moves the energy-on golden and is Orb-visible: it waits for a hash window and a side-by-side of a top-tier shot's crater.

With the model on a shot's crater energy is its kind's base times 12.25 to the level, not the tier table (re-cut to match: `WorldBlast.craterEnergy`). **This moves shot craters in the energy-on golden** (it used to read `tierEnergy` with the model on, today 1 to 2.2 times): Simulation's energy-on target records it. With the model off nothing moves.
