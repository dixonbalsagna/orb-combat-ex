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
| **Launch speed** | `900 × √(E × share)`. A fully charged B is share 1, a lit launcher 0.5 | Kinetic energy goes with speed squared |
| **On screen** | **Along the line, twice the launch speed,** in place of today's ×6 | So a sent body is never faster than a flat-out flyer of that level, the top only just reaching it, and a chase can catch it. The trail and the crater read the launch speed |
| **Crater** | Radius `160 × √E`, depth 0.22 of that, as the code does now. **The tier's extra term and the ordinary cap of 600 both go,** since level already counts | One path, so nothing's counted twice |
| **Through buildings** | Each building takes energy out of the body: house 1, low tower 5, tall tower or skyscraper 15. If he has less than that left, he stops inside it. What's left sets his new speed | "Careening through" is just energy running out |
| **Hitting the ground** | Steep: a crater, and at most one small hop. Shallow: **a trench, and the slide spends the rest.** At most one bounce off terrain per send, then he digs in | Orb bounced 6 or 7 times off an outcrop and wanted a crater or a trench |
| **Beam** | Groove half width `300 × 3.5^level`, depth a tenth of that. Damage to buildings goes with E. Level 1, 2 and 3 beams spend 0.25, 0.5 and 1. A signature spends 1 | Nearly today's width and depth. The damage to buildings is what changes |
| **Burning up** | A **launched** body has a thin edge in its own colour behind it from 4,500 a second, and a full burning trail from 6,000. It's a look only: never an aura around him, never gold, white or red, and he's never shown hurt by it | Base can't reach it, as you asked |
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
| Lit launcher's speed | 1,414 | 1,817 | 2,157 | 3,246 | 4,950 |
| **Crater radius** | 356 (5 bh) | 457 | 542 | 816 | **1,244 (18 bh)** |
| Crater depth | 78 | 101 | 119 | 180 | 274 |
| Lit launcher's crater radius | 252 | 323 | 383 | 577 | 880 |
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
- **Base straight down:** a crater about 5 body heights across each way, or about 70% of that from a lit launcher, and a trench if it's shallow.
- **Maximum through skyscrapers:** 4, with today's table allowing 4 links at tier 4. Its speed falls as it goes, which should read well.
- **Maximum into the ground:** radius 1,244, about 2,500 across. A tower's 240 to 512 wide, so that's about five towers across, which I read as a city block. **World has to confirm that.** Whatever stands in the bowl falls in. Today the crater only digs; the falling is a new rule.
- **Maximum skyward:** the meteor. **My "about 6,600" was wrong for what you see.** Simulation measured 12,821 on screen on its first tick and 9,777 mid-flight. **The meteor is its own thing:** an authored curve, whose on-screen speed is pacing, not the launch speed. It stays inside the model's 14,000 top. For its crater, buildings and energy it counts as the model's top, 7,000. **Its trail burns in full for the whole curve,** whatever the speed reads at that moment. The high arc's the same. `game-design.md` §12's figure is the older sum.
- **World's old scale page** has tier 1 craters at 150 to 450, which this meets. Its tier 3 and 4 figures are close to the signature's row here, not the ordinary send's.

**A narrower beam cuts deeper: yes** (Combat's question). The same energy over a narrower line digs the same amount of ground. For a beam of width `w` (0.4 to 1.2):

`half width = 300 × 3.5^level × √share × w`, and `depth = 30 × 3.5^level × √share ÷ w`

| At maximum, full share | Half width | Depth |
| :--- | ---: | ---: |
| Hem Sweep, ×0.4 | 420 | **262** |
| The reference, ×1 | 1,050 | 105 |
| Breakwater, ×1.2 | 1,260 | **88** |

Even the thinnest beam stays just under a full send's crater at the same level: 262 against 274 at the top, and 75 against 78 at base. So no separate cap is needed. **Only the groove changes.** Damage to buildings stays one number for every width, inside Legal's ×1.5. It's a look and terrain rule, through the look gate. The beam's width is its `w` for the dig, so a look that's only drawn wider doesn't count.

**A repeat launch doesn't go as far as the first** (Encounter's question). **Simulation reports this has no effect yet with the switch on, so it's still to do.** Freshness stays, and it works inside the model: it multiplies the launch's **share** by `fresh²`, with `fresh` worked out as it is today (×0.9 for each launch of that kind on him in the last 60 s, ×0.97 for any kind, never under 0.7). So its speed falls by `fresh`, exactly as today, and everything else follows from the energy spent: at the floor, the speed and crater radius fall to 0.7 and the energy to 0.49. **So `fresh.destruction` goes:** there's now one path, and a slower body breaks less. The meteor's and the high arc's curves are fixed shapes, so freshness doesn't touch them, and their budget limits them instead.

