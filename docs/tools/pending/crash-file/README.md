# Park: the forced-crash check (Tools, 2026-11-23; path to Alpha 1, job 14, X-28), piece 1 of Tools' job 14

The edits are already in the working tree (uncommitted, my paths).

## Uncommitted paths
New: `tools/crash/crash-check.mjs`, `tools/crash/crash-check-selftest.mjs`, `docs/tools/runs/ec80e318/crash-check-windows.md`. Changed: `.github/workflows/ci.yml` (one self-test step), `.github/workflows/desktop-builds.yml` (one step in the `desktop` job, after the hash check: runs the check on the runner, summary only, no upload).

## What it does
`node tools/crash/crash-check.mjs` makes a scratch export of a commit with a probe (scratch only, an autoload that crashes the engine with `OS.crash` or spins forever when the command line says so), starts the PROGRAM headless with its data folders moved off the real ones, and reads what it left. Six rows: (1) it died, (2) a log file is in the game's data folder, (3) the log says why, (4) the next start keeps the dead run's log, (5) a hang is stopped by the harness and its log shows the run started, (6) the report folder picks the log up.

## Result on Windows (the release export of ec80e318, run here): rows 1 to 5 pass; row 6 WAITING
- The game already writes a log on a desktop build (Godot's file logging is on for desktop by default): `%APPDATA%\Godot\app_userdata\Orb Combat EX\logs\godot.log`. After a forced crash it holds the engine's error line with the reason (3 lines, no backtrace: a release export has no symbols). The next start rotates it to a dated file instead of overwriting it, so the dead run's log survives one restart (the engine keeps 5).
- A hang leaves a log that shows the run started and nothing else: **no reason line exists for a hang**; the check says so and does not pretend. A hang can only be caught from outside (a watchdog); not built.
- Row 6 fails today for a plain reason: **the report folder (`user://reports`, UI's "Make my report folder") holds only the match recorder's replays; nothing copies the logs.** That is the gap X-28 names.
- Linux: the same check runs in `desktop-builds.yml` on the runner (dispatch it after landing; not run yet, so Linux is unproven).

## Needs from the EP (not mine to edit)
1. **UI's grant:** the report folder copies `user://logs/godot.log` and the newest dated log (the dead run's), each cut to its last 200 KB, into the folder it makes. The size limit and the name and path scan (path job 14's second piece) apply to these files too. Then `crash-check.mjs --expect-report` turns row 6 into a pass or fail.
2. Optional, a stronger "the last run died" signal: a marker file the game writes at start and clears at a clean quit, so the next start can say "the last run did not close properly" and the report picks the old log up by name. That is game code (main.gd / UI); I have not designed it further.
