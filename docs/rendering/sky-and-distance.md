# Sky, fog and mountains: Rendering's pass

Orb (docs/ep/vision.md, 2026-10-15): "I want all elements of distance fog, background mountains, skies to all look fantastic and not overlapping in a strange way, in the original demo the sky and stars would appear as a close fog that obstructed view of the mountains, I want all the visuals to get tightened so the lighting can be fully appreciated when flying around the planet". Art's audit and target: `docs/art/sky-and-distance.md`. World's backdrop: `docs/world/backdrop.md`.

## What landed (2026-10-16)

- **Haze by depth** (Art's point 2, layer 5; `RenderLook.HAZE_*`, `haze_parts` and `haze_ground` in `render/shaders/skycol.gdshaderinc`). The ground and the water haze by their depth behind the fighter plane, not by their height on the screen: none inside 1,500 (the fight's own ground and all in front of it), 20% by 2,500, 45% by 6,000, 80% by 40,000, eased between, the depths stretched as the camera climbs. A thin glow lies right at the horizon line beyond 2,500. The last eighth before the far edge still fades into the sky, so the ground's end never shows. The old band set by screen height (`fog_band`, `FOG_BAND`, `FOG_NEAR`) is gone: it was what laid the sky over a near mountain like a close fog.
  - **Measured from the plane, not the camera.** A first version measured from the camera; the camera stands about 2,700 in front of the fight, so the fight's own ground took a fifth of the haze and golden-hour plains read milky from mid height.
- **The far mountains' value ladder** (Art's point 3, layer 6; `HAZE_VALUE` 0.6, `HAZE_SAT` 0.7). The ground hazes toward the horizon band's colour taken down to 60% of its value and 70% of its saturation. Each ridge further back is lighter and greyer than the one in front, and none reaches the colour of the sky behind it: at noon the mountains are grey against a brighter horizon (they were white cut-outs or deep-blue ones), at sunset a silhouette against the glow, at night a dark shape under the band.
- **The far field hazes into the sky** (2026-10-19, `HAZE_SKY` 1.0). After Orb's playtest the far ridge read as a huge brown wall: the ladder above holds a ridge off the sky's colour however far it is, and d3f1ca0e's far land had faded into the sky in its own direction. So between `HAZE_AT[2]` and `HAZE_AT[3]` (6,000 to 40,000) the haze's target moves from the ladder's colour toward the sky's colour in that direction. Far peaks come back as faint silhouettes in the sky's own colour; nearer ridges keep the ladder. Against d3f1ca0e: `img/haze-far-d3f1ca0e.png` (uncommitted).
- **Stars on the sky's sphere** (Art's point 4, layer 1; `STAR_TURN`, `STAR_FLOOR`, `STAR_DARK`). They turn with the lap (a lap is a day; the field repeats every lap, so the wrap is seamless), never lower than 0.4 to 0.8 of a half screen above the horizon line (no star on a ridge), and only where the sky behind them is dark (full below 0.02 relative luminance, none above 0.08). Their strength is the key's alone: flying high no longer brings them out over a black noon sky.
- **The sea takes the sky** (Art's point 5, layer 8; `HAZE_SEA` 0.9). The water hazes by depth toward the horizon band at 90% of its value, deepest under the camera, and at its far edge it ends there instead of dissolving into the sky: one clear step between sea and sky at the horizon. It turns opaque as it hazes.
- **The world light's code, at strength 0** (Art's point 1, `docs/art/dynamic-sky.md` section 6; `RenderLook.WORLD_LIGHT` 0). `SkyDrive` builds Art's tints per layer (ground, buildings, trees, water, civilians, bodies) along the lap with the sky's own holds and blends, the mood's multiplies on top, and the share of windows lit; one world light for every pane, for the fight's middle, eased by the sky's own slew. The materials take it (`wl_mul`, `wl_add`); lit panes, lanes, auras, keylines, flashes and the HUD are never dimmed; the trees have their own material. At 0 the world draws as before. It follows as its own batch: at 1 it tipped the near-lens movement and the divider's sweep in AI clips over the flash line (below).

Not yet: the sun and the moon (Legal's pass with a flash condition, 32029623); the altitude smear (Art's point 6); World's layered ranges (`ranges.json`); and, with the world light's batch, two changes to the whip haze it needed (built and measured in scratch). With the world light on, the towers darkened against the sky and a launch's first ticks, swept before the haze came in, were counted: the whip haze coming in within about a tick, a camera up to 60 widths a second still a whip (a launch's first tick read 20.8 and was taken for a cut), and the street paint fading into the ground during a whip took signaturecity from 8 back to 3. Without the world light they cost collapse (the opening blast's camera jerk became a whip: 1.5 / 2 to 3 / 3.5 normal, 2 / 2.5 to 3.5 / 3.5 reduced), so they wait for it.

## Flash

Measured with Tools' `check-clip` (primary / area threshold 15% lower / two-second memory), main and main with the batch both on bf966c57:

| Clip | Main | With the batch |
| :-- | :-- | :-- |
| signaturecity-normal | 2 / 2 / 2 | 2 / 2 / 2 |
| signaturecity-reduced | 1 / 2 / 2 | 2 / 2 / 1 |
| collapse-normal | 1.5 / 2 / 0.5 | 1.5 / 2 / 0.5 |
| collapse-reduced | 2 / 2.5 / 1 | 2 / 2.5 / 0.5 |
| ai-4-normal | 2 / 2 / 2 | 2.5 / 2.5 / 2 |
| ai-106-normal | 1.5 / 2.5 / 1.5 | 2 / 2 / 1.5 |
| ai-106-reduced | 1.5 / 2.5 / 2 | 2.5 / 2.5 / 1 |
| ai-104-normal | **FAIL** 2.5 / 3.5 / 2 | **FAIL** 2.5 / 3.5 / 2.5 |

ai seed 104's fail is main's own: its worst second (ticks 290 to 343, a crater forming in a brawl) holds the same turns with the batch and without. ai seed 38, measured on the way, left Tools' set when the seeds were re-picked for the training dummy (06b0200e).

**The world light at full strength**, on 88d13195 with steps 1 to 3, moved several AI clips: ai seed 104 normal 2.5 / 3.5 / 2 to 3.5 / 5 / 3.5, ai seed 106 reduced 2 / 2 / 3 to 4 / 4 / 1.5, ai seed 38 both modes to 3. Switches on stretches put it on the world light: ai 106 reduced at 3377 read 4 with it on and 2 with it off, ai 104 at 3490 read 4 and 1.5. What it tips is movement already there (the foreground near the lens, the split's divider sweeping between panes); lighting both panes for one shared place changed nothing. At the start's sunset key it also took signaturecity to 8 (the whip changes above took it back to 3).

Gated on bf966c57 (render unchanged up to fd14330f): all 15 of render's gates (the sky check 35).

## The sun and the moon (scratch)

One flat faceted disc each (ten sides, two facet tones in turn and a lighter inner face; no glow, no bloom), behind the clouds and in front of the stars, on the lap's phase: the sun low at golden and on the horizon line at sunset, the moon up at night. The still Legal saw: `img/sky/discs-for-legal.png` (not committed).
