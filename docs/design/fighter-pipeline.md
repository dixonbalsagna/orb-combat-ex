# The fighter pipeline: how a fighter gets into the build, and what it does to the balance

Owner: Game Design. Date: 2026-10-12. **A first version, on paper.** Combat, Animation, Art and Narrative are sizing their parts, and their figures go into §4 and §5 when they arrive. Every number is a first value. Co-op is not designed here.

**Orb,** 2026-10-12: "right now we're building a moveset and calibrating balance on two generic stand-in characters, once we start introducing actual fighters intended for the release version how will the balance be affected? how much retooling will need to happen? Ideally each character should have their own 'flavor' of attack animations and movesets, with a large common pool of attacks to pull from. Can we establish a workflow for the characters so I can get at least four into the playable build soon?"

**The short answers.**
- **Balance:** the tuning done on the stand-ins carries, if a fighter's flavour is kept out of the timing and the rules. That is the line in §1.
- **Retooling:** a fighter who is only flavour needs no retune of the system: one QA pass and a nudge of his own numbers. A fighter's unique mechanic is new balance work each time, and that is where the retooling lives (§2, §3).
- **Four soon:** yes, as four fighters with their own look, voice and moveset on the systems that exist. Their unique mechanics come after, one at a time (§3, §5).

## 1. What is the game's, and what is a fighter's

**The line: timing and rules are the game's. What is thrown, how it looks and who throws it are the fighter's, with a small band of stats.** The EP's instinct, confirmed, with four corrections below.

| Family | Whose | Why |
| :--- | :--- | :--- |
| **Time.** The three strengths' wind-ups (2, 12 and 28 ticks), the flurry gaps, the charge points, the held X's curve, the perfect follow-up's windows and times | **The game's** | Every row QA holds is a row about time. A fighter with his own clock is a second game to tune |
| **The trade's rules.** The run and the close, armour, the launcher and its rest, giving ground, reach and the closing rule, the nudge, the double hit, the stick map, depth | **The game's** | They are what a player learns once and uses with every fighter |
| **Worth and price.** A blow's worth by strength, the ki prices, the mood's units, the set-up weights | **The game's** | A fighter's damage is one multiplier in his band, and never a table of his own |
| **The wounds model.** Regions, stages, the brink, the finisher, the picks by strength, the block rules, `wearPerDamage` | **The game's** | It sets the match's length. Today each fighter's `wounds.json` repeats it, so a length tune is two edits. It should be one shared file, with a fighter's differences beside it |
| **The AI's levers by level, and the director's rules** | **The game's** | The AI plays every fighter by the same shares |
| **His stats:** damage, speed, his care for the world | **His, inside a band** | §2 has the band |
| **His moveset:** his weights in the common pool, the shapes he never makes, a handful of pieces only he has, his launcher's sends, his looks in a clinch | **His** | This is the flavour Orb asks for, and Combat's generator already works this way |
| **His body:** silhouette, pose profile, how he falls, his colours | **His** | |
| **His signatures:** what they are and how they look | **His, at the game's prices and tiers** | |
| **His voice:** lines, taunts, efforts | **His** | Orb writes the universe |
| **His AI's leanings:** which stances he prefers, how he treats a town | **His, as a small block** | |
| **His unique mechanic:** his meter, his forms, his wound profile, his Rally | **His, at tier 2** | §3 |

**Four corrections to "flavour is free".**
1. **A piece carries no timing.** A fighter's own blow lands on the same tick as anyone's blow of that strength. Animation poses his pieces to the game's ticks. A fighter may differ by 2 ticks in his follow-up times at most (`brawl-second-pass.md` §16), and not in the first build.
2. **Where a blow lands is the game's too.** The wound picks go by strength, and a blow that names its region does so by rule (the wrench, a vicious blow). A fighter doesn't get his own table of picks.
3. **Reach is the game's at tier 1.** One striking distance and one body size for all four. A bigger or smaller body is a mechanic, and belongs to the later roster.
4. **His care is a balance number in disguise.** It decides where his launches go, and so the collateral and the match's length. Both stand-ins have it at 0 today. Switching it on is a re-baseline, once.

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

**A reference fighter.** The system needs a yardstick that isn't anyone's character: base stats, no care, plain everything. Today's stand-ins are that by accident. I propose a third folder, `REFERENCE`, that stays as the yardstick and the training dummy when the two stand-ins become real fighters. Every system row is read on its mirror.

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
- **For each unique mechanic:** a slice of its own, with its own rows and two or three tuning passes. Forms are the hardest, because a form changes his stats in the middle of a match: each pairing then has a band for each stage of the fight.
- **What would break this:** a fighter with his own timing, his own damage table, or a mechanic with no off switch.

## 3. Two tiers of "a fighter is in"

**Tier 1, the flavour pass.** His look, his voice, his moveset drawn from the common pool with his own weights and a handful of his own pieces, his stats in the band, his care, a signature at the game's prices, and his AI's leanings. He plays on the systems that exist. No unique mechanic.

**Tier 2, his mechanic.** His meter, his forms, his wound profile, his Rally, and whatever is his alone.

