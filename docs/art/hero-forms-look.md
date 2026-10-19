# The Protagonist's five forms, the run's keepsakes and finisher styles

Owner: Art Director. 2026-10-17. For Game Design's `docs/design/hero-forms.md` (the five steps, two roads), `docs/design/run-mode.md` 4.4 (the reward economy) and Narrative's `docs/narrative/rewards-words.md`. **Concept art, working labels, pending Orb and Legal. WIP character art: the sheets stay in `art/concepts/forms/` (uncommitted); Orb's copies are in `homework/fighters/` (git-ignored).** Regenerate: `node art/concepts/forms/gen-hero.mjs` and `gen-rewards.mjs` (deterministic). Questions for Orb: `homework/fighters/PICK-forms-and-rewards.md`.

## 1. The five forms (sheet `hero-forms.svg`), round 2 of 2026-10-18
Orb's answer to round 1: "all around not distinctive enough, lets bulk up muscles, add distinctive upgrade, lets get lore of the universe settled so we can explain reasoning behind transformations"; Witness and Trial both "not quite", make the body change more, change the top form. **So each step now has a heavier frame and one hallmark** (never his face or tuft, never a hair or eye colour: Legal). The look underneath is whichever hybrid Orb picks.

| Step | Frame | Witness road (plates: shelter; stillness, weight) | Trial road (rings: the sparring circle; delighted, open) |
|---|---|---|---|
| I | +3% | three round marks on the near forearm wrap, in his lane colour | the same |
| II | +8% | **the Vigil Mantle**: a wide collar and a plate over each shoulder, a chest plate, a heavy near guard; the shoulders widen | **the ring gauntlets**: two ring bands round each forearm, a ring on the chest, a pale near guard |
| III | +11% | **the tally**: the mantle, three bars across the chest plate, marks on the guard, a plate on the near thigh | **the lit rings**: a second ring round the chest ring, rings round the ankles, bands on both forearms |
| IV | +16% / +13% | **the Bulwark**: tall chest plate, a plate down the back, a belt plate, plates on both thighs, long guards, a plated fist | **the Orbit**: free rings round both fists and both ankles, bands on both forearms, the chest ring, a small shoulder plate (a sprinter's build) |
| V | +20% | **the Ring at his back**: a plain ring standing behind the shoulders (his Showman mark), the Bulwark's plates carrying the Trial rings round both fists; the road he came by is the plate and outline colour, the other the rings | the same top form in Trial colours with the Witness blue as the core and on the chest bars |

The frame is a scale of the existing body (tw and lw per step: data later); the head stays the same size, so it reads as a bigger body. **Proposed lore hooks (Narrative settles them):** PLATES are shelter (Witness takes on the weight of what he could not stop); RINGS are the sparring circle (Trial draws one more circle round him for each higher form he has met); the top form carries both. Growth is the body answering the weight: Witness grows by carrying, Trial by training. Witness never rages; Trial never mocks.

**Colours (his lane is hue 150 to 250; the Anti-hero's violet is 260 to 320):** Witness rim #598ecf (hue 213), core #aec4ea, keyline #253756: 22 to 30 CIEDE2000 from the Anti-hero's three auras, 21 from his lane colour today. Trial rim #2dbeab (hue 172), core #9de7dd, keyline #1a4d46: 45 to 48 from the Anti-hero's, 25 from today's, 31 from Witness. **The aura** is a thin outline and at most two arcs, only while charging or attacking: Witness none, Trial one at II and III and two at IV and V.

**Measured** (flat silhouette at 46 px, base pose): the distance from his base is 0.037 (I), 0.107 and 0.101 (II), 0.136 and 0.131 (III), 0.233 (IV Witness), 0.155 (IV Trial) and 0.267 (V); the Anti-hero stays 0.612 to 0.628 from every form (the launch pair are 0.620). **Not done:** muscle definition (the kit's body is a generic build; real muscle shows at the rig and the turnaround), and the pieces are on the concept kit's side-on figure, not the game's body.

**Costs (estimates, Rendering to confirm):** the growth is data; I and III are decals; II 2 to 3 rigid parts; IV 6 to 8 (Trial: free rings that follow the wrists and ankles); V 8 to 9 with the back ring (a plain annulus: Legal wants no letter, star or sphere). No new bone; the rings need a small circular emitter. Animation: a planted pose and a leaning-in pose.

**Stacking audit (Legal's seven marks, at most two in a moment):** a step shows none of the seven (no crouch, no scream, no flame, no lightning, hair fixed, flash in lane blue or teal, never gold, white or red); a step taken on the ground carries the ground cracking (mark 4) and nothing else.

## 2. The thirty keepsakes (sheet `keepsakes.svg`)
One drawn object per keepsake on a dark tile, from Narrative's names, lines and triggers (`docs/narrative/pending/keepsakes.json`, in its order). 64 px glyphs, flat with a keyline, readable at the shelf's 48 px. **No body, no death** (Legal c08); the Plain Coin and the Thank-You Note are a coin and a folded note. Art does not write the lines.

## 3. The Protagonist's finisher styles (sheet `finisher-styles.svg`)
Three variants of "Everything"'s camera, colour and closing pose; none changes the rules. **Open Palm** (Trial colours; he ends with an open hand held out low, as an offer; a wide low camera pulling back and up), **Held Breath** (Witness colours; head bowed, looks back for the people; a tight push-in then a hard cut wide), **Both Roads** (two-tone; one open hand raised, a promise in the future tense; a slow half-circle round him). Every flash is one steady pulse in the road colour, never a strobe, never gold, white or red; the blast uses a thin outline and arcs, never a flame or lightning. The other three finishers (The Verdict, Clean Cut, Last Orders) get three styles each by the same method once Orb has seen these. Legal to confirm that neither the offered hand nor the raised hand reads as a taunt of a beaten rival.

## Next
After Orb's marks: the picked styles and forms become turnarounds and `data/art/` rows (Tools adds the schemas); Narrative writes the form names and stings; Rendering and Animation build from the costs above.
