# The polar cold palette (for World's ice, 2026-10-17)

Owner: Art Director. For `docs/world/planet-ice.md` (Orb's homework 5: icecaps on both poles, a big icy landmass south, broken icebergs, floes, sea ice in the north). Concept art and data, working labels, **pending Legal review**; Tools adds the schema (`node tools/validate.js` warns "no schema" until then). **Sheet:** `art/concepts/world/polar-palette.svg`. **Data:** `data/art/polar.json`. Regenerate: `node art/concepts/world/polar.mjs`.

## The finding that shapes it
A pale aura on a pale ground is the game's worst case (the Protagonist's cyan on blue-white ice), and **a mid blue-grey is worse still**: every mid tone I tried measured 12 to 16 from the fighters' auras, under the rule's 20. The dark tones do best (a slate at 25 to 27). So **ice is two tones with nothing between: a warm white and a cold slate, over dark water.** Slopes that face the light are white, slopes that face away and every crevasse and floe edge are slate; the contrast is graphic, and the fighters read on both.

## The palette (data/art/polar.json)
| Where | Tone | Hex |
|---|---|---|
| **Ice sheet** (the south), lit | a warm white (not blue-white: warm separates from cyan) | `#ebe8e2` |
| Ice sheet, dark side, crevasses, **every edge and cliff** | a cold slate | `#485765` |
| Rock through the ice | the mountains' tone | `#7e766a` |
| **Sea ice** (the north), floe top | a slightly warm light grey | `#e3e4e0` |
| Floe edge | the slate | `#485765` |
| Meltwater rim where a floe meets the sea | the only light blue | `#5f8aa2` |
| **Iceberg**, lit face / dark face | `#e6e6e0` / the slate | |
| Under the waterline, seen through the water | the one deep teal | `#3a7893` |
| **Polar water**, deep / shallow | dark and cold, darker than the temperate sea (the sea owns mid blue) | `#1b3f57` / `#2f6a84` |
Distant ice fades to the sky's own horizon colour as everywhere; no polar sky key is needed, the cold comes from the ground. Each key's world-light tint applies to these as to any ground (a warm pink at sunset and dawn, a deep blue at night).

## Measured
Over every key with the world-light ground tint, the nearest of the four lanes' auras (Protagonist, Anti-hero, the proposed Empress and Cyborg) and the nearest of the two bodies:
| Tone | Nearest aura (rule 20) | Nearest body (rule 15) |
|---|---|---|
| Sheet lit | 22.6 (Protagonist, noon) | 15.9 (Protagonist, night) |
| Slate | 25.5 (Anti-hero, noon) | 25.2 |
| Floe top | 20.7 (Protagonist, noon) | 16.0 |
| Berg lit face | 21.9 (Protagonist, noon) | 16.1 |

## What does not clear
- **The training dummy.** His placeholder body `#b9b9b9` is 4 from the warm white (dawn) and his ring `#c6bade` is 7 to 10 from it: **no neutral body clears every ground**, snow and the city's grey being opposite ends. The Pads' canvas (`#b3a57f`) is 10 at worst (desert at sunset). So his read on ice, as on anything pale, is his marks and his keyline; a polar arena is rare (26% of accepted arenas carry any ice) and a dummy fight there rarer.
- **A light mid tone anywhere in the ice.** If Rendering shades a slope with a third, mid blue-grey for depth, it will measure 12 to 16 from an aura: use the slate or the white, and do the depth with the haze.

## Notes for the later windows
- **No buildings and no people** in a polar arena (`planet-ice.md`): the palette needs no building tints.
- Ice cracks, breath and wind are VFX's; a crack line is the slate at one pixel, never darker than the slate.
- A new biome row for `RenderLook.BIOME`: `ice_sheet` takes the lit white, `sea_ice` the floe top; the slate is the shade, not a biome.
