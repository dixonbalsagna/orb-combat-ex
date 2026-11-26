# Park: the CI step for Simulation's size host check (Tools, 2026-11-26)

`ci-size-host.patch`: one step in `ci.yml`, job "Godot headless checks 3 of 3, c (bark reads)" (the job with the most room: about 11 to 15 of its 60 minutes).

**Apply together with** `docs/architecture/pending/size-host/` (its `size-host-check.patch`, sha1 f731354dc3a5, and its grant): without the script the workflow-paths check fails. With both: workflow, workflow-paths, budgets pass; script table 208 in CI, unreviewed stays 55.

The step: `node tools/gate.mjs --verdict -- "$GODOT" --headless --path . --script res://sim/core/tools/size_host_check.gd` (the script ends on `SIZE HOST: N check(s) failed`). Not run here.
