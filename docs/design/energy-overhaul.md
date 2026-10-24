# Energy overhaul: the system spec

Owner: Game Design. **Status: the frame, 2026-10-23.** Every rule is numbered (E1, E2 and on) so Controls, Combat, Research, Narrative and Legal can build on it and cite it. It is paper only. Nothing is built, every number is a first value for data, and all of it sits behind one switch (`energy.v2`) until Orb has played it. Part 2 follows in this file: Orb's step-by-step pictures, the per-fighter templates, QA's bands, the data shape and what retires.

**Orb's ask** (`docs/ep/vision.md`, "Energy attacks overhaul", 2026-10-23), and where each part is answered:

| Orb asked for | Where |
| :--- | :--- |
| Energy split along light, medium, heavy and grab | §2 |
| Light rapid-fires small projectiles | §3 |
| Medium lobs bigger, explosive blasts | §4 |
| Heavy lets loose the most devastating techniques | §5 |
| An energy grab that each fighter does his own way (a net, a ring) | §6 |
| Combined with the defensive button, energy leaves mines or traps | §7 |
| A way to choose between a beam and single blasts | §5, E40 |
| Beams charged before they fire | §5 |
| The light's rapid fire carried over to beams and projectiles | §3, E50, E64, E92 |
| No more one beam shared by everyone | §5, §8 |
| Prototype animations, step by step | Part 2 (Research builds the GIFs) |

## 1. The rules over all of it

- **E1. Control first.** Every energy move is live. No move takes a player's hands for longer than its own hit-stop and reel. A charge can be dropped at any moment (E46). Nothing fires by itself while he still has a choice. The one exception is a loaded charge whose ki runs out (E47).
- **E2. One press, one attack.** Every press is one bolt, one lob, one blast, one pulse, one grab or one mine. A hold is one attack too: the stream follows the held flurry's rule (E23).
- **E3. No press is silent.** A press that can't do what it asks for shows it with a flicker in the hand and the "not ready" cue, and spends nothing.
- **E4. No long locked scenes.** No energy move has a pause or a camera of its own. Only the RT + B signature keeps its pause, at most 1 s and only on a clean hit, as ruled. The camera eases to frame what happens (Orb, 2026-10-22).
- **E5. Payoffs are subtle.** A payoff happens in the world and on the body: a crater, a scar, the parted sea, a sound, a rumble. There is no banner, no text and no number over the fight.
- **E6. Nothing on, over or between the fighters.** No aim line, no charge bar, no mine marker. A charge reads in the hand, and a mine reads in the world (E77). Legal's charge rule holds: a thin ring or an edge light at the hand, never over the whole body.
- **E7. Never out of range (pillar 3).** Bolts, lobs, the heavy blast and the energy grab seek him and arrive within 45 ticks from any range, as seeking shots do today (`agency-pass.md` 6a). A beam reaches at any range, as the beam does today. Mines and traps are the one thing that stays where it is put, because that is their job.
- **E8. Soft costs, no cooldowns.** Ki and freshness pay for everything. The one limit is the field limit on mines (E76), and it exists for reading and frame rate.
- **E9. Deterministic, and in data.** Shots, mines and beams are sim objects stepped on the fixed tick with the seeded RNG. Every number here is a first value for data.
- **E10. Fighters differ in shape, never in grammar.** A fighter's kit changes what each cell looks like, its reach, its timing inside a band and what it does to the world. The buttons, the gestures and the rules are the same for every fighter, so a player learns them once.

## 2. The grammar

- **E11. Stances.** RB held is the energy stance (mask 2), as today, held or toggled by Controls' setting. **LB + RB held is defensive energy (mask 3),** the reserved hybrid, switched on by this overhaul for mines and traps (§7). Switching is instant and free, and it cancels nothing (`melee-press-feel.md` §12).
- **E12. The buttons keep their weights:** X light, Y medium, B heavy, A grab, as in the brawl.
- **E13. Four gestures, read as the brawl reads them.** A tap. A mash, which is a press within 9 ticks of his last. A hold, which is the button still down at the end of its tap window. A release.
- **E14. The tap window is the wind-up, so a tap costs no extra time.** X has none: a bolt fires on the press. Y's window is its 12-tick wind-up, B's is 16 ticks and A's is 10. The hand starts to gather on the press. A button still down when the window ends becomes a hold.
- **E15. The grammar on one page:**

