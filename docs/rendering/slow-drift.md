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

## The far land itself

The far land is still the render's own: each column's base height, scaled by its biome, with relief. World's `farColumn` (the planet's real ground beside the ring) costs about 50 µs a sample natively, nearly all of it the surface read. A far field for a turn's new ring would cost too much at the turn on an old laptop. World has been asked for a cheaper bulk read. When it lands, the drift reads the planet's own far land with no other change.

## Checked

- `gates9` (17 checks) and `cue_check` pass with the drift off, with 0 script errors.
- With it on, a native AI match: the angle grows 0.66, 1.32, 1.99 and 2.66 degrees at ticks 1,000 to 4,000 (53 s of match time), and the ground's `drift_tan` follows.
- Stills and GIFs (seed 4, the AI match, reduced as the demo plays it; Tools' launcher), uncommitted:
  - `img/drift-7200-d3f1ca0e.png`: d3f1ca0e, then tick 7,200 with the drift off and on (about 4.8 degrees by then);
  - `homework/progress-2026-10-22/slow-drift-time-lapse.gif`: two minutes of the match, off and on side by side, 40 times faster;
  - `homework/progress-2026-10-22/slow-drift-real-speed.gif`: four seconds at the real speed, drift on.
