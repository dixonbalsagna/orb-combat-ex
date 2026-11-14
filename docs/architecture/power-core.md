# One energy model: the sim's part

Simulation, 2026-11-01, for Game Design's `docs/design/power-scale.md`, with Combat's shares (`docs/combat/pending/power-shares/`). `sim/core/power.gd`, `SimPower`. **Off on main:** `data/fight/power.json` `enabled` false, or a setup's `"power"`. With it off the golden is byte-identical.

## What it does with the switch on

| | Rule | Base, no power | Maximum |
| :--- | :--- | ---: | ---: |
| **Level** | `0.8 × (tier − 1) / 3 + 0.2 × power / 100` | 0 | 1 |
| **Energy** | `4.94 × 12.25^level` | 4.9 | 60.5 |
| **A send's speed** | `900 × √(energy × share)`, share from Combat's table | 2,000 at share 1 | 7,000 |
| **Along the line** | `launchTravel` ×2 in place of `TRAV_LAUNCH` ×6 | 4,000 | 14,000 |
| **Flat-out flight** | `5,000 × 2.305^level`, in place of the far part of `TRAV_FREE`. A setup's `flatOut` moves the base, 3,500 to 7,000 | 5,000 | 11,525 |
| **Close dash** | Unchanged | 1,023 | 1,330 |

**A move's force becomes its speed.** Each launch site asks `SimPower.sendForce(S, A, force, key)`, or `launchBeat` reads the share from its args, the launcher's power or the exchange's template. So everything after it (`chooseLaunch`, `predictFlight`, `doLaunch`) sees the speed in `force`, and `SimForms.launchMul` is 1. The authored forces stay for the switch-off path.

**Who gets which share.** A brawl's send picks by its reason: "a heavy charged to full" `fullB`, "the sell's send" `brawl.rallySell`, "the turn" `brawl.rallyTurn`, "the launcher" by its power from `brawl.launchAnywhere` or `launcher` (0.5, a lit launcher) with none. The press's tap (0.125) and first flash (0.5) are in the data for what they do to what they hit; neither sets a speed. A chain link's launch beat is marked `chainLink` when it's planned, whichever template it runs on. A template's beat reads its template's row. A beat is a style's small pop by its **authored** force, ahead of the earned gate's multiplier.

**No multiplier takes a send past its share.** `SimPower.fm` makes `fm` 1 and `launchMul` is 1, which drops `ACROSS_FORCE`, the long haul's ×3 and `earned.forceMul`. `SimPower.fit` divides by a plan's direction where its length is over 1, as SMASH ACROSS's is 1.05 and a beam's up to 1.17. **Off, both give back what they're given and the callers keep their products in their own order,** because a float product regrouped moves the golden.

**An aimed send flies the flight its aim planned:** `WorldBrunt._aimBy` plans with the same `fit` as `doLaunch`, and `chooseLaunch` leaves `freshMul` out of the aim. Freshness does nothing to a send's length with the switch on, which is a question for Game Design.

**A knock-back keeps its authored skid speed,** as Combat's table rules ("Length stays as ruled"). It carries `dist`, or sets its own velocity.

**The plan's distances** scale with `launchTravel` through `SimPower.distScale()`: `HAUL_MIN` 3,200, `DIST_CAP` 6,000, a town's `haulMin`, and `MOUNTAIN_REACH` and DirSwing's reach with them. With no multiplier there's nothing for a long haul to raise, so that branch and the street's second read of the same flight don't run.

**The meteor isn't a send by energy.** `DirArc.send` sets his velocity from the curve's own shape, the same on or off: on its first tick 12,821 a second, along the line 6,420, over 8.8 s. Game Design's ruling: it stays its own curve and counts as 7,000 (`meteorSpeed`) for its crater, buildings and energy, with its trail in full for the whole curve. Freshness doesn't touch it.

**A repeat launch goes less far** (Game Design): with the switch on its speed is taken down by `fresh` (×0.9 a launch of that kind on him in the last 60 s, ×0.97 any kind, never under 0.7), on the plan and on the send. A knock and a curve are exempt.

**The factor along the line is a static** (`SimPower.trav`), bound each step, as the arena's statics are, because `WorldSlide.launchTravel` takes no state. Two matches stepped in turn, one on and one off, are each what they'd be alone.

## How far a launch carries: the page's slider (landed in 4890bdd9)

Orb found high-speed launches "cool but a little too fast" (Game Design's `slam-and-pace.md` section 2). **A setup's `"travel"` sets the factor along the line for its match** (`S.powerTravel`, bound into `SimPower.trav` each step), held to `power.json`'s `travel` range of 1.25 to 2.0. With no word it's `launchTravel` (2.0). Orb tries 1.25 to 2 with a page slider, and Game Design's lever is 1.5, then 1.25.
- It changes only how far along the line a send carries: **the rise is the same, and the sideways speed goes by the factor.** Energy, the crater and the buildings read the send's own speed, as before.
- It's hashed with the model on, and so is Netcode's desync digest. A replay carries it in its setup. **With the model off it does nothing.**
- **For Sunday's play the page turns the model on** (Tools' page lines: `"power": true` unless `?power=0`, and the slider sends `"travel"`). The data stays off, so the golden is byte-identical.
- **The data's own switch on** is parked separately (`pending/power-flip/`), to land after Sunday. Twelve checks of five other owners were written for the model off and need their owners' pins first. The list is in that README.
- The reach table below is at ×2. At ×1.25 a send across (a 0.32 rise) keeps about 68% of the sideways speed it has at ×2, with the same rise and so the same time in the air, so its reach comes to about 68% of the table's.

## A tapped LT: the slip's brake (landed in 6a30b4c9)

