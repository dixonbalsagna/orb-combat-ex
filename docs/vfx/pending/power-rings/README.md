# Parked: the power-up's ring leaves the ground, not the body (VFX, 2026-10-19, on HEAD 09d465c0)

**Re-cut 2026-10-22 on HEAD b3a3aa74** (after the flight streaks and the struggle were applied): the ground ring's code now sits before `_flight_streaks` in shots_view.gd, and transform.gd's defaults carry the gather, dim and flash changes too (the first cut missed them and failed 'data and defaults agree'). Applied first, then beam-patterns: `git apply --check` clean in that order, effects_check passes with both (and depth, flash_reg, after, pane, flash, cue checks).

Orb (via the EP): the rings around a fighter powering up obscure him, and the big expanding ring (homework/beam-scar/4-closeup-three-moments.png, middle and right, the tier-4 break). Research's cinematic paper rec 14: the power-up is told by the environment (a ground ring, lifting debris, the aura) and released on one sharp beat. This supersedes my first cut of this park (data only), which failed effects_check's "data and defaults agree" check: it is replaced by this one.

## Apply
`git apply docs/vfx/pending/power-rings/apply.patch` (checked with `git apply --check` on a clean HEAD export). Four files, all VFX's, no grants:
- data/vfx/transform.json and the defaults in render/vfx/transform.gd (they must agree) and tools/schemas/vfx-transform.schema.json: the ring that left the chest at the break is off (`ring_alpha` 0; it was 0.7 to 4.2 body heights wide); the gather lines come from 1.4 body heights (was 2.6); the dim disc (6 heights) is off; the coloured flash disc over the body is off; new `gring_*` numbers for the ground ring
- render/vfx/shots_view.gd: `_ground_rings`: on the break one thin flat ring leaves the fighter's FEET along the ground, in his colour, behind him (0.5 to 2.6 body heights, a fifth as tall, 28 ticks, fading); the standing aura and the aura swap are as they were

## Checks
effects_check, depth_check, flash_reg_check, pane_check, flash_check pass; validate 0 errors. Side by side before and after on the Protagonist's tier-4 power-up at ticks 1240 to 1310, GIF in homework/power-rings/ (private).

## Honest limits
Not a Legal clearance (nothing added that flashes; a flash, a disc, a dim and a body ring removed; one slow flat ring added). Flash readings not re-run. Lifting debris and "full first, short after" are the existing rubble (react.gd, tier 3 and up) and the transformation's full/short/live versions: unchanged. The expanding ring around the fighters at tick 1320 in the EP's picture was this break ring; the thin ring with cross marks at the meeting point is the struggle's old beat ring, which the beam-struggle park removes.
