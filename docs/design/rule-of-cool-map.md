# Rule of cool: the feature map for the global arena

Owner: Game Design. 2026-11-01. Orb's order: fold the global arena and the controller layout into a playable build, "as playable, responsive, and fun as possible", with "more features compatible with our "rule-of-cool" mapped out and built towards with regards to controller function and the procedural combo system."

This says what we build and in what order. `rule-of-cool.md` stays the rationed list and its limits: 3 planet-scale launches a match, one big set piece per 20 s, and Legal's stacking rule. **Every number is a first value, and nothing here has been played.** Costs are rough: **S** is one director's window, **M** is two or three directors with a park each, and **L** is a new system or a content batch.

## 1. Flight lines

Orb: "each fighter's unique way of exploiting the in-universe energy source could account for flight lines when flying at max speed", and "The glow should be enough to look cool when the camera dynamically zooms".

**A flight line is what the fighter's energy does to the air behind them at speed. It's view only:** it reads the sim and writes nothing, so it can't desync or change a fight. It's the same ribbon as the meteor trail (`docs/vfx/meteor-trail.md`), so one fighter's beam, clash and burn stay one identity.

### What it reads

| Reads | How | First value |
| :--- | :--- | :--- |
| **Speed** | The line starts near flat out, so ordinary movement leaves none, and it needs the stick held steady | From 80% of flat-out speed, full at flat out. A launched body follows VFX's burn, up to full |
| **Power** | Tier and form set its strength. **This is a separate term from VFX's `cool`,** whose product leaves a tier 4 flier at about 0.25, too faint for Orb's zoomed shot | Tier 1: none. Tier 2: today's speed streak only. Tier 3: 0.5. Tier 4: 0.8. Each form step taken adds 0.1, up to 1 |
| **Altitude** | Thick air gives a short, hot line; thin air gives a long, thin one. Below about 600 units the wake also touches the ground, as a water V, dust or bending treetops, all view only | Length ×0.7 at ground level, ×1.5 at 8,000 and up. Above the air it keeps the width floor, so it never disappears |
| **Fighter** | The table below: a row of data per fighter, so a new fighter is one row | |

**The read at a distance:** at a view 32,000 wide on a 720p screen, a tier 4 flier's line is a clear thread, and the four fighters can be told apart by shape alone. VFX's floors apply: a core of at least 3 px and a sheath of at least 10 px at 1,280 wide.

### The first four

The energy lore isn't picked yet (`docs/narrative/lore-core-options.md`), so these are written as behaviour that fits any of the options. Narrative words them when Orb picks.

| Fighter | How they use the energy | The line | When they turn | As it cools |
| :--- | :--- | :--- | :--- | :--- |
| **Grist** | Gives it away: the heat spreads into the air | **Broad and rolling,** widest of the four (×1.15), with rings travelling down it. Form steps add a braid | A round, generous curve | **It widens** and lingers as warm air |
| **Loupe** | Holds it shut: only a needle of pressure leaks | **A hard, thin needle** (×0.8) with straight filaments and little ember | **Sharp corners:** the line is drawn from fewer knots, within 1 body height of his true path | **It narrows,** colder, and lasts ×1.3 as long |
| **Empress Orza** | Commands it: it follows her as a train follows | **A long, taut arc** with a thin rim line, shedding almost nothing | The widest, smoothest curves | **It draws tight:** when she stops, it straightens toward her before it goes |
| **Bolus** | Burns what he's taken in, raw through his furnace | **Broken:** gaps fixed in the world, heavy sparks and a dull core with a hot rim. It never flickers in time | Ragged, with sparks thrown out on the corner | **Each Hunger step closes the gaps,** so the line shows how far along he is, and it gets thicker with each molt |

### What it never does

