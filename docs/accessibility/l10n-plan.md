# How Orb Combat EX would be translated

Owner: Accessibility and Localization. 2026-10-28. A plan for a free, zero-budget, open-source game (ADR 0005). Nothing here is turned on; the tools exist and the build hook is a request to the EP.

## Where the text is today

`node tools/l10n/strings.mjs` lists every player-facing string. In the default build:

| Source | Strings | Words | Characters |
| :-- | --: | --: | --: |
| `ui/data/*.json` (the HUD, menus, Settings, How to play, hints) | 747 | 3,850 | 21,546 |
| Hard-coded literals that reach the screen (sim banners, boot line, licences page, two glyph labels, a unit) | 39 | 67 | 397 |
| Barks and captions in data, not shown yet (`data/narrative/combat_barks.json`, `audio/data/babble_captions.json`) | 70 | 355 | 1,886 |
| Debug only (F2 old HUD, `--keyhelp`, the F4 director feed) | 321 | 976 | 5,315 |

So one language is about **3,900 words now**, 4,300 when barks ship. The debug text is never translated.

The UI's rule already helps: "Every player-facing word is data in `data/terms.json`" and "The HUD never builds a sentence from parts" (`ui/README.md`, `ui/data/terms.json` `note`). The gaps are the 39 literals, 41 English fallbacks in code (`dict.get("key", "Words")`, shown if a translation lacks the key) and the points under "What must change first".

## The file format

**Source of truth stays where it is**: the English JSON in `ui/data/` (UI owns it; Narrative writes the words). Translators never edit it.

**Translators work in gettext PO files**, one per language: `localization/<lang>.po`, made from a template `localization/orb-combat-ex.pot`.
- PO is what free translation tools speak: Poedit (desktop, free), Weblate, and plain text in a GitHub pull request. Godot reads PO natively too, should we ever want `tr()`.
- Each entry's `msgctxt` is the inventory key (`terms:prompt.menu_start`), so two identical English strings can be translated differently by context. The extracted comment carries the surface, the English length and a length budget (English length x1.4, from the pseudo-locale), and "LEGAL: do not translate without Legal" where it applies.
- Plurals use PO's `msgid_plural`. Seven strings take a count today (`terms.json` `card.last_stand_sub`, `prompt.over_civilians`, `over_craters`, `over_structures`, `state.chain`, `state.last_stand`, `state.signature_need`); Polish, Russian and Arabic need more than two forms for them.

**The game loads translations as overlays**, the same way it loads the pseudo-locale: a node tool turns `<lang>.po` into `localization/<lang>/ui/data/*.json` with the shape of `ui/data`, and `UiData._read` reads the overlay file when the chosen language has one. One hook in `ui/core/ui_data.gd` serves every language, missing keys fall back to English per string (so a half-done translation still works), and the runtime never parses PO. Tools to write when the first language starts: `tools/l10n/pot.mjs` (inventory to POT) and `tools/l10n/apply-po.mjs` (PO to overlay), both reusing `strings.mjs` and `pseudo.mjs`'s `build()`.

## The pseudo-locale switch

`node tools/l10n/pseudo.mjs --write` makes `localization/pseudo/ui/data/*.json`: every string accented, about 40% longer, bracketed. Legal's eleven cleared lines stay English. The switch, off by default, is a command-line option: `godot --path . -- --pseudo-locale`. Its hook is UI's file, so it is under NEEDS FROM EP in the report. In a pseudo build:
- plain English on screen is hard-coded text (it bypassed `ui/data`);
- a missing closing bracket is text cut off;
- `godot --headless --path . --script res://tools/l10n/overflow_check.gd` lays out each screen with English and with the pseudo-locale and lists what stops fitting.

