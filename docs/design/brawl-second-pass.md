# The brawl, second pass: control first, three strengths on three buttons, and a recast of A

Owner: Game Design. Dates: 2026-10-06, revised the same day for three strengths, and again for Orb's four tests (§13). Orb played the live brawl on the evening of 2026-10-05, answered questionnaire 19, then this page's five questions, and then settled the buttons (`docs/ep/vision.md`, the last three sections). This page turns all of that into rules.

**It revises `melee-press-feel.md`.** Where the two disagree, this page is the newer rule. §9 lists what stands and what changes. **Every number is a starting value,** and none has been run in the sim. Controls' input design, Legal's first screen and Animation's first sizes are folded in. The three-strengths revision needs a fresh look from each (§10).

**The two rules everything here hangs on:**
- **Control comes first.** The stick always moves him, except in a knock-back and the few states like it (§1).
- **One press is one attack.** Orb: "I don't like the idea of one button press equalling two attacks." No move in this page throws a quick blow and then a charged one from the same press.

## 0. What changes, at a glance

| Orb said | The rule now | Where |
| :--- | :--- | :--- |
| "players should always feel like they are able to control their character"; the attraction "was too strong" | The stick moves the brawl. Each fighter nudges the centre the two are drawn to, and when both hold away from each other they walk out | §1 |
| "Proposal X=light, Y=med, B=heavy. turn whatever heavy strikes into medium, and invent new super-heavy looking attacks" | Three strengths. X is at once, Y winds up for 12 ticks and B for 28. Today's heavies are the mediums, and B gets a new tier | §2 |
| "The flurry should be across all attacks"; "I'm excited to see Y and B flurries" | Mashing any of the three is a flurry at that button's pace, and each beats one of the others | §2 |
| "X Light Hold should give a high speed burst of low damage attacks that quickly slows down on a curve" | A held X is the burst: eight blows in under a second, slowing as it goes. Lights never charge | §3 |
| "holding a button should charge up an attack"; a charged heavy "should have benefits that a charged light attack doesn't" | Y and B keep winding while held. The charged medium is quick and doesn't knock back. The charged heavy is armoured, and it knocks back or launches | §3 |
| "an opponent flurrying on me should get punished if they don't block correctly" when a full heavy is charged | A heavy's wind-up is armoured against lights from its first tick | §3 |
| A: a tap is a shove, a mash is a clinch into a throw, a hold is a tackle | Ruled as Orb sketched it, one move to a press. The vicious blows live in the clinch, which Orb confirmed | §4 |
| "just hitting B and getting locked into what feels like a beam-attack cutscene doesn't feel right" | B is the heavy. Signatures move to RT + B, take a hold, and play live | §5 |
| Two-button power attacks on adjacent buttons | X+Y the lift, X+A the slip, Y+B the breaker, A+B the seize | §6 |
| An even mash: "both thrown back, nobody wins", and both take a hit | A trade still level after 4 s ends in a double hit, with a close-up | §7 |
| "Things I'll be looking for next time I test-run": moving in combat, moving while the rival charges, a reliable launch, and energy in close combos | Giving ground, the launcher, energy arts in reach, and a map of the four | §1, §3, §5b, §13 |

## 1. Control comes first: the stick moves the brawl

**Orb:** "movement during combos should not feel 'locked'... each player should be able to nudge the center of attraction between the fighters during an exchange. players should always feel like they are able to control their character, with few exceptions like during knockbacks."

Today a brawl stops both fighters dead and pulls them to one spot. The stick only leans a blow. That is the lock Orb felt.

**The rule.** A brawl has a **centre:** the point between the two fighters that they are drawn to. Each fighter's stick nudges it.

| The sticks | What the brawl does |
| :--- | :--- |
| One fighter holds a direction, the other holds none | The centre moves that way at 0.4 of his free-flight speed, and both fighters go with it |
| Both hold the same direction | It moves at 0.8 of free-flight speed. Two players who agree can fly a brawl across the sky |
| They hold opposite directions | The two cancel, by how far each stick is pushed. It is a tug of war |
| Both hold away from each other | **They walk out.** The brawl lets go after 12 ticks, at no cost to either (Orb) |

- **It answers at once, and it is a rate.** The centre starts to move within 2 ticks of a stick. A stick moves it by how far it is pushed, and reaches its speed in 8 ticks. A keyboard or a D-pad is all or nothing, so for them the nudge ramps from 0.4 of its rate to all of it over 12 ticks of holding: a tap is a small nudge (Controls, `docs/controls/q19-input.md`).
- **It moves smoothly.** The nudge never moves the centre more than 0.3 bh in one tick, whatever the two sticks add up to. The cap is on the drift, so its hard test reads the centre's speed and not its position. A strike that places its attacker is a separate step, with its own row (§11). Animation needs that for the drift to read (`docs/animation/brawl-second-pass-view.md`), and it is fed the pair's velocity while it drifts.
- **The brawl keeps the speed it began with.** Half of the fighters' closing speed carries on as drift for 20 ticks. Nobody is stopped dead.
- **The attraction is softer.** It holds each fighter at striking distance from the centre and no longer pins him to a point.
- **The stick still leans the blow** (`melee-press-feel.md` §13). So holding toward the rival drives him back with elbows and knees, holding away gives ground with kicks, and up and down climb or sink with rising and dropping blows. One stick does both jobs.
- **Every press is still a blow.** Nothing here delays or drops a press.

**Walking out takes both of them.** Orb: "if both players move their sticks in the opposite direction they should be able to walk out." When each holds his stick away from the other, within 45 degrees of straight away, for 12 ticks, the brawl lets go. It is free, and there is nothing to wait for after it. A blow thrown by either in those 12 ticks starts them again.

**The 12 ticks count while either of them guards.** Backing off behind a guard is the ordinary way to part, and a guard isn't an attack. They don't count while either has a blow on its way or an attack button held, or while either is reeling or staggered.

**My one-sided walk-out is withdrawn.** I had a fighter let go after 24 ticks of holding away with nothing landing on him. Orb's answer asks for both sticks, and I can't square the two: mine let one player end a brawl that the other wanted. One fighter alone still moves the brawl his way, at 0.4 of his speed with the rival drawn along. To leave alone he pays: the escape, a dodge, a zip away or a burst.

**Walking out and the escape don't collide.** Walking out is both sticks away with no boost. The escape is one fighter's boost held with his stick away: at once, at the dodge-cancel's price, as built. The nudge reads the stick alone, and the escape needs the boost.

**Giving ground: one fighter alone, while the other winds up or charges.** New, for Orb's second test: "can I move my character when the opponent is charging up an attack?" A nudge moves both fighters, so it never takes him out of a blow's way. The walk-out's count is stopped too, because the rival holds an attack button. This is the one-sided answer.

- **When.** From the first tick of the rival's medium or heavy wind-up, through any charge, until that blow lands, misses or is lost. Also while the rival coils a tackle in reach, or holds for a signature.
- **Who.** The other fighter, while he has no blow of his own on its way and no attack button held. His guard may be up.
- **What his stick does.** Held within 45 degrees of straight away from the rival, it backs him straight off along the line between them, and the rival isn't drawn along. Any other lean is the nudge, as always. He opens 1 bh in 12 ticks: 5 bh a second, the same for every fighter. Behind a guard it is 0.6 of that. It answers within 2 ticks, as the nudge does.
- **What the rival's stick does.** It still nudges the centre, so he can aim his blow with it. Only its part toward the giver follows him, at 0.6 of the giver's rate. So a fighter can walk a wound blow after a rival who backs off, and the gap still opens, slowly.
- **A leash.** He opens no more than 2.4 bh past striking distance. That is what a light can close in its 4 ticks, and it is well inside the 4.5 bh where a brawl lets go. Giving ground never ends a brawl.
- **A wound blow has a reach,** read as it lands: striking distance and 0.5 bh more for a medium, 1 bh more for a heavy, and 1 to 1.5 bh more for a charged heavy as it fills. Out of reach it misses, and he is open for 20 ticks (§3). At the very edge it misses too: a tie goes to the fighter who gave ground. Open means he can't guard, dodge, give ground or strike for those ticks, so a medium does punish it.
- **Afterwards** the brawl takes hold again. A press by either closes the gap as part of the blow, which lands 2 ticks later for each bh, and never more than 4 later. He is drawn closing on every one of those ticks, and never moves more than 0.6 bh in one. A light from further than 2.4 bh, which only happens when the two have come apart some other way, is thrown, closes what it can, and misses if it is still out of reach. So a medium punishes a missed heavy: 16 ticks against the 20 he is open.

| The rival's blow | If the rival stands still | If the rival holds toward him |
| :--- | :--- | :--- |
| A tapped medium, 12 ticks | He is out only if he starts in its first 6 ticks. That is a read, and not a reaction | It lands |
| A tapped heavy, 28 ticks | He is out if he starts by tick 16, which a player can do on sight | It lands |
| A full charged heavy, 48 ticks or more | He is out | It lands if it is let go at the flash. Held on, it misses: the gap passes its reach about 45 ticks after he starts to back off |

- **It isn't the one-sided walk-out.** It exists only while the rival has committed to a slow blow. It can't leave the brawl, the rival can follow, and backing off behind a guard is too slow to get out. To leave alone he still pays.
- **Four of these are Encounter's decisions from the build, and all are confirmed:** the flat rate, the edge, the straight line and what open means. With a fighter's own speed in the rate, the two hard rows can't both hold: a slower fighter isn't out from tick 16, and a faster one gets out when followed. With any direction allowed, aiming a blast or a charge walked the attacker off his own target.
- **The AI** gives ground against 0.05, 0.2 and 0.4 of the wound blows it sees, by level. It follows a player who gives ground at 0.3, 0.6 and 0.9. Without the first, a heavy would always land on it. Without the second, a new player's heavies would miss it for nothing.

**Everything he has while the rival winds up or charges:**

| What | Its price | What it does | Slice |
| :--- | :--- | :--- | :--- |
| The nudge | Free | Moves the brawl, and so chooses where the blow lands. It doesn't avoid it | C1 |
| Giving ground | Free | Avoids a heavy that isn't walked after him | C2t |
| A fresh guard, or a perfect block | Free | Blocks it, or turns it (§3) | Built, and C2b |
| A medium | 2 ki | Ends a heavy in its first 20 ticks | C2a |
| A shove | Free | Ends any heavy, with a stagger of 8 ticks | C2b |
| A charged medium | 4 ki | Ends a charging heavy, always | C2b |
| A dodge, or the slip | The dodge's price, or 5 ki | The blow misses, and the rival is open for 20 ticks | Built, and C6a |
| The escape: the boost, with the stick away | The dodge-cancel's price | He leaves | Built |
| A zip away | 35 or 40 ki | He leaves, and nothing stops it | Z2 |
| More lights | Free | Nothing. They do half damage through the armour, and then the heavy lands | |

