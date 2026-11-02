# Rule of cool: the feature map for the global arena

Owner: Game Design. 2026-11-01. Orb's order: fold the global arena and the controller layout into a playable build, "as playable, responsive, and fun as possible", with "more features compatible with our "rule-of-cool" mapped out and built towards with regards to controller function and the procedural combo system."

This says what we build and in what order. `rule-of-cool.md` stays the rationed list and its limits: 3 planet-scale launches a match, one big set piece per 20 s, and Legal's stacking rule. **Every number is a first value, and nothing here has been played.** Costs are rough: **S** is one director's window, **M** is two or three directors with a park each, and **L** is a new system or a content batch.

## 1. Flight lines

Orb: "each fighter's unique way of exploiting the in-universe energy source could account for flight lines when flying at max speed", and "The glow should be enough to look cool when the camera dynamically zooms".

**A flight line is what the fighter's energy does to the air behind them at speed. It's view only:** it reads the sim and writes nothing, so it can't desync or change a fight. It's the same ribbon as the meteor trail (`docs/vfx/meteor-trail.md`), so one fighter's beam, clash and burn stay one identity.

### What it reads

| Reads | How | First value |
| :--- | :--- | :--- |
| **Speed** | The line starts near flat out, so ordinary movement leaves none, and it needs the stick held steady | From 80% of flat-out speed, full at flat out: that's the sim's own, so 10,320 u/s at tier 1 and 13,416 at tier 4, by VFX's reading. **Flat out only happens about 12,000 units or more from the rival, so there are no lines in melee or close flying. That's intended:** Orb asked for max speed, and it keeps a brawl clear. A launched body follows VFX's burn, up to full |
| **Power** | Tier and form set its strength. **This is a separate term from VFX's `cool`,** whose product leaves a tier 4 flier at about 0.25, too faint for Orb's zoomed shot | Tier 1: none. Tier 2: today's speed streak only, which stops where the line takes over at tier 3, so a fighter never shows both. Feature 11's streak on a launch or heavy is a different thing, and it stays. Tier 3: 0.5. Tier 4: 0.8. Each form step taken adds 0.1, up to 1 |
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

Eight, because each answers something a player will try in the first ten minutes on the new arena and pad.

