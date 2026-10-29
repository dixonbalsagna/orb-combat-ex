# Rulings: the left hand survives, the right hand hurts (2026-10-28 workshop)

Owner: Game Design. Status: **rulings for the workshop, paper only,** reconciled with Controls' spec (`docs/controls/right-hand-attacks.md`). Every number is a first value, and wherever possible it is an existing move's number. Sources:
- Orb's direction and the EP's pitch: `docs/ep/right-hand-attacks-pitch.md`.
- The claw law and step 1: `right-stick-pitches.md` §13, `rulings-2026-10-26.md` items 13 to 16.
- The blows: `brawl-second-pass.md` §2 and §3.
- The rally and launch anywhere: `rulings-2026-10-23d.md`, `rulings-2026-10-26.md` §2.

Ticks are counted from the stick's crossing, as in Controls' §1. A stick request starts 2 ticks after it (the settle), and the D-pad waits the same 2. §8 answers Controls' twelve questions and lists where I differ from 4c+.

**For Orb, in short.**
- The stick's quick flick is a new kind of blow: a stunning strike aimed by the flick.
- Holding the stick is the charged heavy, aimed by the stick. So the charge adds no new balance to tune, and B held still does it for anyone who never touches the stick.
- In energy mode the stick is the beam. With the power trigger held, it is the signature (held, then let go), which frees B there for a fourth special.
- The left hand does all the defending. The trigger and a direction is a slip. Guard and a flick is a brace (the old read). Both together and a direction is the vanish.
- A player who only mashes buttons plays as today, and the reads still beat the mash.

## 1. The class: 4a, 4b or 4c

| | The case for it | The case against it |
| :--- | :--- | :--- |
| **4a, its own class** (Orb's lean) | A blow the player chooses by direction, with an identity B doesn't have and room for each fighter's own four. It matches Orb's words: "powerful directional strikes" | Its charge would duplicate B's charged heavy, which is already armoured, already knocks back or launches, and already takes a direction from the left stick. Two charged heavies with two sets of numbers would be a second balance axis for nothing. It also leans hardest on the law (Controls' model: +5 blows a claw without it) |
| **4b, pooled with heavy** | No new class. B's heavies are already chosen by direction (the one stick map: up lifts, down drives under, toward drives back, away turns him past). It is nearly claw-safe on its own | A heavy's 28-tick wind-up isn't "a quick, stunning blow". The flick would only be B with a different finger, and Orb's stunning blow would have no job of its own |
| **4c, the EP's middle** (Controls' 4c+) | Its own class on screen, with numbers anchored to bands that already exist, so there is no new axis. Each layer's stick means "the big move of the mode" | Costing the quick strike as a heavy (commitment 20) makes it a slow blow. The flick wants a medium's speed |

**The pick: 4c, with Controls' "+" settings, split by gesture.** It is Orb's 4a wherever the class has a job of its own, and 4b wherever it would only duplicate one.
- **Level 0, the quick strike, is its own class: the stick strike.** It has its own pieces, its own look and its own rule, the stun (§2). It is priced between the medium and the heavy, not as a heavy.
- **Levels 1 to 3 are the charged heavy, aimed by the stick.** It is the same move as B held, with the same numbers, armour and launch. The stick's direction takes the place of the left stick's nudge. B held keeps it for a player who never uses the stick (`right-stick-pitches.md` R6).

So there is one new class, level 0, and no new balance axis. If Orb wants pure 4a, give levels 1 to 3 their own numbers later, after a QA read. Nothing here blocks that.

## 2. The quick strike and the charged strike

