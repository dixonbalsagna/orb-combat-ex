# The schema and world-checks lines of World's lake, memory and floor parks, for Tools (World, 2026-11-20; stand-in review L-03)

All stack from a clean HEAD export in this order (tested): `data-switches-gw1a`, `cache-determinism`, `floor-rise`, `lake-places`, `memory-under-model`, `lake-shore`, then the data rows. Each park's `world-checks.json` line sits in its own gap of the run list, so they do not collide.

## Data keys: schema lines and the cases to add

| Key | File and schema | Shipped | Valid cases | Invalid cases |
| :--- | :--- | :--- | :--- | :--- |
| `plans.lakeMax` | `data/biomes/field.json`; `tools/schemas/biomes-field.schema.json`, `plans.properties.lakeMax`: number, minimum -1, maximum 200, optional | -1 (off) | -1, 0, 8, 200 | "8" (a string), -1.5, 201, null |
| `plans.lakeSpill` | the same file and schema, `plans.properties.lakeSpill`: boolean, optional | false (off) | true, false | "true", 1, null |
| `heldMul` | `data/biomes/brunt.json`; `tools/schemas/biomes-brunt.schema.json`, `properties.heldMul`: number, minimum 1, maximum 8, optional | 1.0 (off) | 1, 2, 8 | 0.9, 8.5, "2", null |

(`heldMul` is in `memory-under-model.diff`; the others in `lake-places.diff` and `lake-shore.diff`.)

## world-checks.json (the `run` list), one line each, each in its own gap

| Check | Park | After line (of the HEAD file) |
| :--- | :--- | :--- |
| `floor_rise_check` | `floor-rise` | 4 (the `burial_check` line) |
| `lake_places_check` | `lake-places` | 5 (the `after_check` line) |
| `memory_model_check` | `memory-under-model` | 6 (`power_world_check`) |
| `lake_shore_check` | `lake-shore` | 7 (`control_check`'s line) |
| `default_gate_check` | `a-world-01/default-gate.diff` | 8 (`farsites_check`'s line) |
| `cache_warm_check` | `cache-determinism` | 10 (`beam_grid_check`) |

Every check prints a verdict line ending in `N check(s) failed` and ends (`quit`), and has a negative control (`--negative-control` for `cache_warm_check`, `floor_rise_check`, `memory_model_check`; the others compare their own off switch), so `tools/world-checks.mjs --verify` and `--run` classify them as the other World checks.
