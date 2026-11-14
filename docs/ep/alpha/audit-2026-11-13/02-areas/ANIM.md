# ANIM: animation and characters

Area review of the Alpha audit, baseline 8901d351 (game code of build 6a30b4c9). Read-only. Reviewed at reduced depth: mainly from the inventory slices (I-04, I-08, I-12) and the reading answers RR-01 and RR-02, with the code opened only where a blocker or major might hide. Nothing was run in Godot; counts marked "data count" come from reading the JSON files with a short script.

## Summary

- **Works:** every strike piece Combat's data names resolves to that fighter's own key set (the chamber, contact and follow poses of one blow), 79 of 79 for the Protagonist and 80 of 84 for the rival; joint limits are enforced at run time by a last pass; the creative rulebook exists and is in force as a document.
- **Does not:** a transformation changes only the aura: both fighters play the same three placeholder poses for every form, and no body look is keyed to a form; in a 2v2 the two copies of each fighter are drawn identically.
- **Biggest gap:** transformation looks per form (F-ANIM-01), which is what exit criterion X-04 means by "the change is visible".
- The area's big check (`anim_check`, which holds the joint gate) is not in CI and has no saved record on the landed tree of 6a30b4c9.
- Reduced depth: the 5,912-line pose solver was read by grep only; what a cell looks like on screen is not evidenced.

## Questions and answers

**Q1. What "full moveset" means in animation terms: how many of the move table's cells have their own animation, how many share one, how many are stand-ins?**

The table (RR-01, `reads/RR-01.md:219-224`): 101 cells a fighter (60 face-button, 35 right-stick, 6 pairs); 83 have an entry in data, 65 of those share their id with another cell of the same fighter, 18 have none. So in animation terms the unit is not the cell but the **piece** (one named blow) inside the pool a cell draws from.

- **Own animation.** Data count at the baseline: Combat's pools in `data/combat/recipes.json` and `data/combat/stick.json` name 79 pieces for the Protagonist and 84 for the rival. Looked up the way the game does it (`render/anim/anim_data.gd:503-541`: by the piece's name in the manifests of the fighter's own waves, listed in `data/anim/fighters.json`), all 79 of the Protagonist's resolve to his own key sets (waves protag1, 6, 7, 10, 11, 12, 13) and 80 of the rival's 84 resolve to his (wave1, rival2, 4, 7, 8, 9, 10).
- **Shared between the fighters.** 39 piece names appear in both fighters' pools; none of them resolves to the same key set (data count: 0 of 39). The two fighters share no strike animation by id.
- **Shared between cells.** 65 of 83 cells a fighter reach the same pool as another cell (LB, LT and RT rows fall through to the plain rows: `reads/RR-01.md:227-228`). Those cells have no animation of their own because they have no move of their own; that is Combat's finding (F-COMBAT-04), not an animation hole.
- **Stand-ins.** (a) The rival's four tail strikes are in his pools with status "waiting" and no key set (`data/combat/recipes.json:1930`, `:1934`, `:1986`, `:2200`); the sim skips waiting rows (`sim/director/blur.gd:213`), and the rig has no tail bones (`docs/animation/launch-pair-coverage.md:30`). (b) The transformation plays three placeholder poses shared by both fighters and every form (`data/anim/forms.json:3`, `:9`; `data/anim/poses.json:85-87`). (c) When a beat names no piece, the fighter plays a blow walked from his own light or heavy list (`render/anim/anim_fighter.gd:1594-1601`, `:3278`): his own animation, but not tied to the cell. How often that happens in a match: not evidenced.
- **No animation because no move.** 18 cells a fighter have no entry (A mash and hold, RB holds, RT + B mash and hold, RT stick: `reads/RR-01.md:221-223`). Two pools are posed but no sim code reaches them: the held Y (`mediumHeld`) and X + Y (`lift`) (`reads/RR-01.md:31`, `:208`).

Not evidenced: that each resolved key set plays in a live match for each cell. The project's own table for this (`docs/animation/launch-pair-coverage.json`) was last changed on 2026-10-03, was built from Combat's then-parked files, and still marks 180 of its 228 rows "parked" (F-ANIM-04).

