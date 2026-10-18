# Buildings in a fight

Owner: Game Design. Date: 2026-10-12. **Paper only.** Nothing here is built or run by me, and **every number is a first value.** The measures are World's (`docs/world/destruction-hook.md`). Co-op is not designed here.

**Orb,** 2026-10-12: "realistic building destruction is absolutely a priority... smashing opponents through multiple buildings is climactic, catastrophic, visually appealing, and part of the gameplay hook."

**What World found.** A body hits a building 1.35 times a match, though 40 of 118 buildings fall, nearly all to blasts and beams. Three things are missing: escalation (a tower is punched at every tier), structure (a body clears a whole floor) and time (a collapse is one tick). And fights leave town inside a minute, because the commonest launch hauls the target to open ground.

## 1. The ladder: what each tier does to a building

World's second experiment, taken, with one addition for houses.

| Tier | A house, under five floors | A tower | The chain |
| ---: | :--- | :--- | :--- |
| 1 | **He goes through it** | **It holds him.** The face breaks and he comes back off it: the wall slam (§2) | One tower, or two houses |
| 2 | Through | He punches one tower. The next holds him (towers re-ruled in §6.1) | 2 |
| 3 | Through | Through | 3 |
| 4 | Through | Through, and the breach is most of the building's width | 4 |
| A finisher | | | 5 |

- **So the first minute already breaks buildings.** A house comes apart at tier 1, and a tower shows the hit. "Through several towers" is what the late tiers and the finisher are for, which is where Orb puts it: the climax.
- **A house counts as half a link** of a chain.
- **The duel of perfects** (`brawl-second-pass.md` §14, the tenth round) ends in an amplified knock-back that meets buildings as if the sender's tier were one higher for every two levels the duel reached, up to a finisher's.
- **The lodge.** The last building of a chain takes what is left of the launch. He ends inside the breach, held for 0.5 s at tiers 1 and 2, 0.7 s at tier 3 and 0.9 s at tier 4 and in a finisher. That building takes the rest of the launch as one more hit. The hold is part of the launch, so it is inside "except in knock-backs".

**What a tier-1 hit on a tower must show,** since it doesn't go through:
1. The face breaks over the floors he covers, and glass goes from the floor above and the floor below: three or four floors of damage, readable at the fight's zoom.
2. He is seen to stop in the wall, for about 15 ticks, before he comes off it.
3. Debris and dust fall to the street for at least a second.
4. **The mark stays** for the match, and the building is weaker for it. Three walls on one tower and the fourth launch goes through.
5. The building is heard to take it.

## 2. Three rules for buildings

| Rule | Ruling | First values |
| :--- | :--- | :--- |
| **The wall slam.** A launched body that meets a building which holds him | **Yes.** It turns a launch at tier 1 or 2 into a play: aim at what you can't break. A floor that is punched gives no slam | He takes twice the building's hit. He is staggered at the wall for 24 ticks. And the attacker has the first move: he can't start an approach until 45 ticks after he is free (`brawl-second-pass.md` §14). World's "free rush" is that first move, and not a blow given for nothing |
| **The falling stack.** A collapse takes seconds, and what stands under it is hurt | **Yes.** It is the largest single step toward what Orb describes | A tower comes down over at least 2 s. It warns for at least 1.5 s first, by sound and dust, and always for 0.6 s longer than any hold a fighter there is in. Under it: 6 damage for each floor that lands on him, 100 at most, and he is buried for 0.5 to 1 s. It hurts only the fighter it was aimed at (§6.3, re-ruled 2026-10-16; it hurt either fighter) |
| **Cover from a beam.** A standing building in a beam's line takes it for him | **Yes, with beams in depth, and not before.** Along a street a beam's line is clear, so there is no cover to take until a beam can be aimed across the band. And it must never make a fighter safe for good | A beam of tier 1 or 2 is stopped while the building stands, and carves it stage by stage. At tier 3 it cuts through after 1 s. At tier 4 it cuts through at once, at 0.7 of its power. The people inside are on the firer's account |

- **The fighter who cares pays for all three.** A wall slam into a full tower, a stack brought down, a beam through cover: the people inside cost him, as every person he kills does (`hero-forms.md` §7). He can still do each one. That is the Protagonist as Orb wrote him: he fights to protect, and his fixation on the fight breaks things.
- **A drifting brawl still never damages a building** (`depth.md` §2). Flights do: a launch, a throw, a rush that ploughs.

