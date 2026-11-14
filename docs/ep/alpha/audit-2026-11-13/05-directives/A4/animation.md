# A4: Animation

Leads: A-ANIM-03
Supports: A-ANIM-01, A-COMBAT-04, A-COMBAT-06, A-MODES-02

Goal: Every move in the rebuilt move table, every transformation and every weak horde enemy plays its own animation in a match, and a check that runs with the gates says so instead of a table from early October.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4); `docs/ep/alpha/audit-2026-11-13/02-areas/ANIM.md` (F-ANIM-04, F-ANIM-01; line 57 on counting animation per piece in a cell's pool); `docs/animation/launch-pair-coverage.md`; `docs/animation/launch-pair-coverage.json`; `render/anim/tools/coverage.gd`; `render/anim/render_anim.gd`; `data/anim/forms.json`; Combat's table page and Art's form sheets as they arrive (the EP gives the paths); `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- A-ANIM-03 (S, minor): the animation coverage table is of 2026-10-03, was built from Combat's then-parked files, still marks 180 of 228 rows parked, and its check runs in no gate. Evidence: `docs/animation/launch-pair-coverage.md:1-5` (sources are files under `docs/combat/pending/`; "live 26, parked 180"); `docs/animation/launch-pair-coverage.json`; `render/anim/render_anim.gd:28`.
- Supporting rows: A-ANIM-01 (each fighter's own break pose per form; today `data/anim/forms.json:9` names the same three poses for everyone, and its note calls them placeholders "until a fighter has form art"); A-COMBAT-04 (key sets for the cells Combat fills); A-COMBAT-06 (the forms that exist); A-MODES-02 (poses for the weak enemies).

You own: `art/animation/`, `docs/animation/`.
- ask under NEEDS FROM EP for a grant: `render/anim/` (the coverage tool and the rig; no director owns it)
- ask under NEEDS FROM EP for a grant: `data/anim/` (poses and the forms file; no director owns it)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (if the forms file's shape changes to carry a pose per fighter)
- Putting the check into CI is Tools' (`.github/`): ask for it under NEEDS FROM EP.

Acceptance criteria:
1. (A-ANIM-03) The coverage table is regenerated from Combat's files as they are on main, not from parked files; no row is marked "parked" unless the thing it covers is still off main, and the table's page carries the commit it was built from. Checked by `render/anim/tools/coverage.gd --strict` passing with no gap row.
2. (A-ANIM-03) The check runs in a gate: it is part of Animation's gate run and of CI, with a verdict line. Checked by a CI run on the commit.
3. (A-ANIM-03, X-03) The live half: in a match driven by the pad coverage probe, no cell of either fighter plays a placeholder pose or a walked pick. Animation is counted per piece in a cell's pool, not per cell. The probe's animation column (read from the picks the rig already records in `render/anim/anim_fighter.gd`) is saved. The regenerated table alone is not the proof.
4. (support, A-COMBAT-04) Each new piece Combat adds has that fighter's own key set, including the four tail strikes the audit found without one.
5. (support, A-ANIM-01) Each fighter has their own break pose for each form beyond base, named in data by fighter and form; the gather, break and settle timing stays inside the sim's pause lengths.
6. (support, A-MODES-02) The weak enemies have a small pose set of their own that reads at speed and passes the joint-limits scan.
7. Look gate (ADR 0010): every new or changed animation ships with a side-by-side against the reference build in `docs/ep/taste.md` (`node tools/flash/side-by-side.mjs`) before it is committed; a clip Orb judges for a move shows the button and whether it is a tap, a mash or a hold.
8. Evidence: the coverage run, the probe's animation column and the side-by-sides are saved under `docs/animation/runs/<sha>/`.

Constraints:
- Tokens: about 0.25M as an estimate for the lead row (S). The supporting poses are counted under their lead rows and will be the larger part of the work: say so in the report if they outgrow this brief.
- The lead row does not change the sim's state hash. Animation reads sim state and never writes it; if a pose's timing would need a sim number changed, stop and ask.
- Machine: no Godot windows; Godot headless only, at most 3 processes for a short gate; clips and stills only through Tools' launcher, one capture at a time.
- Determinism: animation follows the tick, not a clock of its own; numbers in data, schema updated in the same commit as a shape change.
- Originality: every pose is our own; no signature pose or gesture of an existing franchise's character. Pose and gesture rules are Orb's creative rulebook, kept by Art and Animation; they never block a gate.
- Orb's rules: rich, dynamic animation (not "lean"); nothing drawn on, over or between the fighters; no dissolves or fades between poses; the silhouette changes on one snap frame in a transformation; in-progress character art is never public.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: the pad coverage probe (A-CONTROLS-06, A1). The table can be regenerated at once and again when Combat's cells land. The supporting poses wait on Combat's table page (A-COMBAT-04), Game Design's forms page (A-COMBAT-06), Art's form sheets (A-ANIM-01) and the horde page (A-MODES-02). Waiting on this: X-03's and X-04's must-pass readings.
