# Melee press feel: every press is a blow

Owner: Game Design. Orb approved the second melee prototype (`docs/ep/prototypes/melee-trade-v2.html`) and gave the direction this page turns into rules (`docs/ep/vision.md`, "the melee feel"):

> close up brawls should make fighters slightly 'magnetic' so they can trade continuous strings of blows without interruption. both players should feel like their attacks actually match a button press. mashers should see their fighter landing faster flurries the quicker they tap the attack, a player trying to tech timing combos should see his character landing flashy skill attacks that lapse into high speed flurries when they miss their timing, and the heavy attack should be reliable against a heavy guard opponent, or to set up chains of skillful juggle attacks.

It is built on the alchemy framework that exists: the press log, the timing grade, the flow count, the pieces and the blur cadence. **Every number is a starting value.** Ten questions for Orb are at the end (§14). The stances, the signatures and the rules for a generated moveset are §10 to §13.

## 0. What changes, in one paragraph

Today a close fight is an **exchange:** the director plans it from the attacker's first press, and the defender mostly watches. This spec replaces that, in the close band, with a **brawl:** both fighters throw blows at the same time, each on his own line, and each press is one blow. The director still chooses what every blow is.

**What it replaces:**

| Today | Becomes |
| :--- | :--- |
| An exchange owned by the attacker, in the close band | A brawl that both fighters are in (§1, §2) |
| A string of five blows with four link presses, set by the director | A string as long as the presses, closed by a heavy (§5) |
| Styles read from the mix of the last five presses (`agency-pass.md` §2) | Each press has its own kind: a mash blow, a skill strike or a heavy (§3 to §5). The flow count is kept |
| A mashed blur closes with a weak knock-back (`agency-pass.md` §13) | It closes with a stagger in place, which still counts as decisive (§3) |
| A lone heavy with the stick launches (`agency-pass.md` §18, earner 3) | A lone heavy lifts the rival for a juggle. Only a string's ender knocks back or launches (§5). **A question for Orb** |
| One landed strike before a heavy makes it an ender | Two: a combo is 3 to 5 hits |

Lunges, charges, blasts and everything at range are unchanged. A lunge or a charge that arrives starts a brawl.

## 1. Press to blow

**The brawl.** It starts when the fighters are within 3 bh and either presses attack. Each fighter then has his own strike line. Nobody waits for the other's string to finish.

| The press | Press to contact | How long the blow takes |
| :--- | ---: | :--- |
| **A mash blow** | **On the press:** 2 ticks at most | 6 to 12 ticks, by tap rate (§3) |
| **A skill strike** (on the beat) | 6 ticks | 30 ticks, ending on its beat (§4) |
| **A heavy** | 34 ticks: a 26-tick wind-up and 8 to land | 76 ticks |
| **A held heavy** | 8 ticks after the release. It is fully charged at 46 ticks of hold | 96 ticks |

**A press the fight can't honour at once:**

| His state | What the press does |
| :--- | :--- |
| In the middle of a blow | It is held for up to 10 ticks and thrown as the blow ends. Only the latest press is held |
| Mashing faster than blows can be thrown | The extra taps aren't queued. They set the flurry's speed (§3) |
| Reeling from a hit (4 to 12 ticks) | Held, and thrown as he recovers |
| Knocked back, launched or lifted | It isn't a strike. A dodge tap or the brake is what works there |

So in a brawl a press is either a blow within 10 ticks, or he is visibly unable to strike.

## 2. Magnetism

Fighters in a brawl are held together, so a string can't be broken by drift.

| Question | Rule |
| :--- | :--- |
| **Where it holds** | It switches on when a brawl starts inside 3 bh, and holds until they are more than 4.5 bh apart |
| **How strongly** | Recoil from a blow leans a fighter and doesn't move him. Any drift is pulled back toward striking distance at up to 0.5 bh a second. Walking with the stick is damped to 0.4 of normal, so tilting the stick aims a launch and doesn't wander him off |
| **What breaks it** | A launch. A dodge with the stick away. Boosting away. 60 ticks with no attack from either fighter |
| **What bends it** | A knock-back. The magnet lets go for the slide, and then **re-closes:** if either fighter holds toward or presses attack within 30 ticks of the slide ending, both are drawn back into reach by a short lunge of 12 to 20 ticks. If neither does, they are apart |
| **What doesn't break it** | A dodge with no direction, which is a sidestep inside the brawl. A guard. A stagger. A lift |

This is also the fix for the downtime Orb saw: a brawl is one continuous thing, and the AI's weave between exchanges (`agency-pass.md` §25) has nowhere to happen.

### 2b. The brawl replaces the exchange-and-cooldown rhythm

**What Encounter measured** on the live build, with a player pressing a light every 8 ticks against the medium AI for 66 minutes: no exchange is running for **22.7 s of every minute.**
- 10.8 s is a short gap after every exchange, a median of 0.37 s. That is the director's cooldown.
- 8.7 s is gaps of 2 s or more: flights (5.3 s), the AI holding guard at range (2.6 s) and escapes (0.4 s).
- Exchanges come 38 a minute and average 2.3 blows.

So the downtime is structural. It is short exchanges with a cooldown after each, more than the AI running away. Halving the cooldown only takes 22.7 s to 19.9 s.

**Inside a brawl, three things change.**

