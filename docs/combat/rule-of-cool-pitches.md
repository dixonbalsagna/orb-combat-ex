# Rule-of-cool pitches: procedural combos, the right hand and the planet

Owner: Combat and Choreography. 2026-10-31. For Game Design to rule on. Nothing here is built. Every number is a first value.

**Orb's order:** "I want novel solutions engineered to make this update as playable, responsive, and fun as possible, I want more features compatible with our "rule-of-cool" mapped out and built towards with regards to controller function and the procedural combo system."

**The idea in one line:** the fighter's seed writes the sentence, and the place you're standing finishes it. The same presses in the same place always give the same combo, so it can be learned. A new place gives a new ending, so it stays a surprise you caused.

## What all ten keep

| Rule | What it means here |
| :--- | :--- |
| **Learnable** | Each fighter's tables come from a fixed seed, written offline by the generator (`moveset-generator.md`), the same for every player and match. They fit `pillar-2-wordings.md` #1, Game Design's recommendation. The wording is still Orb's. If Orb picks another, pitch 1 falls away and the others still work |
| **Deterministic** | Inputs are sim state and the press log, already hashed. Any draw is keyed, as `DirRecipe.pickWhere` is, never the match RNG |
| **Off means off** | Each sits behind its own data switch, so the golden doesn't move with it off |
| **One thumb** | No pitch needs the stick and B at once, so a claw grip gains nothing. Thumb moves are in sequence, and shoulders are held by the other fingers |
| **People (RL-213 to RL-217, RL-219)** | No new term reads people, crowd, toll, `popAlive`, `popNear` or `popHist`. Buildings score by standing, height and wear. `WorldSettle.noTarget` landmarks are never a target. No reward, sound or text for harm |
| **Bolus (RL-220)** | His bite and clamp are clear on fighters only: torso, limbs or guard, with sparks or a bruise, the jaw a machine part |
| **Rationing (`rule-of-cool.md` §1)** | Rule 2 holds, one big set piece every 20 s, and a second plays as its ordinary version. Planet-scale launches share 3 a match. At most two of Legal's seven marks at once |
| **The look (ADR 0010)** | Nothing is drawn on or over the fighters. The body, the world and the camera carry every cue |
| **The launch tick** | It's 10 to 14 ms now. Each pitch's cost below says if it adds a read at press time |

## My order

Build **1, 2 and 3** first: they're what a player notices tonight's build lacks. **5** next, because the meteor can't be reached from the stick as ruled today (see the pitch). The rest follow by Game Design's taste.

| # | Pitch | In a line | Cost |
| ---: | :--- | :--- | :--- |
| 1 | Phrases | Each fighter owns strings you can learn | Medium |
| 2 | The place finishes it | The same string ends differently by biome and height | Small to medium |
| 3 | Walk him to the tower | The stick lines him up during the string, and B puts him through | Medium |
| 4 | Up the face | A string that climbs a tower and ends through the roof | Large |
| 5 | Ignition | A stick stun banks the charge that earns the meteor | Small |
| 6 | Power's dialect | The same string speaks louder at each tier | Small to medium |
| 7 | Your hands | The ender follows how you've been pressing | Small |
| 8 | The world links | Breaking a prop opens a free link | Small to medium |
| 9 | Back to the scene | Landing him in your old crater makes it worse | Small |
| 10 | Clamp and carry | Bolus's grip is a link you steer | Medium to large |

## 1. Phrases: every fighter's own strings

- **Pad:** X, Y or a stick direction, in a short pattern, as now. For example, the rival's X, X, stick up.
- **The choreographer:** the generator writes each fighter 8 to 12 phrases, 2 to 4 presses long, by seed. A press inside a known phrase takes that phrase's next piece, in place of the pool's draw (`_cellPiece`). A press outside one falls back to the pool, as today. Breaking off is free: the blow you broke with starts over. The director still owns the staging, camera and launch. Worth and timing don't change, only which piece plays.
- **Why it's cool:** a player can name a combo, practise it and show it to a friend, yet nobody wrote it by hand. Two fighters' lists read differently from the same buttons. It answers Orb's question about why fighting games don't do this.
- **Cost:** medium. A generator pass, a list in the training mode, and Encounter's reader. No read at press time beyond the press log. A phrase needs a look only if the pieces already drawn don't flow, and the generator's links handle that.
- **Test:** the same presses throw the same pieces over 1,000 seeded runs. Two fighters' phrase lists overlap under 30% by piece. Rally variety still scores: a phrase repeated in a string loses freshness as any blow does. No best phrase: QA's worth band stays within today's.

## 2. The place finishes it

