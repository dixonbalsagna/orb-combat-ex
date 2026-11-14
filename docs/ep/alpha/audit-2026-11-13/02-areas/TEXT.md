# TEXT: names, lines and player-facing words

Alpha audit, phase 2, baseline 8901d351 (game code of build 6a30b4c9). Read-only. Reviewed at reduced depth: worked mainly from inventory slices I-05 and I-08 and reading answer RR-05, with spot checks in the data and code.

## Summary

- **Works:** the fighters show as Grist and Loupe from one data file; 355 fighter lines sit in data, each traced to Orb's own words or marks; the how-to card and hints are short, plain and data-driven. (Reduced-depth review.)
- **Does not:** the fighters say none of those lines in a match (the lines are switched off on main and in the build Orb last played); the line check and the "no placeholder name on screen" check are run by hand only.
- **Biggest gap:** no record that Orb has seen the menu, how-to, hint, notice and settings text. The list made for Orb's marks (1115 strings) has no mark in any row, against Orb's rule of 2026-10-12.

## Questions and answers

**Q1. Which player-facing text in the build has Orb seen?**
- Orb's rule: `docs/ep/vision.md:951` ("written with care and seen by Orb before it is used").
- **Seen, with a record:** the fighters' names (`docs/ep/vision.md:1529`); the fighter lines in `data/narrative/live_barks.json`, whose header says every line is Orb's own words, a line Orb kept, or a rewrite Orb reviewed (`data/narrative/live_barks.json:3`, `lines_policy` at `:5`; the sessions are `docs/ep/vision.md:995` and `:1440`). By source tag, counted from the file: 242 reviewed rewrites and 80 kept drafts from the mid-combat set, 19 rewrites and 4 kept lines from homework 11, 10 lines in Orb's own words. These lines are not in play (Q2).
- **No record:** everything in `ui/data/` (the notice, start menu, how-to, hints, settings, match-over card, report panel). `docs/ui/strings.md:3` says the list holds 1115 strings "so Orb can mark a batch"; the Mark column (`docs/ui/strings.md:5`) is empty in every row (a search for keep, rewrite or cut in that column finds 0). Whether Orb read these strings while playing is not evidenced. F-TEXT-01.

