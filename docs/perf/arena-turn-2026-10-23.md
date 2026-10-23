# The arena turn's cost, and the first crater in the web build (2026-10-23)

Owner: Performance and Platform, for the EP (standing brief, item 4, and the first-crater question). Build: clean `git archive` of HEAD (89b604de) in a scratch export, web export, Tools' hook in auto mode (one tick per animation frame, reduced mode), one browser at a time, every run valid by the load rule. x4 is Chrome's 4 times slower CPU (an old laptop's CPU, not its GPU); "Radeon" is the integrated GPU.

## How the turn was measured (and what is staged)

- **A Half planet arena** (planet 7, touch 3, 2,400 columns), AI against AI, with World's turn on (`setup.arena.turn`) against the same match with it off (`turnoff`): the matches are the same until the decision, so the frames of the two runs line up tick for tick. Three seeds (1, 2, 3).
- **The turn is staged.** On main as it stands, the director almost never makes a calm moment that turns the ring in AI play (six Half-ring matches, 0 asks; with Encounter's parked calm-7b applied in scratch, 2 asks and 0 turns), and the director's own switch (`calmTurn.enabled`) is off as shipped. So the hook does what the director's ask and pick do, at tick 10: `WorldEpoch.ask` (with the 60 s gap between turns reset, which is not what is measured), then `WorldEpoch.choose` with the largest bearing (10 degrees), k = 32 columns a tick, the fallback ring at 2.5 degrees. The director's switch stays off, so World's own calm decides when the swap happens: the first calm tick after both rings are read (tick 115 or 153 here). The turn and the rebuild are the real code.
- **What is read:** the frame times, and the game's own timers on the turn's frame; `arena_turn` events mark the tick; and a scratch timer in `main._arena_turn` and `PlanetView.build` splits the rebuild.

## The turn's frame

The swap tick's frame, with the turn on, and the worst frame in the same ticks (-5 to +45) of the same match with it off, in ms:

| Config | Turn frame (3 seeds) | Worst frame, switch off | 60 Hz frames it spans |
|---|---|---|---|
| RTX | 56.5, 39.9, 38.0 | 11.5, 9.1, 6.9 | 2.3 to 3.4 |
| Radeon | 59.9, 58.4, 42.4 | 15.0, 10.8, 8.6 | 2.5 to 3.6 |
| RTX at x4 | 278.6, 262.7, 221.8 | 66.9, 42.1, 33.5 | 13 to 17 |
| Radeon at x4 | 271.2, 258.5, 240.3 | 86.2, 61.6, 33.9 | 14 to 16 |

- **As the EP guessed, the turn drops frames at the cut**: two to three and a half 60 Hz frames on the RTX and the Radeon (a single frame of 38 to 60 ms against 4 to 8 ms), and a quarter of a second on the old-laptop CPU. The frame after it is a catch-up (0.3 to 16 ms) on some seeds.
- **Nothing lasts after it**: the 45 ticks after the cut cost the same as the switch-off match (mean frame within 0.5 ms on the RTX and Radeon, within 1 ms at x4; p95 within the spread). The low, wide shot and its easing back add nothing measurable here.
- **The warm phase before the swap is not free on a slow CPU.** For the 75 to 140 ticks while the sim reads both rings (k = 32 each, 64 columns a tick): RTX +0.9 to +1.1 ms a frame (64 columns at 17 us); Radeon none (it is GPU-bound, the extra hides); at x4 on the RTX +5 to +8 ms a frame (frames 29 to 32 ms against 23 to 24) and on the Radeon +2.5 to +5 ms (64 columns at 88 us). A p95 frame goes from 33 to about 49 ms during it.

## What the turn's frame is made of

The game's timers on the turn frame (seed 1; ms; x1 / x4):

| Part | RTX | RTX at x4 |
|---|---|---|
| The sim's swap step (World) | 8.7 | 38 to 46 |
| Rendering's rebuild (`_arena_turn`: every pane's `planet.build`) | **30.5** | **141 to 151** |
| The rest of `_arena_turn` (the impact, far land, sky towns) | 1.2 | 5.3 |
| The first draw after it | the rest of the 38.5 / 225 ms |  |

The rebuild, split by timers inside `PlanetView.build` (the turn builds three copies: pane 0 builds its own, pane 1 and the inset take pane 0's data; x1 / x4 ms):

| Piece | x1 | x4 |
|---|---|---|
| Freeing the old copies' nodes (3 panes) | 9.0 | 43 |
| Making the new copies' nodes (3 panes; 9 copies each on a Half arena) | 7.6 | 36 |
| **Together: node churn** | **16.6 (59%)** | **79 (61%)** |
| `refresh(S, true)` (pane 0) | 5.1 | 24.0 |
| The props' data (buildings, trees, crowd; pane 0) | 3.5 | 14.4 |
| The ground field rebuild (pane 0) | 1.7 | 7.4 |
| Stub textures, lanes, crowd materials (3 panes) | 1.1 | 5 |
| Not accounted for | 2.4 | 11.8 |

## A split (proposal)

The rebuild reads the swapped state, so its **data** cannot be built a tick before the swap (the ground inside the carry zone is the blend, the buildings and people are the carried ones). Its **structure** can:

1. **Keep the copies (Rendering).** A turn never changes the arena's length (`_built_nc` is the same), yet `build` frees every `Copy` node and makes them again. Keeping the nodes and their meshes and MultiMeshes and refilling only the data takes the 59% away: **the rebuild goes from about 30 ms to about 14 ms at x1, and from about 145 to about 60 ms at x4**; the turn frame from 38 to about 22 ms (1.3 frames) on the RTX, from about 225 to about 145 ms at x4 (the sim step and the rest of the rebuild remain). This is an estimate from the timers, not tried.
2. **If the nodes must change, make them ahead (Rendering).** Build the new empty copy trees during the warm phase (75 or more ticks of room), swap them in at the cut, and free the old ones over the ticks after (spread `queue_free`). That moves the same 59% off the swap tick without relying on keeping the old ones.
3. **The inset's copy** is 6.1 ms (28 at x4) of pure node churn; if the copies stay it nearly disappears, if not, rebuild it when its strip next opens.
4. **`refresh(S, true)`** (5 ms, 24 at x4) can run on the first tick after the cut, behind it, if the cut's shot does not need all of it on its first frame (Rendering's call).
5. **World's swap step** is 8.7 ms (40 at x4); what dominates there (the fresh-laid places, the lanes rebuilt, the carry fade over the zone) is World's to say. The graft itself must stay on one tick; any part that is only preparation (a fresh place's layout) could be done in the warm ticks.
6. **The warm phase:** at k = 32 on two rings a slow CPU pays 5 to 8 ms a frame for 75 to 140 ticks. A smaller k for the weak tier (k = 16 halves it, doubling the ticks) or reading the fallback ring only when the pivot is uncertain are Encounter's and World's levers.

Not a fix: pre-building the whole scene "a tick before, hidden by the cut" (the data is not there), and a faster cut (the cost is in the frame, not in the shot).

## The first crater: does wasm add a first-call cost to the sim's dig and scorch?

With my own timers (`PaneWorld.PT`) on the AI match at x4, valid, two runs; the first crater (tick 238) against the later craters of the same match (ticks 862, 938, 951, 970, 1026); ms:

| | frame | `host_advance` (sim step and its drain) | view update | `planet_update` | `fighters_update` |
|---|---|---|---|---|---|
| First crater (238), runs 1 and 2 | 54.9, 66.9 | 14.8, 12.6 | **37.9, 31.5** | **13.7, 12.0** | 7.1, 5.1 |
| Later craters (5 of them, both runs) | 17.5 to 45.7 | 9.6 to 17.2 | 12.0 to 18.6 | 4.2 to 5.9 | 2.1 to 3.7 |

- **No web-only first-call cost in the sim**: the first crater's `host_advance` (12.6 to 14.8 ms) is inside the later craters' range (9.6 to 17.2), so the sim's dig and scorch step does not hitch on its first call in wasm. (Simulation's native result, the sim being +0.2 ms of the first crater's host tick, agrees.)
- **The first crater's extra cost is on the render side**: the view update is 20 ms heavier (31 to 38 against 12 to 18), of which the planet view's refresh is +8 ms (13 against 4 to 6), the fighters' view +2 to 4 ms, and the rest (about 10 ms) is the first draw of what a crater adds (a material or buffer used for the first time). At x1 this whole frame is 160 ms before the warm-up and cleared after it; at x4 it is 55 to 67 ms.

## Files

`make-audit-sites.mjs` variants `turn`, `turnprof`, `turn7b`; `scratch-hooks/hook-turn.mjs`, `hook-turnprof.mjs`, `hook-calm7b.mjs`; `frame-bench.mjs` (`turns`, `turnWindows`, `turnDebug`, `craterRows`). Raw runs are in my scratch folder.
