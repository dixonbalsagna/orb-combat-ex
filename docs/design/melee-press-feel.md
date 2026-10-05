# Melee press feel: every press is a blow

Owner: Game Design. Orb approved the second melee prototype (`docs/ep/prototypes/melee-trade-v2.html`) and gave the direction this page turns into rules (`docs/ep/vision.md`, "the melee feel"):

> close up brawls should make fighters slightly 'magnetic' so they can trade continuous strings of blows without interruption. both players should feel like their attacks actually match a button press. mashers should see their fighter landing faster flurries the quicker they tap the attack, a player trying to tech timing combos should see his character landing flashy skill attacks that lapse into high speed flurries when they miss their timing, and the heavy attack should be reliable against a heavy guard opponent, or to set up chains of skillful juggle attacks.

It is built on the alchemy framework that exists: the press log, the timing grade, the flow count, the pieces and the blur cadence. **Every number is a starting value.** Orb answered ten questions about it in questionnaire 17 and added to it on 2026-10-05 (three readings on every attack button, a press and a hold on A, the zip and its counters). All of it is written in (§14). The stances, the signatures and the rules for a generated moveset are §10 to §13.

## 0. What changes, in one paragraph

Today a close fight is an **exchange:** the director plans it from the attacker's first press, and the defender mostly watches. This spec replaces that, in the close band, with a **brawl:** both fighters throw blows at the same time, each on his own line, and each press is one blow. The director still chooses what every blow is.

**What it replaces:**

| Today | Becomes |
| :--- | :--- |
| An exchange owned by the attacker, in the close band | A brawl that both fighters are in (§1, §2) |
| A string of five blows with four link presses, set by the director | A string as long as the presses, closed by a heavy (§5) |
| Styles read from the mix of the last five presses (`agency-pass.md` §2) | Each press has its own kind: a mash blow, a skill strike or a heavy (§3 to §5). The flow count is kept |
| A mashed blur closes with a weak knock-back (`agency-pass.md` §13) | It closes with a stagger in place, which still counts as decisive (§3) |
| A lone heavy with the stick launches (`agency-pass.md` §18, earner 3) | A tapped lone heavy lifts the rival for a juggle. A lone heavy held to full launches when the stick is held. A string's ender knocks back or launches (§5) |
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
| **Where it holds** | In the close band. It switches on when a brawl starts inside 3 bh. Steps and recoil inside the brawl have slack out to 4.5 bh before it lets go |
| **How strongly** | Recoil from a blow leans a fighter and doesn't move him. Any drift is pulled back toward striking distance at up to 0.5 bh a second. Walking with the stick is damped to 0.4 of normal, so tilting the stick aims a launch and doesn't wander him off |
| **What breaks it** | A knock-back. A push. A launch. A dodge with the stick away. Boosting away. 60 ticks with no attack from either fighter |
| **After a knock-back** | They are apart, and nothing draws them back. Closing again is always a player's own move: a lunge, a zip, or flying in (Orb, questionnaire 17). Magnetism holds only while they are in the close band |
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
- after a knock-back there is no cooldown: either fighter's own lunge back in can start as the slide ends (§2);
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
- match length, re-measured: slower charges added 80 s once before (`agency-pass.md` §12). The magnetic brawl means far fewer charges, since after a knock-back a mid lunge is enough to close again.

**Under the stances** (§10). A lunge or a charge pressed without LT flies the straight line above and costs no ki. It arrives and stays, and a brawl starts. Holding LT changes what the press is, by distance:

| Distance | With LT held |
| :--- | :--- |
| In reach | The step strike, a heavy on the move, or the tackle (§10) |
| **The mid band, 3 to 12.5 bh** | **A zip:** he goes in, strikes, and comes out again (below) |
| Far, inside the charge range | A piloted charge: it can be steered, and it stays when it arrives |
| Beyond the charge range | The pursuit, as above. Orb confirmed it over a taunt-only ceiling (questionnaire 17) |

#### The zip: mid-range lunges in the manoeuvre stance

**Orb** (questionnaire 17): "I like the thought that holding LT creates mid-range lunging attacks, these can be utilized at great cost to stamina... in the game I would expect every stance to be able to connect blows against a player using this, but the character should zip back and forth in a stylistic blur, matching our visual cues we established for speed, tech and heavy."

**Orb** (2026-10-05): "LT plus an attack should cause the fighter to zip to the opponent to land the strike and zip back by default. LT plus an attack plus the movement stick pushed towards the opponent should zip to the opponent, land the strike, then zip the fighter on the other side of the opponent... well timed heavy and tech strikes should be able to counter this".

So a zip is a hit and run. It costs a lot of ki, and for a moment at the rival he can be hit by anything. Every number is a starting value.

**What each button's zip is:**

| | LT + X: zip strike | LT + Y: zip heavy | LT + A held: zip tackle |
| :--- | ---: | ---: | ---: |
| Ki, paid at the press | 20 | 30 | 25 |
| The tell, before he moves | 6 ticks | 10 ticks | 12 ticks, which is the hold |
| The way in | 8 to 14 ticks | 10 to 18 ticks | 8 to 14 ticks |
| In reach before his blow lands | 4 ticks | 12 ticks | 6 ticks |
| In reach after it | 6 ticks | 10 ticks | The carry, 12 ticks |
| The way out | 10 ticks | 12 ticks | 10 ticks |
| Press to contact | 18 to 24 ticks | 32 to 40 ticks | 26 to 32 ticks |
| The whole zip | 34 to 40 ticks | 54 to 62 ticks | 48 to 54 ticks |

