# The nightly flash reading on a runner: first speed trial (Tools, 2026-11-14; for the EP, not for Orb)

`.github/workflows/flash-nightly.yml` reads ten clips on GitHub's runners with software rendering: clash, collapse, signature, clash-night and rushcity (since 2026-11-21), each in the normal and the reduced mode. `tools/flash/nightly-ci.mjs` turns each clip's reading into the night's verdict (line 3 on the primary reading, the 15% area, the two-second memory; exit 2 when a clip was not read, never a pass). Self-tests: `nightly-ci-selftest.mjs` (27 checks), `player-watch-selftest.mjs` (30), both in CI.

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

The scheduled run (a night with no dispatch) has happened six times, 15 to 20 November 2026, every night red as expected (the clash clips and signature-reduced read over the line of 3; one night a clip timed out and one night collapse-normal read 3): the record is `docs/tools/runs/09aa0f44/flash-nightly-scheduled-2026-11-15-to-20.md` (for the EP, not for Orb). All six read the one commit 09aa0f44, so they add no new reading, and the nightly turns red every night for the same known reason until it is told which readings are expected. `tools/ci-budgets-check.mjs --runs 3` waits for three runs of the other jobs on 047d4037 or later. The full local readings of signature, collapse and the other clash modes are long runs (under the long-run rules, one at a time, below-normal) and are the way their windows get measured.

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

## The recorded values: the nightly says only what changed (the EP, 2026-11-21; for the EP, not for Orb)

Six scheduled nights (15 to 20 November, `docs/tools/runs/09aa0f44/flash-nightly-scheduled-2026-11-15-to-20.md`) were red for the same known reason: the clash clips and signature-reduced read over the line of 3 and the nightly asked "is it over the line". It now asks "is it worse than it was recorded", against `tools/flash/nightly-baseline.json`:

- **Red** when a clip reads **worse** than its recorded value on any of the four readings (primary, red, area-15%, two-second memory) (exit 4); when a clip has **no recorded value** (a new clip, exit 5); when a clip, or one of its readings, was **not read** (exit 2, as before).
- **Green** only when every clip **equals or beats** its recorded value. A clip that is over the line AS RECORDED is noted on the run ("over the line of 3, as recorded") and is not red; a clip that reads better is noted too.
- **The recorded values are the worst of the six nights per reading** (the five nights for clash-night normal: 16 November was not read), recorded as they are, over the line included. **The exception is collapse-normal, recorded at its five-night value, 2 on the primary, area and memory readings, with no allowance (the EP, 2026-11-21):** the one noisy night, 19 November (3 / 3 / 4), is left out on purpose, a noisy night going red is the tripwire doing its job, and a slip from 2 to 3 must show.
- **What it does not touch:** the outside-tester gate (G21), the release pass and the take-down line of 3 read the absolute line, unchanged; `nightly-ci.mjs` without `--baseline` is the old verdict, and its self-test still holds it. Nothing that guards a player is loosened.
- **Updating a value** is by hand, with the EP's word, when a clip reads better and stays better; never to follow a clip that reads worse.
- Proof: the self-test (47 checks, 27 before) covers each reading one step worse, a new clip, a missing reading, equal and better, the real file; and the six real nights replayed through it: 46 of the 48 clip-nights are green; the two that are not are 16 November's clash-night normal (not read) and 19 November's collapse-normal (3 / 3 / 4 against its recorded 2 / 2 / 2: red, as ruled).

## rushcity joins the nightly (the EP, 2026-11-21; for the EP, not for Orb)

Rendering's B-20 capture of main ed1591cb failed `rushcity` (3.5 normal, 4.5 reduced) and the nightly did not read it: the matrix was the four families clash, collapse, signature and clash-night. `rushcity-normal` and `rushcity-reduced` are now in the matrix, in the verdict's `EXPECTED` list, in `nightly-windows.json` and in `nightly-baseline.json`; two self-test checks keep the matrix and the verdict's list equal and give each clip a window.

**The full local reading of main d168a518** (hardware rendering, 960x540, the nightly's page words, one capture at a time at below-normal priority; the machine's CPU was sampled every 20 s: 28 to 56 percent, median 37, never saturated; the capture rate was 12 frames a second and the guard's loads before and after were 47/41 and 21/26, so both readings stand):

| Clip | Primary | Red | Area-15% | Two-second memory | Worst second (event ticks) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| rushcity-normal | 4.5 | 0 | 6 | 4.5 | 761 to 815 (761, 785, 787, 789, 796, 799, 807, 810, 815) |
| rushcity-reduced | 5.5 | 0 | 7 | 5.5 | 785 to 841 (785, 787, 789, 796, 799, 807, 809, 815, 825, 839, 841) |

These are higher than Rendering's B-20 numbers (3.5 and 4.5). I have not compared the two captures' page words and sizes, so neither disproves the other; the nightly's own words are the ones above.

**The window** is 240 ticks from tick 641 (120 ticks of lead-in for the memory, then the whole worst second and the ticks after it), the same for both clips. Read on the same export (the machine at 30 to 40 percent), it picks the same events (121 to 175 of the window, which are the clip's 761 to 815) and the same four numbers: 4.5 / 0 / 6 / 4.5 and 5.5 / 0 / 7 / 5.5.

**The baseline records main's FAIL as it is** (4.5 / 0 / 6 / 4.5 and 5.5 / 0 / 7 / 5.5). The nightly judges "worse than recorded", so it is green on these clips while they read the same or better and red when one reads worse, is new or is not read. A fix that lowers a reading is noted as better; lowering the recorded value is by hand, with the EP's word. The values come from the hardware full reading, not from a scheduled night: the first scheduled nights read the window in software and may differ by a flash either way (signature's did), and then the EP decides whether to re-record.

**Not proven:** the cost of the window on a runner (640 skipped ticks at about 2.2 s is about 24 minutes, then 240 captured ticks at an unmeasured software rate; capMin 150 against a job limit of 300), and the first scheduled reading of these two clips.

## The windows go stale, and the check that says so (2026-11-26)

A window reads whatever is at its ticks. When the game changes, the moment it was chosen for moves, and a low reading then means nothing: from about 21 November the four clash windows held no clash and the two collapse windows no falling building, and the nightly stayed green.

- **Each window now names what it `holds`** (`beam_outcome:CLASH`, `beam_outcome`, `building_fall`, `shot_hit`), and `tools/flash/flash_worst.gd` records the tick of each.
- **`tools/flash/window-check.mjs`** (CI, the flash count job) fails when a window's counted part (after a clip's first 60 frames) no longer holds its event, and says at which ticks it does happen.
- It says the event is there, not that the window is the clip's worst second. That is still a local full reading.
- **The clash scene changed:** nothing for 90 ticks, then the signature held in cycles of 500, so beams meet twice (ticks 140 and 1140) and the first is past the uncounted start. The second meets in split screen, where no flare shows.
- Re-measure the windows after any change that moves the matches, and re-record the baseline from nightly runs after that (by hand, with the EP's word).
