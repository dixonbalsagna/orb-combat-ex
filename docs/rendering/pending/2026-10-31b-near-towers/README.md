# Parked: Orb's near-tower pick (`2026-10-31b-near-towers`)

Rendering, 2026-10-31. Stacks on `2026-10-31a-tile-ground/tile.diff` (a7cc87de). On only with the tile ground's switch, and only when a swing brings a building nearer than its plan, so at rest and off nothing changes. `nearmode=0` to `4` still switch the old ones.

**Orb's pick (docs/ep/vision.md, the picture in homework/Files/near-tower-q-red-squares-2026-10-31.png):** A's shape, Q's slightly kept bases, and the cut eased where it wedged or spiked a tall tower.

**What it does (`globe_tower`, mode 3):** the whole building goes down, its near side leading. How far the near side leads is bounded by the building's own width (`globe_lead`, a rise of a quarter of its width across it), so a tall tower's roof can't turn into a wedge or a spike. Its base stays (`globe_base`, 90 units, or the whole building if it's lower) instead of sinking under the ground.

**Apply:** on a scratch export with the tile diff on it: `git -c core.autocrlf=false apply --ignore-whitespace near.diff`.

**Seen:** `docs/rendering/img/lookgate/near-towers-pick.png`, the view-only turn at 60°/s over a flat gen 2 city. Stills only. A tower that's a stack of parts squashes each part about its own foot, so a cap can part from its body: not seen in these stills, not ruled out.

**Not run yet:** flash with real swings, which is in the hunt.
