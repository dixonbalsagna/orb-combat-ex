# The shifting arena: design and windows (World, 2026-10-19)

Owner: World and Environment, leading. Orb (2026-10-19): "`31b-shifting-arena.svg` illustrated exactly what I was envisioning. I want this approach to work ... please begin work on engineering this system", and "I can see this being used to programmatically assign stages to opponents in the story mode." The picture: `homework/31b-shifting-arena.svg`. Game Design's rulings that bound it: `docs/design/rulings-2026-10-19.md` §3 (three sizes; the plane tilts only during a launch's flight or a set piece, pivoting round the landing point, never during a brawl) and §4 (homes, a new planet every run). The research behind it: `arena-shift-research.md`, `small-circles.md`, `planet-module.md`. **A plan; nothing in `sim/` or `data/` changed.**

## 1. What we build

**An arena is a plane through the planet; its ring is the ground.** A plane has a normal `n` and an offset `d` (the plane's distance from the centre, 0 to 1 of the radius): `d = 0` is a great circle (today's arena); a larger `d` is a smaller circle round the pole `n`. The ring is exact in columns: with `cols` columns of `COL` units and the planet's own circumference fixed at 4,800 columns, the ring's radius is `rho = cols / 4800` of the planet's, so `d = sqrt(1 - rho^2)` and **every column is exactly `COL` units of arc** (no seam gap). Column `i` is the point `d n + rho (cos a u + sin a v)` with `a = (i - mid) COL / (R rho)`; for `d = 0` this is today's expression to the bit, which is what keeps the golden still.

| Size (Game Design, `rulings-2026-10-19b.md` §3a) | Columns | Units | `rho` | `d` | Lap, flat out | A re-read costs (busy PC) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Whole** | 4,800 | 153,600 | 1 | 0 | 15 s | 0.56 to 0.78 s |
| **Half** | 2,400 | 76,800 | 1/2 | 0.866 | 7.5 s | about 0.3 s |
| **Close** | 1,200 | 38,400 | 1/4 | 0.968 | 3.8 s | about 0.15 s |

**The shift is a new plane that still passes through the pair.** The plane turns about the fighters' point `M` (so the ground at their feet stays the same ground) and may drift `M` slowly along the surface; either way the new ring is a plane through the new `M`. Between shifts the arena is fixed, as today, and the far land and sky drift slowly (cosmetic, window 2). **Not built, on purpose:** a ring that moves every tick (the per-column state would be re-laid every tick, and a launched body could land on ground that moved under him).

**The turn happens at a calm moment** (Game Design, `rulings-2026-10-19b.md` §1): a form step that pauses, **the moment after a launch has landed** (both down or set, nothing moving, under Camera's hard cut back to the pair), or a set piece's cutaway (the inside chain's or a collapse's). Never in a brawl, never under a dissolve or a wipe. **At most 10 degrees of bearing about the pair's midpoint, at most 4 a fight, at least 60 s of fight time apart, and the loop drifts at most 40 degrees in a match.** The turn leans the way the fight was pushed and, inside that side, brings the coolest place into view (Encounter's score). A turn needs a calm tick: no beam, shot, flight, slide, failing stack, magma or crowd on the move (a check gates it). There is no turn mid-flight: that earlier ruling (§3d of the first batch) is superseded.

## 2. The windows

