# Launch anywhere: the launcher from any point in a string

Owner: Game Design. Date: 2026-10-16. **Paper only.** Nothing here is built or run by me, and **every number is a first value.** This is `brawl-second-pass.md` §14's thirteenth round. It replaces three things there: the opening as the only way to launch (§3), the launcher's rest with the hammer (§3 and the fourth, eleventh and twelfth rounds), and the rest's ring (the twelfth round's item 4). Encounter's window 1 on main (9d0530dc: the rest at 30 s, the wider window) is the starting point, and §9 is their next window.

**Orb** (homework 23, `docs/ep/vision.md`):
- "there should be mechanics to chain together attacks dynamically and emergently; launchers should have an intuitive way to activate and aim at any point in a combo string."
- "I'm not a fan of 'cooldowns' and 'recharging' except in limited circumstances, so try to balance it in a way that avoids strict caps on what a player can do in a fight."
- The hint is Orb's pick C: "He's open! Press B and send him flying!"

Rule of cool takes precedence everywhere (Orb).

## 1. The rule in one paragraph

**B in a string launches, aimed by the stick.** A string is his blows landing. Any B pressed within 24 ticks of one of his landed blows is the launcher. **What decides how good it is comes from the fight, not a counter or a timer:**
- how the string got there (how many blows, and how hard the last one was);
- the timing (a perfect B is the best launcher);
- the rival's state (open, reeling, or free to answer);
- whether he has just been launched the same way.

Nothing counts down, and no launch is ever refused.

## 2. What a B is

