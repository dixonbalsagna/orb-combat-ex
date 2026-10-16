# Plain words in the HUD and menus (UI, 2026-10-16)

Orb, homework 4: "definitely needs editing and language improvement. 'The bolt's land' and 'ink on the dark scrim' read as nonsense." The rule: every word a player sees is one a player would say; no team nouns.

## Done this round

- **The teaching sheet** (`docs/ui/img/brawl-teaching-mock.png`): every heading, caption and label rewritten ("TAP: press just as your hit lands", "When he misses, he is open for a moment", "Your energy shot lands: a mark by the energy button says what happened", "FINISH" for the old CLOSE). No ticks, chips, cues, registers, scrims or pixel counts.
- **On the plate and legend:** RESTING became RECHARGING; "launcher ready / resting" became "launch ready / recharging"; BOLT became SHOT; RELEASE became CHARGED; a shot's result words became HIT, BLOCKED, ABSORBED, MISSED.
- **How to play, Reading the fight:** the ring and card lines joined and reworded; "brink", "finisher", "chip" gone from it ("A faint ring: he is nearly beaten. A finishing move can end it.", "The box at the top counts the damage to the world.").
- **Options:** Info flashes, Always show damage rings (was "wear crown"), Hit pause (no "ticks"), Effects quality, Vibration, Damage ring thickness, Reduced motion, Colour-blind mode.

## Left for Narrative (they own the words; I changed only the clear cases)

- **Fighter-specific cards:** FACADE CRACKS, HATCH OPEN: {station}, CHIP: {stage}, REVISION (the Cyborg's body cards), BOILED and the shame lines: they are character words; Narrative to say what a player would call them.
- **Short labels that are game terms:** SIGN, CONTEXT, FORM, SPECIAL on the touch buttons; PRIDE and RESPECT as meter names; BRINK on the plate; MELEE and FINISHER on the finisher card; "stance" in How to play. They read as words but may not be plain to a first-time player.
- **The About and licence pages** are Legal's and Narrative's.
- **Strings still marked by Orb's batches** are in `docs/ui/strings.md`; nothing new ships unmarked.

## Narrative's words, merged and applied (2026-10-16, `docs/narrative/plain-words.md` v1; the EP's go)

Narrative's recommended word for each, as they proposed them; **Orb's calls stay open** (Narrative's four questions for Orb: RATTLED or more edge, WEAK SPOT or keep CHIP, NEARLY BEATEN or ON THE ROPES, the move's name or the kind on the buttons). Where Orb chooses another word it is one line in `ui/data/terms.json` (and, for ACTION, `hints.json` and `howto.json`).

| Was | Now | Where |
| :-- | :-- | :-- |
| FACADE CRACKS | RATTLED | the Anti-hero's card |
| HATCH OPEN: {station} | ARMOUR OPEN: {station} (HEAD, CHEST, BACK, HIP stay) | the Cyborg's card |
| CHIP: {stage} | WEAK SPOT: {stage} | the Cyborg's card. **It fits:** a narrow card splits at the colon (WEAK SPOT over SCRATCHED); drawn whole or split at four sizes down to 360x640 in `_plain_words_rules` |
| REVISION | NEW FORM | the Empress's card |
| ON THE BRINK, BRINK | NEARLY BEATEN | the card and the state word |
| CORE: BOILED OVER | CORE: OVERHEATED | the card |
| TRAIL LOST | LOST HIM | the hiding card (hiding is off today) |
| CHAIN ×{n} | COMBO ×{n} | the plate chip and the banner. **The "stray character" was the multiplication sign (U+00D7), a proper character that Open Sans draws; the console shows it as a box.** Nothing to fix |
| MELEE (finisher kind) | BLOWS | the finisher card |
| SIGN, CONTEXT, FORM (Full touch) | SIGNATURE, ACTION, TRANSFORM | the buttons |
| Context (legend, How to play, Settings) | Action (a grab and a throw: it depends on your stance) | the legend row, the controls page, Remap |

Kept as Narrative advised: PRIDE, RESPECT, WRATH, HUNGER, FINISHER (in running text "finishing move"), SPECIAL, LAST STAND, the rally words, and "stance" (How to play defines it on its own page).
