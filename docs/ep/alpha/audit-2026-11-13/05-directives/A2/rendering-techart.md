# A2: Rendering & Technical Art

Leads: A-PERF-05, A-RENDER-02, A-RENDER-03, A-RENDER-08, A-UI-03
Supports: A-LEGAL-01, A-CONTROLS-03, A-PERF-01, A-QA-11

Goal: A tester's build has no developer keys that bring back old pictures, no stutter the first time an effect is drawn, a measured answer on the frame spikes Orb has felt, and a still, a cause and an owner for each of the three unexplained picture faults.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2), `02-areas/RENDER.md`, `02-areas/PERF.md` (F-PERF-06), `02-areas/UI.md` (F-UI-03), `docs/perf/impact-stutter.md`, `docs/vfx/pending/warm-first-use/README.md`, `docs/qa/runs/6a30b4c9/README.md`, `docs/tools/runs/1931a0f8/terrain-step0-stills.md`, `docs/decisions/0010-look-gate.md`, `docs/ep/taste.md`.
- A-UI-03: developer keys are live in every build with no switch: F8 brings back older flash shapes, F2 swaps in the old grey-box HUD with a health bar and the two backburnered meter bars, and F9, taught as the report key, also toggles the split screen. Evidence: `render/core/main.gd:1588`, `:1593`, `:1524`, `:1582`; `render/core/hud.gd:219-221`. Verified detail: every packaging path sets the Reduce flashing lock, which refuses F8; Alt with a key and F7 stay open.
- A-PERF-05: the frame spikes Orb has felt since 2026-11-01 are still open. Evidence: `docs/ep/vision.md:1621`, `:1654`, `:1662`; `docs/perf/impact-stutter.md:3`, `:81`, `:97`. Verified detail: three fixes, not two, sit on main without a re-measure (the building visit budget, `render/core/planet_view.gd:1058`, is one); the launch loops have sketches only.
- A-RENDER-02: fighters clipping into the ground and a row of three humps in a crater have no still, owner, cause or bug row. Evidence: `docs/qa/runs/6a30b4c9/README.md:33`; `docs/ep/vision.md:1690`; `reads/RR-08.md:73-74`.
- A-RENDER-03: a thick black diagonal line across the picture has stills but no cause or owner, and the "hump of ocean water" itself was not identified. Evidence: `docs/tools/runs/1931a0f8/terrain-step0-stills.md:13`, `:7-8`; `docs/ep/vision.md:1677`. The stills are local and uncommitted.
- A-RENDER-08: the boot warm-up's list does not name the clash, meteor trail or blast-head shaders, and no first-draw record exists for 6a30b4c9. Evidence: `render/core/warmup.gd:18-38`, `:63`; `docs/vfx/pending/warm-first-use/README.md:1-5`. Verified detail: the on-screen boot also compiles every mesh material found in the panes (`render/core/boot.gd:51-58`, `:158-176`), so the true shortfall may be only the full clash air material (`render/vfx/clash_view.gd:101`).

You own: `render/core/`, `render/shaders/`, `docs/rendering/`.
- ask under NEEDS FROM EP for a grant: `render/vfx/` (only if the warm-up needs a material handed over; otherwise VFX does it through the EP)
- ask under NEEDS FROM EP for a grant: `docs/qa/` or have QA add the bug rows to `qa/known-bugs.md` through the EP
- `sim/world/` and `sim/core/` are not yours and no grant is offered in this milestone: if the humps or a slow loop are in the sim, report it and stop.

Acceptance criteria:
1. (A-UI-03) In a tester's package F2, F7, F8 and Alt with a key do nothing, and the report key does one thing only. They may stay in a developer build behind one switch in data that the packer sets off and refuses to build without. Check: a test that presses each key against packed tester data and reads no change; the package check's output saved under `docs/rendering/runs/<sha>/`. No health bar or meter bar can reach the screen in a tester's build by any key.
2. (A-RENDER-08) A first-draw probe on the A2 commit lists every effect's first draw in a real pane and its cost; anything that hitches is added to the warm-up; cold start to menu is re-timed so the longer list is known against X-26. Record: `docs/rendering/runs/<sha>/`. The parked warm-first-use work is landed or retired in writing.
3. (A-PERF-05) Performance's frame record is re-taken on main for the three fixes already there, on a quiet machine, and the page says for each spike Orb named: gone, smaller, or still there with its cause. Launch-tick loops in the sim are reported, not changed here. Record: `docs/perf/runs/<sha>/` (Performance saves it) and a pointer in `docs/rendering/runs/<sha>/`.
4. (A-RENDER-02) For each of the two faults: a replay still from Orb's saved play file, a cause, an owner and a row in the bug list; or a written "cannot reproduce" naming the replay used. The page says plainly whether the humps are in the picture or in the sim's ground.
5. (A-RENDER-03) The same for the black diagonal line and the water hump; the stills are committed with the record.
6. Any fix that changes what a player sees ships with a side-by-side against the reference build recorded in `docs/ep/taste.md` (the look gate, ADR 0010; `node tools/flash/side-by-side.mjs`) before it is committed.
7. (supports) A-LEGAL-01: when Camera's readings name the ground's drawing as a cause, make the fix and its side-by-side in both modes. A-CONTROLS-03: review the pause-on-unplug change to `render/core/main.gd:1495-1499` that Controls proposes. A-PERF-01: stand by for the first Steam Deck session; a shader the Deck's driver rejects comes to you. A-QA-11: answer bug GB-007 with VFX (name the commit, or show it does not reproduce).

Constraints:
- Tokens: about 3.1M as an estimate (two M rows and three S rows at the size classes).
- State hash: no change, and A2 has no golden window. If a cause sits in the sim (the humps, the launch tick), the fix is not made in this milestone: report it with its size and it is placed in GW2 (A3's window, "The fight's rules").
- Machine: headless Godot only; at most 3 Godot processes for a short gate; long runs at below-normal priority; browser captures only through Tools' launcher; a frame record taken on a saturated machine is void, not reported.
- Determinism: rendering reads sim state and never writes it; seeded RNG and fixed step untouched; numbers in data, with the schema updated in the same commit as any shape change.
- Originality: no borrowed shader code without its licence recorded with Legal.
- Orb's rules: nothing drawn on, over or between the fighters; no dissolves, fades or full-screen blur; no health bar on screen; plain words; in-progress character art never public.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: A1's landings first (the globe ground and crater look as defaults, A-RENDER-01 and A-RENDER-04; the desktop build, A-TOOLS-01). Criterion 1 must land before the package goes to a tester: Legal's gate list waits on it. Criteria 4 and 5 need Orb's saved play files replayed by Tools (through the EP). Nothing in A3 waits on this brief except a sim-side cause, if one is found.
