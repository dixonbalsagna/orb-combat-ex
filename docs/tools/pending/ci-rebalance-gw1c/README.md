# Park: "Godot headless checks 2 of 3" back under its limit (Tools, 2026-11-26)

`ci-rebalance-gw1c.patch`: `.github/workflows/ci.yml` and `tools/ci-budgets.json`.

**What happened** (run 45784210995 on cbb6a7d0): the job was cancelled at its 45-minute limit (08:33:48 to 09:19:02), in its last step. Nothing failed. It had been at 28 to 33 minutes against a 30-minute budget since GW1c; this runner ran every step about 1.4 times slower.

**The change:** nothing is dropped; two groups move into jobs with room. The hold answer check (7 to 13 min) to "3 of 3 (rollback)"; the cross end check and its negative control (4 to 6 min) to "3 of 3, c (bark reads)". The limit is unchanged.

| Job | Before | After (estimate) |
|---|---|---|
| 2 of 3 | 28 to 33, one cancel at 45 | 18 to 20, about 27 on a slow runner |
| 3 of 3 (rollback) | 9 to 11 | 17 to 21, about 25 slow |
| 3 of 3, c | 7 to 9 | 11 to 15 |

The "after" figures are added up from step times, not measured: the first green run gives the real ones. Run: workflow, budgets and script-table checks.
