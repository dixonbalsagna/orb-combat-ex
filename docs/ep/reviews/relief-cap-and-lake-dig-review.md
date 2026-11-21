# Review: World's `relief-cap-gw1c` and `lake-dig` parks

- **Who:** Orb's stand-in, the landing reviewer of sprint A1.
- **When:** 2026-11-20, about 22:35, against main at 6bb03b08 and the EP's stacked GW1a tree.
- **What:** `docs/world/pending/relief-cap-gw1c/` (a cap on how high the land rises on the two smallest planets) and `docs/world/pending/lake-dig/` (digging a bowl under each lake so no water stands on a hillside), with their run records.
- **How:** blockers and majors only, as the EP asked. Two readers on the cheaper model read one park each; the stand-in then re-opened the files behind every finding below and re-ran the apply tests on scratch copies. Nothing was run in Godot.

## Verdict

| Park | Verdict | Why |
| :--- | :--- | :--- |
| `relief-cap-gw1c` | **Not as parked: one blocker, five majors.** The maths is sound and medium is untouched | It would change the look of tiny and small with the switch on from the first day and no picture taken, and the ruling it builds is written nowhere |
| `lake-dig` | **Not as parked: one blocker, five majors.** The code does what Game Design ruled, point by point | Its data row cannot be applied together with the row it needs, in either order |

Both are fixable without redesign.

## `relief-cap-gw1c`

### BLOCKER

**RC-01. A visible change lands switched on, with no picture.** The diff puts the cap straight onto tiny and small in `data/biomes/sizes.json`, and both are marked as offered. There is no data row to flip later. On tiny, everything above 1,174 units, about an eighth of the surface, is flattened to 0.08 of its slope, with a crease where the slope changes.
- Evidence: `relief-cap.diff:11-12` (`"offered": true ... "maxReliefShare": 0.3, "reliefKnee": 0.6` on both); `README.md:3` "Art's stills of tiny and small are not taken"; `README.md:17` "the relief above the knee is flatter by a factor (tiny 0.08, small 0.18)".
- Fix: ship the keys off and park a data row that turns them on in GW1c, after Rendering's stills of tiny and small in the default look, Art's word on the flat tops and the crease, and a side-by-side. Small matters most: by the EP's rule A1 offers small, medium and big.
- Owner: World; Rendering and Art for the stills.

### MAJOR

| # | What is wrong | Evidence | Fix | Owner |
| :--- | :--- | :--- | :--- | :--- |
| RC-02 | **The ruling is on no file, and the park may not match it.** The README quotes Art: "altitude biomes follow the capped height, with their lines as shares of the cap". That sentence exists only in the README. World's reading (biomes read from the height before the cap, lines unmoved) picks the same points as before, so mountain and highland land stays where it was but now lies on ground squeezed nearly flat. By the reader's arithmetic the highland line then sits at 0.67 of the cap on tiny and 0.63 on small, so it is not one share of the cap. The check's biome row cannot fail: the biome is set before the cap is applied | a search of `docs/` finds the quote only at `README.md:19`; `relief-cap.diff:21` (the cap applied after the biome is read); the only ruling on file is Game Design's `docs/design/planet-sizes.md:43`, which is about a building's height | Art writes the ruling down, saying whether a line is a fixed share of the cap at every size. World then keeps or changes the reading, and the check's row tests the lines as shares of the cap at tiny and small | Art, World |
| RC-03 | **The saved-planet caches do not know about the cap.** Their keys carry the planet, climate, land, sites, rivers and field data, not `sizes.json`. After an edit to the cap's numbers, which the README invites, an old tiny or small planet can be read back from disk | `sim/world/field_cache.gd:7`; `sim/world/planet.gd:52-57` (`dataHash`, no sizes data) | Add the size's relief keys to the caches' keys for sizes other than medium, with a check row: change the knee, expect a miss | World |
| RC-04 | **The older planet type skips the cap on ordinary land.** Its fast path sets the height from its own copy of the ground arithmetic and never passes through the function the cap was added to, while the polar columns do. A match can name the older type at any size | `sim/world/planet.gd:1049` and `:1097` (the fast path); the diff adds the cap in `surfAt` only | Apply the cap in the fast path too, or refuse sizes other than medium on the older type. Add a check row that reads the columns, not the surface function alone | World |
| RC-05 | **It stands on four parks that do not apply on the tree it will land on.** Everything under it has to be re-cut after GW1a and GW1b, as the GW1c readiness review found (C-07), and its records name no tree. Its sizes record is one line and inherits the shared-ground fault (C-01) | tried on scratch: the stack applies on main; on the GW1a tree `globe-step2.diff`, `planet-sizes.diff` and `gw1c-world-fix` fail; `docs/world/runs/relief-cap/size_check.with-the-cap.txt` reads only "SIZES: 0 check(s) failed" | Re-cut with the rest of the planet stack, with Rendering's field-memo grant in it; file the checks' full output named for the tree | World, EP |
| RC-06 | **Tools' files change with no grant, and the check's name collides.** The schema and check-list lines sit inside World's diff. The new `relief_check.gd` prints "RELIEF:", and a check of that name with that verdict already exists in the director's tools. One error message and one comment in the diff say the opposite of the code | `sim/director/tools/relief_check.gd:15`; `relief-cap.diff:200`, `:37`, `:43` | A separate grant for Tools with cases; rename to `relief_cap_check` with its own verdict word; correct the two lines | World, Tools |

