# Energy overhaul: the system spec

Owner: Game Design. **Status: the full spec, 2026-10-23** (the frame, §1 to §12, then Part 2, §13 to §19, with the builders' constraints ruled in §19). Every rule is numbered (E1, E2 and on) so Controls, Combat, Research, Narrative and Legal can build on it and cite it. It is paper only. Nothing is built, every number is a first value for data, and all of it sits behind one switch (`energy.v2`) until Orb has played it. Part 2 holds Orb's step-by-step clips, the fighter kit sheet, QA's bands, the data shape and what retires.

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
| The light's rapid fire carried over to beams and projectiles | §3, E31, E50, E64, E75 |
| No more one beam shared by everyone | §5, §8 |
| Prototype animations, step by step | §13 (Research builds the GIFs) |

## 1. The rules over all of it

- **E1. Control first.** Every energy move is live. No move takes a player's hands for longer than its own hit-stop and reel. A charge can be dropped at any moment (E46). Nothing ever fires by itself, not even at full charge (E47).
- **E2. One press, one attack.** Every press is one bolt, one lob, one blast, one pulse, one grab or one mine. A hold is one attack too: the stream follows the held flurry's rule (E23).
- **E3. No press is silent.** A press that can't do what it asks for shows it with a flicker in the hand and the "not ready" cue, and spends nothing. That includes a press swallowed by a pace limit (6, 12 or 24 ticks): it gets a lapsed press-ack (Controls).
- **E4. No long locked scenes.** No energy move has a pause or a camera of its own. Only the RT + B signature keeps its pause, at most 1 s and only on a clean hit, as ruled. The camera eases to frame what happens (Orb, 2026-10-22).
- **E5. Payoffs are subtle.** A payoff happens in the world and on the body: a crater, a scar, the parted sea, a sound, a rumble. There is no banner, no text and no number over the fight.
- **E6. Nothing on, over or between the fighters.** No aim line, no charge bar, no mine marker. A charge reads in the hand, and a mine reads in the world (E77). UI may show a charge's stage ticks at the charger's own screen edge, the edge HUD being the last channel after the fight, sound and rumble (`minimal-hud.md`), and never on the fighters. Legal's charge rule holds: a thin ring or an edge light at the hand, never over the whole body.
- **E7. Never out of range (pillar 3).** Bolts, lobs, the heavy blast and the energy grab seek him and arrive within 45 ticks from any range, as seeking shots do today (`agency-pass.md` 6a). A beam reaches at any range, as the beam does today. Mines and traps are the one thing that stays where it is put, because that is their job.
- **E8. Soft costs, no cooldowns.** Ki and freshness pay for everything. The one new limit is the field limit on mines (E76), and it exists for reading and frame rate. The limits already ruled stand: the grab lockout and the struggle's 5 s.
- **E9. Deterministic, and in data.** Shots, mines and beams are sim objects stepped on the fixed tick with the seeded RNG. Every number here is a first value for data.
- **E10. Fighters differ in shape, never in grammar.** A fighter's kit changes what each cell looks like, its reach, its timing inside a band and what it does to the world. The buttons, the gestures and the rules are the same for every fighter, so a player learns them once.

## 2. The grammar

- **E11. Stances.** RB held is the energy stance (mask 2), as today, held or toggled by Controls' setting. **LB + RB held is defensive energy (mask 3),** the reserved hybrid, switched on by this overhaul for mines and traps (§7). Switching is instant and free, and it cancels nothing (`melee-press-feel.md` §12).
- **E12. The buttons keep their weights:** X light, Y medium, B heavy, A grab, as in the brawl.
- **E13. Four gestures, read as the brawl reads them.** A tap. A mash, which is a press within 9 ticks of his last. A hold, which is the button still down at the end of its tap window. A release.
- **E14. The tap window is the wind-up, so a tap costs no extra time.** X has none: a bolt fires on the press. Y's wind-up is 12 ticks, B's 16 and A's 10. The hand starts to gather on the press. **The hold is decided at the wind-up plus 4 ticks of grace, on live ticks, on every device** (Controls: shorter windows misread touch taps as holds). So a button still down at **16 ticks for Y, 20 for B and 14 for A** becomes a hold. These are the energy windows, which differ from the martial ones, so the wind-up read takes the press's mode (data `windupEnergyHeavy` 16, `windupEnergyGrab` 10). **One exception:** on Simple touch, Attack picks its weight by how long it is held, so a bolt goes out on the release, 3 to 12 ticks late. The hand gathers at touch-down to cover it.
- **E15. The grammar on one page:**

| | **X: light** | **Y: medium** | **B: heavy** | **A: grab** |
| :--- | :--- | :--- | :--- | :--- |
| **Tap** | A bolt, at once | A lob: an explosive blast on an arc | The heavy blast: his most devastating single shot | His energy grab, thrown |
| **Mash** | One bolt a press, at most one every 6 ticks | A barrage: one lob a press, at most one every 12 ticks | One heavy blast a press, at most one every 24 ticks | (In a catch, A is his payoff, E65) |
| **Hold** | The stream, which fires while held | Charges the lob through two levels | Charges the beam through three levels | Charges or aims his own grab |
| **Release** | Ends the stream | Throws the charged lob | Fires the beam at the level reached. Before level 1 it is the heavy blast | Throws the held grab |
| **Pressed while his beam is out** | | | A pulse (E50). In a struggle, the beat decides (E92) | |
| **With LB held too** | A spark mine | A blast mine | His trap | His snare |

- **E16. In reach, the brawl's energy blows stand** (`brawl-second-pass.md` §5b): RB + X is the point-blank bolt, and RB + Y is the blast, the string's ender. Two things are new in reach:
  - RB + B tapped is the heavy blast against his body: a knock-back of 5 bh, an ender by 5b's run rule. Held, it charges as at range, and a beam fired in reach carries him along it (C5).
  - RB + A in reach is the energy grab with no flight: it catches at once.
- **E17. The stick.** Neutral always aims at him. While the stream is out, the stick sprays it. At a lob's release, it leads the landing (E33). While a beam is out, it sweeps the beam. While a lob or a beam charges, it moves him at half speed (E45).
- **E18. The AI can do all of it** (Encounter). Simple's layout, touch and keyboard are Controls' (`docs/controls/energy-input.md`). On Simple the director picks energy at range and melee close, as today (`autoMode`), and may throw energy for the player, as it throws the pairs. **On Simple touch,** Attack's hold and swipe pick its weight, so rapid fire there is a mash of taps, and the stream and the charged lob are pad, keyboard and Full touch features. A swipe up held charges the beam. Power doesn't become an energy layer there (Controls withdrew it).

## 3. X: rapid fire

- **E20. A tap fires one bolt at once:** half a light's worth, 1 ki, trade power 1, 60 units a tick, seeking.
- **E21. Mashed, each press is a bolt,** at most one every 6 ticks, the brawl's flurry pace. A press faster than that flickers in the hand (E3) and fires nothing.
- **E22. The flurry.** A bolt within 12 ticks of his last is in his flurry. A flurry is one use for freshness (E101). Its bolts trade one at a time, and bolts cancel in pairs, as today.
- **E23. Held, X is the stream: the brawl's held flurry, carried over.** From 16 live ticks after the press (the brawl's burst start), it opens with a burst of 8 bolts in under a second, then settles to one every 8 ticks while X is held and his ki lasts. Each bolt is worth 85% of a mashed bolt (0.085 a tick of gap, the brawl's floor pace). The stick sprays it up to 15° either way.
- **E24. On a guard, a bolt is a shot,** as 5b rules: half its wear goes to the arms and the rest reaches the core. A bolt never interrupts a heavy's armour.
- **E25. Its job:** pressure and chip at any range, cheap, and the answer to his volleys. At range it never knocks back.
- **E26. Each fighter's own:** the bolt's shape (needles, sparks or shards), its colour, its spread, and its speed within 20% either way (Combat).

## 4. Y: the lob

- **E30. A tap** winds up for 12 ticks, read as a medium's, and then throws a blast on an arc that lands on him 36 ticks later from any range. It bursts over 1.5 bh. At the centre it is worth a medium (2.5 lights), and at the edge half that. A clean centre hit knocks him back 3 bh. 6 ki, trade power 3.
- **E31. Mashed, it is a barrage:** one lob a press, at most one every 12 ticks. A barrage is one use for freshness.
- **E32. Held past its decision point (16 ticks), it charges.**
  - **Level 1** at 28 ticks: a 2 bh burst worth ×1.4, a knock-back of 4 bh, 9 ki, trade power 4.
  - **Level 2** at 48 ticks: his own charged form, which Combat picks per fighter. Templates: it splits into three on landing, it clings and goes off 20 ticks later, or it rolls along the ground. 12 ki, trade power 5.
  - Held past level 2, it is loaded (E47).
- **E33. The aim.** Released with the stick neutral, it lands on him. With the stick leaned toward or away from him, the landing moves up to 4 bh nearer or farther, to lead him or cut off a retreat. There is no marker: the arc and his throwing hand show it.
- **E34. Answers.** A guard takes it at the guard's rate, with no knock-back through the guard. A dodge tap in its last 8 ticks slips it. A shot that meets it in flight sets it off where they meet, by trade power.
- **E35. In reach, RB + Y stays 5b's blast,** the point-blank ender, with 5b's held rule.
- **E36. Each fighter's own:** the lob's shape, its arc (high and slow, or low and quick, within 6 ticks of 36) and its level-2 form (Combat).

## 5. B: the heavy, as a blast or a beam

- **E40. The choice: tap B for the blast, hold B for the beam.** Every press of B starts the same gather in his hand. Let go at any point before level 1, a tap or a short hold, and he throws the heavy blast: never a wasted charge. Hold to level 1 and it is a beam. So the choice is made by how long he holds, with the same thumb, and he can change his mind until level 1 lights.
- **E41. The heavy blast.** After its 16-tick wind-up, read as a heavy's, it is one big seeking shot. It is worth a heavy, a clean hit knocks him back 5 bh, and it craters 2 bh. 10 ki. Trade power 4: it eats four bolts or one lob and goes on.
- **E42. The charge.** From its decision point at 20 ticks, the beam gathers through three levels, at 30, 54 and 84 ticks after the press (0.5, 0.9 and 1.4 s). Each level is a step brighter at the hand, with a click and a rumble tick. **Each level is one event,** `charge_stage` with its number k, and the last is `charge_full`, so the hand, the sound, the rumble and any edge HUD all follow one cue. The lob's two levels and a held grab's one work the same way. Thresholds are data.
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
- **E46. Dropping it.** A dodge tap (LT) or a press of Guard (LB) ends any charge at once, for nothing. The dodge dodges. Guard comes up, and the press counts as a perfect-block attempt, as every fresh LB press does.
- **E46b. One charge at a time.** A press of another face button during a charge is ignored, with a lapsed press-ack (E3). A charge ends only by its release, a cancel (E46) or a blow that ends it (E45). No intent field is added.
- **E46c. Charges off and the latch.** With the latch on, a press starts a charge and the next press releases it, so a player who can't hold still reaches every level. With charges off, every press is a tap: B is the heavy blast and never a beam. That is the setting's purpose, and the latch is the route to beams for a player who can't hold. No "charge for me" assist is added.
- **E47. Loaded, and never fired by itself.** Held at level 3, a beam stays loaded for as long as he holds it, at 4 ki a second. A lob held at level 2 does the same at 2 ki a second. **When his ki can no longer pay for the level he holds, the charge steps down to the level he can pay,** and below level 1 it holds as the heavy blast. It fires only when he lets go (Controls: no auto-fire at full, which keeps the latch and one-hand play safe). A loaded beam is a threat he carries, and the rival can see his lit hand.
- **E48. While the beam is out,** he is rooted, and the stick sweeps the beam at his fighter's sweep rate. A dodge tap ends it early. The beam eats the shots it meets and loses their trade power from its own. **Caught in a beam, he keeps control:** he can guard it at the guard's rate or dodge out of its line, and it reels him only at its end (E44).
- **E49. The beam is his own** (§8). Its shape, width, sweep, end and how it fights in a struggle are Combat's per fighter, inside bands (Part 2).
- **E50. Pulses: the rapid fire carried into the beam.** While his beam is out, each press of B is a pulse: a swell, a bulge that travels to the front, runs down the beam. Each pulse adds 0.1 of a heavy to what lands and makes the beam 4 ticks longer, for 2 ki. At most one pulse every 6 ticks counts, the flurry's pace, so even a flat-out mash lets the beam run down: it can stretch a beam to about three times its length, never hold it out for ever. B held while his beam is out pulses by itself every 8 ticks, the held flurry's pace, at 85%. **In a struggle, pulses don't count: the struggle's beat decides (E92).**
- **E51. The RT + B signature is unchanged:** his defining art, held to its flashes, with its tiers, prices and pause. Where a fighter's signature is a beam, it is his beam's own top form, above level 3. RB + B's beam never takes a pause. **They are two moves, not one:** RB + B is his heavy technique, charged by levels, live and paid by level; RT + B is his signature, held to its flashes, with its tiers and prices. The one beam everyone shared retires. Until a fighter's signature is authored, RT + B fires his own beam's top form by the signature's rules.

## 6. A: the energy grab, each fighter's own

- **E60. The frame every energy grab shares:** a throw, a catch, a way out and a payoff. The throw seeks him and arrives within 30 ticks from any range. The catch holds him for at most 40 ticks. Each fighter fills in the shape and the payoff (Combat), and Narrative names it.
- **E61. A tap throws it** after a 10-tick wind-up. Held past its decision point (14 ticks), it does one of three things, written in his data, since the input only guarantees a tap, a hold and a release (Controls): **charge** (one level: a wider net, a longer catch), **aim** (the stick leads the throw, as a lob's landing), or **place** (laid where the stick points, up to 6 bh, as a snare he can spring). The release throws or sets it. The payoff in the catch is one beat, a press of A (E65).
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

- **E70. Defensive energy is LB + RB held (mask 3).** His guard stays up. Each face press lays one mine or trap nearby, of that button's weight. **Under mask 3 no shot is ever thrown:** every face press is a lay, so a press with guard and energy both held never drops the guard beyond the lay's own frames (E72). The input holds the guard throughout, and the sim drops it only for those frames. Mask 3 is switched on in data (`"hybrids": [3]`); every other pair stays newest-wins.
- **E70b. The lay on each device** (Controls, `docs/controls/energy-input.md` §5). On a pad, LB + RB + a face button. On a keyboard and on Full touch, toggled or latched energy plus Guard held, which is the documented one-hand lay; it also keeps a toggled player in energy while guarding. On Simple pad and Simple touch, which have no energy button, the lay is Guard (held, or the one-shot tap that arms it for one blow or 90 ticks) plus a face button while the director is in energy mode at range; Encounter reads it. Pressing LB into the hybrid is also a perfect-block attempt, as every fresh LB press is.
- **E70c. Why the chord and not a trap left by a riposte.** Orb's words are "using defensive blocks *while* hitting energy attacks would leave energy mines or traps *nearby*", and "these should *all* be combinable with the defensive button". The chord is that, literally: chosen, at will, beside him, for all four weights. A trap left only after a perfect block, where the blast lands, would be rare, far from him and not his choice. Controls says the chord is one data line, and it reaches every device by E70b. The cost is Encounter's: a director branch for a lay with the guard kept, built on today's `DirBlast.layMine`.
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

**The beam struggle stays as Orb played and tuned it** (`rule-of-cool.md`, "The beam struggle, redesigned", 2026-10-16): a tug of war with a meeting point everyone can see, decided by the beat. This overhaul adds per-fighter beams and levels to it, and nothing else.

- **E90. Two beams that meet struggle,** whatever their levels. A signature beam that meets a beam struggles too. Only beams start one. A shot that meets a beam is eaten (E48). A heavy blast that meets a beam bursts on it and pushes its front back 1 bh.
- **E91. The level is part of the head start.** State is a head start and no more, at most 15% of the distance, as built. The beam's level counts with tier and ki inside that 15%: 2.5% toward the weaker side for each level between the two beams. A signature counts as level 4.
- **E92. Inside a struggle the struggle's input rule takes over.** A press of X, Y or B on the pulse is a surge. A press off the pulse, or a second press in its window, is a stray: it moves nothing and voids his next surge. **So pulses (E50) don't count in a struggle,** and mashing feeds nothing, as built. The pulse's bulge is what a surge looks like there. The rapid fire carries into the beam everywhere except the struggle, where timing decides, which is the rule Orb asked for when they played it ("hit the pulse to surge").
- **E93. How it ends, as built.** When the point reaches a fighter, he is overwhelmed: he takes the winner's beam and half of his own, and is launched along the beam's line. If time runs out with the point within 10% of the middle, the beams detonate. If time runs out with the point further over, the side it is on loses, with half the damage and no launch. The time limit is 15 pulses (5 s), as built.
- **E94. No ki in the struggle.** Nothing costs ki during a struggle, and ki never pushes the point, as built, because spent ki would put state back into the outcome.
- **E95. Letting go is A on the pulse,** as built: he slips aside and takes half the rival's beam with no launch. A off the pulse, he is caught letting go and overwhelmed.
- **E96. Each fighter's beam has its own struggle look,** and nothing more. A wide beam pushes as a wall, a lance drills, a twin beam braids. The trait changes how a surge and a buckle look, never the push. Orb's rule (2026-10-22): the losing beam bulges and quivers as it buckles, and never thins.
- **E97. It is live.** There is no pause and no marker. The camera eases to hold both fighters side-on and tightens as the point nears a side.

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

**E102. Hit-stop.** At range, it holds only the body that was hit: the screen and the clock keep running, so the shooter's stream, barrage or beam keeps flowing. **"In reach" is the brawl's engage distance,** with no number of its own. In reach, the brawl's rule holds: the whole sim freezes. How the one body is held is Simulation's call (`docs/architecture/hold-one.md` recommends shifting his motion stamps at release).

| What lands | Hit-stop (ticks) | Who it holds |
| :--- | ---: | :--- |
| A bolt at range | 0. Its 4-tick reel is a flinch he still moves and acts in, never a hold | |
| A bolt in reach | The brawl's light: 3 tapped, 2 after the first of a mash | Both |
| A lob: tapped, level 1, level 2 | 4, 6, 8 | The one hit |
| The heavy blast | 8 | The one hit, or both in reach |
| A beam's end on a clean hit: level 1, level 2 | 6, 10 | The one hit |
| A level-3 beam's carry | 14, the full send's | The one hit |
| A pulse | 0 | |
| An energy grab's catch | 5 | Both |
| A spark mine, a blast mine, a trap | 3, 5, 8 | The one caught |
| A struggle's end: an overwhelm or a detonation | 20 | Both |
| A KO | 24 | Both |

**E103. The freeze budget stands:** 18% of a match, and no 10 s block over 40% (`fight-feel.md`). **A one-body hold at range doesn't count toward it,** since the screen doesn't freeze. It has its own guard against pinning (E104).

**E104. No pinning.** After a one-body hold ends, he has **6 free ticks** in which hits still land and do their damage but don't hold him. And no body is held more than **24 of any 60 ticks**; past that, hits land with no hold. So mines, lobs and a stream together can hurt him but never pin him. A hold that lands on a held body merges by the longer, as Simulation has it. QA's row: no body held over 40% of any 60-tick window.

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

# Part 2

## 13. What Orb will see, step by step

Orb asked to see how this will look once it is built, "so I know we're on the same page." These ten clips are that picture, one feature each. Research builds them as GIFs from the prototype, and each step below is a frame range the GIF should show. Every clip keeps the rules over all of it: nothing on or over the fighters, no pause, and the camera eases.

**C1. Rapid fire (X).**
1. He holds RB. His hands take his colour at the edges, a thin light and nothing more.
2. One tap of X: one bolt leaves his palm at once and seeks the rival. It hits with a spark and a flinch, and the rival keeps flying.
3. He mashes X: a bolt for every press, as quick as his thumb, up to ten a second. Each one is a separate crack.
4. He holds X: a burst of eight in under a second, then a steady stream. The stick sprays it across the rival's path.
5. The rival fires back. Where their bolts meet, they cancel in pairs with small pops in the air.

**C2. The lob (Y).**
1. A tap of Y: his arm winds back, about a fifth of a second, and throws a heavier blast high on an arc.
2. It drops onto the rival and bursts. The ground under him takes a small crater.
3. He mashes Y: a barrage, one lob for each press, coming down where the rival is.
4. He holds Y: the hand gathers and steps up once, then twice. Released at level 2, his own form flies: for this fighter it splits into three as it lands.
5. Leaning the stick away from the rival as he throws: the lob lands behind the rival and cuts off his retreat.
6. The rival shoots the lob in flight, and it bursts in the air halfway.

**C3. Blast or beam (B).**
1. A tap of B: a short, heavy wind-up, and his most devastating single shot. A clean hit knocks the rival back 5 bh and leaves a 2 bh crater.
2. He holds B. The hand steps up in light three times, with a click and a rumble tick at each step. He can still fly at half speed.
3. Released at level 1: a short beam. It knocks the rival back.
4. Held to level 3 and released: a long beam. It catches the rival and carries him along it to its end, carving a trench below.
5. He holds B, then lets go before the first step: it is the blast, not a beam. Until the first step lights, he can still change his mind.
6. Mid-charge, he taps LT: the charge drops, he dodges, and he spends nothing.

**C4. Pulses: rapid fire in the beam.**
1. A level-2 beam is out. He mashes B.
2. With each press a swell runs down the beam to its front, and the front flares as it lands.
3. The beam lasts longer for the pulses, and it still runs down in the end.
4. Instead he holds B: the swells come at a steady beat by themselves.
5. The rival dodges out of the beam's line. Caught in a beam, he always could.

**C5. Loaded.**
1. He holds B to level 3 and keeps holding. His hand stays lit as he flies.
2. The rival sees the lit hand and keeps his distance, or guards, or dodges early.
3. The moment the rival commits to a lunge, he lets go. The beam meets the lunge.
4. Held too long, his ki runs out and the beam fires by itself. That is the price of carrying it.

**C6. A struggle between two different beams.**
1. Both fire level-2 beams, and they meet. One fighter's beam is wide like a wall, the other's a narrow lance.
2. The pulse is a beat in the music and the pad. Each player presses on it, and each surge bulges the meeting point toward the rival.
3. The beam that is losing bulges and quivers as it buckles. It never thins.
4. Close to his own hands, the loser's surges push harder: the comeback.
5. One side is overwhelmed and launched along the beam's line. In another take, the player who is losing presses A on the pulse, slips aside, and the winning beam carries on past him.

**C7. Two energy grabs.**
1. Fighter one taps A: a net seeks the rival, opens wide and wraps him. He hangs in it.
2. The caught rival mashes. Each press tears at the net and shortens the hold.
3. Fighter one presses A: his payoff, the bind. A bolt follows into the held rival, landing as on an open fighter.
4. Fighter two taps A: a ring flies fast and snaps shut around the rival's arms.
5. Fighter two presses A: his payoff, the yank. The rival is pulled into reach, and the brawl starts with fighter two's blow.

**C8. Guard and energy: mines and traps.**
1. He holds LB and RB. His guard is up.
2. He presses X, X, X, leaning the stick. Three small spark mines are laid in a short line nearby. His guard dips for a moment at each lay, and they arm dim, then glow.
3. A tap of Y lays a blast mine a little behind him. A tap of B lays his trap: for this fighter, a faint line across the air.
4. The rival flies in. A spark mine flares for a tenth of a second, and he dodges through the flare.
5. The rival shoots the blast mine from range, and it goes off harmlessly where it sits.
6. The rival crosses the trap's line. The line fires a level-1 beam along itself.
7. Later the rival sends the layer flying, straight through his own last armed mine, which goes off on him.

**C9. The mixed string, close and far.**
1. Punches, then RB + X: a point-blank bolt between two punches, with the hand lit just before it lands.
2. RB + Y: the point-blank blast as the ender. The rival slides 4 bh away, with the shot's colour trailing off his chest.
3. The same thumb keeps going: RB + X is now bolts after him as he slides.
4. A tap of Y lobs a blast where he will land.
5. A zip strike closes the gap, and the brawl starts again.

**C10. One level-3 beam in three places.**
1. Over the sea, the beam parts the water for 1.5 s, and the sea rushes back as a wave.
2. Down a village lane, the hero's beam narrows near the houses and grazes the lane, sparing most of the row. The villain's widens.
3. Through a forest, the trees catch along the line. Later, water from a nearby lake fills the trench and puts the fire out.

## 14. The fighter kit sheet, for Combat

Each fighter's energy is one sheet, filled inside E81's bands. **Orb asked for "some unique mechanic or variation" between most fighters, so a kit should differ from every other kit in what at least three of its cells do,** not only in how they look.

| Cell | What Combat picks | The band (E81) |
| :--- | :--- | :--- |
| **Identity** | One line: what his energy is about, such as control, force, precision or spread | |
| **Bolt (X)** | Shape, colour, spread, speed | Speed within 20% of 60 a tick. Damage within 15% |
| **Lob (Y)** | Shape, arc (high or low), and its level-2 form: a split, a cling, a roll, or his own | Arc within 6 ticks of 36. Level-2 damage within 15% |
| **Heavy blast (B tapped)** | Shape and burst | Damage within 15% of a heavy |
| **Beam (B held)** | Shape (straight, wide, lance, twin, split, sweeping), width, sweep rate, end, struggle look | Damage per level within 15% of the reference. Length within 25%. The struggle look changes no push (E96) |
| **Grab (A)** | Look (net, ring, lash, cage, his own), the held variant, and one payoff: yank, bind, slam or throw | Catch at most 40 ticks. Arrival within 30 ticks |
| **Trap (LB + RB + B)** | A line, a pillar, a field, or his own | Its hit within 15% of a level-1 beam |
| **Snare (LB + RB + A)** | His grab, laid | As his grab |
| **His colour and his hand** | Where it fires from: the heel of the palm, the fists | Legal's charge rule (E6) |

**Starting points for the launch pair** are suggestions only. Combat decides, and Narrative names them.
- **The Protagonist** (cyan to azure, from the heel of the palm). A kit about **control:** a straight beam that serves as the reference, a ring that pins and yanks him into reach, a trap that holds rather than hurts. That fits a carer who would rather fight up close than spray a town.
- **The rival** (violet to magenta, in fists, plates and straight lines). A kit about **force:** a wide beam that pushes as a wall, a lob that clings and goes off late, a net that slams him into the ground, a trap that erupts as a pillar.

## 15. QA's bands, first values

Every row is AI v AI with energy on and 1 to 3 in, unless it says otherwise. The rows that exist stay as they are: match length (median 360 to 480 s, 10th percentile at least 300 s), the masher's 35 to 50%, the freeze budget, and civilians lost inside today's band.

| Row | Band |
| :--- | :--- |
| Energy's share of match damage | 15 to 30% (as today) |
| Beams a match | 4 to 12. By level: level 1 30 to 60%, level 2 20 to 45%, level 3 10 to 30% |
| B at range, blast or beam | Each between 30 and 70% of B presses, so both are used |
| Struggles a match | 0.5 to 2, under the struggle's own rows in `rule-of-cool.md` |
| Lobs a match, and their share of energy damage | 6 to 30, and 15 to 40% |
| Energy grabs | 1 to 4 a match, catching 30 to 60% of throws |
| Mines | 2 to 12 laid a match by each fighter. 20 to 50% of armed mines go off. Mines do at most 8% of match damage |
| A send through a mine | At least 1 in 10 matches (rule of cool) |
| The energy turtle: a script that only fires from range | Wins at most 50% against medium |
| The mine turtle: a script that only guards and lays | Wins at most 30% against medium |
| The shooter frozen at range | 0 ticks (E102) |
| A body held at range (E104) | Never over 40% of any 60-tick window |
| A fighter at 0 ki for more than 10 s at a stretch | Under 10% of matches |
| Pillar 7 | Each biome's beam aftermath seen at least once in 20 matches. No beam of level 2 or more plays the same way in two biomes |

## 16. The data shape, proposed

The shapes are Simulation's and Combat's to settle, and Tools adds the schemas in `tools/schemas/` in the same commit. **All of it sits behind `energy.v2`, so with the switch off the golden match and the parity profiles are unchanged.**
- **Shared** (`data/fight/energy.json`): the tap windows, the paces, the charge levels and lengths, the ki table (E100), the hit-stop table (E102), freshness (E101), the field limit (E76), arming and flare times, and the trade powers, and the energy wind-ups (`windupEnergyHeavy` 16, `windupEnergyGrab` 10, Controls'). Mask 3 is `"hybrids": [3]` in `data/input/stances.json`.
- **Per fighter** (an `energy` block in his fighter data, keyed by roster id: PROTAGONIST, RIVAL, REFERENCE): the sheet in §14, as kinds and multipliers inside the bands, with his grab's hold shape (charge, aim or place, E61). A loader check rejects any value outside its band.

## 17. What retires, and what stays

| Today | With `energy.v2` |
| :--- | :--- |
| RB + X: bolts, and the volley of three | Bolts, the mash and the stream (E20 to E23) |
| RB + Y: the heavy shot, the charged shot (×0.6 to ×1.25 of a heavy) | The lob (E30 to E33). In reach, 5b's blast stays |
| RB + B: the one beam everyone shares, held and live | Tap for the heavy blast, hold for a beam in three levels, release to fire, pulses while it's out. Each fighter has his own |
| The short beam (held past a full charge, 20 ki) | Beam level 1 |
| RB + A: a mine at range (today's `DirBlast.layMine`), the shove in reach | The energy grab. Mines move to LB + RB, built on `layMine` |
| The arc, the burst, the shard spread | Kept only as a fighter's bolt or lob shapes, if Combat wants them |
| LB + RB reserved ("a ki shield or a zone") | Defensive energy: mines, the trap and the snare. A fighter's trap may be a zone |

**Unchanged:** the RT + B signature and its tiers, prices and pause; the beam struggle as built, with levels in the head start (§9); 5b's energy blows in reach; the grab lockout; and the brawl itself.

## 18. For Orb

**One question,** for the EP to ask when it suits: "To choose between a beam and a blast: tap B for a big single blast and hold B to charge a beam, with Y as the lobbed blasts (recommended)? Or should every button's hold be a beam of its own weight?" The second gives three beams a fighter and leaves light without its stream, which was Orb's rapid fire.

**Worth Orb knowing, no answer needed:**
- The one hard limit is the field limit on mines (E76): 4 mines, 1 trap and 1 snare a fighter at a time. It is there so the screen stays readable and the frame rate holds.
- A send through a fighter's own armed mine sets it off on him (E74). That is rule of cool, and the director's launch planner may aim for it.

## 19. Rulings on the builders' constraints (2026-10-23, late)

Controls (`docs/controls/energy-input.md`), Encounter and Simulation (`docs/architecture/hold-one.md`) answered the frame. Where a rule moved, it is amended in place above. This table is the record.

| # | Asked | Ruled | Rule |
| :--- | :--- | :--- | :--- |
| 1 | Which strengths charge | Y (2 levels) and B (3). X never: its hold is the stream. A's hold is one level, an aim or a placement, per fighter | E15, E32, E42, E61 |
| 2 | The hold's decision points | The wind-up plus 4 ticks of grace, on live ticks, on every device: Y 16, B 20, A 14. The wind-up read takes the press's mode | E14 |
| 3 | Beam or blast | By button and by hold. X and Y are blasts. B tapped, or let go before level 1, is the heavy blast, and held to level 1 it is the beam. No misfire window | E40 |
| 4 | A cancel | Wanted: a dodge tap or a Guard press drops any charge for nothing (Controls adds a `charge_cancel` read) | E46 |
| 5 | Auto-fire at full | None. A loaded charge steps down as his ki runs short, and fires only on release | E1, E47 |
| 6 | Charges off | Acceptable: every press is a tap. The latch is the route to beams for a player who can't hold. No assist | E46c |
| 7 | Charge cues | `charge_stage` (k) at each level, `charge_full` at the last | E42 |
| 8 | A press swallowed by a pace limit | A lapsed press-ack | E3 |
| 9 | Two charges at once | No: one charge at a time, and no new intent field | E46b |
| 10 | Mines: the chord, or a trap left by a riposte | **The chord:** mask 3 on, with Controls' form for each device, and no shot thrown under mask 3. The riposte trigger and the recent-guard fallback are declined, for the reasons in E70c | E70 to E70c |
| 11 | Today's mine on RB + A (`DirBlast.layMine`) | It moves to the lays, and RB + A becomes the energy grab | E70c, §17 |
| 12 | A with Guard alone (mask 1) | Unchanged: the reversal inside an exchange, the deflect outside. Only mask 3 makes A the snare | E75 |
| 13 | The signature and the heavy technique | Two moves. The shared beam retires | E51 |
| 14 | Power on Simple touch | No (Controls withdrew it). Simple touch's rapid fire is a mash of taps, and a swipe up held charges the beam | E18 |
| 15 | X on Simple touch | It fires on the release, 3 to 12 ticks late, and the gather at touch-down covers it. A separate Light button is Controls' later fix | E14 |
| 16 | When the stream starts | At 16 live ticks, the brawl's burst start | E23 |
| 17 | Each grab's input shape | A tap throws. The hold is charge, aim or place, in his data. The payoff is one beat | E61 |
| 18 | Rapid fire in beams | Pulses, one a press, as Controls proposed | E50 |
| 19 | A one-body hold and the freeze budget | It doesn't count | E103 |
| 20 | Pinning | 6 free ticks after a hold, and at most 24 held ticks in any 60 | E104 |
| 21 | The bolt's reel | A flinch he moves and acts in, never a hold | E102 |
| 22 | "In reach" | The brawl's engage distance | E102 |
| 23 | Stage ticks on the edge HUD | Allowed, at the charger's own screen edge, never on the fighters | E6 |
