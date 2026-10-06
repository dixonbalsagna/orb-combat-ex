# The brawl, second pass: control first, three strengths on three buttons, and a recast of A

Owner: Game Design. Dates: 2026-10-06, and revised the same day for three strengths. Orb played the live brawl on the evening of 2026-10-05, answered questionnaire 19, then this page's five questions, and then settled the buttons (`docs/ep/vision.md`, the last three sections). This page turns all of that into rules.

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
| A: a tap is a shove, a mash is a clinch into a throw, a hold is a tackle | Ruled as Orb sketched it, one move to a press. The vicious blows live in the clinch, for Orb to confirm | §4 |
| "just hitting B and getting locked into what feels like a beam-attack cutscene doesn't feel right" | B is the heavy. Signatures move to RT + B, take a hold, and play live | §5 |
| Two-button power attacks on adjacent buttons | X+Y the lift, X+A the slip, Y+B the breaker, A+B the seize | §6 |
| An even mash: "both thrown back, nobody wins", and both take a hit | A trade still level after 4 s ends in a double hit, with a close-up | §7 |

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
- **It moves smoothly.** The centre never moves more than 0.3 bh in one tick, whatever the two sticks add up to. Animation needs that for the drift to read (`docs/animation/brawl-second-pass-view.md`), and it is fed the pair's velocity while it drifts.
- **The brawl keeps the speed it began with.** Half of the fighters' closing speed carries on as drift for 20 ticks. Nobody is stopped dead.
- **The attraction is softer.** It holds each fighter at striking distance from the centre and no longer pins him to a point.
- **The stick still leans the blow** (`melee-press-feel.md` §13). So holding toward the rival drives him back with elbows and knees, holding away gives ground with kicks, and up and down climb or sink with rising and dropping blows. One stick does both jobs.
- **Every press is still a blow.** Nothing here delays or drops a press.

**Walking out takes both of them.** Orb: "if both players move their sticks in the opposite direction they should be able to walk out." When each holds his stick away from the other, within 45 degrees of straight away, for 12 ticks, the brawl lets go. It is free, and there is nothing to wait for after it. A blow thrown by either in those 12 ticks starts them again.

**The 12 ticks count while either of them guards.** Backing off behind a guard is the ordinary way to part, and a guard isn't an attack. They don't count while either has a blow on its way or an attack button held, or while either is reeling or staggered, when the core has cleared his stick anyway.

**My one-sided walk-out is withdrawn.** I had a fighter let go after 24 ticks of holding away with nothing landing on him. Orb's answer asks for both sticks, and I can't square the two: mine let one player end a brawl that the other wanted. One fighter alone still moves the brawl his way, at 0.4 of his speed with the rival drawn along. To leave alone he pays: the escape, a dodge, a zip away or a burst.

**Walking out and the escape don't collide.** Walking out is both sticks away with no boost. The escape is one fighter's boost held with his stick away: at once, at the dodge-cancel's price, as built. The nudge reads the stick alone, and the escape needs the boost.

**The centre and what is in its way** (ruled for C1).
- **A building's face stops it,** as Encounter has it. The centre doesn't pass through a building, whole, shell or rubble.
- **It isn't a dead stop.** The part of the nudge that runs along the face carries on, so the brawl slides along a wall, and a nudge upward takes it over the roof. Flight goes over anything, so nobody is cornered (pillar 1).
- **A drifting brawl never damages a building.** Orb's answer is that a building is scenery unless the rival is thrown through its shell. Only a throw, a tackle, a launch or a blast does that.
- **Being pushed against a face gives no bonus.** There is no pin and no wall hit in a brawl.
- The ground and a ridge stop the centre in the same way, and the two fight on along it.

**When the stick does nothing.** Only in these: a knock-back, a launch, a lift, being held in a clinch, being buried, and a set piece.

| His state | His nudge |
| :--- | :--- |
| Striking, charging, or reeling from a light | Full |
| Guarding | 0.6 of full, as a guard already slows him |
| Staggered | None. The core clears the stick in a stun, as it does today. A stagger is 12 to 20 ticks |
| Knocked back, launched, lifted, held, buried | None |

**What it gives the game.** Position is the player's job under pillar 2, and now he has it inside a brawl. The Protagonist's AI nudges a brawl away from a town, and the rival's nudges it toward one. A charged heavy can be walked into place before it is let go.

