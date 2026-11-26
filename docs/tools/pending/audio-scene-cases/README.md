# Park: the cases Audio's schema grant needs (Tools, 2026-11-25)

`audio-scene-cases.patch` adds five cases for `audio-scene-cues.schema.json` to `tools/fixtures/cases.json` (four invalid, one valid). Apply **with** Audio's friends-sound set, after `grant/tools-schema.patch`: without them `node tools/validate.js --self-test` fails ("at least three invalid cases").

Run on main with all four of Audio's patches: the schema self-test passes.
