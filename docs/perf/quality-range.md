# Quality range: what scales, what each level may spend, how a level is picked (Performance and Platform, 2026-10-31)

For the EP on ADR 0012 and Research's ladder (`docs/world/ring-any-angle/quality-range.md`). The old laptop is the bottom of a range, not the ceiling. Measured on the game itself (HEAD e8a95e35 plus the preview's switches, planet 7, the AI match) in stage-timer scratch trees, on this PC: native best of 3 for script time, the web build on the Radeon iGPU (`--igpu`) and the RTX for frame time. **Estimates are marked.** Load on the machine is 11 to 100% across the runs and is stated where it matters (section 2.4).

## Result

- **Nothing a player can reach scales today.** The Settings screen has no graphics section; what exists is a three-level VFX governor with animation riding it, a phone-only render scale and debug switches (section 1).
- **What costs the frame depends on the machine.** On the Radeon at x1 it is GPU-bound: **pixels 3.3 ms a megapixel, the ground's 134k triangles about 3 ms; halving the ground's column density takes the median from 8.4 to 6.8 ms and the p95 from 17.4 to 13.6.** VFX, animation, clouds and cover change nothing there. On the laptop stand-in (x4) and on the RTX it is CPU-bound, and the only levers are VFX and animation, worth **3 to 5 ms of 36** (section 2). The script side is 2.7 ms native and **cannot scale below about 2.3** with the existing switches.
- **Two corrections to Research's ladder on cost:** the engine's `scaling_3d_scale` made the Radeon **2.2 to 2.7 times slower** (18.6 and 22.9 ms for 0.6), so "render scale" has to be the canvas resolution; and the game's own clouds, cover, streets and damage cost nothing measurable, while the **drawn ground mesh** (a separate dial from the sim's 128 spacing) is the largest GPU item after pixels.
- **The Radeon's up-to-2x spread is explained and reproduced** (section 2.4): a cold iGPU reads 2 to 5 times slow for its first seconds; memory-bound passes lose 85 to 90% when the CPU is memory-busy; ALU passes lose 17% with 2.9x spikes at 100% CPU. Vertex-bound work does not move.
- **Performance is the level that needs engineering, not switches:** on the x4 stand-in the existing levers reach about p50 34 / p95 60 (timer tree) or about 28 / 42 (live-build scale, an estimate) against 27 / 40; it needs 1.5 to 3.5 ms of script time p95 found in the rigs, the animation drain and node counts (section 3). Standard on the Radeon misses its p95 by 0.4 to 1.0 ms today and passes with the ground at stride x2.
- **Auto-detection:** a hardware guess, a warmed probe of 100 to 300 ms (the RTX and Radeon are 26 times apart on one fixed draw), and a governor that picks CPU or GPU levers by what the frame is bound by (section 4).

## 1. What scaling already exists

Nothing the player can reach. There is no graphics section in the Settings screen (`ui/data/options.json` and `settings.json` hold HUD, control and accessibility options only). What exists is code and command-line switches:

