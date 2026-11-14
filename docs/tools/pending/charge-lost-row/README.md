# charge-lost-row (Tools park, 2026-11-09)

The Tools row for Controls' charge-lost park (`docs/controls/pending/charge-lost/`, key `switches.chargeLostCue` in `data/input/timing.json`, off as shipped). Controls' patch has no Tools row, so this is mine.

## Apply

Cut to apply AFTER `docs/architecture/pending/dash-slip/grant-tools-slip.patch` (the self-test row list carries `slip`). Order: slip grant, then this.

```
git apply docs/architecture/pending/dash-slip/grant-tools-slip.patch
git apply docs/tools/pending/charge-lost-row/charge-lost-row.patch
```

Two files, both Tools': `tools/preview/switches.mjs` (one row, after `sideFromBlowOnly`, before `airBrake`) and `tools/preview/preview-selftest.mjs` (`chargeLostCue` in the expected ON list, same place).

## The row

`chargeLostCue`: flips `switches.chargeLostCue` false to true in `data/input/timing.json`. `optional` (waits, naming the key, until Controls' park lands), `needs: []` (Controls: no pairing), a probe of `SimInputData.charge_lost_cue_on()` once `func charge_lost_cue_on` is in `sim/input/input_data.gd`. ON in the polish build (the EP).

## Checked

The patch applies after the slip grant on HEAD's tools tree (LF, no CR in the patch); `node --check` clean; `preview-selftest.mjs` run in a scratch copy with both patches (result in the report). Not run against the real tree: nothing is applied there until the EP commits.
