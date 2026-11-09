# The gauntlet's first read: what to expect, the targets, and the levers

Owner: Game Design. 2026-11-07, on Tools' gauntlet of the morning build (`docs/tools/morning-1107-gauntlet.txt`, 10 matches a cell, seed 1). **The right stick is Orb's own scheme,** so stick-only losing is the first thing to fix. Ten matches give about ±30 points at 50%, so every verdict below is read again at 40 a cell.

## 1. Time without control: what it measures, and what to expect

The gauntlet counts a tick as "without control" when the pad's fighter is `locked`, launched, down, stunned or embedded. **A fighter in a brawl is `locked` too,** and in a brawl every press is a blow and the left stick moves the pair. So the 47 to 58 s a minute (80 to 96% of every match) is mostly brawl, and the brawl is meant to fill half the fight. The column has to be split before it can be judged.

| Share of fight time | Expected | Why |
| :--- | :--- | :--- |
| **In a brawl** (in control: each press a blow) | **45 to 60%** for a pressing pad. The computer against itself is 30 to 50% | `melee-press-feel.md` §9e. It's the core |
| **Locked by the director** (planned exchange beats, a launch's flight, a break's set piece, a finisher) | **At most 15%** (9 s a minute) | The director choreographs these, and they're the show. Past 15%, the player is watching more than playing |
| **Taken out by being hit** (stunned, reeling, down, launched, embedded) | **At most 15% in an even fight.** More for the side that's losing, which is fair | It's the price of being hit, so it rises and falls with the fight |
| **So truly without control** | **At most 30% (18 s a minute) in an even fight** | The last two rows together |

**Tools** splits the column into those three, using the brawl's own flag, the exchange's branch and the fighter's state. Until then the column can't pass or fail.

## 2. Target win rates, by pad and level

| Pad | Easy | Medium | Hard | Today (n 10) | Source |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Orb's scheme** (thumb-paced flicks, the left hand guarding; §5) **leads** | at least 70% | 35 to 60% | at most 20% | 0 / 0 / 0 | §5: a newcomer beats easy (`modes.md`), and guarding is more than mashing |
| **Masher** (X every 8) | at least 60% | 35 to 50% | at most 10% | 90 / 50 / 0 | `balance-targets.md`, `agency-pass.md` |
| **Timing** (stands in for a skilled player) | at least 90% | 70 to 90% | 40 to 60% | 0 / 0 / 0 | `agency-pass.md` §3 |
| **Stick-only** | within 10 points of the masher, and no higher | the same | at most 10% | 20 / 0 / 0 | `stick-lands.md` |
| **Circle-first** (LT + stick + a face button) | at least 60% | 35 to 50%, inside the masher's band | at most 10% | 100 / 80 / 0 | Flight strikes' dominance check (`playable-build.md` §1) |
| **Beam-first** | at least 50% | 15 to 35% | at most 10% | 70 / 10 / 0 | New: beams are answerable, so beam spam sits under the masher |

- **Hard at 0% is right for every one-note pad.** The hard computer should beat a script that does one thing. Only the timing pad, which reads, has to reach it.
- **Circle-first at 80% on medium is over its band.** It's today's LT + X and LT + Y, which flight strikes replace. Read it again with `flightStrikes` on. If it's still over, the flight strikes' own lever applies (`kiMul` 1.5 to 1.75).

## 3. The levers

**First, two arms that don't yet test what they claim to (Tools).**
- **Timing.** It presses LB as his blow starts to wind up, and lets go after 10 ticks. A medium winds up for 12 ticks and B for 28, so it's never guarding at contact, and its press is never inside the perfect block's 8 or 10 ticks. It never blocks anything. **The arm needs to press LB 4 to 6 ticks before contact, hold it through, then press X inside the riposte window.** Its 0% says nothing about the game until then.
- **Stick-only.** It never holds a charge. Orb's scheme is a flick for the quick strike and a hold for the charged one, and a level-3 hold is what sets up the send. **Add a hold when he's staggered or open.** Keep today's flick-only arm as a row of its own.

