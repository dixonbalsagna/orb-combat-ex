# docs/perf: Performance and Platform

Owner: Performance and Platform (`docs/directors/performance-platform.md`).

| File | What |
| :-- | :-- |
| [budgets.md](budgets.md) | The budget table (frame, sim, draw calls, primitives, particles, terrain, memory, load, planet slice, run mode), the three hardware tiers, the proposed build gate, a template for reading other people's frame-time numbers |
| [audit-2026-10-16.md](audit-2026-10-16.md) | A measured audit of main: frame time in the web build against the tiers, the cost of the parked work, the hot spots, budgets for the planet slice and the run mode |
| [inset-hitches-aura-2026-10-22.md](inset-hitches-aura-2026-10-22.md) | The inset warm-up measured (no effect on the tick-238 hitch), the tick-131 hitch is the driver, the aura's cost on the old-laptop bound, the repro |
| [input-latency-2026-10-22.md](input-latency-2026-10-22.md) | Press to first changed picture for a light, a dash and a guard on the web build (RTX, integrated GPU, CPU x4): the light starts 5 ticks late in the sim; the rest is inside budget |
| [frame-pacing-2026-10-22.md](frame-pacing-2026-10-22.md) | A 2-minute AI match and a 2-player brawl: the distribution, the worst 1%, the swing between frames, repeating spikes (none), and why the integrated GPU has slow stretches (the terrain grows with craters) |
| [batch-e09dbbbf-2026-10-22.md](batch-e09dbbbf-2026-10-22.md) | The hitch repro and the ring read (k32 at x4) re-run on e09dbbbf |
| [ground-by-band-and-heat-2026-10-23.md](ground-by-band-and-heat-2026-10-23.md) | 22f (the ground by band) and 22h (scorch and heat texture) before and after on main: big gain on weak GPUs, neutral to better at CPU x4 |
| [arena-turn-2026-10-23.md](arena-turn-2026-10-23.md) | The arena turn on a Half arena: the swap frame (38-60 ms, 220-280 at x4), what it is made of (59% node churn), a split, the warm phase, and the first crater at x4 (no web-only sim cost) |
| [batch-1b66c4bb-2026-10-23.md](batch-1b66c4bb-2026-10-23.md) | Item 3 on Encounter's four parks (off): no change in the steady frame cost; one x4 pair that read slower was noise |
| [render-chain-22k-22o-2026-10-23.md](render-chain-22k-22o-2026-10-23.md) | Rendering's chain on the Radeon and RTX: 22l works, 22n triples the Radeon's frame time, 22o is free in frame time; UI's warm-marks is neutral |
| [gen2-bench-2026-10-26.md](gen2-bench-2026-10-26.md) | World's gen 2 readiness benches in the web build (RTX/Radeon x1, x4, x6): planet make 1.7 s (9.5 s old laptop, 16 s phone), match start, calm-turn warm tick, water step, flow field, memory; verdicts |
| [desktop-boot-2026-10-27.md](desktop-boot-2026-10-27.md) | The Windows export of d7647634 (117.6 MB, built), the web side of the desktop comparison (RTX and Radeon bench, x1 and x4), platform notes for Steam (Windows gaps, what a Linux/Deck export needs, native-web parity); the native cold, warm and bench launches on the RTX (about 15 s to playable cold, 5 s warm; hash equals the web) |
| [web-template-2026-10-28.md](web-template-2026-10-28.md) | Tools' custom web template (lazy shader specialization) against the standard one on main 9631fc75: sim parity (51 keys), link wait (156 to 43 programs, 15 to 4.5 s), boot (about 12 s shorter at x1), frame bench (unchanged within noise), look (mash identical, collapse inside its own noise) |
| [web-template-readings-2026-10-28.md](web-template-readings-2026-10-28.md) | The custom engine's four release readings on the live pin 257a766c (signature and collapse both modes, a nightly of 8 seeds, 6,000 frames standard against custom: none beyond noise); the parked record patch; `--check` fails only on the signature clip's reduced 3 / 3 / 3, which the standard build of the pin reads too |
| [coast-layer-cut-2026-10-27.md](coast-layer-cut-2026-10-27.md) | The gen 2 coast on the Radeon, layer by layer: the terrain is 47 to 53% of the frame (fragment-bound; the water costs 0.8 to 1.4 ms), the p95 tail is the wide shots, and at x4 no layer is in it (the CPU frame is) |
| [boot-start-block-2026-10-27.md](boot-start-block-2026-10-27.md) | What is in the start block on 3d276d57 (x1 4.4 s, x4 15.5 s: the script load is 70%, SimHost's graph 6.4 s at x4), the full boot to playable (22.6 s / 40.7 s), the breadcrumbs stages (card is held through the compile) |
| [audio-warm-async-3-2026-10-27.md](audio-warm-async-3-2026-10-27.md) | Audio's warm-async 3 (common hits first, variant by variant, 120 ms boot slice) on 19e56ab3, x4/x6: skipped 0 at x4 and 6 to 7 at x6 (was about 10 and 30), none of the common light hits; the x4 warm-up 12 s shorter, the x6 warm-up not shorter (108 to 110 s) until the host.paused line lands |
| [audio-warm-async-2-2026-10-26.md](audio-warm-async-2-2026-10-26.md) | Audio's re-cut warm-up (adaptive budget, queue-jumping, named skips) against HEAD with the first park, x1/x4/x6: skipped 42 to 11 at x4 and 189 to about 30 at x6, but the warm-up still takes 99 s at x6 because the traffic guess never sees quiet; the cues lost, by name; the host.paused line is the next lever |
| [audio-warm-async-2026-10-26.md](audio-warm-async-2026-10-26.md) | Audio's warm-async park on the phone-freeze probe (x1/x4/x6): the block loses the bank's warm-up (14.2 s at x6, 60.8 to 46.6 s), the warm-up spreads over 350/1,370/2,150 frames, 1/31/176 cues dropped; budget suggestion for the first-run card |
| [phone-freeze-2026-10-26.md](phone-freeze-2026-10-26.md) | Why the live demo may freeze on a phone: the boot is one 22 s block (56 s at 6x CPU); the audio bank warm-up and the first frame are the bulk; context-loss alert; the local-only freeze breadcrumbs park (ocx-crumbs.js) |
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
| `freeze-probe.mjs`, `crumbs-test.mjs` | The phone-freeze probe (mobile emulation, long tasks, boot marks, taps, `--eval-at`) and the breadcrumbs park's 37-check page test |
| `make-desktop-export.mjs`, `bench-page.mjs` | A headless Windows Desktop export of a commit (with optional native boot marks), and the game's own bench on the web build with the choice of GPU |
| `phone-emu-check.mjs`, `web-head.mjs`, `make-placeholder-icons.mjs` | The phone work: emulation checks, the head block of the web export's page, placeholder Home Screen icons |

Every browser here is started through `tools/machine/browser.mjs` (below-normal priority, a core mask, a time limit, a session-named profile); `phone-emu-check.mjs` now starts its browser through the same launcher.
