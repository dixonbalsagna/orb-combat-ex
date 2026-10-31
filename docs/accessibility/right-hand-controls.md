# Right-hand attacks: what accessibility needs to hold (2026-10-30)

Accessibility & Localization, for the EP. Orb's rule: "accessibility settings and customizable controls should be assumed, including left-handed folks who may want to swap their controller around." Read: `docs/controls/right-hand-attacks.md` (CRL) and `docs/design/right-hand-attacks-rulings.md` (GDR), against `docs/accessibility/audit-2026-10-28.md`, `docs/controls/remap.md` and `hold-toggles.md`. Paper only. Gate tags: P2, P3, P5 as in the audit.

## What must hold

1. **Roles, not hands.** The new design speaks of a "left hand" (defend: slip, brace, vanish) and a "right hand" (hurt: strikes, beams, signature). Every setting, string and picture says **defence hand / attack hand** or the control's name, never "left" or "right". A swapped layout then changes only where the roles sit. (Only `ui/data/howto.json` line 43, the touch text, says "Left thumb" today.)
2. **Full remap.** Every control that does something is a row on the Remap screen, for each player, saved in `user://input.json`. That includes the new things: the strike source, beam and signature release, slip/brace/vanish, the lay, and the quick-strike key on a keyboard. A chord is allowed to be fixed only if its members are remappable and **a single-control form also exists** (rule 5).
3. **Swap as a whole.** One setting per player, `hand_layout` = standard or swapped, applied in the layout layer (input to intent, before the sim). Swapped means: move on the stick the attack hand uses today, strikes on the other stick; the shoulder pairs trade places (guard/dodge/vanish under the other index finger and thumb); face-button actions go to the D-pad on a pad. Nothing in the sim or the hash changes. The result is a layout preset, so Remap, glyphs and the gate treat it like any other preset.
4. **Routes to every move class.** Each move class is reachable with (a) both sticks, (b) the left stick plus buttons only, (c) no right stick (D-pad), (d) a keyboard, and (e) one hand on a keyboard. Cost, commitment and **the same tick** as the stick form (CRL §5.3, `right-thumb.md` rule 4). No class is stick-only.
5. **No speed gesture, no two-at-once, without a plain form.** Anything that depends on how fast a thumb moves or on two buttons landing within 6 ticks needs a timing-free alternative: a single button plus a held direction, or a wider window set as a recorded assist.
6. **Hold or toggle for every hold**, per player, same mechanism as `hold_style` and the four built `_style` options.
7. **The UI shows the live layout.** Glyphs, legend, how-to-play and prompts are built from the binding actually in force (prompt-glyphs rule 2), so a swapped or remapped layout is drawn as it is played.
8. **The law holds under every layout.** The no-claw gate (CRL §6.4, rows J to R) runs on the swapped preset and on each mirror, not only on the standard one.

## Move classes against routes (CRL §3 to §5, GDR §3 and §4)

| Move class | Standard (two sticks) | No right stick | One-handed keyboard | Gap |
| :--- | :--- | :--- | :--- | :--- |
| Quick strike, charged strike | right stick | D-pad mirror (setting, off; automatic with no right stick) | strike key + movement keys (U) | pad has no "strike button + left-stick direction" form; D-pad costs movement |
| Beam (RB + stick), sweep | stick, steers sweep | D-pad, stepped 8-way | Q + arrows; assist key | same as above |
| Signature (RT + stick, hold and release) | stick | RT + D-pad | E + arrows | release-timing needs a toggle form |
| Lay placement | LB + RB + stick | LB + RB + D-pad | assist key | none beyond the above |
| Slip (LT tap + flick, 6-tick window) | left stick | same | Space + tap of a move key | tight window; no assist |
| Brace (LB + quick flick from rest) | left stick | same | Shift + tap | **flick speed is the test** |
| Vanish (LB + LT within 6 ticks, then a direction) | chord | same | Shift + Space chord, or C / X / Quote | **no single-control form on a pad** (R3 is freed) |
| Transform (chord, half second) | chord | same | transform key | `transform_style` built |
| Guard, dodge, power, energy | shoulders | same | keys | `*_style` built |

