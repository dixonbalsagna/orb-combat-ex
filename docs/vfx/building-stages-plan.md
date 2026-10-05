# Building stages: what VFX will draw (plan, 2026-10-05)

Owner: VFX. Status: a plan, no build until World's slice is committed (the EP's word). Reads: `docs/world/staged-destruction.md` sections 2 and 6, `docs/world/window-blowouts.md`. Orb's words (questionnaire 15): "pavement should crack and shatter differently from dirt, can windows shatter + multiple levels of dynamic destruction per building".

## What I read (all from World's list, nothing new asked)

- **The event**, once a change of stage: `building_stage {b, from, to, x, y, z, w, h, kind, cx, owner, n}`. `b` indexes `S.buildings`; `from` and `to` are 0 intact, 1 windows out, 2 a part gone, 3 a shell, 4 rubble (a blow past two thresholds is one event, 1 to 3; a building levelled at once 0 to 4); `x` centre, `y` ground, `z` depth, `w` width, `h` the standing height after, `kind` house or tower, `cx` the blast's x (glass and panels fly away from it), `n` the floors lost in the step.
- **The query**, any time and seek-safe: `WorldStructures.stage(b)`, `curH(b)`, `b.fmask`, `b.fdmg`, `b.hp / b.maxhp`.
- **Today's events stay**: `building_hit` (the hit's burst), `floor_hit` and `floors_fall` (the floors' detail), `building_fall` (the collapse), `chain_link`. To stage 4 the stage event comes beside `building_fall`.

## The rule that keeps it from doubling up

The stage event adds **what the change looks like**, not the hit: `building_hit` already throws the blast's own burst. So a stage effect is a different look from the burst (glass, panels, a plume), and it is skipped when the same tick already draws the same thing: no stage-2 shed when `floor_hit` or `floors_fall` for that building is in the tick (the floor path draws its burst, as `floored` does today), nothing for `to == 4` (`building_fall` has the collapse), and a 0 to 4 or 1 to 4 event is ignored.

## The effects, by step

| Step | What is drawn | How |
| :-- | :-- | :-- |
| **0 to 1, windows out** | A shower of glass from the facade floors that face `cx`: 8 to 20 pale glass chips (the biome's glass tone, `VfxPalette.glass`) thrown out and down away from `cx`, a few bright flecks, a thin pane-line crack across a few windows is Rendering's (the window texture). No flame, no flash | `debris.chunk`-style bits in the pool (glass tone, short life); count by the floors that face the blast, scaled by quality |
| **1 to 2, a part gone** | A sheared corner or the cut floors: a dust skirt along the sheared edge (4 to 6 puffs) and a shed of cladding panels (6 flat slabs falling from the top third of the facade, away from `cx`). Skipped when `floor_hit` or `floors_fall` is in the tick | debris puffs and flat chunks; the panels tumble |
| **2 to 3, a shell** | The cladding stripped: a bigger shed (10 to 14 panels from the whole facade), a low dust skirt round the base, and a **smoke plume** that starts here and goes on while it stands | puffs and chunks, then the ambient emitter below |
| **1 to 3 in one event** | Both effects, the glass shower first | |
| **to 4** | Nothing new (`building_fall`'s collapse) | |

Scale: the glass and the panels grow with the building's width and with the blast's closeness (the distance `|x - cx|` against `w`), never with the owner. No lane colour (the world's debris, not a fighter's mark), no white or gold flash, nothing at the fighters.

## A shell keeps smoking (state, not event)

A stage 3 building should look wrecked on a seek or a late join too, and an event cannot do that. So a small **ambient emitter reads `WorldStructures.stage(b)` each frame** for the buildings on screen (the nearest four shells only): one thin grey puff rising from the highest standing point about every 0.5 s, a slow drift, 2.5 s of life, never more than 12 alive. It has no memory (no state to save, nothing in the hash) and stops the moment the building falls. The dark inside seen through the shell, and the windows being out (from `wmask` when World's record lands), are Rendering's.

## Budgets and ordering

- Debris pool only, no new draw call: a stage burst is at most about 40 bits (a 0 to 3 jump); the per-tick spawn budget and the 460 cap already cap a chain, and a blast that steps ten buildings at once draws the nearest first and thins the rest by quality (high 1.0, medium 0.7, low 0.35, reduced motion half and no flecks), as the other building effects do.
- The plume emitter: at most 12 puffs, only for shells on screen, off at quality low and in reduced motion (a single still wisp instead).
- At most four events a building, about a hundred a match (World's numbers), so the cost is bounded.

## Determinism and tests

Presentation only: the events are read, the cosmetic streams (`vfx.dust`, `vfx.shard`) draw the randomness, `S.rng` is never touched. `effects_check.gd` cases when built, with mock `building_stage` events: each step draws its effect; the dedupe (no shed with a same-tick `floor_hit`); `to == 4` draws nothing; a 1 to 3 jump draws both; the pool stays within its cap in a chain; the ambient emitter caps at 12 and stops when the building is gone; reduced motion and quality low counts. `hash_check.gd` and `determinism.gd` unchanged. A web still of each step with a staged event.

## What I need

- **World:** the event as listed (nothing more); `wmask` landing is what lets stage 1 hold across a seek, and it is Rendering's to draw.
- **Rendering:** nothing for my side. Their stage query drives the window texture and the shell's look; my glass, panels and plume are over it.
- **Art (optional):** panel and cladding tones per biome if the palette's dust and glass tones do not read as a house's or a tower's facade.
