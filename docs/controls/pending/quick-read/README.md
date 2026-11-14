# Parked: the quick read (responsiveness), the timing keys and their schema

Controls, 2026-11-01. The code is in the tree and inert (`sim/input/`: `SimInputData.quick_on()`, `SimStrikeRead` `settleQuick` / `pre_dir` / `pre_depth`, `SimLeftHand` `early`, `SimLayout.strike_pre()`, `SimInputHub.strike_pre(slot)`; test `sim/input/test/quick_read_test.gd`, 30 checks; probes `sim/input/tools/latency_probe.gd` and `stick_hit_probe.gd`). The code defaults every key (switch off, `settleQuick` 1, `preAt` 0.25), so the tree validates and runs the shipped numbers without this park. What the park adds is the **data keys**, so a build can turn the switch on and the numbers can be tuned:

| Patch | Touches | What |
| :--- | :--- | :--- |
| `quick-read.patch` | `data/input/timing.json` (Controls'), `tools/schemas/input-timing.schema.json` (Tools') | `switches.quickRead` false, `strike.settleQuick` 1, `strike.preAt` 0.25, and the three schema properties. One patch because the closed schema fails `validate` on a key it does not know. `git apply --check` clean on b54dd326 + the landed right-hand work; if the CRLF working copy refuses a hunk, `--ignore-whitespace` |

Gates (clean export of HEAD + Controls' files + the patch): all 25 input tests pass (`quick_read_test` 30 checks), `validate` 0 errors 0 warnings, `lint-determinism` ok. With the switch off nothing changes; with it on the strike and brace read one tick sooner, the vanish resolves on the second press, and the layout publishes the stick's pre-read for the pose (render-only, never in the intent or the hash). Numbers and the reasons: `docs/controls/responsiveness.md`.

For Tools: `tools/preview/switches.mjs` can add `quickRead` as a ninth switch (the key is `data/input/timing.json` `switches.quickRead`, false to true). For Animation: the pose reads `hub.strike_pre(slot)` (`{dir, depth}` or `{}`) as it reads the other cues; the host passes it as it passes the stick. Delete this folder when the patch lands.
