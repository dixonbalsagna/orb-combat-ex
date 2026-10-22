# Parked: the planet's own far land (Rendering, 2026-10-22)

**Base:** HEAD fcc537b9 plus World's far read (`docs/world/scratch-build/far-read/far-read.diff`, `WorldFarMap`). Every check ran on copies of that, never on the tree.

**Apply after World's far read**, from the project root: `git -c core.autocrlf=false apply docs/rendering/pending/2026-10-22j/batch.diff`. Then delete this folder. The diff applies as text without World's, but `far_land.gd` needs `WorldFarMap`.

## What it changes

Behind a switch (off). On a planet match that may turn (World's epoch), the far land is the planet's own ground beside the ring, read from World's map:
- **The map:** 192 square, built 64 texels a frame (about 9.6 s at 60 frames a second, 1.3 ms a frame natively), kept per planet.
- **The ground's shaders** find each far point on the planet and read the map there. A turn costs nothing on the CPU: only the ring's uniforms change.
- **No aliasing:** each far row reads the map's mip level for its spacing in depth.
- **Only from a hard cut:** a match's start if the map is whole by then, else World's next turn. Until then, and on every other match, the far land is the band's own.
- **The drift fix:** the slow drift now turns the far relief too (22i left the relief noise fixed).

| File | Change |
| :--- | :--- |
| `render/core/far_land.gd` (+ `.uid`, new) | `FarLand`: the map per planet (built in steps, with mip levels), the ring, the cut rule, the uniforms |
| `render/core/look.gd` | `FAR_MAP_ON` false, `FAR_MAP_N` 192, `FAR_MAP_STEP` 64, `FAR_MAP_LOD_MAX` 5 |
| `render/shaders/ground.gdshaderinc` | the far map's uniforms, `far_dir`, `far_lod`, `far_cell`, `far_texel`, `far_fetch`, `far4` (both far lands; the drift turns the relief too); `ground4` reads `far4` |
| `render/shaders/terrain.gdshader` | the planet far land's colour from the biomes' shares |
| `render/shaders/water.gdshader` | the far ground from `far4` |
| `render/core/planet_view.gd` | `set_far` |
| `render/core/pane_world.gd` | `far`, sent to the ground each frame (only when it changes) |
| `render/core/main.gd` | `far_on` (`--farmap`, `?farmap=1`), `--farnow`; `begin` at a match, `step` each frame, `turn` at `arena_turn` |
| `docs/rendering/slow-drift.md`, `docs/rendering/README.md` | what it does and what was checked |

## Checked

- **Gates:** `gates9` (17 checks) and `cue_check` pass with it off, with 0 script or shader errors. With both switches off nothing changes.
- **Native probe** (planet 7, a 2,400-column ring with World's turn on):
  - a GDScript twin of the shader's read is within 0.004 units of World's `field()` at ten depths from -120,000 to 9,000; the opposite side would be 1,561 units off;
  - the map is 17 to 34 units off the exact `farField` on average;
  - the cut rule: off at the start of a new planet's match; whole after 575 steps; still off until a cut, on after a turn; on at once for the same planet again; inactive on the hand-made world.
- **The side-by-side:** `docs/rendering/img/farland-d3f1ca0e.png` (uncommitted).
  - It shows d3f1ca0e, then planet 7 at ticks 600, 3,000 and 6,600, then tick 7,200 with the drift on.
  - Main's far land is on the left, the planet's own on the right (seed 4, the AI match, reduced; Tools' launcher).
  - A first cut without mip levels streaked the horizon; the mip levels cleared it.
- **Not yet:**
  - a planet match without World's turn keeps the band's far land (the ring comes from `S.epoch`);
  - after a turn, the carry zone's far land is read beside the new ring;
  - World's map holds no settlements.
