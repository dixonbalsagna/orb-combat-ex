# Rulings: the left hand survives, the right hand hurts (2026-10-28 workshop)

Owner: Game Design. Status: **rulings, paper only, amended 2026-10-30 for Orb's pick of pure 4a** and reconciled with Controls' spec (`docs/controls/right-hand-attacks.md`), whose recommended 4c+ this replaces. Every number is a first value, and wherever possible it is what Orb played or an existing move's number. Sources:
- Orb's direction and the EP's pitch: `docs/ep/right-hand-attacks-pitch.md`.
- The claw law and step 1: `right-stick-pitches.md` §13, `rulings-2026-10-26.md` items 13 to 16.
- The blows: `brawl-second-pass.md` §2 and §3.
- The rally and launch anywhere: `rulings-2026-10-23d.md`, `rulings-2026-10-26.md` §2.

Ticks are counted from the stick's crossing, as in Controls' §1. A stick request starts 2 ticks after it (the settle), and the D-pad waits the same 2. §8 answers Controls' twelve questions and lists where this differs from 4c+ and from the prototype.

**For Orb, in short.**
- The stick's quick flick is a new kind of blow: a stunning strike aimed by the flick.
- Holding the stick charges that strike, on its own ladder. It has no armour and never launches: it stuns him longer and puts him where you aimed. B is still the blow that sends him across the planet.
- In energy mode the stick is the beam. The signature stays on the power trigger and B.
- The left hand does all the defending. The trigger and a direction is a slip. Guard and a flick is a brace (the old read). Both together and a direction is the vanish.
- A player who only mashes buttons plays as today, and the reads still beat the mash.

## 1. The class: 4a, 4b or 4c

| | The case for it | The case against it |
| :--- | :--- | :--- |
| **4a, its own class** (Orb's lean) | A blow the player chooses by direction, with an identity B doesn't have and room for each fighter's own four. It matches Orb's words: "powerful directional strikes" | Its charge would duplicate B's charged heavy, which is already armoured, already knocks back or launches, and already takes a direction from the left stick. Two charged heavies with two sets of numbers would be a second balance axis for nothing. It also leans hardest on the law (Controls' model: +5 blows a claw without it) |
| **4b, pooled with heavy** | No new class. B's heavies are already chosen by direction (the one stick map: up lifts, down drives under, toward drives back, away turns him past). It is nearly claw-safe on its own | A heavy's 28-tick wind-up isn't "a quick, stunning blow". The flick would only be B with a different finger, and Orb's stunning blow would have no job of its own |
| **4c, the EP's middle** (Controls' 4c+) | Its own class on screen, with numbers anchored to bands that already exist, so there is no new axis. Each layer's stick means "the big move of the mode" | Costing the quick strike as a heavy (commitment 20) makes it a slow blow. The flick wants a medium's speed |

**The pick: pure 4a (Orb, 2026-10-30): "stick strikes are their own class of moves".** My 4c+ split is withdrawn. Every level of the stick has its own numbers (§2), starting from what Orb played in v3 and marked where I've added to it (§8).

**What 4a costs, the "new balance axis" named above:**
- **Numbers.** Four levels of timing, worth, ki, stun and carry that 4c would have borrowed from B, and each fighter may want its own later. Each needs QA's read (§7).
- **Dominance.** A second way to hit can beat Y or B outright, and a faster medium with a stun is the obvious candidate. Hence the bare wind-up, the ki and the triangle in §2.
- **The claw.** Zero gain holds only with the law on: Controls' model has 4a at +5 blows a claw without it, the most of the three. So the lockouts can never be relaxed for feel, and the gate is a hard test.
- **Authoring.** Eight pieces a fighter instead of four: 96 for a roster of twelve.
- **Teaching.** Two charged blows now do different things, and the legend has to say so.
- **What it gives up.** The aimed signature and a fourth special's slot.

## 2. The quick strike and the charged strike