**The lit launcher, on Simulation's measure.** At a share of 0.25 it carried only 1,150 across at base: a building half the time and little else, and less than a charged knock-back's share, for the reward of an opening. **Raised to 0.5.** Simulation measured about 1,800 across at base (2,300 is the far end of its spread). **That's fine:** it's the next building or two along the street, and it keeps base fights local, which the chase depends on. If QA's base-tier rows show sends reaching nothing, this share is the first lever. **A full B at base only just clearing the long haul (3,200) is what I want:** the far planet opens up with power. So a charged knock-back and a lit launcher spend the same: one's earned by waiting, the other by an opening.

## Where a beam struggle does its damage (2026-11-02)

Orb, on Camera's clash clip: "the center where the beams collide would have the biggest shockwave, possibly causing a crater underneath", not the building by the fighter on the left. **Agreed. In a struggle, the damage goes where the beams meet.** One ruling, on VFX's sketch (`docs/vfx/clash-shockwave.md`) and World's plan (`docs/world/struggle-meeting-point.md`). First values, unplayed.

**What World found today:** a struggle does nothing while it runs. Only a detonation (37%) digs at the middle, and time endings (60%) dig nothing at all. **So most struggles leave no mark,** and the one building that fell was most likely the winner's beam carving outward from his own hand.

**The rule:**
- **The beams carve as normal until their fronts meet, then stop.** While locked, neither beam damages anything along its length, so all the energy goes into the meeting point.
- **While it runs:** VFX's ground ring grows from 1 body height to 3, with at most one ring every 2 s. Under it, World's scorch, dust and ring events, so it's seen building. Buildings inside that small ring take the beam's building damage, under Legal's ×1.5 cap. **World's groove under the moving point:** yes, as a shallow scorch only, on its own switch, after the crater's in.
- **At the end, once, every ending:** one wave, one rise and one fall, and the crater dug in a single step under the point.

**World's four numbers, in the energy model:**

| | Ruling |
| :--- | :--- |
| **The energy, E** | Both beams' energy from the model, each its stage share. **Not World's ×9 on both, unless one of them is a signature,** since a signature's own hit already has ×9, and the meeting point shouldn't be smaller than a signature's hit. Two plain beams use the model alone |
| **f_end, the share dug** | **Detonation 0.5. Time 0.25. Overwhelm and letting go: 0.25 × how much of the 5 s it ran.** So every ending digs, a detonation most. In radius terms, the clash factor k is 0.71 and 0.5, as VFX asked |
| **heightReach** | **Twice the crater's own radius,** with the energy reduced by `1 − height ÷ heightReach`, taking the point's lowest height in the last second. Above that it's a burst in the air: the ring and a scorch, no bowl |
| **An overwhelm's carve** | **From the meeting point outward, not from his hand.** The stretch between his hand and the point was spent in the struggle. So the winner's beam carves from the point, through the loser, and blasts him where he lands |

- **The wave's radius matches the crater's.** Inside it, tower glass blows out and buildings take the release's damage, through the crater's fall rule, falling off from the centre. **So the middle takes the most, and a building beside a shooter only falls if the wave reaches it.** The dust dome stays local, at most 6 body heights across.

| Both at | Two plain beams: time, detonation | One a signature: time, detonation |
| :--- | :--- | :--- |
| Base | 250, 356 | 750, 1,066 |
| Tier 3 | 577, 816 | 1,731, 2,448 |
| **Maximum** | **880, 1,244** | **2,640, 3,733** |

These are crater radii, at ground level. The biggest, two signatures detonating at maximum, matches a signature's own hit at the top, so it's the biggest mark of the exchange, as Orb pictured.

**For the builders:** Encounter's grant lines and its end-of-struggle event. World's `struggleMeet`, off. VFX's ring, wave and dust, through the look gate and both flash modes. **Legal sees it before it's built,** as World says: a bigger central blast in a street brings down more buildings, through RL-232, RL-242 and RL-243. QA re-reads the civilian band at the top tier with it on, never tuned toward.

### By stage, as data for World (2026-11-07)

The rule above stands. **What's new is the size by each beam's stage**, now that beams have the stage ladder (`beam-answers-2.md` §1).

**Size.**
- **Each beam brings its fighter's energy times its stage share:** `E(level) × stage ÷ stageCount`. The top stage spends all of it, as the ladder rules.
- **E_meet is the two added,** ×9 only if either is a signature.
- **The dug energy** is `E_meet × f_end × f_height`.
- **Radius** is `160 × √(dug energy)`, with depth 0.22 of it, dug once under the point by `WorldCrater.dig`.