- **Changes nothing in the sim:** no change to speed, path, hitbox, damage, ki or collateral. It sets nothing alight and gives no slipstream.
- **Moves no fighter,** and bends no input: §13's rule on a held stick stands. Loupe's corners and Grist's curves are in how the line is drawn, not in where he flies.
- **Goes over nobody.** It's drawn behind every fighter, never in front of one, so it isn't a marker. It's dimmer than any beam's tell, so it never reads as an attack, and it can't be used to aim.
- **Tells nobody anything hidden.** It shows no swing's destination and no lab or landmark.
- **Reads no person or toll** (RL-213, RL-217). Bolus's line reads his Hunger steps, which take only fighters' output and objects (RL-220 ln08).
- **Dissolves or fades as a whole.** It ends by tapering from the tail and cooling in colour. No pulsing, and it passes the flash clips in both modes. Reduce flashing keeps a steady ribbon.
- **Costs a frame on the old laptop.** It's one ribbon, and the lower levels cut embers and texture first (Performance reads it).

**For Legal, through the EP:** VFX's row gives Orza a gold rim, and the aura rule says no gold, white or red. A trail streaming upward also needs checking against stacking mark 3. Change the rim's colour if the answer is no; the shape is what carries her.

## 2. The meteor launch: one complete curve

Orb on the prototype: "the arc doesn't fully complete, the knocked-back fighter reaches the apex then drifts, and then stops and goes straight down. I know this is a prototype, I just want to make sure our game physics are looking pleasing and follow "rule-of-cool"."

**The cause is my own §12 and the game's law.** §12's three phases put 5% of the carry in the descent, which is the stop Orb saw. Under them, `stepLaunched` bleeds sideways speed at 0.55 a second, so a 6,600 send at 60° spends 97% of its carry by the apex and comes in at 90° (Research). **So the meteor doesn't run on that law. It flies a closed form: a written curve, not physics.**

**The default, closed by the EP on 2026-11-01: this curve as Research flew it, with Research's parabola on a switch for Orb to compare (`docs/world/ring-any-angle/meteor-arc.md`, which has the formula). Its pace needs `tan` (sine over cosine, on our own trig), not only polynomials, and the height carries Research's ground term, `(gL − g0)·u`, so he lands exactly on the ground.** Research and I each withdrew in favour of the other's curve at the same moment, so ignore my earlier withdrawal. Orb's eye decides from here.

| | The default | First value |
| :--- | :--- | :--- |
| **The shape** | One formula with no phases: `w = u − 0.328·u·(1 − u)`, height `= g0 + (gL − g0)·u + 4·H·w·(1 − w)`, with `u` running 0 to 1 along the ground | Apex 58% along |
| **Launch and landing** | 60° up, 74° down. The landing is `1.551 × H` | **About 25,400 units, 60° round a Whole ring,** replacing §12's 31°. It just fits ruling 3d's sixth of the loop, and a Half ring scales to the same angle |
| **The pace** | `du/dt = k·(1 + e²)`: slowest at the apex, quickest at both ends. Written out, that's the tangent in Research's paper | 6.2 s, with the apex at 3.6 s |
| **As drawn** | **It never stops.** About 13,600 u/s leaving, 21,700 arriving | **The crest reads about 5,800 u/s on screen,** not my paper's 3,200, because he's far out from the planet there. So the hang is a sweep rather than a float, and **Orb should judge that first.** Slowing the crest is one number |
| **The sim** | Position comes from live ticks and constants, with no gravity to step and no forecast to run, and hit-stops don't advance it. `simulation.md` §10's longer forecast, launch-only ceiling and paced curve aren't needed | Rollback by reasoning only: Netcode's check should say |

### In frame or distance

**In frame is the rule, and this default keeps both:** measured on the prototype, the foe's in frame for all of the hang and 94% of the descent, and the landing is visible on the far limb. My horizon risk is answered, so the 65° fallback is gone.

| The switch | Lands | What it gives | What it costs |
| :--- | :--- | :--- | :--- |
| **This curve (the default)** | **60° round** | A sixth of the planet in one blow, and a big arc that keeps turning. It passes the turn test at 1.8 | The impact is on the limb, so it reads less head-on. 7 lost ticks of descent. The hang's a sweep. Closing takes about 4.2 s flat out, about 1.7 s more of the fight's time. Far ground has to be ready, which Performance hasn't read |
| **The parabola** | 36° round | An impact more head-on, 120 of 120 descent ticks, and about 2.5 s to close | Only a tenth of the way round, so the fight often stays in the same region. It fails the turn test at 10 and the sideways test at 0.48: its turn bunches at the crest |

