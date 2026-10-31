# UI & UX: Orb's four names on the screen (2026-10-30, RL-211)

Brief from the EP: wire Grist, Loupe, Empress Orza and Bolus into `ui/data/fighter_names.json`. Gated in scratch copies of HEAD 523de5d5 plus these files. Files are in the tree (unstaged).

## SUMMARY
`protagonist` is Grist, `rival` is Loupe, `empress` is Empress Orza, `cyborg` is Bolus. Roster ids PROTAGONIST and RIVAL stay in the data. Plates, speaker tags, set-piece names, the feed, the KO and the feedback report read the table. No craft note anywhere in player text.

## CHANGES
- `ui/data/fighter_names.json`: the four rows (titles and signature names unchanged; the Empress and the Cyborg have none); note updated.
- `ui/core/ui_data.gd`: `display_text` shows a name in capitals only when the whole text has no lowercase letter (the sim's banners: `K.O.  GRIST WINS`); a sentence gets the name as written.
- `ui/mock/ui_mock_feed.gd`: demo scenes pass roster ids (EMPRESS, CYBORG, RIVAL) so they show the table. The live demo is pinned and does not change.
- `ui/tools/hud_check.gd`: the name expectations moved (10 tests) and +1 check: all four names whole on the plate beside badge, word and tag, 844x390 to 4K. `ui/tools/text_size_check.gd`: samples `empress_vs_cyborg` too.
- `localization/pseudo/ui/data/fighter_names.json` regenerated (only that file changed); `docs/ui/strings.md` (826 strings); `docs/ui/hud-spec.md` section 69; side-by-sides in `docs/ui/img/core-four-names/`.

## GATES (last lines)
- `hud_check`: "5871 checks, 0 failed". `text_size_check`: "2402 checks, 0 failed". `render/tools/hud_words_check.gd`: "hud words check passed".
- `node tools/validate.js`: "283 files checked, 0 errors, 1 warning" (the warning is `data/anim/lead_in.json`, not UI's). `strings.mjs --self-test` passed; `pseudo.mjs --check`: current (10 files). `tools/site-interim-selftest.mjs`: "251 checks" ok (the RL-192 string checks: no in-game notice or settings string changed).
- Determinism plain and `--intro`: "determinism passed" both.
- Collapse clip, web export of HEAD against HEAD + files, both modes: PASS, general 2, red 0, area-15% 2.5, 2 s memory 1, 0 dips, in both builds (identical rows).
- Look: `sbs-hero_vs_proud-head-vs-names-1280.png`, `sbs-empress_vs_cyborg-head-vs-names-1280.png`: only the name text changes (plates, speaker tag). "Empress Orza" fits its plate with the CPU tag.

## WHAT ELSE PRINTS A ROLE NAME
- No menu, caption, How to play page or Settings string names a fighter (grep of `ui/data`: only the English word "rival").
- The title under a name still reads Martial Artist and Challenger (placeholders; Rendering's label over a head shows it); the Empress and Cyborg have none. Orb's to set.
- Barks and feed lines Narrative writes in capitals as a roster id are replaced; a name written by hand in mixed case is literal.
- Narrative's beat templates (`docs/narrative/beat-templates.md`) are docs only: no code reads them yet. Their `opp`, `p1`, `p2` slots are roster ids and the doc says the display name comes from the names file, so a renderer that goes through `UiData.display_name` / `display_text` picks the table up. Voice and bark data are keyed by roster id (PROTAGONIST, RIVAL) and unchanged.

## NEEDS FROM EP
None. `terms.json` of the pseudo copies is current now (51d8cc44).

## RISKS
- Names are mixed case on plates where the placeholders were capitals; banners keep capitals. Say if Orb wants capitals on plates.
- Render-internal keys (look.gd, glare.gd) still use ids; they are not drawn.

## NEXT
Idle and frozen on these files until you confirm the commit.
