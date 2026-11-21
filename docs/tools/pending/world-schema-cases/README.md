# Invalid cases for World's two new schemas (GW1c; Tools, parked 2026-11-14)

`node tools/validate.js --self-test` wants at least three invalid cases for every schema. World's new `biomes-sizes.schema.json` (`docs/world/pending/planet-sizes/`) and `biomes-world.schema.json` (`docs/world/pending/a-world-01/`) have none, so the self-test shows **2 failures** on the GW1c stack ("coverage: biomes-sizes.schema.json: at least three invalid cases", and the same for biomes-world). This park is the cases.

`world-schema-cases.patch` (sha1 `4978696f9e0b93d62f3a3c03163a58aaa1204947`, **re-cut 2026-11-21 on the landed main**: camera-swing-cases landed at the end of `cases.json` and the old patch no longer applied): one file, `tools/fixtures/cases.json`, **12 cases appended** (6 a schema), the same 12 as before. It applies to HEAD (09e2de07) alone.

| Schema | Cases (rule at pointer) |
| :--- | :--- |
| `biomes-sizes` | unknown top key (additionalProperties `/extra`); medium `cols` of 100 (minimum `/sizes/medium/cols`); `offered` removed (required `/sizes/medium`); an unknown key in `places` (additionalProperties); `offered` as a string (type); `bakeStride` 0 (minimum) |
| `biomes-world` | unknown top key; `mode` "sphere" (enum `/mode`); `planetGen` 4 (maximum `/fixed/planetGen`); `touch` removed (required `/fixed`); empty `pool` (minItems `/random/pool`); `enabled` as a string (type) |

**Proof** (a scratch git of main with World's two diffs' data, schema and `map.json` hunks applied): before: `validate.js` 0 errors, self-test 10105 of 10107 (the two coverage failures); after: **10144 of 10144** (the re-cut, on HEAD with World's data, schema and `map.json` hunks: 10128 of 10130 before with the two coverage failures). **Negative controls:** with the `minimum` of `cols` removed from the sizes schema, and the `maximum` of `planetGen` removed from the world schema, exactly the two matching cases fail. The cases mutate `data/biomes/sizes.json` and `data/biomes/world.json`, which these parks add, so they can only land with World's parks (or after them): applied to a tree without those files they fail with "fixture path missing".

Order: with or after `planet-sizes` and `a-world-01`.


**Lands with World's two parks that carry its data, schema and `map.json` hunks, in GW1c:** `docs/world/pending/planet-sizes/planet-sizes.diff` (`data/biomes/sizes.json`, `biomes-sizes.schema.json`) and `docs/world/pending/a-world-01/a-world-01.diff` (`data/biomes/world.json`, `biomes-world.schema.json`), both with their `tools/schemas/map.json` lines. The cases mutate those two data files, so on a main without them they fail; with both parks in, the self-test reads 10144 of 10144 (checked on HEAD with just those hunks applied). Until then this patch stays parked (the EP, 2026-11-21).