## Already there

- Remap for every layout and device, per player, with conflict swaps; chords fixed with free members (`remap.md`, `ui_remap_model.gd`).
- Hold or toggle per player for energy, guard, manoeuvre, charge and transform (`options.json`, `hold-toggles.md`; built, on main).
- Touch: a left-handed mirror and the Simple layout (`left_handed`, `touch_preset`; the HUD's side lanes follow it in `ui_layout.gd`). Mobile is parked (ADR 0011), so not extended.
- Glyphs looked up from the live binding, never hard-coded; pad glyphs are position diamonds (`prompt-glyphs.md`).
- A designed D-pad mirror, a keyboard assist key, Simple-S and `strike_style` (CRL §1, §5, §4.3), all paper only.

## Missing

| # | Missing | Why | Owner | Gate |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `hand_layout` (standard or swapped) for pad and keyboard, per player; the swapped presets and their D-pad face-button map | Orb's rule; today only touch has a mirror | Controls (presets, layer), UI (the row, the preview) | P3 |
| 2 | Measure the swapped pair. In a swap the same thumb works a stick and the D-pad, which is its own transfer; `L`, `R`, `W` and the strike dwell `D` need a capture for it | the no-claw law is measured, not assumed | Controls, with QA's capture page | P3 |
| 3 | Gate rows J to R run on the swapped preset and each mirror | rule 8 | Controls, QA | P3 |
| 4 | Remap rows for the new actions and a fixed-chord rule that demands a single-control form | rules 2 and 5 | Controls (`SimInputRemap`), UI | P3 |
| 5 | A pad "strike button + left-stick direction" mirror (a free button such as L3; mirror of the keyboard's U) so a one-stick player keeps movement while striking | the D-pad mirror costs movement; the pad has no one-hand form | Controls; Game Design to rule equal-tick | P3 |
| 6 | A timing-free **brace**: a brace button, with the direction held at the press (assist `brace_style` = flick or press) | a flick-speed test excludes slow or tremor thumbs | Controls; Game Design (cost stays 3 ki) | P3 |
| 7 | A single-control **vanish** on the pad (a bindable action), and an assist that widens the 6-tick chord and slip windows. These change outcomes, so they are gameplay assists: recorded in the match settings and replay header like `autoMode` and `autoBurst`, never the sim clock | rule 5; a toggled guard plus LT is a plain dodge, so toggle users cannot reach the vanish today | Controls, Game Design (ranked and online use: Orb decides) | P3 |
| 8 | `strike_style` (hold or toggle) built, including the signature's hold-and-release and beam charge; say what the second tap does in each | rule 6 | Controls, UI | P3 |
| 9 | Legend, how-to-play and hints drawn from the live preset: swapped pad picture, role words in text, a layout preview in Settings, and a first-run or controller-connect offer ("Which hand moves?", with the D-pad mirror offered for a pad with no right stick) | rule 7 | UI | P3 |
| 10 | The quick-strike key for a shared keyboard is hard-coded in CRL §5.2 (T, Quote); make it a Remap row and check the `layout-pair` rule | rule 2 | Controls | P3 |
| 11 | All new labels, helps and prompts in the string tables with role words, so a language with different hand words reads correctly; the pseudo-locale and `strings.mjs` cover them once they are in `ui/data` | no text in code | UI, Accessibility (checks) | P3 |
| 12 | Accessibility checklist rows for all of the above, and a play test with one hand and with no right stick | P5 gate | Accessibility | P5 |

## Questions for Orb (through the EP)

- Is the swapped layout a pad-only setting, or must it also exist for keyboards (arrow cluster for movement, WASD for strikes)? Recommendation: both, as presets, since the keyboard is a remap already.
- Gameplay assists (wider windows, press-brace, single-button vanish) in ranked or online play: allowed, labelled, or off? Orb decides, with Game Design.

## Next

When Controls has the reader, I audit the first build against rules 1 to 8. The P5 checklist (`docs/accessibility/checklist.md`, not written yet) takes these rules as its controls section. Until then I stay idle.
