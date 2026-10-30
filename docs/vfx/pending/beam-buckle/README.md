# Parked: the losing beam buckles (VFX, 2026-10-23, on HEAD 6ef1e3f1)

Orb (docs/ep/vision.md, 92f860b9): "instead of thinning out, when the losing beam is being pushed closer the beam should bulge and quiver like its buckling under energetic pressure."

Re-checked 2026-10-30 on HEAD b7b7693c: both patches still apply clean, in order; `effects_check` passes with them, `validate` 282/0/0, and all render gates pass (same list as the sheet-splash park's). **Waiting on Encounter's beam-struggle park** (`docs/director/pending/beam-struggle/`), the thing that writes `Clash.mid`: no game code writes it yet, so nothing buckles until it lands. Replaces the old `beam-struggle/grant-rendering-ui.patch`, which no longer applies.

Status: **parked, not applied.** Two patches; `git apply --check` is clean in order on a fresh HEAD export.
1. `apply.patch` (VFX's files only): `render/vfx/beam_struggle.gd`, `render/vfx/shaders/beam_core.gdshaderinc`, `data/vfx/energy.json`, `tools/schemas/vfx-energy.schema.json`, `render/vfx/tools/effects_check.gd`, `docs/vfx/beam-struggle.md`. Safe alone: with no struggle (Clash.mid -1, as on main today) nothing changes.
2. `grant-rendering-ui.patch`: **NEEDS THE EP'S GRANT** (Rendering's `render/core/beam_view.gd`: the clash beams' two calls and `_beam`'s two optional parameters, one line after `set_layer`; VFX's charter keeps `render/vfx/transform_view.gd` out of reach: three lines for the loser's aura flare). It is the old `pending/beam-struggle/grant-rendering-ui.patch` re-cut, because that one no longer applies to Rendering's current `beam_view.gd`; this one replaces it.

## What the player sees
- **The loser's beam is never thinner than its own width** (the floor `lose_min`, 1). The winner's is up to 1.3 times (`push_k` 0.3, was 0.5, so the loser does not read as the thin one beside a fat one).
- **It bulges** where the push lands (up to +70% of its radius, a third of the way in from the point), **bows** between his hand and the point (up to a tenth of its length, 70 units at the most), and **quivers** (two slow travelling waves on its axis, up to 3% of its length, 24 units). It is anchored at the hand and at the meeting point.
- **It grows as he loses ground**: nothing at an even struggle, full when the point is near his own hands (eased, `lost()` 0.03, 0.22, 0.65 at the point's 0.45, 0.35, 0.2 in the check).
- **Geometry only**: vertex displacement and radius in the beam shader (`buck`, `buck2`); alpha and brightness are untouched. The look stays crisp (no blur or glow added).

## Legal's rates
The bow breathes at 0.7 Hz and the quiver's waves travel at 1.6 Hz, so a point of the beam moves at 2 Hz or slower (schema bounds `buck_bow_hz` and `buck_quiv_hz` at 2, asserted in effects_check). Under Reduce flashing or Reduced motion: half the size at 0.6 of the rate (a quiver at 0.96 Hz). It moves edges, not luminance, so it is outside fx03's brightness rule; the rates are kept inside it anyway.

## Checks (fresh HEAD export + both patches)
effects_check passes (9 new or changed lines: the loser not thinner, buckling only in the loser's beam, rates, calm form, growth with lost ground, cleared when no struggle); validate 0 errors; depth, after, pane, flash, cue and flash_reg checks pass. Flash-analyser clips not run (the flash work is paused; this moves edges only).

## Side by side
`homework/beam-struggle/5-losing-beam-buckles.gif` (private, 4 s, real speed): the same scripted struggle in two builds, the loser pushed from the middle to a fifth of the way along: left, today's (the loser's beam thins), right, this park (it swells, bows and quivers). Scratch scenario: a scripted clash held open with faked pulse and surge cues and the point moved by a smooth ramp, since Encounter's struggle is parked and Clash.mid is -1 in the game (the sim ends a clash after 1.6 s). Nothing shows in the game until the struggle lands.

## Honest limits
- Tuned by eye on that scripted scene at the game's own zoom; the sizes are data (`buck_*`), so Orb's eye can change them without code.
- The camera zooms in during a long clash, so the same units read bigger there than in the wide shot.
- Not a Legal clearance.
