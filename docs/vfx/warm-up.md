# The first-use hitches, the headless probe and the dense-burst thinning

Owner: VFX Director. 2026-10-17. For the EP's brief on Performance's audit (`docs/perf/audit-2026-10-16.md` section 3.6, first-use hitches of 150 to 510 ms) and on city variety's blocked switch (`docs/rendering/city-variety.md`, collapse normal's debris run at ticks 124 to 130). Parked as `docs/vfx/pending/warm-and-cat/` (apply notes there). **Timings here were taken while Tools' record run held the machine (65 to 85% load): every millisecond is indicative, not a measurement. The counts are the evidence.**

## 0. The short version

1. **The warm-up is Rendering's, and it is the right one.** Rendering's parked batch (`docs/rendering/pending/2026-10-17/`, d9cbba71) draws every effect's shader once at boot in a viewport nobody sees, and its first-draw probe names the cause at the audit's own ticks: VFX's `trail.gdshader` at the beam scene's 427 (drawn first at 428), VFX's `crack.gdshader` at the ring's 211, and VFX's `beam.gdshader`, `beam_glow.gdshader` and Camera's `panel_mask.gdshader` at 279. That is the audit's hypothesis (a driver compiling a shader on its first draw) with the shaders named. **I built a second warm-up first (each of my multimesh views drawing one invisible instance in its first frames, plus a block in `BeamView`), measured it, and withdrew it: it did the same job a second time and put a block in Rendering's file.** What was learned from it is in section 1.3.
2. **One gap in Rendering's list, and one to keep.** `RenderWarmup.SHADERS` has VFX's beam, beam glow, crack, trail, shard and transform shaders but **not `hole.gdshader`** (the holes in facades, `hole_view.gd`): add `["res://render/vfx/shaders/hole.gdshader", "multimesh"]`. And every shader VFX adds joins that list when it is built (the catastrophe plan's cloud, dust and orbit-impact shaders are named in `docs/vfx/catastrophe-plan.md` section 6; the entry is part of building each).
3. **The probe** (`render/vfx/tools/hitch_probe.gd`) plays an AI match natively and lists the longest frames with their split. It sees the CPU side only, so it cannot see a driver compile; what it does see is the CPU's own first-use cost, which is small for VFX (section 1.2) and which it attributes, in the places where the numbers are not VFX's, to Audio, Rendering and UI.
4. **The collapse run's marginal window is not VFX's, and the thinning I built for it is withdrawn** (section 2). With the thinning and city variety on, `collapse` reads PASS 2.5 / 2.5 / 0.5 in both modes on today's main; **without** the thinning it reads the same, and with every debris bit off, or the whole VFX hub off, the marginal window at tick 130 is the same size (22,620 and 22,506 pixels at full scale; 5,656 and 5,705 at the analyser's default scale). It is the camera sweeping over lit facades.
5. **`transform_view.gd` and `vfx_layer.gd` are untouched** (not mine).

## 1. The hitches

### 1.1 The probe

`render/vfx/tools/hitch_probe.gd` (a tool, headless, no window, one Godot):

```
godot --headless --path . --script res://render/vfx/tools/hitch_probe.gd -- --seed=4 --nointro --ticks=1500 --top=12 [--audio-warm=0]
```

It steps a real match one tick a frame (the game's own `frame()`, main's `_process` off), warms the audio bank first as the game does (main.gd skips `bank.warm()` in headless, so without it every first sound is a 10 to 60 ms frame the game never has), and prints the median, p99 and max, the first beam's frame, and the longest frames with the host's split: the sim tick, the effects and camera, and the rest (views, audio, HUD). Run it at below-normal priority on a quiet machine, twice: a hitch counts only if it is at the same ticks both times.

For the attribution below I also timed (scratch, in a copy of HEAD, never in the tree) each pane's planet, fighters, VFX layer and beams, each VFX sub-view, the hub's `consume`, and the HUD and audio of each frame.

### 1.2 What it found (seed 4, 3,600 ticks, the audio warmed as the game warms it)

