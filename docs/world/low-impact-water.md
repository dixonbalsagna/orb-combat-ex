# Low-impact water on gen 3 (World, 2026-11-01)

The EP's brief, from Orb on clip C10 (a beam parting the sea, the sea rushing back as a wave, lake water filling a trench and putting a fire out): "I love the interaction with the environment, any low-impact water physics we can accommodate I am absolutely excited for." Research only: nothing is built, and nothing is built until Game Design's map row. Orb's earlier line stays the rule (`water-v2.md`): rule of cool, a cosmetic backdrop, no fluid simulation, nothing that costs frames.

## 1. Where we stand

**Already built, for gen 1 and 2, all off by default** (`data/biomes/water.json`, `sim/world/fill.gd`, `render/shaders/water.gdshaderinc`): holes fill from the sea, lakes or a water table behind a running front; a slam into water throws a ring wave that nudges anything at the surface 1 bh; a fill that reaches a scorched line puts it out; shallow water is waded; the skim and the 30-tick surfacing are ruled (Game Design 23b rows 7 and 13 to 17). The shader already draws the fill's crest and slosh (4 fronts) and the wave ring (2 rings), and the foam line and shallow band.

**What gen 3 changes.** On a field world `S.water` holds only what a fight made, and the strip is a view of the planet along the line. A fill window is *strip columns*, so when a swing turns the line it would slide off its hole (the same fault cracks had, which is why they moved to the planet store). Water v2 is off, so nothing breaks today, but **it cannot simply be switched on for gen 3.** Everything below that the sim holds is at planet points, in records or the store, and is a pure function of them plus the tick.

**The sea and the lakes are free.** The sea is derived from the field's height, a lake is a record (`recordWater`), and both reach the strip through `SimField.nativeDepth`. Rivers are built and off.

## 2. The ladder, cheapest first

Cost columns: *measured* means a figure from this project's checks; *estimate* means my reckoning, to be measured on the build. "Per level" is a whole match start.

| # | What the player sees | Sim or view | Cost per tick / per level | Rollback | Flash |
| :-- | :-- | :-- | :-- | :-- | :-- |
| **A1** | **Wakes and splashes.** A fighter, a launched body or a prop that crosses the surface leaves a hollow ring and a short V wake and throws a few drops. A skim shows its skips. | View only, from positions and the existing launch/impact events | Shader: 4 more ring uniforms (the 2 now). Particles: a handful. Sim: 0 / 0 | None (nothing hashed) | Rings and drops are "not a flash" in the register (`flash-sources.md`). Keep rings hollow and under 2 Hz |
| **A2** | **The sea parts.** Along a beam over water the sheet is pressed down into a groove with two walls of foam, the bed showing in the middle, for 1.5 s (90 ticks, Game Design item 10), then the walls slump. | View only: the water vertex shader displaces the sheet along a segment (a, b, half width, t0, open ticks), 2 segments at once | Shader: a loop of 2 over the water vertices (as the fill loop does now). Sim: 0 / 0 | None | **Watch this one.** A big part of the screen changes from sea to bed. The walls must *move* over at least 0.3 s (geometry, no step in colour, no dissolve); ask the register as a `water_part` source with the groove's area |
| **A3** | **Wet shore.** A wave or a splash wets the sand it reaches, a darker band that dries over 4 s. | View only: a per-tile transient, never read by the sim | A byte per visible tile; clears on its own. 0 / 0 | None | A slow band, no flash |
| **A4** | **Bobbing debris and drifting foam** on the surface; a river's foam streaks run along its flow. | View only: bob from the clock and the prop's position; river flow from the record's `a` to `b` (rivers are off) | Shader terms. 0 / 0 | None | None |
| **C1** | **The rush-back.** After the 90 ticks the sea comes back as a wave along the beam's line: a crest runs out from the groove, and a fighter at the surface is pushed 2 bh along it (Game Design item 8). A slam into water throws the same thing as a ring (the built `water_wave`). | **Sim, bounded state**, with a view cue. A `surge` record: a segment or a point, start tick, open ticks, push, width. At most 4 live, each dropped after its steps | Per tick: 4 records x the bodies at the surface (up to about 10): **estimate under 5 us**; 0 when none. Per level: 0 | The records are a small hashed array in the state, copied by the snapshot like the other arrays | One rise and one fall of the crest; the foam is a band. Ask `water_wave` once per surge |
| **B1** | **Holes fill.** A crater, a trench or a beam's groove beside the sea, a lake or wet ground fills with water that runs in from the source; the pool is real to the sim (wade, skim, surfacing). | **Sim, no new state:** water is a pure function of the dug records, the field and the tick. See 3 | Per tick: 0. A read: one store-grid lookup and a few records (**estimate 3 to 8 us**, about a crack read). One source search per kilometre box, once. Per level: 0 | Nothing new beyond the records, which are already hashed. The front is a function of (tick - record time) | The crest and slosh exist; the pool's colour arrives with the front, no step |
| **B2** | **Water puts the fire out.** A flooded trench through a forest douses the burning trees and the glowing char; steam rises thin. | Sim: a tree's `burn` ends where the water depth reaches the standing minimum; the steam is VFX's | One scan of the trees and scorch records in the box, when a fill's front crosses it (once per hole): **estimate 20 to 60 us**. Fire's own tick is measured at 30 us on 66 trees | The tree state is already hashed | Steam kept thin so it never hides a tell (rulings 16) |
| **D1** | Lake **drains** through a trench cut in its bank; a river **carries** things. | Sim state: a mutable lake level, a flow | A level per lake plus a flow rule; any real version is a 2D shallow-water step | Real state to hash | See 5. Not low impact |

