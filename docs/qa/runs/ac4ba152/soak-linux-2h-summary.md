# Soak: 7200 s asked, 7203 s run (linux; build ac4ba15, version 0.1.1)

| Check | Result | Detail |
| :--- | :--- | :--- |
| the program found the game and played the computer against itself | PASS | 719 samples |
| it ran the whole time and quit when asked (not a crash, a stall or a hang) | PASS | quit why=time matches=12 wallSeconds=7200 |
| it exited cleanly (exit code 0, no signal) | PASS | exit 0 |
| the run marker is gone after the close | PASS | none left |
| no SCRIPT ERROR line printed | PASS | none |
| the game kept up: median at least 58 ticks a second after the start | PASS | median 60.0 |
| the run changed matches often enough to read growth between them | PASS | 13 started, at least 7 wanted |

The first match was up 12.6 s after the program started.

**Matches:** 11 ended (ko 6, capped 5), median 578.4 sim seconds.

| Memory (from outside), MiB | after warm-up | end | max | slope, MiB an hour |
| :--- | ---: | ---: | ---: | ---: |
| working set / resident | 383.6 | 600.4 | 600.4 | 142.3 |
| private / data | 443.7 | 660.4 | 660.4 | 142.2 |

Warm-up cut: 720 s; 720 memory samples. The slope on a short run is noise; read it on the two-hour run only.

| Match | began at, s | objects at start | working set 20 s in, MiB | private, MiB |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 673 | 17921 | 383.6 | 443.7 |
| 3 | 1359 | 17993 | 400.8 | 460.9 |
| 4 | 2045 | 18031 | 443.7 | 504.0 |
| 5 | 2731 | 18072 | 463.5 | 523.9 |
| 6 | 3289 | 18109 | 507.3 | 567.5 |
| 7 | 3968 | 18150 | 560.9 | 621.1 |
| 8 | 4561 | 18157 | 566.1 | 626.2 |
| 9 | 5245 | 18177 | 580.7 | 640.9 |
| 10 | 5773 | 18210 | 585.5 | 645.6 |
| 11 | 6360 | 18245 | 597.9 | 658.1 |
| 12 | 6903 | 18268 | 600.3 | 660.4 |

**Frames (headless, capped at 60):** 60.0 ticks a second median (5th percentile 59.9), 60.0 process frames a second, worst frame in a window 23.2 ms median, 1559.4 ms at most, process time 17.5 ms.

| Counts | after start | end | max |
| :--- | ---: | ---: | ---: |
| objects | 13505 | 14295 | 18245 |
| nodes | 1262 | 1287 | 1295 |
| resources | 396 | 396 | 396 |
| orphans | 0 | 0 | 0 |

**Log:** engine log found; SCRIPT ERROR kinds 0, ERROR kinds 1, WARNING kinds 1; report folder: empty (a clean run copies nothing).

ERROR lines, most common first:
- 1x `ERROR: 10 resources still in use at exit (run with --verbose for details).`

WARNING lines, most common first:
- 1x `WARNING: 304 ObjectDB instances were leaked at exit (run with '--verbose' for details).`

SOAK match 1 started seed=15143809 (the game's own boot match)
SOAK match 1 ended how=ko winnerSlot=1 simSeconds=578.4
SOAK match 2 started t=673 seed=2 objects=17921 computer plays both: true
SOAK match 2 ended how=capped winnerSlot=-1 simSeconds=600.0
SOAK match 3 started t=1359 seed=3 objects=17993 computer plays both: true
SOAK match 3 ended how=capped winnerSlot=-1 simSeconds=600.0
SOAK match 4 started t=2045 seed=4 objects=18031 computer plays both: true
SOAK match 4 ended how=capped winnerSlot=-1 simSeconds=600.0
SOAK match 5 started t=2731 seed=5 objects=18072 computer plays both: true
SOAK match 5 ended how=ko winnerSlot=0 simSeconds=486.3
SOAK match 6 started t=3289 seed=6 objects=18109 computer plays both: true
SOAK match 6 ended how=capped winnerSlot=-1 simSeconds=600.0
SOAK match 7 started t=3968 seed=7 objects=18150 computer plays both: true
SOAK match 7 ended how=ko winnerSlot=1 simSeconds=516.6
SOAK match 8 started t=4561 seed=8 objects=18157 computer plays both: true
SOAK match 8 ended how=capped winnerSlot=-1 simSeconds=600.0
SOAK match 9 started t=5245 seed=9 objects=18177 computer plays both: true
SOAK match 9 ended how=ko winnerSlot=1 simSeconds=452.9
SOAK match 10 started t=5773 seed=10 objects=18210 computer plays both: true
SOAK match 10 ended how=ko winnerSlot=1 simSeconds=512.8
SOAK match 11 started t=6360 seed=11 objects=18245 computer plays both: true
SOAK match 11 ended how=ko winnerSlot=1 simSeconds=467.1
SOAK match 12 started t=6903 seed=12 objects=18268 computer plays both: true
