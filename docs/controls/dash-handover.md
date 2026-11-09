# LT's dash handover (switches.dashHandover)

Owner: Controls. Park: `docs/controls/pending/dash-handover/`. Records: `docs/controls/runs/3aaf0df3/` (CD-22). From Game Design's ruling of 2026-11-08, section (c) (`docs/design/overnight-2026-11-08.md`): LT's high speed does not depend on range; "your piece is the lunge-to-sprint handover: at least 1,000 a second on the tick after LT's press and full by tick 12, while a tapped LT stays the slip (at most 1.5 bh if let go by tick 6)".

## What the pad did

A press of LT made the dodge edge and a **free 12-tick lunge** (`dodge.lungeTicks`): the intent's `dash` stayed true for 12 ticks whatever the release, then, if LT was still down, the sprint bit (`tapHold.holdStart`, 12) took over. So a hold had no gap, but a tap was a 12-tick dash. Measured at today's speeds (`lt_tap_probe.gd`, a rival 3,000 off, the stick toward him, 60 ticks):

| LT | dash ticks | travelled (bh) |
|---|---:|---:|
| none (the stick alone) | 0 | 4.98 |
| let go at tick 2, 4, 6, 7, 8 or 12 | 13 | 9.31 for every one of them |
| held | 60 | 17.18 |

