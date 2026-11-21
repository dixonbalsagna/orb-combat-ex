# Review of Animation's step-up schema grant, with its cases (GW1b; Tools, 2026-11-20)

## The grant: docs/animation/pending/step-up/step-up-schema.patch (sha1 71c0cf080de9): APPROVE

It adds one optional block, `step_up`, to `tools/schemas/anim-ground-motion.schema.json`: seven required keys (`enabled` boolean; `min_bh` 0 to 10; `bh` above 0 to 1000; `max_move` 0 to 2000; `ref_bh` above 0 to 20; `p_min` 0 to 1; `ticks` an integer, 12 to 60), closed to other keys apart from `_`-prefixed notes. Checked on a clean export of HEAD d55c612f:

- it applies to HEAD;
- **with it and the park's data row (the `step_up` line of `data/anim/ground_motion.json` from `step-up.patch`): `validate.js` 321 files, 0 errors, self-test 10093 of 10093**; the data row **without** the grant fails once ("/step_up [additionalProperties] unknown property"), so the grant has to land with the park;
- the block is not in the top-level `required`, so a `ground_motion.json` without it stays valid (the step-up is optional, as the park says);
- the data's values sit inside the bounds (`min_bh` 0.5, `bh` 75, `max_move` 200, `ref_bh` 2, `p_min` 0.5, `ticks` 12); `ticks` at its minimum of 12 matches the look ("in over 6, out over 6 at 12").

Nothing to re-cut.

## The fixtures: `step-up-cases.patch` (sha1 `dd5ef0c0871502c43a4b55c72354512bf39fcfa8`)

The self-test stays green without cases (anim-ground-motion already has 78), but a changed shape should come with them. 13 cases, inserted after the last anim-ground-motion case of `tools/fixtures/cases.json`; each sets the whole `step_up` block, so none depends on the park's data row being on main:

| Case | Expect |
| :--- | :--- |
| `valid`; `underscore-key-ok` | none |
| `ticks-under-12` (11); `ticks-over-60` (61) | minimum / maximum at `/step_up/ticks` |
| `ticks-not-integer` (12.5) | type at `/step_up/ticks` |
| `p_min-over-1` (1.5) | maximum at `/step_up/p_min` |
| `ref_bh-zero`; `bh-zero` | exclusiveMinimum at `/step_up/ref_bh`, `/step_up/bh` |
| `max_move-negative` (-1) | minimum at `/step_up/max_move` |
| `min_bh-over-10` (11) | maximum at `/step_up/min_bh` |
| `enabled-not-boolean` ("yes") | type at `/step_up/enabled` |
| `key-required-enabled` | required at `/step_up` |
| `unknown-key` (`speed`) | additionalProperties at `/step_up/speed` |

**Proof** (clean HEAD export with the grant and the data row): self-test **10093 of 10093** before, **10106 of 10106** after (13 cases). **Negative control:** with `ticks.minimum` set to 0, `p_min.maximum` to 5, `enabled.type` removed and `additionalProperties` opened, exactly `ticks-under-12`, `p_min-over-1`, `enabled-not-boolean` and `unknown-key` fail (10102 of 10106); restored, 10106 of 10106. The patch applies to HEAD alone; it must land **with the grant** (a valid case fails on a schema without the block).

## Not proven, and one note on the other parked cases

- I did not run `anim_check` or anything in Godot: this review is the schema and the data, which is what `validate` reads. Animation's park README carries the anim_check numbers.
- **A conflict I found while checking this, not caused by it:** `docs/tools/pending/camera-swing-cases/camera-swing-cases.patch` and `docs/tools/pending/world-schema-cases/world-schema-cases.patch` both append at the end of `tools/fixtures/cases.json`; applied one after the other on a clean export of HEAD d55c612f, the second does not apply, in either order. Each applies alone, and arc-size, ui-modes, wall-cone and this one each apply together with either of them (I tried this one with each, in both orders). If both are to land, land one, then I re-cut the other on top (a short job). `camera-swing-cases` has no README in the folder, so I have not checked what it holds.
