# The 23 pieces of protag7 and rival4, live (Animation, 2026-10-31)

Owner: Animation. The EP's brief (Orb's order: a playable with the new controller mapping): Combat found that `protag7` and `rival4` are not in their fighters' `waves` in `data/anim/fighters.json`, so the 23 pieces the sim throws from its live pools draw as a generic blow (`docs/combat/pending/stick/README.md`). Legal closed RL-079, so they may go live, under the conditions of `docs/legal/zip-screen.md`: `fist_drop`, `plate_hammer` and `palm_heave` lower at once and are never held, a tell, a victory or a taunt; the palm rises stay open hands, feet down, no glow. Render only: no sim state and no hash moves.

## What was wrong, measured

`cell_probe` (scratch): the nine cells (X, Y and B, each tapped, mashed and held) played by a pad on an idle dummy, 8 cycles for each of the two fighters on the main build, every blow logged with the piece the sim named and the key set it drew: 771 blows. **145 of them (19 per cent) were drawn as another blow**, 16 of the 23 pieces among them:

| Piece | Blows | Drawn instead (the commonest) |
| :--- | ---: | :--- |
| Protagonist `palm_heave` | 25 | a hook, a knife chop, a backfist |
| Protagonist `palm_lift` | 24 | a hammer fist, a twin spear, a ridge hand |
| Protagonist `palm_rise` | 19 | a jab, a backfist, a rising elbow |
| Protagonist `knee_hook` | 17 | a ridge hand, a spear hand, a short elbow |
| rival `heel_backhand` | 14 | the double hammer, a spinning heel, a haymaker |
| rival `knee_hook` | 10 | a spear hand, a short elbow, a low kick |
| rival `short_uppercut` | 9 | a cross, a hook, a jab |
| rival `knee_lift`, `fist_rise`, `gut_rise`, `elbow_drop`, `fist_sweep`, `plate_drop`, `plate_hammer` and two Protagonist pieces | 1 to 7 each | other fists, elbows and knees |

The Protagonist's palm rises (the pieces Legal's identity rows give him: palms, open hands) were drawing as jabs, hooks and elbows.

## The change

- `data/anim/fighters.json`: `protag7` on the end of the Protagonist's `more`, `rival4` on the end of the Anti-hero's. No name in either wave is one of the fighter's other waves' (checked), so no existing blow resolves differently.
- **Every strike of both waves is `named`** (the manifests and the generator's specs): findable by the beat's `piece` through `resolve_strike`, in no pick list, as the Anti-hero's fist jabs and the Protagonist's `palm_turn` already are. Without it the 23 would also have entered the fighters' random pick lists and changed the look of every blow that names no piece; with it a blow changes only if the sim named one of the 23. (The training dummy's `common` row already had `rival4` and keeps it.)
- Legal's three: `rm.fist_drop`, `rm.plate_hammer` and `pm.palm_heave` carry `hold_t: 1` (the contact key held one tick, never the style's ten on a perfect press). **Found by the new test and fixed:** the fist of `fist_drop` and `plate_hammer` was still up on the follow key (63 and 66.5 in the pose, 77 and 80 as drawn: the rule is 76 or lower six ticks after the contact), so the arm was held up through the follow-through on the speed and on the tech style. Their follow keys now carry the fist at 59 (73 as drawn). The spec says the same (`follow: { hand_r: ... }`), so a regeneration keeps it.
- Nothing names a piece of the 23 as a tell, a victory, a taunt, an intro or a moment (the test scans the data); the palm rises are open hands with both feet down in every key (the test reads the sketches); the glow is VFX's.

## What changes on screen

Of the 771 blows, **all 771 are now drawn as the piece the sim named (626 before)**; only the 145 above change, and every other blow draws the same key set. By cell, the share drawn as its own piece, before and after:

| Cell | Protagonist | Anti-hero |
| :--- | :--- | :--- |
| X tapped | 80% -> 100% | 66% -> 100% |
| X mashed | 61% -> 100% | 75% -> 100% |
| X held | 74% -> 100% | 83% -> 100% |
| Y tapped | 100% | 75% -> 100% |
| Y mashed | 100% | 83% -> 100% |
| Y held, B tapped, mashed and held | 100% | 100% |

## Do the cells look more distinct?

A little, and the measure says what kind. Scored by the histogram overlap of what each cell draws (Combat's measure: the share of two cells' blows that fall on the same key sets, averaged over the 36 pairs; lower is more distinct): **Protagonist 0.096 -> 0.090, Anti-hero 0.107 -> 0.094.** The distinct key sets a cell throws fall where the generic fallback was scattering blows across unrelated key sets (the Anti-hero's mashed Y 13 -> 8, his tapped Y 8 -> 5), and rise where a cell's own pool was cut short (his mashed X 19 -> 21, held X 18 -> 20): fewer random blows, more of the cell's own. The bigger change is not distinctness but that **what the sim sends is what is drawn**: the Protagonist's palm rises are palms again.

## Proof

- `anim_check` `_test_pieces23` (new): all 23 resolve to their own key sets; none is in a pick list; `fist_drop`, `plate_hammer` and `palm_heave` on the speed and the perfect-tech style have a hand at 76 or lower six ticks after the contact and 80 after, and one contact, no NaN, nothing past a limit on screen; the palm rises are open hands with feet down in every key; no tell, victory, taunt, intro or moment data names one of the 23.
- The cost: the pair bake takes 69 more poses (663 to 732; protag7 has 24, rival4 45) through the lazy bake that is already on main; its time was measured on a loaded machine, so the number is not reported.
- The other gates and the clips are in the report.

## Not here

- The 23 are posed as lights (`weight: light`; `fist_rise` and `heel_backhand` heavy); the stick's "quick pieces tuned to the 10-tick wind-up" is Combat's note and still open.
- Nothing else of the move list is added: the split's pools and the stick's pieces are Combat's, and use these names.
