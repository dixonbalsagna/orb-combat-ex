# Review of Encounter's schema grant for `arcBySize`, with its cases (GW1c; Tools, 2026-11-14)

## The grant: `docs/director/pending/arc-by-size/grant-tools-schema.patch` (sha1 24a9d843622f78e8ef75ac8b40583192b3822d45): APPROVE

It adds one key, `arcBySize`, to `tools/schemas/fight-power.schema.json`: an object with `peakOfRadius` (number above 0), `sideOfLap` (number above 0, at most 0.5) and `sizes` (array of strings), all three required, no other key but "_" comments. Checked in a scratch git of main:
- it applies to HEAD 8ad6286a;
- **with it, and Simulation's power.json hunk (`grant-simulation-power.patch`: `"arcBySize": {"peakOfRadius": 1.0, "sideOfLap": 0.25, "sizes": ["tiny", "small"]}`): `validate.js` 321 files, 0 errors;** without the grant the same data fails ("data/fight/power.json:116 /arcBySize [additionalProperties] unknown property");
- the bounds match the README's rule (a quarter of the lap at most; the radius as a share above 0): `sideOfLap` at most 0.5 is looser than the 0.25 in the data and says so in the schema, which is the right place for a ceiling.
One note, not a finding: the `sizes` strings are not checked against `data/biomes/sizes.json`'s keys (a name that matches no size is silently never used). A cross-reference rule would catch it; I have not added one, and a wrong name would only turn the cap off for that size.

## The fixtures it needs: `arc-size-cases.patch` (sha1 `9fbf11d6c9ea50888937db7a5e3e74916763d40e`)

A changed shape comes with cases. The self-test reads a **virtual copy** of `data/fight/` (`tools/fixtures/virtual/data/fight/power.json`), not the live file, so the copy needs the key too. The patch: `tools/fixtures/virtual/data/fight/power.json` gets `arcBySize` (and a `_arcBySize` comment), and `tools/fixtures/cases.json` gets 5 cases for `fight-power`, inserted after the existing ones: `peakOfRadius` 0 (exclusiveMinimum), `sideOfLap` 0.6 (maximum), a non-string in `sizes` (type, `/arcBySize/sizes/1`), `peakOfRadius` removed (required `/arcBySize`), an unknown key (additionalProperties). It applies to HEAD alone and with `world-schema-cases.patch`.

**Proof:** with the grant: self-test 10093 of 10093 before the cases, **10098 of 10098** after. Negative controls: with `maximum` removed from `sideOfLap` and `exclusiveMinimum` swapped for a minimum, exactly those two cases fail. I did not run the cases against the schema without the grant; the live data without the grant fails as noted above.

Order: with the grant (it needs the schema key to be valid). It does not need Encounter's code.