**The centre and what is in its way** (ruled for C1).
- **A building's face stops it,** as Encounter has it. The centre doesn't pass through a building, whole, shell or rubble.
- **It isn't a dead stop.** The part of the nudge that runs along the face carries on, so the brawl slides along a wall, and a nudge upward takes it over the roof. Flight goes over anything, so nobody is cornered (pillar 1).
- **A drifting brawl never damages a building.** Orb's answer is that a building is scenery unless the rival is thrown through its shell. Only a throw, a tackle, a launch or a blast does that.
- **Being pushed against a face gives no bonus.** There is no pin and no wall hit in a brawl.
- The ground and a ridge stop the centre in the same way, and the two fight on along it.

**What the stick does, state by state.** It does nothing only while he is thrown about, which is the exception Orb named ("few exceptions like during knockbacks"), and in a staged moment.

| His state | His stick |
| :--- | :--- |
| In the brawl with his hands down | Nudges the centre, at full. With the rival's stick away too, they walk out. While the rival winds up or charges, he gives ground (above) |
| Striking, mashing any flurry, or holding the burst | Nudges at full, and leans each blow |
| Winding up a medium or a heavy | Nudges at full, and leans the blow. It follows a rival who gives ground |
| Charging a medium or a heavy, coiling a tackle, holding for a signature | The same. A charge can be walked into place |
| Guarding | Nudges at 0.6 of full, as a guard already slows him. He can give ground behind it |
| Reeling from a light or a medium, for 2 to 6 ticks | Nudges at full |
| **Staggered,** for 12 to 20 ticks | **Half, where it was none.** He stumbles the way he leans. He can't give ground or walk out |
| Holding the rival in a clinch | Nudges at full, aims the region he works on, and aims the throw |
| **Held in a clinch** | **Half, where it was none.** He drags the pair. His tap of A breaks the hold (§4) |
| Knocked back, launched, lifted, thrown, carried by a tackle, or buried | None. These are Orb's exception |
| A finisher, a struggle or another staged moment | The stick has that moment's own job, or none |

- **Why a stagger keeps half.** A stagger comes with every close and every landed heavy, so the stick would go dead several times in a brawl. A nudge moves both fighters, so a staggered fighter who drags the brawl doesn't get away from the next blow. It costs the attacker nothing, and the staggered player still chooses where the fight goes, and where he is launched from (§3). The core clears a stunned fighter's stick, so the director reads the stick as held from Simulation's record (`heldMx` and `heldMy`). The stick isn't kept in the intent: a staggered fighter isn't always locked, and he would fly on it. The core blanks that record for a launched or dropped fighter, so "no control in a knock-back" is enforced in one place (the EP's ruling).
- **A hit freeze is not a lock.** Nothing moves for either fighter for its few ticks, and the stick is read again on the next live tick.
- **The AI doesn't cancel a player's nudge by habit.** It opposes his stick only for a reason of its own: its care for a town, or a wall behind it. Against the medium AI a held stick moves the brawl at least 0.7 as far as it does against a rival who holds none (§11).

**What it gives the game.** Position is the player's job under pillar 2, and now he has it inside a brawl. The Protagonist's AI nudges a brawl away from a town, and the rival's nudges it toward one. It reads each fighter's `care` for that: 0.8 for the Protagonist and −0.5 for the rival (`launch-pair-plan.md` §1). Both are 0.0 in the data today, so neither AI leans anywhere. A charged heavy can be walked into place before it is let go.

