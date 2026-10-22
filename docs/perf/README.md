# docs/perf: Performance and Platform

Owner: Performance and Platform (`docs/directors/performance-platform.md`).

| File | What |
| :-- | :-- |
| [budgets.md](budgets.md) | The budget table (frame, sim, draw calls, primitives, particles, terrain, memory, load, planet slice, run mode), the three hardware tiers, the proposed build gate, a template for reading other people's frame-time numbers |
| [audit-2026-10-16.md](audit-2026-10-16.md) | A measured audit of main: frame time in the web build against the tiers, the cost of the parked work, the hot spots, budgets for the planet slice and the run mode |
| [inset-hitches-aura-2026-10-22.md](inset-hitches-aura-2026-10-22.md) | The inset warm-up measured (no effect on the tick-238 hitch), the tick-131 hitch is the driver, the aura's cost on the old-laptop bound, the repro |
| [stores-and-consoles.md](stores-and-consoles.md) | Where the game can be listed, consoles included, with requirements, cost, order, and what PlayStation friends can do today |
| [phone-web-fullscreen.md](phone-web-fullscreen.md) | Full screen, Home Screen install and landscape on phones in the web build; a checklist for a real phone |
| `web-shell/` | The web page's phone block (`ocx-shell.js`, the manifest, placeholder icons, the site-builder patch) |
| `img/` | Screenshots the notes cite |

## Tools (`tools/`)

| Script | Use |
| :-- | :-- |
| `make-audit-sites.mjs` | Builds the scratch web exports the audit measures, from a clean `git archive` of HEAD, with the measuring hooks and the parked patches applied; opens no window |
| `frame-bench.mjs` | One run: a staged scene (or the slice read, or layer cuts) in a guarded browser, frame times, CPU time per frame, memory, load, validity |
| `audit-run.mjs` | The matrix of runs, one browser at a time, waiting for a quiet machine; `audit-summary.mjs` turns a folder of runs into the tables |
| `native-cpu-bench.ps1` | Headless native Godot's CPU-side cost (sim tick, FX and camera, view update); no GPU |
| `scratch-hooks/` | The measuring code the site builder adds to a scratch export (never to the repo) |
| `phone-emu-check.mjs`, `web-head.mjs`, `make-placeholder-icons.mjs` | The phone work: emulation checks, the head block of the web export's page, placeholder Home Screen icons |

Every browser here is started through `tools/machine/browser.mjs` (below-normal priority, a core mask, a time limit, a session-named profile); `phone-emu-check.mjs` now starts its browser through the same launcher.
