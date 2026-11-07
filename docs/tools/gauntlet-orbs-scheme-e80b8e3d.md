# The gauntlet's "Orb's scheme" pad next to stick-only, on e80b8e3d (Tools, 2026-11-07)

Asked for by the stand-in through the EP: before anyone tunes from the stick-only pad, a fair arm that plays the way Orb's hands do. Tree: `homework/Files/builds/orb-first-play-a8bc66e2-e80b8e3d/tree` (refusedCue and the city rows OFF, proven from the index.pck). 10 matches a cell from seed 1 (same seeds for both pads), below-normal, 3 jobs. Raw cells: `gauntlet-orbs-scheme-e80b8e3d.json`.

## The two pads

- **stick-only** (the old arm): a right-stick flick in one of four directions every 8 to 24 ticks (2.5 to 7.5 a second), nothing else.
- **Orb's scheme** (new, `--arms orbs`, `tools/feel/gauntlet.gd`): the same right-stick flick (three ticks out, one of four directions, aimed from the fighter) every 30 to 48 ticks, so never faster than about 2 a second; and the left hand guards: LB held 10 ticks on every wind-up of the rival's (a heavy's wind-up, or any `windup` start cue, lights included: the same read as the timing pad), at most every 14 ticks. The left stick walks him toward the rival as for every pad. Nothing else: no dodge, no charge, no beam.

## Result

| Pad | Level | Win % (95%) | Refusals per 100 presses | Seconds without control a minute | Blows landed / taken (10 matches) |
| :--- | :--- | :--- | ---: | ---: | :--- |
| stick-only | easy | 20 (+/-23) | 52.3 | 58.0 | 10,892 / 8,503 |
| stick-only | medium | 0 (+/-14) | 23.1 | 57.2 | 12,589 / 9,006 |
| stick-only | hard | 0 (+/-14) | 43.4 | 56.0 | 4,718 / 10,259 |
| Orb's scheme | easy | 0 (+/-14) | 17.3 | 57.1 | 3,021 / 9,010 |
| Orb's scheme | medium | 0 (+/-14) | 24.6 | 56.2 | 3,349 / 10,126 |
| Orb's scheme | hard | 0 (+/-14) | 26.9 | 55.4 | 2,494 / 10,588 |

Presses made (10 matches): stick-only 18,287 / 17,035 / 9,809 (easy / medium / hard); Orb's scheme 4,569 / 5,414 / 5,310.

## Refusals by reason (the six largest in each cell)

| Cell | Reasons (count) |
| :--- | :--- |
| stick-only easy | stick/answered 4,151; stick/replaced 2,336; stick/0 1,633; stick/ki 843; stick/late 300; press_refused/y 136 |
| stick-only medium | stick/0 1,138; stick/replaced 1,109; stick/ki 539; stick/late 509; press_refused/y 217; stick/refused 217 |
| stick-only hard | stick/0 1,641; stick/replaced 1,320; stick/late 560; stick/answered 216; press_refused/y 203; stick/refused 203 |
| Orb's scheme easy | stick/0 423; stick/answered 170; press_refused/y 54; stick/refused 54; stick/replaced 41; stick/late 24 |
| Orb's scheme medium | stick/0 624; stick/answered 296; press_refused/y 102; stick/refused 102; stick/replaced 78; stick/late 73 |
| Orb's scheme hard | stick/0 705; stick/answered 191; stick/1 136; stick/late 112; press_refused/y 88; stick/refused 88 |

`stick/0` is a stick press refused with the source "0": it has no word in the UI (`prompt.refuse_0` does not exist), so the pad's player is told nothing. It is the largest or second largest reason for both pads at every level. `press_refused/y` and `stick/refused` have equal counts in every cell: they look like one event told twice.

## Reading it

- Orb's thumb-paced scheme loses all 30 matches, easy included (stick-only wins 2 of 10 on easy). It lands about a third as many blows as stick-only (3,021 against 10,892 on easy) and takes about the same number (9,010 against 8,503), so the guard on every wind-up did not make up for the flicks it gave up.
- Its refusal rate is lower on easy (17 against 52 per 100 presses); it presses about a quarter as often (4,569 presses against 18,287); on hard it is 27 against 43. Do not tune from the stick-only refusal rate: a pad that flicks 2.5 to 7.5 times a second is not Orb's hands.
- Seconds without control a minute are 55 to 58 for both pads at every level, so they do not tell the pads apart. The metric counts time locked, launched, down or stunned, and the computer's exchanges hold a pad there most of the minute.
- Limits: this pad aims each flick at random (one of four directions), never dodges, charges or fires a beam, and guards every wind-up whether or not the blow would land. It is a floor for a thumb-paced stick player, not a model of Orb. Ten matches a cell give about plus or minus 14 points at 0% and 23 at 20%.