| | **X: light** | **Y: medium** | **B: heavy** | **A: grab** |
| :--- | :--- | :--- | :--- | :--- |
| **Tap** | A bolt, at once | A lob: an explosive blast on an arc | The heavy blast: his most devastating single shot | His energy grab, thrown |
| **Mash** | One bolt a press, at most one every 6 ticks | A barrage: one lob a press, at most one every 12 ticks | One heavy blast a press, at most one every 24 ticks | (In a catch, A is his payoff, E65) |
| **Hold** | The stream, which fires while held | Charges the lob through two levels | Charges the beam through three levels | Charges or aims his own grab |
| **Release** | Ends the stream | Throws the charged lob | Fires the beam at the level reached. Before level 1 it is the heavy blast | Throws the held grab |
| **Pressed while his beam is out** | | | A pulse (E50) | |
| **With LB held too** | A spark mine | A blast mine | His trap | His snare |

- **E16. In reach, the brawl's energy blows stand** (`brawl-second-pass.md` §5b): RB + X is the point-blank bolt, and RB + Y is the blast, the string's ender. Two things are new in reach:
  - RB + B tapped is the heavy blast against his body: a knock-back of 5 bh, an ender by 5b's run rule. Held, it charges as at range, and a beam fired in reach carries him along it (C5).
  - RB + A in reach is the energy grab with no flight: it catches at once.
- **E17. The stick.** Neutral always aims at him. While the stream is out, the stick sprays it. At a lob's release, it leads the landing (E33). While a beam is out, it sweeps the beam. While a lob or a beam charges, it moves him at half speed (E45).
- **E18. The AI can do all of it** (Encounter). Simple's layout, touch and keyboard are Controls'. On Simple the director may throw energy for the player, as it throws the pairs.

## 3. X: rapid fire

- **E20. A tap fires one bolt at once:** half a light's worth, 1 ki, trade power 1, 60 units a tick, seeking.
- **E21. Mashed, each press is a bolt,** at most one every 6 ticks, the brawl's flurry pace. A press faster than that flickers in the hand (E3) and fires nothing.
- **E22. The flurry.** A bolt within 12 ticks of his last is in his flurry. A flurry is one use for freshness (E101). Its bolts trade one at a time, and bolts cancel in pairs, as today.
- **E23. Held, X is the stream: the brawl's held flurry, carried over.** It opens with a burst of 8 bolts in under a second, then settles to one every 8 ticks while X is held and his ki lasts. Each bolt is worth 85% of a mashed bolt (0.085 a tick of gap, the brawl's floor pace). The stick sprays it up to 15° either way.
- **E24. On a guard, a bolt is a shot,** as 5b rules: half its wear goes to the arms and the rest reaches the core. A bolt never interrupts a heavy's armour.
- **E25. Its job:** pressure and chip at any range, cheap, and the answer to his volleys. At range it never knocks back.
- **E26. Each fighter's own:** the bolt's shape (needles, sparks or shards), its colour, its spread, and its speed within 20% either way (Combat).

## 4. Y: the lob

- **E30. A tap** winds up for 12 ticks, read as a medium's, and then throws a blast on an arc that lands on him 36 ticks later from any range. It bursts over 1.5 bh. At the centre it is worth a medium (2.5 lights), and at the edge half that. A clean centre hit knocks him back 3 bh. 6 ki, trade power 3.
- **E31. Mashed, it is a barrage:** one lob a press, at most one every 12 ticks. A barrage is one use for freshness.
- **E32. Held past the wind-up, it charges.**
  - **Level 1** at 28 ticks: a 2 bh burst worth ×1.4, a knock-back of 4 bh, 9 ki, trade power 4.
  - **Level 2** at 48 ticks: his own charged form, which Combat picks per fighter. Templates: it splits into three on landing, it clings and goes off 20 ticks later, or it rolls along the ground. 12 ki, trade power 5.
  - Held past level 2, it is loaded (E47).
- **E33. The aim.** Released with the stick neutral, it lands on him. With the stick leaned toward or away from him, the landing moves up to 4 bh nearer or farther, to lead him or cut off a retreat. There is no marker: the arc and his throwing hand show it.
- **E34. Answers.** A guard takes it at the guard's rate, with no knock-back through the guard. A dodge tap in its last 8 ticks slips it. A shot that meets it in flight sets it off where they meet, by trade power.
- **E35. In reach, RB + Y stays 5b's blast,** the point-blank ender, with 5b's held rule.
- **E36. Each fighter's own:** the lob's shape, its arc (high and slow, or low and quick, within 6 ticks of 36) and its level-2 form (Combat).

