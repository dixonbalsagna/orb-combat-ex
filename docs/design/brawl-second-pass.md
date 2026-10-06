# The brawl, second pass: control first, a flurry on every button, charges, and a recast of A and B

Owner: Game Design. Date: 2026-10-06. Orb played the live brawl on the evening of 2026-10-05 and answered questionnaire 19 (`docs/ep/vision.md`, last section): "It feels closer to where I want it to be", with changes. This page turns those changes into rules.

**It revises `melee-press-feel.md`.** Where the two disagree, this page is the newer rule. §9 lists what stands and what changes, section by section. **Every number is a starting value,** none has been run in the sim, and Legal screens the new moves after this.

## 0. What changes, at a glance

| Orb said | The rule now | Where |
| :--- | :--- | :--- |
| "players should always feel like they are able to control their character"; the attraction "was too strong" | The stick moves the brawl. Each fighter nudges the centre the two are drawn to, and a fighter can walk out when nothing is landing on him | §1 |
| "The flurry should be across all attacks, not just light"; alternating X and Y is "a rapid attack mixup" | A tap of X, Y or B is a blow at once, and mashing any of them, or any mix of them, is a flurry | §2 |
| "holding a button should charge up an attack" | A held X is a charged light: quick, modest, no knock-back. A held Y is a charged heavy: slow, armoured, and it knocks back or launches | §3 |
| "Y just feels really underpowered... an opponent flurrying on me should get punished" | A charging Y can't be stopped by a flurry. It lands for up to 10 brawl lights | §3 |
| A: a tap is a shove, a mash is a clinch into a trip and a throw, a hold is a tackle | Ruled as Orb sketched it | §4 |
| "B needs a recast and its own unique moveset" | B is his ki at close range: a burst on a tap, a ki flurry on a mash. A signature needs a held B, and it plays live | §5 |
| Two-button power attacks on adjacent buttons | X+Y the lift, X+A the slip, Y+B the breaker, A+B the seize | §6 |
| An even mash: "both thrown back, nobody wins" | At the trade's limit a level trade throws both back. The seeded draw and its momentum are gone | §7 |

## 1. Control comes first: the stick moves the brawl

**Orb:** "movement during combos should not feel 'locked'... each player should be able to nudge the center of attraction between the fighters during an exchange. players should always feel like they are able to control their character, with few exceptions like during knockbacks."

Today a brawl stops both fighters dead and pulls them to one spot. The stick only leans a blow. That is the lock Orb felt.

**The rule.** A brawl has a **centre:** the point between the two fighters that they are drawn to. Each fighter's stick nudges it.

| The sticks | What the brawl does |
| :--- | :--- |
| One fighter holds a direction, the other holds none | The centre moves that way at 0.4 of his free-flight speed, and both fighters go with it |
| Both hold the same direction | It moves at 0.8 of free-flight speed. Two players who agree can fly a brawl across the sky |
| They hold opposite directions | The two cancel, by how far each stick is pushed. It is a tug of war |
| Both hold away from each other | The brawl lets go after 12 ticks |

- **It answers at once.** The centre starts to move within 2 ticks of a stick, and reaches its speed in 8.
- **The brawl keeps the speed it began with.** Half of the fighters' closing speed carries on as drift for 20 ticks. Nobody is stopped dead.
- **The attraction is softer.** It holds each fighter at striking distance from the centre and no longer pins him to a point.
- **The stick still leans the blow** (`melee-press-feel.md` §13). So holding toward the rival drives him back with elbows and knees, holding away gives ground with kicks, and up and down climb or sink with rising and dropping blows. One stick does both jobs.
- **Every press is still a blow.** Nothing here delays or drops a press.

**Walking out.** A fighter who holds his stick away from the rival, throws nothing, and has no blow land on him for 24 ticks is let go, at no cost in ki. A blow that lands on him starts the 24 again. So he can always leave a brawl nobody is winning, and he can't walk out of a beating: for that he has the dodge, the burst and the zip away.

