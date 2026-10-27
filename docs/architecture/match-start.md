# A match's start in pieces

Owner: Simulation and Engine. 2026-10-27, on the EP's brief after Performance's phone freeze (`docs/perf/phone-freeze-2026-10-26.md`). There, the boot's `start_match` was one main-thread block: 1.1 s on this PC's web build, 4.8 s at 4x CPU, 7.9 s at 6x. Parked at `pending/match-start/`.

## 1. Where the time goes

Measured natively on HEAD with timers in a scratch copy, cold boots (the first start in a process):

| Part | Native, cold | Whose |
| :--- | :--- | :--- |
| `start_match` in all | **about 1.5 s** | |
| The intro record (`_match_setup`) | 15 ms | Rendering |
| `SimCore.newMatch` | 55 to 115 ms (26 warm) | Simulation |
| — of it, the world (`WorldTerrain.genWorld`): the ground's heights 18 to 20 ms, the settlements and lanes 13 to 15 ms cold (3 warm), the rest about 5 ms | 22 to 50 ms | World |
| — of it, the first loads of the data (fighters, the setups' switches, contact) and the intro and mood | about 30 to 60 ms | Simulation |
| The host's resets (sky, camera, effects, audio cues) | 17 ms | Rendering |
| **Pane 0's build** (`_match_built`, `p.build`) | **680 to 820 ms** | Rendering |
| **The first `render_view`**, with Animation's pair bake (about 500 ms, "pair bake: 663 poses") | **655 to 815 ms** | Rendering, Animation |

- **The planet, the ground, the structures and the civilians are about 25 to 50 ms of the 1.5 s.** Civilians are each building's count, made with it.
- **About 92% of the block is the scene's build and the pair bake.**

## 2. The sim's start in pieces (`SimCore.beginMatch`)

- **`SimCore.beginMatch(S, seed, ai, setup)`** makes a `MatchJob`.
  - **`step()`** runs one piece and is true when the match has started. **`progress()`** (0 to 1) is for the loading screen.
  - **`newMatch` is the job run to its end**, so the state is the same however it is stepped, and the golden does not move.
- **The pieces** are `newMatch`'s own work, in its own order, cut at its seams:
  1. the head;
  2. the world:
     - World's `GenJob`: the ground 1,200 columns a piece, then the smoothing and the platforms, then a settlement a piece, then the lanes, then the people, the trees and the arrays;
     - a planet's world in one piece;
  3. the fighters;
  4. the setups, in three pieces;
  5. the intro;
  6. the mood.
- **Each piece binds the match's statics first** (the arena's length, a planet's biome columns, its generation). Another sim stepped between two pieces, such as a menu's demo, cannot change the match.
- **A refused setup** (`SimPlanetLoad.strict`, a gen 2 planet not made) is a job done at once that touched nothing.
- **Measured natively, cold:** 18 pieces for the boot's match. The longest is 6 to 8 ms (the fighters' piece, with the first loads of the fighter data). The ground's slices are 2.5 to 5.5 ms each.
- **Measured on the web at 4x** (Performance's freeze probe, a web export of 9490ac21 with the park): the longest piece is **32.7 ms** (the fighters'), under the brief's 50 ms. The world's pieces are 1 to 22 ms, the setups 2.5 to 6.3, the intro 9.7 and the mood 7.5. The head is 0.2 ms, and the host's `_started` is 6.3 ms.
- **The boot at 4x:** before, `start_match` was 6.8 s inside one main-thread block of 46.1 s. After, it returns in 0.1 s, and the block is 18.3 s, then 0.7 s of loading frames, then 23.8 s. The two blocks left are the engine's start and first draw, and `_match_built` with the first match frame (section 4).

## 3. The host (Rendering's lines, a grant)

- **`SimHost.stepped_start`** is the game's switch; the game's main sets it. A tool's host starts a match whole, as before, and so does `--syncstart`.
- With it on, `new_match` runs the head at once and leaves the rest to `load_step()`, one piece a frame. That is the path the planet's load already uses: `loading()`, `load_phase()` ("match"), `load_progress()`, the loading screen between the frames, and `cancel_load()` on Back.
- The rest of `new_match` becomes `_started(setup, remember)`, run when the match has started.
- **The boot's split view** (`split_view.attach`, which builds the follower panes and resets the split rig from the fighters) attaches at the end of `_match_built` when the boot's match is still starting. That is the same order as after a whole start.

## 4. What is not the sim's (for the EP)

- **Pane 0's build, 0.7 to 0.8 s** (Rendering): the ground, the buildings and the props built at once. Build them in pieces over frames after the match starts, as this does for the sim.
- **Animation's pair bake, about 0.5 s:** bake it ahead in pieces, or for the pair that is about to fight only.
- **The rest of the first `render_view`, about 0.17 s** (Rendering).
- **The intro record (15 ms) and the host's resets (17 ms):** small, but they are their own pieces at 4x and 6x.
