# The press decides

Owner: Game Design. 2026-11-01, for Orb's "getting knockbacks feels very arbitrary", "better combo control", "hard to charge up an attack when every hit seems to interrupt", and the circle that "felt cool". It rules Combat's corrected `docs/combat/press-read.md` and Encounter's `docs/director/second-play-read.md`, both now on Orb's exact match. This replaces my earlier versions of this page. **Paper only, every number's a first value, and each rule has its own switch.**

| # | The rule | Ruling |
| ---: | :--- | :--- |
| 1 | One rule for B: how long you held it decides | **Yes.** It replaces my "launch anywhere on" |
| 2 | A released charge can't be walked away from | **Yes,** and do it first |
| 3 | A press waits for the blow in hand: one slot, newest wins | **Yes.** It replaces my sooner, weaker next blow |
| 4 | A move you own for the circle | **Yes, but the input waits** for Orb to pick from three clips |
| 5 | A hold builds during your own blow | **Yes** |
| | A charge keeps half when it's hit | **Withdrawn.** Orb's holds of B were hit only 5 times in 218, so it fixes nothing |

## 1. One rule for B

**How long you held it decides, everywhere: in a brawl, or starting one.**

| You hold B | It always does | Share of your energy |
| :--- | :--- | ---: |
| A tap | **A stagger** | 0.125 |
| A tap with B lit, in the moment after a close or a broken guard | **The launcher** | 0.5 |
| Past the first flash (0.53 s) | **A knock-back** | 0.5 |
| To the full flash (0.73 s) | **A send** | 1 |

- **A tapped B's own stagger doesn't light B.** It would make two taps a launch, and nobody would ever charge. The launcher's existing 30 s rest stays too.
- **Your left stick says which way.** If it's neutral, the director picks. The hint should say so.
- **The hidden rule goes.** Flow, string counts and blows taken no longer decide whether you get a knock-back. They can pay for something else later.
- **Launch anywhere stays off.** It would light B after every clean blow, and it has history with short matches. Keeping today's window (10 opened in Orb's match) is the smaller change. It's the next lever if sends are too rare.
- **The lit B is the one exception, so it has to be seen:** on the fighter as his own glow, and on the legend at the edge.
- **Shown on the fighter and the pad:** his glow steps at each flash, with Controls' rumble ladder. **Nothing over him.**
- **A blow that misses or is stopped says so,** with its own sound and rumble, as a refused press does.

**Today, only 18 of Orb's 130 B blows staggered, so this is a big rise, and how a brawl reads is the first thing to check.** A stagger on every clean tap has to feel like weight, not a stutter. **QA reads:** time in a brawl (at least 50%), B's share of blows for a free-choice bot (at most 40%), launches a match, match length, the masher row and the newcomer. **If tapped staggers break up the brawl,** the stagger goes from 12 ticks toward 8. The rule stays. **If there are too many,** first lower a send's share of the planet's reach, and leave the rule alone. Repeat launches already fall off by freshness. **The player's press has to stay sure,** so no rest period on a full charge.

## 2. A released charge can't be walked away from

**Do this first: it's the smallest, and it's what failed Orb.** The one time they held B to full, the rival walked out of reach.

- **A released charge closes the gap.** Past the first flash, it reaches **3 body heights.** At the full flash, **6.** That's the blow travelling, over at most 12 ticks.
- **Right-stick holds too:** from stage 2, 3 body heights, and from stage 3, 6. It still never sends.
- **What still beats it:** a real dodge, a guard, or a perfect block. Stepping back doesn't.

## 3. A press waits for the blow in hand

A quarter of Orb's presses were thrown away, because a press only waited 10 ticks, and a medium takes 12 and a heavy 28.

- **A press waits until your blow finishes,** however long that is. **One slot, and the newest press wins,** so mashing Y then B gives you B.
- **It clears** if you're stunned or the brawl ends. So a press never comes out long after its moment.
- **It isn't sooner or weaker.** That was my first idea, and I've kept it as a lever, as this alone may be enough.
- **QA reads the masher row:** a mash becomes a steadier string, and Y's mash has to stay in the band of 35 to 50%.

**2026-11-06: the flight strikes in `playable-build.md` replace this circle.** Its numbers fold into the arc.

## 4. The circle: the input waits for Orb

Orb loved a tight circle that they couldn't cause on purpose. Encounter's exact replay says the loop is the computer's dodge exchange, and Combat's corrected page now agrees. **Three clips are going to Orb: the dodge loop, the step strike and the zip. Their pick settles it.** On the near band, LT + Y is also wanted for a near zip, so I won't fix the input first. Encounter's build is behind a switch, off.

