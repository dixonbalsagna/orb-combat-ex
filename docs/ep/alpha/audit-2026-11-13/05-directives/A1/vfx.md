# A1: VFX Director

Leads: none
Supports: A-RENDER-01, A-RENDER-04, A-CONTROLS-04, A-RENDER-07

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: A build made plainly from main shows the meteor trail and the craters Orb saw on 9 November with no special start words, and the trail still starts at the right moment at the flight speed Orb likes.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1; decisions 3, 4 and 5); `docs/ep/alpha/audit-2026-11-13/02-areas/RENDER.md` and `CONTROLS.md`; `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- A-RENDER-01 (Rendering leads): the look Orb plays (globe ground, crater look, meteor trail) is switched on only by launch words. Evidence: `render/core/main.gd:243-251`, `:259`; `render/vfx/vfx_look.gd:177`; `docs/tools/runs/6a30b4c9/switch-list.txt:32-36`.
- A-RENDER-04 (Rendering leads): the black, flat-brown crater has a proven cause and a parked fix (finished work waiting outside main) that raises the collapse flash reading from 3 to 4. Evidence: `docs/rendering/runs/1931a0f8/terrain-step0-a.txt:26`; `docs/rendering/pending/crater-look-default/README.md:3`, `:41`.
- A-CONTROLS-04 (Game Design leads): 3500 becomes the default flight speed; the trail starts at speed 3500 and the glow at 4500. Evidence: `data/vfx/meteor.json:6`; `data/fight/power.json:107-108`; `docs/ep/vision.md:1688`.
- A-RENDER-07 (EP leads): no record ties a visible landing to its side-by-side. Evidence: `docs/decisions/0010-look-gate.md:8`.
- Started early for A2, in a separate brief sent the same day: your part of the flashing measurements on the globe ground and of the parked camera safeguards (A-LEGAL-01, A-CAMERA-02).

You own: `render/vfx/`, `art/vfx/`, `docs/vfx/`.
- ask under NEEDS FROM EP for a grant: `data/vfx/meteor.json` (only if the trail's start speed must move with the flight-speed default)

Acceptance criteria:
1. (A-RENDER-01, A-RENDER-04) The defaults in `render/vfx/` that the crater look and the meteor trail read are the played build's, so no launch word is needed. You make the change in your own files or grant Rendering the named line (`render/vfx/vfx_look.gd:177`), within a day of the ask.
2. (A-CONTROLS-04) At a default flight speed of 3500 (the bottom of the range and the trail's start speed), a note says whether the trail and the glow still come on when they should in a normal match, with a still from flat-out flight at the base level and at the top level. If a number in `data/vfx/meteor.json` must move, it moves in the same window as the speed.
3. (Look gate, ADR 0010) Any change of yours that alters the picture ships with a side-by-side against the reference build (`node tools/flash/side-by-side.mjs`; stills plus a short GIF) before the EP commits, and your report names the picture's file (A-RENDER-07). Nothing is meant to look different from the 9 November build.
4. The effects checks under `render/vfx/tools/` pass on the new defaults. Results saved under `docs/vfx/runs/<sha>/` (corrective item CD-22); pictures go in `docs/vfx/`, never in Orb's folders.

Constraints:
- Tokens: no rows of your own in A1; allow about 0.25M as an estimate for the supporting work.
- State hash: nothing here changes the sim's state fingerprint. Effects read sim state and events and never write them.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; long runs at below-normal priority; no browser of your own (captures only through Tools' launcher, one at a time, each with a time limit); check nothing you started is still running before you end a turn.
- Engine: the Compatibility renderer is the baseline.
- Determinism and data: effect numbers live in data; a data shape change updates its schema in the same commit.
- Originality: every effect is our own; nothing from an existing franchise.
- Orb's rules: nothing drawn on, over or between the fighters; no dissolves, fades or full-screen blur; crisp beams, not soft blocks; no effect that drops the frame rate; plain words. The default look is not degraded to move a flashing number (ADR 0010, point 3), and nothing about flashing readings goes to Orb from you: it goes to the EP.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Item 1 goes with Rendering's landing of the look, after the round planet (A-WORLD-01) and the camera (A-CAMERA-01) in step 4 of A1's order. Item 2 waits on Orb's decision 5 and lands in golden window GW1 with the flight speed. Waiting on this: A-CODE-01 (no switch row differs between main and the played build) and the first desktop build's still comparison (A-TOOLS-01).

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- Read the code for the marks drawn on and round the fighters (A-RENDER-13) now, list each with its file and line, and hand the EP one clip per mark for Orb's A1 page. The row still closes in A3. (ORB-07)
