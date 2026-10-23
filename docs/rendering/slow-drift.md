# The slow drift (Rendering, 2026-10-22)

World's window 2 (`docs/world/shifting-arena-design.md`): between turns the arena is fixed, and the far land and the sky turn slowly round the fight. It is cosmetic and render only. The sim's band never moves.

## What it does

- **The far land shears sideways by its depth.** A point `z` units behind the fighter plane is read `z` × tan(angle) further along the ring (`ground.gdshaderinc` `far_x`, uniform `drift_tan`), weighted by the far blend. So:
  - the crater band and everything the fight stands on stay exactly where they are;
  - the land beyond turns about the fight, more the further it lies.
- **The sky turns its azimuth by the same angle** (`sky.gdshader` `sky_turn`): the clouds and the stars. Far land at the horizon and the sky move together.
- **The rate is constant:** `RenderLook.DRIFT_DEG_PER_MIN` (3) degrees a minute of match time, up to `DRIFT_MAX_DEG` (30). It starts from 0 at each match's start.
  - Match time stands still in a hit-stop or a set piece's pause, so the drift does too.
  - About 0.0008 degrees a frame: never motion you can see from frame to frame, only a slow change over half a minute or so.
- **At World's turn** (`arena_turn`) it starts from 0 again on the new ring, under the turn's hard cut.
- **Crisp:** no fade, no blur, no blend; the far land and sky are drawn as they always were, at a turned angle.
- **Off by default:** `RenderLook.SLOW_DRIFT_ON` false. Main's `--drift` or `?drift=1` on a page turns it on.

## The planet's own far land (2026-10-22)

On a planet match that may turn (World's epoch), the far land is the planet's own ground beside the ring, read from World's `WorldFarMap` (`render/core/far_land.gd`).

- **The map:**
  - a `RenderLook.FAR_MAP_N` (192) square octahedral map of the planet's heights and biomes;
  - built `FAR_MAP_STEP` (64) texels a frame: 575 frames, about 9.6 s at 60 frames a second, about 1.3 ms a frame natively;
  - kept for the planet (the last two), so the same planet again has it at once.
- **Read on the GPU.** The ground's shaders find each far point on the planet themselves (`ground.gdshaderinc` `far_dir`): the ring's point at the column, moved over the surface at right angles to the ring. Behind the fighter plane is toward the ring's axis, as `farColumn`'s positive z. They then read the map there (`far_cell`, `far_fetch`, `far4`).
  - A turn costs nothing on the CPU: only the ring's uniforms change.
  - World's `field()` is not called. It is the check: a GDScript twin of the shader reads within 0.004 units of it on planet 7, at ten depths from -120,000 to 9,000.
- **Its look:**
  - each texel carries its biome's far multiplier and relief amplitude (`FAR_RELIEF`), so the far relief is drawn as before, over the planet's own shape;
  - the colour comes from the biomes' shares at the texel.
- **No aliasing.** The map has mip levels. A far row reads the level whose texel matches the rows' spacing in depth there (`far_lod`: `ROW_GROWTH` of the distance, up to `FAR_MAP_LOD_MAX` 5). Without them, the planet's small seas aliased between the sparse far rows into streaks along the horizon.
- **Only from a hard cut:**
  - it shows from a match's first frame if the map is whole by then, else from World's next turn (`arena_turn`), under its cut;
  - until then the far land is the band's own, as ever;
  - it never switches in view.
- **The slow drift turns it too:** the place read moves along the ring by z × tan(angle), relief and all. It also fixes 22i, which turned the base and the biomes but left the relief noise fixed: the relief now turns too, with the sheared field's slope in depth.
- **Off by default:** `RenderLook.FAR_MAP_ON` false. Main's `--farmap` (`?farmap=1`) turns it on; `--farnow` (`?farnow=1`) builds the map whole at the match's start, for stills and probes.
- **Not yet:**
  - a planet match without World's turn keeps the band's far land: the render reads the ring from the epoch (`S.epoch.ring`);
  - after a turn, the far land beside the carry zone's columns (the old ring's) is read beside the new ring; the rings cross at the pivot, so near it they nearly agree;
  - settlements are not in World's map, so no towns or cities stand in the far land.

## Checked

- `gates9` (17 checks) and `cue_check` pass with the drift off, with 0 script errors.
- With it on, a native AI match: the angle grows 0.66, 1.32, 1.99 and 2.66 degrees at ticks 1,000 to 4,000 (53 s of match time), and the ground's `drift_tan` follows.
- Stills and GIFs (seed 4, the AI match, reduced as the demo plays it; Tools' launcher), uncommitted:
  - `img/drift-7200-d3f1ca0e.png`: d3f1ca0e, then tick 7,200 with the drift off and on (about 4.8 degrees by then);
  - `homework/progress-2026-10-22/slow-drift-time-lapse.gif`: two minutes of the match, off and on side by side, 40 times faster;
  - `homework/progress-2026-10-22/slow-drift-real-speed.gif`: four seconds at the real speed, drift on.
- The planet's own far land, on HEAD plus World's far read (`docs/world/scratch-build/far-read/`):
  - `gates9` (17 checks) and `cue_check` pass with it off, with 0 script or shader errors. With both switches off nothing changes: the band's far land reads the same place as before.
  - A native probe:
    - the shader's twin against World's `field()` and `farField` (above);
    - the hard cut: off at the start of a new planet's match, whole after 575 steps, still off until a cut, on after a turn, on at once for the same planet again, inactive on the hand-made world.
  - `img/farland-d3f1ca0e.png` (uncommitted): d3f1ca0e, then planet 7 on a 2,400-column ring at ticks 600, 3,000 and 6,600, and at 7,200 with the drift on; the band's far land on the left, the planet's own on the right (seed 4, the AI match, reduced; Tools' launcher).