**Data:** `brawl.nudgeMul` 0.4, `brawl.nudgeRampTicks` 8, `brawl.carryShare` 0.5 for 20 ticks, `brawl.partTicks` 12 and `brawl.partDeg` 45, `brawl.nudge.guard` 0.6, `brawl.maxStepBh` 0.3, and for digital input `brawl.nudgeDigital` 0.4 to 1.0 over 12 ticks.

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
- **The run and the close don't change.** Every landed flurry blow of any button adds 1 to his run, and a reply takes 1 off. At a run of 4 his next blow staggers the rival in place.
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

- **For players who can't hold a button:** yes to both of Controls' settings. A latched charge: a tap starts the wind-up and the next press lets it go. And charges off: every press is a tap.
- **On the Simple layout** one button carries all three: let go before 12 ticks it is the light, from 12 it is the medium, and from 28 the heavy. The longer the hold, the heavier the blow, and still one blow to a press.

**The bands for press to contact, by button:** X at 2 ticks, with 95% inside 4. Y at 12 ticks, and never past 16. B at 28 ticks, and never past 32. On every button the move starts within 10 ticks of the press, which is the band Encounter already measures.

**Data:** `x` (contact 2, flurry gap 6 to 12, rate 0.10); `y` (wind-up 12, worth 2.5, flurry gap 12 to 16, rate 0.156, ki 2, reel 6, guard chip ×2); `b` (wind-up 28, worth 6, flurry gap 28 to 34, rate 0.214, ki 5, stagger 12, armour: light damage taken 0.5, mediums interrupt to tick 20); `read.windupGrace` 4.

## 3. Holding: the burst on X, and the charges on Y and B

### A held X is the burst

**Orb:** "X Light Hold should give a high speed burst of low damage attacks that quickly slows down on a curve." Lights never charge.

The press throws the light, as always. While X stays down, more blows follow by themselves, fast at first and then slowing.

| Blow | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Lands, in ticks from the press | 2 | 6 | 10 | 15 | 21 | 29 | 40 | 55 |
| The gap before it | | 4 | 4 | 5 | 6 | 8 | 11 | 15 |
| Worth, in brawl lights | 1 | 0.28 | 0.28 | 0.35 | 0.42 | 0.56 | 0.77 | 1.05 |

- **It is one move of eight blows, in under a second,** and it is worth 4.7 brawl lights in all. Each blow after the first is worth 0.07 for each tick of its gap.
- **It doesn't beat a mash or a timed string.** Over the same 55 ticks a mash is worth 6.3, so the burst is three quarters of it. A light and one skill strike are worth 5 in 32 ticks.
- **It is the easy option.** It settles the question of holding to flurry: a player who can't mash holds.
- Its blows reel the rival for 2 ticks each. Each one after the first adds half a point to his run, so if nothing answers it, the eighth blow is the close.
- Letting go stops it after the blow in hand. After the eighth he is open for 8 ticks. Any other press replaces it.
- A long tap throws a second blow at 6 ticks. That costs nothing: a blow from a held X is never worth more than a mashed one.

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
| Getting out of its reach: a dodge, a slip, a zip away | When it lands | It whiffs, and he is open for 20 ticks |
| A power attack or a signature | When they meet | Two heavy commitments meet (`melee-press-feel.md` §11) |

**So against a flurry:** a fighter who keeps tapping X into a full charged heavy takes it. Over the 48 ticks it needs, his lights do about 2.4 brawl lights through the armour, and then 10 come back with a launch. A rival mashing Y is the other case: he stops it in its first 20 ticks. The first playtest of the slice decides whether this holds.

**The just release** (Orb picked it) is on the heavy only: letting go within 4 ticks after the full-charge flash. His line is free 10 ticks sooner, and it adds 1 to the flow. It is kept subtle: no extra damage.

**The wrench.** A charged heavy that lands on a battered limb is the crippling blow, and breaks it. This is the one place a strike is vicious; the rest of that idea lives in the clinch (§4). Both are for Orb to confirm.

**He can nudge the brawl while he winds or charges** (§1).

**A failed option hurts 3 of 10** (Orb, questionnaire 19). A whiffed heavy leaves him open for 20 ticks. The rule for every flashy option: failing never leaves him open for more than 20 ticks, and never adds damage of its own.

**Data:** `burst` (gaps 4, 4, 5, 6, 8, 11, 15; rate 0.07; reel 2; run 0.5 a blow; open 8); `charge.y` (from 16, full 24, lands 4, worth 3 to 4, ki 4, reel 10, max 40); `charge.b` (from 32, full 44, lands 4, worth 8 to 10, ki 8, max 70, whiff 20); `charge.justTicks` 4; `guard.freshTicks` 30.

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

