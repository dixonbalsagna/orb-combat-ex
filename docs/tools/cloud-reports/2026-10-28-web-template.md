# Cloud report: the custom web template (Tools, 2026-10-28)

Brief: `docs/ep/cloud-briefs/tools-web-template.md`. Branch: `cloud/tools-pipeline/web-template`, from origin/main 54ba1bd. Machine: cloud container, 4 cores, 15 GB. No browser was run.

## SUMMARY

The Godot 4.7.2-stable web template builds here from the checked official source in **12 minutes on 4 cores**. A plain build (`optimize=size lto=none`, every module kept) gives a **38.45 MB wasm, 9.76 MB gzipped**; today's stock template is 39.51 MB and 10.2 MB.

The lazy-specialization patch changes three lines in one function. It applies cleanly to 4.7.2-stable and the patched template builds and links. On a native A/B (same engine code, desktop GL, Mesa), the same seeded match links **40 programs instead of 145**, and the link wait drops from **4.4 s to 1.1 s**. Every frame is byte-identical and the gameplay hash is the same.

Module trims, one at a time: the low-risk set together takes the wasm to **33.15 MB and 8.36 MB gzipped** (−5.3 MB raw, −1.4 MB gzipped). No export preset was changed.

## Builds

All builds used `scons platform=web target=template_release threads=no production=yes optimize=size lto=none` plus the row's flags. Every row from "patched" down includes the patch. Savings are measured against the patched build. Times after the first build are incremental, except the two full rebuilds marked.

| Build | Extra flags | Time (s) | wasm (bytes) | gzip -9 | zip | Saved raw / gz (MB) |
|---|---|---|---|---|---|---|
| Stock 4.7.2 template (`web-template-size.md` §1) | | | 39,514,754 | about 10.2 MB | | |
| Plain | none | 728 (from clean) | 38,450,797 | 9,759,609 | 9,861,194 | |
| Patched | none | 146 | 38,450,604 | 9,759,604 | 9,861,157 | baseline |
| 3D physics | `module_jolt_physics_enabled=no module_godot_physics_3d_enabled=no` | 295 | 36,594,771 | 9,222,077 | 9,319,428 | 1.86 / 0.54 |
| 2D physics | `module_godot_physics_2d_enabled=no` | 291 | 37,025,514 | 9,547,916 | 9,647,312 | 1.43 / 0.21 |
| Navigation | `module_navigation_2d_enabled=no module_navigation_3d_enabled=no` | 294 | 38,125,387 | 9,634,582 | 9,738,135 | 0.33 / 0.13 |
| XR | `module_openxr_enabled=no module_webxr_enabled=no module_mobile_vr_enabled=no` | 294 | 38,393,616 | 9,742,917 | 9,840,288 | 0.06 / 0.02 |
| Theora | `module_theora_enabled=no` | 304 | 38,403,361 | 9,743,015 | 9,844,229 | 0.05 / 0.02 |
| Importers etc. | `gltf fbx csg gridmap lightmapper_rd raycast vhacd camera mp3` all `=no` | 263 | 36,968,748 | 9,324,727 | 9,423,357 | 1.48 / 0.43 |
| Image formats | `basis_universal ktx tga bmp tinyexr` all `=no` | 686 (full) | 37,882,935 | 9,488,324 | 9,591,153 | 0.57 / 0.27 |
| Text server | `module_text_server_adv_enabled=no module_text_server_fb_enabled=yes module_msdfgen_enabled=no` | 217 | 36,838,948 | 9,174,039 | 9,273,643 | 1.61 / 0.59 |
| TLS | `module_mbedtls_enabled=no` | 230 | 37,940,086 | 9,448,753 | 9,547,923 | 0.51 / 0.31 |
| ENet, UPnP | `module_enet_enabled=no module_upnp_enabled=no` | 272 | 38,313,020 | 9,740,607 | 9,836,192 | 0.14 / 0.02 |
| Deprecated API | `deprecated=no` | 770 (full) | 37,722,608 | 9,628,196 | 9,724,548 | 0.73 / 0.13 |
| **Low-risk set together** | 3D and 2D physics, navigation, XR, theora, importers (without mp3), ENet, UPnP | 199 | **33,148,078** | **8,360,782** | **8,455,818** | **5.30 / 1.40** |

SHA-512 of the patched zip: `60b6c84beec91678666c3efab298c7e0f4131110d99eeb0efca946faaf472324a566f61b5d93d9c213639a7ee9b041dbd4b4b1f190f10cfd2fb4421fbd73078f`. It is for this build only: a pin for the site should come from the workflow's own run.

