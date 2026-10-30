# A smaller web engine: what a custom export template could drop, and what it would buy (2026-10-26)

Owner: Tools. For the EP, after the Android start freeze (`docs/perf/phone-freeze-2026-10-26.md`). **Nothing was downloaded or built.** What follows is measured on this PC from the files we already have (the exported `index.wasm` of HEAD, the Godot 4.7.2 executable on this PC, the project's own text), or it is marked as an estimate.

## 1. The premise, measured: the wasm itself is not what takes the time

The exported `index.wasm` is **39,514,754 bytes**: 34.5 MB of code (71,003 functions), 4.7 MB of data, an element table of 224 KB. Compressed: **gzip -9 10.2 MB, brotli 8.0 MB** (the page is served by GitHub Pages; what it applies on the wire is its own business, so the first figure is the safe one).

How long a browser takes to compile it (headless Chrome through the guarded launcher, `WebAssembly.compile` on the bytes already in memory; two runs each, the CPU throttle slows the main thread only, and the compile runs on background threads):

| Case | Result |
|---|---|
| Chrome's default (lazy compilation: validate now, compile each function the first time it runs) | **28 to 30 ms** at x1; 46 to 53 ms at x4; 68 to 77 ms at x6 |
| The same with lazy compilation off (eager, as an engine without lazy compilation does) | **185 ms** at x1 on this PC's cores |
| Node's V8, eager, **one** compile thread (the closest to a phone's few slow cores) | **about 1.0 s** (1076 ms and 956 ms in two settings); all cores 288 ms |
| Fetch of the 39.5 MB from the local server | 70 to 160 ms |

So a phone that compiles lazily, as Chrome and Chrome-based browsers do, spends well under a second validating the module; one that compiles the whole thing eagerly spends about **1 s of one fast core here, perhaps 2 to 5 s on a phone** (an estimate: a phone core is several times slower, it has a few cores to share it over). The 3.6 s "engine start" Performance measured to `main._ready` is therefore mostly **not** the module's compile: it is the first run of the functions the engine actually calls (compiled lazily, one at a time), reading and parsing the 8.2 MB pack and loading the scripts. A smaller template shortens the first and the validation by some fraction and leaves the rest. **I do not expect a custom template to move the 57 s block on a phone by more than a second or two, and the block's big parts (the audio bank's warm-up, the first frame's shader compile, the match start) are ours, not the engine's.** Its real benefits are the download (10.2 MB gzipped now), the memory (compiled code of a 34 MB module is large, and a tab killed for memory restarts the whole boot), and a faster parse on a cold install.

Not measured: the lazy-versus-eager split of the *engine start* on a phone, which needs a real device or a profile of function compiles during boot (`--trace-wasm-lazy-compilation` on desktop would list them: a next step that needs no download).

## 2. What is in the template we ship today

Strings in the wasm confirm which libraries are compiled in (a hit is evidence of presence, not of size): Jolt (`JoltPhysics`, `JPH::`), GodotPhysics 2D and 3D, NavigationServer 2D and 3D (recast), **TextServerAdvanced with ICU data, HarfBuzz and Graphite** (and no TextServerFallback), FreeType, msdfgen, ThorVG (SVG), mbedtls, theora, vorbis, minimp3, ENet, OpenXR and WebXR, WebRTC, WebSocket, UPNP, basis_universal, astcenc, etcpak, tinyexr, jpeg, libpng, TGA, BMP, FastNoiseLite, zstd and brotli, minizip, CSG, GridMap, GLTF and FBX documents, the lightmapper (xatlas, embree), vhacd, the camera server, and the 3D joints, soft body and vehicle classes. Nothing here was written or guessed: it is what the 4.7.2 standard web template carries.

## 3. What the game uses

`node tools/wasm/usage-scan.mjs --api <extension_api.json>` (the dump comes from `"$GODOT" --headless --dump-extension-api`) looks for every one of the engine's 954 core classes in the project's shipped text (308 files: scripts, scenes, resources, project settings, shaders). **79 are named.** By family:

