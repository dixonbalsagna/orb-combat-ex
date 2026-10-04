# The moveset generator

Owner: Combat and Choreography. Date: 2026-10-04. Status: a design, with a scratch prototype behind its numbers. Nothing in the tree is edited. Written against HEAD `91b139b`.

**Orb's direction** (`docs/ep/vision.md`, last two sections): five stances by what is held (none: the fighter's martial arts stance; LB: defensive; RB: energy arts; RT: charging; LT: manoeuvre), "all face buttons should have an appropriately broad moveset for each stance", and "a way to generatively work all these stances into vast and varied movesets for each character". In the brawl each press is a blow: mashing gives faster flurries, timing gives flashy skill attacks that lapse into flurries, and the heavy beats a heavy guard and sets up juggles.

**What this replaces.** Today a fighter's moveset is a hand-kept list: 36 posed strikes for the rival and 43 for the Protagonist, sorted by hand into seven pools (`data/combat/recipes.json`). The two lists share 35 strikes, which is 97% of the smaller one. The generator composes each fighter's moves from parts under his own rules, so the lists grow by data and the two fighters stop sharing a moveset.

**Game Design's stance-by-button matrix is still to come.** Section 3 uses a provisional one, marked as such. The generator takes the matrix as input, so nothing else here depends on it.

## 1. A move, its parts, and the grammar

A **cell** is one face button in one stance: 5 stances by 4 buttons, 20 cells a fighter. A **move** is what one press in a cell can play. The generator fills each cell with a set of moves, each assembled from the parts below.

| Part | What it says | Values | Where it comes from today |
| :--- | :--- | :--- | :--- |
| **Limb** | what strikes | hand, foot, elbow, knee, shoulder, head, own | `pieces` in `recipes.json` (slice 11) |
| **Tip** | the striking surface | hand: fist, blade, palm, heel (the bottom or back of the fist), plate (the forearm leads). Foot: ball, heel, instep, edge, sole. Elbow point, knee cap, shoulder plate, brow | new. For hands it is Animation's hand state at contact, which is already in every pose |
| **Target** | where it lands | head, jaw, chest, gut, arm, legs, shins | `pieces` |
| **Path** | the angle the limb travels | line, arc in, arc out, rise, drop, spin (one turn) | new. Today it is only in each strike's written look |
| **Range step** | what his feet or his flight do with it | in, hold, around, out; a full entry in the manoeuvre stance | tempo `stepIn` and `stepAround`; the 15 posed entries |
| **Weight** | light or heavy | light, heavy | the strike rows |
| **Form** | how the press was made, which sets its speed and timing class | flurry (mashed), light, skill (timed), heavy, held, ender, juggle | Game Design's press-feel draft; the styles of `recipes.json` |
| **Hooks** | what it leaves behind | `sends` (across, up, down, turned), `links` (the paths that flow out of it), `beat` (the tick of its beat point), `ends` | the `sends` and `ends` tags; the blur patterns |
| **Keys** | the pose key set that plays it, and how it is got | posed; a hand-state swap; a re-aim; a new key set (section 5) | Animation's manifests |

**The grammar** is four small tables, all data:

1. **Which tip takes which path.** A palm goes on a line or rises; a blade goes on a line, either arc, or drops; a heel drops, arcs out or spins; an instep only arcs in.
2. **Which path reaches which target, by limb.** A rising hand reaches the jaw, chest or gut; a dropping hand the head, chest or arm; no foot reaches the head (kicks stay at chest height and below).
3. **Which weight a shape may have.** A spin, a headbutt and a dropping kick are never light.
4. **What flows into what.** After a line anything but a spin; after an arc in, an arc out or a spin (he unwinds); after a rise, a drop (the hand is high); after a drop, a rise. These are the `links`: they generalise the blur patterns from a fixed list of five steps to a rule that orders any string.

For strikes the four tables give **193 shapes** (limb, tip, path, target, weight): 118 by hand, 51 by foot, 10 each by elbow and knee, 2 each by shoulder and head; 88 light and 105 heavy. The other stances have the same form with their own parts (section 3).

**Everything derived is derived by rule,** so a move never carries a number the generator invented:
- `sends` follows the path: a line sends across, a rise up, a drop down, an arc or a spin turned.
- The range step follows the path: a line steps in or holds, an arc steps around, a spin goes around or out.
- The beat point follows the path: 20 ticks for a line, 24 for an arc or a rise, 26 for a drop, 28 for a spin, inside Game Design's 20 to 28.
- **Damage, speed, reach band and reaction come from the cell's class and the form, never from the variant.** Two moves of one cell differ in limb, tip, path, target and hooks, and are worth the same. That is what keeps a generated set balanced: no variant can be the best button.

