# Geometry the picture does not need, and the warm-up draw (Rendering, 2026-10-17)

Performance's audit (`docs/perf/audit-2026-10-16.md`, sections 3.6 and 5) gave Rendering four items:
- **The water mesh** is the terrain's grid: 171 k primitives drawn under a city with no sea in view.
- **The whole crowd** is drawn every frame: 259 k primitives.
- **Both HUDs** are rebuilt every frame by `main.gd`.
- **First-use hitches** of 150 to 510 ms at the same ticks of every match.

The rule for each answer: the sim and every pixel stay as they were.

## The crowd: chunks the camera culls

The crowd was one MultiMesh of every figure on the planet. It had a planet-wide culling box, so all of it was drawn whenever its copy was in view.

**What changed.** `render/core/crowd_chunks.gd` (`RenderCrowdChunks`) cuts the crowd into chunks. A chunk is a contiguous run of crowd indices whose spots lie within `RenderLook.CROWD_CHUNK` (4,000 units) of each other along the planet. Each chunk is its own MultiMesh with a culling box around its figures, padded by `CROWD_CHUNK_PAD` (400 units: a figure is 59 units tall, twice that boosted). The planet view and the flight make the same calls as before, by crowd index.

**Why the pixels are the same:**
- **The idle hop's phase** comes from the figure's index. Each chunk's material carries its first index (`id_base`), and `INSTANCE_ID + id_base` in `crowd.gdshader` is the index the single MultiMesh had.
- **A runner the flight carries out of its chunk's box** (to a shelter, or across the seam) widens that box. The box is not narrowed again in the match, so no figure is culled while it could be seen.
- **The figures are opaque and depth-tested**, so drawing the chunks in another order changes nothing.

**What it saves.** On seed 1 the city has 751 figures, not the audit's 1,800: the crowd's spacing (`city-variety.md`) already cut them. They fall into 11 chunks. A camera window draws, on average over the planet:
- 3,000 units wide: 5% of them;
- 8,000 units wide: 8%;
- 20,000 units wide: 16%.

The crowd's primitives therefore fall from 259 k to a few tens of thousands at fight framing. The cost is a few more draw calls: one per chunk in view, about 2 to 4 instead of 1.

## The water: drawn only where it can be

**When a water chunk draws nothing.** A water chunk's surface shows only:
- on a column holding water;
- on a land column within `SHORE_COLS` (16) of one, where the shore keeps the water's level;
- in the far rows, on a column whose far terrain the meander takes from up to `MEANDER` (9,600 units, 300 columns) away.

So a chunk with no column holding water within the wider reach (plus `WATER_REACH_SLACK`, 4 columns) of its own draws no pixel. The sea's columns are always full, and water only spreads a column a step from a wet one (`sim/world/water.gd`). So this holds whatever a match digs.

**What changed.**
- `PlanetView._water_show` hides those chunks.
- The ground field counts the water's changes (`GroundField.water_version`), and each pane decides again only when the count moves. A second pane can see a change a frame late, which the slack covers.
- The far mesh (the whole planet at the coarsest stride) is always drawn.

**What it saves.** On seed 1, 14 of the 31 water chunks have no water within reach: 231 k of the planet's 558 k water triangles, and each of the 5 planet copies hides them.

The EP's brief said "a coarse mesh". A coarser grid would move the shoreline and the horizon's bend between vertices and change pixels. Hiding the chunks that cannot draw does not.

## The warm-up draw

**The probe.** The hitches land at the same ticks every match, so I ran a first-draw probe: Tools' staged scenes, headless through the capture hook. Each tick it lists every shader drawn for the first time. Its ticks are one after Performance's:

| Scene | Performance's hitch | First drawn at that tick |
| --- | --- | --- |
| beam in the city (`signaturecity`) | 427 (155 to 230 ms) | 428: VFX's `trail.gdshader` |
| ring of three | 211 (216 to 307 ms) | 212: VFX's `crack.gdshader` |
| ring of three | 279 (363 to 484 ms) | 280: VFX's `beam.gdshader`, `beam_glow.gdshader` and Camera's `panel_mask.gdshader` (the inset) |
| ring of three | 154 (300 to 396 ms) | nothing drawn for the first time: not a shader. Perhaps a first sound, the HUD's first glyphs or the inset's render target; for Performance to time with the warm-up on |

