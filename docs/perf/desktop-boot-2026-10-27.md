# Desktop start-up for Steam: the Windows export of d7647634, the web side, platform notes (2026-10-27)

Owner: Performance and Platform, for the EP and Orb. **Status: the Windows export is built and the web side is measured. The native launches (cold, warm, bench) are NOT run yet: they need a real Godot window and a move of two shader-cache folders, which Orb has to answer first (the EP put both to Orb on 2026-10-27).** The native rows below say so; nothing in them is an estimate.

## What is built

A Windows Desktop **release** export of d7647634 (the "Windows Desktop" preset, Compatibility renderer, Godot 4.7.2's installed `windows_release_x86_64.exe` template, no download), exported headless with `tools/make-desktop-export.mjs --rev d7647634 --marks`: one file, `orb-combat-ex.exe`, **117.6 MB** (the pck is embedded; the template is 109 MB, so the game's data and scripts are about 8 MB) and its `orb-combat-ex.console.exe` (188 KB, prints the boot marks on stdout). The scratch copy carries the boot marks of `hook-bootprof3.mjs --native` (lines `BP <name> <engine ms>`) and has the console wrapper switched on for release (the repo preset has `debug/export_console_wrapper=1`, debug only, so a release export has no console exe; that is right for shipping and only matters for measuring). The export is in my scratch folder, not in the repo.

## What the native run will measure (the protocol, ready)