| Today | While a brawl holds |
| :--- | :--- |
| **The cooldown** after each exchange (0.25 s, plus 0.1 s per second of exchange, up to 0.6 s) | **None.** There is no exchange to cool down from. Each fighter's strike line runs on, and a press is a blow within 10 ticks (§1) |
| **The exchange's length,** 2.3 blows on average | **A brawl has no set length.** It runs until something in §2 breaks it. Inside it the unit is the string: 3 to 5 hits closed by a heavy, or a flurry closed by its stagger |
| **The AI re-picks its stance** every 0.7 to 1.6 s | **The AI picks an action at each of its beats,** when its current blow or guard ends: attack, guard, sidestep or leave. It doesn't re-pick on a timer |

**The AI's commitments inside a brawl:**
- once it attacks, it stays for at least one whole string before it may leave;
- it holds a guard for 20 to 60 ticks, and then it must attack, parry or push;
- leaving is a slip, capped at one in a row and three a minute (`agency-pass.md` §25);
- the circling ellipse and the backing-off bob don't run. Magnetism holds it at striking distance, and what is left of them is footwork in place.

**Outside a brawl:**
- the cooldown stays as it is after a brawl ends in a launch, and at range;
- after a knock-back there is no cooldown: the re-close can start as the slide ends (§2);
- the AI doesn't hold guard at range for more than 45 ticks unless a shot or a charge is on its way. After that it closes, fires or taunts.

**Targets.**

| Measure | Today | Target |
| :--- | ---: | :--- |
| Seconds a minute with nothing running (no brawl, exchange, flight or set piece in progress) | 22.7, with flights | **At most 12,** of which flights and recoveries are about 5 |
| The same, counting only time in the close band | Not measured | At most 6 |
| A brawl's length, median | An exchange of 2.3 blows | 6 to 12 s |
| Blows in a brawl before it breaks, median | 2.3 | 10 or more |

**The masher has to be re-measured.** Encounter found that with a shorter cooldown and an AI that stays in, the masher rises to 63 of 100 against the medium AI, over his 35 to 50% band. Two things in this spec pull him back: a mashed blow is weaker the faster it is thrown (§3), and the AI now guards, parries and pushes inside the brawl. If he is still over the band, the first number to move is how much of a brawl the medium AI spends guarding.

**The mid-band lunge gets a wind-up.** Today it moves on the press tick at 4,000 units a second, which is why Orb finds it hard to judge. It gets **6 ticks** of wind-up for a light and **10** for a heavy, shown as a crouch and a streak along its line. The travel stays at 20 ticks or less.

**The struggle's stray penalty** of −0.10 measures the same as −0.15 on every row, so it is applied as Orb chose (`agency-pass.md` §25).

### 2c. The approach: lunges and charges the defender can read

**What Controls found** (`docs/controls/lunge-control.md`). The sim fits a far charge into 60 ticks for a light or 84 for a heavy, and speeds the flight up to do it. A charge from 100 bh flies at 7,500 units a second, from 200 bh at 15,000, and from 600 bh at 45,000, against a nominal 4,000. That is why Orb finds a far attacker hard to judge.

**Pillar 3 is kept.** Controls proposed a range ceiling beyond which a press is only a taunt. The speed cap and the ceiling are right, but an attack that can't close the gap breaks "never out of range". So beyond the ceiling, a held press becomes **a pursuit:** a longer, slower approach that everyone can see.

| Distance | A tap | A held press |
| :--- | :--- | :--- |
| Inside the charge range | The taunt, as a challenge (`agency-pass.md` §1) | The charge |
| **Beyond the charge range** | The taunt | **A pursuit flight:** he flies at the rival at the capped speed for as long as it is held. When he comes inside the charge range, the charge starts by itself. Letting go at any time stops it, at no cost |

The attack still always closes the gap. From far away it takes seconds, in full view, and the defender has all of that time to answer.

**Controls' numbers, confirmed:**

| | Light charge | Heavy charge | Mid lunge |
| :--- | ---: | ---: | ---: |
| Top speed | 6,000 units a second | 4,500 | As now |
| Shortest flight | 30 ticks | 42 ticks | |
| Longest flight | 90 ticks | 108 ticks | 20 ticks |
| Charge range (speed by longest flight) | 120 bh | 108 bh | The mid band |
| Commit point, before contact | 15 ticks | 20 ticks | 4 ticks |
| Wind-up before he moves | 8 ticks | 16 ticks | 6 for a light, 10 for a heavy (§2b) |

- **Ease-out:** the last 12 ticks slow into the arrival, so the contact reads.
- These replace the charge flight times in `agency-pass.md` §12, and the 150 units a tick that §25 gave as a charge's top speed. Launches keep that cap.

**What the attacker can do on the way:**

| Control | Rule |
| :--- | :--- |
| **Cancel** | Before the commit point, letting go of the button stops the charge at no cost, for a light and a heavy alike. After it, only a dodge-cancel (15 ki) does |
| **Brake** | Holding Guard brakes him and brings his guard up as he stops. It costs ki at the air brake's rate, **20 a second,** which is about 4 ki for a charge at top speed |
| **Steer** | Up or down by as much as 4 bh over the flight. This replaces the 15 degrees in `agency-pass.md` §25 |

A heavy charge still shrugs off light blasts, and a light one is still stopped by any shot. That is now the difference between them, since both can be called off.

**What the defender sees:**
- **an engage ring** at the point where the charge will arrive, which turns red at the commit point;
- **an arrow at the screen's edge** when the charger is off screen;
- **the crouch and the streak** before a mid lunge moves (§2b).

