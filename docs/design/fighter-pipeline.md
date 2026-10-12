# The fighter pipeline: how a fighter gets into the build, and what it does to the balance

Owner: Game Design. Date: 2026-10-12, second version, with Animation's, Combat's, Art's and Narrative's parts folded in (`docs/animation/fighter-onboarding.md`, `docs/combat/fighter-onboarding.md`, `docs/art/fighter-design-workflow.md`, `docs/narrative/fighter-identity-workflow.md`). Their sizes are their own estimates. Every number of mine is a first value. Co-op is not designed here.

**Orb,** 2026-10-12: "right now we're building a moveset and calibrating balance on two generic stand-in characters, once we start introducing actual fighters intended for the release version how will the balance be affected? how much retooling will need to happen? Ideally each character should have their own 'flavor' of attack animations and movesets, with a large common pool of attacks to pull from. Can we establish a workflow for the characters so I can get at least four into the playable build soon?"

**The short answers.**
- **Balance:** the tuning done so far carries, if a fighter's flavour is kept out of the timing and the rules. That is the line in §1.
- **Retooling:** a fighter who is only flavour needs no retune of the system: one QA pass and a nudge of his own numbers. A fighter's unique mechanic is new balance work each time (§2, §3).
- **Four soon:** two are already in. The Protagonist and the Anti-hero are the two in the build, with looks Orb approved on 2026-10-04. So four means two new fighters, the Cyborg and the Empress, and it means making the first two stop feeling generic (§5).

**Names.** The vision's Galactic Tyrant is the Empress, she, since 2026-09-29. Her tail became a bladed mantle. All four are human in build, on the one skeleton.

## 1. What is the game's, and what is a fighter's

**The line: timing and rules are the game's. What is thrown, how it looks and who throws it are the fighter's, with a small band of stats.** Animation and Combat drew the same line from their own sides.

| Family | Whose | Why |
| :--- | :--- | :--- |
| **Time.** The three strengths' wind-ups (2, 12 and 28 ticks), the flurry gaps, the charge points, the held X's curve, the perfect follow-up's windows and times | **The game's** | Every row QA holds is a row about time. A fighter with his own clock is a second game to tune |
| **The trade's rules.** The run and the close, armour, the launcher and its rest, giving ground, reach and the closing rule, the nudge, the double hit, the stick map, depth | **The game's** | They are what a player learns once and uses with every fighter |
| **Worth and price.** A blow's worth by strength, the ki prices, the mood's units, the set-up weights | **The game's** | A fighter's damage is one multiplier in his band, and never a table of his own |
| **The wounds model.** Regions, stages, the brink, the finisher, the picks by strength, the block rules, `wearPerDamage` | **The game's** | It sets the match's length. Today each fighter's `wounds.json` repeats it, so a length tune is two edits. It should be one shared file, with a fighter's differences beside it |
| **The AI's levers by level, and the director's rules** | **The game's** | The AI plays every fighter by the same shares |
| **His stats:** damage, speed, his care for the world | **His, inside a band** | §2 has the band |
| **His moveset:** his weights in the common pool, the shapes he never makes, the pieces only he has, his launcher's sends, his looks in a clinch | **His** | This is the flavour Orb asks for, and Combat's generator works this way |
| **His body:** silhouette, pose profile, stance, guard, how he falls, his colours | **His** | |
| **His signatures:** what they are and how they look | **His, at the game's prices and tiers** | |
| **His voice:** lines, taunts, efforts | **His** | Orb writes the universe |
| **His AI's leanings:** which stances he prefers, how he treats a town | **His, as a small block** | |
| **His unique mechanic:** his meter, his forms, his wound profile, his Rally | **His, at tier 2** | §3 |

**Four corrections to "flavour is free".**
1. **A piece carries no timing.** A fighter's own blow lands on the same tick as anyone's blow of that strength. Animation fits a key set to its cell's ticks, never the reverse. Inside that fixed length the ease, the overshoot and the lean are his.
2. **Where a blow lands is the game's too.** The wound picks go by strength. When blows name their region, a fighter who goes to the legs more will break legs more (Combat's warning). So his spread of places, and of launcher sends, stays between a floor and a ceiling.
3. **Reach is the game's.** Reach goes by the cell: the strength and the piece's class. **A question for Encounter: does the sim read a key set's own reach or offset?** If it does, that read moves to the cell before the third fighter, or a look becomes a balance difference. All four bodies are within 10% of one another, which Animation says the solve absorbs.
4. **His care is a balance number in disguise.** It decides where his launches go, and so the collateral and the match's length. Both fighters have it at 0 today. Switching it on is a re-baseline, once.

