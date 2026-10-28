# Cloud report: the pose_exists drain (Animation, 2026-10-28)

Brief: `docs/ep/cloud-briefs/animation-pose-drain.md`. Background: `docs/animation/incremental-bake.md`. Branch `cloud/animation/pose-drain`, based on main `c890678`.

## SUMMARY
Before this change, a lookup for a pose that wasn't loaded yet (`pose_exists` or `pose`) ran all the fighters' queued wave work while waves were still queued: about 40 wave loads plus the pick lists, ≈20 ms natively in one frame. Now it searches the text of each queued wave's poses file for the id and does not parse the files. It loads only the wave that holds the id. That wave's other poses stay queued, and an id that no queued wave holds loads nothing and is remembered. The same lookup natively now takes 1 to 3 ms, against 18 to 23 ms before. The poses are identical: `bake_check` prints hash 720091122 both eager and lazy, the same as main prints. (The brief's 2051599411 is older; main prints 720091122.)

## CHANGES
I changed no file under `art/animation/`. Every code change sits outside my owned paths, under `render/anim/`. That is the code the brief names (`AnimData.pose_exists`), and the incremental bake was changed there the same way.
- `render/anim/anim_data.gd`: added `_find_queued(id)`, which `pose_exists` and `pose` now call instead of `_drain_work()`. It searches each queued wave's poses file for `"<id>": {` and loads only a wave that matches. `_wave_text` caches each file's text, and `_load_wave` parses that cached text, so each file is still read only once. `_absent` holds ids that no queued wave contains; `ensure_fighter` clears it when it queues more work. `bake_early` counts waves loaded ahead of their turn. `_read` takes optional text that is already loaded.
- `render/anim/render_anim.gd`: the "pair bake incremental" log line now also prints how many waves were loaded early.
- `render/anim/tools/anim_check.gd`: new test `_test_pose_lookup`.
  - Static checks: no id is shared by two waves, or by a wave and `poses.json` or `keysets.json`, for poses, key sets, sequences and entries, and cues. Every wave pose is written in its file as `"id": {`.
  - Live check: two real waves are put back in the queue. Asking for a pose of the later wave loads that wave only. An unknown id loads nothing and does not run the queue. The pose loaded early is the same as the pose loaded in order.
- `render/anim/tools/pose_drain_bench.gd` (new): runs a seeded AI-vs-AI match through `main.tscn` with the incremental bake on and times every frame. `--probe=id` asks for a pose in the first frame, while the queue is still full.
- `docs/animation/cloud-reports/2026-10-28-pose-drain.md`: this report.

## Measurements
All runs are native and headless, on a shared 4-core container, so the times are noisy.

**The frame that asks.** Seed 12345, `--lazy-bake`, probe asked in the first frame of the match. Each row is 3 runs.

| Probe | Before: the lookup | Before: that frame | After: the lookup | After: that frame |
| :--- | ---: | ---: | ---: | ---: |
| `no.such.pose` (in no wave, like `gc.hold.brace_tumble` with ground poses off) | 19.7 to 23.2 ms | 32 to 35 ms | 1.9 to 2.2 ms | not the worst frame |
| `dp.cross_a.step` (depth1, in the middle of the queue) | 19.1 to 20.7 ms | 29 to 32 ms | 1.0 to 1.3 ms | not the worst frame |
| `rq.jab_fist.chamber` (rival9, near the end of the queue) | 18.2 to 20.3 ms | 28.5 to 31.8 ms | 2.2 to 3.3 ms | not the worst frame |

- Queue runs (`bake_drains`): 1 per run before, 0 after.
- Waves loaded early: 0 for the absent id, 1 for each found id.
- After the change the probe frame is no longer the match's worst frame. The worst frame is then 17 to 26 ms, at ticks 72 to 135, which is ordinary match work.
- At x4 (a phone, estimated as four times the native time) the lookup goes from 76 to 93 ms to at most about 13 ms.

**The worst single frame in a whole seeded match.** Seeds 12345 and 4, 900 ticks.
- No queue run happened in these matches, either before or after: `queue_runs=0` in every row. So in the default switches this case does not occur. It occurs when a layer asks for a pose of a queued wave, or for an id no data holds, inside the first ≈130 ticks. The probes above stand in for that case.
- Worst frame, before: 12 to 25 ms plain and 32 to 34 ms with `--intro`.
- Worst frame, after: 12 to 31 ms plain and 20 to 47 ms with `--intro`.
- The `--intro` spike is at tick 117 both before and after, and its size varies by more than 10 ms from run to run. On this machine I can't tell these figures apart.
- On-demand pose bakes: 5 (seed 12345) and 0 (seed 4), the same before and after.

## Gates
All exit 0.
- `bake_check --eager-bake`: `hash=720091122 poses=932`.
- `bake_check --lazy-bake`: `hash=720091122 poses=932`, worst single piece 10.9 ms.
- `anim_check`: `anim check passed`. This includes the new test: "missing-pose lookup: 48 waves, no shared ids; the lookup loaded one wave of two and none for an unknown id".
- The scans with `--strict`: coverage, coverage_live, guard_scan, held_scan, joint_scan and lead_scan all exit 0. Last lines are, for example, "coverage: every posed row finds its poses and there is no gap", "live coverage: every row finds its ids in what a match loads", and lead_scan's "feet leading and not a tumble 0".
- Determinism plain, plain `--lazy-bake`, `--intro`, and `--intro --lazy-bake`: `determinism passed` in all four.
- `node tools/validate.js`: "278 files checked, 0 errors, 0 warnings".
- `node tools/validate.js --self-test`: "data cases 8153".
- `node tools/lint-determinism.mjs`: "determinism lint ok".
- `npm test --prefix sim`: "all 4 stages passed". The golden is byte-identical, since no sim file changed.
- `sim/core/tools/parity.gd`: "golden check passed".
- `sim/core/tools/campaign_episode.gd`: "the two plays are the same to the bit".
- All 40 `sim/world/tools/*_check.gd`: 0 failed.
- `render/camera/tests/split_sweep.gd`: "split sweep passed" (sim hash with and without the rig equal)

## DECISIONS
- **Search the text, not the parsed file.** Parsing is the expensive part of a wave load, and pose keys are written `"id": {`, which anim_check now guards. A false match, where the id appears as a key in another wave, would only load that one wave early, which is still correct.
- **Loading a wave out of order is safe only because the waves share no ids.** I checked this for every kind of data a wave registers, and anim_check now fails if a wave ever shares one. If waves ever need overrides, the lookup would have to load the queue in order up to the matching wave instead.
- `pair_ready` (a pick list asked for early) still runs that fighter's work to the end, as before. The brief covered only the pose lookup.

## NEEDS FROM EP
- A grant for the lines in `render/anim/` listed under CHANGES, which are outside `art/animation/`.
- Please update the brief's bake_check hash to 720091122, which is what main prints.

## RISKS
- An id that is missing from every wave costs one read of the remaining queued wave files, about 2 ms natively. The files are read only once in all, because each wave's load reuses its cached text.
- The lookup depends on how the wave generator writes JSON (`"id": {`). If the generator's format changes, the anim_check test fails and says so.

## NEXT
- If the phone still shows an early hitch, do the same for `pair_ready`: build one fighter's lists from his own waves only, instead of running the queue up to them.
- Run the probes on a real phone, locally.
- No look change, so no side-by-side is needed.

## Rebased on tick-cost (Animation, local, 2026-10-28)
The cloud branch was cut from `c890678`, before `tick-cost` landed (86836935). Re-applied by hand on 86836935: the same code, three context clashes (`bake_drains`' comment and the two counters in `anim_data.gd`, the "pair bake incremental" log line in `render_anim.gd`, and the test's registration, now before `_test_tick_fast()`), no change of meaning. The log line now reads "..., N waves loaded early for a pose, N queue runs, longest piece, N slices (N over budget), drained at tick N". Nothing in `tick-cost`'s code touches the lookup; `_bake_tick` and the frame-aware slice still call `bake_pending(budget)`, which runs the queue as before.

On this PC (headless, below-normal priority, a shared machine, so read the shape and not the milliseconds), scratch export of 86836935 plus the patch:
- `anim_check` passed, 9849 checks (9828 on main plus the lookup test's 21), including "missing-pose lookup: 48 waves, no shared ids; the lookup loaded one wave of two and none for an unknown id".
- `bake_check --eager-bake` and `--lazy-bake`: both `hash=2051599411 poses=932`. The hash differs by machine (Linux 720091122, this PC 2051599411); eager equal to lazy on the same machine is the test, and it holds.
- `pose_drain_bench --lazy-bake --seeds=12345 --ticks=900 --probe=no.such.pose,rq.jab_fist.chamber`: queue 40 pieces, 405 poses at the first frame; the absent id 11.2 ms (reads the 40 queued wave files once, cold, on a loaded machine; the cloud's 1.9 to 2.2 ms was warm), the found id 2.6 ms; `queue_runs=0`, `early_waves=1`. Without the patch the same ask runs the whole queue (the cloud's 18 to 23 ms).
