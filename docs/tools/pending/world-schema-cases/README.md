# Invalid cases for World's biomes-sizes schema (GW1c; Tools, parked 2026-11-14, split 2026-11-21)

`node tools/validate.js --self-test` wants at least three invalid cases for every schema. World's new `biomes-sizes.schema.json` (`docs/world/pending/planet-sizes/`) has none. **The six biomes-world cases moved out on 2026-11-21 to `docs/tools/pending/biomes-world-cases/`** (the EP's order, review B-10: `a-world-01` lands at GW1b and its schema needed its cases at GW1b). This park now carries only the six sizes cases and stays parked for GW1c.

`world-schema-cases.patch` (sha1 `eac8673e0b71f4ccde31e0c0221053a1edf5751e`): one file, `tools/fixtures/cases.json`, **6 cases appended** (it was 12; the same six sizes cases as before, re-cut to apply AFTER `biomes-world-cases`, whose six come first).

| Schema | Cases (rule at pointer) |
| :--- | :--- |
| `biomes-sizes` | unknown top key (additionalProperties `/extra`); medium `cols` of 100 (minimum `/sizes/medium/cols`); `offered` removed (required `/sizes/medium`); an unknown key in `places` (additionalProperties `/sizes/tiny/places/hamlets`); `offered` as a string (type); `bakeStride` 0 (minimum) |

**Order: after `biomes-world-cases`, and with or after `planet-sizes`.** The cases mutate `data/biomes/sizes.json`, which `planet-sizes.diff` adds, so on a tree without it they fail with "fixture path missing". Lands in GW1c with World's `planet-sizes` park (its `data/biomes/sizes.json`, `biomes-sizes.schema.json` and `tools/schemas/map.json` hunks; the rest of that diff is World's GW1c re-cut: it no longer applies whole on the GW1b list, `sim/world/store.gd:37`).

**Proof** (a scratch git of main 575bf093 with the 44-line GW1b list applied, then `biomes-world-cases`, then `planet-sizes.diff`'s data, schema and `map.json` hunks only): before this patch, self-test 10154 of 10155 (the coverage row for `biomes-sizes.schema.json`); after, **10162 of 10162**. **Negative control:** with the `minimum` of `cols` removed from the sizes schema, the matching case fails and the self-test says so. `git apply --check` of this patch passes on the cases.json that `biomes-world-cases` leaves; it does not apply to main alone (the six world cases are its context).
