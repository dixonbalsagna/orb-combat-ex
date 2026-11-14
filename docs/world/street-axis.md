# Which way the street runs against the fight's line: `WorldStructures.streetAxis` (World, 2026-11-06)

For Encounter's turn on impact (`DirSwing` atImpact; controller vision section 4, city step one): when a body strikes a building, which way does the street it stands on run against the fight's line? A **pure read** (it writes nothing, not even SimField's scratch), `sim/world/structures.gd`:

```
WorldStructures.streetAxis(S, bi) -> {"lineSin": float, "alongSin": float, "side": int, "found": bool}
```

All three are read at the building's own point in the fight's strip, in the strip's own orthonormal pair there: *toward the camera* (`m`, the frame's great-circle normal `n = t x p` carried to the point) and *along the line* (`ex = q x n`, the way strip x grows at that depth; the line's tangent only on the line). A sine is the axis's component toward the camera, signed by how the axis is turned:

| Field | Reads | Values |
| :--- | :--- | :--- |
| `alongSin` | the street's **along** axis `t`, turned to face along the line (cosine to it not negative; square to the line it faces the camera) | **0** when the street runs along the line: no turn needed. Toward **+1 or -1** as it runs across the line; the sign says which way the line would turn to run down the street. It jumps from +1 to -1 as the street crosses square to the line (the turn is then either way). |
| `lineSin` | the **across-street** axis `s`, turned to point from the line toward the street (away from the camera when the street lies behind the line, toward it otherwise): its component toward the camera | **+1** street in front of the line and along it; **-1** street behind it and along it; **0** when `s` runs along the line (the street runs across it). Continuous in the street's turn. |
| `side` | which side of the line the street lies | **1** toward the camera, **-1** behind, **0** on the line (within one unit of depth; the building's own depth in the strip, `R asin(q.n)`) |
| `found` | whether a lot was read | false: no frame (the prototype and gen 1 and 2 worlds) or no lot holds the building. Then `lineSin` 1, `alongSin` 0 (a street along the line), `side` from the building's `z`. |

**How:** the building's lot is the one in `S.fieldRecs` (k "lot", the footprint of one street's run of buildings, along axis `t`, across axis `s`, half lengths `hl`, `hd`) that holds `S.bDir[bi]` with the least share of its half lengths (and a 40-unit sidewalk). Its two axes are carried to the building's point and read as above. It is a pass over the lots (83 on planet 7), so it is for an impact, not a per-tick read; I have not timed it. Only buildings of a field world have a `bDir`.

## What it reads on planet 7 (touch 3, a match's first 30 ticks; the full set is `STREETAXIS`)

- **Every building finds its lot** (front street 86 of 86; all 255 buildings read: rows 1 to 3 found 86, 74, 95).
- **At the start every street runs along the line**: `|alongSin|` under 0.011 and `|lineSin|` over 0.999 for all of them.
- **Every street is behind the line at the start**: the front street ("row 1", the fighter plane's row for collisions) lies **322 to 504 units behind the fight** (depth z), row 2 about 1,360 to 1,510, row 3 3,037; `side` is -1 for all. So **there is no street on the camera's side to turn toward until a swing has turned the line**: Encounter's turn is a turn toward a street behind a building, and the lot's `s` (the across axis) is the way out to it.
- **With the line turned by 0.3, -0.7 and 1.2 rad** (the frame's tangent turned about the fight's point), the sines equal a second reading: the street's own two points carried into the strip with `SimField.stripIn`, as a direction (172 reads, **worst difference 0.0004**), and the sign follows the turn (a street turned one way reads positive, the other way negative).

## Not in it

- No turn is made here; it is a read. How far to turn, and the ease, are Encounter's and Camera's.
- A building outside every lot (none on planet 7) answers `found` false.
- A swing in progress turns `S.frame` each tick; the read is the frame as it stands.

`STREETAXIS` (`sim/world/tools/street_axis_check.gd`): lots found, the start's values, depth sides, the turned-frame comparison, the sign, purity (no hash moves, SimField's scratch as it was), the same answer twice, no frame and a bad index.
