# Parked: the ring's turn on screen (Rendering, 2026-10-22, re-cut twice)

**Base:** HEAD 6fd83f6d plus World's window 3 as committed there (`docs/world/scratch-build/calm-turn/calm-turn-window3.diff`). Apply it with `--exclude=sim/world/contact.gd`, which is on main.
- The ring is warmed in the sim (World, with Encounter's calm turn). This park takes no part in that: rendering never writes the sim.
- It needs only window 3's `arena_turn` event, and World's `turn` data for the carry zone.
- Every check ran on copies of the commit, never on the tree.

**Apply order** (from the project root, with `git -c core.autocrlf=false apply`):
1. World's window 3.
2. This park: `docs/rendering/pending/2026-10-22d/batch.diff`.

Then delete this folder.

## What it changes

At World's `arena_turn` every pane makes its ground, far rows, buildings and crowd again from the new world, in that frame: a hard cut, with no dissolve, fade or wipe. Camera decides the cut's moment and shot, so its cut must be on that tick.

| File | Change |
| :--- | :--- |
| `render/core/main.gd` | `_arena_turn`: every pane's planet built again, the heat's turn, the sky's towns |
| `render/core/planet_view.gd` | the far rows follow the world (`_built_cols` on `S.planetCols`), not only its length; the ground's meshes carry no biome colour |
| `render/shaders/terrain.gdshader` | each column's biome read from the ground texture's biome row, as the far land does |
| `render/core/ground_field.gd` | `far_again()`; the far rows' smoothing as a running sum |
| `render/core/impact_fx.gd` | `turn(px)`: the heat fades across the zone as World fades the marks |
| `render/core/sky_drive.gd` | `towns_again(S)`: the towns made again, keeping their glow round the pair |
| `docs/rendering/arena.md`, `docs/rendering/README.md` | the turn, what a warm-up costs a frame, what was checked |

## Checked

The details are in `arena.md`, "The turn, checked".

- **The rebuild:** on 6fd83f6d with window 3, after a turn (World's swap with the rings warmed) and after a planet match that follows another, every pane's biome, far rows, base heights and buildings match the sim. The rebuild takes 25 ms and World's swap 10 ms.
  - Without this park, a planet match that follows another on the same length draws the first world's colours. That is a bug on main now.
- **The look:** the default world and a planet world are pixel-identical with the biome moved into the shader.
- **Gates:** `gates9` (17 checks) and `cue_check`, with 0 script errors.
- **What World's warm-up costs a frame on the web build** (the same `RingJob` read, by a scratch switch, on the transformation scene):
  - at k 32 the iGPU is within its baseline;
  - at Chrome's CPU throttle 4 nothing holds 16.7 ms, the baseline included, and k 32 adds 24 ms.
- **Stills against d3f1ca0e** (uncommitted, from the first cut; the re-cuts change only the warm-up): `docs/rendering/img/turn-4939-d3f1ca0e-play.png` and `docs/rendering/img/turn-4939-wide.png`.
