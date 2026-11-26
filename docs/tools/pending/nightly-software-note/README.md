# Park: the nightly says its software readings of buildings are invalid (Tools, 2026-11-26)

`nightly-software-note.patch`.

- `tools/flash/nightly-baseline.json` gains `invalid_note` (Rendering's finding: SwiftShader draws no building).
- `tools/flash/nightly-ci.mjs` prints it as a WARNING above each night's table and points to it beside the verdict. No verdict changes: collapse-reduced stays red.
- One self-test row (51), and a section in `docs/tools/flash-nightly.md`.

When Rendering's shader fix lands: dispatch two nightlies, re-record collapse-reduced (and any other clip with buildings) and remove `invalid_note`.