**When the stick does nothing.** Only in these: a knock-back, a launch, a lift, being held in a clinch, being buried, and a set piece.

| His state | His nudge |
| :--- | :--- |
| Striking, charging, or reeling from a light | Full |
| Guarding | 0.6 of full, as a guard already slows him |
| Staggered | Half |
| Knocked back, launched, lifted, held, buried | None |

**What it gives the game.** Position is the player's job under pillar 2, and now he has it inside a brawl. The Protagonist's AI nudges a brawl away from a town, and the rival's nudges it toward one. A charged Y can be walked into place before it is let go.

**Data:** `brawl.nudgeMul` 0.4, `brawl.nudgeRampTicks` 8, `brawl.carryShare` 0.5 for 20 ticks, `brawl.walkOutTicks` 24, `brawl.partTicks` 12, `brawl.nudge.guard` 0.6, `brawl.nudge.stagger` 0.5.

## 2. A flurry on every button

**Orb:** "The flurry should be across all attacks, not just light. light mashing, heavy mashing should both have the rapid attack pattern... mashing X and Y alternating should give you a rapid attack mixup made up of heavy and light attacks."

**The rule: a tap of X, Y or B is one blow, thrown at once. Tapped again quickly, in any order, the taps are a flurry.**

| | X: a light | Y: a quick heavy | B: a ki burst (§5) |
| :--- | ---: | ---: | ---: |
| Press to contact | 2 ticks | 6 ticks | 4 ticks |
| Fastest in a flurry | One every 6 ticks | One every 12 ticks | One every 8 ticks |
| Worth, in brawl lights for each tick since his last blow | 0.10 | 0.167 | 0.15 |
| So a blow at its fastest is worth | 0.6 | 2.0 | 1.2 |
| Ki for each blow | None | 3 | 4 |
| The rival reels for | 4 ticks | 6 ticks | 6 ticks |
| Reach | Striking distance | Striking distance | 5 bh, in a short cone |
| On a guard | Chips | Chips double, and tires the guard twice as fast | Chips, and pushes the blocker 0.5 bh |

- **Damage a second is level within a button,** as it is for lights today: a faster tap is a weaker blow. Between buttons it isn't level. Y hits two thirds harder a second than X, and it is paid for in ki.
- **Mashing Y is a rapid pattern too:** up to five quick heavies a second. A full bar of ki pays for 33 of them, which is about 7 s of nothing but Y. An empty bar is 2 s of exhaustion, and no ki for a dodge, a zip or a burst.
- **Alternating is the mix-up.** Each tap throws its own button's blow, up to ten a second. It lands more blows than Y alone, so it builds a run faster. It hits harder than X alone. It spends ki at whatever rate the Y and B taps come.
- **The run and the close don't change.** Every landed flurry blow of any button adds 1 to his run, and a reply takes 1 off. At a run of 4 his next blow staggers the rival in place.
- **The tapped Y is no longer the slow heavy.** The 26-tick wind-up belongs to the held Y now (§3). So a tap never asks the player to wait.
- **A string no longer ends by itself.** "A heavy after two landed blows is the ender" is withdrawn: with Y in the flurry it would end every mix-up. A string ends when the player ends it: with a charged Y, a throw or a power attack (§3, §4, §6), or with the flurry's close.
- **The looks** are the ones already set for speed, on all three buttons. An ordinary exchange of lights is 4 of 10 on flash (Orb, questionnaire 19): hit sparks and at most two ghosts, with no shake and no speed lines.

**Data:** `flurry.x` (gap 6 to 12, rate 0.10), `flurry.y` (gap 12 to 18, rate 0.167, contact 6, ki 3, reel 6, guard chip ×2), `flurry.b` (gap 8 to 14, rate 0.15, contact 4, ki 4, reel 6, reach 5 bh).

## 3. Holding a button charges it

**Orb:** "holding a button should charge up an attack. so a charged heavy should have benefits that a charged light attack doesn't, while charging a light attack is less powerful and doesn't knockback but faster to charge." And: "Y just feels really underpowered right now. an opponent flurrying on me should get punished if they don't block correctly when I charge a full Y attack."