## 5. B: the heavy, as a blast or a beam

- **E40. The choice: tap B for the blast, hold B for the beam.** Every press of B starts the same gather in his hand. Let go inside 16 ticks, or at any point before level 1, and he throws the heavy blast. Hold to level 1 and it is a beam. So the choice is made by how long he holds, with the same thumb, and he can change his mind until level 1 lights.
- **E41. The heavy blast.** After its 16-tick wind-up, read as a heavy's, it is one big seeking shot. It is worth a heavy, a clean hit knocks him back 5 bh, and it craters 2 bh. 10 ki. Trade power 4: it eats four bolts or one lob and goes on.
- **E42. The charge.** From 16 ticks the beam gathers through three levels, at 30, 54 and 84 ticks after the press (0.5, 0.9 and 1.4 s). Each level is a step brighter at the hand, with a click and a rumble tick.
- **E43. Release fires the beam at the level reached.**

| Level | Charged at | Length | Worth if all of it lands | Ki | Beam power |
| :--- | ---: | ---: | :--- | ---: | ---: |
| 1 | 30 ticks | 20 ticks | ×1.0 of a heavy | 12 | 6 |
| 2 | 54 ticks | 36 ticks | ×1.6 | 20 | 9 |
| 3 | 84 ticks | 54 ticks | ×2.4 | 32 | 12 |

- **E44. A clean beam hit.** Level 1 knocks him back 4 bh at its end, and level 2 6 bh. **Level 3 carries him along the beam and drops him at its end** (C5). That is a full send, with the journey's rules, for QA's L16 and for freshness.
- **E45. While he charges.**
  - He flies at half speed.
  - A medium or heavier blow that lands before level 1 ends the charge.
  - From level 1 he is armoured against lights: a light lands and does half, and he keeps charging.
  - A heavy, a grab or a launcher ends the charge at any level.
  - RB held means no guard (5b).
  - Knocked out of a charge, he pays nothing. The cost is the time he lost.
- **E46. Dropping it.** A dodge tap (LT) ends any charge at once, for nothing, and dodges.
- **E47. Loaded.** Held at level 3, a beam stays loaded for as long as he holds it, at 4 ki a second. A lob held at level 2 does the same at 2 ki a second. Either fires by itself when his ki runs out. A loaded beam is a threat he carries, and the rival can see his lit hand.
- **E48. While the beam is out,** he is rooted, and the stick sweeps the beam at his fighter's sweep rate. A dodge tap ends it early. The beam eats the shots it meets and loses their trade power from its own.
- **E49. The beam is his own** (§8). Its shape, width, sweep, end and how it fights in a struggle are Combat's per fighter, inside bands (Part 2).
- **E50. Pulses: the rapid fire carried into the beam.** While his beam is out, each press of B is a pulse. A surge, a bulge that travels to the front, runs down the beam. Each pulse adds 0.1 of a heavy to what lands, pushes in a struggle (§9) and makes the beam 6 ticks longer, for 2 ki. At most one pulse every 6 ticks counts, the flurry's pace. B held while his beam is out pulses by itself every 8 ticks, the held flurry's pace, at 85%.
- **E51. The RT + B signature is unchanged:** his defining art, held to its flashes, with its tiers, prices and pause. Where a fighter's signature is a beam, it is his beam's own top form, above level 3. RB + B's beam never takes a pause.

## 6. A: the energy grab, each fighter's own