| # | Feature | Pad action | What the choreographer does | The cool | Systems | Cost | Test |
| ---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 23 | **The kick and the coin turn** (Research's 2; likely, not final) | Flat-out flight (LT) from a standstill, or a stick flip at speed | Nothing: it's the fighter's own flight. Top speed in about 2 ticks, and a flip plants him for 3 ticks with a thump, then he's gone the other way. §5's rule limits the overspeed | He leaves on the press. The floaty lag is the first thing a player feels on the new pad | Simulation, Controls, Audio. Sim, two hashed fields, behind a switch | S | Standstill to 95% in at most 4 ticks, a full flip in at most 12. Escapes and catches inside their bands. A masher flipping the stick gains nothing |
| 1 | **Phrases, and the place finishes them** (Combat's 1 and 2) | X, Y or a stick direction, in short patterns. The same phrase, anywhere | The generator writes each fighter 8 to 12 phrases of 2 to 4 presses, fixed by seed. A press inside a phrase takes its next piece in place of the pool's draw, and one outside it falls back to the pool. The last blow reads about eight place classes once, and takes that class's ender from **existing pieces only.** Worth and timing don't change | A combo you can name and show a friend, which nobody wrote by hand, and the planet changes its last word | Combat's generator, Encounter, UI's training list. Sim, behind its own switch | M | A mash and a hold count as parts of a phrase if that's a small change (Orb, 2026-11-01). Same presses and place, same pieces, over 1,000 seeded runs. Two fighters' lists overlap under 30% by piece. Eight classes give eight distinct enders. QA's worth band holds. A finished phrase chimes once, and a broken one gives nothing (Controls' 9). Under 1 ms a string, with no new read at press time |
| 2 | **Walk him to the wall** (my string walk, §15's lever 1 and Combat's 3) | Lean the **left stick** toward a standing building during a string, then a knock-back or B | Each blow's carry leans him up to 1 bh onto the line to it, and prefers `links` that travel that way, reading the building once a string. The send then follows `buildings.md` §6.1's ladder, a plain send or a power send | "I walked him into that tower", with no learned input. Every brawl in town starts breaking the town, from tier 1 | Encounter, Combat, World. Sim | S to M | After 3 or more blows with the lean, at least 70% of Bs reach it. §15's rows: 4 to 8 sends and 2 to 5 wall slams a match. Worth identical. Match length and the civilian band hold |
| 4 | **Flight lines** (§1), **with water's A1** (§5) | Flat out and held steady, at tier 3 and up. Crossing water at any tier | Nothing: it's the fighter's own energy, and the sea answering | Speed and power can be read from across the planet, and every dive, skim and slam reads as water | VFX, Rendering, Performance. View | S to M | §1's reads. Hash identical with it on or off. Both flash modes, side-by-side, a still that tells all four apart |
| 5 | **The meteor launch, one curve** (§2), **with ignition** (Combat's 5) | Hold B to the flash and release it on a stunned or weak foe, with both at tier 4. The stick picks the side. **Or:** a level 3 stick strike upward, then B | Picks the landing, runs the curve and the shot, and leaves the launcher to chase or wait. At both tier 4 only, a level 3 upward stun banks charge: B's full mark drops to 24 ticks inside that stun | Orb's picture, and the whole power ladder's payoff. The stick's 54 bare ticks become the route to it | Encounter, Simulation, Camera, VFX, Research. Sim | M | §2's tests. The ignition route lands in a scripted tier 4 run. About one match in two or three stands. **A training start with both at tier 4,** so players and QA can reach it |
| 6 | **The press and the pad answer at once** (with Research's 3; likely, not final) | Any press, and the pad's rumble | The view answers a press on its own frame: the first frames of anticipation, a 1% eased push and the first sound, only on presses the sim's rules would accept. The pad cues a clash pulse, a wall slam, a jolt and the meteor's kick and landing, on the kinds Controls has built, plus each rung of a stick charge and, for the defender, a rival's strike starting (Controls' 1 and 3) | The game stops feeling as if it's waiting, and you feel a landing when the picture is far away. It also hides the stick's 2-tick settle | Animation, Camera, Audio, Controls, UI host. View | S | Press to first change is 1 frame plus the browser's delay, counted on a recording. A refused press settles with no misleading tell. Rumble is never the only cue and has an off switch. Hash identical |
| 42 | **A far press follows him** (the fun check, §5) | After you send him, tap X, Y or B | For about 2.5 s after a send or knock-back you threw, a far tap flies you after him rather than taunting, at the far band's existing price. Otherwise a far tap's still the taunt | The first thing anyone does after a launch is press again, and now it works | Encounter, Controls. Sim, small | S | A scripted masher closes on a sent rival. Flee and chase rows hold. Taunts still happen in neutral. Row 34's lob and bolts come first in RB |
| 40 | **Beams that travel, and the window to answer** (Orb; §5) | RB + stick fires. Answer with RB + stick, a dodge tap or a guard press before the front arrives | Runs the front by level, range and fighter, decides the hit on arrival, and starts a struggle where two fronts meet | A beam you can see coming, and a real choice with it. A struggle that begins with a collision | Encounter, VFX, Camera, Audio, Controls. Sim, small | M | Arrival times inside §5's table at any range. The dodge misses only near arrival. Fire-back starts where the fronts meet. Two runs, one hash. Flash clips. Struggle and dodge rates read |

**Now eight: row 40 joined on Orb's word, since beams are core to the stick, with its options as row 41, and row 42 from the fun check.** The kick came in, the press joined the pad's row, and the long strike moved to the top of Next. **The build order:** 23, 6, 2, 40, 4, 1, and 5 last, because it depends on the most parks. **Rows taken from Research's pitches are likely rather than final, since Orb is trying them with a pad.**

### Next: straight after the first playable

| # | Feature | Pad action | What the choreographer does | The cool | Systems | Cost | Test |
| ---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 34 | **The mixed string** (C9, §5; with Combat) | Punches, then RB + X, Y or B as he slides, and a zip strike back in: the same presses as ever | Keeps one string across any range, leads the far blows from the send's forecast, and lets what's in the way finish it | **What Orb wants most:** a combo that starts as a fist fight and ends across the map, different each place | Combat, Encounter, Camera, World. Sim | M to L | Over seeded random presses, close-to-far strings are common and rarely alike outside a phrase. No worth gain: QA's no-best-button band holds. He can answer the far half. No lock |
| 36 | **The Driver** (`energy-overhaul.md` §21, the replacement for B's hold) | RB + B held to a level, then released | One huge straight shot that moves him and kicks the shooter back. Level 3 is a full send from any range, with the planner choosing the landing | A punch thrown across the world, and a recoil you can use as movement | Encounter, Combat, Animation, VFX. Sim | M | Level 3 lands rarely on a reading opponent. QA's damage and match-length rows. The claw bot shows no gain with the stick inert. Legal's look |
| 35 | **Water, past A1** (C10, §5, World's ladder) | Nothing new | Nothing: the world answers. The parted sea and rush-back, then holes that fill and douse fires | Orb: "absolutely excited". Every big move has a wet version | World, Rendering, VFX, Simulation, Performance. View, plus a small hashed `surge` and the flood read | S to M per rung | No frame cost on the old laptop. Flash clips. Each piece on its own switch |
| 24 | **The low line** (Research's 1; likely, not final) | Flat out with the stick level | Pulls him down to skim what's under his line, with §5's tower rule, plus a wider lens and a look-ahead up to the look gate's limit | Far more rush for no extra speed, with towers whipping past | Simulation, Camera, Rendering. Sim, hashed | S to M | Never under the ground. Vertical speed under a limit. The stick wins on its tick. Hash and rollback gates. Orb's eye on the lens |
| 25 | **Fly into night** (Research's 4) | Keep flying | The sun is fixed to the planet, so 4 to 8 s of flat-out flight takes you to night, with windows coming on | No meter says "you crossed a planet" as plainly | Rendering, Art, VFX. View | S | The look gate with fighters at night. A swing's 60°/s across the sunset, read by the flash clips. Legal, §5 |
| 3 | **The long strike** | Flat out (hold LT) toward the rival, then B or a right-stick flick | Stages the arrival at flying speed. The blow keeps the speed on arrival and the send is up to ×1.25. A whiff carries him about 1 s past | Flying has a payoff: leave, turn and come back like a thrown spear. The defender has seconds and a visible line to answer | Encounter, Combat, Camera. Sim | S to M | Never the best button: a scripted long-striker wins no more than the medium arm. A perfect block stops it, and the hard AI punishes a whiff at least 70% of the time. Flee time doesn't rise |
| 26 | **Aim the send in the freeze** (Research's 8, on the left stick) | Left stick during the meteor's 16-tick freeze | Picks the landing nearest where it points, with the launcher's body and a small camera lean showing it. The director still scores them | You choose which city he lands on, at the peak | Encounter, Controls, Netcode. Sim | S to M | The claw bot shows no gain. The choice lands on most meteors. Never people (RL-213) |
| 27 | **The shock leaves during the freeze** (Research's 5) | Nothing new | A ring runs out through land and cloud during the hit-stop, from tier 3, at most two at once and zero near the fighters | Weight, with no pause added and no slow motion | Rendering, VFX. View | S to M | Never over a fighter. Flash clips, then Legal's reading. Feature 15's limits hold |
| 31 | **Sweep and cut** (Controls' 7, ruled as R25) | RB + right stick: charge a beam, then sweep it while it's out | Follows the stick's sector at a clamped turn rate, cutting a building line floor by floor or drawing a trench | You paint the horizon with a beam | Encounter, World, VFX, Audio. Sim | M | Beam caps by tier, c09 and the civilian band hold. Same carve on two runs. Flash clips pass. D-pad mirror works |
| 7 | **The apex spike** | Chase up the trail (hold LT or hold the press), then B as he slows at the top | Meets him at the hang, with the planet filling the frame, and sends him down the rest of the curve, landing earlier | The launcher gets to be in Orb's picture too | Encounter, Camera, Animation. Sim | M | One curve holds. Inside the 20 s rule. A KO can't come from it alone. Under half of meteors, since waiting has to stay a real choice |
| 8 | **Steer your fall** | The sent fighter's left stick, while coming down | Moves the landing inside its band, at most ±10%, re-solved without a kink | The victim has something to do for 6 s: into the sea or into the city | Encounter, Simulation. Sim | M | Curve tests hold. It never reaches past the band. Works beside the brake with no extra button |
| 30 | **Catch the ground** (Controls' 5) | Guard in the last 6 ticks of a meteor's or high launch's fall | Turns the crater into a skid: less of the fall's damage, and a long trench | The sent fighter has a moment to win, and the launcher gets a longer scar | Encounter, Combat, Camera, Controls. Sim | M | Only presses inside the window skid. A cue that isn't rumble. An assist that widens the window. At least 60% of meteors still crater, or the window shrinks |
| 32 | **Lean the world** (Controls' 8) | Left stick held across the fight when a swing is asked for | A vote between sides that score about the same | "I turned the world" | Encounter, Simulation. Sim | S | It never starts a swing or takes one to nothing. Opposite leans go to the score. Hash and rollback gates |
| 41 | **Alert options** (Orb's "granular"; §5) | The options menu, per player and pad | Nothing: all view only, apart from the longer-window assist | You choose how much the game tells you | UI, Audio, VFX, Controls. View | S to M | Each family off leaves the hash identical. Presets work. Reduced flashing limits them. Captions read |
| 29 | **Snap or push** (Controls' 2) | A fast flick or a slow push | A snap lands at the 7, and a push takes 10 with about a quarter more reach. Worth is identical, and the strike button counts as a snap | Thumb skill you can hear: a crack against a shove | Controls, Encounter, Animation. Sim, one bit | M | Real thumbs first. The claw bot gains nothing. The button lands with a snap |
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
| 28 | **The cloud scar** (Research's 7) | Fly through the clouds | M for a nice touch, and the lower levels may have no clouds. It waits for the widest view to be settled |
| 33 | **The lean, a bluff** (Controls' 10) | Push the right stick short of a request and hold it | L: a real feint, with two more bits in the word, and the AI has to read it. It needs the pre-read to be seen online |
| 37 | **Mines on the open arena** (C8, E134 to E138) and **grabs** (C7) | LB + RB, A | Still in workshop, at Orb's word, on a big-ring prototype |
| 38 | **Stick pulses** (C4, E133) | Pump the stick while a beam is out | Orb: "workshop when the right stick system is fully implemented". The claw bot decides |
| 39 | **Learned combos for custom fighters** (`combo-builder.md`; Orb's idea, not a decision) | Two-part gestures such as Hold Y then Mash X | Waits for phrases (row 1) and for Orb's word on unlocking play in the campaign |

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
2. **The banked charge is the right fix,** at both tier 4 only, and from an upward level 3 stun only. **Encounter found the route doesn't work as built:** the level 3 carry ends the brawl, so B lunges, and lands about 62 ticks after the hit against a 40-tick stun. **So at both tier 4, the upward level 3 strike's carry is short enough to stay in reach and the brawl holds,** with no lunge. A bet of 54 bare ticks should pay when it's won, and landing it inside the stun takes all 40 ticks, so it's still hard. Lengthening level 3's stun would change it at every tier, and saying the stick isn't a route would throw away the game's biggest bet.
3. **The line-up works the same for hero and rival,** because a player's stick is theirs (RL-219 (8)). The hero pays through his cost, as every send does. For the AI, care stays a flat weight, and the mark-down isn't touched by this.

**One line that changes for phrases:** `melee-press-feel.md` §8's "no two strings look alike" holds for everything outside a phrase. Inside one, repeating is the point, and freshness is what stops it being spammed.

### Research's (`research/rule-of-cool/pitches.md`), ruled

**Likely, not final:** Orb is trying the first two with a pad, and their word replaces anything here.

| Pitch | Ruling | Where |
| :--- | :--- | :--- |
| 1 The low line | **Next, first in line, with the tower rule below.** It isn't a flight line, since it moves him | Row 24 |
| 2 The kick and the coin turn | **Yes, must, with the limit below.** Response is Orb's first word in this order | Row 23 |
| 3 The press answers in one frame | **Yes, must, folded into the pad's row,** since they touch the same places | Row 6 |
| 4 Fly into night | **Next, not must, though it can be in the build on a switch for Orb.** It's the one pitch here that can make a fight look worse, and nobody has seen fighters at night. **For Legal:** feature 12 says the sky never darkens. Night here follows where you are and never a fighter's power, so I think it's fine, but Legal should say | Row 25 |
| 5 The shock leaves during the freeze | **Next** | Row 27 |
| 6 A speedometer in your hands | **Folded into row 6, once the low line exists.** A light tick per building, sparing and chunky, and no constant purr | Row 6 |
| 7 The cloud scar | **Later** | Row 28 |
| 8 Aim the send in the freeze | **Next, moved to the left stick.** On the right stick it breaks the claw law: a thumb needs about 12 of the 16 ticks to travel from B, while a claw's thumb is already there. The left thumb is always in place, and §2 already gives it the side | Row 26 |

**The tower rule for the low line.**
- **He hops by default, for every fighter.** Over a place, the height reads roofs as well as ground, but only what's **on his line,** within about a body height of it. A tower beside the line stays beside it, so a street keeps him low with towers whipping past, and that's the picture to protect.
- **In a place, he looks further ahead:** up to about 0.4 s, not 0.14 s, since a climb over a tall roof at this speed needs the room. Clearance over a roof is 140 units, as over ground.
- **The low line itself never causes contact, and pays nothing:** no crash, no damage and no collateral from a hop. It reads structures only, with no care term and no people (RL-213).
- **A held stick wins.** If a player pushes down into a tower, that's his own flight, so §8 of `game-design.md` applies: at tiers 1 and 2 he stops at the face with no damage and slides up and over, and at tiers 3 and 4 he ploughs through on the plain-send ladder, losing speed, inside the chain caps. **So smashing through at speed is a choice he makes, and it's earned by power.** Flying into a wall by accident can't happen with the stick level.
- **When it's on:** flat out with the stick held level, and the rival out of reach, as §13's nudge. It pulls only up and down, and it never changes his heading.

**The kick in escapes and catches.** By arithmetic, at the sim's real flat out of about 12,900 u/s at tier 1 and 16,770 at tier 4 (my first sum used 6,100, a placeholder), the overspeed is worth about 1,650 units and the lost lag about 2,600 more at tier 1: **about 4,000 units, roughly 55 body heights, on today's start, and more at tier 4.** So the limit below matters more than I first thought. An escape is ruled a gamble (pillar 3), so that can't be free. Response isn't the problem, though; overspeed is. So:
- **Reaching top speed in about 2 ticks is free, always.** No ki and no cooldown, because this is the responsiveness Orb asked for.
- **The overspeed above 100% depends on where he's going.** Toward the rival, always: an attack closes. Away from a rival inside charge range, or out of a brawl, **none:** he leaves instantly, at top speed, and the chaser's own kick reaches him. Beyond charge range, both ways, since nobody's escaping anybody.
- **It softens with repeats:** the third kick inside 3 s has no overspeed, as the third slip of a direction loses its frames. No cooldown.
- **It doesn't stack** with the zip away or the vanish, which keep their own prices. For about 30 ticks after one, there's no overspeed away.
- **The coin turn has no invulnerability.** He can be hit in the plant, and that's its price.
- **QA's rows:** escapes and catches stay inside their bands, and flee time doesn't rise. **If it's still too good, cut the overspeed before touching the response.**

### The fun check (2026-11-01)

**On first pickup, your own follow-up doesn't work.** You land a launch and he's thousands of units away. You press X again, as everyone will, and your fighter taunts. In code and data, past 12.5 body heights a tap is a taunt and only a hold flies (`sim/director/bands.gd`, `bands.taunt`). That was fine on a small ring, where the far band was rare. On a globe, nearly every send lands in it, so the game's best moment is followed by a press that seems to do nothing. **From reading the code. I haven't played it or watched the reels,** so Orb's hands or a clip should confirm it. Row 42.

### Beams that travel, and the window to answer (Orb, 2026-11-01)

Orb: "beams should not be instant rays cast in a direction, they should appear to the player to have a velocity and project out from the fighter", with "some way to non-intrusively alert the player on the receiving end that there is a window to fire back their own beam attack or dodge", and "granular display options". **Rows 40 and 41. First values, and nobody has played any of it.**

**One correction to a note I was sent:** RL-218's "`fire_back` under 32" isn't about answering a beam. `bn.hold.fire_back` is the pose for firing **behind him,** and 32 is Legal's limit on how wide the arms are. It has no bearing here, though its pose conditions still stand.

#### 1. The front is real

**The hit is decided when the front arrives, not when it's fired.** Dodging and firing back are a real window, and it isn't only a look. The sim's most of the way there: `beamPlays` already reads what he did on the tick the beam reaches him, but at a fixed 20 ticks, and it's off. `FRONT_SEC` already gives a beam a time to full length.

**A beam's speed is really a time, because the camera frames both fighters.** A front crossing the frame in half a second looks the same at a 4,000-wide view or a 53,000-wide one, so what the eye reads is how long it takes, not units a second. So the rule sets a time. It's quick to reach a fixed floor and stops growing at a ceiling, so across a planet the front simply goes faster, and it still always arrives (pillar 3).

| | Snap | Level 1 | Level 2 | Level 3 | Signature |
| :--- | ---: | ---: | ---: | ---: | ---: |
| **Ticks from hand to him: at least, at most** | 6, 20 | 10, 30 | 14, 40 | 18, 50 | 24, 60 |
| **Speed between those** | 14,000 u/s | 12,000 | 10,000 | 8,000 | 8,000 |

Time is the floor plus distance over speed, up to the ceiling. So at about 4,000 to 5,000 units and beyond, it's at the ceiling.

- **The further away, the more time to answer, and the bigger the beam, the more time too.** Up close, an answer is a read rather than a reaction, as a blow is. At range it's a real reaction, which also gives a charged beam a soft cost.
- **Fighters differ within about 20%,** in keeping with their beams: Breakwater's wall is the slowest, Lance Sheaf the quickest, Hem Sweep a thin fast line, and Furnace Vent surges unevenly on the way, arriving on the same tick.
- **Damage and carving start with the front,** along the path it's passed. The stick can still sweep it, so **a dodge made too early gets followed.**
- **The look:** it comes out of the hand with weight and pushes forward, with no fade or dissolve. A front should cost the flash analyser less than today's frame-filling ray, but it needs reading. The swing still rests for a beam, and now it stays at rest until the beam's gone.

#### 2. The answer window

**It opens when the beam leaves his hand and closes when the front arrives.** The charge before that is a warning, not the window: a lit hand tells you to start thinking.

| Answer | How | What it gets you |
| :--- | :--- | :--- |
| **Fire back** | RB and the stick toward him, or the signature, any time in the window. **Inside the window a beam fires at level 1 at once, at level 1's ki,** even with nothing charged, or at whatever level you've already got. A Loaded beam (E129) is the perfect answer. The snap can't open a struggle | **A struggle that starts where the fronts meet.** That's the natural beat: they collide, hold for about 6 ticks, and the pulse starts. **Answering late means meeting close to your own hands,** which is a real penalty you can see, at most 30% from the middle, and the comeback's ×1.5 near your hands is already there. It replaces the old late penalty. E91's head start stands on top |
| **Dodge** | A dodge tap in the last 18 ticks before arrival, up to 2 after. **Re-ruled on Encounter's park:** 6 after would make the hit land visibly late, so the window keeps its length and moves earlier | **The whole beam misses, and he's still rooted** for its length, so it's your best opening of the match. He can cut it with LT, giving up the rest. There's no extra damage, and the opening is the prize |
| **Perfect block** | A fresh guard press in the last ticks before arrival, moved from the tell | Swat, split or walk through, as ruled (feature 16) |
| **Guard** | Held | Guard damage. It's always there, and wading stays |

- **The claw law:** the fire-back is RB and the stick, the same as any beam, and it's on the same mirror. The claw bot checks it.
- **Can't pay? No answer.** Ki still counts.
- **The AI answers through the same window,** with its reaction time. Under about 28 ticks it needs a read, drawn at the charge as today. **QA re-reads 30 to 60% struggles and the DODGE rates** (`rulings-2026-10-30e.md`), since both will move.

**The signature at point blank, re-ruled 2026-11-01 on Tools' read** (the AI fires 2 beams per 90 s, always from point blank; an answer at 18 ticks clashes, at 25 it's a plain hit). This replaces the signature's floor of 24 and "the charge is a warning, not the window" for the signature. Unplayed.

| | Ruling | First value |
| :--- | :--- | :--- |
| **The floor** | **Raise it. This is the number.** Distance can't supply the time: at 8,000 u/s, 12 more ticks is 1,600 units, about 24 bh, past the middle band | `front.rows.signature.floor` 24 to **36** (0.6 s), ceiling 60 stays. If a first-time player still misses it by reacting, 42 |
| **The lit hand counts** | A signature or fire-back pressed during the charge answers it, and fires the moment he fires. `DirBeam._answer` already reads this from the queue, so **Tools confirms it on the real path** at 30 and 10 ticks before the fire. If it doesn't hold, make it | So from the first sign, a player has 48 + 36 = 84 ticks, 1.4 s |
| **The stand-off: withdrawn on Orb's first play** (the shooter stays put; `power-scale.md`) | **The look, not the time.** With no gap, a 36-tick front crawls across about 1 bh and the fronts meet at their hands, which is no shot. Any signature fired from under the stand-off, by anyone: the shooter kicks back during the charge along with its rise, and stops at a wall. The target's free to chase, and hitting him in the charge is the old read | `standoffBh` 9, which makes the front about 1,000 u/s at the floor. Encounter's, through the look gate |

**Why 36.** 0.3 s is someone who knows what's coming. A first-time player has to notice, remember a chord and press it: about 0.5 to 0.6 s, a general figure and not a test of ours. **A person's first try settles it.** The dodge is unchanged, the last 18 ticks, so it opens at tick 18. The other beam levels keep their floors: they're for versus, where a read is fair, and the AI doesn't fire them.

**Can't pay? Still no answer,** so that press must say why: the refusal cue, with `ki`. **Tools adds a row:** of the AI's beams, how many came when the player could pay 45 ki. If it's under half, the shot's held back by ki and not by the window, and that comes back here.

**The AI's beam rate, ruled 2026-11-01.** Raise it a little, and time it better. All of it applies to an AI fighting a human only, so AI-against-AI batches and the golden don't move. Unplayed, and first values.

| | Ruling | First value |
| :--- | :--- | :--- |
| **The rate** | `sigPick` is a flat chance at each new choice, so the first beam is down to luck: about 7% of fights go 2 minutes with none, if it's as random as it looks | **`sigPick` 0.025 to 0.04,** aiming for 3 per 90 s, band 2 to 4 |
| **The first beam** | Orb should meet it early and be ready. The AI's first signature comes when the human can pay | **Between 25 and 45 s,** seeded. If the human can't pay at 45 s, it waits for them, up to 60 s |
| **Lean toward a clash** | The AI fires more when an answer's possible, and less when it would only be a plain hit. It's the game's shot, so the AI goes looking for it | **`sigPick` ×1.5 with the human on 45 ki or more, ×0.5 under it** |
| **Not its only plan** | A gap between its beams, so they can't bunch. The player's own 15 s cooldown doesn't change | **At least 25 s between the AI's signatures** |

**Rows, QA or Tools, with a scripted pad:** first beam by 60 s in every match; 2 to 4 per 90 s; time in a brawl at least 50% (62 to 66% today); signatures at most 30% of damage, as already ruled; struggles at 30 to 60%.

**If "could pay" comes back low, in order.** Read it with the lean on, and count the cooldown too, since `DirBeam._answer` also refuses a signature inside its own 15 s.
1. **The cooldown is the wall:** an answer inside the window ignores the cooldown. It's a reply, not a fresh signature, and a player who's just fired shouldn't be locked out of the shot.
2. **Ki is the wall, under half:** an answer inside the window costs 30, not 45 or 40, whichever press makes it. The shooter still pays 45. It's for versus too, so QA reads struggles again.
3. **Not:** free ki, a beam that waits indefinitely, or an AI that holds back its other blows to leave you ki.

**The meteor's real route, ruled 2026-11-01 on Encounter's read** (`docs/director/pending/meteor-route/`: level 3 flicks landed 0 in 792 tries against the AI, B alone makes the high arc and spends the budget). This amends `game-design.md` §12's "What earns it". Unplayed, and first values. Orb's words: "a fully charged launch attack landing on a stunned or weakened foe".

| | Ruling | First value |
| :--- | :--- | :--- |
| **"Weakened" is the main route** | **Yes: a full B on a worn foe is the meteor.** It needs no read of a busy AI, and it's what Orb said. But past the first brink is too late: that's 4:30 to 7:00 | `arc.weakBrink`: **`brinkProgress` 0.5,** not 1. On wear only, so roughly 2:15 to 3:30 if wear climbs evenly. A broken region still counts |
| **"Stunned" gets a route too** | A daze lasts 40 ticks and a full B takes 44, so today no daze can be followed by one. **A daze banks the charge,** as a level 3 upward flick does: at both tier 4, B's flash comes at 24 ticks | `DirArc.bank` on a daze, with its existing grace |
| **High arcs can't starve it** | Three arcs in the first 24 s isn't "planet-scale", and it spends the meteor's budget. **Until the meteor's been used, the last slot is kept for it,** so at most 2 high arcs come before it. High arcs also space out | `arc.highGapSec` **60**; the meteor keeps `gapSec` 20 |
| **Level 3 flick** | Re-ruled on Orb's first play: a hold past the quick flick has B's armour, so lights don't stop it (`power-scale.md`) | |

**QA's row stands:** a meteor in about one match in two or three, at most about 2 in one, read on real fights reaching both at tier 4. If 0.5 makes it too common, it goes toward 0.75. **`arc.firstMeteor`** stays a stand-in for Orb's private page, off on main, and it doesn't change this rule.

#### 3. The alerts

**Nothing goes on, over or between the fighters. All of it's view only, so the hash doesn't change and it's fair for each player to set their own.** It only says what's already true on screen.

| Family | What it is | Default | The player can set |
| :--- | :--- | :--- | :--- |
| **The shooter** | A glint at the hand as the charge steps up, in his own colour, by Legal's charge rule. The firing pose | On, as it's part of the fight | Brightness |
| **The front** | The beam itself | Always | Nothing: it's the game |
| **Air and light** | The air ripples ahead of the front, its colour sweeps along the ground, dust lifts and water shivers under its path | On, subtle | Off, subtle or strong |
| **Sound** | A low rising note that belongs to the target, panned toward the shooter and climbing to arrival. Audio's chunky rule | On | Off or on, its own volume, and which beams |
| **Rumble** | A new `incoming_beam` kind beside Controls' incoming ones: a crescendo to arrival, per pad | On | Off or on, strength |
| **Screen edge** | A thin line of the shooter's colour at the edge he's on, for the target only | **On only when the shooter's off screen** | Off, off screen only or always; thickness; which edge rule |
| **Caption** | "Beam incoming", small at the edge, for players who can't hear it | Off | Off or on, size |

**The options are per player and per pad, and they also take:** which beams warn (all, charged only, signature only); three presets (Minimal, Standard and Full); and colour-vision presets. Reduced flashing limits the strong settings. **A "longer window" assist** can add ticks in solo and co-op, and in versus only if the match's setup says so, because that one isn't view only.

**Who costs what:** Encounter the travel, the window and the meeting point (small, with `beamPlays` and `FRONT_SEC` already there, and it adds a little hashed state). VFX the front and the meeting. UI the options. Audio the note. Controls the rumble kind. **Legal:** the air and light family, against "the sky never darkens", and a screen-edge light.

### Orb's energy answer (`docs/design/energy-overhaul.md` §21)

**Row 34, the mixed string, is the row Orb wants most:** "emergent combos, dynamic combat choreography ... something really special". **Combat has it built in scratch, off (`docs/combat/pending/mixed-string`), needing only the far lob from `energy.v2`. The EP is moving it up to join the private page's stack, with its own switch, right after the stick lands.** The first playable still doesn't wait on it. The rulings on the lob, a dense street and the long yank are E142 to E145. It's mine and Combat's to design; Combat's pitches 1, 2 and 8 and the Driver are what it runs on.

**What makes it a system rather than a clip.** One press stays one attack, with no cancel inputs, and these four rules do the rest:
1. **One string across any range.** A shot that lands on him while he's sliding is the string's next blow, and freshness and "one stun a string" count it. So a string doesn't end when he leaves reach; it ends when nothing lands.
2. **The director leads the far blows.** A bolt follows him, a lob aims where the send's forecast says he lands, and a zip strike arrives at his get-up, with its piece chosen by what's between them. It reads the forecast the planner already has.
3. **Nothing's guaranteed.** E1 stands: he has his hands back after his own reel, so he can guard the lob or dodge the zip. **The far half of the string is a read, not a true combo.**
4. **What's in the way finishes it.** A wall, a mine on the line (E137), a tree (row 13), water (row 35), or at the far end a level 3 Driver and the meteor. So the same presses come out differently by place, and the fight writes its own endings.

**What Combat adds:** shot pieces in phrases (row 1), so RB is part of a learnable pattern. **What Camera adds:** one eased framing from close to far, with no cut.

**Row 35, water, on World's ladder (`docs/world/low-impact-water.md`).** Orb: "any low-impact water physics we can accomodate I am absolutely excited for." **One correction to what I wrote before:** the built fill is off and can't simply be switched on for gen 3, because a fill window is strip columns and would slide off its hole when a swing turns the line. So B1 is new work, not a switch. No fluid simulation, on any rung.

| Rung | What | When | Why |
| :--- | :--- | :--- | :--- |
| **A1** | Wakes, splashes, skim marks and a hollow ring | **First playable, folded into row 4, so must stays six** | View only, nothing hashed, not a flash. It's what makes a flat-out flight over a sea feel fast, and it's §1's wake. **The ring has no push yet,** and it waits on the gen 3 water sheet |
| **A2 and C1, then A3** | The parted sea and its rush-back, the ring's push, then wet shore | **Next, first in this row. It doesn't hold the first playable,** but it goes on as soon as it passes | It's the headline, but it needs a stick beam, a `surge` array in the hash and snapshot, and the flash clips, since a big area changes at once. The walls move over at least 0.3 s. Pushes stay as ruled: 2 bh along a line, 1 bh for a ring. It doesn't wait for a name: the `part` row can use a working id until Orb picks |
| **B1 and B2** | Holes fill, and water puts the fire out | **Next, after A2** | C10's third beat and the world answering back. World's design is sound: a pure function of the records, with nothing new to hash but a level. It never traps, slows or hurts |
| **A4** | Bobbing debris and river streaks | When Rendering has room | No sim, and nobody's waiting on it |
| **A skipping B shot** | | Later, with the Driver | |
| **D1** | Lakes that drain, rivers that carry | **Parked** | Real state and not low impact, and neither are tides |

**Each rung reports alone,** with both flash modes and its own switch, and the old laptop's frame time is the limit.

### The stick's speed (`docs/controls/responsiveness.md`), ruled

Measured natively: a face tap at close range lands 3 ticks after the finger moves, and a ramp-2 flick lands at 15. **The first playable ships all three below, behind Controls' switch and in the director's data, for Orb's thumbs to judge.** Together they take that flick from 15 to **11 ticks.** Nobody has played it.

| | The ruling | Why |
| :--- | :--- | :--- |
| **The quick strike's wind-up** | **10 to 7, not 6, with its commitment staying at 14** (so recovery goes from 4 to 7). `data/director/stick.json` holds it, so Orb can try 6 | See below |
| **Settle 1** | **Yes, on every strike and brace,** with `on` staying at 0.60. The D-pad and strike button move with it, to keep R32's same tick | It costs no direction accuracy in Controls' table and no claw gain in the model, for 1 tick on every strike. Only synthetic thumbs have been tested, so the capture tool checks it |
| **The vanish on the second press** | **Yes** | 4 ticks on a press of both together, for an escape that costs 20 ki. **It doesn't get stronger:** the blink is still about 8 ticks, so with the dodge's frames he's covered to about tick 10, not 14. A flick that comes after the read goes away, which is the neutral default and safe. It's the two presses a player means as a vanish, so a perfect block on the same LB no longer has until tick 6 |

**Why 7.**
- **Today the stick doesn't do what I ruled.** I said it beats a medium started at the same time, "10 against 12". That left out the thumb: from the same physical moment it lands at 15, and Y lands at 13. **At 7 with settle 1 it lands at 11, so the triangle becomes true.**
- **Why not 6:** one tick more isn't felt the way these four are, and it costs the reads below for nothing.

**What it does to reads and counter-play.**

| | At 10 | At 7 | So |
| :--- | ---: | ---: | :--- |
| **Reacting to it,** from the strike's start to the blow | 12 ticks | **9 ticks** | At 12 only an expert reacted, and at 9 nobody will. **It becomes a read: you guard, slip or press first because you expect it.** That's what's given up, and it's why Controls' cue below gives the defender something |
| **A light beating it** | A light landing inside 12 ticks | **Inside 9** | Still true for a steady mash with blows every 8 ticks or less. **A slower masher, 9 to 12 ticks a blow, can now be stunned, which is new.** QA's lights-only rows read it, and §2's "mashing stays fine for a beginner" depends on them |
| **A guard** | Blocks it, no stun | The same | The main answer stands: LB reacts on its press tick |
| **The slip away, the neutral dodge, a perfect block** | Beat it | The same, as reads | Less often on reaction |
| **Its price if read:** whiff, commitment | 20 and 14 | **20 and 14, unchanged** | So a blocked or whiffed strike is punished exactly as today, and the lockouts and the claw law don't move. Controls' model re-runs to confirm |
| **Online** at 200 ms | About 6 ticks of wind-up shown | **About 3** | More of the pose is skipped. Netcode reads it |

**The danger is the one I named in §1 of the rulings:** a faster medium with a stun. It's now quicker than Y, as well as stunning. **QA reads it first,** with a stick-only bot's win rate and the stick's share of non-light blows. **If it dominates, cut the stun from 20 toward 16 before giving back the wind-up,** because Orb asked for responsive.

**One thing the wind-up change breaks, and the fix.** Today the wind-up and the dwell end together, so a stick still out at tick 12 turns the wind-up into a charge. At 7, the blow is due before anyone can tell a flick from a hold. **So the blow lands at the later of the wind-up's end and the stick's return.** A stick that's still out holds the pose, and at the dwell it's a charge, as today, with the ladder at 12, 30 and 54 unchanged. On Controls' thumbs, a snap lands at the wind-up's end and a slow push on its return, which is still sooner than today (about 14 from 19 for a ramp-8 push), and nothing misfires. **Encounter and Controls confirm this against the hook.** Animation re-times the stick class's wind-up keys, and the pre-read covers the first frames.

### Controls' (`docs/controls/rule-of-cool-pitches.md`), ruled

| Pitch | Ruling | Where |
| :--- | :--- | :--- |
| 1 Feel the ladder | **Yes, must.** It needs no sim and tells you a level is ready with your eyes on him. The rung pulses only: **no constant hum at full charge,** as Orb wants rumble sparing and chunky | Row 6 |
| 2 Snap or push | **Next, after the capture tool has real thumbs.** A 2-tick line on a synthetic model decides which blow you get, so a misread would feel random. It can then ride on the 7: a push takes 10 and gains reach | Row 29 |
| 3 Feel it coming | **Yes, must, because the 7 needs it.** It's the defender's half of that trade. The pose shows the direction too, so a player with no rumble isn't missing anything hidden. Off switch, as all rumble | Row 6 |
| 4 Trigger depth | **No, for now.** The left hand already has the dodge, the slip, the brace and the vanish, and a third dodge on a half pull risks the wrong one at the worst moment. The slip already answers a close read | |
| 5 Catch the ground | **Next, beside row 8.** It's the right idea, since a sent fighter has a moment to win, and the scar's still there. Meteor and the high rows first, not every 1,500-unit carry, since that moves every launch's damage. The window needs a visible and audible cue too, as rumble can't be the only one | Row 30 |
| 6 Crank the clash | **No, as written.** Its premise is out of date: the struggle is no longer a mash. "The beat decides, and nothing else moves the point" (`rule-of-cool.md` §2), and turning at any speed would bring back what Orb's complaint removed | |
| 7 Sweep and cut | **Next, near the top.** It's already ruled (R25: the stick steers the beam 32-way), and it's the destruction Orb loves. It shares row 16's carve | Row 31 |
| 8 Lean the world | **Next, as a vote and not a command.** The lean is read once when a swing is asked for, and picks between sides that score about the same. It never starts a swing and never takes one to nothing, so §11 and §13 stand. Opposite leans go to the score. It fits row 2: one lean, "go that way" | Row 32 |
| 9 The phrase chime | **Yes, must, with row 1.** It's what makes a generated combo feel found. Once a string, kept short and low (Audio's chunky rule), and nothing for a broken phrase | Row 1 |
| 10 The lean, a bluff | **Later.** A real feint is worth having, but it's two more bits in the word and the AI has to read it | Row 33 |

## 6. For Orb

Three questions, none of which holds up the first playable:

1. **Same presses, same combo?** Once row 1 is in the build, try it with the switch on and off and say which you'd rather have. That settles pillar 2's wording (`pillar-2-wordings.md`), where #1 is my recommendation.
2. **Do the first four lines feel like those four fighters?** (§1.) Answer once there's a still to look at.
3. **The Driver as B's hold?** One huge shot that sends him and kicks you back, from a clip when Research has one. It's my pick over a shot that banks off the world and a battery of stored shots (`energy-overhaul.md` §21).
