# civilians-removed: QA's switch (World, 2026-11-02)

A setup key `"civilians": false` removes every person from a match on a planet; off by default. Design and proof: `docs/world/civilians-removed.md` (copy it into docs/world/ with the diff). **Apply:** `civilians-removed.diff` (`sim/world/collateral.gd` `removeCivilians`, `sim/world/planet_world.gd` two lines after `WorldCollateral.init`, and the new `sim/world/tools/civilians_removed_check.gd`); plain `git apply` on the stack tree and on HEAD with the other World parks. **No Simulation grant.** **`tools/world-checks.json` needs `"civilians_removed_check"` in "run"** (hand-merge). `CIVILIANSREMOVED` 0 failed.

**Re-cut 2026-11-06 on HEAD 51ab2001:** applies as it was; **now carries its own line in `tools/world-checks.json`** (`civilians_removed_check`, in the diff). `CIVILIANSREMOVED` 0 failed on the full stack.
