# The crater's look (Art, 2026-11-01)

Brief: the EP's, for Orb's versus-on-the-globe order. Make a crater read as a hole, not a dark band. Rendering does the drawing.

Mock-up: `docs/art/img/crater-look-mockup.png`. Left, the fight's crater as drawn now (from `docs/rendering/img/lookgate/fine-cells-before-after.png`). Right, the same frame with the crater repainted. The hill, the HUD, the fighters and the loose stones are the original pixels; only the crater is painted.

## Why it reads as a band now

The whole hole is one flat earth colour, so nothing says which side is a wall and which is a floor. It runs from corner to corner of the frame, so it looks like a stripe.

## The look, in four lines

1. **Walls in two rings.** An outer ring (shallow wall) and an inner ring (steeper, darker), one flat quad per edge of the hole, no gradient. Each quad's tone comes from which way it faces: the wall facing the light (left) takes the lit tone, the wall facing away takes the shade.
2. **Earth tones by depth.** Lit wall `#94704d`, mid `#6f4d35`, shade `#45301f` for the outer ring; one step darker for the inner ring (`#6e4d31`, `#4a3424`, `#32241a`); the floor `#2f2219` with stripes between `#2a1e16` and `#33251b`. The floor is warm brown, not near-black, so a dark-clothed fighter still reads against it.
3. **A thin lip.** A 5-pixel strip of soil `#86644a` outside only the edges that face up or left. A lip that is a line all the way round would read as an outline marker, so it stops where the edge turns away from the light.
4. **Cheap facets on the floor.** Four or five flat stripes across the floor, each a half-step lighter or darker, set at slightly different slants. No texture.

## Rules for Rendering

- Hard edges, flat colour, no fade between rings and no blur (ADR 0010).
- The lit side follows the biome's light, not a fixed left. Take the earth triples from the biome's ground colours (subsoil in `data/art/biomes.json`) rather than the hexes above where a biome has them; the hexes here are for this grey hillside.
- Depth comes from the number of rings, not a colour ramp: a deeper crater adds a ring, a wider one lengthens the walls.
- Keep the floor's darkest step lighter than the darkest fighter colour.

## Not done

This is a mock-up painted over one frame. The outline was traced from the frame's pixels, so it is not a mesh. I have not checked it against the flash gate; the wall quads are static, but Rendering should run the flash check on the two ring steps.

## Correction, 2026-11-01: the band in the still is a beam's scar, not a crater

Rendering's reading: scorch 0.42 to 0.44 over at least 1,600 units, deform 0. So there are two looks. A real crater (deform above 0) takes the walls and floor above. A scar takes the look below. Mock-up: `docs/art/img/scar-look-mockup.png` (before on the left, after on the right, same frame).

**Should it read differently from a crater?** Yes. A scar is a burn on the ground, not a hole, so it has no walls, no lit lip, no depth rings and no earth brown. Its colour is char (near-black with a cold tint, `#262021`), so no one reads it as a pit.

**Narrower?** Yes, to about 45 percent of the old band: here about 85 pixels across the line against about 190. Wide enough that a fighter stands on its edge and it still reads as the beam's width.

**Taper?** Yes, both ends, over the last quarter of its length, to a point. In this frame it ends in the lower right. Taper only changes its width; it stays on the ground for good.

**The look:**
1. A core in char `#262021`, flat stripes at slight slants (`#1f191a` to `#2b2424`), a thin edge `#3d3232` kept.
2. A singe fringe about a third wider than the core each side: the ground one value step darker (a multiply of about 28 percent, so the hill's own facets show through). No fade: it is a hard-edged flat shape.
3. A ragged outline: the width varies about 10 percent every 45 pixels, in straight segments, so it reads as a burn, not a drawn stripe.
4. No change at a form step or tier: only the biome's scar colour, taken from the biome's scorch tone, replaces `#262021`.

**What the mock-up cannot show:** the leftover hairlines near the old band's edge are painting artefacts from the repaint, not part of the look. The hill under the old band is two flat tones I chose, not the real ground.
