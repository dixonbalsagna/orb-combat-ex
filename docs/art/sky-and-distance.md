# Sky and distance: an audit and a target

Owner: Art Director. 2026-10-15. For Rendering's next brief; **no render file was changed**. Orb (docs/ep/vision.md, 2026-10-15): "I want all elements of distance fog, background mountains, skies to all look fantastic and not overlapping in a strange way, in the original demo the sky and stars would appear as a close fog that obstructed view of the mountains, I want all the visuals to get tightened so the lighting can be fully appreciated when flying around the planet".

**Contact sheet:** `img/sky-and-distance-sheet.png` (42 stills). Two at full size: `img/sky-and-distance-mo-m-noo.png` (the mountains, mid altitude, noon) and `img/sky-and-distance-de-g-nig.png` (the desert at night).
**How it was taken:** main's HEAD (55b7219f), a scratch web export outside the repo with both fighters pinned at a place and an altitude (the only patch: a pin and no first-run card), the sky held at a key (`?sky=`), through `tools/machine/capture.mjs` (session art), one at a time. Biomes ocean, plains, city, forest, desert and mountains; ground, 1,800 up and 9,000 up (a fighter is about 75); noon (0.00), sunset (0.32) and night (0.58); the five biome borders at sunset; and the key blends 0.18, 0.45, 0.72 and 0.84. Where a divider shows, that is the game's split view, not a seam.

## What reads wrong

1. **The world ignores the key.** The sky goes to night and the ground does not: the sand is full-bright tan at night (`de-g-nig`), the grass and forest are the noon greens at sunset and night (`fo-g-nig`, `pl-m-nig`), the sea is noon blue at night (`oc-m-nig`), the city's facades are daylit under a night sky (`ci-g-nig`). A lit side never differs from an unlit one, so **the lighting cannot be seen at all**. This is the first and the largest fault. The fix is already specified (`docs/art/dynamic-sky.md` section 6, `data/art/sky.json` `_world_light`) and not built.
2. **The haze is a band across the screen, not a distance fog.** It is set mostly by a pixel's height against the horizon line (`fog_band`, a band 0.25 of a half screen deep, thickest at a grazing view), with distance only switching it on. So a near mountain whose upper slope crosses the horizon line is washed pale in a horizontal stripe, while the far peak beside it is not: the sky seems to sit in front of the mountains like a near fog (`mo-m-noo`, `mo-m-sun`, `mo-m-nig`, `mo-g-sun`). This is the "close fog that obstructed the mountains" of the original demo, still there.
3. **The far mountains are the wrong value.** They fade to the sky's colour at their own screen height, which above the horizon line is the upper sky. So at noon they are flat deep-blue cut-outs as dark as the sky behind them (`mo-m-noo`), or pale ghosts that melt into the clouds and read as "mountains in the sky" (`mo-g-noo`, `de-g-noo`); at night they are a faint blue shape in the dark with stars across it (`de-g-nig`). Further is not lighter, and a ridge has no edge against what is behind it.
4. **Stars are on the screen, not in the sky.** They come up with darkness and altitude, are fixed to the view, and know nothing of what stands in front. At 9,000 up they show at **noon** over a black sky (`mo-h-noo`, `pl-h-sun`); at ground level at night they are thin and far apart, and they cross the dim ridges. There is no sun and no moon, so nothing says where the light is from.
5. **The sea is a wall.** At ground and mid altitude the ocean is the same blue from the camera to the horizon, at every key, with a soft smudge for the horizon and faint lighter bands; it takes nothing from the sunset sky (`oc-g-sun`, `oc-m-sun`, `oc-m-nig`). Sea and sky have no edge between them.
6. **At altitude the planet smears.** At 9,000 up the terrain under the camera is stretched into vertical stripes and grey bars (`mo-h-noo`, `mo-h-sun`, `mo-h-nig`); the rim of light along the horizon is good. The sky is already space-black at 9,000 whatever the key, so day and night differ only by the ground, which (point 1) does not change.
7. **One blend goes green.** At 0.72 (night toward dawn) the sky turns a sickly teal-green (`tk-pre`). That one is mine: Art's horizon and lower bands on that blend take a path through green. I can fix the path in `art/concepts/sky/keys.mjs` and `data/art/sky.json` on the EP's word; Rendering needs no code change for it.
8. **What is right and stays.** The key gradients (`tk-gold`, `tk-eve`, `tk-dawn`), the clouds' lit edges, the thin atmosphere rim from space, and the city's lit windows and its dusk haze at mid altitude (`ci-m-sun`).

