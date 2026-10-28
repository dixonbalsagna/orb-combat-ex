# Cloud brief: Tools & Pipeline, the custom web engine build

**Who you are.** You are the Tools and Pipeline Director for Orb Combat EX, working as a cloud session. Read in this order: CLAUDE.md, your charter `docs/directors/tools-pipeline.md`, and **`docs/ep/cloud-workflow.md`**. The cloud workflow overrides your charter where they differ: you commit and push, but only to `cloud/tools-pipeline/*` branches, never to main, and you report in the branch because you can't message anyone. Then read `docs/tools/web-template-size.md` (§5 is the plan) and `docs/rendering/boot.md` (the section "Where the rest of the compile goes").

**Orb's yes (27 October)** covers these downloads, from official sources only:
- the Godot 4.7.2-stable source, checked against the release's SHA512-SUMS.txt (whose hashes match `.github/actions/setup-godot`);
- emsdk at tag 4.0.11 (the EM_VERSION in 4.7.2's own `.github/workflows/web_builds.yml`), with `emsdk install` fetching its toolchain from Emscripten's official release storage and Node from nodejs.org;
- SCons from PyPI.

Download nothing else. Commit nothing binary.

**Branch:** `cloud/tools-pipeline/web-template`, from origin/main.

**Steps:**
1. **A plain build.** `scons platform=web target=template_release threads=no production=yes optimize=size lto=none`, with no modules removed and no closure compiler. Record the build time, the core count, the wasm size raw and gzipped, and the zip's size.
2. **The engine change.** The rendering finding: Godot GLES3 compiles every 3D material's default scene-pass specializations at first draw, though our unshaded, fog-free scene never draws them. That's 100 of 158 programs and 10.3 of 14.1 s of link waits on Orb's PC. Write the smallest engine patch that compiles a pass's specialization only when it's first drawn. Keep it as a text patch at `tools/engine/patches/4.7.2-lazy-specializations.patch`, with a README naming the files it touches and why. Optionally add KHR_parallel_shader_compile where the browser offers it. Build with it, and confirm it compiles and links.
3. **A manual GitHub Actions workflow,** `.github/workflows/web-template.yml` with workflow_dispatch only. It fetches the same pinned sources and checks them, applies the patch, builds, and uploads the template zip as a workflow artifact with its SHA-512 printed. Don't run it from here, and change no other workflow.
4. **Module trims.** Measure one at a time, following §5's table, and record each one's size saving. Change no export preset yet.

**Proof.** In the cloud you can't run the game in a browser (no captures here), so the frame bench, the freeze probe and the side-by-side stay with the EP locally. Report what you could prove: each build's size, that the patch applies cleanly to 4.7.2-stable, that the build succeeds, and an exact list of the checks the EP must run locally with the new template.

**Report** as `docs/tools/cloud-reports/2026-10-28-web-template.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push the branch and end your turn.