1. Cold first launch: Godot's project shader cache (`%APPDATA%\Godot\shader_cache`, and the game's `app_userdata\Orb Combat EX`) and NVIDIA's OpenGL cache (`%LOCALAPPDATA%\NVIDIA\GLCache`, 8 MB) moved aside, then the console exe launched at below-normal priority, window off-screen and unfocused, on the RTX (the default GPU). Marks: engine start, the script load, `_ready`, first frame, boot done (= playable), and every boot frame's length. The longest main-thread block is the longest gap between two marks and two boot frames.
2. Warm second launch: the same, caches as the first run left them.
3. Steady frames: `orb-combat-ex.console.exe --fixed-fps 60 -- --seed=4 --frames=2400 --bench` (the game's own bench, which prints frame, view-update, tick, render and draw-call stats and the gameplay hash at the end), against the web numbers below, which are the same run.
4. Not touched: `%LOCALAPPDATA%\NVIDIA\DXCache` (32 GB of every game's shaders) and `D3DSCache`. The Radeon is not selectable from Godot's OpenGL driver without changing a Windows per-app graphics setting, so the native side is RTX only unless Orb says otherwise.

## The web build, same commit, same scene (measured)

Scratch web export of d7647634; the game's bench (AI match, seed 4, fixed 60 fps, `-- --seed=4 --frames=N --bench`) at 1280 by 720, vsync off, `tools/machine/browser.mjs` launcher at below-normal priority, quiet check before each run, one browser at a time (`tools/bench-page.mjs`). ANGLE Direct3D 11 on both GPUs.

| Web, d7647634 | frame p50 | p95 | p99 | max | view update p50 | tick p50 |
|---|---|---|---|---|---|---|
| RTX 5070 Ti, x1 (2 runs, 2,400 frames) | 6.4, 6.5 | 13.8, 14.4 | 18.0, 18.9 | 25.6, 25.0 | 2.6, 2.7 | 0.6 |
| Radeon iGPU, x1 (2 runs) | 7.3, 9.5 | 13.7, 18.5 | 19.0, 22.2 | 24.4, 28.6 | 2.7, 3.7 | 0.6, 0.9 |
| RTX, CPU x4 (1,200 frames) | 56.4 | 78.9 | 102.4 | 130.5 | 22.9 | 4.7 |
| Radeon, CPU x4 | 43.5 | 67.9 | 89.2 | 109.3 | 17.2 | 3.6 |

- The two Radeon x1 runs differ by 30% in p50 (view update 2.7 against 3.7 ms: the CPU side was slower in the second, so it is machine noise, not the GPU); read it as a range. The RTX is steady. At x1 both GPUs are CPU-side-bound in this scene (the page's frame is the wasm main thread's work: 3 to 4 ms of view update and tick, the rest the engine and the browser).
- **Gameplay hash: `d4f6342a1009bdbc` at tick 2,400 in all four x1 runs** (and `2b6a55ae88b58c30` at 1,200 in both x4 runs): the same match every time, on both GPUs. The native `--bench` prints the same hash line at the same frame count, so the native run doubles as a native-against-web match check on this commit.
- Boot (web, commit 3d276d57, from `boot-start-block-2026-10-27.md`): start block (page start to first frame) **4.4 s at x1, 15.5 s at x4**; playable **22.6 to 23.5 s at x1, 40.7 to 41.1 s at x4**; the last four shader programs compile as frames of 3.7, 2.9, 1.9 and 1.0 s at x1 (the driver, not scaled by the CPU throttle). The page is served from this PC, so there is no download time in them.

| Native, Windows export | cold launch | warm launch | steady frames |
|---|---|---|---|
| start block, longest block, time to playable, first-frame compile | not run (waiting for Orb) | not run | |
| frame p50 / p95 / p99 (`--bench`) | | | not run |

## Platform notes for Steam

**Windows (the first target).**
- The "Windows Desktop" preset exports as it is: the build above came out of it with no change and no warning that stops it. What it does not set: **no icon** (`application/icon` is empty, so the exe shows Godot's icon), **no version or product text**, **no code signing** (Windows SmartScreen will warn on a first download from outside Steam; Steam installs are not affected the same way), and the **console wrapper is debug-only** (fine for shipping).
- The embedded pck makes it one 117 MB file, which is what a Steam depot wants. Setting an icon and version text needs Godot's `rcedit` setting (an editor setting, not in the project) and a real icon file: Tools' and Art's job.
- `runnable=false` on the Windows preset only stops the editor's one-click run; it does not matter for an export.
- No Steamworks binding is in the project (no GDExtension, nothing named Steam in code): the game launches from Steam as a plain exe. Achievements, cloud saves and the overlay would need the GodotSteam extension, which is a native library per platform and is not installed; no web build can use it, so it would be a desktop-only addition.

**Linux for the Steam Deck.**
- From what is installed here: Godot 4.7.2's export templates include `linux_release.x86_64` (and debug, x86_32, arm32 and arm64). Nothing else needs downloading for a Deck build.
- **The repo has no Linux preset** (`export_presets.cfg` holds "Web" and "Windows Desktop" only). A Linux preset has to be added: platform Linux, x86_64, embed pck, `texture_format/s3tc_bptc=true`, the same filters and `script_export_mode=2` as the others. Tools' job.
- The renderer is already **Compatibility** (OpenGL 3.3 / ES 3 class), which runs on the Deck through Mesa's OpenGL driver; no Vulkan path is needed. I could not run it on a Deck or a Linux machine here, so it is unmeasured: the Deck's frame time, its 1280 by 800 screen and a controller run through Steam Input are all untested. (Steam Deck Verified needs a Deck, see `stores-and-consoles.md`.)
- A Linux binary exported on a Windows machine does not carry the executable bit; the usual fix is to export on Linux (the Ubuntu CI runners already have Godot 4.7.2) or to mark the file in the depot. Not tried here.

**Does the sim match native and web bit for bit? Yes, as measured.** `docs/architecture/web-parity.md` (Simulation, 2026-10-23): Godot 4.7.2's Windows x64 build and its web export give the same sim to the bit, all 45 keys of `golden.json` (184,300 ticks of AI matches, two human-input replays, the planet keys) plus 6 extra keys, with a negative control that caught a one-character change; it runs in CI (`web-parity.yml`, passing since d435ca1d). The GDScript golden also runs natively on Ubuntu in CI (`ci.yml`, `godot-parity`, Linux x86_64), against the same `golden.json`, so Linux x86_64 and Windows x64 agree with the web as well. **Not covered:** ARM builds (phones, Apple silicon) and other browsers; the document names ARM as the real risk. A Steam Deck is x86_64, so it falls under the measured case.

## Not covered

Any native launch or native frame time (waiting for Orb); a Linux or Deck run; the Radeon natively; a real old laptop; the Steam depot and the executable-bit question; the icon and signing steps.

## Files

`tools/make-desktop-export.mjs` (the headless Windows export of a commit, with optional boot marks), `tools/bench-page.mjs` (the web bench with the choice of GPU), `tools/scratch-hooks/hook-bootprof3.mjs` (`--native`). Raw web runs in my scratch folder (`w/farun10/`).