| Scaling today | Where | What it does | Reaches the player? |
|---|---|---|---|
| **VFX quality**, 3 levels (`Q_LOW`, `Q_MED`, `Q_HIGH`) | `render/vfx/vfx_hub.gd`, `vfx_look.gd` | Fewer crack sets, pressure rings, shot debris, scan passes, trail and transformation fill, rim light and dust at LOW. Nearly every check is "LOW or not LOW": I found nothing that treats MED and HIGH differently, so the middle level is close to an empty step | Only through the **automatic step**: below 42 fps for 2 s drops a level, at 57 fps or more for 8 s (and 20 s after the last drop) climbs back. `max_quality` caps it. `--vfx-quality=N` fixes it (tools) |
| **Animation quality**, 4 levels (`high`, `medium`, `low`, `minimal`) | `data/anim/quality.json`, `RenderAnim.set_quality` | Switches whole layers off in an order set by measured cost: look, feet, personality (medium); transitions, defender, flight, cloth, lean, aim (low); ragdoll too (minimal) | Only as a rider on VFX: `main.gd` sets `low` when VFX is at LOW, else `high`. **`medium` and `minimal` are never picked automatically** |
| **Reduced looks at VFX LOW** | `main.gd` | `FighterView.damage_reduced` (battle damage a flat tint), `guard_reduced`, no afterimages (`ParticleView.after_on`) | Rider on VFX LOW |
| **3D render scale** 0.6 | `main.gd` `_render_scale`, `RenderLook.TOUCH_3D_SCALE` | `scaling_3d_scale` on the game's viewport and each pane's | **Phones only** (a coarse pointer on the web); `?touchscale=1` forces it |
| **Feature flags** (cracks, destruction, embers, transform, rocks, blast, shots...) | `VfxLook.*_DEFAULT` | Whole effect families on or off | No: set in code, mostly off until approved |
| **Accessibility** | UI options | Reduced motion, reduce flashing (both also lighten the VFX load) | Yes, but for access, not speed |
| **Debug switches** | `main.gd` args | `novfx`, `noclouds`, `nocover`, `nostreets`, `nodamage`, `nowindows`, `nofine`, `nopanhaze`, `nosplit`, `nocull`, `nofill`... | No: URL or command-line only |
| **Fixed LOD in the planet view** | `RenderLook.STRIDES`, `CHUNK_COLS`, `FAR_MAP_N`, `CROWD_MAX` | Ground columns at stride 1 within 400 units, 2 to 2,000, 4 beyond, 8 far; a 192² far map; 12 crowd members a face | Constants. Not a setting |
| The preview's six **switches** (`gen2`, `biome`, `water`, `surface`, `interrupts`, `floor`) | `tools/preview/switches.mjs` | Whole world-generation features | **Not scaling**: they change what the sim computes, which ADR 0012 item 3 forbids a setting to do |

Three gaps. **The governor moves one dial** (VFX, with animation riding it) and ignores resolution, ground detail, the crowd, the planet map and the sky. **Its thresholds are 60 fps thresholds**: 42 fps down means a laptop that is happily at 30 fps is pinned at LOW from the first seconds, with nothing left to give. And **the player cannot see or set any of it**.


## 2. The most expensive things, and which scale with a setting

Measured on the game itself (planet 7, the AI match, seed 4), not on a spike. CPU side: native best of 3 per frame (script work only). GPU side: the web build on this PC's Radeon iGPU at x1, 1280 x 720, 1,400 frames a run, two runs, interleaved with baselines. The `wall` below is frame to frame with vsync off, so on the Radeon it is the GPU's time when the GPU is the slower of the two.

### 2.1 On the Radeon the frame is GPU-bound, and three things make it

Baseline: **wall median 8.4 ms, p95 17.1 to 17.7, p99 21 to 22** (five runs, median 8.4 every time); script work is 4 ms of it, so about 4.4 ms is the GPU and driver past the CPU.

| Piece | Cost on the Radeon at 720p | How I got it | Scales with a setting? |
|---|---|---|---|
| **Pixels** | **about 3.3 ms a megapixel, 3.0 ms at 720p** | 640 x 360: 6.2 ms (-2.2); 1920 x 1080: 12.2 (+3.8). Both give 3.2 to 3.3 ms/Mpx | **Yes: the canvas resolution** (see the trap below) |
| **Ground and water vertices** (134k triangles, about 84% of them the ground) | **about 3 ms (an estimate by proportion: 0.029 ms per 1,000 triangles)** | The ground's column strides doubled: 134k to 78k triangles, **median 8.4 to 6.8 (-1.6), p95 17.4 to 13.6 (-3.8)**; quadrupled: 50k triangles, 6.6 to 7.1 | **Yes: the mesh column stride** (`RenderLook.STRIDES`), which is not a setting today |
| Everything else (fighters, buildings, crowd, the HUD's 94% of the draw calls, driver) | about 2 ms | what is left | Partly: see 2.2 |
| VFX quality, animation quality, clouds, cover, streets, damage | **no change in wall** (8.1 to 8.6) | `vfx-quality=0/1`, `novfx`, `anim-quality=low`, `noclouds`, `nocover`, `nostreets`, `nodamage` | They save script time (below), which a GPU-bound iGPU does not show |

On the RTX the frame is CPU-bound (median 6.2 ms, p95 11.0) and **pixels do nothing** (640 x 360: 6.2; 1920 x 1080: 5.3), while VFX LOW takes median 6.2 to 5.8 and p95 11.0 to 8.9 (one run each). So a setting that matters on one machine is invisible on the other, which is why the levers must be ordered per level and not once.

**Two traps.**

- **`scaling_3d_scale` is a cost, not a saving, in the Compatibility web build.** The phone's 0.6 (`?touchscale=1`) took the Radeon from 8.4 to **18.6 and 22.9 ms** (two runs). The saving seen at 360p came from the page's canvas resolution (the browser scaling up), as `phone-freeze-2026-10-26.md` found. "Render scale" must be built as the canvas resolution; 0.75 and 1.5 through the engine's scale are unmeasured and may carry the same extra pass.
- **Halving the ground's vertices is worth more than any effect setting on this iGPU,** and it is not "near-ground spacing" (the sim's data spacing, which is under the noise per frame, as Research found) but the **drawn mesh's column stride**, a separate dial. Research's Performance level draws "about 150k triangles"; the game draws 134k today at stride 1, so that level is not lighter than now. The mesh at stride 2 (78k) is the level's target.