**What exists and where it goes:**

| Exists | Becomes |
| :--- | :--- |
| `pieces` (limb, target) | the part table: it gains `tip` and `path` |
| The seven pools | written by the generator from the cells, so Encounter's reader does not change |
| Blur patterns and `patternGates` | the `links` rule orders a string; the eight patterns stay as named phrases the director may still draw; gates gain `stance` |
| Strike rows (range, ticks, tags) | the numbers of a posed key set, unchanged |
| Finishers | phrases with slots: the Protagonist's flurry already asks for "a different strike and a new side each time", which is a draw from a cell |

## 2. Identity: the same grammar, two different fighters

Each fighter has an identity block: a weight for every tip, path and limb, a list of shapes he never makes, and how strongly to prefer what is already posed. The selector multiplies the weights, so his cells fill with his own shapes first.

| | The Protagonist | The rival |
| :--- | :--- | :--- |
| **Tips he favours** | palm 3, blade 3, heel 2; the edge of the foot 2.5 | fist 3, plate 3, blade 2.5; the elbow's point 2.5, the knee 2 |
| **Tips he avoids** | fist 0.4; the brow 0.2 | palm 0.6 |
| **Paths** | arc in 3, arc out 3, spin 2, rise 2, drop 1.5, line 1 | line 3, drop 2.5, rise 1.5, arc in 1, arc out 0.5, spin 0.5 |
| **Limbs** | hand 3, foot 3, the rest 1 or under | hand 3, foot 2, elbow 2, knee 1.5, shoulder 1.5, head 1 |
| **Never** | a forearm plate (he has none); a closed fist on a straight light; a clawed hand; two fists clasped; a leap on a rising blow; an arm held raised after a blow; more than one turn | a foot that arcs outward (the crescent and the hook kick are the Protagonist's); a rising palm (his too); crossed forearms held; a roll or a cartwheel |
| **Defence** (section 3) | redirects and parries with open hands, catches; never a block | blocks and checks on his plates; never a redirect |
| **Energy** (section 3) | open palm, the ring hand, a flat palm; lobs and flicks | the blade hand, the pinch, the lit fist; thrusts and drops |

- **The "never" rows are of two kinds.** His own (the other fighter's signature shapes, so they stay signatures) and Legal's (section 5). Both are data rows of part values, checked by the generator and again by the validator.
- **The weights are a proposal** drawn from what is written: the Protagonist's circles and arcs and open hands, the rival's blades, plates and straight lines. Art, Narrative and Orb can change a number and regenerate.
- **A drift from the brief to note.** The posed data does not yet match "fists behind plates": 11 of the rival's 15 posed hand strikes land with an open blade hand, 2 with a claw and 2 with a fist. With the weights above his cells ask for fists, which Animation can give by a hand-state swap on the same key sets (section 5).

**Measured on the prototype,** for a martial arts stance of 46 moves each:

| | Shapes the two fighters share |
| :--- | ---: |
| Today's pools | 35 of 36, 97% |
| Generated, preferring what is posed (the first slice's setting) | 19 of 46, 41% |
| Generated, identity first | 14 of 46, 30% |

## 3. Five stances by four buttons

**The matrix below is provisional,** until Game Design's arrives. Buttons are named by position.

| Stance | West | North | East | South |
| :--- | :--- | :--- | :--- | :--- |
| **Martial arts** (nothing held) | hands, light | heavy | legs and knees, light | close: elbow, shoulder, head |
| **Defensive** (LB) | turn a blow aside with the arms | the counter | the low line: shins and steps | slip and sway |
| **Energy arts** (RB) | the bolt | the charged shot | the area shot | the swat and the shove |
| **Charging** (RT) | the charge itself | the charged blow | the burst | the taunt |
| **Manoeuvre** (LT) | the step strike | the pursuit | the grab | the break-off |

### 3.1 How many variants a cell should have

A cell needs enough moves that a string never shows one twice and two strings running do not match, with one limb broken. It does not need more: past that, each extra move costs a look from Animation and a screen from Legal and is seen less often than it is worth.

| Cell kind | Variants | Why |
| :--- | ---: | :--- |
| A light cell in the martial arts stance | 12 to 14 | Pressed up to ten times a second. A string of five never repeats, and with one arm or leg broken at least 8 remain |
| The heavy cell | 12 | Seen once or twice a string, but it carries the lifts, the enders and the guard breaks, each of which wants a few of its own |
| The close cell | 8 | Only 14 shapes exist for elbow, shoulder and head |
| Defensive | 6 each | Two lines (high and mid, or low) by about three manners |
| Energy arts | 6 each | The shot's kind is fixed by the cell; the variants are how it is thrown |
| Charging | 4 to 5 each | Few and memorable: a charge reads by its pose |
| Manoeuvre | 6 to 8 each | 15 entries are posed, and each takes a blow on arrival |

That is **46 moves in the martial arts stance and about 140 across the five,** for each fighter.

**Forms multiply what the player sees, not what is authored.** In the martial arts stance a move lists the forms it can take, by rule: a light on a line, an inward arc or a rise can be a flurry blow; a light that arcs out, drops or kicks can be a skill strike; a heavy can be held, lift, or end a string; a spin is a skill strike or an ender, never a flurry blow. So the mashed flurry and the timed skill strike draw on different moves of the same cell, as Orb asked, and a missed beat falls back to the flurry's moves.

### 3.2 Worked samples: the prototype's output

Seed 20261004. One cell per stance, both fighters. "Keys" says how the move's poses are got (section 5). The martial arts cell is shown at the identity-first setting, where the two fighters differ most; the first slice would run at the setting that prefers what is posed.

**Martial arts, west (hands, light).** 14 moves each; the first 8 are shown. The rival's are chosen from 54 valid shapes and the Protagonist's from 45.

| The rival | Tip | Path | Target | Step | Sends | Beat | Keys |
| :--- | :--- | :--- | :--- | :--- | :--- | ---: | :--- |
| 01 | fist | line | chest | in, hold | across | 20 | hand state: cross |
| 02 | plate | drop | arm | hold, in | down | 26 | new key set |
| 03 | blade | line | gut | in, hold | across | 20 | posed: spear hand |
| 04 | plate | arc in | head | hold, around | turned | 24 | posed: hook |
| 05 | fist | rise | jaw | in, hold | up | 24 | new key set |
| 06 | blade | drop | head | hold, in | down | 26 | new key set |
| 07 | fist | line | arm | in, hold | across | 20 | hand state and re-aim: cross |
| 08 | plate | drop | chest | hold, in | down | 26 | new key set |

| The Protagonist | Tip | Path | Target | Step | Sends | Beat | Keys |
| :--- | :--- | :--- | :--- | :--- | :--- | ---: | :--- |
| 01 | blade | arc in | head | hold, around | turned | 24 | posed: hook |
| 02 | heel | arc out | jaw | around, hold | turned | 24 | re-aim: backfist |
| 03 | palm | rise | gut | in, hold | up | 24 | new key set |
| 04 | blade | drop | arm | hold, in | down | 26 | posed: knife-hand chop |
| 05 | palm | line | chest | in, hold | across | 20 | posed: palm heel |
| 06 | heel | arc out | head | around, hold | turned | 24 | posed: backfist |
| 07 | blade | arc in | jaw | hold, around | turned | 24 | re-aim: hook |
| 08 | palm | rise | chest | in, hold | up | 24 | new key set |

Across all 14, the rival's paths are 4 lines, 3 drops, 3 rises, 3 inward arcs and 1 outward; the Protagonist's are 6 arcs, 3 rises, 2 drops and 3 lines.

**Defensive, LB and west (turn a blow aside with the arms).** Parts: manner, what he does it with, the line covered, the step, and what it sets up.

| The rival | Manner | With | Line | Step | Sets up | Keys |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 01 | block | plate | high | out | a light counter | posed: guard |
| 02 | check | plate | mid | in | a heavy counter | posed: the forearm check |
| 03 | block | both plates | high | hold | a break-off | posed: guard |
| 04 | parry | plate | mid | around | a turn | new |
| 05 | check | plate | mid | hold | a light counter | posed: the forearm check |
| 06 | block | both plates | high | out | a break-off | posed: guard |

| The Protagonist | Manner | With | Line | Step | Sets up | Keys |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 01 | redirect | palm | high | around | a bind | new |
| 02 | parry | blade | mid | hold | a light counter | new |
| 03 | catch | palm | mid | in | a turn | new |
| 04 | redirect | blade | high | around | a heavy counter | new |
| 05 | parry | palm | mid | hold | a turn | new |
| 06 | catch | both hands | high | in | a bind | new |

**Energy arts, RB and west (the bolt).** The shot's kind is the cell's; the parts are the hand, the release, what his body does and the count.

| The rival | Hand | Release | Body | Count | Keys |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 01 | blade hand | thrust | kiting turn | one | posed: his bolt |
| 02 | lit fist | flick | planted | a fan of three | posed: his fan |
| 03 | pinch | drop | rising | one | posed: the shot down |
| 04 | blade hand | thrust | backpedal | a pair | new |
| 05 | lit fist | flick | rising | a fan of three | posed: his fan |
| 06 | clawed palm | thrust | planted | a pair | new |

| The Protagonist | Hand | Release | Body | Count | Keys |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 01 | ring hand | lob | backpedal | one | posed: his lob |
| 02 | palm thrust | flick | kiting turn | a fan of three | posed: his arc of bolts |
| 03 | flat palm | thrust | rising | a pair | new |
| 04 | palm thrust | lob | planted | one | posed: his lob |
| 05 | ring hand | flick | rising | a fan of three | posed: his arc of bolts |
| 06 | flat palm | thrust | kiting turn | a pair | new |

The count changes what the sim fires, so it is not a free variant: a cell may vary it only if Game Design gives each count its numbers. The hand, the release and the body are looks.

**Charging, RT and north (the charged blow).** A charge pose, then a heavy from the strike grammar released from it.

| The rival | Charge pose | Level | Blow | Keys |
| :--- | :--- | :--- | :--- | :--- |
| 01 | low brace | full | a rising fist to the jaw | both posed (uppercut) |
| 02 | channel | partial | a dropping elbow to the chest | both posed |
| 03 | low brace | full | a knee on a line to the gut | both posed (driving knee) |
| 04 | channel | partial | a blade on an inward arc to the head | both posed (haymaker) |
| 05 | channel | full | both soles on a line to the chest | both posed (drop kick) |

| The Protagonist | Charge pose | Level | Blow | Keys |
| :--- | :--- | :--- | :--- | :--- |
| 01 | open-hand brace | full | a blade on an inward arc to the head | both posed (haymaker) |
| 02 | coil | partial | a sole dropping to the gut | both posed (stomp) |
| 03 | open-hand brace | full | a spinning heel to the chest | both posed |
| 04 | coil | partial | a palm on a line to the arm | pose posed; blow re-aimed (double palm) |
| 05 | coil | full | the edge of the foot arcing out to the gut | pose posed; blow re-aimed (crescent kick) |

**Manoeuvre, LT and west (the step strike).** An entry, its direction, and a light on arrival whose path suits the direction (a rise from under, a drop or an outward arc from over, an arc from around).

| The rival | Entry | Direction | Blow on arrival | Keys |
| :--- | :--- | :--- | :--- | :--- |
| 01 | dash | toward | the ball of the foot on a line to the gut | both posed (front kick) |
| 02 | rising | under | a rising fist to the jaw | entry posed; blow new |
| 03 | step in | toward | a blade on a line to the chest | both posed (cross) |
| 04 | lane step | around | the instep arcing in to the shins | both posed (sweep) |
| 05 | arc dive | over | the plate dropping on the arm | entry posed; blow new |
| 06 | fade | away | the edge of the foot on a line to the chest | both posed (side kick) |

| The Protagonist | Entry | Direction | Blow on arrival | Keys |
| :--- | :--- | :--- | :--- | :--- |
| 01 | pivot | around | the instep arcing in to the shins | both posed (sweep) |
| 02 | air roll | over | the back of the fist arcing out to the head | both posed (backfist) |
| 03 | cartwheel step | around | a blade arcing in to the jaw | entry posed; blow re-aimed (hook) |
| 04 | rising | under | a rising palm to the gut | entry posed; blow new |
| 05 | fade | away | the edge of the foot on a line to the chest | both posed (side kick) |
| 06 | arc dive | over | a blade dropping on the arm | both posed (knife-hand chop) |

Both fighters got the fade into a side kick. That is the identity setting at work: shared shapes are allowed, and the "never" rows and weights decide how many.

## 4. Generated offline, chosen at run time

**I agree with offline generation, a seed and a review sheet.** The moveset is vocabulary, and vocabulary has to be seen before it ships: Animation must know which key sets to make, Legal must screen a fixed list, QA must be able to count it, and Orb must be able to look at it. A director that invented shapes during a match could show none of them in advance.

| Offline, into data | At run time, by the director |
| :--- | :--- |
| Which moves exist in each cell, with all their parts | Which move of the cell this press plays: a keyed draw, past his last two picks |
| Each move's key set and how it is got | The range step, from the two allowed, by where the rival is |
| The pools and the `pieces` block of `recipes.json`, written from the cells | The form, from how the press was made (mashed, timed, held) |
| The review sheet | The order of a string, by the `links` rule or a drawn pattern |
| | What is closed right now: gates (ground, band, stance), broken limbs, pieces still waiting |

**The pipeline.**
1. **Inputs,** all Combat's data: the grammar's four tables, the identity blocks, the cells (from Game Design's matrix), and the seed.
2. **Generate.** For each cell: every valid shape the identity allows, scored by the identity weights, by how its keys are got, and by a small keyed jitter; then picked one at a time, each pick marking down the shapes that share its path, target or tip, so a cell spreads over the grammar and does not cluster.
3. **The sheet.** One row a move: its parts, its hooks, its keys, the Legal rows it passed, and Animation's picture of its contact pose.
4. **Review.** Combat, Animation and Legal mark each new row accept, change or reject. Orb sees the accepted sheet.
5. **Lock.** Accepted moves are written to the fighter's moveset file and keep their ids for good. Rejected shapes go on a list the generator never proposes again.

**Determinism.** The only randomness is a hash of the seed, the fighter, the cell and the shape: there is no generator state. The same inputs give the same file, byte for byte, and CI checks it. The file is hashed with the combat data, so a replay names the moveset it ran on.

**Growth is by appending.** Adding a part or raising a count fills only the free places of a cell; locked moves do not move. A full regeneration (a new seed, or a changed weight) is a deliberate act with its own sheet, because Animation's work hangs on the ids.

## 5. What it asks of Animation, Tools and Legal

### 5.1 Animation: can poses be composed?

Partly, and more than is used today. A pose is a parametric sketch, the striking limb is solved onto the target's socket at contact, and one fighter's wave is already derived from another's by profile. So a move's keys come at four levels:

| Level | What it is | Needs |
| :--- | :--- | :--- |
| **Posed** | a key set that exists, as it is | nothing |
| **Hand state** | the same key set with the hand closed, bladed or opened (fist, blade, palm), for a hand on the same path | a hand state per key set, set from the move's tip: the swap the Protagonist's profile already does for claws |
| **Re-aim** | the same key set landing on a neighbouring socket (head and jaw; chest, gut and arm; legs and shins), for hands and feet | the contact solve, inside the limb's reach; a look at each on the sheet |
| **New key set** | no posed strike has this limb and path | composed from a template (below), or drawn |

**What the 80 posed strikes can already express.** The 80 manifest rows are 44 strike ids. Counted as shapes of the grammar:

| | Posed strikes | Shapes as posed | With a hand-state swap | With a re-aim | With both | Total | Of the shapes his identity allows |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| The rival | 36 | 35 | 8 | 19 | 7 | **69** | 39% of 179 |
| The Protagonist | 43 | 37 | 8 | 19 | 9 | **73** | 42% of 172 |

So what is posed reaches about twice as many moves as it plays today, with no new key set.

**For a 46-move martial arts stance:**

| Setting | The rival | The Protagonist | New key sets |
| :--- | :--- | :--- | ---: |
| Preferring what is posed | 30 posed, 8 by swap or re-aim | 29 posed, 9 by swap or re-aim | 8 each |
| Identity first | 22 posed, 7 by swap or re-aim | 23 posed, 7 by re-aim | 17 and 16 |

**The asks:**
1. **A `tip` and a `path` on every manifest row,** so the counts above are read from Animation's data and not from my reading of each look.
2. **Confirm the two derivations:** the hand-state swap, and how far the contact solve can re-aim before the silhouette breaks. My neighbour table is a guess to correct.
3. **Path templates for new key sets:** a chamber, a contact and a follow for each limb and path (about 20), with the target's height as a parameter, composed offline by `wave_gen` under the fighter's profile and the joint limits. Each composed set still gets a look on the sheet. If templates do not read well enough, a new key set is drawn, three sketches each.
4. **What stays hand-drawn:** spins, each fighter's identity core, held poses (charges, taunts, energy hands), and almost all of the defensive stance, where only the guard and two checks are posed.

### 5.2 Tools: the schemas

| File | Schema | Holds |
| :--- | :--- | :--- |
| `data/combat/parts.json` | `combat.parts/1` | the grammar: tips by limb, paths by tip, targets by limb and path, the weight rule, `links`, and the rules that derive `sends`, the step and the beat; one block for each stance's parts |
| `data/combat/identity.json` | `combat.identity/1` | for each fighter: weights by tip, path and limb, the `never` rows, the reuse setting, the rejected shapes |
| `data/combat/cells.json` | `combat.cells/1` | stance by button: the cell's class, its filter over the parts, its least and most variants |
| `data/combat/movesets/<fighter>.json` | `combat.moveset/1` | generated and locked: the generator's version, the seed and the inputs' hash, then for each cell its moves: id, parts, forms, step, hooks, keys (level and the key set it starts from), the Legal rows passed, the review state |

Cross-checks:
- every move is a valid shape of `parts.json`, and matches no `never` row and no banned shape;
- no cell holds a shape twice; each cell is inside its count;
- a move's key set is a manifest row when its level says posed, swapped or re-aimed;
- the pools and `pieces` of `recipes.json` agree with the moveset files;
- **the generated files are up to date:** generating again from the committed inputs gives the committed files.

The generator itself is a script under `tools/`, so it is Tools' to hold. The prototype is Python in Combat's scratch and can be handed over as the reference.

### 5.3 Legal: the screen rule

A generated move must not land on a franchise's signature move. Four layers, the first two automatic:

1. **Banned shapes, as data.** Each row is a set of part values with a reason in plain words, and no franchise's name. The generator never emits a match, and the validator checks again. The list starts from Legal's rulings already in the manifests and the review log: no hand chambered at the hip; no two fists clasped; no leap on a rising blow; no arm held raised after it; one turn at most; wrists apart; no crossed forearms held; no fist punched ahead and not both arms trailed back on an entry; and for energy, no two-finger hand, no cupped hands, no two-hand push from the chest, no sphere growing in a palm.
2. **Marks.** A part value can carry one of the stacking rule's seven marks. A move or a phrase that would stack three is not generated; two goes to the manual screen.
3. **The sheet.** Legal screens only the shapes that are new since the last lock: go, change or no. A "no" becomes a banned shape, widened to the pattern behind it, so it cannot come back in another cell or for another fighter.
4. **Where the eye is always needed.** A single strike is ordinary martial arts. The risk is in what is held and what is strung together: charge poses, energy hands, taunts, entries, and any named phrase (a pattern, a showcase, a finisher). Those are screened by eye every time.

The prototype's own output shows why. The rival's second step strike is a rising entry into a rising fist under the jaw: legal with his feet staying down and no turn, and exactly the row the "no leap" shape exists for.

**Names.** A generated move has an id made of its cell and a number, and is described by its parts. It gets a name only from Narrative, with Legal's phrase search.

## 6. The first slice: the martial arts stance, for both fighters

It is the stance the approved brawl plays in, most of it is posed, and Encounter's press-to-blow work needs a pool for each button.

| Who | What |
| :--- | :--- |
| **Game Design** | the four cells of the stance (the matrix), and the class numbers of each form |
| **Combat** | `parts.json` (the strike grammar), the two identity blocks, the four cells; run the generator at the setting that prefers what is posed; the sheet; then the lock |
| **Tools** | the four schemas and the cross-checks; the generator under `tools/` |
| **Animation** | `tip` and `path` on the manifests; the hand-state swap and the re-aim; 8 new key sets for each fighter |
| **Legal** | the banned shapes as data; the screen of 92 rows, 16 of them new key sets |
| **Encounter** | a pool for each button in the brawl; the `links` rule as a preference when it orders a string; the beat point by move |
| **QA** | the tests below |

**Exit:**
- Each fighter has 46 moves over the four cells: 38 from what is posed and 8 new.
- The two fighters share under 45% of their shapes (97% today).
- With one arm or one leg broken, each light cell still has 8 moves.
- No string of five shows a move twice.
- Every move has passed the banned shapes, and every new shape has Legal's go.
- Generating again from the seed gives the same files.

**After it:** the manoeuvre stance (the entries are posed, and it reuses the strike grammar on arrival), then energy arts, charging, and the defensive stance last, since it needs the most new poses.

## 7. Open, through the EP

| For | Question |
| :--- | :--- |
| **Game Design** | The matrix. Whether a cell may hold variants that change what the sim does (a pair of bolts against one), or only looks. The forms' numbers |
| **Orb** | The identity weights read as "open hands and arcs" against "fists, plates and straight lines": is that the split wanted, and should the rival's posed blade hands become fists? The rival's tail is still waiting, and would add an `own` limb to his cells |
| **Animation** | The four asks in section 5.1 |
| **Art and Narrative** | The "never" rows of each fighter |