**Two calls Combat asked for.**
- **A cell's count may differ by fighter.** The Protagonist can have 36 lights where another has 30: that is his "huge repertoire", and it is variety and nothing else, since worth and time go by strength. Two conditions: Combat's floors hold for everyone, and his spread of places and sends stays in its band whatever the count.
- **Fighters may share heavies.** Today none is shared: 10 each. Four fighters would need 40 and twelve would need 120, which nobody can pose. A fighter's heavy tier is a shared core with his own on top. At tier 1 he needs 2 that are his alone. At tier 2 he needs 4. No two fighters share more than half their heavies with each other, and a shared heavy is thrown through his own pose profile.

## 2. What happens to the balance

**Rows that belong to the system.** They are tuned once, on a reference, and carry to any fighter inside the band.

| Carries | Examples |
| :--- | :--- |
| Every hard test | Reach, the closing rule, giving ground, the launcher in an opening, the windows |
| The nine cells against the medium AI | The mashers, the holders, the tappers, the edges (`brawl-second-pass.md` §15) |
| Pace | The match's length and its 10th percentile, the first brink, brink to KO, launches a match |
| The mood and the acts; perfect blocks a minute | |

**Rows that belong to a fighter or a pair.** They are read again for each new fighter.

| Read again | Why |
| :--- | :--- |
| His win rate against every other fighter, from both slots | Orb's target: an uneven roster with every pairing inside 45 to 55% |
| His mirror | It shows whether his own numbers bend a system row |
| Collateral, where fights happen, what his launches pick | They follow his care |
| His mechanic's own rows | At tier 2 only |

**A reference fighter.** The system needs a yardstick that isn't anyone's character: base stats, no care, plain everything. The two in the build are real fighters, so I propose a third folder, `REFERENCE`, as the yardstick and the training dummy. Every system row is read on its mirror.

**The stat band, at tier 1.**

| Stat | Band | Today |
| :--- | :--- | :--- |
| Damage (`dmgMul`) | 0.95 to 1.05 | 0.95 and 1.02 |
| Speed (`spd`) | 0.95 to 1.05 | 1.0 and 0.95 |
| His care | -1 to 1. It isn't strength, but it moves collateral | 0 and 0 |
| The sum of his tilts | Near nothing: a fighter who is quicker hits a little softer | |

**What QA runs for a new fighter.**

| Run | Size | It passes when |
| :--- | :--- | :--- |
| His mirror | 100 matches | Every system row is in its band, or within the reference mirror's own spread |
| Against the reference, both slots | 100 each | His win rate is 45 to 55% |
| Against each fighter already in, both slots | 60 each to start, 200 where the first read is outside 45 to 55% | 45 to 55% |
| Four of the nine cells with him as the player: the three mashers and the holder | 60 each | Inside their bands. The other five are read on the reference only |
| His collateral and location rows, as the AI | With the mirror | Their bands |

With four fighters that is four mirrors and six pairings. With twelve it is twelve mirrors and sixty-six pairings, which is why a pairing starts at 60 matches and the reference comes first.

**Who changes: the fighter or the system.**

| What is seen | What changes |
| :--- | :--- |
| A system row is out on his mirror and in on the reference's | **He does.** The system never moves for one fighter |
| The same row is out on the reference too, or two fighters fail it the same way | **The system does,** on the reference. Then every fighter is read again |
| His win rate is 40 to 45%, or 55 to 60% | His stats, inside the band |
| It is beyond 40 or 60%, or the fix would take a stat out of the band | His kit: a signature's worth, his mechanic's numbers. Never a global number |
| A mechanic moves his win rate against the reference by more than 5 points when it is switched on | The mechanic is tuned before he ships with it. Every mechanic has an off switch in data, so the difference can be measured |

**How much retooling, honestly.**
- **For a fighter who is flavour only:** none in the system. One QA pass, and perhaps a stat nudge.
- **Once, for the roster:** the care values. And once more whenever the common pool or a rule changes, for everybody together.
- **For each unique mechanic:** a slice of its own, with its own rows and two or three tuning passes. Forms are the hardest, because a form changes his stats in the middle of a match.
- **What would break this:** a fighter with his own timing, his own damage table, or a mechanic with no off switch.

