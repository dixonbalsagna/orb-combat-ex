# Bystanders: nobody dies (CD-05)

Owner: Game Design. 2026-11-07, on Orb's ruling (`docs/ep/vision.md`, "Legal's scope and bystanders"): "No civilian deaths going forward. Civilians, scientists, bystanders, VIPs, will bounce harmlessly off the ground, or scatter when impacted." Pillar 5 already says it: the villain feeds on destruction, terror and combat trauma, never on civilian deaths, and the hero is pressured by collateral devastation and failing to protect the city. **This page is what World and Simulation build.** First values, as data. Unplayed.

## 1. What happens to people

**Legal's RL-257 (2026-11-07) re-rules RL-247 on Orb's word, and this page follows it.** Nobody is killed, removed or shown hurt.

Everyone counts the same: civilians, scientists, bystander soldiers and VIPs. There are no children in any thrown or scattered set. **Hostile armed soldiers stay under RL-247,** and this page doesn't change that. **Scientists and VIPs are never vaporized.**

| The moment | What they do |
| :--- | :--- |
| **The fight comes near** (a blow, a landing or a beam within the scatter radius, or their building takes its first damage) | **They scatter:** they run away from the fight, drawn running (the existing `evacuate` event) |
| **They're hit** (a blast front, debris, a body landing, a beam's edge, a shockwave) | **Flung, and they bounce harmlessly:** a short arc, at most 2 bounces, a tumble, at most stars, and they're up within 3 s, then they run. No blood, no harm to the body, never a body left lying, never burnt or scorched (RL-247, RL-257) |
| **In a building that's hit** | They stream out as soon as it takes damage. **A building that falls kills no one and shows no one trapped or lost:** its occupants are shown clear or scattering, thrown out through its windows and doors if they're still inside. Nobody is ever buried. **No count of who was inside appears anywhere the player sees** |
| **Where a crater or trench opens** | Popped up and out to the rim, and they bounce |
| **Water, lava and the other gags** | The same: flung and bouncing, with no burning (RL-247) |

**Data** (`data/biomes/collateral.json`):
```json
"bystanders": { "scatterBh": 8, "flingSpeed": [300, 900], "bouncesMax": 2, "upWithinSec": 3, "throwClearOnFall": true }
```
- **The sim decides who scatters and who's flung,** keyed and seeded. **The bounce and the run are drawn by the renderer,** which reads that state and never writes it.

## 2. Nothing counts a death, because there are none

- **The sim's civilian-death scalar comes out, and so does every meter fed from it:** `kill()` and the fields and events that carried it. This also closes the pillar 5 breach in `collateral.gd`'s feed (RL-257 (9)).
- **Retired words** (RL-257 (2), lint row c11): "civilians lost", "casualties", "toll", "kill count" and "body count". Apart from this list, they don't appear in the sim's outputs, the HUD, results, strings, copy or these pages. No death, kill or people-lost counter exists anywhere.
- **The proof Legal reads:** a sim check that a hit landing on people never raises menace, power, anguish or Witness, with a negative control that shows the check would catch it if it did. **Until that check passes, no public line says bystanders are never hurt.**
- **Nothing gains from a person being hit, thrown or scattered:** no meter, score, unlock, form, AI term, achievement or voice line (RL-257 (3), c08). The world's reads below take **structures, wrecks and evacuation events,** never the body of a person struck.
- **The guards that stay** (RL-257 (4)):
  - no AI, picker or score reads people, or who's standing near a target, and nothing aims at people to gain anything;
  - schools, hospitals and places of worship stay spared (c09, RL-242, RL-243), and so do the barred landmarks.
  - **The civilians-removed run is the check:** with every person taken out, every meter, every planner pick and every match result must come out identical.
- **The collateral budget and ceiling** are re-based from people to destruction. By tier, they become a share of the arena's structure mass broken, in a rolling 60 s and in total, so that **no fight destroys the planet at low tiers** (P3's exit). World sets the shares from today's measured structure loss by tier.
- **The old civilian band (12 to 30%) is retired as a safety test.** My call on what replaces it: **QA reads the share of buildings fallen, by tier,** as the spread number, beside World's places reached. Both are information and P3's cap, never a target. People flung is a trend only, and never on screen.

## 3. What the villain's menace reads instead

This applies to whichever fighter has a menace meter (today `data/fighters/RIVAL/meters.json`). Masses are `power.json`'s: house 1, low tower 5, tall tower or skyscraper 15.

| Pillar 5's word | Source | Gain |
| :--- | :--- | :--- |
| **Destruction** (shattered structures, wreckage) | A building his blow, send, beam or body brings down | **0.8 per unit of its mass:** a house 0.8, a low tower 4, a tall tower 12 |
| | A crater or trench his send or beam digs, 3 bh across or more | +1 each |
| **Terror** (mass evacuation) | A **lived-in** building that his blow empties (its first damage) | +1, +2 or +3 by its size. **The lived-in flag belongs to the building** (a home, a tower, a lab), not to whoever's inside, so it reads the place, never people |
| **Combat trauma** (breaking the opposing fighter) | A region break on him | +8 |
| | A send of his that lands | +3, or +5 if it goes into a building |
| | A close or stagger he lands | +1 |
| | The opponent reaches the brink | +10, once |