**Q2. Barks and one-liners for two fighters: how many, and do they follow the voice-lab rules?**
- Count, from `data/narrative/live_barks.json`: 16 beats, 355 lines: Grist (roster id PROTAGONIST) 118, Loupe (RIVAL) 119, and 118 for two later fighters (60 and 58).
- **Length:** the specification's "4 to 12 words" is out of date. Orb widened it to 4 to 15 on 2026-10-30 (`docs/narrative/line-lint.json:8`; `docs/narrative/line-lint.py:4`). Counted here: 3 lines under 4 words, all tagged Orb's own words and exempt; 6 lines over 15 words (16 or 17), each waived by id under `orb_approved_waivers` in `docs/narrative/line-lint.json`. No other line is out of range.
- **Banned words:** 14 from Orb plus 14 proposed by Narrative in `docs/narrative/line-lint.json`; 0 whole-word hits in the 355 lines (counted here with the lint's own word rule). Every line's stored `hard` list is empty.
- **Direct address:** the lint only reports this for a human (`docs/narrative/line-lint.py:17`, `:121`); 239 lines carry a stored `check` note of some kind. How many of those are "not said to the opponent" was not broken out: not evidenced.
- **In play:** none. `"enabled": false` at `data/narrative/live_barks.json:4`, the same in Orb's build (`homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/tree/data/narrative/live_barks.json:4`); the host leaves the emitter null while it is off (`render/core/main.gd:113`, `:366`, `:918`). `tools/preview/switches.mjs` has no row for it. F-TEXT-02.
- The lint was not run in this audit, is in no CI job, and has no saved result (there is no `docs/narrative/runs/`). F-TEXT-03.
- A second file, `data/narrative/combat_barks.json`, is all placeholder (`:3`) and no game code reads it (I-08, Notable 4). F-TEXT-06.

**Q3. Grist and Loupe in the build; KAI and VORR still in code or data?**
- Names: `ui/data/fighter_names.json:5-6` (Grist, "Martial Artist"; Loupe, "Challenger"). The UI swaps roster ids for these (`ui/core/ui_data.gd:165`, `:189`). No file in `ui/data/` contains KAI, VORR, "placeholder" as shown text, or a to-do mark (searched). F-TEXT-10.
- Leftovers (RR-05, section a; 69 and 61 hits): almost all in tools and tests (`sim/core/tools/parity.gd`, checks that assert the names are gone). In data or shipped code: line ids `shout.kai.*` and `shout.vorr.*` (`data/narrative/combat_barks.json:21-23`, `:34-36`), a note (`data/combat/recipes.json:5`), an effects list that still accepts "VORR" (`render/vfx/glare.gd:23`), and the JS reference core's roster (`sim/core/roster.js:5-6`). None is text a player reads. F-TEXT-06.
- The check that a player never sees those names is in a hand-run file (`ui/tools/hud_check.gd:6634`, `:6654`), not in CI. F-TEXT-08.

**Q4. How-to-play and hint wording in plain words.**
- The how-to card is data (`ui/data/howto.json`, 116 lines; 7 pages). The sentences are short and plain, for example `ui/data/howto.json:15`. Hints (`ui/data/hints.json`) are short labels such as "Guard (toggle)". F-TEXT-12.
- Gaps: keyboard keys shown to a pad player (`ui/data/howto.json:6`, `:7`; drawn whenever touch is off, `ui/widgets/ui_howto.gd:481`), F-TEXT-04; "the strip" for the planet bar (`:79`), "his" for the rival (`:75`), and a privacy line about a web version and a clipboard (`:102`), F-TEXT-09.
- Whether the how-to's control rows match Orb's inputs (right-stick attacks; RT + RB + flick) was not traced: the rows draw from the layout data, which belongs to the CONTROLS area. Not evidenced here.

**Q5. The title on screen: "working title" handling.**
- The game's name is "Orb Combat EX" in `project.godot:8`, the Windows file details (`export_presets.cfg:82-83`), the Rail menu's small heading (`ui/data/terms.json:92`, `rail_kicker`), the About page (`ui/data/howto.json:88`) and the report header (`ui/data/feedback.json:17`). No shown text carries "working title" (searched `ui/`, `render/`, `data/`, `localization/`; the only hit is a comment at `project.godot:1`).
- Legal's page: the name is conditional, a search is due before any itch.io page, and the visible heading may keep "(working title)" until then (`docs/legal/name-screening.md:186-187`). The LEGAL area holds the main gap (F-LEGAL-09). F-TEXT-05.
- Where the title shows on the start menu when the Rail menus are off (off on main, `ui/data/features.json:49`) was not traced: not evidenced.

## Exit criteria

| Id | Status | Proof or gap | Measuring tool, and whether it exists |
| --- | --- | --- | --- |
| X-19 | Not measurable today (the text part has small gaps) | The words for the notice, menu, how-to and match-over card exist as data (`ui/data/terms.json:92`, `ui/data/howto.json`). Gaps on the text side: keyboard keys named to a pad player (F-TEXT-04); no record that Orb has seen the text (F-TEXT-01). No proposed number in this criterion belongs to this area. | The real-Deck checklist and the mode smoke on Linux: not checked in this area (see the MODES area). For text, `ui/tools/strings_inventory.py` and `docs/ui/strings.md` exist and can carry Orb's marks. |
| X-32 | Gap | The AI disclosure is in the build (`ui/data/howto.json:88`, `:105`). The in-game privacy line does not match the Alpha's report channel (`ui/data/howto.json:102`; the LEGAL area's F-LEGAL-12). No record that Orb has seen the wording (F-TEXT-01). The title's mark is open (F-TEXT-05). | Legal's sign-off row per item: the LEGAL area found one open row. No new tool is needed for the text side. |

## Findings

