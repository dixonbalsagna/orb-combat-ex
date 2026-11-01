# Rule of cool: ten controller pitches for right-hand 4a on the arena (Controls, 2026-11-01)

The EP's order of 2026-11-01 (Orb: "more features compatible with our rule-of-cool mapped out and built towards with regards to controller function and the procedural combo system"). Game Design rules on these; `docs/design/rule-of-cool-map.md` already holds Combat's and Research's pitches and says it will rule here (section 5, "Controls'"). Ten pitches, each a pad action a player can learn in a minute and show a friend.

**What every pitch keeps** (the map's section 4, restated for the pad): zero claw advantage (no pitch asks for a face press and the right stick together, and every stick gesture keeps its D-pad and key mirror and its strike button at the same tick); left-handed by the swap; a way to do it without the gesture (a button, an assist or a setting); rumble is never the only cue and has an off switch; determinism (a gesture is read into the intent, a feel is a view-side read of sim state or the intent, nothing hidden); no marker over a fighter, no dissolve or fade, both flash modes; and my own numbers, where I have any, are measured (`docs/controls/responsiveness.md`), not guessed. Costs are the map's: **S** one director's window, **M** two or three, **L** a new system. Every number is a first value; nothing here has been played.

## The ten, in the order I would build them

| # | Pitch | Pad action | Cost | Needs | Class |
| ---: | :--- | :--- | :--- | :--- | :--- |
| 1 | **Feel the ladder** | Hold a charge on the right stick | S | Controls, Audio | view and feel |
| 2 | **Snap or push** | A fast flick or a slow push of the stick | M | Controls, Encounter, GD | sim (one intent bit) |
| 3 | **Feel it coming** | Defending, with the pad in your hands | S | Controls, Audio | view and feel |
| 4 | **Trigger depth: slip or dodge** | LT half-pulled or fully pulled | S to M | Controls, Encounter, GD | sim (quantised) |
| 5 | **Catch the ground** | Guard, just before a long fall lands | M | Encounter, Combat, Camera | sim |
| 6 | **Crank the clash** | Turn the right stick in circles in a beam struggle | M | Encounter, GD, Controls | sim |
| 7 | **Sweep and cut** | Sweep the stick while an energy beam is out | M | Encounter, VFX, World | sim (reads `rsAim`) |
| 8 | **Lean the world** | Left stick held across the fight at a calm turn | S | Encounter, Simulation | sim (a sign) |
| 9 | **The phrase chime** | A phrase from the generator, finished | S | Combat, Audio, Controls | view and feel |
| 10 | **The lean** (a bluff) | Lean the stick short of a request | L | Controls, Simulation, Animation | sim (two bits) |

## 1. Feel the ladder

- **Pad action.** Push and hold the right stick: the charge ladder runs at 12, 30 and 50 live ticks (54 for a beam).
- **What happens.** The pad pulses once as each rung is reached, each firmer than the last and different from `charge_full`: a tick (high motor), a knock (both), a thud (low). A held full charge hums faintly until it is thrown or cancelled. The pulses are timed off the intent's `rsLevel`, which only rises while the stick is held.
- **Why it's cool.** You know a level 3 is ready with your eyes on him. The rungs have been invisible numbers; now the thumb feels them, which is also the best non-visual cue for a player who cannot track a small bar.
- **Cost.** Three haptic kinds in `timing.json` `haptics` (closed schema: a patch) and the mapper's cue from `rsLevel`; Audio matches a ring to each. Nothing in the sim.
- **Test.** A scripted charge: pulses on the ticks the level rises, none while the stick is at rest, none after a cancel. The hash is identical with the kinds on or off. Never the only cue: the charge pose and the HUD ring are unchanged.

## 2. Snap or push

- **Pad action.** The stick, by how it is moved. A **snap** is a flick that reaches full in 2 ticks or fewer; a **push** is anything slower.
- **What happens.** A snap's strike lands 3 ticks sooner (the wind-up is a shorter pose). A push's strike has about a quarter more reach and carries the foe further, and lands at the full wind-up. The same worth either way. The reader marks it in one bit of the second word (`rsSnap`): the ramp is measured on the pad's own samples, from the first tick past the dead zone to the crossing, and the strike button counts as a snap, so a player who cannot flick fast loses nothing.
- **Why it's cool.** Skill with a thumb has a visible, audible result (a crack against a shove) and a choice: the crisp hit that lands first, or the heavy one that reaches. It is the one pitch where the stick's own speed matters, which a button can never offer.
- **Cost.** One intent bit (pack2 has room), the reader's measure, two numbers in the director's `stick.json` for the shorter wind-up and the longer reach (Encounter, Game Design), Animation's two readings of the same crouch. The numbers come from responsiveness: the wind-up is 12 of a quick strike's 15 ticks at close range, so a snap of 9 is a visible change.
- **Test.** Over 1,000 seeded flicks of a synthetic thumb at ramps 1 to 8: the bit is set by the measured ramp only; the claw bot gains nothing (it is a stick-only property); the strike button lands exactly with a snap; the worth is identical; the left-handed swap carries the same bit. Real thumbs decide the ramp threshold: it stays data until the capture tool has numbers.

## 3. Feel it coming

- **Pad action.** None: a defender's pad answers an incoming stick strike.
- **What happens.** When a rival's strike starts and the director has a wind-up for it (the hook's `stick_start` cue), the defender's pad gets one directional cue: the high motor for a blow from above or toward, the low motor for below or away, a short tick. It begins at the rival's start tick and is over before the blow lands, so it is a warning, not a spoiler: the wind-up is already visible on screen. The cue names no hidden thing.
- **Why it's cool.** You feel the read before you see it: it makes the brace and the slip a reflex of the hand. It also gives a player with low vision or a split-screen glance something to react to.
- **Cost.** One haptic kind with the direction folded into the motor choice, the cue mapped to the defender; Encounter's `stick_start` cue already carries the direction and mask. Nothing in the sim.
- **Test.** A scripted rival strike: the defender's pad gets one cue within 1 tick of the start, in the motor the direction names; the striker gets none; two humans get one each; a rumble-off setting silences it. The hash is identical.

