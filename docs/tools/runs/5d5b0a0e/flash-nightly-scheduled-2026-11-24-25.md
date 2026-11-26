# Flash nightly on 5d5b0a0e, 2026-11-24 and 25 (Tools, read 2026-11-25)

Runs 45420345678 and 45636366938, both scheduled, both green against `tools/flash/nightly-baseline.json`. These are the first two nights on a commit that has capture-steady (0d21624b). The two nights read the same on every figure. Software rendering, a window of each clip (`tools/flash/nightly-windows.json`), not the full clip. This is not a clearance.

## Readings (primary / red / area-15% / two-second memory)

| clip | recorded value (11-21) | 11-22 (b04de5d5) | 11-24 and 11-25 (5d5b0a0e) |
|---|---|---|---|
| collapse-normal | 2 / 0 / 2 / 2 | 1 / 0 / 1 / 0.5 | 1.5 / 0 / 1.5 / 0.5 |
| collapse-reduced | 3 / 0 / 3 / 2.5 | 0.5 / 0 / 0.5 / 0 | 2.5 / 0 / 2 / 0.5 |
| signature-normal | 3 / 0 / 2.5 / 2.5 | 1.5 / 0 / 1.5 / 0.5 | 2.5 / 0 / 2.5 / 0.5 |
| signature-reduced | 4 / 0 / 5 / 2.5 | 1.5 / 0 / 2.5 / 0.5 | 1 / 0 / 1 / 0.5 |
| rushcity-normal | 4.5 / 0 / 6 / 4.5 | 3.5 / 0 / 3.5 / 5.5 (red night) | 3 / 0 / 3 / 2.5 |
| rushcity-reduced | 5.5 / 0 / 7 / 5.5 | 4.5 / 0 / 4.5 / 5.5 | 3 / 0 / 3 / 2 |
| clash-normal | 4.5 / 0 / 4.5 / 4.5 | 0 / 0 / 0.5 / 0 | 0 / 0 / 0.5 / 0 (no clash in the window, below) |
| clash-reduced | 6.5 / 0 / 6.5 / 6.5 | 0 / 0 / 0 / 0 | 0 / 0 / 0.5 / 0 (same) |
| clash-night-normal | 3.5 / 0 / 4.5 / 3.5 | 0 / 0 / 0.5 / 0 | 0 / 0 / 0 / 0 (same) |
| clash-night-reduced | 5.5 / 0 / 5.5 / 5.5 | 0 / 0 / 0.5 / 0 | 0 / 0 / 0 / 0 (same) |

## The four clash clips are not reading a clash

Their window is ticks 951 to 1120, measured on 2026-11-14. Headless count of the same scene (`tools/flash/flash_worst.gd --only=clash`, clean copies):

| commit | beam outcomes in 1500 ticks | beam-clash flashes at tick |
|---|---|---|
| 09aa0f44 (the commit the recorded values were read on) | 2 | 48 and 978 |
| 54474b97 (today's HEAD, same game as 5d5b0a0e) | 1 | 48 |

The second clash, the one inside the window, no longer happens. So the four clash clips' low readings say nothing about a clash, and their green since the nightly moved off 09aa0f44 proves nothing about it. The one clash left starts at tick 48, inside the analyser's first 60 frames, which count no change; so a full reading of the clip is likely to miss its start too (not measured). `check-log.js` still passes, because the scene does produce one beam outcome.

Not checked: the pixel frames themselves; whether the other three scenes' windows still sit on their worst moment (the headless count shows each still has flashes inside its window).

## Baseline

Not changed. The clash values must not be tightened to these readings.
