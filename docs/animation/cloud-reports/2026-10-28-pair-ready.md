# Cloud report: pair_ready from a fighter's own waves (Animation, 2026-10-28)

Brief: `docs/ep/cloud-briefs/animation-pair-ready.md`. Follows NEXT 1 of `2026-10-28-pose-drain.md`. Branch `cloud/animation/pair-ready`, based on main `31ae23e`.

## SUMMARY
Before this change, when a blow asked for a fighter's pick lists before the match-start queue had built them (`AnimData.pair_ready`), the queue was run in order up to his lists. For the antihero, who is queued second, that is the whole queue: the protagonist's waves and lists, then his own. Now only his own waves that are still queued are loaded, his lists are built, and his "lists" item is taken out of the queue. The other fighter's work stays queued in order. When the queue reaches the waves that were loaded early, it skips them, as `_wave_once` already did. The lists and the poses do not change: anim_check compares the early lists with the in-order ones, and `bake_check` prints 720091122 both eager and lazy. In seed 12345 the ask drops from 28 to 39 ms to 17 to 23 ms natively, and the worst frame of the first 300 ticks drops from 40 to 51 ms to 29 to 41 ms. The count of on-demand bakes does not change.

## CHANGES
I changed no file under `art/animation/`. Every line below is outside my owned paths, in `render/anim/`, which is where the pose-drain fix went too:
- `render/anim/anim_data.gd`, `pair_ready`: finds the fighter's own `lists` item in `_work`, removes it, loads the waves it names that are not done yet, and builds his lists. `--pair-ready-queue` switches back to the old version, which runs the queue up to his lists. It is kept for the bench. New counters: `pair_own`, `pair_runs` (asks that came before the queue reached his lists), `pair_early_waves` and `pair_run_worst_us`.
- `render/anim/render_anim.gd`: the "pair bake incremental" log line also prints "N pick lists asked early (N waves loaded for them)".
- `render/anim/tools/anim_check.gd`: new test `_test_pair_ready`.
  - Static check, for each of the three fighters: a manifest strike counts as a key set when only his own waves and `keysets.json` are loaded exactly when it counts as one with every wave loaded. So his lists cannot depend on the other fighter's waves.
  - Live check: one wave of each fighter goes back in the queue (`protag1`, then `rival1`), with the two fighters' list items. Asking for the antihero's lists loads `rival1` only, does not build the protagonist's lists, and leaves the protagonist's wave and lists queued in order. The antihero's lists match the in-order build exactly (JSON). Running the queue to the end then builds the protagonist's lists exactly as in order.
- `render/anim/tools/pose_drain_bench.gd`: prints `pair_asks`, `pair_early_waves`, `pair_ask_worst_ms` and `first_s_worst_ms` (the worst frame of the first `--first=300` ticks). It passes `--pair-ready-queue` through for the "before" runs.
- `docs/animation/cloud-reports/2026-10-28-pair-ready.md`: this report.

## Measurements
All runs are native and headless on a shared 4-core container, so the times are noisy. "Before" is `--pair-ready-queue` on the same tree. I alternated the before and after runs. Command: `pose_drain_bench.gd -- --lazy-bake --seeds=12345,4 --ticks=300 [--pair-ready-queue]`, 5 runs each.

| seed 12345 | before | after |
| :--- | ---: | ---: |
| early asks (`pair_asks`) | 1 (antihero, tick 72, runs all 40 pieces) | 2 (antihero 19 waves, then protagonist 9) |
| the longest ask | 27.8 to 38.8 ms (median 30.8) | 17.2 to 23.3 ms (median 18.1) |
| worst frame, first 300 ticks | 40.4 to 51.3 ms (median 44.4) | 29.4 to 41.4 ms (median 31.9) |
| on-demand pose bakes | 69 | 69 |

