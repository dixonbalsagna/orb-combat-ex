# 2v2 on the full globe: the number

Simulation, 2026-11-01, for Orb's order ("versus on our 3d globe arena ... a co-op experience that can be played over a local area network"). Updates `docs/net/two-v-two-lan.md`'s version 3, which ran on the half-size flat ring. Rulings are Game Design's (`docs/design/two-v-two.md`). **Session counts are guesses. Nothing here has four fighters in it.**

## The answer

**About 18 to 24 sessions, so the full globe adds 1 to 2 to Netcode's 16 to 22. Drop the half-size ring.** The globe's cost is already being paid for versus. What 2v2 adds on it is small: "each of the pair" becomes "each fighter" in the swing, a rule for when swings rest, and a read of what two far fights do to cold ground on the old PC.

**What it gives up is the turning, while the pairs are apart.** In the proxy below, which is the far end, that's about four-fifths of the time.

## How far apart two fights get

No four-fighter fight exists, so the proxy is **two separate AI fights on one planet from the same start,** stepped together: 6 planet and seed pairs, 43,200 ticks, swing on.

| Pairs farther apart than | 1,000 | 2,000 | 5,000 | 10,000 | 20,000 | 40,000 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Share of the time | 85% | 82% | 60% | 43% | 22% | 7% |

The middle is 7,400 units. **These are far-end numbers:** nothing in the proxy pulls the fights together, and Game Design's levers should bring them down.

**What a fight asks of the line:** 53 swings, 445° in those 12 minutes of play. The other fight was in the air on 97% of those ticks.

## The options, each with its number

