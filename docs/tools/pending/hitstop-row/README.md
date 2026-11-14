# hitstop-row (Tools park, 2026-11-09)

The Tools row for Simulation's freeze budget on whichever table is live (`docs/architecture/pending/hitstop-any/`; key `budgetAny.enabled` in `data/fight/hitstop.json`, false as shipped). Simulation's grant for the schema and fixture (`grant-tools-hitstop.patch`) has no row in it, so this is mine.

## Apply

Cut to apply AFTER `docs/tools/pending/rail-row/rail-row.patch`. Full Tools order (all edit the self-test row list):

```
git apply docs/architecture/pending/dash-slip/grant-tools-slip.patch
git apply docs/tools/pending/charge-lost-row/charge-lost-row.patch
git apply docs/tools/pending/rail-row/rail-row.patch
git apply docs/tools/pending/hitstop-row/hitstop-row.patch
```

(The hit-stop grant, `grant-tools-hitstop.patch`, touches the schema and the fixture only and sits outside this chain.)

Two files, both Tools': `tools/preview/switches.mjs` (one row, `hitstopAny`, after `menusRail`, before `airBrake`) and `tools/preview/preview-selftest.mjs` (`hitstopAny` in the expected ON list, same place).

## The row

`hitstopAny`: flips `budgetAny.enabled` false to true in `data/fight/hitstop.json`. `optional`: the key is NOT in the tree until `hitstop-any.patch` lands, so until then the row waits and names it. `needs: []`. No probe. The flip was run on the post-patch data: only that one `enabled` changes (the top-level `enabled` and `neverCut` are untouched), though `budgetAny` is an inline object. ON in the polish build if Encounter's re-read holds (the EP's word); to hold it, put `held: '<reason>'` on the row and drop it from the self-test list.

The page word `hitstop=1` (hit-stop by weight, HITSTOP_SAMPLES) is a different switch and is not changed.

## Checked

The patch applies after the other three on the working tree's tools folder (LF, no CR); `node --check` clean; the preview self-test is run in a scratch copy with all four patches (result in the report). Nothing is applied to the real tree.
