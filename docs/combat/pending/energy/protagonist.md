# The Protagonist: his energy, step by step (parked)

Combat and Choreography, 2026-10-23, re-fitted to Game Design's frame (`docs/design/energy-overhaul.md`, E1 to E117). The frame owns the grammar, the numbers, the ki and the hit-stop (E10, E100, E102). This page sets only what E81 leaves to a fighter, inside its bands. Legal's conditions are fitted (`docs/legal/energy-overhaul-screen.md`, e10 to e13 and fx08): no ball in or above a hand, one hand loaded with the other open and away, and no flash for each shot. The data is `energy.protagonist.json`. **Nothing here is built.** The names are Narrative's provisional ones. Times are in ticks (60 a second). A bh is a body height.

**Who he is in energy. His identity is control** (Game Design's kit sheet, §14): his energy decides where the fight happens and how close it is. It serves his hands:
- the sparks keep a rival honest;
- the lob hops after a rival who backs off;
- the net hauls the rival into reach, so the brawl starts with the Protagonist's blow;
- the trap throws whoever trips it up and away from people.

Everything fires from the heel of an open palm that turns from edge to flat as it extends, the same turning palm as his strikes. His colour is Art's lane, cyan to azure (`data/art/energy-lanes.json`, bolt main #10c2ea): blue heat, cyan at the heel of the palm and deepening to azure as it runs. He grins when a shot lands on him. Warm, tactile and protective, never cruel.

## X, the light: Knuckle Flick (E20 to E26)
- **His own.** Sparks: short cyan streaks. Their spread is a tight 4 degrees, because he aims. Speed ×1.1 (66 a tick), damage ×1.0.
- **Tapped.** It fires on the press, so the hand is the only tell. One hand thrusts from the chest and turns flat, and its fingers flick open from the knuckles as the spark leaves the heel of the palm. Each press uses the other hand. Open hands, never a fist.
- **Mashed,** one spark a press, at most one every 6 ticks. **Held,** the stream: the frame's opening burst of 8, then one every 8 ticks. His shoulders turn with the stick's spray (up to 15 degrees), and the rest of his body stays still. While it streams, a steady low light sits at the heel of the palm instead of a flash for each spark, and its hits build one steady scorch glow.
- **Everything else is the frame's:** 1 ki a spark, trade power 1, a 4-tick reel at range, and a scorch with a 0.5 bh pock.

## Y, the medium: Pier Lob (E30 to E36)
- **His own.** A heavy cyan lump of heat with a dripping tail of sparks, thrown underhand off the heel of the palm on a high, slow arc of **40 ticks**. It forms as it leaves the hand, and nothing is ever held in it. Level 1 at 28 ticks, level 2 at 48, damage ×1.0.
- **Tapped.** Tell: in the 12-tick wind-up his rear knee drops almost to the ground and the palm sweeps down past the shin. The scoop rises with him, and the lob leaves at the top. The scoop shows the stick's lead (E33): a longer, higher sweep for farther, a short flick for nearer.
- **Mashed,** a barrage: alternating short scoops from the knees, one every 12 ticks.
- **Held** (a hold from 16 ticks, the wind-up plus 4 of grace, E14). He kneels with the throwing palm low and open at shin height, the other hand open a shoulder width away, and flies at half speed. Nothing sits on the palm: its heel brightens a step at each level and holds a steady light. Held at level 2, it stays loaded. It never throws by itself: when his ki can't pay, it steps down a level (E47).
- **Level 2, his form: it bounces.** It bursts where it lands (1.5 bh, worth a tapped lob, a 3 bh knock-back). Then it hops once toward the rival, up to 3 bh in 12 ticks, and bursts again at half. Both bursts mark the ground, and each counts as its own flash event (at most 3 in a second, fx08). 12 ki and trade power 5, as in the frame.
- **Answers** are E34's: guard, a dodge in the last 8 ticks, or a shot that meets it.

## B tapped, the heavy blast: Whole Palm (E40, E41)
- **His own: the look.** Every B press starts the same gather. His hips coil a half turn away, and the rear palm draws back open to chest height as its heel brightens. One hand only: the other stays open and away. No shout, and no ball. Let go inside 20 ticks (the 16-tick wind-up plus 4 of grace, E14), or before level 1, and the hips unwind. The rear palm drives through heel-first and turns flat at full reach. A pale cyan core in a long azure teardrop of flame flies out, seeks, and craters 2 bh with a column of flame.
- **In reach,** the same palm lands flat on the breastbone and the burst throws the rival 5 bh: an ender.
- **The numbers are E41's:** worth a heavy (×1.0), 10 ki, trade power 4, a 5 bh knock-back, hit-stop 8. Mashed, one every 24 ticks.

## B held, the beam: Breakwater (E42 to E50)
- **The charge.** From the gather he settles side-on in a long low stance. His lead arm is straight with the palm edge-forward, and his rear hand is held open and back, a shoulder width away. Each level (30, 54, 84 ticks) turns the lead palm further toward flat and steps up the steady light at its heel, with the frame's click and rumble tick. On release the palm turns fully flat and the beam opens from its heel. Held at level 3, it stays loaded. It never fires by itself: when his ki can't pay, it steps down a level (E47).
- **Shape:** broad and driving, **width ×1.2,** drawn and hit alike (§20 item 1). Cyan at the palm and azure toward the front, a step brighter at each level.
- **Sweep:** slow and heavy, 32 degrees a second.
- **End:** a flat, blunt front of pale cyan heat that shoves a wave of dust ahead of it and breaks into a fan of azure flame where it stops.
- **Pulses (E50).** Each B press shoves the lead palm forward a hand's length, and a pale cyan swell runs down to the front (under a 10% brightness step), which surges. Each adds +0.1 of a heavy and 4 ticks of length, for 2 ki, at most one every 6 ticks. While B is held, it pulses every 8 ticks at 85%.
- **Struggle trait: a wall.** His front flattens against the rival's beam like a palm against a door, and a surge shoves the whole front forward as a slab. When he is losing, the beam bulges and quivers near his palm and his feet plough back. It never thins. The push is ×1.0 (E96: the look only).
- **The rest is E43 and E44's:** lengths 20, 36 and 54 ticks; worth ×1.0, ×1.6 and ×2.4; 12, 20 and 32 ki. Level 3 carries the rival along the beam. These are the reference values, well inside §14's bands (damage within 15%, length within 25%).

## A, the grab: Harbour Net (E60 to E69)
- **His own:** a net, wide and slow with a long catch. The payoff is the yank. His held grab is a charge (E61).
- **Tapped.** Tell: in the 10-tick wind-up his open hand, gripping the tow line, draws back to the shoulder, never the hip (Legal e15). Then it snaps forward and opens. A net of braided cyan cords, 2 bh across, flies out, and the tow line pays out through his loosened grip. It is slow: it takes the full 30 ticks to arrive, from any range. 10 ki.
- **Held: the charge** (a hold from 14 ticks, the wind-up plus 4 of grace, E14). His gripping hand swings a loop of slack at his side. Its one level lights at 24 ticks as a steady brightness step at the heel of the palm. Released after that, it throws a 3 bh net that holds for the full 40 ticks, for 14 ki. Released before it, it throws the tapped net. It never throws by itself.
- **The catch** lasts 32 ticks from the tapped net and 40 from the charged one, with hit-stop 5. The mesh closes round the rival's arms and chest and glows brightest where it grips. The rival keeps half his nudge, and can't guard or fire. The net binds arms and torso only, never the throat, face or hair. He struggles against it and is never limp. There is no slow motion, zoom or taunt over him.
- **The payoff, the yank (A in the catch).** He hauls hand over hand, then makes one big haul past his ear, elbow first, and the rival is pulled into reach. The brawl starts with the Protagonist's blow. X, Y or B in the catch fires that shot into the held rival instead (E65).
- **The way out (E64).** Each press the rival makes takes 4 ticks off, with one counted every 6 ticks. RT's burst breaks the net after its first 12 ticks. A torn net whips back and burns out in sparks, and the slack cools to dull blue and crumbles.
- **Answers to the throw (E62).** A dodge tap in its last 8 ticks, a shot of trade power 2 or more in flight, or a blow on him in his wind-up. It beats a guard. **In reach,** his hand closes the net at once.

- **The call-out (Legal ln06):** one per grab, on the throw or in the first 10 ticks of the catch, inside the hit-stop and never extending it. Nothing is said over the rest of the catch, the payoff or a kneel.
- **The tow line is a thin cord** (Legal, Addendum 3), never a rope or a chain.

## LB + RB: the trap, the snare and the mines (E70 to E79)
- **B, his trap: Trip Pillar.**
  - **Laying it.** With his guard up, his rear palm presses flat down: 12 ticks with the guard dropped, 12 ki. A square of cracked ground 1 bh across sets into the surface, with a faint cyan seam in its cracks. It is a ground trap, so laid in the air it sets into the ground below him.
  - **Tripping it.** It arms in 30 ticks. When the rival comes within 1.5 bh it flares for 6 ticks: the seams brighten. Then **a solid slab of ground (or the lane's own stone) rises 3 bh over 8 ticks** with its top slanted away from people. It pitches whoever is over it **5 bh up and 4 bh away from people.** That is a knock-back, never a send (§20 item 2: at most 6 bh on either axis), worth 0.9 of a heavy (within §14's 15% of a level-1 beam), with hit-stop 8. The slab stands for a moment and then crumbles back into rubble.
  - **Legal's e14.** The pillar is solid stone, never a vertical beam of light, and it rises beside or under a body, never around one.
  - **Limits.** While a person is inside its 1.5 bh reach, it waits with its seams glowing (E79). He has one at a time, and it fizzles 12 s after it arms.
- **Answers (E78).** Go round it. Shoot it with a lob or heavier. Guard it at the guard's rate, which means no throw. Dodge in the flare. Or send him into it, and it throws him.
- **A, his snare:** the net laid, a loose hammock of glowing cord hanging in the air or lying flat on the ground. It catches as the grab does. The payoff is the bind, unless he presses A for the yank.
- **X and Y, everyone's spark and blast mines,** in his look: a pinch of hanging sparks like struck flint, and a lump of heat sitting in a scorched cup. Like all his mines, they fizzle after 12 s and never move toward people, and a string of spark mines flares one after another, never all at once.

## Collateral and his forms
- **Collateral is E113 and E79.** Near occupied buildings, Breakwater narrows to 0.6 of its width and Pier Lob's burst shrinks to 0.7. His mines and his pillar hold while a person is in their burst, and the pillar throws away from people by design. Each life his energy takes adds anguish as now, and his grin goes.
- **His forms (heat) change looks only.** The numbers stay inside E81's bands, and the tier rules carry the power. Each form runs hotter: the cyan climbs toward a pale, white-hot azure, and the light at the heel of his palm burns brighter. After a level-3 beam, steam vents from his forearms. In his final form, where his artefacts take the fight, there is no one to narrow for.

## Atoms (wind-up, active, recover)
- **Light:** a spark 0/4/6; the stream 0/4/4 a spark, looping.
- **Lob:** tapped 12/4/10; a barrage lob 8/4/0; the charge to 28 and 48; the release 0/4/10.
- **Heavy blast:** 16/4/14 at range and in reach.
- **Beam:** charge 30, 54 and 84; fire 20, 36 and 54 with recovery 10, 14 and 18; a pulse 0/6/0; the struggle.
- **Net:** the throw 10/30/12; the charge from tick 14, lit at 24; the catch 0/32/0 tapped and 0/40/0 charged; the yank 0/12/0; in reach 10/2/8.
- **LB + RB:** the pillar laid 4/4/4, its eruption 6/24/0; the snare 3/2/3; a spark mine 1/2/1; a blast mine 3/2/3.

The tells and poses are in the JSON.

## Open questions for Game Design
Settled by the amended frame: E96 makes a struggle look change looks only, so the wall's push is ×1.0; and E50 makes a pulse 4 ticks longer.

2. The lob's bounce goes toward the rival (confirmed by Combat).
3. Parked and cut, as they were not in the frame: bolts that wear a guard open ("the read"), and his beam capped at level 2 near people at high anguish. Wanted as templates?

**For Legal:** the names; the beam's palm turning from edge to flat with the rear hand open and back; the net cast by an open hand gripping the tow line (no "OK"-sign hand); and the underhand scoop from a kneel.