**Q2. Joint limits: is the lint gated, and do Orb's complaints of bent limbs still show?**

- **The rule runs in the game, always.** The limits are data (`data/anim/joints.json`; schema `tools/schemas/anim-joints.schema.json`) and are enforced in the bake, the limb solves, the blends, the ragdoll and a last pass on every solve (`docs/animation/joint-limits.md:40-46`); the IK limit defaults on (`render/anim/anim_joints.gd:21`) and is switched off only by tool flags (`:167`, `:169`).
- **The lint is gated in the animation check, not in CI.** `anim_check.gd` runs `_test_joints` (`render/anim/tools/anim_check.gd:6869`, `:7879`) and exits 1 on any failure (`:7901`). No workflow names `anim_check` or `joint_scan` (grep of `.github/workflows/`, `tools/world-checks.json`, `qa/run-all.js`: no hits; `01-inventory/I-04-render.md:57`).
- **Last saved result:** "anim_check 0 anim check passed" in the EP's full local gate on the tree before the last two patches (record `docs/ep/runs/6a30b4c9/gate-full-s415.txt:59`). The focused gate on the tree that was landed has no `anim_check` line (record `docs/ep/runs/6a30b4c9/gate-focused-s419.txt`; `docs/ep/runs/6a30b4c9/README.md:6`). So: passing one step before the baseline, not recorded on it.
- **Do the complaints still show?** Orb's complaints are of 2026-10-01 and before (`docs/ep/vision.md:419`, `:477`). No later entry in `vision.md` repeats them (grep for bent, knee, elbow, limb, joint: nothing after `:477` on this). Orb's notes on the last build name "ground clipping with the character models" (`docs/ep/vision.md:1690`), which is a different fault. Whether a bent limb can still be seen: not evidenced by a run here. One known soft spot from the page itself: the last pass still corrects some live frames by more than 30 degrees (117 of 24,000 in the page's own count, `docs/animation/joint-limits.md:71`), which can read as a pop rather than a wrong bend.

**Q3. The creative rulebook: does it exist in force, and does it never block a gate?**

- **It exists and says it is in force.** `docs/animation/creative-rulebook.md:3` ("in force as the studio's own rulebook"), with 83 handed-over rows in `docs/animation/creative-rulebook-rows.md`; commit f06d1efe; Legal's handover is `docs/legal/creative-rulebook-handover.md`. Animation's charter carries it (`docs/directors/animation.md:22`). No copy sits under `docs/art/`.
- **"Never blocks a gate" is not literally true.** The held-pose rows are still a failing test: `_test_held` (`render/anim/tools/anim_check.gd:6859-6866`, called at `:7883`) fails the whole check, and that check is a line of the EP's full gate (record `docs/ep/runs/6a30b4c9/gate-full-s415.txt:59`). The rulebook says so itself: "a lint may still fail a build for a row we chose to keep as a lint" (`docs/animation/creative-rulebook.md:3`). The test's message still says "Legal's held rules" and it still reads its thresholds from Legal's folder (`render/anim/anim_held_lint.gd:121`, `docs/legal/movegen-banned.json`). It is not in CI, so it cannot block a deploy; it can block a landing.
- **Open inside it:** three questions for Orb (which numbers move, a named-exception list, who signs a change) are unanswered (`docs/animation/creative-rulebook.md:41-45`, `:52`).

**Q4. Transformation looks per form.**

- **What changes with a form on screen:** the aura's shape by tier (width, height, lobes, fill: `data/vfx/transform.json:20-25`), the aura's size and streaks (`render/core/fighter_view.gd:458-466`), idle scale by tier and the sky's reaction (`reads/RR-02.md:91-95`).
- **What does not:** the body. Each fighter has one colour set, not one per form (`data/fighters/PROTAGONIST/fighter.json:8`, `data/fighters/RIVAL/fighter.json:8`). The body's mesh is cached by its palette colours only (`render/anim/anim_rig.gd:167-171`). The transformation's poses are three placeholders for everyone (`data/anim/forms.json:3`, `:9`). No render or art file is keyed to a form id (`reads/RR-02.md:96`).
- **Design exists on paper:** concept sheets `art/concepts/forms/hero-forms.svg` and `anti-hero-forms.svg`. Orb's last word on them: the hero's forms are "all around not distinctive enough, lets bulk up muscles, add distinctive upgrade" (`docs/ep/vision.md:1464`); earlier, "a bigger visual change per form" (`:347`).
- **Which forms are live:** the shared three-step ladder for both fighters (`data/fight/ladder.json:10-13`); the Protagonist's own five steps are off (`data/fight/forms.json:4`) and the rival has none (F-COMBAT-08).

**Q5. The two fighters telling apart at a glance.**

- **What tells them apart today:** body colour (blue `#3d8fdc` against brick `#a52a2a`), hair and aura colour (`data/fighters/*/fighter.json:8`), the gear colour by role (`render/core/fighter_view.gd:218-222`), a different idle (`data/anim/shapes.json`, shapes P and A), different timing (`data/anim/fighters.json`, "fluid" against "snappy") and wholly separate strike animations (Q1).
- **What does not:** the body's outline. Both draw one humanoid mannequin on one rig; `docs/animation/fighter-onboarding.md:48` states it ("a single procedural mannequin mesh per palette"). Orb accepted this for Alpha: "the current characters are fine for first alpha version" (`docs/ep/vision.md:1729`).
- **Where it fails:** two copies of the same fighter. A 2v2 fills its four slots with Protagonist, rival, Protagonist, rival (`sim/core/stage.gd:65-67`), and a fighter's colours come from his data file alone (`sim/core/roster.gd:13`), so the two copies are identical. UI's own page keeps the mirror match off "until Art has" a second lane colour (`docs/ui/fighter-select.md:26`). A still that shows how it reads: not evidenced.

## Exit criteria

| Id | Status | Proof or gap | Measuring tool, and whether it exists |
| :--- | :--- | :--- | :--- |
| X-03 | Gap (animation half: mostly met in data; not measurable live today) | Every named piece has the fighter's own key set except four tail strikes (Q1); the cells themselves are incomplete (F-COMBAT-04). On the proposed table: keep COMBAT's correction to Orb's ruling (X, Y, B three ways, A two; `02-areas/COMBAT.md:92`), and count animation per **piece in a cell's pool**, not per cell, since 65 of 83 cells share a pool by design of the routing | The moveset coverage probe does not exist (F-COMBAT-11). A data half exists: `render/anim/tools/coverage.gd` with `docs/animation/launch-pair-coverage.json`, stale since 2026-10-03 and in no gate (F-ANIM-04). The live half would read `debug.pair_picks` (`render/anim/anim_fighter.gd:1601`) |
| X-04 | Gap | Three steps beyond base are reachable for both fighters on the shared ladder (`data/fight/ladder.json:10`), which fits Orb's "about three" (`docs/ep/vision.md:423`); so the proposed "at least two beyond base" can be raised to **three, the ladder's own count**. "The change is visible" is met by the aura only (Q4, F-ANIM-01). "Respected" is COMBAT's (F-COMBAT-14, F-COMBAT-23) | No transformation probe. A picture tool exists, `render/vfx/tools/transform_shots.gd` (not opened; in no gate, `01-inventory/I-04-render.md:47`); it could give the still per form |

## Findings

| id | kind | statement | evidence | criterion | severity | alpha | owner | cost | hash |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| F-ANIM-01 | gap | A transformation changes only the aura: both fighters play the same three placeholder poses for every form and no body look is keyed to a form. | `data/anim/forms.json:3`, `:9`; `data/anim/poses.json:85-87`; `data/vfx/transform.json:20-25`; `render/anim/anim_rig.gd:167-171`; `reads/RR-02.md:96`; `docs/ep/vision.md:1464` | X-04 | major | required | art | M | no |
| F-ANIM-02 | gap | In a 2v2 the two copies of each fighter are drawn identically, and the mirror match is held off for the same missing second colour. | `sim/core/stage.gd:65-67`; `sim/core/roster.gd:13`; `render/core/fighter_view.gd:218-222`; `docs/ui/fighter-select.md:26` | X-08, X-09 | major | required | art | S | no |
| F-ANIM-03 | gap | The animation check that holds the joint gate is in no CI job and has no saved record on the tree that was landed as 6a30b4c9. | `render/anim/tools/anim_check.gd:6869`, `:7879`, `:7901`; record `docs/ep/runs/6a30b4c9/gate-full-s415.txt:59`; record `docs/ep/runs/6a30b4c9/gate-focused-s419.txt`; `docs/ep/runs/6a30b4c9/README.md:6`; `01-inventory/I-04-render.md:57` | X-02 | minor | required | tools-pipeline | S | no |
| F-ANIM-04 | gap | The animation coverage table is of 2026-10-03, was built from Combat's then-parked files, still marks 180 of 228 rows "parked", and its check runs in no gate. | `docs/animation/launch-pair-coverage.md:1-5`; `docs/animation/launch-pair-coverage.json` (status counts; last commit 2026-10-03); `render/anim/render_anim.gd:28`; `01-inventory/I-13-other-docs.md:55` | X-03 | minor | required | animation | S | no |
| F-ANIM-05 | gap | The creative rulebook's held-pose rows still fail the animation check, which is a line of the EP's full gate, against the project rule that they never block a gate. | `render/anim/tools/anim_check.gd:6859-6866`, `:7883`; `render/anim/anim_held_lint.gd:121`; `docs/animation/creative-rulebook.md:3`, `:50`; record `docs/ep/runs/6a30b4c9/gate-full-s415.txt:59` | none | minor | nice | animation | S | no |
| F-ANIM-06 | gap | The rulebook's three questions to Orb (which numbers move, a named-exception list, who signs a change) are unanswered, so every threshold is still Legal's first guess. | `docs/animation/creative-rulebook.md:8`, `:41-45`, `:52` | none | minor | nice | orb | S | no |
| F-ANIM-07 | gap | The animation runtime, its tools and its data (render/anim, data/anim) are on no director's "owns" line; Animation owns only art/animation and docs/animation. | `DIRECTORS.md:247`; `docs/directors/animation.md:3`, `:10`; `01-inventory/I-04-render.md:18`; `01-inventory/I-08-data-schemas-switches.md:160` | none | minor | required | ep | S | no |
| F-ANIM-08 | gap | The rival's four tail strikes sit in his live pools as "waiting" rows with no key set and no tail bones in the rig. | `data/combat/recipes.json:1930`, `:1934`, `:1986`, `:2200`; `sim/director/blur.gd:213`; `docs/animation/launch-pair-coverage.md:30` | X-03 | minor | after | combat-choreography | S | yes |
| F-ANIM-09 | gap | Animation's parked-work page still says "Parked" for patches the inventory found on main, and the wave files' own headers still say no live match plays them. | `docs/animation/pending/README.md:3` (uncommitted); `01-inventory/inventory.md:63`; `data/anim/waves/protag1.keysets.json:1`; `render/anim/render_anim.gd:28` | none | minor | nice | animation | S | no |
| F-ANIM-10 | works | Every strike piece Combat's data names resolves to that fighter's own key set (79 of 79 and 80 of 84), and the 39 names both fighters use resolve to different key sets. | `render/anim/anim_data.gd:503-541`; `data/anim/fighters.json`; `data/combat/recipes.json:1878`; `data/combat/stick.json:112`; `render/anim/anim_fighter.gd:1594-1601` | X-03 | none | n/a | animation | n/a | no |
| F-ANIM-11 | works | Joint limits are data, are enforced by a last pass on every solve with the limit on by default, and passed the animation check one tree before the baseline. | `data/anim/joints.json`; `render/anim/anim_joints.gd:21`; `docs/animation/joint-limits.md:40-46`; record `docs/ep/runs/6a30b4c9/gate-full-s415.txt:59` | none | none | n/a | animation | n/a | no |
| F-ANIM-12 | works | The creative rulebook exists as a page with its 83 rows, owned by Animation with Art, and Legal's handover is on file. | `docs/animation/creative-rulebook.md:3`; `docs/animation/creative-rulebook-rows.md`; `docs/legal/creative-rulebook-handover.md`; commit f06d1efe | none | none | n/a | animation | n/a | no |
| F-ANIM-13 | works | The two different fighters read apart by body, hair and aura colour, by idle and by timing, which Orb accepted for the first Alpha. | `data/fighters/PROTAGONIST/fighter.json:8`; `data/fighters/RIVAL/fighter.json:8`; `data/anim/shapes.json`; `data/anim/fighters.json`; `docs/ep/vision.md:1729` | none | none | n/a | art | n/a | no |

Notes on the rows:

- **Owners where no "owns" line fits.** `render/anim/` and `data/anim/` have no owner line; findings in them go to `animation` by its charter (`docs/directors/animation.md:22`, `:33`). F-ANIM-01 is led by `art` (the look per form is a design), with `animation` (per-fighter poses), `vfx` and `rendering-techart`. F-ANIM-02 is led by `art` (the second colour), with `rendering-techart` and `ui-ux`.
- **Costs.** No comparable job with a recorded cost was found for these; all are "estimate, no comparable". The nearest figure on file is a row of the combat variety packet at 7M for five Animation sessions plus wiring (`docs/ep/proposals/combat-variety-packet.html:222`), which is far larger work than any row here.
- **F-ANIM-01 and F-COMBAT-08** describe the same hole from two sides: COMBAT's is which forms exist in the sim; this one is what they look like. Closing this one does not change the sim's hash; switching the Protagonist's own forms on would.
- **F-ANIM-02's hash:** a second colour can be given in the renderer (the lane-colour remap already exists, `render/core/look.gd:930-939`), so no hash change is needed; a fix that writes a new colour into the fighter's sim fields would change it.
- **F-ANIM-08's hash:** removing rows from a pool the sim reads changes the data hash.

## Gaps the questions missed

1. **Two copies of one fighter** (F-ANIM-02). The questions ask about telling the two fighters apart; with a roster of two, every 2v2 has two of each.
2. **The area's gate is outside CI** (F-ANIM-03), together with the coverage tools (F-ANIM-04). CI runs seven render scripts and none of Animation's (`01-inventory/I-04-render.md:57`).
3. **Nobody owns the animation code and data** on the roster's lines (F-ANIM-07): about 30,000 lines under `render/anim/` and 180 files under `data/anim/`.
4. **Leftovers seen in passing, for other areas:** a placeholder name is a live match key in the rival's glasses effect (`render/vfx/glare.gd:23`, VFX); a standalone measuring project sits inside the game tree (`render/anim/spike/`, `01-inventory/I-04-render.md:41`); about 45 animation switches are static values in code rather than data (`01-inventory/I-04-render.md:38`).

## Not evidenced

| What | The one measurement that would settle it |
| :--- | :--- |
| Whether each move-table cell plays a distinct animation in a live match | A scripted pad pressing every cell and logging the key set played (the X-03 probe, with `debug.pair_picks`) |
| How often a blow is a walked pick from the list and not the piece the beat named | The same run, counting named picks against all blows |
| Whether any bent limb is still visible in build 6a30b4c9 | `joint_scan --strict` and `anim_check` on 6a30b4c9, saved under `docs/animation/runs/6a30b4c9/` |
| Whether the over-30-degree corrections of the last pass read as pops | A slowed clip of the worst cases `joint_scan` names |
| How a 2v2 or a mirror match reads on screen | One still of a 2v2 with all four bodies in frame |
| What each tier looks like on each fighter today | One still per tier per fighter (`transform_shots.gd`) |
| Whether the held-pose lint has ever stopped a landing since the rulebook took force | The EP's gate records after 2026-11-07 searched for a held-pose failure |

## Decisions for Orb

1. **Is an aura change enough for a transformation in Alpha, or must the body change too?** Recommendation: ask for one cheap body change per step that data can carry (hair or accent colour, and each fighter's own break pose), and leave the bulked-up bodies you asked for to after Alpha, since you called the current characters fine for the first Alpha.
2. **In a 2v2, how should the second copy of a fighter differ?** Recommendation: a second body colour per fighter from Art, picked by team, not a marker over the fighter (you rejected markers).
3. **Should a failed held-pose rule stop a change from landing?** Recommendation: no; report it as a warning beside the gate, and keep only the joint limits as a hard stop. The rulebook's three open questions (which numbers move, an exceptions list, who signs a change) can wait until after Alpha.