- **Seed 4:** no early ask in either version. The worst frame was 20 to 28 ms before and 22 to 42 ms after, with no ask in it, so the difference is noise. There were 36 on-demand bakes both times.
- **With `--intro`, 900 ticks, 3 runs each:** the ask comes after the intro, at about tick 372 in seed 12345. It took 28.7 to 44.7 ms before and 17.3 to 28.8 ms after. On-demand bakes were 138 (seed 12345) and 49 (seed 4) in both versions.
- **Plain, 900 ticks:** on-demand bakes were 151 and 49, the same before and after.
- **Why the ask is still about 18 ms:** the antihero's own waves are 19 wave loads, and parsing them is most of the cost. His `wave1.poses.json` alone is 48 KB. The protagonist's later ask (9 waves) takes about 16 ms, in a different frame.
- **At x4 (a phone, estimated):** the antihero's ask goes from about 120 ms to about 72 ms.

## Gates
All exit 0.
- `anim_check`: "anim check passed", including "pair_ready: 3 fighters read only their own key sets; the early ask loaded one wave of two and left the other fighter queued" and the lookup test's "missing-pose lookup: 48 waves, no shared ids; …".
- The scans with `--strict`:
  - coverage: "coverage: every posed row finds its poses and there is no gap"
  - coverage_live: "live coverage: every row finds its ids in what a match loads"
  - guard_scan: "guard scan: 149 (key, free hand) rows, 0 over their goal …"
  - held_scan, joint_scan: exit 0
  - lead_scan: "… feet leading and not a tumble 0, braking in the air (exempt) 0"
- `render/tools/determinism.gd`: "determinism passed" in all four runs (plain, `--lazy-bake`, `--intro`, `--intro --lazy-bake`).
- `bake_check --eager-bake`: `BAKECHECK lazy=false hash=720091122 poses=932 …`.
- `bake_check --lazy-bake`: `BAKECHECK lazy=true hash=720091122 poses=932 … worst_single_ms=18.13`.
- `tick_bench`: "TICKBENCH poses IDENTICAL".
- `node tools/validate.js`: "278 files checked, 0 errors, 0 warnings".
- `node tools/validate.js --self-test`: "… schemas 170; data cases 8177".
- `node tools/lint-determinism.mjs`: "determinism lint ok: …".
- `npm test --prefix sim`: "all 4 stages passed". No sim file changed, so the golden is byte-identical.
- `sim/core/tools/parity.gd`: "golden check passed".
- `sim/core/tools/campaign_episode.gd`: "campaign_episode: the two plays are the same to the bit …".
- `render/camera/tests/split_sweep.gd`: "split sweep passed".
- All 40 `sim/world/tools/*_check.gd`: 40 of 40 exit 0.

## DECISIONS
- **Only his own work runs.** The antihero's ask no longer runs the protagonist's waves. When the protagonist's lists are then asked for, his ask comes in a later frame. That is two shorter asks instead of one long one.
- **A queued wave loaded early stays in the queue.** Its turn does nothing (`_wave_once` checks `_waves_done`), so the queue's order and the bake order of everything else stay as they were.
- **The old path stays behind `--pair-ready-queue`,** for the bench only, as `--no-tick-fast` was kept for tick_bench.

## NEEDS FROM EP
- A grant for the lines in `render/anim/` listed under CHANGES, which are outside `art/animation/`.

## RISKS
- If a fighter's manifest ever names a key set that is defined only in the other fighter's waves, the early lists would leave that strike out. The new anim_check test fails in that case and names the strike.
- The ask still loads a fighter's whole remaining wave set in one frame. On a phone that is still one long frame, about 70 ms at x4.

## NEXT
- To cut the ask further: queue each fighter's lists right after his own strike and entry waves, before his `more` waves, so that the queue usually has them built by tick 72. Or build the lists from the manifests and the key-set files alone, and load the poses later. Both change the queue's order, so they need the bake hash and the lists compared again.
- Run the bench on a real phone, locally.
- No look change, so no side-by-side is needed.
