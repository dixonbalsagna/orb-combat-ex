# Parked: VFX's ground marks follow the ring's turn (VFX, 2026-10-22)

The EP's brief: at `arena_turn {n, x (the pivot), amount, k}` the sim drops its marks beyond x plus or minus 12,000 units and Rendering fades its crater heat across the zone; VFX's ground and building marks outside the zone go on the same tick, and inside they fade as World's do. Built and proved in scratch on HEAD plus World's window 3 (`docs/world/scratch-build/calm-turn/calm-turn-window3.diff`, without contact.gd) plus Rendering's 2026-10-22d (`batch.diff`); the patch itself touches only VFX's files and also applies and passes on plain HEAD (it reads the event by name, nothing else of the window).

## Apply
`git apply docs/vfx/pending/arena-turn/apply.patch` (after window 3 and 22d, or without them: it is inert until an `arena_turn` event exists). Five VFX files: vfx_hub.gd (`_arena_turn`, `turn_weight`, `TURN_CARRY`), beam_scar.gd and scar_view.gd, hole_view.gd, effects_check.gd (`_arena_turn_check`, 8 checks).

## What happens at the turn, by mark
The share kept `w` is World's own shape: 1 in the inner quarter of the zone, a smooth fall to 0 at its edge (`turn_weight(d)`; `carry` may be put on the event, a test's small zone; the default is 12,000).
- **Beam scars:** gone beyond the zone; inside, the width is scaled by `w` (a scar is geometry, so it narrows and never fades); under a tenth of its width it goes. A scar the turn dropped is not made again by a beam that is still alive.
- **Facade holes:** gone beyond the zone; inside, the opacity is `w` (the hole shader's COLOR.a).
- **Ground cracks:** gone beyond the zone, kept inside while `w` is over a third and gone below it: a crack set is one mesh with no opacity of its own, so it cannot fade (an honest limit; a fade would need a per-set material).
- **Energy scorches** (reach.gd) and **resting debris** (chunks, embers, puffs of the debris pool): gone beyond the zone at once.
- **Building smoke** (the shells' puff clock, keyed by building index): cleared, since the buildings are laid again.
- Not touched: the view-anchored dust curtains (the tremor) and the blast cloud, which are not anchored to the ground that goes.

## Checked
effects_check passes (8 new checks: the weight's shape; holes, crack sets, scars, debris inside and outside a small zone; the event handled on its own tick; nothing changes without it), validate 0 errors. A still before and after a turn: a scratch scenario injects an `arena_turn` whose zone is far from the pair while a beam's scar stands (the shipped `signature` scene, ticks 258 and 266): the scar is there before and gone after (homework/arena-turn/, private: fighters in the picture).

## Honest limits
The sim does not emit the event until window 3 lands, so the live proof is the injected event, not a real turn. Cracks do not fade across the zone, they stay or go. Not a Legal clearance (nothing is added; marks are removed). Flash readings not re-run.