**For QA:**
- no charge or lunge ever exceeds its top speed (a hard test);
- a far charge's flight is 30 to 90 ticks, or 42 to 108 for a heavy;
- the defender answers a charge (guards, dodges, meets it, fires or leaves) in at least 70% of AI matches' charges, as a sign that it can be read;
- match length, re-measured: slower charges added 80 s once before (`agency-pass.md` §12). The magnetic brawl means far fewer charges, since a knock-back now re-closes with a short lunge.

**Under the stances** (§10), added 2026-10-04:
- A lunge or a charge pressed without LT flies the straight line above, and costs no ki.
- **A piloted approach** is one pressed with LT held, and held through the flight. Steering lives there: up or down by as much as 4 bh, and the stick toward or away changes the speed by up to 20%, never over the top speed or under the shortest flight. It costs 12 ki a second, the boost's rate. Letting go of LT before the commit point stops it, as letting go of the attack does.
- So the steer row above applies to a piloted approach only.
- **The air brake moves to LT:** a hold brakes at 20 ki a second, and a tap techs. Holding Guard during his own charge still stops him into a guard.
- Controls proposed that a press beyond the charge range be a taunt only. That isn't taken: a held press there is the pursuit, as above, so that pillar 3 holds.

## 3. Mash: the faster he taps, the faster the flurry

- **The flurry follows the taps.** The time between blows is the time between taps, held between **6 and 12 ticks.** That is 5 to 10 blows a second.
- Taps slower than one every 12 ticks aren't a flurry. Each is a separate light.
- **Faster isn't stronger.** A blow's damage scales with its interval: ×0.6 of a light at 6 ticks, ×0.8 at 8, and ×1.0 at 10 to 12. So the damage per second is the same at every speed.
- **What speed buys:**
  - it reaches the flurry's closing stagger sooner;
  - it interrupts a heavy's wind-up sooner (§7);
  - it raises the mood faster.
- **What speed costs:** every blow is weaker, so a guard soaks more of it, and a perfect block ends it.
- **The close.** After four flurry blows land in a row with nothing landed in reply, the next blow **staggers** the rival for 12 ticks. He isn't knocked back, so the brawl stays together. It is decisive, at half a set-up, exactly as the plain blur's ender was (`agency-pass.md` §13 and §14.4). A masher can still open and finish a rival.
- **The look** (Orb): the impact lands on the trigger, with a fluid after-image blur.

## 4. Tech: skill strikes on the beat

| Question | Rule |
| :--- | :--- |
| **The beat** | Every light or skill strike of his has a beat point after it lands: 24 ticks after contact by default, and 20 to 28 by the piece |
| **On the beat** | A press within **4 ticks** of the beat point is a **skill strike** |
| **Early** | A press before that window is a **flurry blow,** thrown at once. This is Orb's "lapse into high speed flurries when they miss their timing". It is never a dead press |
| **Late** | A press after the window is a fresh light. The rhythm starts again from it |
| **The first press** | A light. It can't be on or off a beat, and the beat runs from its contact |
| **A skill strike** | ×1.25 of a light. It reels the rival for 8 ticks, where a flurry blow reels him for 4, and that pushes his next blow back. It adds 1 to the flow |
| **A missed beat** | The flow goes to 0, as now |
| **How the beat is shown** | No metronome on the HUD. At the beat point the striking limb **sets** with a glint, and a short tick sounds. The piece's rhythm is the cue |
| **The look** (Orb) | A clean, instant-looking blow with a crisp after-image, distinct from the flurry's smear |

The existing bands hold: timed against the same style untimed at 62 to 82%.

## 5. Heavy: the guard breaker and the juggle starter

**A lone heavy never knocks back.** That is the prototype. It does two other things.

**Reliable against a heavy guard.**
- A heavy that lands on a held guard **breaks it:** the guard is down for 40 ticks and the blocker staggers for 12. He isn't knocked back.
- **A set guard can't turn into a perfect block.** A guard that has been held for 30 ticks or more is set. Letting go and pressing again during the heavy's wind-up gives a normal block, which the heavy breaks. To perfect-block a heavy he must have had his guard down for at least 20 ticks first. So a player who sits in guard loses to a heavy every time, and a player who reads the wind-up from neutral can still perfect-block it.
- Lights and skill strikes only chip a guard.

**The set-up for a juggle.**
- A heavy that lands clean on a rival who isn't guarding **lifts** him: he hangs in place for 30 ticks, or 45 if the heavy was fully charged. He is still in the brawl.
- **The juggle:** while he hangs, skill strikes on the beat keep him up, **three at most.** Each is a skill strike in full (×1.25, flow +1) and re-lifts him for one more beat. An early or late press drops him: the juggle is over.
- **How it ends:** with the string's heavy ender (below), or when he drops.
- **His way out:** a burst (30 ki). A full juggle is three on-beat presses, so it brings the flow to 3 and its ender launches.

**A combo is 3 to 5 hits, and only the last is a heavy.**
- A heavy thrown after **two or more** landed blows of the string is its **ender.** Only an ender knocks back.
- **The ender knocks back.** It **launches** when one of these holds, and the stick aims it:
  1. his flow is 3 or more;
  2. the ender was held to a full charge;
  3. it ends a juggle of three.
- Winning a clash still launches (§7).
- So a player who never times still launches with a charged ender and a won clash, and knocks back with every ender. That keeps what `agency-pass.md` §18 promised him, with one change: a lone heavy with the stick no longer launches.

## 6. Block

