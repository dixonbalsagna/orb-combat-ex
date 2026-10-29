# UI & UX: the computer's level on the start menu, and the Text size option (2026-10-28)

Brief: `docs/ep/cloud-briefs/ui-difficulty-textsize.md`, run locally (cloud sessions are retired). Gated in a scratch copy of HEAD 782aeef4 with my files and the one patch applied; the UI files are now in the shared tree, the patch is parked.

## SUMMARY
- **Difficulty.** A "Computer: Easy, Medium, Hard" row on the start menu, shown only with one player, Medium to begin with, saved with the menu choices (`ai_level`). It reaches the AI as the match setup's `aiLevel`; Medium is applied as the data's own level, so a Medium match is byte for byte the match of a setup with no level (proved over 900 ticks, and by determinism).
- **Text size.** Settings > Accessibility > Text size: Normal, Large (x1.25), Larger (x1.5). It scales the menus' and the match HUD's text; every screen that plans its own text still fits at the four PC sizes at each step, and no line the widgets draw crosses its card.
- Normal looks as it did, bar the two new rows (pixel comparison with main below).

## CHANGES
UI's own (in the tree):
- `ui/core/ui_text.gd`: `UiText.size_mult`; `px()` multiplies the ask and its floor by it. A test switch (`boxing`) keeps each drawn line's rectangle.
- `ui/core/ui_data.gd`: a numeric choice a saved file does not list snaps to the nearest listed one (text size, thickness).
- `ui/hud/ui_hud.gd`: `text_size` option applied in `set_option` (replans the layout) and at `_ready`; the menu config's `ai_level` (load, Left/Right, Enter, tap).
- `ui/widgets/ui_menu.gd`: the Computer row (`levels()` reads data/director/ai.json's `levels`, default its `level`), `rows`, `plan`, `draw`, `sig`.
- `ui/widgets/ui_settings.gd`: the key-hint line wraps when it does not fit (a Larger step is wider than the card); one line as written otherwise.
- `ui/widgets/ui_barks.gd`, `ui/widgets/ui_hints.gd`: at a step above Normal only, the set-piece lines step down to fit their letterbox and the control legend steps its words down (never below Normal's size) to keep its rows. Normal runs the old code.
- `ui/data/`: `terms.json` (`menu_ai`, `menu_ai_easy|medium|hard`), `options.json` (`text_size`), `settings.json` (the row after Color-blind mode; its three words). American English.
- `ui/demo/hud_demo.gd`: demo args `textsize=1.0|1.25|1.5` and `menu` (`menu=2`: two players).
- `ui/tools/hud_check.gd` (+9 checks), new `ui/tools/difficulty_check.gd` and `ui/tools/text_size_check.gd` (with their `.uid`).
- Docs: `docs/ui/start-menu.md`, `docs/ui/hud-spec.md` (table row, section 26 bullet).

Not UI's, parked: `docs/ui/pending/difficulty-textsize/ai-level-setup.patch` (README there). **Encounter's line, as the brief asks: the setup field only, no tuning.** It is the `aiLevel` read in `sim/core/sim.gd` `_mHead` (3 lines) and the host glue in `render/core/main.gd` (14 lines). `DirAI.level`, `levels` and the replay-header hash (`DirAI.skillText()` already folds the level in) were already there.

## GATES (scratch HEAD 782aeef4 + the UI files + the patch; each last line)
- `hud_check`: "hud_check: 5837 checks, 0 failed".
- `difficulty_check`: "difficulty_check: passed" (the sim reads each level and its numbers; Medium equals no level; Easy, Medium, Hard are three different matches; each level is the same twice; the host's Start and New match carry `aiLevel`, with and without the intro).
- `text_size_check`: "text_size_check: 2246 checks, 0 failed" (the option round-trips through save and load; `--negative-control`, steps 1.0 and 3.0: "1498 checks, 108 failed").
- `pseudo_switch_check`: "pseudo switch check passed: the default build reads ui/data", and with `-- --pseudo-locale`: "...the pseudo build reads localization/pseudo".
- `render/tools/determinism.gd` plain and `-- --intro`: "determinism passed" both. At each difficulty (a scratch copy with a `--level=` switch, not parked: `main._ai_level` for `--intro`, `DirAI.level` plain): easy, medium and hard, plain and `--intro`, six runs, all "determinism passed".
- `node tools/validate.js`: "279 files checked, 0 errors, 0 warnings"; `--self-test`: "self-test: 9724 of 9724 checks passed"; `node tools/lint-determinism.mjs`: "determinism lint ok: ..."; `npm test --prefix sim`: "all 5 stages passed"; `node tools/l10n/strings.mjs --self-test`: "strings self-test: all passed" (1190 to 1199 strings: the nine new data strings; the code-string count is unchanged, 364).
- Not run here, for the EP's set: the golden, the 19 render gates, World tools, QA, flash count, anim_check, split_sweep, campaign_episode, parity, sigvariants. UI changes no sim file; the patch's three sim lines act only when a setup has `aiLevel`.

## SCREENS THAT CHANGED, AND THE SCENES FOR THE SIDE-BY-SIDE
Changed at Normal: the start menu with one player (the new row), Settings (the new row; the key hint wraps only when it does not fit). Pixel comparison of main and the re-cut at Normal, 1280x720 and 1920x1080 (`?settings=0&nofeed`, `?three&prompts&nofeed`): the HUD and the Settings card are identical except the two fighters (they move) and four pixels of the scrollbar thumb (the list has one more row). Everything else changes only at Large and Larger, on every text screen and the match HUD.

Scenes (demo web build, `tools/machine/capture.mjs still --path "/index.html?<query>" --width W --height H`, W x H of 1280x720 and 1920x1080): `menu` and `menu=2`; `settings=0&nofeed&textsize=1.0|1.5`; `pause&textsize=1.0|1.5`; `three&prompts&nofeed&textsize=1.0|1.25|1.5`. Mine, already made, in `docs/ui/img/difficulty-textsize/` (left, right): `sbs-menu-main-vs-new-*` (main, new), `sbs-menu-normal-vs-larger-*`, `sbs-settings-normal-vs-larger-*`, `sbs-settings-main-vs-new-normal-1280`, `sbs-match-normal-vs-larger-*`, `sbs-pause-normal-vs-larger-1280`.

## DECISIONS
1. **`aiLevel` is one level for the match** (a string), not the per-slot `[n, n]` that core-backlog.md plans: `DirAI.level` is one static. Per-slot is a later step for Encounter and Simulation; the key's name stays.
2. **Medium is "".** `_mHead` maps the data's own level (and any level the data lacks) to `DirAI.level = ""`, so nothing a Medium match hashes or plays changes. The menu always sends the level once it has run, so a New match after a Hard one stays Hard; a match started without the menu (tools, tests) sends none and runs as before.
3. **The row shows only with one player.** Two players are two humans; the pause menu's "hand back to the AI" uses the level the menu chose.
4. **The option is numeric** (1.0, 1.25, 1.5), as thickness is, so the multiplier is data and not a table in code. The steps are Orb's to change in `options.json`.
5. **The floor scales, the fit does not.** A text asks for its size times the step, and its floor times the step (14 px at Normal, 21 at Larger); where it does not fit it still steps down toward the unscaled floor. So a bigger step never cuts what Normal shows whole, and a screen that wraps (menus, cards, Settings) grows instead.
6. **Normal is guarded:** the barks and hints changes run only above Normal, so those two widgets cannot move a Normal pixel.

## NEEDS FROM EP
1. Land `ai-level-setup.patch` with the UI files (Simulation owns `sim/core/sim.gd`, Rendering `render/core/main.gd`; the 3 sim lines are Encounter's setup field only). `difficulty_check` fails in the tree until it lands.
2. The look gate: the scenes above, and both flash modes. No effect or flash code changed.
3. Accessibility: `node tools/l10n/pseudo.mjs --write` for the nine new strings. `tools/l10n/overflow_check.gd` after the change: 30 to 36 layouts that fit in English but not in the pseudo-locale, all the 1-player start menu at phone sizes (2400x1080, 2532x1170, 390x844, touch or not; English fits); and "English helps cut" is one higher (the new help is long; the tool counts the old two-line rule, the Settings foot now grows for it).
4. Game Design and Encounter on the start-menu choice (it stays proposed until they weigh in): the build is ready and the default is Medium.

## RISKS
- **The control legend loses rows at Large and Larger.** The bark lane under it grows with the text, and the column between has less room: at 1280x720 and 1920x1080 Larger shows 4 of its 6 rows (Normal 6), at its Normal word size or a little more. How to play still lists everything. Say if the lane should hold its Normal height.
- **The fixed plates and lanes of the match HUD** hold their shapes: names and charge bars stay inside (the check proves it on three mock scenarios, 8 s each, at four sizes), but the charge bar is shorter at Larger, and the text there steps down toward the floor in the tightest places.
- **`DirAI.level` is a process static.** A tool that starts a match without `aiLevel` after one with it inherits the last level. The game's own host always sends it after the menu.
- **Phones:** the extra row costs the 1-player menu room at phone sizes in the pseudo-locale (item 3). ADR 0011 parks phone layout; hud_check's phone sizes pass.
- The text-size check samples the match HUD (3 scenarios, every 20th frame) and draws each screen it names; a text drawn only in a state those do not reach is not covered.

## NEXT
- The hold toggles with Controls, aimed at PC.
- Idle and frozen on these files until the EP confirms the commit; then delete `docs/ui/pending/difficulty-textsize/`.

## ADDENDUM (EP's two asks, after hold-toggles landed as 5d26c626)
- **Collapse flash clip, both modes, `tools/flash/check-clip.mjs --clip collapse-normal,collapse-reduced`** on a web export of HEAD 5d26c626 plus my files and `ai-level-setup.patch` (it applies with offsets of 3 and 5 lines), against a web export of HEAD alone (the tool's own `--head` failed with "git archive HEAD failed", so both were exported from scratch trees and passed with `--site`):

  | clip | build | ticks | general | red | area-15% | 2 s mem | margin | dips | verdict |
  | :-- | :-- | --: | --: | --: | --: | --: | :-- | --: | :-- |
  | collapse-normal | HEAD | 1500 | 2 | 0 | 2.5 | 1 | 0/4 | 0 | PASS |
  | collapse-normal | HEAD + difficulty-textsize | 1500 | 2 | 0 | 2.5 | 1 | 0/4 | 0 | PASS |
  | collapse-reduced | HEAD | 1500 | 2 | 0 | 2.5 | 1 | 0/4 | 0 | PASS |
  | collapse-reduced | HEAD + difficulty-textsize | 1500 | 2 | 0 | 2.5 | 1 | 0/4 | 0 | PASS |

  Same numbers in both builds. Each run took about five minutes at below-normal priority; no other capture ran beside it.
- **Pseudo-locale:** `node tools/l10n/pseudo.mjs --write` ran in the tree (options.json, settings.json and terms.json in `localization/pseudo/ui/data/`: my 9 strings and Controls' 8 rows); `--check` now says "pseudo-locale is current (10 files)".
