# The two-hour soak of the built desktop program (parked; QA, path job 14, 2026-11-25)

**State:** the harness is built (`qa/soak/soak.mjs`, `qa/soak/soak_probe.gd`). **The two-hour runs on ac4ba152 (GW1c, 0.1.1) are done, Windows and Linux: all checks pass; memory grew** (`docs/qa/readings/soak-two-hours.md`). The Linux half is the workflow `.github/workflows/linux-soak.yml` (Tools'; Legal RL-279).

## Running it

```
node tools/desktop-local-build.mjs --platform windows --commit <GW1c commit> --out <scratch folder>
node qa/soak/soak.mjs --package <scratch folder>/orb-combat-ex-ORB-PRIVATE-windows-x86_64-<commit8>.zip --seconds 7200 --sample 10 --cap 600 --out <results folder>
```

The package is Orb's private build: it stays in scratch, is never committed and never leaves this PC.

## How it works

- The package is unpacked into a scratch folder and **the program runs exactly as shipped**. The only addition is an `override.cfg` beside it that names `soak_probe.gd` as an autoload. Nothing is rebuilt or edited.
- The program runs headless (no window), capped at 60 frames a second, below-normal priority, with its data folders moved into the scratch folder (never Orb's).
- The probe lets the computer play both fighters, starts the next seed a few seconds after a KO or no contest (or at `--cap` sim seconds), prints a sample every `--sample` seconds, and after `--seconds` asks the game to quit, as "Close the game" does.
- The harness reads memory from outside (a release program reports none of its own), the exit code, the run marker, everything the program printed, and the report folder. A run 5 minutes past its time is stopped by its process id and called a hang. A failed run keeps its scratch folder, engine logs included.

## What passes and what is only reported

| Check (exit 1 if any fails) |
| :--- |
| The computer played both sides, and samples came in |
| It ran the whole time and quit when asked (no crash, stall or hang) |
| Exit code 0, no signal |
| The run marker is gone after the close |
| No `SCRIPT ERROR` line |
| Median at least 58 game ticks a second after the start |
| Enough match starts to read growth between matches: `seconds / (cap * 1.5 + 60)` of them (7 in a two-hour run at the 600 s cap, which is the default; not asked of a run too short for two) |

Reported, with no pass line (QA does not invent a budget): memory after warm-up, at the end, at most, its slope an hour, and **memory and object count at each match start** (growth across matches is the leak signal; growth within one match is the world filling with craters and damage); worst frame; object, node, resource and orphan counts; `ERROR` and `WARNING` lines. Performance owns the memory budget.

## Trial on 20a483d8 (Windows, this PC; records in `trial-20a483d8/`)

| Run | Result |
| :--- | :--- |
| 10 minutes, `--cap 900` | **All six checks pass.** 60.0 ticks a second (5th percentile 59.8). Working set 410 MiB after warm-up, 466 MiB at the end, all inside one match: it had not ended after 507 sim seconds. Counts flat (objects about 13,700, nodes 1,273, resources 393, no orphans). |
| 6 minutes, `--cap 40` (7 matches) | All six checks pass. At each match start from the 2nd to the 6th: working set 428.6, 434.9, 440.7, 442.9, 444.2 MiB; objects 17,738 to 17,855 (to 17,887 at the 7th): about 30 more a match. |

**Read nothing into the slopes yet:** ten minutes is too short to say whether memory levels off. The two-hour run is the reading.

**Seen on the way, for the owners:**
- The first match takes about 11 s to come up in this headless, 60 fps run (the match is built a piece a frame), and each later match start costs a long frame (up to 1.4 s). Headless figures: not what a player's screen shows.
- Closing mid-match prints, at exit only, `8,218 ObjectDB instances were leaked`, `13 resources still in use` and 6 dummy textures; closing just after a match started prints 283 and 9. Harmless to a player at exit; Simulation may want to know that `SimCore.dispose` at the close leaves them.
- **A release program checks no array bounds.** My first probe read the match while it was still being built (no fighters yet) and the program died with `0xC0000005` after a few seconds: no `SCRIPT ERROR`, an empty engine log. The fault was the probe's (the game does not make that read), and the probe now waits. It matters beyond the soak: in players' builds an out-of-range read in GDScript can be a silent crash, so scanning logs for `SCRIPT ERROR` is not enough; the exit code and the run marker are what catch it.

## Limits

- Headless: no graphics card memory, no drivers, no real frame rate on a screen, and no sound device. A soak with a window, played by a person or on a spare PC, is a different test.
- `--frames=2000000000` is passed to the program (main's own switch for scripted runs). **It only skips the How to play card**, which would otherwise hold the match for a key press. It does not skip the flashing notice: a locked build refuses the words that would (`UiHud.bypass_allowed`, RL-206), and a headless run never raises the notice at all (`UiHud.notice_auto_allowed`).
- Legal allows the soak, on this PC and in CI, under RL-279's conditions: `--headless` always (a run with any display is not covered), no new switch or code that skips the notice, the probe and its `override.cfg` stay in the scratch copy, only text and numbers kept or uploaded, and the result is a stability and memory reading only (it counts toward no flash gate).
- The probe's computer is the game's default level; no person's play, menus or pause are exercised.
- **Linux was not tried by this trial.** The harness has the Linux branches (`tar`, `/proc/<pid>/status`); no Linux machine here can run them, so the CI workflow is their first run.

## The Linux half (`.github/workflows/linux-soak.yml`)

Tools' dispatch-only workflow (it started from QA's draft): it builds a commit on main the way `linux-first-run.yml` does and soaks it headless with `qa/soak/soak.mjs`: no display, nothing captured, only text and numbers uploaded, no program kept (RL-262, RL-279). The repository is public, so the runner minutes (about 125 for a two-hour run) cost nothing.
