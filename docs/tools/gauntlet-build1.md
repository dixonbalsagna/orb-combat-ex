# The scheme gauntlet on Sunday's build 1 (Tools, 2026-11-08)

Kept build orb-first-play-1931a0f8-7a5a2d2c (main 1931a0f8; refusedCue on, press answers, kept flick, chord pick, full send). 40 matches a cell from seed 1 (95% interval about plus or minus 14 points at 50%, 8 at 5%), below-normal, 3 jobs, the fixed arms: the Orb's-scheme pad now HOLDS LB from the rival's wind-up until contact; the timing pad guards every wind-up and taps X every 8 ticks; stick-only flicks 2.5 to 7.5 a second; the masher taps X every 8 ticks. Raw cells: `runs/1931a0f8/b1-gauntlet.json` and `.txt`.

| Pad | Easy | Medium | Hard | Refusals per 100 presses (easy / medium / hard) | Seconds without control a minute |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Orb's scheme | 5% (2 of 40) | 0% | 0% | 14.0 / 9.6 / 14.5 | 56.2 / 55.5 / 53.5 |
| timing | 70% | 25% | 0% | 13.0 / 9.6 / 21.3 | 54.4 / 54.8 / 47.3 |
| stick-only | 3% (1 of 40) | 0% | 0% | 16.2 / 14.0 / 16.8 | 56.3 / 56.4 / 54.4 |
| masher | 70% | 25% | 0% | 11.2 / 11.4 / 27.0 | 54.7 / 54.7 / 46.2 |

Against the last table (e80b8e3d, 10 matches a cell, `gauntlet-e80b8e3d.md`): masher 90 / 30 / 0 and timing 90 / 40 / 0 are now 70 / 25 / 0 and 70 / 25 / 0; stick-only 20 / 0 / 0 is 3 / 0 / 0; Orb's scheme 0 / 0 / 0 is 5 / 0 / 0. The older cells had 10 matches each (an interval of 19 to 26 points), so the drops of the masher and timing pads are inside the old interval; stick-only and Orb's scheme are low in both.

What the refusals are made of (the largest in each arm): the masher and the timing pad: `press_refused locked` (a press while locked in an exchange), `press_refused x`, `press_stunned x`, `queue_expired`; the stick-only pad: `stick/ki` (no energy: 3,686 on easy), `stick/late`, `stick/set_piece`, `stick/not_yours`; Orb's scheme: `press_refused locked`, `stick/late`, `stick/not_yours`, `stick/set_piece`, `queue_expired`. The stick's unreadable reasons of the morning build ("8", "0", "refused", "replaced") are gone.

Reading it: the Orb's-scheme pad, with the guard held from the wind-up until contact, wins 5% on easy (2 of 40) and nothing above it, while it lands 13,137 blows and takes 34,332 on easy: it takes about 2.6 blows for each it lands, against 0.27 for the masher and timing pads (about 117,000 landed to 31,000 taken) and 1.08 for stick-only (32,727 landed, 35,344 taken). The held guard did not close the gap that the thumb-paced flicks open. The 70% target the EP named (Game Design's, which assumes the held guard) is not met on this pad by a wide margin; the pad is a floor (it aims each flick at random and never dodges, charges or fires a beam) and not a model of Orb.