**When.**

| Phase | What happens |
| :--- | :--- |
| **Fronts meeting** | The beams have carved their paths up to here, as normal. From this tick neither beam damages anything along its length |
| **During the struggle** | **No digging** (`perPulse` 0). VFX's ground ring grows from 1 to 3 bh, at most one every 2 s, with World's scorch and dust under it. Buildings inside that ring take the beam's building damage each ring, under Legal's ×1.5 cap. The groove under a moving point is a scorch only, on its own switch, after the crater's in |
| **At the end, every ending, once** | One wave and the crater, in a single step |

**Buildings.**

| Where | During | At the end |
| :--- | :--- | :--- |
| **Within the ring at the point** | The beam's building damage each ring | The release's damage through the crater's fall rule, **falling off from the centre,** within the wave |
| **Within the wave's radius** (the crater's radius from the point, on the ground below it) | Nothing | The release's damage through the fall rule, using the dug energy, so the height cut applies. **Tower glass blows out** out to the radius before the height cut, so an air burst shatters windows and fells nothing |
| **Beside the shooters, outside the wave** | **Nothing.** The beams stopped carving at the meeting | **Nothing,** unless the wave reaches them |
| **On the loser's side, after an overwhelm** | | The winner's beam carves **from the point outward,** through the loser, and blasts him where he lands. The stretch from the winner's hand to the point gets nothing new |

- **Structures only,** with no people term and no reward, under RL-232, RL-242, RL-243 and RL-246.
- **The dust dome:** at most 6 bh across.

**Crater radius by the two stages, at ground level.** Overwhelm and let-go are `0.25 × run ÷ 5 s`, so after a full 5 s they equal time, and after 1 s they're under half of it.

| Both beams | E_meet | Time | Detonation | Overwhelm after 1 s | With a signature: time, detonation |
| :--- | ---: | ---: | ---: | ---: | :--- |
| Base, stage 1 of 2 each | 4.9 | 178 | 251 | **80: a scorch only** | 533, 754 |
| Base, both full | 9.9 | 251 | 356 | 112 | 754, 1,067 |
| Tier 3 at 65%, stage 3 of 5 each | 31.2 | 447 | 632 | 200 | 1,341, 1,896 |
| Tier 3 at 65%, both full | 52.0 | 577 | 816 | 258 | 1,731, 2,448 |
| Maximum, stage 2 of 6 each | 40.3 | 508 | 719 | 227 | 1,524, 2,156 |
| Maximum, one full against a base full | 65.5 | 647 | 915 | 289 | 1,942, 2,746 |
| **Maximum, both full** | **121** | **880** | **1,245** | 394 | **2,640, 3,734** |

- **The biggest, two full signatures detonating at maximum, still equals a signature's own hit at the top.** So the meeting point is the biggest mark of the exchange, and never bigger than the biggest hit.
- **A bowl smaller than about 1.5 bh (110 units)** would read as a dent. It's a scorch and the ring instead: `minE` 0.47 on the dug energy.

```json
{
  "struggleMeet": {
    "enabled": false,
    "energy": { "perBeam": "levelEnergyTimesStageShare", "sigMul": 9, "sigMulIf": "either" },
    "fEnd": { "detonate": 0.5, "time": 0.25, "overwhelm": 0.25, "letGo": 0.25 },
    "fEndByRun": { "endings": ["overwhelm", "letGo"], "fullRunSec": 5 },
    "radius": { "k": 160, "depthShare": 0.22 },
    "heightReach": { "ofRadius": 2.0, "heightFrom": "lowestInLastSec" },
    "minE": 0.47,
    "perPulse": 0,
    "during": { "ringFromBh": 1, "ringToBh": 3, "ringMinGapSec": 2, "ringBuildingDamage": "beam", "carveAlongBeams": false },
    "wave": { "radiusOfCrater": 1.0, "fallOff": "fromCentre", "glassRadius": "beforeHeightCut", "dustMaxBh": 6 },
    "overwhelmCarve": "fromPointOutward"
  }
}
```

World's own keys stay where World put them (`data/biomes/craters.json`). This block is the numbers. **This replaces World's first draft:** the ×9 on both beams, and f_end of 1.0, 0.6 and 0.5.

## In the data

A new `data/fight/power.json`, behind a switch, off until read:

