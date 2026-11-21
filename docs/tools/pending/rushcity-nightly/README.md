# rushcity-nightly (park, Tools, 2026-11-21; the EP's order, for the EP, not for Orb)

`rushcity-nightly.patch` (sha1 91f687a616f5a524564cc93078a30c3423cad408, six files): `rushcity-normal` and `rushcity-reduced` join flash-nightly.

**Order: it lands after `docs/tools/pending/nightly-baseline/`.** It edits `tools/flash/nightly-baseline.json`, which that park creates; `git apply --check` passes on d168a518 plus nightly-baseline.patch and fails on d168a518 alone. The self-test of the baseline park asks that the recorded values and the verdict's clip list agree, so the two cannot land the other way round.

| File | Change |
| :--- | :--- |
| `.github/workflows/flash-nightly.yml` | the matrix has the two clips (ten jobs); the header names the sprint |
| `tools/flash/nightly-ci.mjs` | `EXPECTED` has the two clips |
| `tools/flash/nightly-windows.json` | one window for both: 240 ticks from tick 641, `capMin` 150, with how it was found |
| `tools/flash/nightly-baseline.json` | main's current readings, FAIL as it is: normal 4.5 / 0 / 6 / 4.5 and reduced 5.5 / 0 / 7 / 5.5 (primary, red, area-15%, two-second memory), and a sentence saying they come from a local reading, not a scheduled night |
| `tools/flash/nightly-ci-selftest.mjs` | two checks (49 in all, 47 with the baseline park): the workflow's matrix equals the verdict's list, and every clip the night reads has its own window |
| `docs/tools/flash-nightly.md` | a section with the full reading, the window and what is not proven |

## The reading (main d168a518, hardware, 960x540, the nightly's page words; one capture at a time, below-normal)

| Clip | Primary | Red | Area-15% | Two-second memory | Worst second |
| :--- | :--- | :--- | :--- | :--- | :--- |
| rushcity-normal | 4.5 | 0 | 6 | 4.5 | ticks 761 to 815 |
| rushcity-reduced | 5.5 | 0 | 7 | 5.5 | ticks 785 to 841 |

- Valid: the machine's CPU was sampled every 20 s through both reads (full clips 28 to 56 percent, median 37; windows 30 to 40), the capture rate was 12 frames a second (the full clips) and 4.9 (the windows), and the guard's loads before and after were 21 to 48. None was saturated, so none is voided.
- The window read on the same export picks the same events and gives the same four numbers for both clips.
- These are higher than Rendering's B-20 numbers for ed1591cb (3.5 and 4.5). I did not compare the two captures' page words or sizes. The nightly's own words are the ones measured here.
- Checked: `nightly-windows.mjs --check` (10 windows), the self-tests of the nightly verdict (49) and of the windows (13), check-workflows and check-workflow-shell. Negative controls: a matrix without rushcity, a clip without a window and a baseline without a rushcity entry each fail the self-test.

## Not proven

- The window on a runner: 640 skipped ticks cost about 24 minutes at 2.2 s, then 240 captured ticks at a software rate nobody has measured for this clip (collapse took about 21 s a tick, clash 8 to 11). `capMin` 150 of a 300-minute job limit is a guess from those two; read the first night's wall time.
- The baseline is a hardware reading. The first scheduled nights read the window in software and may differ by a flash either way; if one reads worse, the nightly goes red on it, and the EP decides whether to re-record (never by me).
- Two readings of one run each: no repeat of the full clip was taken, and signature's showed that a clip near the line can move by a flash from run to run.
