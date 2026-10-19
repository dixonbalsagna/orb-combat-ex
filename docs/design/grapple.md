# Grappling on A: the catch and the clinch

Owner: Game Design. Date: 2026-10-16. **Paper only.** Nothing here is built or run by me, and **every number is a first value.** Combat designs the moveset side (the pieces, the throws, the looks). This page is the rules, and it is aligned with Combat's paper when that lands. It replaces the tap and the mash of `brawl-second-pass.md` §4. The tackle on a held A out of reach, the seize on A+B (§6) and A's context out of reach stand.

**Orb** (homework 20, `docs/ep/vision.md`): "hybrid between catch and clinch, rule in favor of clinch", and "fantastic ideas, I see it as a way to set up combo chains and create varied combat scenarios". The pitches are Combat's `docs/combat/grapple-pitches.md`. Where the catch and the clinch disagree, the clinch's rule is taken.

**Orb's standing rules, kept:** one press is one attack; grabs can't be spammed; the held fighter always has a way out; the player always feels in control, except in knock-backs. Legal's rows g01 to g05 and s08 apply to every hold here.

## 1. A in reach, in one table

| | **A tapped: the catch** | **A held: the catch and carry** | **A pressed again** |
| :--- | :--- | :--- | :--- |
| **What it is** | A reach for the collar, a shoulder, an upper arm or the waist, with a 10-tick tell, at striking distance | The same catch. If it lands, he keeps the grip and drives the rival along his stick | During the tell: nothing, since one press is one attack. After a miss: the lockout, and the game shows a refused cue rather than a silent button |
| **If it lands on a fighter who is open** (a stagger, a miss's open window, a launcher's opening, a bury) | **The throw, at once** (§4), the stick picking it. The catch's quick throw is how a grab cashes an opening | The carry (§3) | |
| **If it lands on anyone else** | **The clinch** (§2), even | The carry | |
| **On a fighter who is guarding, or winding or charging a blow** | The clinch, **one ahead for the catcher**: a guard or armour doesn't stop a hand on the collar | The carry | |
| **In a perfect window** (`brawl-second-pass.md` §16) | **The perfect catch:** no tell, and the clinch starts one ahead. The chain of perfects ends, and its count is his lead | | |

- **Held A beyond reach is the tackle,** as §4 rules it. The carry and the tackle both end against the first surface on the line.
- **Orb's shove** (questionnaire 14) **becomes the clinch's push-off** (§2). Its old job was stopping a heavy that is winding, and the catch does that now: armour doesn't stop a grab.

## 2. The clinch: a contest for the grip

The clinch's rules are the clinch pitch's, with the pulse of every timed contest (`rule-of-cool.md` §2).

| | The rule | First value |
| :--- | :--- | :--- |
| **Its length** | At most 90 ticks from the tie-up | 1.5 s: Orb wants fights fast |
| **The pulse** | Shown and heard: a flex of the grip, a creak, a pad pulse. Both fighters work the same pulse | Every 20 ticks from the tie-up, so four pulses at most |
| **The grip** | One meter between them, from two behind to two ahead, starting even (or one ahead for the catcher, §1). It is shown in the bodies, five stages of the grip, and never drawn between them (Orb's minimal UI, `minimal-hud.md`) | |
| **A pummel** | A on the pulse moves the grip one step his way. If both pummel the same pulse, **the one nearer the pulse, by the tick, wins the step.** If both are the same number of ticks off, nothing moves (re-ruled 2026-10-17, §9) | Inside 4 ticks of the pulse. Sharp: inside 2 |
| **A stray** | A off the pulse, or a second A in its window, moves nothing and voids his next pummel. So a masher does exactly as well as a fighter who doesn't press, as in every timed contest | |
| **Vicious blows** | X, Y or B: a vicious blow on the region his stick leans to, as §4 ruled. Both fighters may throw them. A vicious blow is not a pummel, so a fighter works either the grip or the body | Half a brawl light of damage and three times a light's wear, on that region. Four a fighter a clinch at most, and never more than two in a row to the same place (Legal s08, by its own wording: re-ruled 2026-10-17 on Combat's reading). A region has two or three places, so a stick held on one wound keeps working it, the blows alternating places. A fighter one or two ahead wears half again as hard |
| **The brace** | A held: he can't be thrown while he holds it, and he can't pummel or strike. It is how a fighter two behind waits out the leader's throw | At most 40 ticks, then his grip tires and he can't brace again for 20 |
| **Moving** | The fighter ahead walks the pair along his stick. The other keeps half his nudge (`brawl-second-pass.md` §1) | At half walking speed |
| **A wall** | Walked into a building that holds, it is **a pin.** The leader's vicious blows wear half again as hard (not on top of his lead's ×1.5: at most ×1.5), and a throw from the pin is the wall slam at once, with no flight between | |
| **In the air** | The clinch needs no ground, so it is how a flying fighter takes control, as before | |

