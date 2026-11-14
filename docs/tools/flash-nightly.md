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

## The windows on a runner: run 43585295274 (by hand, 14 November 2026, 10:26 to 11:58 UTC; for the EP, not for Orb)

The first run with the re-cut windows (`tools/flash/nightly-windows.json`: skip 950 and 170 ticks for the four clash clips with a 90-minute cap, 120 ticks from tick 1 for collapse with 75 minutes, 120 ticks from tick 1 and 45 minutes for signature), software rendering, 960x540, on `main` at 148f4e16.

| Clip window | Result | Time |
| :--- | :--- | :--- |
| clash-normal (170 from 951) | **read: primary 4.5, area-15% 4.5, two-second memory 4.5: over the take-down line of 3** | 5,173 s |
| clash-night-normal (same window) | **read: primary 3.5, memory 3.5: over the line of 3** | 5,411 s |
| clash-reduced, clash-night-reduced | not read: timed out after 96 and 131 captured ticks of 170 | cap 90 min |
| collapse-reduced (120 from tick 1) | read: PASS, primary 0.5, area-15% 1.5 | 2,412 s |
| collapse-normal | not read: timed out after 84 of 120 ticks | cap 75 min |
| signature-normal (120 from tick 1) | read: PASS, primary 2 | 1,251 s |
| signature-reduced | read: **over our gate of 2.5, primary 3**, within the line (a finding, not red) | 2,404 s |

What it shows:

- **The software window on a runner reads the same as the hardware full reading.** clash-normal: primary 4.5 and two-second memory 4 (hardware, full clip, scratch export of HEAD 97df40b8) against primary 4.5 and memory 4.5 (software, the window, main 148f4e16). The window picked the same finding, on a different renderer and a different build, which is what the windows were for. It is a take-down-line crossing on the clip itself, not a fault of the tool: the full local reading said it first.
- **The night sky reads lower than the day sky for the same clash** (3.5 against 4.5), and still crosses the line.
- **The reduced-mode clash windows did not finish.** clash-normal read in 86 minutes inside a 90-minute cap, and the two reduced clash windows had read only 96 and 131 ticks when the cap ended, so the runner's rate varies a lot from job to job (about 2 s a skipped tick and 8 s a captured tick are averages, not promises). Caps are now 150 minutes for the clash windows (the job limit is 300) and 110 for collapse, whose normal-mode window ran 84 ticks in 75 minutes where the reduced mode ran 120 in 40.
- The collapse windows have still not been measured for where the clip is at its worst: they read from tick 1.

**What this makes of the nightly:** the scheduled run will be red on the clash clips every night until the clip itself is fixed, because it truly reads over the line. That is the tripwire doing its job, not a lapse in the tool. The EP decides what goes to whom: this page and the numbers are for the EP only.

## The measured windows for signature and collapse (14 November 2026, hardware, 960x540, export of main f1f91f45; for the EP, not for Orb)

Full local readings of the four clips (the nightly's page words, one at a time, about 4 minutes each), then each clip's window read to see that it picks the same worst second:

| Clip | Full clip (1500 ticks) | Worst second (event ticks) | The window now in `nightly-windows.json` | Window result |
| :--- | :--- | :--- | :--- | :--- |
| signature-normal | primary 3.5 (over the line of 3), memory 2.5 | 76, 82, 110, 114, 125, 127, 129 | 180 ticks from tick 1 | primary 3, memory 2.5 (3 and 2.5 and 2.5 on three runs) |
| signature-reduced | primary 3.5 (over the line), memory 2.5 | 78, 81, 82, 86, 112, 115, 125 | 180 from tick 1 | same events, primary 3.5, memory 2.5: exact |
| collapse-normal | PASS, primary 2, memory 2 | 1111, 1132, 1145, 1151 | 180 from 991 | same events, primary 2, memory 2: exact |
| collapse-reduced | over our gate, primary 3, memory 2.5 | 1465, 1471, 1479, 1491, 1495, 1499: the end of the clip | 160 from 1341 | same events, primary 3, memory 2.5: exact |

- **Signature is on the line and the reading moves.** The same full clip read 3.5 and, on a repeat, 3; the signature-normal window read 3, 2.5 and 2.5. The events at the edge of the threshold (the 129th, a one-tick shift of the 82nd) come and go from run to run, which is half a flash to one flash. The reduced window matched its full reading exactly. A nightly signature window is a tripwire within one flash of the line, not the clip's number: the verdict treats over 2.5 as a finding and over 3 as red, so a signature reading of 2.5 to 3 should be read as "at the line".
- **Signature's worst moment is in the first two seconds**, which is why the earlier window of 120 ticks from tick 1 read 2 and 3. **Collapse-reduced's worst is the clip's last second**, which a window from tick 1 never reached; its window now ends at tick 1500 (the worst moment may run on past it, into time the clip does not play).
- **Memory needs lead-in.** The two-second memory reading ignores the first 120 frames of a clip, so a window needs about 120 ticks before the moment: a window of 130 ticks from 1371 read the right primary but a memory of 1 for collapse-reduced; 160 from 1341 reads 2.5, as the full clip does.
- **Costs on a runner** are not measured for these windows: collapse about 20 to 50 s a tick plus about 2 s a skipped tick, so collapse has a 210-minute cap (the job limit is 300); signature has 100 minutes.