### 2.2 The script side (CPU), mean and p95, native, plain AI match

Total **2.72 ms mean, 4.48 p95, 5.96 p99** (the web build reads 3.7 to 4.7 mean, 6.1 to 8.4 p95).

| Item | Mean | p95 | What it is | Scales with a setting? |
|---|---|---|---|---|
| Fighters in the view (`r_fighters`) | **0.74** | 1.18 | rigs, skin, damage | Animation quality: `minimal` takes 0.75 to 0.62 |
| Animation's drain (`d_anim`) | 0.19 | **1.59** | layers, ragdoll; a first-use hitch to 6 ms | Animation quality (`minimal` 0.15) |
| VFX (`h_vfx` + `r_vfxlayer`) | **0.41** | 1.4 | events and the layer | VFX quality: `LOW` -0.1 to -0.3; off -0.25 to -0.5 |
| The sim (`SimCore.step`) | 0.33 | 0.65 | | **No: shared (ADR 0012 item 3)** |
| Host: events, camera, split rig | 0.3 | | | No |
| Planet update | 0.22 | 0.36 (p99 1.0) | footing sweep, ground upload | By world detail; no measurable change from `nocover` or `nostreets` |
| HUD | 0.2 | 0.3 | | No |

**The script side barely scales.** Every existing switch together is worth at most 0.5 ms mean (0.8 p95): baselines read 2.74 to 2.98; `novfx` 2.50, `vfx-quality=0` 2.67, `anim-quality=minimal` 2.62. The floor, **about 2.3 ms with VFX off and animation at `minimal` (the two savings added: an estimate)**, is the sim, the host and the rigs. On a CPU-bound machine (the RTX, the laptop at x4) that floor is the Performance level's problem; on a GPU-bound one it does not show.

### 2.3 Spikes, which no setting touches today

| Spike | Cost | Source |
|---|---|---|
| The calm turn's swap | 57 to 61 ms native, 84 to 107 web (Half ring) | `docs/world/ring-any-angle/performance.md` section 2 |
| A launch plan's PROP SMASH flight | 13 ms native, one frame | `preview-deform-launch-2026-10-30.md` |
| A dig frame | 13 ms mean, 30 p95 (script) | same |
| The ground field rebuilt whole | 3.8 to 4.9 ms | performance.md |
| A cold planet make + the 512 bake | 3.3 to 4.0 s web, a Performance-level wait of 13 to 22 s | performance.md section 6 |

### 2.3b The laptop stand-in: what the levers reach at x4

Radeon with the page's CPU throttled 4x (the budget's T2 stand-in), 720p, two runs each (`stage-web.mjs run --igpu --throttle 4`). The stage-timer tree adds timers of its own, so the absolute times read high: the same stand-in on the unmodified live build read **p50 30.4, p95 47.3** (`coast-layer-cut-2026-10-27.md`), about 20% under these.