| When B is pressed | It is |
| :--- | :--- |
| **Cold:** none of his blows has landed in the last 24 ticks | The heavy, as now: armoured, a 28-tick wind-up |
| **In his string:** within 24 ticks of a landed blow of his (a light, a medium, a heavy, a vicious blow, a bolt, a blast) | **The launcher** (§3, §4) |
| **In an opening:** the rival is staggered (a flurry's close, a broken guard, a perfect block, a wall slam, a bury, a throw's opening, a tech counter, a punished taunt, a heavy's miss) | **The sure launcher:** it always lands |
| **In a perfect window** (`brawl-second-pass.md` §16) | **The perfect launcher,** at any link of the chain. It is the ender: the director shapes it from the world, as the tenth round ruled |
| **Mashed:** a press under 9 ticks after a plain press | The heavy flurry, never a launcher (the mash rule) |
| **Held** | The charge, as now. A full charged heavy launches, as now |

- **The early press is kept.** A B pressed in the 10 ticks before one of his blows lands is held, and thrown as the launcher. So "X, then B" rolls off the hand.
- **The close stays an opening.** A run of unanswered blows still ends in the flurry's close and its stagger. That is now one way to make a launcher sure, not the only way to launch.
- **The heavy follow-up of §16** becomes the perfect launcher. Its worth of 9 is the perfect launcher's blow plus its landing.

## 3. Safety: whether he can answer it

The launcher keeps its 14-tick wind-up. **It is armoured against lights, and fully only when it is sure** (re-ruled 2026-10-17, §11). An answerable launcher's armour takes one light, and a second light landing in its wind-up stops it (2026-10-18, `rulings-2026-10-18.md`).

| The rival when B is pressed | How safe | His answers |
| :--- | :--- | :--- |
| **Open** (an opening) | **Sure:** it always lands | None. He keeps half his nudge, so he has a say in where he goes |
| **Reeling from a medium, a heavy, a vicious blow or a perfect follow-up** | **Hard to answer:** his reel covers most of the wind-up | A perfect block, giving ground started at once, or a burst |
| **Reeling from a light or a bolt, or free** | **Answerable** | All of the above, plus a catch (`grapple.md`) or a medium started early. Its armour takes one light, and a second light in its wind-up stops it, so a flurry is an answer |

**What an answered launcher costs him:**
- **Perfect-blocked:** the reversal, and the launcher's player staggers for 20 ticks. That is an opening, so the defender's own launcher is sure: **the counter-launch.**
- **Stopped by a medium:** he reels, as from any hit.
- **Dodged, or given ground against:** it misses, and he is open for 20 ticks, as after a heavy that misses.

So "X then B" thrown at a fighter who answers is punished. A string worked up to a medium, or to the close, makes the launcher safe. That is the honest route, and it needs no gate.

## 4. Power: how far, how high, how hard

**Power = string × state × timing × wounds × freshness.** The fighter's tier then scales it, through the ladder's launch gain, as now.

| Factor | Values |
| :--- | :--- |
| **The string:** his unanswered blows in it so far | 1 blow: 0.55. 2: 0.7. 3: 0.85. 4 or more: 1.0. **A gradient, not a gate** |
| **The rival's state** | Sure ×1.0, hard to answer ×0.9, answerable ×0.8 |
| **The timing** | A perfect launcher ×1.25, plus 0.05 for each earlier perfect in the chain, at most ×1.5 |
| **Wounds** | The region it strikes battered ×1.1, broken ×1.2 |
| **Freshness** | §5 |

- **What power sets:** the send's speed and length, the launching blow's worth (3 × power) and the landing's worth.
- **It also sets the building ladder.** A send meets buildings at an **effective tier = the fighter's tier × power**, rounded to the nearest, at least 1 (`buildings.md` §6.1). A tier-4 launch from one light meets towers as tier 2. A tier-4 perfect launcher from a long chain goes through three towers.
- **Rule of cool:** when the choreographer finds a set piece on the send's line (§6), the send may run 15% further, inside every collateral budget.

## 5. What replaces the rest: freshness by kind of send

**There are five kinds of send:**
- **up:** the uppercut, into open sky;
- **across:** along the street, through what stands there;
- **down:** the spike, into the ground;
- **behind:** turned, sent the other way;
- **into a building:** any send that ends in one.

**The stick picks the first four,** and neutral leaves it to the choreographer (§6).

- **Each launch marks its kind on the fighter it sends.** A launch of a kind already marked on him in the last 60 s of fight time is ×0.9 for each such mark (×0.75 until Orb's homework 30, `rulings-2026-10-18b.md`). **A kind not marked has only the general term below.** Marks fade 60 s after they were made.
- **The general term** (added 2026-10-17, §11): each launch of him in the last 60 s, of any kind, is ×0.97 more (×0.9 until homework 30). With the kind's term, never under ×0.7 in all (it was ×0.4). **Freshness is gentle:** a nudge toward variety, never a handicap for repeating, as Orb asked.
- **Air sense.** A fighter sent by a kind marked on him recovers 10% sooner for each mark (`buildings.md` §7; 25% until homework 30).
- **Repeats escalate the destruction instead** (Orb: "each time you launch an opponent against something, the more destroyed it will be"). A send into a building already marked meets it one tier higher for each mark, up to two, and a send into ground already cratered deepens and widens that crater (`buildings.md` §6.1).
- **So nothing locks and nothing waits.** A player can launch at any moment, and a new direction is always full strength. Repeating one send pays less, and the game's answer to spam is variety: Orb's "dynamically and emergently", in numbers.
- **The hammer is retired.** B in an opening always launches.
- **The first move after a launch stands:** the sent fighter can't start an approach for 45 ticks. It is not a cap on the launcher's player, and Encounter's return fix keeps the way back answerable.

## 6. Aim: the stick, and the choreographer

- **A held stick at the press:** the player's direction wins. The choreographer may bend the send by up to 30°, inside that kind, toward a cool target its combat alchemy scores: a building's face, a ridge, a crater's lip, or the inside chain of `buildings.md` §7. **It never changes the kind and never turns the send back.** Player agency is respected.
- **Neutral stick:** the choreographer picks the kind and the target by its score. It prefers a fresh kind, so a player who doesn't aim still sees variety. It keeps each fighter's care: the hero's sends lean away from people, and the Anti-hero's into buildings.
- **The early press keeps its stick:** the aim is read at the press, not at the throw.

## 7. Keeping the route honest, with soft costs only

| Script, against the medium AI | Bound |
| :--- | :--- |
| **The route:** B at every opening | At most 80%, and 0 to 25 points over the same script's masher (the twelfth round's edges) |
| **The spammer:** one light, then B, every string | Below the route, and at most 70% |
| **The varied route:** the route, rotating the stick through the kinds | Within 10 points of the route |
| **Full launches** a match (power 0.7 or more at the send, after freshness): the AI against itself, both together, per 7 minutes of fight | 6 to 12. By the route's player and on him: watched, not banded (homework 30, `rulings-2026-10-18b.md`). The route's edges are the dominance test |
| All launches a match, pops included | Watched, not banded |
| One kind's share of a fighter's launches, default arm | At most 50% |
| The spammer's launchers answered by medium | 20 to 50% (re-banded 2026-10-17, §11) |

**The levers, in order, and none of them a timer:**
1. freshness, from ×0.75 to ×0.65;
2. the answerable launcher's power, from 0.8 to 0.7;
3. the string at one blow, from 0.55 to 0.45;
4. an answerable launcher's ki, from 5 to 8;
5. the AI's answer shares.

## 8. The AI

- **When it launches:** after an opening, 0.15, 0.35 and 0.6 of the time by level (the data's 0.25 at medium is corrected to the paper's 0.35). In a string at a hard-to-answer moment, 0.08, 0.18 and 0.28 of the time (raised 2026-10-17 from 0.05, 0.12 and 0.2). It prefers fresh kinds.
- **How it answers a launcher that isn't sure:** as a player must, by reading the 14-tick wind-up. Its answer starts no sooner than its reaction time after the wind-up begins, so it is a perfect block it was already guessing (the twelfth round's rule for charges), giving ground, or a medium it was already winding. Its lights don't stop it. Shares: 0.1, 0.25 and 0.4.
- **Hard test:** it never answers within its reaction time.