- **Pad:** the same phrase, anywhere.
- **The choreographer:** a phrase's last blow reads one of about eight place classes: open ground, in a street, over water, on ice or mud, against a cliff face, among trees, low air, high air. Each fighter's seed gives each class an ender piece and a carry. Over water, the same string that ends in a body blow on land ends in a downward slap that skims him. In high air, it ends in a spike. The class comes from reads `_biomeCands` already makes, or `WorldContact.lookAt`, height above ground and `_cliff`, taken once at the last blow.
- **Why it's cool:** pillar 7 for every combo. The player learns one string and finds the planet changes its last word, and comes to fight somewhere on purpose.
- **Cost:** small with existing pieces, medium with new looks from Animation. One small read a string, under 1 ms, and `_cliff` is the one to cache.
- **Test:** eight classes show eight distinct ender histograms for each fighter. The same place gives the same ender on replay. Worth is unchanged by class.

## 3. Walk him to the tower

- **Pad:** during a string, hold the right stick's aim or LT's lane toward a standing building in reach, then **B**. Level 3 first, for a full send.
- **The choreographer:** each blow's carry leans him up to 1 bh onto the line to that building, in x and in depth, and the attacker's feet follow. You see him being worked over there: there's no marker. On B, the planner's existing `WorldBrunt.aim` and `chainPlan` have a line that works, and the chain goes through the towers behind it. The stick's charge level picks the floor, using `interiorAim`'s heights, which are off today: level 1 low, level 3 high. If he breaks out, the line is just where he stood, and nothing's owed.
- **Why it's cool:** it's the combo Orb asked for, a string that ends with a body through a tower, and it's yours from the first blow. Sending him through a building you've been walking him to is a different feeling from a planner picking one.
- **Cost:** medium. Encounter's carry, Combat's ender row. `candidates` costs 0.2 to 2.5 ms, so read it once a string and hold it, not per press.
- **Test:** with the stick on a tower for 3 or more blows, at least 70% of Bs reach it. With no stick, the rate is today's. RL-214's lint passes. The hero's care mark-down is untouched. Civilian bands stay inside 12 to 30%.
- **Needs:** Legal's look at a player choosing the floor of an occupied building, under RL-213 and RL-219. If it's a problem, floors go and the rest stands.

## 4. Up the face

