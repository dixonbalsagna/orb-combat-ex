# Homework 4: two pitches before building (Rendering, 2026-10-16)

For the EP, and Art where a palette is needed. Orb's words are from `docs/ep/vision.md`, "Orb answers homework 4". Nothing here is built.

## 1. City variety up close

**What Orb sees.** The skyline "looks great". Up close the towers are "a bunch of dark grid lines". Two looks carry all the towers: `downtown` and `mid_rise` in `render/core/shapes.gd`. Both have grey walls (`#b8c0cc` to `#4a5261`) and the same dark blue-grey glass (`#2c4a63`), and both cap the contrast between pane and wall at `PATTERN_BUDGET` (0.085). Every tower is the same grid in the same two tones, and the window rows only change where damage or lit panes break them.

**What I would change, cheapest first.** All of it is in `building.gdshader` and the looks' data. There is no new geometry.

| Step | Change | Cost | Flash risk |
| --- | --- | --- | --- |
| A | **Glass that takes the sky.** A tower's glass mixes toward the sky's colour at its own height (the uniforms the building already has), so towers go warm at sunset and blue at noon. This is the biggest change for the least work. | one mix a pixel | low: it follows the sky's rate limit |
| B | **A tint per tower inside its look** (value ±8%, hue ±10° from a hash), so a street of towers is not one tone. | none to speak of | none |
| C | **Facade types** chosen per tower, each held to `PATTERN_BUDGET`: ribbon windows (horizontal bands), punched windows with spandrels, vertical fins or mullions, and a base and crown that differ from the shaft (a tall lobby storey; the top floors set back or lit). Data: a `facade` key per look and a hash to choose. | a few branches in the window code; to bench on the web build and an old laptop | medium: finer patterns flip more pixels when the camera sweeps, so each stays inside the contrast budget and is checked on Tools' full set |
| D | **Lit detail:** some lit panes warm and some cool, a lit strip at a lobby or a crown. | small | **lit windows count** (they are never dimmed): any increase in lit share is a flash change, measured before it ships |

**Needs from Art:** the palette per look (tints, glass mixes, the facade types' tones) and which facade types fit which district. My suggestion is A and B first (cheap, safe), then C with Art's palette, and D only after Orb picks from stills ("show me first" applies to lit windows).

## 2. "More dynamic damage patches on the nearby buildings"

The see-through window on the low foreground houses is right ("looks cool, felt natural"). I read the new ask as damage on the low buildings near the fight showing more, and more alive, but it can mean several things. These are the options; Orb picks one or more:

1. **The stage spreads from the hit on houses too.** Towers already show a new damage stage and a held hit's mark spreading from where they were hit (`spread_now`, `MARK_REACH`). The low houses could take the same, so a blow on a house visibly spreads cracks and holes from that point.
2. **Holes you can see into.** At stage 2 a house's wall punched through where it was hit, showing its dark inside and a ragged edge, not only cracks.
3. **Roof damage.** Missing tiles at stage 1, a sag at stage 2, half gone at stage 3.
4. **Smoke and dust** from a damaged house for a few seconds (VFX's, not mine).

My suggestion: 1 and 2 together, shown as stills and a short clip before anything ships. **Question for Orb (one line):** "Damage patches: do you mean (a) damage spreading from the hit point on the houses, (b) holes punched into their walls, (c) roof damage, (d) smoke and dust, or something else?"
