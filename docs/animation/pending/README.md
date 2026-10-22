# Animation's parked patches

The anim_check fix, the finisher styles, the grip layer and the recoil flips (parked 2026-10-19 to 2026-10-22) were applied by the EP on 2026-10-22; their patch files are in git history. The eighteen patches of 2026-10-13 to 2026-10-17 (N bodies and the runs' look, the tenth round, Combat's pieces, homework 4 and 4b, the pulled joints and bend scans, the guard pass, the hammer's join, the ragdoll's variety, weight and out-of-plane joints, the air brake, the chain's poses, the clinch's C0 and C1, the study's scenarios) were applied by the EP in README order in b328017b; the patch files are in git history (`git show 754afbeb:docs/animation/pending/<name>.patch`, `f53ee87c` for the last four).

Accounts: `docs/animation/many-bodies-and-runs.md`, `tenth-round.md`, `combat-pieces.md`, `homework4.md`, `pulled-frames.md` and `homework4b.md`, `guard-pass.md`, `ragdoll-slices.md`, `clinch-sizing.md`.

## Parked: `shiver-by-weight.patch` (2026-10-22), 4 files, render side only

Apply on main (with the recoil flips). Account: `docs/animation/shiver-by-weight.md`. Clip: `homework/shiver-by-weight/shake-before-after.gif`.

- The hit-stop's shake follows its weight: `sqrt(ticks / 8)`, 0.5 to 1.6 of the profile's `shiver` (2 ticks 0.5, 8 ticks as before, 12 ticks 1.22, 24 ticks 1.6). A blow with no stop of its own (a mash's later blows, GD section 6) shakes the struck body for 6 ticks, decaying, small for a light. `RenderAnim.shiver_by_weight`, `--no-shiver-weight` is the before.
- `render/anim/anim_fighter.gd` (the shake; `on_hit` takes the damage event's `stop`), `render/anim/render_anim.gd` (passes it, the switch), `render/anim/tools/anim_check.gd` (`_test_shake`), `render/anim/tools/flurry_study.gd` (scenario `hsw`, `window.__noshiver`).
- Not in it: the `_cue_windup` tolerance. A counter over 331 wind-up cues in AI v AI found 0 outside the 4 ticks, so there is nothing to widen.
