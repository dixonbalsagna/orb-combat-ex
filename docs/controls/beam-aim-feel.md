# Beam aim and the charge, read off Orb's thumb (Controls, 2026-11-01; proposal, nothing landed)

For Orb's order: "lets workshop the way beams are aimed and make the controls feel really responsive and engaging", with charge stages on a hold and a timed release. The numbers are from Orb's own first-play log (`homework/Files/orb-first-play-20261101-2130.json`: 11,873 raw samples of the right stick on an Xbox 360 pad, 415 seconds, 47 holds, 53 requests). **The file stays private: this page carries counts only.** The readers are `docs/controls/clips/read-orb-aim.cjs` (this page's numbers) and `read-stick-log.cjs` (the earlier page, `orb-first-play-stick.md`). A hold below means "the stick at the request line (raw 0.70) until it falls under the release line (raw 0.51)", which is what the strike reader calls down.

## In short

1. **The stick works well and Orb's thumb is easy to read.** It rests at 0.03 (never over 0.12), goes to the rim (1.0 to 1.15) in one frame, and stays there with no sag: before the final fall a hold never dipped under 80% of its rim (the lowest dip is 93% of it at the tenth percentile). A dead zone of 0.25 is twice the rest noise and costs Orb nothing: only 4 of 51 pushes ever stopped between the dead zone and the request line. **Keep 0.25.** Do not make the stick analog (a half push is not how Orb plays it).
2. **The aim is lost at the moment it is needed.** The stick springs home in 13 ms (under one tick) once the thumb lifts, so on the tick the beam is thrown the stick is already at rest. **In 38 of the 53 release rows the aim reads 0, which is "right".** Orb's holds were 18 left and 14 right, so every left-hand beam would have fired right. The fix is small: remember the aim the stick held at the rim and use that on the throw (section 3).
3. **While held, the aim wobbles by about one sector.** On the rim the aim's spread is 3° (median), 11° (the worst tenth), and 26 of 41 holds changed the 32-way sector at least once with the thumb meaning to hold still. A trailing dead band of 4° cuts the changes by 43% (51 to 29) at no more than 4° of lag.
4. **Orb aims sideways.** 32 of 41 holds were within 22° of straight left or right, 5 more were down-left, and only 2 were straight up or down. The elevation aim of a steerable beam is therefore not yet exercised by Orb's play: the numbers say the sideways aim is good, and say nothing about up and down.
5. **A stage is felt by the pad as a short pulse, and the release by an answer in the same tick.** Spring-back is under one tick for most releases, so a pulse on the throw reads as caused by the lift. Keep rumble off while the thumb is aiming (section 5).
6. **Orb holds longer than the old ladder assumed**: half of all holds are 26 ticks or more, and 11 of 47 reached the third rung (54 ticks), 4 reached 84. A six-stage form needs gaps that fit that (section 5).

## 1. What the thumb does (counts only)

| Question | Answer |
| :--- | :--- |
| **Rest** | mean offset (-0.02, +0.01); noise 0.03 (50th), 0.09 (99th), 0.117 at most |
| **Rim** | 1.0 to 1.1 (the pad's gate overshoots on the diagonals: the largest sample is 1.158; the reader clamps at 1) |
| **Speed out** | 50% of the way to the rim in 9 ms (median), 80% in 17 ms; the line that starts a request (0.70) is crossed inside one frame for most pushes |
| **How the stick is used** | 80% of the samples are at rest, 19% at the rim, 3% between: a switch with a direction |
| **Pushes that stopped short of the line (0.25 to 0.70)** | 4 of 51 (peaks 0.25, 0.33, 0.40, 0.42) |
| **Hold length** | 171 ms (tenth), 517 ms (median), 1,134 ms (ninetieth), 1,876 at most; 14 of 47 under 12 ticks (flicks), 33 reach 12, 21 reach 30, 11 reach 54, 4 reach 84, none reach 120 |
| **The clock** | the sim's ticks match the clock over every long hold (ratio 1.0 at the tenth, median and ninetieth): the charge was not starved by slow frames in this match |
| **Direction of the rim** (41 holds with a steady rim) | right 14, left 18, down-left 5, up-right 1, up 1, up-left 1, down 1 |
| **Sag on a hold** | none: the lowest magnitude before the final fall is 93% of the rim (tenth percentile), 98% (median); no hold dropped under 80% |
| **Spring-back** | from the last rim sample to under the release line: 8 ms (tenth), 13 (median), 33 (ninetieth), 71 at most. Under one tick for most; two for nine in ten |
| **Bounce past the centre after a release** | 17 of 41 holds leaned the other way within 200 ms, by 0.4 at most. Under the request line (0.70) every time, so no false push; above the dead zone sometimes, so the aim must not be read after the throw |
| **Pumps** (a second push within 150 ms) | 3 of 46 gaps; 7 within 300 ms, six of them in the same direction (a re-push, not a new aim) |
| **Re-aim while held** | 7 holds moved their aim by more than 20° on the rim (3 by more than 45°); 3 of the 11 holds that reached the third rung (54 ticks) were re-aimed: aiming while charging is something Orb does |
| **Speed of a re-aim** | the median hold does not move at all (0°/s); 90th percentile 94°/s, 99th 397°/s |

## 2. The dead zone

| Line | Today | Orb's thumb | Verdict |
| :--- | ---: | :--- | :--- |
| Strike dead zone (`strike.deadzone`) | 0.25 | rest never over 0.12 | **keep**: 2x the rest noise, and the move stick's 0.20 is its own |
| Request line (`on`, raw) | 0.70 | crossed inside a frame | keep. Lowering it would only catch the 4 short leans, which are not requests |
| Release line (`off`, raw) | 0.51 | thumb lifts in 13 ms | keep. The fall from the rim to under it takes under one tick for most, so moving the line by a few tenths changes the release tick for few of them |
| **Where the aim is read** | from 0.25 up, even at rest, bounces included | angle noise at the rest level of 0.03: 6.8° at 0.25, 3.4° at 0.50, 1.7° at 1.0 | **read only while the stick is down (raw 0.51 and up)**: 3.4° of noise at worst; at rest the aim is 0. No new line is needed: the release line already does it |
| Worn or drifting pads | | the rest noise on this pad is low; a worn pad can sit at 0.15 to 0.2 | the strike dead zone is already data (`strike.deadzone`); a settings row can offer 0.25, 0.30, 0.40, which is also the accessibility answer for a tremor. Not built |

## 3. Aim while charging

**What is wrong today, in order of how much it matters.**

1. **The throw loses the aim** (above): 38 of 53 release rows carry 0.
2. **The start's aim is a 90° quadrant**, locked at the settle (2 ticks, 33 ms after the line). For a strike that is right: the quadrant at 33 ms differs from the rim's in 1 of 41 holds. For a beam that is steered, a latch at the settle is off by 3.3° (median), 16.6° (ninetieth), 50° at worst, because the thumb is still sweeping to its place; 100 ms later it is 3.6° and 10.4°.
3. **The sector wobbles on the rim**: 26 of 41 holds changed a 32-way sector at least once while the thumb held still, 17 even with a quarter-sector of hysteresis.
4. **The aim after the fall is the bounce** (17 of 41), so it must be frozen.

**What I propose and have built (in `SimStrikeRead`, behind `switches.beamAim`, off; the park is `docs/controls/pending/beam-aim/`, section 7):**

| Piece | Rule | Why, in Orb's numbers |
| :--- | :--- | :--- |
| **Aim is read only while the stick is down** | the live aim updates only between the request line and the release line; at rest it is 0 | angle noise at 0.25 is 4x the rim's, and the bounce after a release (17 of 41) is not read |
| **Trailing dead band** | the shown aim follows the stick but only moves once the stick is more than 4° from it, then trails 4° behind it | 51 to 29 sector changes over the 41 holds; never more than 4° behind (under one 11.25° sector); real re-aims at the 99th percentile speed (397°/s, 6.6°/tick) are followed with 4° of lag |
| **The throw's aim is the rim mean** | on the release edge `rsAim` is the sector of the mean of the last 3 ticks the stick was at 85% of its hold's peak or more | error against the whole rim: 2.6° (median), 10.4° (ninetieth); the last tick alone gives 14.1° at the ninetieth |
| **A flick shorter than the settle** | the same rule, from the one to three rim ticks it has; if none reach 85%, the peak vector | the flick is the thumb's arc, not a rim; the peak is the best of it |
| **After the throw, the aim is held at the latched value for the release tick only** | the edge carries it; the next ticks go back to the live aim (0 at rest) | the bounce is not read |

32 sectors (11.25°) stay: the intent's word is five bits, and the aim steers a beam by elevation across the screen; finer needs a bit of the word and a hash-version bump that the 2v2 note (`two-v-two-input.md`) also draws on. With the dead band, a 64-way output costs 54 changes against 29, so finer only pays if Game Design wants the beam sweep to be smoother than 11°.

**What stays live while charging**: yes, aim is continuous. Orb's point ("really responsive and engaging") is that the hand and the beam's origin follow the thumb at once. The trailing band is the only filter, and it never lags more than a sector. This is the `rsAim` field the Encounter chain already carries; the director's part (the arm and the beam's elevation following it) is Encounter's.

## 4. Latching the first direction (the quick beam)

A flick with RB (under 12 ticks, 30% of Orb's holds) cannot track: it lives 3 to 11 ticks. It gets the rim-mean rule above. The signature (RT + stick) is aimed "at him, always" by Game Design's page, so its stick direction only has to start the charge.

## 5. How a charge stage is felt

**By the hand.** The thumb is pinned at the rim for 0.5 s (median) to 1.1 s (ninetieth) with no sag: the hold is solid, so a stage cue needs no help to be read. The other hand is free (RB is the right index), so stage timing is easy: the least gap between two rungs in a 6-stage form should be a third of a second or more. Long holds are not fatigued in a way the data shows: the aim drifts by about 7° (median) in every length bucket, 6.6 to 8.7. What changes is that long holds are re-aimed (3 of the 11 that passed 54 ticks), which is the "aim while charging" Orb wants.

**By the pad.** The Xbox 360 pad has two motors, a heavy one in the left grip and a light one in the right, and none in the triggers. The existing kinds `ladder_1` (a tick), `ladder_2` (a knock) and `ladder_3` (a thud and a ring) are the stage cue. For N stages:

| Stage | Pulse |
| :--- | :--- |
| 1 | `ladder_1` |
| 2 to N-1 | `ladder_2`, 8% stronger each stage (so stage 5 of 6 is about 26% over stage 2) |
| N (the top) | `ladder_3`, with the ring |
| 2-stage form | `ladder_1`, then `ladder_3` |

A pulse is a few tens of milliseconds, **no hum in between**. A continuous rumble would shake the pad under the thumb while it aims; this file is the no-rumble baseline (aim spread 3.2°) so the cost can be measured: play with the ladder on and read the same numbers. If the spread rises, keep pulses only. **The throw gets a thump on its tick** (`release`, a new short kind): the pad answers the lift in the same tick the sim takes it, so the player feels the release as caused by the thumb. This is the felt half of "timing the release".

**The ladder of ticks.** Orb's holds, in ticks, reached each rung as follows (47 holds):

| Rung (ticks) | 12 | 30 | 54 | 84 | 120 | 162 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Holds reaching it | 33 (70%) | 21 (45%) | 11 (23%) | 4 (9%) | 0 | 0 |

The ladder is Game Design's (and Orb's: "base level up to two stages, max form something like six"). The input side's findings: the first rung stays at 12 ticks, because that is where a flick ends and a hold begins (14 of 47 holds are under it); the gaps between rungs should be at least 16 ticks, so a thumb can aim at a rung (Orb's hold lengths have no pile-up at the old rungs, so nobody is timing them yet); and a six-stage form on the old gaps (12, 30, 54, 84, 120, 162) would put its top at 2.7 seconds, longer than any hold Orb made (1.9 s at most). **Option for GD**: gaps that grow more slowly, 12, 28, 46, 66, 90, 120 (top at 2 seconds, in reach of Orb's longest holds, still a real risk with a beam coming).

## 6. The timed release

What Controls can promise: the **release edge** (`rsRelease`) happens within a tick of the thumb's lift (spring-back 13 ms median, 33 at the ninetieth), and its level and aim are the stick's; nothing on the pad's side adds delay. What cannot be read from this file: how steady Orb's release is against a target, since no beam was in front of the thumb when the log was made (the director's cues are not in it). A timed-release window therefore needs a measured scatter. **A drill for the capture tool** (`right-stick-capture.md`): a flash on screen, the thumb releases on it, 30 trials per level, and the spread of the release against the flash is the half-width of the window (a window of two standard deviations lets about nine in ten releases count). Until then the design should not size a window narrower than 6 ticks (100 ms) each side.

**Judge the release on the edge tick** (`rsRelease`), not on the beam's contact, as the stick-strike answers already do (`beam-answers-input.md`): the throw is the beam's start, and the thumb's decision is made when it lifts.

**What I could not see**: Orb said "hard to charge up an attack when every hit seems to interrupt." The input record shows no interrupt on the reader's side: 53 starts, 53 releases, 1 cancel, so the reader never lost a charge. If a hit ends a charge, the director does it, and the input file cannot show it. **That is a design question for Game Design**: does a light hit break a charge, and does the pad say so (a short refuse knock) so a lost charge is told?

## 7. Built and tested (a park, off): `docs/controls/pending/beam-aim/`

`beam-aim.patch` (apply after `first-press.patch` and `haptic-switches.patch`; it touches `sim/input/strike_read.gd`, `input_data.gd`, `data/input/timing.json`, `tools/schemas/input-timing.schema.json`, a new test and a new probe). `switches.beamAim` is off, and with it off every aim is the one it always was (checked). Numbers: `strike.aimTrail` 4 degrees, `strike.aimLatchTicks` 3, `strike.aimLatchPeak` 0.85, all in data.

| Check | Result |
| :--- | :--- |
| `beam_aim_test.gd` (scripted thumbs with the measured wobble) | 31 checks, 0 failed: the throw carries the held direction in all 8 directions; 60 spread holds all within two sectors of the held direction, at most 6 more than one off; a re-aim of 80° is followed by the tick after it ends and thrown there; a flick shorter than the settle takes its peak; the bounce is not read; inert and cancelled charges unchanged; switch off is the old stream |
| Whole input suite (28 tests) and `node tools/lint-determinism.mjs`, `node tools/validate.js` | pass on the full stack |
| **Orb's own samples through the real reader** (`orb_aim_probe.gd`, counts only; the plain reader with no law or lockouts, so it counts all 103 pushes, not the 53 requests the game made) | **off: 92 of 103 throws carry aim 0, the error against the held direction is 154° (median).** **On: 1 of 103 carries 0, the error is 4.2° (median), 7.2° (ninetieth), 49.9° at worst (a flick's arc).** The shown aim changes while a charge is held: 63 times off, 42 on |

Not in this park: the director's use of `rsAim` (Encounter's). The release thump and the stage scaling of the ladder pulses (section 5) are built in `docs/controls/pending/stage-haptics/`, behind `switches.hapticLadder`, off.

## 8. For the other directors

- **Game Design**: stage count and rung spacing (section 5); does a light hit break a charge, and does the pad say so; how wide the release window is (after the drill).
- **Encounter**: the arm and the beam elevation follow `rsAim` while charging (it is live and filtered), and the throw takes `rsAim` from the release edge, not from a later tick. Today the director does not read it.
- **Simulation / Netcode**: nothing changes in the word (the aim stays five bits); the latched aim rides in the existing field.
- **Audio / VFX / UI**: a stage tick for each rung (UI's `charge_stage` cue is the right carrier); the release thump has a sound twin.