- **Vicious lives in the clinch. This is the default, and Orb is to confirm it.** Orb liked a "vicious" kind of blow: "headbutts, bites, clawing, gouging", by character. Every one of those is something done while holding someone. So it has no button of its own. In the hold, the stick aims at a region and each tap works on it. With the wrench (§3) it is how a player goes after one wound on purpose. The four fighters' looks, and what touches the rating, are in `pitch-third-blow.md`: the Protagonist's version is pointed and not cruel, and the Cyborg's bite is the one to settle.
- **The clinch is how a flying fighter takes control,** as Orb put it: no ground is needed.
- **No grab spam** stands (`melee-press-feel.md` §10). The clinch, the tackle, the zip tackle, the dive grab and the seize (§6) share the one lockout, and a thrown fighter can't be grabbed for 120 ticks.
- **The taunt is a gamble** (Orb picked it). Out of reach, a tap of A taunts for 45 ticks. Finished, it gives his meter its taunt gain and 10 ki. Hit before it finishes, he gets nothing and staggers for 12 ticks.

**Data:** `shove` (wind-up 12, push 3 bh, stagger on a heavy 8, lockout 45), `clinch` (reach 10, vicious blows up to 4, damage 0.5, wear ×3, max 45, throw 8 bh, tech 8), `tackle` (coil 16 to 36, max 50, range 6 to 12.5 bh, carry 6 to 16 bh, ki 10, whiff 20), `taunt.ki` 10.

## 5. Signatures move to RT + B

**Orb:** "just hitting B and getting locked into what feels like a beam-attack cutscene doesn't feel right, B needs a recast and its own unique moveset."

B is the heavy now, and it has its moveset. So the signature needs another place.

- **The fighter's defining signature is on RT + B,** the charging stance's B. That is where the control scheme first had it.
- **It takes a hold, which is its tell.** Held to the first flash at 24 ticks, it is his art, for 25 ki. Held to the second at 48, it is his signature, for 45. In acts 3 and 4, held 45 ticks more, it is his ultimate. Let go before the first flash, nothing fires: he gets the "not ready" cue and spends nothing. The tiers and prices are those of `melee-press-feel.md` §11.
- **Signatures play live.** An art has no pause and no camera of its own. A signature takes a pause of at most 1 s, and only when it lands clean. A struggle is staged as before. Finishers keep their staging, which the other player called "really cool".
- **The player keeps hold of it.** A beam lasts while B is held, up to its tier's length, and ends when he lets go. Ki is spent by the second as it fires. The stick nudges its aim. A melee art is a string that the player drives: each press is its next blow, and he can stop.
- **While he holds for it:** a blow that lands before the first flash ends it. From the first flash he is committed, and armoured against lights.
- **The other stances keep their own B:** the guard signature on LB + B, the movement signature on LT + B, and in the energy arts stance the beam, on a hold and live. The energy moves stay where they are: bolts on X and the heavy shot on Y.
- **Until a fighter's own art is authored,** RT + B fires the beam by these rules.
- The Charge burst, blast and flurry of this page's first draft are withdrawn. They were B as ki at close range, which Orb turned down for a blow of the body.

**Data:** `sig.hold` (art 24 ticks, signature 48, ultimate 45 more); `sig.livePauseMax` 60 ticks, on a clean hit only.

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
- **The band:** 0.5 to 2 double hits a match in AI matches, at least one in 40 to 70% of matches, and never more than 4 in one. The lever is the 240.
- **The seeded draw and its momentum are withdrawn** (`flurry.momentum`, `melee-press-feel.md` §9d).

**The staged moment.** It plays live, with no pause, and it is the one place in an ordinary brawl that goes past 4 of 10.

| Who | What it needs |
| :--- | :--- |
| **Encounter** | It knows 8 ticks ahead: at 240 ticks both throw, and contact is 8 ticks later. It sends a cue with that tick, so the others can be ready |
| **Camera** | A picture-in-picture close-up of the two faces and fists, for about 40 ticks: it opens 6 ticks before the contact and closes as they part. The main view carries on beneath it. The split rig already draws a second pane |
| **Animation** | Two poses a fighter: his own straight blow to the face, in his own hands (a palm heel for the Protagonist, a fist for the rival), and taking one. The slide that follows exists |
| **VFX** | Sparks at the point of contact, and dust on the slides. Inside Legal's k04: no ring of rubble, cracks or lightning, and no flash over the whole body |
| **Audio and haptics** | A beat of quiet before it, then one hit. A strong pulse to both players |
| **UI** | The frame of the inset |

