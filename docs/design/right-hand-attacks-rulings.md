# Rulings: the left hand survives, the right hand hurts (2026-10-28 workshop)

Owner: Game Design. Status: **rulings for the workshop, paper only.** Every number is a first value, and wherever possible it is an existing move's number. Sources:
- Orb's direction and the EP's pitch: `docs/ep/right-hand-attacks-pitch.md`.
- The claw law and step 1: `right-stick-pitches.md` §13, `rulings-2026-10-26.md` items 13 to 16.
- The blows: `brawl-second-pass.md` §2 and §3.
- The rally and launch anywhere: `rulings-2026-10-23d.md`, `rulings-2026-10-26.md` §2.

Controls writes the input maps (`docs/controls/right-hand-attacks.md`). Where a ruling here says what an input must do, Controls decides how it is read.

**For Orb, in short.**
- The stick's quick flick is a new kind of blow: a stunning strike aimed by the flick.
- Holding the stick is the charged heavy, aimed by the stick. So the charge adds no new balance to tune, and B held still does it for anyone who never touches the stick.
- In energy mode the stick is the beam. With the power trigger held, it is the signature, which frees B there for a fourth special.
- The left hand does all the defending. The trigger and a direction is a slip. Guard and a flick is a brace (the old read). Both together and a direction is the vanish.
- A player who only mashes buttons plays as today, and the reads still beat the mash.

## 1. The class: 4a, 4b or 4c

