# Park: the store's and water records' box key packed 20 bits an index, and `size_check`'s field-memo row (World, 2026-11-20; GW1c readiness C-24, Simulation's pointer, Rendering's field-memo grant)

| File | What |
| :--- | :--- |
| `box-key-20bit.diff` | `sim/world/store.gd` and `sim/world/waterrec.gd`: `_key` packs each box index into 20 bits with an offset of 524,288 (Simulation's `SimField._boxKey` packing, `docs/architecture/pending/boxkey-gw1c`), replacing the offset that grew with the radius (`_koff`, a margin of two boxes). `oldKeyOffset` (tests only, 0) gives the old key back for the negative control. `sim/world/tools/size_check.gd`: the old `_koff` negative control now sets `oldKeyOffset` 64; rows added (below) |

Stacks after `globe-step2`, `a-world-01`, `planet-sizes` (+ its grants), `gw1c-world` (+ fix) and Rendering's `grant-world-field-size-key.patch` (the field-memo row needs it); strict-applies there (checked from a clean export).

## Why

C-24: the store's key left a margin of two boxes past the radius, but a record is listed out to twice its own radius. At huge (offset 98) a crater wider than about 1,280 units near an axis point lists past the margin, and from about 2,300 its key equals a real box's on the far side: boxes (0, 100, 0) and (1, -96, 0) had one key. No wrong height was seen from it; the comment's claim ("no two boxes share a key") was not true. The 20-bit packing is exact to half a billion units, so no size (colossal's radius is 190 boxes) or reach can alias, and nothing follows the size. A key is only looked up (a dictionary key, never walked or hashed), so its values change nothing a match computes: **the golden does not move**.

## Rows (`SIZES`, `docs/world/runs/box-key-20bit/`)

- Two boxes of the huge planet that a 64 offset would give one key have two: the store's key and the water records' grid.
- The pair (0, 100, 0) and (1, -96, 0): one key with the old offset of 98 (so the pair is real), two now, in both grids.
- No two boxes share a key in three slabs of 224 x 224 boxes (112 boxes either way from the centre): 0 shared in the store, 0 in the water records.
- The field memo: a field made at tiny (80 nodes an edge) is not returned for medium (300); asking again at tiny gives the tiny field back.

`SIZES`: 0 failed. **Negative controls**: `--negative-control` (the old key at 64): 3 FAIL (the two 64-offset rows and the slab row: 64,224 boxes shared in each grid). The memo row **without** Rendering's grant: 1 FAIL ("a field made at tiny (80 nodes an edge) is not returned for medium (80)": the memo returned tiny's field for medium); with it, 0.

## NEEDS FROM EP

- Land with the planet-sizes stack (GW1c), after Rendering's field-memo grant.
- Simulation: none; their `SimField._boxKey` fix is the same packing and independent.

## RISKS

- `oldKeyOffset` is a tests-only switch in two hot functions (one comparison a call, not measured, shared machine).
- Keys are 60 bits: they fit an int, and nothing stores one in a 32-bit array (checked: both tables are dictionaries).