C1 and B1 can share the same record shape later: B1 is the long, slow one (a front and a pool), C1 the short, fast one (a crest).

## 3. B1 in more detail (the one that needs design)

- **Source, found once.** When a crater, trench or groove record is made with its dug depth at least `fill.minDug` (6 units), look for a source around it, in a ring of 8 directions at 4 radii out to `near.reach` (about 1,150 units): the sea (field height under SHORE_WET), a lake (`recordWater`), or the biome's water table (`table`). Keep the *level* it would stand at, or none. The answer is memoised per store box (1,024 units), as a derived index like the store's own grid (not hashed, rebuilt on demand), so a beam's fifty groove samples cost one search. A search is about 32 field reads at 61 us (measured, cold) so at most 2 ms once per box; cap two searches a tick and let the rest wait a tick (deterministic order).
- **The record carries the answer.** The level goes into one of the record's free numbers (the store has 16 slots; counting the kind, craters use 12, scorch 9, trenches 11), so it is folded into `storeHash` and rides the state digest. No new array, no Simulation line beyond the store reader.
- **The read.** `WorldField.recordWater` gains one case: for a point inside a flood-eligible record's reach, depth is `level - (field + heightDelta)` where positive, times the front's fraction `clamp((tick - t - delay) / fillTicks, 0, 1)`. "Connected" is the source test at the record; inland holes have no level and stay dry (the water-v2 rule: no flooding inland). The sea rule for a lake of 75+ units deep follows with no change (`seaMin`).
- **The strip.** `WorldWater.depthOf` already takes `max(S.water, nativeDepth)`; the flood joins nativeDepth, so a swing turns the pool with the world. `nativeLevel` stays the ring's own water: the floor never lifts a fighter in a dug pool (rulings 2026-10-30 row 5).
- **What it will not do.** Never trap, slow or hurt (rulings 15 and 17). A flooded crater in a town is a look.
- **The cue.** The built `water_fill` event, with the source as a planet point instead of a strip x. Rendering's crest shader needs no change except where it reads x.

## 4. Pick

