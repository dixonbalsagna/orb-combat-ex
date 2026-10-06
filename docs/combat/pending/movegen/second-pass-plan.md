# The brawl's second pass: what the generator must produce

> **Superseded in part (2026-10-06).** This plan was written for two strengths. Orb then moved the buttons to three (X light, Y medium, B heavy), and `three-strengths.md` is the newer page for X, Y and B. **Withdrawn here:** the quick heavy on a tapped Y, the charged light, and all of section 5 (B as Charge at close range). **Still the plan:** the cell addressing (section 1; `presses` is built for the held X), the shove, the tackle, the lift, the slip, the breaker, and the `pair` kind of part.

Owner: Combat and Choreography. Status: a plan, parked; nothing here is built. Written against HEAD `51bb701`.
Answers `docs/design/brawl-second-pass.md` (the rules, section 8 for the inputs, section 10 for the order), `docs/animation/brawl-second-pass-view.md` (the body's side) and `docs/legal/brawl-screen.md` (RL-098 to RL-101, merged into `parts.json`).

Every count below is measured on today's generated files (`moveset.rival.json`, `moveset.protagonist.json`, generator version 6) by scratch scripts that write nothing.

**Sizes, on the generator's side only.** Small: data rows and a regenerate. Medium: a new reading, cell or check in the generator, with self-test cases. Large: a new kind of part and cell.

## 0. At a glance, in the EP's order

| Order | Item | Needs in `parts` | `identity` | `cells` | Size | From today's pieces |
| ---: | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | **C1** control, the even mash | nothing | nothing | nothing | none | all of it: the stick's leans are already quotas on X |
| 2 | **C2** the quick heavy, the heavy flurry | a form `quick` | nothing | nothing | small | all: 13 heavies for the rival, 12 for the Protagonist, every one posed or derived |
| 2 | **C2** the X and Y mix-up | nothing more (f02 is merged) | nothing | nothing | small: one more check | all: no string dead-ends |
| 2 | **C2** the charged light | a form `charged`, a chamber table | nothing | nothing | small | all: 16 and 15 hand lights; 1 charge pose a fighter from Animation |
| 2 | **C2** the charged heavy | the form `ender` goes | nothing | nothing | none | all 16 a fighter, as the form `held` |
| 2 | **C2** the shove | a small `shove` block | forearms or palms | A's tap | small | no: 2 poses a fighter; a stand-in exists |
| 2 | **C2** how a cell is addressed | readings by press | nothing | `presses`, `pairs` | medium, once | - |
| 3 | **C3** the skill strike, Y on the beat | nothing | nothing | nothing | none | all |
| 4 | **C5** B: burst, flurry, blast, art, signature | deliveries `burst` and `blast`, a body list for a brawl | nothing | B's tap and holds | medium | bursts on a thrust and the blast: posed. Bursts on a flick: a mapping from Animation |
| 5 | **C4a** the tackle | a travel kind `tackle` | where he takes hold | A's hold | small to medium | the rival's: yes (the zip's tackle poses). A second hold: 1 pose |
| 5 | **C6a** the lift | nothing | nothing | the pair X+Y | small | all: 3 rising heavies a fighter, all posed |
| 5 | **C6a** the slip | nothing | nothing | the pair X+A | small | all: steps and lights exist |
| 5 | **C6a** the breaker | a `wrap` on a strike | his lit hand | the pair Y+B | small to medium | the blow: yes. The tell: 3 poses a fighter |
| 6 | **C4b** the clinch, the trip, the throw; the seize | **a `pair` kind of part** | holds, turns, throws | A's mash, the pair A+B | large | nothing is posed |

About 31 new moves a fighter in the martial arts stance when all of it is built, beside the 46 strikes that stand.

## 1. One change under all of it: how a cell is addressed

Today a cell is one button in one stance, and its three readings (speed, tech, heavy) are forms of the same pieces. Game Design's grammar is now: X, Y and B each have a tap, a mash, a mix, a hold and a beat; A has a tap, a mash and a hold; four pairs.

- **X and Y stay one pool each.** A press picks the form, never a different list. So no id changes and the lock stands.
  `parts.readings.martial` becomes: X tap `light`, mash `flurry`, hold `charged`, beat `skill`; Y tap `quick`, mash `quick`, hold `held`, beat `quick`.
- **A and B hold different kinds of move on each press,** so those cells gain a `presses` block: `tap`, `mash`, `hold`, each a cell of its own kind.
- **A stance gains `pairs`:** `xy`, `xa`, `yb`, `ab`, each a cell.
- **Ids:** `mv.<fighter>.martial.a.tap.01`, `mv.<fighter>.martial.xy.01`.
- **For Tools:** the keys `presses` and `pairs` in `combat.cells/1`, and the longer id pattern.

Medium, once. It is needed from C2, for A's tap.

## 2. C1: control and the even mash

Nothing for the generator. The stick still leans the blow, and X already fills 5 or more places for each lean.

**One thin spot shows once Y is mashed:** Y has no lean quotas, because it was filled by where a blow sends. Holding toward the rival gives the Protagonist 2 heavies of 16 (he is a kicker), and 1 of his 12 quick ones.
**The fix, tried in memory:** Y at 20 with a quota of 3 for each lean. All 16 ids stay, 4 are added, and none waits on new poses (rival 14 posed and 6 derived, Protagonist 15 and 5). His manoeuvre Y is re-picked, as it draws on Y. It changes a count Game Design set, so it needs a yes.

## 3. C2: Y, the mix-up, the charges, the shove

**The quick heavy (tapped Y, 6 ticks) and the heavy flurry (mashed Y).**
- `parts`: a form `quick`: a heavy that is not a spin and uses one arm or none. That leaves 13 for the rival (11 posed, 2 derived) and 12 for the Protagonist (11, 1).
  Left out: the rival's double hammer, spinning elbow and crossed-arm ram; the Protagonist's double palm, crossed-arm ram and two spinning kicks. A full turn or a two-arm blow doesn't read in 6 ticks, and they keep their size on the held Y. This is my call: Animation can play any heavy at any wind-up, and can ask for all 16.
- A quick heavy doesn't knock back, so `sends` is read on the hold only. The 6 ticks are Animation's `quick` style row: the generator writes no timing for a form.
- A flurry of nothing but quick heavies never dead-ends: after any two, at least 6 (rival) and 5 (Protagonist) can follow, and the median is 11 and 8.

**The mix-up, and Legal's f02** ("s01 and s02 count the string, not the button").
- Done in version 6: `string_breaks` judges a string whatever buttons made it, with self-test cases (two gut blows running, X then Y, is refused).
- To add with C2: a check in `--check` that from every allowed pair of blows, each button still has at least 4 allowed next blows. Measured today:

| After any two blows of a mixed string | Rival | Protagonist |
| :--- | ---: | ---: |
| Lights that may follow, of 30: fewest, median | 19, 28 | 19, 28 |
| Quick heavies that may follow: fewest, median | 6 of 13, 12 | 5 of 12, 11 |
| Two blows drawn blind that break a rule | 6.4% | 9.3% |

- So the director's filter turns away about one blind pick in 11 to 16, and never runs out.
- **s01 needs counting at run time.** Each fighter has groups of 4 pieces with one limb, tip and path (the rival's blade hand on a line; the Protagonist's palm on a line). "Never one of his last two pieces" doesn't stop four of them in a row, and s01 allows 3.
- **A B blow carries no target,** so I read it as neither breaking a run nor ending one: a blow to the gut, a burst, a blow to the gut still breaks s02. Legal can say otherwise.
- For Encounter, when C2 opens: `../recipes.brawl.json` needs its pools by button and the rules marked as counting the string. Not done here.

**The charged light (held X).**
- `parts`: a form `charged`: a light thrown by one hand. Animation offers one charge pose a fighter, an arm drawn back, so it is a hand blow: 16 for the rival (13 posed, 3 derived), 15 for the Protagonist (11, 4).
- **A chamber table, from Legal's h04:** an open hand is never drawn to the hip (wrist at x 9 or more); a closed fist at the hip is allowed. A hip chamber fits 4 of the rival's 16 (his fists; 9 if a plate blow counts as a closed hand) and **1 of the Protagonist's 15.** Animation's sketch is "the fist drawn back at the hip". So the Protagonist's charge pose has to be the draw at shoulder height, and the rival needs that pose too for his blade hands and heels, or two poses. The generator would write `chamber: hip` or `shoulder` on each charged light, and refuse an open hand at the hip.
- **The stick:** hand lights cover no lean, up and down (rival 4, 9, 5; Protagonist 3, 9, 4). Toward and away are elbows, knees and kicks by definition, so a charged light has no piece for them. Either it falls back to no lean, or Animation adds a second charge pose for a leg. Game Design's to say.

**The charged heavy (held Y).** It is the form `held` that every heavy already has, and Legal's b12 names it.
- All 16 a fighter pass b12 on Animation's measured flags: no hip chamber, no two-hand chamber.
- Its knock-back is `sends`: up 3, down 4, across 5, turned 4 for the rival; 3, 3, 4, 6 for the Protagonist. A full charge with no stick lifts: the form `lift`, 5 and 6 pieces.
- The form `ender` goes with its rule. `break` stays as the look the director prefers against a set guard (5 a fighter).

**The shove (tapped A).**
- `parts`: a block `shove`: both palms or both forearms on the chest, hands at least shoulder width apart, one motion, no grip, no light, never held (Legal's P1, b01).
- `identity`: the rival shoves with his forearm plates (he has no palm strike), the Protagonist with his palms.
- `cells`: A's tap, one move a fighter. The generator adds little here: it is 2 poses a fighter from Animation.
- **A stand-in for Orb's first play of C2:** no posed two-arm piece has the hands apart (the crossed-arm ram is crossed). Each fighter's posed one-limb push from the defensive stance can play as the shove until the poses land: the rival's shoulder plate to the chest, the Protagonist's palm to the chest.

## 4. C3: the skill strike, widened

Nothing new. X on the beat is the form `skill` (16 pieces for the rival, 17 for the Protagonist). Y on the beat is a `quick` heavy. The juggle keeps its form.

## 5. C5: B recast

- `parts.shot`: two deliveries. `burst` (a tap; in a mash or a mix it is the flurry) leaves on a thrust or a flick. `blast` (held 12 ticks) leaves on a thrust, or a drop from above.
  The energy stance's bodies (planted, kiting turn, backpedal) are footings for shooting from range. In a brawl the body under a B piece is the stick's lean, so the martial stance needs its own body list: none, toward, away, up, down.
- **Legal's e06, merged and checked:** one open or blade hand, at the shoulder or lower; a string never throws the same hand, release and body twice running.
- `identity`: nothing new, and one consequence. **e06 leaves the rival 2 of his 5 energy hands on B** (the blade hand and the open palm). His lit fist, his pinch and his clawed palm are refused: 27 of his 45 candidates. 18 pass, and all 27 of the Protagonist's. The rival's flurry then alternates two hand states: enough for the rule, and thin. A third release, a sweep (which e05 already allows a volley), would give him 6 hand-and-release pairs for 4, and the Protagonist 9 for 6.
- `cells`: B's presses. Tap: a table of bursts, 6 a fighter. Hold: a table of blasts, 3 a fighter, then two frames, the art at 24 ticks and the signature at 48.
  Today's frame (a tell, an opening, four blows from X by their links, a launcher from Y) becomes the art, with its string driven by the player: each press is its next blow, 3 to 8 of them, and he can stop. Until a fighter's art is authored the frame says `stopgap: beam`.
- **From today:** a burst on a thrust is posed for both (the bolt press), and the blast is the charged shot's poses on a 12-tick hold. A burst on a flick needs Animation's spray press named as a key set: no poses. The Protagonist's flat palm is not posed as a hand.
- Medium: a table on a new block, the string check on its pool, the frame's driven string.

## 6. C4a and C6a: the tackle, the lift, the slip, the breaker

**The tackle (held A).**
- `parts`: a travel kind `tackle`: the coil, the run, where he takes hold (the waist or the shoulders: `grab.kinds.tackle`, checked against Legal's g04 today), the carry. Where it ends (the ground, a ridge, a building, thrown off) is the director's at run time, not a variant.
- `identity`: the rival takes the shoulders, plate first; the Protagonist the waist.
- `cells`: A's hold, 2 a fighter.
- From today: the zip's tackle poses exist (coil, run, a shoulder-first tackle, the carry). A waist take is 1 pose more, if the two are to differ.

**The lift (X+Y).** A strike cell over the rising heavies, with no leap and no spin (Legal's L1). 3 a fighter, all posed, and all already in Y: the rival's uppercut, rising knee and rising fist to the chest; the Protagonist's rising palm, rising knee and uppercut. No new key set. In the whole grammar there are 6 for the rival and 9 for the Protagonist if it should grow.
The juggle after it must not open with a rising blow (s05).

**The slip (X+A).** The travel kind `step` exists. A cell of 6, two each round, over and under, each with a light from X. Pairs of a step and a playable light today: rival 20, 9 and 28; Protagonist 42, 20 and 24. "Behind" is the far end of the step round him. Legal's m11 asks 4 ticks of drawn travel, which is the slip's tell exactly: Simulation and Animation hold that number.

**The breaker (Y+B).**
- `parts`: a strike piece may carry a `wrap`: an energy hand from `shot.hands` whose light sits on the plate and knuckle edges. b09 still refuses a glow or a ball on a strike; the wrap is judged by e01.
- `identity`: the rival's is his lit fist. **The Protagonist has no plate and no lit fist.** Legal's condition reads "lit plate or knuckle edges only", so his breaker needs Legal's word: may the edge of his open or blade hand be lit, as his cleared energy hands are?
- `cells`: the pair Y+B, 3 a fighter, from the heavies.
- From today: the blow is any posed heavy. The tell and its own strike are 3 poses a fighter (Animation).

## 7. C4b: a `pair` kind of part (the clinch, the trip, the throw; the seize)

Animation's ask, taken as given: the generator composes names of poses Animation already has and states the anchors. The grip is the body's solve, so the generator never works out a coordinate that depends on the other body.

- **`parts.pair`:**
  - two roles, `holder` and `held`;
  - phases: the reach (10 ticks), the grip, the trip, the throw. The seize: a tell (12), the reach, the grip, an aimed throw. Each phase has one length for both roles, and the generator fails if they differ;
  - anchors for each phase: a part of the holder (a hand or a forearm) to a socket of the held body. The sockets come from `grab.kinds.clinch`: the collar, the elbow, the waist;
  - what is checked: never a hand to a hand (g02), never the throat, hair, tail or face (g01, g05), nothing lit at the hands;
  - for each phase and role, a pose by name from Animation's vocabulary;
  - the trip's turn (forward, back, to the side) and the throw's line, by the stick, as `sends`.
- **`identity`:** the hold he prefers (the rival a collar and elbow, the Protagonist the waist), his turns, and his throws (the rival on lines, the Protagonist on arcs).
- **`cells`:** A's mash, 4 chains a fighter from 24 shapes (2 holds, 3 turns, 4 throws). The pair A+B, 3 seizes a fighter.
- **The generator:** a new cell kind, the checks above, a section of the sheet, 4 or so self-test cases. Legal's G1 and H1 on every row (h04: the clinch hold is class hold, the seize's tell is class tell).
- **From today:** nothing is posed. Once Animation names the vocabulary the rows can be generated as waiting, which gives Animation the list of about 18 poses in the generator's words.

Large, and last, as in the EP's order.

## 8. Open points, each with its owner

| # | Point | Whose |
| ---: | :--- | :--- |
| 1 | The quick heavies leave out spins and two-arm blows (13 and 12 of 16) | Mine; Animation may ask for all 16 |
| 2 | Y at 20 with a quota of 3 for each lean | Game Design (it set 16) |
| 3 | A charged light with the stick toward or away: fall back, or a second charge pose | Game Design, then Animation |
| 4 | The charge pose: at the hip it fits 1 of the Protagonist's 15 charged lights (h04) | Animation |
| 5 | A B blow in the string rules: it neither breaks a run nor ends one | Legal |
| 6 | e06 leaves the rival's lit fist off B; a sweep as a third release for a burst | Legal |
| 7 | The Protagonist's breaker: a lit edge on an open or blade hand | Legal |
| 8 | The tackle: a second hold, at the waist | Animation |
