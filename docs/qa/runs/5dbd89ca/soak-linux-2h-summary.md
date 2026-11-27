# Soak: 7200 s asked, 7203 s run (linux; build 5dbd89c, version 0.1.1)

| Check | Result | Detail |
| :--- | :--- | :--- |
| the program found the game and played the computer against itself | PASS | 720 samples |
| it ran the whole time and quit when asked (not a crash, a stall or a hang) | PASS | quit why=time matches=12 wallSeconds=7200 |
| it exited cleanly (exit code 0, no signal) | PASS | exit 0 |
| the run marker is gone after the close | PASS | none left |
| no SCRIPT ERROR line printed | PASS | none |
| the game kept up: median at least 58 ticks a second after the start | PASS | median 60.0 |
| the run changed matches often enough to read growth between them | PASS | 13 started, at least 7 wanted |

The first match was up 13.1 s after the program started.

**Matches:** 11 ended (ko 6, capped 5), median 516.6 sim seconds.

| Memory (from outside), MiB | after warm-up | end | max | slope, MiB an hour |
| :--- | ---: | ---: | ---: | ---: |
| working set / resident | 381.6 | 383.1 | 387.3 | 0.8 |
| private / data | 441.8 | 443.3 | 447.4 | 0.8 |

Warm-up cut: 720 s; 719 memory samples. The slope on a short run is noise; read it on the two-hour run only.

| Match | began at, s | objects at start | working set 20 s in, MiB | private, MiB |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 532 | 17899 | 381.6 | 441.8 |
| 3 | 1219 | 17973 | 381.6 | 441.8 |
| 4 | 1905 | 17994 | 384.6 | 444.8 |
| 5 | 2591 | 18009 | 387.3 | 447.4 |
| 6 | 3150 | 18026 | 387.3 | 447.4 |
| 7 | 3829 | 18047 | 387.3 | 447.4 |
| 8 | 4422 | 18034 | 387.3 | 447.4 |
| 9 | 5106 | 18034 | 387.3 | 447.4 |
| 10 | 5634 | 18047 | 387.3 | 447.4 |
| 11 | 6221 | 18062 | 387.3 | 447.4 |
| 12 | 6765 | 18065 | 383.1 | 443.3 |

**Frames (headless, capped at 60):** 60.0 ticks a second median (5th percentile 59.9), 60.0 process frames a second, worst frame in a window 26.0 ms median, 1728.1 ms at most, process time 20.0 ms.

| Counts | after start | end | max |
| :--- | ---: | ---: | ---: |
| objects | 13553 | 14014 | 17994 |
| nodes | 1264 | 1282 | 1295 |
| resources | 396 | 396 | 396 |
| orphans | 0 | 0 | 0 |

**Log:** engine log found; SCRIPT ERROR kinds 0, ERROR kinds 2, WARNING kinds 1; report folder: empty (a clean run copies nothing).

ERROR lines, most common first:
- 1x `ERROR: 14 resources still in use at exit (run with --verbose for details).`
- 1x `ERROR: 6 RID allocations of type 'PN13RendererDummy14TextureStorage12DummyTextureE' were leaked at exit.`

WARNING lines, most common first:
- 1x `WARNING: 8224 ObjectDB instances were leaked at exit (run with '--verbose' for details).`

SOAK match 1 started seed=15960619 (the game's own boot match)
SOAK match 1 ended how=ko winnerSlot=1 simSeconds=450.2 t=526
SOAK match 2 started t=532 seed=2 objects=17899 computer plays both: true
SOAK match 2 ended how=capped winnerSlot=-1 simSeconds=600.0 t=1213
SOAK match 3 started t=1219 seed=3 objects=17973 computer plays both: true
SOAK match 3 ended how=capped winnerSlot=-1 simSeconds=600.0 t=1899
SOAK match 4 started t=1905 seed=4 objects=17994 computer plays both: true
SOAK match 4 ended how=capped winnerSlot=-1 simSeconds=600.0 t=2585
SOAK match 5 started t=2591 seed=5 objects=18009 computer plays both: true
SOAK match 5 ended how=ko winnerSlot=0 simSeconds=486.3 t=3144
SOAK match 6 started t=3150 seed=6 objects=18026 computer plays both: true
SOAK match 6 ended how=capped winnerSlot=-1 simSeconds=600.0 t=3822
SOAK match 7 started t=3829 seed=7 objects=18047 computer plays both: true
SOAK match 7 ended how=ko winnerSlot=1 simSeconds=516.6 t=4416
SOAK match 8 started t=4422 seed=8 objects=18034 computer plays both: true
SOAK match 8 ended how=capped winnerSlot=-1 simSeconds=600.0 t=5100
SOAK match 9 started t=5106 seed=9 objects=18034 computer plays both: true
SOAK match 9 ended how=ko winnerSlot=1 simSeconds=452.9 t=5628
SOAK match 10 started t=5634 seed=10 objects=18047 computer plays both: true
SOAK match 10 ended how=ko winnerSlot=1 simSeconds=512.8 t=6215
SOAK match 11 started t=6221 seed=11 objects=18062 computer plays both: true
SOAK match 11 ended how=ko winnerSlot=1 simSeconds=467.1 t=6758
SOAK match 12 started t=6765 seed=12 objects=18065 computer plays both: true