- **LT + B** is the stance's signature, delivered as a zip in its quick, timed or held form. It costs its tier's price (§11), which includes the zip, and it has its tier's tell in place of the zip's.
- **The zip tackle** is the tackle as today: it beats a guard, carries him 4 bh along the line and throws him off, which is a knock-back. It is a grab, so it falls under the grab lockout (§10).
- **The prices are raised** from the first draft's 15, 25 and 20, for Orb's "great cost to stamina". Five zip strikes or three zip heavies empty a full bar, and an empty bar is 2 s of exhaustion.

**The strike lands in the reading it was pressed with** (§10):

| | Speed (tapped, or mashed) | Tech (timed) | Heavy (held) |
| :--- | :--- | :--- | :--- |
| **Zip strike** | A light at ×1.0. The rival reels for 4. Pressed again as he comes out, the next zip follows with a 3-tick tell and its blow is ×0.8. Every zip is paid for in full | It lands in the 4 ticks before the rival's own blow would. That blow misses. It is a skill strike: ×1.25, the rival reels for 8, flow +1 | X kept held for 12 ticks more in the tell. A set light on arrival: ×1.25, and the rival reels for 12. He is in reach for 8 ticks before it lands, not 4 |
| **Zip heavy** | A heavy at ×1.0. The rival staggers for 12, and a set guard breaks. No lift, because the zipper is leaving. Tapped again in the tell, it is rushed: each tap takes 4 ticks off his time in reach before the blow and 15% off the damage, two taps at most | By the same timing, the rival's blow misses: ×1.25, he staggers for 20, flow +1 | Y kept held for 20 ticks more in the tell: ×1.25 and a knock-back |

**Where he goes afterwards:**

| The stick, as his blow lands | The way out |
| :--- | :--- |
| None | **Back to where he came from.** This is the default |
| **Toward the rival** | **Through to the rival's far side,** at the distance he started from |
| Away | Back, as the default |
| Up or down | Back, as the default. Up and down still lean the blow to a rising or a dropping one (§13), and nothing more |

**The rules of a zip:**
- **Range:** the mid band. In reach the same buttons are the step strike, the heavy on the move and the tackle.
- **The ki is paid at the press** and isn't given back. Without enough ki the press is the plain lunge, which is free and stays.
- **Where he arrives is fixed at the tell:** along his own line and on his own side, so the defender can read it. The crouch, the streak and the engage ring show it, as for any lunge.
- **He can be hit for as long as he is in reach:** 10 ticks for a zip strike and 22 for a zip heavy. He has no guard there.
- **On the way in** any shot stops a zip strike. A zip heavy shrugs off bolts but not a charged shot, as a heavy charge does.
- **He can be outrun.** The zip follows the rival for its longest way in. If the rival has boosted out of the mid band by then, it ends short with no blow.
- **A zip doesn't start a brawl** unless he is caught or countered. It isn't decisive, apart from a knock-back, and it never starts a struggle (§11).
- **The looks** are the ones already set: the smear for zips mashed one after another, the crisp snap for a timed one, and the squash for a held one.

#### Countering a zip

**A well-timed tech or heavy strike from the defender cancels the zip's blow.** The mark is the zipper's arrival: the tick the engage ring closes on.

| The defender's strike | Well timed is | Against a zip strike | Against a zip heavy | What it does |
| :--- | :--- | ---: | ---: | :--- |
| **A tech strike:** the tech reading of his X in the stance he is in (a skill strike, the parry, a measured bolt at point-blank, a step strike), or the stuff | Pressed from 4 ticks before the arrival until the zipper's blow lands | An 8-tick window | A 16-tick window | **The zipper's blow is cancelled.** He staggers for 12 ticks in reach, and a brawl starts with the defender ahead. The counter is a skill strike: ×1.25 and flow +1 |
| **A heavy strike:** a martial heavy in any reading, a heavy or charged shot at point-blank, or the held reading of his X (the set light, the guard strike, the volley) | Its wind-up ends, or its hold is let go, from 6 ticks before the arrival until the zipper's blow lands | A 10-tick window | An 18-tick window | **The zipper's blow is cancelled.** The heavy lands in full and knocks him back, which is decisive |

- **The zipper's ki stays spent** in every case.
- **Too early:** the defender's blow is thrown before the zipper arrives and misses. He is in its recovery when the zip lands.
- **Late, while the zipper is still in reach** (6 ticks after a zip strike lands, 10 after a zip heavy): the zip's blow has landed, and the defender's blow **catches** him. The way out is cancelled, he reels where he is, and a brawl starts around him.
- **A speed blow** (a flurry blow, a bolt, a check) that lands on him in reach doesn't cancel his blow. It catches him, and his blow is pushed back by his reel.
- **After he has left,** the blow misses.
- **A signature zip** in its quick or timed form is countered like a zip heavy. In its held form a counter only takes 30% off it.
- A tapped heavy takes 34 ticks to land, so against a zip strike the heavy counter is a held heavy let go on the arrival, a rushed heavy, or a read. Against a zip heavy a tapped heavy pressed at the tell is in time.