**What it does to the mirror.** Two even lights-only mashers still never win an exchange from each other, so that mirror doesn't finish. They now wear each other down by double hits, and still nobody is opened for a finisher. That is the rule working: an even mash is a stalemate, and winning takes something better than mashing evenly. QA's rows change with it (§11).

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
| **The stick** | Nudges the brawl's centre, and leans the blow | |

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
| **The zip's first slice** | All of it. LT + X is the zip strike and LT + Y the zip heavy, as built | Named again when the stances are re-read: with three strengths LT + Y is a zip medium and LT + B a zip heavy. Not now |
| **The skill strike as cut** | All of it for X: the beat point, the 4 ticks either side, the grade at the press, its worth of 4, the cleared run, the flow, the early and late rules, the pinned pose and the 10-tick return as the cue | It widens to all three. The beat follows any landed light, medium, heavy or skill strike. **On the beat, a wind-up is halved:** a medium skill strike lands 6 ticks after the press and is worth 6, for 2 ki; a heavy skill strike lands after 14, is worth 9, and is armoured as a heavy is, for 5 ki. Each adds 1 to the flow and clears the rival's run. "An ender at a flow of 3 launches" becomes "a charged heavy at a flow of 3 launches, at any charge". The showcase is subtle |
| **Timing on a charged blow** | | Only the just release, on a full charged heavy |
| **The lift and the juggle** (not built) | The juggle: up to five skill strikes, each worth less | The lift moves to X+Y, and to a full charged heavy with no stick |
| **Three blows stopping a wind-up** (not built) | | Withdrawn. A heavy's wind-up is armoured against lights, and mediums stop it only in its first 20 ticks |
| **The set guard** (not built) | A guard held 30 ticks is set, and a heavy breaks it | A medium doesn't break a guard. It chips double and tires it |
| **The signature tiers** | The prices, the shared cooldown, the struggles, the ultimate's acts | The defining signature is on RT + B and takes a hold (§5) |
| **The step strike on LT+X in reach** | The move | It is the slip, on X+A |
| **A's press and hold** (`melee-press-feel.md` §10) | The grab lockout, and the other stances' A cells | The martial arts row is §4 here |
| **This page's first draft** | §1 and §7 | The quick heavy on a tapped Y, the charged light, B as Charge at close range, and "a quick move, then the charge from the same press" are all withdrawn |

## 10. Build order

C1 is unchanged and is being built. After it, the buttons come in two halves, so that Orb can play the three flurries as early as possible. This follows Encounter's split and the EP's order.

| Order | Slice | What | What it needs |
| ---: | :--- | :--- | :--- |
| 1 | **C1** | **Control** (§1) and **the even mash** with its double hit (§7) | As ruled. Being built |
| 2 | **C2a** | **The taps and the flurries** (§2): Y as a 12-tick medium, B as a 28-tick heavy with its armoured wind-up, the tap rule read at the wind-up's end with its grace, the three flurries, the mix-up. **The burst** on a held X (§3). **B stops firing the beam,** and RT + B fires it as it does today | Combat: today's heavies re-tagged as mediums, and a first set of super-heavy pieces. Animation: the mediums re-timed to 12 ticks, the heavy's wind-up and blow, the burst at its gaps. Encounter: wind-ups on live ticks, a flurry for each button, armour, B off the signature. Controls: the hold points become wind-up lengths, with the grace. Legal: the new tier and the burst, seen drawn |
| | | **Orb plays C1 and C2a** | |
| 3 | **C2b** | **The holds** on Y and B (§3): the charged medium, the charged heavy with its knock-back, launch and lift, the just release, the fresh and the set guard, the wrench if Orb confirms it. **The shove** on a tapped A (§4). The two settings: a latched charge, and charges off | Animation: charge poses and their flashes. Encounter: the charges, the guard rules, the AI's shove against a heavy. Controls: the tap on A, and the two settings. Simulation: the crippling blow's trigger, if the wrench is confirmed. UI: the charge cue |
| 4 | **C3** | **The skill strike** on all three (§9) | As cut, with the halved wind-ups on Y and B |
| 5 | **C5** | **Signatures on RT + B:** the hold ladder, played live, the beam held and aimed by the player (§5) | Encounter: live staging. Simulation: ki by the second. Camera: no takeover on an art. UI: the two flashes |
| 6 | **C4a and C6a** | **The tackle** and the taunt's gamble (§4). **The lift, the slip and the breaker** (§6), with the juggle | Controls: the hold on A, and the two-button reads. Camera: the tackle's line |
| 7 | **C4b** | **The clinch** with its vicious blows and its throw (§4), and **the seize** (§6) | The largest: paired poses, a new kind for the generator, a held state in the sim. Legal and the rating: the vicious looks |
| 8 | **Z2** | The zip away, the chase of a launch, the signature zip | As planned |
| 9 | **H1** | The fire-on-the-move hybrid, LT + RB | The hybrid's cells and its tell |

