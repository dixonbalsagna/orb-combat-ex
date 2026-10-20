# Parked: the far field hazes into the sky, and Controls' haptics host (Rendering, 2026-10-19)

**Base:** HEAD 257a766c. The diff was checked on a copy of that commit, never on the tree.

**Apply** from the project root:

```
git -c core.autocrlf=false apply --check docs/rendering/pending/2026-10-19c/batch.diff
git -c core.autocrlf=false apply docs/rendering/pending/2026-10-19c/batch.diff
```

Then delete this folder, and `docs/controls/haptics-host.patch` with it (it is applied here).

## The pieces

| Piece | Files |
| :--- | :--- |
| **The far field hazes into the sky.** Between `HAZE_AT[2]` and `HAZE_AT[3]` (6,000 to 40,000) the haze's target moves from Art's value ladder (the horizon band, darker and greyer) to the sky's own colour in that direction (`HAZE_SKY` 1.0). Far peaks come back as faint silhouettes in the sky's colour, as on d3f1ca0e, instead of a huge brown ridge; nearer ridges keep the ladder. | `render/core/look.gd` (`HAZE_SKY`), `render/shaders/skycol.gdshaderinc` (`haze_ground`), `render/core/pane_world.gd` (the uniform), `docs/rendering/sky-and-distance.md` |
| **Controls' haptics host** (`docs/controls/haptics-host.patch`, as Controls wrote it): the sim's moments become rumble (`_haptics_from_events`), with a per-kind gap, and the form prompt goes through `SimHaptics`. | `render/core/main.gd` |

**For Art:** this bends Art's layer 6 in the far field, where a ridge used to "never reach the colour of the sky behind it". The ladder holds nearer than 6,000.

**Against d3f1ca0e** (seed 4, Reduce flashing on as the demo has it, motion normal; d3f1ca0e on the left from `homework/regression-compare`, this change on the right):
- `docs/rendering/img/haze-far-d3f1ca0e.png`, tick 1850;
- `docs/rendering/img/haze-far-d3f1ca0e-1167.png`, tick 1167.

Both uncommitted. Other variants tried, all at tick 1167:
- stronger haze alone (0.95 by 20,000; 0.97 by 12,000) left a tan wall;
- the sky target with that stronger haze removed the ridge entirely.

## Checked

`gates9` (17 checks), `cue_check` and Controls' `sim/input/test/haptics_test.gd` (80 checks) pass on a scratch copy of 257a766c with the diff, 0 script errors.
