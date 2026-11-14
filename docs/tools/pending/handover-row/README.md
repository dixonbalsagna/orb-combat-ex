# handover-row (Tools park, 2026-11-09)

The Tools row for Controls' LT dash handover (`docs/controls/dash-handover.md`; key `switches.dashHandover` in `data/input/timing.json`, false as shipped, already in the tree). Controls says yes to dashHandover plus slip ON for 16:30, on Encounter's slip-arrive (`docs/director/pending/slip-arrive/`); the EP's brief of 2026-11-09.

## Apply

Cut to apply AFTER `docs/tools/pending/hitstop-row/hitstop-row.patch`. Full Tools order (all edit the self-test row list):

```
git apply docs/architecture/pending/dash-slip/grant-tools-slip.patch
git apply docs/tools/pending/charge-lost-row/charge-lost-row.patch
git apply docs/tools/pending/rail-row/rail-row.patch
git apply docs/tools/pending/hitstop-row/hitstop-row.patch
git apply docs/tools/pending/handover-row/handover-row.patch
```

Two files, both Tools': `tools/preview/switches.mjs` (one row, `dashHandover`, placed right after `slip` and before `carryRound`, the order the EP gave) and `tools/preview/preview-selftest.mjs` (`dashHandover` in the expected ON list, same place).

## The row

`dashHandover`: flips `switches.dashHandover` false to true in `data/input/timing.json`. `optional`, `needs: ['arrive', 'slip']`: with either off, it goes off too (the handover's fast dash needs the arrival, and a tap is only a slip with the brake). The key is already in timing.json, so it never waits on the key; it waits only through its two needs. No probe.

Today's ON list (the EP, to be confirmed at "build"): arrive, slip, dashHandover, carryRound, paceMatch, inertKnock, sideFromBlowOnly, chargeLostCue, menusRail, hitstopAny, airBrake. `slip` waits for dash-slip's key (`dash.slip.enabled`) until that park lands, and then so does this row. The page's `dash` word and the dash lines still follow `arrive` (preview.mjs dashWord).

## Checked

The patch applies after the other four on the working tree's tools folder (LF, no CR); `node --check` clean; the preview self-test is run in a scratch copy with all five patches (result in the report). Nothing is applied to the real tree.