**Without a held A** (ruled 2026-10-17, for Controls' `grapple-input.md` and Encounter's `grapple-director.md`):
- **Charges off, or the latched A: the brace is automatic.** A fighter two behind who presses nothing on a pulse braces through it, for at most two pulses in a row, then rests a pulse. That matches the held brace's 40 ticks and 20 of rest.
- So pressing nothing is a brace only at two behind, where the held brace is used. Anywhere else it is nothing, as for any player.
- A latched A's presses are all pummels. There is no toggled brace, so one rule serves every layout without a hold.

**Touch Simple** (Controls' option 1, ruled):
- A tap of the Transform button is the catch. A hold of 30 ticks stays Transform. The catch's 10-tick tell absorbs a tap sent on the release.
- **In a clinch, Guard is A:** a Guard press on the pulse is the pummel, and a held Guard is the brace, as Guard is the let-go in a beam struggle.
- The carry isn't offered on touch Simple. The leader walks the pair along the stick anyway.
- UI labels Guard "PUMMEL / BRACE" during a clinch.

## 3. The carry

- **A held A that lands** drives the rival along the stick's line for up to 90 ticks.
- **It ends** when he lets go, which is the throw (§4) by his stick; at the cap, also the throw; or at the first surface on the line:
  - against a building, the wall slam;
  - against the ground, both end in the crater and the rival is staggered for 24 ticks, which is an opening.
- **The way out:** the carried fighter's A on the carry's pulse (every 20 ticks, inside 4 ticks of it) breaks the carry into the clinch, even. A stray voids his next try. He keeps half his nudge throughout.
- Legal's g03 holds: the carried body is in view every tick, and moves no more than 3 body heights a tick.

## 4. How it ends, and what each exit hands the brawl

**The throw** is the leader's next pummel at two ahead, or the catch's quick throw on an open fighter. The stick at the press picks it. A throw is a plain send (`buildings.md` §6.1): the planner stages it, and it is never a launch. **It lands worth a heavy, 6 brawl lights, with its landing's own damage on top** (2026-10-18, `rulings-2026-10-18.md`).

| Exit | Who | What it hands the brawl |
| :--- | :--- | :--- |
| **The throw down** | The thrower | He is slammed into the ground and **buried for 20 ticks: an opening.** B is the launcher if it is ready, or the hammer. **This is the combo chain:** clinch, throw, launch |
| **The throw up** | The thrower | He is thrown 4 bh up and **open for 16 ticks in the air.** B there is a launch in the air |
| **The throw across** (toward or away, or none) | The thrower | 8 bh along the stick. Into a building that holds: the wall slam, a 24-tick stagger, which is an opening. Into open ground: a landing, and the thrower has the first move (45 ticks) and the chase (`brawl-second-pass.md` §16) |
| **The reversal** | The one two behind | His sharp pummel on the same pulse as the leader's throw throws instead, by his own stick. It hands the brawl what that throw would |
| **A broken region** | The striker | A vicious blow that breaks a region ends the clinch, and the broken fighter staggers for 24 ticks: an opening |
| **The push-off** | Either, from even or ahead | A on the pulse with the stick away from him. Both are 3 bh apart, the brawl lets go, and the pusher has a 20-tick first move. No damage |
| **The time** | The grip's leader | At 90 ticks both part 1.5 bh, and **the leader has a 20-tick first move** (re-ruled 2026-10-17, §9). At even, nobody does, and the brawl goes on |
| **The tech** | The one caught | His own tap of A within 8 ticks of the catch breaks it before the clinch: both 1.5 bh apart |
| **A burst** | The one who bursts | As a burst does: it breaks any grab, at its price in ki |
| **An interjection** (one versus many) | The ring | A ring blow that lands on him in a clinch breaks it, and both part. One partner and the ring's single blows still hold (`empress-guards.md` §5) |

**The lockout and no regrab.**
- **One grab lockout of 90 ticks** is shared by every grab: the catch, the carry, the tackle, the zip tackle, the dive grab and the seize. It starts with each attempt.
- **A thrown fighter can't be grabbed for 120 ticks.**
- **A clinch that ends with nobody thrown** (time, the push-off, the tech, a burst, an interjection) starts the lockout for both.
- **A press in the lockout** shows the refused cue, and does nothing.

## 5. Beside the nine cells and the launcher

- **A is the tenth way to press, outside the nine.** The triangle: blows beat grabs (any blow that lands in the catch's tell stops it, and a dodge leaves the catcher open for 20 ticks); grabs beat guards, armour and charges; guards beat blows.
- **A third answer to a charge.** A charge was answered by a medium early, or by guessing a perfect block (`brawl-second-pass.md` §14, the twelfth round). The catch is the third: it takes him one ahead, mid-charge.
- **An opening has two cashes now.** B is the launcher if it is ready, or the hammer while it rests. A is the throw at once, which never launches. **While the launcher rests, the throw is how a player puts an open rival into a building or the ground.** A down throw's bury is a fresh opening, so the launcher can follow when it is ready.
- **The perfect follow-up feeds the clinch:** a perfect catch ends the chain of perfects and starts the clinch one ahead. A new chain can start from the throw's opening.
- **The run and the gauge:** each landed vicious blow counts one toward the run, as a light does. The throws hand their openings directly, so they add nothing to the run.
- **The mash rule holds:** a masher of A gets one catch and then the refused cue, and in a clinch his presses are strays.

## 6. The AI

- **Pulses:** it pummels on 40, 65 and 85% of pulses by level, as in every clash, and never sharply.
- **The body:** ahead, it throws vicious blows at the region its stick would choose. Two behind, it braces half the time at medium.
- **The tech:** it techs a catch by its level's share (0.15, 0.3, 0.45). It reads the catch's 10-tick tell as a player would, so its tap comes no sooner than its reaction time after the tell begins, never at the catch's landing.
- **The catch:** it catches guards, turtles and charges: a guard once in each 30 ticks of it, or a heavy it has had its reaction time to see, at 0.02, 0.04 or 0.06 by level (Encounter's first values, confirmed 2026-10-17). It takes the throw that its personality and care pick: the hero away from people, the Anti-hero into a building. **It varies its throws** (down, up, across) by what each hands it, not one throw every time.

## 7. QA's rows

| Row | Bound |
| :--- | :--- |
| A stray moves the grip | Never (hard) |
| A masher of A in the clinch against a fighter who doesn't press | Wins no more grip |
| The clinch's length | Median 40 to 70 ticks, at most 90 (hard) |
| A thrown fighter grabbed again inside 120 ticks | Never (hard) |
| The AI's tech starts within its reaction time of the tell's start | Never (hard) |
| Throws a match, default arm | 1 to 4 |
| A throw's opening (a bury, an air throw or a wall slam) followed by a launch | 15 to 40% of them: the chain happens |
| A player who only uses A, against medium: he catches when in reach, and in the clinch presses A on the pulse at a human's spread (within 3 ticks), throwing at two ahead | Wins 10 to 35% (the script re-defined 2026-10-17: a tapper of A every 8 ticks is a masher, and the masher's row covers him) |
| Catch tells a minute, AI against AI | 1 to 3 |
| The route player and launches a match, with grappling on | Read again: the route's edges and the band of 4 to 10 launches a match |

## 8. Data, and who builds it

- **`grapple`:**
  - `catch` (tell 10, tech 8, whiff open 20);
  - `clinch` (max 90, pulse 20, window 4, sharp 2, grip range 2, lead from a guard or a charge 1, perfect lead 1, vicious up to 4, damage 0.5, wear ×3, lead and pin ×1.5, brace 40, brace rest 20, push-off 3 bh, part 1.5 bh);
  - `carry` (max 90, pulse 20);
  - `throw` (across 8 bh, up 4 bh with 16 open, down with a bury of 20);
  - `lockout` 90 and `noRegrab` 120, shared.

  It replaces `shove` and the clinch keys of §4. `tackle` stays.
- **Owners:**
  - Encounter: the catch, the clinch and the carry, the AI.
  - Combat: the throws by stick for each fighter, the vicious blows and the pieces.
  - Animation: the key sets in Combat's estimate (about 12 a fighter for the clinch, and the catch's throws).
  - UI: nothing on or between the fighters (`minimal-hud.md`). Animation draws the grip's five stages; Audio and Controls carry the pulse and the refusal.
  - Audio: the creak on the pulse.
  - Controls: the brace's hold.

## 9. The first read, and what changed (2026-10-17)

Encounter's G1, with the switch on (`docs/director/pending/grapple-g1/`).

| Read | Band | The ruling |
| :--- | :--- | :--- |
| **The clinch's median is 85 ticks,** and half of AI v AI's clinches end at the time | 40 to 70 | **A finer tie-break:** when both pummel one pulse, the one nearer the pulse by the tick takes the step. The AI presses 3 or 4 ticks off, so half its tied pulses now move. **The leader at the time takes a 20-tick first move,** so a clinch that runs out still pays for the grip won. The length and the AI's shares (40, 65 and 85%, as in every clash) stay. The control script, which pummels on the pulse, already reads a median of 45: skill wins the grip |
| **Throw, then launch: 9.4%** | 15 to 40% | Read with window 1's rest, which made most of those Bs the hammer. **The band stands. Read it again on launch anywhere,** which retires the rest |
| **The A-tapper wins 0 of 10** | 10 to 35% | **The script was a masher:** a tap every 8 ticks always leaves a press outside the 9-tick window, so by the stray rule it never steps. That is the rule working, and the masher's row already covers it. **The alone row's script is re-defined** as a player who only uses A as it is meant: he catches in reach and pummels on the pulse at a human's spread. The band stands |

- **The AI's catch shares** (0.02, 0.04, 0.06) are confirmed, with a band of 1 to 3 catch tells a minute AI v AI (it read 1.7).
- **The AI threw only down in G1.** From G2 it varies its throws by what each hands it and by its care (§6).