**The limits on anything Orb picks:** the foe's in frame for all of the hang and at least 90% of the descent, the impact's on screen, both fighters are in one picture at the crest, and the landing stays inside the sixth of the loop. **Past that is feature 22's job,** the planet crossing.

### What else is ruled

| | The ruling |
| :--- | :--- |
| **Buildings on the way** | He goes through them by tier 4's ladder and stays on the curve, up or down (`buildings.md` §6.1), so the towers he crosses pancake and the crater is beyond them |
| **Terrain on the way** | From the apex on, the first contact with terrain is the landing. Before the apex he stays above it |
| **Landings** | Up to three a side, at 85 to 100% of the range, by §11's score, never people (RL-213). One a side is fine in the first build. The stick picks the side |
| **The crater, wear and the brake** | §12 stands: capped at tier 4's largest × 1.5, one impact of wear, not a KO. A brake leaves on the curve's own heading, from the end of the hang. At least 60% land |
| **The crater's shape** | Round for the first playable. A leaning blast for a slanted arrival is World's and VFX's, next |

**The tests,** with Research's prototype reads:
- from launch to contact, sideways speed never falls below half its mean (0.79);
- the on-screen heading turns one way, and between 10% and 90% of the flight the fastest turn is at most twice the slowest (1.8);
- speed never jumps between ticks (largest step 441 u/s, at about 20,000);
- two runs give one hash, and a rollback across the flight re-runs clean (**not yet tested:** the prototype has no hash);
- the limits above;
- **Orb's eye, which decides it.**

### Ordinary high launches

**Yes, they should lose the same fault, by the closed form rather than less drag, behind a switch.** The fault is in every launch high enough to read: 5,000 at 45° still comes in at 89°, and that's what Orb meant by "our game physics".

- **Which:** upward launches on Camera's ladder, from the 2,500 row up, on this same formula (`D` 3,878 at tier 2, 7,755 at tier 3, 15,355 at tier 4's 9,900 row). A launch that's low, flat or short, and every knock-back, stays physics, since its fall is too short to read.
- **Why not less drag:** a change to one number moves the carry of every launch in the game, and so the planner's forecasts, §15's landings and every band. The closed form moves only the launches that have the fault, and it needs no forecast, so it may help the launch tick. That saving isn't measured.
- **The order:** the meteor and the 9,900 row in the first playable. **Rows 2 and 3 come next, behind their own switch,** because it's a feel change. It waits on a cost from Encounter and Simulation, and a QA read of match length, §15's sends into buildings and the civilian band.
- **What needs answering in that cost:** how a closed-form flight meets ground contact, bounces and a skim at low height, which physics handles today; and whether the planner's scores still hold with the new carries.

**The question I put to Orb on §12, a second flatter launch, is withdrawn.** The switch answers it. The planet crossing stays feature 22.

## 3. The map

Every row keeps §4's rules. "Sim" means it needs hashed state and the rollback gates; "view" means it only reads.

**The idea, from Combat's pitches:** the fighter's seed writes the sentence, and the place you're standing finishes it. The same presses in the same place give the same combo, so it can be learned, and a new place gives a new ending, so it stays a surprise you caused.

### Must: the first playable

Six, because each answers something a player will try in the first ten minutes on the new arena and pad.

