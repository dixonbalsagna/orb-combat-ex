# The turntable from a performance mode to maximum graphics

Research & Prototyping, 2026-10-31, on ADR 0012 and Orb's words: "lets find other ways to solve this without tying the entire game down to old laptops. research methods to effectively scale this from a performance mode all the way up to a maximum graphics version." They also said 30 fps looked fine, so this paper doesn't treat it as a concern.

**See it:** open `research/ring-any-angle/proto-v2.html` and press 1 to 5. **Reproduce:** `node research/ring-any-angle/levels.mjs <bin>` (the gaps, `levels.json`), `node research/ring-any-angle/level-bench.mjs [--igpu]` (the costs, `level-bench.json`).

**How far to trust this.** The gaps are measured in 2D on planet 7's real gen 2 ground, baked at 64 units, so steps finer than 64 are missing and the worst cases are floors. The frame costs are a bare WebGL2 spike on this PC: no sim, no game shaders, stand-in buildings and trees. They rank features and show what scales, but they aren't game budgets. Simulation's and World's figures are theirs, credited where used. Nobody has played the levels yet.

## 1. The crux: what is the one sim ground?

**One ground at 128 units for every player, read on demand, with forecasts on a 512-unit bake. This replaces option A,** and it's the EP's provisional call. A was right while the laptop was the ceiling. It isn't any more. **256 is the second choice,** if Orb can't tell the two apart: "Near ground" in v2 shows the difference at 128 and 256. It reads about half as many nodes and leaves shores 2 to 4 columns off, not about one (Simulation, World). Exact gen 2 is refused.

**The sim's ground decides how far every level's picture sits from the fight.** Drawn minus sim, in units, on land, ice apart (a fighter is 75 tall):

| Sim ground | Performance (draws 512) | Low (256) | Standard (128) | High, Maximum (64) |
| :--- | ---: | ---: | ---: | ---: |
| **128** | RMS 27, p99 106, worst 477 | 9.1, 36, 184 | **0** | **5.6, 26, 141** |
| 256 | 23, 89, 358 | 0 | 9.1, 36, 184 | 12.7, 51, 278 |
| 512 (option A) | **0** | 23, 89, 358 | 27, 106, 477 | **30, 117, 500** (mountains 59, 247, 500) |

Option A makes the slowest level exact and every other level wrong by up to a body height or more. 128 does the reverse, and that's the direction ADR 0012 asks for: the gap belongs to the level that chose to draw less.

**Three candidates for that ground:**

