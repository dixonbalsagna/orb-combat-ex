# Accessibility & Localization, cloud report: the foundation (2026-10-28)

Branch `cloud/accessibility-localization/foundation`, from origin/main 767ed0d. Brief: `docs/ep/cloud-briefs/accessibility-foundation.md`. Nothing the player sees by default changed; no file outside my paths was edited.

## SUMMARY
The HUD's accessibility groundwork is strong (no colour-only cue, three colour-blind presets, remapping, an energy toggle, latched charges, reduced motion, the notice and its lock). The real gaps: no volume controls, no difficulty choice (three AI levels exist in data, none is reachable), no text-size option, Guard, Transform and three stances are hold-only, and captions have nothing to caption because no live line is emitted. The audit is `docs/accessibility/audit-2026-10-28.md`. For translation there is now a string inventory (1,177 strings; 39 hard-coded literals reach the default build), a pseudo-locale with an overflow check against the real layout and font, and a plan in `docs/accessibility/l10n-plan.md`.

## CHANGES
- `docs/accessibility/audit-2026-10-28.md`: the audit, ten checklist items, each with what exists (file and key), what is missing, priority and owner.
- `docs/accessibility/l10n-plan.md`: the format (PO for translators, JSON overlays at runtime), contributions, fonts per script, right-to-left text, what must change first, effort.
- `tools/l10n/strings.mjs`: the inventory (`--json`, `--md`, `--self-test`): ui/data text leaves, barks and captions, and GDScript literals that reach the screen (draw and banner sinks plus a hand-read list), each with key, file, surface, reach, length, and flags hard-coded, built from parts and Legal.
- `tools/l10n/pseudo.mjs`: the pseudo-locale (`--write`, `--check`, `--self-test`): accented, about 40% longer, bracketed; placeholders, formats, ids and Legal's eleven cleared lines untouched.
- `localization/pseudo/ui/data/*.json` (10 files): its output, so a build can load it. `localization/` is my charter's path; the brief named `tools/l10n/`, but `tools/*` is excluded from every export (`export_presets.cfg`), so the data cannot live there.
- `tools/l10n/overflow_check.gd`: a Godot report (not a gate) that lays out each screen through the widgets' own `plan()` with English, then with the pseudo-locale, and checks the font's script coverage. It swaps UiData's tables in its own process only.

## DECISIONS
- Translators work in gettext PO (Poedit, Weblate, plain pull requests); the game reads per-language JSON overlays of `ui/data` built from them, through one hook, so a missing key falls back to English per string.
- Supported languages: none promised. The first are whichever Latin, Greek or Cyrillic languages get a volunteer translator and reviewer, since the built-in font already draws them. CJK, Arabic, Hindi and Thai wait for a volunteer and a font register row.
- Legal's cleared lines stay English in every locale until Legal clears a translation; the tools keep them byte-identical (`pseudo.mjs` self-test checks it).
- The pseudo-locale is a command-line opt-in, not a feature flag, so `UiData._read` needs no flag lookup (features.json is itself read through `_read`).

## NEEDS FROM EP
1. **UI: the pseudo-locale switch** (off by default). In `ui/core/ui_data.gd`, the first lines of `_read`, and one new static var and function:
   ```gdscript
   ## The pseudo-locale (tools/l10n/pseudo.mjs, docs/accessibility/l10n-plan.md): off unless the build is started with
   ## "-- --pseudo-locale". Then a ui/data file with a twin under res://localization/pseudo/ is read from there instead.
   static var pseudo_locale: int = -1   # -1 not read yet, 0 off, 1 on

   static func _locale_path(path: String) -> String:
   	if pseudo_locale < 0:
   		pseudo_locale = 1 if OS.get_cmdline_user_args().has("--pseudo-locale") else 0
   	if pseudo_locale == 1 and path.begins_with("res://ui/data/"):
   		var p: String = "res://localization/pseudo/" + path.trim_prefix("res://")
   		if FileAccess.file_exists(p):
   			return p
   	return path
   ```
   and in `_read(path)`, as its first line: `path = _locale_path(path)`.
   Look evidence pending (local) only if the EP wants a pseudo side-by-side; the default build does not change.
2. **Tools**: decide whether interim and public exports exclude `localization/*` (about 100 KB; the switch is useless there). Widen the British-spelling scan to the hard-coded strings `strings.mjs` finds (it misses "Licence" in `ui/widgets/ui_licences.gd`) and to "manoeuvre" and "armour" (`ui/data/stances.json`, `terms.json` `card.hatch_open`). Legal to rule on those two words.
3. **Audio and UI: volume controls** (master, effects, voice, music later; a mono switch). P1 in the audit: the cheapest, most expected option, and missing.
4. **Encounter and UI: a difficulty choice** on the start menu for `data/director/ai.json` `levels` (easy, medium, hard).
5. **Controls and UI: toggles for every required hold** (Guard, the defensive, charging and manoeuvre stances, Transform's half-second hold), as `energy_style` does for Energy. Game Design to say whether a toggled guard needs a balance change.
6. **UI: Settings help that is never cut.** The colour-blind help ends in "..." at 1920x1080 (`ui/widgets/ui_settings.gd`, the foot's two lines); let the foot scroll or grow. Also a text-size option and the contrast-per-role numbers the HUD spec lists as open.
7. **Simulation, Encounter and UI: the sim's banners as ids** (27 literal pieces in `sim/core/` and `sim/director/`) so they can be translated. Note: the JS parity lockstep compares banner text tick by tick (`npm test --prefix sim`), so this touches the oracle too. Not urgent before a first language.
8. **Narrative and Encounter: the bark emitter.** The Captions option has nothing to caption until lines are emitted; Audio to caption the grunts.

## RISKS
- The overflow check reads widgets' `plan()` outputs and private UiData statics; a UI refactor can break it (it is a report, nothing gates on it).
- `strings.mjs` finds code text through sinks and a hand-read list; a new draw path that passes text through a variable is missed until added to `INDIRECT`. The pseudo build shows such strings as plain English, which is the backstop.
- `docs/ui/strings.md` (UI's table) shows the old notice words; it is stale, not live.
- Translated move and fighter names need Legal's search per language; contributions need a licence term before any is accepted.

## NEXT
Land the switch (need 1), then run a pseudo build locally to catch what the static check cannot (plates, legend, prompt row). Then write `docs/accessibility/checklist.md` from this audit for the P5 gate, and `pot.mjs` when the first volunteer appears.

## Gates (this tree)
GATES_PLACEHOLDER
