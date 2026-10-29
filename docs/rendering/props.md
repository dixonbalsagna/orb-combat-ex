# The match's props (Rendering, 2026-10-29)

World's props are the sim's own: boulders, lone trees, bergs, ferns and the rest that `WorldGround.matchProps` lays on a gen 2 ring (`docs/world/props-w5.md`, `docs/world/flight-hooks-w6.md`). PROP SMASH breaks them. Until now the view drew none of them: the band's cover (`cover_view.gd`) is the view's own, seeded by the ring's hash. `render/core/prop_view.gd` draws the sim's props, so what a launch breaks is what is drawn.

## When it draws

- **Only with Combat's biome block on** (`DirLaunch.biomeOn()`: `launch_biome.json`'s `biome.enabled`, off on main). While it is off nothing is laid and no copy carries a prop, so the picture is the one without the pass at every frame.
- **Only on a world with fine ground** (gen 2). `matchProps` is `[]` on gen 1 and the hand-made world.
- The provisional rows (bergs, lone trees) follow World's `provisionalProps`, off on main.

## How it draws

- **The whole ring, once a world.** Each prop stands at its x, at its data height (`size` x `WorldGround.BH`, 75 units a fighter height).
- **Its depth** is `RenderProps.Z`: just behind the fighter plane, where a launch meets it.
- **Its shape** is Art's cover silhouette for its kind (`RenderProps.KINDS`). A lone tree is the tree Art's cover gives its biome. Bergs that are cells are not drawn: the terrain stands there as the berg.
- **The cover's shader** draws it, with its biome's palette, its foot on the ground as drawn. Unlike the cover, a prop stands in a crater too: it still stands in the sim.
- **One MultiMesh a kind in each of `RenderLook.COVER_CHUNKS` spans,** as the cover's, so the frustum leaves out the spans off the screen.
- **Cost:** at the build, the ring's query (about 25 ms natively on a gen 2 ring of 4,800 columns). A frame reads the director's broken columns (two fighters, four each) and compares them with the last; nothing else.

## A prop that breaks

- `SimDir.brokenProps` lists the columns the director keeps broken. When the list changes, each column that came in or went out is asked again (`matchProps` for that column alone, about 0.02 ms).
- A prop that no longer stands there is gone on that frame: a hard cut, the debris and dust doing the work (ADR 0010).
- A fighter's ring holds four. A fifth break lets the oldest stand again, and it is drawn again.
- It is drawn again on a rebuild (a new match, World's turn) only if the sim has it standing.

## The kinds (provisional: Art's call)

| World's kind | Art's cover kind |
| :--- | :--- |
| grass | tuft |
| tall_grass | dunegrass |
| fern, vine | fern |
| reeds | reed |
| scrub | scrub |
| boulder, lichen_rock, lava_rock | boulder |
| log, driftwood | driftwood |
| cactus | cactus |
| termite_mound | termite |
| ice_spire | icespire |
| snow_drift | snowpatch |
| puddle | pool |
| vent | vent |
| berg | berg |
| lone_tree | the biome's tree (acacia on savanna, palm on the beach) |
| shell | not drawn: no Art shape yet |

## For Art: what to look at before `biome.enabled` turns on

The scenes, with the switch on (`docs/rendering/tools/props-hook.mjs` makes a scratch export that takes `?biomeon=1`):

1. **Props beside the cover**, gen 2 planet 7 and planet 47, one still a biome. The pb scene's `pbiome` picks the stretch: desert, forest, coast; plus savanna, tundra and volcanic where a ring has them. Look at the kinds, sizes, depth against the cover behind, and density on the fighter plane.
2. **A PROP SMASH break** (`?propsmash=1`): the frame before the break, the frame of it (the prop gone, debris and dust), and a second after.
3. **A prop in a crater:** a slam beside a boulder. The prop stands in the bowl, as the sim has it.
4. **Split screen:** a prop in the second pane's view.

The kind map, `RenderProps.Z`, and whether the densest small kinds (grass, tall grass, ferns, reeds) belong on the fighter plane at all, are Art's to set.

## The check

`render/tools/props_check.gd`:
- **off:** with the switch off, gen 2 lays nothing through a match of AI play. With it on, the hand-made world lays nothing.
- **laid:** with it on, the ring's props are laid, standing, in every prop copy.
- **broken:** PROP SMASH launches staged as World's `flighthooks_probe` stages them, played through the game's own frames. On the frame the director's broken columns change, the broken prop is gone and the column draws what `matchProps` says stands there. Every other prop is as it was laid.
- **control:** with the update switched off, the broken props stay drawn, so the check must fail.