## 3. Two tiers of "a fighter is in"

**Tier 1, the flavour pass.** His look, his voice, his moveset from the common pool with his own weights and the pieces only he has, his stance and guard, his stats in the band, his care, a signature at the game's prices, and his AI's leanings. He plays on the systems that exist. No unique mechanic.

**Tier 2, his mechanic.** His meter, his forms, his wound profile, his Rally, and whatever is his alone.

| | Where he stands | Tier 1 | Tier 2: waits |
| :--- | :--- | :--- | :--- |
| **The Protagonist** | In the build. Look approved | §5: his own moves, his care, his lines | His parallel transformations and the fold. His meter, filled by a rival's full commitment. Wounds that spread |
| **The Anti-hero** | In the build, as `RIVAL`. Look approved | §5: the same, and the barrage as his signature. His tail of hair waits on rig bones, and tier 1 ships with it still | His Pride and its crash. His three forms. On the Chin. The fusion |
| **The Cyborg** | Not in. Three silhouettes are with Orb: the Press, the Courier, the Hopper | A brawler at home in a town: squares and steps, clamps and slams. The cheapest of the two: no skeleton change, and his cables can be rigid | **Consumption. The molts. The companion hunt.** Regrowth. The fastest last form, with its speed poses |
| **The Empress** | Not in. Three silhouettes are with Orb: the Regent, the Bell, the Tabard | The fighter of her late revisions, alone: precise, cold, cutting. Her mantle needs the chain solver from the first day, or it reads as a board | **Her guard of honour first. The long ladder of revisions.** The mantle as a limb that strikes. A beam that cuts differently in the world |

- **The first two lose little at tier 1.** Their mechanics deepen a fighter who already reads as himself, once §5 is done.
- **The last two lose their premise.** An Empress with no guard and no revisions, and a Cyborg who eats nobody, are a look and a moveset. It is honest to show them as "the fighter, before her mechanic", and it is Orb's call whether to (§7).

## 4. The pipeline for one fighter

**The principle: he is playable early as a grey copy of the reference, and every step replaces one stand-in part with his own.** Orb's eye comes early, where a change is cheap.

| Step | What | Owner | Gate | Size |
| ---: | :--- | :--- | :--- | :--- |
| 0 | **The one-page identity,** pre-filled, for Orb to mark: how he fights, what he wants, his look in words, how he moves | Narrative drafts. **Orb marks** | Orb's six marks | 15 minutes of Orb's |
| 1 | Legal's first screen of the page | Legal | A pass | |
| 2 | **Three silhouettes** | Art. **Orb picks one** | Orb's pick. **This is the step both new fighters wait at today** | 3 to 4 rounds of Art's to a finished look |
| 3 | A grey copy in the build: the reference's data under his id | Simulation, Tools, UI | The others' goldens don't change | |
| 4 | **The ten-second study:** his stance, a light, a medium, a heavy and two hits taken, as one clip | Animation. **Orb says yes, change or no** | Nothing of Animation's starts before it | Half a day |
| 5 | **His sheet:** his row on the roster's axes, stats and care, leanings by stance, his signature, what is tier 2 | Game Design | The EP | A page |
| 6 | His identity row and generated moveset; **a one-page card for Orb** in place of the 805-line sheet | Combat. **Orb says yes or no to the card** | Legal's screen of the sheet. I check the nine cells keep their roles | An hour or two, and ten minutes of Orb's |
| 7 | His shape row and profile, stance and guard, reactions, and 6 to 8 pieces only he has | Animation | The joint and flash checks. A second clip for Orb | 4 to 6 days: about 4 for the Cyborg; the most for the Empress, whose mantle needs the chain solver, specified and not built |
| 8 | His palette, aura and lane colour with the colour-blind check; face; turnaround | Art | The colour tool. Orb approves the face | Inside Art's rounds |
| 9 | His data folder in full, and his AI's block | Simulation, Encounter, Tools | The validator. Parity | |
| 10 | **Ten lines,** for his moments | Narrative. **Orb marks each ten** | **No line of his is used until Orb has marked ten.** None of the voice lab's 1,386 rows is marked today, so until then a fighter has efforts and captions only | 5 minutes of Orb's |
| 11 | His voice in sound; his plate and portrait; his ki's colour | Audio, UI, VFX | | |
| 12 | QA's runs of §2 | QA | The bands | |
| 13 | **Orb plays him** | Orb | Orb | |