| Where | What | Cost (indicative) | Whose |
| :--- | :--- | ---: | :--- |
| First beam, the pool grows | 3 prisms and 3 materials a slot | 2 to 3.5 ms | VFX / Rendering (`beam_view.gd`) |
| First crack set's mesh | `crack_view` builds a shared mesh | 2.7 to 3.1 ms | VFX: real work, not a first draw |
| First transformation | `transform_view` 2.8 ms; the pane's `render_view` 22 ms | about 22 ms in all | the 2.8 ms is `transform_view.gd` (not mine); the other 19 ms is not the VFX layer (every VFX sub-view is under 2.5 ms): **Rendering and Animation** |
| `render_view` spikes at ticks about 1,946, 2,236 and 2,453 to 2,474 | 17 to 22 ms, five frames, none of them the VFX layer or the beams | 17 to 22 ms | **Rendering** (not attributed further) |
| One first sound at tick about 2,541, after `bank.warm()` | a 21 ms `audio.play` | 21 ms | **Audio**: a sound outside what `warm()` renders (the babble and flash ids it leaves to `warm_begin`, per fighter) |
| HUD at tick about 1,546 | 7.3 ms | | **UI** |
| The hub's `consume` | never above 2.5 ms except under load (3 to 6 ms on one-event ticks while Tools' run held the machine) | | VFX: nothing to fix |

**Headless without the audio warm** (as a native bench runs it): the first beam's frame is 63 to 86 ms and the first sounds 10 to 25 ms each. That is the headless run's artefact, not the game's, and it is noted so nobody reads it as the web's hitch.

**VFX's share of a first-use frame is 6 to 10 ms headless** (the first beam's landing, tick 1,168 on seed 4: the pool, the crack mesh, the first flames). At the web build's 5 to 10 times slower GDScript that is 30 to 100 ms, not 150 to 510: the hitches are mostly the driver, as Rendering's probe says, and the warm-up that removes them is theirs.

### 1.3 The withdrawn in-view warm-up, and what it measured