**What else works, by the stance the defender is in:**

| His stance | Besides the counter |
| :--- | :--- |
| **Martial arts** | The skill strike and the heavy are the counters above. A flurry blow or a light catches him |
| **Defensive** | A held guard blocks a zip strike. A perfect block on a fresh press staggers him in reach. The parry and the stuff are tech strikes, so they counter. A zip heavy breaks a guard that is set, and the tackle beats any guard |
| **Energy arts** | A bolt during the tell stops a zip strike on its way in, and a charged shot stops a zip heavy. At point-blank a measured bolt is a tech strike and a charged shot is a heavy, so they counter. The shove throws him off. A mine on his line goes off on him |
| **Charging** | He is exposed while he channels, and a zip is the tool against that. Switching is instant, so he can let go and answer from any other stance inside the tell. From the stance itself, the burst on an RT tap (30 ki) throws the zipper back |
| **Manoeuvre** | A dodge on the arrival makes it miss, for 15 ki. A step strike inside his tell is a tech strike, so it counters. Boosting out of the mid band outruns it |

**Piloted charges** come from the far band, with LT held through the flight.
- **Steering:** up or down by as much as 4 bh, and the stick toward or away changes the speed by up to 20%, never over the top speed or under the shortest flight. The steer row above applies to a piloted charge only.
- **The price is the zip's:** 20 ki for a light and 30 for a heavy, paid at take-off. Calling it off before the commit point gives nothing back.
- Letting go of LT before the commit point stops it, as letting go of the attack does.

**The air brake is on LT:** a hold brakes at 20 ki a second, and a tap techs. Holding Guard during his own charge still stops him into a guard.

**For QA, on zips:**

| Measure | Band |
| :--- | :--- |
| A zip's cost, and its ticks in reach | Exactly the table (a hard test) |
| Zip strikes that land clean, against an opponent who answers | 35 to 55% |
| Zips countered: the blow cancelled by a tech or heavy strike | 10 to 25% |
| Zips that end with the zipper caught | 20 to 35% |
| Ki spent on zips, as a share of all ki spent | At most 25% |
| A zip that starts a brawl without the zipper being caught or countered | Never (a hard test) |

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
| **How the beat is shown** | On the body: at the beat point the striking limb **sets** with a glint, and a short tick sounds. The piece's rhythm is the cue. **A beat ring** is an option in settings, off by default: a ring on the rival that closes on the beat point (Orb, questionnaire 17) |
| **The look** (Orb) | A clean, instant-looking blow with a crisp after-image, distinct from the flurry's smear |

The existing bands hold: timed against the same style untimed at 62 to 82%.

## 5. Heavy: the guard breaker and the juggle starter

**A tapped lone heavy never knocks back.** That is the prototype. It does two other things. A lone heavy held to full may launch, which is further down.

**Reliable against a heavy guard.**
- A heavy that lands on a held guard **breaks it:** the guard is down for 40 ticks and the blocker staggers for 12. He isn't knocked back.
- **A set guard can't turn into a perfect block.** A guard that has been held for 30 ticks or more is set. Letting go and pressing again during the heavy's wind-up gives a normal block, which the heavy breaks. To perfect-block a heavy he must have had his guard down for at least 20 ticks first. So a player who sits in guard loses to a heavy every time, and a player who reads the wind-up from neutral can still perfect-block it.
- Lights and skill strikes only chip a guard.

**The set-up for a juggle.**
- A heavy that lands clean on a rival who isn't guarding **lifts** him: he hangs in place for 30 ticks, or 45 if the heavy was fully charged. He is still in the brawl.
- **The juggle:** while he hangs, skill strikes on the beat keep him up, **five at most** (Orb, questionnaire 17). Each adds 1 to the flow and lifts him again for one more beat. An early or late press drops him: the juggle is over.
- **Each juggle strike is worth less than the one before:** ×1.0, ×0.85, ×0.7, ×0.55 and ×0.4 of a skill strike. Five of them are worth 3.5 skill strikes.
- **How it ends:** with the string's heavy ender (below), or when he drops.
- **His way out:** a burst, at its usual price: 30 ki, and 8 s before he can burst again. It works while he is lifted. A juggler who guards as it fires soaks it, as now.

**What a full juggle is worth.** With the data's light at 26 and heavy at 66, and the flow's 4% a count:

| | Damage |
| :--- | ---: |
| A full juggle: the heavy, five strikes on the beat, the ender | 271 |
| The same with every strike at full worth | 327 |
| Two four-hit timed strings (a light, two skill strikes, the ender) | 332 |
| The old juggle of three, now | 229. It was 245 |

So a full juggle is about 80% of two strings. What the fourth and fifth strikes buy is a flow of 5, which is the showcase, and a certain launch. The rival is also out of the fight for about 3.5 s while it lasts.