- **What runs together.** Steps 1, 2 and 3 start the day Orb marks the page. Steps 5 and 6 need only the page. Steps 7 and 8 need the silhouette and the study. Step 10 runs beside everything.
- **Orb's eye, in order:** the page's marks, the silhouette, the ten-second study, Combat's card, the ten lines, and then playing him. The first four are early and cheap, and together they are under an hour of his time.
- **The narrow parts are Orb's picks first, then Animation's days.** Everything else is pages and data.
- **Tier 2 is a second trip** through steps 5 to 13 for one mechanic, with its off switch. Animation sizes a fighter's tier 2 at 8 to 12 days.

**The common pool, by Combat's count.** 95 strikes are posed: 39 for both fighters and 28 for each alone. At that rate four fighters need about 55 more. For twelve, the share that is a fighter's alone has to fall to about 15, his heavies and energy pieces, and the common lights and mediums have to grow from 65 to about 120, so that weights and bans alone can tell fighters apart. Sharing heavies (§1) is the first step of that. The pool is thin in elbows, knees, shoulders and the head, which is the Cyborg's ground.

## 5. The first two: what ends "generic"

Orb's word for them today. They have their looks. They fight with the same borrowed moves, in one style, toward the world in the same way, with one signature and no voice.

| In order of effect | What | State |
| ---: | :--- | :--- |
| 1 | **Their own moves.** The generated movesets in place of the shared pools. Shapes the two share fall from 97% to between 35 and 46% | Combat's recipes wait for their window |
| 2 | **Their care, switched on.** The Protagonist leads a fight away from a town, and the Anti-hero shows off on a skyline: 0.8 and -0.5. It is the cheapest change, and the one that makes two matches differ | Data. One re-baseline |
| 3 | **A signature each.** Both fire the same beam. The Anti-hero's is the barrage, which is in the signature chart as his. The Protagonist keeps the beam | Encounter sizes the barrage |
| 4 | **Stance, guard and idle** that differ at a glance. Animation has their shape rows and profiles in. Whether their guards and stances are their own yet is a question for Animation | To check |
| 5 | **Ten marked lines each** | Orb's marks |
| 6 | Their heavy tiers, which Animation has provisionally: 10 each | In hand |

That list is the tier 1 of the two who are already in. None of it is a unique mechanic.

## 6. The order

| Order | What | Why here |
| ---: | :--- | :--- |
| Before | **The line of §1 in the data:** one shared wounds and ladder file with a fighter's differences beside it; the `REFERENCE` folder; a way to pick a fighter in the build. Combat's pool builder and probe made to take any number of fighters, which is a session of its own | Without it the third fighter is fitted by hand |
| 1 | **The first two, made their own** (§5) | It needs no new art. It proves steps 6, 9, 10, 12 and 13 |
| 2 | **The Cyborg,** the pilot of the whole pipeline | Animation and Art both find him the cheapest. He is the first new body, and a brawler in a town is what the build does best |
| 3 | **The Empress** | Her mantle needs the chain solver. Animation puts her first form at 8 to 12 days. She also gains most from waiting for her guard |

**What "soon" can honestly mean.**
- The first two can stop feeling generic without waiting for anyone's art: the recipes window, the care values and ten lines each.
- **The Cyborg is the next fighter in.** After Orb's silhouette pick: Art's 3 to 4 rounds, Animation's half-day study and then about 4 days, Combat's hour or two.
- **The Empress follows the chain solver.**
- Each tier 2 mechanic is a slice of its own, in the order Orb wants them. None is needed for four fighters to be playable.

## 7. For Orb

1. **One clock for all fighters.** A heavy-handed fighter looks heavier, hits a little harder and moves a little slower, but his blows take the same ticks. That is what lets the balance carry.
2. **The Empress and the Cyborg before their mechanics:** show each as a look and a moveset, or hold each until her guard and his consumption exist.
3. **The silhouettes,** three each, which are with Orb now. Nothing of theirs can start before the pick.
4. **Shared heavies.** At first a new fighter borrows most of his heaviest blows from the common pool, with two of his own.
5. **The Anti-hero's signature is the barrage,** and the Protagonist keeps the beam.
6. **A plain reference fighter** stays in the build as the yardstick and the training dummy: in the player's roster, or out of sight.
