# Energy prototype tools

Research & Prototyping, 2026-10-23. The energy overhaul prototype `docs/ep/prototypes/energy-v1.html` is built to Game Design's frame (`docs/design/energy-overhaul.md`, E1 to E117). Its clips are the frame's section 13, C1 to C10, plus C7b (the four grabs), for Orb's homework (`homework/48-energy/`). Version 3 draws Combat's four kits (`docs/combat/pending/energy/`) in Art's colour lanes (`data/art/energy-lanes.json`, with the keyline), to Legal's look conditions, and follows Game Design's rulings in sections 19 and 20.

| File | What |
| :--- | :--- |
| `work/sim.js` | The sim and its drawing, with no DOM, between the "ENERGY SIM" and "PAGE" markers |
| `work/page.html` | The page: buttons, keys, step list and sound. Its `/*SIM*/` slot takes `sim.js` |
| `build.mjs` | Writes the single-file prototype from the two |
| `gif.mjs` | Runs the sim in node with its own scanline rasteriser and GIF encoder, so no browser is needed. Makes the clips, one still per step with a sheet per clip, and the homework README |
| `frames.mjs` | Saves frames of one clip at chosen ticks, for a close look |

About the sim:
- **Clock and randomness.** It runs at 60 ticks a second and uses no randomness: a hash stands in for every jitter.
- **Drawing.** It draws only flat polygons through `R.poly`. Effects shrink or break into chips, and nothing fades.
- **Clips.** Each clip is a list of takes. Each take is a script of held buttons and stick values for both fighters, and the step texts sit on one clock across the takes. A step may name the tick for its still as a third value; otherwise the still is the middle of the step.

```
node research/energy-proto/build.mjs                      # rebuild the page after editing work/
node research/energy-proto/gif.mjs --check                # play every clip to the end and print what happened
node research/energy-proto/gif.mjs homework/48-energy     # all the clips, the stills and the homework README (about 15 s)
node research/energy-proto/gif.mjs <dir> C6               # one clip
node research/energy-proto/frames.mjs C10 120,200,262 out.png
```

GIFs use the bitmap font in `research/planet-gen/lib/img.mjs`.
