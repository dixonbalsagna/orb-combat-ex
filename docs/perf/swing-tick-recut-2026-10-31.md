# The swing tick on Simulation's re-cut field-frame, in whole AI matches (Performance and Platform, 2026-10-31)

For the EP, on the owed re-bench of `swing-tick-2026-10-31.md`: the re-cut `docs/architecture/pending/field-frame` (the list `S.bList`: buildings within `poseReach` of the pivot, `poseBody` of each of the pair, `poseShot` of a shot and a sent body's aimed building, laid again every 8 swing ticks or when the pivot crosses 500 units; the incremental `_rebucket` is in it), on the stack Orb's page builds (field-frame, tile ground, swing director on, `d5a0924f`). **Two things came out of it that matter more than the tick: a 2.7 s freeze in one line of Simulation's, and 22 to 112 ms hitches at launches with the swing director on.**

## Method

Scratch tree of the stack (a copy; nothing in the repo changes), `hook-7-recut.mjs` (own-time counters in `swing.gd`), `swing_bench2.gd`: whole AI-vs-AI matches of 3,600 ticks (planets 7, 12, 21, seed 77, `planetGen` 3), the swing director **on** as the game ships it, so swings are the director's own, not asked by the bench. Native, headless, below-normal, 3 Godot jobs at once, 2 reps; the match is deterministic (end state printed, identical across runs), so the per-tick minimum over reps is the cost and load only adds time. The machine was busy with other sessions' captures. Staleness is measured as before (a building's stored pose against its true one, depth counted) for the buildings **not** in the list, by distance from the pair's midpoint, now out to 29,000.

## The swing tick (own time, microseconds)

| Planet | Swing ticks | Own mean | p95 | max | List laid | Rebucket (whole match) | Median tick, swing vs outside |
|---|---|---|---|---|---|---|---|
| 7 (263 buildings) | 202 of 3,600 | **73** | 200 | 508 | 20 times, 100 each | 2.0 ms | 570 vs 511 |
| 12 (163) | 306 | **240** | 490 | 630 | 40 times, 133 each | 0.5 ms | 1,293 vs 543 |
| 21 (196) | 93 | **163** | 381 | 492 | 7 times, 156 each | 0 | 1,015 vs 505 |

- **Over 0.2 ms mean: planet 12 (0.24), near it on 21 (0.16); planet 7 is under (0.07).** The earlier 0.05 to 0.17 ms did not include the list; this does, and the list's laying (0.10 to 0.16 ms, once in 8 ticks, so about 0.02 ms a tick on average) is not what pushes planet 12 up. The worst single swing tick is 0.63 ms.
- **The swing's whole cost is more than its own tick**: the median tick during a swing is 0.06, 0.75 and 0.51 ms above the median tick outside one. The part beyond the own time (0.3 to 0.5 ms on planets 12 and 21) is code that runs differently under a swung line (field reads through the turned frame), not measured here (the matches differ, so it is unpaired).
- **Coverage is thin**: shots were in the match for 5 swing ticks (planet 12) and a sent body for 24 (planet 7), none in the others. The list's cost with many shots at once is not measured.

## Staleness of the poses not in the list (worst error, units, by distance from the pair's midpoint)

| Planet | < 4,000 | 4,000 to 8,000 | 8,000 to 16,000 | 16,000 to 29,000 | beyond |
|---|---|---|---|---|---|
| 7 | **0** | 790 | 7,778 | 9,275 | 9,654 |
| 12 | **0** | 2,786 | 3,675 | 1,315 | 7,039 |
| 21 | **0** | 712 | 0 | 1,883 | 1,929 |

Within 4,000 of the pair every building is in the list and exact. A sent body's 28,900 reach is covered by the list's body term (it is one of the pair); what is stale lies past 4,000 of both, and is read only by what Simulation says reads it (the crowd's shelter and evacuation). That claim is Simulation's; I did not trace the readers.

## Finding 1: a 2.7 s freeze at the first jolt (Simulation's `detmath.gd`)

A 900-tick run showed one tick of 2,694,488 us with the swing's own time at 2 us. Instrumenting `atBlow` statement by statement put all of it on one line: `score = ... - recency * SimDetMath.exp(-since / recencySec)` with `since = 1.0e9` when no jolt has happened yet (`_timing` has the same pattern). `SimDetMath.exp` reduces to `k = floor(x / ln 2)` and then runs `while j > k: y = y / 2.0`, here about 36 million iterations. **2.7 s native; the browser is several times that, a mid-play hang at the first heavy blow with the swing director on.** Fix, scratch-tested: `if k < -1100.0: return 0.0` after `var k` in `SimDetMath.exp` (halving a value under 2 eleven hundred times is exactly 0.0; old loop against new at 1,128 points from -3,000 to 800: 0 differ; the call now takes 5 us). The JS oracle `detmath.js` needs the same line. It does not change a value anywhere the old code returned. `exp_check.gd` is the proof.

## Finding 2: launch decisions with the swing director on cost 22 to 112 ms in one tick

With the 2.7 s fixed, planet 7 still has eight ticks of 22 to 112 ms (the bench's `HITCH` lines), planet 12 one of 41 ms, planet 21 none over 5 ms. **Every one is a launch tick** (`SWING launch ...` then `LAUNCH: ...` in the feed; two have a jolt in the same tick). With the swing director off the same bench on planet 7 has no tick over 20 ms in 3,600 and planet 12 has two (22 ms and 31 ms, launches). So the director's swing-aware launch scoring adds up to about 100 ms to a launch tick: 6 to 8 frames at 60 Hz native, several times more in the browser. Where inside it goes I did not find: wrapping the DirSwing functions with timers changed the match (the swing count fell from 202 to 115), so a localisation through wrappers is not valid; wrapping only `scored`, `candidates`, `_direction`, `_timing` and `places` kept the match and none of them took 15 ms. The suspects are the planner's reads at the 512 bake under `far()` for each candidate and `poseAll` at a launch's start; a non-wrapping timer inside `atLaunch`, `atPlanned` and `atSend` is the next cut (Encounter's or Simulation's, whichever owns the launch planner).

## Owners and what to do

1. **Simulation: the one-line `exp` fix** (and the JS oracle's). Today, bit-identical, removes a 2.7 s freeze.
2. **Encounter and Simulation: the launch-tick hitch** (22 to 112 ms) with the swing director on; reproduce with `swing_bench2.gd --mode=natural --planet=7 --ticks=3600` (it prints `HITCH` lines with the feed).
3. **Simulation: the swing tick** is acceptable (0.07 to 0.24 ms mean, 0.63 ms worst) but planet 12 is over the 0.2 ms mean; the list's laying is not the cause. Nothing to cut yet.

## Limits

Native only, one seed per planet, three planets; unpaired (the swing's total excess over a no-swing tick is read from medians of different ticks); shots and sent bodies appear in few ticks, so the list's cost under many shots is unmeasured; the machine was loaded (the minimum over two reps stands in for CPU time); the browser is several times slower than native on the script side. The localisation in finding 2 is open.

## Files

`docs/perf/tools/swing-bench/`: `swing_bench2.gd` (natural and forced modes, `HITCH` lines, end state), `hook-7-recut.mjs` (own-time counters on the re-cut `swing.gd`), `hook-8-dirswing-slow.mjs` (prints `SLOW <fn> <ms>`; **it changes the match, so do not trust it for localising**), `exp_check.gd`, `gdrun.mjs`. Raw runs in my scratch folder.
