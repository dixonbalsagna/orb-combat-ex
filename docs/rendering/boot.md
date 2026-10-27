# The boot on old GPUs and phones (Rendering, 2026-10-27)

Performance's phone-freeze report (`docs/perf/phone-freeze-2026-10-26.md`) found the game's first frame was one block of 15.6 s on this PC, whatever the CPU throttle: the graphics driver compiling every shader the scene and the boot warm-up draw at once. A phone shows a frozen splash all the while. This page is what Rendering found and changed.

## Where the time went

A probe build compiled one program a frame and timed each frame (frame-by-frame, Chrome over ANGLE and Direct3D 11, this PC). The driver's compiler (FXC) took:

| Program | First cut | After this park |
| :--- | :--- | :--- |
| terrain | 15 s | about 5 s |
| water | 4 to 5 s | about 2.5 s |
| building | 3.4 to 4.3 s | unchanged |
| cover | 2 s | about 1.7 s |
| flash | 1 to 1.5 s | unchanged |
| fighter_body | 1 s | unchanged |
| the other 50 | 0.1 to 0.6 s each | unchanged |

(The machine was shared during these runs; the ratios hold, the seconds move by a third with load.)

- **The cost was the vertex stage, and it was code size.**
  - The terrain with its vertex stage cut to the position compiled in 1.6 s; with its fragment cut to one colour, 18 s.
  - FXC inlines every function, and `ground_vertex` called `ground4` three times. Each `ground4` ran the crater loop and `far4`, and called `fore_fall`, which called `fore_cap3` twice (each with its local arrays and its 10 by 3 by 7 loops). `far4` called `far_fetch` three times, each reading four `far_texel`s with their folds.
  - Constant loop bounds let FXC unroll every loop on top of that.
- **The fix** (`ground.gdshaderinc`, the same maths): each heavy part is called once from a loop, so FXC keeps one copy:
  - `ground_vertex`'s one or two columns;
  - `fore_fall`'s two caps;
  - `far_fetch`'s four texels;
  - `far4`'s three map samples.

  Every constant loop bound is a uniform with the same value (`loop_*`, set by nothing), so no loop is unrolled.
- **The far map** (the planet's own far land, World's far read; off unless `RenderLook.FAR_MAP_ON` or `--farmap`) is behind `#ifdef FAR_MAP`. It cost the terrain a third of its compile and the default game never reads it.
  - `terrain_far.gdshader` and `water_far.gdshader` have it. `planet_view.gd` puts them on the materials only while the far land is on (`set_far`).
  - `far_town.gdshader` always has it.
  - The bodies moved to `terrain.gdshaderinc` and `water.gdshaderinc`; `terrain.gdshader` and `water.gdshader` are their default wrappers.
- **Not yet:**
  - the building shader (its loops are not the cost: uniform bounds changed nothing);
  - the terrain's remaining 5 s: the far land, the vertex far colour, the fore rule and the crater loops each cost about a second, and the fragment about one more.

## The boot, spread over frames (`render/core/boot.gd`)

- **What it does.** On the game's own start on a screen, the panes draw nothing until every program has been compiled once:
  - each frame draws the next few of the scene's materials, and the effects' shaders the warm-up has always drawn (`RenderWarmup.SHADERS`), on small quads in a viewport of its own, far under the planet;
  - one program a frame at first, more while the frames stay under `BOOT_FRAME_MS` (250 ms), up to `BOOT_PER_MAX` (4);
  - the heavy ones last.
