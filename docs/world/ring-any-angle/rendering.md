# Drawing a ground that swings (Rendering, 2026-10-31)

Orb picked the turntable, E and E2: the world visibly swings round the fighters (`docs/ep/vision.md`, end of "The fight's bearing"). This says how the view can draw that on the laptop target with the Compatibility renderer.

**No Godot ran for this.** Performance's quiet window is on, so nothing here measures a swing. "Measured" means someone's earlier run, and the source is named. "Counted" means read from the code. "Estimate" means my arithmetic, and it can be wrong.

## The answer

**It can be done, but not by changing today's ground: it needs a new ground renderer.** Today's near ground isn't 2D, so it has nothing to turn.

I recommend paged 2D tiles keyed to the planet. Each pane gets one frame uniform, and the vertex shader places every vertex from it.

- **A turn is then one uniform a frame.** No mesh is rebuilt, no texture is rewritten and no new height is read.
- **Flight is what costs.** It uncovers ground the pair hasn't seen, so the read budget sets how sharp the near ground can be while flying.
- **My estimate is that the frame gets no heavier than today's.** The GPU's real headroom on the laptop is unknown, so section 6's test comes before anything else.

The largest risk moves from "can the GPU draw it" to two other things. One is how much of the view's code reads columns. The other is whether World can give 2D ground at a budget near 4 reads a tick.

## 1. What the view draws today, and what assumes a strip

The sim's ground is one profile, `S.base + S.deform`, with 4,800 columns of 32 units. Everything else is derived from it.

| Layer | How it's drawn | What assumes a strip |
| :--- | :--- | :--- |
| **Near ground** (`|z|` under 9,000) | A fixed mesh of columns and rows. Height is `base(x)` plus craters, grooves and heaps | **`base` depends on `x` only.** The land behind the fighters is the plane's profile drawn straight back, so it has no 2D relief of its own. Rotated, it would show as ribs swinging |
| **Ground texture** | One RF texture of 24 rows by 4,800 columns (460 KB, counted), set whole when anything changes | Every value is per column. Crater lists, the shore level, rubble, biome and border zones are all indexed by column |
| **Far ground** (blends in from 9,000 to 16,200) | Default: the band's own columns wandering by `far_x`. `FAR_MAP_ON` is off, so the planet's own far map isn't used | The default far land is invented from the strip, so it isn't true to any bearing. The map (`far_dir`, `far4`) reads the planet by direction, which suits a swing, but it builds its direction from a column and a depth |
| **Mesh and copies** | 134 rows, 558,000 ground triangles a ring and the water grid again (counted), in culled chunks, with copies of the ring each side of the camera | World x is a column. Copies exist because the strip wraps |
| **Foreground rule** (`fore_fall`, `fore_cap3`) | Land in front of the plane falls below the sight line to the plane's own row | Reads up to 10 plane columns, twice, per vertex in front of the plane. It's camera-relative and worth keeping, but only ground and water obey it |
| **Panes** | Each pane has its own materials, camera and bend, and shares meshes and textures | Each pane culls by column range on a shared strip |
| **Lanes and streets** | Uniform arrays of depth strips, x spans and avenues, painted in the terrain shader | All streets run along x. A district has no angle of its own |
| **Buildings** | MultiMesh in strip x and z. Footing comes from `ground_at`, and `_mark_open` opens those in front of a fighter | Placed by column and depth row, and only rows 0 to 3 exist. Row 0 is the only row in front of the plane |
| **Props, cover, trees** | Whole-ring lists. The cover and trees read `ground4` in the vertex shader, so they stay on the drawn ground | Laid by column. The props' whole-ring query is 30 to 44 ms (measured, Performance) |
| **Crowd** | Chunks along x. Feet come from `ground_at` on the CPU | Chunks are runs along x, and the shader takes no bend (section 3) |
| **Water** | The same grid again, with the level from row 20 | Lips and shores are worked out by sweeping along columns (`_shore_levels`). A lake is a run of columns |
| **Sky** | `cloud_shift`, `sky_turn`, `star_turn`. Light by place on the lap | Already has an angle uniform (`sky_turn`). The day follows position on the lap, not on the planet |
| **VFX** | Particles and marks in strip x. 32 of 46 scripts in `render/vfx` read the strip's x or wrap, or take the camera's x (a search, not a reading) | Debris and scars would need to stay on the ground while fighters and beams stay in the view |