**The first playable (view-first, little or no sim):**
1. **A1 plus the ring wave (C1 for a point): wakes and splashes.** Every dive, skim and slam reads as water, on every sea and lake in the game, for the price of uniforms. The sim half (the ring's 1 bh push) is built for gen 2 and only needs the point form.
2. **A2 plus C1 for a line: the parted sea and its rush-back (C10, first beat).** It is the headline and it is mostly view: the groove is a shader on the beam's segment, the wave is the C1 record. The sim keeps the 90-tick timer (Combat's TIDE CLEAVE `part.openTicks`) and the push.
3. **A3 wet shore.** A free finish for 1 and 2 (the wave visibly reaches the beach).

**Next:**
1. **B1 holes fill, with B2 the fire put out (C10, third beat; the fill rules Orb already asked for).** Needs the store change and the source memo, so it follows the first playable. It is where the "environment answers back" is strongest, and it is deterministic and rollback-free by construction.
2. **A4** (bobbing debris, river streaks) whenever Rendering has a free evening.
3. **D1** is parked.

This order puts the biggest design risk (B1's state) after we have seen the cheap ones on screen, and Orb sees water react to everything before it sees it fill.

## 5. What I would not do, and why

- **Fluid simulation of any kind.** A 2D shallow-water step on a 64 x 64 patch is 4,096 cells a tick: in GDScript on the web that is milliseconds, against a 4 ms slice rule. A GPU ping-pong in a SubViewport needs the Compatibility renderer's feedback path and an iGPU's fill rate; the old laptop is the budget (ADR 0011). Nothing here needs it.
- **Water that climbs, flows downhill or carries bodies** (rivers with a current, a lake that drains). Each is a state that moves and so a thing to hash, replay and keep out of the way of a fight. D1 is the rung where that starts.
- **Tides or rain.** The shoreline is a sim rule (the sea's wet ground); moving it changes where fighters stand.
- **Reflections and refraction.** An extra pass; flat facets are Art's look (`water.gdshaderinc`).

## 6. Flash and reduced motion

- The register counts at most three full flashes in any second across the whole screen, weighted by area. Rings, drops, splashes and shock rings are already classed "not a flash". The two things that could count are the **parted sea** (a large area changing at once) and the **rush-back** (a large crest). Rules for the build: the groove opens and closes by *movement* of its walls over at least 0.3 s, never by a step or dissolve (Orb's taste, 2026-10-18); foam stays hard bands of pixels; no per-frame random, no sparkle on the surface; the crest has one rise and one fall; a `water_part` source asks the register with the groove's area, and under reduced flashing the walls move but the foam is dropped.
- **Reduced motion** is view only for every A rung (fewer drops, no bob, walls still move). The sim rungs behave the same either way, so the match key does not change.
- Flash clips for both modes run before any report of a look change, each rung alone.

## 7. Gates for the build (when it is released)

A `flood_check` for B1 (inland dry, coast fills, front by tick, a swing turns the pool, the same state twice, the store hash changes with the level); a `surge_check` for C1 (push by band, expiry, 4-record cap); `fill_check` and `sea_rules_check` stay; the golden, gen 2 soak and determinism byte-identical with the switch off; `water.json` grows `surge`, `part` and `flood` blocks and its schema in the same commit; the full `world-checks --run` including script-error counts.

## NEEDS FROM EP

- **Game Design's map row**: A, C1 and B1 as the three beats of C10; the push (2 bh, item 8) and the ring (1 bh, item 16) stay as ruled unless they say otherwise.
- **Rendering**: the gen 3 water sheet (the sea's shore waits for the tile park) and the shader's A1/A2 uniforms; A2 is the one to flash-clip.
- **Simulation**: a `surge` array on the state and its digest line (C1); the flood case in `SimField.nativeDepth` (B1). Both small, neither started.
- **Combat**: the TIDE CLEAVE `part` row (waits on Orb's pick of the name, RL-175 cleared).
- **VFX**: spray, drops and thin steam for A1, C1 and B2.
