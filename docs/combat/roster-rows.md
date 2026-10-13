# Rows for the Demon Cyborg and the Empress, and the rule for sharing heavies

Owner: Combat and Choreography. Date: 2026-10-12. Status: parked. Nothing is applied to `data/`, and `pending/recipes.brawl.json` is untouched. Brief: the EP's of 2026-10-12, on Orb's go. Follows `fighter-onboarding.md`, `fighter-cards.md` and Game Design's `docs/design/fighter-pipeline.md`.

## 1. What was built

- **The sharing rule is in the generator** (`pending/movegen/gen_moveset.py`, version 15). Game Design's rule, on the heavy cell: a fighter has 2 heavies that are his alone at tier 1 and 4 at tier 2, no two fighters share more than half, and the fighter he borrows from keeps his own 2 as well. The two fighters of the build are unchanged by it: every one of their ten is their own.
- **Four rows, as sketches** (`pending/roster/identity.candidates.json`): the Cyborg as the Press, as the Courier and as the Hopper, and the Empress. Tier 1 only: weights and bans on today's systems.
- **A generated moveset, a card and a seeded probe for each.** `pending/roster/` has the movesets, their lock and a review sheet for Legal; `pending/cards/` has the four cards beside the first two.
- **A roster builder** (`pending/roster/build_roster.py`) that runs the generator on the sketches beside the two fighters of the build, and stops if the two fighters' moves would change.

## 2. The sharing rule, as built

| In the data | What it says |
| :--- | :--- |
| `cells.json`, the heavy cell: `share: {own: {1: 2, 2: 4}, maxWithOne: 0.5}` | The rule's numbers |
| A fighter's `tier` | 1 when it is not said |
| A fighter's `borrows` | The packs that are another fighter's |
| A fighter's `alt` | Rows with the same word are options for one place in the roster. They never count each other |

- **His alone** means a piece of a pack of his own, or a new shape that no other fighter's cell holds. A new shape waits for Animation, so the rule also writes his list of what to pose.
- **Shared** means both cells hold the shape, or he takes it from the other's pack.
- **A launcher for every send** became four quotas of the cell, filled first. Without them a borrower under the cap ended with no launcher that sends down, and the generator refused to write.
- **The check fails** when a cell has too few of his own or too many from one fighter.
- **One search was too impatient, and is fixed.** The search for a mashed run of bolts took the first order of pieces that kept Legal's rule and looked for arms for that order only. For the Press it found none and stopped, though another order works. It now goes on to the next order. The two fighters' runs come out as before.

## 3. What the two in the build keep, before and after

"His own" is a piece no other fighter in the roster has. Counted on the four measured matches (7,238 blows), with one Cyborg and the Empress added.

| Blows that are a piece only he has | The two today | Sketches borrow the common pieces only | Sketches borrow every pack |
| :--- | ---: | ---: | ---: |
| The Anti-hero | 33% | 27% | 3 to 12% |
| The Protagonist | 37% | 27% | 1 to 2% |

| Pieces that are his alone, in the pools the brawl draws on | The two today | Common only | Every pack |
| :--- | ---: | ---: | ---: |
| The Anti-hero, of 57 | 27 | 17 or 18 | 5 to 8 |
| The Protagonist, of 54 | 27 | 16 or 17 | 6 or 7 |

- **The rows are parked on "common only", and I recommend it.** A sketch borrows only the lights and mediums that both fighters of the build already have posed, 37 today. The 13 lights and mediums that are the Anti-hero's alone and the 13 that are the Protagonist's stay theirs.
- **With every pack open, the two are generic again.** A newcomer who reads the Anti-hero's own lights takes them from him. That is cheaper to pose and it undoes what the recipes window is about to give Orb.
- **What the two lose under "common only"** is their heavies down to the rule's floor, and their bolts, which the sketches borrow whole. The bolts come back when each new fighter has his own six drawn.
- **A question for Game Design.** Its plan for twelve makes every light and medium common, with a fighter's own being his heavies and energy pieces. On these numbers that leaves a fighter about a tenth of his blows as his own. Either weights and bans must carry him alone, or lights need a floor of their own, as heavies have. The generator can keep such a floor today: the rule is a cell's, not the heavy cell's.

## 4. The four rows

Under "common only". Posed, borrowed and waiting are of his 126 to 128 moves; "new strikes" are the lights, mediums and heavies that wait, which is what Animation would pose to make him whole at tier 1. Each also needs six energy pieces of his own: today all six are borrowed.

