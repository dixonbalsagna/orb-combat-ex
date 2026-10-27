# match-start: a match's start in pieces (parked)

Owner: Simulation and Engine. 2026-10-27, on the EP's brief after Performance's phone freeze (`docs/perf/phone-freeze-2026-10-26.md`). The page is `../../match-start.md`.

## What it changes

| File | Whose | What |
| :--- | :--- | :--- |
| `sim/core/sim.gd` | mine (`match_start.py`) | `newMatch` is `beginMatch` and its `MatchJob` run to the end: `step()`, `progress()`, the pieces `_mHead`, `_mFighters`, `_mSetupsA/B/C`, `_mEnd` (every line as it was, in its order) |
| `sim/core/tools/parity.gd` | mine (`match_start.py`) | "the match's start in pieces" |
| `sim/world/terrain.gd` | World (`grant_world.py`) | `genWorld` is `genBegin` and `genStep` (`GenJob`) run to the end, every line as it was |
| `render/core/sim_host.gd` | Rendering (`grant_rendering.py`) | `stepped_start`, `match_job`; `new_match` runs the head and leaves the rest to `load_step`; `_started`; `loading`, `load_phase`, `load_progress`, `cancel_load` read the job |
| `render/core/main.gd` | Rendering (`grant_rendering.py`) | `host.stepped_start` for the game's main (not a tool's, not `--syncstart`); the boot's split view attaches after the match is built when it starts in pieces |

The state is the same however the start is stepped: **the golden does not move.**

## Apply

On main (fe1d3d23 or later), from the repo root, in one commit, in this order:

```
python docs/architecture/pending/match-start/grant_world.py .
python docs/architecture/pending/match-start/match_start.py .
python docs/architecture/pending/match-start/grant_rendering.py .
```

or `git -c core.autocrlf=false apply docs/architecture/pending/match-start/match-start.diff`.

## Results

Proved on a `git archive` export of fe1d3d23 with the three scripts applied (9490ac21 touches none of the five files, nor `sim/` or `data/`). `match-start.diff` is 5 files, sha1 10163ff3e0ba; applied to the base's files it gives the proved copy, 0 files differ.

- **Golden byte-identical** to HEAD's. Parity 76 of 76, with "the match's start in pieces": the stepped start equals `newMatch` for no intro, the skipped intro and a planet's setup (planet 7, touch 3), with another sim (planet 13) stepped between every two pieces, then 120 ticks hashed. A refused start touches nothing.
- npm 5 of 5, determinism and determinism `--intro`, the seam sweep, flash count, validate 269, self-test 9154, QA 7 of 7, the loader, flash self-test 95, lint.
- **All 19 render gates** (Rendering's 15, city, effects, hash, split sweep) and anim_check: no FAIL, no script errors.
- **World's 38 checks** in `sim/world/tools/`: none fails.
- **The game's cold boot**, natively, stepped and `--syncstart`: no script errors. Stepped, the boot's match is 18 pieces, the longest 6 to 8 ms (the fighters' piece, the first loads of the fighter data), the ground's slices 2.5 to 5.5 ms; the match is built at frame 16. `--syncstart` builds it at frame 0, as before.
- **The campaign episode** (`campaign_episode.gd`, arc c0ffee00c0ffee00) prints the same stage and run hashes as the base, line for line.
- **Boot marks at 4x** (Performance's freeze probe, `docs/perf/tools/freeze-probe.mjs`, on web exports of 9490ac21 with `hook-bootprof2.mjs`, a mark when the match is built and, for the pieces, a scratch mark around each step; the CPU load was 39 to 60% when each probe started, so the machine was not saturated):

| | Before (HEAD) | After (the park) |
| :--- | :--- | :--- |
| `start_match` in `_ready` | 6.8 s (the sim's part and the host's resets about 0.3 s; `_match_built` 6.5 s) | 0.1 s (the head 0.2 ms, and the intro record) |
| The sim's start | inside it | 18 pieces, a frame each: **the longest 32.7 ms** (the fighters'), the world's 1 to 22 ms, the setups 2.5 to 6.3, the intro 9.7, the mood 7.5; the host's `_started` 6.3 ms |
| The boot's main-thread blocks | **one of 46.1 s** | **18.3 s, then 0.7 s of loading frames, then 23.8 s** |

The two blocks left are not the sim's. The first is the engine's start, `_ready` and the first frame's draw (4.3 s). The second is `_match_built` (pane 0's build, about 6.5 s at 4x) and the first match frame with the render warm-up. Rendering and Animation have these.