| Option | The number | Ruling |
| :--- | :--- | :--- |
| **One line, swings rest while apart** (Game Design's ruling) | At the far end, the world turns about 18% of the time at 2,000 apart, about 40% at 5,000. **Adds 1 to 2 sessions** | **In: build this** |
| **Turn for the pair the line's on; the other rides along** | The law lets 82% of the turning through, because the far fight's usually in the air. But that fight's ground then slides by at about **2,000 u/s in the middle and 8,300 at the far end,** while it's hovering in a brawl. A standing fighter's limit is 75 | **Out** |
| ... the same, the far fight held to 300 u/s | 25% of the turning gets through, against about 18% for resting, and the far fight's ground visibly drifts at four body heights a second | **Out:** seven points isn't worth it |
| **Each pair's turn in the render only** | The sim's ground and the drawn ground part. At gap 900, turned 40°, a fighter's 289 units off the sim's line: **feet off by 32 units typically, 636 at worst** (slopes of 0.11 and 2.2). A building 2,000 away is drawn **1,285 units** from where it can be hit. Even at 5° the bad case is 86 units, over a body height | **Out** for anything you can touch. Turning only the sky is a look, Rendering's call, not a substitute |
| **Two lines, one per pair** (`two-v-two-sim.md`) | 6 to 10 more sessions, and World moving water and heaps to records. The lines cross, so in about **12,000 units** around each crossing two fights share space but not coordinates | **Out** |
| **The bent line** (new, below) | At 20,000 apart and 40° between them: flying through the bend runs **1.41 times** as fast at worst and turns **23° per 1,000 units.** About 5 to 7 more sessions | **Not now.** The one to try if Orb misses the turning |

## The bent line: the unconventional one worth keeping

**The idea:** two lines without two sets of coordinates. There's one strip, as now, but its path on the planet bends. Near pair A it follows A's great circle, near pair B it follows B's, and in the empty stretch between it blends from one to the other. Each pair turns its own circle by the law, as in a 1v1, and the other's ground doesn't move at all.

**Why it beats two lines:** all four stay in one strip, so `x`, `z`, gaps, hits and the strip's arrays stay as they are, with no conversion. One set of marks, water and heaps. A body flying from one fight to the other just follows the path, and the world turns under it as it goes.

**Pen-and-paper numbers** (`bent.py` in my scratch, on the unit sphere, 4,000-unit zones either side of a pair):

| Apart along the strip | Turned 40° | Turned 90° | Turned 135° | Turned 170° |
| :--- | ---: | ---: | ---: | ---: |
| 14,000: fastest, sharpest | 1.66 times, 56°/1,000 | 2.95, 90° | 3.81, 213° | Breaks down |
| 20,000 | 1.41, 23° | 2.35, 34° | 3.04, 80° | Breaks down |
| 40,000 | 1.24, 6° | 2.01, 10° | 2.89, 23° | Breaks down |

**Its limits:**
- **The difference between the two lines needs a cap,** about 120°: past that, the blend gets close to passing through the planet's centre.
- **Under about 14,000 apart the bend's too sharp,** so the lines have to converge as the pairs close, by the law, and a closing flyer's in the air. So it wins back the 22 to 40% of the time they're far apart, not all of it.
- **Two fights can be close on the planet and far on the strip** (a 60,000 strip gap can be 20,000 on the planet). They'd see each other and couldn't touch. A building there can be posed for only one of them: the nearer fight has it, and the other flies through.

**Not built, and only the geometry's tested.** Keeping the door open costs one line of refactor (`pointIn(S.frame, x)` going through one function, in my list). If Orb plays one line and misses the turning, a one-session prototype answers it before anything's committed.

## What 2v2 on the globe does to the rest

- **The rule for "apart":** swings run only when every fighter is within about 4,000 units of the pivot, in data (agreed). The law still applies inside it. **This is also what keeps a far fighter safe:** `swing.gd` re-floors only the pair as the line turns, so a far fighter would hang or clip under any turn. With this rule none is far, and refactor 2 re-floors everyone it names.
- **Flying to a rescue:** halfway round is 76,800 units, about 5 to 6 s flat out, by Game Design's sum. It needs no shorter road, which is the case for dropping the half ring.
- **Two fights on cold ground:** each reads new ground on its own, so about twice the cold reads, and a launch can land in each. On the old PC that's Performance's to read; Netcode's table already assumes a doubled tick.
- **Buildings at every place:** cheaper while apart. With no swing there are no pose walks, and the index only holds the band.
- **The hit-stop:** Game Design's ruling (holds only the exchange's fighters, world and everyone else run on, 1v1 byte for byte) is the first thing to build. With one shared clock a fight would be frozen by the other for another 15% of the time, about four times a second, or 11% and about twice a second with the hit-stop table on. **A prototype proves the mechanism** (`pending/clock-by-body/`): across 32,400 ticks a pair's every number matched a plain 1v1 through 6,071 held ticks, with others moving on all of them. About 2 sessions are left.
- **A fighter who changes fights carries deadlines from the old clock.** Clocks drift by the time each was held: 6 s after 25 s of play in the prototype. Tested: a rush with 40 ticks left ran 400 on the new fight's clock, and 40 once re-based. So changing fights has to shift his own stamps by the difference: `hurtT`, `breathT`, `ambushUntil`, `lockBackT`, `sigReadyT`, `lastAtkT`, `exT`, `embedCool`, `beamCharge` and the rush's end, about 66 lines stamp them. An exchange he joins is on its fighters' clock. Two sides of a fight also read each other's stamps (`ai.gd`'s `exT`, for one), so a fight's bodies must be on one clock.
- **Random numbers:** water, collateral, mood and fire draw nothing from `S.rng`. Shots draw nothing themselves, but a shot reaching an AI fighter can (`blast.gd:361`, his perfect block). All of it's deterministic, so peers agree. Two fights will share `S.rng`, and each fight's order draw should move into its own step.
- **Who a stop belongs to,** from refactor 3: a blow's, its two fighters. A launched body's landing or contact, the body and whoever sent him. A building, its body and sender. A wall hold, the body. A beam's blast, its firer. A send's and a KO's aren't named yet, so they hold everyone until the second exchange names them. A shot's hit raises a stop through the director's blast rules, naming the firer and the one hit: **a firer far away shouldn't be held, so that's a question for Game Design.**

## For Orb, when it's time

**Does a fight need to turn its own world while the other fight is far away?** Play one line first. If it's missed, the bent line is the answer to try.