Each of `hole_view`, `shard_view`, `shots_view` and `trail_view` drew one speck-sized, colourless instance of its own multimesh for its first three frames, and `BeamView` built and drew its three slots once at strength 0. On the probe (seed 4, `--nointro`, 1,300 ticks, two runs each) the first beam's frame took 3.8 and 4.0 ms with it and 6.0 and 6.2 ms without: **the CPU part it moved is the beam pool's 2 ms** (the slots built in the match's first frame). Everything else it did, Rendering's draw does for every shader in one place. Gates were green with it (effects_check, hash_check plain and press styles, determinism plain and `--intro`, flash_reg_check, depth_check, after_check, validate). **The one thing left on the table is the beam pool's 2 ms**; if Performance wants it, it is a few lines in Rendering's `BeamView.update` (grow three slots in the first frame), and I can write them on request.

### 1.4 The test that decides the warm-up

Rendering's, after the record run: the web site built with and without `nowarmup`, Tools' `signaturecity` and `ring` scenes through `docs/perf/tools/frame-bench.mjs`, the frames over 50 ms. **Pass:** the 427, 211, 279 hitches are gone or move to the first 3 ticks. Ring tick 154 is not a shader (Rendering's probe found nothing drawn for the first time there); the table above is where its suspects live (a first sound outside `warm()`, the HUD's first glyphs, the inset's render target).

## 2. The collapse run's marginal window (city variety), measured 2026-10-17

The blocked event (`docs/rendering/city-variety.md`): collapse normal, ticks 124 to 130, a run of darker pixels with a fullest window of 22,479 against 21,824. The brief called it VFX's debris; this section is what the clips say.

**The thinning I built** (and withdrew; it was parked in the first version of `apply.patch`): `VfxDebris._add` thinned new shards once more than 90 were alive, by a hash of the spawn count. Run natively through Tools' `collapse` scene (`FlashCapture.begin("collapse")`, stepped tick by tick, main's `_process` off), at ticks 117 to 130 it took the shards in flight from 234 (135 chunks, 61 glass, 26 triangles, 12 steel) to 195 (-17%), and a swept-area proxy by 19%. A cap on `deb.max_per_event` was tried first and moved 3%.

**What the clips say** (today's main 20b95092, `check-clip` at the official scale, city variety on, collapse-normal, first 200 ticks unless noted):

| Build | Reading (primary / area-15% / memory) | The tick-130 window, pixels |
| :--- | :--- | ---: |
| thinning on, both modes, full 1,500 ticks | **PASS** 2.5 / 2.5 / 0.5, both | 22,506 normal, 22,463 reduced |
| thinning off | **PASS** 2.5 / 2.5 / 0.5 | 22,506 |
| thinning off, **every debris bit off** | PASS (1.5 / 2.5 / 0.5) | 22,620 |
| thinning off, **the whole VFX hub off** (`off=hub`, analyser's default scale) | PASS | 5,656, against 5,705 with the hub on at that scale |

So: **city variety on no longer fails collapse on today's main, with or without my change**, and the marginal window does not move when all of VFX's debris, or all of VFX, is taken out. A picture of the run (the darker pixels of ticks 108 to 130 over frame 130) shows the concentric arcs of the camera sweeping across every building edge, and whole columns of lit facade windows going dark in rectangles; with VFX off the picture is the same. **It is the camera and the facades, not VFX.** The thinning does nothing for it and is withdrawn (`debris.gd` and `vfx_look.gd` are back to HEAD in the patch); nothing else in VFX is the lever. If the 22.5k window must come down, it is Camera's sweep or Rendering's window columns.

## 2b. The clips Tools asked about (blastdummy, ring, ai-43), measured 2026-10-17

All on main 20b95092, clean, official scale unless noted; "hub off" is the page's `off=hub`, a scratch switch that turns VFX's hub off (everything else stays).

| Clip | Reading with VFX on | With the whole VFX hub off | What the pictures show |
| :--- | :--- | :--- | :--- |
| `blastdummy-RIVAL-REFERENCE-reduced` (420 ticks) | FAIL primary 3, area-15% 3.5, at tick 250 | OVER GATE 3 / 3 (the tick-250 event stays, 24,037 against 25,358) | **Tick 250 is Camera's inset panel opening** (13,974 pixels brighter at tick 250, 11,859 at 249, the pane's rectangle of sky and mountains): it is there with VFX off. **Tick 301 is a whole-frame camera change** (97,408 pixels darker in one tick, the desert ground sliding and the HUD's off-screen markers), also with VFX off. VFX's part is five windows at ticks 86 to 133 (the blast's ground, debris and embers); turning off only `earth` or only `embers` takes the reading from 3.5 to 3, not below. |
| `ring` of five, normal | **red 0.5** at tick 223 (window 21,841 px, a transition out of red) | red 0.5 at tick 224 (22,286 px) | **Not VFX's.** With the whole hub off it is the same. The red-state changes are on the **three Anti-hero bodies' own dark-red clothing and the red diamond markers above their heads**, a few thousand pixels a frame pooled into one window. (The ring of three reads red 0.) |
| `ai-43`, ticks 2,400 to 2,720 (blasts are in it) | FAIL primary 3.5 | primary 2.5, area-15% still 3.5 (FAIL) | VFX adds a full flash's worth of windows to the primary; **no single group of mine removes it** (shots, earth and embers, explosions and blasts, react and speed, or all the effects together each leave 3.5; only the whole hub off gives 2.5). The tick-260 event (55,212 pixels brighter in one tick) and tick 288 (75,000) are camera changes and stay with VFX off. |

**My reading.** The three failures are mostly the camera's whole-frame changes and the inset's opening, which VFX does not make; the pieces that are VFX's are many small windows spread across groups, none of which a switch removes alone. The ring's red is the Anti-hero's palette and markers, not a red hue in VFX's staging (VFX's beam second tint for him is an orchid, hue 292; his aura is violet).

## 3. Files

New: `render/vfx/tools/hitch_probe.gd` (+ `.uid`), this page. Changed: `render/vfx/flash_registry.gd` and `render/vfx/tools/effects_check.gd` (the catastrophe class, `docs/vfx/catastrophe-plan.md` section 1, built early because it is behind nothing), `docs/vfx/flash-registry.md`, `docs/vfx/README.md` (the probe's row). No file of anyone else's.