**Data:** `brawl.nudgeMul` 0.4, `brawl.nudgeRampTicks` 8, `brawl.carryShare` 0.5 for 20 ticks, `brawl.partTicks` 12 and `brawl.partDeg` 45, `brawl.nudge.guard` 0.6, `brawl.maxStepBh` 0.3, and for digital input `brawl.nudgeDigital` 0.4 to 1.0 over 12 ticks. New: `brawl.nudge.stagger` 0.5, `brawl.nudge.held` 0.5, and `give` (5 bh a second for every fighter, the edge 0.033 bh, guard 0.6, follow 0.6, at most 2.4 bh past striking distance, reach 0.5, 1 and 1 to 1.5 bh past striking distance, closing 2 ticks a bh up to 4, and the AI's shares).

## 2. Three strengths on three buttons

**Orb:** "Proposal X=light, Y=med, B=heavy. turn whatever heavy strikes into medium, and invent new super-heavy looking attacks." And: "I'm excited to see Y and B flurries, I want to see how this looks visually."

**One press is one attack.** A tap of X is at once. Y and B start their wind-up on the press, and a tap lands when the wind-up ends.

| | **X: the light** | **Y: the medium** | **B: the heavy** |
| :--- | ---: | ---: | ---: |
| What it is | Today's light | Today's heavy strikes | A new, super-heavy tier, to be made |
| Wind-up, from the press | None | 12 ticks | 28 ticks |
| Press to contact | 2 ticks | 12 ticks | 28 ticks |
| Worth alone, in brawl lights | 1 | 2.5 | 6 |
| Ki | None | 2 | 5 |
| A clean hit | The rival reels for 4 ticks | He reels for 6 | He staggers for 12, in place |
| On a guard | Chips | Chips double, and tires the guard twice as fast | Breaks a set guard (§3) |
| While it winds up | | No armour | **Armoured** (below) |

**The heavy's wind-up is armoured,** by the EP's ruling, which Orb deferred to:
- **lights and light flurry blows never interrupt it,** from its first tick, and he takes half their damage;
- **mediums interrupt it until it is half wound,** at 20 ticks. After that they don't, though he takes them in full;
- a shove, a grab, a perfect block and any charged blow always end it (§3, §4);
- a blow that meets the armour adds nothing to the rival's run.

**A medium's wind-up has no armour, and a light still doesn't end it** (Encounter's default, confirmed).
- A medium or a heavier blow that lands on him ends it.
- A light does its full damage and adds 1 to the rival's run. Its reel waits until his own blow has landed.
- If a light ended it, the Y flurry would beat nothing. The X flurry beats it by the close: a stagger ends any wind-up.

**Out of reach, Y and B are lunges** (confirmed).
- Y is today's heavy lunge, and it lands as a medium.
- B is the heavy's lunge on the same travel. Its 28 ticks count from the press, so it lands at 28 ticks or as he arrives, whichever is later.
- What stops a lunge is what stops its wind-up, with a bolt read as a light, a heavy shot as a medium and a charged shot as a heavy.
- RT + B is the beam at any range.

### The three flurries

**Mashing a button is a flurry at that button's pace.** Each press is one blow. A press made while a blow of his is still going is held for up to 10 ticks and thrown as his line frees, as now.

| | **The X flurry** | **The Y flurry** | **The B flurry** |
| :--- | ---: | ---: | ---: |
| Fastest | One blow every 6 ticks | One every 12 ticks | One every 28 ticks |
| Blows a second | 5 to 10 | 4 to 5 | About 2 |
| Worth, in brawl lights for each tick since his last blow | 0.10 | 0.156 | 0.214 |
| So a blow at its fastest is worth | 0.6 | 1.9 | 6 |
| Ki a second, flat out | None | 10 | About 11 |
| How it looks | A blur of hands: the smear on the one striking limb | A drum roll of full blows: each one a whole strike, set and thrown | Hammer blows: each one wound up in plain sight, and the ground answers |

- **Damage a second is level within a button,** as it is for lights today. Between buttons it rises with the strength, and so does the price.
- **Each flurry beats one of the others:**
  - **the X flurry beats the Y flurry.** It lands twice as many blows, so its run climbs faster and it takes the close (`melee-press-feel.md` §3);
  - **the Y flurry beats the B flurry.** A medium lands every 12 ticks, inside the 20 in which a heavy's wind-up can still be stopped;
  - **the B flurry beats the X flurry.** Lights don't stop a heavy, and 6 brawl lights come back for the 1.4 he takes through the armour.
- **The run and the close don't change.** Every landed flurry blow of any button adds 1 to his run, and a reply takes 1 off. At a run of 4 his next blow staggers the rival in place. That is the next blow of any strength, and the stagger is the close's 12 ticks whatever threw it.
- **The mix-up is the three in any order.** Each press is its own blow at its own pace, one after another, so a light lands between the slower blows and its reel covers the start of their wind-ups. It also gives the rival no single answer, since each flurry has a different one.
- **A string doesn't end by itself.** "A heavy after two landed blows is the ender" is withdrawn. A string ends when the player ends it: with a charged heavy, a throw or a power attack, or with the flurry's close.
- **The looks** are the ones set for speed, on all three. An ordinary exchange of lights is 4 of 10 on flash (Orb, questionnaire 19).

### How a tap is told from a hold

Controls found two traps in "a tap lands when the wind-up ends, and a hold keeps winding" (`docs/controls/q19-input.md`, "Later notes"). Both are answered by where the decision is read.

| | The rule |
| :--- | :--- |
| **When it is decided** | At the end of the wind-up. Button up: it was a tap, and the blow lands then. Button down: he keeps winding |
| **A grace of 4 ticks, on every device** | A release in the 4 ticks after the wind-up's end is still a tap. The blow goes at once, at a tap's strength. So a tap can run to 16 ticks on Y and 32 on B before it is a hold |
| **The medium's wind-up is 12 ticks, and not 16** | Taps run 3 to 6 ticks on a pad, 4 to 8 on a keyboard and 5 to 12 on touch. At 12 every pad and keyboard tap lands on time, and with the grace no touch tap becomes a charge. A wind-up of 16 for everyone would slow the medium flurry by a quarter to protect one device. The grace is for every device, because the intent doesn't say which device a press came from |
| **The clock** | The wind-up and the grace count live ticks, which stop in a hit freeze |
| **No new bit in the intent** | A release has no true tick: one made in a freeze reaches the sim as the freeze ends. Because the wind-up doesn't advance in a freeze either, the release is read at the same point in the wind-up as it was made. So `relWaited`, and the replay break it would need, aren't asked for |
| **Until a hold has its charge** | A Y still down at its decision point, 16 ticks, goes by itself there at a tap's strength. That lasts until C2b. B's hold is the charge from the first chain on (§10) |

- **For players who can't hold a button:** yes to both of Controls' settings. A latched charge: a tap starts the wind-up and the next press lets it go. And charges off: every press is a tap.
- **On the Simple layout the hold is the wind-up.** One button carries all three, and its clock starts on the press. The blow is thrown when he lets go, at the weight the hold has reached: under 12 ticks the light, from 12 the medium, and from 28 the heavy. So a medium can land 14 ticks after its press and a heavy 30, much as on the other layouts. Read literally, the first wording made them 24 and 56 (Controls, `docs/controls/windup-read.md`). This is Controls' recommendation with the light kept: a short tap is still a light, thrown on the release as it is today. It is still one blow to a press.
  - Held past 28 ticks it charges as any heavy does: full at 44, and it goes by itself at 70. Simple has no charged medium and no burst. Its flurry without mashing is the hold-to-flurry setting.
  - From 12 ticks the pose is a wind-up, and from then it is armoured against lights, since it can no longer be one. Mediums end it until tick 20, as they do a heavy.
  - The clock is live ticks, as on every layout, if the bridge can count them. If it can't, the rule is the two figures: 14 and 30.
  - `read.simpleMediumStart` 12 and `read.simpleHeavyStart` 28.
- **Simple's buttons under three strengths.** Simple has no diamond, so each of its buttons carries one cell of the full layout.

| Simple's button | What it is | Its readings |
| :--- | :--- | :--- |
| **X, Attack** | X and Y, by the length of the hold | A tap is the light. Held, it is the medium from 12 ticks and the heavy from 28, thrown on the release (above) |
| **Y, Heavy** | B's cell, whole | A tap is the heavy, 28 ticks after the press and armoured from its first tick. On a staggered rival it is the launcher (§3). Held, it is the charged heavy. With RT held it is the signature's hold (§5) |
| **B, Guard** | As now | A hold guards, and a tap in time is the perfect block |
| **A, Dodge** | As now | A tap dodges, and a hold sprints |
| **LB, Context** | A's cell | In reach, the shove, the clinch and the tackle (§4). Out of reach, the pick-up, the civilian and the taunt, as now |
| **RT, Power** | As now | Held, it charges. With X, the director's pick of a special. With Y, the signature |

  - **Y is the heavy because the launcher needs it.** A stagger lasts 12 ticks and a heavy by Attack's hold takes 28, so on Simple the route would be out of reach. With Y it is the same as everywhere: Attack until he staggers, then Y.
  - **The binding doesn't change.** Simple's Y sends the `signature` edge, and from C2a that edge with no stance held is B's. Only the label changes, from Signature to Heavy.
  - **The two heavies are told apart by the hold.** A heavy let go from Attack was wound by its hold, and lands 2 ticks after the release. A heavy pressed on Y winds for 28 ticks from the press. Both arrive as B's edge, so the director reads which it is from the held level before the edge.
  - **No tap fires a signature, on any layout.** On Simple it is RT + Y, held to its first flash. If Simple touch can't make that with its thumbs, Controls designs the gesture, and the hold stays as its tell.
  - The pairs, the charged medium, the burst and the energy blows in reach aren't on Simple's buttons. The director throws the pairs and the energy blows, and the hold-to-flurry setting gives the flurry.
  - **Touch Simple has no Context button:** its fourth slot is Transform. There the director throws the shove, the clinch and the tackle, as it throws the pairs. It is read again with C2b, when the shove exists.

**The bands for press to contact, by button:** X at 2 ticks, with 95% inside 4. Y at 12 ticks, and never past 16. B at 28 ticks, and never past 32. On every button the move starts within 10 ticks of the press, which is the band Encounter already measures.

**Data:** `x` (contact 2, flurry gap 6 to 12, rate 0.10); `y` (wind-up 12, worth 2.5, flurry gap 12 to 16, rate 0.156, ki 2, reel 6, guard chip ×2); `b` (wind-up 28, worth 6, flurry gap 28 to 34, rate 0.214, ki 5, stagger 12, armour: light damage taken 0.5, mediums interrupt to tick 20); `read.windupGrace` 4.

### What the core decides by strength

The core carries a third weight, the medium (Simulation's proposal, which the EP accepted). It decides six things by weight. **The new heavy keeps today's heavy column in all six,** and the medium gets a column of its own. Every medium figure is a first value, to be read on the first three-strength baseline.

| What the core decides | A light | **A medium** | A heavy (B) |
| :--- | :--- | :--- | :--- |
| 1. Where it lands: the pick by head, core, arms, legs | 12, 4, 10, 6 | **8, 8, 7, 9** | 1, 3, 1, 3, as now |
| 2. How a block wears it | Half to the arms, up to their cap. The rest is soaked, and nothing goes to the legs | **As a light** | The 0.7 and 0.3 split to arms and legs, as now |
| 3. Whether it staggers | No | **No.** Its 6-tick reel is the director's | Yes, as now |
| 4. Whether it can cripple a battered limb | No | **No** | Today's roll, until the wrench is built. From then only the wrench does (§3) |
| 5. Thrown with a broken arm | ×1.15 | **×1.0** | ×0.8, as now |
| 6. Its mood units | 13 | **40** (`impulses.brawlMedium`) | 120, on `brawlHeavy` as now |

- **The pick is the midpoint of the other two,** as shares: a quarter each to the head and the core, and the rest split 7 to 9 between arms and legs. Today's heavy strikes are thrown far more often as mediums, on a 12-tick wind-up. If they kept the heavy's pick, a Y flurry would wear the core nearly five times as fast as an X flurry, and the brink would come early.
- **A block treats a medium as a light.** A guard soaks the two quick strengths, and their wear on the arms stops at the cap. If a blocked medium took the heavy's split, a Y flurry on a guard would batter the legs and spill into the core, and "a blocked blow never reaches the core" would stop being true. The medium's own pressure on a guard is its doubled chip.
- **A medium never cripples.** The pieces could when they were heavies, but they are thrown too often now. A tapped heavy keeps today's roll only so that limbs still break before the wrench exists. When the wrench is built, the roll goes and the wrench is the one way a strike breaks a limb, and it is certain.
- **A broken arm leaves the medium alone.** It makes his lights sharper and his heavies weaker, and the medium is the strength in between.
- **40 units** puts a flat-out Y flurry at 200 a second, between the X flurry's 130 and the B flurry's 257, and under the decay's 300. So no one button mashed alone raises the mood: a trade does, and a close, and a knock-back.
- The launcher and the charged heavy are heavies for all six. The riposte's and the reversal's blows are mediums for all six, and their staggers are their own rules.
- **For the style label's attack count a medium counts with the lights** (the EP's provisional ruling, confirmed). It is quick, cheap and mashable, and the label's heavy should mean the 28-tick blow and the charges. The label wants a third count when style is next read.
- **A point-blank energy shot goes through the blast's own hit, with no exchange passed** (Simulation's free route, confirmed). On a guard it takes the blocked shot's rule. Unblocked, its wear spreads as a shot's does, and it can't cripple. Its mood units are a light's for a bolt and a medium's for the blast.
- **A blow that names its region** is wanted now, in the same core change: one option on the core's hit, which a blocked blow ignores. The double hit uses it at once, for the head (§7). The wrench and the vicious blows need it next (§3, §4).

## 3. Holding: the burst on X, and the charges on Y and B

### A held X is the burst

**Orb:** "X Light Hold should give a high speed burst of low damage attacks that quickly slows down on a curve." Lights never charge.

The press throws the light, as always. **The burst starts when the hold is certain, 16 ticks after the press.** From there more blows follow by themselves, fast at first and then slowing.

| Blow | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Lands, in ticks from the press | 2 | 18 | 22 | 26 | 31 | 37 | 45 | 56 |
| The gap before it | | 16 | 4 | 4 | 5 | 6 | 8 | 11 |
| Worth, in brawl lights | 1 | 1 | 0.28 | 0.28 | 0.35 | 0.42 | 0.56 | 0.77 |

- **A tap of X never throws two lights.** My first table landed the second blow 6 ticks after the press, which needs the burst to start at 4. Taps run 3 to 6 ticks on a pad, 4 to 8 on a keyboard and 5 to 12 on touch. So at 4 nearly every keyboard and touch tap threw a second light, and at 8, as Controls built it, most touch taps still would. That breaks "one press is one attack" (the EP's finding, from `docs/controls/windup-read.md` §5).
- **So the hold is read on the same line as Y's and A's: 16 live ticks.** By Controls' model no pad or keyboard tap reaches it, and under 2% of touch taps do, which is inside the band for a tap read as a hold (§11). That figure is modelled and not measured. A hold now begins at 16 ticks on X, Y and A alike, and the energy stance's volley already sits there.
- **Until 16 ticks a held X is a tap:** one light, and then he sets himself for about 10 ticks. Let go in that time, nothing more is thrown. The set is the burst's tell, and the rival can answer in it.
- **It is still one move of eight blows in under a second,** and it is still worth 4.7 brawl lights in all. The second blow is a full light, since it is the one he set. Each of the six after it is worth 0.07 for each tick of its gap.
- **It doesn't beat a mash or a timed string.** Over the same 56 ticks a mash is worth 6.4, so the burst is 73% of it. A light and one skill strike are worth 5 in 32 ticks.
- **It is the easy option.** A player who can't mash holds, and gets about three quarters of a mash.
- Its blows reel the rival for 2 ticks each. Each one after the first adds half a point to his run, so if nothing answers it, the eighth blow is the close.
- Letting go stops it after the blow in hand. After the eighth he is open for 8 ticks. Any other press replaces it.

### A held Y or B keeps winding

**Orb:** "holding a button should charge up an attack. so a charged heavy should have benefits that a charged light attack doesn't." The held medium takes the job that the charged light had.

| | **Held Y: the charged medium** | **Held B: the charged heavy** |
| :--- | :--- | :--- |
| Charged from | 16 ticks: the wind-up and the grace | 32 ticks |
| Full at | 24 ticks | 44 ticks |
| It goes | 4 ticks after he lets go. Held to 40 ticks, it goes by itself | 4 ticks after he lets go. Held to 70 ticks, it goes by itself |
| Worth, in brawl lights | 3, rising to 4 at full | 8, rising to 10 at full |
| Ki | 4 | 8 |
| While he holds it | **No armour.** Any blow that lands on him ends it | **Armoured,** as its wind-up is (§2) |
| A clean hit | The rival reels for 10 ticks. **No knock-back** | **A knock-back.** At a full charge, a launch that the stick nudges and the director stages, or a lift of 45 ticks with no stick |
| Its job | Quick to charge. **It ends a charging heavy, always** | It punishes a flurry, breaks a guard and ends a string |
| On a guard | Chips | A guard raised in the last 30 ticks blocks it, with a quarter of the damage through. **A set guard breaks:** he staggers for 20 ticks and half goes through |
| A perfect block | Turns it | Turns it: he staggers for 20 ticks, and the riposte follows |

**What ends a heavy that is winding or charging.** Lights don't. These do:

| The answer | When | What happens |
| :--- | :--- | :--- |
| A medium, or a Y flurry | Before it is half wound, at 20 ticks | The heavy is lost and he reels for 6 ticks |
| **A shove** (§4) | Always | The heavy is lost and he staggers for 8 ticks |
| A charged medium, or a charged heavy that lands first | Always | The heavy is lost |
| A clinch or a tackle | Always | He is grabbed out of it |
| A fresh guard, or a perfect block | When it lands | As in the table above. This is "blocking correctly" |
| Getting out of its reach: giving ground (§1), a dodge, a slip, a zip away | When it lands | It whiffs, and he is open for 20 ticks |
| A power attack or a signature | When they meet | Two heavy commitments meet (`melee-press-feel.md` §11) |

**So against a flurry:** a fighter who keeps tapping X into a full charged heavy takes it. Over the 48 ticks it needs, his lights do about 2.4 brawl lights through the armour, and then 10 come back with a launch. A rival mashing Y is the other case: he stops it in its first 20 ticks. The first playtest of the slice decides whether this holds.

**The just release** (Orb picked it) is on the heavy only: letting go within 4 ticks after the full-charge flash. His line is free 10 ticks sooner, and it adds 1 to the flow. It is kept subtle: no extra damage.

**The wrench.** A charged heavy that lands on a battered limb is the crippling blow, and breaks it. This is the one place a strike is vicious; the rest of that idea lives in the clinch (§4). Orb confirmed vicious inside the clinch on 2026-10-06, and the EP cleared the wrench with it.
- **The stick picks the limb, and the piece lands there.** A charged heavy let go with the stick leaned at a battered limb, down for the legs or away for the arms, is the wrench on that limb. The lean is read at the release.
- **Leaned anywhere else, or at a limb that isn't battered, it is an ordinary charged heavy,** and the lean aims where it sends him.
- **With no stick** the blow lands where its family's pick puts it, as now. If that is a battered limb, it is the wrench too. So the AI and a Simple player still get them.
- **The rule decides, and the content follows it.** Each fighter needs one heavy that lands on an arm and one that lands on a leg. The Protagonist has both. The rival's ten have neither, so two of his are re-aimed. He doesn't need two more (Combat's question). Until then his wrench plays his nearest heavy, and the crippling moment's own beat carries the read.
- **A wrench doesn't launch,** even at a full charge: a blow to a limb doesn't send the whole body. He is knocked back, as by any charged heavy. A tapped heavy and the launcher never wrench.

**The launcher: a heavy on a staggered rival.** New, for Orb's third test: "can I reliably launch my opponent?" Until now a launch came from a full charged heavy, which takes 48 ticks and has no set-up that makes it sure. So a player couldn't launch on purpose.

- **The rule.** A tap of B while the rival is staggered by an opening is the launcher. The openings are the staggers a fighter earns: a flurry's close, a broken guard, a perfect block, a zip's tech counter and a punished taunt. A landed heavy's stagger isn't one, and a shove's isn't.
- **It always lands.** Its wind-up is halved to 14 ticks, as on the beat (§9), and the stagger holds until it lands.
- **It always sends him, and it launches when the launcher is ready.** When it launches, the stick nudges the launch and the director stages it, as for every launch. After any launch of a fighter, the launcher rests on him for 40 s of fight time. In that time the same B still always lands, and knocks him back as the old ender did. It is worth 3 brawl lights either way, which is half a heavy for half the wind-up, and it costs a heavy's 5 ki. The launch's landing is the rest of its worth.
- **A B pressed early is kept.** Pressed in the 10 ticks before the stagger begins, it is held and thrown as the launcher, by §2's rule for a held press. So "X, then B" rolled off the closing blow works, and so does a B pressed on seeing the stagger. A kept B goes before any X pressed after it, so mashing on doesn't lose it (Encounter's decision, confirmed).
- **A held B loses the guarantee.** The stagger holds for the 14 ticks only. Held past that, it is a charged heavy like any other.
- **The staggered fighter keeps half his nudge** (§1), so he has a say in where he is launched from. Nothing gets him out: a stagger takes his buttons, as it does today.
- **A landed heavy doesn't open it.** My first rule let it, and then every heavy that landed was a launch 14 ticks later, for the AI as much as for a B masher.
- **The opening has a ping, and both players hear it** (the EP's ruling). It sounds only when a launch is ready, so no ping means a knock-back. Local play shares its speakers, so the cue can't be private. It tells the defender that he is open as much as it tells the attacker to press B.

**The route to teach:** mash X until he staggers, then B, and aim with the stick. On Simple, B is the Y button (§2). The game says when, because the close has its own cue.

**The other launches stand,** and each is a step up in skill: the full charged heavy, which is the read and is worth 8 to 10; the lift and then a heavy, since a heavy that lands on a lifted rival launches him (C6a); and a charged heavy at a flow of 3 (C3).

**The AI** throws the launcher after 0.15, 0.35 and 0.6 of the openings it causes, by level. Inside a brawl its heavy at a guard has a share of its own, 0.06, 0.1 and 0.18, since a broken guard is an opening (Encounter's decision, confirmed). That replaces `heavyAfterClose` (0.2, 0.6 and 0.9), so that a player isn't launched twice as often as today.

**The riposte and the reversal** threw the old heavy. Both are mediums in worth now, with their staggers as built, and neither separates (confirmed). The launcher is what separates: a perfect block staggers for 20 ticks, so a B pressed in it launches.

**What the first build measured, and what changes** (Encounter's scratch build of C2a and C2t, four matches a row at medium, not yet tuned).

| Measured | Figure | The band |
| :--- | :--- | :--- |
| Windows the route's player used, and launched from | 61 of 61 | Every one (a hard test). It holds |
| Launches a match by the route's player | 16 | 4 to 10 |
| Launches a match on him | 12 | 4 to 8 |
| Brawls that end in his launch | 51% | See below |
| The AI against itself, mean match | 554 s, against 394 s on main | A median of 400 to 450 s, and never outside 5:00 to 8:00 |
| Blows that move their attacker over 0.6 bh in a tick | 0 of about 7,000, against 23 on main | None (a hard test). It holds |

Reliable had become constant. Two things in my rule caused it, and both change now. Neither is a number to tune.

1. **Too many staggers opened it.** Every stagger of 12 ticks or more did, so every landed heavy was a launch 14 ticks later. Now only an opening does (above): the staggers a fighter earns.
2. **Nothing spaced the launches.** Now the launcher rests for 40 s on a fighter who has been launched, and in that time the same B knocks him back (above). A knock-back is what ended most brawls before this chain, so the pace returns to one that is known. The route still works every time: he staggers, B, and the rival is sent.

**The levers for Encounter, in order,** once those two are in:

| Order | Lever | First value | Its range | What it moves |
| ---: | :--- | :--- | :--- | :--- |
| 1 | The rest, `launcher.restS` | 40 s | 25 to 60 | Launches a match, by both fighters, and the match's length with them |
| 2 | The AI's share of the openings it uses, `launcherShare` | 0.15, 0.35, 0.6 | 0.1 to 0.5 at medium | Launches on a player |
| 3 | The launcher's flight, `launcher.flightMul` | 1.0 | Down to 0.6 | The match's length and the collateral, if both are still over with the launches in band. A shorter flight reaches fewer buildings. The full charged heavy and the signatures keep the long flight |
| 4 | The launcher's price | 5 ki | Up to 15 | The last one: only if a player on the route alone still sits at the top of his band |

- **Not levers:** how often a masher earns a close, which is the brawl's own texture and is banded elsewhere; and the bands' widths.
- **The bands to tune to,** at medium:
  - launches a match by the route's player 4 to 10, and on him 4 to 8;
  - the AI against itself, 6 to 12 launches a match in all;
  - the route sends him, by a launch or a knock-back, in 50 to 75% of the brawls it is tried in, and launches in 10 to 25% of them;
  - a first launch inside 30 s of the first brawl in at least 80% of matches, since the launcher is ready at the start;
  - the match's median at 400 to 450 s for the AI against itself, and never outside 5:00 to 8:00, which is Orb's five minutes or more and acceptance test W3;
  - the collateral rows as they stand. Launches drive them, so they are read after the launches are in band, and lever 3 is theirs.

**One map for the stick, wherever it aims a blow in reach.** Combat assumed it (`docs/combat/pending/movegen/c2t-content.md`), and it is confirmed.

| The stick | Where a launcher or a charged heavy sends him | The region a vicious blow or a wrench works on |
| :--- | :--- | :--- |
| Up | It lifts him | The head |
| Down | It drives him under | The legs |
| Toward the rival | It drives him back along the line | The core |
| Away from the rival | It turns him past the attacker | The arms |
| None | A launcher: the launch planner's pick, with a piece that matches it. A full charged heavy: the lift (above) | A vicious blow: the core. A charged heavy: its family's own pick |

- Each direction owns a quarter of the circle, 45 degrees either side. A stick on a diagonal reads as up or down.
- **It is read once:** at the press for a launcher, at the release for a charged heavy, and at each tap for a vicious blow. After that the stick nudges the launch as it always does.
- **The send is the stick's, and the piece follows it where one fits.** While stand-ins are on B, few of them read at 14 ticks. A launcher still goes where the stick says when its piece doesn't match. That is a fault in the look and not in the rule, so it doesn't fail Orb's test.
- A wrench uses only the down and away rows, and only on a battered limb.
- The data key is Combat's `launcher.aim`.
- **As built in the first chain:** up and toward pick among the launch planner's candidates that way. Away has no candidate yet and falls to the planner's pick; the turning send is wanted by C2b. Down on the ground falls to the planner's pick for good, since there is nothing under him.

**He can nudge the brawl while he winds or charges** (§1).

**A failed option hurts 3 of 10** (Orb, questionnaire 19). A whiffed heavy leaves him open for 20 ticks. The rule for every flashy option: failing never leaves him open for more than 20 ticks, and never adds damage of its own.

**Data:** `burst` (start 16, as `read.burstStart`; gaps 4, 4, 5, 6, 8, 11; the second blow worth 1; rate 0.07; reel 2; run 0.5 a blow; open 8); `charge.y` (from 16, full 24, lands 4, worth 3 to 4, ki 4, reel 10, max 40); `charge.b` (from 32, full 44, lands 4, worth 8 to 10, ki 8, max 70, whiff 20); `charge.justTicks` 4; `guard.freshTicks` 30; `launcher` (the openings, wind-up 14, worth 3, ki 5, held press 10, rest 40 s, flight ×1.0, and the AI's shares 0.15, 0.35 and 0.6).

## 4. A: the shove, the clinch and the tackle

Orb's sketch, with one move to a press. A is how a fighter takes hold of the other's body. In reach it has three readings. Out of reach a tap is still context: a pick-up, a civilian, or the taunt.

| | **A tapped: the shove** | **A mashed: the clinch** | **A held: the tackle** |
| :--- | :--- | :--- | :--- |
| What it is | Both hands, no damage. The rival goes back 3 bh and the brawl lets go | He takes hold, works on the rival in the hold, and throws him | He coils, and then shoots at the rival and carries him into whatever is on the line |
| How it is read | A wind-up of 12 ticks from the press. Let go by its end, or in the 4 ticks of grace, and the shove goes | A second press of A inside the shove's wind-up turns it into the reach for a clinch, which takes 10 ticks. The shove isn't thrown | Still held 16 ticks after the press, he is coiling, and no shove is thrown. It goes when he lets go, and is full at 36 ticks. Held to 50, it goes by itself |
| Range | In reach | In reach | 6 bh at the shortest coil, 12.5 bh at full |
| In the hold | | **Each further tap of A is a vicious blow** on the region the stick leans to, up to four. A press of X, Y or B is **the throw,** at once. With neither, he lets go after 45 ticks | |
| Worth | Nothing | A vicious blow does half a brawl light of damage and three times a light's wear, all of it on that one region. The throw is a knock-back of 8 bh | The rival takes the impact as a landing at that speed. **The tackler takes nothing** |
| Where it ends | | The stick nudges the throw and the director stages it. Thrown through the shell of a damaged building, he finishes it (Orb, questionnaire 19) | He carries the rival 6 to 16 bh along the line to the first surface: the ground, a ridge, a building. **Both end in the crater.** At a full coil the rival is buried, which gives a free follow-up. With nothing on the line, he throws him off |
| Ki | None | None | 10 |
| Beats | A heavy that is winding or charging, which it ends with an 8-tick stagger | A guard | A guard |
| Loses to | Any blow that lands on him in its wind-up | Any blow that lands first. **The rival's own tap of A within 8 ticks of the hold breaks it:** both are pushed 1.5 bh apart. A burst | A shove or any blow while he coils. A dodge, after which he flies 6 bh past and is open for 20 ticks. A charged heavy that lands as he arrives |
| Limit | One shove in 45 ticks | The grab lockout: 90 ticks, shared with every grab | The grab lockout |

- **Vicious lives in the clinch,** and Orb confirmed it on 2026-10-06: "vicious inside the clinch is good, go with that." Orb liked a "vicious" kind of blow: "headbutts, bites, clawing, gouging", by character. Every one of those is something done while holding someone. So it has no button of its own. In the hold, the stick aims at a region and each tap works on it: up the head, down the legs, toward the core and away the arms, and the core with no stick (the map is in §3). With the wrench (§3) it is how a player goes after one wound on purpose. The four fighters' looks, and what touches the rating, are in `pitch-third-blow.md`: the Protagonist's version is pointed and not cruel, and the Cyborg's bite is the one to settle.
- **The held fighter keeps half his nudge** (§1). The holder chooses what is done to him, and he still has a say in where it happens.
- **The clinch is how a flying fighter takes control,** as Orb put it: no ground is needed.
- **No grab spam** stands (`melee-press-feel.md` §10). The clinch, the tackle, the zip tackle, the dive grab and the seize (§6) share the one lockout, and a thrown fighter can't be grabbed for 120 ticks.
- **The taunt is a gamble** (Orb picked it). Out of reach, a tap of A taunts for 45 ticks. Finished, it gives his meter its taunt gain and 10 ki. Hit before it finishes, he gets nothing and staggers for 12 ticks.

**Data:** `shove` (wind-up 12, push 3 bh, stagger on a heavy 8, lockout 45), `clinch` (reach 10, vicious blows up to 4, damage 0.5, wear ×3, max 45, throw 8 bh, tech 8), `tackle` (coil 16 to 36, max 50, range 6 to 12.5 bh, carry 6 to 16 bh, ki 10, whiff 20), `taunt.ki` 10.

## 5. Signatures move to RT + B

**Orb:** "just hitting B and getting locked into what feels like a beam-attack cutscene doesn't feel right, B needs a recast and its own unique moveset."

B is the heavy now, and it has its moveset. So the signature needs another place.

- **The fighter's defining signature is on RT + B,** the charging stance's B. On Simple that is RT + Y (§2). That is where the control scheme first had it.
- **It takes a hold, which is its tell.** Held to the first flash at 24 ticks, it is his art, for 25 ki. Held to the second at 48, it is his signature, for 45. In acts 3 and 4, held 45 ticks more, it is his ultimate. Let go before the first flash, nothing fires: he gets the "not ready" cue and spends nothing. The tiers and prices are those of `melee-press-feel.md` §11.
- **Signatures play live.** An art has no pause and no camera of its own. A signature takes a pause of at most 1 s, and only when it lands clean. A struggle is staged as before. Finishers keep their staging, which the other player called "really cool".
- **The player keeps hold of it.** A beam lasts while B is held, up to its tier's length, and ends when he lets go. Ki is spent by the second as it fires. The stick nudges its aim. A melee art is a string that the player drives: each press is its next blow, and he can stop.
- **While he holds for it:** a blow that lands before the first flash ends it. From the first flash he is committed, and armoured against lights.
- **The other stances keep their own B:** the guard signature on LB + B, the movement signature on LT + B, and in the energy arts stance the beam, on a hold and live. The energy moves stay where they are: bolts on X and the heavy shot on Y.
- **Until a fighter's own art is authored,** RT + B fires the beam by these rules.
- The Charge burst, blast and flurry of this page's first draft are withdrawn. They were B as ki at close range, which Orb turned down for a blow of the body.

**Data:** `sig.hold` (art 24 ticks, signature 48, ultimate 45 more); `sig.livePauseMax` 60 ticks, on a clean hit only.

## 5b. Energy arts in reach: the point-blank bolt and the blast

New, for Orb's fourth test: "do energy attacks look cool as part of close-range combos?" Today they can't. A press with RB held inside a brawl is spent as a link, with a `press_ack` of `energy`, and nothing is fired.

**With RB held in reach, X and Y are blows of light.** They take the three strengths' places: the bolt is the light and the heavy shot is the medium. Each is one press and one attack.

| | **RB + X: the point-blank bolt** | **RB + Y: the blast** |
| :--- | :--- | :--- |
| What it is | A bolt fired with the hand on him | The heavy shot, let go against his body |
| From the press | At once: contact at 2 ticks | A wind-up of 12 ticks, read as a medium's is |
| Worth, in brawl lights | 1. At range a bolt is half a light, and here all of it lands | 2.5, a medium's |
| Ki | 1, a bolt's price | 8, the heavy shot's price |
| A clean hit | He reels for 4 ticks, and it adds 1 to the run | **A knock-back of 4 bh,** along the stick's lean. The brawl ends |
| Mashed | The X flurry's pace and worth: one every 6 ticks at the fastest. About 10 ki a second, flat out | One every 12 ticks, though the first clean one ends the brawl |
| On a guard | **It is a shot.** Half its wear goes to his arms up to their cap, and the rest reaches his core (`melee-press-feel.md` §9, blocked shots). A blocked blow never does | The same, and no knock-back |
| Against a heavy's armour | A light: it never interrupts, and does half | A medium: it interrupts until tick 20 |
| While it winds up | | No armour. Any medium or heavier blow that lands ends it |

- **Its job is one a fist can't do.** A guard soaks blows for ever and leaks shots, so energy is how a string gets through a guard without waiting to set it. And the blast is the quickest knock-back in the game: 12 ticks, against the 48 of a full charged heavy. Both are paid for in ki, and RB held means no guard.
- **They chain both ways, with no gap.** Holding RB changes what X and Y throw for as long as it is held, and letting go changes them back. Switching is instant and free (`melee-press-feel.md` §12). The line, the run, the flurry's clock and the mix-up carry across, so a point-blank bolt lands between two punches as a light would.
- **The same button keeps firing as he leaves.** After the blast he is 4 bh away, and RB + X is now a bolt in flight. So the string a player finds first is: punches, the blast, bolts after him as he slides, and a zip back in.
- **The launcher takes no energy.** A blast isn't a heavy, so it doesn't launch a staggered rival.
- **RB + B is the beam,** as it fires today, until signatures play live (C5). From C5 a beam let go in reach carries him along it and drops him at its end. That is designed with C5.
- **Held, each is its tap** (Encounter's default, which replaces my first line here). A held RB + X is one bolt, and a held RB + Y is the blast, let go at its decision point. The volley and the charged shot in reach are read with the energy stance's own slice.
- **On Simple** the director throws them for the player, as it does the pairs.
- **It doesn't drop a zipper.** Against a zip, a point-blank bolt is ruled as a light is.

**What has to be seen,** for Animation and VFX. The test is Orb's word: cool.

1. **The hand is lit before it lands.** A bolt's glow comes up with the blow, in its 2 ticks. The blast gathers into the palm over its 12 ticks, as a thin ring or an edge light and never over the whole body (Legal's charge rule).
2. **It is a blow and a shot at once.** The hand reaches him, and the light goes off against his body at the contact. It must not read as a punch with a glow on it, or as a shot that happens to be close.
3. **Both bodies are lit by it.** For 2 or 3 ticks the near side of each fighter takes the shot's colour, as a rim and not a flash over the whole body.
4. **The spill.** What doesn't stop in him flies on past, along the stick's lean: a spark streak of 2 to 3 bh for a bolt, and a cone of about 6 bh for the blast. Where it meets the ground, the sea or a wall, it leaves a scorch. In this slice it is drawn and not simulated: it damages nothing.
5. **The blast carries him.** He leaves along its line with the shot's colour trailing off his chest for about 10 ticks, and smoke after that.
6. **A mixed string reads as mixed.** The fist has the limb's smear and a thud, and the shot has a flash and a crack. Alternating them should look and sound like two instruments.
7. **Each fighter's own.** The colour is his ki's. The Protagonist fires from the heel of the palm. The rival's is for Combat and Art to pick, in fists, plates and straight lines.
8. **A mashed bolt must not strobe.** At up to ten a second, full flashes would pass the limit of three a second. One blow in each 20 ticks gets the full flash, and the rest get sparks at the hand. Legal and the accessibility checklist rule the final figure.

**Data:** `energy.reach.bolt` (worth 1, ki 1, reel 4, run 1), `energy.reach.blast` (wind-up 12, worth 2.5, ki 8, knock-back 4 bh), `energy.reach.spill` (2 to 3 bh and 6 bh, drawn only), `energy.reach.flashEveryTicks` 20.

## 6. Four power attacks, on buttons that sit together

**Orb:** "a staple of modern fighting games are the two-button combined power attacks: A+B (grab-related) / X+A / Y+B / X+Y. I don't want to add combinations that cross the pad."

They still read right with B as the heavy: each pair does what its two buttons mean together. X is the quick blow, Y the full one, B the heaviest, and A the body. Each costs ki, each has a tell, and none is a flurry blow.

| Pair | Name | What it does | Ki | Tell | Loses to |
| :--- | :--- | :--- | ---: | ---: | :--- |
| **X+Y** light and medium | **The lift** | An upward blow that lifts the rival in place for 36 ticks, which starts a juggle (`melee-press-feel.md` §5). Worth 3 brawl lights | 10 | 10 ticks, armoured against lights | A guard, which blocks it with no lift. A shove |
| **X+A** light and body | **The slip** | He goes round the rival, over, under or behind by the stick, up to 2 bh, and lands a light on the way. Timed inside the rival's tell, the rival's blow misses. This is the step strike, moved here from LT+X | 5 | 4 ticks | A blow that catches him before he moves |
| **Y+B** medium and heavy | **The breaker** | The two strengths together: a blow that no guard stops, fresh or set. It ends a heavy that is winding. Worth 6 brawl lights, with a knock-back of 6 bh | 20 | 14 ticks | A perfect block. A dodge or a slip |
| **A+B** body and heavy | **The seize** | The power grab, as Orb asked. It beats a guard, and the rival's tap of A doesn't break it: only a burst does. It ends in an aimed throw of 12 bh, and through a shell it finishes the building | 20 | 12 ticks | Any blow that lands first. A dodge. The grab lockout applies |

- **No pair crosses the pad.** Y+A and X+B stay empty (Orb confirmed).
- **How a pair is read** is Controls' design, and it is confirmed (`docs/controls/q19-input.md`):
  - the director reads it from the press edges it already gets, by cell. There is no new bit in the intent;
  - **the window is 3 ticks** (`read.pairWindow`), doubled with the assist setting;
  - **both buttons must be fresh:** neither was pressed in the 8 ticks before (`read.pairFresh`). So a two-finger mash never throws a pair by accident;
  - **the first press is never delayed.** A light pressed first is kept: it lands 2 ticks after its press, its damage stands, and it counts toward the run. **A Y, a B or an A pressed first has only just started its wind-up, and the pair replaces it.** An X that arrives as the partner completes the pair, and is never thrown as its own light;
  - a kept light isn't too much for the prices: it adds one brawl light at most;
  - a pair is one press in the log;
  - **the ki price is the second guard** against a power attack thrown by accident;
  - **yes to the four one-key pair actions,** remappable, for keyboards and for one-handed play;
  - on the Simple layout the director throws the pair moves for the player.
- **A pair that lands is a real answer:** it clears the rival's run, as a skill strike does.
- **There are no charged pairs, and no pairs under RT.** A pair is a tap.
- **They are heavy commitments.** Two that meet, or one that meets a charged heavy or a signature, start a struggle.
- **The other stances** keep the same four meanings with their own moves, designed with each stance.

**Data:** `power.lift` (ki 10, tell 10, lift 36, worth 3), `power.slip` (ki 5, tell 4, step 2 bh), `power.breaker` (ki 20, tell 14, worth 6, knock-back 6 bh), `power.seize` (ki 20, tell 12, throw 12 bh).

## 7. The even mash, and the rest of questionnaire 19

**An even mash ends with a double hit: both land, both are thrown back, and nobody wins.** Orb, in questionnaire 19 and then on this page's question 5: "double knockbacks should be slightly uncommon, but exciting developments when they happen. Potential for dynamic closeup PiP of, for instance, both characters punching each in the face, sending each flying in opposite directions."

| | The rule |
| :--- | :--- |
| **A lead in the trade** | At the trade's limit of 120 ticks, a lead of 2 or more in the runs takes the close, as now. After the limit, a lead of 2 takes it as soon as it appears |
| **A level trade** | Runs within 1 of each other at 120 ticks. The trade goes on |
| **The double hit** | A trade that is still level at **240 ticks,** which is 4 s of unbroken even trading. Both throw one blow at the same instant, and both land |
| **Its worth** | **4 brawl lights to each,** on the head. That is a skill strike's worth |
| **What follows** | Both are thrown back 6 bh from the centre, in opposite directions. Nobody has won a decisive exchange. The brawl ends, and each is free as his slide ends |
| **The mood** | The clash's 480 units |

- **Why 240 ticks.** With the limit alone, every even mash would end this way every 2 s, and it would be the default. A median brawl is about 3 s and the 90th percentile about 10 s, so a trade that stays level for 4 s is the slightly uncommon thing Orb asked for.
- **The band is for a player who presses, and not for the AI against itself.** It is re-based on C1 as built (`docs/director/brawl-c1.md`). Orb's "slightly uncommon" is about his own trades. Against the medium AI, a lights-only presser and a mixing presser each see 0.5 to 2 double hits a match, and at least one in 35 to 65% of matches. As built they see 0.3 and 0.2, which is under.
- **The AI against itself is reported, and none is in order.** Its strings are 3 to 5 blows and then a heavy or a guard, so no level trade between AIs lasts 240 ticks. Of about 18 that reach 120 ticks in twelve matches, none does.
- **It is measured now and tuned on C2a,** as the EP leans. Three strengths change how a level trade forms, so a number tuned today would be tuned twice.
- **The limit is not the lever.** One a match between AIs would need about 120 to 130 ticks, which makes the double hit the default again. The 240 stays, and it never goes under 180. The lever is the AI: at a share, it digs in when a trade is still level at the limit, and keeps trading until the trade breaks. First shares for C2a: 0.2, 0.35 and 0.5 by level, and half as much again for the rival, who doesn't give a level trade up (`digIn`).
- **The close-up is rationed.** Two players who only mash see a double hit about every 8 s: 21 a match in the even mirror. The rule stands for them. The inset plays for the first of a match, and after that no more than once in 45 s. The rest play in the main view.
- **The seeded draw and its momentum are withdrawn** (`flurry.momentum`, `melee-press-feel.md` §9d).

**The staged moment.** It plays live, with no pause, and it is the one place in an ordinary brawl that goes past 4 of 10.

| Who | What it needs |
| :--- | :--- |
| **Encounter** | It knows 8 ticks ahead: at 240 ticks both throw, and contact is 8 ticks later. It sends a cue with that tick, so the others can be ready |
| **Camera** | A picture-in-picture close-up of the two faces and fists, for about 40 ticks: it opens 6 ticks before the contact and closes as they part. The main view carries on beneath it. The split rig already draws a second pane. **The close-up replaces the impact push:** the main view takes no push at the contact, and starts pulling back on that tick to hold both slides. The inset may take a push of 3% inside its own frame, and the main view keeps half its usual shake |
| **Animation** | Two poses a fighter: his own straight blow to the face, in his own hands (a palm heel for the Protagonist, a fist for the rival), and taking one. The slide that follows exists |
| **VFX** | Sparks at the point of contact, and dust on the slides. Inside Legal's k04: no ring of rubble, cracks or lightning, and no flash over the whole body |
| **Audio and haptics** | A beat of quiet before it, then one hit. A strong pulse to both players |
| **UI** | The frame of the inset |

**What it does to the mirror.** I expected two even lights-only mashers to be a stalemate, and as built they aren't. A lead of 2 does appear between them after the limit, because each reel shifts the other's rhythm. So that mirror finishes: 20 of 20, with about 21 double hits and 14 closes a match, a median of 164 s, and 53.9 s from brink to KO. That is a better result than the one I ruled for, and it stands. Its first slot won 13 of 20, which 20 matches can't tell from even. QA reads it at 100, against 40 to 60% (§11).

**Three small things C1 found** (Encounter's limits, `docs/director/brawl-c1.md` §6):
- **The mood takes the clash's 480, and no more.** The two slides are knock-backs with no attacker, and the mood adds 180 for each today, which makes 840. A knock-back that nobody dealt feeds no mood. It is Simulation's line, and it can wait for its next change to the mood.
- **"On the head" stands as the rule.** The core picks a blow's region by its family today, so until a blow can name its region, the core's pick is what plays. That option is asked for now, with the third weight (§2).
- **The nudge's rate is the same up, down and across.** That stands.

| Orb's answer | The rule |
| :--- | :--- |
| The player nudges a launch, and the director stages it | As now: the stick leans it and the planner picks where it ends. The same holds for a throw, a tackle's line and a beam's aim |
| Zip chains: until ki runs out | No limit on a chain but ki. Each zip is paid for in full (`melee-press-feel.md` §2c) |
| Chasing your own launch | **A zip at a launched rival.** While his launch is in flight, LT with an attack button follows the body as drawn travel and lands a blow that sends him on, nudged by the stick. It costs a zip's price, 20 or 30 ki, so a chase lasts as long as the ki does |
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
| **X tapped** | A light, at once | 0 |
| **X mashed** | The light flurry: 5 to 10 blows a second | 0 |
| **X held** | The burst: eight blows in under a second, slowing as it goes | 0 |
| **Y tapped** | A medium, 12 ticks after the press | 2 |
| **Y mashed** | The medium flurry: 4 to 5 full blows a second | 2 a blow |
| **Y held** | A charged medium: full at 24 ticks, worth 3 to 4, no knock-back. It ends a charging heavy | 4 |
| **B tapped** | A heavy, 28 ticks after the press, armoured against lights. It staggers him in place | 5 |
| **B mashed** | The heavy flurry: about 2 hammer blows a second | 5 a blow |
| **B held** | A charged heavy: full at 44 ticks, worth 8 to 10, armoured, a knock-back, and a launch or a lift at full | 8 |
| **B tapped in an opening** | The launcher: it always lands and sends him, and it launches when it is ready (§3) | 5 |
| **X, Y and B in any order** | The mix-up: each press its own blow at its own pace | As above |
| **X, Y or B on the beat** | A skill strike: worth 4, 6 or 9 (§9) | 0, 2 or 5 |
| **A tapped** | The shove, after 12 ticks. Out of reach: a pick-up, a civilian, or the taunt | 0 |
| **A mashed** | The clinch. In it, A is a vicious blow and X, Y or B is the throw | 0 |
| **A held** | The tackle, into a crater | 10 |
| **X+Y** | The lift | 10 |
| **X+A** | The slip | 5 |
| **Y+B** | The breaker | 20 |
| **A+B** | The seize | 20 |
| **RT + B, held** | His art at 24 ticks, his signature at 48, his ultimate after that in acts 3 and 4 | 25, 45 or 75 |
| **RB + X, in reach** | The point-blank bolt (§5b) | 1 |
| **RB + Y, in reach** | The blast, with a knock-back of 4 bh (§5b) | 8 |
| **The stick** | Nudges the brawl's centre, leans the blow, and gives ground while the rival winds up or charges (§1) | |

**The ki prices, in one place.** Lights are free. A medium is 2 and a charged medium 4. A heavy is 5 and a charged heavy 8. The tackle is 10, and the pairs are 10, 5, 20 and 20. The stick's lean never costs anything. This is the answer to Combat's parked question on Y: it is the medium now, at 2.

**No press is ever silent.** Controls found that RT with X, Y or A reaches the intent as a special that nothing reads, and that the martial arts A does nothing, both without a word to the player. From now on a press on a cell that has no move in the stance he is in gives a `press_ack` of `empty` from Encounter, and UI shows it as a small grey tick on the button. The presses the brawl already refuses reach the HUD the same way.

**What carries to the other four stances.** The grammar does, and the moves are each stance's own:
- three strengths on X, Y and B, with a tap, a mash and a beat on each, a burst on a held X, and a charge on a held Y or B;
- A has a tap, a mash and a hold: a quick body move, a hold that escalates, and a charged rush;
- the four pairs keep their four meanings;
- the stick always moves him;
- LT with a button is still the zip, and it keeps its own section.

The energy arts stance already fits: a bolt, a heavy shot that charges when held, and the beam. The defensive and manoeuvre rows in `melee-press-feel.md` §10 stand until their slices, and are re-read against this grammar then.

## 9. What stands and what changes

| Built or cut | Stands | Changes |
| :--- | :--- | :--- |
| **B1 and its repairs** (live) | A light is a blow at once. The run, the close, the close guard, blows on a staggered fighter adding nothing. The brawl's worths and `brawl.damageMul`. The perfect block and the reversal in place, and the riposte | The magnetism (§1). **Y is the medium:** today's heavy strikes, on a 12-tick wind-up where they had 26. **B stops firing the beam** and becomes the heavy, on a new tier of blows. The ender rule goes. The level trade's draw goes (§7). `enderShare` becomes how often the AI ends a string with a charged heavy |
| **The zip's first slice** | All of it. LT + X is the zip strike and LT + Y the zip heavy, as built | Named again when the stances are re-read: with three strengths LT + Y is a zip medium and LT + B a zip heavy. Not now. **Its counters follow the strengths** (confirmed): an X in the tech window as built; a Y whose wind-up ends in the tech window is the tech counter; a B whose wind-up ends in the heavy window is the heavy counter. A slow blow counters by when it lands, and not by when it is pressed. **The zip heavy keeps the worth it is built at,** on a key of its own, since today's heavy strikes are worth half as mediums |
| **The skill strike as cut** | All of it for X: the beat point, the 4 ticks either side, the grade at the press, its worth of 4, the cleared run, the flow, the early and late rules, the pinned pose and the 10-tick return as the cue | It widens to all three. The beat follows any landed light, medium, heavy or skill strike. **On the beat, a wind-up is halved:** a medium skill strike lands 6 ticks after the press and is worth 6, for 2 ki; a heavy skill strike lands after 14, is worth 9, and is armoured as a heavy is, for 5 ki. Each adds 1 to the flow and clears the rival's run. "An ender at a flow of 3 launches" becomes "a charged heavy at a flow of 3 launches, at any charge". The showcase is subtle |
| **Timing on a charged blow** | | Only the just release, on a full charged heavy |
| **The lift and the juggle** (not built) | The juggle: up to five skill strikes, each worth less | The lift moves to X+Y, and to a full charged heavy with no stick |
| **Three blows stopping a wind-up** (not built) | | Withdrawn. A heavy's wind-up is armoured against lights, and mediums stop it only in its first 20 ticks |
| **The set guard** (not built) | A guard held 30 ticks is set, and a heavy breaks it | A medium doesn't break a guard. It chips double and tires it |
| **The signature tiers** | The prices, the shared cooldown, the struggles, the ultimate's acts | The defining signature is on RT + B and takes a hold (§5) |
| **The step strike on LT+X in reach** | The move | It is the slip, on X+A |
| **A's press and hold** (`melee-press-feel.md` §10) | The grab lockout, and the other stances' A cells | The martial arts row is §4 here |
| **An energy press in a brawl** (B1: spent as a link) | Its `press_ack` of `energy`, for the cells that still have no move in reach | RB + X and RB + Y in reach are blows (§5b) |
| **This page's first draft** | §1 and §7 | The quick heavy on a tapped Y, the charged light, B as Charge at close range, and "a quick move, then the charge from the same press" are all withdrawn |

## 10. Build order

C1 is unchanged and is being built. After it, the buttons come in two halves, so that Orb can play the three flurries as early as possible. This follows Encounter's split and the EP's order. A small test slice, C2t, follows C2a. It carries what Orb's four questions need and nothing else (§13).

| Order | Slice | What | What it needs |
| ---: | :--- | :--- | :--- |
| 1 | **C1** | **Control** (§1) and **the even mash** with its double hit (§7) | As ruled. Being built |
| 2 | **C2a** | **The taps and the flurries** (§2): Y as a 12-tick medium, B as a 28-tick heavy with its armoured wind-up, the tap rule read at the wind-up's end with its grace, the three flurries, the mix-up. **The burst** on a held X (§3). **B stops firing the beam,** and RT + B fires it as it does today | Combat: today's heavies re-tagged as mediums, and a first set of super-heavy pieces. Animation: the mediums re-timed to 12 ticks, the heavy's wind-up and blow, the burst at its new gaps, with the 10-tick set before its stream. Encounter: wind-ups on live ticks, a flurry for each button, armour, B off the signature. Controls: the hold points become wind-up lengths, with the grace. Legal: the new tier and the burst, seen drawn |
| 3 | **C2t** | **The test slice,** for Orb's four questions (§13). **Giving ground,** with a wound blow's reach (§1). **The stagger's half nudge** (§1). **The launcher** (§3). **Energy arts in reach:** the point-blank bolt and the blast (§5b). **The heavy's charge,** cut small (below) | Encounter: the five rules, and the AI's shares for giving ground, following and the launcher. Simulation: the stick as held, read in a stun. Animation: the heavy at a 14-tick wind-up, and two energy poses a fighter. VFX: §5b's list. Combat: the two energy pieces for each fighter. Legal: the two energy poses and the flash rate, seen drawn. QA: §13's rows |
| | | **Orb plays C1, C2a and C2t** | |
| 4 | **C2b** | **The holds** on Y and B (§3): the charged medium, what C2t leaves of the charged heavy (its rules on a guard, and the lift with no stick), the just release, the fresh and the set guard, the wrench. **The shove** on a tapped A (§4). The two settings: a latched charge, and charges off | Animation: charge poses and their flashes. Encounter: the charges, the guard rules, the AI's shove against a heavy. Controls: the tap on A, and the two settings. Simulation: the crippling blow's trigger. UI: the charge cue |
| 5 | **C3** | **The skill strike** on all three (§9) | As cut, with the halved wind-ups on Y and B |
| 6 | **C5** | **Signatures on RT + B:** the hold ladder, played live, the beam held and aimed by the player (§5) | Encounter: live staging. Simulation: ki by the second. Camera: no takeover on an art. UI: the two flashes |
| 7 | **C4a and C6a** | **The tackle** and the taunt's gamble (§4). **The lift, the slip and the breaker** (§6), with the juggle, and a heavy on a lifted rival as a launch (§3) | Controls: the hold on A, and the two-button reads. Camera: the tackle's line |
| 8 | **C4b** | **The clinch** with its vicious blows, its throw and the held fighter's half nudge (§4), and **the seize** (§6) | The largest: paired poses, a new kind for the generator, a held state in the sim. Legal and the rating: the vicious looks |
| 9 | **Z2** | The zip away, the chase of a launch, the signature zip | As planned |
| 10 | **H1** | The fire-on-the-move hybrid, LT + RB | The hybrid's cells and its tell |

- **The double hit's close-up can follow C1.** C1 ships the rule, and the picture-in-picture comes when Camera, Animation and VFX have it.
- **The armour is in C2a, and not with the charges.** It belongs to the heavy's wind-up, and without it the B flurry has nothing over the X flurry.
- **The heavy tier is built,** by the EP's call, which Orb gave it: 16 key sets first, with today's heavies standing in on B until it is posed.
- **C2a and C2t are built as one chain, in two steps** (Encounter's cut, `docs/director/brawl-plan.md` §10, which the EP accepted). C2a alone has nothing that separates the fighters, so its pacing rows would mean nothing.
- **Encounter's nine defaults for that chain are ruled,** each in its own place: §1 (a light from too far), §2 (what ends a medium's wind-up, a hold before the charges, the lunges, the close), §3 (the riposte and the reversal), §5b (energy held) and §9 (the zip's counters and the zip heavy's worth). All nine are confirmed. Two came with a change of mine: the leash is shorter, and a held energy press is its tap.
- **The heavy's charge comes forward into that chain, cut small.** Orb's second question is about an opponent charging up, and he will hold B himself and expect a charge. With wind-ups of 12 and 28 ticks only, the answer would be half honest.
  - **In:** a B still down at 32 ticks keeps charging. It is full at 44, with its flash. It goes 4 ticks after he lets go, and by itself at 70. It is armoured as its wind-up is. It is worth 8, rising to 10, for 8 ki: 5 at the press and 3 at tick 32 (Encounter's decision, confirmed). Without the 3 it goes at 32 as a tap. A clean hit knocks back, and at full it launches, aimed as the launcher is, with the planner's pick when there is no stick. Its reach grows to 1.5 bh past striking distance. A miss leaves him open for 20 ticks. The AI charges 0.15, 0.3 and 0.45 of its heavies by level, and lets go within 8 ticks of the flash.
  - **Out, and still C2b's:** the charged medium, the just release, the fresh and the set guard, the wrench, the shove, and the lift with no stick. On a guard a charged heavy is blocked as a tapped heavy is. A held Y goes by itself at 16 ticks, at a tap's strength.
- **Animation's earlier sizes** (`docs/animation/brawl-second-pass-view.md`) were for two strengths. The new tier of heavy blows is the largest new item, and it needs sizing again.

**Legal's screen of the first draft** (`docs/legal/brawl-screen.md`, RL-098 to RL-101) avoided nothing. Its rules stand here:
- the repeat rules count the whole string across X, Y and B, and not the button;
- at up to ten blows a second the smear follows the one limb that is striking, with at most two ghosts for each blow. The burst is faster than that, at fifteen a second for its first blows, so it needs its own look at;
- each charge flash is a thin ring or an edge flash, of 4 ticks or fewer, and never over the whole body;
- the player sees Charge and not ki, as the interface says it.

Still to be seen drawn: the tackle, the charged heavy's hold and its flash, the breaker and the seize, a three-hop zip chain and the LT + RB tell. New for Legal: the super-heavy tier, the burst, the vicious blows in a clinch, the point-blank bolt and the blast, and the flash rate of a mashed bolt.

## 11. The bands that move

| Row | Now | With this page |
| :--- | :--- | :--- |
| Press to contact | 2 ticks for a light | **By button:** X at 2, with 95% inside 4. Y at 12, never past 16. B at 28, never past 32. Every press starts its move within 10 ticks |
| A tap that is read as a hold, by device | Not a row | **New:** under 2% on a pad and a keyboard, and under 5% on touch. The lever is the grace. It covers X as well: a tap of X that throws a second light counts here, and the lever there is the burst's start |
| The burst against a mash over the same time | Not a row | **New:** 70 to 80% of the mash's damage. Never over |
| Each flurry against the one it beats, head to head | Not a row | **New:** X against Y, Y against B and B against X each win 55 to 75% |
| The masher against the medium AI | 35 to 50%, tapping X every 8 ticks | Kept for the X masher. **New, reported:** the Y masher, the B masher, the alternator and the player who only holds X. **The slower masher's fall is intended.** At a 10-tick gap he fell from 33 to 16 of 100 on C1, because a level trade no longer ends in a draw and the medium AI taps at 8. The draw doesn't come back: a slower tapper should lose a trade of lights. His answer is a heavy into the flurry, which arrives with C2a. Reported there: the 10-tick tapper who throws B when the AI's run on him reaches 2. If he is still under 25%, the lever is a spread on the AI's tap gap, 8 to 10 at medium, so that its pace isn't one number to fall short of |
| Presses of a scripted two-finger masher that read as a pair | Not a row | **New:** under 5% |
| A full charged heavy thrown into an X flurry lands | Not a row | **New:** at least 80% when the flurrier keeps flurrying. A shove ends a heavy at least 90% of the times it is tried in reach |
| The even lights-only mirror finishes | At least 95% | **Kept: at least 95%.** As built it finishes 20 of 20, by double hits and closes (§7). Its first slot wins 40 to 60%, read at 100 matches. Its double hits a match are reported: about 21 |
| An uneven mirror: 8 ticks against 10 | Not a row | **New:** it finishes at least 95% of the time, and the faster tapper wins at least 80%. Brink to KO at 25 to 50 s is read here |
| Level trades that change who has the momentum; wins from the first slot | 5 to 15%; 40 to 60% | **Retired** with the draw |
| A trade's break | Within 12 ticks of the limit, and always followed by a close within 24 ticks (a hard test) | **Re-based.** A break is always for a lead now. It comes at the limit, or on the tick a lead of 2 appears after it, with no bound but the double hit at 240. A close follows 85 to 95% of breaks, reported: a lead tends to appear as the other fighter stops landing, and then the trade lapses first |
| Double hits a match | Not a row | **New, for a presser against the medium AI,** lights only and mixing: 0.5 to 2, and at least one in 35 to 65% of matches. Measured on C1 at 0.3 and 0.2, and tuned on C2a by the AI's `digIn` (§7). The AI against itself is reported, and none is in order. Every trade still level at 240 ticks ends in one (a hard test) |
| The centre moves within 2 ticks of a stick, in every state where the stick works | Not a row | **New** (a hard test) |
| The centre's step in a tick | Not a row | **New (a hard test), read on the centre's speed:** the nudge never moves the pair more than 0.3 bh in a tick. **Reported beside it:** the ticks on which the pair's middle moves more than 0.3 bh because a strike placed its attacker. On C1 that is 0 to 2 in about 85,000 brawl ticks, the largest 1.01 bh. It isn't worth changing the attraction for. From C2t a press closes a gap over ticks (§1), and then no blow moves its attacker more than 0.6 bh in a tick (a hard test) |
| How far a held stick moves a brawl against a rival who holds none | Not a row | **New, reported,** as bh for each second |
| A brawl's median length | 2.5 to 6 s | **Re-read after C2b.** Strings no longer end by themselves, so I expect it longer: 3 to 8 s as a first band |
| Of the endings that separate: knock-backs and launches | 60 to 75% and 25 to 40% | **Re-read after C2b:** double hits are a third kind, and knock-backs now come from charges and throws |
| The time a failed option leaves him open | Not a row | **New:** at most 20 ticks (a hard test) |
| Ki spent a minute, by what it bought | Reported for zips only | **New, reported:** mediums, heavies, charges, power attacks, zips, signatures |
| A dead stick in a brawl | Not a row | **New (a hard test):** on no live tick of a brawl does a fighter's stick do nothing, unless he is knocked back, launched, lifted, thrown, carried, buried or in a staged moment |
| A held stick against the medium AI | Not a row | **New:** it moves the brawl at least 0.7 as far as against a rival who holds none. The AI holds against a player's stick on under 25% of the ticks he holds it |
| Giving ground | Not a row | **New.** Hard tests: while the rival winds up or charges, a fighter with his hands down moves within 2 ticks of his stick; started by tick 16, he is out of a tapped heavy that isn't followed, every time; followed from its first tick, never. Bands: the medium AI winds up or charges a medium or a heavy 4 to 10 times in a minute of brawl; a player's heavies miss the medium AI by its giving ground 10 to 25% of the time |
| The launcher | Not a row | **New.** A hard test: a B pressed in an opening lands and sends him, every time, and launches every time the launcher is ready. Bands for the scripted route (X every 8 ticks, and B on the stagger) against medium: it sends him in 50 to 75% of the brawls it is tried in, and launches in 10 to 25% of them; a first launch inside 30 s of the first brawl in at least 80% of matches. Launches a match at medium: 4 to 10 by the route's player, 4 to 8 on him, and 6 to 12 in all for the AI against itself. The first build read 16 and 12 (§3) |
| The match's length, the AI against itself | A median near 415 s | **Held:** a median of 400 to 450 s, and never outside 5:00 to 8:00. The first build's mean was 554 s, against 394 s on main for the same seeds, because launches had replaced knock-backs (§3). The collateral rows stand, and are read once the launches are in band |
| Energy in reach | Not a row | **New.** Hard tests: a point-blank bolt lands 2 ticks after its press; a clean blast knocks back 4 bh; no more than three full flashes in any second. Bands: 5 to 15% of the medium AI's brawl blows are energy; a blocked point-blank bolt reaches the core once the arms are at their cap. The bolt-only and mixed blaster rows are read again |
| Perfect blocks | 1 to 4 a minute at medium, 0.5 to 2 at easy, 2 to 5.5 at hard. Per 100 blows it fell from 2.47 to 1.42 as blows a minute rose from 100 to 168 | **The band is by the minute, and it stands** at all three levels. It is what a player meets, and it doesn't move with the mix of blows. **Per 100 blows is reported by strength,** and held as bands after the first three-strength baseline. At medium: lights 0.5 to 1.5, mediums 2 to 6, heavies 6 to 15. The total per 100 blows is retired as a band. If the AI's perfect block is a chance for each blow today, it should be rated by strength or by time, so that a faster brawl doesn't buy more of them |
| A shot on the way out drops a zipper | A drop row | **A rule and a hard test, with no band.** A real bolt can't reach him: his way out is 3 to 10 ticks and a bolt needs 6 to leave (QA). The test by an injected shot stands. In play it is a rare event: a shot already in flight when he leaves, or a mine on his line. Its count is reported, and none is in order. Nothing replaces it: a shooter's answers to a zip are on the way in and at point-blank, where they already are (`melee-press-feel.md` §2c). Encounter confirms it is barely reachable as built: only a shot already in the air does it, and a drop lands only within about 1 bh of the ground. The ruling stands, and the rule stays for mines |

## 12. Orb's answers, and what is still open

| The question | Orb's answer | Where |
| :--- | :--- | :--- |
| Walking out of a brawl | "if both players move their sticks in the opposite direction they should be able to walk out." It takes both | §1 |
| What ends a string | A held heavy ends it, and X+Y is the lift | §3, §6 |
| B | First a third kind of blow, "vicious or something similar". Then, on the buttons: "X=light, Y=med, B=heavy" | §2, §5 |
| A press that gives two attacks | "I don't like the idea of one button press equalling two attacks" | The whole page |
| A held X | "a high speed burst of low damage attacks that quickly slows down on a curve" | §3 |
| The heavy's armour | Deferred to the EP, who ruled it in two steps | §2 |
| The even mash | Both take a hit. "Slightly uncommon", and exciting, with a close-up | §7 |
| The cross-pad pairs | None. Y+A and X+B stay empty | §6 |
| Where vicious lives | "vicious inside the clinch is good, go with that." | §4 |
| The three flurries | "the flurries looked good to me, nothing stood out in particular, you have the call." | §2 |
| What Orb will test next | Four questions | §13 |

**Still open, for Orb:** how graphic vicious is, which decides the Cyborg's bite and any clawing or gouging. It waits for the rating question, and nothing before C4b needs it.

## 13. Orb's four tests

**Orb,** 2026-10-06: "Things I'll be looking for next time I test-run: 'can I move my character around during active combat?' 'can I move my character when the opponent is charging up an attack?' 'can I reliably launch my opponent?' 'do energy attacks look cool as part of close-range combos?'" These are the acceptance test for the next playable build. The before, on the build Orb played: QA reads a held stick as dead on 12,369 of 15,323 brawl ticks, which is 81%, all of them in the locked state.

| Orb's question | The answer | Where | Slice | What Orb should see | QA's check (§11) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Can I move my character around during active combat?** | Yes, in every state but a knock-back and its kind. The stick moves the brawl while he strikes, mashes, winds up, charges, guards and reels. A stagger and a clinch now keep half | §1, the state table | C1. The stagger's half is in C2t, and the clinch's in C4b | He holds a direction while mashing and the fight drifts that way at once. The AI doesn't hold it still | No live tick of a brawl with a dead stick outside the exception (a hard test). A held stick against the medium AI moves the brawl at least 0.7 as far as against no stick |
| **2. Can I move my character when the opponent is charging up an attack?** | Yes, and alone. He gives ground: his stick moves him and not the rival. He is out of a tapped heavy if he starts by tick 16 and the rival doesn't walk it after him | §1, giving ground | C2t, against wind-ups and the heavy's charge (§10) | The AI winds up a heavy, he pulls the stick away, and the blow cuts air in front of him. Then his medium punishes it | He moves within 2 ticks of his stick (a hard test). Out of an unfollowed tapped heavy from tick 16 every time, and never when followed. The medium AI winds up 4 to 10 times in a minute of brawl |
| **3. Can I reliably launch my opponent?** | Yes. A tap of B on a rival staggered by a close always lands and sends him, and it launches whenever the launcher is ready, which the ping says. It is ready at the start, and again 40 s after his last launch. The route is: mash X until he staggers, then B, and aim with the stick | §3, the launcher | C2t | The same three inputs send him every time and launch him whenever the ping sounds, and the stick decides where he goes | From an opening, every time the launcher is ready (a hard test). The scripted route sends him in 50 to 75% of the brawls it is tried in against medium, and launches in 10 to 25%. A first launch inside 30 s of the first brawl in at least 80% of matches |
| **4. Do energy attacks look cool as part of close-range combos?** | They can now be part of one. With RB held in reach, X is a point-blank bolt and Y is the blast, which knocks him back 4 bh. They chain into and out of blows with no gap | §5b | C2t | Punches, a palm shot that lights both fighters, the blast that carries him off, and bolts chasing him as he slides | The bolt lands 2 ticks after its press, and a clean blast knocks back 4 bh (hard tests). No more than three full flashes in a second (a hard test). "Cool" is Orb's to judge, against §5b's list |

**The build that can pass all four is C1, C2a and C2t.** Without C2t, the first question passes on C1 alone. The second is half there on C2a: he can nudge, and stop a heavy with a medium, but he can't get out of its way alone. The third and fourth fail: no launch can be made on purpose, and an energy press in reach does nothing. The heavy's charge is in that chain too, cut small (§10), so that the second question is answered against a held charge and not only a wind-up.

**What could still fail each one on the day,** with its rule in:
1. An AI that holds its stick against his. It is bound in §11.
2. An AI that never winds up a heavy, so the moment doesn't come, or one that always walks it after him. Both are shares in the AI's data.
3. A close he can't see. The stagger has to be plain to the eye and the ear, since it is the cue for B. UI may show the run as it fills.
4. Shots too small to notice, or a mash of them that strobes. §5b's list is the brief.
