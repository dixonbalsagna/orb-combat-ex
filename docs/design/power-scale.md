# Power scale: one energy model

Owner: Game Design. 2026-11-01, on Orb's first play: "a physics based approach to power scaling when it comes to launches, kinetic energy, beam attacks." **Paper only. Every number is a first value, worked out by hand against the code and data, and not run.** Simulation's, World's and Combat's numbers haven't arrived yet. Physics here means consistent, not realistic: the same power always buys the same result.

## What's wrong today

**A base fighter and a maximum one can leave the same crater.** Launches are the problem: the things that make a send go further ignore power. Flight and on-screen numbers below are Simulation's measurements.

| | Today, base | Today, maximum | The fault |
| :--- | ---: | ---: | :--- |
| A heavy launch's speed | 1,600 | 2,368 | Tier adds only 48% from bottom to top |
| The hardest send (long-haul force ×3) | **4,800** | 7,100 | A base fighter can reach two thirds of the top |
| Crater radius from those sends | **600** | **600** | An ordinary blow's crater is capped, so they match |
| A launched body on screen, fastest seen | **24,569** | 15,059 | Tier doesn't order them at all. A ×6 along the line (`TRAV_LAUNCH`) does most of it |
| Flat-out flight, plain stance | 10,320 | 13,416 | Way too fast, and only 30% between them. A ×10 far from the rival (`TRAV_FREE`) does most of it. Press stance is ×1.25, escape ×1.35 |
| Beam's groove, half width | 328 | 1,032 | **This one already scales properly,** and smoothly with power |

## The model

**One number, your level.** Transformation counts for most of it and power for the rest, as you described them:

`level = 0.8 × (tier − 1) / 3 + 0.2 × power / 100`, from 0 (base, no power) to 1 (maximum, 100%). With transformations on, the top form is the top tier.

**One energy, from your level.** Each step in level multiplies it, so the top is 12.25 times the bottom:

`E = 4.94 × 12.25^level`, in the unit the crater code already uses (E = 1 is a body hitting the ground at 900 a second).

**A blow spends a share of it, and everything else follows from what's spent:**

| What | Rule | Why |
| :--- | :--- | :--- |
| **Launch speed** | `900 × √(E × share)`. A fully charged B is share 1, a tapped launcher 0.25 | Kinetic energy goes with speed squared |
| **On screen** | **Along the line, twice the launch speed,** in place of today's ×6 | So a sent body is never faster than a flat-out flyer of that level, the top only just reaching it, and a chase can catch it. The trail and the crater read the launch speed |
| **Crater** | Radius `160 × √E`, depth 0.22 of that, as the code does now. **The tier's extra term and the ordinary cap of 600 both go,** since level already counts | One path, so nothing's counted twice |
| **Through buildings** | Each building takes energy out of the body: house 1, low tower 5, tall tower or skyscraper 15. If he has less than that left, he stops inside it. What's left sets his new speed | "Careening through" is just energy running out |
| **Hitting the ground** | Steep: a crater, and at most one small hop. Shallow: **a trench, and the slide spends the rest.** At most one bounce off terrain per send, then he digs in | Orb bounced 6 or 7 times off an outcrop and wanted a crater or a trench |
| **Beam** | Groove half width `300 × 3.5^level`, depth a tenth of that. Damage to buildings goes with E. Level 1, 2 and 3 beams spend 0.25, 0.5 and 1. A signature spends 1 | Nearly today's width and depth. The damage to buildings is what changes |
| **Burning up** | A **launched** body glows from 4,500 a second, and has a full burning trail from 6,000. It's a look only | Base can't reach it, as you asked |
| **Flying** | Flat out, plain stance, `5,000 × 2.305^level`. It grows with the **cube root** of energy, the way top speed does against air drag | Faster with power, without the gap running away |

**Not in the model: wear.** Hit damage stays where it is, so a maximum send doesn't do 12 times the wear, and match length isn't tied to this page. **Signature, finisher and break launches keep their existing 9× energy** at the crater (3× the radius).

