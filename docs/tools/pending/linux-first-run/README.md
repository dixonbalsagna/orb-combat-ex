# Park: the Linux numbers half of the first run, in CI (Tools, 2026-11-23; EP ruling and Legal RL-270)

The edits are in the working tree (uncommitted, my paths). **Commit the workflow and the script together** (`check-workflow-paths` fails if the workflow names a script git does not have).

## Uncommitted paths
New: `.github/workflows/linux-first-run.yml`, `tools/first-run/linux-numbers.mjs`. Changed: `tools/first-run/first-run-selftest.mjs` (21 checks now: 3 new).

## What it is
A dispatch-only workflow (`gh workflow run linux-first-run.yml`) that exports the "Linux" preset of a commit on main (same lock and route scan as the desktop builds), starts it on an Xvfb virtual display with software GL, presses Return on the flashing-effects warning with xdotool, plays `steps.json`'s keys (mode list, fighter, Start, play, pause, Quit, "Close the game"), reads the program's own frame-rate and bake lines and checks the program closes by itself within 7 s. The job's summary has the report (text and numbers only). Uploads nothing; no still, video or capture.

## Legal RL-270's five conditions, and where each is kept
1. Shipped build, warning unchanged, no skip flag: same lock and routes; `linux-numbers.mjs` adds no argument but the seed, `--print-fps` and window options; the self-test fails if a bypass word, `--frames`, `--bench` or `--shot` appears in it.
2. Nobody watches: Xvfb started by the job; the script refuses to run unless `GITHUB_ACTIONS=true`, `DISPLAY` names an X display and the job set `FIRST_RUN_VIRTUAL_DISPLAY=1` (self-tested: it will not press a key on a person's screen).
3. No stills, video or capture; text and numbers only: no capture tool is installed or named (self-test greps for them); no upload step.
4. Performance reading only: the report says so; software GL is not a graphics card.
5. Dispatch only; no package made.

## Time against the budgets
Not in ci.yml, so no budget row. Expected about 8 to 10 minutes of runner time a dispatch (setup 3, export 1, apt 1, the run about 2.5; limit 25). Unproven: it has never run.

## Not proven
Everything on the runner: xdotool reaching a window under Xvfb without a window manager (the script moves the pointer to the window first), whether the steps land on the real screens (UI confirmed the Start keys; the rest is the draft), and the frame rates (software GL, not comparable with a PC's).