| | The Press | The Courier | The Hopper | The Empress |
| :--- | :--- | :--- | :--- | :--- |
| In a line | Mass that arrives late and all at once | In, a strike, gone | He leaves the ground to hit | She barely moves: one clean line or one cut downward |
| Favours | Forearm plate, hammer fist, shoulder, crossed forearms; drops and rams; the chest and the arms | Elbows, knees, straight hands; lines and rises | Heel, knee, ball of the foot; drops and rises | A blade hand and the heel of the foot; lines and drops |
| Never | A blade hand; a spin; a kick above the gut | A spin; a kick above the chest | A hand or elbow from above; a headbutt; a rise to the jaw or head; the sole from above | A closed hand; a spin; a headbutt; a shoulder |
| Posed, borrowed pose, waiting | 61, 39, 26 | 71, 31, 25 | 60, 40, 28 | 60, 39, 28 |
| New strikes to pose | 10 | 9 | 11 | 12 |
| Heavies: his alone; from the Anti-hero; from the Protagonist | 2; 5; 3 | 2; 5; 3 | 3; 5; 2 | 2; 3; 5 |
| The heavies that are his alone | A falling hammer fist to the chest; a stepping shoulder to the chest | A stepping knee to the legs; a turning elbow to the chest | A falling heel to the legs; a heaving knee to the gut; an unwinding fist to the arm | A falling blade hand to the chest; a stepping blade hand to the arm |
| Thin today | The burst's quick blows (3), the reversal (3), the lift (1) | The reversal (3), the lift (2) | The burst's quick blows (2), the reversal (2), the flurry (6) | The reversal (0), the lift (0), the mediums (5) |
| Leads the roster in | Hammer fists, hand strikes, blows to the arms | Knees, rising blows | Blows to the legs, kicks | Blade hands, straight lines |

**In two seeded matches each** (a grey copy of a fighter under a new id, with the sketch's pools): all 826 of the sketch's blows came from his own pools for the three Cyborgs. For the Empress 8 had no piece: her reversal has nothing posed. The Hopper repeated a piece 15 times inside three blows and broke the gut rule once, both from pools of two.

**What the numbers say for Orb's pick.**
- **The Courier is the cheapest and the surest.** Most posed, fewest new strikes, no thin pool that breaks a rule. His weakness is that he sits nearest the Anti-hero: they share 47% of their shapes, where the two today share 33%.
- **The Press reads as himself at once** and furthest from the Protagonist (28%). The clamps and throws that are his point are not in this row: nobody has them, and they are the most new work of the three.
- **The Hopper cannot fill a held X** from what is posed for him: his quick hands are too few. He needs his own lights before he plays, not after. Legal comes first with him as well.
- **The Empress sits nearest the Protagonist** (47% of shapes): both are open hands. Her mantle is what will set her apart, and it is a new limb, at tier 2.

## 5. The Empress's cloth: one row is not enough

The EP asked whether her three silhouettes differ in cloth and not in how she strikes. They differ in how she strikes.

| Silhouette | What the cloth does | The row |
| :--- | :--- | :--- |
| The Regent: the mantle behind and low | Nothing to her strikes | The parked row is hers |
| The Tabard: a panel in front, shoulder to knee | A knee lifts it and a kick straight forward goes through it | It generates with those two taken out, at 13 new lights and mediums where the Regent has 10 |
| The Bell: her legs under cloth | No kick and no knee would be seen | **It does not generate.** With no leg she has no heavy that lands on the legs, and the tier's floor asks for one. She would need the mantle as a limb from the first day, or that floor waived for her |

The two bans I gave the Tabard are my reading of Art's note, not Art's rule.

## 6. Legal

- **Legal has screened none of these rows.** The generator applies `docs/legal/movegen-banned.json` to them as it does to the two in the build: no row matches. The review sheet in `pending/roster/` is for Legal's screen.
- **No stomp on a downed opponent.** The grammar has no blow on a downed opponent at all. The Hopper's row also bans the sole brought down from above on a standing one, until Legal rules.
- **The Hopper's rises** go to the gut and the chest: Legal's b03 refuses a leaping rise to the jaw or the head, and he leaps.
- **No new fighter borrows the lit fist.** Legal's e06 allows an open hand, a blade hand or the Anti-hero's own lit fist in reach. The Cyborg borrows the Protagonist's open-palm pieces, and the Empress the blade-hand ones.
- **The Empress's cutting hand** is a pinch or a blade hand at range, never a pointed finger (e03), and the pinch is refused in reach (e06), so in reach she has the blade hand and an open palm.

## 7. What is not done

- **Nothing is drawn for any of them.** Every piece a sketch throws is the Protagonist's or the Anti-hero's pose. Whether a third body can play those key sets as they are is Animation's to say.
- **The Press's clamps and throws, and the Empress's mantle:** new parts, not rows.
- **"Never a two-arm blow"** cannot be said in a row today: a ban reads a shape, and a shape does not say how many arms. I left it out of the Empress's row.
- **A sketch's pools for the older exchanges** are filled by a simple rule from his cells.
- **The card generator and the pool builder are still in Combat's scratch.** The generator, the roster builder and all the data are in the tree.

## 8. To run it

```
python -B docs/combat/pending/movegen/gen_moveset.py --check
python -B docs/combat/pending/roster/build_roster.py --check
python -B docs/combat/pending/roster/build_roster.py --borrowing all     (tries the other policy; writes nothing)
```

Both checks pass. The data scripts' order gains a last step, `share_data.py`, which puts the rule and the launcher quotas on the heavy cell.
