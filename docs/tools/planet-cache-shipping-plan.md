# Shipping cache files for the default planets: noted, not started (Tools, 2026-10-31)

Status: **a note for later. Not started** (the EP, 2026-10-31: after World's gen 3 field lands, and "don't start"). From World's option (a).

## What is asked

Ship **cache files for the default planets 7, 3 and 25**, **built at export**, about **0.5 MB each**, **fetched when the planet is chosen** and **not in the first pack**. It makes a first visit's planet load as warm as a returning visitor's: World's caches (diffs 08 to 11 of `docs/world/pending/gen3-field/`: the bake cache `sim/world/field_cache.gd`, the made planet `planet_cache.gd`, the node pool `field_pool.gd`) are filled on the first load and read after it; on the web they would otherwise live in the browser's own storage, empty on a first visit.

## What it touches (read before starting)

- **The site job** (`tools/site-pin.mjs --export`, `.github/workflows/`): a step after the export that builds the three caches headless from the pinned commit (the cache's own key, `CODE_REV` and the checksums World's README names), writes them under the site's `play/` folder (not into `index.pck`, so the first pack does not grow), and adds them to `tools/check-site-offline.mjs`'s list of what a built site holds.
- **The page**: a fetch of `play/cache/<planet>.bin` when a planet is chosen (Rendering's or World's side of the loader, not Tools'); the site's service worker and its cache list, if there is one, must know the files (`docs/perf/web-shell/`).
- **The key and the pin**: a cache is valid only for the data and code that built it (World's whole key and `CODE_REV`). The files are therefore built from the **pinned commit** in the site job, never reused across pins, and a wrong or stale file must be refused by the cache's own checks (it has a checksum and witnesses), so a mismatch falls back to a normal load and never to a wrong world.
- **Determinism and the look**: a cache hit must produce exactly what a cold load does (`field_load_check` holds that for a warm load); the nightly and the flash set stay on cold loads unless Legal and Simulation say otherwise.
- **Size and the budget**: three files at about 0.5 MB are 1.5 MB of site, fetched on demand; the budgets page (`docs/perf/budgets.md`) and the offline check's size limit decide whether that fits.

## Not decided

How the loader names and finds the files; whether the caches are built by a Godot run in the site job (minutes of CI) or by a small tool; whether a planet other than 7, 3 and 25 (a campaign planet) is fetched the same way or built on the player's machine; the service worker. All of that waits for World's gen 3 field to land and for a brief.
