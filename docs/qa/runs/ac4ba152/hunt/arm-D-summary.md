# Soak: 600 s asked, 604 s run (win32; build ac4ba15, version 0.1.1)

| Check | Result | Detail |
| :--- | :--- | :--- |
| the program found the game and played the computer against itself | PASS | 292 samples |
| it ran the whole time and quit when asked (not a crash, a stall or a hang) | PASS | quit why=time matches=1 wallSeconds=600 |
| it exited cleanly (exit code 0, no signal) | PASS | exit 0 |
| the run marker is gone after the close | PASS | none left |
| no SCRIPT ERROR line printed | PASS | none |
| the game kept up: median at least 58 ticks a second after the start | PASS | median 60.0 |
| the run changed matches often enough to read growth between them | PASS | not asked of a run this short (2 started) |

The first match was up 11.2 s after the program started.

**Matches:** 0 ended (none), median n/a sim seconds.

| Memory (from outside), MiB | after warm-up | end | max | slope, MiB an hour |
| :--- | ---: | ---: | ---: | ---: |
| working set / resident | 415.5 | 463.2 | 463.2 | 423.6 |
| private / data | 318.6 | 365.8 | 365.8 | 417.4 |

Warm-up cut: 120 s; 301 memory samples. The slope on a short run is noise; read it on the two-hour run only.

**Frames (headless, capped at 60):** 60.0 ticks a second median (5th percentile 59.6), 60.0 process frames a second, worst frame in a window 30.3 ms median, 41.5 ms at most, process time 16.2 ms.

| Counts | after start | end | max |
| :--- | ---: | ---: | ---: |
| objects | 13436 | 13965 | 14232 |
| nodes | 1260 | 1279 | 1287 |
| resources | 400 | 400 | 400 |
| orphans | 0 | 0 | 0 |

**Log:** engine log found; SCRIPT ERROR kinds 0, ERROR kinds 2, WARNING kinds 1; report folder: empty (a clean run copies nothing).

ERROR lines, most common first:
- 1x `ERROR: 6 RID allocations of type 'PN13RendererDummy14TextureStorage12DummyTextureE' were leaked at exit.`
- 1x `ERROR: 14 resources still in use at exit (run with --verbose for details).`

WARNING lines, most common first:
- 1x `WARNING: 8225 ObjectDB instances were leaked at exit (run with '--verbose' for details).`