| Family | The game |
|---|---|
| 3D rendering | **Uses it**: Node3D, MeshInstance3D, MultiMeshInstance3D, Camera3D, Skeleton3D, BoneAttachment3D, World3D, Environment, Sky, the primitive meshes. So the engine cannot be built without 3D. |
| 3D physics, 2D physics, navigation, XR, networking, video, camera, CSG and GridMap, model import, zip | **No class named anywhere.** |
| Audio | Synthesised at run time: AudioStreamWAV, AudioStreamPlayer2D; no OGG or MP3 file ships today. |
| Fonts, images | Font, ImageTexture; the imported textures need the image decoders their import mode chose. |
| Regular expressions | **Uses it** (four files). |
| Advanced GUI | Uses ColorRect, TextureRect, Window and **TextEdit** (the feedback box): so the advanced-GUI switch is not available to us. |
| Noise | "Noise" is matched in the synth's own code: a word in comments, not FastNoiseLite (the scan over-counts on purpose: it can only say "used" too often). |

## 4. What I would drop, and the risk of each

Savings are **estimates** from what Godot's own build-size notes and community reports give for the pieces; none is measured here (a build is what measures them). "Risk" is what could break.

| Drop | Why it is unused | Est. saving | Risk |
|---|---|---|---|
| `module_jolt_physics_enabled=no`, `module_godot_physics_3d_enabled=no` | No 3D physics class is named; the sim has its own physics and ragdolls | 2 to 4 MB | **Low.** A 3D scene still builds (the engine falls back to a dummy physics server). Breaks if a future 3D feature wants `RigidBody3D` or a raycast against colliders (a picture-only ray test would). |
| `module_godot_physics_2d_enabled=no` | No 2D physics class named | about 1 MB | **Low.** The same: only a future 2D physics node. |
| `disable_navigation_2d=yes`, `disable_navigation_3d=yes` (or `module_navigation_*_enabled=no`) | None named | 1 to 2 MB | **Low.** Breaks if AI ever wants the engine's pathfinding; the sim's AI is our own. |
| `module_openxr_enabled=no`, `module_webxr_enabled=no`, `module_mobile_vr_enabled=no`, `disable_xr=yes` | A fighting game in a browser tab | 0.5 to 1 MB | **Very low.** |
| `module_theora_enabled=no` | No video stream | 0.3 to 0.6 MB | **Low.** Breaks cut-scenes as Ogg Theora video (the plan is rendered in-engine). |
| `module_gltf_enabled=no`, `module_fbx_enabled=no`, `module_csg_enabled=no`, `module_gridmap_enabled=no`, `module_lightmapper_rd_enabled=no`, `module_raycast_enabled=no`, `module_vhacd_enabled=no`, `module_camera_enabled=no`, `module_minimp3_enabled=no` | No class named; the importers only matter in the editor (imported models are already scenes in the pack) | 2 to 4 MB together | **Low.** `minimp3` is the one to hold: if Suno hand-backs ever ship as MP3 instead of OGG (the music plan encodes OGG, `docs/tools/music-encode-proposal.md`), keep it. A runtime glTF loader for fighter models would need `gltf` back. |
| `module_basis_universal_enabled=no`, `module_tga_enabled=no`, `module_bmp_enabled=no`, `module_tinyexr_enabled=no` | No file in those formats is loaded at run time | 1 to 2 MB | **Low to medium.** Dropping an image decoder fails *silently at load* for any resource that used it: check the pack's imported texture formats first (a scan of the pack's `.ctex` headers), and never drop `webp`, `jpg`, `svg` or `etcpak`/`astcenc` until that check is done. |
| `module_text_server_adv_enabled=no` (use the fallback text server), with `module_msdfgen_enabled=no` | The game's text is Latin, in one font | **2 to 4 MB** (ICU data, HarfBuzz, Graphite) | **Medium to high.** The fallback server has no right-to-left, no complex scripts, basic line breaking and no OpenType features: a **localisation to Arabic, Hebrew, Thai, Hindi or good CJK wrapping would break**. Do this only if Orb rules out those languages for the web build, or keep it as a "lite" variant. It changes the look of kerning slightly too: the look gate (ADR 0010) applies. |
| `module_mbedtls_enabled=no` | No HTTPS request is made (the feedback button copies to the clipboard) | 0.7 to 1 MB | **Medium.** Online play, a leaderboard or any `HTTPRequest` would need it: it is on the roadmap after launch. Rebuild then, or leave it in. |
| `module_enet_enabled=no`, `module_upnp_enabled=no` | Neither can work in a browser (no raw UDP, no UPnP) | 0.5 to 1 MB | **Very low** for the web template. Keep `websocket` and `webrtc` and `multiplayer`: they are how online play will work in a tab. |
| `deprecated=no` | The game calls no deprecated API (a scan of the engine's own warnings would settle it) | 0.3 to 1 MB | **Low to medium:** a script that still calls a deprecated function stops compiling. The headless checks would catch it. |

**What stays, and why:** the 3D renderer and the Compatibility (OpenGL) driver, GDScript, `regex`, FreeType, the image decoders the pack's textures use, `vorbis` and `ogg` (the music), `svg` (the default theme's icons are rasterised from SVG at start; dropping it needs the UI to confirm it uses none), WebSocket, WebRTC and multiplayer (online play), zstd, minizip (the pack format and patches), and TextEdit and the rest of the advanced GUI (the feedback box).

