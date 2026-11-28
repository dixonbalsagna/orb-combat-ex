# Energy Toy

A one-page toy for building and discovering energy looks. Open `index.html` in Chrome. Nothing to install, nothing leaves the PC.

It is about the look only. Nothing in it is physics, and nothing in it is in the game yet. Made with AI assistance (Claude), for Orb's ask of 2026-11-27 (`docs/ep/vision.md`, the energy toy entry).

## What you see

One preview window with three pictures, all drawn from the same recipe:

- **Aura:** the look round a plain stand-in figure.
- **Beam:** the same look as a beam fired from the figure's hand.
- **Blast:** the same look as a ball of energy hovering in place.

## How to play with it

- **Preset** (under the picture): seven looks to start from. The first three are Orb's own examples: blue sparks that jump off the body, arcing black plasma waves, and a small golden cloud above the head that rains vibrating green atoms.
- **Random:** a brand-new look made from everything that is unlocked.
- **Mutate:** nudges every slider a little, and sometimes swaps one choice or adds a layer. Press it over and over to wander away from a look you like.
- **Back:** undoes the last step, so nothing is lost by pressing Random.
- **Layers** (on the right): a look is a stack of up to five layers. Each layer picks one **Shape**, one **Behaviour**, one **Material** and one **Colour**, and has its own sliders. **Shuffle** re-rolls one layer and keeps the rest.
- **Trails:** how long the energy lingers and drifts, which is what makes it look like smoke or fluid.
- **Blend two looks:** press **Keep as A** on one look and **Keep as B** on another, then drag the slider. Sliders and colours slide smoothly. The four choices switch over at different points along the way, so the middle holds hybrids that neither end has (A's shape with B's behaviour, for example).
- **Preview campaign unlocks:** see below.
- **Save file / Load / the text box:** a look is a small text file. Save it, load it back, or copy the text.
- **Quality:** if the picture runs slowly the toy turns this down by itself.

Adding `?preset=2` to the address opens on the third preset; `?random=3` opens on a random look with everything unlocked.

## Rewards from the campaign

Every choice and every slider range has a rarity: **common, rare, exotic** or **mythic**. A new player has the common ones. Locked choices show greyed with a padlock, and the thin bar under each slider is coloured by the tier that opens each part of it.

The four buttons under **Preview campaign unlocks** pretend the player has earned that tier, so you can see what playing the campaign would add. Random and Mutate reach into whatever is unlocked, and lean toward the rarer things. Choosing a preset that needs a higher tier switches the preview up and says so. Switching the preview down swaps locked choices for common ones.

| | Common | Rare | Exotic | Mythic |
| :--- | :--- | :--- | :--- | :--- |
| **Shape** | Shell, Sparks, Waves and rings, Cloud, Falling particles | Lightning arcs, Little forms (atoms, crystals, glyphs), Shards | Filaments, Ghost lattice | Twin helix |
| **Behaviour** | Jump off the body, Ripple out, Float above the head, Rain down, Cling and vibrate | Arc between points, Orbit | Erratic, Inverted: rise instead of fall, Inverted: pulled inward | Inverted: runs backward, with echoes |
| **Material** | Soft glow, Smoky fluid, Crackle | Plasma, Inked | Dark energy, Prism, Heat shimmer | Negative |
| **Colour** | Azure, Ember, Gold, Viridian, Violet, Rose, Moonlight | Riptide, Dusk | Spectrum, Blacklight | Anomaly |

Slider ranges that widen with tier:

| Slider | Common | Rare | Exotic | Mythic |
| :--- | :--- | :--- | :--- | :--- |
| Size | 0.5 to 1.5 | 0.3 to 2 | 0.3 to 3 | |
| Speed | 0 to 1.2 | to 2 | to 3 | |
| Amount | 0.2 to 1 | to 1.6 | to 2 | |
| Reach | 0.3 to 1 | to 1.5 | to 2 | |
| Erratic | 0 to 0.25 | to 0.5 | to 1 | |
| Vibrate | 0 to 0.3 | to 1 | | |
| Form (atoms, crystals, glyphs) | atoms | crystals | glyphs | |
| Spin | -0.3 to 0.3 | -1 to 1 | -2 to 2 | |
| Colour range | 0 to 0.6 | to 1 | to 2 | |
| Colour drift | locked | | | 0 to 1 |
| Trails | 0 to 0.4 | to 0.8 | to 1 | |

Power, Detail and Colour shift are common across their whole range.

**The tiers live in data, not code.** They are in the block marked `id="catalog"` near the top of `index.html`: each menu entry has a `"tier"`, and each slider has a list of `"ranges"`, one per tier. Moving an entry to another tier, or adding a palette or a preset, is an edit to that block only.

## The recipe format

A saved look is JSON:

```json
{
  "format": "orb-energy-recipe",
  "version": 1,
  "name": "Blue jump-sparks",
  "trail": 0.25,
  "layers": [
    {
      "shape": "sparks",
      "behaviour": "jump",
      "material": "glow",
      "palette": "azure",
      "seed": 3,
      "sliders": {
        "power": 0.95, "size": 0.8, "speed": 1.1, "density": 1, "reach": 1,
        "erratic": 0.2, "vibrate": 0, "detail": 0.6, "form": 0.1, "spin": 0,
        "hue": 0, "spread": 0.6, "cycle": 0
      }
    }
  ]
}
```

