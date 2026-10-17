# The Protagonist's five forms, the run's keepsakes and finisher styles

Owner: Art Director. 2026-10-17. For Game Design's `docs/design/hero-forms.md` (the five steps, two roads), `docs/design/run-mode.md` 4.4 (the reward economy) and Narrative's `docs/narrative/rewards-words.md`. **Concept art, working labels, pending Orb and Legal. WIP character art: the sheets stay in `art/concepts/forms/` (uncommitted); Orb's copies are in `homework/fighters/` (git-ignored).** Regenerate: `node art/concepts/forms/gen-hero.mjs` and `gen-rewards.mjs` (deterministic). Questions for Orb: `homework/fighters/PICK-forms-and-rewards.md`.

## 1. The five forms (sheet `hero-forms.svg`)
Each step is a modest all-rounder (+5 percent speed, damage, launch), so **the body changes modestly: pieces on the approved body**, never a new body, never his face or tuft, never a hair or eye colour (Legal). The look underneath is whichever hybrid Orb picks (a form adds only plates, marks and rings).

| Step | Witness road (a cold quiet: stillness, weight) | Trial road (delighted, open) |
|---|---|---|
| I (marks on his base) | three round marks on the near forearm wrap, in his lane colour | the same |
| II | a chest plate and a heavier near guard, deep blue | a ring on the chest, a pale near guard |
| III | three bars across the chest plate, marks on the guard (a tally) | a second ring round the chest ring, marks on the guard |
| IV | tall chest plate, a big shoulder plate, a plate down the back, a belt plate, long near and far guards (a wall) | the chest ring, a small shoulder plate, both guards and a free ring turning round each fist |
| V (both roads meet) | the Witness plates carrying the Trial rings round both fists; the road he came by is the plate and outline colour, the other the inner mark | the same top form in Trial colours with Witness blue as the core and on the chest bars |

**Colours (his lane is hue 150 to 250; the Anti-hero's violet is 260 to 320):** Witness rim #598ecf (hue 213), core #aec4ea, keyline #253756: 22 to 30 CIEDE2000 from the Anti-hero's three auras, 21 from his lane colour today. Trial rim #2dbeab (hue 172), core #9de7dd, keyline #1a4d46: 45 to 48 from the Anti-hero's, 25 from today's, 31 from Witness. **The aura** is a thin outline and at most two arcs, only while charging or attacking: Witness has no arcs (stillness is the read), Trial one at II and III and two at IV and V. Poses: Witness planted, hands low; Trial leaning in, hands open.

**Honest limits.** (1) The silhouette moves little: measured on the base pose, steps II to IV differ from his base by 0.005 to 0.039 and V by 0.044 (the launch pair are 0.620 apart; the Anti-hero stays 0.617 to 0.623 from every form), so at 46 px **the colour and the rings tell the forms apart more than the shape does**; Orb's second tick asks whether to make the body change more. (2) The pieces are drawn on the concept kit's side-on figure, not the game's body. (3) The rings are free elements that must follow the wrists: a small circular emitter, not a bone.

**Costs (estimates, Rendering to confirm):** I and III are decals; II 2 rigid parts; IV 4 to 6; V 6 to 7. No new bone. Animation: two poses (planted, leaning-in) and the release's showpiece, which is Game Design's.

**Stacking audit (Legal's seven marks, at most two in a moment):** a step shows none of the seven (no crouch, no scream, no flame, no lightning, hair fixed, flash in lane blue or teal, never gold, white or red); a step taken on the ground carries the ground cracking (mark 4) and nothing else.

## 2. The thirty keepsakes (sheet `keepsakes.svg`)
One drawn object per keepsake on a dark tile, from Narrative's names, lines and triggers (`docs/narrative/pending/keepsakes.json`, in its order). 64 px glyphs, flat with a keyline, readable at the shelf's 48 px. **No body, no death** (Legal c08); the Plain Coin and the Thank-You Note are a coin and a folded note. Art does not write the lines.

## 3. The Protagonist's finisher styles (sheet `finisher-styles.svg`)
Three variants of "Everything"'s camera, colour and closing pose; none changes the rules. **Open Palm** (Trial colours; he ends with an open hand held out low, as an offer; a wide low camera pulling back and up), **Held Breath** (Witness colours; head bowed, looks back for the people; a tight push-in then a hard cut wide), **Both Roads** (two-tone; one open hand raised, a promise in the future tense; a slow half-circle round him). Every flash is one steady pulse in the road colour, never a strobe, never gold, white or red; the blast uses a thin outline and arcs, never a flame or lightning. The other three finishers (The Verdict, Clean Cut, Last Orders) get three styles each by the same method once Orb has seen these. Legal to confirm that neither the offered hand nor the raised hand reads as a taunt of a beaten rival.

## Next
After Orb's marks: the picked styles and forms become turnarounds and `data/art/` rows (Tools adds the schemas); Narrative writes the form names and stings; Rendering and Animation build from the costs above.
