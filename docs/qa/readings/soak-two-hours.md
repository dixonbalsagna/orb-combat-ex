# The two-hour soak of the desktop program on ac4ba152 (0.1.1, GW1c), Windows and Linux (QA, path job 14; run 2026-11-25 to 26)

**What it measures.** Stability and memory of the built program over two hours of computer-against-computer matches, headless (RL-279). It is not a flash reading, a frame-rate reading on a screen or a performance budget. Harness: `qa/soak/soak.mjs`; method and limits: `docs/qa/pending/soak/README.md`.

**Runs.**
- **Windows:** Orb's private zip of ac4ba152 (hash checked against its `.sha256.txt`), unpacked into scratch, this PC, below-normal priority. Other sessions' engine jobs ran at times: machine load 25% on average, 56% at most, never 80% or more, in 118 one-minute readings.
- **Linux:** the workflow `linux-soak.yml`, run 45773552777 on ac4ba152, read from the run's log.

## Result: all seven checks pass on both

| | Windows | Linux |
| :--- | :--- | :--- |
| Ran | 7,204 s, quit when asked, exit 0, run marker gone | 7,203 s, the same |
| SCRIPT ERROR lines | none | none |
| Game ticks a second | 60.0 median (5th percentile 59.9) | 60.0 median (59.9) |
| Matches | 13 started, 11 ended: 6 KO, 5 at the 600 s cap | the same counts |
| First match up | 11.6 s | 12.6 s |
| Worst frame (at a match start) | 1,458 ms; median window 31 ms | 1,559 ms; median 23 ms |
| At exit | `10 resources still in use`, 302 objects leaked | `10 resources still in use`, 304 |

## Memory grew, on both, and did not come back down

| MiB, resident (working set) 20 s into the match | m2 | m3 | m4 | m5 | m6 | m7 | m8 | m9 | m10 | m11 | m12 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Windows | 527 | 593 | 611 | 618 | 666 | 693 | 697 | 699 | 745 | 768 | 769 |
| Linux | 384 | 401 | 444 | 464 | 507 | 561 | 566 | 581 | 586 | 598 | 600 |

| | Windows | Linux |
| :--- | :--- | :--- |
| From the 2nd match's start to the end | 527 → 766 (+239) | 384 → 600 (+217) |
| Slope after the 720 s warm-up | 130 MiB an hour | 142 MiB an hour |

**Reading.**
- **No match gives its memory back:** each begins where the last one ended, or a little above.
- On Windows (the only run whose samples I have), of the 239 MiB from the 2nd match's start, about 155 MiB came **during** matches (several matches added nothing, others 11 to 54 MiB in steps) and about 84 MiB **at the match changes** (4 to 16 MiB a change). The first match had already added 97 MiB while it ran.
- Both platforms show it, so it is not one system's allocator alone.
- The engine's counts do not explain it: resources flat (396), nodes flat (about 1,262 to 1,297), no orphans, objects up by a few hundred (at match starts about 37 more a match). That is far too few objects for 220 MiB; the memory is likely in the data inside them (arrays, buffers, stores). **QA has not found where.**
- Whether it levels off is not settled: the last reading rose only 1 to 2 MiB on both, but earlier readings were flat too before the next step. A longer run would say. Performance owns the memory budget; QA sets no pass line.

## Also seen

- **Computer-against-computer matches are long:** the 11 that ended ran 453 to 600+ sim seconds, and 5 of them reached the 600 s cap without a result.
- **The two platforms played the same matches, with one exception.** Matches 3 to 11 ended the same way on both, and every KO among them at the same sim time. Match 2 did not (Windows: KO at 594.0 s; Linux: capped at 600 s). The two runs' first matches had different clock seeds and the game keeps a session intro memory between matches, which may explain it; QA has not checked. This is not a replay or hash comparison.

## Records

`docs/qa/runs/ac4ba152/`: `soak-windows-2h-summary.md`, `soak-windows-2h-samples.csv`, `soak-windows-2h-matches.txt`, `soak-windows-2h-load.txt`, `soak-linux-2h-summary.md` (cut from the run's log; its samples are in the run's `soak-numbers` artifact, not downloaded).

## Windows against Linux, match change by match change (added 2026-11-26)

The same matches 3 to 11 were played on both (see above), so the change-by-change differences can be set side by side. Each figure is the rise from one match's start to the next.

| Into match | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | Total |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Objects, Windows | 75 | 29 | 51 | 46 | 44 | 10 | 29 | 33 | 29 | 24 | 370 |
| Objects, Linux | 72 | 38 | 41 | 37 | 41 | 7 | 20 | 33 | 35 | 23 | 347 |
| Memory MiB, Windows | 66.1 | 17.3 | 7.8 | 47.4 | 27.3 | 3.9 | 1.6 | 46.4 | 22.5 | 1.1 | 241.4 |
| Memory MiB, Linux | 17.2 | 42.9 | 19.8 | 43.8 | 53.6 | 5.2 | 14.6 | 4.8 | 12.4 | 2.4 | 216.7 |

