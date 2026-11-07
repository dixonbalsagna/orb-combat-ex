# The scheme gauntlet on the morning page e80b8e3d (Tools, 2026-11-07)

Five scripted pads against the three computer levels, 10 matches a cell from seed 1, below-normal, 3 jobs, on the tree of `homework/Files/builds/orb-first-play-a8bc66e2-e80b8e3d` (main a8bc66e2; refusedCue and the four city rows are OFF in this build, proven from its index.pck). Raw cells: `gauntlet-e80b8e3d.json`. Method: `docs/tools/feel.md`.

## What changed in the arms since the first run (docs/tools/morning-1107-gauntlet.txt, now superseded)

- `press_refused` with reason `stun_limit` is a landed hit on an already stunned rival (about 700 a match), so it no longer counts as a refusal.
- The timing pad guards (LB for 10 ticks, then X) on the rival's `windup` start cue, so lights are guarded too, and taps X every 8 ticks (it was 20).
- `set_struggle` is given the push word (`DirBeam.pushModeOf == "stick"`), as the host gives it.
- The first run was on dee2fb35's tree, which had refusedCue and the city rows ON by a build fault (fixed 2026-11-07); this one is on the page as it is now.

## Result (the page's own rules)

| Pad | Easy | Medium | Hard |
| :--- | :--- | :--- | :--- |
| stick-only | 20% (refusals 52.3 per 100 presses) | 0% (23.1) | 0% (43.4) |
| masher | 90% (4.1) | 30% (4.5) | 0% (19.5) |
| timing | 90% (3.3) | 40% (3.9) | 0% (14.6) |
| beam-first | 90% (6.9; 53 beams a match) | 20% (12.8; 41) | 0% (21.5; 30) |
| circle-first | 100% (4.7) | 80% (8.6) | 0% (23.1) |

Each rate is of 10 matches, 95% interval about plus or minus 14 to 26 points. Seconds without control a minute: 47 to 58 for every pad and level (the stick-only pad 56 to 58); read it as time locked in exchanges, not as a feel gauge.

## Against the first run

- Refusals per 100 presses fell for every pad that had them (stick-only 76/66/55 to 52/23/43; timing 17/20/25 to 3/4/15; beam-first 10/16/24 to 7/13/22; circle-first 8/11/25 to 5/9/23): the stun_limit rows were most of them, and the build no longer knocks on landed hits.
- The timing pad, which won nothing before, wins 90% on easy and 40% on medium now that it guards the lights and taps every 8 ticks.
- Masher medium fell from 50% to 30%, beam-first easy rose from 70% to 90%. With 10 matches a cell these are inside the interval; do not read them as rules changes.
- Hard is 0% for every pad.
- The stick-only pad is still the one that loses: 20% on easy, 0% above it, and it still has the highest refusal rate (52 per 100 on easy).