**Confirmed fine:** medium is bit for bit (the cap is skipped at medium's size, and no key sits on medium, big or huge). The squeeze is smooth and in proportion, with no flat shelf: tiny's real tops end at about 1,600 under a cap of 1,956. The negative control is real: with the cap off, two rows fail. Lakes and rivers take their levels from the capped ground.

## `lake-dig`

### BLOCKER

**LD-01. The data row cannot go on together with the row it needs.** The README says the dig's row "needs `lakeSpill` true". But both of the dig's patches are anchored on the line that says `lakeSpill` is false. So either order fails, and applied alone the dig's row turns on code that then does nothing, because the dig only runs when `lakeSpill` is on.
- Evidence, tried on a scratch copy of the GW1a tree's files: lake-places, lake-shore, lake-dig apply, then `lake-shore-data.diff` fails ("patch failed: data/biomes/field.json:20"). With `lake-shore-data.diff` first, `lake-dig.diff` and `lake-dig-data.diff` both fail at `:22`. `lake-dig/README.md:8`.
- Fix: re-cut so the dig's lines in `field.json` do not sit beside `lakeSpill`, or ship no key in the code patch (LD-02). Make the later row one diff that sets both switches, and test both orders.
- Owner: World.

### MAJOR

| # | What is wrong | Evidence | Fix | Owner |
| :--- | :--- | :--- | :--- | :--- |
| LD-02 | **"Shipped off" is unrecorded, and it is not free.** No parity or golden run with the switch off is on file, and no pair of runs showing one result. The new key in `field.json` changes the planet data's hash even while off. That hash is in a saved match's key, the laid-places memo and the bake cache, so matches saved before are refused and planets are rebuilt once. The README does not say so. (This also settles a point left open in the lake fixes review: `field.json` is part of a saved match's key.) | `docs/world/runs/lake-dig/` holds two files; `sim/core/replay.gd:280` `h.text(WorldPlanet.dataHash(gen))`; `sim/world/planet.gd:56` | Ship no key in the code patch: the code already treats a missing key as off. File a parity run with the switch off and one hash of the same dug match run twice | World |
| LD-03 | **The check does not test its two main claims against failure.** "No walls" and "at most 300 deep" have no control that must fail; the two controls only show that the dig switches off. The depth sampler stops after 400 nodes while the largest lake has 728 dug. And it reads the stored node values, not the ground the game reads after buildings' lots are applied | `lake-dig.diff:175-181` (the controls), `:102` (`if cnt > 400`); `docs/world/runs/lake-dig/lake_dig_check.txt` ("dug 728") | A control with the spill and the dig both off that must find open shore; a control with a smaller depth that must hold; read the ground the game reads; sample every dug node | World |
| LD-04 | **A bowl that crosses an edge of the planet's six-sided grid can leave a step.** A grid point on such an edge has one number on each side. The dig stores a dug point under the number it was reached by; the reader looks it up by the number of the side the fighter is on. Where they differ the dug ground is not found, and the ground can jump by up to the dug depth along the edge | `lake-dig.diff`, `dugGround` (`dug.get(base + (j + dj) * F.side + (i + di))`); `sim/world/field.gd:253-254` (a point's number includes its side); `sim/world/waterrec.gd:323-328`. The mechanism is in the code; whether any lake on the three test planets crosses such an edge was not checked | Store each dug edge point under both numbers, or look it up by one agreed number; add an edge case to the check | World |
| LD-05 | **Tools' files change with no grant and no cases.** The README asks for it under what it needs from the EP | `lake-dig.diff`, the schema and check-list hunks; nothing for `lakeDig` in `docs/tools/pending/` | Tools reviews and adds cases | Tools |
| LD-06 | **Nobody has counted buildings in the dug lakes.** The one check that counts buildings standing in water now forces the lakes back to their old shape, so the dig never runs inside it. Lots are applied after the bowl, so a laid building flattens the bowl's floor under itself | `lake-places.diff:104-107` (`plans["lakeSpill"] = false`); `lake-dig/README.md`, the files table ("cuts the bowl before the pads") | Run the count with all three rows on (the spill, the trim at 8, the dig) on the three test planets and file it | World |

**Confirmed fine:** the code matches Game Design's ruling point by point (`docs/design/planet-sizes.md:65-79`): the level is the spill level; only ground inside the planned footprint and at most 300 above the level is cut; the floor is at most 300 below it and no steeper than 1 in 3; a lake digs only if its dug water is at least 40 grid points; smaller ones keep their real basin. The record shows 6 of 12 lakes dug, 1,324 water points against 148 without the dig, 0 open shore links, the deepest point 241.6. With the switch off every new line is skipped. The picture and the game read the same dug ground. The README says the look gate is owed.

One more thing from this park's own record: `lake_places_check` now pins the lakes' shape for its own run, which fixes L-01 of the lake fixes review.

## How this was done

Two readers on the cheaper model, about 0.3M tokens, returned twelve findings. The stand-in re-opened the evidence for each, re-ran the two apply orders behind LD-01, and confirmed the mechanism of LD-04 in the code. RC-04 was read on main's file; the reader gave it medium confidence, and LD-04 low until the mechanism was confirmed.
