# Flash nightly on d9bc2f07: the baseline readings (Tools, 2026-11-26)

Runs 45873938790 and 45873942592, dispatched on d9bc2f07 (the fix landing, with GB-010). Software rendering, a window of each clip; not a clearance. The two read the same on every figure.

| clip (window) | primary / red / area-15% / two-second memory | before GB-010 (b784d33c) |
|---|---|---|
| clash-normal (1–240) | 0 / 0 / 0 / 0 | same |
| clash-reduced | 0 / 0 / 0 / 0 | same |
| clash-night-normal | 0 / 0 / 0 / 0 | same |
| clash-night-reduced | 0 / 0 / 0 / 0 | same |
| collapse-normal (1–300) | 2 / 0 / 2 / 1.5 | same |
| **collapse-reduced (1–300)** | **4 / 0 / 4 / 3 — over the take-down line of 3** | **same** |
| signature-normal | 2 / 0 / 2 / 0.5 | same |
| signature-reduced | 1 / 0 / 1 / 0.5 | 1.5 / 0 / 1.5 / 0.5 |
| rushcity-normal | 3 / 0 / 3 / 2.5 — over our gate of 2.5 | same |
| rushcity-reduced | 3 / 0 / 3 / 2 — over our gate of 2.5 | same |

**GB-010 did not cause collapse-reduced's 4.** The same window read locally on b784d33c (hardware, 960x540, the nightly's ground settings) was 1. The difference between the runner's software rendering and a graphics card is not attributed.

To read it the runner's way on a PC (a web export of the commit in a scratch folder first):

    node tools/flash/run-pixels.mjs --dir <site> --path "/index.html?flashcap=1&planet=7&meteor=loud&tiles=1" --out <out> --clip collapse-reduced --ticks 300 --sizes 960x540 --jobs 1 --software

Leave `--software` out for the card's own reading. Expect the software one to take many minutes.