**The larger saver is not a module.** `optimize=size` (with link-time optimisation) trades some run speed for code size; the usual figure for the web template is 15 to 25% off the wasm, and about 5 to 15% slower code. The game's budget (16.7 ms on the old-laptop bound) is tight, so this one needs the frame bench (`docs/perf/tools/frame-bench.mjs`) before it is chosen: on a phone, **a slower frame costs more than a smaller download saves**.

Combined, my estimate is **39.5 MB to roughly 25 to 31 MB** with the low-risk modules and size optimisation, and to 22 to 27 MB with the text-server and TLS changes too. Unmeasured; a build gives the real number.

## 5. What a custom template needs

Everything here is a download, so none was started:
- **The engine source** at the tag `4.7.2-stable` (a source archive, about 60 MB compressed, from the Godot release page; the same checksum rule as `.github/actions/setup-godot`).
- **Emscripten**, the version Godot 4.7's docs name for the web build (the 4.x series pins one; to be read from the docs and the `SConstruct`, not guessed): the emsdk download is about 1 GB with its LLVM and Binaryen, and about 3 GB unpacked.
- **Python 3 and SCons 4** (small), a C++ build for the web (single-threaded wasm, `dlink_enabled=no`, `threads=no` to match the export preset: `thread_support=false`).
- **Time and disk:** a web template build is a long compile: about 30 to 60 minutes on this PC's 16 cores for one release template, and 8 to 10 GB of disk for the build tree. It would run below normal priority, one job at a time, in a scratch folder.
- **The command**, to be read from 4.7.2's own documentation when the source is there: `scons platform=web target=template_release threads=no ...` with the `module_*_enabled=no` options of the table above and `optimize=size lto=full production=yes`; then the template zip (`web_nothreads_release.zip`) goes where the export preset's `custom_template/release` points.
- **Hosting and trust:** CI should not build it on every push. A separate manual workflow builds it, publishes the zip as a **release asset or artifact**, and the site job downloads it with a pinned SHA-512, the way `setup-godot` pins the standard templates ("Nothing binary is committed" stays true). Reproducibility is the point: the same source and flags give the same bytes, so the pin is meaningful.
- **Proof before use:** the whole check set with the custom template (`parity`, `determinism`, the render gates and the web parity workflow: a different engine build must give the same sim bits; the web-parity check exists for exactly this), the look gate's side-by-side against the standard template, the frame bench and the freeze probe at x1, x4 and x6.

**My recommendation:** do not start this for the freeze. The wasm's compile is measured at well under a second on Chrome and a few seconds at worst; the stall is ours (the audio warm-up, the first-frame shader compile, the match start). Spend the effort there first (Performance's list in the freeze note). A custom template is still worth doing **later**, for the download and the memory, when someone has an hour to spare for the toolchain and Orb has said yes to the downloads; the first step then is a plain `optimize=size` build with *no* module removed, to see what that alone gives and whether the frame bench tolerates it.

## 6. Files

`tools/wasm/usage-scan.mjs` (the class-usage scan: nothing downloaded; it needs the engine's own `--dump-extension-api`). Scratch measurements: the compile probes (`WebAssembly.compile` at three throttles through `tools/machine/browser.mjs`; Node's V8 with one compile thread) are in my scratch folder and are easy to re-run; the figures above are theirs.

## 7. The build, step by step, on a local machine (Tools, 2026-10-27, reworded 2026-10-30)

Orb said yes to the downloads (2026-10-27, through the EP: the Godot 4.7.2-stable source and emsdk with its toolchain; SCons from PyPI too, the EP's call on Orb's delegation). This is the recipe for building the template by hand on a PC, for example to try a module trim before the workflow does. The shipped template (`web-template-4.7.2-lazy-1`) was not built this way: `.github/workflows/web-template.yml` built it on a GitHub runner from the same source and flags, with the lazy-specialization patch and no trims, and `tools/web-template.json` pins the result (flags, source hash, Emscripten, patch hash, zip and wasm SHA-512). A hand build is only ever used by publishing it and pinning the published zip. The steps were read from the source and the fetch, verify and install parts were done in a scratch folder (never committed). A local build is a long run: start it at below-normal priority on a quiet machine, one scons job at a time, with no other long run beside it.