- **E60. The frame every energy grab shares:** a throw, a catch, a way out and a payoff. The throw seeks him and arrives within 30 ticks from any range. The catch holds him for at most 40 ticks. Each fighter fills in the shape and the payoff (Combat), and Narrative names it.
- **E61. A tap throws it** after a 10-tick wind-up. Held past 10 ticks, it charges or aims his own variant, such as a wider net or a ring thrown ahead to lead him, and the release throws it.
- **E62. It beats a guard,** as every grab does. It loses to a dodge tap in its last 8 ticks, to any shot of trade power 2 or more that meets it in flight, and to a blow that lands on the thrower in his wind-up.
- **E63. The catch.** It takes hit-stop 5. He is held by it and keeps half his nudge, as in the clinch. He can't guard or fire.
- **E64. The way out is the rapid fire again.** Each press he makes in the catch takes 4 ticks off the hold, with at most one counted every 6 ticks. RT's burst breaks it at once after its first 12 ticks, as it breaks a pop.
- **E65. The payoff is the grabber's to choose in the catch.** A press of A is his fighter's payoff. A press of X, Y or B fires that shot into him while he is held. If he presses neither, the catch lets go at its end.
- **E66. The payoffs to pick from.** These are templates. Combat gives each fighter one, and more come as the roster grows.
  - **The yank:** it pulls him into reach and the brawl starts, the grabber's blow first.
  - **The bind:** he is held where he is, and the grabber's next shot lands as on an open fighter.
  - **The slam:** it drags him down into the ground under him, a down send in place under the spike's rules.
  - **The throw:** it flings him 6 bh along the stick, a knock-back.
- **E67. Limits as every grab's.** It shares the grab lockout (90 ticks), and a thrown fighter can't be grabbed for 120 ticks. 10 ki tapped, 14 held.
- **E68. In reach, RB + A catches at once,** with no throw: the hand closes the net, or the ring snaps on.
- **E69. Templates for the look, not names:**
  - a net: wide and slow, with a long catch;
  - a ring: narrow and fast, it pins his arms;
  - a lash: a line that yanks;
  - a cage of bars: it closes around him where he is.

  For Legal: the ring binds. It never cuts, as a thrown disc would.

## 7. LB + RB: mines and traps

- **E70. Defensive energy is LB + RB held (mask 3).** His guard stays up. Each face press lays one mine or trap nearby, of that button's weight, instead of firing.
- **E71. Laying.** It is laid at his hand, where he is. In the air it hangs, and on the ground it sets into the surface. The stick's lean flicks it up to 3 bh that way. Held past the lay, it goes farther, up to 6 bh, and is set on release.
- **E72. The price of a lay.** His guard drops for the lay's own frames: X 4 ticks, Y 8, B 12, A 8. A blow that lands in them lands as on an open fighter. The ki is 3, 6, 12 and 10.
- **E73. Arming.** A mine is dim and harmless until it arms: X after 12 ticks, Y 20, B 30, A 20. So a mine laid in reach can't go off on him in the same exchange.
- **E74. The trigger.** An armed mine goes off when the rival comes within its reach: X 1 bh, Y 2 bh, A 1.5 bh, and B across its line or zone. **It flares for 6 ticks first, and that is his window to answer it.** A send that carries either fighter through an armed mine sets it off on him at once, with no flare, and that includes the one who laid it.
- **E75. The four:**
  - **X, the spark mine.** Worth two bolts, with a 6-tick reel. Mashed, one a press, at most one every 6 ticks, which lays a string of them.
  - **Y, the blast mine.** A lob's level-1 burst, with a knock-back of 3 bh.
  - **B, his trap,** his own (Combat). Templates: a line across the air that fires his level-1 beam along itself when crossed, a pillar that erupts from the ground, or a field that drags a passing fighter down.
  - **A, his snare.** His energy grab laid as a trap. It catches as the grab does (E63 and E64). The payoff is the bind, unless the layer presses A while the catch holds.
- **E76. The field limit.** Each fighter has at most 4 live mines, 1 trap and 1 snare. Laying another of a kind sets off his oldest of that kind harmlessly: it fizzles. An armed mine fizzles after 12 s. This is a limit for reading and frame rate, not a cooldown: he can always lay.
- **E77. How they are seen.** In the world, in his colour, small. Dim while arming, a slow glow when armed, and a bright flare for its 6 ticks. A trap's line or zone shows faintly along its length. Nothing goes on the HUD, and both players see every mine (hidden information isn't modelled). A soft tick sounds as it arms, and a rising note in the flare.
- **E78. The answers:**
  - avoid it;
  - shoot it: a shot that touches it sets it off where it is. One bolt is enough for a spark mine, a lob or heavier for a blast mine or a trap, and any shot sets off a snare, which then catches nothing;
  - guard: a guard takes it at the guard's rate;
  - dodge: a dodge tap in the flare;
  - send the layer into it (E74).
