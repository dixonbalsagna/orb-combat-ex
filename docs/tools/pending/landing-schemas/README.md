# Landing schemas (Tools, 2026-11-02): two schema lines the landing tree's validate asked for

`node tools/validate.js` on the clean landing tree failed with two errors, both Tools' schemas:

1. `audio/data/carry_cues.json` `grapple.refuse.texts` has three entries (`lockout`, `stunned`, `refused`; Audio's press-stunned) and `tools/schemas/audio-carry-cues.schema.json` allowed at most one (`maxItems` 1). Now 3.
2. `data/director/swing.json` `brawl.shareCap` (Encounter's swing-pair) is not in `tools/schemas/director-swing.schema.json`, which is closed. Added: `shareCap` {enabled, max 0 to 1, after >= 0}, all three required, `_notes` allowed.

`landing-schemas.patch`: two files, 27 lines; applies on the stack after swing-pair and press-stunned. Nothing else of anyone's.
