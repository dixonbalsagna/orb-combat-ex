# Parked: the beam struggle carried by the beams (VFX, 2026-10-19, on HEAD e1e4281b)

The EP's order (Orb's minimal-UI rule; Game Design's docs/design/minimal-hud.md; Research's readable-speed paper): the beams themselves show who pushes, the beat, the surges and the swelling meeting point; the loser's aura flares. Design, numbers and limits: docs/vfx/beam-struggle.md (inside the patch).

## Apply, in this order
1. `git apply docs/vfx/pending/beam-struggle/apply.patch`: VFX's files only (new beam_struggle.gd, the shader's waves, hub, reach, aura, energy data and schema, effects_check, the doc). Safe alone: with Clash.mid at -1 (today's sim) the beams are as they were.
2. `git apply docs/vfx/pending/beam-struggle/grant-rendering-ui.patch`: NEEDS THE EP'S GRANT. render/core/beam_view.gd (Rendering's: the clash beams' widths and one call per layer, `_beam` gets two optional parameters) and render/vfx/transform_view.gd (three lines for the loser's aura flare; VFX's charter keeps this file out of reach).
Checked with `git apply --check` on a clean HEAD export (the grant patch after the first).

## Checks (scratch build of HEAD + both patches)
effects_check passed (19 new; the old struggle-ring tests now run with the beams' own struggle off), depth_check, flash_reg_check, after_check, pane_check, flash_check, cue_check pass; validate 0 errors. Side by side before and after on a scripted struggle (homework/beam-struggle/, private).

## Honest limits
Encounter's struggle is parked, so Clash.mid is -1 in the game and nothing shows until it lands; the pictures use a scratch scenario that fakes the cues and the point. Not a Legal clearance. Flash readings not re-run. The old thin rings (beat, surge, stray, opening) are off while this is on (`struggle_marks`; set `struggle_enabled` false in the hub to bring them back).
