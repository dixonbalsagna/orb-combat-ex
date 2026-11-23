# Art's crater and scar looks

Parked by Rendering, 2026-11-01, from `docs/art/crater-look.md`. `look.diff` stacks on `2026-11-01h-store-bowls/bowls.diff`. Behind `?craterlook=1` (`--craterlook`), a local word for now, on the tile ground only. Without the word nothing here changes.

**The crater:** walls in two rings, each toned by which way it faces in eight flat sides against the biome's light, the inner ring a step darker, a thin lip only on edges facing the light, a warm floor in flat stripes. Colours come from each biome's subsoil. Hard edges, no gradient. Depths and steps are `RenderLook.CRATER_RINGS` and `CRATER_STEPS`.

**The scar:** a burn, not a hole. A core in the biome's scar colour with flat stripes and a thin edge, a hard singe fringe that darkens the land by multiply so its facets show through, a ragged outline in straight runs, and a taper to a point over the last quarter of its run at both ends. Stays for good. The sim's scorch is only read.
- **Width:** the burn's own width, leaving out a knockback slide's trench, which jumps from column to column. `RenderLook.SCAR_LOOK.x` is 0.27 of it, which is Art's 45% of the old visible band. It's the strongest beam's; the weakest is 55% of that (Orb, 2026-09-29: stronger beams are more intense).
- **Taper:** the view works out how far a column is from its run's ends, from `S.scorch`, 600 columns a frame, and remakes the table only when the runs change. Runs that cross the world's seam count as two.

**Seen:**
- `docs/rendering/img/lookgate/crater-look-off-on.png`: flat ground and sea's edge, left off, right on (before the flooding fix).
- `crater-scar-frames.png` and `crater-scar-fight-sheet.png`: planet 7, seed 12345, to tick 3421, with everything on.

**Differs from Art's mock-up:**
- The beam in those frames sits mid-range, so its scar is narrower than the mock-up's.
- The rings are depth contours on the bowl's own shape, not traced quads.
- The lip is a depth band, so it isn't 5 pixels at every zoom.

**Not checked:**
- Biomes other than the ones in these frames.
- Flash on the ring steps, which Art asked for. It's off and private for now, so it's owed before this goes public.

**Cost:** two to six more texture reads per pixel inside a scar and none outside, a little per-pixel arithmetic in a crater, and one more varying. The slice's CPU cost isn't timed. **Not measured** on a GPU: the frame bench needs a quiet window.
