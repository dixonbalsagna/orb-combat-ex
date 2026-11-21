# biomes-world-cases (park, Tools, 2026-11-21; the EP's order, review B-10)

On the GW1b apply list (docs/ep/reviews/GW1b-stack.txt without the four lake lines: 44 patches, `a-world-01` first), `node tools/validate.js --self-test` is **10140 of 10141**: "coverage: biomes-world.schema.json: at least three invalid cases". `a-world-01` brings `biomes-world.schema.json` in at GW1b and the self-test wants three invalid cases for every schema. CI runs the self-test (`.github/workflows/ci.yml:76`), so without this park CI goes red at the GW1b landing.

`biomes-world-cases.patch` (sha1 `1d0bd7a87c1173c2039ad84dbb254e45e14bbbbc`, one file, `tools/fixtures/cases.json`, **6 cases appended**): **lands with or after `world/pending/a-world-01/a-world-01.diff`** (the cases mutate `data/biomes/world.json`, which that park creates), on the 44-line list at the end. It applies to the cases.json that list produces (`git apply --check` ok there; it does not apply to main alone, and on main alone the cases would have no file to mutate).

| Case | Rule at pointer |
| :--- | :--- |
| `biomes-world-unknown-key` | additionalProperties `/extra` |
| `biomes-world-mode-unknown` | enum `/mode` (`"sphere"`) |
| `biomes-world-plangen-too-high` | maximum `/fixed/planetGen` (4) |
| `biomes-world-fixed-missing-touch` | required `/fixed` (`touch` removed) |
| `biomes-world-random-pool-empty` | minItems `/random/pool` |
| `biomes-world-random-enabled-not-boolean` | type `/random/enabled` |

They are the same six as in `world-schema-cases` before this split (that park now carries only the six sizes cases; its patch is re-cut to apply after this one).

## Proof (a scratch git of main 575bf093 with the 44-line list applied in order, plain `git apply`, one at a time: all 44 apply)

- Before: `validate.js` 323 files, 0 errors, 2 warnings; self-test **10140 of 10141**, the one failure the coverage row above (it reproduces the re-check page's figure).
- After: self-test **10148 of 10148**; `validate.js` unchanged (0 errors).
- **Negative control:** with the `maximum` of `/fixed/planetGen` removed from `biomes-world.schema.json`, exactly one check fails, `data: biomes-world-plangen-too-high` (10147 of 10148); restored, green.
- On top of this park, `world-schema-cases` (sizes) with `planet-sizes`' data, schema and `map.json` hunks: self-test 10162 of 10162.

## Notes

- cases.json round-trips byte for byte through `JSON.stringify(,null,2)` plus a newline on the 44-line list (checked before the append), so the diff is the six cases and nothing else.
- Not in this park: cases for `lakeMax` on its own (the lake group is GW2; `lake-places-cases` carries lakeSpill's cases with it). The full `planet-sizes.diff` does not apply on the 44-line list (`sim/world/store.gd:37`): that is World's GW1c re-cut, not this park's; only its data, schema and map.json hunks were applied to prove the sizes cases.