## The target: layers, back to front

Each layer is opaque to what is behind it, except the haze, which is a mix toward the next colour back. Nothing draws in front of a nearer layer.

| Depth (back to front) | Target | Colour and contrast |
|---|---|---|
| **1. Stars** | In the sky's own sphere (they move with the look, not the screen). They come in only where the sky is dark: from the upper band down to about 0.4 of a half screen above the horizon, **never lower**, so no star can sit on a ridge. They fade out as the sky lightens: none at noon, however high, until the sky itself is dark. | Small, pale, never white-hot; thinned by ruin as today (`SKY_RUIN_STARS`). |
| **2. Sky bands** | Art's four bands, unchanged: the keys, the blends, the mood. | The gradient of `data/art/sky.json`. |
| **3. Sun and moon** (new, small) | One flat faceted disc each, on the lap's phase: the sun low at golden and sunset, the moon at night. They key the **direction** of the world's light (warm from the sun's side, cool and dim from the moon's). No bloom, no flash. | The sun a warm pale, never white; the moon a cool grey-blue. Legal to screen. |
| **4. Clouds** | As built, but always **behind** every ridge and mountain. | Lit from the horizon as now; darker than the sky above them at night. |
| **5. Distance haze, by depth** | A function of **distance**, not screen height. None inside about 1,500 units; from 1,500 to 6,000 a mix of 20 to 45 percent toward the *horizon band's* colour; from 6,000 to the far edge 70 to 90 percent toward it. The band along the horizon line keeps only a **thin glow right at the line**. | Aerial perspective: further is lighter and less saturated, and tends to the horizon band (not to the upper sky). |
| **6. Far mountains** | A **value ladder**: each ridge is 6 to 10 percent lighter and less saturated than the one in front of it. Against the sky behind: at noon the farthest ridge is no more than about 60 percent as bright as the horizon band; at sunset a **silhouette** at least 1.6 to 1 against the glow (a warm rim on the sunward edge); at night darker than the horizon band by about 0.6, with a cool rim. A ridge never reaches the colour of the sky above the horizon band. | A ridge reads against the sky at every key by value, not by hue. |
| **7. Near terrain and structures** | The fight's own ground, the slopes beside it and the buildings take the **world light**: the multiply tint per layer (`_world_light`), with the sun's side lighter and the other side cooler. No haze inside 1,500 units, so the horizon-line stripe never lies across a near slope. | Night: ground about 0.1 of noon in value with a cool lift; golden: sand warmed. Fighters, auras and lane colours never dim. |
| **8. Water** | The sea takes the sky: lighter and tinted by the horizon band toward the horizon, deepest under the camera, with a **visible horizon line** (one clear step between sea and sky). Sunset warms it, night darkens it. | At the horizon the sea is within 10 percent of the horizon band's value but a step darker than the sky above it. |

## Order of work (the brief for Rendering)

1. **World light** (point 1): the biggest change to how the lighting reads, specified and waiting. Sun and moon come after it, to give it a direction.
2. **Haze by depth** (point 2): one change in `ground_fog` (`render/shaders/skycol.gdshaderinc`) removes the stripe and the near fog.
3. **The far-mountain ladder** (point 3) follows from 2 with the horizon colour as the fog's target.
4. **Stars** (point 4): a latitude fade and a darkness gate.
5. **The sea's sky** (point 5), then **the altitude smear** (point 6).

**For Orb to judge in motion,** not in stills (he has said stills are not enough for light): one flight round the planet from plains at golden hour, through the mountains, to the sea at night, after 1 and 2 only. That is the cheapest picture that shows whether the lighting can be "fully appreciated".

## Limits of the audit

- The stills pin the fighters, so the camera's own motion (the pan haze, the zoom) is not seen. The audit says nothing of how any of this looks while travelling fast.
- Altitudes between 1,800 and 9,000 were not sampled: the change to space is somewhere between them and may be a step.
- The numbers in the target table are Art's starting values, to be tuned by eye in the build.
- The first-run notice and card were suppressed in the scratch export only.
