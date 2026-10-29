# UI & UX: RL-206, the toggle words, and the level in the replay header (2026-10-29)

Three items from the EP after difficulty-textsize landed (b6df7059). Gated in a scratch copy of HEAD 40d5ee92 with these files. UI's files are in the tree (unstaged); one patch is parked.

## SUMMARY
1. **RL-206 done (one line, UI's).** `UiHud.bypass_allowed()` is false in any build whose Reduce flashing lock is on, unless it is the measurement export (`capture_hook` on). Desktop or web, local host or not. So the six words (bench, frames, shot, nonotice, flashcap, study) no longer skip the notice in a locked build, and the host's `gate_args` drops its `LOCAL_ONLY_ARGS` there (the study route, the capture hook and the developer look switches: the set a public page already drops).
2. **Toggle words done (legend, Remap, strings.md).** For a player whose style is toggle the words say toggle and press; read from UI's own `guard_style`, `manoeuvre_style`, `charge_style`, `transform_style`, `energy_style` and their `_p2` (the options the host forwards to the hub), never written.
3. **The level in the header: yes, it needs its own line.** Measured, with a fix parked (below).

## CHANGES
- RL-206: `ui/hud/ui_hud.gd` (`bypass_allowed`, 3 lines + comment); `ui/tools/hud_check.gd` (+18 checks: each of the six words with the lock off as the control, with the lock on, and with the lock and the capture hook on).
- Legend: `ui/data/hints.json` (18 `label_toggle` words on the Guard, Power and Dodge rows), `ui/data/stances.json` (`_legend_toggle`, `_remap_toggle`, `_remap_help_toggle` for Defensive, Charging, Manoeuvre; Energy gets the last two), `ui/widgets/ui_hints.gd` (`STYLE_OPTION`, `styles()`, `rows(.., styles)`, `sig(.., styles)`), `ui/core/ui_stance.gd` (`remap_words(action, toggle)`), `ui/hud/ui_hud.gd` (the options in `_o()`, the sig call, `_rm_toggle`, the Remap rows).
- Remap helps: `ui/data/settings.json` `remap.helps_toggle` (guard, dodge, power, mode, transform).
- Schemas: `tools/schemas/ui-hints.schema.json` (`label_toggle`), `tools/schemas/ui-settings.schema.json` (`remap.helps_toggle`).
- `docs/ui/strings.md` regenerated whole (`python ui/tools/strings_inventory.py`): 816 strings; it was out of date (it still read the old notice words), so the diff is large. `docs/ui/hud-spec.md` section 68.
- `localization/pseudo/ui/data/`: `hints.json`, `settings.json`, `stances.json` regenerated for the new words.
- `hud_check` +30 checks for the toggle words: legend rows on every preset and Simple, player two reading `_p2`, the redraw signature, the stance legend, and Remap for a hold player, a toggle player, player two's screen and a live stance.

## THE LEVEL IN THE HEADER (item 3)
Measured: `SimReplay.dataHash({"aiLevel": "hard"})` is `2394210b3445674e` before any match in a process and `fa88651557e01d17` after a Hard match started first; after an Easy match in the same process it is still `fa88...`. So a replay recorded as the first match of a process at Easy or Hard has a header a fresh process will not reproduce (it is refused as "made on other data"), and in one process Easy and Hard have the same header. The replay carries `setup.aiLevel` and `newMatch` applies it, so only the header is wrong. **Yes, the header needs the level on its own, taken from the setup.**
Fix, parked: `docs/ui/pending/ai-level-hash/` (README, `ai-level-hash.patch`, 41 lines, against HEAD b6df7059). `DirAI.skillText()` stops adding the level; new `DirAI.levelOf(setup)`; `SimReplay.dataHash(setup)` folds it in only when it is not the data's own level. Checked: Hard `26439ef2b95740ba` before and after a match, Easy `3e864e230c55a3e6`, Medium or no key `2394210b3445674e` (what HEAD gives for no key), so no existing hash moves. Owners: `sim/director/ai.gd` Encounter, `sim/core/replay.gd` Simulation; Netcode to confirm the handshake compares `SimReplay.dataHash(setup)` of the session's setup.

## GATES (scratch HEAD 40d5ee92 + these files; last lines)
- `hud_check`: "hud_check: 5867 checks, 0 failed".
- `text_size_check`: "text_size_check: 2390 checks, 0 failed". `difficulty_check`: "difficulty_check: passed". `pseudo_switch_check`: passed plain and with `-- --pseudo-locale`.
- `node tools/validate.js`: "280 files checked, 0 errors, 0 warnings"; `--self-test` and `node tools/lint-determinism.mjs`: ok; `node tools/l10n/pseudo.mjs --check`: "pseudo-locale is current (10 files)" (in the scratch tree).
- `render/tools/determinism.gd` plain and `-- --intro`: "determinism passed" both.
- Not run, for the EP's set: the golden, the render gates, World tools, QA, flash count, anim_check, split_sweep, campaign_episode. No look changes at Normal for a hold player: the legend rows and Remap helps for hold are the old words, and the toggle words show only to a player who chose toggle (the Settings rows with them are Controls').

## NEEDS FROM EP
1. **Tools, for RL-206's package check:** `tools/desktop-package.mjs` already reads `BYPASS_WORDS` from `ui_hud.gd` (about line 182). It should also require that `bypass_allowed()` begins `if UiData.rf_locked() and not UiData.feature("capture_hook"):` then `return false` (regex over the source, same place), and `tools/desktop-package-selftest.mjs` needs the negative control: the same function without those two lines is reported. I did not touch Tools' files.
2. Route the level-header patch (Encounter, Simulation, Netcode as above).
3. A locked desktop build now drops `LOCAL_ONLY_ARGS` (`--nointro`, the sky and look switches, `farmap` and the rest) as a public page does. If Orb's own desktop play wants any of them, say which; the menu's Intros box covers `nointro`.
4. Pseudo-locale: in the shared tree `node tools/l10n/pseudo.mjs --check` reads `terms.json` as stale and `--write` accents Legal's notice lines (a clean HEAD export reads current). I left `terms.json` at HEAD. Something in the tree differs from the HEAD export for that tool (Legal's fixed-lines file moved after b6df7059); not mine to settle.

## RISKS
- How to play still says "(hold)" in its table for everyone (one card for both players); the brief named the legend, Remap and strings.md. It is a small follow-up if wanted.
- Transform's legend row never said hold, so a toggle player's legend is unchanged for it; only Remap's help says press.
- The legend's width is set by its longest label: "Dodge, sprint (toggle)" is the longest word now.

## NEXT
Idle on these files until you confirm the commit.
