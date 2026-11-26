# Soak: 600 s asked, 604 s run (win32; build 20a483d, version 0.1.0)

| Check | Result | Detail |
| :--- | :--- | :--- |
| the program found the game and played the computer against itself | PASS | 60 samples |
| it ran the whole time and quit when asked (not a crash, a stall or a hang) | PASS | quit why=time matches=1 wallSeconds=600 |
| it exited cleanly (exit code 0, no signal) | PASS | exit 0 |
| the run marker is gone after the close | PASS | none left |
| no SCRIPT ERROR line printed | PASS | none |
| the game kept up: median at least 58 ticks a second after the start | PASS | median 60.0 |

The first match was up 11.0 s after the program started.

**Matches:** 0 ended (none), median n/a sim seconds.

| Memory (from outside), MiB | after warm-up | end | max | slope, MiB an hour |
| :--- | ---: | ---: | ---: | ---: |
| working set / resident | 409.8 | 466.2 | 471.5 | 451.9 |
| private / data | 307.2 | 368.0 | 368.0 | 476.0 |

Warm-up cut: 120 s; 61 memory samples. The slope on a short run is noise; read it on the two-hour run only.

**Frames (headless, capped at 60):** 60.0 ticks a second median (5th percentile 59.8), 59.9 process frames a second, worst frame in a window 31.6 ms median, 210.8 ms at most, process time 19.0 ms.

| Counts | after start | end | max |
| :--- | ---: | ---: | ---: |
| objects | 13658 | 13753 | 13877 |
| nodes | 1273 | 1273 | 1282 |
| resources | 393 | 393 | 393 |
| orphans | 0 | 0 | 0 |

**Log:** engine log found; SCRIPT ERROR kinds 0, ERROR kinds 2, WARNING kinds 1; report folder: empty (a clean run copies nothing).

ERROR lines, most common first:
- 1x `ERROR: 6 RID allocations of type 'PN13RendererDummy14TextureStorage12DummyTextureE' were leaked at exit.`
- 1x `ERROR: 13 resources still in use at exit (run with --verbose for details).`

WARNING lines, most common first:
- 1x `WARNING: 8218 ObjectDB instances were leaked at exit (run with '--verbose' for details).`