## 9. Encounter's next window, after window 1

| # | The change |
| ---: | :--- |
| 1 | The string's link: B within 24 ticks of his landed blow is the launcher. The kept early press, as built |
| 2 | Safety (§3): armoured only when sure, the three states, the answers and what they cost |
| 3 | Power (§4), with the effective tier handed to the building ladder |
| 4 | Freshness marks by kind (§5). **Retire `launcher.restS` and the hammer's path.** The wider window around the close stays, since that is an opening's |
| 5 | The AI (§8) |
| 6 | UI's marks (below) |

**UI's marks, re-purposed from the eleventh round:**
- **The lit B** says LAUNCH whenever a B would launch. Its ring is solid when the launcher is sure, and broken when it can be answered.
- **No pips and no rose** (Orb's minimal UI, 2026-10-18, `minimal-hud.md`). A launch's power shows in the send itself, and the opening in his stagger, the ping and the pad.
- **The rest's ring is retired.**
- **The hint** is Orb's C, once, at the first sure launcher.

**Data:**
- `launcher`: windup 14, link 24, worth 3, ki 5, kept 10;
- `launcher.power`: string [0.55, 0.7, 0.85, 1.0], state (sure 1.0, hard 0.9, answerable 0.8), perfect 1.25, chain 0.05, max 1.5, wounds (battered 1.1, broken 1.2);
- `launcher.fresh`: window 60 s, factor 0.75, floor 0.4, air sense 0.25;
- `launcher.aim`: bend 30°, cool extend 1.15;
- `restS` is removed.

## 10. QA's hard tests

- A B inside the link window is always the launcher; a mash press never is.
- A sure launcher always lands.
- No launcher is ever refused: nothing blocks one but the rival being out of reach.
- A fresh kind is always at full strength.
- The AI never answers within its reaction time.

## 11. The first read, and what changed (2026-10-17)

Encounter built it and read it on main with window 2 (`docs/director/pending/launch-anywhere/`).

| Read | Band | The ruling |
| :--- | :--- | :--- |
| **The spammer answered 96%,** and wins 0 of 50. Almost every answer was the AI's own string landing in the wind-up | 30 to 60% | **The launcher is armoured against lights,** as the heavy is. A light in a busy brawl was stopping every launcher that wasn't sure, which made "launch at any point in a string" a trap. It is still answered by a medium early, a catch, a perfect block or giving ground. **The band becomes 20 to 50%,** and the spammer's own row (below the route, at most 70%) keeps it honest |
| **AI v AI: 3.8 launches a match,** no kind over 46% | 6 to 12 | **The AI's shares go up:** after an opening at medium to the paper's 0.35 (the data had 0.25), and in a string to 0.08, 0.18 and 0.28. Armour against lights also lets more of its launchers land |
| **The route: 47.8 launches a match, 20.3 on him,** 12 points over its masher (read before Encounter's fix 1) | 4 to 10; 4 to 8 | With no rest, every opening launches, and the route makes one about every 9 s. **A ki cost can't bring that down:** ki comes back at 5 a second, so a cost big enough to bind a script would make launching unaffordable for a player. **The count was the wrong row.** Freshness already turns repeats into short pops, and what spoils the pace is a full send every 9 s. So: **the general freshness term** (§5: ×0.9 for each launch of him in the last 60 s, any kind), and **the bands count full launches,** power 0.8 or more at the send: 4 to 12 by the route, 4 to 10 on him, 6 to 12 AI v AI. All launches, pops included, are watched. The route's edges (at most 80%, 0 to 25 points over its masher) are the test that launching isn't a dominant strategy, and it reads 12 points |

- **The ki stays 5.** It is the next soft lever only if the full-launch bands fail, from 5 to 10.
- **Re-read** the route and the gates on the build with fix 1, as Encounter has them PENDING.
