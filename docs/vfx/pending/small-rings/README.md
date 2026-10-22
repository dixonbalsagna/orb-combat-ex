# Parked: every ring round a fighter hugs the contact point, small (VFX, 2026-10-22, on HEAD 3b5c657e)

Orb's rule via the EP: hug the contact point small, or remove it. Three instances, one root: the sim itself emits `ring` events (the power-up's at 1,300 units a second, a launch's white ring at 600, a landing's at 700: rings of two to ten body heights), and the reference consumer draws them. Those, not only VFX's own marks, were the big blue ring (a) and the white ring round the launched body (c).

## Apply (after power-rings and beam-patterns; the three apply in that order, `git apply --check` clean, effects_check passes with all three)
`git apply docs/vfx/pending/small-rings/apply.patch`. Six VFX files, no grants:
- render/vfx/vfx_hub.gd: `reference_events` hands the reference consumer COPIES of the sim's `ring` events with their growth cut to 0.12 of it (at most 80 units a second) and their start radius capped at 12: a small ring at the point it happened, about a body across at most. The sim's own events are untouched (audio and the hash read the originals). `hub.rings_small_enabled` (on) turns it off.
- (b) the pale arc round the fighters in AI matches is the standing aura's outline, a tall ellipse a body away from him: transform.json and transform.gd's defaults now give it 0.7 to 1.0 body heights wide and 1.12 to 1.4 tall by tier (was 1.0 to 1.7 by 1.45 to 1.9), so it hugs the body.
- (c, VFX's own) press.gd: the contact ring 40 to 18 units, the wind-up ring 34 to 22, the speed ring 20 to 14; shots_view.gd: the energy landing's crack 34/56 to 20/30 and its ring 20/36 to 10/16.
- effects_check.gd: `_small_rings_check` (the 1,300 a second ring ends under a body and a half; the originals untouched; the switch works).

## Checks
effects_check, depth_check, flash_reg_check, after_check, pane_check, flash_check, cue_check pass; validate 0 errors. Side by side before and after on the launch (launchai scenario, ticks 1 to 60) and the AI match's tier-4 power-up (ticks 1240 to 1330), GIFs in homework/small-rings/ (private).

## Honest limits
Not a Legal clearance (smaller rings only). Flash readings not re-run. Rendering's own particle ring is the same one that draws these: no Rendering file is touched. The standing aura here is the old flat outline; the aura rework (aura3d) is separate.