**A lone heavy held to full may launch** (Orb, questionnaire 17).
- **Fully held is 46 ticks of hold.** The charge flashes at that tick, and he can let go at any time after it. It lands 8 ticks after the release, so no sooner than 54 ticks after the press.
- **The stick, read at the release, decides what a clean hit does.** With the stick held it launches him along it: up, down, or across in the direction he is facing. With no stick it lifts him for 45 ticks, which is the juggle starter.
- A heavy held for less than 46 ticks lifts for 30 and never launches. A tapped one is the same.
- On a guard it breaks the guard and the blocker isn't moved (§6).
- The hold is part of its wind-up, so three clean blows during it stop it (§7).
- This brings back the third launch earner of `agency-pass.md` §18 in a narrower form: a lone heavy with the stick, when it was held to full.

**A combo is 3 to 5 hits, and only the last is a heavy.**
- A heavy thrown after **two or more** landed blows of the string is its **ender.** Only an ender knocks back.
- **The ender knocks back.** It **launches** when one of these holds, and the stick aims it:
  1. his flow is 3 or more;
  2. the ender was held to a full charge;
  3. it ends a juggle of three or more.
- Winning a clash still launches (§7).
- So a player who never times still launches with a charged ender and a won clash, and knocks back with every ender. That keeps what `agency-pass.md` §18 promised him, with one change: a lone heavy with the stick launches only when it was held to full.

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
| Skill hits per juggle | A mean of 2 to 3.5, of five at most |
| A full juggle's damage, against two four-hit timed strings | 75 to 90% |
| Launches from a lone heavy held to full | At most 10% of launches. The launch share of separations stays in its 25 to 40% band |
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

Controls then checked the matrix against its mappings. It fits, and the EP ruled on four gaps for Orb (2026-10-04). They are written in below and in §12: the held context level, one stance at a time until the hybrids exist, the Simple layout's charging row and transform, and the air brake's lock.

### The matrix

**One rule runs across every stance, so it is learned once:** X is the quick action, Y the strong one, A the stance's context action, and B its signature. X, Y and B each read three ways by how they are pressed (speed, tech and heavy), and A has a press and a hold. Both are set out under the matrix. **The kinds of signature in the B column are proposed, and not final** (§11).

| Stance | Held (mask) | X: quick | Y: strong | A: context, pressed and held | B: signature (§11) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Martial arts** | Nothing (0) | Light strikes (§3, §4) | Heavy strikes (§5) | Pressed: the grab, the pick-up, civilians, the dive grab, or the taunt. Held: the aimed throw, or his channel (On the Chin) | **His defining signature,** a melee art |
| **Defensive** | LB (1) | **The check** | **The push** | Pressed: the reversal after a block, or the deflect. Held: the guard throw, or the aimed deflect | **A counter** |
| **Energy arts** | RB (2) | Bolts | The heavy shot | Pressed: a mine at range, the shove in reach. Held: an aimed mine, or the long shove | **The beam** |
| **Charging** | RT (4) | His quick special | His strong special | His utility special, pressed or held | **His release.** In acts 3 and 4, held to full, his ultimate |
| **Manoeuvre** | LT (8) | **Zip strike** from the mid band (20 ki). **Step strike** in reach (5 ki). A piloted light charge from far | **Zip heavy** from the mid band (30 ki). A heavy on the move in reach (10 ki). A piloted heavy charge from far, and the pursuit past charge range (§2c) | Pressed: a snatch on the fly, or the dive grab. Held: the tackle in reach, or the zip tackle from the mid band (25 ki) | **His signature as a zip** (§2c). Held, a terrain art |

**Reserved, and not in this update:**

| Hybrid | Held (mask) | What it is for | Its B |
| :--- | :--- | :--- | :--- |
| Evasive energy | LT + RB (10) | Firing on the move | Reserved |
| Defensive ki | LB + RB (3) | A ki shield or a zone | Reserved |
| Terrain while flying | LT + LB (9) | Landscape effects: barriers for the hero, collapses for the villain | Reserved |

Each hybrid gets the same four columns and one signature when it is designed. Until one is switched on in data, holding its two buttons reads as the newer of the two, and only the newer button does its own job (§12).

**What each stance button does by itself is unchanged.**
- **LB** guards, and a fresh press in a wind-up is the perfect block.
- **RB** makes his attacks energy.
- **RT** channels, and a tap is the burst when he is threatened.
- **LT** dodges on the press and boosts when held. In the air after a hit it is his recovery: a tap techs and a hold brakes.
- **The transform** is one action, and the only way to transform. It is LT and RT together on a pad, an RB hold on the Simple layout, and the Transform button on touch.

**On the Simple layout** Attack tapped is the stance's X and Attack held is its Y. Signature is its B, and Context is its A, pressed or held. The choreographer picks the energy stance.
- For a Simple player the sim takes the director's stance choice, and doesn't read the held buttons for it.
- **The charging row is the exception to tap and hold.** With RT held, Attack is a special that the director picks, Signature is the ultimate, and Context is the utility special.

### Three readings on X, Y and B

**Orb** (2026-10-05): "in all states X, Y, B all should have speed, tech, heavy modifiers."

So the button picks the move, and how it is pressed picks the reading. The grammar is the same in every cell:

| Reading | How it is pressed | What it does, in every cell | Its look |
| :--- | :--- | :--- | :--- |
| **Speed** | A tap. Tapped again quickly, it repeats | The cell's plain move, on the press. Mashed, it comes faster and each one is weaker, so the damage for each second stays level | The smear |
| **Tech** | A tap within 4 ticks of the cell's mark | A cleaner result and 1 flow. In a strike cell it is also ×1.25. Off the mark it is the speed reading, and never a dead press | The crisp snap |
| **Heavy** | Held to the hold point, then let go | Slower, with a tell. Up to ×1.25 at a full hold, with the cell's strong result | The squash and smear |