- **E79. People.** A mine harms what is in its burst, structures by the tier factor, and the people it kills are on the layer's account. **The carer's mines hold while a person is inside their burst:** they glow and wait. The villain's don't. No mine ever moves toward people (Legal c08).

## 8. Each fighter's own energy

- **E80. Each fighter has his own kit** in data (Combat): bolt, lob and its level-2 form, heavy blast, beam, grab and its payoff, trap and snare. The grammar never changes (E10).
- **E81. The bands a kit keeps,** so no fighter breaks the rules: per cell, damage within 15% of the reference fighter's; timing within 4 ticks of each tap window and within 10% of each charge level; reach and speed within 20%. The ki table is the same for everyone.
- **E82. The launch pair comes first:** the Protagonist and the rival (roster ids PROTAGONIST and RIVAL). Combat fills theirs first, and the rest come as each fighter is authored.

## 9. Beam struggles, with every fighter's own beam

- **E90. Two beams that meet struggle,** whatever their levels. A signature beam that meets a beam struggles too. Only beams start one. A shot that meets a beam is eaten (E48). A heavy blast that meets a beam bursts on it and pushes its front back 1 bh.
- **E91. The start.** Each side's push is its beam's level (1, 2 or 3, and a signature counts 4), plus 0.5 for each power tier he has above the other.
- **E92. The push.** Every pulse pushes (E50: a press of B, at most one counted every 6 ticks). **A pulse on the struggle's beat is a surge, worth double.** The beat comes every 15 ticks, with a window of 2 ticks either side; it is felt in the rumble and heard in the hum. No press ever voids anything: a mash pushes, and timing pushes harder. This answers Combat's struggle-scoring proposal: a stray press no longer voids a hit.
- **E93. The front** moves by the difference. When it reaches a fighter, the winner's beam goes through at its level, with half the loser's added, and lands by E44.
- **E94. The clock is ki,** and there is a backstop.
  - Each pulse costs 2 ki. A side at 0 ki can't pulse, and its beam holds at its starting push.
  - **At 3 s (180 ticks), if neither has won, both beams burst at the front:** both fighters are thrown back 4 bh, with hit-stop 20 for both. That is the standoff, and no struggle runs longer.
- **E95. The way out.** A dodge tap ends his beam and slips the other by the dodge's rules: the beam's ESCAPE and DODGE outcomes, as today.
- **E96. The look.** Orb's rule (2026-10-22): the losing beam bulges and quivers as it buckles, and never thins. Each fighter's beam has its own look in a struggle: a wide beam pushes as a wall, a lance drills, a twin beam braids. Its trait moves the push by at most 10% either way.
- **E97. It is live.** There is no pause. The camera eases to frame both fighters and the front. Both players keep their thumbs and their dodge.

## 10. Ki, freshness and hit-stop

**E100. Ki,** as first values. Regen stays 5 a second while he is free (`economy.md`).

| What | Ki |
| :--- | :--- |
| A bolt | 1. The stream costs about 8 a second flat out |
| A lob: tapped, level 1, level 2 | 6, 9, 12 |
| A loaded lob | 2 a second |
| The heavy blast | 10 |
| A beam: level 1, 2, 3 | 12, 20, 32, paid on release |
| A pulse | 2 |
| A loaded beam | 4 a second |
| The energy grab: tapped, held | 10, 14 |
| A spark mine, a blast mine, a trap, a snare | 3, 6, 12, 10 |
| The RT + B signature | As ruled: 25, 45, 75 |

**E101. Freshness,** with launch anywhere's values (`rulings-2026-10-18b.md` §1b). Each use of a kind marks it ×0.9, every use marks the general term ×0.97, and the floor is ×0.7.
- A use is a flurry, a stream, a barrage, a lob, a heavy blast, a beam with its pulses, a grab, or a set of mines laid within 2 s of each other.
- A kind's mark fades after 6 s unused.
- Freshness scales damage and wear only. It never touches ki, trade power or knock-back distance.

**E102. Hit-stop.** At range, it holds only the body that was hit. The shooter is never frozen, so a stream or a beam keeps flowing. In reach, the brawl's rule holds: both freeze.

