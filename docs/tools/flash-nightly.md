# The nightly flash reading on a runner: first speed trial (Tools, 2026-11-14; for the EP, not for Orb)

`.github/workflows/flash-nightly.yml` reads eight clips on GitHub's runners with software rendering: clash, collapse, signature and clash-night, each in the normal and the reduced mode. `tools/flash/nightly-ci.mjs` turns each clip's reading into the night's verdict (line 3 on the primary reading, the 15% area, the two-second memory; exit 2 when a clip was not read, never a pass). Self-tests: `nightly-ci-selftest.mjs` (27 checks), `player-watch-selftest.mjs` (30), both in CI.

## The speed trial (run 43575965534, 14 November 2026, 08:28 to 08:59 UTC)

The trial reads only the first 120 ticks of each clip (`TICKS=120`), with a 30-minute cap a clip, because the first trial of 300 ticks ran for over an hour and was cancelled.

| Clip | Result | Time | Per tick |
| :--- | :--- | :--- | :--- |
| clash-night, reduced | read, PASS | 14.8 min | |
| clash, normal | PASS (primary 1, area 1) | 976 s | 8.1 s |
| clash, reduced | read, PASS | 19.9 min | |
| signature, normal | PASS (primary 2, area 2) | 1278 s | 10.6 s |
| signature, reduced | read, PASS | 22.6 min | |
| clash-night, normal | read, PASS | 25.6 min | |
| collapse, normal and reduced | **not read**: "timed out after 86 ticks" at the 30-minute cap | 30 min | about 21 s |

Six clips read; the two collapse clips did not. The job's exit is 2 by design (a clip not read is never a pass), so the run is red.

## What it says

- On a runner with software rendering a tick costs 8 to 11 s in the clash and signature clips and about 21 s in collapse (its debris and terrain). A clip is 1,500 ticks, so a whole clip would take about 3.4 hours (clash at 8.1 s), 4.4 hours (signature at 10.6 s) and 8.8 hours (collapse at 21 s): **a full clip is not something to read on a runner.**
- What a runner can read is a window: about 120 ticks in 16 to 21 minutes (clash, signature), and about 80 in 30 minutes for collapse.
- Reading wiring is proven on six clips: the capture, the reading, the verdict and the summary line all ran on a runner.

## The decision (the EP, 14 November 2026) and what was built

Each clip is read on the runner as a WINDOW at its worst moment (collapse at 60 ticks) as the nightly tripwire; the full reading stays a local run on Orb's PC under the long-run rules. Until every clip has a measured window the scheduled nightly may run red on collapse: expected and recorded, not a lapse.

- The start-tick option already existed: `tools/flash/run-pixels.mjs --skip N` (ticks run without a picture first; the clip is `--ticks` long from tick N + 1; the page hook's `skip`, render/tools/flash_capture.gd). Nothing new was needed there.
- `tools/flash/nightly-windows.json` holds each clip's window (skip, ticks, and how the moment was found); `tools/flash/nightly-windows.mjs <clip>` prints the options the workflow passes (`--skip S --ticks T`); `nightly-windows-selftest.mjs` (10 checks, in CI's data job) and `nightly-windows.mjs --check` keep the file whole (no window past a clip's 1,500 ticks, every entry says how it was found).
- `flash-nightly.yml`: a scheduled run reads the windows (45-minute cap a clip). By hand: no input reads the windows, `-f ticks=60` reads that many ticks from the window's start, `-f ticks=full` reads the whole clip.

## The proof: one window picks the same worst second as the full local reading (clash-normal)

On a Web export of HEAD 97df40b8 (scratch copy), 960x540, hardware rendering through the guarded launcher, the page words of the nightly (planet 7, loud meteor, tiles=1):

| Reading | Primary | Worst second (ticks) | Two-second memory | Time |
| :--- | :--- | :--- | :--- | :--- |
| the full clip, 1,500 ticks | 4.5 | 1075, 1081, 1086, 1101, 1107, 1109, 1110, 1111, 1113 | 4 | 340 s |
| a window of 150 ticks from tick 1001 | 4.5 | the same nine ticks | 0.5 (only 75 ticks of lead-in) | 119 s |
| a window of 170 ticks from tick 951 (the one in the data file) | 4.5 | the same ticks, one of them a tick off (1082 for 1081) | 4.5 | 114 s |

The window picks the same worst second and the same primary reading as the full reading. The two-second memory needs about 120 ticks of lead-in before the worst second, which is why the window starts at 951 and not at 1001. (This is a flash finding about the clip itself, not about the window: the full reading of the clash on this build counts 4.5 on the primary reading, over the line of 3. It goes to the EP only.)

**Not proven:** the same window on a runner with software rendering (the numbers above are hardware, to compare like with like; a software window of 170 ticks is expected at about 23 minutes plus the skipped ticks, within the 45-minute cap, not yet seen); that the reduced mode and the night sky peak at the same second (those three clips carry the clash-normal window and say so in the data); a measured window for signature (it reads 120 ticks from tick 1 until a full local reading names its worst second) and for collapse (60 ticks from tick 1, not measured).

## Not done

The scheduled run (a night with no dispatch) has not happened yet; its first reading is the next to record. `tools/ci-budgets-check.mjs --runs 3` waits for three runs of the other jobs on 047d4037 or later. The full local readings of signature, collapse and the other clash modes are long runs (under the long-run rules, one at a time, below-normal) and are the way their windows get measured.
