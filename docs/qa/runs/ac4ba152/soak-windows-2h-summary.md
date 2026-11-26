# Soak: 7200 s asked, 7204 s run (win32; build ac4ba15, version 0.1.1)

| Check | Result | Detail |
| :--- | :--- | :--- |
| the program found the game and played the computer against itself | PASS | 719 samples |
| it ran the whole time and quit when asked (not a crash, a stall or a hang) | PASS | quit why=time matches=12 wallSeconds=7200 |
| it exited cleanly (exit code 0, no signal) | PASS | exit 0 |
| the run marker is gone after the close | PASS | none left |
| no SCRIPT ERROR line printed | PASS | none |
| the game kept up: median at least 58 ticks a second after the start | PASS | median 60.0 |
| the run changed matches often enough to read growth between them | PASS | 13 started, at least 7 wanted |

The first match was up 11.6 s after the program started.

**Matches:** 11 ended (capped 5, ko 6), median 594.0 sim seconds.

| Memory (from outside), MiB | after warm-up | end | max | slope, MiB an hour |
| :--- | ---: | ---: | ---: | ---: |
| working set / resident | 526.9 | 766.2 | 768.6 | 129.9 |
| private / data | 431.5 | 674.2 | 674.2 | 133.2 |

Warm-up cut: 720 s; 720 memory samples. The slope on a short run is noise; read it on the two-hour run only.

| Match | began at, s | objects at start | working set 20 s in, MiB | private, MiB |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 704 | 17908 | 527.2 | 431.5 |
| 3 | 1386 | 17983 | 593.3 | 494.0 |
| 4 | 2065 | 18012 | 610.6 | 511.5 |
| 5 | 2751 | 18063 | 618.4 | 519.7 |
| 6 | 3310 | 18109 | 665.8 | 568.4 |
| 7 | 3988 | 18153 | 693.1 | 597.0 |
| 8 | 4581 | 18163 | 697.0 | 600.8 |
| 9 | 5264 | 18192 | 698.6 | 602.8 |
| 10 | 5792 | 18225 | 745.0 | 649.5 |
| 11 | 6378 | 18254 | 767.5 | 672.7 |
| 12 | 6920 | 18278 | 768.6 | 673.7 |

**Frames (headless, capped at 60):** 60.0 ticks a second median (5th percentile 59.9), 60.0 process frames a second, worst frame in a window 31.1 ms median, 1458.4 ms at most, process time 17.0 ms.

| Counts | after start | end | max |
| :--- | ---: | ---: | ---: |
| objects | 13548 | 14162 | 18225 |
| nodes | 1264 | 1282 | 1297 |
| resources | 396 | 396 | 396 |
| orphans | 0 | 0 | 0 |

**Log:** engine log found; SCRIPT ERROR kinds 0, ERROR kinds 1, WARNING kinds 1; report folder: empty (a clean run copies nothing).

ERROR lines, most common first:
- 1x `ERROR: 10 resources still in use at exit (run with --verbose for details).`

WARNING lines, most common first:
- 1x `WARNING: 302 ObjectDB instances were leaked at exit (run with '--verbose' for details).`
