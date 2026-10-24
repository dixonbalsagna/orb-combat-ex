# Animation's parked patches

The anim_check fix, the finisher styles, the grip layer and the recoil flips (parked 2026-10-19 to 2026-10-22) were applied by the EP on 2026-10-22; their patch files are in git history. The eighteen patches of 2026-10-13 to 2026-10-17 (N bodies and the runs' look, the tenth round, Combat's pieces, homework 4 and 4b, the pulled joints and bend scans, the guard pass, the hammer's join, the ragdoll's variety, weight and out-of-plane joints, the air brake, the chain's poses, the clinch's C0 and C1, the study's scenarios) were applied by the EP in README order in b328017b; the patch files are in git history (`git show 754afbeb:docs/animation/pending/<name>.patch`, `f53ee87c` for the last four).

Accounts: `docs/animation/many-bodies-and-runs.md`, `tenth-round.md`, `combat-pieces.md`, `homework4.md`, `pulled-frames.md` and `homework4b.md`, `guard-pass.md`, `ragdoll-slices.md`, `clinch-sizing.md`.

## Parked: `shiver-by-weight.patch` (2026-10-22), 4 files, render side only

Apply on main (with the recoil flips). Account: `docs/animation/shiver-by-weight.md`. Clip: `homework/shiver-by-weight/shake-before-after.gif`.

- The hit-stop's shake follows its weight: `sqrt(ticks / 8)`, 0.5 to 1.6 of the profile's `shiver` (2 ticks 0.5, 8 ticks as before, 12 ticks 1.22, 24 ticks 1.6). A blow with no stop of its own (a mash's later blows, GD section 6) shakes the struck body for 6 ticks, decaying, small for a light. `RenderAnim.shiver_by_weight`, `--no-shiver-weight` is the before.
- `render/anim/anim_fighter.gd` (the shake; `on_hit` takes the damage event's `stop`), `render/anim/render_anim.gd` (passes it, the switch), `render/anim/tools/anim_check.gd` (`_test_shake`), `render/anim/tools/flurry_study.gd` (scenario `hsw`, `window.__noshiver`).
- Not in it: the `_cue_windup` tolerance. A counter over 331 wind-up cues in AI v AI found 0 outside the 4 ticks, so there is nothing to widen.

## Parked: `press-ack.patch` (2026-10-23), 11 files, render side only; apply after `shiver-by-weight.patch`

Account: `docs/animation/press-ack.md`. Clip: `homework/press-ack/press-ack-before-after.gif`.

- The press-tick anticipation (Encounter's `press_ack` text `queued`): on the press tick the fighter commits with the first frames of the wind-up (wave `ack1`, prefix `ak`, 6 poses: a light's lean in, a heavy's weight forward, a signature's sink, one each per fighter), ramped in over 6 ticks, held for the wait, let go over 6 ticks, and handed over to the real wind-up when the exchange starts. `RenderAnim.press_ack`, `--no-press-ack`.
- `data/anim/press_ack.json` is a new key set: **Tools' closed schema needs an entry** (the request is in the account).
- Gates on a scratch export of main with the shake-by-weight park applied: `anim_check` with no arguments, the scans `--strict`, the 4-body scans, determinism plain and `--intro` all pass.

## Parked: `struggle-dig-in.patch` (2026-10-23), render side only; apply after `shiver-by-weight.patch` and `press-ack.patch`

Account: `docs/animation/struggle-dig-in.md`. Clip: `homework/struggle-dig-in/struggle-dig-in-before-after.gif`.

- The beam struggle's loser digs in (the squash pose's legs, pelvis and spine, a tremble, the drawn body dragged back along the ground, up to 9 units) and the winner leans in 2.5 units, by `S.game.clash.mid`. `RenderAnim.struggle_dig`, `--no-struggle-dig`.
- `data/anim/struggle.json` is a new key set: **Tools' closed schema needs an entry** (the request is in the account).

## Parked: `grip-stages.patch` (2026-10-23), render side only; apply after `shiver-by-weight.patch`, `press-ack.patch` and `struggle-dig-in.patch`

Account: `docs/animation/grip-stages.md`. Clip: `homework/grip-stages/grip-stages-before-after.gif`.

- The grip layer's feed from the sim's grapple (`DirGrapple.now`, the cue `grapple_pummel`): the tell's reach, the tie-up by grade as five stages (the grade eases a step at a time), the leader's set at two ahead and the cave at two behind (wave `cl2`, prefix `cs`, 2 poses), the pummel, a gentle release. `RenderAnim.grip_feed`, `--no-grip-feed`. Inert while the grapple is off.
- `data/anim/grip_feed.json` is a new key set: **Tools' closed schema needs an entry** (the request is in the account).

## Parked: `grip-throws.patch` (2026-10-23), render side only; apply after `grip-stages.patch`

Account: the throws section of `docs/animation/grip-stages.md`. Clip: `homework/grip-stages/grip-throws-before-after.gif`.

- The grapple's end as a throw: Encounter's `grapple_end` cue (`throw_across`, `thrown_up`, `thrown_down`, `reversal`) plays the thrower's own sequence from `throws.json` (the wave `pair3`, now loaded with the feed), started so the release lands on the sim's send tick; the hold lets go over 6 ticks, hands not chasing. `_test_grip_throw`.
- One key added to `data/anim/grip_feed.json` (`throw_release_ticks`): Tools' schema for that file (requested with `grip-stages`) takes it.

## Parked: `lunge-crouch.patch` (2026-10-23), render side plus one data key and its schema, apply on main

Account: `docs/animation/lunge-crouch.md`. Clip: `docs/animation/img/lunge-crouch-before-after.gif`.

- The mid-band lunge's authored wind-up crouch (light 6 ticks, heavy 10, the return's 10) drawn from Encounter's `lunge_light`, `lunge_heavy` and `return` cues on the press tick, deepening over the cue's ticks and handed to the travel over 6. `data/anim/press_ack.json` gains `lunge` and `tools/schemas/anim-press-ack.schema.json` the key (granted on Orb's word).

## Parked: `flight-locomotion.patch` (2026-10-23), render side plus a new data file; apply after `lunge-crouch.patch`

Account: `docs/animation/flight-locomotion.md`. Clip: `docs/animation/img/flight-locomotion-before-after.gif`.

- Window 1 of Orb's push: a free fighter in the air leans into acceleration on an underdamped spring (the Protagonist floaty, the Anti-hero crisp), flares and leans back on a hard stop, coils at a dash's press, banks into a curve and breathes in the hover. Read from the sim's velocity, never written; every ramp 6 ticks or more. `RenderAnim.flight_loco`, `--no-flight-loco`.
- `data/anim/locomotion.json` is a new key set: **Tools' schema `anim.locomotion/1` is needed** (the shape is in the account's schema request; granted on Orb's word).

## Parked: `ground-locomotion.patch` (2026-10-23), render side plus a new data file; apply after `flight-locomotion.patch`

Account: `docs/animation/ground-locomotion.md`. Clip: `docs/animation/img/ground-locomotion-before-after.gif`.

- Window 2 of Orb's push: a free fighter on the ground walks and runs on a gait that follows the distance he covers (thighs, knee lift, hip bob, shoulders against the pelvis), kicks off the ground when he rises and absorbs his landing by the arrival speed and the surface (sand slides and sinks, rock and paving are crisp, rubble stumbles, water wades), each fighter his own (the Protagonist long and loose, the Anti-hero short and quick). `RenderAnim.ground_loco`, `--no-ground-loco`.
- `data/anim/ground_motion.json` is a new key set: **Tools' schema `anim.ground_motion/1` is needed** (the shape is in the account; granted on Orb's word).