**Stick-only, in order (Encounter, then Controls):**
1. **A landed flick counts 1.5 run points** (`stick.json` `flickRun`). It was ruled on 2026-11-02 in `stick-lands.md` but never given a page row, so it's off in the morning build. It's what decides trade breaks: against easy, at 1 point the stick lost all 48, and at 1.5 it won 32 of 45. Without run, the stick never closes, so it never earns the set-ups that lead to a finisher. *Encounter sets the points to 1.5, and Tools adds the row.*
2. **"One stun a string" isn't a refusal.** It limits a stun, never a hit. But it sends `press_refused stun_limit`, which is 42 to 64% of stick-only's "refusals" (7,158 of 11,185 on medium). The hit landed, so the player mustn't be knocked or told "refused". *Encounter cues it as a hit with no stun. Controls makes sure no haptic knock fires for it.* Then the silent reason "0" (1,109 on medium) needs a name, or it's a press with no answer.
3. **The steal** (`stick.json` `steal`, built and off), if stick-only is still under the masher's band after lever 1. It rewards reading a flurry, and it was approved for a QA run on 2026-11-01. *Encounter's switch. QA reads it against the "no higher than the masher" ceiling.*

**Timing, in order, once the arm is fixed:**
1. **The anti-mash lockout only follows a missed perfect press** (Controls, `timing.json` `perfectBlock.antiMashLockout` 20). Today any guard press starts 20 ticks in which a fresh press can't be perfect, so a player who reads two blows of a flurry correctly is locked out of the second. Mash still pays nothing, because every whiff starts the lockout. Soft costs over hard stops.
2. **A riposte builds the run** (Encounter): 2 points, so a read wins the next trade break the way a flurry does. Today a perfect block clears his run but gives the blocker none, so the timed player has to win the trade from zero.
3. **The computer gives something to read** (Encounter): at medium and hard, at least 25% of its brawl blows are wound up (Y or B), each with a tell. Lights land 2 ticks after the press, and no one times those. If the computer only streams lights, the timing pad has nothing to read and is only guarding.

## 4. Read next

Tools re-runs the grid at 40 a cell with the two arms fixed, the no-control column split, and `flickRun` 1.5 on as its own scheme. Then each lever goes on one at a time, as its own scheme against the shipped rules.

## 5. Orb's scheme leads the next build (2026-11-07, `docs/tools/gauntlet-orbs-scheme-e80b8e3d.md`)

Tools' arm plays the way Orb's hands do: a right-stick flick every 30 to 48 ticks, and LB on every wind-up of the rival's. **It loses all 30 matches, easy included.** It lands a third of stick-only's blows and takes as many. Per press it lands about as often as stick-only. It just presses a quarter as often, and nothing it lands builds toward a finisher.

### Its targets

