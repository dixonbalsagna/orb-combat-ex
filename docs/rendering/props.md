# The match's props (Rendering, 2026-10-29)

World's props are the sim's own: boulders, lone trees, bergs, ferns and the rest that `WorldGround.matchProps` lays on a gen 2 ring (`docs/world/props-w5.md`, `docs/world/flight-hooks-w6.md`). PROP SMASH breaks them. Until now the view drew none of them: the band's cover (`cover_view.gd`) is the view's own, seeded by the ring's hash. `render/core/prop_view.gd` draws the sim's props, so what a launch breaks is what is drawn.

## When it draws

- **Only with Combat's biome block on** (`DirLaunch.biomeOn()`: `launch_biome.json`'s `biome.enabled`, off on main). While it is off nothing is laid and no copy carries a prop, so the picture is the one without the pass at every frame.
- **Only on a world with fine ground** (gen 2). `matchProps` is `[]` on gen 1 and the hand-made world.
- The provisional rows (bergs, lone trees) follow World's `provisionalProps`, off on main.

## How it draws

- **The whole ring, once a world.** Each prop stands at its x, at its data height (`size` x `WorldGround.BH`, 75 units a fighter height), with Art's two exceptions (`docs/art/props-review.md`):
  - **The small dense kinds are capped** (`RenderProps.CAPS`): tuft and dune grass at 0.45 fighter heights, scrub at 0.7. A World kind drawn as one of these is scaled so its largest size in `ground.json` draws at the cap, the smaller ones in proportion. Grass draws 0.23 to 0.45 heights, tall grass 0.24 to 0.45, scrub 0.35 to 0.7 (the sim's are two to three times that). Fern and reed already draw at the cover's heights.
  - **The flat kinds take the size as their width** (`RenderProps.FLAT`): snow patch, pool, lava flow and driftwood. A snow drift is 0.6 to 1.8 heights wide, not tall. Driftwood, a log lying down, is one too: by its height a log drew 6 to 13 fighter heights long.
- **Its depth** is `RenderProps.Z`: just behind the fighter plane, where a launch meets it.
- **Its shape** is Art's cover silhouette for its kind (`RenderProps.KINDS`). A lone tree is the tree Art's cover gives its biome. Bergs that are cells are not drawn: the terrain stands there as the berg.
- **The cover's shader** draws it, with its biome's palette, its foot on the ground as drawn. Unlike the cover, a prop stands in a crater too: it still stands in the sim.
- **On a slope its foot goes down** to the lowest ground under it (read at the ends of its foot, the shape's outline at its ground line), by at most `RenderProps.FOOT_SINK` of its height (the shader's `prop_sink`). A prop's custom `a` is 1 plus its foot's half-width in units; the cover and the trees write 0 and are drawn as before.
- **One MultiMesh a kind in each of `RenderLook.COVER_CHUNKS` spans,** as the cover's, so the frustum leaves out the spans off the screen.
- **Cost:** at the build, the ring's query (about 25 ms natively on a gen 2 ring of 4,800 columns). A frame reads the director's broken columns (two fighters, four each) and compares them with the last; nothing else.

## A prop that breaks

- `SimDir.brokenProps` lists the columns the director keeps broken. When the list changes, each column that came in or went out is asked again (`matchProps` for that column alone, about 0.02 ms).
- A prop that no longer stands there is gone on that frame: a hard cut, the debris and dust doing the work (ADR 0010).
- A fighter's ring holds four. A fifth break lets the oldest stand again, and it is drawn again.
- It is drawn again on a rebuild (a new match, World's turn) only if the sim has it standing.

## The kinds (Art's rulings, `docs/art/props-review.md`)

| World's kind | Art's cover kind |
| :--- | :--- |
| grass | tuft |
| tall_grass | tuft (the savanna's gold grass) |
| fern, vine | fern |
| reeds | reed |
| scrub | scrub |
| boulder, lichen_rock, lava_rock | boulder |
| log, driftwood | driftwood (flat: the size is its length) |
| cactus | cactus |
| termite_mound | termite |
| ice_spire | icespire |
| snow_drift | snowpatch (flat) |
| puddle | pool (flat) |
| vent | vent |
| berg | berg |
| lone_tree | the biome's tree (acacia on savanna, palm on the beach) |
| shell | Art's scallop in its three fixed tones (`docs/art/shell-cover.md`), in three leans (-8, 2 and 12 degrees, the cover kinds `shell_l8`, `shell_r2`, `shell_r12`) picked by the prop's seed; never mirrored, so its lit face stays on the left; decoration, not a PROP SMASH target |

## For Art: what to look at before `biome.enabled` turns on

The scenes, with the switch on (`docs/rendering/tools/props-hook.mjs` makes a scratch export that takes `?biomeon=1`):

1. **Props beside the cover**, gen 2 planet 7 and planet 47, one still a biome. The pb scene's `pbiome` picks the stretch: desert, forest, coast; plus savanna, tundra and volcanic where a ring has them. Look at the kinds, sizes, depth against the cover behind, and density on the fighter plane.
2. **A PROP SMASH break** (`?propsmash=1`): the frame before the break, the frame of it (the prop gone, debris and dust), and a second after.
3. **A prop in a crater:** a slam beside a boulder. The prop stands in the bowl, as the sim has it.
4. **Split screen:** a prop in the second pane's view.

Art ruled on the kind map, `RenderProps.Z` and the small kinds on the fighter plane in `docs/art/props-review.md` (2026-10-29); the sizes above follow it.

## The check

`render/tools/props_check.gd`:
- **off:** with the switch off, gen 2 lays nothing through a match of AI play. With it on, the hand-made world lays nothing.
- **laid:** with it on, the ring's props are laid, standing, in every prop copy.
- **sized:** a flat kind's drawn width is World's size, a capped kind's drawn height is at most its cap and in one proportion to World's size for each World kind, and every other kind's height is World's size.
- **broken:** PROP SMASH launches staged as World's `flighthooks_probe` stages them, played through the game's own frames. On the frame the director's broken columns change, the broken prop is gone and the column draws what `matchProps` says stands there. Every other prop is as it was laid.
- **control:** with the update switched off, the broken props stay drawn, so the check must fail.
