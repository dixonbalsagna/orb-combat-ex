# The launcher, energy in reach, and a plan for vicious

Owner: Combat and Choreography. Date: 2026-10-06. Status: parked. Sections 1 and 2 are generated content for the slice C2t; section 3 is a plan for C4b and nothing of it is built.
Answers `docs/design/brawl-second-pass.md` (`51846cc5`): section 3 (the launcher), section 4 (the clinch and vicious), section 5b (energy in reach), section 13 (Orb's four tests).

The generator is version 10. `--check` passes on all three lines and `--self-test` passes 68 cases. Rows a fighter: 126 (rival 74 posed, 25 derived, 27 waiting; Protagonist 69, 30, 27): the 120 of before and 6 energy pieces in reach.

## 1. The launcher (C2t)

A tap of B on a staggered rival, on half of B's wind-up. Orb's test: "can I reliably launch my opponent?"

**Which heavies read as launchers at 14 ticks.** Two rules, in `parts.json` (`strike.windup.heavy`, and the form `launch`):
- **It reads on half the wind-up** unless it is a spin or a leap. A whole turn of the whole body does not fit 14 ticks, and a leap's gather is its wind-up. For the rest, the tell is cut to its last third and the drive is whole: he is already loaded as the stagger begins.
- **It lands on the trunk or the head,** so that it is the whole body it sends. A heavy to an arm or a leg is not a launcher. It is what the wrench is thrown with (section 3).

**Aimed by the stick.** The blow is picked by where it sends: up lifts him, down drives him under, toward drives him back along the line, away turns him past the attacker. With no stick, any. The stick still nudges the launch and the director still stages it; this is only the blow that starts it.

| Sends | The rival's tier: 10 of 10 | The Protagonist's tier: 7 of 10 |
| :--- | :--- | :--- |
| up | heaving elbow to the jaw; heaving fist to the gut | heaving palm to the chest; heaving ball of the foot to the gut |
| down | falling heel to the chest; falling hammer fist to the head; falling forearm plate to the chest | falling palm to the chest |
| across (stick toward) | stepping fist to the chest; stepping knee to the gut; stepping edge of the foot to the chest | stepping edge of the foot to the gut; stepping blade hand to the jaw |
| turned (stick away) | turning forearm plate to the head; turning fist to the jaw | unwinding edge of the foot to the gut; turning elbow to the jaw |

- The Protagonist's three that are not launchers: the spinning blade hand (a spin), and the falling hammer fist to the arm and the turning knee to the legs (the wrench's).
- **Thin spot:** the Protagonist has one launcher that sends down.
- `--check` fails if a fighter's tier has no launcher for one of the four ways.

**Until the tier is posed.** Of the heavy stand-ins, few read at 14 ticks: the rival's double hammer (down) and crossed-arm ram (across), and the Protagonist's double palm and crossed-arm ram (both across). The spins and the drop kicks need the whole wind-up. That is two ways for the rival and one for the Protagonist, which would fail Orb's test.
So the launcher's pool today (`brawl.launcher` in `../recipes.brawl.json`) adds his posed mediums that land on the trunk or the head. They were the launching blows before the three strengths, and 14 ticks is close to their own 12.

| Sends | The rival today: 11 | The Protagonist today: 11 |
| :--- | :--- | :--- |
| up | uppercut, rising knee, fist rise | rising palm, rising knee, uppercut |
| down | **double hammer**, dropping elbow, stomp, hammer | axe kick, stomp |
| across | **crossed-arm ram**, driving knee, headbutt | **double palm**, **crossed-arm ram**, palm push |
| turned | roundhouse | haymaker, crescent kick, body hook |

Bold is a heavy stand-in. Both fighters have all four ways today. The rival has one blow that turns. The Protagonist's overhand is left out: it comes down on the head, and he never launches that way.

## 2. Energy in reach (C2t)

With RB held in a brawl, X is the point-blank bolt and Y the blast. Orb's test: "do energy attacks look cool as part of close-range combos?"

