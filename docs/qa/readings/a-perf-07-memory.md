# A-PERF-07: memory at 5 and 30 minutes of computer-against-computer play (QA, run 2026-11-14, for Performance)

**What it measures.** The process's CPU-side memory and object count while seeded AI-v-AI matches play one after another on the sim alone, at 5 and 30 minutes of cumulative sim time, so a leak shows as a climb.

**Tool.** `qa/godot/memory_read.gd`. **Command:**

```
QA_PLANET="gen=3;planets=7;touches=3;cols=4800;power=1;travel=1.5" godot --headless --path <tree copy with qa/godot/qa_planet.gd> --script res://qa/godot/memory_read.gd -- --marks=5,30 --level=medium
```

**Tree and settings.** Build 6a30b4c9's own data, no patch; the computer at medium on both sides; planet 7 touch 3 generation 3, the energy model on, travel 1.5; seeds 1 to 3 one after another, each disposed as the game does. Headless: no video memory is counted.

**Result** (record `docs/qa/runs/6a30b4c9/memory-read-5-and-30-minutes.md`):

| Mark | Static memory, MiB | Objects |
| :--- | ---: | ---: |
| Start | 65.0 | 1,690 |
| 5 minutes | 114.0 | 9,578 |
| 30 minutes | 131.7 | 9,572 |
| After the last dispose | 109.0 | 1,705 |

**What it says.** Objects do not climb and return to the start's count. Static memory rises 17.7 MiB from 5 to 30 minutes and ends 44 MiB above the start; with three matches it looks like caches that stay for the run (the planet and ring bake), not a leak that grows with play. A ten-match run would show whether it keeps climbing. The peak (262.3 MiB) came at the first match's build.