## 3. Aiming for it, and staying in town

**What a launch through buildings is worth.**
- **Damage.** Each building he goes through hits him, the lodge takes the rest, and a wall hits him twice over. The band: a launch through one building is worth at least half again a launch across open ground, and a full chain at least double.
- **The mood,** which already takes more for a building launch and a chain.
- **Nothing toward the finisher** beyond what any launch gives. The pay is damage and the sight of it.
- **For the Anti-hero,** his Pride for a building levelled, as planned.

**The player's stick is a vote that wins.** When he launches with the stick toward a side, and a building stands on that side inside the launch's reach, the planner takes the building if a plan to it exists. The planner's own taste decides only when the stick is neutral. So a player sets a launch up by where he drags the brawl first, which is what the nudge and the depth rules are for.

**The AI votes by its care.** A fighter who cares takes a building only when nobody is in it, or late and behind. A fighter who doesn't takes it when it is there.

**What the share of buildings taken means** (ruled on Encounter's town levers, 2026-10-13). QA's band of 35 to 60% averaged two personalities, and with both cares at 0 it read one of them. "Preferred" means taken. So the share is read by care, in two rows (§4). `bruntPrefer` stays at 40, where a fighter with no care takes a building in reach 97 times in 100. The 35 to 60% band is retired. Bodies into buildings read 3.58 a match from a crossing on 12 matches, against 4 to 8. That is read again on QA's 100 matches before any lever moves. The ladder's wall slam then makes a tier-1 building a play, and is the next step if it is still short.

**What keeps a fight in town, without pinning it.**

| Today | The rule | Whose lever |
| :--- | :--- | :--- |
| The commonest launch hauls him 13,200 units to open ground, and is paid for distance and for a new biome | **A launch along a street stays in the street.** In a settlement it lands inside it, 3,000 to 4,000 units on, while a street runs that way. The distance bonus is halved in a settlement, and the new-biome bonus is paid once in 60 s | Encounter |
| A building launch is 5 to 9% of launches | With a building on the line and no stick held, it is preferred from tier 2. With the stick toward it, it wins | Encounter |
| The hero's lure leads every fight out | It stays, since it is his care. It pulls by the people near, and not by the buildings. The Anti-hero's care pulls the other way. **Where the fight is becomes a tug between the two,** and a player takes it either way with his nudge | Encounter, with the care values |
| A fight that starts in open country never sees a building | Nothing forces it to. The planet is the arena | |

## 4. QA's rows

| Row | Today | Bound |
| :--- | :--- | :--- |
| Bodies into buildings a match, from a start in town | 1.35; 2.5 from a crossing | 4 to 8 |
| Launches that take a building, in a settlement | 5 to 9% | 15 to 30% |
| Launches that end in a building, every launch from the default start | 10.4% at `bruntPrefer` 40 | **4 to 15%,** where it was 4 to 10% (ruled 2026-10-15). Orb has made destruction a priority, and the lever is doing what it was set for. The settlement row above is the one that matters |
| Fight time within 1,500 units of a building, from a start in town | 15%, or 41% and falling | 30 to 50% |
| Fight time outside every settlement | | At least 25%: the fight isn't pinned |
| A tier-1 body through a tower | | Never (hard) |
| A tower hit at tier 3 or 4 with the strength to punch it | | He goes through (hard) |
| Every chain ends in a lodge, held 0.5 to 0.9 s | | Every time (hard) |
| Wall slams a match | | 1 to 3 |
| Chains of two buildings or more a match | | 0.5 to 2, at tier 3 and up |
| A tower's collapse | One tick | At least 2 s, after at least 1.5 s of warning (hard) |
| A fighter hurt by a falling stack | | 0.2 to 1 a match. It should be rare and remembered |
| A launch through one building against one across open ground; a full chain | | At least 1.5 times the damage; at least 2 times |
| With the stick toward a building in reach, the launch takes it | | At least 90% of the times a plan exists |
| With no stick, a building in reach is taken by a fighter whose care is 0 or less | 97% at `bruntPrefer` 40 | At least 80%: "preferred" means taken |
| With no stick, a building in reach is taken by a fighter who cares, while people are inside | Not read: both cares are 0 today | Under 35% |
| The collateral budgets, the people lost in a match, the match's length | In band | Their bands. More fighting in town will press all three, and they are read first |

### Ruling on Encounter's window 2 (2026-10-17, main 20b95092)

**No lever's weight moves. Two bands move, three rows are re-based, and the one row still under waits for the new sources of bodies into buildings.**

| Row | Read | The ruling |
| :--- | ---: | :--- |
| Launches that end in a building | 11.0% | **Its band is already 4 to 15%** (ruled 2026-10-15, the table above). QA's runner still reads 4 to 10, and moves to 4 to 15. It passes |
| Building brunts as a share of all launches (`balance-targets.md` §5b) | 12.1% | **4 to 15%,** for the same reason. The 10% top was set while collateral ran high (§18). Orb has since made destruction a priority, and the collateral bands still hold |
| Halted journeys | 38.4% | **Re-based on journeys that end on the ground,** not all journeys. A launch that ends in a building can't halt on the ground, so more brunts take from the denominator. 38.4% of all is about 43% of ground journeys. The band stays 40 to 60% |
| Long launches (1,500 units or more) | 28.8% | **Re-based on launches that don't end in a building:** a brunt stops a launch short by design. 28.8% of all is about 32% of those. The floor stays 30% |
| Flights off a crater's lip a minute | 0.47 | **Its floor goes from 0.5 to 0.4,** since the launches buildings now take are launches the craters would have had. It failed narrowly before this window too (0.36 and 0.44 on older baselines). The top stays 2.5 |
| Bodies into buildings a match | 3.30 | **The band stays 4 to 8, and no lever moves.** Encounter found the vote spent: the ceiling is how often a plan into a building is offered. The sources that add bodies are ruled and coming: power sends through towers and the lodge (§6.1), the inside chain (§7.3), plain sends lodging from tier 3, throws into walls (`grapple.md`), the choreographer's bend toward a building (`launch-anywhere.md` §6), and World's more offers. If it is still under once those land, the next lever is World's offer count, never `bruntPrefer` |

- **The collateral bands are read first,** as always. If people lost or front-row structures go over, the brunt share's top comes back to 10% before anything else moves.

## 5. The order, and what it asks

1. **The ladder and the lodge** as data (World's first window), with the wall slam, which is a rule on the same hit.
2. **Holes the size of the hit,** so a punch leaves a floor with a hole and not a missing floor (World).
3. **The collapse that takes seconds, and the falling stack** (World, with Rendering's and Audio's warning).
4. **The planner's side,** with Encounter's work on using the planet: the haul, the bonuses, the stick's vote.
5. **Cover from a beam,** with beams in depth.

| Who | What |
| :--- | :--- |
| World | Steps 1 to 3; the house's half link; a building that remembers its walls |
| Encounter | Step 4; the first move after a wall slam; the AI's vote by care |
| Combat | The stack's damage number, and the wall slam's |
| Rendering, VFX, Audio | The five things a tier-1 hit shows; the warning before a collapse; the lodge |
| Camera | A chain through buildings, and a collapse, held in frame |
| Legal | The collapse through the flash check |
| QA | §4 |

## 6. Orb's answers (homework 5, 2026-10-16)

Orb's words are in `docs/ep/vision.md`, "Orb answers homework 5". World, Rendering and Encounter build from this section. Where it differs from §1 to §3, this section wins.

### 6.1 Towers are earned by power (5b)

Orb: early, "a well-earned power hit could send an opponent through the side of a skyscraper and they recover inside", and at max power "the same hit could launch the fighter through three skyscrapers, causing them to pancake-collapse, then propelling into a crater that levels nearby skyscrapers".

- **A power send is one the attacker earned:** a launch (B in an opening, or a charged heavy at full), a finisher, a perfect B's ender, the duel of perfects' send, or a beam struggle's overwhelm.
- **Every other send is a plain send:** a knock-back, a throw, a blast's push, or a rebound off a wall.

| Tier | A power send into towers | A plain send into a tower |
| ---: | :--- | :--- |
| 1 | **Into the tower.** He goes in through the face, lodges inside it and recovers there (§6.4) | The wall slam (§2): it holds him |
| 2 | Through one tower, and into the second | The wall slam |
| 3 | Through two, and into the third. The two he went through are cracked at the core (§6.2) | Into it |
| 4 | **Through three, which pancake,** and on into the ground beyond them: **a crater whose blast levels the towers near it** | Through one, and into the second |
| A finisher | As tier 4, through four | |

- **This replaces §1's ladder for towers.** Houses are as §1: through at every tier, as half a link. §1's five things a tier-1 hit shows now belong to the wall slam.
- **The pancake.** Each tower he went through at tier 4 comes down floor onto floor from the breach up. They fall in the order he went through them, 0.3 s apart, each over 1.5 to 2.5 s. The breach is their warning, and no fighter is under them to be hurt (§6.3).
- **The crater beyond.** The send ends on the ground past the last tower in a crater of a tier-4 impact (World's size). Its blast brings down every tower within 1,200 units of it as a falling stack, with §2's warning.
- **The budget still holds.** The collateral window and ceiling go by the highest tier, and the chain spends them. When they are spent, the director picks sends that miss buildings, as now. **World's ask:** the tier-4 budget leaves room for one full chain, pancakes and crater, the first time a match reaches it.

### 6.2 The three rules (5c), all confirmed

- **The wall slam,** as §2: twice the building's hit, a 24-tick stagger at the wall, and the attacker's first move (he can't be approached for 45 ticks after he is free).
- **Cover from a beam,** as §2, with beams in depth and not before. At tiers 1 and 2 a beam is stopped while the building stands, and carves it. At tier 3 it cuts through after 1 s, and at tier 4 at once, at 0.7 of its power.
- **The falling stack: crack the core, a clear warning, and it comes down.**
  - **A tower's core cracks** from a power send through it at tier 3 or more (§6.1), a beam that carves through its middle third, or its fourth mark (§1's marks).
  - **The warning** lasts at least 1.5 s, and always 0.6 s longer than any hold a fighter there is in. The crack is heard, dust jets from the floors at the crack, the tower leans a few degrees, and windows burst up its face.
  - **It comes down** over at least 2 s.
- **The live picture-in-picture of a dodged beam hitting a tower** (Orb's note to 5c) is Camera's to propose.

### 6.3 A falling building hurts only the fighter it was aimed at (5d)

- **The fighter it was aimed at** is the target of the blow that cracked its core: the one sent through it, or the one the beam was fired at. If he is under it, he takes §2's damage (6 a floor, at most 100) and is buried for 0.5 to 1 s.
- **Nobody else is hurt by it:** never the attacker who brought it down, and never a guard.
- **The people in it and under it** are on the account of whoever cracked it, as every casualty is.
- This replaces "It hurts either fighter" in §2.

### 6.4 Lodged in a building (5f): two versions, as switches

Orb plays both before choosing. The switch is `lodge.mode` in World's data. Both start the same way: the last building of a chain takes the rest of the send, and he is inside the breach.

| | **Brief** (`brief`, the default, and §1 as it was) | **Pinned** (`pinned`) |
| :--- | :--- | :--- |
| **Who is held, and for how long** | Only the lodged fighter: 0.5 s at tiers 1 and 2, 0.7 s at 3, 0.9 s at 4 and in a finisher | Only the lodged fighter, longer: 1.2 s at tiers 1 and 2, 1.5 s at 3, 1.8 s at 4 and in a finisher |
| **What lodges** | A power send's last building, and a plain send into a tower from tier 3 | The same. **Also any knock-back into a tower, at any tier,** in place of the wall slam: the reward for knock-back attacks Orb asked for |
| **The attacker** | Free. The lodged fighter's way back is the return rule's (Encounter's tell and approach) | Free, with **the barrage window.** While he is pinned, the attacker's energy at range (bolts, blasts, the barrage signature) can't miss him, is worth 1.5 times, and carves the building with every shot. A barrage's volleys come twice as fast |
| **His way out** | When the hold ends, out of the breach the way his stick points | When the hold ends, or sooner: a perfect block on a shot bursts him out of the breach toward the attacker, as a deflect does |
| **The building coming down on him** | Only if it was aimed at him (§6.3) | The same. A barrage that cracks the core brings it down on him |
| **Why** | Fast: the fight never waits for a lodge | Knock-backs pay: a knock-back into a tower opens the heaviest barrage in the game |

- **Control comes first.** The hold is part of the send, so it is inside "except in knock-backs". At 1.8 s the pinned hold is the longest in the game. That is the version's cost, and why it is a switch.
- **The AI** at medium uses the barrage window in 60% of pins.

### 6.5 QA's rows for this section

| Row | Bound |
| :--- | :--- |
| A power send at tier 1 into a tower | Lodges inside it, every time (hard) |
| A power send at tier 4 with three towers on its line | Goes through all three, and all three come down (hard) |
| A falling stack hurts anybody but the fighter it was aimed at | Never (hard) |
| The holds, in each mode | As the table (hard) |
| Pinned: the attacker lands energy on the pinned fighter | In at least half of pins |
| The median match length, pinned against brief | Within 15 s |
| The first tier-4 chain of a match, when there are three towers on its line | Plays in full (hard, while the budget is World's ask above) |

## 7. Orb's notes: ragdolls, recovery and the chain inside a tower (homework 23, 2026-10-16)

Orb said §6 "Sounds right", and added this note (`docs/ep/vision.md`): "entertaining ragdoll physics-based combat should be a goal, rule-of-cool always takes precedence, player agency should always be respected but when rule-of-cool demands it, the fight choreographer should determine the direction the fight takes." Recovery should come "in a reasonable amount of time", bigger blows should send fighters "flying backwards", and "skidding in midair" should regain control and show velocity. A launch into a building's side can go through the floor inside, bounce off the ceiling and crash down through the next floor. "The fight choreographer should always be aware of cool scenarios as the fight progresses and use the combat alchemy system to choose emergent combat situations."

### 7.1 Ragdolls, and who decides where a body goes

- **The ragdoll is the look, and the sim's journey is the truth.** A sent body's path is the knocked-about journey (`balance-targets.md` §20): deterministic, decided by speed, angle and surface. Animation's physics hangs the limbs, the tumble and every impact on that path, and never moves it. So it is entertaining to watch, and every replay is the same.
- **Bigger blows send him flying backwards.** A send leaves along the blow's line, away from the attacker unless it is aimed up or down. Its speed comes from its power (`launch-anywhere.md` §4). From a power of 0.8 he tumbles head over heels, ragdolled, rather than sliding upright.
- **Agency first, then the rule of cool.**
  - With the stick held, the player's direction wins, and the choreographer may bend it by up to 30° inside its kind toward a cool target.
  - With no stick, the choreographer picks, by combat alchemy's score: a building's face, the chain inside a tower (§7.3), a ridge, a crater's lip, the open sky.
  - It never turns a send back against the stick (`launch-anywhere.md` §6).

### 7.2 Getting control back in the air: the brake and the midair skid

Orb's hold to brake stands (`agency-pass.md` §4, on LT). Here it is re-ruled so recovery always comes in a reasonable time.

| | The rule | First value |
| :--- | :--- | :--- |
| **When he can start it** | Once the hit has read: sooner after a light send, later after a full launch | From 8 ticks (power 0.55 or less) to 20 ticks (power 1 or more) after the send. Never later, except for the set pieces below |
| **How long it takes** | The brake slows him at a fixed rate. He has control again when his speed falls under a third of the send's | At most 0.6 s of braking, even from the hardest send. So he is back in control within about 1 s of being launched, if he brakes at once |
| **Its cost** | Ki, as before: 20 a second held. **With no ki it still works, at half the rate.** Never denied: Orb's "no strict caps" | |
| **Air sense** | A fighter sent by a kind of launch already marked on him (`launch-anywhere.md` §5) can start braking 25% sooner for each mark | |
| **Steering** | Free: the stick bends his path by up to 15°, as before | |
| **The control** (ruled 2026-10-17) | **LT held while sent: `stanceMask` bit 8, the manoeuvre stance's hold** (`docs/controls/lunge-control.md` B4). A tap of LT at a contact stays the tech. On Simple and on touch, which have no LT, **Guard held while sent** is the brake (Controls' first mapping, `agency-input.md` 4a). No new intent bit | |
| **Its start, for any send** | By the send's power (`launch-anywhere.md` §4). A send with no launcher's power (a knock-back, a throw, a blast's push) counts its speed over a full launch's speed as its power, at most 1. The window is measured from the send. It replaces the 20-tick lock after the last hit | Straight-line between 8 and 20 ticks |
| **Who builds it** | **Simulation:** the brake in a sent fighter's flight (the rate, the ki, the half rate with none, control back under a third of the send's speed, the start window, air sense) and an `air_brake` event (start and end, the reason, the speed, the direction) for Animation's skid. **Controls:** the read, as above. **Encounter:** the AI's use, 20, 50 and 80% of its chances by level, as before. **Animation and VFX:** the skid and its trail, from the event | |
| **Never** | On a finisher's send, a crippling blow's send, a hard impact (`agency-pass.md` §7), or inside the chain of §7.3 until it lodges or leaves by a face. These are set pieces | |

**The midair skid** is how the brake looks and sounds, and it shows his speed.
- He turns to face along his flight with his arms and legs braced against it, as if digging his heels into the air.
- An air trail runs behind him. Its length shows his speed, so a long skid reads as a big hit.
- Clouds and dust he passes ripple and part.
- The sound rises with his speed and drops as he slows.
- It ends in a catch pose when control comes back.
- The camera keeps the trail in frame.
- **A stronger send skids further,** since the brake's rate is fixed. That is the velocity Orb asked to see.

### 7.3 The chain inside a tower: floor, ceiling, floor

- **When a power send enters a tower's face** at 15° to 60° up or down, the body goes on inside along the floors.
- **Each slab he meets is a contact,** by the knocked-about rules (a bounce between 40° and 70° keeps its share of speed). A slab breaks when the send's effective tier is high enough for it. **A slab that holds is a bounce when he meets it at 900 or more and between 40° and 70°; slower or shallower, he lodges on it** (2026-10-18, `rulings-2026-10-18.md`).
- **A broken slab collapses locally:** the floor gives way over two or three bays and its debris falls to the floor below, never a whole floor vanishing. Each one counts as half a link of the chain (§1).

| Effective tier of the send | Inside the tower |
| ---: | :--- |
| 1 | He breaks no slab. He lodges on the first floor and recovers inside (§6.1) |
| 2 | Down (or up) through one floor, and he lodges on the next |
| 3 | **Orb's picture:** through the floor, up off the ceiling (breaking it), and down through the next floor, then he lodges |
| 4, or a finisher | Up to five slabs. Then the tower's core cracks, and it comes down as a falling stack, aimed at him (§6.3) |

- **The journey's bounds hold:** at most 8 contacts and 4 s from the first contact. Past either, he lodges where he is.
- **The chain's values** (ruled 2026-10-17, for Animation's `docs/animation/ragdoll-physics-paper.md` §4 and §5):
  - **a ceiling contact** reverses him and keeps 0.4 of his speed, and the ceiling collapses locally (Orb's "bounce up and off the ceiling (also collapsing it)");
  - **a floor he goes through** keeps 0.7;
  - **a floor that holds** is a bounce, by the ground's bounce rules turned to the slab;
  - **at most 5 contacts** in a chain, the slabs inside only (the face counts toward the journey's 8), and **at most 3 of them bounces;**
  - **the next tower's link** plays only if he leaves by the far face with 900 or more of speed left. If he lodges, the first tower is the chain's last link, and the planner predicts the inside chain before it plans any later link;
  - **the face's stop:** 15 ticks, as §1 has it;
  - **a cap of 2.5 s** of ragdolled time from the face to the lodge, or to leaving by a face, inside the journey's 4 s;
  - **the brake is off inside the chain.** It returns once he lodges (and he recovers inside after the lodge's hold) or once he leaves by a face;
  - **the ceiling is reached from effective tier 3.** At tier 2 he goes through one floor and lodges, and at tier 1 he lodges on the first.
- **Rule of cool:** with no stick, or within the 30° bend, the choreographer takes an inside chain when a tower stands in the send's kind and the angle fits. It is a high score in combat alchemy.
- **The camera** cuts to the tower's cutaway, or holds it from the street. That is Camera's, with Rendering's open floors.

### 7.4 QA's rows for this section

| Row | Bound |
| :--- | :--- |
| The brake can start within 20 ticks of a send, set pieces apart | Every time (hard) |
| Braking at once, he has control within 1 s of the launch | Every time (hard) |
| With no ki, the brake still works | Every time (hard) |
| The inside chain's slabs, by effective tier | As the table (hard) |
| A sent body's path the same on every replay, ragdoll or not | Every time (hard) |
| Inside chains a match, in matches with three or more fights in town at tier 3 and up | 0.3 to 1.5 |