- **Objects track each other** (correlation of the steps 0.94): about 35 more are kept per match, and how many depends on what the match did, not on the platform.
- **Memory steps do not** (correlation 0.24), though the totals are close (241 and 217 MiB). The same matches gave a large step on one platform and a small one on the other. That reads like buffers or pools growing in lumps when they cross a size, not like one particular match event costing memory; QA infers this and has not shown it.
- Both end with small rises (1 to 2 MiB into match 12), which is not enough to call it level: both had small rises earlier and then larger ones.

## The faster hunt (EP's order, 2026-11-26): what grows, per match change and per minute of play

Four short arms on the same build (Windows, headless, below normal, other sessions' engine jobs running; every arm passed the soak's checks). `soak.mjs` now has `--census` (every field of the match state, the replay recorder, the host, the game scene and 1,580 script statics, sized at each match's start and end; the sizes are estimates, within about a factor of two of real memory since the fix below, not the process's memory) and `--same-seed`. Records: `docs/qa/runs/ac4ba152/hunt/`.

| Arm | What | Process memory |
| :--- | :--- | :--- |
| A | 40-sim-second matches, a new seed each, 20 min (21 starts) | 410 → 464 MiB over the first changes, **then flat** (463.6 for the last matches); per match 5.68 MiB in the first half, **0.16 in the second** |
| B | the same, but **the same seed** every match, 12 min (13 starts) | 436 → 448 MiB, then flat; 2.96 then **0.20** MiB a match |
| C | as A with the census, 15 min (16 starts) | 441 → 456 MiB, then flat; 2.49 then 0.16 |
| D | **one long match**, 10 min, census each minute | **404 → 462 MiB (+58)** over nine minutes of play, still rising at the end |