- **Pad:** hit him into a wall with stick toward, then stick up, up, up, and stick down or B at the top.
- **The choreographer:** stick toward with a facade behind him pins him to it (`wall-slam.md`'s 2.0). Each stick up then climbs both fighters a level along the face, and each blow breaks that band of the facade. Stick down at the top spikes him through the roof, and the chain's floors go in sequence on the way down. The camera eases out as you climb and lands on the drop.
- **Why it's cool:** it's the moment people clip. The whole string is drawn on the building, and the wreck stays, floor by floor.
- **Cost:** large. A climb in Encounter's hook, a facade band in World, a pinned pose from Animation, Camera's framing. One stun a string has to bend for the pin, or the climb is carries rather than stuns. It's a late build.
- **Test:** the climb fits a 3-second window. A guard or slip at any floor drops out cleanly. It counts as one set piece under rule 2. Structures stay under the tier's `levelCapShare`.

## 5. Ignition: the stick earns the meteor

- **Pad:** stick up, level 3 (54 bare ticks). If it lands, move the thumb to B and hold to the flash.
- **The finding:** the meteor is ruled to need a fully charged B on a stunned or weak foe, and a stick stun counts. Level 3's stun is **40 ticks**. A full charge takes **44** (`brawl.heavy.charge.fullTicks`), plus thumb travel. **So the stick stun can't lead to the meteor today:** he recovers first. Only "weak" reaches it.
- **The choreographer:** at both fighters' tier 4 only, a level 3 stick stun banks charge: B's full mark drops to 24 ticks for the next B inside the stun. That's 12 ticks of thumb travel, 24 of charge and 4 to land, inside the 40. The body shows it: he's floating at 4 bh, and the attacker's stance sinks as the charge fills. Nothing else changes. All of the meteor's other gates and budget stand.
- **Why it's cool:** 54 bare ticks is the biggest bet in the game. Winning it and hearing the charge catch is the route to punching someone out of the sky, and the player knows exactly what they did.
- **Cost:** small. One data row and Encounter's line. Animation's charge stance exists. VFX's meteor trail is parked.
- **Test:** the route lands at least once in a scripted tier 4 run. Meteors stay about one match in two or three, at most about 2 in one. At least 60% land. No new way past a guard. At most two of Legal's marks at the catch.

## 6. Power's dialect

- **Pad:** the same phrase at any tier.
- **The choreographer:** a phrase's ender has a row per tier band (1 to 2, 3, 4). The pieces get bigger and the world answers more: at tier 1 he's knocked back, at tier 3 the air cracks and dust lifts, at tier 4 a small crater marks the ground and the landing carries. The first blows don't change. It uses the ladder's existing gate: below tier 3 the world doesn't react.
- **Why it's cool:** a player feels their power growing in a combo they already know. It's pillar 4 at the size of a single press.
- **Cost:** small to medium. Data rows, VFX's existing rings and dust, World's small crater. No new read: tier is on the fighter.
- **Test:** a tier 4 ender digs no more than `balance-targets.md` allows. No planet damage below tier 3. The flash register passes on the tier 4 ender. Worth follows the ladder, with no extra bonus.

## 7. Your hands

- **Pad:** whatever you've been doing.
- **The choreographer:** `DirAlchemy` already reads the last presses as a mix. It picks the accent of the next ender, from three written by seed: a mashing player's ender is a fast multi-hit look, a timed player's a clean stop with a held beat, a holding player's a big wind-up. Worth, timing and result are the same. It only changes which piece and how it's staged. It's in the replay, because the press log is.
- **Why it's cool:** the game seems to know you. Two players on one fighter end up with fights that look like their own, with nothing to unlock.
- **Cost:** small. Three rows a fighter and a read that exists.
- **Test:** three scripted players throw three distinct ender histograms. Worth is unchanged, to the bit. QA's no-best-button band holds.

## 8. The world links

- **Pad:** stick toward, with a tree, rock, pole or car behind him.
- **The choreographer:** the blow's carry breaks the prop, using the props `_smashProp` already breaks. That break opens one free link: the next press inside 20 ticks costs no ki, keeps the string's stun rule, and reads as a follow-through off the impact. The landscape's own reaction is the cue: the tree falls, the rock splits. One a string.
- **Why it's cool:** "a landscape that answers back" as a move. A forest fight has a different rhythm from a desert one, because of what's there to break.
- **Cost:** small to medium. `launch-reads` gives the props cheaply. Encounter adds the free link. Props are read once at a toward blow, under 1 ms.
- **Test:** one link a string, at most. Biomes with props show a higher string length than bare ones, by under 20%, so a desert isn't a penalty. Broken props stay broken in the hash. No prop is a `noTarget` kind.

## 9. Back to the scene

- **Pad:** a send, with the stick aimed, as any launch.
- **The choreographer:** a landing within a crater's radius in `S.store` from earlier in this fight, or on already worn ground, plays a bigger second beat: the old crater's rim collapses, its dust rises again, a longer rumble. The impact's worth is the same. The launch planner adds a small score to the crater you made, read from the store, never from people.
- **Why it's cool:** the fight has a memory, and the planet keeps score. Sending him back to where you first hurt him is a story, and it comes from systems.
- **Cost:** small. A store read at landing, World's existing rim. The crater's energy cap stands.
- **Test:** the second beat fires only on a landing within the radius. The store's hash is unchanged by the read. No score term outside the store's own wear. Below tier 3, there's no collapse.

## 10. Clamp and carry: Bolus's grip as a link

- **Pad:** after a stick stun, hold the stick toward him. Then aim it, and release or press B.
- **The choreographer:** his jaw clamps a limb or the guard, with sparks. While held, the stick steers both bodies for up to 40 ticks, slowly, toward what's ahead, a wall or a tower's foot. Release throws him there, and B bites and sends him. The director reuses the clinch-first hybrid's pair spec (`grapple-hybrid.md`). The victim mashes out as from a clinch.
- **Why it's cool:** a fighter who's a different animal, not a palette: a right-stick verb only he has. It's the "characters are personalities" pillar in the hands, and he drags you through his yard.
- **Cost:** medium to large. Bolus isn't built, so this waits on his kit. It sets the pattern for fighter-only stick verbs: any of the twelve can have one.
- **Test:** RL-220's forms hold: no blood, no chewing, never a lingering face or neck bite, fighters only. Mashing out takes under 30 ticks at equal tier. The steer moves at most 2 bh a second, so it isn't a free carry across the map.

## For Game Design

1. **Pitch 1's question from the wordings:** a string the player breaks off starts over, and costs nothing. Is that right, or should a broken phrase cost some flow?
2. **Pitch 5:** is the banked charge the right fix, or would you rather lengthen level 3's stun, or say the stick isn't a route to the meteor?
3. **Pitch 3:** should the line-up work on the hero the same as the rival, given that pillar 5 pressures the hero over collateral?