| The arm | Easy | Medium | Hard |
| :--- | :--- | :--- | :--- |
| **As built, once its guard is fixed** (flicks and the guard only) | at least 70% | 35 to 60% | at most 20% |
| **With a hold on an opening** (Orb's charge, the level-3 send) | at least 85% | 50 to 75% | 15 to 35% |

- **Why higher than the masher.** It guards, and guarding is more than mashing. A newcomer has to beat easy within three tries (`modes.md`), and this arm is the floor for anyone holding a pad Orb's way.
- **Why under the timing pad.** It guards every wind-up, needed or not, and reads nothing.
- **The ceiling** is the stick's rule from `stick-lands.md`, applied to spam: the flick-only arm (stick-only) never beats the masher by more than 10 points. Orb's scheme may, because it guards.

### First, the arm's guard has the timing pad's fault (Tools)

LB is held for 10 ticks from the start of a wind-up. A medium winds up for 12 ticks and B for 28, so the guard is down before most blows land. **Hold LB from the wind-up until contact.** Then add the hold on an opening as a second row.

### Encounter's rulings: the stand-in's four levers, from Orb's "each press is a blow" (re-ruled the same day)

**1. A flick that can't start now is held, and it becomes his first blow out.** It no longer expires after 9 ticks.

| Why it can't start | What happens to the flick |
| :--- | :--- |
| **Stunned or reeling**, or **in a planned exchange** with no window of his open | **Held, the newest only, until his first free tick,** up to 90 ticks (`pendFollow.maxTicks`, as a swept hold already waits). Then it goes, its direction read relative to the rival at that tick. Past 90 ticks it's refused, with a word |
| **Launched, knocked down or dropped** (recovering) | **Held too, but it must be at most 20 ticks old when he's free,** the face queue's 20. So a press as he recovers is his first blow out, and one made early in the flight doesn't fire seconds later. Older than that, it's refused with "Recovering" |
| **A set piece** (a break shot, a finisher, the KO, a struggle's walk-in) | **Not held.** Those are the show, and a blow out of one would be stale. Refused at once, with a word |

- **Why:** Orb presses about once every 45 ticks, and the director holds a fighter for much of a minute. A press dropped after 9 ticks with no word (`stick/0`, the largest reason at every level) did nothing. That breaks "each press is a blow" and the rule that a press waits for the blow in hand (`press-decides.md`).
- **Told at once:** a held flick is acknowledged quietly, with no knock, and the blow itself is its answer. Only a final refusal knocks.
- **Lever:** if Orb's next files show held flicks firing when they're no longer wanted, 90 drops to 45 ticks. The 20 for recovering stays the face queue's.

**2. A planned exchange folds the flick into its next beat, and that honours it.** `stick_refused answered` goes away.

| When the flick meets a planned exchange | What it becomes |
| :--- | :--- |
| **His request started it** (he's its attacker) | **Its first strike,** played with the flick's direction piece where the template allows. The rival's dodge, parry or counter is the fight, which the player can see, as with a guard |
| **The exchange is running, and a window of his is open** (a parry, a chain, a riposte) | **His press for that window,** as any blow's press is. What the window gives is the answer |
| **The exchange is running, and no window is open** | **Held,** by ruling 1, to his first free tick |

All three count as honoured, with no refusal cue and no knock. In a window a flick counts as one press, as a button's does, with the same timing and anti-mash rules, so parrying with the stick is no easier than with a button.

**3. A word for every refusal, and each press told once.**
- **`stick/0` and its numbered siblings go.** A held flick too old after a knock-back says **"Recovering"**. A set piece's refusal gets a word of UI's choosing. A press nobody is told about is a fault.
- **`press_refused y` and `stick_refused refused`** come in equal numbers in every cell. They're one event told twice. The stick's own cue owns a stick press.

**4. If the arm still loses on easy, read easy against a guard.** Once the arm's guard is fixed and levers 1 to 3 are on, a player who guards every wind-up must not lose to easy. **Encounter reads** easy's blows against the guarding arm: how many are B into a guard, and how many of the guarder's staggers follow from them, because any heavy on a guard staggers the blocker.
- **The lever is easy's B into a held guard,** at half its rate. Easy then backs off and tries again rather than breaking a guard.
- **It isn't less aggression overall.** Easy still has to attack, or a newcomer has nothing to hit back.
- Medium and hard keep breaking guards. That's what stops turtling.

### Levers for Orb's scheme, in order

1. **`flickRun` 1.5** (§3, stick-only's lever 1). Without run the flicks never close, and nothing builds to a finisher.
2. **The hold** (ruling 1).
3. **The fold and the words** (rulings 2 and 3). These change the count and the feel more than the wins, so they're read with levers 1 and 2 on.
4. **Easy against a guard** (ruling 4), only if easy is still lost.

**Read next:** Tools re-runs Orb's scheme first, at 40 a cell: the guard fixed, then each lever as its own scheme, then the arm with holds.

## 6. Easy against Orb's scheme: easy matches your pace (2026-11-08, Encounter's control audit)

**What Encounter found** (build 2's page, the energy model on): Orb's-scheme pad loses 6 of 6 to easy.
- It takes 171 hits a minute. Easy's lights are 148 of them and about 83% of the damage: flurry lights every 12 ticks with no wind-up, so the held guard blocks 0.8 a minute.
- Ruling 4's lever (easy's B into a guard) can't move it, at 2.8 heavies a minute.
- Easy at Saturday's pace (`tapGap` 24 to 30) wins it 5 of 6 for the pad, with hits taken down to 89 a minute.

**Ruling: easy matches the player's own pace** (Encounter's second option), behind a switch. Medium and hard are unchanged.

| | Rule |
| :--- | :--- |
| **Easy's gap between blows** | **Never shorter than his recent gap between attack presses,** with a **floor of 12** and a **ceiling of 30** ticks. The recent gap is the median of his last 3 s of attack presses (face buttons and stick strikes; guards don't count) |
| **The floor** | A masher still meets easy's 12-tick strings, as today. The masher's band against easy (at least 60%) is unchanged |
| **The ceiling** | A player who barely presses, or only guards, still meets a string every 30 ticks, so easy never goes passive, and a pad that's put down is still the idle rule's to end |
| **Without a human** (computer against computer, QA's batches) | Easy uses the middle of the old range, 27 |

- **Why the pace and not a flat 24 to 30:** it's what Orb asked for at 21:52, "adaptive to what the player is trying to do". A newcomer meets their own rhythm, and a masher meets mashing.
- **Why not "unfair" or rubber-banding:** it changes when easy throws, never what its blows are worth, its stats or its reads. The AI still plays by the same rules (`modes.md`).
- **The bands it answers to:** Orb's scheme at least 70% on easy (§5), the masher at least 60%, and a newcomer beating easy within three tries. Read at 40 a cell.
- **Data:** `ai.json` easy `brawl.paceMatch: { "enabled": false, "floor": 12, "ceiling": 30, "windowSec": 3, "noHuman": 27 }`.

## 7. Hit-stop's share: yes, it comes down

**Measured:** freeze is 16 to 27% of a match.
- `data/fight/hitstop.json`, with its 18% budget, is **off.** So it's the brawl's own table (light 2, medium 2, heavy 6) with no budget.
- With 171 hits a minute, easy's 2-tick lights alone are about 8 s a minute frozen.
- Orb's 21:52 "weren't in control of our fighter" and Sunday's "charge attacks interrupted arbitrarily" both point at time held still.

| | Ruling |
| :--- | :--- |
| **The target** | **At most 15% of a match frozen, on average,** with a player in it |
| **The ceiling** | **The 18% budget in any rolling 10 s applies to whichever table is live,** the brawl's included (`rulings-2026-10-22.md` 5b). Over it, every stop under a decisive blow is ×0.75, rounded, **at least 1** (a light's 2 goes to 1; the floor was 2, which left lights uncut). Stutter is still capped at 40% in any 10 s |
| **Never cut** | Decisive blows, the KO, and a launch's held moment (`slam-and-pace.md`) |
| **Order of levers** | 1. Easy's pace (§6), which roughly halves the hits taken. 2. The budget on the brawl's table. 3. Only then, the flurry light's own stop from 2 to 1 |

## 8. The planned dodge set piece against easy (for the record)

Easy's evasive stance plays the planned dodge set piece for 2 to 3 s a minute. **That's inside §1's limit for time locked by the director** (at most 15%, 9 s a minute), so no new cap. The fix for being carried round is already ruled (`beams-third-play.md`: you only go round after him if you're still pressing toward him). **QA found it was never built (2026-11-08):** the rush in `exchange.gd` (lines 448 and 548) carries the player round unconditionally in build 2. **It goes before `paceMatch`.** It's a small condition on the rush, and it's Orb's own complaint (16 of 31 side swaps on 11-06), so the 15% reading only holds once it's in. If Orb still feels it, easy's evasive stance plays the set piece only against a medium or heavier press, not a light.
