# The street grid and the depth API (D, E, F of Orb's depth addition)

Owner: World and Environment. 2026-10-12. Scratch only (nothing in the tree changes until the EP's go). Files: `docs/world/scratch-build/city3/` (`files/` the finished copies, `city3.diff` the three code files against HEAD, `mk_grid.py` the data step), pictures in `docs/world/stills/streets3/` (review diagrams, uncommitted, not for a public page).

Orb's picture: a neighbourhood whose streets make a perfect grid, as deep as the Z axis is, with the fight able to happen over any intersection.

## D. What the lane table needs for a grid as deep as the band

The band is 32 fighter heights deep (bh = 75 units). A grid there is **streets along the planet** (lanes of kind `street`) crossed by **avenues** (x intervals the generator leaves empty in every block row; `S.lanes` carries them). An intersection is an avenue crossing a street. Three things decide how it reads: how many streets stand in the band, how often an avenue falls, and whether the crossing is clear air from the ground to the sky.

| Option | Streets in the band | Block rows | Band | Avenues in Bellgate | What it costs | Depth off (60 matches): front row / all rows / civilians lost, length, t4 %/min |
|---|---|---|---|---|---|---|
| Today (city2) | 2 (front 9 bh, back 6 bh) | 2 | 32 bh | 3 | nothing | 31.5 / 25.6 / 18.5 %, 381 s, 7.89 |
| **G** Tighter avenues | 2 | 2 | 32 bh | 10 | data only (`block_bh`, `avenue_bh`, widths) | 33.8 / 28.1 / 18.6 %, 387 s, 8.60 |
| **P (pick)** Three streets | **3** (front 5, middle 5, back 5 bh) | 2 | **32 bh, unchanged** (z_front 2.5, z_back -29.5) | 10 | data only (`lanes.json`, plus G) and one line of `lane_check.gd` | 32.4 / 27.0 / 18.5 %, 389 s, 8.20 |
| **Q** The literal 4 x 4 | 4 | 3 | 40 to 48 bh | 10 | a fifth row id (0 to 4) in `S.lanes`, the terrain rows (T), the director's lane use, Camera's framing; not data-only | not measured: it needs L4's depth planning to mean anything |

**The pick is P.** It keeps the band, the sim's row ids and every neutral proof; it puts a second along-street in the middle of the band (the one the fight passes through when it drifts from the front street to the back), so the picture is three streets crossed by an avenue every 11 to 15 fighter heights: about a 3 x 4 grid of crossings in a 4,500-unit stretch of downtown. Near downtown's centre there are **15 crossings within 3,000 units** (3 streets x 5 avenues, `isect_check.gd`). Q is the picture of "perfect 4 x 4" and is the next window, if Orb wants the whole band to be a grid rather than three streets and two block rows; it needs a deeper band, which is Camera's call and L4's.

**The street table in P** (fighter heights, z toward the camera): foreground 10 to 5 (row 0, empty until Camera frames it), front street 2.5 to -2.5, block 1 -2.5 to -11 (row 1), middle street -11 to -16, block 2 -16 to -24.5 (row 2), back street -24.5 to -29.5, scenery -36.5 to -44.5 (row 3). Each street has five strips (sidewalk 0.9, kerb 0.7, carriageway 1.8, kerb 0.7, sidewalk 0.9). Two things move for the other directors: **Rendering** `STREET_STRIPS` 8 to 16 (three streets, five strips each, plus the foreground's), and **Camera** confirms the band `z_front` +2.5 and `z_back` -29.5 (the front street is narrower than today's 9 bh because the middle one now takes the depth).

**Clear air at an intersection.** The generator never puts a footprint in an avenue (blocks end at the avenue's edge) and never in a street lane (the blocks start where the lane ends), so an intersection is clear from the ground to the sky by construction. Checked: 17 avenues across the planet hold no row 1 or row 2 footprint (0 overlaps); the 15 crossings near downtown's centre hold none; `clearLane` at each crossing's centre returns its own depth. One qualification: a **foreground** building (row 0, when Camera frames it) stands in front of the front street and not in the grid; it is the see-through patch's concern, not the intersection's.

**Where a brawl's centre may stand.** The rule I propose, and the one the helpers below answer:
1. In a street lane at any x (the street runs the whole planet): the depth is clamped so the body's half depth (0.3 bh) fits inside the lane.
2. In an avenue at any depth of the band (from the front street to the back one, through both block rows): the avenue is a corridor across the blocks, so a brawl standing at an intersection may be dragged across it to the next street. Its x must keep the body's half width (0.3 bh) inside the avenue.
3. Nowhere else below a roof. Above a building's standing top the sky is clear at any depth (the box is the building's footprint to its top), which is how a launched flight crosses a block at a height.
A brawl's centre dragged toward a block is therefore moved to the nearest street (that is `clearLane`), or, inside an avenue, left where it is. **The three-street table doubles the places a fight can be pulled to** without opening the blocks.

**Numbers for the pick** (depth on, 60 matches, seeds 1 to 60): see section E.

## E. Rebase of L3 and T on today's main; neutral with depth off; depth on on the new city

- **T** (the terrain rows) is committed and dormant: nothing to rebase. **L3** (the swept tests, `docs/world/scratch-build/l3/l3.diff.new` against today's HEAD `bd7f6e9f`) applies cleanly to the new city's files (`structures.gd`, `brunt.gd`; `lanes.gd` and `lanes.json` carry the body's half extents, already in `city3/files`).
- **Neutral with depth off, proved:** the 30-match digest (default arm, seeds 1 to 30) is `6b725c77da1e9613` for HEAD and for HEAD with L3: the same. Matches 30; PROTAGONIST 15 wins, RIVAL 15; length 359 s; collateral 17 % of civilians, 33.7 of 169 structures.
- **Depth on, the city2 re-lay (60 matches, seeds 1 to 60):**

| | front row lost | all rows lost | civilians lost | length | t4 structures all rows (%/min) |
|---|---|---|---|---|---|
| depth off | 31.5 % | 25.6 % | 18.5 % | 381 s | 7.89 |
| depth on, no L3 | 34.3 % | 27.9 % | 18.8 % | 388 s | 8.46 |
| depth on, with L3 | 31.5 % | 20.3 % | 16.9 % | 386 s | 6.15 (near the floor of the structure-rate band, 6) |

With true collisions the all-rows loss falls by about a quarter: a blast and a flight now stop at the building they meet instead of the aimed one, and the towers behind a front block are less often reached. That is the intent; the t4 rate is still inside the band, so it needs no re-tune, but it is the one number to watch when L4 starts moving fighters in depth.

- **Depth on, option P** (the three-street table):

| 60 matches, seeds 1 to 60 | front row lost | all rows lost | civilians lost | length | t4 all rows (%/min) |
|---|---|---|---|---|---|
| city2 (2 streets), depth on, no L3 | 34.3 % | 27.9 % | 18.8 % | 388 s | 8.46 |
| **P (3 streets), depth on, no L3** | 32.4 % | 26.9 % | 18.6 % | 383 s | 8.35 |
| city2, depth on, with L3 | 31.5 % | 20.3 % | 16.9 % | 386 s | 6.15 |
| **P, depth on, with L3** | 32.1 % | 21.3 % | 17.9 % | 380 s | 6.59 |

P changes nothing the other proofs would notice: the numbers sit within the noise of the city2 rows, and the C1 rule holds (0 failures in 60 matches in both). With L3 the t4 rate stays above the band's floor of 6 (6.59 against 6.15).

### Grants L3 and the depth windows need from Simulation

None for L3 as built: it lives in World's files (`structures.gd`, `brunt.gd`, `lanes.gd`, `lanes.json`) and runs only when `S.depthOn`. T's lines in `state.gd`, `sim.gd`, `hash.gd` are in the tree already. What the **depth windows** need:

| File | Line(s) | For | Whose switch |
|---|---|---|---|
| `sim/core/fighter.gd` | the free branch's contact rule: a fighter that meets a building (not a launched body) is stopped at its face and slid along the wall by the normal `sweep` returns; called from `stepZ`'s position update, a few lines, by grant | L4 | Encounter and Simulation |
| `sim/core/sim.gd` | none (T's `initRows` line is in) | | |
| `sim/core/state.gd`, `hash.gd` | none for L3; the pick adds no state (`S.lanes` stays derived and unhashed) | | |
| `data/combat/depth.json` | the `enabled` switch (L4's); World never touches it | L4 | Encounter |
| `sim/director/launch.gd` (`DirLaunch.predictFlight`) | the director's launch predictor still ignores buildings; with depth on, an unaimed launch can meet one unplanned; L4 chooses whether to call `WorldStructures.sweep` there | L4 | Encounter |

**What L4 needs from World** (all exist, scratch or tree): `WorldLanes.clearLane(S, x, z)` (the nearest street depth a body fits), `WorldLanes.laneAt(z)` (which lane holds z), `WorldStructures.blocked(S, x, y, z, rx, ry, rz)` (the lowest building the body overlaps, or -1), `WorldStructures.sweep(...)` and its wall normal (`nx`, `nz`, `face`), plus `WorldLanes.limits()`, `streets()`, `avenueAt()` and `intersections()` (new, below) and `WorldTerrain.groundY(S, x, z)`.

## F. The note for Encounter's L4: the depth API in one page

Everything below is a pure read of the sim state, in units (bh = 75), z positive toward the camera, x wrapped (`SimWrap.sdx`). None writes state; none uses a clock or a random.

| Question | Call | Returns |
|---|---|---|
| The band's limits | `WorldLanes.limits()` | `[z_front, z_back]` in units (188 and -2213 in P): a flight outside them is a bug |
| The nearest clear street depth at an x | `WorldLanes.clearLane(S, x, z)` | the depth, clamped into the closest street lane no footprint overlaps for the body's half depth; `z` itself when the table has no street |
| Which lane holds a depth | `WorldLanes.laneAt(z)` | an index into the `lanes.json` array, or -1 |
| The street lanes | `WorldLanes.streets()` | `[[z_top, z_bottom], ...]` front to back |
| Is x inside an avenue (a corridor across the blocks) | `WorldLanes.avenueAt(S, x, pad)` | the avenue's index, or -1; pass the body's half width as `pad` so the whole body fits |
| Intersections near a point | `WorldLanes.intersections(S, x, r)` | `[[cx, cz, hx, hz, d], ...]` nearest first: the centre (x, z), the half extents of the crossing, and the distance from x; empty when the table has no avenue |
| Does a body overlap a building | `WorldStructures.blocked(S, x, y, z, rx, ry, rz)` | the building's index or -1 |
| The first thing a move meets | `WorldStructures.along(S, xa, xb, pad)` then `WorldStructures.sweep(S, list, x0, y0, z0, x1, y1, z1, rx, ry, rz, skipInside)` | `{"hit": false}` or `{"hit": true, "b", "t", "x", "y", "z", "face", "nx", "nz"}`; `nx`, `nz` is the wall normal for sliding |
| The body's half extents | `WorldLanes.body()` | `[rx, ry, rz]` in units (0.3, 0.5, 0.3 bh) |
| The ground at a depth | `WorldTerrain.groundY(S, x, z)` | the ground height at that depth (the plane's when depth is off or z is 0) |

**Depth limits to hold:** `Z_FRONT` and `Z_BACK` are `limits()[0]` and `limits()[1]`; the fighters' plane is z = 0 (inside the front street at the pick's table: the front street runs from +188 to -188 units). A brawl whose centre leaves a street must be in an avenue or above a roof; `clearLane` is the one call that makes a depth valid for the street case.

**How a brawl uses it at a crossing.** A brawl's centre at (x, z): if `avenueAt(S, x, rx)` is not -1 the depth is free across the band; otherwise `clearLane(S, x, z)` is the nearest valid depth. `intersections(S, x, r)` is what a director reads to pick a "fight happens here" stage (e.g. a signature that wants the crossing's long view): the first entry is the nearest.

**Checks:** `sim/world/tools/isect_check.gd` (runs headless in a second: 8 checks) and the existing `probe_collide.gd` (L3's 20 checks).

## What I ask of the other directors

- **Encounter:** read F; the free-fighter rule and `predictFlight` are L4's; the pick's three streets double the places a brawl can be pulled to.
- **Camera:** confirm `z_front` +2.5 and `z_back` -29.5 (band unchanged at 32 bh); say whether Q (a deeper band, 40 to 48 bh) is worth the framing.
- **Rendering:** `STREET_STRIPS` 8 to 16 (three streets with five strips), the avenues as gaps in the blocks (they are already in `S.lanes`), the crossings' paving.
- **Tools:** schema keys for the re-lay: `aspect_max` (top level of `settlements.json` and a kind's own), `row_pop` (district, four numbers from 0 to 1); `lanes.json` strips are rounded to 4 decimals.
- **Simulation:** nothing for the pick; the list above for L4.
