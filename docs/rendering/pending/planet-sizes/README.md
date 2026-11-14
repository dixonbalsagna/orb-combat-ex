# The tile ground at Orb's five planet sizes, steps 1 and 2 (HALF-DONE, paused for quiet time 2026-11-14)

Rendering, on the EP's order: "the sizes with the level-0 tile scaling". It follows `docs/rendering/planet-sizes-plan.md` and stacks on World's GW1c stack: `globe-step2`, `a-world-01`, `planet-sizes` with its Simulation and meteor grants, `gw1c-world`, `store-parts`, then my `feet-ground`, `foot-slice` and `marks-baked` (store-parts version). Run records: `docs/rendering/runs/fd5c1895/sizes-tiles.txt`.

**Where I stopped:** the split-aware feet check (`--split`, reading only the panes the split renders) was running at big, small and medium when quiet time came, and I stopped it. **Next:**
1. Run `feet_check_size.gd -- --tiles --split --size=<big|small|medium> --seeds=1,...,10`.
2. Run the medium gates on `sizes_tiles.diff` 4477705c (golden, the five ground checks, the render gates, the feet gate). This re-cut changed medium's branch text; the numbers should be the same, but it hasn't been run.
3. Stills of small and big against medium, then Performance's readings.

## The files

| File | What |
|---|---|
| `sizes_tiles.diff` (4477705c, 158 lines) | `render/core/tile_field.gd`, `tile_ground.gd`. Not yet gated as cut (see above). |
| `grant-world-field-size-key.patch` (6883b121) | World's `sim/world/field.gd`: the field memo keyed by the size too. |
| `feet_check_size.gd` | A scratch copy of `feet-ground`'s feet check with `--size` (World's `planetSize`) and `--split`. When this lands, these flags should go into the real check. |

## What the diff does

- `LEVEL0` follows the size, so level 0's tiles stay about 12,800 units wide (`level0_for`: tiny 1, small 2, medium 3, big 6, huge 12).
- `edge()` replaces the face edge, which was written as 38,400.
- The tile key's i and j widen to 9 bits.
- **Medium's two lattice branches read World's lattice size** (`WorldField.cells()`):
  - Big and huge fall on the lattice as medium does: levels 0 to 2 on its nodes, levels 3 and 4 on its sub-nodes.
  - Tiny and small don't fall on it. Their nodes read `WorldField.sample`, as the sim reads a column.
- The first cut read the planet's function at every node off medium. The values matched, but big's tiles arrived about eight times slower: by tick 652, 6 level-2 tiles against 47.

## Findings

1. **Medium is byte-identical (first cut, c16b87dc):** golden matches, the five ground checks pass, the render gates pass 20 of 20, and the feet gate gives 0.6% (3% allowed).
2. **World's field memo (a bug in the size stack; grant above).**
   - `WorldField._fields` is keyed by the seed alone, but `WorldPlanet` keys its memo by seed, generation and size.
   - So a medium planet 7 and a big planet 7 share one field (301 nodes a side). At big, face 5 reads past the end: 42,330 script errors in one run.
   - At small the indices stay in range, so it reads the wrong lattice silently.
   - With the grant: no errors at any size, and medium is untouched (the key is the seed alone there).
3. **The feet check needs the split at big.** Tools run without the split screen, and the game attaches it.
   - On big's seed 2 the fighters are 67,763 units apart. The one camera is 33,000 units from each, so the far fighter's ground is rightly level 0, and the check measured it.
   - My first split run chose among every pane. A pane the split had stopped rendering kept its camera and craters from the match before, so that run is void.
   - The re-run chooses only among the panes the split renders this frame (`SplitFrame.active`). That's the run I stopped.
4. **Small passes without the split:** 1.7% over 10 seeds, worst 25.0 (25 allowed).
