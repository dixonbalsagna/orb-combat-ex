# A combo builder for custom fighters

Owner: Game Design. 2026-11-01. **A page for Orb to read, updated on Orb's direction. It's still paper: nothing's built or played, every number is a first value, and none of it touches the first playable.**

Orb's idea: mashing should count as part of a combo, and a custom fighter learns combos from a pool of attacks, starting with Grist in training. Orb's direction since (`docs/ep/vision.md`, last entries): a **hybrid** that takes the best of "fixed button patterns whose last hit changes with where you're standing"; **only a minimal disadvantage** for a fresh custom fighter in versus against a roster fighter; and deep pools of swappable moves, each tied to a damage type, with lore, graded on several levels such as knock-back force and the ratio of ki to physical force.

**This changes one thing I wrote before.** I said custom fighters should use learned combos only. A fresh fighter would then have almost nothing, which breaks "minimal disadvantage", so I withdraw it.

## 1. The hybrid

**One rule for everyone: a combo is a fixed pattern of presses, and the place you're standing finishes it.** The pattern never changes, so you can learn and rely on it. The last hit changes by place, so it stays a surprise you caused. A mash, a hold and a tap all count as parts.

| | Roster fighter (Grist, Loupe and the rest) | Custom fighter |
| :--- | :--- | :--- |
| **Patterns from a seed** | 8 to 12, written once, the same for every player | **8, written when you create them, from a school you pick.** So they work from the first minute |
| **Learned combos** | None. Every player meets the same Grist | **A belt of 3,** kept for good. A learned combo that uses the same presses as a seeded one takes its place, so nothing's left to clash |
| **The place's ending** | Each pattern has an ending for each kind of place | **The same for seeded patterns. A learned combo's last move brings its own place reaction** for two or three kinds of place, with the generic ending elsewhere, so there's far less to author |
| **Everything else you press** | The generic pool, as now | The same |

**So the difference is who wrote the list, not how it works.** Everything runs on one system, which is the one in the first playable (map row 1). Learned combos cost little more on top of it.

**The ending also reads the attack's damage type** (§3). The same combo over water might skip him if it's mostly body, or raise a column of steam if it's burn or mostly ki. That's where the depth comes from: pattern × place × type, without any more for a player to memorise.

**Research's loop, which I'd take** (`research/rule-of-cool/combo-builder.md`): **three combos on your belt, kept for good, with upgrades that last for that run only.** What you know is permanent, and how strong it is resets. A teacher offers one of three after a big moment, always with "keep what I have". A combo you replace stays in your book. That also keeps the rule that no stat carries past a run, so I withdraw that item from what breaks.

## 2. Fairness: what a fresh custom fighter starts with

**In versus, a fresh custom fighter has:**
- 8 seeded patterns from their style, at the same worth as a roster fighter's;
- the full generic pool and the whole control scheme;
- an energy kit at the middle of every band, which is what the reference fighter already has;
- the same ladder of power as anyone, and one plain transformation track until a better one's designed;
- **the whole pool of combos open for their belt, at base values.** No run upgrades count. A campaign never buys an advantage in versus.

Both players see each other's three combos on the loading screen, and the choice travels in the match's setup, so replays and online stay exact.

**What they'll still lack,** and why it's "minimal" rather than none: a roster fighter's own mechanic, their signature and their hand-tuned look. That's what makes the roster worth playing, and I wouldn't flatten it.

**The test, with numbers.** QA runs a fresh custom fighter on default choices against each roster fighter, hard AI on both sides, sides swapped, about 400 matches a pairing, which gives roughly ±5 points. First values:

| Row | Bound |
| :--- | ---: |
| **Win rate against every roster fighter** | **At least 45%,** and at least 47% averaged across the roster |
| **The other way: it mustn't be the best pick** | No more than 55% against any roster fighter |
| **A fully played fighter in versus against a fresh one** | No more than 52%, or the campaign's leaking into versus |
| **Any one combo on a belt** | Its win rate within 45 to 55%, and picked under about a quarter of the time once players exist |

**AI against AI can't prove this for people,** since an AI uses neither phrases nor a belt the way a person would. So it's a floor, and the real read is people's: QA's masher arm first, then Orb's hands.

## 3. The move sheet

**Built on Research's `research/rule-of-cool/move-pools.md`,** which has five worked examples. I've taken its shape: **about 50 moves first** (three schools × six jobs × about three), about ten of them showpieces with new poses, and the rest from the generator on existing poses. That's about one to two weeks of Animation by Research's estimate, plus Legal's screen of each new pose.

