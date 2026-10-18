# The route and the newcomer measured again, with the launch counts the right way round: f15d7de3 (QA, 2026-10-18)

The re-run the EP ordered after the correction of 2026-10-17 (`README.md`, Corrections): `SimFx.launch(S, f, by)` sends the body that was *sent* as its actor and the launcher as its target, and `players.gd` had read them the other way. Every first-launch time, "launches by him" and "on him" printed before 2026-10-17 was the other player's. These are the first readings with the fix.

| | |
| :--- | :--- |
| Build | **f15d7de3**, a clean `git archive` with **no overlay** (the harness is in the commit, 4c9a1c65) |
| Run | 06:17 to 07:41 on 2026-10-18, five Godot jobs of 100 matches (seeds 1 to 100), `--jobs=3`, headless, below-normal priority, wall cap 1,800 s a match. **No job invalid** (no wall cap, no budget stop). The machine was quiet at the start (about 15% CPU); Tools' captures ran beside it, which cannot change a sim result |
| Scripts | **The route:** X every 8 ticks on the absolute S.tick clock, and one B at every opening of his (the launcher's, pinged or not). **The newcomer:** X every 10 ticks, and one B a seeded 0 to 20 ticks after his run reaches the close (the gauge full), whether or not the rival is open; he does not read the opening |

## The corrected first launches and launch counts

First launch is measured from the first brawl, in seconds of fight, over the matches in which he launched at all.

| Player, against | Launched at all | First launch: p10 / median / p90 | Inside 30 / 60 / 120 s | Launches by him a match | On him a match | Wins |
| :--- | ---: | :--- | :--- | ---: | ---: | ---: |
| **Newcomer, medium** | **77 of 100** | 67.7 / **244.4** / 287.7 s | **2 / 6 / 15** of 100 | **1.58** | **10.14** | **4%** |
| Newcomer, easy | 96 of 100 | 150.2 / **227.8** / 255.1 s | 4 / 5 / 9 | 3.65 | 8.19 | 71% |
| Route, easy | 100 | 1.4 / 1.9 / 7.0 s | 100 / 100 / 100 | 9.35 | 5.44 | 100% |
| **Route, medium** | 100 | 1.8 / **3.9** / 11.6 s | 99 / 100 / 100 | **11.23** | **9.41** | **68%** |
| Route, hard | 100 | 6.2 / **30.4** / 83.8 s | 50 / 84 / 95 | 5.18 | 19.73 | 0% |

### The rows

| Row | Read | Band | |
| :--- | :--- | :--- | :--- |
| **A newcomer launches within 60 s of the first brawl, medium AI** | **6.0% of 100 matches** (77 had a launch at all; inside 30 s 2.0%; the median first launch is at 244 s) | at least 90% | **out, far**. Orb's "once or twice" is this |
| ... easy AI | 5.0% inside 60 s; inside 30 s 4.0% | reported | |
| Route, a first launch inside 30 s / 60 s (medium) | **99.0% / 100.0%** | at least 65% / 90% | in / in |
| Route share of brawls (launches by him over brawls): easy / medium / hard | **80.6% / 74.8% / 30.9%** (935 of 1,160; 1,123 of 1,502; 518 of 1,674) | 70-90 / 50-75 / 30-55 | in / in (on the top edge) / in (on the floor) |
| Route: every launcher used lands and launches, none lapsed | 502, 666 and 329 used, 0 lapsed; 935, 1,123 and 518 launches by him | none lapsed | in |
| **Route: launches a match by him / on him (medium)** | **11.23 / 9.41** | 4 to 10 / 4 to 8 | **out / out** (both over their tops) |
| Route wins against medium (100 matches; the band is read on 200) | 68% | at most 80% | in (the 200-match reading is not made) |

## What it says

- **The newcomer almost never launches the medium AI, and when he does it is late.** One in four never launches at all in a 7-minute match. The median first launch comes at about four minutes, and he is launched ten times for each launch of his own (10.14 against 1.58). His win rate is 4%. This is the "before" for the eleventh round's wider window, the gauge, and the removal of the rest. It is far from the 90% of the target, and the earlier 88% was the AI's first launch of him.
- **The likely reason is the script's timing, which I did not isolate.** The close staggers the rival for 12 ticks, and a B only launches inside them on this build. A newcomer who presses B a seeded 0 to 20 ticks after his gauge fills presses before the close or after the 12 ticks have run out most of the time. That is what the eleventh round's window (from 10 ticks before the close to 24 after it) is for; this script has no reaction to the opening, by design. How many of his Bs fall outside the stagger is a count I have not made.
- **Against the easy AI he wins 71% but launches only 3.65 times a match, with a first launch at 228 s.** He wins by his blows, not by launching.
- **The route is a different player.** It reads the opening, launches within 4 s at the median (medium), 1.9 s at easy, and 30 s at hard. Its count of launches by him (11.23 a match at medium) is over the 4 to 10 band, and the AI launches it 9.41 times: the match is a launching contest, which Game Design's launch-anywhere work (no rest) will move.
- **Against 3198301f (corrected from the saved jobs):** the route's launches by him went from 8.58 to 11.23 a match at medium and its share of brawls from 66.3% to 74.8%; wins from 61% to 68%. The medium route is now on the top edge of its 50 to 75% band. f15d7de3 differs from 3198301f in many commits (the window, the camera, the dummy), so this is not an isolated effect and was not split.
- **Not read:** the full-launch rows (L16, power 0.8 or more at the send) stay PENDING until Encounter's `launch_power` cue exists (the EP's note: `amount` the power at the send, `k` 1 at 0.8 or more). The harness counts the sent body's `launchPower` today and will count the cue when it lands.

The saved jobs are `mf15.json` in my scratch.
