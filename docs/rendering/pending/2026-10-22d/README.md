# Parked: the ring's turn on screen (Rendering, 2026-10-22)

**Base:** HEAD 79693404 **plus World's window 3** (`docs/world/scratch-build/calm-turn/calm-turn-window3.diff`; its `sim/world/contact.gd` part is on main already, so apply it with `--exclude=sim/world/contact.gd`). This park reads `S.epoch`, `WorldEpoch` and the `turn` block of `rings.json`, so the window must land first. Every check ran on copies of the commit, never on the tree. The gates ran on 826bb6cd plus the window; none of this park's files changed since.

**Apply order** (each from the project root, with `git -c core.autocrlf=false apply`):
1. World's window 3.
2. This park: `docs/rendering/pending/2026-10-22d/batch.diff`.

Then delete this folder.

## What it changes

At World's `arena_turn` every pane makes its ground, far rows, buildings and crowd again from the new world, in that frame: a hard cut, with no dissolve, fade or wipe. Camera decides the cut's moment and shot, so its cut must be on that tick.

| File | Change |
| :--- | :--- |
| `render/core/main.gd` | `_arena_turn`: every pane's planet built again, the heat's turn, the sky's towns |
| `render/core/planet_view.gd` | the far rows follow the world (`_built_cols` on `S.planetCols`), not only its length; the ground's meshes carry no biome colour (`_biome_col` gone) |
| `render/shaders/terrain.gdshader` | each column's biome read from the ground texture's biome row, as the far land does |
| `render/core/ground_field.gd` | `far_again()`; the far rows' smoothing as a running sum |
| `render/core/impact_fx.gd` | `turn(px)`: the heat fades across the zone as World fades the marks |
| `render/core/sky_drive.gd` | `towns_again(S)`: the towns made again, keeping their glow round the pair |
| `render/core/sim_host.gd` | `WorldEpoch.prewarm` a few columns a frame once a turn is decided |
| `render/core/look.gd` | `TURN_WARM_COLS` 16 |
| `docs/rendering/arena.md`, `docs/rendering/README.md` | the turn, what it costs, what was checked |

## Checked

The details are in `arena.md`, "The turn, checked".

- **Probe:** after a turn, and after a planet match that follows another on the same length, every pane's biome, far rows, base heights and buildings match the sim.
  - Without this park, 837 columns were wrong after a turn, and 2,298 of 2,400 after a planet match that follows another. That second one is a bug on main now.
  - The sky's towns no longer raise their script error.
- **Time:** the render's rebuild costs 17 to 26 ms. The whole turn frame is 29 ms with the ring warmed, and 330 ms cold, nearly all of that World's read.
- **The look:** the default world and a planet world are pixel-identical with the biome moved into the shader. `gates9` (17 checks) and `cue_check` pass with 0 script errors.
- **Stills against d3f1ca0e** (uncommitted): `docs/rendering/img/turn-4939-d3f1ca0e-play.png` and `docs/rendering/img/turn-4939-wide.png`.
