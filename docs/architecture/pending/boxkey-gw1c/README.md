# Parked: SimField's box keys can't alias at any planet size (owed before colossal is offered)

Simulation, 2026-11-20, sprint A1, for GW1c. World's planet-sizes park lists it under Simulation: "Before colossal is ever offered: `SimField._boxKey`'s offset (a radius past 131,000 units aliases), the same fix the store got."

## What was wrong

`SimField._boxKey` packed a box's three indices with an offset of 64 and 7 bits each, so it held indices from −64 to 63. A box is 2,048 units (`CEIL_BOX`), so past a radius of 131,072 units two boxes could share a key. Medium (24,446) and huge (97,786) are inside that; colossal (38,400 columns, a radius of 195,571, 96 boxes) isn't.

The keys feed two tables, `_cr` (the most World's records can make the ground, by box) and `_rise` (crater rims, by box). Both are only ever bounds, and a merged key takes the higher or the summed value, so aliasing could only make the planet ceiling more cautious, never wrong. Still, it's wrong, and it's owed.

## The fix

The key now packs each index into 20 bits with an offset of 524,288. That's exact for any box within a billion units of the centre, so no planet size and no reach can give two boxes one key, and nothing has to follow the planet's size.

The two tables are only ever looked up, never walked or hashed, so the key's values change nothing a match computes. **The golden doesn't move.**

The store's own fix (World's planet-sizes park) takes another route: an offset that grows with the radius, plus a margin of two boxes. A store record reaches up to `REACH_R` (2) crater radii, and a store box is 1,024 units. So where a direction lies close to one of the three axes, a crater wider than about 1,000 units could list into a box past that margin, on a size big enough to use it. That's arithmetic, not a fault I've seen; it's a pointer for World.

## Apply

Independent of the planet sizes: it applies on main, and on top of `../../../world/pending/planet-sizes/grant-simulation-sizes.patch` (checked). `git -c core.autocrlf=false apply boxkey.patch`.

| Patch | Files | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `boxkey.patch` | `sim/core/field.gd`, `sim/core/tools/ceil_check.gd` | 4415e71dfcf3bdcf5ee569e936b92afe1a2f63e4 | f2207ba5dce8 |

`ceil_check` gets a row: no two boxes share a key out to 112 boxes from the centre (colossal's radius is 96), on three slabs through the planet, with two pairs that shared a key under the old offset. Its negative control shows the old offset giving one of those pairs a single key.

## Proof

Records in `docs/sim/runs/554430ad/boxkey/`. On HEAD 554430ad:
- **The golden is byte for byte** (9 matches, 174,798 ticks).
- **Parity through `gate.mjs`: exit 0**, no SCRIPT ERROR lines.
- `ceil_check` 0 failed (the new rows with it). Its negative control: 0 failed, which means every break was seen, the old offset's included.
- Import, validator, determinism lint, the two-fighter ratchet (365), the load split.
- Rendering's 15: all pass.