| Field | What it says | Notes |
| :--- | :--- | :--- |
| **School** | A way of fighting, with a lean toward ki or body | Where lore attaches. **A custom fighter's starting style is a school,** so their 8 seeded patterns come from it |
| **Job** | One of six: send, stun, break guard, move him, launch, linger | **Limits where it can go:** a send or launch only on B. **B sends, and the stick never does.** No move overrides that |
| **Six grades, −2 to +2, adding up to 0** | Knock-back force, speed, reach, stun, guard damage, worth | **The budget.** A machine checks it |
| **Ki-to-force ratio** | How much of the blow is ki. **Mostly body:** dust, cracks, a deep thud, more knock-back, more wear on buildings, and a guard stops it. **Mostly ki:** a lit limb, a higher sound, less knock-back, more through a guard, more ki spent, and more reaction from the place | **Orb's ratio,** outside the budget because it changes what the move does. Both ends must come out even, which QA reads |
| **Damage type** | **Impact** moves him and breaks structures. **Pierce** gets through a guard. **Shock** stuns and wears the limb it hits. **Burn** lingers, and reacts to trees and water | **Research's four replace my draft.** No chart: none is strong against another. Shock is a word, not a look: **no lightning** (Legal's aura rule) |
| **Launch angle** | Flat, low, steep or none | Visible at once |
| **Place reaction** | What it does in a wall, on water, in trees, on ice | **This is the hybrid's ending** (§1) |
| **Twist** | One rule-breaking thing per move | The rule of cool. See below |
| **Body, poses** | The generator's limb, tip, target and path | Joint limits and Legal's banned list apply |
| **Lore, name** | Filled from Orb's blanks, after the move works | Original only. Never claims to be a real school or art |
| **Sound, hit-stop, camera** | Set by family, not by move | Never shown. Flash is read by family, which is the big saving |

**What a player sees:** five bars (force, speed, reach, stun, guard), a mark for the ki lean, one sentence and a four-second clip, on one menu screen and never over the fighters. Worth is in training only, since players barely feel it.

**The three calls Research flagged, ruled.**
1. **No stronger rare tier: agreed, in every mode.** A rare move can only be stranger. Zero-sum stays for good, or new moves slowly kill old ones.
2. **Upgrades add a choice: agreed for anything permanent.** A kept upgrade is a different version of a combo, never a better one. **Upgrades that last one run can be real strength,** and that's where the campaign's growth lives. None of it reaches versus.
3. **"Can you say when you'd pick it without quoting a number?": yes, as a gate.** A person watches the clip and says it in a line. A move that fails is cut, however well it balances. That's the guard against fifty moves that play as five.

**Where I've tightened Research's rules.**
- **Grades aren't equal until they're tuned.** Research says it too: speed may be worth more than anything, so +1 speed isn't +1 worth. Zero-sum is only true once real fights set the numbers behind each grade. **A −2 must never be a trap,** and QA's pick and win tracking is the real judge.
- **A twist can be a hidden strength,** since the budget can't see it. "Your next blow bites harder" is power. So every twist runs through the same win and pick bands, and one that's too good gets a grade cut.
- **Keeping to one school gives no mechanical bonus.** Research floats a small effect for three matching combos, but that's a strength outside the budget. It gets a look and a rival's line, and straying is just as valid.
- **Speed has floors.** Grades can't push a stick strike's wind-up under its ruled floor or below the lockouts, so the claw law holds. The bot checks the whole pool.
- **The seeded patterns and the generic pool keep today's rule,** that a generated move changes the look and never the worth. Only pool moves carry grades.

**Does the budget limit what Orb asked for? Yes, in one way, and plainly:**

- **It gives you:** moves graded on many levels, including knock-back force and the ratio of ki to body, each with its own job, type, twist and lore.
- **It rules out, in versus:** a move that's simply better. No legendary attack that's great at everything, and no moves that climb from bronze to gold. The strongest possible move still pays for its strength somewhere.
- **What's left for "feels overpowered":** spectacle costs nothing, so a +2 force move can look and sound enormous. The twist can break a rule. And in the campaign, a run's upgrades can really make you stronger.
- **So if "graded" meant better and worse moves,** that's only possible in the campaign. It's your call, below.

## 4. What still breaks

1. **"Only cosmetics unlock; everything that changes play is open from the start"** (`unlocks.md`, from questionnaire 3). Swappable moves imply a change, but Orb hasn't said so. This is the one question below.
2. **"Pick one of three" can't be a random roll,** since unlocks rule that out. The offers are fixed by where you are in the story. Legal should look.
3. **Balance rests on the budget,** since every combination can't be tested. A bad row could reach versus until QA catches it.
4. **A hold-to-flurry assist has to count as a mash,** along with remapping and Simple mode. Research says this is needed from the start, and I agree.
5. **Deep pools are real art.** Unique moves mean new animation, so the first ones reuse pieces and the generator helps. That's the main cost of "deep", and it's why this stays well after the first playable.

## 5. The smallest test

**Unchanged, after the first playable and with phrases in:** one stand-in custom fighter, one fight against an AI Grist in training, and a pick of three: Hold Y then Mash X, Tap X then Hold B, and Flick up then Mash X. They use existing pieces, with the buttons shown at the frame's edge, and no save or upgrades. **The question it answers:** by the second minute, are you using your combo on purpose, and do you want to try another afterwards?

## Two questions for Orb

Neither needs answering until you've seen UI's mockups.

1. **"Only cosmetics unlock" was your rule. Should moves now unlock in the campaign for custom fighters, with versus staying fair by opening the whole pool to everyone?** My recommendation is yes.
2. **By "graded on multiple levels", did you mean moves that differ in many ways, or moves that can be better and worse?** I've assumed the first, so that a fresh fighter isn't behind. The second can only happen in the campaign.