**What I'd rule if it's the loop, which is what I expect:**

| | |
| :--- | :--- |
| **Press** | LT + Y, in reach, in a brawl or starting one |
| **Motion** | He flies over the rival on one curve (under, with the stick down), lands on the far side, and the blow lands as he arrives. About 24 ticks |
| **Worth** | A medium's. The motion is the reward |
| **Price** | **10 ki,** ×1.5 for each one inside 3 s. No cooldown |
| **Answers** | It's slower than a medium, so it can be seen. **A heavy or a grab stops it,** and a guard can turn and block it. A light doesn't stop it |
| **After** | The sides are swapped, and the brawl goes on. No run, no close |

LT + X stays the step strike, with a bow, and the middle band's zip and the computer's dodge stay as they are. **QA reads:** the circle's share of blows, at most 25%.

## 5. A hold builds during your own blow

Half of Orb's B presses came while a blow of theirs was still going. **If you press and keep holding while your blow finishes, the hold has been charging since you pressed,** so the blow in the slot comes out as far along as you've held it. You're already committed to the blow in hand, so it's free time and costs nothing else. It's on the same switch as the press wait.

**Not yet, and next: phrases as the route.** Nine of Combat's phrases finished in Orb's match and nothing told them. Letting the second press choose where a string goes is the real "combo control", and it's the next thing to design once these are in hands.

## Hit weight

**Yes to Combat's table.** It stays a holding value until there's sound: Orb hasn't heard a hit in any build yet.

| Blow | Pause, in ticks |
| :--- | ---: |
| A light in a mash | 0 to 2 |
| A tapped light | 2 |
| A medium | 3 |
| A heavy | 8 |
| A launch; a full launch | 12; 14 |
| A decisive blow; a KO | 20; 24 |

`data/fight/hitstop.json` on, with the 18% freeze budget staying.

## The meteor's widest shot

**Fine, and the camera doesn't hold closer.** The fighter's a few pixels, the trail carries him, and Legal bars an aura, which I wouldn't ask them to change. The picture is the planet and the trail. As I've already ruled, it lasts about 2 s at most, with the view back in before he lands. **If Orb loses him in the clip,** the next rung in, 32,000 wide, is the lever. Their eye decides.

## QA's read with all five on (2026-11-02)

| Row | Read | Band | Ruling |
| :--- | ---: | :--- | :--- |
| Masher against medium | 42% to **52%** | 35 to 50% | **Move:** the press wait is for **Y and B only.** X keeps its 10-tick wait. Orb's lost presses were Y and B, and the masher bot mashes X, so this takes the masher's gain without giving back the fix |
| Match length, median | 464 to **514 s** | 360 to 480 s | **Hold** until the X change and Encounter's stick fix are read, as both may move it. If it's still over, wear's k goes 0.045 to 0.05, inside QA's tuning range. The band doesn't widen |
| Match length, p90 | 658 s | 660 s | Fine |
| Launches, AI v AI | 14.3 to 13.1 a match | | Fine |
| Civilians, slices | 28.8% | 12 to 30% | Fine, and never tuned toward (RL-214) |
| Pad mix against easy | 8 to 15 of 30 | | Read again after the stick fix |
| Steal on: closes on the stick player | 4.6 to 1.3 a minute | Fewer | **Met** |
| Steal on: the stick player's own closes | 0 to 3 a minute | | Good |
| Stick-only against the AI | 1 of 30 | Within 10 points of the X mash | Encounter's fix for refused late flicks first. A flick's run stays 1.5 |

**Nothing else moves.** The steal's shape stays as ruled.

## The masher on medium again (2026-11-06, QA's city step one read)

**52 against 35 to 50: the band holds, and nothing moves yet.**

- **On 100 matches, 52 can't be told from 50.** The 95% interval is about ±10 points, and this row has read 36, 38, 46 and 52 on recent builds. **QA reads it on 300 matches (about ±6) before anything moves.**
- **If it's still over 50 on 300, the AI's answer moves, not the band.** Encounter's lever, by its smallest step, on medium only. A masher shouldn't beat the middle AI half the time, and the band has said so since it was set.
- **The answer has to key on the same button pressed again and again, not on pressing a lot.** The stick-only player already loses far more than the X mash (about 20 points on medium, against a band of 10), so an answer to busy hands would widen that gap. QA reads the stick-only row in the same batch.
