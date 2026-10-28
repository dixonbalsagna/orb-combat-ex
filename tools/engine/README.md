# Engine patches for the custom Web export template

Owner: Tools. Text patches against the official Godot **4.7.2-stable** source (the release's `godot-4.7.2-stable.tar.xz`, SHA-512 checked against its `SHA512-SUMS.txt`). Nothing binary is committed. The manual workflow `.github/workflows/web-template.yml` fetches the source, applies every `patches/4.7.2-*.patch` with `git apply` (which works on the unpacked tarball; no git repository is needed) and builds the single-threaded Web release template. Why we build our own template: `docs/tools/web-template-size.md`; the first build's figures: `docs/tools/cloud-reports/2026-10-28-web-template.md`.

To apply one by hand, from the unpacked source folder:

```bash
git apply --check -v /path/to/orb-combat-ex/tools/engine/patches/4.7.2-lazy-specializations.patch
git apply /path/to/orb-combat-ex/tools/engine/patches/4.7.2-lazy-specializations.patch
```

## 4.7.2-lazy-specializations.patch

**Touches one file: `drivers/gles3/shader_gles3.cpp`, the function `ShaderGLES3::_initialize_version`.** Three lines removed, two comment lines added.

**Why.** In stock 4.7.2, the first time any GLES3 shader version is bound, `_initialize_version` compiles and links the *default* specialization (every specialization bit at its default: lights, fog and the rest on) of *every* variant (pass) the shader has, before the specialization actually asked for is compiled. For a 3D material that is the colour and depth passes, plain and instanced: four programs nobody draws in our unshaded, fog-free scene, on top of the one or two it does draw. On Orb's PC that is 100 of the scene's 158 programs and 10.3 of 14.1 s of link waits at the first frames (`docs/rendering/boot.md`, "Where the rest of the compile goes"). WebGL has no program binaries, so the engine's shader cache cannot hide it on the web.

**What it changes.** `_initialize_version` now only creates an empty table of specializations per variant. `_version_bind_shader` already compiled a missing specialization on the spot (the code path every non-default specialization took in stock 4.7.2), so each pass's specialization is now compiled the first time it is bound, and only then. Nothing else needs it:
- no caller binds or reads uniforms of a specialization it has not bound first (`_version_get_uniform` is only reached after the bind);
- the "queued build, fall back to the default" branch of `_version_bind_shader` is dead in 4.7.2 (`build_queued` is never set), so nothing falls back to a default that is no longer there;
- `version_get_native_source_code` builds source text for the default specialization without compiling it, unchanged;
- the shader cache (desktop and mobile only; `_save_to_cache` and `_load_from_cache` return at once on the web) stores whatever specializations exist, so it stays valid, and simply holds no programs until the first one is bound. This template is Web only.

**What it does not change.** The programs the game does draw compile exactly as before, at the same moment (their first draw) and from the same source text, so what the player sees should be unchanged. The canvas (2D), sky, copy and other built-in shaders also go lazy: each pass compiles at its first use instead of all of them at once, which can only move or remove waits, never add them. The look gate still applies before the template is used (the side-by-side stays local).

**Not done: `KHR_parallel_shader_compile`.** With it, the browser compiles off the main thread, but the engine would have to stop asking for the link status straight after `glLinkProgram` and skip (or substitute) a draw whose program is not ready yet. That means objects appear a frame or more late at first sight: a change to what the player sees, which needs a switch, the look gate and a larger patch touching the scene, canvas and sky renderers. It belongs in its own brief once this patch's gain is measured locally.

**Measured (cloud, 2026-10-28; `check/native-ab.sh`).** Linux templates built from the same source with and without the patch, the same seeded match (300 frames, seed 12345, 1280x720, Mesa llvmpipe under Xvfb, Godot's and Mesa's shader caches off): **145 programs linked on stock, 40 patched**, every one of the 40 also linked on stock; the link waits 4.3 to 4.5 s and 1.1 to 1.2 s; the gameplay hash and the last frame's bytes identical. A 1,200-frame run at 640x360 gave 1,218 frames, every one byte-identical. Of the 105 programs no longer linked, 91 are the scene passes' defaults (fog and lights on) and 14 are built-in passes (2D, copy, sky) that were compiled but never used.

## check/

`native-ab.sh` and `linkcount.c`: the A/B above, for a Linux box with Xvfb and Mesa. It is proof that the patch compiles less and draws the same; the web's own timings (the frame bench, the freeze probe, `docs/rendering/boot.md`'s link-wait probe) stay with the local runs.
