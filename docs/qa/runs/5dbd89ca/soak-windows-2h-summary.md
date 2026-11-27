# Soak: 7200 s asked, 7203 s run (win32; build 5dbd89c, version 0.1.1)

| Check | Result | Detail |
| :--- | :--- | :--- |
| the program found the game and played the computer against itself | PASS | 720 samples |
| it ran the whole time and quit when asked (not a crash, a stall or a hang) | PASS | quit why=time matches=12 wallSeconds=7200 |
| it exited cleanly (exit code 0, no signal) | PASS | exit 0 |
| the run marker is gone after the close | PASS | none left |
| no SCRIPT ERROR line printed | PASS | none |
| the game kept up: median at least 58 ticks a second after the start | PASS | median 60.0 |
| the run changed matches often enough to read growth between them | PASS | 13 started, at least 7 wanted |

The first match was up 9.0 s after the program started.

**Matches:** 11 ended (ko 7, capped 4), median 516.6 sim seconds.

| Memory (from outside), MiB | after warm-up | end | max | slope, MiB an hour |
| :--- | ---: | ---: | ---: | ---: |
| working set / resident | 481.1 | 504.0 | 513.0 | 15.5 |
| private / data | 388.3 | 408.5 | 413.9 | 13.7 |

Warm-up cut: 720 s; 720 memory samples. The slope on a short run is noise; read it on the two-hour run only.

| Match | began at, s | objects at start | working set 20 s in, MiB | private, MiB |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 504 | 17884 | 483.2 | 384.3 |
| 3 | 1187 | 17957 | 486.5 | 389.3 |
| 4 | 1866 | 17978 | 489.0 | 390.8 |
| 5 | 2552 | 17997 | 486.8 | 388.8 |
| 6 | 3110 | 18017 | 490.5 | 392.8 |
| 7 | 3788 | 18035 | 509.5 | 411.7 |
| 8 | 4380 | 18028 | 506.6 | 408.4 |
| 9 | 5064 | 18034 | 507.5 | 408.1 |
| 10 | 5591 | 18044 | 509.0 | 409.6 |
| 11 | 6178 | 18059 | 505.8 | 406.6 |
| 12 | 6720 | 18063 | 507.4 | 408.2 |

**Frames (headless, capped at 60):** 60.0 ticks a second median (5th percentile 60.0), 60.0 process frames a second, worst frame in a window 17.2 ms median, 1232.4 ms at most, process time 13.3 ms.

| Counts | after start | end | max |
| :--- | ---: | ---: | ---: |
| objects | 13527 | 13938 | 14388 |
| nodes | 1262 | 1282 | 1297 |
| resources | 396 | 396 | 396 |
| orphans | 0 | 0 | 0 |

**Log:** engine log found; SCRIPT ERROR kinds 0, ERROR kinds 2, WARNING kinds 1; report folder: empty (a clean run copies nothing).

ERROR lines, most common first:
- 1x `ERROR: 6 RID allocations of type 'PN13RendererDummy14TextureStorage12DummyTextureE' were leaked at exit.`
- 1x `ERROR: 14 resources still in use at exit (run with --verbose for details).`

WARNING lines, most common first:
- 1x `WARNING: 8225 ObjectDB instances were leaked at exit (run with '--verbose' for details).`
