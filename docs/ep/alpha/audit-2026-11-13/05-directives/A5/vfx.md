# A5: VFX

Leads: none
Supports: A-RENDER-05, A-RENDER-06

Goal: When a player picks a lower picture-quality level, the effects visibly thin out and the frame rate rises, and a Steam Deck holding 30 frames a second is not pushed to the lowest level by itself.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A5 and the A-RENDER-06 line of "Rows proposed smaller for Alpha"); `docs/perf/quality-range.md` (the Result list, and line 30 on the governor's thresholds); `docs/vfx/perf-level.md`; `render/vfx/vfx_hub.gd` lines 152 to 160; `render/vfx/vfx_look.gd` lines 175 to 180; `data/vfx/perf.json`; `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- A-RENDER-05 (Rendering leads): Settings offers "Effects quality" but no game code reads the choice. Evidence: `ui/data/options.json:52`; `ui/hud/ui_hud.gd:85`; `render/core/main.gd:168-172` (only the launch word `vfx-quality` reaches your hub's `quality` and `auto_quality`).
- A-RENDER-06 (Rendering leads): no working level picker, no Deck default, and an automatic step whose threshold pins a 30 frames-a-second machine at low. Evidence: `render/vfx/vfx_hub.gd:156-158` (`AUTO_DOWN_FPS` 42, `AUTO_UP_FPS` 57); `render/vfx/vfx_look.gd:178` (`PERF_DEFAULT` off "until the quality ladder asks for it"); `docs/perf/quality-range.md:30`.

You own: `render/vfx/`, `art/vfx/`, `docs/vfx/`.
- ask under NEEDS FROM EP for a grant: `data/vfx/perf.json` (no owner), for the level caps.
- The option handler in `render/core/main.gd` is Rendering's and the Settings row is UI's; say what your hub needs from each under NEEDS FROM EP.

Acceptance criteria:
1. (supports A-RENDER-05) The hub exposes one documented way to set the effects level from the saved option (low, medium, high, auto), and each fixed level differs visibly and measurably from its neighbour. Checked by: a headless test that sets each level and reads the live caps, saved under `docs/vfx/runs/<sha>/`.
2. (supports A-RENDER-06) The automatic step's thresholds follow the frame rate the machine is aiming for, from data, so a machine holding 30 frames a second at the Deck's default level stays there. Checked by: a scripted frame-time trace at 30 held and at 60 held, with the level the governor ends on, saved under `docs/vfx/runs/<sha>/`.
3. (supports A-RENDER-06) The parked Performance-level caps (`docs/vfx/perf-level.md`) are brought onto main behind the "low" level if Rendering's level table asks for them, and are identical to today when off. Checked by: the bench in that page re-run on the A5 tree, at below-normal priority, result saved.
4. (both) Fewer effects never hide a warning or a cue a player needs: the lowest level keeps the same events visible, only with less debris, dust and cracking (the option's own help text promises this). Checked by: a list in `docs/vfx/` of what each level drops, read by the EP.
5. (both) Look gate (ADR 0010): a side-by-side per level against the reference build named in `docs/ep/taste.md` on the day, same scene and ticks, seen by the EP before commit; both modes of the flash check run on the changed picture first. The high level is the reference look unchanged.

Constraints:
- Tokens: no row of its own; plan on about 0.5M of supporting work, an estimate, counted inside A-RENDER-06's class.
- State hash: no change. Effects read the sim and never write it; the same seeded match must give the same fingerprint at every level.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; the bench is a long run at below-normal priority; pictures only through Tools' launcher (`tools/machine/capture.mjs`), one at a time; a reading on a saturated machine is void.
- Determinism: level numbers live in data; a change to `data/vfx/perf.json`'s shape updates its schema in `tools/schemas/` in the same commit.
- Originality: every effect is our own.
- Orb's rules: nothing drawn on, over or between the fighters; no dissolves, fades, blur or haze as a way to save frames; beams stay crisp at every level.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Starts when Rendering's level table (which dials each of the three levels moves) reaches you through the EP, and after the Deck's readings from A2 to A4 are in. Rendering's acceptance items 1 to 3 and UI's quality row wait on your items 1 and 2.