**A piece is a blow and a shot at once:** an energy hand he already has, how it is let go, and the place it is set on. So it has a path (a thrust is a line, a flick an outward arc, a sweep an inward arc) and a place, and it takes a light's or a medium's place in a string: the links carry into it and out of it, and Legal's string rules count it with the blows. No piece is aimed at the head.

| | The Protagonist: pointed, not cruel | The rival: a show of it, in straight lines |
| :--- | :--- | :--- |
| How he lets one go | The heel of the palm set on one point, the chest or the ribs, and the shot let go as a short cone that moves him. Placed, never swung | A blade hand driven in with the forearm plate behind it, the light running down the plate's edge and off the fingertips as it lands |
| Point-blank bolt 1 | palm thrust, a thrust, on the chest (the posed bolt press) | blade hand, a thrust, on the gut (the posed bolt press) |
| Point-blank bolt 2 | flat palm, a thrust, on the gut (the posed bolt press; the flat palm is not posed as a hand) | open palm, a thrust, on the chest (the posed bolt press) |
| Point-blank bolt 3 | palm thrust, a flick, on the chest (new) | blade hand, a flick, on the gut (new) |
| Point-blank bolt 4 | flat palm, a sweep, on the gut (new) | blade hand, a sweep, on the chest (new) |
| The blast, two places | palm thrust, a thrust, on the chest or the gut (the charged shot's poses on a 12-tick wind-up) | blade hand, a thrust, on the chest or the gut (the charged shot's poses) |

- **Why four bolts and not one.** A mashed RB + X is one every 6 ticks. Legal's e06 says an energy flurry varies its piece and never pumps one hand or fires both palms in turn. So the four differ in hand or release, and after any two blows at least one may follow. `--check` tests it.
- **The rival's look is his blade hand,** which is what his lights are. His own blast would be the lit fist with the plate behind it. **e06 asks an open or a blade hand,** so the generator refuses it, and I read the point-blank bolt as that row's "burst" and refuse it there too. Whether e06 is meant for an energy blow in reach is a question for Legal; the sheet lists both as questions.
- **Chaining with no gap** is the paths: a thrust follows a straight or an arc as a jab would, and a flick or a sweep follows a hook. Nothing new is needed between a fist and a shot but the hand's state.
- **State:** the thrusts are the posed bolt press and charged shot, played with the hand on him, so they are derived. The flick and the sweep are new releases: waiting.

## 3. Vicious (a plan for C4b)

Inside the clinch, each further tap of A is a vicious blow on the region the stick leans to, up to four. The regions are the wounds system's: head, core, arms and legs. I assume up is the head, down the legs, toward the core and away the arms; that mapping is Game Design's to set.

**What vicious is for each of the launch pair.** No bite, no gouge and no claw for either, so nothing here needs the rating question. That stays open for the Cyborg.

| Region | The Protagonist: he stops a limb working, and doesn't maul it | The rival: the same bruise again, glasses on |
| :--- | :--- | :--- |
| Arms | the heel of the palm into the elbow joint of the held arm; a blade hand to the inside of the wrist | his forearm plate ground down the held arm; an elbow's point into the upper arm |
| Legs | a knee to the outside of the thigh; the heel of the palm to the hip joint | a knee into the thigh; a short stamp on the shin |
| Core | four fingertips under the ribs; the heel of the palm to the breastbone, at no distance | a short elbow into the ribs he has already hit; a knee into the same side |
| Head | the heel of the palm to the hinge of the jaw; the heel of the palm to the brow, pushing the head back | a headbutt, brow to cheekbone; the forearm plate across the jaw |