Game Design's (c): "a tapped LT is still the slip". With the flat-out dash, a tap carried him about 31 bh at range (Controls, `docs/controls/runs/d240cef1/`). **`power.json`'s `dash.slip`, or a setup's `"slip"`, only with the dash on:** a dash let go before tick 12 (`underTicks`) eases from its speed on the release to the slip's 1,125 a second (the slip bound's 1.5 bh in 6 ticks) over 4 ticks, by a smoothstep. A dash held 12 ticks or longer is untouched, tick for tick. A new press ends the brake.
- **12 is the pad's own tap/hold line** (`timing.json` `tapHold.holdStart`): a press shorter than the sprint's start is a tap. It was 6 when the brake was first parked; Encounter's slip-arrive grant moved it, and it landed with that park in 6a30b4c9.
- `SimPower.slip` runs in free flight after the stick sets his velocity and before Encounter's arrival.
- `SimPower.slipNote` clears it outside his own free flight.
- Its state is hashed while it's on.
- It works with Controls' `dashHandover` on. With the 12-tick lunge every tap is a 13-tick dash.
- **Encounter's slip-arrive** keeps the arrival's ease through the brake and the coast, and holds a tap at striking distance to tick 13, as today's lunge did. With both, no press is carried further than before at any range (Encounter's matrix, `docs/director/pending/slip-arrive/`).
- A tap at 3,000 apart goes from 31 bh down to 10 to 22 bh (presses of 1 to 11 ticks). The 1.5 bh bound isn't met, because each held tick before the release already moves him 1.1 bh. The levers are Game Design's: `slip.speed`, and the kick's first ticks.

## How far a send goes

Real flights through `doLaunch`, `launchTravel` ×2, started 100 units up, median of 14 starts on planets 7 and 12. Thin samples: read them to the nearest 500. Planet 3 is hillier and shorter.

| Speed | Who | Across (a 0.32 rise) | Low and flat (0.05) |
| ---: | :--- | ---: | ---: |
| 707 | Base, share 0.125 | 700 | 600 |
| 1,000 | Base, share 0.25: a chase, a dodge, a trade | 1,150 | 850 |
| 1,414 | Base, share 0.5: **a lit launcher, heavy clash, guard break, a chain link** | 1,800 | 1,250 |
| 1,817 | Base at 100% power, share 0.5 | 2,850 | 1,900 |
| 2,000 | Base, share 1: a full B | 3,300 | 2,100 |
| 2,570 | Base at 100% power, share 1 | 4,900 | 3,100 |
| 3,050 | Tier 2 at 35%, share 1 | 6,150 | 4,050 |
| 3,500 | Maximum, share 0.25 | 7,450 | 4,750 |
| 4,590 | Tier 3 at 65%, share 1 | 10,500 | 6,300 |
| 7,000 | Maximum, share 1 | 17,850 | 9,700 |

## What's there to reach

800 points round the ring, 5 planets, buildings at every place on.

| Within | 1,200 | 2,000 | 3,400 | 5,200 | 8,000 | 12,000 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| A building on the fight's band, along the line | About 55% | 64% | About 75% | About 84% | 93% | 99% |
| A first-ring building | About 36% | 43% | About 52% | About 62% | 72% | 85% |
| A rise of 600 along the line | 4% | 15% | About 29% | About 39% | 51% | 64% |
| A place, any bearing | About 5% | 13% | About 34% | About 60% | 89% | 98% |
| A place on the line | About 6% | 11% | About 19% | About 28% | 41% | 56% |

The "about"s are interpolated from counts at 1,000 steps.

**The read:** base reaches enough, so base energy stays at 4.94, 2,000 a second, and the ceiling of 3,500 isn't used. Heavy clash and guard break at base carry about 1,800: a building about 6 times in 10, and a place or a hill 1 in 7 or less. They're the shortest of what's called a launch, as Combat intended.

## Not in this part

Craters, absorb, bounces, the burn's look and the beam's groove read the same file and aren't built here (World, VFX, Encounter). Combat's kit rows for moves not on main yet (Banner Snare, Crane Hook, the mixed string's lob, the apex spike, the Driver's lower levels) have shares in the data and no site.

**A landing's wear** comes from the speed it lands at, so slower sends may wear less at base. Game Design's model leaves wear where it is. QA's match length read should say.

## Proof

`sim/core/tools/power_check.gd`, verdict `POWER: n check(s) failed`:
- Level, energy, speed and flat-out against Game Design's table, and Combat's shares at base.
- Flight held flat out at each tier, measured: 5,000, 6,624, 8,701, 11,525, with the close dash exactly what it is with the switch off.
- **Each real route,** not the table: `DirBrawl._send` for a full B (1), a tapped launcher (0.25), a launcher with its power (0.375 and 0.5), the sell (0.5), the turn (0.5); `launchBeat` for heavy clash, guard break, dodge, trade blows and a clean heavy; a chain link's own planned beat on four templates (0.5); a small pop past the earned gate's multiplier (0.125).
- **Aimed sends,** planned by `WorldBrunt.aim` and flown by `doLaunch`: 24 of 24 hit at tier 1, 23 of 24 at tier 4.
- AI fights at each tier: no launched body past what its sender has (2% allowed), and **the hard test: none at tier 2 or under reaches 4,500.** Fastest seen 1,005, 3,103, 4,599, 3,501, from 12 launches, because AI launches are rare on a whole ring. Thin: QA's read is the real one.
- The meteor's curve is the same on and off.
- Two runs one hash, a match on and a match off in turn, a rollback across launches.
- `--negative-control` lets a send go 3 times past what it has, and the hard test sees it.