## The table

Full-charged B straight down, unless it says otherwise. Units are world units, and a body height is about 70.

| | Base, no power | Base, 100% power | Tier 2, 35% | Tier 3, 65% | **Maximum, 100%** |
| :--- | ---: | ---: | ---: | ---: | ---: |
| **Level** | 0 | 0.2 | 0.34 | 0.66 | **1** |
| **Energy** | 4.9 | 8.2 | 11.5 | 26 | **60** |
| **Launch speed** | 2,000 | 2,570 | 3,050 | 4,590 | **7,000** |
| On screen, along the line | 4,000 | 5,140 | 6,100 | 9,180 | **14,000** |
| Tapped launcher's speed | 1,000 | 1,285 | 1,525 | 2,295 | 3,500 |
| **Crater radius** | 356 (5 bh) | 457 | 542 | 816 | **1,244 (18 bh)** |
| Crater depth | 78 | 101 | 119 | 180 | 274 |
| Tapped launcher's crater radius | 178 | 228 | 271 | 408 | 622 |
| Signature's crater radius (×3) | 1,068 | 1,371 | 1,626 | 2,448 | 3,732 |
| **Goes through** | 4 houses, or stops inside a low tower | A low tower and 3 houses | 2 low towers | A tall tower and 2 low | **4 skyscrapers** |
| **Trail** | None | None | None | First glow | **Burning** |
| **Beam groove half width** | 300 | 386 | 457 | 688 | 1,050 |
| Beam's damage to buildings | ×0.12 | ×0.2 | ×0.28 | ×0.65 | ×1.5 |
| **Flat-out flight, plain stance** | **5,000** | 5,910 | 6,620 | 8,695 | **11,525** |
| The same in press stance | 6,250 | 7,390 | 8,275 | 10,870 | 14,400 |
| One lap, plain stance | 31 s | 26 s | 23 s | 18 s | 13 s |

**Checked against Orb's ends:**
- **Base never burns:** its fastest send is 2,570, well under 4,500. **This is a hard test: no send by a base or tier 2 fighter ever glows.**
- **Base straight down:** a crater about 5 body heights across each way, or half that from a tapped launcher, and a trench if it's shallow.
- **Maximum through skyscrapers:** 4, with today's table allowing 4 links at tier 4. Its speed falls as it goes, which should read well.
- **Maximum into the ground:** radius 1,244, about 2,500 across. A tower's 240 to 512 wide, so that's about five towers across, which I read as a city block. **World has to confirm that.** Whatever stands in the bowl falls in. Today the crater only digs; the falling is a new rule.
- **Maximum skyward:** 7,000 at 60° up. That matches the meteor, which already sends at about 6,600, so the meteor needs no change.
- **World's old scale page** has tier 1 craters at 150 to 450, which this meets. Its tier 3 and 4 figures are close to the signature's row here, not the ordinary send's.

## In the data

A new `data/fight/power.json`, behind a switch, off until read:

```json
{
  "level": {"tierShare": 0.8, "powerShare": 0.2},
  "energy": {"base": 4.94, "topOverBase": 12.25},
  "share": {"fullB": 1.0, "launcher": 0.25, "driverLevel3": 1.0},
  "absorb": {"house": 1, "lowTower": 5, "tallTower": 15},
  "contact": {"maxTerrainBounces": 1},
  "burn": {"glow": 4500, "full": 6000},
  "beam": {"halfWidth": 300, "depthShare": 0.1, "levels": [0.25, 0.5, 1.0], "signature": 1.0},
  "flight": {"flatOut": 5000, "exponent": 0.333},
  "launchTravel": 2.0
}
```

**What it replaces:** `ladder.json` `tiers.launch`, the crater's `IMPACT_TIER_E` and `ORD_R_MAX`, `brunt.json` `tierFactor`, `towerPunches` and `chainMax`, the beam's `structure` row, `TRAV_LAUNCH`, and the flat-out part of `TRAV_FREE`. A close-range dash doesn't change, at 1,023 to 1,330.

