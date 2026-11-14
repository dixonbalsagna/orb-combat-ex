# phrases-schema (Tools, 2026-11-01): the schema, map row and cases for Combat's phrases

`git -c core.autocrlf=false apply docs/tools/pending/phrases-schema/phrases-schema.patch` (3 files: `tools/schemas/combat-phrases.schema.json` (new, Combat's own file from `docs/combat/pending/phrases/`, unchanged), `tools/schemas/map.json` (the row `data/combat/phrases.json`), `tools/fixtures/cases.json` (9 cases: the live file valid, a wrong `schema`, a stray key, `enabled` not a boolean, `gapTicks` 0, `generator.version` 0, an unknown class, a fighter with no phrases, a part that is not X, Y or stick)).

**Lands WITH `docs/combat/pending/phrases/`** (its `phrases.json` goes to `data/combat/phrases.json`): the cases mutate that real file, so on a tree without it the self-test would fail.

Checked on a full HEAD export with the patch and `phrases.json` in place: `node tools/validate.js --self-test` 9,937 of 9,937 (with the mixed string's schema and file also in), `node tools/validate.js` 0 errors, 0 warnings. It applies with `mixed-schema` in either order (the two use different places in the map and the case list).
