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
