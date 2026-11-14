# A4: Art

Leads: A-ANIM-01, A-ANIM-02
Supports: none

Goal: When a fighter transforms the player sees the body change, not only the glow, and in a 2v2 the two copies of the same fighter can be told apart at a glance by body colour.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4; decision 17); `docs/ep/alpha/audit-2026-11-13/02-areas/ANIM.md` (F-ANIM-01, F-ANIM-02; lines 80-88 on owners and on the hash); `docs/ep/alpha/audit-2026-11-13/reads/RR-02.md` (which files carry a per-form look today); Game Design's forms page (which forms exist; the EP gives the path); `docs/art/README.md`; `data/fighters/PROTAGONIST/fighter.json` and `data/fighters/RIVAL/fighter.json` (one colour set per fighter: `col`, `aura`, `hair`); `docs/ui/fighter-select.md`; `docs/rendering/2v2-drawn-plan.md` (the row for Art and Animation); `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- A-ANIM-01 (M, major): a transformation changes only the aura: both fighters play the same three placeholder poses for every form and no body look is keyed to a form. Evidence: `data/anim/forms.json:3` and `:9` (poses `form.gather`, `form.break`, `form.settle` for every fighter); `data/anim/poses.json:85-87`; `data/vfx/transform.json:20-25` (the aura's shape by tier).
- A-ANIM-02 (S, major): in a 2v2 the two copies of each fighter are drawn identically, and the mirror match is held off for the same missing second colour. Evidence: `sim/core/stage.gd:65-67` (the four slots are the roster's first two, twice); `sim/core/roster.gd:13`; `render/core/fighter_view.gd:218-222` (one palette per fighter); `docs/ui/fighter-select.md:26` ("needs a second lane colour from Art").

You own: `art/`, `docs/art/`.
- ask under NEEDS FROM EP for a grant: `data/art/` (the per-form look and second-colour data; no director owns it)
- ask under NEEDS FROM EP for a grant: `data/fighters/` (only if a colour is stored beside `col`, `aura` and `hair`; Narrative & Fighter Identity's folder)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (any data shape you change)
- Poses are Animation's, the aura is VFX's, and the code that draws a fighter (`render/core/fighter_view.gd`, `render/core/look.gd`) is Rendering's: hand each the design and list what they must build under NEEDS FROM EP.

Acceptance criteria:
1. (A-ANIM-01) A design sheet in `art/` and a page in `docs/art/` give, for each fighter and each of the two forms beyond base, one cheap body change carried by data: hair or accent colour, and that fighter's own break pose (the one frame the silhouette changes). Bulked-up bodies are after Alpha. Checked by the EP against decision 17 and seen by Orb.
2. (A-ANIM-01) The look per form is a data entry keyed by fighter and form; no look table keyed by fighter id is added to render or UI code (it would raise the count A-CODE-05 holds down). Checked by CI's data job and the two-fighter ratchet.
3. (A-ANIM-01, X-04) One still per form per fighter from the built game, beside the base form, shows the change is visible at fight distance and at the zoomed-out split. Stills come through Tools' launcher; `render/vfx/tools/transform_shots.gd` exists as a picture tool to start from (VFX's).
4. (A-ANIM-01) Look gate (ADR 0010): a side-by-side of a transformation against the reference build in `docs/ep/taste.md`, made with `node tools/flash/side-by-side.mjs`, before it is committed; and the transformation clip is run through the flash check in both modes before any look report.
5. (A-ANIM-02) A second body colour for each fighter, picked by team, as data. It is a body colour only: no marker, ring, arrow or label on, over or between the fighters.
6. (A-ANIM-02) The second colour is applied in the renderer's existing lane-colour remap (`render/core/look.gd:930-939`), not written into the fighter's sim fields, so the state hash does not change. Checked by the determinism gate being unchanged.
7. (A-ANIM-02, X-09) A still of a 2v2 with all four fighters in frame, and of a mirror 1v1, shows each copy can be told apart on the day and night sides and against the brightest biome. Checked by the EP and by a contrast reading saved with the stills.
8. (A-ANIM-02) The stills of both second palettes go to Legal through the EP for an originality look before they are used.
9. Evidence: the sheets, stills, side-by-sides and check results are saved under `docs/art/runs/<sha>/`.

Constraints:
- Tokens: about 1.45M as an estimate (M 1.2M + S 0.25M).
- Neither row changes the sim's state hash, and neither may: colour and form looks stay on the render side.
- Machine: no Godot windows; pictures come from the web build in headless Chrome through Tools' launcher only (`tools/flash/capture-web.mjs`, `tools/machine/capture.mjs`), one capture at a time, each with a time limit; check nothing you started is still running before you end a turn.
- Determinism: nothing here writes sim state; numbers and colours in data, schema updated in the same commit as a shape change.
- Originality: each form's look and each second palette is our own; no hair, colour scheme or power-up look that reads as an existing franchise's character. No masks (parked for a future fighter).
- Orb's rules: nothing drawn on, over or between the fighters; no dissolves, fades or full-screen blur in the change; in-progress character art is never public (sheets stay in the repository, off any public page); the AI disclosure goes wherever the art is shown; plain words in the pages.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: Orb's answer to decision 17 (body change per step; a second colour by team); Game Design's forms page (A-COMBAT-06) for A-ANIM-01. A-ANIM-02 needs nothing and can go first. Waiting on this: Animation's break poses, VFX's per-form aura, Rendering's hookup, UI's mirror match on the fighter pick, and the stills X-04 asks for.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- Supports A-MODES-02: one cheap weak-enemy body as data, or a written statement that Alpha's enemies reuse an existing body with a palette, delivered before Legal's row. (MIS-06)
