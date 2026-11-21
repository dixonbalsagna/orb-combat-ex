# Review: the lake fixes (World's `lake-places` and `lake-shore`, Rendering's `water-everywhere`)

- **Who:** Orb's stand-in, the landing reviewer of sprint A1.
- **When:** 2026-11-20, about 20:45, against main at 14da0fdb and the EP's rebuilt GW1a tree (s423).
- **What:** `docs/world/pending/lake-places/` (re-cut in 0ed48472), `docs/world/pending/lake-shore/` (new in the same commit), `docs/rendering/pending/water-everywhere/` (c7113398), their run records, and Animation's check `docs/animation/pending/water-tile-check/`.
- **How:** by one reviewer, by hand; nothing run in Godot. Patches were tried in order with `git apply` on a scratch copy of the GW1a tree's files.

The fault, in plain words: on the round planet, lakes near towns drew no water while the game still stood fighters at the lake's level, up to 681 units in the air over a dry bed. A second fault sits under it: most lakes are slabs of water lying over a hillside, with an edge up to 2,898 units above the ground beside it.

## Verdict

**`lake-places` with the two tile lines can be stacked in GW1b after one small fix (L-01) and Tools' review (L-03). `lake-shore`'s code can land switched off. Its data row must not be switched on without a decision, and the picture GW1b will show at a lake's edge needs a look before the round planet becomes the default (L-02).**

## What applies on what (tried on a scratch copy of the GW1a tree's files)

