# 2026-10-27m: the terrain's fragment on the Radeon, a probe (Rendering)

**Not a park to land.** These are the scratch tools and one round of numbers for the EP's coast item b, the weak-tier terrain. They are kept here through the cloud move. The Radeon is on Orb's PC only, so a re-run is local.

## Files

- **`tcut_hook.py`** (applies to main 9c9251cc). It wraps each optional part of the terrain's fragment in a compile-time cut and writes one shader a cut (`render/shaders/tcut_<name>.gdshader`). The page's `?tcut=<name>` picks one.
  - The parts: the border zone, rock bands, strata, the far ladder, streets, craters and rims, cracks and rubble, the scar, the lane cue and the pair's mark, the heat's glow, the haze.
  - `all` cuts them all.
  - Apply it with Performance's pb hooks (`hook-perf`, `hook-slice`, `hook-pbiome`) on a scratch tree, then export.
- **`tcut.mjs`.** For each variant it loads the gen 2 coast (planet 7), runs it to tick 60 (the wide opening) and to tick 500 (the settled shot), pauses, and times 60 drawn frames with vsync off.
  - It uses Tools' guarded launcher with `--force_low_power_gpu`.
  - `node tcut.mjs <repo> <site> <out.json> none,all,zone,... [rounds]`
- **`tcut1.json`.** One round, 2026-10-27, on ANGLE D3D11 with the AMD Radeon. The machine was shared.

## The one round

| Variant | Wide opening, tick 60, p50 (ms) | Settled, tick 500, p50 (ms) |
| :--- | :--- | :--- |
| none, first | 18.4 | 9.7 |
| none, last | 15.0 | 10.9 |
| all cuts | 12.2 | 8.4 |
| each single cut | 14.5 to 16.0 | 8.7 to 9.7 (strata 12, an outlier) |

**What it says:**
- The noise is about ±3 ms. The same uncut shader read 18.4 and then 15.0 in one round.
- No single part stands out of the noise.
- Every optional part together is about 3 to 6 ms of the wide opening's 15 to 18. Performance cut the terrain whole for 8.5 ms (`docs/perf/coast-layer-cut-2026-10-27.md`), so about 3 to 5 ms of the terrain is the vertex shader and the bare fragment.
- The levers are therefore:
  - a cheaper variant with the optional parts off on the weak tier, look-gated;
  - and the vertex work: the ground field's reads, about 60k vertices near and 95k in a wide shot (World's density).

**To finish it:** three or more rounds on a quiet machine (the frame bench's load rule), then the vertex shader cut the same way.