- **A blocker is never knocked back by a blow,** not even by a string's ender.
- A blocked light or skill strike chips him. A blocked heavy, ender or not, breaks the guard and staggers him in place (§5).
- **What does move a blocker:**
  - a grab, a tackle or a dive grab, which beat a guard as before (`control-rules.md` §9);
  - any blow that lands while his guard is broken;
  - a signature beam's push, as today.
- A perfect block is unchanged: it ends the attacker's string, staggers him and gives the riposte.

## 7. Both fighters attacking at once

Each fighter's blows land on his own line. These rules settle the meetings.

| When | What happens |
| :--- | :--- |
| Two blows land more than 2 ticks apart | Both land, in order. The reeling fighter's next blow is pushed back by the reel |
| A skill strike and a flurry blow land within 2 ticks | The skill strike wins the beat, and the flurry blow is voided (`agency-pass.md` §2) |
| Two lights, flurry blows or skill strikes of the same kind land within 2 ticks | A trade: both land |
| Three clean blows land during a heavy's wind-up | The heavy is stopped. Fewer, and it comes through |
| Two held heavies or enders land within 6 ticks | **A struggle:** the fist clash on the pulse, if one is allowed (one per 20 s). Otherwise a double slide: both are knocked back half the distance |
| Two tapped heavies that aren't enders land within 2 ticks | Both land, and both stagger for 12 ticks. Nobody is lifted, and there is no struggle |
| Two fully charged blows are released on the flash | Blow for Blow (`agency-pass.md` §2) |

**Only heavy commitments start a struggle** (the EP for Orb, 2026-10-04; §11). Lights, flurry blows and skill strikes that meet trade by the rows above, so a brawl where both fighters press never stops for one.

**The shape this gives.** Mashing stops a heavy before it lands. A heavy breaks a guard. A guard soaks a flurry and can perfect-block it. Timing is what lifts any of them.

Hit-stop is 2 ticks for a flurry blow, 4 for a skill strike and 6 for a heavy, for both fighters.

## 8. What stays the director's

The player owns **when** each blow happens and **what kind** it is. The director still owns:
- which piece each blow is: the limb, the strike and where it lands, with the broken-limb filter;
- the pattern and cadence of a string, so no two look alike;
- the look: the after-images, the smears, the staging;
- the camera;
- every set piece: clashes, Blow for Blow, finishers, signatures, crippling blows;
- a launch's path and target, inside what the stick aims at;
- depth, and the AI.

**Pillar 2 keeps its stances** (Orb, 2026-10-04; §10). Its wording still needs to change, because the director no longer owns the combo. A proposal, for Orb to approve:

> **2. Stances, and every press a blow.** The player chooses his stance (martial arts, defensive, energy arts, charging or manoeuvre) and owns when he strikes and how: each press is one blow, and the rhythm of his presses (mashed, timed or held) is his style. The procedural director owns what each blow is, the camera and the set pieces, so no two strings look alike.

## 9. QA bands that would prove it

| Measure | Band |
| :--- | :--- |
| Press to contact, a mash blow | 2 ticks or less. 95% inside 4 |
| Press to contact, a skill strike | 6 ticks. 95% inside 8 |
| Presses in a brawl that become a blow within 10 ticks | At least 95% |
| Seconds without contact per minute, inside a brawl | At most 6 |
| Share of fight time spent in a brawl | 45 to 60% |
| Flurry blows a second against taps a second, from 5 to 10 taps | Within 10% of each other |
| A flurry's damage per second across tap rates | Within 10% |
| Timed against the same style untimed | 62 to 82%, kept |
| A heavy on a set guard breaks it | At least 95% |
| A blocker knocked back by a blow | Never (a hard test) |
| Skill hits per juggle | A mean of 1.5 to 2.5 |
| Juggles ended by a burst | 20 to 40% |
| A masher against the easy and medium AI, and a lights-only mirror finishing | The bands in `agency-pass.md` §13 and §23 still hold |

## 10. Stances and the face buttons

**Orb:** "stances will still be involved, the default represents the characters' martial arts stance, LB represents defensive stance, RB is Energy arts stance, RT is the charging stance, LT is maneuver stance. All face buttons should have an appropriately broad moveset for each stance."

