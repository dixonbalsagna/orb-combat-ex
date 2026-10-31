# 2026-10-31: the swing test's sources (Rendering). Not a park to land

Scratch only: it goes on a copy of HEAD, never in the game. Results are in `docs/world/ring-any-angle/rendering.md`, section 7.

Put `*.gd`, `*.gdshader` and `*.gdshaderinc` in a `swing/` folder, with `sw_*` beside that folder. `bash sw_mk.sh bake` makes the scratch tree on HEAD, bakes planet 7 and exports the web build to `sw_site/play/`. `sw_c.sh`, `sw_d.sh` and `sw_b.sh` are the runs: stills, seams, benches and flash. `serve.mjs` goes in `sw_site/`, and `node serve.mjs` plays it. They read `tools/flash/` and `docs/perf/tools/` from the repo, and they expect `crop.mjs`-style helpers only for the sheets. `sw_mk.sh` also copies an imported `.godot` from a scratch tree if there is one, which only saves time.
