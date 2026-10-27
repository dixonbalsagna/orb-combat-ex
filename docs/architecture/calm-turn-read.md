# The calm turn's ring read on gen 2: k, or a lazy read (paper)

Owner: Simulation and Engine. 2026-10-26, on the EP's question from World's gen 2 read-speed work (`docs/world/gen2-read-speed.md`). The build is parked at `pending/calm-k/` (§6).

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

Game Design accepted it (`rulings-2026-10-26.md` item 28), with each warm begun at the earliest moment its choice is known.

- **`K`: the columns read a tick across all the warmed rings, in the state** (`E.next.k`, set at the pick from data). One ring reads `K`; two rings read `K / 2` each.
  - Today Encounter shares a budget of 16 to 32 a tick between the rings (`DirCalm._rate`: a landing's two at most 16 each, a form step's one up to 32), so at 32 a tick a gen 2 read is about 44 ms at x6.
  - **The first value: `K` = 12.** About 16 ms a tick at x6, 10 at x4, 0.7 native.
- **What it does to the warm:**

| Pick | Today | `K` = 12 | `K` = 16 |
| :--- | :--- | :--- | :--- |
| A form pick, one ring, Half | 75 ticks at 32, 1.25 s | 200 ticks, 3.3 s | 150 ticks, 2.5 s |
| A form pick, one ring, Whole | 150 ticks at 32, 2.5 s | 400 ticks, 6.7 s | 300 ticks, 5 s |
| A launch pick, two rings, Half | 150 ticks at 16 each, 2.5 s | 400 ticks, 6.7 s | 300 ticks, 5 s |
| A launch pick, two rings, Whole | 300 ticks at 16 each, 5 s | 800 ticks, 13.3 s | 600 ticks, 10 s |

- **When the warm begins** (item 28):
  - a launch's at its throw, which is the send (`DirCalm.atSend`), as now;
  - a form step's at its ready tell (`SimFx.transformReady`), not its pause. The pivot is then predicted (the pair may move before the step), so World's smallest bearing is warmed as the fallback, as a landing's is.
  - A warm not done by its moment waits for the next one (Encounter's rule).
- **Determinism:**
  - `K` is in the state and comes from data, so it is the same on every platform;
  - a ring is warm when `cols` reaches its length, a count of ticks since the pick;
  - nothing a host does moves it.
- **Gen 2 only.** On a gen 1 planet the pick passes today's rate, so the reads are the same to the bit.

## 4. World's interface for it (World's park)

- **`data/biomes/rings.json` `turn.warmTotal`** (0 or 1, default 0). At 1, `WorldEpoch._warm` reads `k / E.warm.size()` of each warm ring a tick: `E.next.k` is the total.
- **`_warm` reads each ring to its counted columns** (`RingJob.readTo`).
- **`WorldEpoch.readAhead(S, units, colUnits = 3)`:** a host's idle time steps the warm jobs further ahead, so the sim's tick reads nothing. It touches no state. It helps where there is idle time (x1, x4), not on the phone tier, where `K` does the bounding.
- **`WorldEpoch.warmPlan(S)`:** the warm's plan, for a host or a HUD.
- **The carry-zone skip is declined** (World): it saves 8%, not the 31% this page first said, and it changes the swap.

## 5. The worst tick

- `_prep` was not the worst tick. At `K` 12 shared, the worst was the tick when two rings finished their read together (8 ms native).
- World moved the blend and the held places into the preparation's first two ticks, to the bit. The worst is now 4.4 ms native, and `prepTicks` stays 6.

## 6. As built (`pending/calm-k/`, on World's gen2-read-speed-b, on main since cb42a242)

- **World** (`grant_world.py`):
  - `turn.warmTotal` 1;
  - `WorldEpoch._share` shares `k` on a gen 2 planet only (the step binds the match's generation), so **a gen 1 pick is as it always was, its hash included.**
- **Encounter's lines** (a grant):
  - on a gen 2 planet the pick passes `calmTurn.warmColsGen2` (12) in all, whatever the lead: the total under `warmTotal`, else each ring's share;
  - `DirCalm.totalK(S)` says which, and the waiting pick's rate (`warmRate`) divides by the rings only then;
  - a form step's pause on gen 2 asks only if a new ring could be warm at `K` by its end;
  - `DirCalm.atReady` asks at the ready tell, with a predicted pivot and the fallback ring.
  
  On gen 1 every line takes today's path.
- **Mine:** the ready tell calls `DirCalm.atReady` (`SimFx.transformReady`), and parity's "the calm turn on gen 2".
- **Tools:** `calmTurn.warmColsGen2` and `turn.warmTotal` in their schemas.
- **Measured** (native, on 9490ac21; 4 AI matches of 3 minutes on a gen 2 Half ring, QA's calm probe):
  - the same 3 turns (1, 1, 1 and 0 a match), one of them from a ready tell; none bad, none cold;
  - every ask at 12 (before: seven at 32, one at 16);
  - the worst tick while warming 4.6 ms (5.0 before), the mean 0.45 ms (0.44 before);
  - the ticks held for warming 1,435 (643 before).
- **Gen 1:** four AI matches with the calm turn on hash as HEAD does, every 600 ticks and at the end. World's `calm_digest` with `warmTotal` 1 gives the base's gen 1 lines without it.
