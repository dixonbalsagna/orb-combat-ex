# Animation's parked patches

Nothing is parked here that has not been applied. The eighteen patches of 2026-10-13 to 2026-10-17 (N bodies and the runs' look, the tenth round, Combat's pieces, homework 4 and 4b, the pulled joints and bend scans, the guard pass, the hammer's join, the ragdoll's variety, weight and out-of-plane joints, the air brake, the chain's poses, the clinch's C0 and C1, the study's scenarios) were applied by the EP in README order in b328017b; the patch files are in git history (`git show 754afbeb:docs/animation/pending/<name>.patch`, `f53ee87c` for the last four).

Accounts: `docs/animation/many-bodies-and-runs.md`, `tenth-round.md`, `combat-pieces.md`, `homework4.md`, `pulled-frames.md` and `homework4b.md`, `guard-pass.md`, `ragdoll-slices.md`, `clinch-sizing.md`.

## Parked: `fix-reach-gap-perf.patch` (2026-10-19, re-proved on e2f5d2ea 2026-10-22), 3 files, render side only

- **The red `anim_check` default run** (`seed 12345 mix/snappy: a blow within reach ends 5.00 units short of the defender`): `_contact_one` measured the gap in three dimensions, and a limit-respecting arm that reaches across the depth offset ends that far short in the plane; it now measures on the plane (the sim's reach is a plane distance). `anim_check`'s allowance is 3 units (2.4 the worst on real seeds). A 5% reach slack and a bigger retreat were tried and dropped (one broke `_test_energy_reach` by a degree).
- **Perf** (`fighters_update`): the idle wing check skipped when its bones are unchanged (`WING_SIG_BONES`), `debug["slew_state"]` only under `debug_checks`, the ragdoll tier read every 12 ticks, the air brake layer's early exit, the ragdoll's out-of-plane zeroing once. `_free_arm_slew` 13.5 to 2.5 microseconds a call.
- Files: `render/anim/anim_fighter.gd`, `anim_ragdoll.gd`, `tools/anim_check.gd`. Applies on main alone, and before or after the other parks. The sim and its golden are not touched.

## Parked: `recoil-flips.patch` (2026-10-22), 11 files, apply after the three above

- Encounter's `recoil` cue (DirRecoil, `recoilFlip.enabled` false): `RenderAnim` reads `source` (skip, handspring, tuck, backflip) and `dur` and calls `AnimFighter.on_recoil`; `_recoil_layer` turns the body once, backward, about its middle (`pivot_y` 34) while the sim's bowed path carries it (`arc` 17 to 25 for the flips, on top of the sim's 60, so no body point sinks below the ground at any duration from 8 ticks: Encounter's tapped heavy sends an 8-tick backflip). Ricochets (`ricochet_wall`, `ricochet_ground`) are built for Combat's section 2 and idle until that cue sends a surface normal. `RenderAnim.recoil_flips`, `--no-recoil-flips`, and reduced motion keeps the sequence and drops the turn.
- Wave `recoil1` (prefix `rc`, 26 poses, 8 sequences): the skip, the two-handed handspring (Protagonist) and one-handed (Anti-hero), the layout backflip (Protagonist) and the compact tuck (Anti-hero), the back tuck, the wall plant and the ground plant. `data/anim/recoil.json` is a new key set: Tools' closed schema needs it.
- `_test_recoil` (turn, direction, the head down at the middle, upright at the end, the wall plant, no NaN, no limit past, the sim's x never moved), the held lint's `rc.` class, study scenarios `rc_backflip`, `rc_handspring`, `rc_wall`.

## Parked: `finisher-styles.patch` and `grip-layer.patch` (2026-10-18), in this order, render side only

- `finisher-styles.patch` (6 files): the three finisher closing poses (wave `fin1`, prefix `fn`), the study's scenarios `fs_open_palm`, `fs_held_breath` and `fs_both_roads` with a scripted camera and one colour pulse, the held lint's class for `fn.`. Account: `docs/animation/finisher-styles-motion.md`. Clips: `homework/finisher-styles-in-motion/`.
- `grip-layer.patch` (10 files): the clinch's C2 (`AnimFighter.on_hold`, `_grip_layer`, `_grip_one`, `RenderAnim.grip_layer`), the wave `cl1` (13 shared poses, prefix `cl`), `data/anim/clinch.json` (a new key set: Tools' closed schema needs it), `anim_data.gd` loading, the held lint's class for `cl.`, `_test_grip` (the spacing table: the sim holds a pair 30 to 36 units apart at every grade). Account: `docs/animation/clinch-sizing.md` section 10.