| What lands | Hit-stop (ticks) | Who it holds |
| :--- | ---: | :--- |
| A bolt at range | 0, with a 4-tick reel | |
| A bolt in reach | The brawl's light: 3 tapped, 2 after the first of a mash | Both |
| A lob: tapped, level 1, level 2 | 4, 6, 8 | The one hit |
| The heavy blast | 8 | The one hit, or both in reach |
| A beam's end on a clean hit: level 1, level 2 | 6, 10 | The one hit |
| A level-3 beam's carry | 14, the full send's | The one hit |
| A pulse | 0 | |
| An energy grab's catch | 5 | Both |
| A spark mine, a blast mine, a trap | 3, 5, 8 | The one caught |
| A struggle's end, or the standoff | 20 | Both |
| A KO | 24 | Both |

**E103. The freeze budget stands:** 18% of a match, and no 10 s block over 40% (`fight-feel.md`).

## 11. Collateral, tiers and biomes

- **E110. The tier rules apply to all of it.** Every energy hit on the world uses the tier factor on structures (`balance-targets.md` §15). The collateral budget caps deaths, with no borrowing at tiers 1 and 2, so a place over budget evacuates. Low tiers never break the planet.
- **E111. The marks, by power** (with `agency-pass.md`'s table):
  - a bolt leaves a scorch and a 0.5 bh pock;
  - a lob leaves 1.5 bh, 2 bh at level 1, and its own form's mark at level 2;
  - the heavy blast leaves 2 bh, with a column of flame;
  - a beam carves a trench along its path, 0.5, 1 or 1.5 bh deep by level, and the trench fills with water by the fill rules (`rulings-2026-10-23b.md` 14 to 17).
- **E112. A shot that misses carries on** and hits what is behind it (6a).
- **E113. Personality (pillar 5).** Near occupied buildings, the carer's beam narrows to 0.6 of its width and his lob's burst to 0.7, and the villain's widen to 1.3 (`rulings-2026-10-23b.md` item 9). The carer's mines hold near people (E79).
- **E114. Biomes (pillar 7).** The beam's biome aftermath is the signature variants: the parted sea, LANE SWEEP's graze, the forest's firestorm, the ridge bore, the glass trench and the plains' field scar. It belongs to every beam at level 2 and up: half size at level 2, full at level 3. Level 1 only scorches. So a beam plays differently by place, by level and, through its shape, by fighter: no beam plays the same way in two contexts.
- **E115. Lobs by biome:**
  - on water, a column and a ring wave (the crater wave's push of 1 bh);
  - in forest and grass, a fire line, with fire's light hazard wear;
  - on ice, a star of cracks;
  - in sand, a splash of glass;
  - in snow, a burst of powder, kept thin so it never hides a tell;
  - in a town, structure damage by tier.
- **E116. Mines by biome.** On water they sink and go off as a column. In sand and snow they sit just under the surface as a visible ripple. In a canopy they hang lit. They are never hidden.
- **E117. Legal throughout.** No score, bonus or unlock for deaths, and no schools, hospitals or places of worship as targets (c08). "Blast cloud" for the big ones, and no nuclear words (c07).

## 12. Who builds on it, and in what order

| Owner | What |
| :--- | :--- |
| Controls | The gestures and read windows (E13, E14), mask 3 switched on (E70), the hold or toggle setting, Simple, touch and keyboard. Constraints back to Game Design |
| Combat | Each fighter's kit inside §8's bands, the launch pair first: bolt and lob shapes, the level-2 lob form, beam shape and struggle trait, grab and payoff, trap and snare |
| Research | A playable prototype of the grammar, and GIFs of Part 2's clips |
| Narrative | Names for each fighter's techniques |
| Legal | A screen of the kits, the looks and names of the mines and traps, the grab looks and the charge looks |
| Encounter | The AI's use of energy and mines, the struggle's tuning, the reads |
| Simulation | Shots, mines and beams as sim objects; hit-stop that holds one body at range (E102) |
| Animation, VFX, Audio | The hand's charge steps, the pulse's bulge, the mines' glow and flare, the grab looks, the sounds and rumble ticks |
| World | Craters, trenches, fills and the biome aftermaths |
| UI | Nothing on the HUD, and the tutorial's lines |
| QA | Part 2's bands |

**The order.** First, in parallel: Controls' constraints, Combat's kits for the launch pair, and Research's prototype on this frame. Then Narrative and Legal on the kits. Then Encounter and Simulation build behind `energy.v2`. Then Orb plays it.
