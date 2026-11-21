# Memory at 5 and 30 minutes of computer-against-computer play (A-PERF-07, for Performance), QA 2026-11-14

Tool: `qa/godot/memory_read.gd`. Tree: build 6a30b4c9's own data (no patches), headless, AI v AI at medium, planet 7 touch 3 generation 3, the energy model on, travel 1.5, seeds 1 to 3 played one after another, each disposed as the game does; the process's CPU-side memory only (no video memory in a headless run). Run 04:21 to 04:23.

```
MEM {"kind":"start","matches":0,"objects":1690,"orphans":1,"peakMiB":262.3,"resources":139,"simMinutes":0,"staticMiB":65.0}
MEM {"kind":"mark","matches":0,"objects":9578,"orphans":1,"peakMiB":262.3,"resources":139,"simMinutes":5,"staticMiB":114.0}
MEM {"kind":"mark","matches":2,"objects":9572,"orphans":1,"peakMiB":262.3,"resources":139,"simMinutes":30,"staticMiB":131.7}
MEM {"kind":"done","matches":3,"objects":1705,"orphans":1,"peakMiB":262.3,"resources":139,"simMinutes":30,"staticMiB":109.0}
MEMDONE matches 3 ticks 108000
```

| Mark | Static memory, MiB | Objects |
| :--- | ---: | ---: |
| Start (before any match) | 65.0 | 1,690 |
| 5 minutes of sim time (inside match 1) | 114.0 | 9,578 |
| 30 minutes (inside match 3) | 131.7 | 9,572 |
| After match 3 was disposed | 109.0 | 1,705 |

**Reading.** Objects do not climb: 9,578 at 5 minutes and 9,572 at 30, and they return to the start's count after the last dispose (1,705 against 1,690). Static memory rises 17.7 MiB between 5 and 30 minutes (114.0 to 131.7) and ends 44 MiB above the start after the matches are gone (109.0 against 65.0). With three matches that is a growth that stops being objects, so it looks like caches (the planet and ring bake) that stay for the run, not a leak that grows with play; a longer run, or the same read over ten matches, would show whether it keeps climbing. The peak, 262.3 MiB, was reached at the first match's build and was not passed.