- `layers`: one to five, drawn in order and added together.
- `shape`, `behaviour`, `material`, `palette`: the `id` of an entry in the catalogue. An id the catalogue does not know is replaced by a default on loading.
- `seed`: a whole number that fixes this layer's random pattern, so a saved look always comes back the same.
- `sliders`: one number each. `density` is shown as "Amount", `hue` as "Colour shift", `spread` as "Colour range", `cycle` as "Colour drift".
- `trail`: the one slider that belongs to the whole look.

**As a fighter's style.** A recipe holds nothing but ids and numbers, so it can sit in a fighter's data file as it is (`"energyStyle": { ...recipe... }`) and a player's own look can be saved the same way. What a player may pick is the catalogue filtered by the tiers they have unlocked, which is one list of unlocked tiers in the save file. A blend between two recipes is itself a recipe, so "upgrades that subtly shift the look" can be a blend slider moved by campaign rewards.

## How it is drawn

Two passes over the whole picture.

1. **Layers.** For every point, each layer runs three steps:
   - **Behaviour** decides where the pattern lives and which way it travels: a pair of coordinates (how far round the body, how far out from it), a direction, and a fade.
   - **Shape** turns those coordinates into an amount of energy at that point.
   - **Material** turns that amount into light, darkness, a bend of the backdrop, or an inversion.

   The beam and the blast are the same code wrapped round a different outline (a capsule and a circle in place of the figure), which is why one recipe drives all three.
2. **Picture.** The backdrop, the figure, then the energy over it. The last frame's energy is carried forward, drifted upward and faded, which gives trails for the cost of one texture read.

Techniques used: value noise and warped layered noise for smoke and cloud; a cell grid with one moving body per cell for sparks, motes and the little forms; a line with layered sideways wobble for lightning; nearest-cell (Voronoi) distance for crackle and shards; cosine palettes (`a + b * cos(2 pi (c t + d))`) for colour; two ring sets a few percent apart for the ghost lattice; a rainbow keyed to thickness for the prism; a darkness channel for dark energy (a black core with a bright rim at one level of density); a small offset to where the backdrop is read for heat shimmer.

"Runs backward" plays the layer with time reversed and draws a second, fainter copy a quarter-second ahead of it. Because every pattern is worked out from the clock and never stored, running backward costs nothing.

## Porting notes for the game

- **Shader language.** The shaders are GLSL ES 3.00 with only uniforms, plain functions and loops with fixed bounds. They port to Godot's shading language nearly line for line (`texture`, `mix`, `smoothstep`, `fract`, uniform arrays and structs all exist there). The pieces that change: `gl_VertexID` (use a full-rectangle mesh), the two outputs of the first pass (two viewports, or pack the bend and inversion differently), and the trail (a `SubViewport` that keeps its last frame).
- **One recipe, three uses.** In the game the outline would come from the fighter, the beam and the projectile themselves. The toy's `geoOf` is the only place that knows about outlines.
- **Layers are data.** The five-layer limit, the per-layer numbers and the palettes are uniform arrays filled from the recipe. No shader is compiled per look, so a new look never causes a compile hitch.
- **Cost.** One full-picture pass with up to five layers, each with a handful of noise reads. Not measured on a target machine: the toy's frame counter is the only reading so far, and it draws at three-quarters size by default. A game port would draw energy only where energy is, not across the whole screen.
- **Not deterministic, and it need not be.** This is picture code. It reads the clock and never writes anything the simulation reads.
- **Brightness and pulse limits built into the toy.** These are the toy's own guards and have not been through the project's picture checks; a game port has to pass those on its own.
  - Light is compressed (`L / (1 + L)`) and the final picture is capped below white.
  - A few times a second the toy reads a thumbnail of the picture. If more than a quarter of it is bright it eases the energy's light down, and eases it back when the picture calms. It never snaps.
  - Travelling bands never pass one spot more than 2.5 times a second, whatever the Speed and Amount sliders say.
  - Lightning is re-drawn about twice a second with a cross-fade between the old and new bolt, never a hard blink.
  - The ghost lattice's offset drifts slowly, because the wide beat it makes moves many times faster than the offset does.
  - "Negative" is a gentle inversion toward mid-grey, never a white field, and never covers the figure.
  - Vibrate moves things by a small distance; it does not change their brightness.
- **Names.** Every name here is our own and descriptive. None is a reference.

## Known rough edges

- The pattern round the figure is mirrored left to right and then skewed, to avoid a seam under the body. Some looks show the symmetry.
- Orbit has a small seam on one side of its ring.
- Stills taken through the team's capture tool run with the clock slowed, so the frame counter reads 0 there. In an ordinary Chrome window it reads normally.
- The slider ranges and the tier each thing sits in are a first guess for Orb to play with, not a balance decision.