## What was proved, and how

- **The source.** Checked against the release's `SHA512-SUMS.txt`. That file's hashes for the Linux zip and the export templates match `.github/actions/setup-godot`.
- **The toolchain.** emsdk at tag 4.0.11 (commit `d49219d0`), which is the `EM_VERSION` in 4.7.2's own `web_builds.yml`. SCons 4.10.1, the version 4.7.2's own `godot-deps` action uses.
- **The patch applies cleanly.** `git apply --check -v` passes on the clean unpacked tarball, and the patched web template compiles and links.
- **Native A/B.** I built two Linux release templates from the same checked source, one stock and one patched, an incremental rebuild apart. Godot's desktop GL and WebGL share `drivers/gles3`, so this tests the patched code itself. I ran both on a pack exported from HEAD with Godot's and Mesa's shader caches off, as on the web. Each run was a seeded match (`-- --frames=300 --seed=12345 --nointro`), under Xvfb with Mesa llvmpipe. An `LD_PRELOAD` shim counted and timed every `glLinkProgram`, and Mesa's shader capture recorded every program's source. Tool: `tools/engine/check/native-ab.sh`.
  - **Programs linked: stock 145, patched 40**, in each of three sequential runs. All 40 patched programs are among stock's 145, so none is new.
  - Of the 105 dropped, 91 are scene-pass defaults (fog and lights on) and 14 are built-in passes (2D, copy, sky) that were compiled and never used. The 28 scene programs the game actually draws are linked by both builds.
  - **Link waits: 4.33 to 4.45 s on stock, 1.13 to 1.15 s patched**, on an idle machine, about 74% less. Orb's PC measured 10.3 of 14.1 s in the defaults, about 73%.
  - **The picture.** The 300-frame final frame is byte-identical, and the gameplay hash is the same (`efa002db4bda76d2`). A 1,200-frame movie at 640x360 gave 1,218 PNG frames per build, **every one byte-identical**, with the same gameplay hash (`56f612be99dae13f`).
- **Not proved here.** The web's own figures: WebGL through ANGLE, Chrome's link times, the frame bench, the freeze probe and the side-by-side. Program counts depend on load: two runs at once compiled fewer in both builds, because the boot paces its loads by the clock. Only sequential runs are reported.

## CHANGES

