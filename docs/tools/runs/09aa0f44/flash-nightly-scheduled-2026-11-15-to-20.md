# The scheduled flash nightly, six nights (15 to 20 November 2026): all red, as expected (Tools; for the EP, not for Orb)

`.github/workflows/flash-nightly.yml` reads eight clips on GitHub's runners with software rendering at 960x540 (clash, collapse, signature and clash-night, each in the normal and the reduced mode). The scheduled run is the one with no dispatch. Six scheduled runs have happened, one a night, and **every one ended "failure"**. The cause is the same each night: the clips whose reading is over the line of 3 turn their job red by design (`tools/flash/nightly-ci.mjs`: red when a clip crosses the line of 3 on any reading, or could not be read). Nothing broke; the nightly says what the local readings already said. Read from each run's log (`gh run view <id> --log`) on 2026-11-21.

## The runs

| Night (UTC start) | Run | Commit read | Wall time | Jobs red of 8 |
| :--- | :--- | :--- | ---: | :--- |
| 15 Nov 12:00 | 43711627577 | 09aa0f44 | 138 min | 5: the four clash clips and signature-reduced |
| 16 Nov 12:53 | 43870618754 | 09aa0f44 | 152 min | 5: the same five (one of them **not read**: see below) |
| 17 Nov 13:35 | 44094333781 | 09aa0f44 | 118 min | 5: the same five |
| 18 Nov 13:10 | 44311081706 | 09aa0f44 | 138 min | 5: the same five |
| 19 Nov 13:26 | 44533410579 | 09aa0f44 | 148 min | **6**: the same five and collapse-normal |
| 20 Nov 13:06 | 44741476400 | 09aa0f44 | 98 min | 5: the same five |

All six read **the same commit, 09aa0f44** (Camera's GW1b parks, committed 14 November): nothing was pushed to GitHub's main between 14 and 20 November, so the nights are six readings of one build and the spread between nights is the runner's, not the game's. The schedule says 04:23 UTC; GitHub started the runs 7.5 to 9 hours late each night (queue delay). The wall time is the whole run, the eight jobs side by side.

## What each night read (primary reading, the worst of two readings, 960x540)

| Clip | Reading | Job |
| :--- | :--- | :--- |
| clash, reduced | **6.5** every night (area 6.5; 2 s memory 6.5, except 5.5 on 16 Nov) | red |
| clash-night, reduced | **5.5** on 15, 16, 17, 18 and 20 Nov; 4.5 on 19 Nov | red |
| clash, normal | **4.5** every night | red |
| signature, reduced | **4** every night (area-15% 5 on 18 Nov; 2 s memory 0.5 to 1, and 2.5 on 19 Nov) | red |
| clash-night, normal | **3.5** every night it was read (area-15% 4.5 on 15 and 18 Nov) | red |
| collapse, normal | PASS 2 on 15, 16, 17, 18 and 20 Nov; **FAIL on 19 Nov: primary 3, 2 s memory 4** (a run at scale 2) | green five nights, red once |
| collapse, reduced | "OVER GATE" 3 every night (over our gate of 2.5, not over the line of 3) | green |
| signature, normal | "OVER GATE" 3 on the nights its line is in the log (15, 16, 17 and 20 Nov) | green |

The worst reading of the six nights is the clash clip in the reduced mode at **6.5 on all six**. The run's numbers equal the earlier local and hand-dispatched readings (the clash clip at 4.5 normal; signature reduced and collapse reduced over the gate): the nightly adds no new fault.

**Two things in the log that are not the clips' fault.**
- **16 Nov, clash-night normal: not read.** Its capture timed out after 154 of 170 ticks (`[capture-web] FAILED: timed out after 154 ticks`); the nightly counts a clip it could not read as red ("never a pass"), so that night's red for that clip is a missing reading, not a number. The other five nights read 3.5.
- **19 Nov, collapse normal: the one night it failed.** Primary 3 and 2 s memory 4 against 2 on the five other nights, on a run at scale 2. The clip is not changing (the same commit); the reading moved with the runner. Software rendering and the memory reading together move 0.5 to 1 from night to night on a clip near a line: that is the nightly's noise, and one night in six is what to expect of the collapse clip while it sits at 2 to 3.

## What this does not say

- Not a reading of the game Orb plays: it is main's Web export (Godot's standard 4.7.2 Web templates: the scheduled nightly installs them and never used the custom template, whatever `tools/site.json` says), software rendering, at 960x540.
- Not new numbers for the pin: no pin moves on these.
- The flash numbers go to the EP only (Orb's word, 2026-11-01).
- GitHub emails the repository owner about a failed scheduled run: six emails, one a night, for the same expected reason. **Decided 2026-11-21 (the EP):** the nightly is now judged against recorded values and turns red only on a clip that reads worse than the record, a new clip or a missing reading; **the six-night values above, taken as the worst of the six per reading (collapse-normal at its five-night value, 2 / 2 / 2: the EP's ruling), are that baseline** (`tools/flash/nightly-baseline.json`; `docs/tools/flash-nightly.md` says how it works). The outside-tester gate and the release pass still read the absolute line.
