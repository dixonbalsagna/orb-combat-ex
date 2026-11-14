# KHR_parallel_shader_compile in the custom Web template: the plan, for later (Tools, 2026-10-31)

Status: **not started. Orb has not approved the toolchain download** (the EP, 2026-10-31: no for now; 8.5 s is good enough to play). This page keeps what was learnt so the work can start cold.

## Where the load time is (measured, 2026-10-31)

Same stack tree, Performance's `docs/perf/tools/load-probe.mjs`, cold first visit, 1920x1080, an RTX 5070 Ti, the machine about 90% busy:

| | Standard template | Custom template (`web-template-4.7.2-lazy-1`, the site's) |
| :--- | :--- | :--- |
| Programs linked | 178 | 49 |
| `getProgramParameter` (link wait) | 29.2 s over 354 calls | 8.5 s over 96 calls |
| `getShaderParameter` | 1.5 s | 0.4 s |
| Longest main-thread freeze | 4.9 s | 1.6 s |
| Warm second visit, link wait | 0.3 s | 0.1 s |

Performance's first profile (178 programs, 27.5 s) was the **standard** template: the stack preview was exporting with it. The page now exports with the custom one by default (`tools/preview/stack-preview.mjs --template custom`). "Skip the unused default specializations" is the lazy-specializations patch already in that template. The five biggest programs are 3.9 s of the remaining 8.5 s: scene shaders with a 44 KB vertex and a 128 KB fragment source, 0.5 to 1.1 s each.

## Why the waits are serial

In Godot 4.7.2's GLES3 driver (`drivers/gles3/shader_gles3.cpp`), `_compile_specialization` compiles the vertex and fragment shaders, checks `COMPILE_STATUS`, links, then checks `LINK_STATUS` and reads the uniform locations, for one program at a time. The status checks wait for the browser's compile. So the browser compiles programs one after another while the main thread waits on each. (From the shape of the existing patch; the source was not re-read for this page.)

## The patch, as designed (not written)

1. **Split `_compile_specialization` in two:** *start* (create, `glCompileShader`, attach, `glLinkProgram`; no status read) and *finish* (status, uniform locations; waits only if the program is not ready, polling `COMPLETION_STATUS_KHR` 0x91B1 when the extension is there).
2. **A batch mode.** While it is on, a first bind *starts* the program and returns "not ready" instead of finishing it, and the draw is skipped. Off, behaviour is as it is now. The mode is on only during the boot warm-up, behind the loading card, so no draw is skipped during play and the look is unchanged.
3. **A way to switch the mode from the game:** a project setting read at the warm-up, or a small `RenderingServer` method (a larger patch). Whichever is cheaper, in the same file set.
4. **The warm-up cooperates** (Rendering's, `docs/rendering/boot.md`): pass one draws every material once with the mode on (starts every compile, which Chrome's ANGLE runs on its compile threads in parallel); then the mode goes off and pass two draws normally, finishing each program (most already done). Without this change the engine patch alone gains nothing, because the warm-up binds programs one at a time.
5. **Check Emscripten enables the extension** (its `initExtensions` list; if not, `emscripten_webgl_enable_extension` once at context creation).

## Expected gain, and what is not known

The lower bound is the single longest program, about 1.1 s. A realistic estimate on this machine: 8.5 s down to about 3 to 4 s. **Not measured.** Unknown: how many compile threads Chrome gives the page, how the 5 big programs overlap, and whether Firefox and Safari behave alike.

## What it needs

- **Toolchain** (not installed here: no `emcc`, `scons` or engine source): `godot-4.7.2-stable.tar.xz` (about 60 MB, SHA-512 pinned in `.github/workflows/web-template.yml`), emsdk 4.0.11 (about 1 GB from github.com and Google's storage, tag and commit pinned in the workflow), SCons from PyPI. **Orb's approval of the download.** The alternative is the CI route (`web-template.yml` dispatched with the patch), a public run on the repo, which "private only" rules out.
- **Time:** about a day to a measured private build (a first build 20 to 40 minutes below-normal on a busy machine, then a few minutes a rebuild), then the flip list of `docs/tools/site-template.md`: parity 51 of 51, the signature and collapse clips in both modes, the nightly on the child export, the frame comparison (about another day of machine time; flash work is paused until about 11-04).
- **A look gate:** the warm-up is behind the loading card, so nothing the player sees should change; the frame comparison is the proof.

## A cheaper lever, Rendering's side

A lighter scene shader (mostly unshaded, no light arrays) would shrink the five 128 KB programs and their compile time with no engine change at all. When Rendering's shader cut lands, take a fresh load-probe on the stack page (`node tools/preview/stack-preview.mjs`, then `node docs/perf/tools/load-probe.mjs --site <web dir> --query "planet=7&meteor=loud&tiles=1" --out run.json`, `load-report.mjs run.json`) and compare with the table above.
