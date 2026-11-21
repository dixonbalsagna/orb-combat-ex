# Plan: GW1b's one golden re-record (A-CODE-02), with the planet flip last

Simulation, 2026-11-20, sprint A1. The GW1b review (`docs/ep/reviews/GW1b-review.md`, B-02, and its 20-step order) and the GW1a review's S-07 ask for one re-record of the golden at the end of GW1b. They also ask that the golden finally play the world the game starts on: planet 7, touch 3, generation 3, which Orb played. This page is the plan; the recipe change it names lands with the re-record.

## The order

- **Steps 1 to 19** land one by one on the GW1a tree, as the review lists them. **The golden is not re-recorded between them.** Each step is gated against its own expectation:
  - steps 1 to 4 (A-WORLD-01's code, its one line in `beginMatch`, `replay-world`, World's pins) change nothing while the mode is `arena`: **the golden byte for byte**, parity green;
  - steps 5 onward move the golden on purpose (meters-zero, gw1b-energy, the director's riders, the floor rise, and more). For each, parity runs against a golden regenerated on that step's tree, and the step's own lane says what moved and why. That's what my parks already record (meters-zero, gw1b-energy, floor-rise-unpin).
- **Step 20, World's flip (mode only, the draw off):** every match that names no planet moves to planet 7, touch 3, generation 3. Before it:
  - one full gate on a scratch stack with the mode on `planet`;
  - each owner parks pins or re-reads for its red rows. A row that's about the hand-made arena takes `"world": "arena"`.
- **Then the one re-record**, on the finished GW1b tree, by me: `sim/core/test/golden.json` regenerated once, parity green against it, Rendering's 15, and a two-run check (the golden made twice gives one file).

## What the recipes change (lands with the re-record; built and gated before step 20)

- **After the flip, the default recipes play the round planet by themselves.** Each recipe that names no planet starts on planet 7, touch 3, generation 3, through `WorldDefault`. That covers S-07's gap: today no recipe plays generation 3.
- **The hand-made arena stays covered on purpose.** Two of the 9 computer matches and both scripted replays take `"world": "arena"`, so the arena (still a mode, and the strip-ground tools' world) keeps a reference.
- **`PLANET_MATCH` names its generation** (`"planetGen": 3`), so it no longer follows `climate.json`.
- **A new recipe, as `path-round-2.md` asked: planet 7 at generation 3, with a crater and a slide.** It's a seeded computer match whose record shows both. The recipe prints the tick of its first crater and its first slide, so a later change that loses either is seen. I pick the seed with a probe on the GW1b stack.
- **Cold and warm alike.** Since World's fix (b1d9444e, with its `cache_warm_check`), a planet reads the same from a cold field cache as a warm one. The re-record is taken with a cold cache and made again warm, and the two files must be equal (fork_check's finding).

## Who re-reads what

| When | Who | What |
| :--- | :--- | :--- |
| Each of steps 5 to 19 | the step's owner | parity against the step's regenerated golden; the step's lane |
| Before step 20 | every director, through the EP | their checks with the mode on `planet`; pins parked |
| After step 20 | Simulation | the one re-record; parity; two runs, one file; Rendering's 15 |
| After the re-record | QA | the reference lanes on the new golden |

## Open

- The recipe change and its probe are built after gw1b-energy's re-cut gate (one Godot job at a time). The patch lands at step 20 with the re-record, not before.