The beam scene's first beam, crack and shards come at tick 83. That is inside Performance's 120 frames of warm-up, so it was not measured.

**What changed.**
- `render/core/warmup.gd` (`RenderWarmup`) draws each effect's shader once at boot, behind the flashing-effects notice:
  - VFX's beam, beam glow, crack, trail, shard, transform, facade holes and the tremor's dust;
  - Rendering's particle, flash, glow and guard;
  - Camera's two masks.
- MultiMesh shaders are drawn with each mix of instance colours and custom data.
- It draws into its own 64-pixel viewport, which no one shows. That viewport shares the pane's world, so the shaders are built as the game builds them. Its camera and quads stand a million units under the planet, and it frees itself after three frames.
- `main.gd` starts it after the pane is built. It does not run in a tool's main, and the page argument `nowarmup` skips it, to measure with and without.

**Who keeps the list.** A new effect's shader joins `RenderWarmup.SHADERS`. Performance's budget table asks for "no new first-use hitch", and VFX and Camera own most of the entries.

## The HUDs' redraw

`main.gd`'s `render_view()` asked both HUDs to rebuild their draw lists every frame. Now:
- **UiHud is no longer asked.** It draws nothing itself: its layers redraw when their own content changes. This is UI's line (`docs/ui/pending/hud-cache/main-redraw.patch`), taken as it is.
- **The greybox HUD redraws when what it draws changes** (`hud.gd` `redraw_key`). That covers the demo's prompt, the overlay, touch, the screen's size, the seed, the tick and the pause; the legacy view and the perf readout redraw every frame.
  - UI's patch redrew it on every tenth frame instead. In a match its corner line shows the tick, so that would leave the number behind for up to nine frames and change those pixels.
  - With the change rule, a match still redraws it every tick. Pauses, frozen ticks and the demo's still prompt no longer do.
- UI's `hud_check` passes before and after: 4,719 checks.
- The HUD's real cost, 330 of 382 draw calls, is UiHud's layers. UI's texture cache (`docs/ui/pending/hud-cache/`) addresses that.

## Proof

- **Determinism and the sim:** on af5151b5 all 17 render gates pass on the batch. On d9cbba71 all pass but the depth check, which fails the same way on HEAD alone: since Simulation's depth window (46734840), a held pair drifts in depth inside a tick, and the lane cues hold the pair's mark at their level. Determinism passes plain and `--intro`, as do the pane, flight, ground, seam, shape and city checks and UI's `hud_check`. The sim is not touched.
- **Pixels:** the plan is frame-for-frame captures of `mashcity`, `signaturecity`, `ring` and `collapse` before and after, against a repeat of the same build as the noise floor. Pose stills differ by 1 to 2 k pixels in the street's crowd band between two captures of one build, and collapse in reduced mode diverges after tick 910 between two runs of one export. These wait for the end of Tools' record run.
- **Primitives and the hitches:** Performance's frame-bench against the same commit, after the record run.

## The warm-up's world (2026-10-22)

Performance's report on the live demo (`docs/perf/inset-hitches-aura-2026-10-22.md`) found two first-use hitches left with the warm-up on:
- the AI match's first hit, tick 131, about 90 ms;
- its first crater, tick 238, about 160 ms, about 55 ms of it Camera's strip.

**What the time was.** A Chrome trace of the 238 frame, on Performance's web repro through Tools' launcher:
- Three shader programs were linked in that frame: VFX's `beam_scar` and `crack`, and the beam's prisms.
- The page waited on each link while the browser compiled its Direct3D shaders (`D3DCompile`, 15 to 69 ms each).
- Nothing on the ground's path (the crater's deformation, the heat) compiled.
- The same stage code had been compiled at boot, all but one to the letter, but in other variants. One boot variant lacked the tonemap and scene-data blocks.

**Why.** `main.gd` started the warm-up with pane 0's world before the split view moved pane 0 into its own SubViewport (`own_world_3d`). So the warm-up drew into the world the pane had left, without the pane's environment (its sky and tonemap), and compiled variants the game never draws with.