**The quick strike** (level 0: the stick is back under `off` before tick 12; first values from Y's row in `brawl-second-pass.md`):
- **Timing.** Its wind-up starts at the request (tick 2) and lasts 12 ticks. A stick still out at `D` (tick 12) turns the same wind-up into the charge (R4: a hold is its flick, continued). Nothing waits, and a slow thumb never misfires.
- **Commitment:** 16 ticks from the request, meaning the 12-tick wind-up and 4 of recovery. This replaces Controls' placeholders (4a 14, 4c 20). It is longer than Y's 12 and shorter than B's 24, and well over `L` (6), so the strike-to-button link hides the lockout.
- **Its directions, relative to him:**
  - up is a rising blow (high);
  - down is a low sweep, or a spike in the air;
  - toward is a body blow (mid);
  - away is a wide turning blow that pushes him a step off. It never sends.
- **Worth** is a medium's (2.5).
- **The stun:** a stagger of 20 ticks, never a daze. It applies **on any hit that isn't guarded or perfect-blocked**, except:
  - a trade (both blows land on the same tick), where neither fighter is stunned;
  - a blow that lands on armour that holds.
- **The stun opens a string. It never hands over a full launch.** The quick strike is a blow of the string, as a medium is. B after it is the string's next blow and takes that place's power (0.7, under `pop.full` 0.72), so it pops unless a perfect or a wound lifts it, as with any string. No timing has to keep the launcher out of the stun. The lockout makes a claw's early press start on the same tick as a standard thumb's, so the stun is grip-neutral.
- **It beats** a heavy started at the same time (12 ticks against 28, and mediums interrupt a heavy until tick 20). It also beats a charge before tick 20 and **the slip that moves into it.** Same direction catches:
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
- **So mashing stays fine for a beginner** (a mash of lights beats the quick strike), and the quick strike is the tool against heavies and slips. No brace reads it, because it is a quick blow and slips answer it.
- **Soft cost.** It costs and earns what a medium does. The third quick strike of one direction inside 3 s still hits but doesn't stun (R8). A stick mash is capped at its commitment, as a face mash is. There is no cooldown.
- **Beyond reach** it closes the gap as a button blow does at that range (the lunge, the zip strike), at their price. Pillar 3 holds.

**The charged strike is the charged heavy, unchanged** (`brawl-second-pass.md` §3), on Controls' one ladder:

| Level | Tick | What it is |
| :--- | ---: | :--- |
| 1 | 12 | The hold is recognised, and he is armoured against lights (half their damage) from here. Mediums interrupt him until tick 22 (the heavy's tick 20). From here it is a charged blow for `rulings-2026-10-26.md` item 23, so a guard it breaks is a daze |
| 2 | 30 | A step of the fill the charged heavy already has: more reach and more launch power |
| 3 | **50** | **Full, the flash.** It knocks back, or launches at full power. 50 is the charged heavy's 48 plus the stick's 2-tick settle, so the stick and B held flash at the same point of the move. Controls' 54 is for beams only |

- **Committed** for B's 24 ticks after the release.
- **Its direction is a nudge, never a call.** It weights the launch planner exactly as the left stick's nudge weights B today, and the director still stages the send (questionnaire 19 stands).
- **It loses to** a grab, a medium before tick 22, energy, a perfect block on its release, and brace high, which reads "a heavy or a charged blow".
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
- **The signature moves to RT + stick, hold and release only** (Controls' Q6, adopted; I had a flick firing it).
  - A stick back before tick 12 fires nothing and costs nothing, so a grazed stick never spends 45 ki. The cue for that is the hands gathering and dropping, plus the legend's hint, never text over the fighters.
  - The hold aims it, shown in his stance and hands and never as a line or a marker. The release fires it.
  - It keeps 45 ki and is refused at once when he can't pay.
  - The variant stays the director's, chosen by biome, altitude and the defender's stance (pillar 7). The stick aims it and never picks it.
  - Only the power layer's signature moves. The stances' own B signatures stay.
- **RT + B is the fourth special's slot.** Until a fighter has one, RT + B fires that fighter's signature at him, so nothing goes missing in between.
- **The kite (LT + RB, hybrid 10) is on.**
  - Blasts and snap-beams fire on the move.
  - A charged beam may be built while sprinting, but **its release plants him:** the sprint ends and he is rooted while the beam is out. So the big beam stays a commitment and kiting stays a ki gamble. The chaser's lunge closes any gap (pillar 3).
- **Mirrors.** Every stick command has its D-pad, key and swipe form at the same tick (R32). The D-pad mirror is a setting, off by default, and on automatically for a pad with no right stick (Controls). The D-pad does nothing else, so off loses nothing.
- **Simple:** stick strikes are off by default, and Simple-S moves the defence to LT and LB (Controls' §4.3). With them off, the director may still pick a stick strike's piece for a Simple heavy at a modest rate, as it sets reads, so Simple players see the class.

## 4. The left hand: slips, braces and the vanish

The reads are Controls' (`right-hand-attacks.md` §2). The game needs only three things of them, and Controls' reads give all three:
- a **reaction** (the slip, the vanish) starts on its press tick;
- a **prediction** (the brace) never comes from a guard lean;
- **a slip out of guard stays possible:** LT pressed after LB has been held more than 6 ticks is the ordinary dodge.

| Move | Cost | With the guard | With a perfect block |
| :--- | :--- | :--- | :--- |
| **Slip** (LT tap and a left flick, R34) | The dodge's cost, paid only when it affects an exchange. The third slip of one direction inside 3 s keeps its movement and loses its slip frames | Drops the guard for its ticks. The guard comes back if LB is still held | Separate. The perfect block is LB's own edge, and a slip opens no window |
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

**Pillar 2 survives, reworded.** Proposed wording, **Orb's creative call** (the EP asks Orb after the prototype; `pillars.md` stays as it is until then): "Intent, not combos. The left hand chooses intent (guard, evade, brace: the old stances). The right hand chooses weight and direction. The director owns which blow lands, the string, the links and the staging. No input is a combo: a press is a blow, a flick is a blow, and there are no motion inputs."
- That last clause keeps the right stick's five patterns (§2) parked: **a strike is a flick or a hold, never a pattern.**
- The brace is the stance's modern form (R36), now where the stances always belonged, on the hand that survives.

**The face-button slots don't change in number.** One cell moves, and two stick cells are added:

| Held | X | Y | B | A | Right stick |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Nothing (martial) | light | medium | heavy, the launcher | grab | **new `martial.stick`:** four quick strikes. Levels 1 to 3 use B's charged-heavy pieces by direction |
| RB (energy) | bolts | blasts | heavy blast (**the beam leaves**) | context | **`energy.stick`:** the snap-beam and the charged beam (the beam's cell moves here) |
| RT (power) | special 1 | special 2 | **special 4** (the signature until it exists) | special 3 | the signature, held and released (its frame cell moves here) |
| LB (defensive) | checks | pushes | as today | as today | a guard-layer strike from the checks' pieces |
| LT (manoeuvre) | travel | travel | as today | as today | a strike on the move from the travel cell's blows |
| LB + RB (the lay) | lay | lay | lay | lay | places the lay (Controls' 4c+) |

- **Authoring.** Four quick-strike pieces a fighter (`martial.stick`, stand-ins first from the quick mediums by direction) and a fourth special a fighter, when Orb wants it.
- **What needs no generator cell:** the charged strike (heavy tier, mapped by direction), the brace and the slip (the director's existing slip and stagger pieces), and the vanish (a blink pose and VFX).
- **Variety rule:** a quick strike never repeats the piece the same direction's button blow just threw in the string.

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

**Held until Orb has played the prototype** (EP, 2026-10-28): none of this routing goes out before then.

| What | Owner |
| :--- | :--- |
| The reader, the left-hand upgrade, hybrids 3 and 10, the mirror setting, the gate's rows J to R plus "a stick in a struggle changes nothing" | Controls |
| The quick strike's numbers; the AI's use of strikes, braces, slips and the vanish; the snap-beam and the beam on the stick; the kite's planted release | Encounter |
| `martial.stick`, `energy.stick`, the signature's cell move, special 4 when wanted | Combat |
| Four quick-strike pieces, a blink pose | Animation |
| The vanish's after-images | VFX |
| A playable prototype of 4c+ split by gesture, beside pure 4a | Research |
| The legend and the how-to-play: teach the stick's beam early, because with the mirror off a player who never uses the stick has no beam | UI |

**QA reads it before any tune:**
- the masher (35 to 50%);
- L17 (the newcomer against medium 10 to 50%, against easy 50 to 95%);
- dazes a match, since an aimed charged heavy may break more guards;
- slips and vanishes a match;
- kite time;
- p10 on 200 matches.

**Nothing is tuned on paper beyond these first values.**

## 8. Controls' twelve questions, and where I differ from 4c+

| # | Question | Ruling |
| :--- | :--- | :--- |
| 1 | 4a, 4b or 4c | **4c+, split by gesture** (§1). Level 0 is its own class at a commitment of 16. Levels 1 to 3 are the charged heavy |
| 2 | The quick strike's stun and recovery; on any hit or a clean one | 20-tick stun on any hit not guarded or perfect-blocked, not a trade, not into armour that holds. Recovery 4 (commitment 16). A whiff is open 20 (§2) |
| 3 | The ladder: 3 levels at 12, 30, 54, or fewer | **Three levels.** Strikes at 12, 30, **50** (the charged heavy's flash plus the settle); beams at 12, 30, 54 |
| 4 | Do a guard or a dodge cancel a charge, and is it kept | **Cancel, and it's lost;** the dodge pays its own cost. Adopted |
| 5 | B in the energy layer | Tap is the heavy blast. Hold is a bigger blast in two levels. Adopted |
| 6 | Signature on RT + stick, hold and release only; special 4 on RT + B | **Yes,** and RT + B fires the signature until a fighter has a special 4 |
| 7 | The vanish: cost, cooldown, in a brawl or a clinch, R3 | 20 ki with the dodge's included, ×1.5 inside 3 s, no cooldown. In a brawl, away lets it go and the other ways keep it. Not in a clinch. **Replaces R3**; the dodge with the stick away stays |
| 8 | The brace while stunned; a wrong read's cost | None can be set while stunned or launched (one set before keeps its time). A wrong one costs 3 ki and nothing else |
| 9 | Hybrids | **3 and 10 on, 9 off.** The kite's charged beam plants him at the release |
| 10 | The stance lane of a strike from guard or LT | The mask at the crossing tick, as a face press. LB is a guard-layer strike, LT a strike on the move |
| 11 | Blast aim | **Toward him, always.** The aimed shot is the beam. A lean arc would make every blast thrown while moving or kiting bend by accident |
| 12 | Simple | Stick strikes off by default; on, Simple-S. The director may still pick a stick strike's piece for a Simple heavy |

**Where I differ from Controls' 4c+:**
- **Costing.** Not "costed as heavy" for the whole stick. Level 0 sits between the medium and the heavy (commitment 16 for 4c's placeholder 20, wind-up 12, worth 2.5). Levels 1 to 3 are the heavy itself, numbers and all. A heavy-costed quick strike would be 4b's slow blow again.
- **The strike's top level is 50, not 54,** so the stick and B held flash together.
- **In a struggle the stick does nothing,** a rule the claw-bot gate should assert alongside the "rooted" row.
- **RT + B keeps the signature** until a fourth special exists.
- **On Orb's open questions I agree with Controls:** the vanish replaces R3, and the D-pad mirror is a setting, off by default.
