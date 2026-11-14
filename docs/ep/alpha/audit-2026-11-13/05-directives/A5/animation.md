# A5: Animation

Leads: none
Supports: A-WORLD-05, A-RENDER-06

Goal: A fighter's feet sit on the ground the player sees, in a fresh crater as much as on flat land, and the fighters still move well at the Steam Deck's picture-quality level.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A5); `docs/ep/proposals/terrain-globe-plan.md` (item 9 at lines 56 to 59, and step 4 of the step table: "feet see new craters", Rendering leads, Animation and QA support); `docs/perf/quality-range.md` line 7 (the effects governor "with animation riding it"); `data/anim/quality.json` and `tools/schemas/anim-quality.schema.json`; `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- A-WORLD-05 (Rendering leads): the ground drawn is not the ground stood on. Evidence: `render/core/look.gd:596` (only the 16 nearest crater bowls are drawn); `docs/ep/proposals/terrain-globe-plan.md:54-58`; `docs/ep/vision.md:1690` and `:1695` (Orb's reports of fighters clipping into the ground).
- A-RENDER-06 (Rendering leads): the quality range has no working levels or Deck default. Evidence: `docs/perf/quality-range.md:7` and `:30`; `render/vfx/vfx_hub.gd:156-158`.

You own: `art/animation/`, `docs/animation/`.
- The animation runtime and its data are on no owner's line (row A-ANIM-06 settles that in A1; use the answer it gave). Until it says otherwise: ask under NEEDS FROM EP for a grant: `render/anim/` (name the files) and ask under NEEDS FROM EP for a grant: `data/anim/quality.json`.

Acceptance criteria:
1. (supports A-WORLD-05) Foot placement reads the same ground height that Rendering now draws, new craters, trenches and scars included, so no foot floats or sinks on a fresh mark. Checked by: Rendering's drawn-versus-stood-on probe within 8 units under the feet over QA's 10 seeds, and the joint-limit check still passing; results saved under `docs/animation/runs/<sha>/` (CD-22).
2. (supports A-RENDER-06) For each of the three levels (low, the Deck's default, the PC's default), `docs/animation/` states what animation gives up, and at the Deck's default the fighters keep every pose a player reads the fight from (wind-up, hit, guard, launch, transformation). Checked by: the animation checks passing at each level, saved; and the EP's look at item 3.
3. (both) Look gate (ADR 0010): a side-by-side against the reference build named in `docs/ep/taste.md` on the day, same scene and ticks, for feet on a fresh crater and for each quality level, seen by the EP before commit. The PC's default level is the reference motion unchanged.
4. (both) Nothing here changes what the sim computes: the same seeded match gives the same state fingerprint at every level. Checked by: the saved fingerprints.

Constraints:
- Tokens: no row of its own; plan on about 0.5M of supporting work, an estimate, counted inside the two rows' classes.
- State hash: no change. Animation reads sim state and never writes it.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; pictures only from the web build through Tools' launcher (`tools/machine/capture.mjs`), one at a time.
- Determinism: numbers live in data; a change to `data/anim/quality.json`'s shape updates its schema in `tools/schemas/` in the same commit.
- Originality: every pose and motion is our own.
- Orb's rules: rich, dynamic animation is the direction, so a lower level drops cost, not character; nothing drawn on, over or between the fighters; no fades between poses standing in for motion.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Item 1 waits on Rendering drawing trenches and scars (its item 5) and on A-WORLD-03 from A3. Item 2 waits on Rendering's level table. QA's ten-seed reading waits on item 1.
