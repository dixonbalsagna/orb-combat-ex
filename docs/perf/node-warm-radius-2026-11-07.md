# Node warm radius: a bigger disc or earlier timing? (Performance and Platform, 2026-11-07)

The question (World, `docs/world/surface-memo.md`): a landing candidate is 20,000 to 40,000 units away and `warm.radius` reaches 10,000. Is a bigger radius, or an earlier warm, worth it?

**Answer: no. Leave `warm.radius` at 10,000 and build no earlier warm for the launch.** The launch tick's cost is not cold node reads.

**Measured.** I replayed Orb's third-play match (planet 7, 22,551 ticks, reproduces on every checkpoint) with `WorldField.reads` counted per tick (`docs/perf/tools/preplay/replay_reads.gd`, a copy of `replay_prof.gd` plus the counter and `--warm=<radius>`). Cold node reads are counts, not times, so machine load does not affect them. The page's load bake and the data's 10,000 disc were already in place.

| Where | Cold node reads |
| :--- | ---: |
| Whole match, 22,551 ticks | 6,197 (about 0.25 s in all at 41 us a node), 1,364 ticks with any, **at most 34 on one tick (about 1.4 ms)** |
| The 14 heavy ticks (12 launches and 2 others) | 0 to 34 each (692: 0 reads and 37 ms; 7768: 34 reads and 15 ms) |
| First 6,000 ticks, extra disc 20,000 | 618 down to 422; the one launch tick that read (832, 28 nodes) still reads |
| First 6,000 ticks, extra disc 40,000 | 618 down to 1 |

**What a bigger disc costs** (native, loaded PC, so ratios carry): the 20,000 disc takes 3.6 s at match start and the 40,000 disc 15.4 s (the 16,000 disc was 1.9 s in World's table; the web is 2 to 3 times slower again). A 40,000 disc saves 617 reads over 6,000 ticks, about 25 ms.

**So the 6.8 ms of launch time sits elsewhere:** the first read of a column's memo (`_fcol`: biome, the town test with its record scan, the fine biome), the candidate scoring and the flight predictions. None of those is a node read, which is why tick 692 costs 37 ms with 0 cold nodes. World's own numbers agree (41 us a cold column, 2 to 3 us a warm one).

**If an earlier warm is still wanted for the memo,** it would be a warm of the `_fcol` columns along the swing line (a strip, not a disc), read a few ticks before the offer. Not measured and not recommended without a quiet-window measurement of the launch tick: it would need the first-launch 23 ms (cold) against the later launches (11 ms) split into column-memo cost and the rest.

**Limits:** one match, one planet (7), 12 launches; counts only, no timing (the machine was at about 88% load). Nothing in the repo or World's files was changed.