- **The mark** is one of two things, by the cell. For an attack it is **his own beat:** the beat point after his last landed blow or shot. For an answer it is **the rival's tell:** the 4 ticks before the rival's blow lands. The director supplies both.
- **A reading never changes what X or Y costs in ki.** B's readings are its tiers, and they do (§11).
- Every number below is a starting value.

| Stance | Button | Speed (mashed) | Tech (timed) | Heavy (held) |
| :--- | :--- | :--- | :--- | :--- |
| **Martial arts** | X | Flurry blows (§3) | A skill strike, on his beat (§4) | **A set light.** After the light lands, X held for 12 ticks sets him, and letting go throws one hard light: ×1.25, and the rival reels for 12. He doesn't reel from flurry blows while he holds |
| | Y | A heavy (§5). Tapped again in the first 16 ticks of its wind-up, it is **rushed:** each tap takes 4 ticks off the wind-up and 10% off the damage, three taps at most | **A timed heavy,** on his beat after a landed blow: 16 ticks of wind-up in place of 26, ×1.25, flow +1. This is how a timed string closes fast | The held heavy (§5): ×1.25 at 46 ticks, and the launch or the long lift |
| | B | His signature's quick form | The quick form on his beat, closing a string | His signature's held form |
| **Defensive** | X | Checks. They come 10 to 16 ticks apart by the tap rate, at ×0.3 to ×0.5 of a light. Guard fatigue runs twice as fast while he mashes them | The parry: a check within 4 ticks after a blow lands on his guard. The rival reels for 12 | **A guard strike.** X held for 16 ticks: a full light, and the rival staggers for 12. His guard is open to a heavy while he holds |
| | Y | The push: 3 bh. Tapped again within 30 ticks it is a short shove of 1 bh, 12 ticks apart at the fastest. Three shoves in a row let the brawl go | **A stuff:** a push within the rival's tell. His blow is voided and he staggers for 8 | The long push: held for 20 ticks, 5 bh |
| | B | His signature's quick form | The quick form within the rival's tell | His signature's held form |
| **Energy arts** | X | The spray: bolts at the tap rate, with the spread building (`agency-pass.md` §15.4) | A measured bolt, on his firing beat: no spread, and flow +1, as built | **A volley.** X held for 16 ticks: three bolts together in a tight fan, each a full bolt at a bolt's price. It counts as one press (§13) |
| | Y | The heavy shot. Faster than one every 20 ticks, each is weaker, as built (`agency-pass.md` §23) | A heavy shot on his firing beat: no spread, and flow +1 | The charged shot: ×1.25 at a full hold. Held on, the short beam. The rival's second press splits it |
| | B | His signature's quick form | The quick form on his firing beat | His signature's held form |
| **Charging** | X, Y | The special as authored, on the press. Mashed, it repeats as fast as its recovery allows, at full price each time | The special on its mark: ×1.25 and flow +1. The mark is his beat or the rival's tell, by the special | The special held: its charged cut, up to ×1.25 at a full hold, for the same ki |
| | B | His signature's quick form | The quick form on his beat | His signature's held form. Held to 45 ticks in acts 3 and 4, his ultimate |
| **Manoeuvre** | X | The zip strike from the mid band (§2c). In reach, the step strike. Mashed, they follow one another, each paid for | A zip strike or a step strike inside the rival's tell: his blow misses, and it is a skill strike | A set light on arrival: ×1.25, and the rival reels for 12 (§2c) |
| | Y | The zip heavy from the mid band (§2c). In reach, a heavy on the move. Rushed, as the martial heavy | A zip heavy inside the rival's tell: his blow misses, ×1.25, and he staggers for 20 | The zip heavy held: ×1.25 and a knock-back (§2c) |
| | B | His signature as a zip, in its quick form | The quick form inside the rival's tell | His signature's held form |

- **The check's 20-tick lock is replaced** by its speed reading: checks can't come closer than 10 ticks apart. The sim enforces that floor, and the layout passes every press through.
- **The specials' three cuts** are Combat's to author, one special at a time.
- **On the Simple layout** Attack held is still the stance's Y. The held reading of X is the choreographer's to use there.

### A: a press and a hold

**Orb** (2026-10-05): "A should have a press and a hold, no grab spamming."

A hold is 12 ticks, and the intent carries it as `contextHeld`.

| Stance | A pressed | A held |
| :--- | :--- | :--- |
| **Martial arts** | By the situation: in reach, the grab and a quick throw. Near an object, the pick-up. Near a civilian, lifting him clear. From above, the dive grab. Otherwise the taunt | In reach, **the aimed throw:** he keeps hold for up to 30 ticks and the stick aims it. It is a knock-back and never a launch. When a blow is coming at him, his channel if he has one (On the Chin) |
| **Defensive** | The reversal after a block (20 ki). At range, the deflect | In reach, **the guard throw:** a grab from behind his guard, which beats a rival who is guarding too. At range, **the aimed deflect:** the stick sends the shot back where he points, for 10 ki |
| **Energy arts** | A mine at range. The shove in reach | At range, **an aimed mine,** lobbed up to 6 bh where the stick points. In reach, **the long shove:** 5 bh, for 10 ki |
| **Charging** | His utility special | Its held cut, for the same ki |
| **Manoeuvre** | A snatch on the fly (pick-up, civilian). From above, the dive grab | **The tackle** in reach. From the mid band, **the zip tackle** (25 ki, §2c) |

