# The calm turn's ring read on gen 2: k, or a lazy read (paper)

Owner: Simulation and Engine. 2026-10-26, on the EP's question from World's gen 2 read-speed work (`docs/world/gen2-read-speed.md`, parked in `docs/world/pending/gen2-read-speed/`). Paper only.

## 1. Where the cost sits

- **The read.** A decided turn's rings are read in the sim's tick: `WorldEpoch._warm` reads `k` columns of each warmed ring a tick, with `k` in the state (`E.next.k`). Encounter sets `k` between `warmCols` 16 and `warmColsMax` 32 (`data/director/interrupts.json`). A form pick warms one ring; a launch pick warms two, the chosen and the 2.5° fallback.
- **When a ring counts as warm.** The state counts the columns read (`w.cols`), so a ring is warm on the same tick on every platform. The slices themselves are derived data outside the state (`WorldEpoch._jobs`).
- **What a column costs on gen 2:** 51 to 56 microseconds native (after World's cut), about 130 at x1 on the web. Performance measured one ring at `k` = 32 at 25.8 ms a tick at x4 and 43.7 ms at x6: about **0.8 ms a column at x4 and 1.35 at x6.** A launch pick reads two rings, so it costs double.
- **The budget** (Performance): no frame over 50 ms. A frame is already about 17 to 20 ms at x4 and about 30 ms at x6, which leaves **about 15 ms a tick for the read on the phone tier.**
- **The warm today, at `k` = 32:** a Half ring (2,400 columns) in 75 ticks (1.25 s), a Whole ring (4,800) in 150 (2.5 s), plus `prepTicks` 6.

## 2. Lever (b), a lazy read: not recommended

**The swap needs the whole new ring at once,** bar the carry zone (`carryUnits` 12,000 each way: 375 columns, so 750 of a Half ring's 2,400). It replaces the arena's ground, its places and its biome table beyond the zone in one tick, and its preparation (the carry weights, the slice hash, the fresh places' layouts, the blended ground) reads the ring.

So "the columns as the swap needs them" is about 1,650 columns of a Half ring on the swap tick: about 2.2 s at x6, about 90 ms native. **That moves the cost to the worst possible tick.**

The only lazy read that helps is a **progressive swap:**
- the near band swaps at the moment, and the far ground stays the old ring's until it is read, then changes off screen a band at a time;
- it is deterministic if the bands are counted in the state;
- but it redesigns World's swap and its places (fresh places laid late, buildings on ground that changes after the turn) and Encounter's hold;
- a fighter launched across the far side would land on the old ring's ground;
- **not for now.**

## 3. Lever (a), a lower k: recommended, as a total a tick

- **`K`: the columns read a tick across all the warmed rings, in the state** (`E.next.k`, set at the pick from data). One ring reads `K`; two rings read `K / 2` each.
  - A launch pick then costs the same a tick as a form pick. Today it costs double.
  - **The first value: `K` = 12.** About 16 ms a tick at x6, 10 at x4, 0.7 native.
- **What it does to the warm:**

| Pick | Today (`k` 32 a ring) | `K` = 12 | `K` = 16 |
| :--- | :--- | :--- | :--- |
| A form pick, one ring, Half | 75 ticks, 1.25 s | 200 ticks, 3.3 s | 150 ticks, 2.5 s |
| A form pick, one ring, Whole | 150 ticks, 2.5 s | 400 ticks, 6.7 s | 300 ticks, 5 s |
| A launch pick, two rings, Half | 75 ticks, 1.25 s (double the cost) | 400 ticks, 6.7 s | 300 ticks, 5 s |
| A launch pick, two rings, Whole | 150 ticks, 2.5 s | 800 ticks, 13.3 s | 600 ticks, 10 s |

- **For Game Design:** a launch pick's moment (the landing) comes within a second or two of the send. With a 5 to 7 s warm the pick waits, warming, for a later moment (Encounter's rule already). So **a launch's turn usually lands at the next calm moment, not the one the launch made.** A form pick's 3.3 s fits a pause better.
- **Determinism:**
  - `K` is in the state and comes from data, so it is the same on every platform;
  - a ring is warm when `cols` reaches its length, a count of ticks since the pick;
  - nothing a host does moves it.
  
  This is today's rule with a smaller number.
- **Who changes what:**
  - Encounter: the pick's `k`, a total split over the rings (its data's `warmCols` and `warmColsMax` become 12);
  - World: `_warm` reads `n / rings` of each ring (a line);
  - Game Design: whether the longer warm reads fine.

## 4. Two cheap additions (World's lines, same determinism)

1. **Skip the carry zone's columns,** if the swap never reads the new ring's columns inside the zone (World to confirm: the slice hash covers the whole ring today, so it would cover the read part). This saves 31% of a Half ring (750 of 2,400 columns) and 16% of a Whole one. A Half form pick at `K` = 12 drops from 3.3 to 2.3 s.
2. **A host's read-ahead.**
   - `_warm` reads each ring *up to* its counted columns (`readTo(cols)`) in place of *n more* (`step(n)`). A host with idle time in a frame steps the same jobs further ahead (`WorldEpoch.readAhead(S, budget)`), and the sim's tick then reads nothing.
   - The state's count is untouched, so warm-ness and the swap tick don't move.
   - It helps where there is idle time (x1, x4), not the phone tier, where `K` does the bounding.
   - Rendering's host would call it.
   - Threads would do more, but the web's threads need cross-origin isolation, and World's noise cache is not thread-safe.

## 5. Not the read

World measured the calm turn's worst tick (10 ms native) as **a swap-preparation step** (`WorldEpoch._prep`), not the read: about 60 ms at x6, over the budget on its own. Lowering `K` does not touch it. It needs splitting in World's `_prep`, and `prepTicks` (6) may need to grow with it.