A tap carried him 4.3 bh beyond the stick alone, whatever the release. With the dash fast at any range (Simulation's part), that 13-tick dash would be a leap, the opposite of "a tapped LT stays the slip".

## The handover

`switches.dashHandover` (off): the intent's `dash` is on from LT's press tick (the dodge edge is the first tick) and **only while LT is held** (and the stance is still LT's: LB pressed after it ends it; the LT + RT transform chord gives none). It ends the tick LT is let go. There is no lunge after a release. The sprint bit still starts at `tapHold.holdStart` (12), so the Escape (sprint away from the rival) is unchanged; the sim's speed reads `dash`, which is on from tick 1. The dodge edge, the take-back (4 ticks) and the flight strikes are untouched.

Measured the same way with the switch on (`runs/3aaf0df3/lt-tap-probe-on3000.txt`; 600 apart in `on600`):

| LT let go at | dash ticks | travelled (bh) | beyond the stick alone |
|---|---:|---:|---:|
| 2 | 2 | 5.91 | 0.93 |
| 4 | 4 | 6.56 | 1.58 |
| 6 | 6 | 7.20 | 2.22 |
| 8 | 8 | 7.83 | 2.85 |
| 12 | 12 | 9.07 | 4.09 |
| held | 60 | 17.18 | 12.20 (same as off) |

The dash follows the finger. A hold is unchanged.

## What is Simulation's

- **At least 1,000 a second on the tick after the press** is the sim's response: with the pad's dash on at tick 1, the speed on tick 1 is 223 at today's 11% a tick, 144 at 600 apart, 1,013 only on tick 6. That is `flightSpeed` and the velocity rise (Simulation's: "a faster rise for the held dash").
- **A tap at most 1.5 bh if let go by tick 6** is the sum of the dash's speed over ticks 1 to 6 plus the coast after the release. At today's speeds a tap at 6 carries 2.22 bh beyond the stick alone, at 4 it is 1.58, at 2 it is 0.93, and that is with the stick held out the whole time. With a first tick of 1,000 a second the first six ticks alone are about 1.3 bh, so the rise and the post-release decay have to be tuned together: the input side now gives the sim exactly the ticks LT was down, and cannot do better. The probe (`lt_tap_probe.gd`) is the measure; re-run it after the sim change.
- **Full speed by tick 12 with LT held** is the sim's rise on the dash's age (`f.act.dodgeTick`); the intent supplies `dash` from tick 1 and `dodgeHeld` (when `switches.dodgeHeld` is on).

## Tested

- `dash_handover_test` (15): a tap is a dash on the press tick and only while it is down (2 ticks, 6 ticks, the keyboard's dodge key); held, the dash is on from the first tick to the release and the sprint bit starts at `holdStart`; LB pressed after LT ends it; the LT + RT chord gives none; a host-held sprint (the touch outer ring) is the dash; a press and release inside one tick still moves him on that tick; through the sim a tap at tick 4 carries him less than 2 bh beyond the stick alone and a hold carries him far. Off (the control): a tap is `lungeTicks` dash ticks and carries him more than 3.5 bh.
- Negative control: with `layout.gd` put back, 7 checks fail (`dash-handover-negative-control.txt`).
- All 44 input tests pass with the four parks of this batch applied in order; lint and validate clean (321 files, 0 errors); each patch applies in sequence and reproduces the tested tree.
- Not run: the parity golden (a human's LT only; the switch is off), the director and QA rows for close times (Simulation's change is not in).

## To turn it on

Flip `switches.dashHandover` (a Tools row, or the landing commit) with Simulation's range-free dash; alone it only shortens a tap's dash, which is the slip Game Design wants.

## Measured on the Monday build (kept 6eec6a75-62e1fea3; dash at up to 5,000/s, arrive on), 2026-11-09

`runs/<this commit>/lt-tap-probe-kept-6eec6a75.txt`. Distance in body heights over 60 ticks, the stick alone being 4.98 (the slip bound is 1.5 bh beyond that, if let go by tick 6):

| Rival | handover | tap let go at 2 | at 4 | at 6 | held |
|---|---|---:|---:|---:|---:|
| 3,000 apart | off | 31.2 | 31.2 | 31.2 | 37.5 |
| 3,000 apart | on | 16.4 | 19.1 | 21.9 | 37.5 |
| 400 apart (5.3 bh) | off | 6.6 | 6.6 | 6.6 | 2.8 |
| 400 apart (5.3 bh) | on | 14.8 | 8.9 | 7.8 | 2.8 |

Neither state meets the bound. At 5,000/s the dash is 83 units (1.1 bh) a tick from tick 1, and the speed then decays at about 11% a tick after the release, so even a 2-tick tap leaves a 10 bh tail. Handover on halves a tap's leap at range, but near the rival the shortest taps fly past him (14.8 bh against 5.3 bh away), because the arrival ease (bands.arrive) runs only while the dash is held. The cure is Simulation's and Encounter's: a brake on release (cap the speed to the slip when the dash ends before tick 6) and the ease kept for the decay.

## With Simulation's slip brake (dash-slip park, on 592a807b), 2026-11-09

`runs/592a807b/lt-tap-probe-slip-matrix-592a807b.txt` (Simulation's probe, unchanged; the numbers reproduce theirs). Distance in bh over 60 ticks; the stick alone is 4.98, so the bound is 6.48 (1.5 bh beyond). "Today" is handover off, slip off. "On" is handover on, slip on. Slip alone changes nothing (the 12-tick lunge makes every tap 13 dash ticks, so the brake never fires): the two are one pair.

| Rival | LT let go at | today | on |
|---|---|---:|---:|
| 3,000 apart | 1 / 3 / 5 | 31.2 | 9.9 / 12.1 / 14.4 |
| 3,000 apart | 6 / 8 / 12 | 31.2 | 21.9 / 24.9 / 30.2 |
| 1,000 apart (13.3 bh) | 1 / 3 / 5 | 15.0 | 9.9 / 12.1 / 14.4 |
| 1,000 apart | 6 / 8 / 12 | 15.0 | 21.9 / 24.9 / 15.1 |
| 400 apart (5.3 bh) | 1 / 2 / 3 / 4 / 5 | 6.6 | 9.9 / 10.6 / 10.0 / 8.9 / 8.2 |
| 400 apart | 6 / 8 / 12 | 6.6 | 7.8 / 7.1 / 6.7 |
| any | held | 37.5 / 10.8 / 2.8 | the same |

- **Far taps (1 to 5 ticks): better by 17 to 21 bh** (31.2 down to 9.9-14.4), and a held LT is untouched. The bound is still not met (3.4 to 7.9 bh over it).
- **Near taps: worse.** At 5.3 bh a 1 to 3-tick tap carries him 9.9 to 10.6 bh, 4.6 to 5.3 bh past the rival; today's 13-tick lunge stops at him (6.6 bh, the arrival ease runs while the dash is held). Worse by 3.3 to 4.0 bh at 1 to 3 ticks, by 1.2 to 2.4 at 4 to 6.
- **Mid-range presses of 6 to 11 ticks: worse.** At 13.3 bh a 6 or 8-tick press flies 21.9 or 24.9 bh (8.6 to 11.6 past him) where today's 13-tick dash lands 1.7 past. The brake only covers 1 to 5 ticks, and the arrival ease stops with the dash.
- Both ends have the same cause: Encounter's arrival ease runs only while the dash is held. With the dash let go, the 5,000 a second kick's tail (and the brake's 1,125 coast) is not eased into striking distance.

## With Simulation's slip and Encounter's slip-arrive (five patches on cc958c18), 2026-11-09

`runs/cc958c18/lt-tap-probe-slip-arrive-matrix-cc958c18.txt` (raw: `...-raw-...`). Independent re-run of the tap matrix, Simulation's probe, every press 1 to 12, at 3,000, 1,000, 400 and 200 apart, today (handover off, slip off) against on (handover on, slip on, underTicks 12, the arrival's carry and its 13-tick hold). **No row is worse than today.** Far (3,000): presses 1 to 11 carry 9.9 to 22.0 bh instead of 31.2 (21 to 9 bh shorter), press 12 is 1.0 shorter, a held LT is the same. Mid (1,000): presses 1 to 7 are 5.1 to 0.0 shorter, the rest equal. Close (400 and 200): every press equals today, to the hundredth. The 1.5 bh slip bound is still not met far away (9.9 at the shortest press against 6.5), which is Simulation's and Game Design's lever. Not covered: a tap with the stick away from or across the rival, or a moving rival.

### Taps away from the rival and across (side probe, cc958c18, 2026-11-09)

`runs/cc958c18/lt-tap-probe-direction-cc958c18.txt` (probe `lt_tap_probe_dir.gd.txt`; raw in `...-raw-...`). Same five patches, a still rival, the stick held away (or across, up) for 60 ticks, presses 1 to 12, today against on. **Yes, the getaway is weaker for a tap, by design, and no row is better than today:** distance from the rival after 60 ticks, stick away at 400 apart (5.3 bh), today 36.6 for every press 1 to 11; on 15.2 (press 1), 17.4 (3), 20.9 (6), 27.4 (11), 35.7 (12) (9 to 21 bh less); at 200 apart 12.6 to 33.0 against 33.9; across at 400, 10.3 to 26.2 against 27.1. No LT and a held LT are identical (a held LT away is 86.7 bh travelled both ways), so the escape by hold is untouched. In the first 12 ticks a 1-tick tap away now covers 4.7 bh (today 15.4), a 3-tick 6.7, a 6-tick 10.0, a 12-tick 15.4: a tap is a step, a press of 12 or a hold is the getaway.
