# The beam shove: a hit on the cue `beam_shove` (VFX, 2026-11-01)

Encounter's beam-hold (`docs/director/pending/beam-hold/`): firing a beam from under the stand-off throws the other fighter back to it over 0.25 s, with no damage and no stun, and the sim raises the cue `beam_shove` on him. Its own note: "the rival just slides, in a standing pose, and nothing says a blast did it": a shock wave with no reaction. Animation does the pose. This is VFX's half, "something at the start".

## What is drawn (`beamplay.gd`, in the beam plays' own hard-edged language)
All in the **shooter's lane colour** (the blast is his), never white, gold or red, no dissolve, fade or marker, and **all of it behind the thrown fighter in depth** (`shove_back`, 60 units: the wedge and ring sit behind him and the dust is let go behind him), so nothing is ever drawn over his body, legs included (the first cut drew the ring and dust in front of his legs and Orb's rule bars that):
- **A wedge of the blast** in front of him (80 units on the shooter's side of his chest), pointing the way he is thrown: the muzzle wedge's shape, `launch`, 190 long, living 10 ticks.
- **A flat ring on the ground at his feet** where it hit (`land`, 170 across, 14 ticks), only if he is within 1.2 body heights of the ground.
- **Dust off his feet while he slides**: a puff every 2 ticks for 0.3 s (the pool's own biome dust, left behind him, going the way he came from), only while he is on the ground.
In the air: the wedge only. The look is data (`shove_on`, `shove_s`, `shove_wedge`, `shove_ring`, `shove_off`, `shove_every`, `shove_back` in the `beamplay` group's defaults); `shove_on` 0 puts the old look back.

## What it does not do
- It does not read the shove's distance: the effect is the start and the slide's dust, 0.3 s whatever the length. It reads only the cue's actor, the two fighters' positions and the ground.
- It adds no new pool or shader: wedge, ring and puffs are the existing pieces, and the caps are the existing ones.
- The pose, and the pan the split makes as the rival goes (Camera's), are not here.

## Check
`effects_check` (`_beamplay`): the wedge is in front of him, pointing the way he goes, not on him; the ring is at his feet; six puffs over the slide; the effect ends after 0.3 s; in the air the wedge only; off with `shove_on` 0.