**Grabs can't be spammed.** The grabs are the grab, the aimed throw, the guard throw, the dive grab, the tackle and the zip tackle.
- **One lockout for all of them:** after any grab is tried, landed or not, he can't try another for **90 ticks.**
- **A fighter who has just been thrown can't be grabbed** for 120 ticks after he is free again.
- **A grab that misses or is beaten** leaves the grabber open for 20 ticks.
- **A press during the lockout** gives its cue and does nothing. So mashing A gets one grab and then nothing.
- Grabs cost no ki of their own. The zip tackle has the zip's price.
- The AI is held to the same lockout.
- **For QA:** two grab tries by one fighter inside 90 ticks never happen (a hard test), and grabs are at most 15% of a fighter's decisive results.

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
| The air brake and the tech | **Move** to LT: a tap techs, and a hold brakes at 20 ki a second. `agency-pass.md` §4 had the brake on Guard. The brake keeps its lock for 20 ticks after a hit (§12) |
| Context: grab, pick-up, civilians, taunt | **Stay:** martial A |
| His own channel on a held context press (On the Chin) | **Stays:** martial A, held. The intent carries the hold as a level, `contextHeld`. It is one bit, added in the same format change as the stance mask |
| The escape stance | **Gone** since the agency pass. The Escape button stays a control of its own |

**New actions.** Orb approved the check with its parry, the push and the step strike (questionnaire 17). The zips come from Orb's notes there, and their numbers are in §2c. First numbers:
- **Check:** half a light's damage, 6 ticks to contact. Mashed, checks come no closer than 10 ticks apart and are weaker (above). His guard stays up against lights and flurry blows while he throws it. A heavy still breaks a set guard (§5).
- **Parry:** a check pressed within 4 ticks after a blow lands on his guard. The rival reels for 12 ticks. It doesn't end his string, which is what the perfect block does.
- **Push:** no damage, a 10-tick wind-up, and the rival is driven back 3 bh, or 5 bh when it is held for 20 ticks. Either way the brawl's hold lets go (§2), and closing again is a player's own move. It isn't decisive. Tapped again inside 30 ticks it is a short shove (above).
- **Step strike:** a light at ×0.8 with a step of up to 2 bh around, over or under the rival, by the stick. It stays inside the brawl. Pressed within 4 ticks before the rival's contact, his blow misses. The timing mark is the rival's tell, and the director supplies it. It costs 5 ki.
- **Zip strike, zip heavy and zip tackle:** from the mid band he goes in, strikes and comes out again, for 20, 30 and 25 ki (§2c). The stick toward the rival takes him out on the far side.
- **The four signatures that aren't a beam** (§11). Their kinds are still a proposal.
- **New with the readings** (2026-10-05), with their first numbers in the tables above: the set light, the rushed and the timed heavy, the guard strike, the stuff, the volley, the aimed throw, the guard throw, the aimed deflect, the aimed mine and the long shove. They are for Orb to see in the prototype.

**Dropped from the first draft:** the brace, prime and overcharge. The charging row is the three specials, and the perfect block stays on the guard button.

## 11. Signatures: one for each stance, in three tiers

B gives every fighter his own array of signatures: one for each stance, so five in this update and eight when the hybrids arrive. Ki is the limit. There is no cap per match.

**Where this stands with Orb** (questionnaire 17). The tiers are in, with one change: the ultimate is for the last two acts only. **The five kinds are not final.** Orb: "it looks good I just want some quick charts and alternatives before this is finalized". The EP is showing Orb a chart and alternatives. Until Orb picks, "What each signature is" below is a proposal. The tiers, the cooldown and the rule for struggles don't depend on which kinds are picked.

### The tiers

| Tier | Ki | Damage, against today's signature | The pause it may take (`spec-wounds.md` §8b) | Shortest tell before it can land | Which reading of B |
| :--- | ---: | ---: | :--- | ---: | :--- |
| **Art** | 25 | ×0.55 | Live, 0.8 s | 20 ticks | **Quick:** B tapped, in any stance. **Timed:** B tapped on its mark, for ×1.25 and 1 flow at the same price |
| **Signature** | 45 | ×1.0 | Short, 1.5 s | 30 ticks | **Held:** B held for 20 ticks and let go, in any stance |
| **Ultimate** | 75 | ×1.7 | Full, 3 s | 45 ticks | The charging stance only, in acts 3 and 4: B held for 45 ticks |