**Reading (corrected 2026-11-26: the first version's store sizes were wrong; see "The correction" below. The process memory figures above were measured from outside and stand).**
- **Per match change, short matches: no leak seen.** After the first few matches the process stops growing (about 0.2 MiB a match, within a reading's step), with new seeds or the same one.
- **Per minute of play: memory climbs.** About 5 to 6 MiB a minute on average in the long match, in steps.
- **Not accounted for:** the two-hour run grew about 240 MiB. What is named below is a few tens of MiB.

## The correction (World's measurement, then QA's)

- **The census counted shared lists once for every reference.** World measured the water-record index `sim/world/waterrec.gd:_ix` against real memory: **1.93 MiB** 40 s into a match and **4.10 MiB** at the very worst, not 136 (`docs/world/runs/waterrec-ix/`). The census now counts each list and dictionary once, by identity; it then reads the index at 1.95 MiB. **Withdrawn:** "one very large store", and the idea that freeing it holds the process's high-water mark.
- **Withdrawn:** "`main.pane.planet` +36 MiB, not emptied at a new match". It was the same error, and it charged to the planet view what the view only refers to. The saved `arm-C` and `arm-D` census files and `arm-C-split.txt`'s store table are from the faulty census: do not quote their sizes.

## What grows, checked against real memory (editor build of ac4ba152, static memory before and after emptying each field)

| Field | Whose | Over a match | Emptying it frees | Kept at a new match? |
| :--- | :--- | :--- | :--- | :--- |
| `sim/world/field.gd` `Field.sh` (sub-node heights) | World (the renderer reaches it as `tile_field._F`) | 0.5 → 5.10 MiB by about 100 to 120 s, then level | **5.10 MiB** | **Yes**: fields are cached by planet seed, three kept |
| `sim/world/field.gd` `Field.sb` (sub-node biome) | World | the same | **5.10 MiB** | **Yes**, the same |
| `render/core/tile_field.gd` `_hs` (tile heights) | Rendering | 0.2 → 1.5 to 2.0 MiB; a pool of 800 layers bounds it | 1.45 to 2.05 MiB | No: a new tile field each match |
| `tile_field.gd` `_wets` | Rendering | 0.15 → 0.44 MiB, bounded the same way | 0.29 to 0.44 MiB | No |

- **The planet view itself does not grow:** its own larger lists are set up with the match (`_parts` 4.1 MiB and `_win` 1.8 MiB freed; the rest under 1 MiB each).
- Everything listed above and the field's fixed lists came to 25.5 MiB of 270 MiB static after 163 sim seconds of one match; static memory rose 29 MiB in that time, of which `sh` and `sb` are about 9. **The rest of the rise is not named.**
- With three planets cached, `sh` and `sb` can hold about 30 MiB between them; this fits arm A levelling off after its first few matches, but QA has not shown that it is the reason.

## Found on the way: a bug (GB-010)

From the second match on, neither pane's `ground` is linked to its `tile_field` (match 1: linked; matches 2 and 3: null). `qa/known-bugs.md` GB-010, with the cause in the code; what a player sees from it is not verified.

Records: `docs/qa/runs/ac4ba152/hunt/` (`real-memory-*.txt`, `real_probe2.gd.txt`, `ground-link-three-matches.txt`, `planet-fixed-*`).

## The hour of long matches, real memory beside the census (EP's order, 2026-11-26): the growth is named

**How.** The editor build of ac4ba152, headless, below normal, isolated (`qa/soak/real-memory.mjs` with `real_probe.gd`): real static memory, the fixed census and an estimate of what the engine holds outside scripts, at each match's start and end. Matches capped at 600 sim seconds. At the end the memory is taken apart: every list, dictionary and packed array is emptied one by one, then the whole scene freed, and what each gives back is read. A baseline run does the same after one match. Records: `docs/qa/runs/ac4ba152/hour/`.

**Static memory at each match's start (MiB):** 254, 356, 391, 427, 432, 466 (matches 1 to 6). The census (script data) at the same points: 60, 100, 133, 149, 153, 189. The scene's meshes, textures and audio stay at about 7.

| Static memory, MiB | after 1 match (baseline) | after 5 matches | difference | per match |
| :--- | ---: | ---: | ---: | ---: |
| All | 327.7 | 434.0 | **+106.3** | 26.6 |
| In lists, dictionaries and packed arrays | 63.7 | 151.3 | **+87.6** | 21.9 |
| Freed with the scene | 12.2 | 12.4 | +0.2 | 0.1 |
| Left after both (engine, code, anything else) | 228.5 | 246.8 | +18.3 | 4.6 |

| Store (static memory freed by emptying it) | baseline | after 5 matches | difference |
| :--- | ---: | ---: | ---: |
| **World's field, `Field.sh`** (`sim/world/field.gd`; reached by `sim/core/field.gd` `_ctF`) | 19.12 | **62.15** | **+43.03** |
| **World's field, `Field.sb`** | 19.12 | **62.15** | **+43.03** |
| `RenderTileField._wets` | 1.38 | 2.15 | +0.77 |
| `RenderMats._tracked` (render/core/mats.gd) | 0.14 | 0.85 | +0.71 |
| everything else | | | under 0.1 each |

**Reading.**
- **`Field.sh` and `Field.sb` are 86 of the 106 MiB (81%).** They are the field's sub-node tables: an entry is added for every new fine-ground point read (`_subKey`) and none is removed; only the pool's `extra` lists have a limit. **Every match plays the same planet** (`data/biomes/world.json`: planet 7, random off), so one field is reused and its tables go on growing for as long as the program runs.
- **This fits the two-hour release soak:** 22 to 24 MiB a match there (Windows 527 → 769 and Linux 384 → 600 over ten match changes), 21.9 a match in lists here. It also fits arm A levelling off: short matches from the same start read little new ground. (A fit across two builds, not a measurement on the release program.)
- **Not named:** 18 MiB over four matches (4.6 a match) stays after the lists are emptied and the scene freed.
- **Small, but it only grows:** `RenderMats._tracked` (+0.7 MiB over four matches).
- Not a leak in the sense of memory nobody can reach: it is a cache with no limit. Static memory was still rising at the sixth match.

**Withdrawn:** my earlier "sh and sb level off by about 120 sim seconds, 5 MiB each" came from one short run.

## The fix confirmed: World's field-subcap on d9bc2f07 (2026-11-26, the same five-match run)

World's fix holds `sh` and `sb` in two generations of at most 150,000 sub-nodes each (`sim/world/field.gd`). Same method, same machine, editor build, headless, below normal, 600-sim-second matches. The build also carries Rendering's ground-link fix (GB-010); Rendering's `_tracked` fix was not in it. The final take-apart came at match 7's start here (after six matches; match 1 ended early), at match 6's start before (after five). Records: `docs/qa/runs/d9bc2f07/hour/`.

| Static memory at each match's start, MiB | m1 | m2 | m3 | m4 | m5 | m6 | m7 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Before (ac4ba152) | 254 | 356 | 391 | 427 | 432 | 466 | |
| After (d9bc2f07) | 254 | 344 | 345 | 367 | 367 | 368 | 351 |

| Taken apart at the end, MiB | Before, after 5 matches | After, after 6 matches |
| :--- | ---: | ---: |
| Static, all | 434.0 | **319.4** |
| In lists, dictionaries and packed arrays | 151.3 | 58.7 |
| Freed with the scene | 12.4 | 11.4 |
| Left after both | 246.8 | 226.0 |
| `Field.sh` + `Field.sb` | 124.3 | 13.8 |
| `Field.shOld` + `Field.sbOld` (the older generation) | none | 18.3 |
| **The sub-node tables together** | **124.3** | **32.1** |
| `RenderMats._tracked` | 0.85 | 1.03 |

**Reading.**
- **The field tables level off, and so does the process:** from match 2 on, match starts stay between 344 and 368 MiB, with the seventh at 351. Before, they rose every match to 466.
- The tables held 32 MiB at this reading against 124 before.
- The 4.6 MiB a match that stayed unnamed does not show here either: what is left after emptying everything is 226.0 MiB against 228.5 after one match on the old build (two different builds, so a rough comparison).
- `_tracked` still creeps up (1.03 MiB), as expected until Rendering's fix lands.
- **Not read here:** the release program (the two-hour soak on the next build is that), and what the bound costs in read time.
