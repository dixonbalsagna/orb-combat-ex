# The two-hour soak of the built desktop program (parked; QA, path job 14, 2026-11-25)

**State:** the harness is built (`qa/soak/soak.mjs`, `qa/soak/soak_probe.gd`) and proved on today's main (20a483d8) on Windows. **The real two-hour run waits for the GW1c commit**, in a quiet window, at below-normal priority. The Linux half is a draft workflow (`linux-soak.yml` here), not live and never run.

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
- `--frames=2000000000` is passed to the program (main's own switch for scripted runs): without it the first-run card holds the match for a key press. It also skips the flashing notice. There is no display here, and the package locks Reduce flashing on.
- The probe's computer is the game's default level; no person's play, menus or pause are exercised.
- **Linux is untested.** The harness has the Linux branches (`tar`, `/proc/<pid>/status`), but no Linux machine here has run them.

## The Linux half (`linux-soak.yml`)

A dispatch-only workflow that builds a commit on main the way `linux-first-run.yml` does and soaks it headless for two hours: no display, nothing captured, only text and numbers uploaded, no program kept (RL-262). The repository is public, so the runner minutes (about 125 a run) cost nothing. It passes `tools/check-workflows.mjs`. Before it goes live: Legal's word on the `--frames` switch (RL-270 covered a virtual display and a pressed key, not this), then Tools moves it into `.github/workflows/`.
