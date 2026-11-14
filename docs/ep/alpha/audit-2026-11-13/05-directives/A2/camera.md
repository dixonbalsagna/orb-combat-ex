# A2: Camera & Cinematography

Leads: A-CAMERA-02, A-CAMERA-03, A-LEGAL-01
Supports: A-MARKET-01, A-QA-11, A-RENDER-03

Goal: On the globe ground that every played build uses, a tester sees a fight whose flashing reads inside Legal's limits in both the normal and the reduced mode, and the picture frames correctly on a Steam Deck's 1280 by 800 screen.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2), `02-areas/LEGAL.md` (gates G4 and G5), `02-areas/CAMERA.md` (F-CAMERA-03, F-CAMERA-04), `docs/camera/pending/cd04/README.md`, `docs/decisions/0010-look-gate.md`, `docs/ep/taste.md`, `docs/ui/split-unequal-fit.md`.
- A-LEGAL-01 (blocker): on the globe (tile) ground the last pixel flash reading failed in both modes (clash 5.5 and 6.5 a second against a limit of 3), the standard clips never run with that ground, and no pixel reading exists for the played commit 6a30b4c9. Evidence: `docs/rendering/runs/d985eb15/crater-look-default.txt:24`, `:25`; `docs/ep/corrective-plan-2026-11-07.md:12`; `render/camera/camera_params.gd:150`; `tools/flash/release-pass.json:3`.
- A-CAMERA-02: two camera flash safeguards are parked (finished work waiting outside main) and not on main: the scroll limit in reduced mode equals the ordinary one (0.045), and most camera cuts do not ask the flash register. Evidence: `render/camera/camera_params.gd:149-150`; `render/vfx/flash_registry.gd:290`; `docs/camera/pending/cd04/README.md:1-12`; record `docs/camera/runs/d41ce393/cd-04/`. Verified detail: the transformation's break cut already asks (`render/camera/split_rig.gd:2292`) and the optional cut dip asks (`render/camera/split_view.gd:144`); every other cut (`split_rig.gd:5039`) asks nothing.
- A-CAMERA-03: no camera test or saved record runs at 1280 by 800, and UI's paper says a plate crosses the 30% pane by 70 px at that size when the dividing line leans most. Evidence: `render/camera/tests/chase_rush_check.gd:75`; `render/camera/tests/split_sweep.gd:33` (it does take `--size=WxH`, `:150-153`); `docs/ui/split-unequal-fit.md:13`.

You own: `render/camera/`, `docs/camera/`.
- ask under NEEDS FROM EP for a grant: `render/vfx/` (only if a cut needs a new call on the flash register; otherwise VFX makes it through the EP)
- ask under NEEDS FROM EP for a grant: `render/core/` (only if a reading shows the cause is in the ground's drawing; otherwise Rendering takes that part through the EP)
- Tools owns the measuring chain and the clip runner (`tools/flash/`); you run them, you do not change them.

Acceptance criteria:
1. (A-CAMERA-02) The cd04 park is finished and landed: the cut-step table exists, every cut that changes most of the screen asks the flash register, and the reduced-mode scroll limit is 0.03 or a higher value justified by a saved reading. Check: the park's new test `render/camera/tests/cut_register_check.gd` (it arrives with the patch; it is not on main today) passing, and the reduced-mode reading the park's own "done when" asks for. Record: `docs/camera/runs/<sha>/`.
2. (A-LEGAL-01) The standard clips are read with the globe ground on, in normal and reduced modes, on main after A1's landings, using Tools' repaired chain. The first full reading is saved whatever it says.
3. (A-LEGAL-01) Each clip that reads over Legal's limits (the limits of review row RL-203, `docs/legal/review-log.md:232`) has a named cause (camera, VFX or the ground's drawing) and a fix by its owner, routed through the EP. The reduced mode is brought inside the limits by what the reduced mode switches off or slows; the default look is not made worse to pass a count (ADR 0010, point 3).
4. (A-LEGAL-01) A final reading on the A2 commit, both modes, globe ground, inside the limits, written to `tools/flash/release-pass.json` for that commit by Tools and saved under `docs/camera/runs/<sha>/`. This is gate G4 on Legal's list; the build is not handed to a tester while it is red.
5. (A-CAMERA-03) The split sweep and the chase, launch-shot and split-share checks run at 1280 by 800, with results saved under `docs/camera/runs/<sha>/`; the 70 px plate crossing is either gone or reported to the EP for UI with a still.
6. Every change to a cut, a scroll speed or framing ships with a side-by-side against the reference build recorded in `docs/ep/taste.md` (the look gate, ADR 0010; `node tools/flash/side-by-side.mjs`, stills plus a short GIF), in both modes, before it is committed. If the picture looks worse, it goes back whatever the reading says.
7. (supports) A-MARKET-01: give the EP the camera notes for the two new shots (a transformation, a lap of the globe). A-QA-11: name the commit that answered bug GB-003, or say it is still open. A-RENDER-03: say whether the black diagonal line in `docs/tools/runs/1931a0f8/terrain-step0-stills.md` is the split divider.

Constraints:
- Tokens: about 4.5M as an estimate (one L row and two S rows at the size classes). A-LEGAL-01's class has no comparable finished work behind it.
- State hash: no change. A2 has no golden window; the camera reads sim state and never writes it.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; a clip set that runs over about ten minutes goes at below-normal priority; browser captures only through Tools' launcher, one at a time, and a reading taken while the machine was saturated is void.
- Determinism: seeded RNG and fixed step are untouched; no rendering state in the sim; camera numbers live in data, and a data shape change updates its schema in the same commit.
- Originality: no shot copied from an existing game or show.
- Orb's rules: nothing drawn on, over or between the fighters; no dissolves, fades, slow wipes or full-screen blur, including as a way to pass a reading; ease camera moves; plain words. This topic is kept off Orb's page: a look question that comes out of it goes to the EP as clips, never as measurements.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: starts in A1 (briefed on day one). Before criterion 2: Tools' repair of the measuring chain (A-LEGAL-08) and A1's globe-ground and crater-look defaults (A-RENDER-01, A-RENDER-04) on main. Before criterion 5: A-UI-09 (A1). Waiting on this brief: Legal's gate list going green (A-LEGAL-03), Orb's one-line approval, and so the two friends' Steam Deck session (A-PERF-01). If G4 is still red at the end of A2, the Deck session waits.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- A change to the ordinary look of a cut or of the clash goes to Orb, through the EP, as two clips and one look question with no numbers (ADR 0010, point 3). This row is now sized XL, shared with Rendering and VFX. (ORB-02, COS-07)