| Step | Result |
| :--- | :--- |
| floor-rise's Simulation grant, `floor-rise.diff`, `lake-places.diff`, `lake-shore.diff`, `lake-places-data.diff`, `lake-shore-data.diff`, `grant-rendering-tile-water.patch`, in that order | All apply clean |
| `lake-places.diff` alone on the GW1a tree, without floor-rise | Applies. The re-cut fixed the failure the GW1b review reported |
| Rendering's `water_everywhere.diff` after World's `grant-rendering-tile-water.patch` | Fails at `render/core/tile_field.gd:539`, as expected: the two are the same two lines (Rendering's README says "byte-identical"). **Apply one, never both** |

Place in the GW1b order (`docs/ep/reviews/GW1b-review.md`): straight after step 16 (the floor rise), before the flip. `lake-shore`'s code may follow `lake-places` at any point.

## Is the code right, and is it safe with its rows off?

| Park | With its row off | Evidence |
| :--- | :--- | :--- |
| `lake-places` (`plans.lakeMax` -1) | Nothing changes: the new test is skipped before any water is read | the diff: `if lake_max >= 0.0 and WorldField.recordWater(...) > lake_max` |
| `lake-shore` (`plans.lakeSpill` false) | Nothing changes: the old flood runs under `elif bh < level`, untouched | the diff's `if bh < level and spillOn():` ... `elif bh < level:` |
| The two tile lines | Picture only; they never write the game's state | `render/core/tile_field.gd`, two lines; Rendering's README: "`golden.json` is byte-identical to HEAD's" |

The trim itself is sound: a building whose base is under more than 8 units of lake or river water is not laid. On planet 7 it drops 35 of 3,835 buildings and leaves none in water (`docs/world/runs/lake-places/lake_places_check.txt`). The new flood in `lake-shore` is a correct lowest-pass search: it takes ground in order of the highest point on the way to it, stops the level at the first way out (the lake's bound, an earlier lake, or the sea), and keeps only ground whose way in is below that level. Ties are broken by fixed neighbour order, so two runs give one result.

## MAJOR

### L-01. The two parks' checks clash if both rows are ever on

- **What is wrong.** `lake_places_check` proves its fix by first showing the fault: with the trim off it requires at least 5 buildings in water and one more than 40 units deep, and then requires that the trim dropped some buildings. It reads the lakes as the data gives them and does not pin `lake-shore`'s switch. With `lakeSpill` on, planet 7 keeps 79 lake nodes of 6,641, so there would be almost no water for a building to stand in, and both rows would most likely fail.
- **Evidence.** `lake-places.diff`, the check's rows: `ok(int(off[1]) >= 5 and float(off[2]) > 40.0, ...)` and `... and int(on[0]) < int(off[0])`; no `spillOverride` anywhere in that diff. `docs/world/runs/lake-shore/lake_shore_check.txt`: "planet 7 touch 3: 6 lakes; off: 6641 nodes ... on: 79 nodes".
- **Fix.** `lake_places_check` sets `WorldWaterRec.spillOverride = 0` for its run and puts it back, since it tests the trim and not the lakes' shape. World's order has `lake-shore` after `lake-places`, so the line goes in with `lake-shore.diff`.
- **Owner:** World.
- **Limit:** by reading; nothing was run.

### L-02. After GW1b the picture shows water standing on hillsides, and nobody has looked at it

- **What is wrong.** Today the slab lakes near towns are hidden, because no water is drawn there. The tile lines make every lake draw at the level the game uses. That is the right fix for fighters standing in the air, and it also puts the slabs on screen: water that ends in a wall over a slope, on about half of every lake's shore (1,404 of 2,430 shore links on the three planets read, the worst 2,898 units). With the floor rise in, a fighter who walks into such an edge is lifted to the lake's level: Animation measured 837 units over 5 ticks at one edge. None of this has a still or a side-by-side yet. Rendering's own README says the side-by-side is owed and needs a capture window.
- **Evidence.** `docs/world/pending/lake-shore/README.md` ("every lake has about half of its shore links open"; the lift at x 23,976 to 24,008); `docs/rendering/pending/water-everywhere/README.md`, "The look"; `docs/decisions/0010-look-gate.md`.
- **Fix.** Before the flip to the round planet: one still of a lake edge on the GW1b data in the default look, next to the 9 November build at the same place, and the EP's look at it. Then one of two for GW1b, written in the sprint page: lakes drawn as they are (slabs and all), or `lakeSpill` on (honest water, almost no lakes) as the interim. World has asked that the choice go to Game Design and Orb, and it is a taste call, so a draft question is at the end of this page.
- **Owner:** EP; Rendering and Tools for the still; Game Design.

### L-03. Both parks edit Tools' files without saying so

- **What is wrong.** `lake-places.diff` and `lake-shore.diff` each add a property to `tools/schemas/biomes-field.schema.json` and a line to `tools/world-checks.json`. Tools has just said both files are its own, when it reviewed the same pattern in `memory-under-model` ("Its README says 'no grant': that is wrong"). Neither lake README names a grant, and no cases exist for `lakeMax` or `lakeSpill`.
- **Evidence.** the two diffs' schema and check-list hunks; `docs/tools/pending/memory-under-model-cases/README.md:3`.
- **Fix.** Tools reviews the two schema lines and adds cases (for `lakeMax`: under -1, over 200, wrong type; for `lakeSpill`: wrong type), as it did for `heldMul`.
- **Owner:** Tools.

## MINOR

| # | What | Evidence | Fix | Owner |
| :--- | :--- | :--- | :--- | :--- |
| L-04 | The run records for `lake-places` are from 20:06, before the re-cut at 20:35, and neither park has a parity or golden run on file with its row off. "Nothing moves" is shown by the code above, not by a record | file times in `docs/world/runs/lake-places/`; the READMEs' result tables | One parity run with both rows off, filed | World |
| L-05 | `data/biomes/field.json` gains two keys even with both rows off. The field data's hash changes, so the kept places are laid cold once, as the README says for the row. If that file is part of a saved match's data key, matches saved before would be refused | `lake-places/README.md`, the data row's line; not checked further | Say it in the landing note. Harmless inside GW1b, which re-records everything | World, EP |
| L-06 | The trim reads the water at the building's centre only. A wide building with a dry centre and a corner on a steep bed can still stand in deeper water. The slope test beside it reads eight points round the footprint | `lake-places.diff`, the one `recordWater` call at `q`; `sim/world/plan.gd` `_overhangs` | Read the corners too, or note it | World |
| L-07 | The trim is counted on planet 7, touch 3 only (35 of 3,835 dropped). The check takes other planets but no record has them | `lake_places_check.txt`; the README's risks | Enough while the quick-match draw stays off (GW1b review, B-03). Count the other four before the draw goes on | World |
| L-08 | The new flood keeps its work list in a plain array: it takes from the front and inserts in order, for up to 8,000 nodes a lake. It was not timed | `lake-shore.diff` (`heap.pop_front()`, `heap.insert(lo, ...)`); README: "not timed (shared machine)" | Time planet generation with the row on, in a quiet window, before the row flips. It adds to loading | World, Performance |
| L-09 | Both checks pass their first row only while the fault exists with the switch off. That is a fair control today and will fail by design when the lakes are redone | the first `ok(...)` of each check | Keep, and say so in each README | World |
| L-10 | World's own note: the game's record-water memo kept one match's lakes into the next when the switch was changed between two matches in one process. World calls it a tests-only trap | `lake-shore/README.md`, risks; `sim/core/field.gd:59-60`, `:446-454` | Worth one check that a second match on a different planet in the same process does not read the first one's water, since players do start a second match | World, Simulation |
| L-11 | The two places Animation's check still failed (a lot's edge at x 32,000 and a steep bed at x 22,400) are the check reading coarse tiles, by Rendering's probe. Animation's update of 20:41 makes the check read the finer tiles | `water-everywhere/README.md`, "The two places left"; commit 14da0fdb | None, if the updated check passes on the stacked tree | Animation |

## Confirmed fine

- Rendering's park is World's grant, reviewed by the file's owner and gated: tile, lake water, cover water, sweep and ground checks pass, render gates 20 of 20, golden unmoved (`docs/rendering/pending/water-everywhere/README.md`).
- With the two tile lines, every lake's drawn water is at the game's level "to the unit" (`docs/world/pending/lake-places/README.md`, the result table: up to 0.0 above).
- No bystander rule is touched. Buildings that would stand under water are simply not laid.
- Nothing is drawn on or over a fighter, and nothing fades in.

## A draft question for Orb, for the EP to put with a picture

It should go with one still of a lake's edge as it will look, so it waits for L-02's still.

**Many of the planet's lakes are water lying on a hillside, with one side ending in a wall of water. Until now you could not see it, because the water was not drawn near towns. What should the game do for now?**

- **A. Draw the lakes as they are.** You keep every lake. Some will show a wall of water over a slope, and a fighter who walks into one is lifted to the top of it.
- **B. Keep only the lakes the land can really hold.** No water on hillsides. Almost every lake goes for now: on the test planet, 79 pieces of lake remain of 6,641.
- **C. Dig a real bowl for each lake** so they all stay and all look right. This changes the planet's ground and is a bigger job, for after this landing.

I think Orb would want B now and C as the work to follow: a fighter standing on water that hangs over a slope is the kind of thing Orb has asked to have squashed, and losing lakes for a while costs less than showing them wrong. It is a look call, so the picture should decide.

## How this was done

One reviewer read the three parks, their records and the lines of code they change, and tried the patches in order on scratch copies. No agents. Cost: about 0.3M tokens of the reviewer's own reading.
