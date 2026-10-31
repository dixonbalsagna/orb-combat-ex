# Animation's parked patches

**Parked (2026-10-30), apply in order; each stacks on the one before.** Everything else Animation has parked is on main; the patch files are in git history.

- `lead-in-all.patch` (park 1 of 4): the lead-in for every blow of the split's Y and B pools (49 rows; the double hammer and the heel's last tick are the two exceptions, said in the account) on the three blows already reported, with a row's `arm`, `legs` and `solve` lists. Stacks on the EP's lead-in commit and on nothing else. Account: `docs/animation/lead-in.md`. Needs Tools' schema (`docs/animation/schema-drafts/anim-lead-in.schema.json`).
- `follow-through.patch` (park 2 of 4, on park 1): the handover of a mashed string's contact solve over five ticks instead of one, and each listed blow's weight carried on after the contact (`drive`, `dip`), with `--no-follow-through`. Account: `docs/animation/follow-through.md`. Needs Tools' schema (`docs/animation/schema-drafts/anim-follow-through.schema.json`).
- `stomp-posing.patch` (park 3 of 4, on park 2): the Y-mashed stomp's key poses reworked for both fighters, and the honest account of the joint-posing measure (what improved, what did not). Account: `docs/animation/joint-posing.md`.
- `solve-carry.patch` (park 4, on park 3, not needed by the stomp): the contact solve carries a listed blow's drive without taking it back (30 of 50 key sets gain; median 1.4 to 3.0 units past no drive), and the striking arm's release is rate-limited (`su_hook`, `su_plate`, `su_hammer` 53, 54 and 41 degrees a tick down to 30), switch `--no-carry-solve`; also the account of why a blend change would not help. Account: `docs/animation/solve-carry.md`. Needs the schema draft's `release_deg` (`schema-drafts/anim-follow-through.schema.json`).

- `tick-cost` landed as 86836935 (with Tools' three `bake` schema keys, `tick_bench.gd` and its uid): the per-tick cuts and the frame-aware bake slice. Account: `docs/animation/tick-cost.md`. The EP's gate was green and the bake hash identical both ways.
- `pose-drain` landed as 5d8d4978 (a missing-pose lookup loads only the wave that holds it) and the cloud's `pair_ready` cut as b7fd2250. Account: `docs/animation/cloud-reports/2026-10-28-pose-drain.md`.
- The incremental bake landed as e253f88a (with 247dc706 for `bake_check.gd`'s uid). Account: `docs/animation/incremental-bake.md`.
- The eight landed as 96944eff, with Tools' six schemas, the account docs and `docs/animation/img` (the GIFs and the look-gate set): `lunge-crouch`, `flight-locomotion`, `ground-locomotion`, `hit-reactions`, `air-recovery`, `secondary-motion`, `pop-juggle`, `ragdoll-families`. Accounts: `docs/animation/lunge-crouch.md`, `flight-locomotion.md`, `ground-locomotion.md`, `hit-reactions.md`, `air-recovery.md`, `secondary-motion.md`, `pop-juggle.md`, `ragdoll-families.md`. The EP's gate was green (self-test 9636, validate 275, `anim_check`, all 19 render gates, the bake hash identical eager and lazy).
- Earlier: the anim_check fix, the finisher styles, the grip layer and the recoil flips were applied on 2026-10-22; the eighteen patches of 2026-10-13 to 2026-10-17 in b328017b; shiver-by-weight, press-ack, struggle-dig-in, grip-stages and grip-throws before the bake. Their patch files are in git history (`git show 754afbeb:docs/animation/pending/<name>.patch`, `f53ee87c` for the last four of the eighteen).

Still open on the landed work:

- The pop park has no study scenario and no before/after GIF (the other seven have GIFs).
- The ragdoll families wait on Orb: play a build and say which families to push (the two ragdoll GIFs are in Orb's watch folder).

Next window (queued, not started):

- Encounter's cues for GD's rulings 23d (the daze's sway, the sell reactions, the rally links' poses, the turn's flip).
