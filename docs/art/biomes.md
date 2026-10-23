# The biome look bible

Owner: Art Director. 2026-10-23. For Rendering and VFX (routed by the EP) and for World's new biomes, on Orb's word: "pour resources into improving our planet generation, biomes, fighter animations". **Concept art and data, working labels, pending Orb. Biomes only, no character art, so the sheets may be shown to Orb freely.** The pictures are in `art/concepts/biomes/` (README there); the numbers are `data/art/biomes.json` (Tools adds the schema: `node tools/validate.js` warns "no schema" until then); each biome's page is `docs/art/biomes-pages.md` (generated). Regenerate: `node art/concepts/biomes/gen.mjs`.

| What | Where |
|---|---|
| One sheet per biome (15, by World's id: ocean, plains, forest, desert, mountains, ice_sheet, sea_ice, jungle, savanna, tundra, taiga, wetland, beach, highland, volcanic): the strip at fight distance, the palette, the scorched, cratered and burned states, three destruction frames, the transitions into each neighbour | `art/concepts/biomes/biome-<id>.svg` |
| All fifteen side by side | `art/concepts/biomes/biomes-sheet.svg` |
| The planet from orbit: a colour study (three views, a flat map, the legend) | `art/concepts/biomes/orbit.svg` |
| The fifteen under the light keys, with the world-light tints (golden, sunset, dawn, night) | `art/concepts/biomes/biomes-golden.svg`, `biomes-sunset.svg`, `biomes-dawn.svg`, `biomes-night.svg` |
| The 35 cover silhouettes, clean and charred, at true pixel size with triangle counts | `art/concepts/biomes/cover-sheet.svg` and `cover-sheet.png` (1:1), `docs/art/biomes-cover.md` |
| The numbers | `data/art/biomes.json` (the cover counts and the colour-vision results are in its underscore keys) |
| One page per biome (palette, cover, damage, destruction, transitions) | `docs/art/biomes-pages.md` |

## 1. The rules every biome keeps

These come from the game's own look (`docs/ep/taste.md`, the sky and world-light work) and Orb's rejections:
- **Flat faceted colours with a thin keyline** (#0a0d14). A surface is three faces, **lit, mid and shade**: the lit face takes the sun, the shade face turns from it. No gradients inside a surface.
- **No blur, no fades, no dissolves, no haze as a default** (Orb, ADR 0010). Distance is a **value ladder**: three ridges, each a flat colour hazed toward the horizon (the sky and distance audit's target: further is lighter and less saturated, and tends to the horizon band, never to the upper sky). Every transition between biomes is **hard steps in colour**, five bands across the zone.
- **Fight distance first.** A fighter is 75 units tall; the strip is 1,200 units wide. Anything that must read at fight distance is a **silhouette of 30 units or more** (a tree, a rock, a reed bed, a dune, a mesa); finer detail is a facet colour, not a shape.
- **Original shapes in the anime brawler's spirit**: low-poly stylised nature, nothing taken from another game's biomes. The cone spruce, the flat-topped acacia, the faceted boulder are generic nature drawn in our own facets.
- **Noon is authored; the world light does the rest.** The world-light tint per sky key (`data/art/sky.json`) multiplies each layer (ground, trees, water), so a biome never needs a night palette.

## 2. The fifteen at a glance (World's ids)

| # | World id | Biome | Ground mid | Rock mid | Vegetation mid | Water deep | Sky horizon | Ground profile | Signature cover | Plume |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 0 ocean | Open ocean | #2c78a8 | #4f5a64 | #3f7a50 | #1f5a88 | #bfdcec | swell | stack, whitecap | water column and ring |
| 2 | 1 plains | Plains | #70a246 | #7e7a6e | #3b7634 | #376b7c | #c4e0ee | rolling | tree, tuft, boulder | dirt and divots |
| 3 | 2 forest | Temperate forest | #487a38 | #6e6a5e | #327c3a | #3d6076 | #c0dce8 | rolling | tree, fir, shrub | leaf shred and splinters |
| 4 | 3 desert | Desert | #d8b868 | #b87a44 | #4d8040 | #357a85 | #f0e4c0 | dunes | cactus, scrub, mesa | sand plume |
| 5 | 4 mountains | Mountains | #547e46 | #7e786c | #2c5e3e | #366577 | #c4daea | jagged | fir, boulder, scree | rock shards and dust |
| 6 | 5 ice_sheet | Ice sheet | #ebe8e2 | #6a645c | #ebe8e2 | #1b3f57 | #d4e2ec | sheet | icespire, crevasse, nunatak | ice shatter |
| 7 | 6 sea_ice | Sea ice | #e3e4e0 | #e3e4e0 | #e3e4e0 | #1b3f57 | #c4d2de | floes | berg, floeblock, icespire | floe burst |
| 8 | 7 jungle | Jungle | #386e36 | #5e6e5a | #3a8f3c | #2f6a58 | #b8d8cc | rolling | jungletree, fern, flower | shredded leaves and steam |
| 9 | 8 savanna | Savanna | #c0a650 | #8e806c | #5b8434 | #3f7a80 | #ecdcb0 | rolling | acacia, tuft, termite | red-ochre dust |
| 10 | 9 tundra | Tundra | #738868 | #6e6e74 | #5f7248 | #3b6276 | #cadce8 | hummock | krummholz, snowpatch, boulder | snow burst |
| 11 | 10 taiga | Taiga | #57705f | #6c6e72 | #2a5444 | #3b6276 | #c4d8e6 | rolling | spruce, snowpatch, shrub | snow and needles |
| 12 | 11 wetland | Wetland | #5f804e | #6e6e62 | #5a8048 | #4d8474 | #c6dcd4 | flat | reed, mangrove, pool | mud splash |
| 13 | 12 beach | Beach and coast | #d8c088 | #857c70 | #4a9440 | #2c78a8 | #cfe6ee | shore | palm, dunegrass, boulder | sand and spray |
| 14 | 13 highland | Highland | #687452 | #8c8070 | #6c4660 | #2f5a6e | #c8dae6 | hummock | tor, heath, boulder | rock and peat |
| 15 | 14 volcanic | Volcanic ground | #43404a | #4a464e | #4a6a38 | #3f6578 | #d8c8b0 | cones | basaltcol, boulder, vent | ash column, ember chips |

The full palettes (lit, mid and shade for ground, rock and vegetation; subsoil; secondary cover; trunk; water; accent; sky; the far ladder; the orbit colour) are on each biome's sheet and in the data. **World split two of my first thirteen** (2026-10-24): the tundra and the taiga are now two biomes (open lichen ground with stunted scrub, and dark spruce with snow in the hollows), and the rocky highland (weathered grey granite, mauve heather, russet bracken, stacked tors, wind-bent trees) is its own biome, no longer the volcanic ground in its cold state. **Volcanic** stays black basalt and ash with a cone and cooled flows; a hot state is an event, not a biome (static orange, small area; Legal's photosensitivity and the saturated-red test apply). The ids follow World's: `ice_sheet`, `sea_ice` and `beach` (not `ice`, `seaice`, `beach and coast`).

## 3. Readability: the fighters stay readable on every ground

The rule the sky and the polar palette already use (`docs/art/dynamic-sky.md` section 6; `data/art/sky.json` readability): an aura stays **20 or more CIEDE2000** from the ground it is drawn over, a body **15 or more**, at every sky key with that layer's world-light tint. Measured here for every ground, rock, vegetation, subsoil and water tone of the thirteen (`art/concepts/biomes/measure.mjs`):

- **All fifteen pass.** The worst aura is 20.6 (beach) and the worst body is 15.6 (desert, against the rival's red at dawn: the red mesa was moved from red to orange-tan to get there). The two ices keep the polar palette's rule: two tones, a warm white and a slate, with no mid blue-grey.
- **Advisory, not gated (and not new):** the Protagonist's blue body against the sea measures 10.3 (the sea owns mid blue; the keyline carries it, as in the build today); the rival's new brick coat (#6f342c) against brown subsoil measures 11.9 (plains crater floor) and 8.4 (savanna's red earth): a fighter standing in a savanna crater reads by his keyline and aura, so **the savanna's earth is the one place to watch the coat**.
- **The Empress's green aura (not in the build) collides with every green biome** (3 to 10 against jungle, forest, plains, savanna and beach vegetation). That is a lane problem for her design, not a palette problem: a green aura on a green world needs a dark keyline and a second hue. Flagged for the EP.
- **Under the light keys** (the world-light tints on the ground, trees and water, the fighters never dimmed): the rule holds at golden (worst aura 22.2, beach; worst body 22.3, volcanic), sunset (22.4, ocean; 21.1, volcanic), dawn (22.0, sea ice; 15.6, desert) and night (25.1 and 25.3, ice). The sheets `biomes-golden.svg`, `biomes-sunset.svg`, `biomes-dawn.svg` and `biomes-night.svg` show each biome under each key.
- **The colour-vision pass (protan, deutan, tritan; Machado et al. 2009, severity 1.0, as `docs/art/colour-vision.md`).** The check is the **preset lane auras** (a viewer with that vision plays with the preset: protan Protagonist #30a6a6 and rival #6b0bcb, deutan #35b6ab and #5b0bcb, tritan #9c90d5 and #6b0bcb) against every ground, rock, vegetation, subsoil and water tone at every key, **14 or more CIEDE2000** under that vision (the rule's simulated figure; 20 stays the normal-vision figure). First run: 87 tones failed. **Fixed in the palette (nothing changed in the default look beyond a few tones):** the lit rocks of beach, plains, forest, jungle, wetland and mountains and tundra (small nudges, 1 to 8), plains and tundra's lit ground, tundra's secondary cover, the tea-green and teal lakes and pools of the land biomes (plains, savanna, forest, wetland, desert, mountains, volcanic, tundra: moved toward a greyer teal, since the teal preset aura sat on top of them under protan and deutan), the ocean's subsoil. After the fixes all land biomes pass (worst 14.0 to 14.3); the two new ones (the taiga and the highland) and the split-off tundra needed small nudges the same way (the taiga's lit rock, the tundra's lit scrub and secondary cover, the highland's lit ground, lit rock and tarn water, all 1.8 to 8.9 from where they started) and then pass (14.0, 14.0 and 14.1). **Not fixable in the palette, and not changed:** the **open sea and the beach's shallows** (3 sea tones and 2 beach water tones; 8.9 to 12.6 under protan and deutan: the sea owns mid blue, and the Protagonist's preset teal is a mid blue-teal), and the **lit ice and sea ice at dawn** (4.6 to 6.4 under protan and deutan: the dawn tint turns the pale ice a lilac grey that the same teal aura matches; the two ices keep the polar palette's two-tone rule) plus the polar water (12.1 to 13.5). These are **lane issues, like the Empress's**: the carriers are the aura's dark keyline, the non-colour mark per fighter and the silhouettes (`docs/art/colour-vision.md`), and a lane tweak (a lighter protan and deutan Protagonist aura) would be the fix if Orb wants one.
- **Body against ground under colour blindness is not a gate** (it cannot be: a red body on green ground merges for protan and deutan by definition); the body is told apart by its shape, keyline and mark.
- **Known lane issues, no fix now (the EP's ruling, 2026-10-24):** the Empress's green aura against every green biome; the rival's brick coat against the savanna's red earth and the plains' crater soil; the temperate sea and the protan and deutan Protagonist aura; the pale ices at dawn under protan and deutan.

## 4. The damage language (scorched, cratered, burned)

The same three states in every biome, so the player learns one grammar; the material changes:

| | Scorched (a beam along the ground) | Cratered (an impact) | Burned (fire on what grows) |
|---|---|---|---|
| Drawn as | a flat band along the surface, a thin lighter edge | a bowl in the profile with a raised rim; **the inside is the subsoil colour, not the surface colour**; rubble on the rim; cover inside removed | the ground in that span turns ash grey; trees become black skeletons, grass stubs and ash flakes |
| Sand, beach | a glassy dark green-black band with a pale edge (the prototype's GLASS TRENCH) | the bowl floods from the water side on a beach | black palm trunks, grey ash in the dune lee |
| Ice, sea ice | a slate streak with a melt-blue edge (refreezes in ten seconds) | a clean blue-walled bowl and shattered white blocks | a soot band and a melt pool |
| Water | a steam line on the surface for about two seconds | a bowl of water, a ring wave | charred wreckage floating, steam banks |
| Wetland | a dark band and burnt reed stubs | fills at once with tea-green water | a reed fire, grey flakes on the water |
| Volcanic | a pale-grey fused streak with a thin static orange edge | a bowl of ash and clinker | the few shrubs black; fresh orange crust (static) |
| Soil, grass, forest, jungle, savanna, tundra, mountains | a black char band, the soil dark below it | a round bowl of subsoil, a torn rim, trunks lying outward like spokes in woodland | the standing burn: black trunks, grey ash floor |

Everything stays flat colour; there is **no smoke haze**: smoke and steam are small faceted puffs (VFX).

## 5. Destruction (for VFX): the impact at burst, peak and settle

One shape language across the fifteen: a **billowing column of overlapping faceted puffs** (the high ones drawn first, so the low ones sit in front), a **flat pale burst star** at the first frame (one still frame, never a flicker; coloured from the plume's own light tone, not white-hot), **ejecta on parabolic arcs** (shards, chunks, leaf diamonds, ember chips), a **skirt of low puffs along the ground** and **debris that lands** and stays. What changes is the colour, the height and the ejecta:

| Biome | Kind | Colours (lit, mid, shade) | Height and width (units) | Ejecta and extras |
|---|---|---|---|---|
| Ocean | water | #e4ecee, #9cc8de, #4a86b0 | 320 by 120 | a tall faceted column with a crown of puffs, a flat ring wave, pale blue shards |
| Beach | sand (wet) | #f3e4b2, #dcc58a, #a89060 | 300 by 200 | sand chips and rock; a ring of dark wet sand |
| Plains | dirt | #9a7a52, #6b5338, #4a3826 | 280 by 190 | turf chunks and clods |
| Savanna | dust | #e8c88a, #c0884c, #8a5a34 | 320 by 230 | red earth chips, tumbling grass |
| Forest | leaf | #79b058, #4a9a48, #1f5a2c | 330 by 210 | green and orange leaf diamonds, bark chunks |
| Jungle | leaf and steam | #9ad052, #3a8f3c, #1f6a30 | 360 by 240 | magenta petals, grey steam puffs from the wet ground |
| Wetland | mud | #a09a72, #6a6448, #3e3a2a | 240 by 230 | dark globs on arcs, flung reed |
| Desert | sand | #f3e4b2, #d8b868, #a88a44 | 360 by 260 | sand chips; the dune face slumps |
| Mountains | rock | #a8a398, #7e786c, #524e46 | 300 by 200 | angular blocks, scree sliding downhill |
| Volcanic | ash | #8a868e, #4a464e, #22202a | 400 by 220 | black blocks; **static** orange ember chips (never pulsing) |
| Tundra | snow | #e4ecf0, #a8bccb, #6a7e90 | 340 by 220 | snow crystals, dark soil clods |
| Ice sheet | snow | #ebe8e2, #c4cdd4, #485765 | 320 by 220 | cut blue crystal shards |
| Sea ice | snow and ring | #e3e4e0, #b8c8d4, #485765 | 300 by 200 | white chunks, a ring of black water |

Legal and the flash work: every frame is a still; the burst star appears for one frame; the ember chips are steady; no plume strobes (the flash check's rules stand).

## 6. How biomes meet (for World and Rendering)

A border is a **zone about a third of the 1,200-unit window wide (about 360 units)**. Across it: the **ground colour steps in five hard bands** (the mix of the two biomes: 10, 30, 50, 70, 90 percent), the **ground profile blends smoothly** (geometry, not colour), the **cover mixes by probability** (each candidate takes the neighbour's cover with the band's share), a few **ecotone covers** appear only in the zone (the list per pair: palms between beach and jungle, scrub between plains and desert, mangroves between forest and wetland, krummholz between mountain and tundra), and the **far land ladder** takes the colour step too. The 45 pairs (the climate adjacency: which biomes can touch) and each pair's note are in the data (`pairs`) and on each biome's sheet (section D). **Coasts** are special: the sea plane is three flat bands to the horizon (lighter toward the haze) behind the shore, and the land tapers up from the horizon at a headland, so a coast has an open horizon on the sea side.

## 7. The planet from orbit

`orbit.svg`: three views of a stand-in planet (the terrain is smooth waves, **not World's planet function**: the study is about colour and read, not shape) with hard-stepped light (lit, mid, shade, night), a thin crisp atmosphere rim (bright on the sun side, dim elsewhere) and a flat map. **From orbit every biome is its own colour** (an authored blend of its ground and its cover by how green it is), **12 percent toward the atmosphere blue (8 for ice)**; ice and sea ice are a warm white and a pale cool grey, the ocean its deep blue. The fifteen stay apart: the minimum pairwise distance from orbit is **9.3 CIEDE2000 (mountains and highland)**; ice and sea ice are told apart by where they are (a pole, an ocean). From orbit the planet reads as ice caps, a taiga and tundra ring, forest and plains, a savanna-desert-jungle belt, small dark volcanic spots and thin pale beaches: the map is the colour key for the planet picker and for the intro (a planet turning in space).

## 8. What each team builds, cheapest first

1. **Rendering:**
   1. the ground facet colours per biome from the palette (lit, mid, shade by slope), with the subsoil colour in craters;
   2. the far land as a three-ridge value ladder, replacing the haze band;
   3. the cover set: about 35 low-poly silhouettes (tree, fir, spruce, acacia, jungle tree, palm, mangrove, fern, reed, cactus, mesa, boulder, stack, basalt column, ice spire and so on), each in a clean and a charred state (the charred ones are a bare trunk or a stub);
   4. the stepped transitions and the ecotone covers;
   5. the damage states (the band, the bowl, the ash span);
   6. the sea plane for coasts;
   7. the orbit colours for the planet picker.
2. **VFX:** the plume language of section 5 (puffs, burst star, arcs, landed debris) with the per-biome colours and ejecta; steam in the jungle, steady ember chips in the volcanic.
3. **World:** the fifteen biome ids (World's `climate.json` "fine" table: the data is keyed by them, and `_world_id` on each entry is the number), the neighbour rules (the pairs) as the adjacency of the planet function (ice at the caps, taiga and tundra poleward of forest, savanna and desert on the dry belt, jungle and wetland on the wet equator, beaches wherever land meets the sea, volcanic at hotspots), and the cover densities (`cover` in the data: units per 1,200).
4. **Tools:** a schema for `data/art/biomes.json`.

## 9. Limits and risks

- The **flash check** (the plumes) is not run over this; the colour-vision presets and the light keys now are (section 3).
- The silhouettes are **concept drawings in 2D**; Rendering's ground is 3D and flat-shaded, so the cover needs modelling at about 30 to 120 triangles each; **cost** is the cover set (about 35 shapes) and the stepped blend; an estimate, Rendering to confirm.
- The profiles are illustrative; **World's planet function owns the real terrain** (the profile kinds and amplitudes here are the look to aim for: dunes with a steep lee, jagged mountains, cones, hummocks, floes).
- The orbit study's planet is a stand-in.
- The Empress's green (section 3) and the savanna's red earth under the rival's brick coat are the two readability watch-points.

## 10. Next

On Orb's word: a short motion test of one plume with VFX; the flash check over the plumes; a lane tweak for the protan and deutan Protagonist aura if Orb wants the sea and the dawn ice cleared; and any cover Orb wants changed or added (a fourteenth biome would be one spec entry, then regenerate).