Counted across `render/*.gd`, outside tools and tests, 27 ground reads are in `ground_field.gd` itself. The next largest are `vfx/after.gd` (11), `anim_fighter.gd` (7), `vfx/debris.gd` (6) and `split_rig.gd` (6). That's a search for four patterns, not an audit.

## 2. The budget

From `performance.md`. The laptop is a 30 fps machine, stood in for by the dev PC at x4, so the frame is **8.3 ms at p95 at x1**.

- A quiet fight has about 2 ms spare, and a digging one has none.
- A steady render addition may be **0.5 to 1 ms**.
- A read may be **0.2 ms a tick, about 4 gen 2 reads**.
- A single spike may be **8 ms**.
- On the integrated Radeon the frame is already at its limit in wide shots: p95 of 26 ms during the wide opening shot at 227k to 451k primitives, against 10.9 ms at 147k once settled (measured, `coast-layer-cut-2026-10-27.md`). So **primitives and the terrain's fragment cost are the GPU levers**. No GPU timer exists on the web.

## 3. The options

| | **A. Re-laid columns** | **B. Near strip, far disc** | **C. Resident 2D, turned by a frame** |
| :--- | :--- | :--- | :--- |
| **What it is** | Keep the mesh. Each tick, rewrite the strip along the turned line | Keep the near band as it is. Turn only the far land and sky | Height in 2D tiles round the pair. The whole world turns rigidly |
| **Does it swing?** | **No.** Each row's ground changes shape, because depth is still the line's profile drawn back | **Only past the near band.** The fighters' own ground doesn't move | **Yes**, all of it |
| **Frame cost (estimate)** | Over budget many times: the whole sweep 28 ms, props 30 to 44 ms, texture set 1.2+ ms (all measured), each tick. The view's columns alone (668 of 4,800) are still over 8 ms | Today's frame plus about 0.1 ms of uniforms. The far map costs up to 12 fetches a vertex with slope, unmeasured | Turn: uniforms only, under 0.05 ms. Flight: reads held at 0.2 ms a tick, plus an upload about every 70 ticks. Drawn triangles about 100k to 150k against 147k to 451k today |
| **Memory (estimate)** | No change | Far map, already written: RGBAF 192 square with mips, plus two biome textures | About 5 MB of tile layers (90 tiles at 51 KB), against 128 MB target. A map and no ring copies |
| **What breaks** | Nothing in code, and the look is wrong | The near and far land disagree more as the angle grows. At 90° the near ribs run across the far land's grain | Everything in section 1 that reads a column. It's a new ground renderer |
| **The join** | None needed | **Hard.** Near is fixed and far is turned, so a ring between them has to shear by the whole angle. It's what `drift_tan` does for a few degrees; at 90° it's a visible smear | **Clean:** a radial height morph between levels, and rigid (below) |
| **Verdict** | Killed for the view. **The sim may still re-lay the plane's columns**, and that's not this table | Useful as a first look at the far land and sky, and it's Research's stage 1. It isn't Orb's pick | **Recommended** |

### How C works

**Tiles keyed to the planet.** A cube-sphere quadtree, as prototype E keys its nodes:

- Near tiles are about 2,048 units across.
- Coarser levels are 4 and 16 times that.
- A tile's data doesn't depend on any bearing, so it never needs rewriting when the fight turns.

**One small tile mesh, drawn by MultiMesh.**

- About 33 by 33 vertices, one draw call a level. Near vertices are 64 units apart, twice today's column spacing, and that's a look question for the test. About 16 near tiles in view is about 33k triangles (estimate).
- Each instance carries the tile's four corner directions on the planet and its layer in a `Texture2DArray`.
- There are no ring copies, because nothing wraps. The 30 to 45 ms of node churn in the swap goes with them.