**The quick strike** (level 0: the stick is back under `off` before tick 12; first values from v3's 4a, as Orb played it):
- **Timing.** Its wind-up starts at the request (tick 2) and lasts 10 ticks (v3's 4a), so it lands on tick 12. A stick still out at `D` (tick 12) turns the same wind-up into the charge (R4: a hold is its flick, continued). Nothing waits, and a slow thumb never misfires.
- **Commitment:** 14 ticks from the request, meaning the 10-tick wind-up and 4 of recovery. It is longer than Y's 12 and shorter than B's 24, and well over `L` (6), so the strike-to-button link hides the lockout. **It is the quickest stick pitch, so it leans hardest on the law** (§1).
- **Its directions, relative to him:**
  - up is a rising blow (high);
  - down is a low sweep, or a spike in the air;
  - toward is a body blow (mid);
  - away is a wide turning blow that pushes him a step off. It never sends.
- **Worth** is a medium's (2.5).
- **The stun:** a stagger of 20 ticks, never a daze. It applies **on any hit that isn't guarded or perfect-blocked**, except:
  - a trade (both blows land on the same tick), where neither fighter is stunned;
  - a blow that lands on armour that holds.
- **The stun opens a string, and a quick strike never hands over a full launch.** It is a blow of the string, as a medium is. B after it is the string's next blow and takes that place's power (0.7, under `pop.full` 0.72), so it pops unless a perfect or a wound lifts it, as with any string. No timing has to keep the launcher out of the stun. The lockout makes a claw's early press start on the same tick as a standard thumb's, so the stun is grip-neutral.
- **It beats** a medium or a heavy started at the same time (10 ticks against 12 and 28). It also beats a charge before tick 20 and **the slip that moves into it.** Same direction catches:
  - the rising blow catches a sway up;
  - the low sweep catches a duck;
  - the body blow catches a slip in;
  - the turning blow catches a back-step.
- **It loses to:**
  - **a light**, which ends its wind-up. Unlike Y, it is bare, and that is its price for the stun;
  - a guard, which blocks it as it blocks a medium, with no stun;
  - a perfect block (a reversal, as any blow);
  - **the slip that moves away from it**: a duck under the rising blow, a sway over the sweep, a back-step off the body blow, a slip in inside the turn;
  - the neutral dodge, as any blow.
- **A whiff** leaves him open for 20 ticks, as any blow out of reach.
- **So mashing stays fine for a beginner** (a mash of lights beats the quick strike), and the quick strike is the tool against mediums, heavies and slips. No brace reads it, because it is a quick blow and slips answer it.
- **Soft cost.** It costs and earns what a medium does (2 ki, which v3 didn't charge: free, it would be a better medium). The third quick strike of one direction inside 3 s still hits but doesn't stun (R8). A stick mash is capped at its commitment, as a face mash is. There is no cooldown.
- **Beyond reach** it closes the gap as a button blow does at that range (the lunge, the zip strike), at their price. Pillar 3 holds.

**The charged strike is its own move, on its own ladder** (v3's 4a numbers, Controls' ticks):

| Level | Tick | Worth | Ki | Stun | Carries him |
| :--- | ---: | ---: | ---: | ---: | :--- |
| 0, the quick strike | under 12 | 2.5 | 2 | 20 | as above |
| 1 | 12 | 3.4 | 3 | 26 | 1 bh the way aimed |
| 2 | 30 | 4.3 | 4 | 32 | 2 bh |
| 3 | **54** | 5.5 | 5 | 40 | 4 bh |

- **Its identity against B: B sends him, and the stick puts him where you aimed.**
  - **B** is armoured, breaks a guard, hits for more (6 tapped, more charged), and launches him across the planet on the director's staging, with the stick only a nudge.
  - **The stick** is bare, never breaks a guard, hits for less, and **never sends him.** He stays in reach, where the direction says: up floats him and he comes back down in reach, as a pop does (`rulings-2026-10-23c.md` row 1); down drives him to the floor or spikes him; toward drives him back; away turns him past. The direction here is a call rather than a nudge, because no launch is involved, so questionnaire 19 (the player nudges, the director stages a launch) stands. It makes no journey, adds nothing to the launch rows and asks nothing of the camera.
  - **So the choice is real:** keep the fight here and in your hands, or send it across the world.
- **The triangle:** a guard beats the stick, the stick beats B (10 ticks against 28, and a stun ends a wind-up), and B beats the guard. A light beats the stick too, and that is the price of the stun.
- **Bare at every level.** A light, a medium, a grab, energy or a perfect block on its release ends or answers it, and the charge is lost. That is what Orb played. Brace high reads it as "a heavy or a charged blow".
- **Level 3 sets up the send.** The next B within the stun is a full launch, as on a wound. Levels 0 to 2 pop by the string's rule. So 54 bare ticks are a real bet with a real reward.
- **One stun a string.** Any stick strike on a fighter already stick-stunned in this string still hits and carries, and stuns nothing. Without it the four directions chain: 14 of commitment against a stun of 20 is a lock that the third-repeat rule doesn't catch. It limits a stun and never a hit, so the string runs as long as the presses (Orb's "no strict caps").
- **On a guard:** blocked as a medium is, with no stun, at every level.
- **Reach:** a quarter of a bh more for each level. **Beyond reach** it closes the gap at the lunge's price (pillar 3).
- **Committed** for 16 ticks after the release. **Held to 70 ticks it goes by itself,** as B does.
- **A guard or dodge press cancels the charge, and the charge is lost.** The guard rises and the dodge starts on their own press tick (T1), the dodge paying its own cost, and LB's edge is still the perfect-block attempt. A kept charge would make the left hand a free shield for the right (Controls' Q4, adopted).
- **Face presses are inert while the stick is held** (Controls' K3, adopted). A face press queues and starts at the release plus `L`, or it expires.

**From guard or the manoeuvre stance,** a strike carries that stance into the director's table (the mask at the crossing tick), exactly as a face press does.
- From LB it is a guard-layer strike, as the defensive checks are, drawn from that cell's pieces by direction.
- From LT it is a strike on the move, drawn from the travel cell's blows.
- Neither needs a new generator cell.

## 3. Beams on the energy stick, and the signature

- **RB + stick is the beam,** on the same reader.
  - **Level 0 is the snap-beam:** a short, thin beam with the heavy blast's wind-up and ki. It cuts through a blast it meets, is overpowered by any charged beam, can never open a struggle, and a guard blocks it.
  - **Levels 1 to 3 charge the beam** at 12, 30 and 54 (Controls' ladder).
  - **The aim is latched at the settle** (toward is at him, up and down are 45 degrees, away is behind), and the release fires along it. While the beam is out, the stick steers its sweep 32-way (R25). The latched aim line of §13.4's RB rows retires, and blasts fire toward him (Q11).
- **RB + B is the heavy blast.** Held, it charges a bigger blast in two levels, as a held Y does. So no button press can ever become a beam, and `energy-input.md` §6's rule against misfires now holds by which control is used.
- **In a struggle the stick does nothing** (my addition to Controls' "rooted" row). The surges are face presses on a pulse (X, Y or B, A to let go: §13.5). A sweep alongside them would pair the stick and a button in one beat, and a claw would gain from it. So once beams meet they lock, and the stick is inert until the struggle ends. Outside a struggle the sweep stands, and no face button acts while his beam is out, since he is rooted.
- **LT while his own rooted beam is out is never refused** (changes Research's v3 call, which refused it). Outside a struggle, LT's tap ends the beam early (`energy-overhaul.md` E48, standing) and does nothing else. The dodge needs a fresh LT, and the vanish chord only cuts the beam too. One press does one thing, so a cut beam is a way out that the rival can still read, never a free escape, and no press is dead (control first). In a struggle LT does nothing: letting go is A on the pulse (E95).
- **The signature stays on RT + B, fired at him, and RT + stick does nothing** (pure 4a, as Orb played it). So the stick doesn't aim it and there's no fourth special's slot. It keeps 45 ki, is refused at once when he can't pay, and its variant stays the director's, chosen by biome, altitude and the defender's stance (pillar 7).
- **The kite (LT + RB, hybrid 10) is on.**
  - Blasts and snap-beams fire on the move.
  - A charged beam may be built while sprinting, but **its release plants him:** the sprint ends and he is rooted while the beam is out. So the big beam stays a commitment and kiting stays a ki gamble. The chaser's lunge closes any gap (pillar 3).
- **Mirrors and remapping.** Every stick command has its D-pad, key and swipe form at the same tick (R32). The D-pad mirror is a setting, off by default, and on automatically for a pad with no right stick (Controls). **Accessibility and customizable controls are assumed (Orb, 2026-10-30),** including a left-handed player swapping the pad round: a swapped layout keeps the same law and the same ticks.
- **Simple:** stick strikes are off by default, and Simple-S moves the defence to LT and LB (Controls' §4.3). With them off, the director may still pick a quick strike's piece for a Simple heavy at a modest rate, as it sets reads, so Simple players see the class.

## 4. The left hand: slips, braces and the vanish

The reads are Controls' (`right-hand-attacks.md` §2). The game needs only three things of them, and Controls' reads give all three:
- a **reaction** (the slip, the vanish) starts on its press tick;
- a **prediction** (the brace) never comes from a guard lean;
- **a slip out of guard stays possible:** LT pressed after LB has been held more than 6 ticks is the ordinary dodge.

| Move | Cost | With the guard | With a perfect block |
| :--- | :--- | :--- | :--- |
| **Slip** (LT tap and a left flick, R34) | The dodge's cost, paid only when it affects an exchange. The third slip of one direction inside 3 s keeps its movement and loses its slip frames. **The neutral dodge is a direction of its own** under this rule (Research's v3 call, confirmed 2026-10-28): without it, chained plain dodges are untouchable for any window | Drops the guard for its ticks. The guard comes back if LB is still held | Separate. The perfect block is LB's own edge, and a slip opens no window |
| **Brace** (LB and a left flick from rest: R36's read, now on the left thumb) | 3 ki. It lasts until it fires or 90 ticks, one at a time, and reads only his attacks that start after it. The four reads and the look are R36 and R37, unchanged. **A wrong brace costs 3 ki and nothing else** | It sits on top of the guard. A match plays the brace instead of the block. A miss leaves the block | On the same blow the perfect block wins (the bigger reward) and the brace stays set |
| **Vanish** (LB and LT within 6 ticks in either order, and a direction: an upgrade of the dodge) | **20 ki in all, the dodge's cost included,** ×1.5 for each further vanish inside 3 s. A soft cost, never a cooldown | It replaces the guard for its blink | A perfect block already earned is never spent on it. Whatever the first shoulder started (the guard, the window, the dodge) stands until tick 6, when the blink begins |

**The brace while stunned or launched:** none can be set then, since the sim already reads held states as false during stun ticks. One set before the hit keeps its 90 ticks.

**The vanish, in full.**
- **The blink** is a short one (about 3 bh), invulnerable for about 8 ticks from tick 6. The dodge's own slip frames cover ticks 0 to 6.
- **The directions:**
  - **away is the escape.** It lets the brawl go, as the zip away does, and the chaser may follow at the lunge's price. So it is a gamble (pillar 3);
  - **through** puts him at the rival's back. A blow in flight whiffs, which gives a plain opening (20 ticks) and **never a daze**. In a brawl, the brawl goes on with the sides swapped;
  - **up and down** go over and under him, and a brawl goes on;
  - **with the stick neutral, it goes away.**
- **Not available** while stunned, launched, caught or clinched (the clinch keeps its own ways out), nor during a rush. It counts as ESCAPE for a beam's outcome.
- **The look:** an instant cut with sharp after-images, the tech look. Never a fade or a dissolve (Orb, 2026-10-18). It goes through the look gate.
- **Yes, it replaces R3 Escape.** Three ways out remain, and they don't overlap:
  - the escape stance (sprint away) is slow and free;
  - the vanish is instant, priced, and can be followed;
  - the zip away is dear and reliable, with a parting blow.
- R3 does nothing until a target swap has a use (henchmen).

## 5. Pillar 2 and the generator

**The wording is open again (Orb, 2026-10-30): "Intent, not combos" isn't accepted.** The options for Orb's pick are `pillar-2-wordings.md`, and `pillars.md` stays as it is until then. Whatever Orb picks, the rule for this page stands: **a strike is a flick or a hold, never a pattern,** which keeps the right stick's five patterns (§2) parked. The brace is the stance's modern form (R36), now where the stances always belonged, on the hand that survives.

**The face-button slots don't change in number.** One cell moves, and two stick cells are added:

| Held | X | Y | B | A | Right stick |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Nothing (martial) | light | medium | heavy, the launcher | grab | **new `martial.stick`:** four quick strikes and four charged strikes |
| RB (energy) | bolts | blasts | heavy blast (**the beam leaves**) | context | **`energy.stick`:** the snap-beam and the charged beam (the beam's cell moves here) |
| RT (power) | special 1 | special 2 | **the signature, as today** | special 3 | nothing |
| LB (defensive) | checks | pushes | as today | as today | a guard-layer strike from the checks' pieces |
| LT (manoeuvre) | travel | travel | as today | as today | a strike on the move from the travel cell's blows |
| LB + RB (the lay) | lay | lay | lay | lay | nothing |

- **Authoring.** Eight strike pieces a fighter (`martial.stick`), stand-ins first from the quick mediums by direction. Levels 1 to 3 of a direction share one piece, played bigger.
- **What needs no generator cell:** the brace and the slip (the director's existing slip and stagger pieces), and the vanish (a blink pose and VFX).
- **Variety rule:** a stick strike never repeats the piece the same direction's button blow just threw in the string.

## 6. What this retires from `right-stick-pitches.md` §13

- **The law stands** (R28 to R33, R32b), restated as Controls' K1 to K7, with **a strike, a beat of its own,** as a fifth kind of command.
- **R34 and R35 stand.**
- **R36 to R38 stand except their input:** LB and a right flick becomes LB and a left flick.
- **Retired:**
  - §13.4's movement rows with nothing held (lunge, steps, hop, drop, dash, orbit, wall run, skim). Flight and LT already own those moves;
  - R31 (the step carries the blow);
  - the RB aim rows;
  - the stance radial;
  - R10.

## 7. Owners and reads

**Released for routing:** Orb has played the prototype and picked 4a. Pillar 2's wording is still Orb's (`pillar-2-wordings.md`) and nothing below waits on it.

| What | Owner |
| :--- | :--- |
| The reader; the left-hand upgrade; hybrids 3 and 10; the mirror setting; the gate's rows J to R plus "a stick in a struggle changes nothing"; remapping with the law intact, including a left-handed swap of the pad | Controls |
| The stick strike at all four levels (§2's table) as data: timing, stun, carry, ki, one stun a string, level 3's launch; the AI's use of strikes, braces, slips and the vanish, and its answers to them; the snap-beam and the beam on the stick; the kite's planted release | Encounter |
| `martial.stick` (four quick and four charged), `energy.stick`, the guard and travel lanes' draws | Combat |
| Eight strike pieces a fighter, a blink pose, a charge stance that reads by direction without a marker | Animation |
| The vanish's after-images, the charge's look on the body, through the look gate (ADR 0010) | VFX |
| The charge's and the stun's sounds | Audio |
| The stick strike's data file and its schema; the claw sweep kept as a CI gate | Tools |
| A stun's and a charge's framing, only if QA or the look gate asks for it | Camera |
| The legend and the how-to-play: what the stick does that B doesn't, and the stick's beam early, because with the mirror off a player who never uses the stick has no beam | UI |
| Re-run the claw sweep at these numbers, then retire v3 as a reference | Research |

**QA reads it before any tune, on the new class first:**
- **No best button,** the first thing 4a can break: a stick-only script, a buttons-only script and a mix at each level. Stick-only and buttons-only within 10 points of each other, and the mix at least level with both. Band is a first value.
- **The triangle:** a guard beats the stick, the stick beats B, B beats the guard; each read by who wins the meeting, above 50%.
- **The stick's share of blows** when a script is free to use it: 10 to 30%. **Y's and B's shares** beside it, since the class must add a choice rather than replace one.
- **Level 3 landed,** of those started: 15 to 40%. Under that the bare charge isn't worth the risk; over it the armour on B has no point.
- **Hard test:** no fighter is stick-stunned twice in one string, and no stun lands on a stunned fighter.
- **The standing rows:** the masher (35 to 50%); L17 (the newcomer against medium 10 to 50%, against easy 50 to 95%); dazes a match; launches a match, against the launch round (`rulings-2026-10-30f.md`); slips and vanishes a match; kite time; p10 on 200 matches.
- **The claw gate** at these numbers, zero gain, as a hard test.

**Nothing is tuned on paper beyond these first values.**

## 8. Controls' twelve questions, and what changed

| # | Question | Ruling |
| :--- | :--- | :--- |
| 1 | 4a, 4b or 4c | **4a, pure** (Orb, 2026-10-30; §1). Every level is its own class |
| 2 | The quick strike's stun and recovery; on any hit or a clean one | 20-tick stun on any hit not guarded or perfect-blocked, not a trade, not into armour that holds, and once a string. Wind-up 10, commitment 14. A whiff is open 20 (§2) |
| 3 | The ladder | **Three levels at 12, 30 and 54,** for strikes and beams alike. The stick no longer flashes with B held, because it isn't the same move |
| 4 | Do a guard or a dodge cancel a charge, and is it kept | **Cancel, and it's lost;** the dodge pays its own cost. Adopted |
| 5 | B in the energy layer | Tap is the heavy blast. Hold is a bigger blast in two levels. Adopted |
| 6 | Signature on RT + stick, or a special 4 on RT + B | **No, by Orb's pick.** The signature stays on RT + B, fired at him. RT + stick does nothing |
| 7 | The vanish: cost, cooldown, in a brawl or a clinch, R3 | 20 ki with the dodge's included, ×1.5 inside 3 s, no cooldown. In a brawl, away lets it go and the other ways keep it. Not in a clinch. **Replaces R3**; the dodge with the stick away stays |
| 8 | The brace while stunned; a wrong read's cost | None can be set while stunned or launched (one set before keeps its time). A wrong one costs 3 ki and nothing else |
| 9 | Hybrids | **3 and 10 on, 9 off.** Hybrid 3 is the lay: it stays on LB + RB and a face button, and the stick no longer places it, which was 4c+ only. The kite's charged beam plants him at the release |
| 10 | The stance lane of a strike from guard or LT | The mask at the crossing tick, as a face press. LB is a guard-layer strike, LT a strike on the move |
| 11 | Blast aim | **Toward him, always.** The aimed shot is the beam. A lean arc would make every blast thrown while moving or kiting bend by accident |
| 12 | Simple | Stick strikes off by default; on, Simple-S. The director may still pick a quick strike's piece for a Simple heavy |

**Where this differs from 4c+ and from v3's 4a.**
- **4c+ is withdrawn** (Orb, 2026-10-30): the commitment of 16, the armoured charge, the 50-tick flash, the signature on the stick, the fourth special and the stick placing the lay.
- **From what Orb played in v3's 4a,** the timing, ladder, armour, stuns and damage steps are unchanged. **My additions, none of which v3 tested:** ki (it had none, so the strike would have been a free, faster medium with a stun), one stun a string, a level 3 that sets up a full launch, and a carry of 4 bh where v3's pop was 8, so he stays in reach.
- **In a struggle the stick does nothing,** a rule the claw-bot gate should assert alongside the "rooted" row.
- **On Orb's open questions:** the vanish replaces R3, and the D-pad mirror is a setting, off by default, which Orb's answer on customizable controls settles.
