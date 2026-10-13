# Rows for the Demon Cyborg and the Empress, the floors of a fighter's own, and the gate on blows

Owner: Combat and Choreography. Date: 2026-10-12, second version: Game Design's borrowing policy (`docs/design/fighter-pipeline.md` section 1) and Legal's screen (`docs/legal/roster-sketches-screen.md`) are built in. Status: parked. Nothing is applied to `data/`, and `pending/recipes.brawl.json` is byte for byte unchanged. Follows `fighter-onboarding.md` and `fighter-cards.md`.

## 1. What is built

- **A piece is his or it is common, and his own is never lent.** The generator (`pending/movegen/gen_moveset.py`, version 16) marks each move that is a fighter's own. A newcomer reads only the common pieces of a pack he borrows, and a blow that is another fighter's own is not drawn again for him at any strength.
- **Floors of his own, in `cells.json`** beside the heavies': 3 lights, 2 mediums and 2 heavies at tier 1; 5, 3 and 4 at tier 2. The check fails when a cell is under its floor.
- **Heavies and bolts are the exception,** as ruled: a tier-1 newcomer takes them from the others' packs, no more than half a tier from one fighter, and never below the lender's own floor.
- **The gate on blows is a check.** `--check` prints, for each fighter, the part of his blows that are pieces only he has, and fails under a fifth.
- **Four rows as sketches** (`pending/roster/`), each with a generated moveset and a card (`pending/cards/`): the Cyborg as the Press, the Courier and the Hopper, and the Empress.
- **A roster builder** (`pending/roster/build_roster.py`) that runs the generator on the sketches beside the two fighters of the build, and stops if the two fighters' moves would change.

## 2. The shares, under the policy

The gate reads the generated moves against the measured mix of blows (two blows in three are flurry blows). "With his own drawn" counts his own pieces that wait as if Animation had posed them. Each figure is the fighter's worst over the rosters he may be in: one Cyborg and the Empress.

| | The two alone | With one Cyborg and the Empress | Measured in matches |
| :--- | ---: | ---: | :--- |
| The Protagonist | 37% | 27% | 37% alone; 27% in the roster |
| The Anti-hero | 35% | 28% | 33% alone; 27% in the roster |

| The sketches, with their own drawn | Share | Against the gate |
| :--- | ---: | :--- |
| The Press | 27% | Passes |
| The Courier | 25% | Passes, at the line |
| The Hopper | 30% | Passes |
| **The Empress** | **19%** | **Under a fifth.** Her own drawn one and a half times as often as the rest would reach a quarter |

- **Today every sketch reads 0%:** nothing is drawn for them, so nothing they throw is theirs.
- **The estimate agrees with the matches** to within two points for the two in the build, which is the only place both exist.
- **Three rows pass on the floor alone, at an even draw.** That needed one thing of mine beyond the ruling: all three of a tier-1 fighter's own lights fit the flurry's gap (a quota of the light cell). With two of three, the Hopper read 24%.
- **The Empress does not pass, and the reason is the Protagonist.** Her quick hands are open and bladed, which is his ground, and his own are never lent. Only two new quick hands are left for her, and her other own lights are kicks, which a flurry never throws. Game Design's remedy is more of her own or her weights: the first has nowhere to come from until her mantle strikes as a limb.
- **"His own are the blows he throws most" is not in the game yet.** Today's picker draws evenly. The check carries the draw weight as a number (`gate.ownWeight`, 1 today) and says what weight a row would need; a weight in the pools and in Encounter's pick is a change of its own.

## 3. The four rows