| | Reads in a fight | Load | What it asks | Verdict |
| :--- | :--- | :--- | :--- | :--- |
| **A. The 512 bake alone** | 0 | 6 to 11 s on the laptop | Nothing more. But everyone's fight is on rounded mountains and blurred lakes | The floor. Rejected as the ground |
| **128 on demand, over the bake** (Simulation section 9) | Mean 0.30, launched ticks 1.14, p99 3 (Simulation, real fights with swings). Slowest level: 0.23 ms launched, 4.6 ms at p999 | **The same 6 to 11 s** | Forecasts read the bake, a rule fixed by the reader. Two helpers need a level passed in; then the worst tick is a dig of 115 nodes, 23 ms on the slowest level, inside its 33 ms (Simulation's arithmetic, not re-run) | **Recommended** |
| **128 as a whole-planet bake in the lobby, cached** (World section 14, your candidate) | 0 | 26 s on the web, **100 to 140 s on the laptop** (Performance's scaling) | A lobby wait on every new planet for the slowest player, in every match against them | **The same ground, wrong as a requirement** |

**On your candidate: the spacing is right, the requirement isn't.** World's table reads the old laptop as "the web column or slower", 23 s. Performance's measure puts the laptop at x4 to x5.6 of native, so it's 100 to 140 s, more than ten times its 10 s ruling. World's 9 s native also rests on an estimate: at the measured 38 µs it's about 20 s.

**But the two aren't rivals, and that's the useful part.** A node is a pure function of the planet and its key, so a machine may fill it early or late without changing a bit. **So how much is filled ahead is per machine, and never a sim input:** a laptop reads on demand, and a desktop can fill the whole 128 grid in the lobby, in threads on native, and never read in play. Both get the same ground. Simulation's rule covers it: the level is fixed by the reader, never by what's ready.

**Two parts of World's candidate I wouldn't take yet:**

- **Fidelity as a match setting, in the match key.** With 128 fitting the slowest level there's nothing to negotiate. A setting would split lobbies and replays, and put one player's machine in charge of the other's ground. The spacing stays one data value in the data hash, so it can still change between versions.
- **Sharpening to exact columns after a swing rests (14.3).** World has since withdrawn this: always-128 supersedes it. Records hold the edges that exact columns would restore (below).

**"128 or better"?** Not 64: Simulation has p99 at 1.2 ms on the slowest level, over its 0.8. Not exact columns: refused, 3x the budget in a swing, with no memo.

**Edges are records at every level (World 14.2).** Coasts, cliffs, ice edges, lake basins, rivers and marks are planet records both sim and view read, so a shore is where it is on every setting. Nothing noise-based goes in anything the sim reads (World section 13).

### How the view differs without feet floating

**One rule at every level: a body keeps its height above the drawn ground.** `y_drawn = viewGround(x) + (y_sim - simGround(x))`, fading out over about a body height of altitude. It's Simulation's body offset, applied as the one transform in Rendering's `world_place()`. In v2 the HUD shows the gap and a switch turns the rule off, so Orb can see what it hides.

**This differs from Rendering's section 8, so it's a choice to make:**

| | **Body offset at every level** (my recommendation) | **Feet on the sim's triangles** (Rendering 8) |
| :--- | :--- | :--- |
| Drawn finer than the sim | Ground stays as drawn; he stands on it | Detail fades to zero within about 200 units of a fighter, or stays in the fragment |
| Drawn coarser than the sim | The same rule | An extra patch at the sim's spacing, moving with each fighter |
| Is the world solid? | **Yes.** The ground is a function of place only: 0 of 921,600 pixels differ after a full turn, at every level | Ground near him changes as he moves. At Performance the gap is RMS 27, p90 about 73 in real fights (Simulation): a hump travelling with his feet, likely visible |
| Reads | 2 a frame | A patch's nodes |
| What it costs | Everything at his feet takes the same offset: dust, craters, sparks, shadows. Rendering's foot test passes by construction and needs stricter wording | Depth of detail lost right where the player looks |
| Two fighters | At 300 apart, Maximum: RMS 7.8, p99 36. Performance: RMS 26, p99 100. Each stands on what's drawn, so it reads as ground. A beam between them follows the same transform | Exact |
| Not yet shown | Offset's fade in low flight over ridges; v2's bars keep full offset at all altitudes | Not prototyped |

Rendering owns this. I'd pick the offset, because it's one rule and it's the only one measured to keep test 7. Orb can judge it at Performance with the switch.

## 2. The ladder

Five levels. A level only sets defaults for the separate settings in section 3. Rows marked **same** can't vary. Hardware is my estimate, for Performance to replace with a budget set per level (ADR 0012).

| | 1 Performance | 2 Low | 3 Standard | 4 High | 5 Maximum |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **For** | 2015 ultrabook iGPU | Steam Deck, older iGPU | Current iGPU, the web in a current browser | A discrete GPU | A current discrete GPU, native |
| **Frame target** | 30 fps | 30 to 60 | 60 | 60 | 60 and up |
| **Sim ground, rules, marks, edges** | **same** | **same** | **same** | **same** | **same** |
| **Planet map, near ground** | 512 | 256 | 128, the sim's own nodes | 64 | 64 near, exact columns as tiles on native (World 14.4) |
| **Far land** | 512, or the far map | 512 | 512 | 256 | 128 |
| **Tiles (Rendering 8), near vertex** | 150 u, about 30k triangles | 150 u | 75 u, about 180k (run) | 37 u, about 700k | 19 u, about 1.2M |
| **Generated relief, drawn only** | Off | Off | Off | On | Finer |
| **Buildings** | Every building the sim has; flat faces, far ones as blocks | Same, near detail | Today's look | Lit windows at all ranges, interiors in near lobbies | More facade detail, far windows |
| **Crowd** | Every figure the sim has; far as dots | Near as figures | Today's | Today's, more animation layers | Same |
| **Trees** | The sim's, simple | The sim's | The sim's, plus generated scenery | More scenery, further | Dense scenery, far out |
| **VFX** | `Q_LOW` (exists) | `Q_MEDIUM` | `Q_HIGH` | `Q_HIGH` | A new top tier: more debris, longer-lived |
| **Shadows** | None | None | Cloud shadows | Terrain shadows, 8 steps | Terrain shadows, 16 steps |
| **Sea** | Flat | Flat | Waves and glint | Same | Same |
| **Renderer** | Compatibility | Compatibility | Compatibility | Compatibility | Compatibility (section 4) |
| **Render scale** | 0.75 | 1 | 1 | 1.5 | 2 |
| **Load, cold planet** | Bake 512: 6 to 11 s; make + bake 13 to 22 s | Same | Same; near nodes fill behind the sim's | Same on web; native may fill 128 in the lobby | Native: fill 64 in threads, cached (about 5 s by arithmetic, 9 MB) |
| **Flight softening** | No need: it's already 512 | Yes | Yes: 128 at rest, 548 at a launch | Web yes, native no | Native no |

**Two traps the proto hides, because it's made of stand-ins:**

- **What the sim knows must be drawn.** Its "towers a city" slider is a look only. In the game a building or a civilian the fight can touch exists at every level, so low levels draw it more simply, never not at all.
- **What the view adds must answer to the world.** Generated scenery has no body in the sim, so it must honour the store: v2's trees vanish in a crater. It's why generated things stay unbreakable scenery or read the marks, and never become something a fighter appears to hit.

**The web tops out below native,** with no threads and the first-load pack at 14.4 of its 15 MB. Standard is its natural level; High works with softening kept.

## 3. Granular settings, and what picks them

Measured, one feature at a time against Standard at 1280 x 720, interleaved with its baseline, median of 3 passes (`level-bench.json`):

| Setting | Radeon iGPU, added ms | RTX 5070 Ti | Ladder | Reading |
| :--- | ---: | ---: | :--- | :--- |
| **Render scale** 0.75 / 1.5 / 2 | **-2.3 / +6.3 / +14.4** | Small | All | **The biggest lever by far.** Spread 0.3 at most |
| **Ground paint** off | -2.4 | Small | Perf | Noise per pixel |
| **Clouds** off | -3.8 | Small | Perf | Overdraw, and costlier than it looks |
| **Cloud shadows** off | -3.1 (spread 3.6) | Small | Perf, Low | Noisy reading |
| **Terrain shadows** 8 / 16 steps | +3.0 / +6.0 (spread 6.7) | Small | High, Max | Per pixel |
| **Near mesh** 150 u / 37 u / 19 u | -0.7 / +1.1 / +2.3 | Small | All | Vertices |
| **Relief** on / finer | +0.7 / +1.4 | Small | High, Max | **With a 19 u mesh, +7.5:** noise per vertex |
| **Trees** 96 / 320 a tile | +0.3 / +2.1 | +0.2 at 320 | Std up | Cheap until dense |
| **Far land** 128 | +0.5 | Small | Max | Mostly memory and fill reads |
| **Near-ground spacing** 512 to 64 | **Under the noise** | Small | All | **Costs load and memory, not frames** |
| **Lit windows, sea** | Under the noise | Small | | |

| Whole level, this PC | Performance | Low | Standard | High (1080p) | Maximum (1440p) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Radeon iGPU, ms (quietest run; earlier runs up to 2x) | 2.0 | 5.1 | 8.3 | 21.7 | 44.4 |
| RTX 5070 Ti, ms | 0.4 to 0.5 | 0.4 to 0.6 | 0.6 to 0.8 | 0.8 | 1.3 |

**So the granular settings a player sees:** resolution scale; ground detail (spacing and mesh, with load as the cost shown beside it); draw distance; terrain relief; shadows; clouds; buildings' detail; crowd detail; scenery; effects; frame cap. Each group is one setting, and a level is a set of them.

**The ladder's top isn't near the RTX's limit.** Maximum takes 1.3 ms there on this spike. Real game shaders will take far more, so I wouldn't size the top until a game build runs, but there's room above it.

**What auto-detection can pick, in order:**

1. **The build:** web starts no higher than Standard.
2. **A short measured probe,** during the intro, of the real scene at Standard: frame time picks the level. This is better than a table of GPU names, which ages and misses laptops.
3. **In a match, only fast levers step down on their own:** render scale first, then effects (`auto_quality` already does this), then scenery. Ground spacing changes only between matches or at a cut, so nothing pops in play.
4. **A player's choice always wins,** and sticks. Levels are private: nothing crosses the wire, and online opponents and replays are untouched.

**Rendering's laptop greybox** passes with p95 3.6 ms at 180k triangles, with no sim, VFX, water or real shader. So Performance's old-iGPU estimate (allowance gone at p95) stays open, but it no longer binds anyone else: that machine now has its own level, and render scale is its first lever.

## 4. Can desktop go beyond Compatibility?

**It can, and nothing here needs it.** ADR 0001 already allows "Forward+ or Mobile as optional quality tiers" on desktop, and the web must stay on Compatibility. Every effect in v2's High and Maximum (relief, terrain shadows, instanced scenery, windows, sea) is in plain WebGL2, GLES3-class shaders, so they should fit Compatibility. That's by reasoning from the API: I haven't ported any to a Godot shader.

**What it would buy:** real-time shadow maps, global light, screen-space effects, compute. Rendering's section 9 agrees, and adds that none of it touches the sim.

**What it would take (from reading the tree; no spike was run):**

- **The look doesn't use the engine's light today.** Of the game's 45 shader files, 30 are `unshaded`. So switching renderer gives little by itself: to get global light, materials would have to go lit, which is a look project on its own.
- **A second renderer for the life of the game:** every shader through the look gate twice, every flash reading doubled, compile stutter back as a task, clip-space and depth assumptions to check.
- **A restart to switch,** since the method is chosen at start-up.

**So: not for the swing, not at launch. Revisit as "maximum look" once Compatibility's Maximum is seen,** starting with one window's spike: today's game under `--rendering-method forward_plus`, counting what breaks. It's Orb's and Art's to ask for.

**What desktop can have without a second renderer: threads.** Native can read planet tiles on worker threads, each with its own `Planet` (Simulation's rule), which the web can't. That's what makes Maximum's exact ground affordable in flight: about 500 nodes a tick at 64 units is 19 ms of CPU, about 2.4 ms across 8 threads (arithmetic).

## 5. Going above today's look, not only staying at it

All view-only, all pure functions of the planet, so a whole turn still returns the same picture.

| Way | What it adds | Status | Cost or catch |
| :--- | :--- | :--- | :--- |
| **Denser true samples** (World 14.4) | The planet's own creases as true cliffs: reads at 8 to 16 units near the pair | Not built; v2 shows 64 | Reads a tick is the setting. Threads on native |
| **Generated relief on the mesh** | Ridged detail on mountains, hills on land, fading near shores so it invents none | **In v2 (High, Max)** | "Consistent, not true", as World puts it, and Art's to judge. Noise per vertex: +7.5 ms on the Radeon at the finest |
| **"Tessellation"** | There's no hardware tessellation stage in GLES3. The same result comes from denser tile meshes displaced in the vertex shader | **In v2:** 150 to 19 u | Vertices, then the relief above |
| **Cubic reconstruction** (World) | Removes the straight-edge look between nodes | Not built | Cheap on the GPU; mountains 13% closer |
| **Records at full density** (World) | Coast foam, cliff faces, river and lake outlines, sharper at Maximum with no extra read | Not built | Needs the records |
| **Terrain shadows from the height map** | Mountains and ridges throw shadows across the land | **In v2** | Per pixel: +3 to +6 ms on the Radeon. Ignores relief |
| **Generated scenery** | Forests from the biome map, one tree per planet-keyed slot, the same tree at any bearing | **In v2** (up to 30,000 slots) | Cheap until dense. Must honour marks |
| **Facades** | Lit windows by position and hash | **In v2** | Almost free |
| **Generated data, baked per tile on the GPU** | Normals, cavity and wear rendered into tile layers as they arrive; or eroded detail, generated and cached in the lobby | Not built. `research/planet-gen/gen/erosion.mjs` is a start | Float32 and not the same across GPUs, which is fine, since only the view reads it. Never the sim, and never heights at the feet unless the offset carries them |
| **Debris and effects** | More pieces, longer-lived, resting on the ground | **In v2:** 15 to 2,000 | **Flash:** more change on screen, so each level is read |

## 6. One look at each level

The stills are `img/quality/level-0.jpg` to `level-4.jpg`, one pose. **The look gate proper (ADR 0010, the side-by-side against the reference build) needs a game build, so it can't run on this spike.** This is a first look only.

| Level | What I see | Against today's reference |
| :--- | :--- | :--- |
| Performance | Broad facets, no clouds, big plain boxes. It reads and it's clear, and it's well under today's look. Ground paint is its cheapest way back, at +2.4 ms | **Orb, on the coarse mode: "the coarse mode looked fine".** So the level's ground is cleared in principle, subject to real terrain, and this ladder relies on that. Its other rows haven't been judged |
| Low | Facets gain a pattern, clouds return | Under |
| Standard | Clouds, shadows, windows, some trees. Ground is soft close up | Can't compare: stand-ins |
| High | The hills gain real shape, and forests read as forests | Above in ground; can't compare in buildings |
| Maximum | Dense forest, ridged slopes, lit city | Above in ground |

**A look fault at every level:** where a mountain stands just in front of the plane, the foreground rule flattens it into a table with a hard edge along the plane. It's visible in these stills as a straight band. **Near towers are moving on:** Orb prefers a hybrid of the options Rendering showed them ("a hybrid between Q and W, maybe a hybrid of W and E", `docs/ep/vision.md`), and Rendering is building it. v2's towers still sink, as a stand-in, so judge near towers on Rendering's test, not here.

**Curvature: 100% at every level.** Orb withdrew their flattening idea after the swing test: "the flattening effect actually looks pretty weird, especially around buildings". It stays a true globe, "unless we run another test with globe reduced to 95% at the closest zoom". v2 has that as one option under "Curvature", with Camera's table kept beside it for comparison. Neither is a level setting.

**Each level needs its own flash reading (RL-208),** especially at Maximum, with more debris and windows. Reduced flashing and reduced motion stay separate from the level: they mustn't be tied to a graphics choice.

## 7. What this changes in the route

In `research.md` T6:

- **Stage 3:** the sim's ground is 128 on demand, the bake is 512 for forecasts and the floor. Add World's records, and a seeded sample of about 64 fine nodes to the match key (Simulation), since a build that computes a 128 node differently wouldn't otherwise show at the handshake.
- **Stage 4:** the renderer ships with the settings groups from the start, and `world_place()` carries the offset.
- **Stage 5:** the audit is 69 lines: 38 forecasts on the bake, 31 exact writers becoming records. **It also takes World's prefetch:** a launch reads its arrival window ahead, from the 512 forecast, about 84 nodes, 21 ticks at 4 a tick. A swing starting in a brawl and a chase with no planned arrival still read nodes not yet cached. That's the known on-demand cost, inside Simulation's figures.
- **New, with Performance:** one budget set per level, and the measured probe.
- **Nothing changes for the ribbon fallback:** the stages it shares are the same.

## 8. What's open

| From | What |
| :--- | :--- |
| **Orb** | The range in v2; the 95% test at the closest zoom; the reveal's size |
| **Rendering** | Body offset or feet on the sim's triangles. The ladder's rows against its table: v2's tiles are all 33 vertices, so its Performance draws about 150k triangles, not 30k |
| **Simulation** | The two helpers given a level, re-run; the offset's fade |
| **World** | A height-only read; records from a real flood (its 8,000 and 1,100 vertices are estimates); correct 14.1's laptop column |
| **Performance** | One budget set per level; the probe; a machine of the old laptop's class |
| **Art, VFX, Animation** | What each level means for them. Every row for buildings, crowd and effects above is my first guess |
| **Legal** | A flash reading per level |

**Limits of this evidence:** one planet, one PC. The Radeon's readings moved by up to 2x between runs with other sessions on the machine (31 to 55% load), so read its small differences with the spread column in mind. No level has run in Godot, and only Rendering's middle row has run in a real scene.