| | Tier 1: in the build soon | Tier 2: waits |
| :--- | :--- | :--- |
| **The Protagonist** | Open hands, blade hands and arcs. He lures a fight away from a town. The beam with his look | His parallel transformations and the fold. His meter, filled by a rival's full commitment. Wounds that spread |
| **The Anti-hero** | Fists, plates and straight lines, glasses always on. He shows off on a skyline. The beam with his look, and his bolts thrown as volleys if the look alone allows it | His Pride and its crash. His three forms. On the Chin. The fusion |
| **The Tyrant** (the Empress, in our pages) | The fighter of her late stages, alone: precise, cold, cutting. The beam as a thin cutting beam, in look only. Her blades as hand and forearm pieces on the shared rig | **Her minions first. The long chain of stages. A tail or mantle,** which needs her own rig. A beam that cuts differently in the world |
| **The Cyborg** | A brawler at home in a town: clamps, slams, twitches. His look within the rating Orb has set. The beam with his look | **Consumption. The molts. The companion hunt.** Regrowth. The fastest last form |

- **The first two lose little at tier 1.** Their mechanics deepen a fighter who already reads as himself.
- **The last two lose their premise.** A Tyrant with no minions and no stages, and a Cyborg who eats nobody, are a look and a moveset. That is honest to show as "the fighter, before his mechanic", and it is Orb's call whether to show them so (§6).

## 4. The pipeline for one fighter

**The principle: he is playable on the first day, as a grey copy of the reference, and every step replaces one stand-in part with his own.** Nothing waits for everything. Orb can look at any point, and a change is cheap until Animation's pieces.

| Step | What | Owner | Gate | Runs beside |
| ---: | :--- | :--- | :--- | :--- |
| 0 | **Orb's one-page brief:** who he is, how he fights in three verbs, what he does to the world, one line he would say, what he must never be. Our drafts are templates only | **Orb** | Orb's own | |
| 1 | A grey copy in the build: the reference's data under his id, selectable | Simulation, Tools, UI | Existing fighters' goldens don't change | 0 |
| 2 | Identity and voice: his function, his manner, a first batch of lines | Narrative | **Orb edits the lines** | 3 |
| 3 | Design and silhouette, with Legal's screen | Art, Legal | Legal passes. **Orb picks from three silhouettes** | 2 |
| 4 | **His sheet:** his row on the roster's axes, his stats and care, his leanings by stance, his signature, what is tier 2 | Game Design | The EP | 2, 3 |
| 5 | His identity row and his generated moveset, with its review sheet. The list of pieces only he has | Combat | Legal's screen of the moveset. Game Design checks the nine cells still have their roles | 4 |
| 6 | His pose profile, his own pieces, how he falls. Any rig he needs | Animation | The joint and flash checks. **Orb sees a motion study** | 5; the profile can start at 3 |
| 7 | His data folder in full: stats, his deltas from the shared wounds and ladder, his AI's block, his finisher | Simulation, Encounter, Tools | The validator. Parity | 5, 6 |
| 8 | His voice in sound; his plate, lane colour and portrait; his ki's colour | Audio, UI, VFX | The lane colour check | 6 |
| 9 | QA's runs of §2 | QA | The bands | When 7 is in |
| 10 | **Orb plays him** | Orb | Orb | |

- **Orb's eye is asked four times,** and three of them are early and cheap: the brief, the silhouette and lines, the motion study. The fourth is playing him.
- **The narrow parts are Art and Animation.** Steps 2 to 5 and 7 are pages and data. So two fighters can be in the pipeline at once if their pieces are staggered.
- **Tier 2 is a second trip** through steps 4 to 10 for one mechanic, with its off switch.
- **For twelve,** the same steps hold. What grows is step 6, where a fighter needs his own rig, and step 9, which §2 keeps in hand.

## 5. The order, and a pilot

| Order | Fighter | Why here |
| ---: | :--- | :--- |
| Before | **The line of §1 in the data:** one shared wounds and ladder file with a fighter's differences beside it; the `REFERENCE` folder; a way to pick a fighter in the build | Without it the first real fighter becomes the yardstick |
| 1, the pilot | **The Anti-hero.** `RIVAL` becomes him | He is the nearest to what is built: his identity row exists, and Legal has ruled on his glasses. He proves every step once |
| 2 | **The Protagonist.** `PROTAGONIST` becomes him | Same rig, and his row exists. He overlaps the pilot from step 2, which tests two in the pipeline at once. His lines are in Orb's hands already |
| 3 | **The Cyborg** | His tier 1 is a brawler in a town, which is what the build does best. He is the first new body |
| 4 | **The Tyrant** | Her tier 1 is the thinnest, and her rig is the most work. She gains most from waiting for her minions |

**What "soon" can honestly mean.**
- **The first two at tier 1** need no new system. They need the generated movesets live in place of today's stand-in pools, and the super-heavy tier posed. Both are already ordered, and I haven't checked how far along either is. If they land, the two can follow the tuned brawl into the same build.
- **The third and fourth at tier 1** each need a design, a silhouette, a pose profile and a handful of pieces. Their size is Art's and Animation's to give.
- **Each tier 2 mechanic is a slice of its own,** in the order Orb wants them. None is needed for four fighters to be playable.
- The pipeline doesn't wait for the brawl's remaining passes, and they don't wait for it: one is rules, the other is flavour.

## 6. For Orb

1. **Fighters share one clock.** A heavy-handed fighter isn't slower in ticks than a quick one: he looks heavier, hits a little harder and moves a little slower. That is what lets the balance carry. Is that acceptable, at least until all four are in?
2. **The Tyrant and the Cyborg without their mechanics.** Show them at tier 1 as a look and a moveset, or hold each until minions and consumption exist?
3. **The pilot.** The Anti-hero first, then the Protagonist?
4. **The brief.** One page from Orb for each fighter starts his pipeline. Which does Orb want to write first?
5. **A plain reference fighter** stays in the build as the yardstick and the training dummy. Wanted in the player's roster, or kept out of sight?