| | **Held X: the charged light** | **Held Y: the charged heavy** |
| :--- | :--- | :--- |
| How it starts | The light is thrown on the press, as always. Still held 8 ticks later, he is charging | Still held 4 ticks after the press, he is charging. No quick heavy is thrown |
| Charged at | 8 ticks | 12 ticks |
| Full at | 14 ticks | 40 ticks |
| Lands | 4 ticks after he lets go | 8 ticks after he lets go |
| Worth, in brawl lights | 1.5, rising to 2 at full | 6, rising to 10 at full |
| Ki | None | 4 |
| While he charges | **No armour.** Any blow that lands on him ends the charge | **Armoured against every flurry blow and light.** He takes their damage, he doesn't reel, and they add nothing to the rival's run |
| A clean hit | The rival reels for 10 ticks. **No knock-back** | **A knock-back.** At a full charge, a launch that the stick nudges and the director stages, or a lift of 45 ticks with no stick |
| On a guard | Chips | A guard raised in the last 30 ticks blocks it, with a quarter of the damage through. **A set guard breaks:** he staggers for 20 ticks and half the damage goes through |
| A perfect block | Turns it | Turns it: he staggers for 20 ticks, and the riposte follows |

**What stops a charging Y.** Blows don't. These do:

| The answer | What happens |
| :--- | :--- |
| **A shove** (a tap of A, §4) | The charge is lost and he staggers for 8 ticks |
| A clinch or a tackle | He is grabbed out of it |
| A fresh guard, or a perfect block | As in the table above. This is "blocking correctly" |
| Getting out of its reach: a dodge, a slip, a zip away | It whiffs, and he is open for 20 ticks |
| A charged Y of his own, a power attack or a signature | Two heavy commitments meet (`melee-press-feel.md` §11) |

**So against a flurry:** a fighter who keeps flurrying into a full charge takes it. Over the 48 ticks it needs, an X flurry does about 5 brawl lights to him and a Y flurry about 8, and then 10 come back with a launch. The flurrier has to stop and answer.

**This replaces "three clean blows stop a heavy's wind-up"** (`melee-press-feel.md` §7), which was never built and says the opposite of what Orb asks.

**The just release** (Orb picked it): letting go within 4 ticks after the full-charge flash. His line is free at once, 10 ticks sooner than usual, and it adds 1 to the flow. It is kept subtle, as Orb asked for a timed string's payoff: no extra damage. A charge can't be held past 70 ticks: it goes by itself.

**He can nudge the brawl while he charges** (§1).

**A failed charge hurts 3 of 10** (Orb, questionnaire 19). A whiffed charged heavy leaves him open for 20 ticks, where it was 30. The rule for every flashy option: failing never leaves him open for more than 20 ticks, and never adds damage of its own.

**Data:** `charge.x` (start 8, full 14, land 4, worth 1.5 to 2, reel 10), `charge.y` (start 4, charged 12, full 40, land 8, worth 6 to 10, ki 4, max hold 70, whiff 20), `charge.justTicks` 4, `guard.freshTicks` 30.

## 4. A: the shove, the clinch and the tackle

Orb's sketch, ruled as given. A is how a fighter takes hold of the other's body. In reach it has three readings. Out of reach a tap is still context: a pick-up, a civilian, or the taunt.