| id | kind | statement | evidence | criterion | severity | alpha | owner | cost | hash |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-TEXT-01 | gap | No record shows Orb has seen the menu, how-to, hint, notice or settings text; the list made for Orb's marks (1115 strings) has no mark. | `docs/ep/vision.md:951`; `docs/ui/strings.md:3`, `:5`, `:11` | X-19, X-32 | major | required | ui-ux (with narrative-identity) | S (estimate, no comparable) | no |
| F-TEXT-02 | gap | The fighters say nothing in a match: the approved lines are off on main and in Orb's build, with no switch row. | `data/narrative/live_barks.json:4`; the build's `tree/data/narrative/live_barks.json:4`; `render/core/main.gd:113`, `:366`, `:918` | none | minor | nice | narrative-identity (with ui-ux, tools-pipeline) | S (estimate) | no (claimed at `live_barks.json:3`; not run) |
| F-TEXT-03 | gap | The line check is hand-run only: not in CI, no saved result for the baseline. | `docs/narrative/line-lint.py:4`; no `docs/narrative/runs/`; no workflow names it | none | minor | nice | narrative-identity (with tools-pipeline) | S (estimate) | no |
| F-TEXT-04 | gap | The how-to card names keyboard keys ("Enter", "Esc", "F1") to a pad player. | `ui/data/howto.json:6`, `:7`; `ui/widgets/ui_howto.gd:481` | X-19 | minor | required | ui-ux | S (estimate) | no |
| F-TEXT-05 | gap | The title shows as plain "Orb Combat EX" with no working-title mark, while Legal's page allows that mark until the search is done. | `project.godot:8`; `ui/data/terms.json:92`; `export_presets.cfg:82`; `docs/legal/name-screening.md:186-187` | X-32 | minor | nice | legal-ip (with ui-ux) | S (estimate) | no |
| F-TEXT-06 | gap | KAI and VORR remain in data and code a player does not see, including a placeholder line file that only a translation tool reads. | `data/narrative/combat_barks.json:3`, `:21`, `:34`; `tools/l10n/strings.mjs:143`; `data/combat/recipes.json:5`; `render/vfx/glare.gd:23`; `sim/core/roster.js:5` | none | minor | after | narrative-identity (with vfx, simulation-engine) | S (estimate) | no |
| F-TEXT-07 | gap | Words for the set-aside meters and hiding are still in the word list, and F2 swaps in the old HUD with MENACE and ANGUISH bars. | `ui/data/terms.json:9`, `:80`; `render/core/hud.gd:228`; `render/core/main.gd:1546`; `ui/core/ui_sim_bridge.gd:9` | none | minor | nice | ui-ux (with rendering-techart) | S (estimate) | no |
| F-TEXT-08 | gap | The "no KAI or VORR on screen" check is hand-run, not in CI, with no saved run for the baseline. | `ui/tools/hud_check.gd:6634`, `:6654`; I-05 CI summary; `docs/ui/runs/` has no 6a30b4c9 folder | none | minor | nice | ui-ux (with tools-pipeline) | S (estimate) | no |
| F-TEXT-09 | gap | A few how-to lines are not plain or not true for a desktop tester ("the strip", "his", a web-and-clipboard privacy line). | `ui/data/howto.json:79`, `:75`, `:102` | X-19, X-32 | minor | nice | narrative-identity (with ui-ux, legal-ip) | S (estimate) | no |
| F-TEXT-10 | works | Names come from one data file (Grist, Loupe) and the UI swaps roster ids for them; no placeholder name in `ui/data/`. | `ui/data/fighter_names.json:5-6`; `ui/core/ui_data.gd:165`, `:189` | none | none | n/a | ui-ux | n/a | no |
| F-TEXT-11 | works | All 355 fighter lines trace to Orb by source tag; no banned word; every length break is Orb's own words or waived by id. | `data/narrative/live_barks.json:3`, `:5`; `docs/narrative/line-lint.json:8` | none | none | n/a | narrative-identity | n/a | no |
| F-TEXT-12 | works | How-to and hints are plain, data-driven text; the AI disclosure is on the About page; the music and voice lines stay hidden while their flags are off. | `ui/data/howto.json:15`, `:88`; `ui/data/features.json:8-9`; `ui/widgets/ui_howto.gd:37` | X-19, X-32 | none | n/a | ui-ux | n/a | no |
| F-TEXT-13 | works (off Orb's page) | The flashing-effects notice text exists as data and leads the strings list. | `ui/data/terms.json:92`; `docs/ui/strings.md:7` | X-19 | none | n/a | ui-ux | n/a | no |

Owner note: `data/narrative/` has no owns line in DIRECTORS.md (I-08, Notable 12). It is placed with narrative-identity because that charter's owned paths are `docs/narrative/` and `data/fighters/` (`DIRECTORS.md:347`) and the files say Narrative owns the text. `ui/data/` falls under ui-ux by path.

## Gaps the questions missed

- **The specification's own rule is stale** (4 to 12 words): Orb's current rule is 4 to 15 (`docs/narrative/line-lint.json:8`). Later phases should use 15.
- **Nothing automated guards text.** No CI job runs the line check, the strings list or the HUD check (F-TEXT-03, F-TEXT-08).
- **The old HUD is one key away** (F-TEXT-07): F2 is a keyboard key, so a Deck tester is unlikely to reach it; a Windows tester can.
- **The live line file also holds 118 lines for two fighters that come after Alpha.** That is not a gap; it only matters if the switch is turned on, where the emitter must speak for the two Alpha fighters only (not traced).
- **The pseudo-locale copies carry the same leftover words** (`localization/pseudo/ui/data/terms.json:27-28`, from I-05) and are outside the data check. Translation is not in the Alpha definition; noted only.

## Not evidenced

- Whether Orb has read the UI text in passing while playing. One thing settles it: Orb's marks on a short strings list.
- Whether the line check passes on the baseline file. One run settles it: `python docs/narrative/line-lint.py --live data/narrative/live_barks.json`, saved under a runs folder.
- Whether turning the lines on leaves the sim's state hash unchanged. One golden run with `enabled` true settles it.
- Whether captions for 15-word lines fit the Deck's 1280 by 800 screen. One still per longest line settles it (X-22's sweep).
- Whether the how-to's control rows match Orb's inputs on a Deck pad. One still of the Controls page on a Deck layout settles it (CONTROLS area).
- Where the title shows on the start menu with the Rail menus off.
- Whether the report file's header and the About page show a build version next to the title (X-29; not this area).

## Decisions for Orb

1. **Will you mark a short list of the text a tester meets before outside testers play?** Recommendation: yes. A cut-down list of about 150 strings (the notice, start menu, how-to card, match-over card, report panel), not all 1115.
2. **Should Grist and Loupe speak their approved lines in the Alpha?** Recommendation: yes, switched on in the tester build once the captions are checked on the Deck's screen; it is the cheapest way to show the personalities, and every line is already yours.
3. **Should the Alpha show "(working title)" beside the name?** Recommendation: yes, on the start menu and in the tester note, until the title search is done.