| Setting | Wall median | p95 | p99 | Script work, mean / p95 | Triangles |
|---|---|---|---|---|---|
| Today, full effects | 36.4 to 37.9 | 67.4 to 68.7 | 91 to 98 | 27.3 to 29.0 / 47 to 50 | 134k |
| VFX LOW + animation `minimal` | 34.3 to 36.3 | 59.9 to 63.1 | 79 to 90 | 24.2 to 24.8 / 40 to 41 | 134k |
| + VFX off + ground stride x2 | 32.1 to 36.8 | 62.1 to 66.6 | 90 | 22.5 to 24.4 / 40 to 43 | 78k |
| + a 640 x 360 canvas | 36.7 to 37.4 | 66.0 to 66.6 | 81 to 88 | 24.5 to 25.2 / 43.5 to 44.3 | 78k |
| Ground stride x2 alone | 35.9 to 36.3 | 67.9 to 72.2 | 100 to 103 | 27.5 to 27.7 / 49 to 52 | 78k |

**At x4 the frame is CPU-bound, not GPU-bound:** script work is 27 ms of a 36 to 38 ms frame (6 to 7 times its x1 value, not 4: a throttled wasm main thread). So **the GPU levers that win at x1 (pixels, vertices) win nothing here,** and the CPU levers win 3 to 5 ms (about 12%): the existing switches together take the median to about 34 and the p95 to about 60. Against Performance's budget (section 3: p50 27, p95 40, p99 50) the stand-in with the levers reads **p50 34 and p95 60 as measured** (7 and 20 ms over), and, scaling by the unmodified build's 20% lower reading, **about p50 28 and p95 42** (1 and 2 ms over). Which scale is right is the open question: the lever run on an unmodified export would settle it (not done: the stage tool needs its timers to write a result). **On the measured scale the levers fall well short; on the lower one they are at the edge; and everything they buy is CPU-side.** The p99 (79 to 90 with the levers) is the worse gap: 30 to 40 ms over, from the spikes of 2.3. What would close it is script work at x1 about 1.5 to 3.5 ms lower at p95 (the 5 ms figure of section 3) than the 6.1 to 8.4 the web build shows today, from the fighters' rigs (0.74 ms mean, the largest item), the animation drain and the engine's own per-node cost: none of them are settings yet.


### 2.4 Why the Radeon's readings moved up to 2x between runs

Research saw it; I can reproduce it, and it is three separate things (a fill-bound WebGL2 bench, `gl-fetch-bench` with `--extra fill`, on the Radeon; PC load 11 to 100%, 12 memory-streaming burners at below-normal priority for the high end):

| Condition | ALU-bound pass | Cache-friendly texture pass | Memory-bound texture pass |
|---|---|---|---|
| **Warm and quiet** (four runs: spread 1 to 3%) | 7.1 ms | 0.65 | 48.6 |
| **First run after the GPU sat idle** | **15.2 (2.1x)** | **3.05 (4.7x)** | 59.3 (1.2x) |
| CPU memory-busy, 4 burners (61% load) | 7.2 (+2%) | 0.76 (+17%) | **91.4 (+88%)** |
| CPU saturated, 12 burners (100%) | 8.3 (+17%), worst batch 20.2 (2.9x) | 0.78 (+20%) | **89.9 (+85%)** |

1. **A cold iGPU is slow for its first seconds** (the clock and power state ramp up): the first run read 2 to 5 times slower, and its best batch of 40 was still 1.7x the warm median. Every first read after a pause is suspect.
2. **It shares memory with the CPU.** A memory-bound pass (large overdraw, shadow and cloud fills, a big render scale) loses **85 to 90%** when the CPU streams memory, even at 61% load. An ALU-bound or vertex-bound pass does not: my vertex-fetch bench repeated within 1% at 28% and 51% load, and the game's own runs repeated within 3% in nine of twelve pairs (the three that did not are listed below).
3. **It shares a power budget with the CPU.** At 100% CPU the ALU pass loses 17% at the median and stalls up to 2.9x in single batches.

So the **noisy readings are the fill-bound ones** (shadows, clouds, render scale), which is what Research measured. The three outliers in my own game runs (`640 x 360` repeat 7.7 against 6.2, `novfx` repeat 16.2 against 8.3, `touchscale` 22.9 against 18.6) are the same thing with another session's work on the machine. The fix is method: warm the GPU for several seconds first, interleave, take the best of N, and write down the load. It is also why the probe of section 4 must not read a cold GPU as the machine's speed.

