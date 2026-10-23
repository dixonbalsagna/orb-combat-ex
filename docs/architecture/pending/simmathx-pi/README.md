# simmathx-pi: the sim's own pi and tau (parked)

Owner: Simulation and Engine. 2026-10-23, on the EP's brief. Tools' determinism lint (`tools/lint-determinism.mjs`) finds 24 uses of the engine's PI or TAU in Encounter's and World's sim files. They change no result today, since they are the same double everywhere, but they break the rule.

## What it adds

- **`SimMathx.PI`** = `f64("400921fb54442d18")` and **`SimMathx.TAU`** = `f64("401921fb54442d18")`, built from their bits as `epoch.gd` builds its `_PI`.
  - TAU is twice PI, exact.
  - Both are static vars, never assigned.
  - Their two definition lines carry `# det-ok`, since the lint flags any bare `PI`.
- **A parity check, "SimMathx.PI and TAU":**
  - the bits;
  - TAU is exactly 2 × PI;
  - both equal the engine's PI and TAU on this build, so the swaps move nothing.

Nothing reads them until Encounter and World swap their uses, `PI` to `SimMathx.PI` and `TAU` to `SimMathx.TAU`, one word each. **The golden does not move.**

## Apply

On a clean export of 4c3b25d4 or later, from the repo root: `python docs/architecture/pending/simmathx-pi/pi.py .` (it edits `sim/core/mathx.gd` and `sim/core/tools/parity.gd`). It needs no grant.

## Results (scratch, on 4c3b25d4)

- Apply and import were clean.
- Parity on the committed golden: 71 of 71, with "SimMathx.PI and TAU" ok. The golden was byte-identical.
- det passed, and Rendering's 15 checks all passed.
- The lint finds the same 24 uses as main, all in Encounter's and World's files, and none in `mathx.gd`.