- **The readings of B are its tiers** (Orb, 2026-10-05: every attack button has speed, tech and heavy modifiers). So the tier is chosen by the press and not by the stance, and every stance has a cheap form and a full form of its one signature. This replaces the first draft, where each stance had one tier.
- **The quick form is a cut of the held form:** the same authored signature, shortened. So there is still one signature to author for each stance.
- **The timed form's mark** is his own beat in the martial arts, energy arts and charging stances, where it closes a string or a volley. Its tell is 10 ticks there, because the string is the warning. In the defensive and manoeuvre stances the mark is the rival's tell.
- **Damage for each ki spent is the same in every tier,** within 10%. So no tier is the best buy. They differ in what they do and what they risk.
- **One shared cooldown** covers all of a fighter's signatures: 120 ticks after an art, and 180 ticks (3 s) after a signature or an ultimate. It starts when the signature ends. It is there only to stop two in a row.
- **The ultimate is available only in the last two acts** (Orb, questionnaire 17). Those are acts 3 and 4, so from about 3:15 (`spec-wounds.md` §9). Before then charging B gives a "not ready" cue and spends nothing.
- **No cap per match, and no cooldown of its own for any signature.** This replaces the 45 ki and 15 s limit of `agency-pass.md` §5. The 40% cut to a signature's damage made there is kept, and it is the ×1.0 in the table.
- A hybrid's signature gets the same three readings when the hybrid is designed.

### What each signature is (proposed, not final)

These are the types. Combat authors each one as a generated frame, with hand-picked pieces for the defining one.

| Stance | Type | What it does | What answers it |
| :--- | :--- | :--- | :--- |
| **Martial arts** | A melee art: his defining signature | A rush of his own strikes that ends in a launch. From the mid band it opens with a lunge | A guard takes it at reduced damage and isn't launched. A perfect block on its first blow. A dodge. Another signature, which makes a struggle |
| **Defensive** | A counter | He sets himself for up to 40 ticks. The next strike, heavy or single shot that would land is caught and answered with a knock-back. If nothing comes, the ki is spent and he is open for 20 ticks | A grab or a tackle. Waiting it out. A signature or an ultimate, which it only weakens by 30% |
| **Energy arts** | The beam | As built: the biome variants, the beam struggle and the beam answers (`rule-of-cool.md`) | As built |
| **Charging** | The ultimate | Everything he has gathered, let go at once. Its shape is the fighter's own. He is exposed through its whole tell | Any clean hit during the tell stops it, and half its ki is lost. Distance. A signature that meets it, which makes a struggle with the ultimate ahead |
| **Manoeuvre** | A terrain art | He takes hold of the rival in flight and puts him into the landscape: the ground, a ridge, the sea or a building. The launch planner picks the target with his personality term, so the hero steers away from people and the villain toward them | A dodge. A hit during its approach. A guard doesn't stop it, because it is a grab |

- **The quick and the held form of each proposed kind:**
  - *the melee art:* quick, its opening strikes, ending in a knock-back. Held, the whole rush, ending in a launch;
  - *the counter:* quick, as in the table. Held, it also catches an art and answers with a launch, and a signature is weakened by 50%;
  - *the beam:* quick, a snap beam of half a second. Held, the beam as built;
  - *the charging stance:* quick, a pulse around him. Held, the release. Held to full in acts 3 and 4, the ultimate;
  - *the terrain art:* quick, a zip in, one signature blow, and out. Held, he takes the rival into the landscape.
- **Pillar 7 holds for all five.** The stance picks the signature. The biome, the altitude and the defender's stance pick its variant. Each signature ships with at least three variants.
- **Collateral.** Each signature's damage to the world is capped by power tier, as the beam's is (`balance-targets.md` §15). The terrain art counts as a landing for structures.
- **Legal's stacking rule holds:** no moment shows more than two of the seven power-up marks (`rule-of-cool.md`, rule 9). An ultimate's staging has to fit inside it.

### What the tiers touch

- **The last stand** (`spec-wounds.md` §1b): its one free signature covers up to 45 ki. An ultimate fired there costs the other 30, and still needs act 3 or 4.
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
| An ultimate fired before act 3 | Never (a hard test) |
| Struggles a match | 1 to 4 |
| A struggle started by a light, a flurry blow or a skill strike | Never (a hard test) |
| Beam clashes | 30 to 60% of beams fired, kept |

## 12. Moving between stances

**Which stance he is in.** The layout reports which stance buttons are held, as a mask, and the sim looks the stance up (Controls, `docs/controls/lunge-control.md` A2).
- **RT dominates.** With RT down he is in the charging stance, whatever else is held. Holding RT ends a held guard, because charging is exposed. The burst on an RT tap still fires from a guard.
- LT and RT pressed within 6 ticks of each other are the transform chord, and change no stance.
- Any other pair is a reserved hybrid. Until it ships, it reads as the newer button.
- **Until the hybrids exist, a stance is exclusive.** While a newer stance button is held, the layout stops reporting the older button's own state: its guard, its energy mode or its sprint. Two things are excepted: RT's burst from a guard, and the transform chord. So sprinting while he channels is dropped for now.

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
| Manoeuvre | Entering it is a dodge. Its moves cost the most: 5 to 30 ki each (§2c). The boost costs 12 ki a second as now, and empty ki is 2 s of exhaustion. No guard |

**While he is launched, lifted or stunned** only the manoeuvre stance works (a tap techs, a hold brakes), with the Escape button. The brake can't start in the first 20 ticks after the last hit, so a juggle still pays. A hold that is already down when that lock ends starts braking on that tick.

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

**Inside X and Y the stick leans the pick** (confirmed by Orb, questionnaire 17), so a broad cell is still under the player's hand:

