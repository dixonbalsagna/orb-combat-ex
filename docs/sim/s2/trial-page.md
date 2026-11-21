# The gravity well: what the trial found

Spike S2, sprint A1, 2026-11-14. Simulation built it with Encounter, on a copy of the build you played on 9 November, with flight at 3,500 (your decision 5). **Nothing here is in the game.** The trial answers three things: what the well does, what it costs, and the question at the bottom. There are clips to watch and two versions to play.

## What we built

- **Every fighter has a gravity well.** It reaches 12.5 body heights at the first power level and grows with each level, to 20 at the fourth. It also swells a little while you power up or gather a beam, so powering up close in makes you easier to reach. The well only changes on things you can see, never by itself.
- **Inside your rival's well, X, Y, B or a flick of the right stick snaps you in.** It's the lunge you already have, with the same short crouch first so you can see it coming. What's new: it reaches as far as the rival's well (plus a small edge, so there's no cliff), and a stronger fighter flies in faster.
- **Outside the well, the same press is the long-range kit you have today:** the taunt, the charge, bolts and beams.
- **Let go of everything inside a well and you drift together, gently.** The moment you touch anything, the drift stops on that same frame. After you've been knocked away it stays off until you move. It never moves you while the rival's attack is coming in.
- **Up close, two versions of the close fight:**
  - **Today's:** each stick moves the whole fight, both of you.
  - **The new one:** your stick moves only you, and nobody's stick ever moves the other player. Your rival stays with you by attacking. Walk away from someone who's hitting you and you break clear on the third blow that reaches you.

Every piece is behind its own switch. With them off, the game is exactly the build you played: every recorded match comes out identical.

## What it does, measured

All of this comes from the game itself, not a model.

**Press X from a distance** (a light attack; the rival at the first power level):

| From | Today | With the well, level 1 | With the well, level 4 and a full power meter |
| ---: | :--- | :--- | :--- |
| 6 body heights | lands in 0.25 s | 0.25 s (the same) | 0.23 s |
| 9 | 0.32 s | 0.32 s (the same) | 0.25 s |
| 12.5 | 0.38 s | 0.38 s (the same) | 0.28 s |
| 15 | a taunt | **snaps in, lands in 0.43 s** | 0.30 s |
| 20 | a taunt | a taunt (outside the rival's well) | a taunt |

At the first level nothing changes inside today's lunge range. The well adds reach at its edge, and power adds speed. Against a fourth-level rival, whose well is bigger, you snap in from 20 body heights (0.52 s) and even from 23 (0.58 s).

**How fast the snap flies.** It's never slower than today's lunge (4,000 a second), and it rises with power. At levels 1 to 4 it's 4,000, 4,373, 5,464 and 6,827 a second with an empty power meter, and 4,136, 5,168, 6,457 and 8,068 with a full one.

**Walking away, up close** (the first four seconds after you turn away):

| You... | Today's close fight | The new one |
| :--- | :--- | :--- |
| hold away; the rival does nothing | you drag the rival along; the fight lets go after about a second | you walk off; the rival isn't moved; it lets go after about a second, with you 3 body heights clear |
| hold away; the rival throws lights | 16 blows land, you never get out, and you drag the rival 7 body heights | **3 blows, then you break clear (0.6 s)** |
| hold away; the rival winds up heavies | 6 blows reach you, and you never get out | 3 blows, then you break clear (1.5 s) |
| do nothing; the rival pushes away | you're carried almost 2 body heights | **you aren't moved at all** |
| walk into an idle rival | the pair slides almost 2 body heights | you stop against the rival, who isn't moved |

**Your own stick:** pushed from rest, your fighter starts moving within a thirtieth of a second in both versions.

**When the rival's snap arrives:** in the new close fight you keep about 60% of your speed. In today's, the pair moves as one.

**The drift never moves a busy fighter.** Over 80 seconds of scripted play (holding the stick, guarding, pressing, holding the right stick) and 80 long computer matches, it never moved anyone who had a hand on anything, was staggered, had just been knocked away, or was being attacked. Game Design's other version, a drift that also pulls while you hold the stick (only half as hard), is built for comparison.

**Computer against computer** (40 matches for each version, with the well on):

| | Today's close fight | The new one |
| :--- | :--- | :--- |
| Brawls a match | 53 | 49 |
| How they end | mostly a flight strike out (64%), then a beam, a launch, or a second without attacks | the same mix |
| Middle brawl length | 2.6 s | 2.5 s |
| Share of the match spent brawling | 35% | 30% |
| Blows that reach a fighter, a brawl | 30 | 28 |

The computer barely changes how it fights. It never walks out of a brawl in either version, because its close-fight stick was written to steer the pair, and it holds still for the trial. Neither version reaches the half of the match in brawls that Game Design asked for.

**Your button layout against the computer on easy** (Tools' scripted pad playing your layout):

| 10 matches each | Today | The well, today's close fight | The well, the new close fight |
| :--- | :--- | :--- | :--- |
| Your pad wins | 6 | 6 | 4 |
| Presses the game turned down, per 100 | 20.6 | 19.4 | **9.8** |

| 30 matches each | Today | The well, the new close fight |
| :--- | :--- | :--- |
| Your pad wins | 21 | 16 |
| Presses the game turned down, per 100 | 24.6 | **14.8** |

No draws or timeouts, and the time without control is the same in all of them. **The steady change is that the game turns down far fewer of your presses in the new close fight.** The lower win count is a lean, not a result: a gap that size over 30 matches happens by chance about 3 times in 10.

## What it brought up

- **A dodge against a fast snap.** A dodge tapped as a fourth-level snap comes in now starts the locked dodge set piece from as far as 15 body heights away. Today that only happens up close. Game Design has proposed turning those into brawl answers instead; that isn't in the trial.
- **The computer can't answer a fast snap.** It only reacts to an approach that lasts a quarter of a second or more. A fourth-level snap from 12.5 body heights takes a fifth of a second, so the computer never sees it coming (today it reacts 3 times in 8). The computer would need to learn the well before Alpha.
- **The bigger fighter's long-range kit.** When a transformed fighter's well reaches a smaller one, the smaller one can snap in from further away, while the bigger one still has the long-range kit at that distance. In 80 computer matches the bigger fighter never taunted while the smaller one stood inside its well, so it didn't come up. Power-ups cut short by a snap from beyond today's lunge range: 3 in 40 matches with today's close fight, none with the new one.
- **Breaking clear.** Blows that land or are guarded count toward the three. A heavy that staggers you or a grab stops the walk, as Game Design ruled.

## What it cost, and how big it is

- **The trial:** about 560 lines of game code (280 in the simulation, 283 in the fight director), plus about 1,100 lines of checks and measuring tools. One independent review checked it before the measurements: it used 1.26M tokens and found 19 real faults. 18 were fixed; the last only ever holds the drift back.
- **The well itself (its size, the snap, the drift): large, as expected.** For Alpha it still needs a pulse and a sound at the well's edge (Controls and Audio), the computer playing the well (Encounter), online play and its checks (Netcode), flight strikes reaching to the well's edge, and a decision on the dodge set piece.
- **The new close fight: medium in code, but it has the longest tuning tail.** All of the computer's close-fight habits were tuned for today's version.

## Watch, then play

**The clips** (in `homework\Files\clips\s2-trial-gravity-well-9f867c5a\`). Each comes as a pair, today then the new version, with your buttons drawn under the picture. **The "today" clips show the fight as you played it on 9 November, with no well at all.** The "proposed" clips have the well and the new close fight.

| What you see | Today | The new version |
| :--- | :--- | :--- |
| Walking away from a rival who does nothing | `1-walk-away-idle-today-01-clip-t392.webm` | `1-walk-away-idle-proposed-01-clip-t367.webm` |
| Walking away from a rival throwing lights | `2-walk-away-lights-today-01-clip-t392.webm` | `2-walk-away-lights-proposed-01-clip-t367.webm` |
| Standing still while the rival pushes the stick away | `3-still-rival-pushes-today-01-clip-t392.webm` | `3-still-rival-pushes-proposed-01-clip-t367.webm` |
| Pressing X from 14 body heights at the first power level | `4a-press-x-tier1-today-01-clip-t159.webm` (a taunt) | `4a-press-x-tier1-proposed-01-clip-t160.webm` (a snap) |
| Pressing X from 14 body heights at the third power level | `4b-press-x-tier3-today-01-clip-t2290.webm` (a taunt) | `4b-press-x-tier3-proposed-01-clip-t2400.webm` (a faster snap) |

**The two versions to play** (in `homework\Files\builds\`). **Both have the well on;** they differ only in the close fight. That's different from the clips, where "today" has no well.
- `Open - S2 trial, today's close fight.cmd`: the well, with each stick moving the whole fight.
- `Open - S2 trial, the new close fight.cmd`: the well, with your stick moving only you.

Fight the computer for a minute on each: push away, push into them, circle.

## The question for you

**Up close, when you push your stick, who should move?**

- **A. The fight moves** (today's, from your October calls). Each stick nudges the whole fight, so you can drag it where you want and it never drifts apart. To leave on your own, you escape for 15 energy, zip away, or wait a second without attacks.
- **B. You move.** Your stick moves only your fighter, at the same pace as today. Nobody's stick ever moves the other player. You can always walk away from someone who isn't hitting you. Walk away from someone who is, and you take three blows before you break clear, unless a heavy or a grab stops you. The paid escape is still the fast way out.

What B costs: you can no longer drag the fight across the map with the stick alone, and three light attacks no longer hold someone who wants to go. If neither feels right yet, the knobs are B's walking pace, how many blows it takes to break clear, and whether the fighters drift together while one stick is busy.