Each is parked behind a switch with the golden byte-identical while it is off, built in scratch, gated (parity's five stages, Rendering's 15 gates, the self-test, World's checks), and reported.

| # | Window | What it is | World's | Others' lines | Cost |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **0** | **A match from a slice** (planet window 2) | The draft of 2026-10-17, re-cut on today's main: a setup with a `planet` builds its world from the slice instead of `genWorld`. The existing plane work is useless without it | `planet_world.gd`, `biomes.gd` | `sim/core/sim.gd` `newMatch` (two hunks, Simulation's); golden keys (Simulation); the ice biomes' stand-ins (Rendering, Art, Game Design) | 1 window |
| **1** | **The arena as a plane** | `SimConst.W`, `NC` and `HALF` become statics set once in `newMatch` from `setup.arena` (the columns; absent means 4,800); `WorldPlanet` separates the planet's fixed size from the arena's columns and reads a ring; the slice, the held places and the world from a slice take the arena's columns. A Half and a Close match play. **Built and proved in scratch** | `planet.gd`, `planet_world.gd`, `collateral.gd` and `structures.gd` | **Simulation:** `constants.gd`, `sim.gd`. **Encounter:** `location.gd` (`STEP` follows the arena). Rendering and Camera: the far fog and the zoom ceiling at 38,400 | Done in scratch; one window to apply |
| **2** | **The slow drift** | Render only: the far land and the sky turn slowly round the fight, driven by the tick; the sim's band does not move. World gives a pure read of the real ground beside the ring (`WorldPlanet.farColumn`) so the far land is the planet's own, not a wander | `farColumn` and its check | **Rendering:** the far field reads it; **Camera:** none | 1 window each |
| **3** | **The calm-moment turn** | At a calm tick the arena is swapped for a new ring through the pair, read in the time-sliced loader beforehand and carried by place id (below) | the epoch module: the new ring, the read, the carry | **Simulation:** the swap tick, the epoch in the hash and the replay, calm-tick gate. **Rendering:** the ground rebuilt at the cut. **Camera:** a hard cut at the swap. **Encounter:** the calm states and the steering (the side, the coolest place) | 2 to 3 windows: the swap with its triggers, the steering, the polish |
| **4** | **Story stages from the plane** | A function from an opponent (and Narrative's homes) and a run's seed to a plane through their thematic ground | `stages_story` data, the picker's scoring | **Narrative:** each opponent's ground profile; **Game Design:** the run's size ladder; **run-core's owner:** where the run calls it | 1 window |

**Status, 2026-10-22.** Windows 0 and 1 are built, gated and committed as a design (`scratch-build/arena-plane/`), waiting on Simulation's yes (Encounter has said yes). **Window 4's picker is built in scratch** (`scratch-build/ring-picker/`: `WorldRingPick`, Narrative's claims as scoring data, `firstRing`, `bossRing`, a stepped `PickJob`; 96 of 96 picks met their size's minimum on 8 planets) and **window 2's World part** (`WorldPlanet.farColumn`, a pure read of the planet's own ground beside the ring) is too. Window 3 (the calm-moment turn) is next, with Encounter's calm states.

## 3. Window 1 in detail (the arena as a plane): built and proved in scratch

Built: `scratch-build/arena-plane/` (`arena-window1.diff`, on top of planet window 2's re-cut, `planet-window2-recut.diff`; scripts `mk_arena.py`; check `arena_check.gd`).

**The setup key.** `setup.arena = {"cols": 2400, "side": 1}` with `setup.planet` (and `touch`): the ring is the small circle through the picker's touch-down, tangent to the great circle there, on its left (side 1) or right (side -1); `cols` 4,800 is the great circle itself. The ring's radius is `sin(theta) = cols / 4,800`, so a column is exactly `COL` units of arc and the ring closes. An `arena` without a `planet` is ignored (the hand-made world is 4,800 columns). Explicit axes (`n`, `d`) are window 4's (the story picker names its own ring).

**Simulation's lines.**
1. `sim/core/constants.gd`: `W`, `NC`, `HALF` from `const` to `static var` (today's values), `PLANET_NC` (4,800, a `const`: the planet's own size) and `static func setArena(cols)`. The 213 reading sites keep their text; none is a compile-time constant (the scan found four, below).
2. `sim/core/sim.gd` `newMatch`: first, `SimConst.setArena(setup.arena.cols if present with a planet else 4800)`; after the world is built, `DirLocation.reset()`; the planet start reads `WorldPlanet.touchCol()`. **A static every match sets is never stale.**
3. **`replay.gd` needs nothing:** the replay header already carries the whole `setup`, so the arena is recorded and replayed; the data hash is unchanged.
4. The JS twin is frozen and not a gate.

**Encounter's line.** `sim/director/location.gd`: `STEP` (a bucket of the lure's histogram, `W / 48`) was a `const` of 3,200 units; it becomes a static the tables rebuild on (`_ensure` keyed on the arena's length and the world; `reset()` at each match). Without it the lure's buckets would not line up with World's population histogram on a smaller arena.

**World's own lines.** `collateral.gd` (`HIST_STEP`) and `structures.gd` (`BUCKET_W`) read `SimConst.W / 48` and `/ 128` where they used a `const`; `planet.gd`: `PLANET_NC` for the planet's size, `touchCol()` for the middle column, `ringThrough`, `lateral`, `columnPoint` and `readSlice` for a ring (today's expressions to the bit when the ring is the great circle, so the golden and `d0f86ade` do not move), `sliceFor(..., side)` keyed on the arena's length; `planet_world.gd` passes the side. A **picker for rings** (choose a centre, score the ring) is window 4; window 1 reads the ring through the picker's touch.

**Proof** (`arena_check.gd`, 0 failed): the statics follow `setArena` and the wrap and shortest arc with them; rings of 2,400, 1,600, 1,200 and 600 columns are closed (a gap under 0.01 unit), unit, one column of arc between neighbours (within 0.2%), tangent to the great circle at the touch-down and zero lateral on themselves; the Whole slice is today's (hash `d0f86ade`); a place's lateral offset is its distance to the ring; a match on each size builds from its slice (every building and fighter inside the world), plays and plays to the same hash twice; an arena of 4,800 plays the same as none; a default match after a small one is today's world (118 buildings). The gates are in the package's README.

## 4. Window 3 in detail (the turn)

**One epoch, step by step.**
1. **Ask:** the director's calm state (Encounter) raises `epochDue`; World's rule answers with the next plane: pivot = the pair's midpoint (or the landing point in a flight), a bearing change of at most about 10 degrees and a drift of a few degrees, from a keyed draw of (planet, touch, epoch). A match has at most about four.
2. **Read, off the sim:** the time-sliced loader reads the new ring (`LoadJob`, no clock, memoised outside `S`, bit-identical however stepped). A Half takes about 0.3 s of work, a Close 0.15 s, the Whole about 0.7 s (spread over a second or more at 4 ms a frame). It starts when the epoch is asked and is ready by the calm tick; if it is not, the epoch waits.
3. **Swap, on a calm tick, in one step:** `S.base` is the new heights; the per-column arrays are re-laid; buildings and craters are carried (below); the fighters keep their arc coordinate from the pivot and their `y` is set above the new ground; the epoch number goes into the hash (a conditional append, so a match with no epoch hashes as before) and the new slice's hash is checked.

**What is carried.**

| State | How |
| :--- | :--- |
| **Craters** (up to 400 records) | Point records in the **place frame** (the run's wear list already does this); written out before the swap and re-applied on the new ring |
| **`deform`** | Not a sum of the craters (beams, slides and heaps write it directly): the craters are re-dug; **the thin marks (a beam's scorch, a slide's heap) are the honest loss**, kept to the pair's neighbourhood by the calm-tick gate and, if wanted, resampled by arc coordinate within a few thousand units of the pivot where the new ring is nearly the old one |
| **Buildings** | By identity: **place id and plan index** (the collateral window's `Building.place`, `plan`). A building leaving the ring returns its hp, floors, breaches and failing state to the wear list; one entering starts from it; the ones near the pivot are the same buildings at a new lateral offset (a street slides sideways: a bearing change under about 10 degrees keeps the front street the front street) |
| **People** | By place: `popAlive` follows the building; the collateral window's ledger (`S.world.present`, `peopleLeft`) is per run, not per ring |
| **Water, scorch, rubble, crack, low, depth rows, lanes, `popHist`** | Re-laid from the new read; marks carried as above |
| **Things in flight** | Swap only when none is live (a calm tick); this is also what makes the replay simple |

**Determinism and replay.** The epoch's plane is a keyed draw, so a replay needs no entry; Simulation hashes the epoch number every tick and the slice hash at the swap. A playback recomputes the slice at the swap (synchronous, 0.08 to 0.7 s). `planet-slice-core.md`'s header is unchanged.

**Nothing is in flight at a turn** (Game Design 1a), so no body, beam or shot has to be carried; both fighters keep their arc coordinate from the pivot and their `y` is set on the new ground.

## 5. Window 4 in detail (story stages)

A story stage is a plane chosen for an opponent. **Input:** the opponent (a fighter id with a ground profile: Narrative's homes give the Protagonist and the Anti-hero a home each; others a biome mix), the run's seed and the stage index. **Output:** a plane `(n, d)` and a touch point, from the picker's scored candidates (a centre: the opponent's home, a landmark, a city, a pole; a size from Game Design's ladder; a bearing), seeded per run, with the stage's minimum (Half: a city, two towns, two biomes; Close: a city or a landmark) and the opponent's affinity as a score term (the biome shares along the ring). A boss is the Whole ring through his home and the most populous city standing (Game Design 2c). It is a data file (`stages_story.json`) and a pure function, so a run's whole stage list can be shown on a map before it is played.

## 6. Order, cost, risk

**Order:** 0, 1 (World, then Simulation), 2 (in parallel, Rendering), 3, 4. Each window leaves the golden unchanged while its switch is off.

- **The risks.** (1) The per-column state carried across a swap: the thin marks are lost; I would rather lose a scorch than carry a stale one. (2) Rendering's ground rebuild and the far field at 38,400 units (a Close arena (38,400 units) is close to the camera's widest view (21,333): Camera clamps). (3) Window 0 depends on the ice biomes' stand-ins. (4) Four statics and a header field are the only change to a hashed or replayed thing; each is conditional.
- **What I need:** Simulation's yes on the window 1 lines; Encounter's calm states; Rendering's and Camera's owners to read this paper; Game Design to rule on the first calm triggers and the epoch cap.
