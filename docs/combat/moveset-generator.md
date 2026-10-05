# The moveset generator

Owner: Combat and Choreography. Date: 2026-10-04. Status: a design, with a scratch prototype behind its numbers. Nothing in the tree is edited. Written against HEAD `5ed93bf`; the cells are Game Design's matrix (`docs/design/melee-press-feel.md` sections 10, 11 and 13, on disk).

**Orb's direction** (`docs/ep/vision.md`, last two sections): five stances by what is held (none: the fighter's martial arts stance; LB: defensive; RB: energy arts; RT: charging; LT: manoeuvre), "all face buttons should have an appropriately broad moveset for each stance", and "a way to generatively work all these stances into vast and varied movesets for each character". In the brawl each press is a blow: mashing gives faster flurries, timing gives flashy skill attacks that lapse into flurries, and the heavy beats a heavy guard and sets up juggles.

**What this replaces.** Today a fighter's moveset is a hand-kept list: 36 posed strikes for the rival and 43 for the Protagonist, sorted by hand into seven pools (`data/combat/recipes.json`). The two lists share 35 strikes, which is 97% of the smaller one. The generator composes each fighter's moves from parts under his own rules, so the lists grow by data and the two fighters stop sharing a moveset.

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
| **Form** | how the press was made, which sets its speed and timing class | light, flurry blow, skill strike, heavy, held heavy, ender, juggle strike | Game Design's forms table (`melee-press-feel.md` section 13) |
| **Hooks** | what it leaves behind | `sends` (across, up, down, turned), `links` (the paths that flow out of it), `beat` (the tick of its beat point) | the `sends` and `ends` tags; the blur patterns |
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
- The beat point follows the path: 20 ticks for a line, 24 for an arc or a rise, 26 for a drop, 28 for a spin. Game Design has accepted these.
- **A variant may change how a press is delivered, and never what it is worth** (Game Design's rule). Its role, its timing, its reach band, its damage and ki, and its result are the cell's and the form's. Two moves of one cell differ in limb, tip, target, path, step and what follows them best. So no generated move can be the best button.

**What exists and where it goes:**

| Exists | Becomes |
| :--- | :--- |
| `pieces` (limb, target) | the part table: it gains `tip` and `path` |
| The seven pools | written by the generator from the cells, so Encounter's reader does not change |
| Blur patterns and `patternGates` | the `links` rule orders a string; the eight patterns stay as named phrases the director may still draw; gates gain `stance` |
| Strike rows (range, ticks, tags) | the numbers of a posed key set, unchanged |
| Finishers and signatures | frames with slots, filled from the cells (section 3.2, martial B) |

## 2. Identity: the same grammar, two different fighters

Each fighter has an identity block: a weight for every tip, path and limb, a list of shapes he never makes, and how strongly to prefer what is already posed. The selector multiplies the weights, so his cells fill with his own shapes first.

| | The Protagonist | The rival |
| :--- | :--- | :--- |
| **Tips he favours** | palm 3, blade 3, heel 2; the edge of the foot 2.5 | fist 3, plate 3, blade 2.5; the elbow's point 2.5, the knee 2 |
| **Tips he avoids** | fist 0.4; the brow 0.2 | palm 0.6 |
| **Paths** | arc in 3, arc out 3, spin 2, rise 2, drop 1.5, line 1 | line 3, drop 2.5, rise 1.5, arc in 1, arc out 0.5, spin 0.5 |
| **Limbs** | hand 3, foot 3, the rest 1 or under | hand 3, foot 2, elbow 2, knee 1.5, shoulder 1.5, head 1 |
| **Never** | a forearm plate (he has none); a closed fist on a straight light; a clawed hand; two fists clasped; a leap on a rising blow; an arm held raised after a blow; more than one turn | a foot that arcs outward (the crescent and the hook kick are the Protagonist's); a rising palm (his too); crossed forearms held; a roll or a cartwheel |

- **The "never" rows are of two kinds.** His own (the other fighter's signature shapes, so they stay signatures) and Legal's (section 5). Both are data rows of part values, checked by the generator and again by the validator.
- **The weights are a proposal** drawn from what is written: the Protagonist's circles and arcs and open hands, the rival's blades, plates and straight lines. Art, Narrative and Orb can change a number and regenerate.
- **A drift from the brief to note.** The posed data does not yet match "fists behind plates": 11 of the rival's 15 posed hand strikes land with an open blade hand, 2 with a claw and 2 with a fist. With the weights above his cells ask for fists, which Animation can give by a hand-state swap on the same key sets (section 5).

**Measured on the prototype,** over the martial arts stance's two strike cells (46 moves each):

| | Shapes the two fighters share |
| :--- | ---: |
| Today's pools | 35 of 36, 97% |
| Generated, preferring what is posed (the first slice's setting) | 21 of 46, 46%: 53% of the lights and 31% of the heavies |
| Generated, identity first | 16 of 46, 35% |

## 3. Five stances by four buttons

**The matrix is Game Design's.** One rule runs across every stance: X is the quick action, Y the strong one, A the stance's context action, and B its signature.

| Stance | X: quick | Y: strong | A: context | B: signature |
| :--- | :--- | :--- | :--- | :--- |
| **Martial arts** (nothing held) | light strikes: flurry blows and skill strikes | heavy strikes: the guard breaker, the lift, the ender | grab and throw, pick-up, civilians, the taunt at range, a dive grab in the air; held, his channel | his defining signature, a melee art (45 ki) |
| **Defensive** (LB) | the check; timed after a blocked blow, a parry | the push | reversal after a block; deflect at range | a counter (an art, 25 ki) |
| **Energy arts** (RB) | bolts and volleys | the charged shot; a short beam; the split | a mine at range; the shove in reach | the beam (45 ki) |
| **Charging** (RT) | his quick special | his strong special | his utility special | his ultimate (75 ki) |
| **Manoeuvre** (LT) | the step strike; beyond reach, the piloted light lunge | a heavy on the move; the piloted heavy charge; the pursuit | tackle, dive grab, a snatch on the fly | a terrain art (25 ki) |

Three hybrids are reserved and not built: LT with RB, LB with RB, LT with LB.

### 3.1 How many moves a cell holds

| Cell | Moves | Why |
| :--- | ---: | :--- |
| **Martial X** | 30 | Every light shape: hands, feet and the close limbs. It is pressed up to ten times a second, and the stick leans the pick five ways, so each lean needs its own depth |
| **Martial Y** | 16 | Every heavy shape. It carries the lifts, the enders and the guard breaks, and an ender is picked by where it sends |
| **Martial A** | one action for each context, in 2 or 3 looks | The context decides the action; only the look varies |
| **Martial B** | 1 signature, in at least 3 variants | Hand-picked pieces in a generated frame |
| Defensive and energy cells | 6 each | The action is fixed by the cell; the variants are the limb and line, or how a shot is thrown |
| Charging cells | 4 or 5 looks for each special | Few and memorable |
| Manoeuvre cells | 6 to 8 each | 15 entries are posed, and each takes a blow on arrival |

That is 46 strikes in the martial arts stance, and about 140 moves across the five, for each fighter.

**The stick leans the pick** inside X and Y (Game Design): nothing held favours hands on a line or an arc; toward, the close limbs; away, feet; up, rising shapes and high targets; down, dropping shapes and low targets. It is a weight of 3 and not a filter. So the generator fills **quotas** before it fills freely: **at least 5 moves under each lean in X, and at least 3 heavies for each way of sending in Y** (up, down, across, turned). A quota is one more data row on the cell.

**Forms multiply what the player sees, not what is authored.** A move lists the forms it can take, by rule: a light on a line, an inward arc or a rise can be a flurry blow; a light that arcs out, drops or kicks can be a skill strike or a juggle strike; a heavy can be held, lift, or end a string; a spin is a skill strike or an ender, never a flurry blow. So the mashed flurry and the timed skill strike draw on different moves of the same cell, as Orb asked, and a missed beat falls back to the flurry's moves. The forms' numbers are Game Design's table.

**A press may be delivered as 1, 2 or 3 pieces** that share the cell's damage and ki (Game Design): two bolts for one, or a double tap for one strike. The piece count is data on the move, and it is the only way a variant touches what the sim does.

### 3.2 Worked samples: the prototype's output

Seed 20261004, at the first slice's setting (preferring what is posed). "Keys" says how the move's poses are got (section 5).

**Martial X: light strikes.** 30 moves each, from 81 valid shapes for the rival and 75 for the Protagonist. The first 10 are shown; the quotas put the close limbs and the feet first.

| The rival | Limb | Tip | Path | Target | Step | Sends | Beat | Keys |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | ---: | :--- |
| 01 | shoulder | plate | line | chest | in, hold | across | 20 | posed: shoulder check |
| 02 | elbow | point | rise | jaw | in, hold | up | 24 | posed: rising elbow |
| 03 | knee | cap | line | gut | in, hold | across | 20 | posed: short knee |
| 04 | elbow | point | arc in | jaw | hold, around | turned | 24 | posed: short elbow |
| 05 | elbow | point | drop | chest | hold, in | down | 26 | new key set |
| 06 | foot | ball | line | gut | in, hold | across | 20 | posed: front kick |
| 07 | foot | instep | arc in | legs | hold, around | turned | 24 | posed: low kick |
| 08 | foot | edge | line | chest | in, hold | across | 20 | posed: side kick |
| 09 | foot | instep | arc in | shins | hold, around | turned | 24 | posed: sweep |
| 10 | foot | instep | arc in | chest | hold, around | turned | 24 | posed: snap round |

| The Protagonist | Limb | Tip | Path | Target | Step | Sends | Beat | Keys |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | ---: | :--- |
| 01 | elbow | point | arc in | jaw | hold, around | turned | 24 | posed: short elbow |
| 02 | elbow | point | rise | jaw | in, hold | up | 24 | posed: rising elbow |
| 03 | knee | cap | line | gut | in, hold | across | 20 | posed: short knee |
| 04 | knee | cap | arc in | legs | hold, around | turned | 24 | new key set |
| 05 | elbow | point | drop | chest | hold, in | down | 26 | new key set |
| 06 | foot | heel | arc out | chest | around, hold | turned | 24 | posed: hook kick |
| 07 | foot | instep | arc in | shins | hold, around | turned | 24 | posed: sweep |
| 08 | foot | edge | line | chest | in, hold | across | 20 | posed: side kick |
| 09 | foot | instep | arc in | legs | hold, around | turned | 24 | posed: low kick |
| 10 | foot | heel | arc out | gut | around, hold | turned | 24 | re-aim: hook kick |

Over all 30: the rival has 16 hand, 7 foot, 3 elbow, 3 knee and 1 shoulder; 10 lines, 7 inward arcs, 5 rises, 5 drops and 3 outward arcs. The Protagonist has 16 hand, 9 foot, 3 elbow and 2 knee; 13 arcs, 7 lines, 5 rises and 5 drops. Under the stick the rival has 10, 7, 7, 13 and 9 moves (nothing, toward, away, up, down) and the Protagonist 9, 5, 9, 13 and 9.

**Martial Y: heavy strikes.** 16 each, from 98 and 97 valid shapes. The first 8 are shown; the quotas put three of each send first.

| The rival | Limb | Tip | Path | Target | Sends | Keys |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 01 | hand | fist | rise | jaw | up | posed: uppercut |
| 02 | knee | cap | rise | gut | up | posed: rising knee |
| 03 | hand | fist | rise | chest | up | new key set |
| 04 | hand | plate | drop | head | down | posed: double hammer |
| 05 | elbow | point | drop | chest | down | posed: dropping elbow |
| 06 | hand | blade | drop | head | down | posed: overhand |
| 07 | hand | blade | line | chest | across | posed: rib shot |
| 08 | knee | cap | line | gut | across | posed: driving knee |

| The Protagonist | Limb | Tip | Path | Target | Sends | Keys |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 01 | hand | palm | rise | jaw | up | posed: rising palm |
| 02 | knee | cap | rise | gut | up | posed: rising knee |
| 03 | hand | fist | rise | jaw | up | posed: uppercut |
| 04 | hand | blade | drop | head | down | posed: double hammer |
| 05 | foot | heel | drop | chest | down | posed: axe kick |
| 06 | foot | sole | drop | gut | down | posed: stomp |
| 07 | hand | palm | line | chest | across | posed: double palm |
| 08 | foot | sole | line | chest | across | posed: drop kick |

**Martial B: the defining signature.** Game Design: a rush of his own strikes that ends in a launch, opening with a lunge from the mid band; a generated frame with hand-picked pieces. The frame: a tell of at least 30 ticks; a rush of four lights from his X cell, ordered by the `links` rule, his hand-picked pieces first; then a launcher from his Y cell, chosen by where the variant sends.

| The rival | The rush | The launcher |
| :--- | :--- | :--- |
| High in the air | the plate dropped on the arm (new), cross, short elbow, spear hand | the dropping elbow, down |
| On the ground | cross, short elbow, a cross to the arm (re-aimed), hook | the rising knee, up |
| Against a guard | a fist dropped on the head (new), cross, short elbow, a cross to the arm | the body ram, across |

| The Protagonist | The rush | The launcher |
| :--- | :--- | :--- |
| On the ground or low | low kick, hook kick, knife-hand chop, palm heel | the rising palm, up |
| In the air | hook kick, knife-hand chop, palm heel, hammer-fist | the double palm, across |
| Against a guard | knife-hand chop, palm heel, hammer-fist, front kick | the spinning back kick, turned |

The same two or three pieces come back in every variant (the cross and the short elbow; the knife-hand chop and the palm heel). That is the hand-picked spine doing its work: the signature is recognisable, and the rest is fresh.

**Defensive X: the check,** a short blow from behind the guard. The strike grammar, narrowed to short paths (line, rise, arc in) by hand, elbow or knee, thrown over the guard pose.

| | The rival | The Protagonist |
| :--- | :--- | :--- |
| 01 | a blade on a line to the chest (posed: cross) | a blade on a line to the chest (posed: cross) |
| 02 | a blade on a line to the gut (posed: spear hand) | a blade arcing in to the jaw (re-aim: hook) |
| 03 | a rising elbow to the jaw (posed) | a palm on a line to the gut (hand state: spear hand) |
| 04 | an elbow arcing in to the jaw (posed: short elbow) | a rising elbow to the jaw (posed) |
| 05 | a fist on a line to the chest (hand state: cross) | a palm on a line to the chest (posed: palm heel) |
| 06 | a knee on a line to the gut (posed: short knee) | an elbow arcing in to the jaw (posed: short elbow) |

**Energy X: the bolt.** The shot's kind is the cell's; the parts are the hand, the release, what his body does and the count.

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

The count is the piece count of Game Design's delivery rule: a pair or a fan shares one press's damage and ki, and counts once.

**Charging X: his quick special.** A special is a fixed frame for each fighter; the generator makes its looks. The rival's is the cutting step of wave 7 (a change of level and a wide cutting blow as he arrives). The Protagonist's specials are not designed, so his row is a placeholder frame: a turn that carries him round the rival, and an arc on arrival.

| | The rival: level, how he gets there, the blow | The Protagonist (placeholder): the turn, where he comes out, the blow |
| :--- | :--- | :--- |
| 01 | up; a dash from out of reach; haymaker | air roll; over; crescent kick |
| 02 | down; a step in reach; spinning elbow | pivot; around; ridge hand |
| 03 | up; a dash from out of reach; roundhouse | cartwheel step; around; spinning back kick |
| 04 | down; a step in reach; spinning heel | air roll; over; hook kick |
| 05 | up; a step in reach; spinning elbow | pivot; around; crescent kick |

**Manoeuvre X: the step strike.** A step around, over or under the rival, by the stick, and a light on arrival whose path suits the direction (an arc from around, a drop or an outward arc from over, a rise or a line from under).

| The rival | Entry | Direction | Blow on arrival | Keys |
| :--- | :--- | :--- | :--- | :--- |
| 01 | lane step | around | the instep arcing in to the legs | both posed (low kick) |
| 02 | arc dive | over | the back of the fist arcing out to the head | both posed (backfist) |
| 03 | rising | under | the ball of the foot on a line to the gut | both posed (front kick) |
| 04 | pivot | around | the plate arcing in to the head | both posed (hook) |
| 05 | arc dive | over | a fist dropped on the head | entry posed; blow new |
| 06 | coil spring | under | the edge of the foot on a line to the chest | both posed (side kick) |
| 07 | lane step | around | the instep arcing in to the shins | both posed (sweep) |
| 08 | arc dive | over | the back of the fist arcing out to the jaw | entry posed; blow re-aimed (backfist) |

| The Protagonist | Entry | Direction | Blow on arrival | Keys |
| :--- | :--- | :--- | :--- | :--- |
| 01 | pivot | around | the back of the fist arcing out to the head | both posed (backfist) |
| 02 | air roll | over | the hammer-fist dropped on the head | both posed |
| 03 | rising | under | the ball of the foot on a line to the gut | both posed (front kick) |
| 04 | cartwheel step | around | the instep arcing in to the shins | both posed (sweep) |
| 05 | arc dive | over | the heel arcing out to the chest | both posed (hook kick) |
| 06 | rising | under | a blade on a line to the gut | both posed (spear hand) |
| 07 | spiral | around | the instep arcing in to the legs | both posed (low kick) |
| 08 | air roll | over | a blade dropped on the arm | both posed (knife-hand chop) |

## 4. Generated offline, chosen at run time

**I agree with offline generation, a seed and a review sheet.** The moveset is vocabulary, and vocabulary has to be seen before it ships: Animation must know which key sets to make, Legal must screen a fixed list, QA must be able to count it, and Orb must be able to look at it. A director that invented shapes during a match could show none of them in advance.

| Offline, into data | At run time, by the director (Game Design's order) |
| :--- | :--- |
| Which moves exist in each cell, with all their parts | 1. The situation removes what cannot be thrown: air, ground, wall, water; the form; a broken limb |
| Each move's key set and how it is got | 2. The range picks the close pieces or the lunge pieces |
| The pools and the `pieces` block of `recipes.json`, written from the cells | 3. The stick leans the pick |
| The quotas each cell was filled to | 4. The last presses rule out a repeat inside the string |
| The review sheet | 5. The flow unlocks the showier variants |
| | 6. A seeded draw settles what is left |

**The pipeline.**
1. **Inputs,** all Combat's data: the grammar's four tables, the identity blocks, the cells with their counts and quotas (from Game Design's matrix), and the seed.
2. **Generate.** For each cell: every valid shape the identity allows, scored by the identity weights, by how its keys are got, and by a small keyed jitter; then picked one at a time, quotas first, each pick marking down the shapes that share its path, target or tip, so a cell spreads over the grammar and does not cluster.
3. **The sheet.** One row a move: its parts, its hooks, its keys, the Legal rows it passed, and Animation's picture of its contact pose.
4. **Review.** Combat, Animation and Legal mark each new row accept, change or reject. Orb sees the accepted sheet.
5. **Lock.** Accepted moves are written to the fighter's moveset file and keep their ids for good. Rejected shapes go on a list the generator never proposes again.

**Determinism.** The only randomness is a hash of the seed, the fighter, the cell and the shape: there is no generator state. The same inputs give the same file, byte for byte, and CI checks it. The file is hashed with the combat data, so a replay names the moveset it ran on.

**Growth is by appending.** Adding a part or raising a count fills only the free places of a cell; locked moves do not move. A full regeneration (a new seed, or a changed weight) is a deliberate act with its own sheet, because Animation's work hangs on the ids.

**The move list is free.** Orb's answers ask for a per-fighter move list first, before a practice mode. It is the moveset file printed by cell.

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

**The asks:**
1. **A `tip` and a `path` on every manifest row,** so the counts are read from Animation's data and not from my reading of each look.
2. **Confirm the two derivations:** the hand-state swap, and how far the contact solve can re-aim before the silhouette breaks. My neighbour table is a guess to correct.
3. **Path templates for new key sets:** a chamber, a contact and a follow for each limb and path (about 20), with the target's height as a parameter, composed offline by `wave_gen` under the fighter's profile and the joint limits. Each composed set still gets a look on the sheet. If templates do not read well enough, a new key set is drawn, three sketches each.
4. **What stays hand-drawn:** spins, each fighter's hand-picked pieces, held poses (signature tells, charges, taunts, energy hands), and the guard layer the checks are thrown over.

### 5.2 Tools: the schemas

| File | Schema | Holds |
| :--- | :--- | :--- |
| `data/combat/parts.json` | `combat.parts/1` | the grammar: tips by limb, paths by tip, targets by limb and path, the weight rule, `links`, and the rules that derive `sends`, the step, the beat and the forms; one block for each stance's parts |
| `data/combat/identity.json` | `combat.identity/1` | for each fighter: weights by tip, path and limb, the `never` rows, the reuse setting, his hand-picked pieces, the rejected shapes |
| `data/combat/cells.json` | `combat.cells/1` | stance by button: the cell's filter over the parts, its count, its quotas (the stick's five leans, the four sends), and for a frame cell (a signature, a special) its slots |
| `data/combat/movesets/<fighter>.json` | `combat.moveset/1` | generated and locked: the generator's version, the seed and the inputs' hash, then for each cell its moves: id, parts, forms, piece count, step, hooks, keys (level and the key set it starts from), the Legal rows passed, the review state |

Cross-checks:
- every move is a valid shape of `parts.json`, and matches no `never` row and no banned shape;
- no cell holds a shape twice; each cell meets its count and its quotas;
- a move delivered in pieces has shares that add up to the cell's values (Game Design's rule);
- a move's key set is a manifest row when its level says posed, swapped or re-aimed;
- the pools and `pieces` of `recipes.json` agree with the moveset files;
- **the generated files are up to date:** generating again from the committed inputs gives the committed files.

The generator itself is a script under `tools/`, so it is Tools' to hold. The prototype is Python in Combat's scratch and can be handed over as the reference.

### 5.3 Legal: the screen rule

A generated move must not land on a franchise's signature move. Four layers, the first two automatic:

1. **Banned shapes, as data.** Each row is a set of part values with a reason in plain words, and no franchise's name. The generator never emits a match, and the validator checks again. The list starts from Legal's rulings already in the manifests and the review log: no hand chambered at the hip; no two fists clasped; no leap on a rising blow; no arm held raised after it; one turn at most; wrists apart; no crossed forearms held; no fist punched ahead and not both arms trailed back on an entry; and for energy, no two-finger hand, no cupped hands, no two-hand push from the chest, no sphere growing in a palm.
2. **Marks.** A part value can carry one of the stacking rule's seven marks. No moment may show more than two, so a move or a frame that would stack three is not generated, and two goes to the manual screen.
3. **The sheet.** Legal screens only the shapes that are new since the last lock: go, change or no. A "no" becomes a banned shape, widened to the pattern behind it, so it cannot come back in another cell or for another fighter.
4. **Where the eye is always needed.** A single strike is ordinary martial arts. The risk is in what is held and what is strung together: signature tells, charge poses, energy hands, taunts, entries, and every frame (a signature, a special, a pattern, a finisher). Those are screened by eye every time.

The prototype's own output shows why. One of the rival's heavies is a rising fist to the jaw, and one of his step strikes rises from under the rival: together they are legal only with his feet staying down and no turn, which is exactly the row the "no leap" shape exists for.

**Names.** A generated move has an id made of its cell and a number, and is described by its parts. It gets a name only from Narrative, with Legal's phrase search.

## 6. The first slice: the martial arts stance, for both fighters

X, Y, A and the defining signature on B. It is where most of a match is spent, most of it is posed, and it is the first build in Orb's sequencing.

### 6.1 Sized against the matrix

At the setting that prefers what is posed, with the quotas of section 3.1:

| Cell | Moves | The rival: posed, derived, new | The Protagonist: posed, derived, new |
| :--- | ---: | :--- | :--- |
| **X**, light strikes | 30 | 14, 4, **12** | 16, 6, **8** |
| **Y**, heavy strikes | 16 | 13, 2, **1** | 14, 2, **0** |
| **Both strike cells** | 46 | 27, 6, **13** | 30, 8, **8** |
| **A**, context | 5 actions and the held channel | Today's actions and their shared poses. His taunts (4 far, 1 close) and On the Chin (6 poses) are posed. New: nothing | Today's actions and their shared poses. His taunts (3 far, 1 close) are posed; he has no channel yet. New: nothing |
| **B**, the defining signature | 1 frame, 3 variants | The rush and the launchers are X and Y moves. New: the tell and the held end, **2 sketches** | The same: **2 sketches** |

- **"Derived"** is a hand-state swap or a re-aim on a posed key set: no new sketch, a look on the sheet.
- **21 new strike key sets and 4 signature sketches in all.** 20 of the 21 are lights: the posed sets hold 16 lights for the rival and 20 for the Protagonist, and X asks for 30.
- **The slice can start on what is posed.** New moves sit in the file as waiting, and the director skips them: X plays at 18 for the rival and 22 for the Protagonist from the first day, and Y at 15 and 16. Each key set that arrives turns one move on.
- **With a leg broken on the ground** X keeps 20 and 19 moves, and Y keeps 13 and 7. The Protagonist's heavies lean on his legs; 7 is enough for a cell thrown once or twice a string, and in the air he has all 16.
- **A second look for each grab and throw** waits for wave 4's grabs (16 designed, none posed), outside this slice.

**If 21 new key sets is too many for the slice,** the lever is X's count, and it costs sameness:

| X holds | New light key sets (rival, Protagonist) | Lights the two share |
| ---: | :--- | ---: |
| 30, as above | 12 and 8 | 53% |
| 30, reusing harder | 9 and 5 | 57% |
| 26 | 9 and 6 | 54% |
| 24, reusing harder | 5 and 3 | 67% |

I recommend 30 as above, started on what is posed.

### 6.2 Who does what

| Who | What |
| :--- | :--- |
| **Combat** | `parts.json` (the strike grammar), the two identity blocks with their hand-picked pieces, the four cells; run the generator; the sheet; then the lock |
| **Tools** | the four schemas and the cross-checks; the generator under `tools/` |
| **Animation** | `tip` and `path` on the manifests; the hand-state swap and the re-aim; 21 new key sets and 4 signature sketches |
| **Legal** | the banned shapes as data; the screen of 92 strike rows (21 new shapes by eye) and the two signature frames |
| **Encounter** | a pool for each button in the brawl; the stick's lean; the `links` rule as a preference when it orders a string; the beat point by move; the signature frame's slots |
| **QA** | the tests below |

**Exit:**
- Each fighter has 30 lights and 16 heavies in the file, with at least 18 lights and 15 heavies playable.
- Under each lean of the stick, X has at least 5 moves; Y has at least 3 heavies for each send.
- The two fighters share under 50% of their shapes (97% today).
- No string shows a move twice, and the same three-blow series comes in under 10% of strings (Game Design's bands).
- Every move has passed the banned shapes, and every new shape has Legal's go.
- Generating again from the seed gives the same files.

**After it:** the manoeuvre stance (the entries are posed, and it reuses the strike grammar on arrival), then energy arts, the defensive stance, and charging last, since the Protagonist's three specials are not designed.

## 7. Open, through the EP

| For | Question |
| :--- | :--- |
| **Orb** | The identity weights read as "open hands and arcs" against "fists, plates and straight lines": is that the split wanted, and should the rival's posed blade hands become fists? The rival's tail is still waiting, and would add an `own` limb to his cells |
| **Game Design** | Which of each fighter's three specials is the quick, the strong and the utility one. The Protagonist's specials |
| **Animation** | The four asks in section 5.1, and whether 21 new key sets fits the slice |
| **Art and Narrative** | The "never" rows and the hand-picked pieces of each fighter |

## 8. As generated (2026-10-05)

Orb confirmed the identity split and lifted the hold for the martial arts stance (`docs/ep/vision.md`, questionnaire 17). The inputs, the reference generator, the two moveset files and the review sheet are parked in `pending/movegen/`; its README has the counts and the keys for Tools. What differs from the sections above:

- **The rival's hands are a mix:** a closed fist on his heavies and enders, blade hands first on his lights. Section 2's table gave him fists throughout; `pending/movegen/identity.json` is the current data.
- **Martial B is a generic frame** with nothing hand-picked, because the signature's kind is not final. The hand-picked spines in section 3.2 are an illustration only.
- **A juggle is up to 5 skill strikes,** so the light cell has two more quotas: 10 moves that can be a flurry blow and 10 that can be a skill strike.
- **The counts:** 23 new key sets (section 6 said 21), 13 derived moves, and the two fighters share 43% of their shapes (section 6 said 46%).
- **Legal's rows are merged** (`docs/legal/movegen-banned.json`, RL-072 to RL-075): 13 banned shapes and 7 sequence rules in `parts.json`, refused by the generator and tested by its `--check`. The rival has no palm strike. Section 5.3 above was the proposal; `pending/movegen/README.md` section 3 is how it works.

## 9. All five stances, on Animation's data (2026-10-05, later)

`pending/movegen/` now holds all five stances for both fighters, 100 moves each, generated from Animation's own tip, path, flag and re-aim data and held by a lock so an id never changes shape. In the martial arts stance no move waits for a key set any more. The counts, what each stance still needs from Simulation, Animation and VFX, what needs Legal's person screen, and the keys for Tools are in `pending/movegen/README.md`. Sections 3.2 and 6 above are the earlier samples and sizing.