- **The double hit's close-up can follow C1.** C1 ships the rule, and the picture-in-picture comes when Camera, Animation and VFX have it.
- **The armour is in C2a, and not with the charges.** It belongs to the heavy's wind-up, and without it the B flurry has nothing over the X flurry.
- **Animation's earlier sizes** (`docs/animation/brawl-second-pass-view.md`) were for two strengths. The new tier of heavy blows is the largest new item, and it needs sizing again.

**Legal's screen of the first draft** (`docs/legal/brawl-screen.md`, RL-098 to RL-101) avoided nothing. Its rules stand here:
- the repeat rules count the whole string across X, Y and B, and not the button;
- at up to ten blows a second the smear follows the one limb that is striking, with at most two ghosts for each blow. The burst is faster than that, at fifteen a second for its first blows, so it needs its own look at;
- each charge flash is a thin ring or an edge flash, of 4 ticks or fewer, and never over the whole body;
- the player sees Charge and not ki, as the interface says it.

Still to be seen drawn: the tackle, the charged heavy's hold and its flash, the breaker and the seize, a three-hop zip chain and the LT + RB tell. New for Legal: the super-heavy tier, the burst, and the vicious blows in a clinch.

## 11. The bands that move

| Row | Now | With this page |
| :--- | :--- | :--- |
| Press to contact | 2 ticks for a light | **By button:** X at 2, with 95% inside 4. Y at 12, never past 16. B at 28, never past 32. Every press starts its move within 10 ticks |
| A tap that is read as a hold, by device | Not a row | **New:** under 2% on a pad and a keyboard, and under 5% on touch. The lever is the grace |
| The burst against a mash over the same time | Not a row | **New:** 70 to 80% of the mash's damage. Never over |
| Each flurry against the one it beats, head to head | Not a row | **New:** X against Y, Y against B and B against X each win 55 to 75% |
| The masher against the medium AI | 35 to 50%, tapping X every 8 ticks | Kept for the X masher. **New, reported:** the Y masher, the B masher, the alternator and the player who only holds X |
| Presses of a scripted two-finger masher that read as a pair | Not a row | **New:** under 5% |
| A full charged heavy thrown into an X flurry lands | Not a row | **New:** at least 80% when the flurrier keeps flurrying. A shove ends a heavy at least 90% of the times it is tried in reach |
| The even lights-only mirror finishes | At least 95% | **Retired.** It is a stalemate by rule (§7). Reported, with how it ends |
| An uneven mirror: 8 ticks against 10 | Not a row | **New:** it finishes at least 95% of the time, and the faster tapper wins at least 80%. Brink to KO at 25 to 50 s is read here |
| Level trades that change who has the momentum; wins from the first slot | 5 to 15%; 40 to 60% | **Retired** with the draw |
| Double hits a match | Not a row | **New:** 0.5 to 2 in AI matches; at least one in 40 to 70% of matches; never more than 4. Every trade still level at 240 ticks ends in one (a hard test) |
| The centre moves within 2 ticks of a stick, in every state where the stick works | Not a row | **New** (a hard test) |
| How far a held stick moves a brawl against a rival who holds none | Not a row | **New, reported,** as bh for each second |
| A brawl's median length | 2.5 to 6 s | **Re-read after C2b.** Strings no longer end by themselves, so I expect it longer: 3 to 8 s as a first band |
| Of the endings that separate: knock-backs and launches | 60 to 75% and 25 to 40% | **Re-read after C2b:** double hits are a third kind, and knock-backs now come from charges and throws |
| The time a failed option leaves him open | Not a row | **New:** at most 20 ticks (a hard test) |
| Ki spent a minute, by what it bought | Reported for zips only | **New, reported:** mediums, heavies, charges, power attacks, zips, signatures |

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

**Still open, for Orb:**
1. **Where vicious lives.** The default here is inside the clinch, aimed by the stick, with the wrench on a charged heavy against a battered limb (§3, §4). The other homes are in `pitch-third-blow.md`.
2. **How graphic it is,** which decides the Cyborg's bite and any clawing or gouging.
