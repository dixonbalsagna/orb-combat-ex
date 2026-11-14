# Controls' answer on the check scripts (A-CODE-04; the EP's wave 2 brief, 2026-11-14)

Tools' table (`docs/tools/check-scripts.md`) counts 262 scripts: 116 run in CI, 64 in the landing gate only, 82 unreviewed. **None of the 82 unreviewed is under Controls' paths:** `sim/input/test` has 45 scripts, all marked GATE, 0 unreviewed (`*_check.gd` and `*_test.gd` are all the table reads; Controls' `sim/input/tools/` holds probes, which the table does not list). So there is nothing of mine to review out of the 82. What follows is the answer to the question underneath it: which of my 45 should also run in CI.

## The recommendation: 44 in CI on every push, one in the landing gate

Measured (`runs/51b840f5/input-tests-timing.txt`; Godot headless, one job each, 3 at a time, below normal priority):
- **44 tests take 294 seconds in all**; 41 of them take under 13 seconds each (the slowest are `b_no_beam_test` 29, `touch_glue_test` 21 and `hold_toggle_test` 16); with 3 at a time that is about 2 minutes of wall time. They are deterministic, need no display, no network and no engine window, and each ends on `N checks, M failed` with exit 1 on a failure.
- **`b_no_beam_layouts_test` takes 245 seconds on its own** (the 504-run scan of B across layouts, stances and shoulders, which Game Design's ruling (b) asked for). It stays in the landing gate and the nightly job, not on every push.

So: **CI gets all of `sim/input/test/*_test.gd` except `b_no_beam_layouts_test`**, as one step that runs them 3 at a time through `tools/gate.mjs` (so a SCRIPT ERROR hidden by exit 0 fails it, as for the other Godot steps). The reason is what happened with the pad group: **4 of the 45 failed when only `timing.json` was flipped** (`runs/51b840f5/pad-group-input-suite-control-no-pins.txt`), and CI's data job checks only the shape of HEAD's data, not what a pad does with it, so a data flip like that reaches main with nothing in CI to say a test was written against the old default.

## Per script

All 45 are GATE today. In CI: every one except these:
- `b_no_beam_layouts_test`: the landing gate and the nightly job only (245 s).
- `touch_glue_test` (21 s) needs the `render/` folder in the tree, which CI's full checkout has: in CI.
- `mash_probe.gd` is in `sim/input/test/` but is a probe, not a test: it should move to `sim/input/tools/` (Controls' to do; no script in CI).

Who adds the step: Tools (`.github/workflows/ci.yml` is theirs); Controls supplies the loop if wanted: `for t in sim/input/test/*_test.gd` with `--script res://$t`, 3 at a time, each through `tools/gate.mjs`.
