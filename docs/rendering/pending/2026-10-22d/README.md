# Parked: the ring's turn on screen (Rendering, 2026-10-22, re-cut)

**Base:** HEAD 7a79d0e0 plus two parks:
- World's window 3 as committed in 3947e02a (`docs/world/scratch-build/calm-turn/calm-turn-window3.diff`). Apply it with `--exclude=sim/world/contact.gd`, which is on main. It now carries the pick's tick and `cancel`, so Encounter's `grant_world.cjs` refuses and isn't needed.
- Encounter's calm-turn park (`docs/director/pending/calm-turn/`: `ct.cjs` and `grant_sim.cjs`).

Notes on the base:
- This park also applies on HEAD plus window 3 alone. Without Encounter's park no `calm_turn` cue comes, so the host never warms, and World's swap reads the ring on its own tick.
- Every check ran on copies of the commit, never on the tree.
- The gates, probes and bench ran on f04372ec with the window 3 of that time and Encounter's park. None of this park's files changed since, and the carry zone World's swap fades across is the same.

**Apply order** (each from the project root, with `git -c core.autocrlf=false apply`, or the park's own scripts):
1. World's window 3.
2. Encounter's calm-turn park.
3. This park: `docs/rendering/pending/2026-10-22d/batch.diff`.

Then delete this folder.

## What it changes

At World's `arena_turn` every pane makes its ground, far rows, buildings and crowd again from the new world, in that frame: a hard cut, with no dissolve, fade or wipe. Camera decides the cut's moment and shot, so its cut must be on that tick. The host reads a picked ring ahead, each sim tick, at the rate Encounter's `calm_turn` cue asks in `k`.

| File | Change |
| :--- | :--- |
| `render/core/main.gd` | `_arena_turn`: every pane's planet built again, the heat's turn, the sky's towns |
| `render/core/planet_view.gd` | the far rows follow the world (`_built_cols` on `S.planetCols`), not only its length; the ground's meshes carry no biome colour |
| `render/shaders/terrain.gdshader` | each column's biome read from the ground texture's biome row, as the far land does |
| `render/core/ground_field.gd` | `far_again()`; the far rows' smoothing as a running sum |
| `render/core/impact_fx.gd` | `turn(px)`: the heat fades across the zone as World fades the marks |
| `render/core/sky_drive.gd` | `towns_again(S)`: the towns made again, keeping their glow round the pair |
| `render/core/sim_host.gd` | `warm_k` from the `calm_turn` cue; `WorldEpoch.prewarm(S, warm_k)` every sim tick until the turn lands |
| `docs/rendering/arena.md`, `docs/rendering/README.md` | the turn, the warm-up, what they cost, what was checked |

## Checked

The details are in `arena.md`, "The turn, checked".

- **The rebuild:** after a turn, and after a planet match that follows another, every pane's biome, far rows, base heights and buildings match the sim. Without this park, a planet match that follows another on the same length draws the first world's colours, which is a bug on main now.
- **The warm-up, with Encounter's park:** in 13 picks the host warmed at each pick's `k`, and the ring was read one tick before the hold asked.
- **The cost on the web build:** at k 32, the transformation scene's frame on the iGPU is within its baseline (plus 0.3 to 0.5 ms at the median), so k 32 fits a full form pause at 4,800. k 64 adds about 4 ms on the iGPU and 7.6 ms on the RTX.
- **Gates:** `gates9` (17 checks) and `cue_check` on the re-cut tree.
- **Stills against d3f1ca0e** (uncommitted, from the first cut; the re-cut changes only the warm-up): `docs/rendering/img/turn-4939-d3f1ca0e-play.png` and `docs/rendering/img/turn-4939-wide.png`.
