# The view update's bigger cut: the building sweep by view (Rendering, 2026-10-29)

Brief: `docs/ep/cloud-briefs/rendering-pane-sweep.md`, run locally in the shared tree (no branch, no commit). Base: main 40d5ee92.

## SUMMARY

The source planet's refresh no longer visits every building every frame. It visits:
- the buildings a pane can show: each pane hands in its camera's frustum, cut to the props' depths;
- the buildings this frame changed, wherever they stand: events, debris, hits, sinks, drops, the district flight, the ground, people on the way;
- 16 of the rest in turn, as a safety net.

A second pane, and Camera's inset, sweep their own view in their own draw, after the first pane's refresh and before anything is drawn.

- **Switch:** `PlanetView.pane_sweep`, on by default (`RenderLook.PANE_SWEEP_ON`). Main's `--nopanesweep` keeps the A/B.
- **Picture:** unchanged at every frame wherever a pane can see. The proof is `render/tools/sweep_check.gd` (below): 0 differences in 12,000 frames. No building out of view was ever behind.
- **Cost** (loaded machine, INVALID, side by side): visits 122 to 22 a frame. At x4:

| | 27l | the sweep by view |
| :--- | :--- | :--- |
| the building sweep | 1.66 ms | 0.56 ms |
| the planet's update | 2.71 ms | 1.61 ms |

## CHANGES

- `render/core/planet_view.gd`:
  - the sweep by view: `view_span`, `see`, `see_more`, `_visit_list`, `_touch`, `_sweep_index`, `unseen`;
  - the refresh's per-building body moved unchanged into `_visit`, and its second pass into `_grow_pass`;
  - tools-only `record_writes` / `writes` and `ctl_slice_only`.
- `render/core/pane_world.gd`: each pane hands its view to the sweep before the planet's update.
- `render/core/main.gd`: `--nopanesweep` (one line, after `--noviewfast`).
- `render/core/look.gd`: `PANE_SWEEP_ON`, `SWEEP_SLICE` (16), `SWEEP_PAD` (200).
- `render/core/crowd_chunks.gd`: tools-only `record` / `rec`.
- `render/tools/sweep_check.gd`: the proof (new).
- `docs/rendering/tools/prof-hook.mjs`:
  - the `pv_see` and `pv_swept` parts;
  - lets a scratch page set `noviewfast` and `nopanesweep` (the shipped page's `URL_ARGS` are untouched).
- Docs: `docs/rendering/view-update.md` (the sweep by view, its proof, the bench), and the README's checks table.

## DECISIONS

- **What changed out of view is found from the events.** Every sim path that changes a building's hit points, floors or standing throws debris from its x or names it: `damageBuilding`, the floor and pancake paths, kill's evacuate.
  - The district flight moves people every tick with an event only every half person. Its buildings and its shelter (`WorldCollateral.shelter`, this frame's and the last's) are visited while it runs.
- **The view** is the frustum's span over the props' depths, at any height. A building counts within `_reach` of it: its parts, its figures' spots, plus 200 units.
- **The slice is 16.** On these planets it passes over every building in about 8 frames. In the check it never had anything to catch.
- **`unseen()`:** a host that restores and re-runs the sim without draining the re-run's events calls it, and the next refresh visits everything. Online play does not draw yet.

## The proof (`sweep_check.gd`; every frame compared)

**Method:** a twin planet view sweeps every building every frame from the same match and events. For every building in any pane's view it compares:
- each instance's last written transform and colour;
- the cut and window texels;
- the drawn height, stage, top and footing; the marks, spread, drop and sink;
- the figures at home;
- every runner, wherever it is.

It also checks the views with geometry of its own: any building whose parts or figures a camera's frustum overlaps, seen from above, must be in that pane's view.

**Scenes:** the city at tier 3 (the pair set down by the tallest tower) and gen 2 planet 7, seeds 4 and 12345, 1 and 4 ticks a frame, split attached. Every frame of 2,400 ticks each, with 88 to 586 frames a scene drawing a second pane.

**Result:**
- All 8 scenes pass. Buildings in view a frame: 4 to 15; visited a frame: 22 to 33; up to 84 building changes a scene.
- Control A (the sweep cut to its slice): 10,884 differences in view found.
- Control B (the props' depths narrowed): 609 buildings a view left out found.

## Gates (scratch: HEAD 40d5ee92 + the six files; each gate's last line, exit 0)

- **sweep check:** "sweep check passed".
- **golden:** written in the scratch tree, byte-identical to HEAD's `sim/core/test/golden.json`.
- **determinism:** "determinism passed", plain and with `--intro`.
- **seam_sweep:** "seam sweep passed".
- **split_sweep:** "split sweep passed".
- **The other render gates:** open, depth, shape, patch, pane, stage, lane, ground, after, sky, flash register, HUD words, flight, city, cue and flash each print "... passed". City's last line lists its switches.
- **The collapse clip** (`check-clip`, this build's own export):
  - normal: PASS 2 / 2.5 / 1;
  - reduced: PASS 2 / 2.5 / 1;
  - HEAD (`--head`): the same in both modes, PASS 2 / 2.5 / 1.

## Look evidence: scenes to capture (side-by-side against HEAD, both flash modes)

1. **The collapse clip:** the city comes down in view; its people flee and shelter.
2. **A split over a town.** Gen 2 planet 7, seed 4, AI against AI: the frames where the second pane frames buildings the first doesn't, for example a launch across the planet into a town.
3. **A town damaged out of view, then seen.** A beam or a blast through a town off screen, then the camera's pan or cut onto it: the buildings must be drawn as hit, at once.
4. **Sheltering:** runners arriving at a shelter that comes into view as they arrive.
5. **The 4-ticks-a-frame case:** any of the above at x4 (the bench's throttle).

## NEEDS FROM EP

1. **The gate set:** add `sweep_check.gd` to the render gates and CI. It takes about 2.5 minutes, one Godot process.
2. **Netcode, when online play is drawn:** call the source planet's `unseen()` after a restore whose re-run events are not drained to the planet.
3. **Tools:** `tools/flash/head-export.mjs` hands GNU tar a backslashed `-C` path, and tar reads `\6` in it as an escape. My scratchpad holds `\60bff52c...`, so `check-clip --head` failed ("Cannot open"). It works with Windows' tar first on PATH. Forward slashes in the path would fix it.
4. **A quiet window** for the bench (the recipe is in `view-update.md`).

## RISKS

- **A change with no event, out of view,** waits up to about 8 frames for the slice. None was seen.
- **Within one frame** (x4, several ticks): if the flight's heavy x moves twice, or its shelter changes twice, the middle one's buildings wait for the slice.
- **The view hand-off costs 0.21 ms at x4** (8 frustum corners, 12 edges). It can be trimmed if it matters.
- **The test hooks** (`record_writes`, `ctl_slice_only`, `RenderCrowdChunks.record`) cost one check each per write, off.

## NEXT

The broken-props brief waits on one question (its premise).

World's W6 NEEDS 4 assumes the view draws the sim's props. It does not:
- W5's NEEDS 2 ("draw the props from `propsIn`") was never briefed or built;
- the band's cover is render-side, seeded by the ring's hash, and is not the sim's props.

So the brief first needs that props pass.
