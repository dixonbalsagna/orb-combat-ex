# Review of World's lakeMax and lakeSpill schema lines and its six world-checks lines, with cases (Tools, 2026-11-21)

World's `docs/world/pending/lake-places/tools-lines.md` lists the schema and run-list lines of its lake, memory and floor parks. All are lines of **my** files (`tools/schemas/biomes-field.schema.json`, `tools/schemas/biomes-brunt.schema.json`, `tools/world-checks.json`). `heldMul` was reviewed in `../memory-under-model-cases/`. This is the rest.

I stacked the parks on a clean export of HEAD (HEAD at the time of the export) in World's order: `a-world-01/data-switches-gw1a`, `cache-determinism`, `floor-rise`, `lake-places`, `memory-under-model`, `lake-shore`, `a-world-01/default-gate`, then the data rows (`lake-places-data`, `memory-under-model-data`, `lake-shore-data`). **All ten apply, in that order, with no conflict.**

## The two schema lines: APPROVE both

| Key | Schema line | Shipped | Checked |
| :--- | :--- | :--- | :--- |
| `plans.lakeMax` | `biomes-field.schema.json`, `plans.properties.lakeMax`: number, `minimum` -1, `maximum` 200, optional (in `lake-places.diff`) | -1 (off) | `validate.js` 0 errors with the data at the shipped value and with the data row (8) |
| `plans.lakeSpill` | the same file, `plans.properties.lakeSpill`: boolean, optional (in `lake-shore.diff`) | false (off) | `validate.js` 0 errors with the shipped value and with the data row |

With every park and every data row on: `validate.js` **321 files, 0 errors**, self-test **10093 of 10093** (before my cases). Both are optional, so a `field.json` without them stays valid. Nothing to re-cut.

**One thing to land correctly (your word, not a schema matter):** the EP's ruling is that `lakeSpill`'s data stays off. The data diff `lake-shore-data.diff` sets `"lakeSpill": true` (and `lake-places-data.diff` sets `"lakeMax": 8`, the lake rows' value for GW1b). If `lake-shore-data.diff` lands, `lakeSpill` is **on**. The schema line is fine either way; the data diff is the thing to leave out.

## The six world-checks lines: APPROVE

`floor_rise_check`, `lake_places_check`, `memory_model_check`, `lake_shore_check`, `default_gate_check`, `cache_warm_check`, each a line in its own gap of the run list. With all six: `node tools/world-checks.mjs --verify` reads **ok, 91 checks run in CI** (85 on HEAD), 30 scripts left out with a reason. Each script ends on a verdict line (`... N check(s) failed`) and `quit`s, which `tools/gate.mjs --verdict` reads; floor_rise, memory_model and cache_warm have `--negative-control` in the script, the other three compare their own off switch (World's note). The scripts table (`node tools/check-scripts-table.mjs --check`) counts all six as CI: 6 more scripts, 6 more in CI, **55 unreviewed (ratchet 55)**: no change. I did not run the six scripts in Godot (that is World's proof); `cache_warm_check` and `memory_model_check` are already in the parked table `../gw1a-checks/check-scripts.md`, the other four are not yet: run `node tools/check-scripts-table.mjs --write` after they land.

## The fixtures: `lake-places-cases.patch` (sha1 `c7a8e674e24991f983448201c431ceecb1702982`)

13 cases after the last biomes-field case of `tools/fixtures/cases.json`, each setting one key under `/plans` on `data/biomes/field.json` (so none depends on the data rows being on main): `lakeMax` valid at -1, 0, 8 and 200; invalid as a string "8" (type), -1.5 (minimum), 201 (maximum), null (type); `lakeSpill` valid true and false; invalid as "true" (type), 1 (type), null (type). These are the cases World's table asked for.

**Proof** (clean export of HEAD with all ten diffs): self-test 10093 of 10093 before, **10106 of 10106** after. **Negative control:** with `lakeMax.minimum` -100, `maximum` 2000, and `type` removed from `lakeMax` and from `lakeSpill`, exactly the **seven invalid cases fail** (10099 of 10106) and the six valid ones still pass; restored, 10106. The patch applies to HEAD alone and with every other parked cases patch (arc-size, camera-swing, ui-modes, wall-cone, world-schema, step-up, memory-under-model; both orders each; the world-schema and camera-swing clash is the old one). `lakeMax` lands in GW1b with its schema line; the cases go with it.
