# Rendering's batch of 2026-10-17 (parked)

The EP's brief of 2026-10-17 had three parts:
- Performance's audit: the water, the crowd and the first-use hitches;
- city variety's switch split, with Legal's neighbour gate;
- Controls' haptics patch.

All of it is in `batch.diff`, built and gated in Rendering's scratch. Nothing is in the tree.

**Base:** built and gated on af5151b5 with Rendering's city batch, since committed as 80d92d65. Every file the diff touches is the same at HEAD 70cf2fe6, so it applies there as it is. The captures will be redone on the newest HEAD, because Camera's merge lookahead and World's sliced planet load change the scenes.

**Apply** from the repo root:

```bash
git -c core.autocrlf=false apply --check docs/rendering/pending/2026-10-17/batch.diff
```

```bash
git -c core.autocrlf=false apply docs/rendering/pending/2026-10-17/batch.diff
```

`core.autocrlf=false` keeps the files LF. With it, every file comes out byte for byte as gated: checked on a copy of the base, never on the tree.

## The pieces and their files

| Piece | Files |
| --- | --- |
| **City variety's two switches and Legal's neighbour gate** (w05, RL-144) | `render/core/look.gd` (`CITY_TINTS` on, `CITY_FACADES` off), `render/core/shapes.gd` (`city_data`, `CITY_SLOTS`, `NO_FACADE`), `render/core/planet_view.gd` (the sky glass follows `CITY_TINTS`), `render/shaders/building.gdshader` (the facade code only with a facade), `render/tools/city_check.gd` and its `.uid` (new) |
| **Controls' haptics** (b1fd310d, as committed) | `render/core/main.gd` (one connect and `_on_haptic`, `_play_haptic_step`) |
| **The crowd in chunks the camera culls** | `render/core/crowd_chunks.gd` and its `.uid` (new), `render/core/look.gd` (`CROWD_CHUNK`, `CROWD_CHUNK_PAD`), `render/core/planet_view.gd`, `render/core/crowd_flight.gd`, `render/shaders/crowd.gdshader` (`id_base`) |
| **Water only where it can be** | `render/core/look.gd` (`WATER_REACH_SLACK`), `render/core/ground_field.gd` (`water_version`), `render/core/planet_view.gd` (`_water_show`) |
| **The warm-up draw** | `render/core/warmup.gd` and its `.uid` (new), `render/core/main.gd` (started after the pane; not in a tool's main; `nowarmup` skips it) |
| **Docs** | `docs/rendering/geometry-and-warmup.md` (new), `docs/rendering/city-variety.md`, `docs/rendering/README.md` |

`look.gd`, `planet_view.gd` and `main.gd` carry more than one piece, so the batch is one diff.

## What is proved, and what waits for the machine

**Proved in scratch:**
- All 17 render gates pass: the 16, plus the new city check.
- Determinism passes plain and `--intro`.
- Controls' `haptics_test` passes: 34 checks.

**Measured headless:**
- The crowd is 751 figures in 11 chunks. A camera window 3,000 to 8,000 units wide draws 5 to 8% of them.
- 14 of the 31 water chunks have no water within reach: 41% of the water's triangles.
- Every hitch the audit measured except ring tick 154 lines up with the first draw of one of VFX's shaders, Camera's inset mask among them (`geometry-and-warmup.md`).

**Waiting for the end of Tools' record run** (no captures until then):
- The city clips with the tints on (A and B). With everything on, collapse normal failed by the pooling; the tints alone are not measured yet. If they fail, `CITY_TINTS` goes back to false before commit.
- Frame-for-frame captures before and after, against a repeat of one build as the noise floor, for the crowd, the water and the warm-up.
- Performance's frame-bench for the primitives and the hitches.

**Not in this batch:**
- UI's patch for the HUDs' redraw: not received.
- The world light and the flight over land: next.
