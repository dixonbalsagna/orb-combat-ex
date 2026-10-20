# The ground each opponent claims, and the heavy's full-charge hint

Owner: Narrative and Fighter Identity. Version 1, 2026-10-19. Orb approved the shifting arena (World's 31b) and sees it "used to programmatically assign stages to opponents in the story mode." World builds the function; this page gives it **meaning**: for each story opponent, the ground they claim (their home, the places that suit them, what the ring should pass through) and **one line on why the fight goes there**. It builds on `planet-and-homes.md` (the four homes) and World's `homes-and-arenas.md` and `arena-shift-research.md`. Paper only. **Options for Orb; Orb's lore pick (homework 37) and the names (homework 39) are still open, so each claim is written to survive any of the three ideas and notes what changes under each.** The data is `pending/opponent_grounds.json`.

## 1. How the function should read this

World's picker gives a run a list of candidate rings (a centre, a loop length, a bearing). **Each candidate is a loop through the planet, so it passes through some biomes, some places and some wear.** This page gives each opponent a **claim**: a score the picker can compute for any ring, so that the stage "goes where the opponent would take it".

A claim has five parts:

| Part | What it is | Unit the function can compute |
|---|---|---|
| **Home** | The fixed home place; a ring centred on or passing through it scores highest | The place class and its distance to the ring |
| **Suits** | Biomes and place kinds the ring should pass through, each with a weight (1 to 3) | Share of the ring in a biome, count of places of a kind in the loop |
| **Must cross** | The one feature the ring must include or the claim fails | At least one of: a biome, a place kind, a state of wear |
| **Avoids** | Features that lower the score | Same units |
| **Size** | The loop length the opponent likes, by stage (close, half, whole) | A choice among World's three sizes |

**Rules that hold for every claim.**
- **A home is colour and set piece, never numbers.** Fighting on someone's ground changes the look, the props and the line, not a stat (Narrative's homes paper, Game Design to confirm).
- **The planet decides before the opponent does.** On a fresh planet the picker lists candidates first, then each candidate goes to the opponent whose claim scores highest for it; a tie goes to the rival, who is the usual face of a run. If no claim fits well, the stage keeps its usual rules and its opponent plays on neutral ground (and says nothing about the place).
- **Wear is ground too.** A damaged or fallen place from earlier in the run is a feature the Cyborg wants and the others do not (section 2.3).
- **Never a school, hospital or place of worship** as a claimed feature, and the Cyborg's appetite is aimed at wreckage only (Legal).
- **The polar outposts stay free** for a later fighter, so no claim lists them.

## 2. The four claims

### 2.1 The rival (the Anti-hero): the high place everyone can see

**His home:** **Rankhold**, the terraced town up a cold mountainside, with the Rank Stair.
**What he claims:** height with a crowd below it. He needs a witness (Pride), and rank is height, so he wants to win where he can be seen from below.
- **Suits:** a mountainside town (3), a city with a high terrace or tall skyline (2), a harbour breakwater or sea wall (1), a cold biome (1).
- **Must cross:** a mountain *and* a settled place, so the ring climbs and then drops to people.
- **Avoids:** open sea (no witness), empty desert (nobody to see him).
- **Size:** close round Rankhold early; half later; whole on a boss stage.
- **Under the lore ideas:** **Furnace**, a pressure vault (a cold, windowless chamber under the mountain). **Tide**, a breakwater fortress on the coast. **Regard**, the League's ranking hall at the top of the stair.
- **Why the fight goes there:** he drags it up the stair so everyone can see him win. **His line:** "Up here, everyone can see you lose." (7 words)

### 2.2 The Empress: wide flat ground where nothing hides

**Her home:** **Crownreach**, the ceremonial enclave on the plains, with an avenue of banners and the records tower.
**What she claims:** long, flat, open ground where her beam can run and nothing blocks the view. A province is something you can see the edge of.
- **Suits:** plains (3), a large city at the end of an avenue (2), a long straight stretch of coast (1).
- **Must cross:** plains for at least a third of the ring.
- **Avoids:** mountains and dense forest (they break her sight line and her beam).
- **Size:** half or whole (she thinks in provinces); close only round Crownreach in a 3v1.
- **Under the lore ideas:** **Furnace**, a kiln-hall where each revision is stamped. **Tide**, an observatory on the shore that charts the tides. **Regard**, a court of records.
- **Why the fight goes there:** she claims the open plain so there is nowhere to hide from her. **Her line:** "Wide open ground, insect. Nowhere to hide!" (7 words)

### 2.3 The Cyborg: where the wreckage is