| | The case for it | The case against it |
| :--- | :--- | :--- |
| **4a, its own class** (Orb's lean) | A blow the player chooses by direction, with an identity B doesn't have and room for each fighter's own four. It matches Orb's words: "powerful directional strikes" | Its charge would duplicate B's charged heavy, which is already armoured, already knocks back or launches, and already takes a direction from the left stick. Two charged heavies with two sets of numbers would be a second balance axis for nothing |
| **4b, pooled with heavy** | No new class. B's heavies are already chosen by direction (the one stick map: up lifts, down drives under, toward drives back, away turns him past), so the generator has the pieces | The flick would only be B with a different finger. Nothing about it would be "powerful" or special, and Orb's stunning blow would have no job of its own |
| **4c, the EP's middle** | Its own class on screen, with numbers anchored to bands that already exist, so there is no new axis | Anchored on the heavy's numbers, the quick flick would be a slow blow. The pitch's 4c costs the whole stick like B, but the flick wants a medium's speed |

**The pick: 4c, split by gesture.** It is Orb's 4a wherever the class has a job of its own, and 4b wherever it would only duplicate one.
- **The flick is its own class: the stick strike.** It has its own pieces, its own look and its own rule, the stun (§2). Its numbers sit in the medium's band.
- **The hold is the charged heavy, aimed by the stick.** It is the same move as B held, with the same numbers, armour and launch. The stick's direction takes the place of the left stick's nudge. B held keeps it for a player who never uses the stick (`right-stick-pitches.md` R6).

So there is one new class, the flick, and no new balance axis. If Orb wants pure 4a, give the hold its own ladder later, after a QA read. Nothing here blocks that.

## 2. The flick strike and the charged strike

**The flick strike** (martial mode, nothing held; first values from Y's row in `brawl-second-pass.md`):
- **Timing.** Its wind-up starts at the flick's peak and lasts 12 ticks. If the stick is still out at Controls' decision tick (about 8), the same wind-up becomes the charged heavy's (R4: a hold is its flick, continued). Nothing waits, and a slow thumb never misfires.
- **Its directions, relative to him:**
  - up is a rising blow (high);
  - down is a low sweep, or a spike in the air;
  - toward is a body blow (mid);
  - away is a wide turning blow that pushes him a step off. It never sends.
- **Worth** is a medium's (2.5). **On a hit it stuns:** a stagger of 20 ticks, never a daze.
- **The stun opens a string, not a launch.** It is set so that after the lockout a light or a medium lands inside it, and B's launcher (14 ticks) doesn't. Encounter sets the exact length from the lockout. Since the lockout makes a claw's early press start on the same tick, the stun is grip-neutral.
- **It beats** a heavy started at the same time (12 ticks against 28, and mediums interrupt a heavy until tick 20). It also beats a charge before its armour and **the slip that moves into it.** Same direction catches:
  - the rising blow catches a sway up;
  - the low sweep catches a duck;
  - the body blow catches a slip in;
  - the turning blow catches a back-step.
- **It loses to:**
  - **a light**, which ends its wind-up. Unlike Y, it is bare, and that is its price for the stun;
  - a guard, which blocks it with no stun;
  - a perfect block (a reversal, as any blow);
  - **the slip that moves away from it**: a duck under the rising blow, a sway over the sweep, a back-step off the body blow, a slip in inside the turn;
  - the neutral dodge, as any blow.
- **So mashing stays fine for a beginner** (a mash of lights beats the flick), and the flick is the tool against heavies and slips. No brace reads it, because it is a quick blow and slips answer it.
- **Soft cost.** It costs and earns what a medium does. The third flick of one direction inside 3 s still hits but doesn't stun (R8). There is no cooldown.
- **Beyond reach** it closes the gap as a button blow does at that range (the lunge, the zip strike), at their price. Pillar 3 holds.

**The charged strike** is the charged heavy, unchanged (`brawl-second-pass.md` §3):
- it is armoured from its first tick against lights, which do half damage through the armour;
- mediums interrupt it until tick 20;
- it is full at 48 ticks, at the flash;
- it knocks back, or launches at the power launch anywhere gives it.
- **No new levels.** One visible step, the flash, is the read both players share.
- **Armour starts** when the hold is recognised (about tick 8). A light in the ticks before that ends it, as it would end the flick.
- **Its direction is a nudge, never a call.** It weights the launch planner exactly as the left stick's nudge weights B today, and the director still stages the send (questionnaire 19 stands). A full charge breaking a guard dazes, as any charged blow does (`rulings-2026-10-26.md` item 23).
- **It loses to** a grab, a medium or heavier blow before tick 20, energy, a perfect block on its release, and brace high, which reads "a heavy or a charged blow".

**With LB or LT held** the stick keeps its mode's job. A strike from guard drops the guard, as any blow does. The defensive and manoeuvre cells stay on the face buttons.

## 3. Beams on the energy stick, and the signature

- **RB + stick is the beam.**
  - **A flick is the snap-beam:** a short, thin beam along the flick, with the heavy blast's wind-up and ki. It cuts through a blast it meets and is overpowered by any charged beam. It can never open a struggle, and a guard blocks it.
  - **A hold charges the beam** in its three levels (`energy-input.md`). The release fires at the level reached, along the stick's last direction before it came home. A release before level 1 is the snap-beam.
  - While the beam charges, the stick sweeps its aim. **Its aim is the stick.** The latched aim line of §13.4's RB rows retires, and blasts aim as they do today.
- **RB + B is the heavy blast only.** Held, it charges as a held Y does (two levels). So no button press can ever become a beam, and `energy-input.md` §6's rule against misfires now holds by which control is used.
- **The struggle stays on the buttons.** Once beams meet, they lock: no sweep, and the stick does nothing. The surges keep X, Y and B on the pulse and A to let go (§13.5), so there is never a stick and a button in one beat. Outside a struggle, the stick may sweep a beam that is out, and no button acts meanwhile, since he is rooted.
- **The signature moves to RT + stick.**
  - A flick fires it along the flick. A hold aims it, shown in his stance and hands and never as a line or a marker, and the release fires it.
  - It keeps 45 ki and the refusal when he can't pay.
  - The variant stays the director's, chosen by biome, altitude and the defender's stance (pillar 7). The stick aims it and never picks it.
  - Only the power layer's signature moves. The stances' own B signatures stay.
- **RT + B keeps the signature until each fighter has a fourth special.** Then it becomes that special, the charging stance's B cell, so nothing goes missing in between.
- **Mirrors.** Every row has its D-pad, key and swipe form at the same tick (R32). On Simple, beams stay automatic and the director throws a stick strike at a modest rate, as it sets reads.

## 4. The left hand: slips, braces and the vanish

**What the inputs must do:**
- A **reaction** (the slip, the vanish) acts on the tick of the input that completes it, with no wait. A flick is never required to react, and a direction the left stick already holds counts (R34: the slip is LT's dodge with the left stick's direction at the tap's edge).
- A **prediction** (the brace) may be read on the flick's return, so a guard lean never sets one by accident.
- **A slip out of guard stays possible:** LB held plus LT's tap is a slip, never a vanish. The vanish needs a deliberate gesture of its own.

| Move | Cost | With the guard | With a perfect block |
| :--- | :--- | :--- | :--- |
| **Slip** (LT and a direction) | The dodge's cost, paid only when it affects an exchange. The third slip of one direction inside 3 s keeps its movement and loses its slip frames | Drops the guard for its ticks. The guard comes back if LB is still held | Separate. The perfect block is LB's own edge, and a slip opens no window |
| **Brace** (LB and a flick: R36's read, now on the left thumb) | 3 ki. It lasts until it fires or 90 ticks, one at a time, and reads only his attacks that start after it. The four reads and the look are R36 and R37, unchanged | It sits on top of the guard. A match plays the brace instead of the block. A miss leaves the block, so a wrong guess costs 3 ki and nothing else | On the same blow the perfect block wins (the bigger reward) and the brace stays set |
| **Vanish** (LB, LT and a direction) | **20 ki,** ×1.5 for each further vanish inside 3 s. A soft cost, never a cooldown | It replaces the guard for its blink | A perfect block already earned is never spent on it. Whatever the first shoulder started (the guard, the window, the dodge) stands until the vanish begins, and ki is never charged twice |

**The vanish, in full.**
- **The blink** is a short one (about 3 bh), invulnerable for about 8 ticks.
- **The directions:**
  - **away is the escape.** It lets the brawl go, as the zip away does, and the chaser may follow at the lunge's price. So it is a gamble (pillar 3);
  - **through** puts him at the rival's back. A blow in flight whiffs, which gives a plain opening (20 ticks) and **never a daze;**
  - **up and down** go over and under him;
  - **with the stick neutral, it goes away.**
- It counts as ESCAPE for a beam's outcome. It isn't available while stunned, launched or caught.
- **The look:** an instant cut with sharp after-images, the tech look. Never a fade or a dissolve (Orb, 2026-10-18). It goes through the look gate.
- **Yes, it replaces R3 Escape.** Three ways out remain, and they don't overlap:
  - the escape stance (sprint away) is slow and free;
  - the vanish is instant, priced, and can be followed;
  - the zip away is dear and reliable, with a parting blow.
- R3 does nothing until a target swap has a use (henchmen).

## 5. Pillar 2 and the generator

**Pillar 2 survives, reworded.** Proposed for `pillars.md`, to apply on the EP's word: "Intent, not combos. The left hand chooses intent (guard, evade, brace: the old stances). The right hand chooses weight and direction. The director owns which blow lands, the string, the links and the staging. No input is a combo: a press is a blow, a flick is a blow, and there are no motion inputs."
- That last clause keeps the right stick's five patterns (§2) parked: **a stick strike is a flick or a hold, never a pattern.**
- The brace is the stance's modern form (R36), now where the stances always belonged, on the hand that survives.

**The face-button slots don't change in number.** One cell moves, and two stick cells are added:

| Held | X | Y | B | A | Right stick |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Nothing (martial) | light | medium | heavy, the launcher | grab | **new `martial.stick`:** four flick strikes. The hold uses B's charged-heavy pieces by direction |
| RB (energy) | bolts | blasts | heavy blast (**the beam leaves**) | context | **`energy.stick`:** the snap-beam and the charged beam (the beam's cell moves here) |
| RT (power) | special 1 | special 2 | the signature, then **special 4** | special 3 | the signature, aimed (its frame cell moves here) |
| LB (defensive) | checks | pushes | as today | as today | the mode's job |
| LT (manoeuvre) | travel | travel | as today | as today | the mode's job |

- **Authoring.** Four flick pieces a fighter (`martial.stick`, stand-ins first from the quick mediums by direction) and a fourth special a fighter, when Orb wants it.
- **What needs no generator cell:** the charged strike (heavy tier, mapped by direction), the brace and the slip (the director's existing slip and stagger pieces), and the vanish (a blink pose and VFX).
- **Variety rule:** a stick strike never repeats the piece the same direction's button blow just threw in the string.

## 6. What this retires from `right-stick-pitches.md` §13

- **The law stands (R28 to R33, R32b),** with a fifth kind of command: **a strike, a beat of its own.** It commits the buttons for the lockout, a press commits the stick, and the claw-bot gate runs every stick-to-button link.
- **R34 and R35 stand.**
- **R36 to R38 stand except their input:** LB and a right flick becomes LB and a left flick.
- **Retired:**
  - §13.4's movement rows with nothing held (lunge, steps, hop, drop, dash, orbit, wall run, skim). The wall run and the skim may go to LT's sprint if Controls finds room;
  - R31 (the step carries the blow);
  - the RB aim rows;
  - R10.
- The LB + RB lay's aim waits on Controls' map.

## 7. Owners and reads

| What | Owner |
| :--- | :--- |
| The maps, the gestures, the mirrors, the claw-bot gate on every new link | Controls |
| The flick's stun length from the lockout; the AI's use of flicks, braces, slips and the vanish; the snap-beam and the beam on the stick | Encounter |
| `martial.stick`, `energy.stick`, the signature's cell move, special 4 when wanted | Combat |
| Four flick pieces, a blink pose | Animation |
| The vanish's after-images | VFX |
| A playable prototype of the split (§1) beside pure 4a | Research |
| The legend and the how-to-play: teach the stick's beam early, because a player who never uses the stick only finds it on the D-pad | UI |

**QA reads it before any tune:**
- the masher (35 to 50%);
- L17 (the newcomer against medium 10 to 50%, against easy 50 to 95%);
- dazes a match, since an aimed charged heavy may break more guards;
- slips and vanishes a match;
- p10 on 200 matches.

**Nothing is tuned on paper beyond these first values.**