## 4. Trigger depth: slip or dodge

- **Pad action.** LT, pulled halfway or all the way. The analog trigger already feeds the layout.
- **What happens.** A half pull is a **slip**: a shorter, cheaper dodge with a smaller step and a shorter invulnerability, for a close read. A full pull is the dodge as it is. The depth is quantised to three bands in the layout (under 0.3 nothing, 0.3 to 0.8 slip, over 0.8 dodge) and read once, on the tick the trigger crosses 0.3, so a slow pull cannot turn into a full dodge halfway and a masher gains nothing. The pad rumbles a small detent at the band edge.
- **Why it's cool.** The trigger is a dial, and the left hand finally has a second dodge to choose without another button. It is the sort of control a controller does that a keyboard cannot, and the keyboard keeps a second key for the slip.
- **Cost.** A second dodge in the director (a size and a length: GD and Encounter), one more intent field or a reuse of `dodge` plus a depth bit, the detent haptic. Accessibility: a Remap row for a second control; with the trigger threshold setting it already has.
- **Test.** Pulls at 8 depths and 6 speeds produce one dodge each, of the right band; a pull that crosses the slip band and the dodge band in under 3 ticks reads as a dodge; the swapped layout (RT) is identical; escapes and catches stay in QA's bands.

## 5. Catch the ground

- **Pad action.** Guard (LB), pressed just before a long fall lands: the meteor's landing, or any carry of 1,500 units or more.
- **What happens.** The pad rumbles a rising crescendo through the last 20 ticks of the fall (a count-in felt in the hand). A guard pressed in the last 6 ticks turns the crater into a skid: the fighter takes less of the fall and the ground is dragged into a long trench instead of a pit. Pressed early or late, nothing changes.
- **Why it's cool.** The sent fighter has something to do in a fall that is all spectacle: land it well. The launcher gets a longer, wider scar to enjoy either way. Both players have a moment to win, which is the point of the meteor.
- **Cost.** Encounter (the window and the skid), Combat (the landing piece), Camera (a skid framing), the rumble kind. Row 8 of the map (`steer your fall`) has the same fall and the left stick; this is the button on the same moment, and the two can coexist.
- **Test.** A scripted meteor with a guard press at each tick of the last 30: only presses inside the window skid; the skid's damage is lower by the same fraction at every tier; the hash is identical in a replay; a window-widening assist exists (GD's).

## 6. Crank the clash

- **Pad action.** In a beam struggle, turn the right stick in circles instead of mashing a button.
- **What happens.** Each quarter-turn of the stick is one push of the point, at the same cap as a mash: clockwise or anticlockwise, any speed. Faster turning does not push harder than the mash cap, so a stick is no stronger than a button; the pad hums a spin, rising with the turn, and `struggle_push` rings on the surge. In a struggle the strike stick is otherwise inert (the layout already ignores it and frees the faces), so this reuses a quiet control.
- **Why it's cool.** The struggle is the game's strangest moment and its input is a mash. A turned stick is a physical crank: it reads as winding up power rather than hammering, it is easy on the thumb, and it is a real alternative for a player who cannot mash.
- **Cost.** A reader for stick angle in a struggle (quarter-turn counts, in the layout, a field of the second word), Encounter's struggle scoring takes it as a press (GD's cap), the rumble. The scoring is open already (`combat-struggle-scoring.md`: a stray press voids a hit), so Combat and GD rule on how a crank counts.
- **Test.** Synthetic circles at 1 to 4 turns a second push the point exactly as many presses at the mash cap; a stick held still pushes nothing; the swapped layout and the D-pad mirror (four directions in order) work; the claw bot gains nothing; no more than the mash's strength.

## 7. Sweep and cut