- **Decay and effects as today:** decay 0.4 a second after 240 ticks unfed; regen +0.01 a point, at most +1; damage +5% at full; beam power +0.08 a point.
- **Destruction and terror are normalised** by the arena's structure mass at the start, as people were by pop0, so planets are equivalent. Combat trauma isn't normalised.
- **His power from the world:** the old +0.09 per person becomes **+0.07 per unit of mass he levels,** normalised the same way (World's calibration, 2026-11-08: 0.07 is within 20% of the old feed on both worlds, where my first 0.22 gave 3 to 10 times it). World's budget by tier is .02, .05, .12 and .30, and its ceiling .03, .10, .25 and .70 (22 matches).
- **Every trigger is a structure's destruction, a wreck or an evacuation event** (RL-257 (3)). The crowd scattering can be a beat of his menace only through the building's evacuation event, never through anyone's body. It goes in `meters.json`, since numbers live in data.
- **His launch planner seeks structures** (the building smash, wreckage), never people.

## 4. What pressures the hero instead

| | Source | Gain |
| :--- | :--- | :--- |
| **Anguish** (collateral devastation) | A building brought down within 3,000 units of him (shortest arc) | **0.3 per unit of mass** if his opponent did it, **0.6** if he did |
| | A lived-in building emptied within 3,000 units | +0.5 |
| **Anguish** (failing to protect, RL-257 (3): a cost to him, not a reward) | A building falls inside the place he's fighting in while he's the nearer fighter to it | +1 per unit of mass. He was there, and it fell |
| **Witness, the form branch** ("he watched the city he's protecting wrecked") | Buildings his opponent brings down, and lived-in buildings his opponent empties, within 3,000 units | Calibrated so Witness is reached as often as today, within 10 points |
| | **Never from his own.** Each unit of mass he levels takes twice its worth off, as each death he caused took 2 off | |

- **Anguish's decay and effect are as today:** 0.6 a second, ki regen −0.01 a point, at most −1.
- **His care avoids the city's lived-in buildings,** never people.
- **This is the new input RL-247 asked for** from Orb and Game Design for hero anguish, and it fits RL-257 (3).

## 5. Elsewhere

- **UI and the results screen:** no death or people count anywhere. The results read the destruction and the fight.
- **Narrative:** barks about wreckage, fear and the fight, never about death.
- **Campaign:** "protect" objectives mean keeping a place standing or a person out of the fight's reach, never alive against dead.
- **Superseded where they read deaths:** `hero-forms.md` (Witness and anguish), `economy.md` (menace and anguish), `pillars.md` §5's prototype notes, and every QA civilian row.

## 6. Who builds CD-05

| Who | What |
| :--- | :--- |
| **World** | Scatter, fling, stream-out and throw-clear; the lived-in flag; the budget and ceiling re-based on structure mass; the structures-broken band |
| **Simulation** | `kill()` and the civilian-death scalar retired, with the lint and the check (with its negative control) that a hit on people raises nothing; the meters' new sources in `meters.json`; the normalisation; the civilians-removed identity check |
| **Encounter** | The planner's personality terms read structures |
| **Rendering and Animation** | The bounce, tumble and run drawn, reading sim state only |
| **Narrative, UI** | Lines and screens with no counts |
| **QA** | The destruction band by tier, the civilians-removed identity, and Witness's reach rate |
| **Legal** | RL-257 re-ruled it (2026-11-07). Legal reads the sim check's result, the strings and the clips (stars, flings, scatters) when they're built |

## 7. Pose and look rules now cite the creative rulebook (CD-15)

These rulings of mine carry pose or look limits that came from Legal. They stand as written until Art and Animation re-rule them under Orb, and from now on they cite CD-15, not Legal:
- `beam-answers.md`: the swat and catch pose (shoulder height, no open palm);
- `beam-answers-2.md`: the catch pose, no halo, and the colour limits;
- `moveset-rules.md`: no arms thrown wide, and the flash colour;
- `power-scale.md`: the trail (no aura, no gold, white or red);
- `rule-of-cool.md` and `rule-of-cool-map.md`: the aura colours;
- `energy-overhaul.md`: E6, the charge hand.

**Flash safety (photosensitivity) isn't a pose or look rule,** and it stays where it is unless the EP says otherwise.

## 8. Three older rows recast (Legal's RL-258, 2026-11-07)

| Row | Ruling | What it becomes |
| :--- | :--- | :--- |
| **RL-027, Pass-Through** (the Cyborg's two-sided portal kitchen: civilians in, sandwiches out) | **Recast. People never go in.** | **Wreckage goes in:** rubble, metal, the wrecks of cars and buildings. Sandwiches come out the far side as pickups, feeding his Hunger by mass, as `economy.md` already rules (never people, RL-216, RL-257). People near a frame scatter from it like any fight. Both frames stay destructible, which is the counterplay. Same comedy, new ingredients |
| **RL-155, the Cyborg as a stomach that eats fighters** | **The eating part is retired. His stomach takes wreckage only.** | Against a fighter, the stomach is a **grab:** his chain-mail plates clamp shut on him (the Press), hold him for a beat, and throw him out as a launch with the Press's force. **He's never swallowed, digested or shown eaten.** Rating questions about depicting a bite or swallow stay with Legal (ln02) |
| **RL-147, the two rival lines after deaths** (`story-beats.md` §6) | **Kept, on new triggers.** The lines are about the hero's resolve, and with nobody dying, "Good" and "Finally" can't be heard as cheering a death | "Good. That's the look I wanted." plays on **`witnessed_enter`,** the hero taking the Witness form, now fed by watching the city wrecked (§4). "Finally. Now you look like you mean it." moves from the old per-person trigger to **`wreckage_rival_many`:** the rival has brought down a lot of the city near the hero. **Narrative renames the trigger and re-reads §6's c08 lines** (the hero's own wreckage shames him and turns the crowd, and the rival's feeds branch A) |

- **`systems-sketch.md` §5** ("Civilian consumption") is superseded by `economy.md`'s Hunger (wreckage and metal by mass) and this page.
- **The fold still hard-counters the Cyborg,** because it takes him away from the wreckage, not away from people.
