# Encounter's uncommitted paths, for the EP's working-tree clean-up (2026-11-14)

Asked by Sat noon (sprint A1). My owned paths: `sim/director/`, `data/director/`, `docs/director/`. Nothing in `sim/director/` or `data/director/` is uncommitted. Each park was checked against main by the share of its diffs' added lines found verbatim in main's files (`landed_scan.py`, kept in my scratch), then read by hand where unclear.

## Commit (records and plans worth keeping)

| Path | What |
| :--- | :--- |
| `docs/director/runs/397a7adf/` | Gate records of the 2026-11-08 overnight parks (side-from-blow, arrive, carry-round, pace-match; CD-22) |
| `docs/director/runs/def3445a/stray-beams/` | stray-beams' gate records (A1) |
| `docs/director/beams-own-move-plan.md`, `flight-strikes-plan.md`, `launch-cuts-plan.md`, `two-v-two-plan.md` | the plans those landed parks were built from |
| `docs/director/img/shove-t00055.png`, `shove-t00065.png`, `shove-t00085.png` | the beam shove's look stills (small) |
| `docs/director/uncommitted-2026-11-14.md` | this page |

## Commit as parks (A1, current)

`docs/director/pending/stray-beams/` (GW1b riders, reported) and `docs/director/pending/director-rows/` (GW1a, the computer opponent; reported next).

## Delete: landed on main (26), or withdrawn (2)

**Landed** (at least 90% of their added lines on main):
- `b-one-rule`, `beam-aim`, `beam-hold`, `beam-still`, `candidates-heights`;
- `charge-armour`, `charge-close`;
- `chase-air`, `chase-carry`, `chase-tap`;
- `clash-end` (its code is on main behind `beamStruggle.endEvent`, off: 71% of lines, the rest are its data and schema keys);
- `ground-settle`, `idle-match`, `outside-blow`, `press-wait`, `ratchet-roster`, `slip-arrive`;
- `stance-circle`, `stick-pend`, `stick-steal`, `sure-reach`;
- `swing-pair`, `swing-plan-cost`;
- `two-fights-end`, `two-fights-join`, `two-fights-read`, `two-fights-swing`.

**Withdrawn** (their own READMEs say don't land):
- `plan-cost` (2026-10-31);
- `swing-warm` (2026-11-02: places-records landed instead).

The tracked deletion of `docs/director/pending/beam-struggle/` (5 files) is a landed park's folder: commit the deletion.

## Keep, not on main and still waiting

| Folder | Waiting on |
| :--- | :--- |
| `power-on` | Simulation's power flip |
| `brunt-tier1` | a Game Design lever (`town.bruntFromTier` 2 to 1); main still reads 2. Nobody has ordered it: say if it should be withdrawn |
| `town-sea` | Game Design's town-sea ruling (8% on main). Same question |

## Tools' call

`blackbox-clip-fix`: two fixes to Tools' and Rendering's files for black-box playback (2026-11-02), cut on Tools' stack tree. It isn't mine to land. Tools can say if it's superseded.