| | **A tapped: the shove** | **A mashed: the clinch** | **A held: the tackle** |
| :--- | :--- | :--- | :--- |
| What it is | Both hands, no damage. The rival goes back 3 bh and the brawl lets go | He takes hold, turns the rival over in the air, and throws him | He coils, and then shoots at the rival and carries him into whatever is on the line |
| Timing | 8 ticks of wind-up | A second tap inside the shove's wind-up turns it into the reach for a clinch: 10 ticks. In the clinch, two more taps are **the trip** and two more are **the throw.** It lasts 45 ticks at most | Held 16 ticks to charge, and full at 36. He travels at a zip's speed, under Legal's floor |
| Range | In reach | In reach | 6 bh at the shortest charge, 12.5 bh at full |
| Worth | Nothing | The trip is worth 2 brawl lights, and the rival can't guard for 20 ticks after it. The throw is a knock-back of 8 bh | The rival takes the impact as a landing at that speed. **The tackler takes nothing** |
| Where it ends | | The stick nudges the throw and the director stages it. Thrown through the shell of a damaged building, he finishes it (Orb, questionnaire 19) | He carries the rival 6 to 16 bh along the line to the first surface: the ground, a ridge, a building. **Both end in the crater.** At a full charge the rival is buried, which gives a free follow-up. With nothing on the line, he throws him off |
| Ki | None | None | 10 |
| Beats | A charge, which it ends with an 8-tick stagger | A guard | A guard |
| Loses to | Any blow that lands on him in its wind-up | Any blow that lands first. **The rival's own tap of A within 8 ticks of the hold breaks it:** both are pushed 1.5 bh apart. A burst | A shove or any blow during the charge. A dodge, after which he flies 6 bh past and is open for 20 ticks. A charged Y that lands as he arrives |
| Limit | One shove in 45 ticks | The grab lockout: 90 ticks, shared with every grab | The grab lockout |

- **The clinch is how a flying fighter takes control,** as Orb put it: no ground is needed. The trip turns the rival over, and the throw sends him.
- **No grab spam** stands (`melee-press-feel.md` §10). The clinch, the tackle, the zip tackle, the dive grab and the seize (§6) share the one lockout, and a thrown fighter can't be grabbed for 120 ticks.
- **The taunt is a gamble** (Orb picked it). Out of reach, a tap of A taunts for 45 ticks. Finished, it gives his meter its taunt gain and 10 ki. Hit before it finishes, he gets nothing and staggers for 12 ticks. That is a 3 of 10: a real loss, and a small one.
- The feedback that "the context button didn't seem to do anything" is this: in the live brawl A has no reading in reach.

**Data:** `shove` (wind-up 8, push 3 bh, stagger on a charge 8, lockout 45), `clinch` (reach 10, trip at 2 taps, throw at 4, max 45, trip worth 2, no-guard 20, throw 8 bh, tech 8), `tackle` (charge 16 to 36, range 6 to 12.5 bh, carry 6 to 16 bh, ki 10, whiff 20), `taunt.ki` 10.

## 5. B: recast as his ki at close range

**Orb:** "just hitting B and getting locked into what feels like a beam-attack cutscene doesn't feel right, B needs a recast and its own unique moveset."

Until now a tap of B was a 25-ki signature, and in the martial arts stance it fired the beam with its full staging. One press took the fight away from the player.

**The recast: B is his ki, used at arm's length.** X is the quick body blow and Y the strong one. B is the blow that reaches further, pushes, and costs ki. It has a moveset like theirs.

