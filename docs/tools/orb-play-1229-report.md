# Orb's morning play, the ledger and the slow frames (Tools, 2026-11-07)

File: `homework/Files/orb-first-play-20261107-1229.json` (build e80b8e3d: main a8bc66e2, stack key 0fefb541c93c, 69 rows on, refusedCue and the city rows off; saved 2026-11-07 20:29 UTC; Xbox 360 pad; planet 7, easy foe; 19,280 ticks, 5:21; KO at the end). Orb's words are at the end of `docs/ep/vision.md`. Rows and counts: `orb-play-1229-ledger.txt` and `.json` (the json now also carries, per press, `air`: his height over the ground, the rival's state, the rival's height over the ground, the gap).

## Does it replay?

Yes. Replayed on `homework/Files/builds/orb-first-play-a8bc66e2-e80b8e3d/tree`, it reproduces the saved final hash exactly (0ba7d303c755c467), so everything below is the match Orb played, not an approximation.

## The ledger (slot 0, the pad)

1,159 presses: 737 honoured (64%), 363 silent (31%), 44 refused, 15 partly. 422 not honoured (36%).

| Press | Presses | Honoured | Refused | Partly | Silent |
| :--- | ---: | ---: | ---: | ---: | ---: |
| heavy | 467 | 294 | 21 | 2 | 150 |
| sig | 358 | 236 | 16 | 2 | 104 |
| rsStart (a right-stick start) | 101 | 72 | 5 | 10 | 14 |
| light | 110 | 84 | 1 | 1 | 24 |
| dodge | 64 | 32 | 0 | 0 | 32 |
| guardPress | 47 | 18 | 1 | 0 | 28 |
| powerPress | 8 | 1 | 0 | 0 | 7 |
| transform | 3 | 0 | 0 | 0 | 3 |
| context | 1 | 0 | 0 | 0 | 1 |

By the fighter's state at the press: locked 994 presses (664 honoured, 278 silent), free 134 (72 honoured, 61 silent), launched 30 (1 honoured, 23 silent, 6 refused), down 1 (silent). Silent presses come in runs: 30 runs of three or more silent presses of one kind within three ticks of each other cover 170 of the 363 (the first is five signature presses at ticks 949 to 953).

Refusals by reason (59 rows that were refused or partly): press_stunned/y 17, press_stunned/b 10, stick/late 8, stick/0 5, driver_refused 5, press_zip/y 4, press_refused/y 3, press_refused/b 2, press_stunned/x 2, stick/replaced 2, stick/ki 1, press_zip/b 1. `stick/0` has no word in the UI (no `prompt.refuse_0`).

## Right-stick presses (101)

| Direction | Starts | Honoured | Partly | Refused | Silent |
| :--- | ---: | ---: | ---: | ---: | ---: |
| away | 48 | 41 | 4 | 2 | 1 |
| down | 34 | 20 | 5 | 2 | 7 |
| up | 14 | 6 | 1 | 1 | 6 |
| toward | 5 | 5 | 0 | 0 | 0 |

Reasons on the right stick: stick/late 8, stick/0 5, stick/replaced 2, stick/ki 1. All 14 silent starts were in the locked state (inside an exchange). Up is the worst: 6 of 14 silent.

## The down-flick on a foe in the air

34 down starts. In 33 of them the rival was in the air (his height over the ground read from several hundred up to over 13,000; the whole fight was up there), always in the `locked` state (inside an exchange) and 58 to 108 units away; the other was on the ground. Of the 34: 20 honoured (a start, a blow, or the press answered), 5 partly (stick/late, a refusal and something else), 2 refused (one `stick/ki`, one `stick/0`), 7 silent.

The silent ones cluster: ticks 5061 to 5065 are five down presses on consecutive ticks with no cue at all, followed by a sixth at 5066 refused with `stick/0`; ticks 16238 and 16239 are two more, between honoured presses. Nothing in the ledger shows a launch or a slam following a down start, because the ledger lists only the first four cues of each press; so I cannot say from it which press was the "mega slam" Orb tried for. What the numbers say is that about one down flick in five got no answer, and the clearest case is a five-tick burst inside a locked exchange.

## The slow frames

497 seconds, 66,310 frames: 21 frames over 33 ms, 7 over 50 ms, none over 100 ms, the worst 87.5 ms at tick 18454 (483.2 s). Page visible and focused throughout; no frames lost to a hidden tab.

| Ticks | Frames and worst | Mark near |
| :--- | :--- | :--- |
| 101 | 45.9 ms | crater 101 |
| 968 | 42.0 ms | launch 968 |
| 3499 | 37.6 ms | crater and building_fall 3499 |
| 4095, 4097, 4108 | 37.4 to 37.5 ms | launch 4078, building_fall 4082 (13 to 26 ticks before) |
| 7785 | 33.4 ms | none (building_fall 7744, launch 8098 near) |
| 13941 | 41.6 ms | crater and building_fall 13941 |
| 14015 | 33.4 ms | none |
| 17378 | 41.7 ms | crater and launch 17378 |
| 17588 | 54.3 ms | crater 17588 |
| 18450, 18452, 18454, 18458, 18463 | 37.5, 58.4, 87.5, 62.6, 37.6 ms | building_fall 18406 (44 ticks before) |
| 18699, 18701, 18703, 18706, 18711 | 37.5, 54.1, 79.5, 79.1, 41.6 ms | building_fall 18643 (56 ticks before) |

Seven of the eleven rows line up with a crater, launch or building fall at the same tick or within 26 ticks; the other four (7785, 14015 and the two worst clusters, 87.5 and 79.5 ms) have no mark of their own, and the two clusters come 44 and 56 ticks after a building fall. That is a coincidence in time, not a cause.

## The sound (from the file's audio record)

Both audio contexts were created at 0.5 s and 3.0 s and stayed `suspended` until a key press at 178.4 s; the first sound reached the output at 178.6 s. So nothing was audible for the first three minutes. Orb played with the pad only, and a pad press does not wake a browser's audio, so he heard nothing until he paused (a key press). This matches his note ("sound effects weren't audible until i paused the game the first time"). Audio's shell snippet that wakes the engine's context on a pad press is the fix the EP has asked to inject in every build. Over the whole match: 2,226 cues, 1,570 taken, 656 dropped, output peak 0.891.

## Against the 1934 save (a different match, build, and tree)

Silent presses are 363 of 1,159 (31%) against 306 of 1,264 (24%); heavy silent is 150 of 467 (32%) against 86 of 446 (19%), sig 104 of 358 against 96 of 425, dodge 32 of 64 against 51 of 110, right-stick silent 14 of 101 against 3 of 85. Refused plus partly is 59 against 84. They are different matches on different builds, so read this as a direction: more presses fell into locked exchanges this time, and the heavy and dodge presses are where the silence sits.

## Orb's words against the numbers

- "tried to slam my opponent into the ground with the right stick": 34 down starts, one in five silent, two refused, five late; the five-tick silent burst at 5061 to 5065 is the clearest.
- "the beams are a lot easier to shoot now": 5 toward starts (the beam stick) all honoured.
- "speed of the fighters still a little bit confusing, high speed launches are cool but a little too fast": 17 launches in the match; the ledger does not measure speed.
- "sound effects weren't audible until i paused": the audio contexts stayed suspended until 178.4 s (above).
