# The foreground clamp's teeth and the river's band (planets 12 and 17, GW1b's quick-match draw)

Rendering, 2026-11-14, on the EP's GO. `fore_fix.diff` (sha1 353a4cb2, 88 lines, cut on main e56d372c + Camera + A-CODE-03 + `look-recut/`) touches `render/shaders/tile_read.gdshaderinc`, `tile_vertex.gdshaderinc`, `water.gdshaderinc` and `render/core/tile_ground.gd`.

## The faults (`docs/rendering/runs/4f06e7a3/planets-fore-test.txt`)

The tile ground's foreground rule (`tile_fore`) holds every vertex in front of the fighter plane at or under the sight line to the line's own ground. On ground that rises toward the camera:
- **planet 12's beach grew teeth;**
- **planet 17's river read as two bands** with green ground between.

## The change, three parts

1. **The profile's window.** The rule read the line's 64-point profile at `p.x / (1 - t)`, with `t` up to 0.95 near the lens, so a vertex's step there spans many points and neighbours were held to very different heights.
   - It now reads the lowest within a window that grows with that spread, as the strip's rule already does (`FORE_SPAN`).
   - The window comes from four more rows of the profile (the lowest within 1, 2, 4 and 8 points either side), picked by `log2(1 / (1 - t))`.
   - A held vertex is lit as the flat ground it's drawn as.
2. **The drop stops where `t` stops.** Past 0.95 of the way to the lens the line stopped rising but kept dropping by `fore_drop × depth`, so the mesh's vertices past the camera were held ever lower.
3. **The water keeps its order over its bed.** Where the water was above its bed and both were held to the same line, the sheet had no depth and wasn't drawn. Now the sheet stays a unit over its held bed, with the depth it had for its colour. A dry place is never moved.

## What it took (the readings that ruled versions out)

Tools' capture-web + analyse-frames on the `beamduel` scene, the only one that reads the planet word (900 ticks, seed 12345). Records are `docs/rendering/runs/e56d372c/fore-fix-flash-v2.txt`, `-v3.txt` and `-v4.txt`.

- **v2 lowered held ground 6 units under the line.** It flooded the near ground with water on planet 17, reduced mode, frame 135, which read 4.5 on the lower threshold. Dropped.
- **v3 (parts 1 and 2):** no regression. Planet 17's band was unchanged.
- **v4 (all three), as parked.** Primary / threshold 15% lower / two-second memory:

| | before | v4 |
|---|---|---|
| planet 12, normal | FAIL 3.5 / 4.5 / 3.5 | FAIL 2.5 / 2.5 / 3.5 |
| planet 12, reduced | FAIL 4.5 / 4.5 / 2.5 | FAIL 3.5 / 3.5 / 2.5 |
| planet 17, normal | PASS 1.5 / 1 / 1.5 | PASS 1 / 1 / 1.5 |
| planet 17, reduced | PASS 1.5 / 1.5 / 1.5 | PASS 1.5 / 2.5 / 1.5 |
| planet 7, normal | FAIL 3.5 / 3.5 / 3 | over the 2.5 gate, 3 / 3 / 3 |
| planet 7, reduced | FAIL 3 / 4 / 3.5 | FAIL 3 / 4 / 3 |

Planet 12 improves and nothing regresses; planet 7 is as it was within the captures' spread. This isn't the standard flash set (no `beamduel` clip there), so it's a fair before and after, not a register reading.

## The look (uncommitted, show fighters)

`docs/rendering/img/lookgate/fore-clamp-v4-sheet.png` (shipped against v4) and `fore-clamp-p<N>-t*.png` (v4's stills of planets 12, 17 and 7):
- **Planet 12:** the near-lens teeth (tick 301) are gone.
- **Planet 17:** the river's green band is half gone: on the left the water runs on unbroken, while a green strip remains on the right.
- **Planet 7:** unchanged.

**Planet 12's second sawtooth (tick 451) isn't this rule's:** it's the profile's groove. By tick 451 the beam has cut a groove along the line, which the profile includes and the tiles on this base don't draw, so ground in front is held down to an undrawn floor. With `feet-ground` + `marks-baked` (the grooves in the tiles) it's gone (`fore-clamp-p12-with-marks.png`: shipped, v4, v4 + the feet parks). So it lands clean once marks-baked follows.

## Owed

- The render gates and ground checks on the v4 tree.
- The flash on the standard set (planet 7 is the standard set's world) when this goes to the EP's gate.