**The one big consequence: a send can only spend what you have.** Long-haul force and destination-first launches used to raise the force to reach a place. Now they pick among places in reach. **So base fighters stay closer to home, and the planet opens up as you power up,** which I think is right. But it moves many rows, below.

## Who has to read it

| Who | What |
| :--- | :--- |
| **Simulation** | How far a send goes at each speed, and so what's in reach at base. If base can't reach anything, base's energy goes up, up to a ceiling of 3,500 a second |
| **World** | Block size, building masses in place of my 1, 5 and 15, and whether a bowl can bring down what's standing in it |
| **Combat** | Shares for every launching move, and whether the Driver or a fighter's kit needs its own |
| **QA** | The sends, places and falling rows in §15 by tier, which will drop at low tier. The civilian band, match length, launches a match. **The hard test above** |
| **Performance** | Bigger ordinary craters and whole blocks falling, when launches already spike the frame. **A falling block may have to be spread over several frames in the view.** Orb named this: destruction has to stay smooth |
| **Legal** | A whole city block coming down at maximum, and a burning body. Both are new at this scale. **Not decided here** |

## The five rulings

### 1. Flight

**My number: 5,000 flat out at base in plain stance, up to 11,525 at maximum.** That's half of today's 10,320 at base. It sits about midway between what felt too fast and the early playable, whose flat out I take to be about 2,500 or less, though I haven't measured that build. A lap goes from 15 s to 31 s at base and 13 s at the top, so you can still reach what you called too fast, in press stance, but it takes earning. **Orb picks the base from a slider, 3,500 to 7,000,** since this is about comfort, and Camera's 70/30 split changes it. Close-range speed doesn't change. **Knock-on:** a rescue in 2v2 at base takes up to 15 s, not 6, by my arithmetic.

### 2. Charged attacks

**Overrides my "charged flicks stay bare", and Orb's right.** Once a right-stick hold is past the quick flick (0.2 s), it has B's armour, and the same goes for charging a beam on the stick:

| What lands on it | What happens |
| :--- | :--- |
| **A light** | **Never stops it.** He takes 30% of the damage, as B does |
| **A medium** | Stops it before level 2 (0.5 s), and not after |
| **A heavy, a beam or a grab** | Stops it |

**How it stays beatable:**
- A guard blocks it, with no stun.
- A dodge makes it miss, and he's open for 0.33 s.
- B, Y early, or a grab gets there first.
- It still can't break a guard, and it never sends.

The AI treats it as it treats a B winding up. This should also open the meteor's real route: a level 3 flick landed 0 times in 792 tries against the computer, because of lights. **Read:** level 3 landed 15 to 40% of the time, stick share 10 to 30%, as already ruled. **If it dominates,** level 3's stun goes from 40 to 30 first.

### 3. A foe who doesn't fight back

**Withdraw my 10 s and ×3.** It was for a pad that's been put down, and it hit someone trying things out. New: after **60 s** with no input, wear ×2, and the push for the finisher starts only after **90 s.** I haven't checked whether this is what ended Orb's match, and Tools can read it from the replay.

**Yes, the default P2 is the problem. The page starts against the computer, with Player 1 on the left and Player 2 on the right. A player slot with no pad joined is the computer, and never a body standing still.** If someone wants a dummy, that's a practice setting, and that match never ends.

**"No chance to power up" is a second fault.** Holding RT gives 0.5 power a second, so the first step takes 70 s. **`chargePerSec` 0.5 to 2:** 17.5 s to the first step, 50 s to 100%, and you're wide open while you do it. Powering up has to be a choice you can make in a fight. QA reads the tier pace.

### 4. The chase after a launch

**You don't float. The chase ends with a blow.** The press that sends you after him is the blow, and it lands as you catch him, in the air or as he lands. One press, one attack. The riding-along is removed.

