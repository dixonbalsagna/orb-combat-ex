# Parked: a swing's plan and offer, for less, with the same answers

Encounter, 2026-11-01, the EP's order, from Simulation's timers on a launch tick. **No switch: the same sums, for less.** It changes no answer: Orb's match reproduces every checkpoint and the same final hash.

**A plain patch on HEAD.** It doesn't touch `field-place`'s grant.

**Apply in a scratch export:** `git -c core.autocrlf=false -c core.eol=lf apply swing-plan-cost.diff`. Then copy.

## What it does

| Where | What | Why it's the same |
| :--- | :--- | :--- |
| `SimSwing._poseThese` | The line's terms and the band's edges are worked out once, not per building, and a building outside the band both before and after skips its buckets | The same arithmetic in the same order, to the bit |
| `SimSwing.posesNear`, `DirSwing._planOn` and `_planOff` | A plan that's posed the buildings doesn't pose them again when its candidates ask on the same line, about the same point | A pose is a function of the line, and nothing moves in between |
| `DirSwing._onLine` | The sine's only taken where simple bounds don't decide it: sin y° lies between y / 90 and y × π / 180 up to 90°, with a margin of one part in a million | The count is the count: anything near the edge still takes the sine |

## Before and after

Orb's match, on `field-place` and its grant, with the bake and the page's switches. Three runs each, taken in turn, one job, below normal, medians, in ms. **All 6 runs: 36 of 36 checkpoints, final hash 630154cb09579ddc.** The timers add a little of their own, and these are single ticks, so a difference under about 2 ms in a tick's total isn't a reading.

| Tick | | Whole tick | `posesOf` | `scored` |
| ---: | :--- | ---: | ---: | ---: |
| 2751 | launch | 24.3 to **18.1** | 6.5 to **2.0** | |
| 18753 | launch | 21.6 to 21.3 | 2.4 to **0.8** | |
| 19500 | launch | 22.3 to 20.2 | 1.7 to **0.8** | 3.0 to **2.2** |
| 21732 | launch | 12.6 to 10.4 | | |
| 2550 | offer | 5.9 to **3.7** | | 3.5 to **2.3** |
| 20014 | offer | 4.5 to **3.0** | | 4.0 to **2.4** |
| 20318 | offer | 4.7 to **3.2** | | 3.9 to **2.6** |
| 21313 | offer | 6.1 to **4.3** | | 4.2 to **2.5** |

**All 37 ticks with an offer or a launch: mean 6.9 to 5.3 ms.**

**Tick 252 stays at about 31 to 35 ms.** That's `_builtPlaces`' first walk, and `swing-warm` moves it.

## What didn't come down

- **`_standing`: 0.9 to 1.8 ms, unchanged.** The cost isn't the walk, after `field-place`'s grant. It's `acosf` and `atan2f` for each building in reach. **I built a coarse index of the buildings' directions and it read no better than the plain walk,** so it's out.
- **A launch tick is still 10 to 21 ms.** `chooseLaunch` is most of what's left: `predictFlight` is `ceil-table`'s, and `aim` and `candidates` are as I reported.
- **`_poseThese` is cheaper for every swing tick, not only plans.** I haven't read those ticks.

## Proof

On the stack (chase-tap, chase-ease, charge-armour, idle-match, beam-still, beam-hold, this), one job at a time, below normal:
- **Off:** golden byte-identical, `frame_check` digest d292f189cff552bb, the same as Simulation's. Validate 302 files, self-test 9,977. `swing_check` 0, `beam_front_check` 0, `chase_tap_check` 0.
- **With the page's switches on:** determinism on the field, rollback, `two_states`, `stick_check` 0, `beam_front_check` 0, `chase_tap_check` 0.
- `swing_check` shows 4 failures with the page's switches on: "the switch off", "planet 7" and "planet 11: at rest", and "only built places count". I'd seen 4 failing there before this piece, as its rows read the page's data, but I didn't compare it against a run without this piece.
- `stick_check` shows its usual 6 rows with the switches off.

**Not run:** Rendering's 15, which matter here because `_poseThese` writes what the view reads. The EP's gate runs them.

## Grants

| Whose | File | What |
| :--- | :--- | :--- |
| **Simulation's** | `sim/core/swing.gd` | `_poseThese`, rewritten in place, about 40 lines. `posesNear`, 2 lines. `holdPlan` and its 3 statics, about 10 |