- `tools/engine/patches/4.7.2-lazy-specializations.patch`: new. Touches `drivers/gles3/shader_gles3.cpp` only (`ShaderGLES3::_initialize_version`).
- `tools/engine/README.md`: new. Says what the patch touches and why, why it is safe, the measurement, and why `KHR_parallel_shader_compile` is not in it.
- `tools/engine/check/native-ab.sh`, `tools/engine/check/linkcount.c`: new. The native A/B (Linux, Xvfb, Mesa).
- `.github/workflows/web-template.yml`: new, `workflow_dispatch` only. It:
  - fetches the source and checks it twice (against the release's list and a pinned hash);
  - clones emsdk by tag and checks the commit;
  - installs SCons 4.10.1 in a venv;
  - applies every `tools/engine/patches/4.7.2-*.patch` with `git apply --check`;
  - builds, prints the sizes and SHA-512, and uploads the zip and its `.sha512` as an artifact.

  An optional input `extra_flags` takes module trims. Not run from here. No other workflow changed.
- `docs/tools/cloud-reports/2026-10-28-web-template.md`: this report.

Every path is inside Tools' own (`tools/`, `.github/`, `docs/tools/`). Nothing binary is committed.

## DECISIONS

- **The patch is unconditional, not limited to the web.** It only ever ships in this web template, and the desktop shader cache stays valid with it (it stores whatever exists), so a guard would only add lines.
- **No `KHR_parallel_shader_compile`.** Using it means not waiting on the link and skipping a draw until its program is ready. That makes objects appear late, which is a visible change needing a switch and the look gate. Better as its own step once this patch's gain is measured on the web.
- **Trims were measured with module switches, not the global `disable_navigation_*` and `disable_xr` switches.** The module switches rebuild far less. `deprecated=no` was the one global switch measured.
- **`mp3` stays out of the low-risk set.** §4 says to hold it until the music format is settled. **The image formats and the text server stay out too.** Both need a check before use (below).
- **The workflow pins `actions/upload-artifact` v7.0.1 by commit** (`043fb46d`). I read that commit with `git ls-remote`, which fetches tag names only, nothing else. **Node came from Emscripten's release storage**, not nodejs.org: `emsdk install 4.0.11` fetched `node-v22.16.0` from `storage.googleapis.com/webassembly/emscripten-releases-builds/deps/`, Emscripten's official mirror. The brief named nodejs.org; flagging the difference.
- **Branch.** The session's own setup named `claude/beautiful-dijkstra-g1rfkd`, so the same commits are pushed there too. The brief's branch is `cloud/tools-pipeline/web-template`. Read that one.

## NEEDS FROM EP

1. **Get the template.** Either run "Web template" by hand (Actions, empty `extra_flags`) and download the artifact, or build locally with the same command. Then point the Web preset's `custom_template/release` at the zip **locally, without committing the preset**.
2. **The checks to run locally with it, against the standard template:**
   - `node sim/core/tools/web_parity.mjs`: the sim must be bit for bit the same on the new engine build.
   - The link-wait probe of `docs/rendering/boot.md` ("Where the rest of the compile goes"), at x1. Expected: the 100 default programs and their 10.3 s gone, the 33 drawn ones and the 2D ones as before or fewer.
   - `docs/perf/tools/freeze-probe.mjs` at x1, x4 and x6. The first frames should lose most of the shader wait.
   - `docs/perf/tools/frame-bench.mjs` at x1, x4 and x6. Expected unchanged. The stock template is already built with `optimize=size` (4.7.2's web default), so the only build difference is `lto=none` here against the release's default, `lto=thin`.
   - The look gate: `node tools/flash/side-by-side.mjs`, standard template against the new one. **Look evidence pending (local).** The native frames are byte-identical, but that is desktop GL on Mesa, not WebGL on ANGLE.
   - The site checks the site job runs (`tools/check-site-offline.mjs` and the rest) on an export with the new template.
3. **Before any image-format trim:** a scan of the pack's imported texture formats. `basis_universal`, `ktx`, `tga`, `bmp` and `tinyexr` save 0.57 MB raw and 0.27 MB gzipped, and a missing decoder fails silently at load.
4. **A ruling from Orb before the text-server trim.** It saves 1.61 MB raw and 0.59 MB gzipped, and is the biggest gzipped saving of any single row. It drops right-to-left and complex scripts from the web build, and changes kerning (look gate).
5. **A ruling on TLS** (0.51 MB raw, 0.31 MB gzipped). Any `HTTPRequest` to an https address, such as a leaderboard, would need it back.

## RISKS

- **Godot 4.7.2's `SConstruct` has a module-loop bug.** When a module is disabled for a missing dependency, the loop `continue`s before `sys.modules.pop("config")`. The next module is then judged by the wrong `config.py`. Here, disabling `basis_universal` alone disabled `ktx`, which pulled the editor-only `lightmapper_rd` into the web link, and the link failed.
  - The workaround is to always disable a module's dependents with it (`ktx` with `basis_universal`, `fbx` with `gltf`, `theora` with `vorbis` or `ogg`).
  - The workflow's `extra_flags` can hit it. The failure is a loud link error, not a silent one.
- **The patch's gain is measured on Mesa, not ANGLE or Chrome.** Program counts carry over, since the same code picks them. Seconds will not carry over as they are.
- **The patch moves compiles, it does not remove those the game needs.** A pass first drawn mid-match, such as a beam's material or the first shadow, compiled its own program there before too. Nothing new compiles at a new moment. But anything that used to compile at the first frame only as a default now compiles at its first real draw, if one ever comes.
- **Byte reproducibility across machines is not checked.** The zip carries file times. The site should pin the hash the workflow prints, not one from here.
- **The `deprecated=no` row is an estimate of the API's cost, not a check that the game compiles without it.** The headless gates would have to run on a desktop build with `deprecated=no`.

## NEXT

1. EP: the local checks in NEEDS 2 on the patched template with every module kept. Patch first, trims second, so each change has its own evidence.
2. Then the low-risk trims (−1.4 MB gzipped) as a second template, through the same checks. Image formats after the pack scan.
3. Then, separately, `lto=thin` (the release default) against `lto=none` for size and speed. And `KHR_parallel_shader_compile` behind a switch, if the web's remaining link wait still matters after this patch.

Gates run on this tree, which touches no game code:
- `node tools/validate.js`: last line "277 files checked, 0 errors, 0 warnings", exit 0.
- `node tools/validate.js --self-test`: last line "parser 282 files + 7 text cases; engine 46 cases + 6 unsupported; schemas 169; data cases 8149", exit 0.
- `node tools/lint-determinism.mjs`: last line "determinism lint ok: no engine trig, PI/TAU, random numbers or clock in sim/core, sim/director, sim/world, sim/input", exit 0.

The Godot gates and `npm test --prefix sim` were not run: nothing they cover changed.