| | The Press | The Courier | The Hopper | The Empress |
| :--- | :--- | :--- | :--- | :--- |
| In a line | Mass that arrives late and all at once | In, a strike, gone | He leaves the ground to hit | She barely moves: one clean line or one cut downward |
| Favours | Forearm plate, hammer fist, shoulder, crossed forearms; drops and rams | Elbows, knees, straight hands; lines and rises | Heel, knee, ball of the foot; drops and rises | A blade hand and the heel of the foot; lines and drops |
| Never | A blade hand; a spin; a kick above the gut | A spin; a kick above the chest | A hand or elbow from above; a headbutt; a rise to the jaw or head | A closed hand; a spin; a headbutt; a shoulder |
| Posed, borrowed pose, waiting | 60, 41, 25 | 70, 31, 26 | 63, 37, 28 | 60, 43, 24 |
| His own, all waiting: lights, mediums, heavies | 5, 2, 2 | 6, 2, 2 | 6, 2, 3 | 4, 2, 2 |
| Heavies: from the Anti-hero; from the Protagonist | 5; 3 | 5; 3 | 5; 2 | 3; 5 |
| The heavies that are his own | A falling hammer fist to the chest; a stepping shoulder to the chest | A stepping knee to the legs; a turning elbow to the chest | A falling heel to the legs; a stepping ball of the foot to the gut; a stepping palm to the arm | A stepping blade hand to the chest; a falling heel to the gut |
| Thin in what is posed | The burst's quick blows (3), the reversal (3) | The reversal (3) | The reversal (2), the burst's quick blows (3) | The reversal (0), the lift (0) |

- **His own come out at 8 to 11 strikes,** above Game Design's floor of 7, because the stick's leans ask for shapes that the common pool does not have for him. Each also needs six energy pieces of his own in time: today all six are borrowed.
- **Probed in matches before the floors were built** (`pending/roster/` at `a847d212`): every blow of each Cyborg sketch came from his own pools; the Empress's reversal had no piece to throw. That has not changed: nothing that waits is in a pool.

## 4. The Empress's cloth

| Silhouette | The row | The gate |
| :--- | :--- | ---: |
| The Regent: the mantle behind and low | The parked row is hers | 19% |
| The Tabard: a panel in front, shoulder to knee | Generates with a knee and a forward kick taken out | 21% |
| The Bell: her legs under cloth | **Does not generate at tier 1.** The waiver of the leg floor is built (`waives` in her row) and works; she then fails the floor of three lights of her own, because with no kick or knee only two new quick hands are left for her | |

So the Bell needs her mantle as a limb before she has a row, or a second waiver. The Tabard's two bans are my reading of Art's note.

## 5. Legal's screen, folded in

Legal passed the four rows with one correction and two conditions (RL-133 to RL-135).
- **The correction: the Protagonist's falling palm is one arm.** My label said both arms because Animation's pack still does (`pu.su_drive`: `uses.arms` 2 and a second limb), though its drawing and its words are one arm. His identity now says one (`armsOf`), the label and his card follow, and the pack is Animation's to mend.
- **A leap** is allowed for a knee or a foot to the gut, the chest or the legs, and never by hand, elbow or head (b14, merged). The Hopper's row already kept to it. Legal calls his leap a new drive, the hop; it is not built, and his rising heavies are named as heaves until it is.
- **The stomp:** a sole or heel from above on a standing opponent is clear (s09, merged), so the ban his row held for that ruling is gone. A downed opponent's head is out of the base moveset until the rating decision; the grammar has no blow on a downed opponent at all, and his card says so.
- **The barrage** passes on paper (sg01). `barrage-signature.md` has its conditions.

## 6. The measure the policy was ruled on

Kept here because Game Design's ruling cites it. Four seeded matches, 7,238 blows, one Cyborg and the Empress added to the two.

| Blows that are a piece only he has | The two alone | Newcomers borrow the common pieces only | Newcomers borrow every pack |
| :--- | ---: | ---: | ---: |
| The Anti-hero | 33% | 27% | 3 to 12% |
| The Protagonist | 37% | 27% | 1 to 2% |

`build_roster.py --borrowing all` still tries the second policy and writes nothing.

## 7. What is not done

- **Nothing is drawn for any of them.** Whether a third body can play the two fighters' key sets as they are is Animation's to say.
- **A draw weight on a fighter's own pieces** (section 2).
- **The hop** as a drive of the heavy tier, for the Hopper.
- **The Press's clamps and throws, and the Empress's mantle:** new parts, not rows.
- **"Never a two-arm blow"** cannot be said in a row: a ban reads a shape, and a shape does not say how many arms.
- **The card generator and the pool builder are still in Combat's scratch.** The generator, the roster builder and all the data are in the tree.

## 8. To run it

```
python -B docs/combat/pending/movegen/gen_moveset.py --check
python -B docs/combat/pending/roster/build_roster.py --check
```

The first passes: the two in the build read 37% and 35%. The second exits 1 on one line, the Empress under a fifth; every other line passes. The data scripts' order ends `share_data.py`, `rl133_data.py`.
