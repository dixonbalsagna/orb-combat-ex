# The backdrop: what the world gives it, and what would make the far ranges read as mountains (World, 2026-10-15)

Owner: World and Environment. Paper, for Orb's sky, fog and mountains pass (`docs/ep/vision.md`, last section). Facts are read from `sim/world/terrain.gd`, `render/core/look.gd`, `render/core/ground_field.gd` and `render/shaders/ground.gdshaderinc` on main, and from a sample of the heightfield (seed 1; the planet's ground does not depend on the seed).

## 1. What is there today

| Layer | What it is | Numbers |
| :--- | :--- | :--- |
| The sim's ground | One heightfield: 4,800 columns of 32 units round a planet of 153,600 units (about 2,050 fighter heights). **One mountain range exists, and it is one bell**: x 104,000 to 121,600, peak 7,354 at x 111,000 (98 fighter heights; the tallest tower is 2,300), west flank 600 to 7,000 over 6,000 units, a long east tail 7,000 to 1,100 over 10,000. No second summit, saddle or spur (a search for a peak that stands 150 units over everything within 1,300 units each side finds one). The other biomes top out at 750 (the hill village) and 600 (the desert) | the whole of what the sim holds |
| The band | Fighters and props live in z +2.5 to -29.5 fighter heights; the last buildings (scenery row 3) stand at -36.5 to -44.5 (-3,340 units). **The sim holds nothing beyond that.** | |
| The far land (Rendering's, `ground.gdshaderinc`) | **The same heightfield read again**, not a separate range: behind the band the ground blends from the band's own heights over `FAR_BLEND` (7,200 units), each column's height times a biome multiplier (mountains 1.25) plus a 3-harmonic sine "relief" (amplitude 300 x MS = 3,600 units in mountains), and the column read wanders sideways with depth by up to `MEANDER` (9,600 units) so the coast and the range meander | one surface from the fighter plane to `FOG_FAR` (120,000 units, 0.78 of the planet) |
| The horizon | The far mesh fades into the sky between `FOG_NEAR` (5,600) and `FOG_FAR` (120,000); a screen-space bend sags the world 3.5% to 10% (and 10% more as the camera climbs) | at the ceiling (24,000) the highest ground (7,354, 9,200 far) is under a third of the climb: the mountain is a bump, the horizon a fogged line |
| Rock and snow | One flat rock tone (`#7e766a`), snow above 6,720 and full at 10,800 | only the far peaks (9,200 and noise) reach it |

**What that gives the eye:** one mountain, repeated at every depth with a wander, in one rock colour, behind a fog that is the same for the ground at 6,000 and at 100,000 units. There is no ridge in front of a ridge, no range that is taller further back, no slope that faces the light. "Not overlapping in a strange way" is partly that: the same bell shows at several depths at nearly the same x, and the far relief (three sines, free in depth) is a smooth swell, not a range.

## 2. What would make them read as layered mountains

1. **A range is several summits with saddles and spurs, in layers.** Three or four ridgelines, each its own silhouette (a sum of peaks, not sines: positions, heights and widths from data), at spacings that grow geometrically with depth (first ridge at 6,000 to 8,000 units back, then about twice as far each: 15,000, 40,000, 100,000), each **taller as it gets farther** so each shows over the one in front by a band of at least a fifth of its height, and each with its peaks **in the saddles of the ridge before it** (a half spacing of phase). That is the whole rule against "overlapping strangely": layers that cannot hide one another and cannot be read as one.
2. **Scale and tone by depth.** Ridge heights from 98 fighter heights (the near range) to about 160 (the far), fighters and towers beside them; tone from rock (`#7e766a`) to a blue-grey by depth (Art's aerial perspective; the fog colour is the sky's own, so the far ridge ends in the horizon's band and not in a haze in front of it). The snow line is **per range** (data), so every range has a white top and the near one a bare one.
3. **Faces that catch light.** A ridge's profile has a derivative, so each slope has a facing: the side toward the sun is lit, the lee side in shade, in the sun's x direction (Art's dynamic sky has it by place). World can give, with each layer, the slope's facing and a rock-or-snow value by height and steepness; the colour is Rendering's.
4. **The sky and the stars belong behind all of it:** that is Rendering's draw order, and the one rule from this side is that **nothing in the fog band may be nearer than the first ridge** (the fog starts at `FOG_NEAR` 5,600, at the first ridge's depth, so the nearest ridge is already fogged: it should start beyond it, or be per layer).

## 3. The data and geometry it needs

- **`data/biomes/ranges.json`** (new, with a schema): per range its x centre and length, `layers` (depth, base height, summits: x offset, height, width, spur), snow line, rock tones. World builds each layer's profile deterministically from the planet seed (a pure function `WorldBackdrop.profile(range, layer, x)`); **the sim never reads it** (cosmetic: no hash, no golden).
- **The band's own range, as a range** (the sim's heightfield): turn the single bell into 4 or 5 summits 1,200 to 2,000 units apart (ridged noise on the same envelope, the same peak and span). That is a change to the base terrain, so a golden and a re-measure (the MOUNTAINSIDE launch, the ridge cover, and the lure read the slope).
- **Rendering** draws each layer as a far ribbon at its own depth (a profile mesh: 1,200 points a layer, no heightfield) in place of the far land's mountains; the far land stays the plains, desert and sea. One draw a layer; the layers wrap with the planet.
- **Cost:** the data and the generator: one World window (cosmetic only, no golden); the heightfield range: a second window with a golden. Rendering's ribbons and Art's tones are theirs.

**Open for Art and Rendering:** how many layers the camera can use (the zoom the fight is fought at shows the first ridge at about a quarter of the screen height); whether the far land's mountains are removed or kept as the last layer; the sun's direction by place.
