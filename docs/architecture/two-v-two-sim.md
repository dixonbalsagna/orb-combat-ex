# 2v2: what the sim would have to do

Simulation, 2026-11-01, for Orb's spitball at the end of `docs/ep/vision.md` and Netcode's `docs/net/two-v-two-lan.md`. **Paper only:** nothing was built, and nothing with four fighting bodies was run. The counts are from main 1b82e32a.

## The answer

**It's feasible, and I'd put all four on one line.** Each player's "record" is then their own focused opponent and their own camera, on one shared planet and one line. Two lines, one per pair, is what "their own record of the planet" sounds like, and it's about three times the work in the sim, with a rule nobody has designed for when the two fights meet. I'd only build that if Orb plays one line and misses it.

**The line isn't the big job either way.** The big job is that the director runs one exchange at a time, and that the game has one clock.

## Option A: all four on one line

**Why it can hold any two fights:** any two points on a sphere lie on one great circle. So a line can always pass through both pairs, up to 76,800 units apart along it, and each PC draws its camera at its own player's place on that line. The planet's records don't care: ground, craters, cracks, scorch and buildings are all at planet points already.

**What it gives up:** a pair can't turn its own bearing while the other pair is far away. This happens by itself: the swing's law limits the rate by each fighter's distance from the pivot, so at 20,000 units a standing fighter holds it to about 0.2° a second. In practice **the world turns when all four are close, and stays put when they've split up.** A launch that would have swung the line doesn't, if the other fight is far.

| What | What it needs | Size |
| :--- | :--- | :--- |
| `SimSwing`'s pivot, limit and standing test, the pose list, the near marks | "Each of the pair" becomes "each fighter". 12 sites in `swing.gd` and `field.gd` | Small |
| Depth | Already per fighter. A brawl's line frame (`DirBrawl._frA`) is one at a time, and goes with the second exchange | With the exchanges |
| Cross-pair hits | Everyone's on one strip in one depth band, so a launched body or a beam can reach the other pair with no conversion. **Whether it hits them is Game Design's rule** | Small once ruled |
| Hash, rollback, snapshot | Two more fighters, and they're already in lists. Nothing new about the line | Small |

## Option B: two lines, one per pair

**The shape that keeps it possible:** a "line" becomes a bundle of the frame, the swing, the strip's arrays (`crack`, `scorch`, `deform`, `water`, the rows) and the poses. While stepping a pair, swap that pair's bundle into `S`, as `WorldTerrain.enterRow` already swaps depth rows. That way the 280 or so sites that read them (`S.frame` 55, `S.swing` 20, the strip arrays 209) don't change.

**What breaks or costs:**

| What | Why |
| :--- | :--- |
| **Near reads and memos** | `SimField`'s column memos are one set of statics, keyed on one frame. Two lines alternating would miss every time, so they need a set per line |
| **Poses** | `bX` and `bZ` are per line: two sets, and twice the walks (`_poseList`, the far poses). At 4,075 buildings that's the costliest part of a swing tick now |
| **The strip's marks and water** | Per line. `_layMarks` and the water windows run per line, and `S.water` and heaps aren't planet-fixed, so a flood on one line doesn't exist on the other. They'd have to move to records first |
| **Fighters' numbers** | `x`, `z` and gaps only mean something on your own line. Every read between pairs has to convert through a planet point |
| **Two lines cross, twice, at opposite points** | Near a crossing the two fights share real space but not coordinates. In the 3,000-unit depth band, at 30° that's about 12,000 units of each line. Nothing can hit across without conversion, so bodies would pass through each other, or there has to be a new rule |
| **Meeting up** | When the pairs come together they have to end up on one line. One line turns onto the other, at the law's rate, which is a slow visible swing of that pair's world, or a cut. **This is the design problem, and nobody has ruled on it** |
| **A launched body or a beam leaving its pair** | It flies along its own line, into space the other line's fight can't see. A meteor landing on the other fight would need the conversion above |
| **Tick** | The world stages about double: reads, poses, lays, water |
| **Hash and snapshot** | Two frames, two swings. On a swing, about 65 KB more of poses to copy, and up to about 19 KB for each strip array a line changes. Copy-on-write hides most of it. Not measured |

**What's already right for it:** the store, `bDir`, the field's reads and trees by cell are all planet-fixed, and every line read already goes through `SimField`. So choosing A now doesn't close B off.

## Either way: the two-fighter sites

| Site | Count | What it means |
| :--- | ---: | :--- |
| `S.dirS.ex`: the running exchange, one | **111 reads in 26 files** | **The heart.** Two fights means two exchanges, so this becomes a list, and each read has to know which one it means. Encounter called this out in `docs/director/one-v-many.md` section 4. Encounter's |
| `ex.A`, `ex.D` | 431 | Mostly fine: they already take the exchange as an argument |
| `fighters[0]`, `fighters[1]` | 39 in `sim/` (25 core, 14 director) | Each needs a look |
| `SimRoster.opp` and `.opp(` | 64 | One function, so **"who's my focus" is one change,** plus a read of what each caller means by it |
| `range(2)` | 15, and 24 in `sim/input/` | Input's are by player and mostly fine |
| Outside the sim | render 175, audio 11, net 2 | Rendering's is the largest, and it's a fight's worth of its own work |

**What's already there:** a match can hold up to 5 bodies (`SimRoster.MAX_BODIES`, since 06b0200e), and Encounter's parked ring has guards waiting their turn. But that's one fight with bystanders, not two fights.

**One clock, the other big one:** hit-stop, a launch's pause, slow motion (`S.game.ts`) and set pieces all stop the whole sim. In 2v2 one pair's hit-stop would freeze the other pair's fight, several times a second. It needs a ruling, and then either hit-stop by pair (a real change to `stepFighter` and the exchange's clock) or a global freeze only for the big moments. **I'd treat this as a feel risk as large as the exchanges.**

## Tick cost

**Not measured:** there's nothing to measure until two exchanges exist. By arithmetic, on Option A: the fighter and director stages about double, and the world doesn't, so the 0.4 ms tick goes to about 0.7 ms. Launch ticks don't change, but two can land together, and those are still the hitches (Performance's table). Netcode's rollback sums assume a doubled tick, which is about right or a little high. Option B adds the doubled world stages on top: about 1 ms, with swing ticks higher.

## Recommendation

1. **Option A.** The focus and the camera are the player's record; the planet and the line are shared.
2. **The order:** Game Design's rulings on the shared clock and on cross-pair hits; two exchanges at once (Encounter); the focus table and the D-pad (Controls and me); the swing's sites (me); the panes (Rendering).
3. **My part in Option A is about 2 to 3 sessions,** a guess. Option B adds about 6 to 10 of mine, and World's work moving water and heaps to records.
4. **Don't start before the launch's four-fighter work.** Netcode says the same from its side: 2v2 is on Orb's list for launch, and LAN on top of it is small.

**The question for Orb, when it's time:** does a fight need to turn its own world while the other fight is far away? If yes, that's Option B. Playing one line with four bodies is the cheapest way to find out.