**Partial uploads by layer.** The renderer's public update call replaces a whole texture, which is why today any dirty column sets 460 KB. `RenderingServer.texture_2d_update(tex, image, layer)` replaces one layer. A near layer is 65 by 65 texels, so marks can be 32 units apart, at about 17 KB each for height, marks and colour data: 51 KB a tile. A tile's 289 nodes at 128 units take about 72 ticks at 4 reads a tick, which is the upload rate in the table above. **The call is from the API as I remember it. I haven't read the Compatibility path, and section 6 tests it.**

**The frame uniform.** Each pane sends its pivot and heading on the sphere. The vertex shader maps a planet direction to the view by an azimuthal equidistant projection about the pivot. This fits for three reasons:

- **Turning about the pivot is exactly rigid** on this projection, at any radius.
- **The line through the pivot keeps its arc lengths,** so a sim column at `x` lands at view `x`. The plane row is the strip.
- **Moving the pivot is rigid on the sphere,** so vertices stay on their planet nodes and nothing swims. A grid fixed to the camera would crawl over the land, and the flat-shaded facets would show it. That's why I rejected a camera-fixed or polar grid.

So "turned by the camera" and "turned by the world" are the same maths. I'd keep the camera, fighters and beams in the view frame and turn the world. Camera's rig and the fighters then don't change at all. A flat chart won't do past the near ground: a flat map stretches a 12,000-unit circle by 476 units (arithmetic, planet radius 24,446).

**The join, without a seam or a pop.**

- Levels meet by CDLOD's morph: as distance from the pivot nears a level's edge, a vertex's height slides to what the coarser level has there. It's continuous in space, so there's no crack.
- The morph depends on radius, so it doesn't change during a turn at all.
- Today's `flag` snap row does a smaller version of the same thing.
- The far level reads the planet's map by direction, with the near blending into it the same radial way as `far_weight` does by depth today.
- This is geometry moving, not a dissolve or a fade (ADR 0010). It still goes through the look gate.

**The cost of what remains in the vertex shader (counted from the source).** A near vertex today makes about 10 to 22 fetches, and one in front of the plane up to about 50 more for the foreground rule. C's near vertex would read height, marks and water: about 3 to 6, plus the rule. The crater loop can go: a settled crater is baked into its tile's marks layer, with only the newest few kept live for their opening. A dig then touches 1 to 6 layers instead of the whole 460 KB, which also answers Performance's dig-frame finding.

### What flight costs

A disc turns free, but moving it uncovers an edge. With 4 reads a tick, radius `r` and node spacing `g`, flight at `v` needs `(2r/g)(v/g)/60` reads a tick. So at `r` 6,000:

| Speed | Spacing the budget holds |
| ---: | ---: |
| 1,000 u/s | 224 u |
| 3,000 u/s | 387 u |
| 6,000 u/s (launch) | 548 u |
| 10,000 u/s | 707 u |

So the near ground is about 512 units while flying flat out and sharpens to about 128 at rest.

- **Already resident:** the far map's finest texel is 400 units, at about 9 s to build a planet (`look.gd`).
- **At rest:** a 128-unit disc of radius 6,000 is about 6,900 reads, 373 ms native, against 259 ms for today's whole ring. It's a match-start cost, or 29 s at 4 a tick.
- **Error against the true column on gen 1:** 128 u, RMS 0.7, max 17; 512 u, RMS 4.7, max 60 (measured, Research). **Gen 2's rivers and shores may do worse.** World hasn't measured it.
- **Sharpening is the one thing here that can fail Game Design's test 7.** It's a height morph, and ground changing shape in view is what that test forbids. So tiles sharpen out of view first, ahead of the pair. A launch's arrival is known at its start, so its disc can be read during the flight: about 96 ticks at 4 reads a tick is 384 reads, which only covers a disc of radius about 1,400 at 128 units. Anything else sharpens in view, and the test will say whether that shows.

Tiles at 128 units are coarser than today's 32-unit columns. The rest would be a deterministic detail term, in the sim and the shader alike. That's World's and Simulation's call, because **the sim's plane must equal the drawn plane** or feet leave the ground.