**1. The engine source** (47.7 MB), from the official release page, checksum checked:
- `https://github.com/godotengine/godot/releases/download/4.7.2-stable/godot-4.7.2-stable.tar.xz` and `.../SHA512-SUMS.txt` (the same release's sums file; it also lists the two hashes `.github/actions/setup-godot` pins for the editor zip and the templates, which is how the sums file itself was checked).
- SHA-512 of the tarball: `15e23f8423003f5d32da07c34a8651e43af23b050cc0dea2d4fba6944ca445d079edb52b66fdf82b6d5739bba1fe707b9e27b8836b19f09f64f313966160f8fc` (`sha512sum -c` said OK). Unpack with `tar -xf` into a SHORT path (Windows: deep paths break emscripten and SCons).

**2. Emscripten 4.0.11.** The engine's own CI pins it (`EM_VERSION: 4.0.11` in `.github/workflows/web_builds.yml`); `platform/web/detect.py` only requires 4.0.0 or newer. (The standard 4.7.2 template that the game ships today reports `Emscripten 4.0.20, single-threaded, no GDExtension support` in the browser console: the custom build uses the engine CI's version, so the toolchain is not what differs.)
- `git clone https://github.com/emscripten-core/emsdk.git`, then `git checkout 4.0.11` (commit `d49219d03a41cd12f95a33ba84273c20d41fd350`, "Release 4.0.11").
- `python emsdk.py install 4.0.11` (Linux: `./emsdk install 4.0.11`), then `python emsdk.py activate 4.0.11` and `source ./emsdk_env.sh` (Windows: `emsdk_env.bat`). It fetches, from the official Emscripten storage (`storage.googleapis.com/webassembly/emscripten-releases-builds/`), the LLVM and Binaryen build for releases tag `7033fec38817ec01909b044ea0193ddd5057255c` (`wasm-binaries.zip`, 622 MB on Windows) and Node from nodejs.org; on Windows it also takes its own Python 3.13.3 (30 MB, same storage), which is a usable interpreter for SCons.
- Check with `emcc -v` (it must say 4.0.11).

**3. SCons 4.4 or newer** (`EnsureSConsVersion(4, 4)` in the SConstruct; Python 3.9 or newer): `pip install scons` (PyPI; the workflow pins the version). The system Python on the project PC is 3.14.7, which has not been tried with SCons: the emsdk Python 3.13.3 is the fallback.

**4. Step 1, the plain build, no module removed** (from the unpacked source folder, with emsdk activated):
```
scons platform=web target=template_release threads=no arch=wasm32 dlink_enabled=no optimize=size production=yes lto=none debug_symbols=no
```
- `threads=no`, `arch=wasm32`, `dlink_enabled=no` match the export preset (`thread_support=false`, no GDExtension). `optimize=size` is one of the SConstruct's enum values (`auto none custom debug speed speed_trace size size_extra`). `production=yes` sets the production defaults; its `lto=auto` is overridden by the explicit `lto=none` (full LTO makes the link very slow; a later step may try `lto=thin` or `full`). No closure compiler (`use_closure_compiler=no`, the default: it would be one more npm download).
- Add `-j 8` (or the machine's cores minus a few); one scons job at a time. About 30 to 60 minutes on 16 cores and 8 to 10 GB of disk (the estimate of section 5, still unmeasured).
- The result is `bin/godot.web.template_release.wasm32.nothreads.zip`; the template's name for the export preset is `web_nothreads_release.zip` (rename it), pointed at by `custom_template/release` in a SCRATCH copy of `export_presets.cfg` only; nothing binary is committed (section 5: a manual workflow publishes the zip with a pinned SHA-512).

**5. Step 2, Rendering's change** (an engine change in a scene pass's default specializations: compile only when drawn; see `docs/rendering/boot.md`, "Where the rest of the compile goes", and its tools in `docs/rendering/tools/`). Rendering writes the shader-side part, Tools applies and builds it. **Step 3**, module trims one at a time (the table of section 4), each with the frame bench.

**6. Proof before the demo uses a template** (the list the EP set): parity, determinism, the 19 render gates, the web parity check (same sim bits as the standard template), the side-by-side against the standard template, both collapse modes, the frame bench, and the freeze probe at x1 and x4. A template build never runs on the same machine as a long QA run, and below normal priority.
