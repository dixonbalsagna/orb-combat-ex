# The Anti-hero's red against the saturated-red test

Owner: Art Director. 2026-10-17. For the EP's brief (his dark-red clothing pools into a red flash in the ring of five). **Sheet:** `art/concepts/looks/red-shade.svg` (concept art, kept on this PC; a copy for Orb is in `homework/fighters/`). Regenerate: `node art/concepts/looks/gen-red-shade.mjs`.

## The test, and what fails
A state is saturated red when R/(R+G+B) is 0.8 or more, on stored or on linear values (`docs/tools/flash-check.md`; the analyser, `tools/flash/wcag.js`, is the authority). Rendering shades a fighter by `flat_shade` (x0.65 to x1.0 of linear light) under each sky key's world light, so the worst share is taken over that band and over all five keys on the bodies layer.

| Part | Today | Worst share (linear / stored) | |
|---|---|---|---|
| Clothing (`RenderLook.CAPE`, the villain's `gear`) | #7a1414 | 0.94 / 0.80 (sunset, x0.65) | **red**; its x0.65 step is #640e0e, the EP's "about 104,8,8" |
| Body (`data/fighters/RIVAL/fighter.json` `col`) | #a52a2a | 0.91 / 0.70 (sunset, x1.0) | **red on linear values** |

## Two shades that keep his look and pass
Nearest colours (within 4 L* of today's lightness) whose worst share stays at 0.775 or less on both counts, in two families:

| Part | Brick (red-brown, nearest) | Wine (leans plum, safest) |
|---|---|---|
| Clothing | #6f342c: 0.76 / 0.57, 7.7 CIEDE2000 from today | #752c38: 0.77 / 0.58, 10.7 from today |
| Body | #974440: 0.77 / 0.57, 6.3 from today | #a04050: 0.77 / 0.56, 10.2 from today |

Art's recommendation: **brick for the body and wine for the clothing**: the body stays his red-brown, and the coat takes the plum edge, so the two pieces read as two materials and the coat is the one furthest from saturated red. Orb picks (`homework/fighters/PICK-forms-and-rewards.md`, question 1).

## Who changes what after the pick
- **Rendering:** `RenderLook.CAPE` in `render/core/look.gd` (the clothing).
- **Simulation:** `col` in `data/fighters/RIVAL/fighter.json`. **Risk:** `sim/core/roster.js` and the golden files carry the string "s:#a52a2a" (the legacy VORR oracle), so a change of body colour may move a hashed field; Simulation to judge before the colour moves.
- **Art (mine, prepared after the pick, for the EP to commit together):** `data/art/colour-vision.json` (the rival's default `col` and the three presets) and `DEFAULT_LANES` in the colour-vision search. The Anti-hero's *aura* lane (violet) is not a red and is untouched.
- **Tools:** run the flash analyser on the red-heavy clips (the ring of five) after Rendering lands it; the numbers above are a prediction, not a measurement.

## Limits
The share is computed from the colour and the five keys' tints and shade band; it does not see bloom, the lit-window pass or a mid-flash blend of two sprites. The analyser's verdict on the real clip decides.
