# GW1b: draft mapping from register rows to commits

**Status: section A confirmed by the EP on 2026-11-22 and applied, with A-CONTROLS-04 added (701cf676); A-AI-10 stays open (X-06's window); ADD-A1-03 and -05 part landed, ADD-A1-02 not closed.** Written 2026-11-22 by Production Operations from `git log --reverse 7b69eafc..b624340a` (58 commits; 7b5da0a5 is the first, a QA and Encounter X-06 commit that is not a GW1b park) and the commits' subjects and file lists (read-only `git log` and `git show --name-only`; no diffs read, nothing run). Confidence as in the GW1a draft: **placed**, **likely**, **unsure**; a row is proposed "landed" only when placed or likely.

## A. Rows GW1b closes (proposed landed)

| Row | Proposed commit | Basis | Confidence |
| --- | --- | --- | --- |
| A-WORLD-01 | 3aaac98c | "World: THE FLIP, the round planet is the world every match starts on (GW1b)"; touches data/biomes/world.json. Also df0e5942, 2917d4e4, aef24cf1, 139a4613 (a-world-01 parks), 37ac9a46 (pins), 991af282 (checks re-read), d43cc312 (Netcode planet) | placed |
| A-COMBAT-05 | 89eca66d | "Encounter: GW1b stray-beams": touches data/director/interrupts.json, beam_move.gd, exchange.gd; with f12dbace (schema grant), 7b119859 (dash probe), 2dd33c0d (Controls: stray-beams-input test) | placed |
| A-COMBAT-11 | 89eca66d | the second stray-beam fix (the signature window) rides in the same stray-beams park per the EP's list of GW1b riders; no separate commit names it | likely |
| A-ENERGY-05 | ab813cef | "Simulation: GW1b meters-zero": touches sim/core/damage.gd and fighter_data.gd; with cf17c9f6 (narrative meters grant) and the gw1b-energy set: 701cf676 (data/fight/power.json), a28b3c0c, b099e7fb | placed |

## B. GW1b riders the EP named that have no register row of their own

These are page notes in the tracker, not row closures; the path lists them as riders of the rows above.

| Rider | Commit(s) | Note |
| --- | --- | --- |
| launch cone | 653f0046 | touches sim/director/launch.gd and swing.gd |
| wall cone | 088264b3 (with 06e5e8c3, 407c073f) | touches data/director/launch.json |
| replay-world | 69ef6487 | Simulation |
| intro-store | 1afd96ae (with 9271a59e) | Simulation |
| gw1b-energy | 701cf676, a28b3c0c, b099e7fb | see A-ENERGY-05 |
| gw1b-golden | 57ad6454 | the GW1b re-record |

Also in the range, with no row: Encounter's gw1b-riders (9f745ea1, swing and beam-move files), index-stage (6a61d973), beam-aim-throw (0fe60eaa), bounce-count (78081692, may bear on the ping-pong bug ADD-A1-05), floorlift-rise (90889dd6) and World's floor-rise set (df6149d1, 2f549496, c11cc478), Simulation's floor-rise-unpin (878abcee), Animation's step-up (bd362be5, b7b3c57d, c4f58000) and water-tile-check (23313464), Rendering's strip-arena (8d8c0512) and join-press (3dd91f1c), VFX ghost-tally-parts (17c29ad0, 3706a592) and pins (aebda66a), Camera's four GW1b parks (8c30b457, b1dbda29, 94d1181f, 6c00b00f, 6c54231b, 240aeb72), Audio's recut (36a615e2), Netcode's desync marks (4c0aeecc, 203c1941), World's bystanders-gw1b (6e5d9b27), Tools' cases and CI lines (6bde912b, 0130112f), and the uid files (b624340a).

## C. Rows I cannot place

| Row | Why |
| --- | --- |
| A-CONTROLS-04 (flight 3500) | The EP says flat-out 3,500 and launch travel 1.5 are now main's own values, but no commit's file list names the flight setting (the candidates are 701cf676's data/fight/power.json and 57ad6454): **unsure**. Its paper landed in 970d15a6 |
| A-AI-10 (the computer perfect-blocks charged attacks) | 7b5da0a5 re-cuts the X-06 hold answer (data under docs, a park and QA's read), which is not the perfect-block fix itself: **unsure** |
| ADD-A1-05 (the launch-rebound bug) | bounce-count (78081692) and the wall-hold fix may bear on it; its done test (seeded launches plus Orb's eye) is not recorded: **unsure** |
| ADD-A1-02, -03 (terrain, destruction) | the floor-rise and wall-cone sets may belong to them; the EP has not said which part is done: **unsure** |
| ADD-A1-01 (five sizes) | the planet flip is the default world; the five sizes are GW1c (not in this range) |

## D. What happens when the EP confirms

Rows in section A become landed in status.json with the first commit as `ref` and the rest in the note. That would move A1 from 38 to 42 landed of 77 (the four rows above), minus any the EP holds. Section B items become a page note; section C stays as it is.