## 3. Budgets per level

Research's five levels (`docs/world/ring-any-angle/quality-range.md` section 2) replace the one table of `budgets.md`; each level has its own frame target and its own reference machine. **Rule for the frame numbers:** p50 at most 80% of the target period, p95 at most the period (120% at 30 fps, since a laptop that holds 30 fps is "playing well", Orb's words), p99 at most 150% and never over 50 ms; Low sits between its two targets (a 30 fps floor with a 60 fps wish). **No frame over 50 ms after the warm-up, at any level,** except the swing and the loads below, which have their own rows. Flashing and reduced motion are never a level (RL-208): each level gets its own flash reading.

| | **1 Performance** | **2 Low** | **3 Standard** | **4 High** | **5 Maximum** |
|---|---|---|---|---|---|
| **Reference machine, and what I can run for it** | A 2015 ultrabook iGPU: this Radeon with the CPU throttled x4, 0.75 canvas. The iGPU itself is modelled, not run (performance.md 6.4: 2.5 to 4x slower than this Radeon) | Steam Deck, older iGPU: the Radeon at CPU x2 | A current iGPU, the web: the Radeon at x1, 720p | A discrete GPU: the RTX at x1, 1080p | A current discrete GPU, native: the RTX at 1440p |
| **Frame target** | 30 fps | 30 held, 60 when it can | 60 | 60 | 60 and up (budgeted at 60) |
| **Frame p50 / p95 / p99 (ms)** | 27 / 40 / 50 | 20 / 33 / 45 | 13 / 16.7 / 25 | 13 / 16.7 / 25 | 13 / 16.7 / 25 |
| **Where the game stands today on that machine** | p50 36 to 38, p95 67, p99 91 to 98 (timer tree); 30 / 47 live. With the existing levers about 34 / 60 / 85. **Fails** | Not run | p50 8.4, p95 17.1 to 17.7, p99 21 to 22. **p95 misses by 0.4 to 1.0 ms;** with the ground at stride x2: 6.8 / 13.6 / 17: passes | p50 5.3, p95 10.4, p99 14.8 at 1080p (the game as it is, no High look). **6 ms of p95 headroom** for what High adds | p50 6.2, p95 11.0 at 720p; 1440p not run. Research's spike: +1.3 ms |
| **Script work, p95, x1 web** | **at most 5 ms** (today 6.1 to 8.4: 1.5 to 3.5 ms to find) | 6.5 | 8 | 8 | 8 |
| **Triangles a frame, median / p95** (today 134k / 360k) | 80k / 150k (the mesh at stride x2 is 78k) | 130k / 250k | 200k / 360k | 700k / 1M | 1.2M / 1.8M (Research's ladder, not validated) |
| **Draw calls a frame** (today 143 median; 94% of the budget table's were the HUD's) | 100 / 150 | 150 / 300 | 300 / 450 | 300 / 450 | 300 / 450 |
| **Video memory** (today 73 to 91 MB) | 128 MB | 256 MB | 256 MB | 512 MB | 1 GB (the last two unmeasured: set when the levels run) |
| **Page memory, web** (today 495 to 537 MB) | 450 target, 600 limit (`budgets.md`, unchanged) | same | same | same | native: no web cap |
| **Cold planet: make + bake** (performance.md 6) | bake at most 10 s added on the laptop, in slices behind the intro (13 to 22 s in all) | same | 3.3 to 4.0 s web at x1 | same on the web; native may fill 128 in the lobby | native fills 64 in threads, cached (Research: about 5 s) |
| **A swing, added to each frame (x1)** | 1 ms (measured on the Radeon 0.1 to 0.5; modelled 0.2 to 1.6 on the old iGPU) | 1 | 1.5 | 2 | 2 |
| **Sim** | 0.4 ms mean, 1.0 p99 per tick, **identical at every level** (ADR 0012 item 3), with Simulation's on-demand 128 reads inside it (0.30 mean, 3 at p99, a dig of 115 nodes = 23 ms on the slowest level, rare) | same | same | same | same |
| **The governor steps down when** | below 26 fps for 2 s | below 26 fps for 2 s, up to Standard when 58 fps holds | below 52 fps for 2 s | below 52 fps | below 52 fps |

**How each row is checked:** `stage-web.mjs run --web <export> --igpu [--throttle N] --width W --height H --extra <switches>` on the reference machine above, the p50, p95 and p99 of `wall_ms` over 1,400 frames after the first 100, two runs, the machine's load written beside it, and the GPU warmed first (section 2.4). A level's budget is met when both runs are under it.

**Three consequences.**

1. **The Performance level needs script time found, not settings turned.** The levers that exist buy 3 to 5 ms at x4 and nothing for the GPU-bound parts; the rest is the fighters' rigs, the animation drain and the engine's per-node cost. That work belongs to Animation, Rendering and VFX, and it is the one place where the budget asks for engineering and not for a switch.
2. **Standard on the Radeon is 0.4 to 1.0 ms over its p95 as the game is today,** before it adds Research's clouds, shadows and trees. The cheapest way back is the ground's mesh stride, which halves the triangles (-1.6 ms median, -3.8 p95 measured), so Standard's ground detail must be a mesh setting separate from the sim's 128 data spacing.
3. **High and Maximum are not Performance-limited** and have 6 ms of p95 headroom on the RTX before any look is added; their budgets are set by what the look gate lets them spend, so they stay provisional until a game build runs the levels. The ladder's top costs 1.3 ms on a bare spike; the real shaders will cost more.


## 4. How auto-detection would pick a level

Three stages, each correcting the one before, none touching the sim (ADR 0012 item 3): a **guess from the hardware**, a **short probe on the loading screen**, and a **governor in play**. A level the player sets by hand always wins, and the governor then only suggests.

**Stage 1, the guess (free, at boot).**

| Signal | Web | Native | Use |
|---|---|---|---|
| GPU name | `WEBGL_debug_renderer_info` unmasked renderer: this PC reads `ANGLE (AMD, AMD Radeon(TM) Graphics ...)` and `ANGLE (NVIDIA, NVIDIA GeForce RTX 5070 Ti ...)` in Chrome. **Firefox and Safari return generic strings**, so the name is a hint, never the rule | `RenderingServer.get_video_adapter_name()`, `get_video_adapter_vendor()` | A table of name patterns to a class (integrated, mid, discrete) |
| Integrated or discrete | not exposed (infer from the name) | `get_video_adapter_type()` | Integrated starts one level lower |
| CPU threads and memory | `navigator.hardwareConcurrency` (browsers may cap it), `navigator.deviceMemory` (Chromium only, capped at 8) | `OS.get_processor_count()`, `OS.get_memory_info()` | A 2-thread machine starts at the performance level whatever its GPU |
| Pixels | `devicePixelRatio` and window size, the one cost that scales with the screen: at 4K on an iGPU the pixel count alone sets the level | window size | Sets the **render scale**, not the level |
| Touch or coarse pointer | `matchMedia('(pointer: coarse)')` (used today for the phone's 0.6 scale) | | Mobile is parked (ADR 0011 item 4); keep the existing phone rule |

**Stage 2, a probe (100 to 300 ms on the loading screen, presentation only).** The names are not enough, and the spread is too wide to ignore: my vertex-fetch bench (a fixed 400,000-vertex draw, `docs/perf/tools/gl-fetch-bench`) takes **0.06 ms on the RTX and 1.7 ms on this Radeon, 26 times apart**, and the Radeon is itself a recent integrated GPU. A fixed draw timed with a one-pixel `readPixels` (web) or a frame timer (native) reads GPU and driver speed directly, and a fixed block of script work reads the CPU. Two numbers place the machine against the three reference points this project already has: the RTX, the Radeon, and the Radeon at x4 CPU. **The probe must warm the GPU first and take the best of several batches: an iGPU that has sat idle reads 2 to 5 times too slow for its first seconds (section 2.4), and the machine would be graded a level too low.** A cold read can only err toward "slower", so it fails safe, and the governor steps back up. **The probe's result is not a sim input and is never sent to a peer.** Its thresholds are to be set by running it on those three references (the Radeon at x4 stands for the performance level; nothing slower has been run).

**Stage 3, the governor (in play).** Today's governor (`VfxHub.note_frame`) is the right shape (down fast, up slowly, hold after a drop) with three changes it needs:

1. **Thresholds per level, in the level's own frame target**, not 42/57 fps for all: the performance level's target is 30 fps, so it steps down below about 26 fps and never up past its cap, instead of sitting at the floor.
2. **One ladder, but the next lever depends on what the frame is bound by.** Section 2 measured both cases on the same game: on the Radeon at x1 the frame is GPU-bound (script work 4 ms of 8.4), so the canvas resolution (3.3 ms a megapixel) and the ground mesh stride (-1.6 ms median) are the levers and VFX or animation levels change nothing; on the laptop stand-in at x4 or on the RTX it is CPU-bound, so only VFX, animation layers and node counts help and resolution does nothing. The governor already has both numbers (the frame time and the script time it measures for the profile); when the script time is more than about 70% of the frame it steps the CPU levers, otherwise the GPU ones. The order within each side is data (the animation quality file is already built that way), and a level is a named point on it. **Resolution must be the canvas size, not `scaling_3d_scale`** (section 2.1).
3. **A cap and a memory**: the highest level the probe allowed is the ceiling; the level the player ended on is saved (`user://` on native, the origin's storage on the web; a lost save only costs a re-probe) and tried first next time, with the probe re-run if the GPU name changes.

**What cannot be detected well, and the fallback.** A frame's time on the web is capped by the display's refresh and shared by CPU and GPU, so the governor cannot tell a slow GPU from a slow CPU (the game's `viewport_get_measured_render_time_gpu` reads 0 in my web runs); the probe's draw is the only GPU-only reading available. A laptop on battery or a throttling CPU changes mid-session, which only the governor sees. A wrong first guess therefore costs a few seconds at the wrong level, not a bad session; the player's own setting is the last word.

## 5. Where Research's ladder is wrong on cost, and what is still open

| Research says | What I measure in the game | So |
|---|---|---|
| Render scale is the biggest lever on the Radeon | True for pixels (3.3 ms a megapixel; 36% of the 8.4 ms frame at 720p). **The engine's `scaling_3d_scale` 0.6 is 2.2 to 2.7x slower, not faster.** Canvas resolution works (6.2 ms at 640 x 360) | Build it as the canvas size; measure 0.75 and 1.5 before using the engine's scale |
| Near-ground spacing is under the noise per frame | True of the data spacing. **The drawn mesh's column stride is not: 134k to 78k triangles is -1.6 ms median and -3.8 p95** | Two dials: sim and data spacing (load and memory), mesh stride (frames) |
| Performance draws about 150k triangles | The game draws 134k now at stride 1. The mesh at stride x2 is 78k | Performance's target is 80k, not 150k |
| Clouds off -3.8 ms, cloud shadows -3.1 | In the game `noclouds` changes nothing (wall 8.1 to 8.3 against 8.4). Its spike's clouds are not the game's | Do not list clouds as a Performance lever until the game's own are measured with shadows added |
| Whole levels cost 2.0 / 5.1 / 8.3 / 21.7 / 44.4 ms on the Radeon | The game today is 8.4 ms at 720p by itself (Research's Standard spike reads 8.3 ms alone) | Their costs rank features and show what scales; they are not additive to the game's, so a level's real cost is the game's plus the delta |
| Radeon readings moved up to 2x | Three causes, section 2.4 | Warm up, interleave, best of N, record the load |
| (Open on its side) the old iGPU | I model it at 2.5 to 4x this Radeon (performance.md 6.4); no such machine has run | The Performance row stays provisional |

**What I would measure next, in order of what it settles:**

1. The Performance lever run on an **unmodified export** at x4 (whether the real stand-in is 28 / 42 or 34 / 60 against 27 / 40). The stage tool needs its timers to write a result, so this wants the game's own bench result read by the runner (about an hour of tool work).
2. `scaling_3d_scale` at 0.75 and 1.5, and the canvas resolution at the same factors, on the Radeon and the RTX.
3. The ground mesh stride as a setting, with the look gate: stride x2 and x4 at the near plane (the foreground rule, Rendering's risk).
4. The fighters' rigs (0.74 ms mean) and the animation drain: what a lower rig detail buys on the CPU-bound machines.
5. A machine of the old laptop's class. Everything marked "modelled" is waiting on one.