- **Pad action.** In the energy layer, charge a beam with the right stick, then sweep it round while it is out.
- **What happens.** The beam's aim follows the stick's sector (`rsAim`, 32 of them), clamped to a turn rate that makes a sweep take as long as it looks. A sweep over a building line cuts it floor by floor; a sweep over the ground draws a trench; both read as a stroke because the beam's tail stays lit. The pad rises in pitch with the sweep and drops on a clash.
- **Why it's cool.** The planet-scale destruction pillar in a thumb: you paint the horizon with a beam. A beam that can only fire straight is a button; a beam you draw is a weapon.
- **Cost.** Encounter (the sweep), World (the carve along a path), VFX, Audio, and the tier-height caps on beams (GD's `strafing run` row 16 is the flying version). `rsAim` is already in the intent and unread.
- **Test.** A scripted sweep: the beam's angle is the stick's sector within the clamp; a stick held still is the old straight beam; the carve is identical across two runs of one seed; the beam cap by tier holds; the swapped layout and the D-pad mirror (four fixed sectors) work.

## 8. Lean the world

- **Pad action.** At a calm turn (the arena swinging a few degrees to a new bearing), the left stick held across the fight axis, to either side.
- **What happens.** The swing asks the side the stick leans to: the world swings that way if both fighters agree or one is neutral, the way it would have gone otherwise if they disagree. Nothing else changes: no cost, no stun, no advantage, the same angle and the same time. Camera shows the turn as it always does.
- **Why it's cool.** The player gets a say in the arena's most dramatic camera move. It is a one-bit decision with a visible result: "I turned the world".
- **Cost.** The swing's request already takes a direction (Simulation's `SimSwing.ask`, a sign); the intent's left stick is read once at the turn's start. Encounter and Simulation own it. Tiny.
- **Test.** A scripted calm turn with the stick at each side and neutral: the sign is the lean's; two opposite leans give the default; the angle and duration are identical; the hash is identical with the lean off. Pure choice, so it passes QA's fairness rows as it is.

## 9. The phrase chime

- **Pad action.** Combat's phrases: the generator writes each fighter 8 to 12 phrases of 2 to 4 presses (X, Y or a stick direction) and the place finishes them (map rows 1 and 2).
- **What happens.** When a phrase is completed, the pad gives a fixed three-pulse flourish and Audio a short chime, once a string. A broken phrase gives nothing, never a penalty tone.
- **Why it's cool.** A combo nobody wrote by hand needs a way to say "that was one": this is the sound of finding a move. A friend watching hears it too, and it makes a learned phrase worth showing.
- **Cost.** One haptic kind and a cue from Combat's generator; Audio's chime. Nothing in the sim beyond the cue Combat already plans.
- **Test.** The cue fires exactly when the generator reports a phrase finished, never on a partial; the rumble-off setting silences the pulses but the chime stays; the hash is identical.

## 10. The lean (a bluff)

- **Pad action.** Push the right stick part of the way (past `preAt`, short of `on`) toward a direction, and hold it there.
- **What happens.** The fighter shows the beginning of the strike for as long as the lean is held: the crouch, the shoulder turned toward the aimed side. Pushing on starts the strike (the pose is already there, so it lands sooner); letting go returns to neutral with no cost. The opponent sees the lean as a tell, and has to guess whether it is a bluff. The AI reads it with the same delay a human does.
- **Why it's cool.** A bluff exists. Fighting games live on the feint, and the stick's rescaled range makes it natural: half-way is a threat.
- **Cost.** This is the large one. The quick read already publishes the pre-read for the **local** pose (`strike_pre`, built, render-only); for the opponent to see it in a netplay match it has to be in the hash: two bits in the second word (the lean's direction and depth band). That makes the lean a sim-visible state: Simulation, Animation (the pose), Netcode (the word), and Legal's read that the AI reacts to it. Not for the first playable.
- **Test.** A scripted lean: the two bits follow the stick's band with a 1-tick lag; a lean that rolls into a request starts the strike one tick sooner than without it, not more; the claw bot gains nothing (stick only); the hash and a rollback replay with the lean on are identical.

## Which to rule on first

If Game Design wants three for the first playable: **1, 3 and 9** are views over cues that already exist (no sim, no hash, small, and they sell power and the generator), **8** is a sign on a request that already exists. **2** is the one that makes the stick itself a skill, and it pairs with the responsiveness result (the wind-up is the biggest tick cost). **5** and **6** are the moments with the most feeling for the least new system. **4** gives the left hand a second dodge. **7** is the best picture and the most work. **10** waits.

Cross-checks with the map: 5 sits beside row 8 (`steer your fall`) on the same moment; 7 beside row 16 (`the strafing run`); 9 completes rows 1 and 2; 3 and 1 extend row 6 (`the press and the pad answer at once`) from the press to the thumb and the defender; 8 is a cheaper cousin of row 11 (`the turntable throw`). None replaces a Must row.
