# The page's load with World's caches and the custom template, and the proof that a warm visit reads the cache on the web (Performance and Platform, 2026-10-31)

For the EP, on the work order after `page-load-2026-10-31.md`: the stack with `docs/world/pending/gen3-field` diffs 08 (bake cache) and 09 (made planet and node pool in the cache) and the custom web template (Tools' `--template custom`, which is now the page's default), timed cold and warm against the target **warm under 10 s, cold about 20 s**, and a test that **a warm visit reads the cache on the web**, where `user://` is IndexedDB and World was not sure it syncs.

## Method

Same as the first report (`load-probe.mjs`: headless Chrome through Tools' launcher, RTX 5070 Ti, 1920 by 1080, below-normal, a fresh profile so load 1 is a cold first visit, later loads are reloads in the same browser), with three loads and, after each, a listing of the browser's IndexedDB read from inside the page. The stack is built by `tools/preview/stack-preview.mjs` on main `3a489e73` with a scratch manifest that adds 08 and 09 to `world-gen3-field` (the manifest in the repo has 01 to 07 only), 11 parks applied, switches `gen2 ... tiles, swing` on, and the scratch copy of the tree carries `hook-loadmarks.mjs` (marks and per-step totals; nothing else changes). Two parks of the manifest were not in this build (`simulation-right-word` and `animation-pieces23`: "missing"). Machine 73 to 91% busy from other sessions throughout.

## The proof: the cache is written, kept in IndexedDB, and read

- **Written and persisted.** After load 1 the page's own `/userfs` IndexedDB (store `FILE_DATA`, Godot's `user://`) holds `godot/app_userdata/Orb Combat EX/field-cache/` with three files: `26d6fa38....wfc` 90,390 bytes, `52eb69b4....wfc` 149,681 bytes, `65a322ec....wfc` 208,157 bytes. Listed from inside the page by `indexedDB.databases()` and a read of each entry. **Godot's web file system does flush to IndexedDB on its own in time: the files were there when the page was reloaded, so the browser, not the page's memory, held them.** (A reload destroys the page's memory file system, so what a warm load reads can only have come from IndexedDB.)
- **Read.** In the warm loads the sim's planet load drops its phases: `places` 169 slices (1.26 s) and `climate` 79 slices (0.69 s) are **gone**, `ring` falls from 318 slices (4.51 s) to **75 slices (0.94 s)**, and the listing of the three files is byte-for-byte unchanged after loads 2 and 3 (nothing rewritten). Same results on both warm loads.
- **Not tested here:** closing and reopening the browser (the profile's IndexedDB is Chrome's own on-disk store, so it should keep; not run: the launcher deletes the profile on close), Opera itself, a private window (the storage is thrown away at its end, so a private window is always cold), quota and eviction under storage pressure, and a rebuild that changes `CODE_REV` or a shader's source (the cache key should miss once; not run).

## The table (seconds from the page's start)

| Phase | Cold | Warm (load 2) | Warm (load 3) | Before the caches and template (`page-load-2026-10-31.md`) |
|---|---|---|---|---|
| Engine up (first autoload) | 6.0 | 0.3 | 0.8 | 3.1 cold / 0.8 warm |
| Scripts to `main._ready` | 3.1 | 2.6 | 2.4 | 3.5 / 3.4 |
| Sim planet load (the loading line) | 10.7 | 3.5 | 3.5 | 11.3 / 11.3 |
| Pane build (tile build 1.7 to 1.8 s of it) | 2.5 | 3.0 | 2.6 | 2.5 / 2.1 |
| Shader warm-up (46 programs) | 6.8 | 0.5 | 0.5 | 28.8 / 2.3 (178 programs) |
| **To the card** | **29.6** | **10.1** | **9.9** | **49.9 / 20.3** |

Against the target: **warm is at it (9.9 to 10.1 s, on a machine 75% busy; the CPU shows the renderer's main thread running flat out through the load, 1.7 to 2.0 CPU-s per 2 s, so this is the page's own cost, not starvation); cold is 29.6 s, about 10 s over.**

## What each cut bought, and what is left

- **The custom template:** 178 programs to 46, link wait 29 s to 7.5 s cold (0.1 s warm); the shader phase is 6.8 s cold against 28.8 s. Cold total 49.9 s to 29.6 s.
- **World's caches:** the planet load 11.3 s to 3.5 s warm. Cold is unchanged by design (10.7 s: the full ring, places and climate, and now the cache write).
- **Left, warm (10 s):** the pane build is the largest (3.0 s: `_bs_tiles` 1.6 to 1.7 s over 130 to 140 steps, Rendering's tile build; the rest of the pane build 0.5 s timed and the frames around it), then the planet load's 3.5 s (`ring` 0.94 s, of which **one slice is 0.75 s** with the rest in 74 slices: the hit's copy and hash in World's `field_cache.gd` is not sliced fine enough; `match` 0.33 s; the remainder frame overhead), the script load 2.5 s, the compile 0.5 s.
- **Left, cold (30 s):** engine up **6.0 s** (the first 6 s are mostly the main thread waiting: renderer CPU 0.9 s in them, a 4.3 s long task at 4.4 s with the GPU process busy; it was 3.1 s in the first capture on the same PC, so I read it as the cold GPU start under load and have one sample of it), the planet load **10.7 s**, the compile **6.8 s**, the pane build 2.5 s.

## Owners

1. **Rendering:** the tile build, `_bs_tiles` 1.7 s (and the cold compile's remaining 46 programs, 7.5 s).
2. **World:** the cache hit's one 0.75 s slice (slice the copy and hash), and the cold planet load (10.7 s) if cold is to reach 20 s: with the compile at 6.8 s and the pane build at 2.5 s, cold needs the planet load near 5 s and the engine start back near 3 s.
3. **Tools:** nothing new; the build is the template's. A first visit after any rebuild that changes the cache key (a code revision, a shader source) is cold once.

## Limits

One machine, headless Chrome (not Opera), one cold run, two warm; the machine 73 to 91% busy; a single cold sample of the 6 s engine start; the cache was proved for planet 7 only; the build lacks `simulation-right-word` and `animation-pieces23`.

## Files

`docs/perf/tools/load-probe.mjs` (now `--loads N` and an IndexedDB listing per load), `load-report.mjs`, `scratch-hooks/hook-loadmarks.mjs`. Raw run in my scratch folder, not the repo.
