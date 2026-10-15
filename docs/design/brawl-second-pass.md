# The brawl, second pass: control first, three strengths on three buttons, and a recast of A

Owner: Game Design. Dates: 2026-10-06, revised the same day for three strengths, and again for Orb's four tests (§13). Re-ruled on 2026-10-11 against the first chain as built (§14). The nine cells of §15 are the brawl's acceptance table (2026-10-12), and §16 is its tapped column: the perfect follow-up. Orb played the live brawl on the evening of 2026-10-05, answered questionnaire 19, then this page's five questions, and then settled the buttons (`docs/ep/vision.md`, the last three sections). This page turns all of that into rules.

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
- **What his stick does.** Any lean that doesn't point at the rival moves him alone, the way it points, and the rival isn't drawn along. A lean at the rival is the nudge, as always. Straight away he opens 1 bh in 12 ticks: 5 bh a second, the same for every fighter. Behind a guard it is 0.6 of that. It answers within 2 ticks, as the nudge does. (Encounter first built it as a straight line off, and the stick slice widened it: §14.)
- **What the rival's stick does.** It still nudges the centre, so he can aim his blow with it. Only its part toward the giver follows him, at 0.6 of the giver's rate. So a fighter can walk a wound blow after a rival who backs off, and the gap still opens, slowly.
- **A leash.** He opens no more than 2.4 bh past striking distance. That is what a light can close in its 4 ticks, and it is well inside the 4.5 bh where a brawl lets go. Giving ground never ends a brawl.
- **A wound blow has a reach,** read as it lands: striking distance and 0.5 bh more for a medium, 1 bh more for a heavy, 0.5 to 1 bh more for a charged medium as it fills, and 1 to 1.5 bh more for a charged heavy as it fills. Out of reach it misses, and he is open for 20 ticks (§3). At the very edge it misses too: a tie goes to the fighter who gave ground. Open means he can't guard, dodge, give ground or strike for those ticks, so a medium does punish it. After a medium's miss, tapped or charged, he is open for 12 ticks (§14, the seventh round).
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
- **It isn't a dead stop.** The part of the nudge that runs along the face carries on, so the brawl slides along a wall, and a nudge upward takes it over the roof. Flight goes over anything, so nobody is cornered (pillar 1). From the stick slice on, a pair pushed into a face or a steep slope goes up and over by itself (§14).
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
- **The AI doesn't cancel a player's nudge by habit.** It opposes his stick only for a reason of its own: its care for a town, or a wall behind it. Against the medium AI a held stick moves the brawl at least 0.7 as far as it does against a rival who holds none (§11). And on every tick a player's held stick moves the pair his way by at least half his own nudge, whatever the AI's stick or the carry say (`nudge.floor` 0.5). Two players who oppose still cancel.

**What it gives the game.** Position is the player's job under pillar 2, and now he has it inside a brawl. The Protagonist's AI nudges a brawl away from a town, and the rival's nudges it toward one. It reads each fighter's `care` for that: 0.8 for the Protagonist and −0.5 for the rival (`launch-pair-plan.md` §1). Both are 0.0 in the data today, so neither AI leans anywhere. A charged heavy can be walked into place before it is let go.

