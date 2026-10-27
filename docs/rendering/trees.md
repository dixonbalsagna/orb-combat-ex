# The fellable trees (Rendering, 2026-10-27)

World's gen 2 readiness list said the trees are still drawn as cones; World's window 18 (`docs/world/forest-fire.md`) gave them a burn. This page is how the render draws both.

## Art's silhouettes (`render/core/tree_view.gd`, `RenderTrees`)

- **The kind.** Each tree in `S.trees` takes one of the tree kinds Art's cover gives the biome it stands in (`data/art/biomes.json` `cover`, by Art's counts as weights): `tree`, `fir`, `spruce`, `palm`, `acacia`, `jungletree` or `mangrove`.
  - The biome is the column's own palette id (the ground field's zone row, the cover's way): the fine biome on a gen 2 planet.
  - A biome whose cover names no tree (a city, a village) takes the broadleaf.
  - Seeded by the tree's index, so the same world draws the same trees.
- **The shape** is Art's own (`RenderCoverMeshes`, the cover's shapes from `art/concepts/biomes/draw.mjs`), at the sim's height `t.h`, in Art's proportions, flipped at random, standing in the strip's plane at the tree's depth.
  - The depths are the props' own as before (the `render.trees` stream: a depth, then a draw), so VFX's fire still finds each tree's plane.
- **The shader** is the cover's (`cover.gdshader`, its own material). It reads the ground under each foot, so a dig moves a tree with no CPU work; the trees no longer update when the ground changes.
- **Draws:** one MultiMesh for each kind the world uses, and one for its charred shape. A charred one draws nothing until a tree of its kind burns out. The hand-made world and gen 2 planet 7 use two kinds (`tree`, `fir`): one draw more than the cone's.

## The burn states (World's tree state: `alive`, `burn`)

| State | Drawn |
| :--- | :--- |
| `burn` 0, alive | the tree |
| 0 < `burn` < 1, alive | burning: the crown char from the top down to that share of its height, in `TREE_BURN_STEPS` (5) hard steps, a hard line in `CHAR_COLOUR`; VFX's flames on it |
| `burn` 1, not alive | charred: Art's burned shape (a black trunk with bare branches) at `TREE_CHAR_H` (0.6) of the tree's height |
| `burn` 0, not alive | felled: gone, as before |

- World's fire is off on main (`data/biomes/fire.json`, World's parked window 18), so until it is on, the trees stand or fall as before.

## Checked (2026-10-27)

- A scratch scene with World's fire park switched on: a blast in the hand-made world's densest stand felled 5 trees and lit 1, which burned out to charred by tick 440 (headless). For the look, the stand's nearest trees were staged in every state at once (`img/lookgate/lookgate-trees-states.png`).
