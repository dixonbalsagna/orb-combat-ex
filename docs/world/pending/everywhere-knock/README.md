# Park: "a knock in reach of a building aims at it", and why Encounter's staged one didn't (World, 2026-11-14; EP, from docs/director/pending/gw1a-pins/README.md)

Check only: `everywhere-knock.diff` adds two rows to `sim/world/tools/everywhere_check.gd` (applies to HEAD). Run: `docs/world/runs/everywhere-knock/`.

## Verdict: expected, not a fault in Orb's game. A staging artifact of the checks, with one design note

**Cause (read, then measured on knock_wall_check's own staging: seed 11, planet 7, touch 2, `plans.everywhere` on).** The knock aims at a standing building of the **index** (`WorldStructures.near`), on the side he goes, inside the knock's reach and the depth window, nearest first, taking the first of up to three whose flight reaches it (`DirLaunch._wall`, `_wallPlan`). The index leaves out a building whose front face stands toward the camera past `plans.indexFrontBH` (-3 bh = -225): the view lowers such a building, so it is not struck (`WorldStructures.inBand`; the rule is Rendering's, in the index build). With `plans.everywhere` on the world holds 3,794 buildings instead of 297 and many stand in front of the lane. `knock_wall_check` stages its target beside "the building with the smallest face distance from the plane" over **all** buildings. On the field world with plans that is building 2078 (face 19 units off the plane, but its centre 237 and its front face 455 toward the camera): outside the index. `near()` returned 21 of 3,794 buildings and not it, though it stands 80 units away. The knock then aimed at the nearest indexed wall whose flight works: 2083 (27 units ahead, 1,702 behind the lane) fails, 2084 (258 ahead, 1,866 behind) takes him. The knock still hit a wall, so "2 hits": a different one from the one the check named. That is the mechanism working as written. With the arena's streets (everywhere off) the nearest building to the plane is a front-row one inside the index, so the staging happened to coincide.

**Not a fault**, because: nothing is wrongly skipped (the index rule is by design and Rendering's), the knock never fails to find a wall that is there to be found, and it hit one. The pin Encounter put on both checks is correct for GW1a as a pin; the better fix is to stage from the index (below).

**Design note for Game Design (not a World fault).** With `plans.everywhere` the lane has no front-row wall beside the fight any more (the plan streets stand behind it or toward the camera), so a knock tends to take the nearest-in-x wall that is **1,700 to 1,900 units behind the lane** in the background rows, because the order is by distance along the line only (depth does not enter, inside a 2,212 window). Whether a knock should prefer a wall near the fighters' depth over a nearer-in-x one deep in the background is a call about how it looks; the rule is `DirLaunch._wall`'s (Encounter's file), the window `lanes.json` z_back.

## The rows (`everywhere_check`)

- "a knock in reach of a building aims at the nearest indexed one it can reach": staged on knock_wall_check's match beside the nearest **indexed** building, 80 units from its near side, tier 4: the knock aims at exactly the first reachable candidate (the check recomputes the candidates from the index, the depth window and `_wallPlan`; reads building 866 of 4 in reach).
- "a building toward the camera past the index front is outside the index and is not aimed at" (building 1252, z -206, depth 367).
- Pass: `EVERYWHERE` 0 failed. With the knock off (`setWallForce(0)`) the first row fails by construction (the aim is -1).

## NEEDS FROM EP

- **Encounter:** `knock_wall_check` and `walk_check` can stage from the index: pick the building from `WorldStructures.near(S, x, reach)` (an indexed one) instead of from all buildings, and the GW1a pin comes off. The rows here show the contract.
- **Game Design:** the design note above (nearest-in-x versus nearest in depth).

## RISKS

- None to the sim: a check only.
