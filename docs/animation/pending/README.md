# Animation's parked patches

**One patch is parked (2026-10-28): `pose-drain.patch`.** Every other patch Animation has parked is on main; the patch files are in git history.

- `tick-cost` landed as 86836935 (with Tools' three `bake` schema keys, `tick_bench.gd` and its uid): the per-tick cuts and the frame-aware bake slice. Account: `docs/animation/tick-cost.md`. The EP's gate was green and the bake hash identical both ways.
- The incremental bake landed as e253f88a (with 247dc706 for `bake_check.gd`'s uid). Account: `docs/animation/incremental-bake.md`.
- The eight landed as 96944eff, with Tools' six schemas, the account docs and `docs/animation/img` (the GIFs and the look-gate set): `lunge-crouch`, `flight-locomotion`, `ground-locomotion`, `hit-reactions`, `air-recovery`, `secondary-motion`, `pop-juggle`, `ragdoll-families`. Accounts: `docs/animation/lunge-crouch.md`, `flight-locomotion.md`, `ground-locomotion.md`, `hit-reactions.md`, `air-recovery.md`, `secondary-motion.md`, `pop-juggle.md`, `ragdoll-families.md`. The EP's gate was green (self-test 9636, validate 275, `anim_check`, all 19 render gates, the bake hash identical eager and lazy).
- Earlier: the anim_check fix, the finisher styles, the grip layer and the recoil flips were applied on 2026-10-22; the eighteen patches of 2026-10-13 to 2026-10-17 in b328017b; shiver-by-weight, press-ack, struggle-dig-in, grip-stages and grip-throws before the bake. Their patch files are in git history (`git show 754afbeb:docs/animation/pending/<name>.patch`, `f53ee87c` for the last four of the eighteen).

Still open on the landed work:

- The pop park has no study scenario and no before/after GIF (the other seven have GIFs).
- The ragdoll families wait on Orb: play a build and say which families to push (the two ragdoll GIFs are in Orb's watch folder).

Next window (queued, not started):

- Encounter's cues for GD's rulings 23d (the daze's sway, the sell reactions, the rally links' poses, the turn's flip).

## Parked: `pose-drain.patch` (2026-10-28), render side only; applies on main 86836935

Account: `docs/animation/cloud-reports/2026-10-28-pose-drain.md` (in the patch; the cloud routine's report plus a rebase section). sha1 `93f8e3198aa5889623dace5612984a1280cddf7a`.

- The cloud routine's cut (`origin/cloud/animation/pose-drain`, 716aaf69), re-applied by hand on top of tick-cost: a missing-pose lookup (`pose_exists` / `pose`) searches the queued waves' text for the id and loads only the wave that holds it, instead of running the whole queue (about 20 ms natively to 1 to 3 ms). Poses identical.
- Gates on a scratch export of main plus the patch: `anim_check` 9849 checks; `bake_check` eager and lazy both 2051599411 (this PC; Linux prints 720091122); `pose_drain_bench` with a probe: `queue_runs=0`, `early_waves=1`.
- New: `render/anim/tools/pose_drain_bench.gd` and its uid (in the patch). No data or schema change.