- The Protagonist's fingertips are a blade hand's four fingers, never one or two (Legal's b10). His blows to the head are strikes, never a grip (b06).
- The rival's headbutt is a posed strike already. His glasses stay on through all of it.
- Eight looks a fighter, two a region, so that four taps on one region show two blows and not one.

**What it needs from the generator,** on top of the `pair` kind (`second-pass-plan.md` section 7): a `vicious` block in `parts` (for each region, the close blows that fit inside a hold: an elbow, a knee, the head, a hand's heel, plate or palm, on a short path, with one arm, the other keeping the hold), each fighter's list in `identity`, and the four regions as slots of the clinch's cell. Small, once the `pair` kind exists.

**Three things to settle before it is built:**
1. **Four blows on one place.** Legal's s02 allows two blows running to the same place. A head, a core and a leg each have two places to alternate (head and jaw, chest and gut, legs and shins). **An arm has one.** Four taps on an arm need Legal's word, or more places on the limb from Animation (the wrist, the elbow, the shoulder).
2. **The wrench and the rival's tier.** The wrench is a charged heavy that lands on a battered limb. The Protagonist's ten have one heavy to an arm and one to the legs. **The rival's ten have none.** If the piece's own place decides where it lands, he needs two more heavies, or two of his ten re-aimed.
3. **Sound.** Legal's f03 (no chanted syllables) holds for four taps in a hold.

## 4. `care`

No selector of Combat's reads it: not the generator, the recipes, the templates or the finisher selection. The launch planner and the AI's nudge are Encounter's. So nothing of mine moves with 0.8 and −0.5.
Two notes in the live `data/combat/finishers.json` still quote the old values in prose (1.0 for the hero, −0.8 for the villain), and the rival's still describes the old villain. They are text, and they go when the parked launch-pair finisher rows land (`../apply-order.md`, step 4).

## 5. The lists

**For Animation**
- *The launcher:* nothing new to pose. The tier's 17 launchers and the stand-ins play on 14 ticks with the tell cut to its last third. The mediums in the launcher's pool play at 14 where they have 12.
- *The point-blank bolt:* the bolt press with the hand on him, fitted to 2 ticks, for two hand states a fighter (palm thrust and flat palm; blade hand and open palm). The Protagonist's flat palm is still not posed as an energy hand.
- *A flick and a sweep at the contact,* one each a fighter: new, or the swat and the spray press named for them.
- *The blast:* the charged shot's poses on a 12-tick wind-up, the hand set on the chest or the gut as it goes. The wind-up is a held pose (h05).
- *Later, vicious:* eight looks a fighter inside the hold.

**For VFX** (Game Design's eight points in section 5b are the brief; these are the pieces they hang on)
- The lit hand: the edge of the palm's heel for the Protagonist; the blade hand's edge and the forearm plate's edge for the rival. A thin edge, never a ball.
- The shot at the contact: a thin edge or a short cone at the hand.
- The spill follows the piece's path: straight on for a thrust, off to the outside for a flick, across for a sweep.
- The blast: its gather over 12 ticks as a thin ring or edge at the palm; the cone past him; his chest trailing the colour as he leaves.
- Mashed: at most one full flash in 20 ticks, sparks at the hand for the rest.
- The launcher adds nothing: it is a heavy's effects on half the wind-up.

**For Legal** (the sheet's section "New looks for Legal: the launcher and energy in reach", 17 rows)
- 8 point-blank bolts and 4 blasts, with the hand, the release and the place of each.
- Two questions: the rival's lit fist for a blast, and for a point-blank bolt.
- How each fighter lets one go.
- The launcher: no new shape.
- A proposed condition, R1, for an energy blow in reach.
- My reading that e06's "burst" covers the point-blank bolt.
- Ahead of C4b: the two fighters' vicious lists above, and the question of four blows on one arm (s02).

**For Tools**
- `parts.json`: `strike.windup.heavy`; the form `launch`; `strike.heavy.launcher` (`aim`); a block `reach` (`release`, `body`, `targets`, `path`, `rules`, `forms`); `readings.martial.b.staggered` and `readings.energy`.
- `identity.json`: `energy.reach.hands`; `manner.reach`.
- `cells.json`: a table cell under `presses.reach`, with `statusCap`, `distinct` and `asks`.
- `combat.moveset/1`: a heavy has `wind`; a table row may carry `target`, `limb` and `path`; a refused row carries `hands`.
- `combat.recipes/1`: the `brawl` key `launcher` and the pool `brawl.launcher`; two blocks, `launcher` (`aim`, `bySend`) and `reach` (`rule`, `pieces`).

**For Encounter**
- The launcher's pick: the stick's lean to a send (`launcher.aim`), then a piece of `launcher.bySend`, under the string rules and the fallback already in the file.
- Energy in reach: the pieces and the one rule (never the same hand and release twice running).
