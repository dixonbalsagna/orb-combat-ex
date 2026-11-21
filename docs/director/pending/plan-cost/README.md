# PROP SMASH's plan cost (Encounter, 2026-10-30): WITHDRAWN, 2026-10-31

**Withdrawn: don't land this. The EP may delete the folder.** Performance's and Combat's `propflight` and `launch-reads` take the search's cost. All that's left here is the tick limits (`aimTicks`, `aimTicksAll`), which guard a worst case nobody has measured since. If the launch tick is still over budget after those land, I'll cut the limits again on what's there, with a fresh timing. The rest of this page is the record.

## As it stood: unfinished, stopped by the pause

**Not ready to land: the gates haven't run.** The diff is built and timed. Orb's pause stopped the paired timing, and the gates and
the QA arm after it never started. Cut on main 6a6e00e1; it applied cleanly on 5a294503.

Performance's finding: `DirLaunch._propFlight` simulates a whole `WorldContact` flight per aim force in one frame
(`docs/perf/preview-deform-launch-2026-10-30.md`, item 1).

## The change (`plan-cost.diff`)

Nothing is spread over ticks and nothing is cached, so there's no new state. The search is bounded in ticks, never in time, so every
machine and every replay gives up at the same tick.

- **The flight stops past the furthest prop.** A flight that has passed it can't break a prop, unless it comes back.
- **At most 120 ticks a flight (`aimTicks`) and 480 in the plan (`aimTicksAll`).** Every flight that broke a prop did so within 110 ticks.
- **Props are fetched once and only ahead.** `_propsNear` looked both ways and `_propTargets` fetched each column again.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/launch.gd` | Encounter | The above; `_aimLeft`, set as a plan's search starts and read only inside it |
| `data/combat/launch_biome.json` | **Combat** (grant needed) | `aimTicks`, `aimTicksAll` in the PROP SMASH row. The schema doesn't list the row's keys, so no schema line |

## Timing so far

`chooseLaunch` in native CPU, microseconds, min of 3 calls at each of 10,050 poses where PROP SMASH is searched: 6 gen 2 planets, 2
touches each, biome on. Machine loaded and **the two runs weren't at the same moment**: the paired run was what the pause stopped, so
treat the ratio as rough.

| | p50 | p90 | p99 | Worst |
| :--- | ---: | ---: | ---: | ---: |
| As built | 3893 | 11261 | 15962 | 26992 |
| This diff | 1905 | 2935 | 4415 | 6748 |

Flight ticks per plan: p90 861 to 71, worst 1495 to 485. Performance's multiplier of about 4 for the laptop is an estimate I haven't
checked: p50 about 8 ms, p99 about 18 ms, worst about 27 ms. **So under 8 ms native at every pose, and not on the laptop past the
median.** Going further means `predictFlight` per candidate or spreading the plan over wind-up ticks; neither is built.

## What it changes in play

Of 7352 poses offering PROP SMASH, 19 lose the offer and 2 gain one (0.3%), nearly all at aimed forces above the row's own. The pick share in
real matches isn't read yet: band 5 to 30% where offered, 8.0% in QA's floor-on table.

## Still to do

Run `tools/gates.sh <base>` in a scratch folder (its scratch paths need updating): paired timing; golden byte-identical with biome off
(`_biomeCands` doesn't run then, so it should be, unproved); twin; parity; `propreach_probe`; `launchbiome_probe`; `sigafter_probe`;
`sigvariants_check`; `flighthooks_probe`; determinism; rollback on planet 2 with biome on and off; validate, self-test, lint; QA's
default arm for PROP SMASH's share. `tools/mk.py` adds the counters `plan_cost.gd` reads, to a scratch tree only; never land it.
