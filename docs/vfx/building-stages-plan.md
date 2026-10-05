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

## Built (2026-10-05, against World's committed event, bca8f34 and section 10)

`render/vfx/stages.gd` (`VfxStages`), four small methods in `debris.gd` (`stage_glass`, `stage_shed`, `stage_skirt`, `stage_smoke`), the hub's `stages_enabled` flag (`VfxLook.STAGES_DEFAULT`, on), tests in `effects_check.gd` (`_stages()` and `_real_stages()`). Numbers are `VfxStages.DEFAULTS` (code; an optional `data/vfx/stages.json` is read if it exists, none is created).

**What World's section 10 changed in the plan, and how it is handled**
- **Jumps are common** (0 to 3 about 40 a match, 0 to 2, 1 to 3, 0 to 4): what is drawn is the union of the steps a jump crosses (`VfxStages.crosses`). Glass if it crosses 1; the big shed, a skirt and a smoke belch if it crosses 3 (the small shed is subsumed, so a 0 to 3 draws one shed); the small shed and skirt only for a jump that stops at 2. To 4 draws nothing.
- **About 240 events a match and up to 69 in one tick**: the whole tick's events are read first (so a `floor_hit` for the same building, which comes before its stage event, dedupes the small shed), sorted nearest-fighter first, and drawn at full strength for 6, 40% for the next 14, 12% for the rest, and a token chip and puff each once the per-tick budget of 300 bits is spent (none past 1.6 times it). A real 16,000-tick match (seed 12345) sent 68 stage events (0 to 1: 7, 0 to 2: 25, 0 to 3: 31, 0 to 4: 5; busiest tick 56) and the pool never passed its 460 cap; a test with 69 mock events in one tick spawns 368 bits.
- **A shell is a hit-point state**, not a ruin: the effect is the same wherever a stage 3 came from, and nothing assumes the floors are gone. A tower with cut floors stays stage 2 and keeps the floors' own bursts.
- **Stage 1 is by damage only for now**: the glass shower is for damaged buildings; the shock-wave windows stay VFX's `react.blowouts` until `wmask` lands.
- **The shell's smoke is read from state**: every 10 ticks the nearest 4 shells within 3,500 units of a fighter (`WorldStructures.stage(b) == 3`) let one thin grey puff rise every 30 ticks, 12 alive at most, none at quality low or in reduced motion; it stops when the building falls. In the real match above: 105 puffs.

**Quality** thins every count (high 1.0, medium 0.7, low 0.35, reduced motion half; the plume off at low and in reduced motion): a 0 to 3 jump spawns 40 bits at high, 20 reduced, 14 low.

**Pictures** (web build, the event SENT for the tallest front-row building near the start, the state not changed; fighters 2,000 apart): `bs-glass-0to1.jpg` (a shower of pale glass from the facade), `bs-shell-2to3.jpg` (panels, dust and a belch of smoke), `bs-jump-0to3.jpg` (the common jump: glass, the shed and the smoke at once), `bs-many-69.jpg` (69 events in one tick: the building near the fighters at full strength, the rest thin).

**Legal (k01, k02, noted, no change needed now).** The stacking rule counts at most two of the seven marks at any tick, a held tell or a 45-tick charge checked at every tick. The stage effects are consequences of a blast on a building (glass, cladding, smoke), not the "rubble ring with ground crack and wind" mark, and they never run at a fighter's tell. They are world debris with no lane colour, no flash and nothing on a fighter, so they add no mark to a tell. If a stage event lands during a fighter's crouch-and-scream or lightning tell and Legal counts the world answering as a mark, the one place to look is a jump 0 to 3 drawing its smoke at the same moment as a rubble ring; the effects here can be dropped to glass only at that moment (a flag per tick on `hub.stages`) if Legal asks.

**Needs from Rendering (not edited by me):** the building's own look at each stage (the shell's stripped cladding and dark inside, the windows out) is Rendering's from `WorldStructures.stage(b)`, `curH` and `fmask`; my glass, panels and smoke are drawn over it. In the staging stills the building is not changed (the state is not), so the panels fall from an intact facade; in play the standing height drops with the stage.
