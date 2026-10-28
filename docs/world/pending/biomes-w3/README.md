# biomes-w3: trees on a path by mode, and the aftermath strips in surfaceAt and lookAt (parked, window 22)

World and Environment, 2026-10-27. Stacked on main (09fff642). The first of World's pieces of `docs/combat/biomes.md` section 6 for Encounter's W3; no grant, no non-World line. Behind the director's own switch: every default is today's, so gen 1, the hand-made world and the golden are byte-identical (all five `run-all` stages pass).

## Apply

```
git -c core.autocrlf=false apply docs/world/pending/biomes-w3/biomes-w3.diff     # sha1 0c18e19d6e3f, 6 files
```

`mk_p29.py` (with `mk_wbc_lib.py`) rebuilds the four sim files from main byte for byte; `docs/world/after.md` and `sim/world/tools/after_check.gd` are edited in the diff only.

## What it adds

1. **Trees on a path.** `WorldStructures.damageArea(..., reachMul, treeMode = "area")`: the director passes the signature row's `trees` for each beam sample, which retires W1's "read as area until World builds the rest".
   - `area` (the default): what it always was: felled, with the fire cue.
   - `burn`: felled and charred (`burn` 1; the tree view already draws that as a charred stump), with the fire cue.
   - `fell`: felled, no fire.
   - `snap`: felled, with a crown-drop `debris` cue at each tree.
   - `none`: the trees stand.
   Which trees are reached is unchanged (within 0.7 of the sample's radius).
2. **The strips in `lookAt` and `surfaceAt`** (Combat's `stripLooks`). `WorldContact.lookAt` now returns `ice` on a glaze, `crust` on an ember strip and a cooled one, `ash` on burnt grass and `water` on a flooded groove; scree is surface `rubble` already (it is in `S.rubble`). `WorldContact.surfaceAt` returns `rock` on glaze, ember and crust (ice and crust are rock, as ground.json has them), rubble first as ever. Both read the strips only when `S.aftermath` is sized (the aftermath switch on), so nothing changes with it off.
3. **A correction to my earlier note.** The first aftermaths park added an `ember` look class; Combat's `stripLooks` says an ember strip reads `crust`, so that class is gone again (`ground.gd` `LOOKS` is as it was). **No `ember` row is needed by Animation, VFX or Rendering.**

## Proof

`after_check` 0 failed (adds: the five tree modes and the cues each makes, the far tree standing in all; glaze on rock with the plains beside it soil; ember reads crust on rock; a flooded groove reads water). All 46 World checks and both probes 0 failed; lint clean; validate self-test 9675 of 9675; `run-all` all 5 stages; `gen2_soak` 900, `--b`, `--rivers`: 12 of 12 each; the render gates pass (`cull` and `outline` refuse to run under --headless, as before; `warm_async_check`, Audio's, read 55 ms against its 50 bar in the chain under heavy machine load and 6 to 15 ms on three runs alone, with and without this change).