**Depth.** How a brawl drifts toward and away from the camera, and where it may stand in the band, is in `depth.md`. Nothing in this section changes for it: the stick moves the pair along the fighters' line, and that line may be angled in depth.

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
  - **the X flurry no longer beats the Y flurry** (re-ruled in §14's fifth round). A landed medium counts 3 toward the run, so a Y flurry out-runs lights. What beats it is a perfect block, a medium into its wind-up, and its price in ki;
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
| Worth, in brawl lights | 1 | 1 | 0.34 | 0.34 | 0.43 | 0.51 | 0.68 | 0.94 |

- **A tap of X never throws two lights.** My first table landed the second blow 6 ticks after the press, which needs the burst to start at 4. Taps run 3 to 6 ticks on a pad, 4 to 8 on a keyboard and 5 to 12 on touch. So at 4 nearly every keyboard and touch tap threw a second light, and at 8, as Controls built it, most touch taps still would. That breaks "one press is one attack" (the EP's finding, from `docs/controls/windup-read.md` §5).
- **So the hold is read on the same line as Y's and A's: 16 live ticks.** By Controls' model no pad or keyboard tap reaches it, and under 2% of touch taps do, which is inside the band for a tap read as a hold (§11). That figure is modelled and not measured. A hold now begins at 16 ticks on X, Y and A alike, and the energy stance's volley already sits there.
- **Until 16 ticks a held X is a tap:** one light, and then he sets himself for about 10 ticks. Let go in that time, nothing more is thrown. The set is the burst's tell, and the rival can answer in it.
- **It is still one move of eight blows in under a second,** and it is worth 5.2 brawl lights in all. The second blow is a full light, since it is the one he set. Each of the six after it is worth 0.085 for each tick of its gap (0.07 until §14's fifth round).
- **It doesn't beat a mash or a timed string.** Over the same 56 ticks a mash is worth 6.4, so the burst is 82% of it. A light and one skill strike are worth 5 in 32 ticks.
- **It is the easy option.** A player who can't mash holds, and gets about 85% of a mash at the same pace.
- Its blows reel the rival for 2 ticks each. Each adds a full point to his run, as a tap's does. It was half a point until §14's sixth round.
- Letting go stops it after the blow in hand. Any other press replaces it. After the eighth it goes on at a floor pace (below).

**After the burst, a held X keeps throwing** (re-ruled on the built chain, §14). As first ruled the burst ended after its eighth blow, and a player who only held X won 0 of 40. Nothing came until his next press, and any stagger threw the hold away.
- **A held X is the flurry played for him, in the shape Orb drew.** It opens as the burst and slows on the curve. From the eighth blow it holds a floor pace of one blow every 8 ticks, for as long as X is held and the brawl lasts. It waits a stagger out. It doesn't carry on once the two are parted: a new approach takes a new press (§14, the fifth round).
- **Each blow goes through a tap's own path** (Encounter's proposal, taken). A reel carries it, and after a stagger the hold picks up again at the floor pace. A new burst needs a new press.
- **It is worth 85% of a mash,** as the burst's blows are: 0.085 for each tick of its gap, against a mash's 0.10. It is never over a mash's.
- **The run.** Every blow of a held X adds 1, as a tap does.
- **One press is still one attack.** A hold is one press and one move. A tap is still one light.
- **Its blows can't be perfect-blocked** (new, §15): its rhythm changes with every blow.
- **Its row:** the player who only holds X wins 10 to 35% against medium. That sits under the masher's band, because holding is the easy option and should cost. The lever is the floor pace, between 8 and 12 ticks (`burst.floorGap`).

### A held Y or B keeps winding

**Orb:** "holding a button should charge up an attack. so a charged heavy should have benefits that a charged light attack doesn't." The held medium takes the job that the charged light had.

| | **Held Y: the charged medium** | **Held B: the charged heavy** |
| :--- | :--- | :--- |
| Charged from | 16 ticks: the wind-up and the grace | 32 ticks |
| Full at | 24 ticks | 44 ticks |
| It goes | 4 ticks after he lets go. Held to 40 ticks, it goes by itself | 4 ticks after he lets go. Held to 70 ticks, it goes by itself |
| Worth, in brawl lights | 3, rising to 4 at full | 8, rising to 10 at full |
| Ki | 4 | 8 |
| While he holds it | **No armour.** A medium or a heavier blow that lands on him ends it. A light doesn't: it does its full damage, and adds nothing to the rival's run, so a flurry of lights can't close on him while he holds it (§15; §14, the seventh round) | **Armoured,** as its wind-up is (§2) |
| A clean hit | The rival reels for 10 ticks. **At full he staggers for 12, as from a close** (§15). No knock-back | **A knock-back.** At a full charge, a launch that the stick nudges and the director stages, or a lift of 45 ticks with no stick |
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
- **It always lands, and it launches when the launcher is ready.** When it launches, the stick nudges the launch and the director stages it, as for every launch. After any launch of a fighter, the launcher rests on him for 40 s of fight time. **In that time the same B is the hammer:** it still always lands, as a full heavy worth 6, and the brawl goes on. It doesn't part them (re-ruled in §14's fourth round: as a knock-back it cost the launcher's player matches). The launching blow is worth 3 brawl lights, which is half a heavy for half the wind-up. The sixth round put it at 6, and the ninth put it back: at 6 the route was over both its edges, and the B masher halved. Either one costs a heavy's 5 ki. The launch's landing is the rest of its worth.
- **A B pressed early is kept.** Pressed in the 10 ticks before the stagger begins, it is held and thrown as the launcher, by §2's rule for a held press. So "X, then B" rolled off the closing blow works, and so does a B pressed on seeing the stagger. A kept B goes before any X pressed after it, so mashing on doesn't lose it (Encounter's decision, confirmed).
- **A held B loses the guarantee.** The stagger holds for the 14 ticks only. Held past that, it is a charged heavy like any other.
- **The staggered fighter keeps half his nudge** (§1), so he has a say in where he is launched from. Nothing gets him out: a stagger takes his buttons, as it does today.
- **A landed heavy doesn't open it.** My first rule let it, and then every heavy that landed was a launch 14 ticks later, for the AI as much as for a B masher.
- **The opening has a ping, and both players hear it** (the EP's ruling). It sounds only when a launch is ready, so no ping means the hammer. Local play shares its speakers, so the cue can't be private. It tells the defender that he is open as much as it tells the attacker to press B.

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
| The AI against itself, mean match | 554 s, against 394 s on main | A median of 360 to 480 s, with 400 to 450 s as the target |
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
  - the route's shares of brawls are reported and not banded (§14);
  - a first launch inside 30 s of the first brawl in at least 65% of matches, inside 60 s in at least 75%, and inside 120 s in at least 95% (§14);
  - the match's median inside 360 to 480 s for the AI against itself, with 400 to 450 s as the target. That is Orb's five minutes or more and acceptance test W3;
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

**Data:** `burst` (start 16, as `read.burstStart`; gaps 4, 4, 5, 6, 8, 11; the second blow worth 1; rate 0.085; reel 2; run 1 a blow; then a floor gap of 8); `charge.y` (from 16, full 24, lands 4, worth 3 to 4, ki 4, reel 10, max 40); `charge.b` (from 32, full 44, lands 4, worth 8 to 10, ki 8, max 70, whiff 20); `charge.justTicks` 4; `guard.freshTicks` 30; `launcher` (the openings, wind-up 14, worth 3, ki 5, held press 10, rest 40 s, flight ×1.0, and the AI's shares 0.15, 0.35 and 0.6).

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
| A clean hit | He reels for 4 ticks, and it adds 1 to the run | **As a string's ender, a knock-back of 4 bh** along the stick's lean, and the brawl ends. It is an ender when his run is 2 or more as it lands. Thrown cold, he reels for 6 ticks and nothing more |
| Mashed | The X flurry's pace and worth: one every 6 ticks at the fastest. About 10 ki a second, flat out | One every 12 ticks. Each is a medium of light until his run is 2 |
| On a guard | **It is a shot.** Half its wear goes to his arms up to their cap, and the rest reaches his core (`melee-press-feel.md` §9, blocked shots). A blocked blow never does | The same, and no knock-back |
| Against a heavy's armour | A light: it never interrupts, and does half | A medium: it interrupts until tick 20 |
| While it winds up | | No armour. Any medium or heavier blow that lands ends it |

- **Its job is one a fist can't do.** A guard soaks blows for ever and leaks shots, so energy is how a string gets through a guard without waiting to set it. And the blast is the quickest knock-back in the game, as a string's ender: 12 ticks, against the 48 of a full charged heavy. Both are paid for in ki, and RB held means no guard.
- **The blast is an ender, and not an opener** (re-ruled on the first chain, §14). As first ruled, a clean blast knocked back every time, and no light stops its wind-up, so a script that only blasted won 58 of 60. Now it knocks back only when his run is 2 or more as it lands, which is the old ender's rule. Bolts in reach count toward the run as fists do. Its knock-back counts as half a set-up, as a close does.
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

**Data:** `energy.reach.bolt` (worth 1, ki 1, reel 4, run 1), `energy.reach.blast` (wind-up 12, worth 2.5, ki 8, knock-back 4 bh at a run of 2 or more, half a set-up, reel 6 otherwise), `energy.reach.spill` (2 to 3 bh and 6 bh, drawn only), `energy.reach.flashEveryTicks` 20.

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
- **The band is for a player who presses, and not for the AI against itself.** It is re-based on C1 as built (`docs/director/brawl-c1.md`). Orb's "slightly uncommon" is about their own trades. Against the medium AI, a lights-only presser and a mixing presser each see 0.5 to 2 double hits a match, and at least one in 35 to 65% of matches. As built they see 0.3 and 0.2, which is under.
- **The AI against itself is reported, and none is in order.** Its strings are 3 to 5 blows and then a heavy or a guard, so no level trade between AIs lasts 240 ticks. Of about 18 that reach 120 ticks in twelve matches, none does.
- **It is measured now and tuned on C2a,** as the EP leans. Three strengths change how a level trade forms, so a number tuned today would be tuned twice.
- **The limit is not the lever.** One a match between AIs would need about 120 to 130 ticks, which makes the double hit the default again. The 240 stays, and it never goes under 180. The lever is the AI's `digIn`. As first ruled, it dug in when a trade was still level at the limit. On the first chain that moment never comes, so it is re-ruled (§14): it is decided as a trade starts, and at its share the AI matches his pace for that trade until the trade breaks or the double hit lands. First shares: 0.1, 0.2 and 0.3 by level, and half as much again for the rival, who doesn't give a level trade up. As built it is 0.3 at medium. Two AIs never both dig in to one trade, and the AI digs in only while the match has had fewer than 2 double hits and not within 45 s of the last (Encounter's, confirmed in §14). **Re-ruled in §14's fourth round:** the share is of matches and not of trades, at 0.3, 0.55 and 0.75, with 120 s between the two.
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
| **X held** | The held flurry: it opens as the burst, eight blows in under a second, and slows to one every 8 ticks for as long as it is held | 0 |
| **Y tapped** | A medium, 12 ticks after the press | 2 |
| **Y mashed** | The medium flurry: 4 to 5 full blows a second | 2 a blow |
| **Y held** | A charged medium: full at 24 ticks, worth 3 to 4, no knock-back. It ends a charging heavy | 4 |
| **B tapped** | A heavy, 28 ticks after the press, armoured against lights. It staggers him in place | 5 |
| **B mashed** | The heavy flurry: about 2 hammer blows a second | 5 a blow |
| **B held** | A charged heavy: full at 44 ticks, worth 8 to 10, armoured, a knock-back, and a launch or a lift at full | 8 |
| **B tapped in an opening** | The launcher: it always lands. It launches when it is ready, and is the hammer when it isn't (§3) | 5 |
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

**The ki prices, in one place.** Lights are free. A medium is 2 and a charged medium 4. (The medium's price is the Y masher's lever, and may go to 1: §14.) A heavy is 5 and a charged heavy 8. The tackle is 10, and the pairs are 10, 5, 20 and 20. The stick's lean never costs anything. **A press he can't pay for throws the strongest blow he can pay for:** a B becomes a medium, and with nothing a Y or a B becomes a light. Every press is still a blow. This is the answer to Combat's parked question on Y: it is the medium now, at 2.

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
| **The skill strike as cut** | All of it for X: the beat point, the 4 ticks either side, the grade at the press, its worth of 4, the cleared run, the flow, the early and late rules, the pinned pose and the 10-tick return as the cue | It widens to all three. The beat follows any landed light, medium, heavy or skill strike. **On the beat, a wind-up is halved:** a medium skill strike lands 6 ticks after the press and is worth 6, for 2 ki; a heavy skill strike lands after 14, is worth 9, and is armoured as a heavy is, for 5 ki. Each adds 1 to the flow and clears the rival's run. "An ender at a flow of 3 launches" becomes "a charged heavy at a flow of 3 launches, at any charge". The showcase is subtle. **Three skill strikes running close** (§15). **§16 moves the beat to the hit itself,** and renames the skill strike the perfect follow-up |
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
- **The heavy's charge comes forward into that chain, cut small.** Orb's second question is about an opponent charging up, and they will hold B themselves and expect a charge. With wind-ups of 12 and 28 ticks only, the answer would be half honest.
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
| The burst against a mash over the same time | Not a row | **New:** 80 to 90% of the mash's damage. Never over |
| Each flurry against the one it beats, head to head | Not a row | **New:** Y against B and B against X each take the first decisive exchange of a match at least 60% of the time. X against Y is reported: that edge is withdrawn (§14, the fifth round). There is no upper bound: two fixed scripts lock. It is read on the first decisive exchange because a B masher is out of ki after about 20 s. The first chain read 100%, 92% and 52% by matches won (§14) |
| The masher against the medium AI | 35 to 50%, tapping X every 8 ticks | Kept for the X masher. **New, reported:** the Y masher, the B masher, the alternator and the player who only holds X. **The slower masher's fall is intended.** At a 10-tick gap he fell from 33 to 16 of 100 on C1, because a level trade no longer ends in a draw and the medium AI taps at 8. The draw doesn't come back: a slower tapper should lose a trade of lights. His answer is a heavy into the flurry, which arrives with C2a. Reported there: the 10-tick tapper who throws B when the AI's run on him reaches 2. If he is still under 25%, the lever is a spread on the AI's tap gap, 8 to 10 at medium, so that its pace isn't one number to fall short of |
| The Y masher and the B masher against the medium AI | Reported | **New:** 20 to 50% each. No single button mashed beats medium more than half the time, and none is shut out. The first chain read 0 of 60 and 60 of 60 (§14) |
| The player who only holds X, against the medium AI | Reported | **New:** 10 to 35%. It read 0 of 40 on the chain as built, and the held X is re-ruled for it (§3, §14) |
| Presses of a scripted two-finger masher that read as a pair | Not a row | **New:** under 5% |
| A full charged heavy thrown into an X flurry lands | Not a row | **New:** at least 80% when the flurrier keeps flurrying. A shove ends a heavy at least 90% of the times it is tried in reach |
| The even lights-only mirror finishes | At least 95% | **Kept: at least 95%.** As built it finishes 20 of 20, by double hits and closes (§7). Its first slot wins 40 to 60%, read at 100 matches. Its double hits a match are reported: about 21 |
| An uneven mirror: 8 ticks against 10 | Not a row | **New:** it finishes at least 95% of the time, and the faster tapper wins at least 80%. Its brink to KO is reported: the 25 to 50 s row is retired (§14) |
| Level trades that change who has the momentum; wins from the first slot | 5 to 15%; 40 to 60% | **Retired** with the draw |
| A trade's break | Within 12 ticks of the limit, and always followed by a close within 24 ticks (a hard test) | **Re-based.** A break is always for a lead now. It comes at the limit, or on the tick a lead of 2 appears after it, with no bound but the double hit at 240. A close follows 85 to 95% of breaks, reported: a lead tends to appear as the other fighter stops landing, and then the trade lapses first |
| Double hits a match | Not a row | **New, for a presser against the medium AI,** lights only and mixing: 0.5 to 2, and at least one in 35 to 65% of matches. Measured on C1 at 0.3 and 0.2, and at 0 on the first chain, where the AI's spread tap gap leaves no level trade. `digIn` is re-ruled for it (§7, §14), and the masher's band comes first. The AI against itself is reported, and none is in order. Every trade still level at 240 ticks ends in one (a hard test) |
| The centre moves within 2 ticks of a stick, in every state where the stick works | Not a row | **New** (a hard test) |
| The centre's step in a tick | Not a row | **New (a hard test), read on the centre's speed:** the nudge never moves the pair more than 0.3 bh in a tick. **Reported beside it:** the ticks on which the pair's middle moves more than 0.3 bh because a strike placed its attacker. On C1 that is 0 to 2 in about 85,000 brawl ticks, the largest 1.01 bh. It isn't worth changing the attraction for. From C2t a press closes a gap over ticks (§1), and then no blow moves its attacker more than 0.6 bh in a tick (a hard test). The test's bound is 0.62 bh, which allows the core's own step on that tick |
| How far a held stick moves a brawl against a rival who holds none | Not a row | **New, reported,** as bh for each second |
| A brawl's median length | 2.5 to 6 s | **Re-read after C2b.** Strings no longer end by themselves, so I expect it longer: 3 to 8 s as a first band |
| Of the endings that separate: knock-backs and launches | 60 to 75% and 25 to 40% | **Re-read after C2b:** double hits are a third kind, and knock-backs now come from charges and throws |
| The time a failed option leaves him open | Not a row | **New:** at most 20 ticks (a hard test) |
| Ki spent a minute, by what it bought | Reported for zips only | **New, reported:** mediums, heavies, charges, power attacks, zips, signatures |
| A dead stick in a brawl | Not a row | **New (a hard test):** on no live tick of a brawl does a fighter's stick do nothing, unless he is knocked back, launched, lifted, thrown, carried, buried or in a staged moment |
| A held stick against the medium AI | Not a row | **New:** it moves the brawl at least 0.7 as far as against a rival who holds none. The AI holds against a player's stick on under 25% of the ticks he holds it |
| Giving ground | Not a row | **New.** Hard tests: while the rival winds up or charges, a fighter with his hands down moves within 2 ticks of his stick; started by tick 16, he is out of a tapped heavy that isn't followed, every time; followed from its first tick, never. Bands: the medium AI winds up or charges a medium or a heavy 4 to 10 times in a minute of brawl; a player's heavies miss the medium AI by its giving ground 10 to 25% of the time |
| The launcher | Not a row | **New.** A hard test: a B pressed in an opening lands, every time, and launches every time the launcher is ready. **The route's player never reads more than 3 points under the same script's masher.** Bands for the scripted route (X every 8 ticks, and B on the stagger) against medium: its shares of brawls are reported and not banded, since the route's player has about ten long brawls a match (§14); a first launch inside 30 s of the first brawl in at least 65% of matches, inside 60 s in at least 75%, and inside 120 s in at least 95%. Launches a match at medium: 4 to 10 by the route's player, 4 to 8 on him, and 6 to 12 in all for the AI against itself. The first build read 16 and 12 (§3) |
| The match's length, the AI against itself | A median near 415 s | **Held:** the band is QA's, a median of 360 to 480 s, and 400 to 450 s is the target to tune to. The first build's mean was 554 s, against 394 s on main for the same seeds, because launches had replaced knock-backs (§3). The collateral rows stand, and are read once the launches are in band |
| Energy in reach | Not a row | **New.** Hard tests: a point-blank bolt lands 2 ticks after its press; a clean blast knocks back 4 bh; no more than three full flashes in any second. Bands: 5 to 15% of the medium AI's brawl blows are energy; a blocked point-blank bolt reaches the core once the arms are at their cap. The bolt-only and mixed blaster rows are read again |
| The blast-heavy script against the medium AI | 30 to 50% | **Kept.** The first chain read 58 of 60, and the blast is re-ruled as an ender (§5b) |
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
| **3. Can I reliably launch my opponent?** | Yes. A tap of B on a rival staggered by a close always lands, and it launches whenever the launcher is ready, which the ping says. When it isn't, the same B is a full heavy and the brawl goes on. It is ready at the start, and again 40 s after his last launch. The route is: mash X until he staggers, then B, and aim with the stick | §3, the launcher | C2t | The same three inputs land every time and launch him whenever the ping sounds, and the stick decides where he goes | From an opening, every time the launcher is ready (a hard test). The route's player launches 4 to 10 times a match against medium. A first launch inside 30 s of the first brawl in at least 65% of matches, inside 60 s in at least 75%, and inside 120 s in at least 95% |
| **4. Do energy attacks look cool as part of close-range combos?** | They can now be part of one. With RB held in reach, X is a point-blank bolt and Y is the blast, which knocks him back 4 bh. They chain into and out of blows with no gap | §5b | C2t | Punches, a palm shot that lights both fighters, the blast that carries him off, and bolts chasing him as he slides | The bolt lands 2 ticks after its press, and a clean blast knocks back 4 bh (hard tests). No more than three full flashes in a second (a hard test). "Cool" is Orb's to judge, against §5b's list |

**The build that can pass all four is C1, C2a and C2t.** Without C2t, the first question passes on C1 alone. The second is half there on C2a: he can nudge, and stop a heavy with a medium, but he can't get out of its way alone. The third and fourth fail: no launch can be made on purpose, and an energy press in reach does nothing. The heavy's charge is in that chain too, cut small (§10), so that the second question is answered against a held charge and not only a wind-up.

**What could still fail each one on the day,** with its rule in:
1. An AI that holds its stick against his. It is bound in §11.
2. An AI that never winds up a heavy, so the moment doesn't come, or one that always walks it after him. Both are shares in the AI's data.
3. A close he can't see. The stagger has to be plain to the eye and the ear, since it is the cue for B. UI may show the run as it fills.
4. Shots too small to notice, or a mash of them that strobes. §5b's list is the brief.

## 14. The first chain as built, and the follow-up tune

Encounter's chain of C2a, C2t and the heavy's hold is built and passes its gates (2026-10-11). These rows are out of band. Each is my rule or my number, and none is a fault in the build. Nothing here has been run: every new value is a first value for the follow-up tune.

| The row | Measured | The band | The ruling |
| :--- | :--- | :--- | :--- |
| Double hits a match, for a presser against medium | 0 | 0.5 to 2 | **The rule changes:** `digIn` matches his pace (§7). The band stands, and the masher's band comes first |
| The blast-heavy script against medium | 58 of 60 | 30 to 50% | **The rule changes:** the blast knocks back only as a string's ender, and that knock-back is half a set-up (§5b). The band stands |
| The B masher against medium, a press every 30 ticks | 60 of 60 | Reported until now | **A band, and the AI's levers:** 20 to 50% |
| The Y masher against medium | 0 of 60 | Reported until now | **A band, and a lever:** 20 to 50% |
| X over Y, Y over B and B over X, head to head | 100%, 92% and 52% | 55 to 75% each | **The band changes** to 60 to 90%, and each edge has its lever |
| A first launch inside 30 s | 71% of matches | 80% | **The band changes:** 65% inside 30 s, and 90% inside 60 s |
| The AI against itself: launches a match | 14.1 | 6 to 12 | **The levers,** as Encounter has them |
| The AI against itself: the match's median | 340 to 350 s | 360 to 480 s | **The lever is `wearPerDamage`** (below). `brawl.damageMul` was tried, and is back at 0.31 |

**The double hit.** The spread on the AI's tap gap restores the masher, at 45 of 100, and it also means a trade against the AI is never level for long. As I ruled it, the AI dug in only once a trade was still level at the limit, and that moment no longer comes.
- `digIn` is decided as a trade starts. At its share the AI matches his pace for that trade, blow for blow, and holds it until the trade breaks or the double hit lands.
- First shares: 0.1, 0.2 and 0.3 by level, and half as much again for the rival. The range at medium is 0.1 to 0.4.
- The masher's band comes first. If he falls under 35%, the share comes down, and the double hit against the AI is reported and not banded.

**The blast.** A clean blast was a decisive knock-back every 12 ticks, and no light stops it. That made it an opener, and I meant an ender (§5b has the rule).
- If the script is still over 50% with the rule in, the next lever is its price, from 8 ki up to 12.

**The one-button mashers.** No single button mashed should beat medium more than half the time, and none should be shut out. So the Y and B mashers take a band of 20 to 50%. The X masher keeps 35 to 50%.
- **The B masher** wins everything because the medium AI doesn't answer a wind-up it can see. The levers are the AI's, in order: its medium into a heavy's first 20 ticks, to 0.25, 0.5 and 0.75 of the heavies it sees by level; then its giving ground; then its perfect block against a heavy.
- **One check before that tune.** A heavy every 30 ticks costs 10 ki a second, and ki comes back at 5. The rule for a press he can't pay for is in §8: he throws the strongest blow he can pay for. If the build throws the heavy anyway, that alone may be the row.
- **The Y masher** loses everything because the X flurry beats it outright, and the AI mostly taps X. Its first lever is that edge, below.

**The three edges.** 55 to 75% was a guess that two scripts can't meet: two fixed rhythms give nearly the same result every time. The band is 60 to 90% for the flurry that should win. A lock at 100% leaves the loser nothing but a change of button, and 52% is no edge at all.

| The edge | Measured | The lever | From, and to |
| :--- | ---: | :--- | :--- |
| X over Y | 100% | What a landed medium does to the run, as what it adds and what it takes as a reply (`flurry.runBy.medium`). Today it counts 1, as a light does, so two lights always outrun one medium | 1, toward 2. At 2 the trade is level and ends by the trade's own rules |
| Y over B | 92% | The tick until which a medium stops a heavy | 20, down to 14 |
| B over X | 52% | What a light does through the armour. Then: a light that meets the armour takes nothing off his run, if it does today | 0.5, down to 0.3 |

**The first launch.** 80% was a guess. The route's first launch needs a close, and how often a masher earns one is the brawl's own texture, which this row shouldn't bend. The band is 65% of matches inside 30 s of the first brawl, and 90% inside 60 s.

**Launches, and the match's length.** No objection to what Encounter is tuning.
- **Launches:** the AI's share of openings and its charge share are the right levers. The charge share is new to §3's list: a full charged heavy launches whatever the rest says, so it sits beside lever 2. The rest stays at 40 s until Orb has played it.
- **Length:** I first named `brawl.damageMul`. Encounter tried it, and it isn't the lever (below). The two halves are still read apart: the first brink (4:30 to 7:00) and brink to KO (45 to 90 s).
- **One band, not two.** The band is QA's, a median of 360 to 480 s. My 400 to 450 s is the target to tune to.

**The match's length, after Encounter's tune** (2026-10-11). Launches read 11.2 a match and the X masher 45 of 100, both in band, and the median is still 340 to 360 s. `brawl.damageMul` at 0.27 bought 5 to 12 s and pushed the masher to 56, so it is back at 0.31, and it isn't the lever.
- **Why the match is shorter.** The brawl is 40% of live time, against 31% on main. That share is inside its own band of 30 to 50%, where main's wasn't. So the fight is denser, as it was meant to be, and the same wear arrives sooner.
- **I don't accept 340 to 360 s.** Orb's answer was matches of five minutes or more, and QA holds that as a 10th percentile of 300 s. Before the chain it read 303 s in one arm, with the median at 419 s. A median 60 s lower puts a good share of matches under five minutes.
- **The lever is `wearPerDamage`,** 330 today. It scales the wear from every source alike, so it moves the first brink and leaves the win rates where they are. `brawl.damageMul` scales the brawl's blows only, which is why it moved the masher. It is the same lever that brought the 10th percentile back from 293 s on the riposte build.
- **Its steps:** 300 first, then 285. Not under 270 without reading limb breaks again.
- **What to read with it.** The 10th percentile at 300 s or more is the row that decides. The median inside 360 to 480 s, toward 400 to 450. The first brink inside 4:30 to 7:00. Limb breaks a match, which will fall a little.
- **If brink to KO reads under 45 s,** that half is set-ups and not wear. A close is half a set-up, and the launcher's blow now always follows it, so one close can be worth one and a half. The lever: the knock-back a resting launcher gives counts half, so a close and its knock-back make one.
- **The even mirror's brink row is retired** (QA's question). I derived 25 to 50 s when a level trade ended in a draw, and that rule is gone. The even mirror's brink to KO is read against the overall 45 to 90 s like any match, and at 56 to 66 s it is in. The uneven mirror's is reported.

### The second round, after the follow-up tune (2026-10-11)

Encounter's follow-up is on main (14ae38c9), with a stick slice after it. Its measures are in `docs/director/brawl-c2.md` §11, and QA's of the first chain are in `docs/qa/c2-chain-2e0f3b2.md`. Nothing below has been run: every new value is a first value.

| | The question | The ruling |
| ---: | :--- | :--- |
| 1 | Length: at `wearPerDamage` 270 the median is 381 s and the 10th percentile 264 s | **One more step of the same lever, then a lever for the short matches.** 255, with the floor moved to 240. Then the second breath's wait |
| 1 | Limb breaks at 0.21 to 0.29 a match, 90% of them arms | **Encounter's lever, taken:** `cripple.base` 0.03, then 0.04. For the arms, the light's pick |
| 2 | Digging in: `digInBoth` false, 0.3 at medium, `digInMax` 2 and `digInRestS` 45 | **All confirmed** |
| 3 | The stick slice: `nudge.floor` 0.5, the giver's stick, up and over, `nudgeShare` 0.3 | **All confirmed** |
| 4 | The B masher at 60 of 60, the Y masher at 0, and the three edges | **The order of levers is below.** The edges are read another way, and lose their upper bound |
| 5 | Six other rows out of band | **One waits for C2b, two change their band, three take a lever** (below) |
| 6 | `closing.step` at 0.609 bh once; five dead keys in the AI's loader | **The test's bound is 0.62 bh. No dead keys:** each is wired at the value the code plays today, or deleted |

**1. Length.**
- Each step of 15 has bought about 14 s at the 10th percentile and about 30 s at the median: 237, 252 and 265 s, against 316, 341 and 377 s. So the lever lifts the middle twice as fast as the short end. At 240 the 10th percentile would still read about 290 s, with the median at the top of its target.
- **So one step, to 255,** which should put the median near 410 s. The floor moves to 240. It stood at 270 for the sake of limb breaks, and they read 0.20, 0.17 and 0.21 across the three steps: they don't move with it.
- **Then the short matches get their own lever: the second breath's wait.** A short match is a one-sided one, and the second breath is what the trailing fighter has. It waits for 240 ticks of quiet, and a fight that is 40% brawl has few of those. The wait goes to 180 ticks, and then 150.
- **What QA reads with it:** the seconds a match that a second breath runs, before and after. If that figure is already large, the wait isn't the cause, and I rule again on what it shows.
- **Limb breaks:** `cripple.base` from 0.02 to 0.03, and 0.04 if they are still under 0.3 a match. It is a stopgap: the wrench replaces the roll in C2b.
- **The arms' 90%.** The legs aren't being battered. Today's heavy strikes went to the legs 3 times in 8, and as mediums they go there 9 in 32, while the AI throws mostly lights. The light's pick goes from 12, 4, 10, 6 to 12, 4, 8, 8. If the arms are still over 65%, `cripple.legWeight` goes from 0.8 to 1.2.

**2. Digging in.** All three of Encounter's additions are confirmed.
- **Two AIs never both dig in to one trade.** Without it they read 1.65 double hits a match and 6 in one.
- **0.3 at medium:** 0.61 double hits a match for a presser, with the masher at 47 of 100. Both in band.
- **No more than 2 from digging in, and none within 45 s of the last.** A steady presser read 10.3 a match without it, which isn't "slightly uncommon". Two players are not capped: between them it is the rule. The hard row of 4 in one match is for a match with an AI in it.

**3. The stick.** All of it is confirmed, and §1 is amended.
- **A player's held stick always moves the pair his way by at least half his own nudge,** whatever the AI's stick or the carry say. Two players who oppose still cancel.
- **The fighter who may give ground moves alone by any stick that doesn't point at the rival.** That is nearer my first rule than the straight line was, and it is more control.
- **At a building's face or a steep slope the pair goes up and over.** Flight goes over anything, and that was already the rule for a stick held up.
- **The dead-stick row stays a hard test.** It allows the first 2 ticks of a hold, which is the time the nudge has to answer. What is left of the 0.5% is named by cause in QA's row, and a cause that isn't in §1's exception is a fault.

**4. The mashers and the edges.**

*The B masher, at 60 of 60.* A medium only stops a heavy if it lands by tick 20, so it has to be pressed by tick 8. Nobody reacts that fast, and the AI's `mediumIntoHeavy` can only act when the timing happens to allow it. The answer to a heavy that a fighter sees is to get out of its way and punish the miss, to block it perfectly, or to be throwing mediums already. The shove, which is the answer made for it, is C2b's.

| Order | Lever | From | To |
| ---: | :--- | :--- | :--- |
| 1 | **New:** against a rival whose last two blows were heavies, the AI's strings are mediums at a share. This is the triangle, played by the AI | Not a key | 0.15, 0.4, 0.7 |
| 2 | `giveGround`, with the medium it already throws at a miss | 0.05, 0.2, 0.4 | 0.1, 0.45, 0.7 |
| 3 | **New:** its perfect block against a heavy it sees | Not a key | 0.05, 0.2, 0.4 |
| 4 | `mediumIntoHeavy` | 0, 0.2, 0.5 | 0.15, 0.5, 0.8 |
| 5 | Mine, and last: the heavy's price | 5 ki | 7 ki |

If he is still over 50% after the first four, the row is held as pending C2b, and the AI isn't bent further for it.

*The Y masher, at 0, and X over Y, at 100%.* One lever: `flurry.runBy.medium`, at 1.75 and not 2. At 2 a full-speed X flurry and a Y flurry are dead level, which makes a coin toss of an edge that should be X's. At 1.75 the X flurry still takes the trade at its limit, and a Y flurry out-runs lights that come slower than one in 7 ticks, which the medium AI's do. The trade's lead counts a medium the same way. If the Y masher is under 20% it goes to 2, and if he is over 50% it goes to 1.5.

*Y over B, at 95%.* No lever. The stop stays at tick 20.

*B over X, at 45%.* A light through the armour goes from 0.5 to 0.3. A light that meets the armour takes nothing off his run, if it does today.

*How the edges are read.* Two fixed scripts lock, and a B masher runs out of ki after about 20 s, since a heavy every 30 ticks costs twice what comes back. So a whole match between scripts measures the purse and not the edge.
- **Each edge is read on the first decisive exchange of a match,** when both are at full ki.
- **The band is at least 60%** for the flurry that should win, with no upper bound. A lock is in order between two scripts: the loser's answer is another button.

*Reported, and still to rule:* the player who only holds X reads 0 of 100, and the alternator 78 of 100. The first is the player the burst was made for.

**5. The other rows.**

| The row | Reads | The band | The ruling |
| :--- | :--- | :--- | :--- |
| Launches as a share of the endings that separate | 53.6% | 25 to 40% | **Waits for C2b,** whose throws are the knock-backs it counts on. Pending, and not a fail |
| A first launch inside 60 s | 79% | 90% | **The band changes:** 75% inside 60 s, and 95% inside 120 s. 90 was a guess |
| The route's launches as a share of its brawls | 84.3% | 50 to 75%, then 10 to 25% | **Retired, and reported.** The route's player has about ten long brawls a match, so a share of brawls says little. Launches a match is the band: 4 to 10 |
| Perfect blocks a minute at easy | 2.42 | 0.5 to 2 | **A lever:** the easy AI's perfect-block share, ×0.7 |
| The mood: Calm 46%, Frenzied 2.4%, Frenzied in act 4 8.2% | | 20 to 40%, 5 to 20%, at least 15% | **A lever, after item 4's tune.** The mood is a rate and doesn't wait for length. Today's heavy strikes fed it 120 each and feed it 40 as mediums. `impulses.brawlLight` from 13 to 16, with room to 20, and then `brawlMedium` from 40 to 55 |
| Acts 3 and 4 start at 139 s and 223 s | | 150 to 240 s, and 270 to 345 s | **A lever, now.** The acts come from damage, which the wear lever doesn't touch, and both came 0.74 as late as before. The ladder's two power rates take ×0.75: 0.0075 to 0.0056, and 0.0045 to 0.0034 |

**6. Small.**
- **`closing.step`:** the rule stays at 0.6 bh, and the test's bound is 0.62, which allows the core's own step on that tick. The slack isn't widened: that would let more through.
- **The dead keys.** A key the loader doesn't read tells a lie about the game. Each is wired at the value the code plays today, so nothing moves and the goldens hold, or it is deleted if no rule names it. `answerTicks` says 20 in data and plays 28: the data takes 28, and it becomes a lever. I don't choose 20 now, since a quicker AI moves every row.

### The third round, after the second tune (2026-10-12)

Encounter's second tune is built and lands as it is. Nothing below has been run: every new value is a first value.

| | The question | The ruling |
| ---: | :--- | :--- |
| 1 | The second breath's wait at 150 ticks reaches Orb's five minutes, and costs two rows | **No band moves. The wait goes back to 240, and the wear takes one more step:** `wearPerDamage` 240, with its floor at 225 |
| 2 | The player who only holds X wins 0 of 40, and no number fixes it | **The rule changes: after the burst, a held X keeps throwing** (§3). His row takes a band: 10 to 35%. One question goes to Orb |
| 3 | The launcher doesn't cost matches, like for like. Does it want a lever ready? | **One, held until Orb has played:** who may start the next exchange after a launch. The rest stays at 40 s |
| 4 | Is a shove's depth part held to the drift's cap? | **No.** A knock-back moves in all three axes at its own speed (`depth.md` §3) |
| | The Y masher at 2 of 60 | **A lever:** the medium's price, from 2 ki to 1 |
| | The AI's launches at 14.3 a match | **The band is a stand-in.** If length and collateral hold at 14, its top moves to 14. If not, the AI's shares |
| | The hard AI's perfect blocks at 5.82 a minute | **A lever:** its perfect block against a heavy it sees, from 0.4 to 0.3 |

**1. The second breath.**
- The EP's ruling for this build stands: Orb's floor of five minutes comes before my two rows.
- **But the wait wasn't the cause, and it isn't the right lever.** At 180 ticks the 10th percentile read 281 s, against 287 s at 240: nothing. At 150 it read 313 s by brute force: the second breath gives back 42% of the wear, where the band is a quarter. Wounds have to stay, or the wear means little. And a fighter who makes his own quiet is paid for it, which is the blast script's 37 of 60.
- **The wear lever has the last 15 s.** At 255 the 10th percentile read 287 s, better than I had worked out. Each step of 15 has bought 13 to 15 s there, so 240 should read about 300 s, with the median near 430 s.
- **The floor moves to 225,** which should read about 313 s and a median near 460 s. That is over my target and inside QA's band of 360 to 480 s. I would take a long median before a healed wound.
- **The 10th percentile needs more matches.** At 100 its error is about the size of the gap, which is why 180 read lower than 240. QA reads this row on 200.

**2. The held X.** The rule is in §3. What decided it:
- I had called the burst "the easy option" for a player who can't mash. As ruled it can't win a match, so that was untrue.
- Orb's words are "a high speed burst of low damage attacks that quickly slows down on a curve." They don't say it stops. A curve that slows to a pace and holds it is inside them, and it is what Encounter proposed from the other side: the flurry played for him, with the burst as its look.
- **One press is still one attack.** A hold is one press and one move. A tap is still one light, because the burst still starts at 16 ticks.
- **The price of holding is kept:** 70% of a mash's worth, and the slower pace.
- **On Simple nothing changes.** Attack is read by the length of the hold there, so a hold is a medium or a heavy.
- **The question for Orb, and only this one:** when the burst has slowed, should a held X keep throwing at the slow pace, or stop until it is pressed again? I have ruled the first. If Orb wants the second, the burst is a flourish and its row is retired.

**3. The launcher.**
- Like for like it doesn't cost matches: 14 of 100 with it against 12 without. My worry came from two different scripts.
- **What the measure does show is that a launch hands over the first move.** After one, the rival starts the next exchange 130 times of 166, and launches the route's player 6.8 times a match against 1.8. A launch should leave the launcher ahead.
- **The lever held ready:** after a launch from the launcher, the launched fighter can't start an approach until 45 ticks after he is free. He can move, guard, dodge and shoot. The launcher has no wait of his own.
- It isn't applied until Orb has played the rest at 40 s. If Orb finds launches too rare, the rest goes to 30 s. If too common, to 55 s. The rest doesn't come down while the AI's launches are over their band.

**4. A shove in depth.** The cap of 1.2 bh a second is on a brawl's drift: the push and pull, the carry and the ease home. A knock-back is one motion along the line, and its depth part goes with the rest of it. That holds for the shove, the blast, a charged heavy, a resting launcher and the double hit. It is bounded by how far it goes and by the faces.

**The three rows still out.**
- **The Y masher.** A medium every 12 ticks costs 10 ki a second and 5 come back, so in seconds he is throwing slow lights. The run isn't his limit any more. A medium at 1 ki makes a Y flurry cost what comes back. `flurry.runBy.medium` then goes back toward 1.75 if he passes 50%.
- **The AI's launches.** I set 6 to 12 as a stand-in for the match's length and the collateral. If the median, the 10th percentile and the collateral rows all hold with 14.3 launches, the band's top moves to 14. If any of them is out, the levers are the AI's: its share of openings from 0.25 to 0.15 at medium, and its charge share from 0.15 to 0.1.
- **The hard AI's perfect blocks.** The new share for a heavy it sees is the likely cause, at 0.4. It goes to 0.3.

## 15. The nine cells: the brawl's acceptance table

**Orb,** 2026-10-12: "I still like the way the held light-attack flurries, lets make sure every attack has some meaningful way to be utilized either held, tapped, mashed rapidly."

**The rule.** Each of the three attacks has a meaningful use in each of three ways of pressing. None of the nine is a trap, and none is a flourish. The brawl is accepted against this table. Nothing new in it has been run: every new value is a first value.

**What the three ways mean.**
- **Tapped** is one placed blow. It is placed in time, on the beat, or in a moment: a miss, a wind-up, an opening.
- **Mashed** is a flurry at the button's own pace.
- **Held** is one press and one move that lasts. One press is still one attack.

### The nine roles

| | **Tapped** | **Mashed** | **Held** |
| :--- | :--- | :--- | :--- |
| **X, the light** | **The beat.** A light placed on the beat is a skill strike: worth 4, and it clears his run. A perfect B ends the chain, and the director shapes the ender. Off the beat it is the link between slower blows and the quickest punish. **For:** stopping his flurry without out-mashing him. **Beaten by:** armour, a medium that lands in its wind-up, and a perfect block, which a steady beat invites (§16) | **The pressure.** It is free, it lands at once and it can't be read: four blows he doesn't answer, and the next one closes. **For:** making an opening. **Beaten by:** a heavy's armour, a skill strike, a charged medium held through it | **The easy pressure.** The burst, slowing on its curve to a pace it keeps. It is 85% of a mash for no effort, and its changing rhythm can't be perfect-blocked. **For:** keeping him busy while the stick moves the fight, and a rival who turns flurries. **Beaten by:** a mash, which out-runs it, and armour |
| **Y, the medium** | **The stop.** It ends a heavy in its first 20 ticks, and it punishes a miss: 16 ticks against the 20 he is open. On the beat it lands in 6 ticks and is worth 6. **For:** answering anything slow. **Beaten by:** a flurry of lights, which it can't out-run, and a heavy past tick 20 | **The grind.** The most damage and wear a second without armour. It chips a guard twice as hard, and it beats a flurry of heavies. **For:** the race to the brink, and a rival who turtles. **Beaten by:** a perfect block, since its drum roll is the plainest rhythm to read; a medium into its wind-up; and its price, which is all the ki he gets back | **The patient close.** A charged medium: lights don't stop it, and at full it staggers him as a close does. It ends any charge, always. **For:** closing through a flurry of lights, and punishing a rival who holds something. **Beaten by:** a medium, a fast mash that closes first, giving ground |
| **B, the heavy** | **The hammer.** In an opening it is the launcher. Thrown cold it trades through lights on its armour and staggers him. **For:** the decisive hit when he is open. **Beaten by:** a medium in its first 20 ticks, giving ground, a perfect block | **The advance.** Heavy after heavy. Lights don't answer armour, so his run climbs while theirs doesn't. **For:** walking through a masher. **Beaten by:** a flurry of mediums, giving ground and the punish, ki: it costs twice what comes back | **The big read.** A charged heavy: a knock-back with no opening needed, and a launch at full. **For:** making space, and punishing a rival who has committed to a flurry. **Beaten by:** a medium early, a charged medium always, giving ground, a fresh guard |

**No cell is another one made smaller.** Within a button the three differ by what the player brings: timing for a tap, effort for a mash, patience for a hold. Across buttons the mashes are the triangle of §2, and the holds answer it: a held Y goes through X's lights, a held B through anything light, and a held X through a perfect block.

### Today, and the gap

| Cell | Today, as built | The gap |
| :--- | :--- | :--- |
| X tapped | A light. The beat isn't built for any button | **The perfect follow-up, on all three** (§16, which re-rules §9's skill strike on Orb's anchor: the player's own hit), with one new rule: **three perfects running close.** The third staggers him for the close's 12 ticks, under the close guard |
| X mashed | The flurry. The masher reads 37.5% on one of QA's scripts and 12% on the other | None in the rule. QA says which script the band is read on, and all nine rows use that one |
| X held | The burst, and then nothing. The holder wins 0 of 40 | **The floor pace,** ruled in §3: one blow every 8 ticks through a tap's path, at 0.085 a tick. **New:** the held flurry's blows can't be perfect-blocked |
| Y tapped | A medium, 12 ticks | The beat, as for X |
| Y mashed | 2 of 60: he is out of ki in seconds | **The medium's price, 2 ki to 1** (§14). `flurry.runBy.medium` stays at 2 |
| Y held | **A trap.** It goes by itself at 16 ticks at a tap's strength, so it is a medium that lands late | **The charged medium, brought forward from C2b,** with two changes: lights don't end it, as they don't end a tap's wind-up; and **at full it closes.** Charged from 16 ticks, full at 24, worth 3 to 4, 4 ki |
| B tapped | A heavy, 28 ticks, armoured. The launcher in an opening | The beat, as for X: 14 ticks and worth 9 |
| B mashed | 12 of 60, with the AI's new perfect block against a heavy. It was 60 of 60 | On the edge of its band. A lever if it reads under 20% on 100 matches: that share at medium, from 0.2 to 0.15 |
| B held | The charge: from 32 ticks, full at 44, a launch at full | None to be meaningful. Its guard break, its just release and the wrench stay in C2b |

### Alone: a player who only ever does one thing

Each row is one script against the medium AI: he does that one thing and nothing else. None has to be the best, and none may be hopeless.

| Cell | The script | Band | Reads today |
| :--- | :--- | :--- | :--- |
| X tapped | An X on every beat | 40 to 75% | Not built |
| Y tapped | A Y on every beat | 40 to 75% | Not built |
| B tapped | A B on every beat | 40 to 75% | Not built |
| X mashed | An X every 8 ticks | 35 to 50% | 37.5%, or 12% |
| Y mashed | A Y every 12 ticks | 20 to 50% | 3% |
| B mashed | A B every 30 ticks | 20 to 50% | 20% |
| X held | X held down | 10 to 35% | 0% |
| Y held | Y held to its flash and let go, again and again | 10 to 40% | Not built |
| B held | B held to its flash and let go, again and again | 15 to 45% | Not read |
| The three mashed in turn | X, Y, B, a press every 12 ticks | 30 to 55% | 78%. **Out:** it takes no thought, and shouldn't beat medium this often |

- **The set, in one line:** timing out-earns effort, and effort out-earns ease. A player who times his taps should beat medium more often than not. A player who mashes one button should lose more often than not. A player who holds one button should lose most of the time, and still win some.
- A real player mixes the nine, and that should beat any one of them. The mindless mix is the row to watch for it.

**Each role has a row that proves it,** beside the match rows. Most exist: a flurry's close; each flurry against the one it beats; a B in a ready opening; a full charged heavy into an X flurry. New: a medium pressed by tick 8 stops a heavy every time; a medium lands inside a miss's 20 ticks at least 90% of the time; a full charged medium held through lights lands and closes at least 80% of the time when no medium answers; a full charged medium ends a charging heavy every time; no blow of a held X is ever perfect-blocked.

### The order for Encounter

| Pass | What | Reads after it |
| ---: | :--- | :--- |
| 1 | Levers already ruled: the held X's floor pace; the medium at 1 ki; `wearPerDamage` 240 with the second breath's wait back at 240; the AI's perfect block against a heavy to 0.15 at medium, if B mashed reads under its band | X held, Y mashed, B mashed; the match's length |
| 2 | Y held: the charged medium with its two changes. The held X's blows can't be perfect-blocked | Y held, X held, the mindless mix; the edges |
| 3 | The beat on all three, and three running close (C3) | The three tapped rows. Every masher row again, since the AI gets the beat too |
| 4 | After Orb has played: the launcher's first-move lever, and the rest | Launches a match |

C2b's remainder follows these: the shove, the fresh and the set guard, the just release, the wrench and the lift.

### What the player must be shown

The nine have to be learnable from the screen and the sound alone, and on the phone Attack is read by how long it is held.

| | Tapped | Mashed | Held |
| :--- | :--- | :--- | :--- |
| **UI** | The beat's mark on the button it follows. A press he can't pay for shows what will be thrown in its place | The run filling toward the close, and the launcher's mark when it is ready | A ring by the button: X's shows the burst spending and then its steady pace, Y's and B's fill to the flash. On Simple, one ring with marks at 12 and 28 ticks |
| **Animation** | The pinned pose and its return, which is the beat. The stop and the launcher each read as their own blow | The three flurry studies Orb liked: a blur of hands, a drum roll of full blows, hammer blows wound in plain sight | X's curve visible in the body, fast and then slowing to a pace. A held Y and a held B each with a pose of their own and a flash at full |
| **Audio** | A tick on the beat. A sound for the stop, and the opening's ping | Three impact classes, and a flurry mode that tells them apart by pace | The burst falling in pitch as it slows. A charge rising to a click at full, higher for Y than for B |

**On Simple** seven of the nine are on its buttons. A held X and a held Y aren't, because Attack reads a hold as strength. The hold-to-flurry setting gives the first. The second is the director's, as the pairs are.

## 16. The perfect follow-up: a tap on the hit

**Orb,** 2026-10-12: "yes, reward well-timed taps, if the player taps at the moment they land a hit they get a perfect followup --- please brainstorm if this could be improved".

This is the tapped column of §15. It replaces §9's beat point and its window: the anchor is now the player's own hit. The worths of 4, 6 and 9 and the halved wind-ups stand. Nothing here is built or run, and every number is a first value.

### The rule

1. **When a blow of his lands, a window opens.** It opens on a clean hit, on a blocked one, and on one that meets armour.
2. **A tap of X, Y or B inside the window is a perfect.** It throws the follow-up of that strength. The tap is the follow-up's press: one press is still one attack.
3. **A follow-up is a full blow with a short wind-up,** so its own hit comes a beat later and can be tapped in turn.

| The follow-up | Lands, after the tap | Worth | Ki | Its own bonus |
| :--- | ---: | ---: | ---: | :--- |
| **Light** | 10 ticks | 4 | 0 | The quickest link |
| **Medium** | 6 ticks | 6 | 0 | It stops a heavy at any tick of its wind-up, where a plain medium stops it only in its first 20 |
| **Heavy** | 14 ticks | 9 | 0 | Armoured. From a chain's second perfect it is the ender (§14, the tenth round) |

Every follow-up clears his run, as a skill strike did.

4. **The window is the hit.** It is counted in ticks as the player sees them, the hit's freeze included.

| The blow that landed | The window | Its length |
| :--- | :--- | ---: |
| A light follow-up | From 2 ticks before the hit to 5 after | 8 |
| A medium, plain or a follow-up | From 3 before to 6 after | 10 |
| A heavy, plain or a follow-up | From 3 before to 8 after | 12 |
| **A plain light,** thrown at once | From 6 to 12 after the hit, as its pose lets go | 7 |

- The quickest blow has the tightest window, and the slowest the widest.
- **The plain light is the one case that isn't on the hit.** It lands 2 ticks after its press, sooner than any hand can press again. So its hit holds its pose for 6 ticks, and the window is as it lets go. Every later hit in a chain has travel, and its window is on the hit.
- No window ends sooner than 5 ticks after its hit. That is what a tap aimed at the hit needs when the picture is 3 frames behind.

5. **A hand that is mashing never makes one.** A press under 9 ticks after a plain press is a mash press, whatever the window says: a flurry blow, at once. So a chain can't start from a mash, and a plain light's window is in effect 7 to 12 ticks after its hit. After a perfect the window alone decides, so a tap on a perfect medium's hit, 6 ticks on, counts. A masher keeps his flurry and never the perfects, and a tapper has the perfects and not the flurry's pace.
6. **An early press ends the chain, and not the string.** A press between a follow-up's throw and its window doesn't stop the follow-up. It lands, and the chain is back to nothing. A press after the window is a plain blow, and the chain is back to nothing.

### The chain

- **It counts perfects in a row.** It is the flow of §9, under its own name.
- **The chain has no fixed length** (re-ruled in §14's tenth round). From its second perfect, a perfect B ends it with an ender that the director shapes from the world. A perfect X or Y keeps it going. A soft limit makes a long chain pay less and break more easily.
- **Against a guard, the ender breaks it.** So timing matters when he blocks, and nobody is taught to stop.
- **Every perfect follow-up is free** (the tenth round, on Orb's note). The count of three and the double link are retired with the fixed close.
- **It ends** on a missed window, when a medium or a heavier blow lands on him in a follow-up's wind-up, when he is staggered, and 90 ticks after his last perfect.
- **The stick at the tap aims the follow-up,** by the stick map of §3, as it aims any blow. It does nothing more in depth: that question is with Orb (`depth.md` §8).

### What beats it

- **A perfect block.** A follow-up can be perfect-blocked, and a steady beat is the easiest thing to read. Timing answers timing. A perfect block of a perfect can open the duel of perfects (§14, the tenth round).
- **A stop.** A medium or a heavier blow that lands in a follow-up's wind-up ends it. A light doesn't.
- **Armour.** A winding heavy takes a perfect light at half and isn't stopped by it.
- **A dodge.** The follow-up misses, and he is open for 20 ticks.
- A guard alone doesn't: the third perfect breaks it.

### The EP's twelve, weighed

| | The idea | | Why |
| ---: | :--- | :--- | :--- |
| 1 | The window is the hit, by strength | **Kept** | With the plain light's one exception above |
| 2 | No wind-up, can't be perfect-blocked, a bonus by strength | **Changed** | Half a wind-up and not none: a follow-up needs travel, or its own hit comes 2 ticks after the tap and can't be tapped. It can be perfect-blocked: a chain needs an answer in its own language, and that edge is the held X's. The heavy gets no knock-back of its own: that is the close and the launcher |
| 3 | A chain that escalates, and the third closes | **Kept** | |
| 4 | Mashing must not earn it | **Kept, by another test** | A press before the hit can't be the test: a light's own press is 2 ticks before its hit. The test is 9 ticks since a plain press, so a chain can't start from a mash |
| 5 | Links between strengths | **Kept** | A link counts double. It doesn't answer the mindless mix by itself: that row falls only if a steady 12-tick hand makes few perfects, which is a proof row |
| 6 | The stick aims the follow-up, and leans the line in depth | **Half kept** | It aims. It doesn't turn the line, while depth steering is Orb's open question |
| 7 | A perfect on a blocked hit counts | **Kept** | The third breaks the guard |
| 8 | One rhythm for attack and defence | **Kept, as an aim** | The perfect block's windows are 8 ticks against a light and 10 against a heavy today. These are 8, 10 and 12. They are aligned when this is tuned, and they share one cue |
| 9 | One signal for the window and one for the perfect; Simple and phones; an assist | **Kept** | On Simple the release is the tap, as Controls has it. The assist widens every window by half, and is flagged as Simple's assists are |
| 10 | Fighters differ in their timing | **Kept, small** | A fighter's three follow-up times may differ from another's by 2 ticks at most. His windows don't, and his own don't vary from blow to blow, or the beat can't be learned. Both fighters share one set in the first build |
| 11 | The AI's rates, and what beats a chain | **Kept** | Below, and above |
| 12 | Rollback, flash, one press | **Kept** | The 5 ticks after a hit. A perfect's mark is a spark at the hand and a sound, and never a flash: at one every 10 ticks it would pass three a second. Only the close may flash |

### The AI

| | Easy | Medium | Hard |
| :--- | ---: | ---: | ---: |
| Windows it taps (`perfectShare`) | 0.1 | 0.35 | 0.7 |
| The longest chain it keeps | 1 | 2 | 3 |
| Follow-ups it perfect-blocks, of those it sees | 0.05 | 0.15 | 0.3 |

It never taps every window, and only the hard AI closes with a chain.

### Bands, and the proof rows

- **A player who taps every window,** one button only, against medium: 40 to 75% (§15). The levers are the three worths, and then the windows.
- **A player who makes two in three:** reported. He shouldn't read under his own button's masher.

| Proof row | Bound |
| :--- | :--- |
| A tap inside its window makes a perfect, and one outside doesn't | Every time (hard) |
| A hand at a steady 6 or 8 ticks | No perfect, ever (hard) |
| A follow-up lands at its time after the tap: 10, 6 and 14 ticks | Within 2 ticks (hard) |
| The third perfect running, clean; and on a guard | A close, every time; a broken guard, every time (hard) |
| A perfect block against a follow-up | Turns it, every time (hard) |
| A steady hand at 12 ticks, X, Y, B in turn | Under 25% of its presses are perfects. Its match row stays 30 to 55% |
| A script that taps at the seen hit, with the picture 3 frames late | At least 95% of its perfects |
| A perfect's mark | No full flash; three a second at most stands (hard) |
| The perfect block's windows beside these | Reported, until they are aligned |

### The order, inside pass 3

| Step | What |
| ---: | :--- |
| 3a | The window, the mash test, the perfect light, the chain's count, the cues |
| 3b | The perfect medium and the perfect heavy, with the medium's sure stop |
| 3c | The third closes, and breaks a guard; a link counts double; the AI's three rows |
| 3d | Later: a fighter's own times, and the perfect block's windows aligned |

### What the player must be shown

| | The window is open | The perfect is made | The chain |
| :--- | :--- | :--- | :--- |
| **UI** | A ring closing on the button that can follow | The ring snaps shut, in the fighter's colour | One, two, three marks. The third is the close's mark |
| **Animation** | The hit holds its pose. For a plain light the pose lets go at the window | The follow-up reads as a bigger blow than a mashed one, drawn back and thrown | The third is the close's pose |
| **Audio** | The hit itself is the cue. A plain light has a tick as its pose lets go | A bright note on the hit, one step higher for each in the chain | The third resolves the phrase, with the opening's ping |
| **Pad** | | A short pulse | A stronger one on the third |

On a phone a tap is a tap. With the Simple layout the release is what is timed.

### For Orb

1. **The quick light.** A light lands too soon after its press to be tapped on the hit, so its window is as the pose lets go, 6 to 12 ticks later. Every other window is on the hit. Is that right for the one case, or should a chain have to start from a medium or a heavy?
2. **A follow-up keeps half its wind-up.** A perfect heavy lands 14 ticks after the tap, and not at once. At once it would be a sure thing, and there would be no next hit to tap. Is a short wind-up the "perfect" Orb means?
3. **A perfect block can answer a perfect.** The other choice is that nothing but a stop or a dodge can.
4. **Mixing closes sooner.** A change of strength counts double toward the close. Wanted, or should three be three?

### The fourth round: two of QA's findings on the second tune (2026-10-12)

QA's two scripts now press at the same pace, so these are like for like. Nothing below has been run: every new value is a first value.

| | The finding | The ruling |
| ---: | :--- | :--- |
| 1 | The route's player, who uses the launcher, wins 13%. The same script's masher wins 35% | **The launcher costs matches, and it mustn't.** Two changes: the first move comes forward, and a resting launcher no longer parts the two |
| 2 | A steady presser of lights gets exactly 2 double hits in every match | **The lever is what `digIn` is a share of:** matches, and not trades |

**1. The launcher.**
- **Where the loss comes from.** He earns about 21 openings a match, and the rest lets him launch from 4. In the other 17 his B knocked the rival back. So he broke off his own pressure 17 times a match, for 3 brawl lights each, and handed over a fresh approach. After a parting the rival started the next exchange 130 times of 166. The masher stays in and keeps hitting.
- **The first move comes forward,** and it is wider than I first ruled. After a launch, a wall slam or a knock-back that his blow gave, the fighter who was sent can't start an approach until 45 ticks after he is free. He can move, guard, dodge and shoot.
- **A resting launcher is the hammer.** When the launcher isn't ready, B in an opening still always lands, at 14 ticks. It is a full heavy, worth 6, and **the brawl goes on.** It doesn't knock him back. So the route never breaks off his own pressure, and a parting comes only with a real launch.
- **The rule this protects:** a player who uses the launcher never does worse than the same player who doesn't. QA's row: the route's player against the same script's masher, within 3 points or above.
- The rest stays at 40 s until Orb has played it.

**2. Digging in.**
- **Why no share fits.** A share for each trade can't serve two players. At 0.3 the steady presser reaches the cap of 2 in every match, and a presser who varies reads 0.61 a match. Lower it far enough for the first, and the second never sees a double hit. A longer rest only spaces the same two out.
- **`digIn` becomes a share of matches.** It is drawn once as a match starts: this AI digs in during this match, or it doesn't. If it does, it digs in to the first level trade after the first 30 s, and at most once more, after `digInRestS`.
- **First values:** 0.3, 0.55 and 0.75 by level, and `digInRestS` 120. `digInMax` stays 2, and `digInBoth` stays false.
- **What that should read:** for any presser who trades, at least one double hit in about 55% of matches at medium, and under 1 a match on average. Both are inside the band.

### The fifth round: the nine cells, pass 1, as built in scratch (2026-10-12)

Encounter's numbers, 200 matches on the default arm unless said: a median of 442 s; X mashed 86 of 200; B mashed 19 of 60; Y mashed 3 of 60; X held 3 of 60. Nothing below has been run by me: every new value is a first value.

**Encounter's finding, which I take as a principle: what wins a match is the close, and not the damage.** The Y masher deals 9,026 against 9,326 and wins 3 of 60, because he closes 1.5 times a match and is closed on 37 times. So every cell needs its own way to a close, and a cell's row is moved by that way first and by its worth second.

| | The question | The ruling |
| ---: | :--- | :--- |
| 1 | Does a held X outlive its brawl and press as a tap out of reach? Does it wait a stagger out? | **It waits a stagger out: yes. It doesn't carry out of reach: no,** as the default. One question for Orb |
| 2 | The held pace at 8 ticks | **Yes** |
| 3 | The held X's worth, or its band | **The worth goes to 0.085 a tick,** and the band is also read against the same script's masher |
| 4 | `flurry.runBy.medium` at 3 | **Land it.** The X-over-Y edge goes, and what beats a Y flurry is restated |
| 5 | The ladder's rates one step back up | **Yes:** 0.006 and 0.0037 |
| 6 | The hard AI's perfect blocks | **A different lever:** its general share, ×0.9 |

**1. The hold.**
- **Through a stagger: yes.** It is §3's rule, and the core dropping a held button 27 to 32 times a match was working against it.
- **Out of reach: no.** A held X that lunges back in after the two are parted is an attack nobody pressed. Orb's rules are that every attack on screen matches a press, and that a hold is one press and one move. A new approach takes a new press.
- **The row's script changes instead.** The player who only holds X lets go and holds again when he has no hold running. That is one press for each approach, which is no more effort than a tap.
- **The carry may live in the hold-to-flurry setting,** which is off by default and is Controls'. That is the player who has asked the game to keep fighting for him.
- Encounter's numbers with the carry on stand in for the new script, which should read a little under them.

**2. The pace.** One blow every 8 ticks, inside my 8 to 12. At 10 he closes 11 times a match and at 8 he closes 27 times, and closes are what win.

**3. The worth.**
- **0.085 for each tick of its gap, for the whole held flurry,** where it was 0.07. That is 85% of a mash at the same pace. On Encounter's probe 0.07 read 7 of 120, 0.093 read 6 of 40 and 0.10 read 8 of 40, with the masher at 17 of 80. So 0.07 was a little under a third of the masher, and 0.10 was the masher.
- **It is never over 0.10.** A hold is never worth more than a mash.
- **The band is read two ways.** On QA's script it stays 10 to 35%. On any other probe the holder wins between a third and two thirds as often as that probe's masher. The second reading is the one that travels.
- **What holding still costs:** 15% of the worth, a pace he can't raise where a masher can reach 6 ticks, and the 16-tick set before each burst.
- "Can't be perfect-blocked" stays. It didn't move the row and wasn't meant to: it is the hold's own use against a rival who turns flurries.

**4. The Y flurry.**
- **`flurry.runBy.medium` is 3.** It reads 18 of 60 for the Y masher, with X at 78 of 200, B at 10 of 60 and a median of 470 s. At 2 a Y masher never closes against lights, and Orb's rule is that no cell is hopeless. That rule comes before my triangle.
- **The triangle loses one edge.** With a medium counting 3, a Y flurry out-runs a flurry of lights. So "the X flurry beats the Y flurry" is withdrawn (§2), and the edge row becomes a reported one.
- **What beats a Y flurry now:** a perfect block, since a drum roll every 12 ticks is the plainest rhythm in the game to read; a medium of his own into its wind-up; and its price, which is all the ki he gets back, so a Y masher has nothing left for a heavy, a zip or a signature.
- **What the X flurry is still for:** it is free, it lands at once, and it can't be read or stopped. It is how a fighter with no ki keeps pressing.
- **B mashed at 10 of 60 is just under its band.** The lever is the one already named: the medium AI's perfect block against a heavy, from 0.2 to 0.15.
- **The median at 470 s** is inside QA's band and over my target. If the 10th percentile has room, `wearPerDamage` goes back up one step, to 255.

**5. The acts.** 0.006 and 0.0037, for 83% of matches reaching act 4 before the first brink, and the acts at 106, 193 and 294 s. All inside their bands. My ×0.75 was a first value and it overshot.

**6. The hard AI's perfect blocks.** Its share against a heavy moved the row from 5.82 to 5.72, so it isn't the cause. The lever is the hard AI's general perfect-block share, ×0.9. The share against a heavy can stay at 0.3. The band doesn't move for a tenth of a block a minute.

**The granted lines:** `wearPerDamage` 240 and the second breath's wait back at 240 ticks, with the second breath giving back 23.0%. No objection: that is the ruling of the third round, and the give-back is under its 25% again.

### The sixth round: the chain as parked (2026-10-13)

Encounter's chain of the nine cells' first pass, the recipes hook and the fourth round is parked and gated, and lands as it is. These rulings are for the tune after it. Its numbers, 200 matches on the default arm: a median of 440 s, a 10th percentile of 324 s, act 4 before the first brink in 90.5% of matches, with `wearPerDamage` at 225. Nothing below has been run by me: every new value is a first value.

| | The row | Reads | The ruling |
| :--- | :--- | :--- | :--- |
| a | The route's player against the same script's masher | 14 of 100 against 50 | **Three things change, and the bound stays.** The pursuit is wanted. The route's script presses B in every opening. The launching blow is worth a full heavy |
| b | B mashed | 6 of 60 | **A lever:** what a landed heavy counts toward the run, at 4 |
| c | X held | 3 of 120, against a masher at 14 of 80 | **A rule change:** every blow of a held X counts a full point toward the run |
| d | Double hits for a steady presser | 1.18 a match, in 68% of matches | **A lever:** the medium AI's `digIn`, from 0.55 to 0.45 |
| e | Knock-backs' share; launches' share of partings | 21.2%; 63.2% | **One is retired and one waits for C2b,** on a new base |
| f | Perfect blocks a minute | 2.13 at easy, 5.93 at hard | **The bands move a little, and an order is added** |

**a. The launcher's route.** A player who uses the launcher must never do worse than the same player who doesn't. That bound stands: within 3 points, or above. It is far from met, and it is the main target of the next tune.
- **The pursuit is wanted.** While the first move is his, the launcher's attack press from beyond reach flies him in. Today a tap from the far band opens a taunt, so the first move I gave him was a move he couldn't take. It also keeps the launched fighter from a quiet 4 s and a second breath. It is pillar 3: an attack closes the gap.
- **It starts while the rival's launch is still in flight,** so he can arrive as the rival lands or lodges. It costs nothing. The zip at a launched rival, which hits him on and costs ki, is a different move and stays for Z2.
- **Outside the first move a far tap stays as it is today.** The taunt's home is A (§4). Whether a light in the far band should ever taunt is read with the stances.
- **The route's script is wrong for the rule.** QA's route taps B only on the ping, so the hammer never plays in it. The route is B in every opening: a launch when the launcher is ready, and the hammer when it isn't.
- **The launching blow is worth 6,** where it was 3. The hammer is worth 6, and a launch shouldn't hit softer than the blow that stands in for it.
- **If the route is still under its masher** with all three in: the launch's landing, ×1.25. The rest stays at 40 s until Orb has played it.

**b. B mashed.** `flurry.runBy` counts a medium as 3 and a heavy as 1 or little more, so a B masher's run barely moves and the AI's mediums empty it. A landed heavy counts 4: it fills the run, and his next blow closes. The close guard still spaces his closes 90 ticks apart. Range 4 to 6.

**c. X held.** At the pace and worth of the fifth round he still wins about a sixth as often as his masher. Each hold opens with a 16-tick set and then seven blows at half a run point, so in its first second a hold gains 4.5 toward the run where a masher gains 7.
- **Every blow of a held X adds a full point to the run,** as a tap's does. Unanswered, the burst then closes about 31 ticks after the press, which is where a masher at 8 ticks closes.
- The pace stays 8 and the worth 0.085. **If he passes two thirds of his masher, the worth comes down toward 0.07.** Ease should still cost.

**d. Double hits.** 1.18 a match is inside 0.5 to 2. Matches with at least one read 68%, just over 35 to 65%. The medium AI's share goes from 0.55 to 0.45.

**e. The partings.**
- **"Exchanges that end in a knock-back, of those that reach a launch decision" is retired.** A brawl has no launch decision for each exchange. It belonged to the planned exchange.
- **"Launches as a share of the partings" waits for C2b, as before, on a new base:** the brawls that end with the two parted, by a launch, a knock-back, a throw, a shove or a double hit. The hammer parts nobody, the ender is gone, and the throws, the shove and the breaker aren't built, so today nearly every parting is a launch.
- **Its band stays 25 to 40% for when C2b is in.** That figure is Orb's, from when a knock-back ended every string. If it can't hold beside a launcher that is reliable, it is a question for Orb then, and not a band I move now.
- **Partings a match, by kind, are reported** until then.

**f. Perfect blocks.** Easy and hard keep reading a tenth or two over their tops, whatever the last lever was. The brawl now has two wound-up strengths to read where it had one, so more perfect blocks happen at every level.
- **The bands:** 0.5 to 2.5 at easy, 1 to 4 at medium, 2 to 6.5 at hard.
- **An order is added, and it is what matters:** hard reads at least half again medium, and medium at least a fifth over easy. Today: 2.13, 2.86 and 5.93, which holds.
- No lever this time.

**Two findings, noted.**
- **The Y holder closes twice as often with the charged medium, and still wins 0 of 60.** So the principle of the fifth round needs its other half: a close wins for a fighter who can stay off the brink himself while he earns it. The Y holder takes every light in full while he charges. His first lever is the full charged medium's worth, from 4 to 5.5. If he is still under a tenth after that, his row is read on his proof rows alone, and I say so plainly: a held Y is an answer to lights and to charges, and may not be a way to play a whole match.
- **Buildings.** Wall slams read 0.10 a match from the default start and 0.76 from a crossing, at about 24 damage, which is a building's single hit: the ladder and the slam's doubling aren't in yet. Encounter's town levers take bodies into buildings from 1.67 to 4.17 a match from a crossing, which is inside the 4 to 8 of `buildings.md` at its lower edge, on 12 matches.

**The wear is at its floor.** 225 was needed because the hammer keeps a brawl going. The 10th percentile has 24 s of room. If the next tune shortens matches again, the lever is the hammer's worth, and not the wear.

### The seventh round: the held Y (2026-10-13)

Encounter followed every charge of QA's Y holder to its end (`docs/director/pending/nine-cells-pass2/README.md`): 345 charges a match. 28% miss because the AI gives ground. 25% come to nothing, most of them inside the 20 ticks he is open after a miss. 18% are cut by the AI's close, when its fourth light staggers him. 15% land and close. He takes 2,250 a minute and deals 700, and the worth of 5.5 changed nothing.

**What it shows.** The cell isn't doing what §15 says it is for. "Lights don't stop it" holds one light at a time, and then the fourth light closes on him and the stagger takes the charge. So even its proof row fails: a full charged medium held through lights lands and closes 15 times in 100, where the row asks 80. A charged blow also reaches only as far as a tap, so it is easier to walk away from than a heavy, though it is just as slow. Three of Encounter's four answers make the cell what it claims to be, and I take them. The fourth is the AI's.

| Order | What changes | Why |
| ---: | :--- | :--- |
| 1 | **While he holds a charge, the rival's lights add nothing to the rival's run.** They still do their full damage. A medium or anything heavier still ends the charge, and a close from anything else still does | "Lights don't stop it" has to include what lights add up to. This isn't armour: he takes every light in full, and armour stays the heavy's |
| 2 | **A charged medium's reach grows as it fills,** from 0.5 bh past striking distance to 1 bh at full, as a charged heavy's grows from 1 to 1.5 | A charge as slow as a heavy shouldn't be the easiest blow to walk out of |
| 3 | **A missed medium, tapped or charged, leaves him open for 12 ticks,** and a missed heavy for 20 as before | A medium is the smaller commitment, and its miss should cost less. Inside 12 ticks the punish is still a light |
| 4 | **The AI's giving ground against a charging medium** gets a share of its own, under its share against a heavy: 0.05, 0.25 and 0.4 by level | Encounter's lever |

- **The full charged medium's worth goes back to 4.** The worth wasn't the cause.
- **Then his alone row is read again.** If he is still under 10%, it is read on his proof rows alone, and I say so plainly: a held Y is an answer to lights and to charges, and not a way to play a whole match. Orb's rule asks that each of the nine has a meaningful use, and that use is in its proof rows.
- **The proof row that matters most:** a full charged medium held through a flurry of lights lands and closes at least 80% of the times no medium answers.

### The eighth round: Encounter's reads, one change at a time (2026-10-14)

Encounter read each change of the sixth round alone and in order, on main, on QA's same-cadence pair, 100 matches against the medium AI. Nothing below has been run by me: every new value is a first value.

| Step | The route's player | Its masher |
| :--- | ---: | ---: |
| QA's new route script: B in every opening | 61 | 50 |
| + the pursuit | 82 | 43 |
| + the launching blow at 6 | 76 | 44 |
| + a landed heavy counting 4 on the run | 78 | 39 |

**Orb's bar for tonight:** every face button's mash, timed press and hold "responsive, useful, and visually engaging each in their own way". Useful is read on each cell's proof rows, and on its alone row where the cell can carry a match. Responsive and engaging are §15's table for UI, Animation and Audio.

| | The question | The ruling |
| :--- | :--- | :--- |
| a | Does the route's bound want an upper edge? | **Yes.** The route wins 0 to 25 points over the same script's masher, and no more than 70% against medium. **The pursuit is parked.** The launching blow at 6 stays, and is read without the pursuit |
| b | A lever for B mashed that helps only the masher | **What a heavy counts is split:** 4 to the run of the fighter who lands it, 1 off the run of the fighter it lands on |
| c | The held Y: its proof rows only, or one more lever? | **Its proof rows only.** They pass, at 99.6% and 20 of 20 |

**a. The route.**
- **The script was the fault.** With B in every opening the route already beats its masher, 61 to 50. The bound that a launcher never costs is met before any change.
- **The pursuit makes it far too strong,** for both sides. The route goes to 82, and the masher falls from 50 to 43, because the AI pursues after its own launches. A habit the game cues with a ping shouldn't win four matches in five against medium.
- **The upper edge:** the route's player wins between 0 and 25 points more than the same script's masher, and at most 70% against medium. A launch should pay, and not decide matches by itself.
- **The pursuit stays built and switched off.** It is a good answer to "a far tap is a taunt". It comes back with the stances' re-read of the far band, if the route has room under its edge.
- **The launching blow stays at 6,** to match the hammer. If the route without the pursuit goes over its edge, the blow goes back to 3 before anything else moves.

**b. B mashed.** A heavy that counts 4 both ways drained his run as fast as it filled it, so he fell from 6 of 60 to 2: each heavy the AI landed on him emptied it.
- **Split the count:** a landed heavy adds 4 to the run of the fighter who lands it, and takes 1 off the run of the fighter it lands on. A heavy already staggers him for 12, which is its punishment. Emptying his run too was a second one.
- **It helps the fighter who lands heavies back to back,** which is the B masher. The AI's few heavies still add to its own run.
- **The next lever, if he is still under 20%:** a heavy thrown inside a B flurry, within 34 ticks of his last landed heavy, costs 3 ki where it costs 5. A heavy every 30 ticks costs twice the ki that comes back, so half his presses become mediums.

**c. The held Y is read on its proof rows only.** 243 of 244 full charges held through lights land and close, and against a masher of lights it is 20 of 20. It is the answer it was meant to be. Alone it wins 1 of 60, because 31% of its full charges miss when the AI gives ground, which is the counter it is meant to have. Its alone row is reported, and no lever follows it. Every other cell keeps its alone row.

### The ninth round: a correction, and the window (2026-10-15)

Encounter read B mashed again on 120 matches, and the eighth round as one build (`docs/director/pending/sixth-round/README.md`). Nothing below has been run by me: every new value is a first value.

**A correction to my eighth round.** I split the heavy's count because Encounter's interim had it draining the B masher. On 120 matches that was noise. Main reads 13 of 120; with the heavy's count both ways, 6; without it, 5; with my split, 5. The count makes no difference either way. What halved him was the launching blow at 6: back at 3 he reads 10 of 120. My ruling b rested on the wrong reading.

| | The question | The ruling |
| :--- | :--- | :--- |
| 1 | B mashed, re-ruled | **Its band's floor comes down to 10%, and its proof is its edge over the light masher.** One lever, held: a heavy inside a B flurry costs 3 ki |
| 2 | The window Encounter applies | **Encounter's recommendation, with `digIn` at 0.4.** The route at 27 points over its masher is accepted as inside noise |

**1. B mashed.**
- **What beats him is what was designed to.** He lands about 92 heavies a match. He deals 5,683 and takes 10,434, and he is launched about eight times. A B flurry is the slowest and plainest rhythm in the game. The medium AI perfect-blocks it, steps out of it and punishes the miss, which opens him for its launcher. Those are the answers §15 gives the B flurry.
- **Its alone row is 10 to 50%,** where it was 20 to 50%. Mashing the heaviest button against an AI that reads heavies should lose most matches. Under a tenth would be hopeless, and that is the line.
- **Its proof row is the edge it is for:** a B flurry against the lights-only masher's script takes the first decisive exchange at least 60% of the time. That is "B over X" of §11, read as it stands.
- **The heavy's count stays split,** 4 up and 1 down. It moves nothing that was measured, and it is the rule as written.
- **The lever held, if he is under a tenth:** a heavy thrown inside a B flurry, within 34 ticks of his last landed heavy, costs 3 ki where it costs 5. Only a fighter who lands heavies back to back ever meets it.

**2. The window.**
- **In it:** the pursuit off (built and parked); **the launching blow back at 3**; the heavy's count split; every blow of a held X a full point; the medium AI's `digIn` at **0.4**. At 0.45 it read 66 matches in 100 with a double hit, one over the band's top, and 0.4 is Encounter's next value.
- **The launching blow goes back to 3,** as my own order of the eighth round said. At 6 the route was over both edges, 72% and 32 points, and the B masher halved.
- **The route at 66% and 27 points over its masher is accepted.** It is inside the 70% edge, and two points over the 25-point one, which is inside noise on 100 matches. QA reads the edge on 200.
- **The masher's fall from 50 to 39 or 40** is inside his band of 35 to 50%. It comes from the split, the full point or `digIn`, and isn't yet isolated. QA isolates it in the first baseline after the window. It doesn't hold the window.

### The tenth round: Orb's answers on the brawl's feel (2026-10-15)

Orb answered homework 2 (`docs/ep/vision.md`, "Orb answers homework 2"). Most answers are "your call" with a note that sets the direction. They are ruled here in that spirit: rule of cool, without costing the player any agency. Nothing below has been run: every new value is a first value. Encounter builds it after the demo's window.

| | Orb's question, and note | The ruling |
| ---: | :--- | :--- |
| 1 | A chain from a light: "whatever works in favor of 'rule of cool' without negatively impacting player agency" | **Yes, by the held hit,** made to read as a moment |
| 2 | How quick is perfect: an instant heavy "could be worth investigating" if high-level players could explain its use | **Investigated.** No instant follow-ups in general. **One instant move is worth building later: the cash-in** |
| 3 | Perfect block against a perfect: "perfect responses back and forth escalating into an amplified knockback with potentially higher levels of destruction" | **The duel of perfects** |
| 4 | The chain's cap: "Give the choreographer leeway to dynamically decide combo enders and chains" | **No fixed length. A perfect B ends a chain, and the director shapes the ender from the world.** A soft limit, and no hard one |
| 5 | Charge for perfects: "at the very least, not expending energy" | **Every perfect follow-up is free** |
| 6 | The charged medium | **As built** (the seventh round) |
| 7 | The held X when the two are knocked apart: a "chase" that keeps agency | **The chase: his own send, his own press** |
| 8 | Rumble on a perfect | **On by default,** as Orb ticked. Hints 9 and 10 go to UI and Narrative to rewrite |

**1. A chain from a light.** A light lands 2 ticks after its press, so its hit holds and the window opens as the hand lets go (§16). Requiring a chain to start from a medium or a heavy would take the commonest blow away from the player, so the light stays a start.
- **For the cool of it:** the hit is seen to hold. The fist stays planted, his flinch hangs for a beat, and the striking hand takes a small shine while the window is open. It reads as a punch, a held breath, and the bang of the follow-up.
- **To start a chain in the middle of a flurry,** he stops mashing for a moment and taps on the let-go (§16's mash test). Changing from a mash to a timed tap is a choice the player can see himself make.

**2. "Instant", investigated.**
- **No instant follow-ups in general.** A follow-up with no wind-up lands 2 ticks after the tap, so there is no next hit to tap and the chain dies. An instant heavy can't be read or answered, which is what makes it sound like an exploit. Online, a window can't sit on the hit's own tick when the picture runs 3 frames late.
- **One instant move is worth building, as a choice with a price: the cash-in.** RT + B tapped inside a perfect window throws a heavy at once. It can't be perfect-blocked. It ends the chain. It costs 25 ki, an art's price. It launches if the launcher is ready, and is the director's ender (point 4) if not. Today a tap of RT + B does nothing but the "not ready" cue, so it needs no new input.
- **What a high-level player would say it is for:** ending a duel of perfects (point 3) before the other player wins it; cashing in a chain before it lapses, or before a reader has caught its rhythm; a sure hit on a rival on the brink. Each time he trades the chain's future and his ki for certainty.
- It is built after the perfect follow-up has been played (step 3e of §16), so that it can be judged against a chain that already feels good.

**3. The duel of perfects.**
- **How it starts.** When a perfect follow-up is perfect-blocked, the block doesn't stagger him as a plain perfect block would. It opens a window for the blocker, of the same length as a follow-up's. A tap in it is his own perfect follow-up, a riposte in kind, and it can be perfect-blocked in turn.
- **It escalates.** Each perfect block that is answered adds a level. Each level shows more: the sparks grow, the camera closes in, the sound rises a step, the pads pulse. From level 3, every block sends a shockwave out from the pair: glass goes from the buildings within 4 bh, and the ground cracks under them.
- **It ends in one of four ways:**
  1. **Someone misses the timing.** The last fighter to make a perfect lands it, and it is an **amplified knock-back**: a quarter further for each level, and it meets buildings as if his tier were one higher for every two levels, up to a finisher's (`buildings.md` §1).
  2. **Someone cashes in** (point 2). The cash-in can't be perfect-blocked, so it ends the duel on the spot, with the same amplified send.
  3. **It runs long.** From level 5, each window is a tick narrower, so a duel ends by itself.
  4. **Level 8.** Both fighters are thrown apart, as a double hit is, amplified at level 8, with destruction on both sides.
- **The perfect-blocked blows do only chip.** The pay is the ending: the amplified send and the world it breaks.
- **The mood** takes a clash's units at level 3, and again at each further level.
- **Who can do it.** Two players, and the AI by level: its share of riposting a perfect it has blocked is 0.05, 0.2 and 0.45. Its share of perfect-blocking a riposte is its share against a follow-up.
- **Collateral** is counted as for any knock-back: the fighter who sent him pays.

**4. The chain: no fixed length.**
- **The close at three is retired, and so is the double link.** A chain goes on for as long as the player keeps his perfects.
- **From the second perfect, a perfect B ends it with an ender.** The director shapes the ender from what is there: a building in the stick's direction and in reach (a wall slam, or a launch into it), height (a spike to the ground), open sky (an uppercut), and his state (near the brink, the biggest send there is). The stick picks the direction. The launcher's rest decides whether it may launch, and otherwise it is a knock-back or a wall slam.
- **A perfect X or Y keeps the chain going.** So the player decides when it ends and the director decides how it looks.
- **Against a guard,** the ender breaks the guard.
- **The soft limit, for fairness.** From the sixth link each link is worth 15% less than the one before, never under half. The defender's perfect-block window against a follow-up widens by a tick for each link past the fifth. A long chain is never stopped, but it becomes easier to break and pays less.
- **It still ends** on a missed window, a medium or heavier blow into a follow-up's wind-up, a stagger on him, and 90 ticks with no perfect.

**5. Every perfect follow-up is free.** No ki for a perfect light, medium or heavy. The cash-in is the one exception, because it is an instant move bought on purpose.

**6. The charged medium** stays as built in the seventh round.

**7. The chase.**
- **When.** His own blow has just sent the rival: a knock-back, a wall slam's rebound, the hammer's push, a blast. Not a parting the rival caused, and not a launch: chasing a launch stays the zip of Z2, with its ki.
- **How he chooses it.** He keeps X held through the send, or presses X in the first 20 ticks of the rival's flight. Either is his own press. Letting go, or not pressing, lets the rival go.
- **What it plays as.** He follows the flying body as drawn travel, inside Legal's travel floor and drawn every tick, and the brawl goes on in the air: a beatdown in mid-air. Each blow of it sends the rival 1 bh further along the stick's lean.
- **How it ends.** After six blows, or 90 ticks, or when the rival meets the ground or a building, which is a landing or a wall slam. A perfect B in it is an ender, as in any chain.
- **The rival's answers.** A tech in the air, by a guard press timed to the chaser's arrival, breaks the chase and leaves them in an ordinary brawl in the air. A perfect block of the arriving blow turns it. And the first move still holds: after the chase he can't start an approach for 45 ticks after he is free.
- **It costs nothing,** because it only follows a short send. It is tuned by feel in playtests, as Orb asked: the distance it will follow, the pace of its blows, and the tech's window are its levers.
- **It refines the fifth round.** A held X still never carries the player back in after a parting the rival caused. It does carry through a send that his own blow made.

**8. Rumble and the hints.**
- **Rumble on a perfect is on by default.** It pulses once on a perfect, and harder on an ender and on each level of a duel. A setting turns it off.
- **Hints 9 and 10,** for UI and Narrative to rewrite: Orb read neither. Hint 9 meant that if you hold B until the charge clicks and then let go, the blow knocks him back. Hint 10 meant that when his heavy misses, a medium punishes it.

**What changes in §16:** perfect follow-ups cost no ki. The chain has no count, and a perfect B ends it. The duel of perfects is a new answer to a perfect, beside the plain perfect block. The order gains two steps: 3e, the cash-in; and 3f, the duel of perfects. The chase comes with them.