| B | What it is | Ki |
| :--- | :--- | ---: |
| **Tapped** | **A ki burst:** a short flash from the hand, 4 ticks to land, with a reach of 5 bh. It is worth 1.2 to 2 brawl lights by how fast it is tapped, the rival reels for 6 ticks, and it pushes him and the brawl's centre 0.5 bh | 4 |
| **Mashed, or mixed with X and Y** | Part of the flurry (§2). X, Y and B together are a three-way mix-up | 4 a blow |
| **On the beat** (from the skill strike's slice) | A ki skill strike, worth 5 | 6 |
| **Held to 12 ticks** | **A ki blast** at point-blank: worth 5 brawl lights, with a knock-back of 4 bh | 12 |
| **Held to the first flash, 24 ticks** | **His art:** the quick form of the stance's signature (`melee-press-feel.md` §11) | 25 |
| **Held to the second flash, 48 ticks** | **His signature** | 45 |

- **No signature starts on a tap, in any stance.** It always takes a hold, which is its tell. This replaces "tapped is the art" in `melee-press-feel.md` §11. The tiers and their prices stand.
- **Signatures play live.** An art has no pause and no camera of its own. A signature takes a pause of at most 1 s, and only when it lands clean. A struggle is staged as before. Finishers keep their staging, which the other player called "really cool".
- **The player keeps hold of it.**
  - A beam lasts while B is held, up to its tier's length, and it ends when he lets go. Ki is spent by the second as it fires, and not all at the press.
  - The stick nudges its aim, as it nudges a launch.
  - A melee art is a string that the player drives: the art runs for as long as he keeps pressing, each press is its next blow, and he can stop.
- **While he charges B:** a blow that lands before the first flash ends the charge. From the first flash he is committed, and armoured against lights and flurry blows.
- **In the energy arts stance** nothing changes for X and Y. Its B follows the same ladder: a tap is a quick ki shot, and a hold is the beam.
- **Until a fighter's martial art is authored,** a held B in the martial arts stance fires the beam by these rules: charged, live, and held by the player. That is the stopgap that was there before, without the cut scene.
- The ultimate keeps its rule: the charging stance, a hold of 45 ticks more, acts 3 and 4.

**Data:** `flurry.b` as in §2; `charge.b` (blast 12 ticks and 12 ki, art 24 ticks, signature 48 ticks); `sig.livePauseMax` 60 ticks, on a clean hit only.

## 6. Four power attacks, on buttons that sit together

**Orb:** "a staple of modern fighting games are the two-button combined power attacks: A+B (grab-related) / X+A / Y+B / X+Y. I don't want to add combinations that cross the pad."

Each pair does what its two buttons mean together. X is quick, Y is strong, A is the body, and B is ki. Each costs ki, each has a tell, and none is a flurry blow.

| Pair | Name | What it does | Ki | Tell | Loses to |
| :--- | :--- | :--- | ---: | ---: | :--- |
| **X+Y** quick and strong | **The lift** | An upward blow that lifts the rival in place for 36 ticks, which starts a juggle (`melee-press-feel.md` §5). Worth 3 brawl lights. It replaces "a lone tapped heavy lifts" | 10 | 10 ticks, armoured against lights | A guard, which blocks it with no lift. A shove |
| **X+A** quick and body | **The slip** | He goes round the rival, over, under or behind by the stick, up to 2 bh, and lands a light on the way. Timed inside the rival's tell, the rival's blow misses. This is the step strike, moved here from LT+X | 5 | 4 ticks | A blow that catches him before he moves |
| **Y+B** strong and ki | **The breaker** | A blow wrapped in ki that no guard stops, fresh or set. It ends a charge. Worth 6 brawl lights, with a knock-back of 6 bh | 20 | 14 ticks | A perfect block. A dodge or a slip |
| **A+B** body and ki | **The seize** | The power grab, as Orb asked. It beats a guard, and the rival's tap of A doesn't break it: only a burst does. It ends in an aimed throw of 12 bh, and through a shell it finishes the building | 20 | 12 ticks | Any blow that lands first. A dodge. The grab lockout applies |

- **No pair crosses the pad.** X+B and Y+A stay empty, and I have no pitch for them.
- **How the two presses are read together** is Controls' side. What the design needs: two buttons pressed within about 3 ticks of each other are the pair, and a light already thrown by the first press gives way to it.
- **They are heavy commitments.** Two that meet, or one that meets a charged Y or a signature, start a struggle.
- **The other stances** keep the same four meanings with their own moves: a lift, a slip, a breaker and a power grab. They are designed with each stance.

**Data:** `power.lift` (ki 10, tell 10, lift 36, worth 3), `power.slip` (ki 5, tell 4, step 2 bh), `power.breaker` (ki 20, tell 14, worth 6, knock-back 6 bh), `power.seize` (ki 20, tell 12, throw 12 bh).

## 7. The even mash, and the rest of questionnaire 19

**An even mash ends with both thrown back, and nobody wins** (Orb). At the trade's limit of 120 ticks:
- **a lead of 2 or more in the runs still takes the close.** The faster masher wins the trade, as now;
- **runs within 1 of each other are a level trade, and both fighters are thrown back 4 bh from the centre.** No damage, no stagger, and nobody has won a decisive exchange. The brawl ends, and each is free as his slide ends;
- **the seeded draw and its momentum are withdrawn** (`flurry.momentum`, `melee-press-feel.md` §9d).

**What it does to the mirror.** Two even lights-only mashers now never win an exchange from each other, so that mirror doesn't finish. That is the rule working: an even mash is a stalemate, and winning takes something better than mashing evenly. QA's rows change with it (§11).

| Orb's answer | The rule |
| :--- | :--- |
| The player nudges a launch, and the director stages it | As now: the stick leans it and the planner picks where it ends. The same holds for a throw, a tackle's line and a beam's aim |
| Zip chains: until ki runs out | No limit on a chain but ki. Each zip is paid for in full (`melee-press-feel.md` §2c) |
| Chasing your own launch | **A zip at a launched rival.** While his launch is in flight, LT with X or Y follows the body as drawn travel and lands a blow that sends him on, nudged by the stick. It costs a zip's price, 20 or 30 ki, so a chase lasts as long as the ki does |
| A just release on the heavy | §3 |
| The taunt as a gamble | §4 |
| A perfect timed string's payoff: subtle | The showcase at a flow of 5 is a look only: no pause and no camera of its own. Perfect and good grades already pay the same |
| An ordinary exchange of lights: 4 of 10 on flash | §2 |
| A failed flashy option hurts 3 of 10 | §3: open for 20 ticks at most, and no added damage |
| A visible spark-lock | When two heavy commitments meet, the struggle shows as a lock of sparks between them. VFX's, on the struggles that exist |
| The fire-on-the-move hybrid | LT + RB. It is reserved in the stance matrix, and it is put in the build order (§10) |
| Buildings | Throwing the rival through a shell finishes it. Otherwise a damaged building is scenery, and nothing new is asked of World |
| Not wanted | Stance-switch flourishes, a right-stick launch call, and playable intros. None is in this page |

## 8. The martial arts stance, one line for each input

| The input | What it is | Ki |
| :--- | :--- | ---: |
| **X tapped** | A light, 2 ticks to land | 0 |
| **X mashed** | The light flurry: 5 to 10 blows a second | 0 |
| **Y tapped** | A quick heavy, 6 ticks to land | 3 |
| **Y mashed** | The heavy flurry: 3 to 5 blows a second | 3 a blow |
| **X and Y alternated** | The mix-up: each tap its own blow, up to 10 a second | 3 for each Y |
| **X held** | A charged light: full at 14 ticks, worth 2, a 10-tick reel, no knock-back, no armour | 0 |
| **Y held** | A charged heavy: full at 40 ticks, worth 6 to 10, armoured against flurries, a knock-back, and a launch or a lift at full | 4 |
| **X or Y on the beat** | A skill strike, worth 4; with Y a heavy skill strike, worth 6 | 0 or 3 |
| **A tapped** | The shove. Out of reach: a pick-up, a civilian, or the taunt | 0 |
| **A mashed** | The clinch, the trip, and the throw | 0 |
| **A held** | The tackle, into a crater | 10 |
| **B tapped** | A ki burst, with a reach of 5 bh | 4 |
| **B mashed** | The ki flurry, and the third part of a mix-up | 4 a blow |
| **B held** | A ki blast at 12 ticks, his art at 24, his signature at 48, all live | 12, 25 or 45 |
| **X+Y** | The lift | 10 |
| **X+A** | The slip | 5 |
| **Y+B** | The breaker | 20 |
| **A+B** | The seize | 20 |
| **The stick** | Nudges the brawl's centre, and leans the blow | |

**What carries to the other four stances.** The grammar does, and the moves are each stance's own:
- X, Y and B each have a tap, a mash, a mix, a hold and a beat;
- A has a tap, a mash and a hold: a quick body move, a hold that escalates, and a charged rush;
- the four pairs keep their four meanings;
- the stick always moves him;
- LT with a button is still the zip, and it keeps its own section.

The energy arts stance already fits: its X sprays when mashed, its Y is a heavy shot that charges when held, and its B is the beam. The defensive and manoeuvre rows in `melee-press-feel.md` §10 stand until their slices, and are re-read against this grammar then.

## 9. What stands and what changes

| Built or cut | Stands | Changes |
| :--- | :--- | :--- |
| **B1 and its repairs** (live) | A press is a blow inside 10 ticks. The run, the close, the close guard, blows on a staggered fighter adding nothing. The brawl's worths and `brawl.damageMul`. The perfect block and the reversal in place, and the riposte | The magnetism (§1). The tapped Y: it becomes the quick heavy, and the 26-tick heavy becomes the charged Y (§2, §3). The ender rule goes. The level trade's draw goes (§7). `enderShare` becomes how often the AI ends a string with a charged Y |
| **The zip's first slice** (built in scratch, lands next) | All of it | Nothing. The chase (§7) and the zip away come in its second slice |
| **The skill strike as cut for B2** | All of it for X: the beat point, the 4 ticks either side, the grade at the press, its worth of 4, the cleared run, the flow, the early and late rules, the pinned pose and the 10-tick return as the cue | It widens. The beat follows any landed light, quick heavy or skill strike. **Y on the beat is a heavy skill strike:** worth 6, a reel of 10, 3 ki. "An ender at a flow of 3 launches" becomes "a charged Y at a flow of 3 launches, at any charge". The showcase is subtle |
| **Timing on a heavy or a charged blow** | | It exists in two places: Y on the beat, and the just release on a full charge. A partial charge has no timing |
| **The lift and the juggle** (not built) | The juggle: up to five skill strikes, each worth less | The lift moves to X+Y, and to a full charged Y with no stick |
| **Three blows stopping a wind-up** (not built) | | Withdrawn (§3) |
| **The set guard** (not built) | A guard held 30 ticks is set, and a charged Y breaks it | A quick heavy doesn't break a guard. It chips double and tires it |
| **The signature tiers** | The prices, the shared cooldown, the struggles, the ultimate's acts | A tap of B is no longer the art. Tiers are reached by holding (§5) |
| **The step strike on LT+X in reach** | The move | It is the slip, on X+A. LT+X in reach is the zip away when the stick is away, and the slip otherwise |
| **A's press and hold** (`melee-press-feel.md` §10) | The grab lockout, and the other stances' A cells | The martial arts row is §4 here |

## 10. Build order

Control is first, as Orb asked, and I don't argue otherwise: it is the complaint about feel, and every later slice is judged by playing inside it. The zip's first slice lands when it is ready, beside these.

| Slice | What | Size | Encounter | Controls | Simulation | Animation and VFX | Camera and UI |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **C1** | **Control:** the nudged centre, the softer attraction, the carried speed, walking out (§1). With it, **the even mash** (§7) | Medium | The brawl's movement. The AI's nudge: the hero away from towns, the rival toward them. The double throw-back, and the draw taken out | Nothing new: the stick is already in the intent | The fighters' movement inside a brawl, if it sits in the core | Footwork while striking, and the lean of a drifting pair | Camera: frame a pair that moves |
| **C2** | **Y:** the quick heavy, the heavy flurry and the mix-up (§2). **The charges:** held X, held Y with its armour, the guard rules and the just release (§3) | Large | The flurry by button, armour, the fresh guard, the knock-back from a charge. The AI: when it charges, and the shove as its answer once C4 is in | The tap against the hold on Y at 4 ticks. `lightHeld` and `heavyHeld` exist | Wear from armoured hits | The heavy flurry's pieces and looks. Charge poses, and the charge flash | UI: the charge cue, and haptics on landed blows, closes, launches and landings (Orb, questionnaire 19) |
| **C3** | **The skill strike,** as cut, widened to Y on the beat (§9) | Medium, and already cut | As cut | As cut (`docs/controls/skill-strike-input.md`) | The mood's 50 | The return as the cue | UI: the beat ring option |
| **C4** | **A:** the shove, the clinch with the trip and the throw, the tackle and its crater (§4). The taunt's gamble | Large | Three new states, and the break-out. The AI's use of the shove against a charge | The tap, the mash and the hold on A | The crater and the burial exist. The carry | Paired poses for the clinch and the throw, which the generator doesn't make yet | Camera: the tackle's line |
| **C5** | **B:** the ki burst and its flurry, the ki blast, and signatures on a hold, played live (§5) | Large | B in the flurry. The held ladder. Live staging, and the beam held by the player | The tap, the mash and the hold on B | Ki spent by the second | Ki blows. The live signature without its cut scene | Camera: no takeover on an art. UI: the two flashes |
| **C6** | **The four power attacks** (§6), and with them the lift and the juggle | Large | Four moves, and the juggle | **The two-button reads** | Nothing new | Four moves for each fighter | |
| **Z2** | The zip away, the chase of a launch, the signature zip | Medium | As planned, with the chase | Nothing new | | | Camera: the chase |
| **H1** | The fire-on-the-move hybrid, LT + RB | Medium | The hybrid's cells | The hybrid's mask is reserved | | | |

- **C1 and C2 are what Orb's notes are mostly about,** and they are the two to play before anything after them is built.
- **Animation carries the most new work:** paired poses in C4, and four moves a fighter in C6. Both wait on its say.
- **Legal screens after this page:** the clinch, the trip and the throw, the tackle and its crater, the ki burst, and the four power attacks.

## 11. The bands that move

| Row | Now | With this page |
| :--- | :--- | :--- |
| The even lights-only mirror finishes | At least 95% | **Retired.** It is a stalemate by rule (§7). It is reported, with how it ends |
| An uneven mirror: 8 ticks against 10 | Not a row | **New:** it finishes at least 95% of the time, and the faster tapper wins at least 80%. Brink to KO at 25 to 50 s is read here |
| Level trades that change who has the momentum; wins from the first slot | 5 to 15%; 40 to 60% | **Retired** with the draw |
| Level trades that end in a double throw-back | Not a row | **New:** all of them (a hard test) |
| The masher against the medium AI | 35 to 50%, tapping X every 8 ticks | Kept for the X masher. **New, reported:** the Y masher and the alternator, each against medium. I expect the Y masher lower, since he runs out of ki, and the alternator a little higher |
| A full charged Y thrown into a flurry lands | Not a row | **New:** at least 80% when the flurrier keeps flurrying; and a shove ends a charge at least 90% of the times it is tried in reach |
| The centre moves within 2 ticks of a stick, in every state where the stick works | Not a row | **New** (a hard test) |
| How far a held stick moves a brawl against a rival who holds none | Not a row | **New, reported,** as bh for each second |
| A brawl's median length | 2.5 to 6 s | **Re-read after C2.** Strings no longer end by themselves, so I expect it longer: 3 to 8 s as a first band |
| Of the endings that separate: knock-backs and launches | 60 to 75% and 25 to 40%, from B2 | **Re-read after C2:** double throw-backs are a third kind, and knock-backs now come from charges and throws |
| The time a failed option leaves him open | Not a row | **New:** at most 20 ticks (a hard test) |
| Ki spent a minute, by what it bought | Reported for zips only | **New, reported:** flurry blows, charges, power attacks, zips, signatures |

## 12. Five questions for Orb

Each is one choice. The first answer is what this page assumes.

1. **Walking out of a brawl:** free when no blow is landing on you, or always at the price of a dodge or a zip?
2. **What ends a string,** now that a tapped Y is a flurry blow: a held Y, with X+Y as the lift; or X+Y as the ender, with the lift on a full charge only?
3. **B:** ki blows on a tap and signatures only on a held B, played live; or B as a second family of body blows, with signatures moved to a pair?
4. **A charging Y against a flurry:** armoured from the first tick; or armoured only once it is half charged, so a quick enough flurry can still stop it early?
5. **The double throw-back of an even mash:** no damage to either; or both take a hit?

The EP has one more to confirm with Orb, and it isn't mine: that the "Y+X" in Orb's list of cross-pad pairs meant Y+A.
