# The sim's props, as drawn: Art's rulings (2026-10-29)

Art Director, for the EP, on Rendering's `render/core/prop_view.gd` (`docs/rendering/props.md`). Nothing ships from this; `biome.enabled` stays off. Stills: Rendering's `docs/rendering/img/lookgate/props-*` and mine in `docs/art/props-review/` (a scratch export of HEAD with the props pass and the pb scene; main, planet 7 unless noted; the switch on; tick 121 unless noted).

## What the stills show

- **Desert** (Rendering's, on against off): the sim's boulder, about 1.4 fighter heights, stands behind-left of the pair and clear of them; with the cover's cacti and the dunegrass it reads as scale and place. It works.
- **Forest and coast** (Rendering's): the props are small rocks and a branch under the cover's trees; they do no harm. The coast still is the town on the shore, not a beach stretch.
- **Savanna** (`props-savanna-t121.png`): the lone acacia (about 1.5 heights) is the best thing in the set. The tall grass is not: sim `tall_grass` is 0.8 to 1.5 heights (60 to 112 units) against the cover's `tuft` at 24 to 50, so clumps as tall as the fighters stand at their feet and spike across their legs.
- **Tundra** (`props-tundra-t121.png`): good. Grey boulders, krummholz, snow patches and a little grass at the right scale; the pair stays the strongest thing on screen.
- **Volcanic** (`props-volcanic-t121.png`, planet 21; on planets 7 and 11 every volcanic column lies under a city): boulders and basalt columns read well; vents smoke. The small green shapes (probably `scrub`) look like leaves floating over black ground.
- **A prop in a crater** (`props-crater-desert-t40.png`): the boulder stands on the lip of the bowl, as the sim has it. Where the lip slopes its left foot hangs in the air.

## The rulings

1. **Kind map: keep, with five changes.**
   - `tall_grass` draws as `tuft` (the savanna's gold grass), not `dunegrass` (the beach and desert dune grass).
   - `snow_drift`, `puddle` and any flat kind (`snowpatch`, `pool`, `lavaflow`) take the sim size as their **width**, not their height (a `snowpatch` is 8 to 16 units tall; scaled to 135 it would stand up).
   - `log` stays `driftwood` (the cover shader gives it the biome's trunk colour). `lava_rock` and `lichen_rock` stay `boulder`. `vine` stays `fern`.
   - `lone_tree` stays the biome's tree at the sim size (acacia on the savanna, palm on the beach).
   - `shell`: not drawn until Art draws a `shell` silhouette (a small ridged fan, 0.4 to 0.9 heights). Until then a shell should not be a PROP SMASH target, or a launch breaks something nobody sees. Art can build it as a small task when asked.
2. **Desert boulders at up to 1.6 heights just behind the fighters: keep.** Do not shrink or push back. The still shows the pair clear of a 1.4-height boulder and the lit and shade faces keep the fighters' keylines readable; a pushed-back boulder would stand at the wrong depth for the PROP SMASH debris. Mountains reach 2.0 and are the same call.
3. **The dense small kinds on the fighter plane: yes, at the cover's height, not the sim's.** The sim sizes these between two and three times the cover's. Cap the drawn height at about 0.45 heights for `tuft` and `dunegrass`, 0.7 for `scrub`, and the cover's 50 to 110 for `fern` and 60 to 120 for `reed` (both already match). They are decoration (PROP SMASH targets only lone trees, boulders and bergs), so their drawn size is free. Reeds I could not see: no ring I probed had a wetland stretch on the fighter plane; check them when one does.
4. **Captured:** savanna, tundra, volcanic, and a prop in a crater (above), through `tools/machine/capture.mjs` one at a time. The tundra, savanna and volcanic stills are of the stretch's longest run on the ring; the crater is a tier 3 power-up bowl dug 40 units from the boulder (a scratch hook, not a launch).

## A list for Rendering (through the EP)

- Draw cap by kind as in ruling 3, flat kinds by width as in ruling 1, `tall_grass` as `tuft`.
- Sink a prop's foot a few percent into the ground on a slope (the crater's lip, steep dunes).
- Look at the small green shapes on the volcanic ground (probably `scrub`): they float; they may want no draw on ash.
