# Review of Encounter's wall-cone schema grant, with its cases (GW1b; Tools, 2026-11-14)

## The grant: docs/director/pending/wall-cone/grant-tools-schema.patch (sha1 39fe5bb27940ddbbebaa4a4342e5489c1387a14e): APPROVE

It adds two keys to the closed `knockBack.wall` block of `tools/schemas/director-launch.schema.json`: `wallCone` (number, 0 to 90, degrees around the blow's line a knock may aim at a wall; 0 is no cone) and `wallBy` (enum `trueDistance` or `line`). Checked in a scratch git of main:
- it applies to HEAD ca774f25;
- **with it and the park's data hunk (`wallCone: 20.0`, `wallBy: "trueDistance"` and a `_wallCone` comment in `data/director/launch.json`): `validate.js` 321 files, 0 errors, self-test 10093 of 10093;** without the grant the same data fails twice ("/knockBack/wall/wallCone [additionalProperties] unknown property" and the same for `wallBy`);
- both keys are optional (not in `required`), as they should be: the park's code reads `w.get("wallCone", 0.0)` and `wd.get("wallBy", "line")`, so a file without them keeps today's rule (every wall in reach), and the `_wallCone` comment is allowed by the block's `^_` pattern;
- the bounds match the design (a cone of at most 90 degrees; the data's 20).
Nothing to re-cut. One note, not a finding: `wallCone` of 90 or `wallBy` of `line` combined with a cone is a legal pair that the schema does not forbid, which is fine (the code orders by line when asked).

## The fixtures: `wall-cone-cases.patch` (sha1 `43e39a094dc93615432839bf9dee811d358e8e36`)

The self-test did not need cases to stay green (director-launch already has many), but a changed shape should come with them, and the self-test reads a virtual copy of `data/director/`: so `tools/fixtures/virtual/data/director/launch.json` gets a `knockBack.wall` block (the live block without its comments, with `wallCone` 20 and `wallBy` "trueDistance": it also makes the valid fixture exercise both new keys), and `tools/fixtures/cases.json` gets 5 cases inserted after the existing director-launch ones: `wallCone` 120 (maximum), -5 (minimum), "wide" (type), `wallBy` "nearest" (enum), an unknown key in the block (additionalProperties).

**Proof:** with the grant: self-test 10093 of 10093 before, **10098 of 10098** after. **Negative control:** with `maximum` removed from `wallCone` and the `enum` from `wallBy`, exactly `director-launch-wallcone-over-90` and `director-launch-wallby-unknown` fail. It applies to HEAD alone and together with the ui-modes, World and arc case patches (they insert at different places). Land the cases with the grant (the virtual copy and the cases need the keys to be valid).