```json
{
  "level": {"tierShare": 0.8, "powerShare": 0.2},
  "energy": {"base": 4.94, "topOverBase": 12.25},
  "share": {"fullB": 1.0, "launcher": 0.5, "driverLevel3": 1.0},
  "absorb": {"house": 1, "lowTower": 5, "tallTower": 15},
  "contact": {"maxTerrainBounces": 1},
  "burn": {"glow": 4500, "full": 6000},
  "beam": {"halfWidth": 300, "depthShare": 0.1, "levels": [0.25, 0.5, 1.0], "signature": 1.0, "depthDividesByWidth": true},
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
| **Legal** | Read: RL-232, below. Stays open until QA has read the civilian band at maximum and the flash clips and look gate have passed |

## Legal's limits (RL-232, `docs/legal/review-log.md`)

Fine with these limits. All of it ships through the look gate and the flash clips in both modes.

**The block falling at maximum.**
- **It falls by the energy spent, never as a chosen place.** No AI, picker or landing score reads a block's size, occupancy or population. The filter for schools, hospitals and places of worship reaches this fall too.
- **No ceremony:** no slow motion, zoom, held shot, sting, score popup, or line about the dead. No person is on screen in the bowl, and no civilian is shown dying. The toll is the existing number, with no new count, line or reward.
- **Light:** it's one event, even when the fall is spread over several frames. It rises over at least 0.3 s and falls over at least 1 s, with a calm form under Reduce flashing, measured by day and by night.
- **Dust stays a local cloud,** never a wash across the screen that darkens the sky.
- **QA** re-reads the civilian band (12 to 30% at the KO) at maximum with the fall on, plus the civilians-removed run.

**The trail.**
- It follows RL-222: a ribbon from the body, trailing behind, with its head width capped.
- From 4,500 it's a thin edge in the fighter's own colour, behind the body. **Never an aura,** and a glow on or around the body counts toward the stacking limit.
- **Never gold, white or red.** The body is never charred, aflame, or shown hurt, and the heat doesn't kill him.
- Only a launched body burns. **Base and tier 2 never glow,** and the hard test stands.

**The beam.**
- **Its damage to buildings is capped at ×1.5,** and any rise goes back to Legal. It acts on structures only, with no people term and no reward.
- It can raise falls and so the toll, so QA reads the civilian band at tier 4 with it on.

## Hit weight

**Combat's table, in `press-decides.md`,** replaces the one I first put here.

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

**The chain, on Camera's read** (at base, 4 tapped chases got 1 catch, as he lands first; at the top, a full B is the meteor, and its taps got no blow). **Not what I want at base. It's fine for the meteor, except that a tap must never go unanswered.**

| | Ruling | First value |
| :--- | :--- | :--- |
| **At base** | **A chase's blow holds him up, whatever his energy.** A catch gives him at least a set time in the air before he lands. It's a hit's hang, not more energy: he still goes a short way, so it's a small fight in the air, and the planet doesn't open up | At least **40 ticks** in the air after each catch, unless it's B driving him down. Aim: 2 or 3 catches at base, 3 or 4 at the top, as ki allows |
| **The meteor** | It's a chapter break, so **no chain from it, as ruled.** Chains belong to ordinary sends: a lit launcher at the top flies 4,950 and has plenty of air. **Camera re-reads the top on a lit launcher** | |
| **A tap that reaches a landing** | **It's a blow, not just an arrival.** Your press lands as he gets up, as an ordinary blow he can guard, so Orb's follow-up always hits something. It replaces "for the first move", and it's the stand-in until the apex spike is built | As he rises, after his usual 0.35 s down |

**The hang's floor (2026-11-02): `chase.tap.hangMinPace` 0.25.** The 40-tick hang must never be a near-still float: that's what Orb disliked. With the floor, the bodies always move at least a quarter of the send's own pace, so a low catch whose send would land at once hangs only about 5 ticks and lands. Then the next tap is the blow as he rises. The 40 ticks still holds for any catch with real air under it.

**The meteor's peak shot, with the fighter 3 to 4 pixels high at 720p: acceptable for that moment.** The picture is the planet and the trail. **The conditions:** under 6 pixels for no longer than about 2 s around the top, the trail unbroken and in frame, and the view back in before he lands, with the fighter easy to see in the last second. Orb's eye decides, from the clip.

**Teaching it.** The game has no hint for this yet: I meant the line in Orb's first-play sheet, in the homework folder, which isn't in `ui/`. So it's a new panel line, in the small left panel, with the chase switch on: "Tap an attack to chase. It lands as you catch them." It shows after your own launch, for as long as a tap would chase, the first three times in a match. Then it stops until the next match. The sheet's line gains the same words.

**On a keyboard, the beam's line names the keys:** "Hold the arrows: beam. Let go to fire", with the arrow glyph, or the bound keys if they've been changed. "Strike keys" is our word, not a player's.

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