| # | Feature | Pad action | What the choreographer does | The cool | Systems | Cost | Test |
| ---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | **Phrases, and the place finishes them** (Combat's 1 and 2) | X, Y or a stick direction, in short patterns. The same phrase, anywhere | The generator writes each fighter 8 to 12 phrases of 2 to 4 presses, fixed by seed. A press inside a phrase takes its next piece in place of the pool's draw, and one outside it falls back to the pool. The last blow reads about eight place classes once, and takes that class's ender from **existing pieces only.** Worth and timing don't change | A combo you can name and show a friend, which nobody wrote by hand, and the planet changes its last word | Combat's generator, Encounter, UI's training list. Sim, behind its own switch | M | Same presses and place, same pieces, over 1,000 seeded runs. Two fighters' lists overlap under 30% by piece. Eight classes give eight distinct enders. QA's worth band holds. Under 1 ms a string, with no new read at press time |
| 2 | **Walk him to the wall** (my string walk, §15's lever 1 and Combat's 3) | Lean the **left stick** toward a standing building during a string, then a knock-back or B | Each blow's carry leans him up to 1 bh onto the line to it, and prefers `links` that travel that way, reading the building once a string. The send then follows `buildings.md` §6.1's ladder, a plain send or a power send | "I walked him into that tower", with no learned input. Every brawl in town starts breaking the town, from tier 1 | Encounter, Combat, World. Sim | S to M | After 3 or more blows with the lean, at least 70% of Bs reach it. §15's rows: 4 to 8 sends and 2 to 5 wall slams a match. Worth identical. Match length and the civilian band hold |
| 3 | **The long strike** | Flat out (hold LT) toward the rival, then B or a right-stick flick | Stages the arrival at flying speed. The blow keeps the speed on arrival and the send is up to ×1.25. A whiff carries him about 1 s past | Flying has a payoff: leave, turn and come back like a thrown spear. The defender has seconds and a visible line to answer | Encounter, Combat, Camera. Sim | S to M | Never the best button: a scripted long-striker wins no more than the medium arm. A perfect block stops it, and the hard AI punishes a whiff at least 70% of the time. Flee time doesn't rise |
| 4 | **Flight lines** (§1) | Flat out and held steady, at tier 3 and up | Nothing: it's the fighter's own energy | Speed and power can be read from across the planet | VFX, Rendering, Performance. View | S to M | §1's reads. Hash identical with it on or off. Both flash modes, side-by-side, a still that tells all four apart |
| 5 | **The meteor launch, one curve** (§2), **with ignition** (Combat's 5) | Hold B to the flash and release it on a stunned or weak foe, with both at tier 4. The stick picks the side. **Or:** a level 3 stick strike upward, then B | Picks the landing, runs the curve and the shot, and leaves the launcher to chase or wait. At both tier 4 only, a level 3 upward stun banks charge: B's full mark drops to 24 ticks inside that stun | Orb's picture, and the whole power ladder's payoff. The stick's 54 bare ticks become the route to it | Encounter, Simulation, Camera, VFX, Research. Sim | M | §2's tests. The ignition route lands in a scripted tier 4 run. About one match in two or three stands. **A training start with both at tier 4,** so players and QA can reach it |
| 6 | **The pad keeps the beat** | Nothing new: it reads the pad's rumble | Sends a cue on a clash pulse, a wall slam, a jolt, flat-out flight and the meteor's kick and landing, using the kinds Controls has built | You feel a pulse and a landing through the hands when the picture is far away | Controls, UI host. View | S | Never the only cue. An off switch and a strength setting. Hash identical. Reads right on a pad in the web build |

**The build order:** 2, 4, 3, 6, 1, and 5 last, because it depends on the most parks. The curve in row 5 can reach the prototype first, today.

### Next: straight after the first playable

| # | Feature | Pad action | What the choreographer does | The cool | Systems | Cost | Test |
| ---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 7 | **The apex spike** | Chase up the trail (hold LT or hold the press), then B as he slows at the top | Meets him at the hang, with the planet filling the frame, and sends him down the rest of the curve, landing earlier | The launcher gets to be in Orb's picture too | Encounter, Camera, Animation. Sim | M | One curve holds. Inside the 20 s rule. A KO can't come from it alone. Under half of meteors, since waiting has to stay a real choice |
| 8 | **Steer your fall** | The sent fighter's left stick, while coming down | Moves the landing inside its band, at most ±10%, re-solved without a kink | The victim has something to do for 6 s: into the sea or into the city | Encounter, Simulation. Sim | M | Curve tests hold. It never reaches past the band. Works beside the brake with no extra button |
| 9 | **Your hands** (Combat's 7) | Whatever you've been doing | `DirAlchemy`'s read of the last presses picks the next ender's accent: fast for a masher, a clean stop for a timer, a big wind-up for a holder | Two players on one fighter end up with fights that look like their own | Combat, Encounter. Sim | S | Three scripted players give three distinct ender histograms. Worth unchanged to the bit |
| 10 | **Power's dialect** (Combat's 6) | The same phrase at any tier | An ender has a row per tier band, so a known string speaks louder as power grows, with no world reaction below tier 3 | Pillar 4 at the size of one press | Combat, VFX, World. Sim | S to M | `balance-targets.md`'s dig limits hold. Worth follows the ladder only. Flash register passes |
| 11 | **The turntable throw** | A in a clinch, with the left stick | The spin of the throw is a swing: the world wheels round the thrower's feet and rests at the release | The world visibly turns with a throw, and the swing has its most physical cause | Encounter, Combat, Camera. Sim | M | The thrower's ground sweeps nothing. The rate law holds. Flash clips pass |
| 12 | **Back to the scene** (Combat's 9) | Any aimed send | A landing in a crater from earlier in this fight plays a bigger second beat, for the same worth. The planner adds a small score for the crater you made | The fight has a memory | World, Encounter. Sim | S | Fires only inside the radius. The score reads the store only. No collapse below tier 3 |
| 13 | **The world links** (Combat's 8) | Stick toward, with a tree, rock, pole or car behind him | The carry breaks the prop, and the next press inside 20 ticks costs no ki, once a string | A forest fights to a different rhythm from a desert | Encounter, World. Sim | S to M | String length rises under 20% in biomes with props, so a desert isn't a penalty. No `noTarget` kind is ever a prop |
| 14 | **New place looks** | The same phrases | New Animation pieces for row 1's enders: a skim over water, a spike in high air | Row 1 with its own art | Animation, Combat. Sim | M | Joint limits and RL-218's terms. Worth identical |
| 15 | **The relay** | B on the beat at each bounce of a rally | Each bounce swings the line and carries round the world, ending on a building | A rally becomes a tour of the planet | Encounter, Combat, Camera. Sim | M | Rally bands hold, the shared budget holds, and one big set piece per 20 s |
| 16 | **The strafing run** | LT + RB and a right-stick beam, flat out | Aims and carves along the line. No swing while the beam is out (§2 of `game-design.md`) | A trench drawn at flying speed | Encounter, World, VFX, Audio. Sim | M | Beam caps by tier hold. c09 and the civilian band hold. Flash clips pass |

### Later

| # | Feature | Pad action | Why later |
| ---: | :--- | :--- | :--- |
| 17 | **Up the face** (Combat's 4) | Into a wall with stick toward, then up, up, up, and down or B at the top | The moment people will clip, but it's large: a climb, a facade band, a pinned pose and framing, and §8's real walls first. First in line after the Next list |
| 18 | **The round-the-world hit** (feature 22) | A rally's ender or a finisher launch, at tier 4 | The planet crossing. It needs the Whole ring proved in play and a named exception to ruling 3d |
| 19 | **Through the mountain** (feature 18) | A launch aimed at a formation | Needs real formations and the tunnel in the shared world |
| 20 | **The lab run** (`game-design.md` §14) | Bolus's own command | Waits for Bolus to be built |
| 21 | **Clamp and carry, and each fighter's own stick verbs** (Combat's 10) | After a stick stun, hold the stick toward him, then aim and release or press B | Waits for the fighters. It's the pattern for fighter-only verbs, and Bolus's stays inside RL-220's forms |
| 22 | **Thrown vehicles and ships** (feature 17) | A in reach, then X, Y or B | Needs props on the new ground |

## 4. What every feature keeps

- **Determinism and rollback.** Seeded keys only, fixed step and live ticks. Anything sim is hashed and carried in the snapshot, with the switch off byte-identical until the EP lands it.
- **Zero claw advantage.** One thumb, one index finger per side: no feature asks for a face press and the right stick together, and none is faster on a claw. Controls' claw bot gates each one, and every stick command keeps its D-pad and key mirror at the same tick (R32).
- **Accessibility and remapping,** including left-handed. Simple mode reaches the first playable's six, or the director does it for them.
- **No marker over a fighter, no dissolve, fade or blur, no frame drops.** Anything on screen passes the look gate and both flash modes.
- **The launch tick is already 10 to 14 ms.** Nothing adds a read at press time without saying so, and a read that's needed is taken once a string and held.
- **Soft costs, not caps,** except `rule-of-cool.md`'s planet-scale budget.
- **Legal:** RL-213 to RL-220, and nothing new reads a person or the toll. RL-219's relief stays AI only and waits for QA's batch.
- **Worth doesn't come from generation.** A generated piece changes how a press looks, and what it's worth doesn't change (`docs/combat/moveset-generator.md`).

## 5. The pitches

### Combat's (`docs/combat/rule-of-cool-pitches.md`), ruled

| Pitch | Ruling | Where |
| :--- | :--- | :--- |
| 1 Phrases | **Yes, must.** It's built behind a switch, so Orb can answer pillar 2's question by playing it. `pillar-2-wordings.md` stays as it is until they pick | Row 1 |
| 2 The place finishes it | **Yes, must, with existing pieces only.** New looks are row 14 | Rows 1 and 14 |
| 3 Walk him to the tower | **Yes, must, merged with my string walk, and with two changes.** It's on the **left stick**, since a held right stick makes face presses inert (K3) and a string needs them. **Choosing the floor is out for now:** `interiorAim` is off, and it would be a player choosing the height of a strike on a building that may be occupied. It needn't wait for Legal | Row 2 |
| 4 Up the face | **Later, first in line.** I want it, but it's large and needs real walls | Row 17 |
| 5 Ignition | **Yes, must, with the meteor.** Combat's finding is right: a 40-tick stun can't fit a 44-tick charge | Row 5 |
| 6 Power's dialect | **Next** | Row 10 |
| 7 Your hands | **Next,** and cheap | Row 9 |
| 8 The world links | **Next.** It's the only pitch that pays out rather than only changing a look, so its test has to show a desert isn't a penalty | Row 13 |
| 9 Back to the scene | **Next** | Row 12 |
| 10 Clamp and carry | **Later,** with Bolus | Row 21 |

**Combat's three questions:**
1. **A broken-off phrase is free and starts over.** Yes. Each press is already a blow, so all he's lost is the ender. Rally freshness still applies, so a repeated phrase loses freshness as any blow does.
2. **The banked charge is the right fix,** at both tier 4 only, and from an upward level 3 stun only. Lengthening level 3's stun would change it at every tier, and saying the stick isn't a route would throw away the game's biggest bet.
3. **The line-up works the same for hero and rival,** because a player's stick is theirs (RL-219 (8)). The hero pays through his cost, as every send does. For the AI, care stays a flat weight, and the mark-down isn't touched by this.

**One line that changes for phrases:** `melee-press-feel.md` §8's "no two strings look alike" holds for everything outside a phrase. Inside one, repeating is the point, and freshness is what stops it being spammed.

### Controls' and Research's

`docs/controls/rule-of-cool-pitches.md` and `research/rule-of-cool/pitches.md` didn't exist when this was written. I'll rule on them here when they do, and a stronger idea can replace a row, but the must list stays at about six.

## 6. For Orb

Two questions, neither of which holds up the first playable:

1. **Same presses, same combo?** Once row 1 is in the build, try it with the switch on and off and say which you'd rather have. That settles pillar 2's wording (`pillar-2-wordings.md`), where #1 is my recommendation.
2. **Do the first four lines feel like those four fighters?** (§1.) Answer once there's a still to look at.
