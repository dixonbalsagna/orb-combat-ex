# Soak: 360 s asked, 364 s run (win32; build 20a483d, version 0.1.0)

| Check | Result | Detail |
| :--- | :--- | :--- |
| the program found the game and played the computer against itself | PASS | 71 samples |
| it ran the whole time and quit when asked (not a crash, a stall or a hang) | PASS | quit why=time matches=7 wallSeconds=360 |
| it exited cleanly (exit code 0, no signal) | PASS | exit 0 |
| the run marker is gone after the close | PASS | none left |
| no SCRIPT ERROR line printed | PASS | none |
| the game kept up: median at least 58 ticks a second after the start | PASS | median 60.0 |

The first match was up 10.6 s after the program started.

**Matches:** 6 ended (capped 6), median 40.0 sim seconds.

| Memory (from outside), MiB | after warm-up | end | max | slope, MiB an hour |
| :--- | ---: | ---: | ---: | ---: |
| working set / resident | 428.7 | 444.3 | 444.3 | 204.9 |
| private / data | 325.4 | 340.6 | 340.7 | 199.6 |

Warm-up cut: 120 s; 73 memory samples. The slope on a short run is noise; read it on the two-hour run only.

| Match | began at, s | objects at start | working set 20 s in, MiB | private, MiB |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 70 | 17738 | 428.6 | 325.4 |
| 3 | 128 | 17777 | 434.9 | 331.5 |
| 4 | 186 | 17803 | 440.7 | 337.6 |
| 5 | 240 | 17822 | 442.9 | 339.6 |
| 6 | 295 | 17855 | 444.2 | 340.7 |
| 7 | 355 | 17887 | n/a | n/a |

**Frames (headless, capped at 60):** 60.0 ticks a second median (5th percentile 38.5), 60.0 process frames a second, worst frame in a window 30.9 ms median, 1393.4 ms at most, process time 18.5 ms.

| Counts | after start | end | max |
| :--- | ---: | ---: | ---: |
| objects | 13413 | 13733 | 17803 |
| nodes | 1262 | 1273 | 1278 |
| resources | 393 | 393 | 393 |
| orphans | 0 | 0 | 0 |

**Log:** engine log found; SCRIPT ERROR kinds 0, ERROR kinds 1, WARNING kinds 1; report folder: empty (a clean run copies nothing).

ERROR lines, most common first:
- 1x `ERROR: 9 resources still in use at exit (run with --verbose for details).`

WARNING lines, most common first:
- 1x `WARNING: 283 ObjectDB instances were leaked at exit (run with '--verbose' for details).`
