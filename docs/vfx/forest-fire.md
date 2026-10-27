# Forest fire (VFX, window 4 of the biome effects)

World's burn field (`sim/world/fire.gd`, behind `data/biomes/fire.json` `enabled`, **off**; docs/world/forest-fire.md) sets a tree's own `burn` and nothing else shows it: a blast or a beam fells the trees inside its ring and may light the ones just beyond, a burning tree's `burn` runs 0 to 1 over its burn time and the tree is then dead with `burn` 1. The sim's only cue is one `fire` event at the foot on ignition and on burn-out (`earth.gd` throws a few flames then). This is what a burning tree looks like in between.

## What it draws (`render/vfx/forest_fire.gd`, `VfxForestFire`)
From the tree's own state (`0 < burn < 1` and alive), so a seek, a snapshot or a late join draws the same fire:
- **Flames**: the pool's cel flame bit (three-banded tongue, Art's orange `#ff9a2e` body with the ember ramp's hot and core bands), set inside the tree's silhouette (below), 0.6 to 1.0 s each. A flame grows in over a tenth of a second and burns down (shard_view), so no flame is a one-frame pop.
- **Embers**: the pool's ember bit (steady, on Art's ramp), a few a second, rising and drifting.
- **Smoke**: a thin dark puff column from the char line, 2.4 to 3.4 s, rising (the pool's `smoke`, the city tone). None in reduced motion.
- **Intensity** follows the tree's burn: it catches up over its first tenth, burns full, and dies down over its last third (`VfxForestFire.intensity`). A charred tree (burn 1, dead) and a felled one (burn 0, dead) draw nothing; a tree that is out (water) draws nothing.

## Where it burns: the crown, not a cone
The planet view draws each fellable tree as one of Art's cover silhouettes (fir, spruce, palm, acacia, jungle tree, mangrove, the broadleaf; `render/core/tree_view.gd`), and burns it from the top: a crown chars in `RenderLook.TREE_BURN_STEPS` hard steps, a burnt-out tree is a charred trunk. The fire reads the same shapes (`render/core/cover_meshes.gd`, read only):
- **The crown of a kind**, read once from its cover mesh: where its vegetation starts and ends up the height (a palm's or an acacia's high on a bare trunk, a fir's down near the ground) and its half width in eight bands (the widest |x| along the vegetation triangles' edges). Flames are set inside that outline.
- **The live span** (`VfxForestFire.live_span`): from the crown's foot to the char line. The line sinks with the burn's steps, and the foot reaches down the trunk as the crown goes, so the fire ends on the trunk the planet view leaves standing. Smoke leaves the char line; embers rise from the live span.
- **Which kind**: Rendering's pick, through a hook (`kind_of`, set from `render/core/pane_world.gd` to `RenderTrees.kind_at`). With no hook every tree is the broadleaf.
- Flame data `h` is now where in the live span a flame sits (0 the foot, 1 the char line).

## Budgets
- Looks for burning trees every 6 ticks within the framing's span of the pair (900 + 0.7 of their separation, at most 2,600), and draws the nearest 24; the rest of a big stand is only counted.
- Flames stay under 36 alive in the pool (earth.json's flame cap, 40, is the explosions'), embers under the pool's ember cap and drawn-area limit, smoke under the puff area budget.
- A burning tree's fire is drawn at its depth, or, where another tree stands in front of it with a crown that reaches over this one's, in front of that one (the stand's face burns, not a hidden middle). The silhouettes are flat, so the fire sits a hair (an eighth of TREE_W) in front.
- Rates are per tree per second at full intensity: flames 4, embers 1.4, smoke 1.0; scaled by quality, halved in reduced motion. Everything is in `data/vfx/biome.json` `fire` (schema `vfx-biome.schema.json`).
- Switch: `hub.forest_fire_enabled` (`VfxLook.FOREST_FIRE_DEFAULT`, on); it does nothing while the sim's fires are off (no tree has `burn`).

## Legal
Steady orange and dark smoke; a flame is on screen about a second and grows in over 0.1 s; no flame, ember or smoke is white-hot or red; no luminance step on the frame beyond a flame's own size (a flame is a few percent of the frame at most). Not run through the flash register or the pixel analyser (nothing asks the register); a fixed clip for it is a Tools question (see the report).

## Not done
- **Buildings do not burn** (World: not done, collateral rules are Game Design's).
- The look is first-pass and by eye (sizes, rates); every number is data.
