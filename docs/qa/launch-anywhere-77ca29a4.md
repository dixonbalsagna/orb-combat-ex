# The newcomer and the route with launch anywhere on: a scratch read on 77ca29a4 (QA, 2026-10-19)

Game Design's ruling on the re-run (2026-10-18): the newcomer row stands, with 6 of 100 as its "before"; it is re-read on launch anywhere at 90% inside 60 s, and if it is still short the first lever is the link's 24 ticks. This is that re-read.

| | |
| :--- | :--- |
| Build | **HEAD 77ca29a4**, a clean `git archive`, in a **scratch export**, with two overlays (disclosure): my harness files, uncommitted at the time (`masher.js`, `players.gd`, `records.gd`, `selftest.js`: the `launch_power` cue counting and the watched-not-banded L16 rows), and **`data/director/interrupts.json` in the scratch copy only: `brawl.anywhere.enabled` set to `true`** (it is `false` on main). The repo is untouched. UI's `launch_marks` is not a sim switch and is not part of this read |
| Run | 21:54 to 00:19, five Godot jobs of 100 matches (seeds 1 to 100), `--jobs=2`, headless, below-normal priority, wall cap 1,800 s a match. **No job invalid.** Other sessions kept the machine at about 60% CPU, which cannot change a sim result |
| Scripts | As in `launch-rerun-f15d7de3.md`. **The route:** X every 8 ticks, one B at every opening. **The newcomer:** X every 10 ticks, one B a seeded 0 to 20 ticks after his run reaches the close; he does not read the opening |

## The newcomer

| Against | | Launched at all | First launch p10 / median / p90 | Inside 30 / 60 / 120 s | By him / on him a match | Full by him / on him | Wins |
| :--- | :--- | ---: | :--- | :--- | :--- | :--- | ---: |
| **Medium** | f15d7de3, switch off | 77 | 68 / 244 / 288 s | 2 / **6** / 15 | 1.58 / 10.14 | n/a | 4% |
| | **launch anywhere on** | **74** | 24 / **148** / 305 s | **10 / 14 / 31** | **1.89 / 17.93** | 1.79 / 4.17 | **2%** |
| Easy | f15d7de3, switch off | 96 | 150 / 228 / 255 s | 4 / 5 / 9 | 3.65 / 8.19 | n/a | 71% |
| | **launch anywhere on** | 99 | 19 / **166** / 253 s | 18 / **25** / 37 | 4.89 / 11.71 | 2.92 / 2.37 | 62% |

- **The row: a newcomer launches within 60 s in 90% of runs. With launch anywhere on it reads 14% at medium** (6% before), and 25% at easy. **Still far short.** The first launch comes earlier (a median of 148 s against 244 s) and more often early (10 of 100 inside 30 s against 2), but a quarter of the matches at medium still never see one.
- **He is launched far more.** On him a match goes 10.14 to **17.93** at medium: the AI's in-string launcher reaches a newcomer who lands few blows, and his own launches by him barely move (1.58 to 1.89). He still wins 2%.
- **Of his launches by him at medium (1.89 a match), 1.79 are full** (power 0.8 or more at the send, after freshness). Against the AI's 4.17 full launches on him.
- **What this does and does not say about the link.** The link makes a B within 24 ticks of one of the presser's *clean landed blows* a launcher. This newcomer lands few clean blows against medium (he wins 2%), so the link has little to attach to. I did not vary the link's length or the newcomer's timing, so **I cannot say that the 24 ticks is the lever or that it is not.** What the run does show: with the link, the newcomer's B no longer depends on the 12-tick stagger, and it still launches in 14% of matches inside a minute.

## The route (launch anywhere on)

| Against | f15d7de3, off: by / on a match | **On: by / on a match** | Full by / on | First launch median | Wins, off to on | Share of brawls with his launch |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Easy | 9.35 / 5.44 | **63.00 / 9.62** | 4.03 / 1.78 | 1.9 s | 100% to 100% | 100.9% (6,300 in 6,242 brawls) |
| **Medium** | 11.23 / 9.41 | **44.67 / 17.20** | 3.37 / 5.35 | 3.9 s | **68% to 46%** | 88.9% (4,467 in 5,023 brawls) |
| Hard | 5.18 / 19.73 | **12.08 / 51.20** | 4.42 / 18.22 | 28.9 s | 0% to 0% | 29.4% |

- **Every launch of the route now counts, and most are not full.** The route launches 44.67 times a match at medium, of which **3.37 are full**. Full launches by him are 3 to 4 a match against every level; on him, from 1.78 at easy to 18.22 at hard.
- **The route's win rate at medium falls from 68% to 46%.** Game Design's edges are at most 80% and 0 to 25 points over the same script's masher. The route is inside the 80% (it is far under it). **The masher was not run on this build**, so "0 to 25 over the masher" is not read; the route's own win rate dropping 22 points is the sign to read it for.
- **The old rows break.** "The route launches in 50 to 75% of the brawls" divides launches by brawls, and with launch anywhere a brawl holds many launches (100.9% at easy, 88.9% at medium); "launches a match by him 4 to 10, on him 4 to 8" reads 44.67 and 17.20. Those bands were ruled for the launcher of window 1. **They need re-banding or retiring for launch anywhere; it is Game Design's call.** Their statuses in the run (FAIL) are not findings about the build.
- **The launcher always lands:** 5,405, 3,858 and 752 launchers used at easy, medium and hard, none lapsed.
- **Still first-launch fast:** 99 and 100 of 100 matches inside 30 and 60 s at medium.

## Not read

- The route's masher on this build (the 0 to 25 points over it), and the route on 200 matches (the 80% edge is read on 100).
- AI against itself (the 6 to 12 full launches, L16): it is read from the default arm, which was not run.
- The spammer and the varied route (L13 to L15): their scripts are not built.
- A variation of the link's length or the newcomer's timing.

Saved jobs: `mla.json` in my scratch (the five jobs, with the `launch_power` counts).
