# ACCESS: accessibility and localisation

Alpha audit 2026-11-13, baseline 8901d351 (game code of build 6a30b4c9). Read-only. This area was reviewed at reduced depth: mainly from the inventory slices I-05 and I-07 and reading answer RR-09, with the code opened only where a blocker or major might hide.

## Summary

- Works: colour-blind presets, three text sizes over a 14-pixel floor, hold-or-toggle for five actions, a Simple controller layout with remapping, volume and mono, and settings that are saved and re-applied at start.
- Does not: no test proves settings survive a restart on Windows or a Steam Deck (X-20), and no saved record or stills show clean text at 1280 by 800 (X-22).
- Biggest gap: the area has no pass, checklist or record newer than 2026-10-31, and its corrective item CD-14 has no recorded progress.
- Language: English only in practice; nobody has written that down.
- No blocker found. Reviewed at reduced depth.

## Questions and answers

**Q1. The baseline for Alpha: what's in the build (colour-blind options, text size, hold-or-toggle, simple controls)?**

All four are in the code at the baseline. Whether each is on screen in Orb's build was read from main's data only (the kept build's own packed data was not opened: see Not evidenced).

| Item | In the build? | Evidence |
| --- | --- | --- |
| Colour-blind options | Yes: off, protan, deutan, tritan; reaches HUD, fighters and effects | ui/data/options.json:91; ui/hud/ui_hud.gd:645-646; render/core/look.gd:921; render/vfx/vfx_hub.gd:287; data/art/colour-vision.json |
| Text size | Yes: 1.0, 1.25, 1.5; one function sizes all text; floor 14 px | ui/data/options.json:92; ui/hud/ui_hud.gd:647-649; ui/core/ui_text.gd:51-52; ui/core/ui_look.gd:12 |
| Hold-or-toggle | Yes, per player: energy, guard, manoeuvre stance, charging stance, transform | ui/data/options.json:74-83; render/core/main.gd:1134, :1637 |
| Simple controls | Yes: "Simple" controller layout beside "Arena"; remap screen on | ui/data/options.json:60; data/input/layouts.json:145; ui/data/features.json:7 |
| Also present | Reduced motion; Reduce flashing (default on); camera shake; master, effects and voice volume; mono; vibration switch; cue captions (off by default); "Button only" brace | ui/data/options.json:39, :45, :46, :53, :57, :70, :96-99; render/anim/anim_fighter.gd:487; audio/audio_voices.gd:207 |
| The Accessibility page lists | colour vision, text size, reduced motion, reduce flashing, the notice, captions, cue captions, damage rings, ring thickness, Hit pause, keep hints, vibration | ui/data/settings.json:56 |
| Hidden until a feature is on | latched charge and charges off (three_strengths false), planet map, world turning | ui/widgets/ui_settings.gd:35; ui/data/features.json:10, :21, :22 |
| Missing | Screen reader or menu narration | docs/accessibility/audit-2026-10-28.md:153-157 |

The saved gate record for the baseline's game code shows the HUD check at 8288 checks, 0 failed (record: docs/ep/runs/6a30b4c9/gate-full-s415.txt:123). That check is not run by CI (I-05 inventory, line 9).

**Q2. Open items from the corrective plan (CD-14).**

The row reads: cue captions, Hit pause wired or removed, brace_key on pads, ship main's fixes with the next pin; done-test "hud_check covers cue captions; no option without a consumer"; progress cell empty (docs/ep/corrective-plan-2026-11-07.md:22). RR-09 found no commit and no record naming CD-14 since 2026-11-07 (reads/RR-09.md:32).

| Part | State at baseline | Evidence |
| --- | --- | --- |
| Cue captions | Open. Two captions exist (beam struggle, an opening); the line is off by default | ui/core/ui_event_hub.gd:1062; ui/hud/ui_hud.gd:4313; ui/data/options.json:39 |
| Hit pause wired or removed | Open. Still listed on the page, still no reader outside ui/ | ui/data/settings.json:56; ui/hud/ui_hud.gd:72 ("the HUD only carries it"); a search of sim, render, audio and data at 8901d351 finds no other use |
| brace_key on pads | Done on Arena (L3), by commit 8db493cb; Simple binds none | data/input/layouts.json:136-140; data/input/layouts.json:145 (no brace_key in that block) |
| Ship main's fixes with the next pin | Moot while the public page is down; applies to the Alpha candidate instead | docs/ep/corrective-plan-2026-11-07.md:11 |

**Q3. Language: English only for Alpha? Say so.**

In practice yes. The only alternative text is a test copy with stretched, accented words behind a command-line switch (ui/core/ui_data.gd:41; I-05 inventory line 38). The translation plan says "Nothing here is turned on" (docs/accessibility/l10n-plan.md:3). No language option exists in ui/data/options.json. A statement from Orb that Alpha is English only: not evidenced (a search of docs/ep/vision.md for language, translate, locali found none). See Decisions for Orb.

## Exit criteria

| Id | Status | Proof or gap | Measuring tool, and whether it exists |
| --- | --- | --- | --- |
| X-20 | Not measurable today | Saving and loading are coded (ui/hud/ui_hud.gd:2477-2496; render/core/main.gd:212-215; sim/input/remap.gd:13) and round-trip inside one process in the HUD check (ui/tools/hud_check.gd:5877, :7859). No run restarts a Windows or Linux export and reads the files back. | Settings round-trip test per platform: does not exist. The in-process checks exist and are not in CI. |
| X-22 | Not evidenced | The text floor is 14 px (ui/core/ui_look.gd:12). A check plans every screen at 1280 by 800 at each text size (ui/tools/text_size_check.gd:7), and the HUD check includes that size (ui/tools/hud_check.gd:9876). No saved record of text_size_check or the overflow report exists under docs/*/runs, and no stills at 1280 by 800. | Screen sweep at 1280 by 800: the planning half exists (text_size_check, overflow_check); the stills half and a saved record do not. |

**The proposed number for X-22.** The specification proposes a smallest text of 9 px. The audit's web check records the platform holder's rule as 9 px minimum character height with 12 px recommended (02-areas/web-checks.md:35, :40). The code's floor is a 14 px font size, scaled up by the text-size option (ui/core/ui_text.gd:51-52). Recommendation: keep 9 px as the failing line and 12 px as the aim, as web-checks.md:40 says, and measure character height in the stills, because the code's 14 is a font size, not a measured glyph height (the height of the smallest drawn character: not evidenced).

## Findings

| id | kind | statement | evidence | criterion | severity | alpha | owner | cost | hash |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-ACCESS-01 | gap | Settings and remaps are written to two files, but no test restarts the game on Windows or a Deck to show they survive; a failed write is silently ignored. | ui/core/ui_prefs.gd:4-5, :34-38; sim/input/remap.gd:13; ui/tools/hud_check.gd:5877, :7859 | X-20 | major | required | ui-ux | S | no |
| F-ACCESS-02 | gap | The 1280 by 800 text checks exist but run in no CI job, and no saved record or stills show the menus clean at the Deck's size. | ui/tools/text_size_check.gd:7; ui/tools/hud_check.gd:9876; tools/l10n/overflow_check.gd:1; I-07 inventory :72 | X-22 | major | required | ui-ux | S | no |
| F-ACCESS-03 | gap | No accessibility pass or record newer than 2026-10-31 and no runs folder, so the area's part of the "before an outside tester plays" list does not exist. | docs/accessibility/audit-2026-10-28.md:1, :11; docs/ep/corrective-plan-2026-11-07.md:22; reads/RR-09.md:32 | X-02 | major | required | accessibility-localization | S | no |
| F-ACCESS-04 | gap | The Hit pause slider is shown and does nothing (CD-14, open). | ui/data/settings.json:56; ui/data/options.json:50; ui/hud/ui_hud.gd:72; audit/2026-11-07/findings.md:183 | none | minor | required | ui-ux | S | no (yes if wired into the sim instead of hidden) |
| F-ACCESS-05 | gap | Sounds are captioned for two cues only, and that line is off by default. | ui/core/ui_event_hub.gd:1062; ui/hud/ui_hud.gd:4313, :953; ui/data/options.json:39 | none | minor | nice | ui-ux | M | no |
| F-ACCESS-06 | gap | CD-14's progress cell is empty and nothing names it since 2026-11-07, though its pad brace part is done on Arena. | docs/ep/corrective-plan-2026-11-07.md:22; reads/RR-09.md:32; data/input/layouts.json:136-140; commit 8db493cb | X-02 | minor | required | ep | S | no |
| F-ACCESS-07 | gap | The Simple layout binds no brace button; whether "Button only" strands a Simple-layout player is not evidenced. | data/input/layouts.json:145; ui/data/options.json:70; sim/input/layout.gd:1127 | none | minor | nice | controls-feel | S | no |
| F-ACCESS-08 | gap | Nothing written says Alpha is English only; no language choice; translation tools and the stretched-text copy are in no CI job. | docs/accessibility/l10n-plan.md:3; ui/core/ui_data.gd:41; I-07 inventory :56; I-05 inventory :38 | none | minor | after | accessibility-localization | S | no |
| F-ACCESS-09 | gap | The switch that stops Reduce flashing being turned off is false on main, and no record shows a tester build of the baseline with it on; the tool step exists. (Handled off the owner's page.) | ui/data/features.json:12; ui/core/ui_data.gd:427-428; tools/desktop-package.mjs:6-7; questions.md:17 | X-02 | minor | required | tools-pipeline | S | no |
| F-ACCESS-10 | gap | No screen reader or menu narration. | docs/accessibility/audit-2026-10-28.md:153-157 | none | minor | after | ui-ux | M | no |
| F-ACCESS-11 | works | Colour-blind mode reaches HUD, fighters and effects. | ui/data/options.json:91; ui/hud/ui_hud.gd:645-646; render/core/look.gd:921; render/vfx/vfx_hub.gd:287 | none | none | n/a | ui-ux | n/a | no |
| F-ACCESS-12 | works | Three text sizes over a 14-pixel floor. | ui/data/options.json:92; ui/core/ui_text.gd:51-52; ui/core/ui_look.gd:12 | X-22 | none | n/a | ui-ux | n/a | no |
| F-ACCESS-13 | works | Hold-or-toggle per player for five actions. | ui/data/options.json:74-83; render/core/main.gd:1134, :1637 | none | none | n/a | controls-feel | n/a | no |
| F-ACCESS-14 | works | Simple layout and a remap screen; remaps saved. | ui/data/options.json:60; data/input/layouts.json:145; sim/input/remap.gd:13; render/core/main.gd:205 | X-20 | none | n/a | controls-feel | n/a | no |
| F-ACCESS-15 | works | Settings saved on change and applied at start; HUD check 8288 checks, 0 failed on record. | ui/hud/ui_hud.gd:2477-2496; render/core/main.gd:212-215; record docs/ep/runs/6a30b4c9/gate-full-s415.txt:123 | X-20 | none | n/a | ui-ux | n/a | no |
| F-ACCESS-16 | works | Volume (three) and mono, with a reader in audio. | ui/data/options.json:96-99; ui/hud/ui_hud.gd:650-653; audio/audio_voices.gd:207 | none | none | n/a | audio-music | n/a | no |
| F-ACCESS-17 | works | Reduce flashing defaults on, the notice can be re-read, and a lock is coded. (Off the owner's page.) | ui/data/options.json:45; ui/data/settings.json:56; ui/hud/ui_hud.gd:2474-2475, :2493-2494 | X-02 | none | n/a | ui-ux | n/a | no |

Owner notes: data/input has no "owns:" line; findings on it go to controls-feel, whose code reads it (sim/input/remap.gd, sim/input/layout.gd). Costs are all "estimate, no comparable": no recorded cost for a like job was found in the files read.

## Gaps the questions missed

- **A failed save is silent.** UiPrefs ignores a write that fails (ui/core/ui_prefs.gd:4-5, :34-38). On a new platform a tester would lose settings with no message; part of F-ACCESS-01.
- **Scripted and tool runs skip saved options by design** (render/core/main.gd:212-214), so no existing scripted run can serve as the X-20 test without a new mode that loads them.
- **The stale summary.** The area's only audit still lists "no volume controls", "no difficulty choice" and "no text-size option" (docs/accessibility/audit-2026-10-28.md:11), all since built (ui/data/options.json:92, :96-99; ui/tools/hud_check.gd:7859). Part of F-ACCESS-03.
- **The Simple layout and the brace** (F-ACCESS-07).
- **The new side-rail menus** ("Rail", off on main: ui/data/features.json:49; reported on in Orb's build by the inventory) were not checked for whether every accessibility row is reachable from them: see Not evidenced.
- **The stretched-text copy is unchecked data.** It sits outside the schema checker's roots (I-05 inventory, Notable 4) and still carries retired words (I-05 inventory line 38). After Alpha; folded into F-ACCESS-08.

## Not evidenced

- **Which options Orb's kept build shows.** I read main's data, not the build's packed data; the path I tried under homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/tree/ui/data/ did not exist. One read of the build's own features and settings data settles it.
- **Settings surviving a restart on Windows desktop and on a Deck.** One save, quit, start, read run per platform settles it (X-20).
- **Clean text at 1280 by 800.** One saved run of ui/tools/text_size_check.gd plus stills of each menu settles it (X-22). Godot was not run in this audit.
- **Smallest character height in pixels on the Deck.** The 14 is a font size; a still measured at 1280 by 800 settles it.
- **Whether the side-rail menus reach every accessibility option.** A pad walk through them in the candidate settles it.
- **"Button only" brace on the Simple layout.** One input test with the Simple layout settles it.
- **Contrast.** The 2026-10-28 audit says contrast was not measured (docs/accessibility/audit-2026-10-28.md, table row 4); no later measurement was found.
- **Whether bark captions ever show.** The 2026-11-07 audit says barks were off (audit/2026-11-07/findings.md:182); not re-checked here.
- **A statement by Orb on Alpha's language.** Not found.

## Decisions for Orb

1. **Is the Alpha English only?** Recommended: yes; say so in the tester guide, and leave translation until after Alpha.
2. **Hit pause, the slider that does nothing: hide it for Alpha, or make it work?** Recommended: hide it now; bring it back only when the short freeze on a heavy hit is switched on in the game and the slider can change it.
