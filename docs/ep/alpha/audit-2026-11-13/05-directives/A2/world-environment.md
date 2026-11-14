# A2: World & Environment

Leads: none
Supports: A-RENDER-02, A-RENDER-03, A-QA-11, A-PERF-05

Goal: The picture faults Orb reported on the ground (fighters sinking into it, three humps in a crater, a hump of ocean water) each get a plain answer on whether the ground itself is wrong or only how it is drawn.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2, last exit line), `02-areas/RENDER.md` (F-RENDER-03, F-RENDER-04), `docs/qa/runs/6a30b4c9/README.md`, `docs/tools/runs/1931a0f8/terrain-step0-stills.md`, `qa/known-bugs.md`, `docs/perf/impact-stutter.md`.
- A-RENDER-02 (led by Rendering): fighters clipping into the ground and a row of three humps in a crater have no still, no owner, no cause and no row in the bug list. Evidence: `docs/qa/runs/6a30b4c9/README.md:33`; `docs/ep/vision.md:1690`. Risk named in the register: if the humps are in the sim's ground and not the picture, the fix moves the state hash.
- A-RENDER-03 (led by Rendering): a black diagonal line across the picture has stills but no cause, and the "hump of ocean water" Orb reported was not identified. Evidence: `docs/tools/runs/1931a0f8/terrain-step0-stills.md:13`, `:7-8`; `docs/ep/vision.md:1677`.
- A-QA-11 (led by QA): bug GB-005 is open with World. Evidence: `qa/known-bugs.md:25` (World names the commit; QA's `5c.bounces` and `5c.long` rows read it).
- A-PERF-05 (led by Rendering): the frame spikes after a blow; the building sweep and the launch tick's loops are part of the record. Evidence: `docs/perf/impact-stutter.md:81`, `:97`.

You own: `sim/world/`, `data/biomes/`, `docs/world/`.
- ask under NEEDS FROM EP for a grant: none expected; this brief is reads and a page.

Acceptance criteria:
1. (supports A-RENDER-02) From the replay of Orb's saved play file that Tools provides through the EP, read the sim's own ground heights at the crater in question and at the spot where a fighter sank, and say for each, with the numbers: the sim's ground is as designed and the fault is in the drawing, or the sim's ground is wrong. Record: `docs/world/runs/<sha>/`.
2. (supports A-RENDER-03) The same for the water hump: is there water in the sim where Orb saw it, and should there be. If it cannot be found, a written "cannot reproduce" naming the replay used.
3. If a fault is in the sim's ground, do not fix it in this milestone: report its cause, its size class and that it changes the state hash, so the EP can place it in GW2 (A3's window, "The fight's rules").
4. (supports A-QA-11) GB-005: name the commit that answered it, or say it is open and what it needs.
5. (supports A-PERF-05) One line to the EP on whether any slow loop named in `docs/perf/impact-stutter.md` sits in `sim/world/`, with the file line; no change is made here.

Constraints:
- Tokens: not counted in the path's totals (supporting work); about one S (0.25M) as an estimate.
- State hash: no change, and A2 has no golden window (a landing that re-records the reference matches). Reads only.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; long runs at below-normal priority; no browser captures of your own.
- Determinism: the read uses the replay's seed and ticks so anyone can repeat it; seeded RNG and fixed step untouched.
- Originality: nothing to add.
- Orb's rules: plain words in the answer (say what the ground is at that spot and what the player saw); the terrain workshop of 2026-11-09 is proposed for after Alpha and is not opened by this brief.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: waits on Tools replaying Orb's saved play files and on Rendering's stills. Rendering's cause-and-owner page (the last A2 exit line) waits on criteria 1 and 2.