Prototype E's "pop" column (2,347 ticks, largest 356 units) counts a column's height changing when re-laid. In a rigid drawing that isn't a pop: the ground moves smoothly under a fighter. Under Game Design's sweep limit it moves at most 75 units a second under a standing fighter, so on a 1 in 2 slope he rises about 0.6 units a tick. Lifting him is Simulation's, by Game Design's rule for a waded body.

### Split screen

Panes keep their own frames, each pivoted on its own fighter, with the line's heading carried along the great circle. The tiles and textures are shared, each pane gets its own MultiMesh, and a split means two discs of tiles. Both panes stay on one line, so Orb's rule holds.

Speed under a far fighter is settled: Game Design's rate falls with distance from the pivot, to a sweep limit of 75 u/s standing and 6,000 u/s airborne.

## 4. Keeping buildings, props and citizens attached

**One rule: nothing computes its own place.** Today each shader has its own: some take `bent_world`, some read `ground4`, some trust the CPU. A single `world_place()` include would take a planet anchor and a local offset, and every world shader would use it. Then a swing can't separate anything from the ground, because they all move by one function.

| Thing | How it stays attached |
| :--- | :--- |
| **Buildings** | Per instance: a planet anchor and heading. No per-frame writes in a swing. A building's position is stable only with **places by plan** (Research's stage 3, World), so this depends on that |
| **Cover, props, trees** | Per tile, filled when the tile comes in, which replaces the whole-ring queries. They read their foot in the shader, as the cover does today |
| **Citizens** | Per building, as today, with `world_place()` and a foot read from the tile. Running figures need their path in planet terms: `crowd_flight.gd` is Rendering's |
| **Streets** | Each district gets a frame, and the paint runs in it. The 16-span arrays probably suffice |
| **Water** | Per-node depth and level. **The lip rule I landed on 2026-10-30 sweeps along columns and won't carry over.** World needs a 2D answer for lakes and rivers |
| **Marks** | Baked into tile layers from the planet store (Research's stage 2) |
| **VFX** | Two roots: the view frame for fighters and beams, the world for debris, scars and fires. VFX's call |

**What swings into the foreground.** Today only row 0 stands in front of the plane, with its own holes and stubs (`_bld0`, `_front_mat`); after 90° half the world does. Land falls by the foreground rule, but **a mountain coming round would be seen sinking**, and that may read oddly. Buildings don't obey the rule at all: row 0's holes and stubs would have to work for any building, from the view frame. This is the largest look risk I can name, and it belongs in the test.

### Does the floating citizens problem share a cause?

**Yes, in kind. And the bug is now better evidenced than I told you before the pause.**

- **The evidence.** Before the pause I said the citizen stills showed feet on the ground on both builds. **That was wrong: I hadn't looked closely enough.** Enlarged, `docs/rendering/img/lookgate/crowd-g2-far-crop-head.png` (HEAD) shows the row floating against the wall, and `crowd-g2-far-crop-after.png` (with park 2026-10-30i) shows them on the street. They drop about 14 px at screen x 105 and about 5 px at x 300, as `bend × x²` predicts for offsets of 535 and 340 px. **That's one still at a close camera. Orb's wide view is still untested, and the park's collapse clip is still owed.**
- **The shared cause.** `crowd.gdshader` carries its own idea of where a thing is, and it missed the bend. A swing would add more of these errors, wherever a shader kept its own copy.
- **A second cause, which a swing would expose.** Citizens' feet come from `ground_at` on the CPU, not the drawn ground. Today that's fine: of 751 to 940 figures per world, none stand in front of the plane (a count on 2026-10-30). In a swing about half would, the foreground rule would lower the ground under them, and they would float again **even with the bend fixed**. So the feet must come from the same function as the ground.

Park 2026-10-30i fixes the first only. It stays parked as you said, and its README still carries my wrong sentence about the stills. It's frozen, so I've left it: please read this section as the correction.

## 5. Game Design's rulings and Netcode's question

None of this is measured. It's read from the code and worked out by hand.

**Netcode: can the near view's ground be a 2D height texture with the heading as a shader value? Yes. That is option C.**

- The view never re-lays columns, so the 1.7 to 3 ms doesn't arise in the view.
- It's drawn once per rendered frame, however deep the rollback, from the heading and pivot at that frame.
- A correction shows as the shown heading easing toward the sim's, no faster than the swing: a view-side value, with no extra draw work.
- **One condition for marks:** a crater must stay live, unbaked, until it's older than the deepest rollback, so a rolled-back crater never has to be unbaked from a tile.
- **One cost my summary left out:** a turn is one uniform only if the foreground rule doesn't need the plane's profile. That rule reads the plane across the whole view, wider than the sim's strip of about 170 columns. Sampling about 64 points from the tiles is my estimate of 0.2 ms a frame native, inside the 0.5 to 1 ms but not free. It's in the test.

**Test 7, the world turns as a solid thing: C passes by construction, with one exception.** Heights are keyed to the planet, and a turn changes only the frame, so no vertex's height changes. The radial morph doesn't change either, because radius is constant in a turn about a fixed pivot. A moving pivot is still rigid on the sphere. The exception is sharpening, in section 3. A re-laid view (A) would fail it, and that's another reason to rule A out.

**Test 6, a crater and a damaged tower swing away unchanged: yes for the crater, expected for the tower.** A crater is in a tile layer or the live list, in planet terms. A tower's damage is read by instance index (`cut_tex`, `stub_tex`, windows), which a turn doesn't touch. **I haven't audited whether any of it stores a world position**, such as where a stage's spread or a wall slam's dent starts. Any that does must become local to the building. The test pins this by comparison.

**An airborne fighter passing through a building face at up to 6,000 u/s: it holds with depth off, and not fully with depth on.**

At his place on the line, the world moves across the line, so to him and his camera a face arrives **in depth**, at up to 100 units a tick. A wall 300 to 800 units across passes in 3 to 8 ticks.

| | What happens | Holds? |
| :--- | :--- | :--- |
| **Depth off** (`S.depthOn`, the default today) | The hole is worked out every frame from his chest and has no easing. It cuts what's nearer than his chest less 30 units, so a face is cut from the tick it crosses him | **Yes** |
| **Depth on** | The hole is the patch. A tower takes it by a share that fades over at least 0.3 s (18 ticks) inside an area budget of 16,000 pixels a tick | **No, for towers.** It passes before it opens: he's hidden for up to about 8 ticks (0.13 s). I'd accept that as passing behind it, since it's brief. That's Orb's and Game Design's call. Raising the budget is a flash risk |

Changes it needs either way:

- `occluders` and the near list test boxes square to the strip, by `b.w`, `b.d` and `SimWrap.sdx`. They need the building's own frame and a 2D query.
- The building he's aimed at stays whole by the existing rule. If a sweep carries that one over him, he's inside a whole building. Game Design's ease to rest before arrival should prevent it.

**A larger problem than the fighter: the camera.** A building at about the camera's distance from the pivot passes through the lens. Nothing has to hit the fighter for that to happen, and at launch-speed sweep it arrives 10 to 30 ticks after it passes him. The near-tower rule (a lobby inside 600 units of the lens) fades over 0.3 s, and stubs sink over 0.2 s; at 100 units a tick both are too late.

**I'd give buildings the foreground rule:** every vertex above the sight-line cap is lowered to it, as a stub is, using the one value `fore_low` and no column reads. It has no state, so speed doesn't matter. The look risk is the one in section 4: towers would be seen sinking as they come round.

**Flash at the peak of 60°/s: a concern, unmeasured.**

- **Far scenery is inside Camera's bound.** The lens is 30° vertically, so far scenery moves 0.018 of the width a tick at 16:9 and 0.024 at 4:3, against 0.045 and 0.03 reduced. Game Design's 0.025 assumed 40°, which is the 4:3 case.
- **Near things are not.** A point at `z` in front of the pivot, with the camera `D` from it, moves `z / (D − z)` times the far rate, the other way. At 60°/s anything within 29% of `D` from the lens passes 0.045 at 16:9, and 35% at 4:3. Reduced mode's half rate is within 23% and 29% against 0.03. The sight-line cap above lowers most of this, not all.
- **The bound doesn't protect a city.** Camera's own note on a launch across downtown: 20 to 35% of the frame changing every tick at 0.041 to 0.052 of the width. A swing's far pan is under half that travel, but it's the whole picture moving, near towers included.
- **Pan haze won't help.** It reads the camera's x, which a swing doesn't move, and it ships off along with the whip. Orb rejected that kind of look (ADR 0010), so I wouldn't lean on it.
- **The aspect ratio matters.** Collapse reads FAIL in normal at 960 by 540 and PASS at the standard 1024 by 768, so a swing has to be read at 16:9 as well. Reduced is the take-down trigger under RL-208, so that mode counts most.
- **If a city clip fails,** the honest lever is a lower peak rate over tall places, as a sim-side rate from data, since rates are in the sim. That's Game Design's, and Legal should see the first readings.

## 6. Recommendation and the smallest test

**Build C behind a switch, but only after this test passes.** It's a new ground renderer, several windows of work, and it replaces most of `ground.gdshaderinc`, `terrain` and `water`. Today's strip stays the default until it's flipped. There's no byte-identical oracle, because true 2D relief changes the look on purpose. Only the plane row can be held to the strip.

**The test: one scratch scene, about 300 to 500 lines, one window. No sim, no game code.** It needs the quiet window to end.

- Planet 7's nodes baked to a scratch file at 128 units (radius 6,000) and 512 beyond, with the far map.
- Tiles, the `Texture2DArray` and the frame uniform; the real terrain colours if they come easily.
- Two boxes as fighters, boxes as buildings, and the real crowd and cover shaders on `world_place()`.
- A scripted swing at 60°/s, a full turn each way, then a flight at 6,000 u/s.
- A crater and a damaged tower in view, and one place of tall boxes with lit windows for the flash reading.
- Web export, through `frame-bench.mjs` and Tools' capture launcher, at below-normal priority.

| # | Question | Pass line |
| ---: | :--- | :--- |
| 1 | Can the laptop draw it? | On the Radeon and at x4: p95 no worse than the `pb` scene with the same drawn triangles, and under 1 ms more at x1 |
| 2 | Is an upload really one layer? | One tile under 0.2 ms at x1, and the same with 8 or 256 layers. **If it scales with the array, the plan needs separate textures or an engine patch** |
| 3 | Does anything leave the ground? | A foot-to-ground probe reads 0 px for every object; stills at three radii |
| 4 | Is there a seam or a pop? | A magenta clear colour: no magenta pixel in any frame. Heights continuous across a level's edge on a CPU twin |
| 5 | Is it solid (test 7)? | With the pivot fixed, a full 360° returns a frame **byte-identical** to the first, with the crater and tower unchanged (test 6) |
| 6 | Does it flash? | The flash analyser on the swing clip, through the city, in both modes, at 1024 by 768 and at 16:9. A failure there is a finding, not the end of the test |
| 7 | Does it look right? | **Orb's call:** a clip of the swing, with a mountain and a tower coming into the foreground, and the ground sharpening after the flight |

**If it fails:** on 1, fewer levels or fewer vertices a tile; on 2, separate small textures, at more draw calls; on 6, a lower peak rate over tall places; on 7's mountain, cap how far land rises in front, or Orb reconsiders how far a swing may turn.

**What others would need to answer before building:**

- **World:** gen 2 reads in 2D at about 4 a tick, sparse-read error, 2D lakes and rivers, and places by plan.
- **Simulation:** the plane's agreement with the drawn plane. Research estimates E's re-lay at 1.7 to 3 ms a tick, over the sim's budget, and that's an estimate from another language; Netcode prefers about 170 columns.
- **Game Design and Camera:** whether a fighter hidden about 8 ticks by a passing tower is acceptable with depth on, and how far a swing may turn.
- **Art:** the look of true 2D near land, and of land and towers sinking in the foreground.
- **Legal:** the first flash readings of a swing.
