# The tile ground at Orb's five planet sizes, steps 1 and 2 (gated 2026-11-20; stills wait for a capture window)

Rendering, on the EP's order: "the sizes with the level-0 tile scaling". It follows `docs/rendering/planet-sizes-plan.md` and stacks on World's GW1c stack: `globe-step2`, `a-world-01`, `planet-sizes` with its Simulation and meteor grants, `gw1c-world`, `store-parts`, then my `feet-ground`, `foot-slice` and `marks-baked` (store-parts version). **It needs `rows-interp` landed first** (finding 5). Run records are in `docs/rendering/runs/fd5c1895/`: `sizes-tiles.txt`, `sizes-tiles-recut.txt` and `sizes-feet-final.txt`.

**Status:** medium is byte-identical on the re-cut, and the feet check passes at big, small and medium with the split attached and `rows-interp` in. **Next:**
1. Stills of small and big against medium, through Tools' launcher in a capture window (the export is ready; see "The export").
2. Performance's readings at small, medium and big on the same export.
3. Tiny and huge when Orb's answer comes (the plan's step 4).

## The files

| File | What |
|---|---|
| `sizes_tiles.diff` (4477705c, 158 lines) | `render/core/tile_field.gd`, `tile_ground.gd`. Gated at medium: `sizes-tiles-recut.txt`. |
| `grant-world-field-size-key.patch` (6883b121) | World's `sim/world/field.gd`: the field memo keyed by the size too. World is reviewing it. |
| `feet_check_size.gd` (2aed6e9a) | A scratch copy of `feet-ground`'s feet check with `--size` (World's `planetSize`) and `--split`. With `--split` it reads each fighter through the nearest pane the split renders, and skips a fighter outside every pane's view. When this lands, these flags should go into the real check. |

## The export

`ln/szw_site/` in my scratchpad: szs plus a scratch size word in the flash hook's film setup (`ln/tg/size_word.py`; not a park). It loads the beamduel scene at a size: `/index.html?flashcap=1&size=small|medium|big`, then `window.__flashcap.start("beamduel", {seed: 12345})`. Performance can read frames from it at each size; the planet is World's default (7, gen 3).

## What the diff does

- `LEVEL0` follows the size, so level 0's tiles stay about 12,800 units wide (`level0_for`: tiny 1, small 2, medium 3, big 6, huge 12).
- `edge()` replaces the face edge, which was written as 38,400.
- The tile key's i and j widen to 9 bits.
- **Medium's two lattice branches read World's lattice size** (`WorldField.cells()`):
  - Big and huge fall on the lattice as medium does: levels 0 to 2 on its nodes, levels 3 and 4 on its sub-nodes.
  - Tiny and small don't fall on it. Their nodes read `WorldField.sample`, as the sim reads a column.
- The first cut read the planet's function at every node off medium. The values matched, but big's tiles arrived about eight times slower: by tick 652, 6 level-2 tiles against 47.

## Findings

1. **Medium is byte-identical, on the first cut (c16b87dc) and on the re-cut (4477705c):** golden matches, the five ground checks pass, the render gates pass 20 of 20, and the feet gate gives 0.6% (3% allowed), the same numbers both times.
2. **World's field memo (a bug in the size stack; grant above).**
   - `WorldField._fields` is keyed by the seed alone, but `WorldPlanet` keys its memo by seed, generation and size.
   - So a medium planet 7 and a big planet 7 share one field (301 nodes a side). At big, face 5 reads past the end: 42,330 script errors in one run.
   - At small the indices stay in range, so it reads the wrong lattice silently.
   - With the grant: no errors at any size, and medium is untouched (the key is the seed alone there).
3. **The feet check needs the split at big.** Tools run without the split screen, and the game attaches it.
   - On big's seed 2 the fighters are 67,763 units apart. The one camera is 33,000 units from each, so the far fighter's ground is rightly level 0, and the check measured it.
   - My first split run chose among every pane. A pane the split had stopped rendering kept its camera and craters from the match before, so that run is void.
   - The re-run chooses only among the panes the split renders this frame (`SplitFrame.active`).
   - It also skips a fighter outside every rendered pane's view (beyond 1.25 of its half width). On big's seed 2, for two ticks while the split opened, one fighter was 31,700 units from the only pane's camera. No picture shows his feet then.
4. **Small passes without the split:** 1.7% over 10 seeds, worst 25.0 (25 allowed).
5. **The feet at each size, split attached, ten seeds** (`sizes-feet-final.txt`):

   | | without `rows-interp` | with `rows-interp` |
   |---|---|---|
   | big | 2.5% over 8, worst 35.0: **fails** | 0.1%, worst 8.9 |
   | small | 5.2%, worst 25.0: **fails** | 0.0%, worst 2.2 |
   | medium | 1.1%, worst 16.6 | 0.0%, worst 1.6 |

   - Every failure without it is the case `rows-interp` fixes, at any size. Big's seed 4 is the worst: he stood at 0.91 of the way from a column with a +37-unit deform spike to the next. The sim interpolates between the two columns; the rows drew the first column's whole residual.
   - With it, all three sizes meet the ratchet the EP set for when it lands: at most 0.5% over 8, nothing over 12.
   - So this park lands after `rows-interp`.
