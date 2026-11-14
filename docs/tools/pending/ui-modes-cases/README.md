# Invalid cases for UI's `ui-modes` schema (GW1a; Tools, parked 2026-11-14)

`node tools/validate.js --self-test` wants at least three invalid cases for every schema. UI's new `tools/schemas/ui-modes.schema.json` (docs/ui/pending/a1-start-flow/grant/schema-ui-modes.patch, for `ui/data/modes.json` in start-flow.patch) has none, so the self-test shows **1 failure** on the GW1a stack: "coverage: ui-modes.schema.json: at least three invalid cases, has 0". This park is the cases.

`ui-modes-cases.patch` (sha1 `b433b538de8a7db611a4d12ed9c8c0a67810709f`): one file, `tools/fixtures/cases.json`, **6 cases inserted** beside the other `ui-` cases (so it does not overlap the World and arc case patches: all three apply together).

| Case | Rule at pointer |
| :--- | :--- |
| unknown top-level key | additionalProperties `/extra` |
| `schema` 2 | const `/schema` |
| `modes` empty | minItems `/modes` |
| first mode's id "Solo!" | pattern `/modes/0/id` |
| first mode's state "soon" | enum `/modes/0/state` |
| a `ready` mode with no `players` | required `/modes/0` (the schema's if/then) |

**Proof** (a scratch git of main with UI's grant and `ui/data/modes.json` applied): before, `validate.js` 0 errors and self-test 10099 of 10100 (the coverage failure); after, **10107 of 10107**. **Negative control:** with the id `pattern`, the `then` rule and `minItems` removed from the schema, exactly the three matching cases fail (list-empty, id-bad-pattern, ready-without-players). The cases mutate `ui/data/modes.json`, which UI's park adds, so they land with UI's grant (alone, on a tree without the file, they say "fixture path missing").
