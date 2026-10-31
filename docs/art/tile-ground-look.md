# The tiled 3D ground: look check (Art, 2026-10-31)

Brief: the EP's, for Orb's order of a playable with the swinging 3D world. A look check only; Art's other work stays parked. Seen: `docs/rendering/img/lookgate/tile-fore-tone-on-off.png`, `tile-gen3-fight.png`, `tile-gen3-first.png`, `tile-gen3-water.png` and `docs/camera/img/swing/fore-tone-look.png`. No new captures. I could not see the town pads or a tree close-up in any of them, so those two items are rules, not readings.

## The fore tone: it fits

Keep the one tone in front of the fighter plane. A near ground that is one flat colour is how a held key pose in a flash cartoon is drawn, and it is the quietest backdrop a fighter can stand against. The "off" frames (hard-toned facets and streaks, bottom row) are busier than the style guide wants anyway: they read as noise at the lens.

One tweak. Today the tone is a neutral grey in the harbour and the hillside (first and second frames), so a hillside village stands on what looks like concrete, while on plains and at the shore it takes the biome's own green and blue and looks right. So:

1. **Hue by biome.** Take the biome's shade colour from the palette (the third of its lit / mid / shade triple) and use it as the tone, at the same value. The city stays grey, as its road is. No new hexes: the data is already in `data/art/biomes.json`.
2. **At most one hard value step, not a gradient.** If the plain slab feels dead, split it once at a fixed world distance from the fighter plane: the nearer band about 8 percent darker in value, one hard edge, same hue. No soft step, no fade (ADR 0010). The step is a static edge that slides with the camera, and a small step is the kind of change the flash gate allows. Rendering must run the flash check on it; I cannot measure that from stills.
3. **No streaks or tracks in the near band.** Those lines are what failed flash. If the road wants texture, put it in the far band only.

## Worst look problems, in order

1. **The biome border is a large hard-edged triangle.** Seen in `tile-gen3-water.png`, bottom middle, a lime wedge cutting into the grey street; and in `tile-gen3-first.png`, a pale wedge on the sand. At node size one wrong-coloured triangle is a whole screen shape. *Do:* keep flat colour, and give only the border cells extra vertices, pushed sideways by seeded noise up to a third of a node, so the edge becomes a short irregular polyline. Add a one-node band in a third, in-between flat colour at the border, as the sea already does with its stepped shore. No dither (it reads as flicker) and no blend.
2. **The fore tone's hue** (above). Most of the screen, so it is second.
3. **A pad under every building.** Not visible in the stills, so this is a rule. A town on separate pads reads as toy blocks on a board. *Do:* one lot per street block, edge at the footprints plus a sidewalk, in the shade-tone family, and no more than one value step up from the road. Where a building stands alone, no pad, only a contact shadow in the keyline colour at low opacity.
4. **Trees as flat silhouettes.** At the hillside they read as a saw-tooth edge (`tile-gen3-fight.png`, top middle), which is fine far away under haze. Near the fighters it loses the lit-left, shade-right split every other prop has. *Do:* if the tile build draws one colour per tree, restore the cover's authored three tones (`cover_meshes.gd` already builds them; krummholz has its own, parked in `docs/art/pending/krummholz-scrub/`). Trees beyond about three screens stay a silhouette.

## What I would not do

No fog or blur to hide the borders, no noise texture on the ground, no per-building ground colour. Each is a look Orb has rejected (ADR 0010) or breaks the flat faceted rule.