**The fix.** The warm-up starts after the split view attaches, with pane 0's own world. With `--nosplit` the pane stays in the window's world, which is then its own.

**Measured** (`frame-bench --scene ai --reduced --ticks 400`, the web export, every run valid by the load rule):

| Build | Strip | Hitches over 50 ms |
| :--- | :--- | :--- |
| HEAD | off | 131 (76 ms), 238 (164 ms) |
| the warm-up after the split view | off | none; none but one 59 ms frame at 143 in one run |
| the same, with VFX's real crack and beam meshes too | off | none; none |
| the warm-up after the split view | on | none (worst frame 12.8 ms) |

**What was tried first, without effect** (both still in the old world):
- drawing the real beam (its prisms and `VfxBeamLook`'s materials) and a mesh in the crack's vertex layout;
- drawing the warm set under the pane's camera at boot. The camera's near plane, set on the first frame, clipped it.

**`BeamView.prism_mesh()`** is the one source of the beam's prism (16 sides, 24 rings), for the view and for anything that warms its first draw.

## The ground by band (2026-10-22)

Performance's frame-pacing report (`docs/perf/frame-pacing-2026-10-22.md`) found the AI match on the integrated GPU missing 60 Hz in stretches, and the ground's triangles growing over the match. World's reading (`docs/world/scratch-build/frame-cost/README.md`): craters change texels, never the mesh. The count follows how many ground chunks the frustum keeps.

**Why so many.** Each 320-column chunk was one mesh for its finest rows (within 400 units of the fighter plane) and one for all its middle rows, from 9,000 units in front of the plane to 9,000 behind. The coarsest rows were one mesh for the whole ring, from 120,000 behind to 1,000,000 in front. The frustum culls a mesh only when all of it is out of view. So:
- a chunk whose back rows reached the wide horizon drew all its rows;
- every far mesh drew its rows in front of the fighter plane, which are behind the camera and can never show: about 40,000 of its 63,600 triangles;
- each copy of the ring the view reached added another far mesh.

The water is the same grid again.

**The fix.** One mesh per run (one stride on one side of the fighter plane; the finest run spans both sides) and per chunk. So the frustum culls each band on its own.
- The coarsest runs are cut into chunks of `FAR_CHUNK_COLS` (1,280).
- The finest run's chunks come first (`near_chunks()`, the rows with the fighter plane's exact row).
- The water follows the same split. Its far chunks are always shown, as before, since the far rows read other columns' land (`far_x`).
- The vertices and the shader are unchanged.

**Measured** (the AI match as Performance's bench plays it, 6,000 frames on the integrated Radeon; Performance's `frame-bench` with its perf hook; every run valid by the load rule):

| Build | p50 | p95 | Frames over 16.7 ms | Over 25 ms | Median triangles | Draw calls |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| main (2 runs) | 9.8 to 9.9 ms | 23.5 to 23.9 ms | 812 to 837 | 116 to 162 | 359 k | 108 |
| by band (2 runs) | 7.5 to 8.1 ms | 17.6 to 18.0 ms | 349 to 388 | 40 to 55 | 140 k | 118 |

- **In view, the ground's triangles fall from 108 to 193 k to 23 to 62 k** (a native count of the meshes inside pane 0's frustum along the match).
- **What is left is one very wide shot** (ticks 5,870 to 6,120: the view about 7,800 units across). There the ground is still about 176 k triangles and the frame 19 ms; with the ground cut it is 7 ms.
  - Camera's strip is not it: the same with `nopanel=1`.
  - A stride that coarsens with the zoom would take it, but it would pop where it switches. That is a look decision, not taken here.
- **The look** (seed 4, reduced): pixel-identical at ticks 500, 4,000 and 5,500.
  - At tick 2,000, 136 pixels differ by 1 to 14 levels (127 of them by 1 or 2) on a translucent effect at a fighter's side. That is a changed blending order of see-through draws, with the water's far mesh now in chunks.
  - Repeat captures of each build are identical, so the difference is real but invisible.
- **The checks:** `ground_check` and `seam_sweep` pass with the new layout, as do the other render gates.

