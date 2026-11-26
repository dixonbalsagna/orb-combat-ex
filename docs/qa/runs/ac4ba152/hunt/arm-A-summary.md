# Soak: 1200 s asked, 1204 s run (win32; build ac4ba15, version 0.1.1)

| Check | Result | Detail |
| :--- | :--- | :--- |
| the program found the game and played the computer against itself | PASS | 587 samples |
| it ran the whole time and quit when asked (not a crash, a stall or a hang) | PASS | quit why=time matches=21 wallSeconds=1200 |
| it exited cleanly (exit code 0, no signal) | PASS | exit 0 |
| the run marker is gone after the close | PASS | none left |
| no SCRIPT ERROR line printed | PASS | none |
| the game kept up: median at least 58 ticks a second after the start | PASS | median 60.0 |
| the run changed matches often enough to read growth between them | PASS | 22 started, at least 10 wanted |

The first match was up 10.9 s after the program started.

**Matches:** 21 ended (capped 21), median 40.0 sim seconds.

| Memory (from outside), MiB | after warm-up | end | max | slope, MiB an hour |
| :--- | ---: | ---: | ---: | ---: |
| working set / resident | 432.4 | 463.6 | 467.2 | 76.6 |
| private / data | 329.1 | 361.8 | 365.0 | 77.7 |

Warm-up cut: 120 s; 599 memory samples. The slope on a short run is noise; read it on the two-hour run only.

| Match | began at, s | objects at start | working set 20 s in, MiB | private, MiB |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 69 | 17694 | 432.4 | 329.1 |
| 3 | 128 | 17735 | 435.2 | 331.0 |
| 4 | 185 | 17833 | 448.0 | 344.2 |
| 5 | 238 | 17859 | 449.9 | 348.4 |
| 6 | 294 | 17894 | 451.3 | 349.4 |
| 7 | 352 | 17920 | 452.1 | 349.9 |
| 8 | 407 | 17952 | 452.3 | 349.8 |
| 9 | 464 | 17978 | 458.9 | 356.4 |
| 10 | 521 | 18001 | 459.6 | 356.9 |
| 11 | 577 | 18036 | 459.6 | 356.9 |
| 12 | 633 | 18050 | 461.6 | 358.9 |
| 13 | 692 | 18077 | 461.6 | 358.8 |
| 14 | 749 | 18103 | 462.4 | 359.8 |
| 15 | 805 | 18130 | 463.0 | 360.3 |
| 16 | 864 | 18144 | 463.5 | 360.8 |
| 17 | 921 | 18175 | 463.6 | 360.8 |
| 18 | 978 | 18186 | 463.6 | 360.8 |
| 19 | 1035 | 18206 | 463.6 | 360.8 |
| 20 | 1093 | 18244 | 457.2 | 361.3 |
| 21 | 1148 | 18265 | 463.6 | 361.8 |

**Frames (headless, capped at 60):** 60.0 ticks a second median (5th percentile 59.6), 60.0 process frames a second, worst frame in a window 30.4 ms median, 1354.8 ms at most, process time 17.9 ms.

| Counts | after start | end | max |
| :--- | ---: | ---: | ---: |
| objects | 13408 | 14364 | 18282 |
| nodes | 1262 | 1284 | 1288 |
| resources | 396 | 396 | 396 |
| orphans | 0 | 0 | 0 |

**Log:** engine log found; SCRIPT ERROR kinds 0, ERROR kinds 1, WARNING kinds 1; report folder: empty (a clean run copies nothing).

ERROR lines, most common first:
- 1x `ERROR: 10 resources still in use at exit (run with --verbose for details).`

WARNING lines, most common first:
- 1x `WARNING: 302 ObjectDB instances were leaked at exit (run with '--verbose' for details).`