**His home:** **Slagholt**, the breaking yard of cranes and wrecks in the desert.
**What he claims:** wreckage, which is his fuel. He goes where things have already been broken: the dry desert, a ship graveyard on a coast, and above all **a place this run has already hurt**.
- **Suits:** desert (3), a damaged or fallen place from earlier in the run (3), a dry coast with hulks (2), a city already half in ruins (1).
- **Must cross:** a desert, or a place in the *damaged* or *fallen* state.
- **Avoids:** an untouched city or town. He does not choose a place with people in it to feed on, and nothing about his ground puts a living person on his menu (Legal's condition).
- **Size:** half; close in the yard; whole on the boss stage.
- **Under the lore ideas:** **Furnace**, slag heaps and open furnaces. **Tide**, a coast where the tide leaves hulls. **Regard**, a closed arena nobody watches.
- **Why the fight goes there:** the wreckage is already there, so it is free fuel. **His line:** "Lots of wreckage out here. Free fuel!" (6 words)

### 2.4 The Protagonist (when he is the opponent): the shore, so the fight can leave the town

**His home:** **Mendquay**, the harbour town with the half-rebuilt pier.
**What he claims:** a coast where he can lure the fight away from the people and over open water, which is his habit.
- **Suits:** a coastal town (3), open sea within the ring (3), a quay or pier (2), a river mouth (1).
- **Must cross:** a coast and open water.
- **Avoids:** a dense city centre with no way out (nowhere to take it).
- **Size:** close round Mendquay; half along a coast; whole is fine.
- **Under the lore ideas:** **Furnace**, an old foundry on the quay. **Tide**, the pier where the tide runs through. **Regard**, a sparring yard the town watches.
- **Why the fight goes there:** he drags it to the water so nobody's roof breaks. **His line:** "Keep it over the water. Nobody's roof breaks!" (8 words)

## 3. The cases the claims do not cover

| Case | What to do |
|---|---|
| **The generic boss** ("any", when no named boss applies) | The stage with the most standing cities; whole size; no claim line |
| **A boss stage** (the last of a run) | Whole, and a boss may still claim its own ground by section 2: the ring's score is the boss's claim, scaled up |
| **The first stage of a run** | Close, round the *player's own* home (World's section 5); the opponent's claim does not apply, and a one-line nod is enough ("You're on my ground") |
| **A rival who steps in** (the fifth-fight path) | The ground of the *boss* who escaped; the rival speaks no line about the place |
| **Two opponents want one ring** | The ring goes to the claim with the higher score; a tie goes to the rival; the other claim waits for a later stage |
| **A stage with no suitable ring** (a planet with no mountain) | Take the best-scoring candidate and let the picture carry the fantasy, as World's best-fit rule for homes does |
| **Training dummy** | No planet ground; the training hall |

## 4. One line from each claim as a stage line

The line is said at the start of the fight (the touch-down intro, `intro_lines`), keyed by the opponent and a `ground` tag. Each follows the voice bibles and the lint.

## The rival
> "Up here, everyone can see you lose."

## The Empress
> "Wide open ground, insect. Nowhere to hide!"

## The Cyborg
> "Lots of wreckage out here. Free fuel!"

## The Protagonist
> "Keep it over the water. Nobody's roof breaks!"

## 5. The heavy's full-charge hint

Game Design's ruling 6b (`docs/design/rulings-2026-10-19.md`): Orb's "Full! Let go to knock him back." is true only for a charge let go **before** full; a charged heavy **at full launches** him. The EP asked for a line in Orb's voice for the launching case, so the old one stays where it is true. Orb's voice in the hints is short, warm and imperative, with an exclamation at the moment ("He's open! Press B and send him flying!"; "Full! Let go to knock him back."). Options for the full charge, in that voice:

| Option | Line | Note |
|---|---|---|
| **1 (my pick)** | "Full! Let go to blast him away!" | A different verb from the B launch hint, so the two do not blur |
| 2 | "Full! Let go and he'll fly!" | Shortest, a promise instead of an order |
| 3 | "Full! Let go to send him flying!" | Orb's own phrase from the launch hint; the closest to Orb's words, but two hints would then say the same thing for different buttons |
| 4 | "Full! Let go to launch him!" | The plainest and uses the game's own word; slightly flat |

**Where each plays.** Keep Orb's line, "Full! Let go to knock him back.", for a charge that has passed its knock-back point and is **not yet full**; show the new line at the first full charge. The rulings' other option (one line at full, changed to "send him flying") also works with option 3 and no second line.

## The heavy hints

> "Full! Let go to blast him away!"
> "Full! Let go and he'll fly!"
> "Full! Let go to send him flying!"
> "Full! Let go to launch him!"

## 6. What it needs

- **World:** the claims as data (`pending/opponent_grounds.json`: suits with weights, must-cross, avoids, size by stage) and a score for a ring; the homes as place classes (their own proposal).
- **Game Design:** whether a home is colour only; whether a claim chooses the opponent for a candidate, or the opponent chooses the candidate; the stage-size ladder.
- **UI:** the heavy's hint, keyed on the charge's two states.
- **Legal:** read the Cyborg's claim (wreckage and fallen places) and the line, and confirm that the Empress's and the Cyborg's lines are in order.
- **Orb:** the lore pick and the names; none of the claims changes with them, only the home's flavour.
