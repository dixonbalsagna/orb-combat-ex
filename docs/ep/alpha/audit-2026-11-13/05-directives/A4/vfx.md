# A4: VFX

Leads: none
Supports: A-ANIM-01, A-COMBAT-06, A-MODES-09

Goal: Each fighter's two forms beyond base have their own energy look that goes with the body change, and when two fights share one screen in a 2v2 the light from both is counted together and stays inside the safety limits.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4; decision 17); `docs/ep/alpha/audit-2026-11-13/02-areas/ANIM.md` (F-ANIM-01); `docs/ep/alpha/audit-2026-11-13/reads/RR-02.md` (lines 18-36 and 94-96: the only per-tier look today is the aura's shape by tier); `data/vfx/transform.json`; `render/vfx/tools/transform_shots.gd`; `docs/rendering/2v2-drawn-plan.md` (VFX's row: one register per screen); `docs/ep/proposals/co-op-2v2.md` (line 37); Game Design's forms page and Art's form sheets (the EP gives the paths); `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- A-ANIM-01 (Art leads): a transformation changes only the aura, by tier, the same for both fighters. Evidence: `data/vfx/transform.json:20-25`; `data/anim/forms.json:3`; `render/anim/anim_rig.gd:167-171`.
- A-COMBAT-06 (Game Design leads): the Protagonist's own forms are off and the rival has none; when they are on, no render file keys on a form's id. Evidence: `data/fight/forms.json:4`; `RR-02.md:20-24`.
- A-MODES-09 (Rendering leads): drawing the other fight puts two fights' effects on one screen; the plan ties it to one flash register per screen that sums every light event from either fight and the shared world. Evidence: `docs/rendering/2v2-drawn-plan.md:7-8`; `docs/ep/proposals/co-op-2v2.md:37`.

You own: `render/vfx/`, `art/vfx/`, `docs/vfx/`.
- ask under NEEDS FROM EP for a grant: `data/vfx/` (the transformation's look per fighter and form; no director owns it)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (any data shape you change)

Acceptance criteria:
1. (A-ANIM-01, A-COMBAT-06) The transformation's energy look is data keyed by fighter and form, following Art's sheets; no new table keyed by fighter id is added in `render/vfx/` (files such as `beam_look.gd` and `glare.gd` already hold some, and the count must not rise).
2. (A-ANIM-01, X-04) `transform_shots` (or its successor) produces one still per form per fighter from the built game and is listed as a tool with a stated output; the stills are saved.
3. (A-MODES-09) One register per screen: it sums every light event drawn on any pane from either fight and from the shared world against Legal's limits; when it is over, the other fight gives way (calmer, thinner or later), never the player's own fight. The per-fight registers feed it. A check with a verdict drives two fights' worst cases on one screen and shows the sum stays inside the limits.
4. (A-MODES-09) Counting starts on the tick an effect comes on screen, using Rendering's on-screen test; with the effects word off, none of the other fight's light is drawn.
5. Look gate (ADR 0010): each change ships with a side-by-side against the reference build in `docs/ep/taste.md` (`node tools/flash/side-by-side.mjs`) before it is committed, and the collapse clip is run in both flash modes before any look report. The player's own fight in a 1v1 looks the same as the reference: safety is met by the register and the settings, not by dulling the default look.
6. Evidence: check results, stills and side-by-sides are saved under `docs/vfx/runs/<sha>/`; pictures for anyone to look at go in `docs/vfx/img/`.

Constraints:
- Tokens: supporting work, counted under the lead rows; plan for about an M (1.2M) as an estimate, most of it the register.
- No change to the sim's state hash: effects read sim state and events and never write them.
- Machine: no Godot windows; Godot headless only, at most 3 processes for a short gate; captures only through Tools' launcher, one at a time, with a time limit.
- Determinism: effects follow the tick; numbers in data, schema updated in the same commit as a shape change.
- Originality: each form's energy look is our own; no power-up look that reads as an existing franchise's.
- Orb's rules: nothing drawn on, over or between the fighters that is not the fighter's own energy (no steady ring or marker); no dissolves, fades or full-screen blur or haze; nothing that costs frame rate for presentation (a full-screen pass needs Performance's timing first); the brawl reads chunky, not thin.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: Game Design's forms page and Art's sheets for the form looks; Rendering's step A (bodies drawn, on-screen test) for the register. Waiting on this: Rendering's step B (the other fight's light), UI's effects switch, Tools' two-fights clips and Legal's reading; the per-form stills X-04 asks for.
