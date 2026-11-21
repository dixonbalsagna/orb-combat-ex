# Review of World's memory-under-model schema line (heldMul), with cases (GW1a; Tools, 2026-11-21)

World's `docs/world/pending/memory-under-model/memory-under-model.diff` (sha1 `8a5344faa10f...`) edits **my closed schema** `tools/schemas/biomes-brunt.schema.json`, and one line of **my `tools/world-checks.json`**. Its README says "no grant": that is wrong, both are Tools' files and this is the review. (The README is World's; I did not touch it.)

## The schema line: APPROVE

It adds one optional property, `heldMul`: a number, `minimum` 1, `maximum` 8, with a description of the held hit (a body held by a tower puts all its energy into the few floors it covers; Game Design's value is 2). Checked on a clean export of HEAD (485b328a):

- the diff applies to HEAD and to the EP's stack s422 (3917885);
- with it (the data ships `heldMul` **1.0**, inert): `validate.js` 321 files, **0 errors**, self-test **10093 of 10093**; with the follow-up data diff (`memory-under-model-data.diff`, `heldMul` 2.0) also **0 errors**, self-test 10099 after the cases below;
- the key is not in `required`, so a `brunt.json` without it stays valid, which matches the code: `brunt.gd` carries `"heldMul": 1.0` in its defaults and reads `cfg().heldMul`, and `heldMul > 1.0` is the switch, so 1 is "as before" and anything under 1 would also read as off; the schema's minimum of 1 keeps such a value out of the data;
- **one note, not a finding:** the maximum of 8 is the schema's only upper bound (the code does not clamp), which is the right place for it; the design asks for 2.

## The other non-owned line: `tools/world-checks.json`

The same diff adds `"memory_model_check"` to the world job's run list. Checked: `node tools/world-checks.mjs --verify` reads **ok, 87 checks run in CI** on the stack with the diff (86 on HEAD with the diff; the stack has one more world check), the script ends on a verdict line (`MEMORYMODEL: N check(s) failed`), which `tools/gate.mjs --verdict` reads, and `check-scripts-table --check` counts it as CI: **268 scripts, 192 in CI, 55 unreviewed (ratchet 55) on the stack with the diff**. I did not run `memory_model_check.gd` (Godot); that is World's proof. The parked table `../gw1a-checks/check-scripts.md` is re-generated with it (one more row, `sim/world/tools/memory_model_check.gd`: CI).

## The fixtures: `memory-under-model-cases.patch` (sha1 `63132282b52b7b4dc084e343576cb20751c238c2`)

Six cases after the last biomes-brunt case of `tools/fixtures/cases.json`, each setting `/heldMul` on `data/biomes/brunt.json` (so none depends on the data row being on main yet): **valid** at 1, 2 and 8 (the two bounds and the design's value); **under-1** (0.5, minimum at `/heldMul`); **over-8** (9, maximum at `/heldMul`); **wrong-type** ("2", type at `/heldMul`).

**Proof** (clean export of HEAD with the diff): self-test 10093 of 10093 before, **10099 of 10099** after. **Negative control:** with `minimum` set to 0, `maximum` to 80 and `type` removed from `heldMul`, exactly `under-1`, `over-8` and `wrong-type` fail (10096 of 10099); restored, 10099. The patch applies to HEAD alone and **together with every other parked cases patch** (arc-size, camera-swing, ui-modes, wall-cone, world-schema and step-up, each in both orders; and all but world-schema in one sequence, since camera-swing and world-schema clash with each other, already reported). It lands with the diff, in GW1a.