| Stick | What it favours |
| :--- | :--- |
| None | Hands, on a line or an arc |
| Toward | The close limbs: elbow, knee, shoulder, head |
| Away | Feet |
| Up | Rising shapes and high targets |
| Down | Dropping shapes and low targets |

It is a weight of ×3 and not a filter, so a broken limb or a repeat still falls through to the rest of the cell. A blow's wear goes to the region it lands on, so the stick is also how a player works on one region.

**The rival's hands** (Orb, questionnaire 17): fists on his heavies and blade hands on his lights. So his martial X lands with the blade hand and his martial Y with the fist. The identity split is confirmed: palms, blade hands and arcs for the Protagonist, and fists, plates and straight lines for the rival.

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
| **Set light** | X held for 12 ticks after a light lands, then let go | Light ×1.25 | 4 after the release | 20 after the release | Reeling for 12. He doesn't reel from flurry blows while he holds | 4 | No change. Its contact starts a new beat |
| **Heavy** | Y, tapped | Heavy ×1.0 | 34: 26 of wind-up and 8 to land | 76 | Lifted for 30. A set guard breaks: down for 40, staggered for 12 | 6 | No change |
| **Rushed heavy** | Y tapped again in the first 16 ticks of its wind-up, three times at most | Heavy ×0.9, ×0.8, then ×0.7 | 30, 26, then 22 | 72, 68, then 64 | As the heavy. At three taps the lift is 20 | 6 | No change |
| **Timed heavy** | Y within 4 ticks of his beat point, after a landed blow | Heavy ×1.25 | 24: 16 of wind-up and 8 to land | 66 | As the heavy, or as the ender when it closes a string | 6 | +1 |
| **Held heavy** | Y held, then released | Heavy ×1.0, rising to ×1.25 at 46 ticks of hold | 8 after the release | 96 | Lifted for 30. At a full charge: launched along the stick, or lifted for 45 with no stick | 6 | No change |
| **Ender** | Y after two or more landed blows of the string | As the heavy or the held heavy | As the heavy | As the heavy | Knocked back. Launched at flow 3 or more, at a full charge, or after a juggle of three or more | 6 | Spent by a launch, as now |
| **Juggle strike** | X within 4 ticks of the beat point while he is lifted | Light ×1.25, then ×0.85, ×0.7, ×0.55 and ×0.4 of that by its place in the juggle | 6 | 30 | Lifted again for one beat. Five at most | 4 | +1 |

- **The beat point** is 24 ticks after contact by default. Combat's values by path are accepted: 20 for a line, 24 for an arc or a rise, 26 for a drop and 28 for a spin.
- **Reach:** every form is the close band. From the mid band a lunge comes first (§2b).
- **An ender can be stopped** by three clean blows in its wind-up, like any heavy. QA watches it: enders stopped by a mashing rival should be at most 40%. If it is higher, the first lever is one more blow to stop an ender.
- **Martial B** has a quick form at the art tier and a held form at the signature tier (§11). **Martial A** keeps today's context numbers, with the aimed throw on a hold and the grab lockout (§10).
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

## 14. Orb's answers, and what is still open

Orb answered the ten questions in questionnaire 17 (`docs/ep/vision.md`, 2026-10-05).

| # | The question | Orb's answer | Written in |
| ---: | :--- | :--- | :--- |
| 1 | A lone heavy never launches | "A fully held heavy may also launch." A tapped one doesn't | §5 |
| 2 | Mashing closes with a stagger in place | Yes | §3 |
| 3 | The fighters are drawn back together after a knock-back | No. Closing again is always the player's own move | §2 |
| 4 | The beat is shown on the body | Yes, with a beat ring as an option in settings | §4 |
| 5 | A juggle of three skill strikes | Up to five | §5 |
| 6 | Pillar 2's new wording | **Not answered.** It stays as proposed | §8 |
| 7 | The five kinds of signature | **Not final:** "it looks good I just want some quick charts and alternatives before this is finalized" | §11 |
| 8 | An ultimate as soon as he has 75 ki | No. Only in the last two acts | §11 |
| 9 | The check with its parry, the push and the step strike | All three are in | §10 |
| 10 | The stick leans which limb he uses | Yes | §13 |

**Also from questionnaire 17:**
- holding LT makes mid-range lunges that zip in and out, at a great cost in ki (§2c, §10);
- a far charge becomes a slower pursuit that everyone can see, and not a taunt-only ceiling (§2c);
- the identity split is confirmed, the rival's hands are fists on heavies and blade hands on lights (§13), and his glasses are always on (`launch-pair-plan.md` §1).

**Orb, 2026-10-05, after the questionnaire** (`docs/ep/vision.md`, "modifiers on every button, and the LT zip"):
- X, Y and B have speed, tech and heavy readings in every stance (§10), and B's readings are its tiers (§11);
- A has a press and a hold in every stance, and grabs share one lockout (§10);
- a zip goes back by default, and through to the far side with the stick toward the rival (§2c);
- a well-timed tech or heavy strike counters a zip (§2c).

**Still open:**
1. Pillar 2's wording (§8).
2. The five kinds of signature (§11). The EP is showing Orb a chart and alternatives.

**Settled earlier:** B is the signature in every stance. The perfect block stays on the guard button. The transform stays its own action. The specials stay on the charging row.
