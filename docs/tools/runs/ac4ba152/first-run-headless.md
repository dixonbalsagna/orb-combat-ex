# First run, 2026-11-26

Build: 0.1.1 (commit ac4ba15, 2026-11-25). Machine: AMD Ryzen 7 9800X3D 8-Core Processor, AMD Radeon(TM) Graphics; NVIDIA GeForce RTX 5070 Ti, 31 GB, Windows 10.0.26200. Window none (headless).

**Numbers pipeline only (no window): the frame rates below are NOT a window's.** A performance reading, never a flash reading.

## Size: default

| Step | What | Result | Still |
| :--- | :--- | :--- | :--- |
| notice | a person reads the flashing-effects warning and presses Enter in the game | skipped: no window (--no-window) |  |
| mode-list | the list of modes, with the version line | skipped: no window (--no-window) |  |
| fighter-pick | Solo chosen, the setup with the fighter pick | skipped: no window (--no-window) |  |
| match-start | Start pressed (Up twice from the first row of the setup wraps to Start); the match loads and begins | skipped: no window (--no-window) |  |
| match-play | the match, after half a minute of play (the frame rate is read over this time) | skipped: no window (--no-window) |  |
| pause | the pause menu | skipped: no window (--no-window) |  |
| quit-question | Quit, and the question 'Close the game?' with Stay lit | skipped: no window (--no-window) |  |
| close-the-game | Up to 'Close the game', Enter: the program must close | skipped: no window (--no-window) |  |

Loading and frame rate:

- Engine start to the first picture: not measured
- Frame rate settled (80% of steady) after: 3 s
- Frames a second over 13 steady seconds: mean 92.1, median 89, slowest second 74, 5th percentile 74, fastest 120; 100% of seconds at 30 or more, 100% at 58 or more
- The game's own load lines: pair bake 223 ms (1084 poses), incremental bake drained at tick 103
- The program closed: yes, by itself; the run took 27 s