**What is ruled** (Orb to Controls, and the EP's answers for Orb in `docs/ep/stance-answers-2026-10-04.md`):
- **B is the signature in every stance.** So a stance is three move buttons and a signature.
- RT dominates. Three hybrids are reserved (LT+RB, LB+RB, LT+LB) and don't ship in this update.
- Switching stance is instant and free, and cancels nothing (§12).
- Each stance has one tell (§12).
- The AI can do everything the player can (§12).
- The first build is the martial arts stance, for both fighters.

### The matrix

**One rule runs across every stance, so it is learned once:** X is the quick action, Y the strong one, A the stance's context action, and B its signature.

| Stance | Held (mask) | X: quick | Y: strong | A: context | B: signature (tier, §11) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Martial arts** | Nothing (0) | Light strikes: flurry blows and skill strikes (§3, §4) | Heavy strikes: the guard breaker, the lift, the ender (§5) | Grab and throw, pick-up, civilians, the taunt at range, a dive grab in the air. Held: his own channel where he has one (On the Chin for the rival) | **His defining signature,** a melee art (signature) |
| **Defensive** | LB (1) | **Check:** a short blow from behind the guard. Timed just after a blow lands on his guard, it is a parry | **Push:** a shove that makes space | Reversal after a block; deflect a shot at range. Both as today | **A counter** that catches the next blow and answers it (art) |
| **Energy arts** | RB (2) | Bolts and volleys | The charged shot; held on, a short beam; a second press splits it (the rival) | A mine at range; the shove in reach. Both as today | **The beam** (signature) |
| **Charging** | RT (4) | His quick special | His strong special | His utility special | **His ultimate** (ultimate) |
| **Manoeuvre** | LT (8) | **Step strike** in reach. Beyond it, the piloted light lunge or charge | A heavy on the move in reach. Beyond it, the piloted heavy lunge or charge, and the pursuit past charge range (§2c) | Tackle in reach and dive grab from above, as today; a snatch on the fly (pick-up, civilian) | **A terrain art:** he takes the rival into the landscape (art) |

**Reserved, and not in this update:**

| Hybrid | Held (mask) | What it is for | Its B |
| :--- | :--- | :--- | :--- |
| Evasive energy | LT + RB (10) | Firing on the move | Reserved |
| Defensive ki | LB + RB (3) | A ki shield or a zone | Reserved |
| Terrain while flying | LT + LB (9) | Landscape effects: barriers for the hero, collapses for the villain | Reserved |

Each hybrid gets the same four columns and one signature when it is designed. Until one is switched on in data, holding its two buttons reads as the newer of the two (Controls).

**What each stance button does by itself is unchanged.**
- **LB** guards, and a fresh press in a wind-up is the perfect block.
- **RB** makes his attacks energy.
- **RT** channels, and a tap is the burst when he is threatened.
- **LT** dodges on the press and boosts when held. In the air after a hit it is his recovery: a tap techs and a hold brakes.
- **LT and RT together** are still the transform, and the only way to transform.

**On the Simple layout** Attack tapped is the stance's X and Attack held is its Y. Signature is its B, and Context is its A. The choreographer picks the energy stance.

### Which cells take which reading

| Reading | Where it applies |
| :--- | :--- |
| **Speed** (tap rate) | Martial X (the flurry) and energy X (the spray, `agency-pass.md` §15.4) |
| **Tech** (on the beat) | Martial X (skill strikes), energy X (measured bolts), defensive X (the parry), manoeuvre X (a step strike on the rival's tell slips his blow) |
| **Held** | Every Y cell: the charged heavy, a longer push, the charged shot, the heavy charge. Martial A, for his channel |
| **None** | Every B cell, and the charging stance's three specials. They cost ki |

Mashing the defensive X is locked out: a check can be thrown once every 20 ticks.

### How today's inputs map onto it

| Today | In the matrix |
| :--- | :--- |
| Light, heavy | **Stay:** martial X and Y |
| Guard held, and the perfect block on a fresh press | **Stay.** The defensive stance is added on top |
| Reversal and deflect (context in guard) | **Stay:** defensive A |
| Energy held; bolts, the charged shot, the mine and the shove | **Stay:** the energy row |
| The signature (B, or the power trigger and B) | **Changes.** B is the signature of the stance he is in, and the beam is the energy stance's. Until a fighter's martial signature is authored, martial B fires the beam, so the first build has no dead button |
| The three specials (the power trigger and X, Y or A) | **Stay:** they are the charging row. They are fixed for each fighter, with a loadout later |
| Power held to charge; a tap to burst | **Stay** |
| Transform (both triggers for 0.5 s) | **Stays,** as the only way |
| The dodge on an LT tap; the boost on a hold | **Stay.** Entering the manoeuvre stance is a dodge, and it pays 15 ki when he is threatened. This is looked at again once Orb has played it |
| The tackle (context while sprinting); the dive grab | **Stay:** manoeuvre A. No sprint wait is needed: LT held is enough |
| The air brake and the tech | **Move** to LT: a tap techs, and a hold brakes at 20 ki a second. `agency-pass.md` §4 had the brake on Guard |
| Context: grab, pick-up, civilians, taunt | **Stay:** martial A |
| The escape stance | **Gone** since the agency pass. The Escape button stays a control of its own |

**New actions,** each for Orb to approve, with first numbers:
- **Check:** half a light's damage, 6 ticks to contact, once every 20 ticks. His guard stays up against lights and flurry blows while he throws it. A heavy still breaks a set guard (§5).
- **Parry:** a check pressed within 4 ticks after a blow lands on his guard. The rival reels for 12 ticks. It doesn't end his string, which is what the perfect block does.
- **Push:** no damage, a 10-tick wind-up, and the rival is driven back 3 bh. Held for 20 ticks it is 5 bh, which takes him out of the brawl (§2). It isn't decisive, and it can be done once a second.
- **Step strike:** a light at ×0.8 with a step of up to 2 bh around, over or under the rival, by the stick. It stays inside the brawl. Pressed within 4 ticks before the rival's contact, his blow misses.
- **The four signatures that aren't a beam** (§11).

**Dropped from the first draft:** the brace, prime and overcharge. The charging row is the three specials, and the perfect block stays on the guard button.

## 11. Signatures: one for each stance, in three tiers

B gives every fighter his own array of signatures: one for each stance, so five in this update and eight when the hybrids arrive. Ki is the limit. There is no cap per match.

### The tiers

| Tier | Ki | Damage, against today's signature | The pause it may take (`spec-wounds.md` §8b) | Shortest tell before it can land | Whose |
| :--- | ---: | ---: | :--- | ---: | :--- |
| **Art** | 25 | ×0.55 | Live, 0.8 s | 20 ticks | The defensive and manoeuvre stances |
| **Signature** | 45 | ×1.0 | Short, 1.5 s | 30 ticks | The martial arts and energy arts stances |
| **Ultimate** | 75 | ×1.7 | Full, 3 s | 45 ticks | The charging stance |

- **Damage for each ki spent is the same in every tier,** within 10%. So no tier is the best buy. They differ in what they do and what they risk.
- **One shared cooldown** covers all of a fighter's signatures: 120 ticks after an art, and 180 ticks (3 s) after a signature or an ultimate. It starts when the signature ends. It is there only to stop two in a row.
- **No cap per match, and no cooldown of its own for any signature.** This replaces the 45 ki and 15 s limit of `agency-pass.md` §5. The 40% cut to a signature's damage made there is kept, and it is the ×1.0 in the table.
- A hybrid's signature gets its tier when the hybrid is designed.

### What each signature is

These are the types. Combat authors each one as a generated frame, with hand-picked pieces for the defining one.

| Stance | Type | What it does | What answers it |
| :--- | :--- | :--- | :--- |
| **Martial arts** | A melee art: his defining signature | A rush of his own strikes that ends in a launch. From the mid band it opens with a lunge | A guard takes it at reduced damage and isn't launched. A perfect block on its first blow. A dodge. Another signature, which makes a struggle |
| **Defensive** | A counter | He sets himself for up to 40 ticks. The next strike, heavy or single shot that would land is caught and answered with a knock-back. If nothing comes, the ki is spent and he is open for 20 ticks | A grab or a tackle. Waiting it out. A signature or an ultimate, which it only weakens by 30% |
| **Energy arts** | The beam | As built: the biome variants, the beam struggle and the beam answers (`rule-of-cool.md`) | As built |
| **Charging** | The ultimate | Everything he has gathered, let go at once. Its shape is the fighter's own. He is exposed through its whole tell | Any clean hit during the tell stops it, and half its ki is lost. Distance. A signature that meets it, which makes a struggle with the ultimate ahead |
| **Manoeuvre** | A terrain art | He takes hold of the rival in flight and puts him into the landscape: the ground, a ridge, the sea or a building. The launch planner picks the target with his personality term, so the hero steers away from people and the villain toward them | A dodge. A hit during its approach. A guard doesn't stop it, because it is a grab |

- **Pillar 7 holds for all five.** The stance picks the signature. The biome, the altitude and the defender's stance pick its variant. Each signature ships with at least three variants.
- **Collateral.** Each signature's damage to the world is capped by power tier, as the beam's is (`balance-targets.md` §15). The terrain art counts as a landing for structures.
- **Legal's stacking rule holds:** no moment shows more than two of the seven power-up marks (`rule-of-cool.md`, rule 9). An ultimate's staging has to fit inside it.

### What the tiers touch

- **The last stand** (`spec-wounds.md` §1b): its one free signature covers up to 45 ki. An ultimate fired there costs the other 30.
- **On the Chin:** an art or a signature is its "one signature", cut by 70%. An ultimate is cut by 50%.
- **The pause budget:** when it is empty a signature plays live, as now.
- **The alchemist:** a signature is an ingredient by its stance.

### Struggles

**A struggle starts only when two heavy commitments meet** (the EP for Orb, 2026-10-04). Lights, flurry blows and skill strikes that meet only trade (§7), so a brawl where both fighters press never stops for one.

| What meets | What happens |
| :--- | :--- |
| A beam and a beam | The beam struggle, as built |
| Any other two signatures: a melee art into a beam, two melee arts, two terrain arts | A struggle on the pulse (`rule-of-cool.md`: 3 pulses, an 8-tick window). The higher tier starts 10 ahead for each tier between them |
| A held heavy or an ender, against a held heavy or an ender, landing within 6 ticks | The fist clash on the pulse. Two fully charged blows released on the flash are Blow for Blow |
| A signature against a held heavy or an ender | No struggle. The signature comes through with 15% less damage |
| Two tapped heavies that aren't enders, landing within 2 ticks | No struggle. Both land and both stagger for 12 ticks. Nobody is lifted |
| Lights, flurry blows and skill strikes | Never a struggle |
| A beam against a ki shield that breaks | A short struggle. Reserved with the defensive ki hybrid |

- **The counter doesn't struggle.** It catches the blow or it doesn't.
- **Any face button** presses on the pulse. A stray press costs what it costs in the finisher struggle: 0.10, with the floor kept.
- **The stance he holds during a struggle bends it a little:**
  - charging (RT): each pulse he hits scores 12 in place of 10, and costs him 5 ki;
  - defensive (LB): if he loses, he takes 20% less from it;
  - any other stance changes nothing.
- **One struggle in 20 s,** as now, except the beam struggle, which keeps its own rules. When a struggle isn't allowed, the meeting is settled without one: both fighters are knocked back half the distance and take half the damage.

### For QA

| Measure | Band |
| :--- | :--- |
| Arts fired a match, both fighters | 4 to 12 |
| Signatures fired a match (the melee art and the beam) | 3 to 8. It was 2 to 5 under a cooldown, and the AIs measured 5.6 |
| Ultimates fired a match | 0 to 2 |
| Share of a match's damage from all signatures | At most 30%, kept |
| Matches with an ultimate in the first 90 s | Under 10%. If it is over, the first lever is the ultimate's cost |
| Struggles a match | 1 to 4 |
| A struggle started by a light, a flurry blow or a skill strike | Never (a hard test) |
| Beam clashes | 30 to 60% of beams fired, kept |

## 12. Moving between stances

**Which stance he is in.** The layout reports which stance buttons are held, as a mask, and the sim looks the stance up (Controls, `docs/controls/lunge-control.md` A2).
- **RT dominates.** With RT down he is in the charging stance, whatever else is held. Holding RT ends a held guard, because charging is exposed. The burst on an RT tap still fires from a guard.
- LT and RT pressed within 6 ticks of each other are the transform chord, and change no stance.
- Any other pair is a reserved hybrid. Until it ships, it reads as the newer button.

**Switching is instant and free, and it cancels nothing.**
- A blow keeps the stance it was pressed in. Letting go of the stance button in the middle of it changes nothing.
- A string can mix stances: two martial lights, a bolt at point-blank, a heavy ender. That is the mix-up.
- Going to guard in the middle of his own blow guards when the blow's recovery ends. A dodge-cancel (15 ki) cuts it short.
- Boosting away in the manoeuvre stance breaks the brawl's magnetism (§2).
- A stance switch never resets the flow or the recipe window. The stance of each press is one more ingredient for the alchemist.

**Holding a stance is free. Its moves cost ki.** What each one exposes:

| Stance | The price |
| :--- | :--- |
| Martial arts | No guard |
| Defensive | Guard fatigue after 3 s. A guard held 30 ticks is set, and a heavy breaks it (§5). He moves at 0.6 speed |
| Energy arts | No guard while RB is held. Spread builds with fast fire. Every shot costs ki |
| Charging | Exposed and nearly still while he channels. Any clean hit interrupts it |
| Manoeuvre | Entering it is a dodge. The boost costs 12 ki a second as now, and empty ki is 2 s of exhaustion. No guard |

**While he is launched, lifted or stunned** only the manoeuvre stance works (a tap techs, a hold brakes), with the Escape button.

**One tell for each stance,** so a rival's stance can be read: the pose first, and one small cue second. There is no glyph on the HUD unless a setting turns it on.

| Stance | Pose | Cue |
| :--- | :--- | :--- |
| Martial arts | His own fighting stance | None |
| Defensive | Arms set: open hands for the Protagonist, plates forward for the rival | A rim of light on the guarding side |
| Energy arts | The lead hand raised and lit | The glow at the hand |
| Charging | Planted and drawn in | The rising aura, as now |
| Manoeuvre | Leaning into flight | A short trail |

The cues are kept small, so that none of them reads as a power-up mark. Legal confirms that against its stacking rule.

**The AI and the choreographer.**
- The AI plays through the same stances, costs, cooldowns and timings. Difficulty changes only how well it executes: its reaction time, its timing accuracy and how often it switches.
- A player can hand stance choices to the choreographer. The presets ship first (Full, Assisted, Manual), and the setting for each stance follows. The choreographer obeys the same costs and timings, and holding a stance button takes that blow back.
- When the choreographer picks, it picks in character: care, Pride and anguish steer it as they steer the AI.

## 13. Rules for a generated moveset

Orb: "Lets work out a way to generatively work all these stances into vast and varied movesets for each character." Combat designs the generator (`docs/combat/moveset-generator.md`). These are the rules its output must obey so that a vast moveset is still readable and fair. They also answer Combat's three questions: the matrix (§10), what a variant may change, and the forms' numbers.

### How the cells are filled

**The martial arts stance has two strike cells,** now that B is the signature and A is context. Combat's 46 strikes for each fighter stay, sorted like this:

| Cell | Holds | At launch |
| :--- | :--- | ---: |
| Martial X | Every light shape: hands, feet, and the lights of the close limbs | About 30 |
| Martial Y | Every heavy shape, with the lifts, the enders and the guard breakers | About 16 |
| Martial A | The context actions: grabs and throws, the taunt, the dive grab | 1 action for each context, in 2 or 3 looks |
| Martial B | His defining signature | 1, in at least 3 variants |

**Inside X and Y the stick leans the pick,** so a broad cell is still under the player's hand:

| Stick | What it favours |
| :--- | :--- |
| None | Hands, on a line or an arc |
| Toward | The close limbs: elbow, knee, shoulder, head |
| Away | Feet |
| Up | Rising shapes and high targets |
| Down | Dropping shapes and low targets |

It is a weight of ×3 and not a filter, so a broken limb or a repeat still falls through to the rest of the cell. A blow's wear goes to the region it lands on, so the stick is also how a player works on one region.

**The other stances** take Combat's counts (`moveset-generator.md` §3.1): 6 for each defensive and energy cell, 6 to 8 for each manoeuvre cell, and 4 or 5 looks for each special. They replace the smaller floors of my first draft.

### What a variant may change

**What may vary** between variants of one cell: the limb, the tip, the place it lands, the path, the range step, the look of its form, and which blow follows it best.

**What must stay the same for every variant of a cell,** so that a player can learn the cell and not the variant:
1. **Its role:** what it beats and what beats it.
2. **Its timing:** press to contact, the length of its tell, and its beat point, inside the 20 to 28 ticks that Combat's paths use.
3. **Its reach band.**
4. **Its damage and its ki cost.**
5. **Its result:** whether it leaves the rival in the brawl, staggers him, lifts him, knocks him back or launches him.

**A variant may change how a press is delivered, and never what it is worth.** This is the answer to "a pair of bolts against one":
- A variant may deliver its press as 1, 2 or 3 pieces: two bolts for one, or a double tap for one strike.
- The pieces share the cell's damage and ki between them. All of them arrive within 6 ticks of the cell's contact time.
- **One press counts once:** for the flow, the flurry's four, the barrage's four shots, a set-up, the stale-habit rule and the mood. It counts as landed when at least half of its pieces land. Its damage is by the pieces that land.
- One guard, perfect block, parry or deflect answers the whole press.
- Its reach band, its spread and its result are the cell's.
- The piece count is data on the move, and the validator checks that the shares add up to the cell's values.
- Anything past this (a different damage, cost, range, speed or result) is a different cell or a special, and not a variant.

**The same cell has the same timing on every fighter.** Fighters differ in their stats, their specials, their signatures, their meters and their pieces. What a player learns about martial X on one fighter holds on the next.

### The forms' numbers, for the martial arts stance

Damage is against the light and heavy values in data. Flow, tier, form and wounds multiply on top, as now.

| Form | How it is pressed | Damage | Press to contact | Whole blow | A clean hit leaves the rival | Hit-stop | Flow |
| :--- | :--- | :--- | ---: | ---: | :--- | ---: | :--- |
| **Light** | X: a string's first press, or a press after the beat window | Light ×1.0 | 4 | 24 | Reeling for 4 | 2 | Starts the beat |
| **Flurry blow** | X again before the beat window | Light ×0.6 at 6-tick taps, ×0.8 at 8, ×1.0 at 10 or slower | 2 or less | The tap interval, 6 to 12 | Reeling for 4. After four unanswered, the next staggers him for 12 | 2 | To 0, if it missed a beat |
| **Skill strike** | X within 4 ticks of the beat point | Light ×1.25 | 6 | 30 | Reeling for 8 | 4 | +1 |
| **Heavy** | Y, tapped | Heavy ×1.0 | 34: 26 of wind-up and 8 to land | 76 | Lifted for 30. A set guard breaks: down for 40, staggered for 12 | 6 | No change |
| **Held heavy** | Y held, then released | Heavy ×1.0, rising to ×1.25 at 46 ticks of hold | 8 after the release | 96 | Lifted for 30, or 45 at a full charge | 6 | No change |
| **Ender** | Y after two or more landed blows of the string | As the heavy or the held heavy | As the heavy | As the heavy | Knocked back. Launched at flow 3 or more, at a full charge, or after a juggle of three | 6 | Spent by a launch, as now |
| **Juggle strike** | X within 4 ticks of the beat point while he is lifted | Light ×1.25 | 6 | 30 | Lifted again for one beat. Three at most | 4 | +1 |

- **The beat point** is 24 ticks after contact by default. Combat's values by path are accepted: 20 for a line, 24 for an arc or a rise, 26 for a drop and 28 for a spin.
- **Reach:** every form is the close band. From the mid band a lunge comes first (§2b).
- **An ender can be stopped** by three clean blows in its wind-up, like any heavy. QA watches it: enders stopped by a mashing rival should be at most 40%. If it is higher, the first lever is one more blow to stop an ender.
- **Martial B** is signature tier (§11). **Martial A** keeps today's context numbers.
- The other stances' numbers come with their slices. Where a cell exists today, its numbers stand: the bolts, the charged shot, the reversal, the tackle, and the specials at 20, 20 and 25 ki.

### How a variant is picked at run time

In this order:
1. **The situation** removes what can't be thrown: in the air, on the ground, at a wall, in water; the form; a broken limb.
2. **The range** picks the close pieces or the lunge pieces.
3. **The stick** leans the pick, by the table above.
4. **The last presses** rule out a repeat inside the string, and a habit makes his blows stale (`control-rules.md` §6).
5. **The flow** unlocks the showier variants, and the showcase at 5.
6. **A seeded draw** settles what is left, keyed on the match seed, the fighter and the string, so a replay is identical.

**The bands that prove it:** no key strike twice in a string; the same three-blow series in under 10% of strings (`moveset-rules.md` §6); and in a blind test, a player can name which cell a blow came from at least 80% of the time.

## 14. Questions for Orb

1. **A lone heavy never launches.** The prototype has only the string's ender knock back, so this retires "a heavy with a stick direction" as a way to earn a launch (questionnaire 14). The stick now aims the ender's launch. Is that right?
2. **Mashing closes with a stagger in place,** not a knock-back, so the brawl stays together. Is that the feel wanted?
3. **After a knock-back, the fighters are drawn back together** if either holds toward or presses within half a second. Should that be automatic like this, or always the player's own move?
4. **The beat is shown on the body:** a glint on the striking limb and a tick of sound, with no metronome on the HUD. Is that enough, or should a beat ring be an option in settings?
5. **A juggle** is a clean heavy, then up to three skill strikes on the beat, then the ender, with a burst as the way out. Is three the right size?
6. **Pillar 2's new wording** (§8), which keeps the stances.
7. **The five kinds of signature** (§11): a melee art for the martial arts stance, which is his defining one; a counter for the defensive stance; the beam for energy arts; an ultimate for charging; and a terrain art for manoeuvre. Are these the right five?
8. **Their cost:** 25, 45 and 75 ki, a shared cooldown of 2 or 3 s, and nothing else. So an ultimate can be fired as soon as he has 75 ki, even in the first minute. Is that right, or should the ultimate wait for his first form?
9. **Three small new actions** (§10): the check with its parry, the push, and the step strike.
10. **The stick leans which limb he uses** (§13): toward for elbows and knees, away for kicks, up and down for rising and dropping blows. Is that wanted, or should the director pick freely?

**Settled since the first draft:** B is the signature in every stance. The perfect block stays on the guard button. The transform stays on the two triggers. The specials stay on the charging row.
