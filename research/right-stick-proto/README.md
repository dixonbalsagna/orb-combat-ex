# Right-stick prototype tools

Research & Prototyping, 2026-10-23. The prototype `docs/ep/prototypes/right-stick-v1.html` is step 1 of Game Design's pitch C, the family stick. The command set is from `docs/design/right-stick-pitches.md` §11, with §12's rulings, and the reads use Controls' fixed thresholds (`docs/controls/right-stick.md` §11). Its clips are for Orb's homework (`homework/49-right-stick/`).

| File | What |
| :--- | :--- |
| `work/sim.js` | The recognizer, the sim and the drawing, with no DOM, between the "STICK SIM" and "PAGE" markers |
| `work/page.html` | The page: buttons, the gamepad (standard mapping) and keyboard, the step list and sound. Its `/*SIM*/` slot takes `sim.js` |
| `build.mjs` | Writes the single-file prototype from the two |
| `gif.mjs` | Runs the sim in node with a scanline rasteriser, the bitmap font and a GIF encoder (copied from `research/energy-proto/gif.mjs`). Makes the six clips, the stills, a sheet per clip and the homework README. `--check` prints what the recognizer read; `--frames` saves chosen ticks |

**The recognizer** (`readStick`) takes one sample a tick and runs these stages in order:

1. **Dead zone:** 0.25 radial, rescaled and quantised to 1/16.
2. **Hysteresis:** the stick counts as out at 0.60 and back in at 0.35.
3. **Flick:**
   - It is a flick when the stick goes from rest (0.2) to 0.60 in 3 ticks or fewer.
   - Its direction is read four ways, 2 ticks after the crossing, with a tie going to the vertical.
4. **Hold:**
   - A hold starts after 10 ticks out.
   - Its angle is read 32 ways.
   - Flight reads it four ways, with 8 degrees of hysteresis at the diagonals.
5. **Family:** whatever shoulder is held at the first deflection locks the family until the stick rests.

**Patterns** are only named in the panel, as step 2's:

- **Circle:** a sweep of 300 degrees or more.
- **Half-circle:** 140 to 250 degrees.
- **Zig-zag:** two reversals along one line.
- **Pump:** two flicks the same way within 18 ticks.

**Directions** are relative to the rival.

**Simplified in the prototype:**

- No brawl, so §12's rushes inside a brawl are not modelled.
- Flicks and holds under LB, LT or RT do nothing (step 2 and 3).
- The aim line's hold turns the line toward the stick at 2 degrees a tick.
- A beam turns toward the stick at the fighter's own sweep rate.

```
node research/right-stick-proto/build.mjs
node research/right-stick-proto/gif.mjs --check
node research/right-stick-proto/gif.mjs homework/49-right-stick          # about 10 s
node research/right-stick-proto/gif.mjs --frames R2 150,180,210 out.png
```
