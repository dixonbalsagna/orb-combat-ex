# places-reached: the places the fight reached, and their people (World, 2026-11-02)

The test (for Legal first), the records and the QA lines: `docs/world/places-reached.md` (copy it into docs/world/ with the diff). **Nothing is on:** the data rule exists, `WorldCollateral.placesReached` is a pure read nobody calls until QA's `records.gd` does (their grant, the lines are in the doc), and it changes no state or hash.

**Apply:** `places-reached.diff` (`sim/world/collateral.gd` `placesReachedRule`, `placesReached`; `data/biomes/field.json` `plans.placesReached`; `tools/schemas/biomes-field.schema.json`; the new `sim/world/tools/places_reached_check.gd`). Plain `git apply` on the stack tree. **`tools/world-checks.json` needs `"places_reached_check"` in "run"** (hand-merge).

**Proved:** `PLACESREACHED` 0 failed (planet 7: seven first-ring places hold pop0 between them; at the start only they are reached; two posed far places add their people; the loss in the places reached is the toll plus the far places' loss; a far place not posed is not reached and not lost; the whole planet is beside it; reading it changes no hash). `world-checks --verify` ok.

**Re-cut 2026-11-06 on HEAD 51ab2001:** applies as it was; **now carries its own line in `tools/world-checks.json`** (`places_reached_check`, in the diff). `PLACESREACHED` 0 failed on the full stack.