What the check found (2026-10-28, nine viewports from hud_check's lists):
- **How to play** does not fit at 2532x1170 (a phone in landscape) or 360x640 in the pseudo-locale, on all seven pages; in English it fits only by shrinking its type to x0.67 at 1280x720 and x0.45 on small windows.
- **Settings help** ends in "..." for 10 rows at 1920x1080 (3 in English), 23 at 1024x576 (10 in English).
- **The start menu** fails at 390x844 in the pseudo-locale and already fails at 360x640 in English.
- **Wound cards**: 4 of 51 titles do not fit at the text floor on small windows (390x844, 360x640); none in English.
- **The banner**: "NEED 45 CHARGE" at +40% is wider than the gap between the plates at 360x640.
- Fit everywhere: the notice, the pause menu, Settings' controls, feedback, loading, turn-your-phone, the join line.
- Not checked (no layout function to call without a live fighter): the plates, the control legend, the prompt row, the stances table.

## Fonts and scripts

The game has one font: Godot's built-in fallback, Open Sans SemiBold (`docs/ui/font-note.md`; nothing is bundled). `overflow_check.gd` asks it for sample text in each script:

| Script | Languages | Open Sans today | Free font to add |
| :-- | :-- | :-- | :-- |
| Latin, incl. Vietnamese | Spanish, Portuguese, French, German, Italian, Polish, Turkish, Czech, Vietnamese | all drawn | none needed |
| Greek, Cyrillic | Greek, Russian, Ukrainian | all drawn | none needed |
| Hebrew | Hebrew | glyphs drawn; needs right-to-left layout (below) | none needed |
| Arabic | Arabic, Persian | none | Noto Sans Arabic (SIL OFL 1.1) |
| Devanagari | Hindi | none | Noto Sans Devanagari (OFL) |
| Thai | Thai | none | Noto Sans Thai (OFL) |
| Han, kana, Hangul | Chinese, Japanese, Korean | none | Noto Sans CJK SC, JP or KR (OFL), subset to the glyphs used |

Every added font needs Legal's register row first (`docs/ui/font-note.md`, LR-004). They join as fallbacks behind Open Sans (`UiText.font` with Godot's font fallbacks), loaded only with their language. CJK fonts are 15 to 20 MB uncut; subset to the strings we ship they are well under 1 MB, which matters for the browser build and old laptops (Performance's budget).

## Right-to-left text

Godot's official builds shape text with the advanced text server (HarfBuzz and ICU bidi), so a Hebrew or Arabic string draws in the right order inside one `draw_string` (not yet checked against our web template). What our code does not do:
- `UiText.draw` splits a line at "→" and draws the pieces left to right; `UiText.wrap` breaks by spaces and lines start at the left. RTL needs right-aligned blocks and reversed piece order.
- Widgets place text from the left edge in many places (Settings labels, How to play, the notice).
- The layout itself must **not** mirror: player one on the left and player two on the right is the game's geometry, not reading order.

Estimate below. Recommendation: no RTL language until a volunteer for one exists.

## Community contributions

- **The licence comes first.** The game is "all rights reserved for now" (`docs/legal/page-fixed-lines.md`). A volunteer's translation is their own copyright unless they grant it. Before the first translation is accepted, Legal sets a contribution term (a sign-off line in the pull request, or a short agreement) that fits whatever licence Orb picks. Hosted Weblate's free plan also needs an open licence, so until then contributions come as PO files in GitHub pull requests.
- **Legal's cleared lines are not translated by volunteers.** The flash notice, the lock line, the two buttons, the AI line and the privacy line (`docs/legal/page-fixed-lines.md`) show in English in every language until Legal clears a translation of each, per language. The tools keep them byte-identical.
- **Names**: fighter, place and move names were screened in English only. Narrative decides which are kept as names and which are translated; a translated move name needs Legal's search in that language.
- **Review**: each language needs two people, a translator and a reviewer who plays it. A pseudo build and `overflow_check.gd` run on the overlay before merge; the EP merges.
- **Which languages**: none promised. The pipeline is built for the scripts the font already draws (Latin, Greek, Cyrillic), so the first languages are whichever of those get a volunteer pair. CJK, Arabic, Hindi and Thai wait for a volunteer and a font row.

## What must change first (other directors' files, through the EP)

1. **The sim's banners become keys.** 27 literal pieces in `sim/core/` and `sim/director/` (`SimFx.banner(S, "GUARD BREAK", ...)`, and banners built from parts such as `f.name + " POWERS UP  TIER " + ...`). The sim should emit an id and its numbers, and UI look up the words. The sim must not change behaviour; whether banner text is in the golden hash needs Simulation's check.
2. **The HUD stops making words in code**: `UiData.banner()`'s " KI" to " CHARGE" replace, `ui_stance.gd`'s `+ " (hold)"`, the "s" unit in `ui_incoming.gd`, the Start and Back glyph labels in `ui_glyphs.gd`, the licences page headings in `ui_licences.gd`, the boot line `RenderLook.BOOT_WORDS`.
3. **Upper case is data, not code.** Banners are upper-cased in code (`ui_event_hub.gd`, `UiData.banner(...).to_upper()`). That is wrong for Turkish (i to İ), German (ß), and meaningless for scripts without case. Store the upper-case form in the data.
4. **Sentences with inserted words.** The remap lines put "the east button" into "{control} is already {other}" (`settings.json` `remap.conflict`, `remap.controls`). In languages with case and gender that needs whole sentences per control, or a neutral form ("Button: east").
5. **A language choice** in Settings and the start menu, saved with the other options.
6. **English fallbacks** in code (41, `strings.mjs` counts them) stay as a safety net, but hud_check should fail when a fallback is the only source of a word.

## Effort

Engineering (once, by owner):

| Work | Owner | Estimate |
| :-- | :-- | :-- |
| Overlay hook in `UiData._read` and a language option | UI | 1 day |
| `pot.mjs`, `apply-po.mjs`, plural support | Accessibility and Localization | 2 days |
| Sim banners to ids; HUD words out of code (items 1 to 4) | Simulation, Encounter, UI | 2 to 3 days, plus the golden check |
| Text that can grow: How to play and Settings help that scroll instead of shrinking or cutting | UI | 2 days |
| A font fallback chain and per-language loading | UI, Legal (register), Performance (web size) | 1 day per script family |
| Right-to-left text in `UiText` and the widgets | UI | 3 to 5 days |

Per language (volunteers): about 3,900 words, roughly three to five evenings to translate and two to review, plus a pseudo and overflow pass, plus Legal's clearance of the notice in that language. On a Pro plan with zero budget the binding cost is people, not tools.
