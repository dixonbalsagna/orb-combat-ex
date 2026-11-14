# Art's crater and scar look on by default: the black fill gone (A-RENDER-04)

Parked by Rendering on 2026-11-08 and re-cut for sprint A1 on 2026-11-14, on Orb's decision 3 ("the crater look with the black fill removed" as a default, as this work has it and no wider). **It stacks on `globe-default`.** `crater_look_default.diff` (sha1 1e3108a1, 23 lines, cut on main e715c9cc with globe-default 54b06089) changes `render/core/main.gd` alone:
- `RenderTileGround.crater_look` is on unless `--nocraterlook` (`?nocraterlook=1` on a local page);
- the test word goes in both URL lists, next to `craterlook`, so it stacks on Tools' A-CODE-03 too.

## The cause (docs/rendering/runs/1931a0f8/terrain-step0-a.txt)

The black "crater" in Orb's 8 November play is a beam struggle's scorch groove:
- full burn over 8,192 units of line;
- half widths of 328 to 1,002 units;
- 73 scorch records in the store.

With Art's look off (the 9 November build's address carries no `craterlook`), the old scar fills the whole groove width in the scar fill (biome tone 9, #221c18). It's decided per vertex against a hard threshold, so on coarse tiles it covers whole triangles: one flat near-black area with a spiky edge. Art's look reads the scar per pixel from the column, at 27% of the burn width, outlined and striped. It also draws a crater's walls and floor in Art's flat tones. Only the tile ground reads it, and its per-frame cost is `_scar_slice` (a few columns a frame, rebuilt only when the set of scarred columns changes).

## Proof

On main e715c9cc with globe-default and this park (`docs/rendering/runs/e715c9cc/crater-look-default-2.txt`):
- it imports clean, and `golden.json` is byte-identical;
- the tile, lake water, cover water, sweep and ground checks pass;
- the render gates pass 20 of 20.

## The look (uncommitted, show fighters)

- **Against the 9 November build and globe-default:** `docs/rendering/img/lookgate/a1-crater-vs-nov9-*` and `a1-crater-vs-globe-*`. It's one computer match (seed 12345, ticks 1 to 1,201 every 100). `crater-vs-globe` is the same match with only this switch, and the crater's band near the ground changes from a wide fill to a thinner outlined band.
- **On Orb's own 8 November play** (his build, his window, his words, with and without the look): `terrain-a-scar-t3880.png`, `-t4000.png` and `terrain-a-scar.gif` show the black crater. `terrain-crater-*` shows an ordinary launch crater at tick 2423.

## Flash (for the EP only)

`docs/rendering/runs/fcd6706c/look-defaults-flash.txt`: collapse and clash, both modes, with the default on, against globe-default alone and against main as built (Tools' pixel clips, no page word, one capture at a time). Normal / reduced:

| | clash | collapse |
|---|---|---|
| main as built (the old ground) | 4.5 / 4.5 | 5 / 4 |
| globe-default | 5.5 / 6.5 | 2.5 / 3 |
| globe-default + this park | 5.5 / 6.5 | 4 / 3.5 |

Clash is unchanged by this park; collapse rises by 1.5 and 0.5 against globe-default alone. That agrees with the 2026-11-08 reading on the tile ground (`docs/rendering/runs/d985eb15/crater-look-default.txt`: collapse 3 to 4). Per A-RENDER-04 acceptance 4, a reading over the limit goes under RISKS for the EP to route, and the look isn't degraded to move a number (ADR 0010).
