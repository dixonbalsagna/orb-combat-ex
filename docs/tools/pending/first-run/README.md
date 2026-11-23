# Park: the one-click first run, for Orb (Tools and Performance, 2026-11-23; path to Alpha 1, job 8)

Script now; the click is after GW1c (job 6). The page for Orb is `docs/tools/first-run.md`.

**The change is already in the working tree** (uncommitted, my owned paths); `first-run.patch` is the same against 66d4e460 and applies alone, and together with `prove-a-build.patch`. Do not apply it on top of the working tree.

## Uncommitted paths (this park)

New: `tools/first-run/first-run.mjs`, `tools/first-run/window.ps1`, `tools/first-run/steps.json`, `tools/first-run/sizes.json`, `tools/first-run/FIRST-RUN.cmd`, `tools/first-run/first-run-selftest.mjs`, `docs/tools/first-run.md`. Changed: `.github/workflows/ci.yml` (one step, the self-test, after "Version and changelog agree"; that file also carries job 7's step).

## What it does

`FIRST-RUN.cmd` (double-click) runs `node tools/first-run/first-run.mjs`: finds the newest ORB-PRIVATE Windows zip in `homework/Files/desktop`, starts the built program in a window the way a player does, plays one fixed match (`--seed=4`) behind the menus, saves stills at fixed moments (after the warning, the list of modes, the version line cropped from it, the fighter pick, the match at 20 s and 50 s, the pause menu, the Quit question), presses Quit and "Close the game" and checks the program closes within 7 s, records the frame rate (the program's own `--print-fps`, a line a second) and the loading times (engine start to the first picture, the second the frame rate settles, the game's own pair-bake lines), and writes `first-run-report.md` and `.json` under `homework/Files/first-run/`. **`--size small|medium|big|all`** picks rows of `tools/first-run/sizes.json`: only `default` has arguments; the others are reported "not offered by this build" until GW1c lands the sizes and its owner fills the rows.

## Two things I found that shape it

1. **A locked build (every build we make) honours no bypass word** (`ui/hud/ui_hud.gd` `bypass_allowed`): `--bench`, `--frames` and `--shot` do not skip the flashing-effects warning in a window. So the script **never presses through the warning**: it says so, a person presses Enter in the game, and the run carries on when it sees the picture change. This follows the old-PC kit's rule ("no skip word, the page never clicks it"). The numbers come from `--print-fps`, which is not a bypass word.
2. The program prints **no load time of its own**, so "loading" is measured from outside (and called that in the report).

## Tried, and not tried

- **Proven here (the built Windows program of main 66d4e460, a scratch export):** the pure parts, 18 self-test checks (the frame-rate lines, the settle time, the size table including "small, medium and big wait for GW1c", the steps file, the report text, "no bypass word on the command line", "no key before the warning", the helper knows every key the steps use and names no process but its own); **the whole `--no-window` run once** (zip found and unpacked, program started `--headless` at below-normal priority, 14 frame-rate seconds read, program closed by itself, report and program-output files written, three sizes reported "not offered"). Its numbers are headless and the report says they are not a window's (mean 92.6 frames a second there).
- **Not proven: the window half.** `window.ps1` (a still of the program's window; the keys) parses (PowerShell's own parser) and has never run against a game window: no session opens a Godot window. Open questions the first click answers: whether a screen grab of the GPU window shows the game and not black; whether Enter, arrows and P reach the game as pressed; whether the draft steps (`steps.json`, from the mode smoke's own walk) land on the real screens. A step that goes wrong is a line in the report and the numbers are still saved. **UI should confirm the keys before the click** (the steps are data).
- **Not built: the Linux half** ("runs in CI under the virtual display"). The numbers half would run under Xvfb as it is; the stills and keys need xdotool and a screen grabber and a workflow file (a CI change, for the EP to rule on).
- A loading-time reading of the menu to match (Start to first match picture) is not separate: it is inside the `match-start` step's wait (20 s) and the frame-rate settle.
