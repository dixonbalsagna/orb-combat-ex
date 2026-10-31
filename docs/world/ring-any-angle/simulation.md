# The turntable: what the sim has to know during a swing (Simulation, research only, 2026-10-31)

Orb picked the turntable, E and E2: the world visibly swings round the fighters. Nothing is built and no tree was edited. Probes ran in scratch copies of HEAD e8a95e35 and a8b4a5c9. **This section replaces the recommendation of 2026-10-30 below** ("sparse first, a road only for a visible curve), which assumed a change nobody sees. Its findings on `W`, `sdx`, trig and rounding still hold.

## The answer

1. **A swing needs exact ground only near the fighters, and it needn't re-lay anything.** 80% of the sim's ground reads land within 3,000 units of a fighter. The rest are forecasts, scores and off-screen effects that can take coarse ground, plus 31 lines that write marks or water.
2. **Build the narrow strip, as a read-through.** `groundY` reads the field through the frame for the columns actually asked for, a mean of 10 a tick. That costs about 0.1 to 0.15 ms a swing tick, inside Performance's 0.2 ms. Re-laying the view's 669 columns costs 3.6 ms.
3. **Readers can't keep the strip arrays rebuilt on each relay.** World asked; the numbers say no (below). The 77 `groundY` sites need no change anyway, because `groundY` is one function.
4. **The sim's plane must read the same nodes and the same triangles as the drawn mesh.** Today's ring columns miss a 128-unit mesh by up to 232 units on gen 2.
5. **A standing fighter just rides the ground.** The most it rose in the probe was 3.8 units a tick at Game Design's 75 u/s, under the 7.5 cap on every sample.
6. **A whole-planet bake at load is safe for determinism on every build we can test.** It's a pure function: same bits in any order, after any match, in two processes, native and web (section 7). It needs one rule the EP's decision doesn't state yet: which level a read uses must never depend on what's ready.

## 1. Who needs ground beyond the pair's reach

**The 639 are now 642, and only 165 are the sim's.** 381 are in tools, tests and QA, and 96 in the views (render 93, audio 3), which I counted but did not audit by site: what they draw is Rendering's section.

| The sim's lines | `groundY` (77) | `S.base` (88) | All |
| :--- | ---: | ---: | ---: |
| **Near only:** a body's own feet, contact, brawl, cover, AI at a fighter | 41 | 0 | **41** |
| **Far, coarse is fine:** forecasts, scores, off-screen effects | 32 | 6 | **38** |
| **Far and exact:** writers of marks and water | 2 | 29 | **31** |
| The read itself (`groundY`, `seaAt`, water's column read) | 2 | 12 | 14 |
| Builders: run at a match's start or a turn's swap, not by a fight | 0 | 33 | 33 |
| Comments | 0 | 8 | 8 |

**How it was counted.** Every call in a scratch copy recorded its distance from the nearer fighter, over 7 AI fights of 7,200 ticks on gen 2 rings: 1.74 million reads, plus the `floorAt`, `surfaceAt` and `seaAt` wrappers. 82 of the 201 instrumented sites ran, and I classed the other 119 by reading them. There was no swing in these runs, and they were AI fights, not human ones.

| Reads within | All | The exact writers (890,000 reads) |
| ---: | ---: | ---: |
| 1,500 units | 67.0% | 62.8% |
| 3,000 | 80.4% | 87.4% |
| 6,000 | 89.6% | 99.6% |
| 12,000 | 95.8% | 100% (furthest 6,350) |

**Distinct columns read a tick:** mean 10.3, p50 4, p90 22, p99 168, max 1,013. Of those past 3,000 units of both fighters: mean 1.8, p99 39, max 561.

**The far readers, by weight:**

| System | Lines | Reads past 3,000 | Furthest | Why coarse is fine, or why not |
| :--- | ---: | ---: | ---: | :--- |
| A building's base (`structures.gd`) | 3 | 128,669 | 12,198 | Recomputed at every read, stored nowhere |
| Water flow, digging, lakes, fills, aftermath | 31 | 112,571 | 6,350 | **Exact today:** they write state from the ground beside them. These become records (World's 8.4) |
| Location tables (`location.gd`) | 1 | 88,506 | 70,857 | "Land, not a crater lake" |
| Line of sight (`hiding.gd`, parked) | 1 | 4,211 | 17,846 | A yes or no; hiding is parked |
| Launch planner and its slope and water reads | 11 | 4,995 | 38,340 | A score; the flight itself reads near |
| Brunt's and a flight's forecast | 3 | 1,333 | 10,169 | A forecast |
| Shots in flight, a shot's blast | 6 | 1,205 | 36,806 | Off-screen; a mark becomes a record |
| A beam's groove and aim | 2 | 96 | 12,343 | Game Design ends a swing before a beam, so neither runs in one |
| Fire, tree damage, cosmetic events | 11 | none reached it | | Height for an effect |

**Say how big, as World asks:**

- **The far-reader audit is 69 lines, and this table is its first pass.** The 38 coarse lines sit behind about six functions: `predictFlight` and `_propFlight` (Encounter's), the location table, `baseY`, a shot's floor and line of sight. One window with Encounter. The 31 exact lines are 5 modules that World's 8.4 already turns into records; one to two windows with World.
- **Far ground for the planner and long beams:** a coarse field at 512 units misses true gen 2 columns by RMS 17, p99 58, worst 235 (below). Fine for a score. A forecast can land a little off, so nothing may treat one as a promise.
- **The pose move is small: one window.** `Building.x` and `.z` are already properties that read `g.x`. Pointing them at bound arrays `S.bX` and `S.bZ` takes about 30 lines in `state.gd` and its restore hook, the way `bHp` works. The 194 `b.x` and `b.z` reads in 30 sim files and the 38 shipping files that read `S.buildings` don't change. Trees do the same. Snapshot: 16 bytes each, +2.8 KB on this ring. With the switch off the arrays hold the generated values, so the golden holds, to be proved by regenerating it.
- **`bIdx`** says it never changes in a match, which ends here. A whole re-index is 0.13 ms and a whole re-pose 0.23 ms for 177 structures, together past the 0.2 ms budget. So pose and index only what's within a window, about 0.05 ms by proportion, and bring a far building up to date when something reads it.

## 2. Three shapes, ranked

All natively, on a gen 2 Half ring. Budget: 0.2 ms added a tick (Performance); 12.5 ms a rollback frame (Netcode). A swing tick's fight work is otherwise unchanged. Measured pieces are in section 5; the sums are arithmetic.

| | **1. Narrow strip, read-through** | Narrow strip, re-laid (±40 to ±75 columns, two windows) | 2. Strip re-laid as E does (669 columns) | 3. True 2D sim |
| :--- | :--- | :--- | :--- | :--- |
| **Added a swing tick** | **0.1 to 0.15 ms mean**, p99 0.7 | 0.8 to 1.4 ms | **3.6 ms** (18 x the budget) | 0.12 ms, on every tick |
| **Laptop, x4** | 0.4 to 0.6 ms; a planner's worst tick 15 ms | 3 to 6 ms | 14 ms | 0.5 ms |
| **Rollback frame, depth 6** (no swing: 3.7 ms) | **4.8 ms** | 9 to 14 ms | 29 ms | 4.6 ms |
| **Depth 13** (no swing: 6.8) | 9 ms | 18 to 26 ms | 57 ms | 8.5 ms |
| **Snapshot, first cut** (today 82 KB) | About 113 KB | About 113 KB | About 113 KB | About 35 KB |
| **What changes in the core** | `groundY`, the frame, poses | Those, plus incremental derived tables | Those, every tick, whole | 1,335 wrap sites, 642 reads, every director plan |
| **Migration** | Medium: several windows | Medium | Small, but it can't ship | A new world layer |
| **Reads through `S.base` directly** | 31 become records, 6 go coarse | The same | Can stay | All go |

**Why that order.**

- **Read-through wins** because a swing changes what a column would hold, not what the sim asks for, and it asks for few. It meets Netcode's condition (re-lay only what the sim reads) better than a fixed width, and a re-run costs what the straight run did.
- **The re-laid narrow strip fits only at a shallow rollback.** At 3.6 to 3.8 µs a column, 0.2 ms buys 55 columns a tick. World's ±40 is 162. It's useful as a stepping stone, not as the target.
- **Re-laying as E does is out for good.** World's question is answered in section 3.
- **A true 2D sim is cheap to run and buys nothing play asked for.** Game Design's rulings keep fighters, gaps and velocity on the line, and Rendering's tiles give the true 2D picture without it. Its cost is the migration. Reconsider only if Orb wants fighters to leave the line.

**Snapshots.** 113 KB is today's 82, `S.base` out of the shared list (+9.6), the store at its 400-record cap (+19), poses (+2.8), the frame and swing (under 1). A Whole ring is about 185 KB. A take is one copy per packed block, so this adds microseconds. Dropping the column arrays from the snapshot later (the store holds the marks) gets to about 35 KB, but it needs the 35 `S.deform` and 33 `S.water` lines moved too. **No history in the state,** as Netcode says.

**Rollback's memo.** The field's nodes are a pure function of the planet and a node key, kept outside the state like `WorldEpoch._jobs`. A re-run reads no noise, and a view that fills a node first changes no sim bits, so a view may share the store without writing the sim.

### By Game Design's rates

A swing tick costs the same at any rate; only exposure changes. A 7-minute match is 25,200 ticks.

| | Swing ticks | Read-through, added over the match | E's re-lay, added over the match |
| :--- | ---: | ---: | ---: |
| 10 to 15% of fight time | 2,520 to 3,780 | 0.3 to 0.6 s | 9 to 14 s |
| **Launches only, about 12 s** | 720 | **0.1 s** | 2.6 s |

**Launches only doesn't rescue E:** every one of its 720 ticks is still 18 times the budget. It does remove the standing ride and the face backstop, since a flying fighter has neither, and the brawl's slow swing, which is Game Design's open question for Orb.

### Noise reads, at Performance's 1.5 columns a tick on the web laptop

**Arithmetic, and checked against the probe's counts where a probe ran.**

- **A swing in place reads nothing new once the nodes are there** (Performance's point). Filling a line's own nodes as it first turns costs what's in section 5.
- **A flight is what reads.** Line-only, a body flat out at 171 u/tick crosses 171 / G cells and needs about 2 new nodes a cell: 2.7 a tick at 128 units (over), 1.3 at 256, 0.7 at 512. So a flying body reads 512, a grounded one 128 within about 1,200 units, and idle ticks fill ahead. Both flat out, at 512, is 1.3: it just fits.
- **Whole disc round a swinging line** if the sim ever needed it, per tick at the first pass, `r² x dθ / G²`: at 60°/s, 1.5 reads holds r to 1,187 units at 128 and 4,746 at 512; at 10°/s, 2,907 and 11,627. The probe's first-pass counts at 30°/s came in at about 70 to 85% of this formula. That's World's and Rendering's budget more than the sim's.

## 3. World's questions

**Can readers keep the strip arrays, rebuilt from the store on each relay? No, not on these numbers.**

- 669 columns from a resident field with 23 marks: 2.5 ms. `WorldWater.init` 0.35, poses 0.23, `bindStructures` 0.30, index 0.13, `popHist` 0.09, lanes 0.02: 1.1 ms more. **3.6 ms a tick**, 14 ms at x4, and that's before any fight work.
- 2,400 columns (the whole Half strip): 8.5 + 1.1 = 9.6 ms.
- It would also wipe water: `WorldWater.init` restarts the flows each relay.
- **It does hold at rest and for the strip's near part,** so the arrays can stay as the at-rest store, with `groundY` reading through the frame only while a swing runs.

**The state-hash line: yes, it's mine.** A swing adds a block to `hash.gd` beside the epoch's (line 234), only while the swing's state exists, so a match without it hashes as before and the golden holds:

- the frame: point, heading and column, as bits;
- the swing: bearing to go, cause's rate, ease;
- **the store's length and a running hash of its records.** World says length; length alone misses a record with a wrong value.

`stateHash` already skips `S.base` and hashes `S.deform`. Once `deform` is derived it's a slower way to check the same thing, but harmless, so it can stay until it shows up in a profile. `NetDesync.digest` needs the same block (Netcode: `PROTO` 4). The digest is 0.18 ms and `stateHash` 11 to 17 ms, and only tests and desync reports use the latter.

## 4. Rendering's questions

### Does the sim's plane match the drawn plane?

**Only if both come from one source, and on gen 2 that isn't today's ring.** Land columns, 4 planets, 24 lines at each spacing, heights in units; a fighter is about 75 tall:

| Compared | 128 u nodes: RMS, p99, worst | 256 u | 512 u |
| :--- | :--- | :--- | :--- |
| **True gen 2 column against the mesh** | 8.5, 19, 239 | 22.8, 72, 384 | 17.3, 62, 234 |
| True column against bilinear on the nodes | 7.4, 17, 232 | 23.2, 70, 384 | 16.6, 58, 235 |
| Bilinear against the mesh's two triangles | 1.8, 5.0, 72 | 5.3, 21, 94 | 5.9, 24, 69 |
| The sim's 32-unit linear read of mesh columns, against the mesh | 0.54, 1.9, 17 | 0.53, 2.6, 11 | 0.26, 1.2, 7 |

The lines differ by spacing, so read across a row with care: 256 happened to cross rougher ground than 512. **Gen 2 is far from Research's gen 1 floor** (0.7 RMS, 17 worst at 128 units). This is the first gen 2 measure of it, and World's 8.1 expected worse at creases.

**What the sim must do:**

1. **Ground comes from the field all match, not only in a swing.** Otherwise a swing's first tick drops him onto a surface up to 232 units from the one he stood on. That makes it a new generation behind a switch; with it off, the golden holds. It moves every gen 2 hash with the switch on, and it needs a detail term if the 128-unit relief looks too smooth (Rendering's point, and that term must be one pure function on both sides).
2. **Same interpolation, same diagonal.** Bilinear against triangles alone is 72 units worst. The sim reads the mesh's triangle at `x` rather than a column, which removes the 32-unit row too. It's the same arithmetic as the probe's triangle read.
3. **Then agreement is float32 rounding,** about 0.001 units at these heights, by construction. I haven't run a CPU twin against the shader; test 3 in Rendering's section is that check.
4. **Watch the texture's format.** Performance notes R16F filters in hardware. A half-float at height 6,500 steps by 4 units, which is enough to lift feet in the mountains. Use the hand bilinear on 32-bit values.
5. **The sim's line must be a great circle in a field world.** A Half ring today is a small circle, and Rendering's projection keeps arc lengths only along a great circle through the pivot. `W` and `NC` stay fixed as a ring buffer of the line (below). Both panes read one frame from the sim, and the view never writes it.

### How does a standing fighter ride rising ground?

**As he does now: his height is the ground's.** `floorFor` and the down state set `f.y` to the ground each tick. Nothing new is stored, `vy` stays 0, no landing fires, and his stick is untouched, which is Game Design's "adds no velocity". It rolls back with `y`, as today.

**The cap didn't bind.** The slope across the line, sampled on 7,024 land columns of 40 lines on 4 planets: p50 0.11, p99 2.2, worst 3.05. At Game Design's 75 u/s (1.25 u/tick):

| Rise a tick | p50 | p99 | Worst | Over 7.5 |
| :--- | ---: | ---: | ---: | ---: |
| Bare gen 2 ground | 0.14 | 2.8 | 3.8 | **0** |

Rendering's "4 units a tick" is at 523 u/s, which Game Design's limit no longer allows. Craters, heaps and building pads were not in this sample, and their edges can be steeper.

**So the 7.5 cap needs a backstop, not a new body rule:**

- **Over water,** `floorFor`'s existing rule already rises at 7.5 a tick.
- **On land it can't.** `floorFor` never returns below the ground, and letting him sink would break Rendering's foot test. So the swing slows instead: each swing tick, read the ground one tick ahead under each standing fighter, and scale the rate so the rise stays within 7.5. That's 2 to 4 reads a tick, deterministic, and it's the same shape as World's rate cap at a building's face (9.3). It's what "never refuses, it slows" means here.

## 5. The owed timings

Native, Windows x64, one job at a time. **Load 28 to 39%,** after Performance's window, so these are valid under the rule of 2026-10-12. Gen 2 Half ring of planet 7, idle fighters unless stated.

| | p50 | Worst |
| :--- | ---: | ---: |
| A gen 2 column on this ring | 27 to 28 µs | |
| **Swap tick,** 2.5° | **4.1 ms** | 4.4 |
| Swap tick at 90° and 180° | 3.8 to 4.0 ms | 4.2 |
| Warm tick at k 12 (swap every 205 ticks) | 0.65 ms | 3.9 |
| Warm tick at k 240 (every 15 ticks) | 7.4 to 8.3 ms | 17.6 |
| A cold swap every tick | 104 ms | 125 |
| Snapshot take / restore | 0.25 / 0.65 ms | 10.8 / 0.85 |
| **Rollback of 21 ticks over a swap, pick outside the window** (0 columns) | **5.9 ms** | 7.8 |
| **The same, pick inside** (2,400 columns: `choose` drops the job) | **106 ms** | 114 |
| `stateHash` / `NetDesync.digest` | 11 to 12 / 0.18 ms | 16 / 0.25 |
| The rollback bench, gen 1 planet, 1,200 ticks: tick / take / restore | 0.19 / 0.18 / 0.23 ms mean | p99 0.62 / 0.28 / 0.35 |

All 20 rollbacks gave the same state as the straight run. **My column here is half World's 54 µs.** This ring is cheaper than the mix World measured, so the page's 130 ms for a ring is conservative; the measured whole-ring tick above is about 100 ms.

**A swing's pieces:**

| Re-laid from a resident field, with 23 marks, at 30°/s | Warm tick, p50 | New noise reads a tick, 128 u / 512 u |
| :--- | ---: | :--- |
| 188 columns | 0.64 ms | 7 / 0 |
| 376 | 1.45 ms | 26 / 2 |
| 669 (E's view) | 2.5 ms | 98 / 7 |
| 2,400 | 8.5 ms | 730 / 47 |
| 4,800 | 16 ms | 1,449 / 92 |

The array work is 3.4 to 3.8 µs a column at either spacing; the ms column is at 512 u, and new reads at 128 u add to it (669 columns: 4.1 ms). That's a GDScript figure, where Research's 1.7 to 3 ms was a guess from JS, and it lands inside that range. The read-through's sum is 10.3 columns x 3.6 µs, plus near poses and index. The planner's worst tick, 1,013 columns, is 3.6 ms, inside the 8 ms spike allowance. Both are arithmetic from these pieces, not a run of a read-through, which doesn't exist.

## 6. What this leaves open

- **Nothing here has run a swing in the real sim.** The read counts come from fights without one, and a read-through isn't built.
- **Water in a swing.** The 31 exact lines become records only with World's 8.4. Until then water beyond a window has no honest answer, and `WorldWater.init` can't run per relay.
- **Web parity on the field's read.** The bake passed (section 7). The triangle read at `x` is plain arithmetic on proven math, but it hasn't been through the web check.
- **Laptop figures are x4 of native,** Performance's stand-in, not a measured laptop.
- **Human fights** may read differently from AI ones.

## 7. The EP's provisional route: the field defines the ground, with a bake at load

The decision: the field is the ground, a pure function of the planet at a fixed canonical spacing that the sim and the renderer both read, with a whole-planet bake at 512 carrying flight. The probes ran on a scratch copy of HEAD 2bb581ab at below-normal priority, so the times are a rough guide.

### Is a bake at load safe across machines?

**Yes on x64 native and x64 web, and the bake makes any other build's difference show up before the first tick.**

| Test, planet 7 unless stated, 34,656 nodes | Result |
| :--- | :--- |
| Baked twice, and in a second process | Same hash |
| In reverse order | Same |
| Another planet read between the nodes, generation flipped and bound back | Same |
| After a gen 1 match on another planet | Same |
| Native against web (Chrome 156): planets 7 and 3 at 75 cells a face, 25 at 150 | Same bits |
| The 904 nodes that face edges hold twice or more | 0 differ, so the ground is continuous across faces |
| **Controls:** one node one float32 step off; gen 1 asked for by name | Both change the hash |

All 45 golden keys passed in the same web run.

**One control didn't do what I expected.** Leaving the generation unbound during the bake changed nothing, because a read follows the planet object it's given. The generation matters when the planet is made: `WorldPlanet.make` keys on the static `WorldClimate.curGen`. So the bake has to bind the generation before `make`, as the planet load's job already does.

**Cost, measured natively:** 38 to 42 µs a node, 1.3 s a planet. **Memory:** 135 KB of float32 heights and 34 KB of biomes. Distinct nodes are 33,752 (World's 28,650 is by area). At Performance's 130 µs that's about 4.4 s on the web, and about four times that on the laptop by its x4 stand-in. Those two are arithmetic, and that load time is Performance's to rule on. Rendering's far map already spends 65,000 reads on the same job, so one bake serving both would be cheaper than today's far map.

**The rules that keep it safe:**

1. **Whether the bake is done is never a sim input.** It finishes before tick 0, through `SimPlanetLoad.mayStart`. Peers wait at the handshake, and a slow machine waits longer but gets the same bits.
2. **Which level a read uses is fixed by the reader, never by what's ready.** A read that takes the finer level when its node happens to be there, and the bake otherwise, gives two machines two grounds, and that's a desync. So: near readers always read canonical, computing a missing node on the spot. The 38 coarse lines always read the bake.
3. **No bake on disk in the first cut.** `user://` is shared by every copy on the PC, which is the clash that made parity's fixtures fail. A later cache must be keyed by the data hash and the engine version, and checked.
4. **One thread.** The web has no threads, and `P.outH` and the `_vc*` noise caches aren't safe to share. A native worker would need a `Planet` of its own. Slicing is safe: order doesn't matter, as tested.
5. **The bake is immutable and outside the state,** keyed by seed and generation. Snapshots never touch it, and two sims can share it. The view reads it and can't write it.

**Not proven:** ARM (macOS on Apple silicon is a target), Firefox, Safari. This is the same gap as the rest of the sim, and the match key below gives it an early check.

### What it does

| | With the switch off | With it on |
| :--- | :--- | :--- |
| **Strip** | Unchanged | A view of the field, not a source. `W`, `NC`, `x` and the wrap math stay, as a ring buffer of a great circle. No ring read at match start, and no swap: a whole strip laid from the field is 8.5 ms with no noise. The 33 builder lines go or move: platforms, lakes and rivers become planet-keyed (World's 8.1), because they plan on one line today |
| **`S.base`** | Shared, as now | Not state. `groundY` reads the field through the frame. The 6 coarse lines read the bake, and the 31 exact lines become records |
| **Digest** | Unchanged | `NetDesync.digest` folds the frame, the swing, and the store's length and running hash. The bake isn't in it. Netcode's `PROTO` 4 |
| **Match key** | Unchanged | **The bake's hash joins the match key.** Two builds that bake differently are refused at the handshake, not left to desync minutes later |
| **Golden** | **Byte-identical, to be proved by regenerating** | New keys: each of 3 planets' bake hash, tick-0 states, one AI match. About 4 s more to generate. Gen 1, hand-made and gen 2 keys don't move |
| **Replay** | Unchanged | No format change. Spacing, face count and field version join `WorldPlanet.dataHash`, so a replay on another field is refused |
| **Parity** | Unchanged | A new check: the bake's hash, order against reverse, a field match same twice, near and coarse reads each from their own level. `web_parity` gets the bake keys, as this run did. `replay_xproc` and `two_states` then cover a bake in a fresh process and one shared by two sims. No fixtures are written |

**Make it gen 3.** `setup.planetGen`, `genFor` and `dataHash(gen)` already separate generations, so a field world is `planetGen: 3`, and gen 2 and its replays keep working beside it. `make`'s key is `seed * 4 + gen`, so 3 fits and 4 wouldn't.

**The field's error against today's ground stops being an error,** as World says: nothing compares the field with the old planet any more. Its creases and steps get smoothed into a new, smoother planet, and that's a look for Orb.

### Does the sim starve at 1.5 reads a tick?

**No. The sim reads a line, and World's starving field is a disc for the view.** Near reads taking 128-unit nodes along the line, far reads taking the bake, over the same 7 AI fights, 50,400 ticks:

| New 128-unit nodes a tick | Mean | p90 | p99 | Worst |
| :--- | ---: | ---: | ---: | ---: |
| The sim's own near reads | **0.058** | 0 | 2 | 66 |

That's 2,920 nodes in all. The worst tick is 3.6 ms natively at 54 µs, or 8.6 ms on the web, about the 8 ms spike allowance. **No swing ran in this count.** Arithmetic for one: a standing fighter's line moves 1.25 u/tick, so a new cell about every 100 ticks. A flying one 6,000 units from the pivot at 60°/s moves 105 u/tick sideways, about 1.6 nodes a tick at 128 (just over, before his own flight's 2.7) and 0.4 at 512. A flying body has nothing at his feet until he lands, so he can read the bake until he's within reach of the ground, if that rule is the same on both peers.

### The one conflict left

**"Both read it" and "the view sharpens later" can't both hold at a fighter's feet.** World's 11.3 has the view's disc refining over seconds after a landing. If the sim reads 128 at his feet while the view still draws 512, the two differ by World's 512 row, RMS 23 and up to 319 units. Three ways out:

| Option | The sim | The feet | Cost |
| :--- | :--- | :--- | :--- |
| **A. One canonical spacing, the bake** | Reads only the bake. Zero noise reads in play, and the simplest route by far | Always agree | Ground as smooth as 512 everywhere, unless a pure detail term runs on both sides. A look for Orb |
| **B. 128 canonical, view offsets the feet** | Reads 128 near, as counted above | The view draws him on its own ground until it sharpens: a cosmetic offset, and rendering still writes nothing | Effects at his feet need the same offset. Rendering's foot test would pass by construction, so it needs a tighter wording |
| **C. 128 canonical, a small tile forced at landing** | The same | Agree | About 256 nodes in one go is 33 ms on the web: 4 x the spike allowance. A launch's flight could read ahead, as World's 96 ticks and 144 nodes suggest, but that doesn't reach it |

**My call for the sim: determinism is equally safe in all three, and A is by far the cheapest.** I'd build the sim's read so that the spacing is one data value, try A first, and let Orb judge the look, since B can be added later without changing the core's shape. The choice is the EP's and Orb's.

## What the sim keeps from the page of 2026-10-30

The rest of this page is the earlier report. The columns as a ring buffer, the statics, wrap math, trig and rounding results all still apply, and a field world's line uses that buffer. Its option table and "build first" do not.

---

# A bearing change at any tick: what the core needs (Simulation, research only, 2026-10-30)

For the EP, on Orb's ask. Nothing is built and no tree was edited. I ran throwaway probes in a scratch copy of HEAD f19a3523, on a gen 2 Half ring of planet 7. The probes use the real turn code with its caps lifted in memory, plus a small prototype of a curved road. World's and Netcode's pages cover the ring read's cost and the online rules; this page covers the core.

**How to read the numbers.** The machine sat at 74 to 100% load, so under the rule of 2026-10-12 I report none of my timings. Costs here are counted columns x World's quiet figure, 54 µs a gen 2 column natively. Counts, states and bits don't depend on load.

## The answer

1. **The core does not block any angle or any tick.** A real swap ran on every tick, at 180° and in the middle of AI fights. The state was the same both runs, with no script errors, and the two runs I compared matched between native and web.
2. **What blocks it is the columns.** A whole-ring change every tick is 2,400 columns a tick (130 ms). It can't ship.
3. **A curved road can change every tick,** at 12 columns a tick (0.65 ms), the rate already budgeted. `W`, `NC`, `sdx` and `wrap` stay exactly as they are.
4. **A curve only changes the ground ahead.** A pair standing still never reaches it, so the large steps Game Design wants still need a swap. The two work together.

## The three options

| | Whole ring every tick | Sparse swap (today's turn, caps off) | Curved road |
| :--- | :--- | :--- | :--- |
| **Change rate** | Every tick | One per 205 ticks at `K` 12 (3.4 s). Counted: 80 at k 32, 43 at 64, 24 at 128, 15 at 240, 10 at 480. The floor is 6 (`prepTicks`) | Every tick, at the road's front |
| **Columns a tick** | 2,400 (counted: 60,000 in 25 ticks) | 12 | 12 (6 a side) |
| **Cost a tick, native** | 130 ms, plus the preparation | 0.65 ms, plus the swap tick | 0.65 ms, ground only |
| **What moves under a fighter** | Everything outside the kept zone, every tick | The same, once, at a known moment | Nothing he has reached: only the road ahead |
| **A rollback of 21 ticks** | 50,400 columns (2.7 s) by arithmetic | 0 columns if the pick is older than the window; a whole ring per pick if it's inside (below) | 252 columns (13.6 ms) with no cache, 0 with one |
| **Prototyped how far** | Real swap | Real swap | Ground heights only: no places, buildings, carry or view |
| **My call** | Refuse | **Build first** | Build only if Orb wants a visible curve |

6 columns a side is 192 units a tick, and a flat-out dash is about 171. So the road's front outruns any free flight, by 12%. I haven't sized a long rush against it.

## `SimConst.W` and `NC` as statics

**Keep them fixed for the match in all three options.** A change of bearing never needs a change of length.

- **Shipping code outside tools reads them often:** `W` 56 times, `HALF` 23, `NC` 185, `COL` 178, `sdx` 616, `wrap` 343. None of those change.
- **The statics are already safe.** `step()` rebinds them when another sim has run (the conditions in `arena-conditions.md`).
- **Changing `W` mid-match is refused.** A curve whose length changed would have to resize the per-column arrays and rescale every `x` and the `DirLocation.STEP` buckets on each change, and it buys nothing that a fixed-length buffer doesn't give.

## Shortest-arc math if the path isn't a closed circle

**Make the columns a ring buffer of the road.** `x` stays in `[0, W)`, and column `i` holds the newest road point whose distance along the road is `i x COL` modulo `W`.

- **`sdx` stays exact along the road** while two bodies are less than `HALF` apart, and that is the same limit as today. It measures road distance, never planet distance. The fight code has never asked for planet distance.
- **The old and new road meet opposite the pair.** That seam needs World's blend. A body crossing it has `sdx` reading through a join that isn't one place on the planet. Pillar 3 still holds, because the buffer still closes.
- **A lap no longer comes home.** Game Design has accepted that.
- **Anything recorded in a column must end when its column is overwritten:** marks, craters, slides, aftermath and water. The swap has this rule by zone today; the road needs it by column.

## Ring position against planet coordinates

- **The fight has no planet coordinates.** Fighters, shots, craters and structures all hold ring `x`. Outside tools, `ringPoint` and `lateral` are read only by the world's build, the turn and the campaign, and never in a fight's tick.
- **So the map from `x` to the planet is one piece of state:** the epoch's ring today, the road tomorrow. A swap keeps every `x`, so nothing is converted.
- **The road's state is small:** each front's point and tangent, 12 floats. Rendering's far land and the wear list need a point for a column. As a table that's 57.6 KB on a Half ring and 115 KB on a Whole, or arc records if those are smaller. Never keep a history (Netcode's rule).
- **Stable building slots are the core's real job for a road.** `S.buildings = keep + made` re-indexes everything, which orphans `f.interior`, wreck ids and `splashed`. `bIdx` says it never changes in a match. A road adds and retires buildings as it goes, so it needs fixed slots and an index updated one building at a time. Those are my packed arrays.
- **Far readers are the largest unknown; I haven't audited them.** The director has 19 `groundY` calls, and 11 director and core files read `S.buildings`. A launch planner could aim at a tower that the road overwrites before he arrives. Either planners read only the committed road, or a plan commits what it aims at.

## Hash and replay

- **A replay needs no format change.** If the bearing is a director decision from the state and seed, nothing new is recorded. The forced runs below confirm that the same inputs give the same turns.
- **New data keys must join `SimReplay.dataHash`,** so a replay on other data is refused.
- **`stateHash` doesn't read `S.base`.** The ground is covered only by `E.sh`, the slice's hash. A road folds each column into a running hash as it's read, as `_hashTo` does. Re-hashing a whole ring each tick is not an option.
- **The bearing, the lead's queue and the fronts go in `hash.gd`,** and in `NetDesync.digest`, which doesn't read `S.epoch` today (Netcode's page).

## Snapshot and rollback

- **Size:** 83.5 KB on this ring (67.7 KB packed, 2,075 scalars). How often the bearing changes doesn't grow it.
- **The road adds little:** `S.base` must leave `SNAPSHOT.share`, which adds 9.6 KB, since writing a shared array in place corrupts every snapshot. Most of a take's cost is scalars; a packed block is one copy.
- **Rollback over a swap is exact:** 6 of 6 depth-21 re-runs at each of k 32, 240 and 2,400 gave the same `stateHash` and digest, with no cold swaps.

**Measured: a pick inside the window throws the ring away.** `choose` calls `_dropJobs`, so a re-run that passes the pick reads the ring again on the rollback frame:

| Pick rate | Picks inside the 21 ticks | Columns read by each re-run | Native |
| :--- | ---: | ---: | ---: |
| k 32 | 0 | **0** (the kept job is found) | 0 |
| k 240 | 1 | **2,400** | 130 ms |
| k 2,400 | 3 | **7,200** | 390 ms |

Netcode found this by reading the code; these counts confirm it. The fix is World's: key the job cache by seed and ring, and don't drop it at `choose` or `cancel`. It should land before any turn goes on. A road needs the same cache keyed by a front's exact bits, or its re-run costs 13.6 ms, over the 12.5 ms budget.

**Netcode's lead of 20 ticks fits the road.** Inputs through T - 20 are confirmed before T runs, so a change made 21 ticks ahead of the body can't flip on screen. The road must be committed for 21 ticks x 171 units, plus half a screen: 5,085 units, 159 columns. At a flat-out dash a change therefore reaches his feet in about half a second.

## float64 trig, web and native

**Holds, on everything run.** The sim's math is scalars with `+ - * / sqrt` and our own sin, cos, atan and acos. `Vector3` is float32 and stays out, as `planet.gd` already does.

**Native and web agree to the bit** (Chrome 156, x64; all 45 golden keys and 14 extras identical, 8 of them new):

| New key | What it runs |
| :--- | :--- |
| `drift`, `driftNorm` | 216,000 composed turns and steps, without and with renormalising |
| `stream`, `streamWild` | The road for 1,200 ticks at up to 1° a tick; 400 ticks at up to 30° |
| `turns25`, `turn180` | Real turns at 2.5° and 180° |
| `perTick` | A real cold swap on each of 12 ticks |
| `anyTick` | An AI fight with a swap forced every 60 ticks at 45° |

**Rounding is not a problem.** After 2,160,000 composed steps (10 hours of ticks), a point is 0.0000008 units from the closed form and its length is off by 9e-11. Renormalising brings that to 0.00000007 at about twice the cost, so it isn't needed for accuracy.

**Not proven:** ARM (macOS on Apple silicon is a target platform), Firefox and Safari. This is the gap `web-parity.md` already lists; any-angle adds nothing new to it.

## Forced swaps in a real fight

World's calm test skipped, AI on both sides, the swap called directly. Each row ran twice with the same state; there were no script errors.

| Angle, spacing | Ticks | Swaps | On a tick that wasn't calm |
| :--- | ---: | ---: | ---: |
| 45°, every 60 ticks | 3,600 | 60 | 59 |
| 180°, every 30 ticks | 3,600 | 120 | 53 |
| 10°, every tick | 240 | 240 | 96 |

This shows the core stays deterministic and doesn't crash. It does **not** show the fight stays right: World's list of what a non-calm swap breaks (water, tower chains) still stands, and no fighter was in a tower chain in these runs. I also ran the swap with idle fighters at 45°, 90° and 180°, with no cold swaps, which closes one item World could not run.

## The curve's ground

Kinks don't show as steps. The height step between neighbouring columns stays close to a straight road's, so the ground needs no smoothing at the arcs' joins:

| Up to, a tick | Step, p50 | p99 |
| ---: | ---: | ---: |
| 0° | 2.66 | 26.0 |
| 0.5° | 2.70 | 29.6 |
| 5° | 2.61 | 33.9 |
| 30° | 4.50 | 39.4 |

The largest single step varies by what the road crosses (57 to 329 units), and one run per row can't separate that from the curve. A fighter is about 75 units tall.

## What the core would need

**For sparse swaps at any angle (small):**
- the lead's queue in `S.epoch`, and its hash lines;
- the call at a launch's stop;
- nothing in `W`, `NC` or the wrap math.

**For a road (a slice of its own, behind a switch, golden byte-identical with it off):**
- `S.base` out of the shared list;
- stable building and tree slots, with an index updated one at a time;
- the fronts in the state and the hash;
- records ended by column;
- the far-reader audit, with Encounter.

## Not measured

- Any timing that counts as valid. One quiet window of about 3 minutes would give the swap tick and the rollback frame.
- The road's places, buildings, carry and view; the column reads are the only part prototyped.
- A long rush against the road's front.
- A road under rollback: the 252 columns are arithmetic.
- ARM.
