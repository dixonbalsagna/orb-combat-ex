# The two signatures: Game Design's rulings on the build spec

Owner: Game Design. 2026-11-15, on the stand-in's `docs/ep/proposals/signature-build-spec.md`: its 21 departures (§4), its 20 open rulings (§3.12) and its four draft questions for Orb (§11). Orb's signature inputs are RT + RB + a flick for the energy signature and RT + a flick for the martial one (2026-11-09). Orb's standing words: "PLAYER AGENCY MUST BE RESPECTED", and whatever comes back must complement high-speed combat.

## 1. The three that touch Orb's record or a pillar

| | Ruling | Reason |
| :--- | :--- | :--- |
| **Back-to-back signatures** (open ruling 5, departure 4): no refusal, a repeat inside 15 s slower and weaker, against the 15 s Orb set on the slider | **My recommendation is never to refuse, with a repeat inside 15 s stale:** a gather of 48 ticks instead of 30, and ×0.75 damage (103.5 instead of 138). Orb's own 15 seconds become the window in which a repeat is stale, rather than a lockout. **It changes a number Orb chose, so it goes to Orb as question 3. Until Orb answers, today's 15 s refusal stays.** My earlier 3 s shared cooldown (`melee-press-feel.md`) is withdrawn either way | Orb: "I just didn't like the cooldown", and "not a fan of cooldowns and recharging except in limited circumstances". Soft costs over caps. A stale gather is long enough for a heavy thrown on reaction to stop it, so the rival answers a spammed signature. The costs (45 energy and 30 stamina) do the rest |
| *For Legal (RL-268, condition 2), if Orb picks "never refuse"* | **A stale signature is drawn in its calm form,** RL-227's: the gather's glow, the release flare and the beam at the calm form's light, with at most one rise and fall per 2 s, and its impact inside the one envelope. **So two signatures can never strobe, timer or not.** The register's priority rule applies as written: a stale signature's light gives way first | The register's limit (at most 3 light events a second) is kept by the repeat's own form instead of a refusal. With the 15 s kept until Orb answers, nothing changes for Legal now. Flashing isn't raised with Orb |
| **The martial rush's reach** (departure 17, open rulings 14 and 19): it ends after 36 ticks, falls short beyond about 33 bh, and can be out-flown by a same-form rival | **A gap-closer, so pillar 3 applies inside its reach:** <br>- **if the rival is inside the thrower's snap reach** (the rival's well plus the edge band: 15.5 bh at base, up to 23) **when the rush starts, it always arrives**, covering what's left in the ticks it has, as the snap does; <br>- **beyond that, it's a chase** at the faster of the snap's speed and **1.15 × his own flat out**, ending when it touches or has stopped gaining for 12 ticks, with a ceiling of **90 ticks.** <br>The fixed 36-tick end goes | Pillar 3: "Attacks always close the gap, and the escape stance is a real gamble rather than a range check." My beam reach ruling named the beam as the one attack that doesn't close the gap, and the martial signature is the opposite: it's a melee move. **The rival's gamble is the gather:** 30 ticks, wholly free, in which flying off takes them out of snap reach, at the price of not answering. Thrown from far, it's a chase that can fall short, and that's the thrower's gamble, paid at the rush's first tick |
| **A flick during the RT charge fires the signature** (open ruling 3, departure 2) | **Yes** (`sigChordTicks` **0**). **Lever:** 12, so the flick counts only within 12 ticks of RT's press, if Orb's files or QA's reading 15 show signatures he didn't mean | It's the chord as Orb named it, and charging into the release is what the charge is for. **This isn't the RT + B case I ruled before:** B is a mashed button, and a B mashed while powering up mustn't fire anything. A flick under RT has no other use. The one accident (a panic flick at a rival closing in) throws an armoured gather that lights and mediums can't stop, usually not a bad outcome, at 45 energy. **Question 2 isn't asked now:** the lever is one number if the play says so |

## 2. The 20 open rulings (§3.12)

| # | Ruling |
| ---: | :--- |
| 1 | **The fighter's own top stage** (2 at base) |
| 2 | **Yes:** a fixed gather in place of the hold, half the hold and never under 30 ticks. The same at every range, never longer up close (`beam-physics.md`, S1 ruling 1) |
| 3 | **Yes,** above |
| 4 | **Yes:** a power press under threat waits up to 10 ticks for the chord (7 without the RB grace). A tapped burst is unchanged |
| 5 | Above: recommend never refusing with a stale repeat; Orb decides (question 3); 15 s until then |
| 6 | **Yes:** a held guard against the martial signature takes chip and a knock-back, not a launch |
| 7 | **No new multiplier** for a signature beam's own carve. The ×9 stays only where two beams meet |
| 8 | **A medium doesn't stop a signature's gather** (departure 18). It's stopped by a grab, a heavy already winding, a charged stick strike, or a beam that meets it. A stale gather (48 ticks) can be stopped by a heavy thrown on reaction. This is the signature's own rule: the plain beam hold keeps "a medium stops it in its first 28 ticks", because the signature is the committed, paid move, and otherwise it could never be thrown inside a brawl |
| 9 | **No:** guard and dodge don't cancel your own gather, since you committed. **No guard while gathering:** the armour against lights and mediums is the protection, and heavies and grabs land |
| 10 | **Yes:** the martial touch on a launched body is one blow and a send, once a launch, the same as the beam's one touch a launch |
| 11 | **The energy signature's line: the assist is read at the fire, not the flick.** The line is the flick's direction, re-aimed by a held stick. When it fires, it snaps onto the rival if he's still within 15° of that line, and goes where you aimed if he's moved further off. This is the same principle as the beam's assist at its release (S1 ruling 5), and the fire is 30 ticks after the flick here. **Question 4 isn't asked:** it stays inside "aimed with the stick". A rival who moves well off the line escapes, and a flick at one who stands or drifts lands |
| 12 | **Yes:** the rival's burst is live inside the string |
| 13 | **Yes:** the price is paid at the fire, or on the rush's first tick |
| 14 | Above: 1.15 × flat out beyond snap reach; always arrives inside it |
| 15 | **Yes:** the whole price is capped at **90** (`maxPrice`), and it's never refused for stamina |
| 16 | **Yes,** with Controls: a 4-build RB grace; the martial signature starts 4 builds after the crossing; its gather stays 30 |
| 17 | **Yes:** RT and RB are read physically (no release grace, no one-shot). The D-pad and a keyboard's strike keys may throw it, counted apart |
| 18 | **Yes, both turned for Alpha.** A martial struggle goes in the ideas log |
| 19 | Above: replaced by the snap-reach rule, and the 90-tick ceiling beyond it |
| 20 | **Yes:** only the two principals throw one; the rush is at the rival; the energy signature touches the first enemy body its front meets; in 2v2 each fight is its own |

## 3. The 21 departures (§4)

| # | Ruling |
| ---: | :--- |
| 1 | **Accepted:** RT + RB at the flick is the energy signature. Orb named it after Controls' grip note. Reading 5 measures the comfort |
| 2, 3 | Accepted (open rulings 3 and 4) |
| 4 | Orb's question 3, as above. 15 s until answered |
| 5 | **Accepted:** a fixed gather at every range |
| 6 | **Accepted:** aimed by the flick, with the assist read at the fire (open ruling 11) |
| 7 | **Accepted:** never less than today's 138 |
| 8 | **Accepted:** the price at the fire |
| 9 | **Accepted:** the rival is wholly free during the gather. Ticks a rival is held or moved before contact: 0 |
| 10 | **Accepted:** one martial touch a launch |
| 11 | **Changed:** inside snap reach the rush always arrives; beyond, it's a chase that can be out-flown (§1) |
| 12 | **Accepted for Alpha:** an authored beat list until the cells file exists |
| 13 | **Accepted:** both fighters fire the one beam at the third milestone. The Anti-hero's barrage waits on Combat's paper |
| 14 | **Accepted:** no biome aftermath twists for a beam in space (biome variants are on Orb's back burner) |
| 15, 16 | **Accepted** (the `guardSince` correction; `inertMasks` stays and the switch overrides it) |
| 17 | **Changed:** §1's rule replaces the 36-tick end |
| 18 | **Accepted** (open ruling 8) |
| 19 | **Accepted** (open ruling 18) |
| 20 | **Accepted** (open ruling 17) |
| 21 | **Accepted** (open ruling 15) |

## 4. The four draft questions for Orb (§11)

| # | Question | Goes to Orb? |
| ---: | :--- | :--- |
| 1 | The martial signature: a rush and a string, or one huge blow | **Yes.** It's creative and Orb's. My recommendation is the rush and the string: it shows each fighter's style and ends on the launches the game has |
| 2 | A flick while charging | **Not now** (ruled yes). Asked only if the play shows signatures he didn't mean |
| 3 | Back-to-back signatures | **Yes,** since it changes Orb's own 15 s. Recommendation: never refuse, with a repeat inside 15 s slower and weaker. **No mention of flashing** |
| 4 | Where a flicked beam goes | **No** (ruled: the assist is read at the fire) |

So two questions go to Orb, one at a time: 1, then 3.