**Take Encounter's proposal: while he's in the air, the far tap is the existing chase (`DirChase`), with no LT.** You rush him and a blow lands in the air. This replaces my first thought of switching on the whole rally (`rally.enabled` stays off until it's read). A chase's send spends the share of a tapped launcher, so it's within the energy model.

| | Ruling | First value |
| :--- | :--- | :--- |
| **Price** | **The first tap of a send is free.** Orb's follow-up should just work. Then the chase's price, rising each time in that chain, as a soft cost | Free, then X 20 or Y 30, ×1.5 for each one after |
| **How many** | No fixed count. The rising price does it: from a full bar you run out at about 4. **The chased fighter needs an answer,** so he can tech it with a guard press, by the rally's table: 4 ticks, then 6 for a kind used before, 8 for the same one again, and the third of a kind is teched by itself | If the tech isn't cheap to take from the rally, the price alone for the first read, and that's a known gap |
| **A press during the rush** | **It picks the blow,** and the newest press wins: X the strike, Y the heavy, **B drives him down,** at Y's price, so a chase can end in a crater. It never queues another chase. The stick leans the send, as it does now | After the blow lands, a press inside 0.33 s starts the next chase. No press and you peel off |
| **On the meteor's curve** | **Not alongside: the apex spike (row 7).** A tap on the way up rises with him and meets him at the top, wherever you pressed, and any press sends him down the rest of the curve, landing earlier. One a curve, no chase after it, no extra wear, and it can't end a match. A tap after the top flies to his landing, for the first move | If the spike costs too much for now, every tap on the curve goes to his landing. Under half of meteors should get a spike, as row 7 says, so waiting stays a choice |

The hint keeps its line, and gains: "It lands as you catch them."

### 5. Teaching the beam

**The likely cause:** a flick with RB is a quick blast, and only a **hold** is a beam, so a beginner flicks and never sees one. RB also needs to be held, and it costs energy. So, using only the small panel on the left that already appears with RB:

1. **While RB is held,** the panel says: "Hold right stick: beam. Let go to fire."
2. **If you haven't fired a beam after 45 s,** the panel says it once, on its own, then stops. It goes away for good after your first beam.
3. **When you flick with RB,** the panel says "Hold for a beam" for a moment, the first three times.
4. **If you've got no energy,** the pad knocks and the panel says "Needs energy".
5. **The computer's first beam** teaches the answer: "RB + right stick: fire back", once.

Nothing goes on or over the fighters. It's for UI, and the look gate.

## One correction from me

**My 9-body-height kick-back during a beam's charge is withdrawn.** Orb: "when I fire a beam, the character slowly drifts in a direction, then fires. I don't like this... the fighter should more or less remain stationary." Encounter found the drift was the charge's existing rise, not my kick-back, and `front.stationary` removes both. **New rule:** the shooter stays put. Hold to charge, let go to fire.

**Up close, a shove at the fire, not a shorter floor.** The 0.6 s floor is what lets a person react, so it stays. From under 9 body heights, the beam's firing throws the **other** fighter back to 9 over 0.25 s, ahead of the front, like a shock wave. No damage and no stun: he keeps his hands, so he can still answer. That gives the front about 1,000 a second, and fronts that meet between them. It stops at a wall, and then the front simply arrives sooner. It goes through the look gate, and if it looks wrong, Orb's eye decides between this and a shorter floor.

**While holding a beam, you barely move.** Past the quick flick (0.2 s), the left stick moves you at **10% of normal flying speed, with no dash,** so you can adjust but not travel. A dodge or guard press still cancels it. A flick's quick blast moves you as normal. **The kite's charged beam, built while sprinting, is withdrawn** for now, as it's the opposite of what Orb asked for. Charged strikes aren't beams, so they keep their movement.

`beam-answers.md` and `rule-of-cool-map.md` are marked.

**Orb's first fight:** the EP reports that Orb's pad joined as Player 2 by accident, so they were hitting an idle Player 1. **The seat is the bug: the first pad to press is Player 1.** My change to idle wear stays, at low priority: 10 s also catches someone who's just put the pad down.
