# rail-row (Tools park, 2026-11-09)

The Tools row for UI's Rail menus (`docs/ui/menus-rail.md`; key `features.menus_rail` in `ui/data/features.json`, false as shipped).

## Apply

Cut to apply AFTER `docs/tools/pending/charge-lost-row/charge-lost-row.patch`, which itself applies after `docs/architecture/pending/dash-slip/grant-tools-slip.patch` (all three edit the self-test row list). Order: slip grant, charge-lost row, this.

```
git apply docs/architecture/pending/dash-slip/grant-tools-slip.patch
git apply docs/tools/pending/charge-lost-row/charge-lost-row.patch
git apply docs/tools/pending/rail-row/rail-row.patch
```

Two files, both Tools': `tools/preview/switches.mjs` (one row, `menusRail`, after `chargeLostCue`, before `airBrake`) and `tools/preview/preview-selftest.mjs` (`menusRail` in the expected ON list, same place).

## The row

`menusRail`: flips `features.menus_rail` false to true in `ui/data/features.json`. `optional` (waits, naming the key, if the key is missing from the tree; today the key is in the working tree, uncommitted), `needs: []`. No probe: the screens read `UiData.feature("menus_rail")` and nothing on the page's state probe depends on it. ON in the polish build, if UI's rule fix and the EP's look at the stills pass (the EP's word); to hold it instead, put `held: '<reason>'` on the row or leave it out of the ON list and say so.

## Checked

The patch applies after the other two on HEAD's tools tree (LF, no CR); `node --check` clean; the preview self-test is run in a scratch copy with all three patches (result in the report). Nothing is applied to the real tree.
