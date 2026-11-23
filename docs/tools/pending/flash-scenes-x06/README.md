# flash-scenes-x06 (park, Tools, 2026-11-23; CI run 45201190857 on 0d21624b, job "Flash count", the recount's 8 problems)

X-06 (8006fe3d) changed how the Medium computer fights, and four of the flash scenes stopped showing the events they exist to show: mashdummy (launch 0 of 1), ring (damage 41 of 60), launchai (damage 52 of 60), signaturedummy (building_fall 0 of 1), each in both modes. **The guards are not loosened**: the scenes are re-staged longer, as after GW1b.

`flash-scenes-x06.patch` (sha1 `69544b859580164ee828161349147e91caf0dba3`, four files; applies to 4e3d4323): `tools/flash/sources.json` (the lengths), `.github/workflows/ci.yml` (scenes-2 cut in two sets), `docs/tools/dummy-ring-scenes.md` (this table and the reasons), `tools/flash/release-pass.json` (the `toRedo` note says the clips are longer again).

## Per scene (headless, the scratch exports of c83efe87, the last green run, and ead18383, one pairing each; `flash_worst.gd` unchanged)

| Scene | c83efe87, 1,800 ticks | ead18383, 1,800 ticks | Now |
| :--- | :--- | :--- | :--- |
| mashdummy, PROTAGONIST | damage 121, launch 1 | damage 86, launch 6 | 3,600 ticks |
| mashdummy, RIVAL | damage 145, launch 1 (the heavy planned a launch once) | damage 117, **launch 0, no launch planned**; one launch at 3,600 (a beam's), two at 5,400, the heavy none | 3,600 ticks |
| ring, 3 bodies | damage 109 | damage **41** (60 needed); 102 at 3,600 | 3,600 ticks (the 5-body ring was 75 and passed) |
| launchai | damage 99 | damage **52** (60 needed); 118 at 3,600 | 3,600 ticks |
| signaturedummy, PROTAGONIST (3,600) | damage 372, building falls 8 | damage 326, falls **0**; 6 at 5,400 | 5,400 ticks (the RIVAL pairing: 2 falls at 3,600) |

## Proof

All **14 runs** of the four scenes at their new lengths (every pairing, both modes), through the real `check-log.js --allow-missing`: no PROBLEM, every window under the caps (worst weight 2.15 of 2.5 normal, 1 of 1 reduced), `flash count passed`; 580 s locally. `split-merge-selftest` (17 checks, the new set included), `flash selftest` (100), `release-pass` self-test (113), `check-workflows`, `check-workflow-shell`, `ci-budgets-check` ok. Both parks apply together on 4e3d4323.

## What it costs

A pixel clip is as long as its scenario: these four scenes' clips (mashdummy 4, ring 4, launchai 2, signaturedummy 4) take up to twice as long to capture and read. In CI the one set `scenes-2` (10.6 minutes) would have become about 16, so it is **two sets**: scenes-2 (mashdummy, ring, about 8) and scenes-3 (launchai, clashcity, signaturedummy, blastdummy, about 10), each limit 30, budget 20, to be recorded from the first run.

## For Game Design's eye (a real play change, not a staging one)

- With X-06 the same ticks give about **half the damage** in the ring and in launchai (109 to 41, 99 to 52): the Medium computer takes less and answers more.
- **RIVAL's heavy mash at the idle dummy plans no launch in 5,400 ticks** (one in 1,800 before X-06). The clip's launcher chain is gone for RIVAL; the guard is met by a beam's launch. Whether the idle training dummy should answer holds and heavies like that is Game Design's call.
- signaturedummy's PROTAGONIST beams need 5,400 ticks to fell a building (3,600 before X-06, 1,800 before GW1b).

Not proven: the sets on a runner; the pixel readings of the longer clips (none taken).
