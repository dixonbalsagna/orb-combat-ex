# Plan: the flash readings on the tile ground (A-LEGAL-01, A-CAMERA-02), Camera's part

Camera, 2026-11-14, sprint A1 wave 2. **This is a plan; it holds no readings.** Readings go to the EP only, never to Orb.

The work is shared with Rendering and VFX, and done in a quiet window the EP names. Captures go through Tools' launcher only (`tools/machine/capture.mjs`), one at a time, each with a time limit, at below-normal priority, under the session name `camera-whip`.

## What the last reading said

- **Where:** `docs/rendering/runs/d985eb15/crater-look-default.txt`, on main and with Rendering's crater-look park, `tiles=1`.
- **Clash:** fails in both modes (5.5 normal, 6.5 reduced).
- **Collapse:** reads 3 to 4.
- **Missing:** no pixel reading exists for the played commit 6a30b4c9, and the standard clips have never run on the tile ground.

## Before the first capture (the chain, in order)

1. **Tools' measuring-chain repair (A-LEGAL-08, CD-09)** is in: the counter-phase tie is fixed in `tools/flash/wcag.js`, and the self-test case passes. A reading on the old analyser is void.
2. **The candidate stack is the camera a tester gets.** Main, plus:
   - A-CAMERA-01 (`docs/camera/pending/a-camera-01`: the eight pieces and the 0.7 share at a plain start);
   - A-CAMERA-02 (`docs/camera/pending/cd04`: SCROLL_MAX_REDUCED 0.03, every hard cut through the register's `ask_cut`);
   - VFX's shared register (`docs/vfx/pending/shared-register`: `ask_cut`);
   - Rendering's look (A-RENDER-01 and A-RENDER-04: the tile ground at a plain start).

   Until those land, it's a scratch stack of the parks, named in the run file. A reading of a stack that isn't the candidate says so in its first line.
3. **cd04's cut-step table, measured first.** Each hard cut's luminance step and area is read on recorded cuts (scratch tools written: a hook that lists the cuts, a two-pass capture, a step reader), and fills `CamParams.CUT_STEP`. A cut that barely changes the screen then costs less than a whole flash.

## The captures (one at a time, in the EP's quiet window)

| Order | Clip | Modes | Why |
| :---: | :--- | :--- | :--- |
| 1 | clash, `tiles=1` | normal, reduced | The failing scene: what the camera half (cd04) changes, on its own |
| 2 | collapse, `tiles=1` | normal, reduced | Over the gate last time |
| 3 | the full standard set (`tools/flash/` scenarios), `tiles=1` | normal, reduced | The release rule's set, on the ground players see |
| 4 | a real match replayed from Orb's save (`tools/preview/blackbox-clip.mjs`) on the played build's data, once main reproduces it (A-CODE-01) | normal, reduced | The reading on what a tester actually plays |

**Each clip** has the hook's cut log beside it (each cut's tick, reason, and whether the register granted, eased or held it), and the analyser's event list. Every counted flash is then put to its source:
- a camera cut;
- the camera's scroll (the governor's 0.03 under reduced);
- a VFX flash;
- the tile ground's own tones.

So a failure goes to its owner. The fixes these readings may lead to may not be a fade, a dissolve or a slow wipe (COS-07, Orb's rule).

## What Camera fixes, if the reading points at the camera

- **A cut that still counts** (an eased form that isn't eased): the cut's eased form in `_cut_gate`'s table.
- **A scroll that counts:** the governor's floor.
- Nothing new in A1 beyond the parked safeguards. Anything larger goes to the EP as a finding.

## Output

`docs/camera/runs/<sha>/flash/`: each clip's analyser table, its cut log and the attribution, plus the stack it was read on. A short note goes to the EP. Nothing goes to Orb.
