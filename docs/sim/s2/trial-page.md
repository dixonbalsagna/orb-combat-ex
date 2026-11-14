# The gravity well: what the trial found

Spike S2, sprint A1, 2026-11-14. Simulation built it with Encounter, on a scratch copy of the build you played on 9 November, with flight at 3,500 (your decision 5). **Nothing here is in the game.** The trial answers three things: what the well feels like, what it costs, and the question at the bottom.

**DRAFT: rows marked "(to come)" are still running.**

## What we built

- **Every fighter has a gravity well.** It's 12.5 body heights across at the first power level and grows with each level, to 20 at the fourth. It also swells a little while you power up or gather a beam: power up close in and you're easier to reach. The well only changes on things you can see, never by itself.
- **Inside your rival's well, X, Y, B or a flick of the right stick snaps you in.** It's the lunge you already have, with the same short crouch first so it can be read. What's new: it reaches as far as the rival's well (plus a small edge, so there's no cliff), and a stronger fighter flies in faster.
- **Outside it, the same press is the long-range kit you have today:** the taunt, the charge, bolts and beams.
- **Let go of everything inside a well and you drift together, gently.** The moment you touch anything, the drift stops on that same frame. After you've been knocked away it stays off until you move. It never moves you while the rival's attack is coming in.
- **Up close, two versions of the close fight, side by side:**
  - **Today's:** each stick moves the whole fight, both of you.
  - **The new one:** your stick moves only you, and nobody's stick ever moves the other player. Your rival stays with you by attacking. Walk away from someone hitting you and you break clear on the third blow that reaches you.

Every piece is behind its own switch. With them off, the game is exactly the build you played: every recorded match comes out identical.

## What it does, measured

All from the game's own simulation, not a model. 60 ticks is one second.

**Press X from a distance** (a light; the rival at the first power level):

| From | Today | With the well, level 1 | Level 4, full power meter |
| ---: | :--- | :--- | :--- |
| 6 body heights | lands in 0.25 s | 0.25 s (the same) | 0.23 s |
| 9 | 0.32 s | 0.32 s (the same) | 0.25 s |
| 12.5 | 0.38 s | 0.38 s (the same) | 0.28 s |
| 15 | a taunt | **snaps in, lands in 0.43 s** | 0.30 s |
| 20 | a taunt | a taunt (outside his well) | a taunt |

At the first level nothing changes inside today's lunge range. The well adds reach at its edge, and power adds speed. Against a fourth-level rival, whose well is bigger, you snap in from 20 body heights (0.52 s) and even 23 (0.58 s).

**How fast the snap flies.** It's never slower than today's lunge (4,000 a second). It rises with power: 4,000 / 4,373 / 5,464 / 6,827 at levels 1 to 4 with an empty power meter, and 4,136 / 5,168 / 6,457 / 8,068 with a full one.

**Walking away, up close** (the first four seconds after you turn away):

| You... | Today's close fight | The new one |
| :--- | :--- | :--- |
| hold away; the rival does nothing | you drag the rival with you; the fight lets go after about a second | you walk; the rival isn't moved; it lets go after about a second, you 3 body heights clear |
| hold away; the rival throws lights | 16 blows land, you never get out, and you drag the rival 531 units | **3 blows, then you break clear (0.6 s)** |
| hold away; the rival winds up heavies | 6 blows reach you, you never get out | 3 blows, then you break clear (1.5 s) |
| do nothing; the rival pushes away | you're carried 128 units | **you aren't moved at all** |
| walk into an idle rival | the pair slides 134 units | you stop against the rival, who isn't moved |

**Your own stick:** pushed from rest, your fighter moves within two ticks in both versions.

**When the rival's snap arrives:** in the new close fight you keep about 60% of your speed. Today the pair moves as one.

**The drift never moves a busy fighter:** over 4,800 scripted ticks of stick, guard, presses and right-stick holds, the drift moved nobody who had a hand on anything, was staggered, had just been knocked away, or was being attacked. Game Design's other version, a drift that also pulls while you hold the stick (only half as hard), is built as a comparison.

**Matches** (the computer against itself, 40 a version, with the well on):

| | Today's close fight | The new one |
| :--- | :--- | :--- |
| Brawls a match | 53 | 49 |
| How they end | mostly a flight strike out (64%), then a beam, a launch, a second without attacks | the same mix |
| Median brawl | 2.6 s | 2.5 s |
| Share of the match spent brawling | 35% | 30% |
| Blows that reach a fighter, a brawl | 30 | 28 |
| The drift moving a busy fighter | never | never |

The computer barely changes how it fights. It doesn't walk out of brawls in either version, because its close-fight stick was written to steer the pair and holds still for the trial. Neither version reaches the half of the match in brawls that Game Design asked for (`playable-build.md`).

**Your scheme against the computer on easy** (Tools' scripted pad playing your button layout, 10 matches each):

| | Today | The well, today's close fight | The well, the new close fight |
| :--- | :--- | :--- | :--- |
| Your pad wins | 60% | 60% | 40% |
| Presses the game refused, per 100 | 20.6 | 19.4 | **9.8** |

With 10 matches a win rate can be off by about 26 points either way, so Tools played today against the new close fight 30 times each:

| 30 matches each | Today | The well, the new close fight |
| :--- | :--- | :--- |
| Your pad wins | 21 of 30 (70%) | 16 of 30 (53%) |
| Presses the game refused, per 100 | 24.6 | **14.8** |

No draws or timeouts in either, and the time without control is the same. **The steady change is the refusals: in the new close fight, fewer of your presses are turned down.** The lower win rate is a lean, not a result: at 30 matches a gap this size happens by chance about 3 times in 10 (`docs/tools/runs/s2-row11-close-fight-n30.txt`).

## What it brought up

- **A dodge against a fast snap.** A dodge tapped as a fourth-level snap comes in now starts the locked dodge set piece ("dodge and read") from as far as 15 body heights. Today that only happens up close. That's the "locked" Game Design's call 5 would turn into a brawl answer, and it isn't in the trial.
- **The computer can't answer a fast snap.** It answers an approach only if it lasts 16 ticks or more. A fourth-level snap from 12.5 body heights lasts 12, so the computer never sees it coming (today: 3 times in 8). The computer would need to learn the well before Alpha.
- **The bigger fighter's taunt.** When a transformed fighter's well reaches the smaller one, the smaller one fights close from further away, and the bigger one still has the long-range kit there. In 80 computer matches the bigger fighter never taunted while the smaller one stood inside its well, so this didn't come up. Power-ups cut short by a snap from beyond today's lunge range: 3 in 40 matches with today's close fight, none with the new one.
- **The walk-out count.** Blows that land or are guarded count; a stagger stops the walk, as Game Design ruled.

## What it cost, and its size

- The trial: about 560 lines of game code (280 in the simulation's core, 283 in the fight director), plus about 1,100 lines of checks and the measuring tools. One independent review checked it (6 agents, 1.26M tokens) and found 19 real faults. 18 were fixed before the readings above; the last only ever holds the drift back.
- **The well itself (size, zones, the snap, the drift): large, as the design guessed.** For Alpha it still needs the pulse and sound at the well's edge (Controls and Audio), the computer playing the well (Encounter), the online copy and its checks (Netcode), flight strikes reaching to the well's edge, and the dodge call above.
- **The new close fight: medium in code, with the longest tuning tail.** The computer's close-fight habits were all tuned for the shared movement.

## The question for you

**Up close, when you push your stick, who should move?**

- **A. The fight moves** (today, from your October calls). Each stick nudges the whole fight, so you can drag it where you want and it never drifts apart. To leave on your own you escape for 15 energy, zip away, or wait a second without attacks.
- **B. You move.** Your stick moves only your fighter, at the same pace as today. Nobody's stick ever moves the other player. You can always walk away from someone who isn't hitting you. Walk away from someone who is, and you take three blows before you break clear, unless a heavy or a grab stops you. The paid escape is still the fast way out.

Watch each pair of clips. If the two links are ready, fight the computer for a minute on each: push away, push into them, circle.

**Clips** (to come): walking away from a rival who does nothing; walking away from one throwing lights; standing still while the rival pushes the stick; pressing X from across the well at the first power level and at the third. Each is today, then the new version, with your buttons drawn under the picture.