- **The screen.** A plain line and a thin bar on a dark ground ("Preparing the graphics"; static, no fade, no spinner) sit under UI's layer, so the notice and the cards draw over it. The first boot frame draws only the line, so it is up before any compile.
  - The bar is the share of the programs drawn, a whole percent at a time. It only moves forward, and it stands still through a long compile.
  - The list of programs is fixed when the compile starts. A match started during the boot (the notice's Start) adds nothing to it.
  - The line takes no click or tap.
  - Legal's conditions (RL-191): no other words, and nothing the boot does changes the notice or its gate.
- **The sim waits** (`frame()` returns before the host advances). UI's notice and cards stay live, and the audio warm-up takes its quiet budget (`bank.warm_quiet = 1`).
- **Where it does not run.** A tool, the capture hook, a bench, a scripted run and a headless run keep the warm-up's single frame, as before. `nobootstage` turns it off.
- **What it cannot do** is split one program's compile: the terrain's is still one block of several seconds on this PC's driver. The page paints before and after it, and the line is up.

## The first match, built a few steps a frame (`main.gd`, `pane_world.gd`, `planet_view.gd`)

Simulation timed `_match_built` at 1.4 s natively on the first boot. A probe of its steps (this PC, native, the first match after the game starts; later matches take about 85 ms in all):

| Step | ms |
| :--- | :--- |
| the ground's meshes (`_make_ground_meshes`, first build only) | 372 |
| the materials | 37 |
| the ground's upload, the props, the cover, the copies, the first refresh | 5, 8, 9, 7, 9 |
| the fighters' views | 180 to 200 (two fighters) |
| the first `render_view` | 660 (about 500 of it Animation's pair bake) |

- **The same work in the same order, now as steps.** `PlanetView.build_steps`, `PaneWorld.build_steps` and `main._match_built_steps` each return Callables that return true when done; `build()` and `_match_built()` run them at once, as before.
  - The ground's meshes are a chunk a step.
  - The fighters' views are one fighter a step.
- **On the game's own first start on a screen,** it runs on Simulation's stepped match start (`host.stepped_start`, the match's pieces through `host.load_step()`).
  - `_ready` shows the boot's line and hides pane 0, then starts the match as usual.
  - When the sim's last piece is done (`load_step()` true), `_match_built`'s steps become a load phase of their own (`main._step_build`). Steps run from `frame()` until `RenderLook.BOOT_STEP_MS` (30 ms) has gone in a frame, while the loading screen stays up.
  - Last comes the split's attach that waited for the boot's match; then the boot compiles the built panes' programs.
  - `frame()` runs the match's and the panes' pieces before the boot's compile. Nothing reads `host.S` while the sim's piece runs, and input that would start a match waits for the boot.
  - A match started during the boot (the notice's Start, the start menu):
    - during the pane build, it drops that build's steps (they were the old match's), and its own follow its load;
    - during the compile, it is built whole when its load is done (its programs are the ones being compiled), and the compile is not started again.
- **Still one block:** the first `render_view` (Animation's pair bake, briefed to Animation).

## Around the boot (`main.gd`)

- **Audio's quiet budget.** `host.audio_cues.bank.warm_quiet` is 1 while the sim is held or a notice, a card, the start menu or the loading screen is up (an AI match plays behind the first-start card); 0 otherwise.
- **Performance's freeze breadcrumbs.** The four stages are said to the page once each as they change, through `window.__ocx.crumbs.stage(...)` (nothing on a desktop build or headless):
  - `first_frame`: the first frame is up;
  - `card`: the notice or the How to play card;
  - `intro`;
  - `playing`.
- **A phone's render scale.** On the web with a coarse pointer (a phone or a tablet), the game's viewport and every pane's draw their 3D at `RenderLook.TOUCH_3D_SCALE` (0.6) of the screen's pixels. UI's layers stay at the full ratio. `?touchscale=1` forces it on a desktop.

## Where the rest of the compile goes (main 3d276d57)

A scratch probe timed how long the page waits on each shader program's link, which is where the driver's compile blocks, with each program's pass defines. It ran at x1 on this PC through Tools' launcher.

| Programs | Count | Wait |
| :--- | :--- | :--- |
| The engine's default specializations: the four scene passes (colour and depth, plain and instanced), with lights and fog on | 100 | 10.3 s |
| What the game draws: the same passes with fog and lights off (`DISABLE_FOG`, `DISABLE_LIGHT_*`) | 33 | 3.6 s |
| 2D (canvas) | 25 | 0.3 s |

- **Every 3D material shader compiles six programs at its first draw.** Four are the engine's default specializations: Godot's GLES3 back end compiles the default of every scene pass when a shader is first bound. Two are the specialization the game draws. Our scene is unshaded and has no fog, so it never draws the defaults.
  - The terrain is drawn plain, yet its instanced programs compile too.
  - The building casts no shadow, yet its depth programs compile too.
- **The building:**
  - its six programs wait 2.8 s in all: colour 770, 784 and 786 ms; depth about 155 ms each;
  - only the last colour program and one depth program are drawn.
- **The start block:** two programs with no marker of ours (probably Godot's default 3D material) wait 0.83 s each at 0.6 s and 1.5 s.
- **Not in our code:**
  - Godot has no project setting for this.
  - Its shader cache cannot help on the web: WebGL has no program binaries.
  - Removing the defaults needs an engine change in a custom export template: compile a pass's default only when it is drawn. With `KHR_parallel_shader_compile`, which Chrome has, the rest could compile off the main thread.
- **The building's own code** (FXC timed offline on ANGLE's HLSL, d3dcompiler_47, best of two; about 0.8 s a colour program):
  - the window block is about two thirds of it, and the held hits' marks are a quarter;
  - constant loop bounds and gradients inside branches are **not** the cost (both changed, no gain);
  - a smaller window block would save in all six programs, but the gain is far smaller than the engine's defaults.
