# The one-click first run (Tools and Performance, 2026-11-23; path to Alpha 1, job 8)

For Orb. **Double-click `tools/first-run/FIRST-RUN.cmd`** (after `node tools/desktop-local-build.mjs` has put a build in `homework/Files/desktop`). It opens the built game in a window, plays one fixed match, takes pictures at fixed moments, records how fast it runs and how long it takes to load, saves a report and closes the game. Nothing is uploaded and nothing leaves the PC.

## What you do, and what you see

1. The game opens and shows **its own warning about flashing effects. Read it and press Enter in the game.** The script never presses that key for you (a locked build honours no skip word, and the warning is the point). It waits as long as five minutes.
2. About two minutes of the game playing by itself: the list of modes, a mode chosen, a fighter, the match, the pause menu, then Quit and "Close the game". Please keep your hands off the keyboard and the mouse (the script presses keys in the game window).
3. The game closes by itself. The report is in `homework/Files/first-run/first-run-<date>-<time>/`: `first-run-report.md`, `first-run-report.json`, the pictures, and `program-output-<size>.txt` (the frame-rate lines).

This is a performance and screens check, never a flashing-effects reading. You alone should watch it.

## What it records

| Moment | Picture | Where it comes from |
| :--- | :--- | :--- |
| After the warning | `00-after-warning.png` | the window |
| The list of modes, the version line | `01-mode-list.png`, `02-version-line.png` (the bottom strip) | the window |
| The fighter pick | `03-fighter-pick.png` | the window |
| The match (20 s in, and 50 s in) | `04-match.png`, `05-match-later.png` | the window |
| The pause menu | `06-pause.png` | the window |
| Quit, "Close the game?" | `07-quit-question.png`, then the program must close | the window and the process |

Numbers: **frames a second** (the program's own `--print-fps` line, one a second: mean, median, slowest second, 5th percentile, the share of seconds at 30 or more and at 58 or more over the steady seconds after the first three), **engine start to the first picture** (the window is polled), **the second at which the frame rate settles** (first second at 80% of its steady value), and the game's own load lines (pair bake ms, the tick the incremental bake drained). The game prints no load time of its own, so these are measured from outside and the report calls them that.

## The size

`FIRST-RUN.cmd` passes its arguments on: `FIRST-RUN.cmd --size medium`, `--size small,medium,big`, `--size all`. `tools/first-run/sizes.json` has a row per size; `default` and `medium` (the one size offered since GW1c) have arguments. Small and big are `null` and are reported "not offered by this build" until they are offered again and whoever offers them fills their rows (the arguments to add after `--`; if a size is chosen by a menu row instead, the step keys in `steps.json` gain it). Several sizes run one after another, each a full run with its own report section.

## The numbers pipeline without a window

`node tools/first-run/first-run.mjs --no-window --size default --frames 1800` starts the built program `--headless` and ends it by `--frames`. Nothing is drawn, no key is pressed, no picture is taken, and **the frame rates are not a window's**: they prove the pipeline (build found, program run, lines read, report written, program closed), nothing about speed.

## The steps are data

`tools/first-run/steps.json`: a step is `human` (a sentence for the person at the PC), `keys` (ENTER ESC SPACE UP DOWN LEFT RIGHT P F1 TAB), `settleMs`, `shot`, `crop`, `holdS`. The draft follows the mode smoke's own walk (`tools/smoke/mode_smoke.gd`). Keys are held 90 ms and left 260 ms apart on Windows (window.ps1: about 5 frames down, 21 frames between presses at 60 a second) and pressed 250 ms apart on Linux (xdotool --delay 250). A step that goes wrong is a line of the report and the run goes on, so the numbers are always saved. **UI confirms the keys on the first click.**

## What is proven and what is not (2026-11-23)

- Proven here, on the built Windows program of main 66d4e460 (a scratch export): the pure parts (self-test, 18 checks: the frame-rate and load lines, the settle time, the size table, the steps file, the report text, "no bypass word on the command line", "no key before the warning"), and the whole **no-window** run, once: build found in the zip, program started headless at below-normal priority, 14 frame-rate seconds read, closed by itself, report written, sizes small, medium and big reported as not offered.
- **Not proven: the window half.** `tools/first-run/window.ps1` (the still of the program's window; the keys) parses and has never been run against a game window: no session opens a Godot window. Whether the still shows the game and not black (a GPU window grabbed from the screen), whether the keys reach the game, and whether the draft steps walk the real menus are what the first click finds out. A first-click failure is a line in the report, not a lost run.
- Not built: the Linux half (the path page says it runs in CI under the virtual display). The script's number half would run under Xvfb as it is; its stills and keys need xdotool and a screen grabber, and a workflow, which is a CI change for the EP to rule on.

## Closing on Linux (2026-11-25)

The numbers half must close the program with its own keys (pause, Quit, "Close the game"): the `quit-keys` row fails the run if they do not. If they do not, the script then asks the window manager (Alt+F4) and the `program-closes` row says whether that worked.

**Why earlier runs did not close by keys:** a runner's profile is new, so the How to play card came up after the warning and held the match; every key went nowhere (runs 45305205835 to 45773667206). Both first-run scripts now start the game with their own settings, only that card marked as seen. Run 45777933506 closed by the keys. A person pausing and closing on a real Deck is still its own check.
