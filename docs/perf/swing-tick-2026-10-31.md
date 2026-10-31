# The swing tick, benched (Performance and Platform, 2026-10-31)

For the EP, on Simulation's `docs/architecture/pending/field-frame` (the turntable). Question: Simulation read about 0.25 ms a swing tick on a loaded machine, against a 0.2 ms budget, "not a valid measure". Is it over?

## Result

- **Yes, over, and by more than the rough run said.** On the arena stack in a scratch tree, the swing tick's own time is **0.18 to 0.73 ms mean and 1.0 to 1.8 ms at p95**, and a frame with a swing in it costs **0.2 to 0.9 ms more than the same frame without** (p95 1.1 to 2.2 ms). The 0.25 ms was a mean of a skewed spread.
- **One cause: `WorldStructures.buildIndex`.** A building crossing a 300-unit bucket makes `SimSwing._poses` rebuild the whole building index (128 arrays and 246 appends): **about 1.0 ms each, on 27 of 48 ticks of a 30 degree launch swing.** That is 55 to 95% of the tick (90% of a launch's). Everything else together (the poses, the sweep limit, the rise backstop) is about 0.14 ms a tick.
- **The fix is small and the result is identical.** Move only the buildings that crossed, copying the two buckets they touch (the outer array is copied once, so a snapshot's shared buckets are never written). Measured on the same ticks: **own time 0.10 to 0.26 ms mean, 0.15 to 0.54 p95; a swing frame adds 0.14 to 0.38 mean, 0.29 to 1.03 p95.** The index equalled a full `buildIndex` after **every tick of every run, 11,550 of 11,550** (planets 7, 1 and 3; the swing cases and the no-swing ones; 5 reps).
- **With the fix it passes the 0.2 ms own-time budget on planets 7 and 1 (mean 0.10 to 0.14) and misses it on planet 3 (0.20 to 0.26)**, where 56 to 61 buildings are posed a tick against 20 to 28. Planet 3 is the second cut below.

## Method (valid under the rule of 2026-10-12)

Scratch tree: HEAD d9c48a5e, World's `gen3-field` 01 to 03, then `field-frame/install.py` (it installed without `right-word`). Timers added only in the scratch tree (`hook-1`, `hook-2`). `planetGen 3`, an AI match, a swing asked at tick 300, 110 ticks timed with `Time.get_ticks_usec` around `SimCore.step` and around `SimSwing.tick`. Cases: standing fighters with a 30 degree launch, a 10 degree brawl, an 8 degree blow; fighters in the air (y 3000) with a 60 degree launch and a 30 degree chase. **The baseline is the same match to the same tick with no swing**, so each swing tick is paired with the no-swing tick at its index.

**Load is handled by the match being deterministic: the work in a tick is identical in every run, so load only adds time and the per-tick minimum over 5 reps is the cost.** Machine load was 43 to 70% (three Godot jobs in parallel, below-normal priority), not saturated; the minimum, not the mean, is reported. CPU time is not readable from GDScript, so the minimum of wall time stands in for it. Native, GDScript, warm (the 512 bake and the 128 nodes already read). Planets 7, 1 and 3.

| Before the fix | Planet | Own mean | Own p95 | Frame adds, mean | Frame adds, p95 |
|---|---|---|---|---|---|
| 30 deg launch, standing | 7 / 1 / 3 | 0.66 / 0.40 / 0.72 | 1.4 / 0.9 / 1.7 | 0.78 / 0.47 / 0.86 | 1.7 / 1.1 / 1.9 |
| 10 deg brawl, standing | 7 / 1 / 3 | 0.18 / 0.18 / 0.37 | 1.0 / 1.0 / 1.3 | 0.22 / 0.23 / 0.45 | 1.1 / 1.1 / 1.4 |
| 8 deg blow, standing | 7 / 1 / 3 | 0.37 / 0.28 / 0.54 | 1.3 / 1.1 / 1.8 | 0.49 / 0.40 / 0.69 | 1.5 / 1.3 / 2.2 |
| 60 deg launch, in the air | 7 / 1 / 3 | 0.73 / 0.48 / 0.71 | 1.4 / 1.0 / 1.6 | 0.85 / 0.57 / 0.81 | 1.7 / 1.2 / 1.9 |
| 30 deg chase, in the air | 7 / 1 / 3 | 0.54 / 0.46 / 0.71 | 1.4 / 1.1 / 1.8 | 0.65 / 0.56 / 0.85 | 1.7 / 1.3 / 2.0 |

| After the fix | Planet | Own mean | Own p95 | Frame adds, mean | Frame adds, p95 |
|---|---|---|---|---|---|
| 30 deg launch, standing | 7 / 1 / 3 | 0.11 / 0.12 / 0.23 | 0.16 / 0.22 / 0.49 | 0.16 / 0.18 / 0.30 | 0.32 / 0.39 / 1.03 |
| 10 deg brawl, standing | 7 / 1 / 3 | 0.11 / 0.11 / 0.24 | 0.18 / 0.15 / 0.51 | 0.20 / 0.14 / 0.33 | 0.42 / 0.30 / 0.93 |
| 8 deg blow, standing | 7 / 1 / 3 | 0.13 / 0.10 / 0.20 | 0.18 / 0.16 / 0.39 | 0.25 / 0.14 / 0.25 | 0.41 / 0.29 / 0.55 |
| 60 deg launch, in the air | 7 / 1 / 3 | 0.12 / 0.11 / 0.26 | 0.18 / 0.18 / 0.54 | 0.16 / 0.17 / 0.38 | 0.32 / 0.37 / 0.88 |
| 30 deg chase, in the air | 7 / 1 / 3 | 0.14 / 0.12 / 0.22 | 0.19 / 0.16 / 0.43 | 0.20 / 0.18 / 0.27 | 0.33 / 0.37 / 0.71 |

("Frame adds" is the whole `SimCore.step` against the no-swing step, so it includes the 3 to 5 column reads the new frame forces elsewhere in the tick, about 0.05 ms.) A first, cold swing in a process reads the same within 20% (planet 7, one rep: own 0.11 to 0.16 mean after the fix).

**Where the 0.7 ms went (planet 7, 30 degree launch, 48 swing ticks, before the fix):** index rebuilds 28.6 ms total (27 of them, 1.06 ms each), poses 5.1 ms (1,170 poses, 4.4 µs each), the sweep limit 0.5 ms, the rise backstop 0.9 ms. After: poses 4.9 ms, limit 0.4, backstop 0.7; rebuilds 0.

## The fix, for Simulation (`sim/core/swing.gd`, `_poses`)

Where the loop now sets `moved = true` on a crossing, and `WorldStructures.buildIndex(S)` follows, put:

```gdscript
		var k0: int = mini(int(SimWrap.wrap(x0) / bw), buckets - 1)
		var k1: int = mini(int(SimWrap.wrap(SimField.sx) / bw), buckets - 1)
		if k0 != k1:
			if not moved:
				S.bIdx = S.bIdx.duplicate()   # the outer array only: the index is shared by snapshots, so no bucket is written in place
				moved = true
			_rebucket(S, i, k0, k1)
```

and no `buildIndex` call after the loop; with

```gdscript
static func _rebucket(S: SimState, i: int, k0: int, k1: int) -> void:
	var a: PackedInt32Array = S.bIdx[k0].duplicate()
	var p: int = a.find(i)
	if p >= 0:
		a.remove_at(p)
	S.bIdx[k0] = a
	var b: PackedInt32Array = S.bIdx[k1].duplicate()
	b.insert(b.bsearch(i), i)
	S.bIdx[k1] = b
```

A bucket stays in ascending index order, as `buildIndex` makes it, so `near()` returns the same list in the same order. `hook-4-incremental-index.py` is this edit exactly as benched (it keeps a switch, `SimSwing.incr`, for the A/B; drop the switch to land it). **The bench's check compared the index with a full rebuild after every tick: 0 of 11,550 differ.** It has not been through `frame_check`, `two_states`, `rollback_check` or the golden: those are Simulation's gates and the rollback one matters here (shared buckets), so the park should run them on the cut.

## Second cut: the pose reach, benched (added the same evening)

`POSE_REACH` is 15,000 units on a ring 38,400 around, so a swing tick poses 20 to 28 buildings on planets 7 and 1 and 56 to 61 on planet 3, at 3.6 to 4.4 µs each. With the index fix on, I benched narrower reaches two ways: the strip test the park uses (`WorldStructures.near(S, px, reach)`) and a **planet-distance test** (buildings within `reach` of the pivot by great-circle distance, from their planet points; a turn about the pivot keeps that distance, so the set is the same all swing long and is laid again each 500 units the pivot moves, one pass over the 246 buildings). Own time of a 30 degree launch swing, standing fighters, best of 5 (planet 3) or 3 (planets 7, 1), mean / p95 in ms:

| Reach | Planet 3, strip test | Planet 3, planet-distance | Planet 7, strip / planet-distance | Planet 1, planet-distance |
|---|---|---|---|---|
| 15,000 (now) | 0.30 / 0.55 | | 0.17 / 0.19 | 0.12 / 0.22 |
| 8,000 | 0.26 / 0.44 | 0.23 / 0.38 | | |
| 6,000 | | 0.17 / 0.29 | 0.06 / 0.07 | 0.05 / 0.07 |
| 4,000 | 0.14 / 0.24 | 0.11 / 0.18 | 0.06 / 0.07 | 0.05 / 0.07 |

A swing frame's total add on planet 3 (mean / p95): 0.42 / 1.10 at 15,000, then with the planet-distance test 0.34 / 0.77 at 8,000, 0.28 / 0.70 at 6,000, **0.22 / 0.52 at 4,000**. **A reach of 6,000 by planet distance passes the 0.2 ms own-time budget on all three planets (0.05 to 0.17); 4,000 passes with room.**

**What a narrow reach leaves wrong.** A building outside the reach keeps its old pose until the swing rests. The bench measured, every swing tick, the worst error of any building by its true distance from the fighters' midpoint (depth counted, since the fight is on the plane): **at reaches of 4,000, 6,000 and 8,000 (either test) every building within 4,000 of the fighters was exact on every tick, and at 8,000 and 15,000 every building within 8,000.** Beyond the reach the poses are stale by up to 10,300 units on planet 3 (8,850 on planet 7, none on planet 1) between 4,000 and 8,000 out, and up to 29,600 to 32,700 far round the planet. So the reach has to be **the largest distance at which anything reads a pose during a swing: the camera's view half-width (buildings drawn from `S.bX`/`S.bZ` would visibly lag), a launch's sweep, a beam (a beam rests the swing, so likely none).** That figure is Camera's and Rendering's to name; I did not measure it. (An earlier version of this check left depth out and showed large errors at 4,000; those were buildings in the background that the fight never touches, and I discarded them.)

**Recommendation.** If the view's half-width plus the fighters' drift in a swing is under about 5,000, a planet-distance reach of 6,000 is safe on the AI matches benched and cuts the tick to 0.05 to 0.17 ms; the park's constant stays a number in `data/fight/swing.json`. Simulation and Encounter decide. Not tried: the effect on the golden (the poses of buildings out of reach differ mid-swing, so any hash that reads them moves).

## What this does to the budget

Performance's swing allowance is **1 ms added to each frame at x1** (quality-range.md section 3). The script side reads about 1.4 to 1.7 times native on the web, and the x4 stand-in about 6.5 times the web's (quality-range.md 2.3b). So, by those ratios (estimates, not run): **before the fix a swing frame's p95 of 1.1 to 2.2 ms native is 1.5 to 3.7 ms on the web at x1, over the allowance, and 10 to 24 ms at x4, up to 60% of the 40 ms p95 budget, for every frame of a swing.** After the fix: 0.3 to 1.0 native, 0.4 to 1.8 web, 3 to 11 at x4. The mean is inside the allowance everywhere (0.14 to 0.38 native); **planet 3's p95 (0.7 to 1.0 native, about 1.2 to 1.8 on the web) still tests it**, which is what the reach cut below is for.

## Files

`docs/perf/tools/swing-bench/`: `swing_bench.gd` (the bench; goes in `sim/core/tools/` of a scratch tree), `hook-1-timers.py`, `hook-2-parts.py`, `hook-4-incremental-index.py`, `hook-5-reach.py`, `hook-6-planet-reach.py` (patch the scratch tree, in that order, after `install.py`), `gdrun.mjs` (runs a Godot script at below-normal priority with a time limit and writes the PID beside the output). Run: `node gdrun.mjs <tree> <out.txt> 900 res://sim/core/tools/swing_bench.gd --planet=7 --reps=5 [--incr] [--reach=N] [--planet-reach]`.

## Limits

Native only; the web and x4 figures are conversions. The stack was HEAD d9c48a5e plus the parks without `right-word` (the installer did not need it). The AI match is the only fight tried; a fight in a dense city would pose more buildings. Planet 3 is the busiest of the three I ran; the park's own four planets were not all run.
