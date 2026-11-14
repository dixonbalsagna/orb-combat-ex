# A2: VFX

Leads: none
Supports: A-LEGAL-01, A-CAMERA-02, A-RENDER-08, A-QA-11

Goal: On the globe ground that every played build uses, the beam clash and the other big effects read inside Legal's flashing limits in both the normal and the reduced mode without the default look getting worse, and no effect hitches the first time it is drawn.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2), `02-areas/LEGAL.md` (gates G4 and G5), `02-areas/RENDER.md` (F-RENDER-14), `docs/camera/pending/cd04/README.md`, `docs/vfx/pending/warm-first-use/README.md`, `docs/decisions/0010-look-gate.md`, `docs/ep/taste.md`.
- A-LEGAL-01 (led by Camera): on the globe ground the last pixel flash reading failed in both modes (clash 5.5 and 6.5 a second against a limit of 3), and the standard clips never run with that ground. Evidence: `docs/rendering/runs/d985eb15/crater-look-default.txt:24`, `:25`; `docs/ep/corrective-plan-2026-11-07.md:12`. The failing clip is the beam clash, whose pictures are yours.
- A-CAMERA-02 (led by Camera): most camera cuts do not ask the flash register. Evidence: `render/vfx/flash_registry.gd:290` (the register has the call); `docs/camera/pending/cd04/README.md:1-12`. Camera's park (finished work waiting outside main) works with or without your parked shared-register work (`docs/vfx/pending/shared-register`).
- A-RENDER-08 (led by Rendering): the boot warm-up's list does not name the clash, meteor trail or blast-head shaders, and your warm-first-use park has waited since 2026-10-22. Evidence: `render/core/warmup.gd:18-38`; `render/vfx/shaders/clash_air.gdshader`; `render/vfx/shaders/meteor.gdshader`; `docs/vfx/pending/warm-first-use/README.md:1-5`.
- A-QA-11 (led by QA): bug GB-007 is open with VFX and Rendering, not reproduced. Evidence: `qa/known-bugs.md:27`.

You own: `render/vfx/`, `art/vfx/`, `docs/vfx/`.
- ask under NEEDS FROM EP for a grant: none expected. `render/core/warmup.gd` is Rendering's and the cut code is Camera's; hand them what they need through the EP.

Acceptance criteria:
1. (supports A-LEGAL-01) For each clip that Camera's first reading on the globe ground shows over the limits with an effect as its cause, a fix in `render/vfx/`: the reduced mode is brought inside the limits by what it switches off, slows or holds steady; the normal mode is brought inside by timing and brightness steps, not by haze, blur, a fade or a steady ring. Check: Tools' repaired chain re-reads the clip in both modes; outputs under `docs/vfx/runs/<sha>/`.
2. (supports A-LEGAL-01) Every such fix ships with a side-by-side against the reference build recorded in `docs/ep/taste.md`, in both modes (the look gate, ADR 0010; `node tools/flash/side-by-side.mjs`, stills plus a short GIF), before it is committed. If it looks worse, it goes back whatever the reading says.
3. (supports A-CAMERA-02) Say in one line whether the shared-register park should land with, before or after Camera's cd04 park, and land or retire it in writing.
4. (supports A-RENDER-08) Hand Rendering the list of every material of yours that is first set after boot (the full clash air material at `render/vfx/clash_view.gd:101` is the known one), and land or retire the warm-first-use park in writing once Rendering's first-draw probe has read the A2 commit.
5. (supports A-QA-11) GB-007: name the commit that fixed it (a shorter fade or world-space pieces, as its row says), or show with a clip recipe that it does not reproduce.

Constraints:
- Tokens: not counted in the path's totals (supporting work); expect about one S (0.25M) to one M (1.2M) as an estimate, depending on how many clips read over the limits.
- State hash: no change. Effects read sim events and never write sim state; A2 has no golden window.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; clip sets over about ten minutes at below-normal priority; browser captures only through Tools' launcher, one at a time; run the collapse clip in both modes before reporting any on-screen change.
- Determinism: effect timing follows sim ticks; numbers live in data, with the schema updated in the same commit as any shape change.
- Originality: no effect shape or energy look copied from an existing game or show.
- Orb's rules: nothing drawn on, over or between the fighters; no dissolves, fades, slow wipes or full-screen blur; nothing that costs frame rate for presentation. This topic is kept off Orb's page: a look question goes to the EP as clips, never as measurements.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: started early in A1 with Camera and Rendering. Criterion 1 waits on Tools' repaired measuring chain (A-LEGAL-08) and Camera's first reading. Waiting on this brief: Camera's final reading (A-LEGAL-01), and so Legal's gate list and the two friends' Steam Deck session.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- A change to the ordinary look of the beam clash "by timing and brightness steps" goes to Orb, through the EP, as two clips and one look question with no numbers; the EP's side-by-side is not the last word on it (ADR 0010, point 3). (ORB-02)