## The first crater on an old laptop (2026-10-22)

Performance's frame pacing (`docs/perf/batch-e09dbbbf-2026-10-22.md`): with the warm-up fixed, the AI match's first crater (tick 238) is still a 67 to 69 ms frame on the old-laptop bound (the integrated GPU, Chrome's CPU throttle 4). Frames of 50 to 60 ms follow at 240 to 270.

**What the frame is.** Per section, over its median frame:

| Section | x4 on the web (four runs) | Native, ms |
| :--- | :--- | :--- |
| the host's tick (the sim, VFX's hub, the consumers) | +9 to +13 | 0.6 (drained) + 0.7 (VFX's consume) |
| VFX's layer | +7 to +10 | 1.0 |
| the planet's update (the ground, the props) | +7 to +10 | 1.0 (deform scan 0.3, shore 0.3, upload 0.3) + 0.2 |
| the beams (Rendering's view, its first beam) | +2.6 to +3.9 | 3.4 |
| the fighters | +1 to +2.5 | |

Camera's strip opens on the same frame, adding 31 draws and about 460 k triangles. It is no one cost: every owner's first work at a crater lands in one tick.

**What this changes:**
- **The beam view** loads the beam look's data (`VfxBeamLook.warm()`, `data/vfx/energy.json`) and makes its first slot at boot: three layers with their materials, hidden. Natively the first beam's frame cost 3.35 ms in the beams and now 0.27.
- **The ground's deform scan** compares runs of 64 columns in the engine and walks only the runs that changed: the same columns, in the same order. Natively 0.34 ms becomes 0.20 at the first crater.
- **The first crater's native frame** goes from 10.1 to 7.2 ms.
- **On the web at x4** the beams' share falls from 2.6 to 3.9 ms to 2.0. The frame itself moves within the noise of these runs (medians of 17 to 28 ms between valid runs).

**Measured and not changed:**
- **The ground texture's upload** (the whole 400 KB image whenever the heat or the scorch changes) is about 1 ms a frame at x4 during a fight's fires (planet update median 2.05 against 3.10 ms with the heat and scorch uploads cut in a timing build).
- **Splitting the heat and scorch rows into their own small texture** would save that on most frames after a crater. Done the same day: see "The scorch and the heat on their own".
- **The rest of the first crater's frame** is VFX's, the host's (the sim and its consumers) and the strip's.

## The scorch and the heat on their own (2026-10-22)

A fight's fires change the ground's scorch and heat every tick, and the ground field (`GroundField`) uploaded its whole texture each time: 21 data rows of every column, about 400 KB at 4,800 columns.

**The change:**
- The scorch and the heat are their own small texture (`hot`, two rows, `htex`), uploaded when they change.
- The whole field is uploaded only when the ground's shape, water or cracks change.
- The shaders read them with `gh()` (`ground.gdshaderinc`): the grooves' width (`groove_half_at`) and the terrain's char and glow.
- `row_bytes()` answers the scorch and heat rows from `hot`, so the checks read what the shaders read.

**The look:**
- Pixel-identical against the build without it, seed 4, at ticks 250, 280, 500 and 1,500 (reduced) and at 250 and 1,180 (normal).
- A control build with `hot` left unbound changes 258 pixels at tick 1,180 in normal mode, so the scorch and heat are on screen there, and the split draws them exactly.
- Under Reduce flashing they do not show in these frames: the calm look keeps the heat at 0.
- `img/heat-split-1180.png`, uncommitted: the build without it on the left, with it on the right.

**The cost** (the AI scene as the hook plays it, ticks 240 to 400, after the first crater):
- **Natively:** the whole field is uploaded on 23 frames instead of 57, and the uploads' mean falls from 0.108 to 0.041 ms a frame. The small texture's uploads are each under 0.1 ms.
- **On the web at x4** (Performance's repro, four valid runs, interleaved): the planet update's median over those ticks is 1.2 and 2.3 ms with it against 1.0 and 1.3 without. That is within the noise of runs on a shared machine (one run's frames were twice as slow as the others'). The timing build that cut the scorch and heat uploads altogether measured about 1 ms a frame at x4.
