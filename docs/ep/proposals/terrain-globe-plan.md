# Terrain on the globe: the overhaul plan

Orb's stand-in, 2026-11-08, revised the same day after three checks (rulings, engineering, completeness). A plan only: nothing starts until Orb says go, then the EP briefs it. Sections 1 to 3 are for Orb. Sections 4 to 8 are for the EP and the directors. Section 9 lists what the checks found and what changed. Every number marked *first value* is a starting point for Game Design or World to set, not a ruling.

## 1. Orb's ask, and the short version

> "from my play testing I am noticing the terrain destruction seems to be geared for the 'treadmill' version of the game we had in the beginning, I want all the destructible terrain, the fighters' interactions with terrain, by every conceivable metric upgraded and overhauled for the 3d globe arena. Just start working out a plan to fold in the best of the 'treadmill' system into the new globe arena." (Orb, 2026-11-08)

The short version:

- The planet's ground is already stored as a real round surface. But almost everything a fight does to it is still worked out on one thin line: the strip the two fighters stand on, the old treadmill.
- So a skid trench is 64 units across, about one body height, at every power. Rubble, fight water and trees slide along with the line when the world turns. A body that lands only ever feels the slope along the line.
- When marks moved onto the planet, some of the treadmill's best rules were left behind. These are: no digging shafts, ground that settles to a natural slope, a furrow on a glancing hit, and water only where it could come from.
- The plan: every mark becomes a shape at a real place on the planet, with the width, direction and depth the hit's force gives it. The old rules come back in round form, and what's drawn is exactly the ground the fighters stand on.
- Your earlier calls are built as you made them: craters sized by force with no ordinary cap, the meteor as an ordinary launch past the top speed, and holes filling with water where it would plausibly come from (the sea, lakes, wet ground).
- The camera stays side-on. When a body is knocked across a hillside or off a wall at an angle, the world turns to follow it, so its trench curves across the planet.
- There are ten steps. Step 0 measures today, so every goal has a number to beat. Step 1 makes sure nobody gets hurt, and nothing that adds destruction lands before it. Steps 2 to 4 fix what you saw in play.

## 2. What the treadmill did well, and what's still treadmill-shaped

### 2.1 Worth keeping

1. **One number sizes every crater.** Crater radius = 160·√force at impact (`sim/world/crater.gd:4-9`, the physics packet's rule at `physics-packet.html:86`). Powering up uses energy = tier^3.2, so tier 4 makes a radius of about 1,470. A signature, finisher or break launch has 9× the energy (3× the radius, `power-scale.md:41`).
2. **No shafts.** A cap on relief (0.26 of the radius, measured as the ring around the crater against its centre) stops repeat hits digging a well (`crater.gd:299-305`). A spot too dented to take the crater gets none (`MIN_DEPTH`). Grooves are cut to a target depth, never added up (`store.gd:148, 164`).
3. **Ground settles to a natural slope** (slope 1.25, `crater.gd:504-509`). The terrain audit's fix took steps taller than a body height from 20-43 a match down to 0-6 (`terrain-audit.md`, T1).
4. **The look follows the force.** The rim grows with energy (`crater.gd:306-309`). A glancing hit furrows the way it was going (`crater.gd:336-360`). Powering up on the ground scars it and in the air doesn't, and the feed says which (`prototype/index.html:692-703`).
5. **Buildings read as damaged.** They have 4 stages, floors and the lodge (a body stuck in a wall) (`brunt.gd:2-11`). Rubble keeps its volume, with heaps capped at a 1:1 slope and footings on the highest ground (`structures.gd:521-544`, audit T4).
6. **The landscape answers back.** Launches aim at buildings and mountainsides (`prototype/index.html:365-367`, `launch.gd:469-543`). Beams change by biome (`prototype/index.html:584`). Only the aim at terrain and buildings folds in: the old planner's care term, which scored the people near a landing (`index.html:371`), is left behind (RL-257 (4)).
7. **Water stays where it could come from.** On the treadmill a hole fills only when an unbroken run of low ground joins it to the sea: an inland crater stays dry however deep, and a bay dug at the coast fills (`water.gd:5-11`). Your 2026-10-23 ruling widens the sources to the sea, lakes and wet ground (section 2.2, item 10).
8. **Replays hold.** Blasts draw no random numbers (blast.gd header), and trees use keyed draws.
9. **The pebble skip**, which you asked to keep (`vision.md:1498`).

**Built and switched off:**
- Repeat blows grow one crater instead of stacking craters: the radius grows 1.25× for each repeat, on impacts only, up to a limit (`crater.gd:138-155`; your homework 30, `buildings.md:133`). It's off on main (`brunt.json:69`, `repeatMarks: 0`).
- The fix for repeat bounces (`contact.json:34`), craters by material (`craters.json`), fire, beam aftermath and water v2. Water v2 can't simply be switched on, because its windows are strip columns and "would slide off its hole" (`rule-of-cool-map.md:347`).

### 2.2 Still treadmill-shaped in your build

Your playable shortcut runs `?planet=7&tiles=1&meteor=loud`. That's the round-planet ground with tile drawing. Fighter depth is off (`data/combat/depth.json`), so bodies are always on the line's centre. Items 1 and 8 only matter once depth comes on. Everything else applies to what you played.

1. **Every mark is recorded at the line's centre** (`crater.gd:208-213`). With depth off that's where the body is, so it's correct today. It needs fixing before depth comes on.
2. **Skid trenches are about one body height wide.** The planet's trench record has a fixed half width of 32 units, so it's 64 across (`crater.gd:623`, `store.gd:287`). The designed half width, 56 + 24·√energy (109 at base, 242 at max, `slide.gd:25-27`), only sizes the dust. You asked for "longer and wider trenches" (`vision.md:1650`).
3. **The treadmill's safety rules are off for planet marks.** There's no furrow (`crater.gd:338`) and no settling (`crater.gd:377`, `498`). The shaft cap only looks at the old strip (`crater.gd:300-303`), and the planet's craters add up with no floor (`store.gd:133-165`). This comes from reading the code and hasn't been measured in a match.
4. **Things that slide with the line when the world turns:**
   - rubble heaps (`structures.gd:538-568`)
   - the banks beside a trench (`crater.gd:660-666`)
   - beam aftermath (`after.gd:345`)
   - fight water (`water.gd:2`)
   - trees (`state.gd:738-743`; `ring-any-angle/simulation.md:515-516`)

   Moving water is one candidate for your "hump of ocean water". It hasn't been checked.
5. **Follow-ups look for craters by old strip position**, which is wrong after a turn. This covers the buried fighter's follow-up (`crater.gd:394-410`, `bury.gd:142`) and the crater-rim check (`contact.gd:874-879`).
6. **A body feels slope only along the line.** It reads only the slope ahead and behind (`contact.gd:535-537`) and has no sideways speed. That fits "bounced against an outcrop of ground maybe six or seven times" (`vision.md:1619`). (The ground-type table itself does follow the line after a turn: on your planet it's read through `_fcol`, keyed on the line, the turn and the store, `contact.gd:441-454`.)
7. **Buildings always face the line square on.** A building has no angle (`brunt.gd:272, 900`; `state.gd:66-68`), and a ricochet treats every wall face as pointing straight along the line (`ricochet.gd:148-151`). Only buildings 225-3,375 units behind the line can be hit (`plan.gd:64-70`). That fits the "ping pong ball" bounce (`vision.md:1656`).
8. **Area damage reads the launcher's depth**, not the depth of the body that landed (`contact.gd:1242` → `structures.gd:603`), and trees are checked by strip position only (`structures.gd:641`). With depth off both read 0, so this waits for depth.
9. **The ground drawn isn't the ground stood on.**
   - Planet trenches and beam scars aren't drawn, but feet and props stand on them (`ground_field.gd:435`; the store-bowls README in `docs/rendering/pending/2026-11-01h-store-bowls/` says "not drawn yet").
   - Strip marks are smeared 9,000 units across the depth (`tile_vertex.gdshaderinc:71-99`).
   - Only the 16 nearest craters are drawn, and the rest pop (`look.gd:596`).

   That fits "clipping into the ground" (`vision.md:1660`).
10. **Water fills with no source test.** Any ground dug below the shore line reads as sea at once (`sim/core/field.gd:434-457`), whether or not water could reach it. Your words were "trenches, holes, any empty spaces… should be filled with water when necessary" (`vision.md:1498`), ruled as filling where water would plausibly come from: the sea, lakes, wet ground (`rulings-2026-10-23b.md:23-25`). Not checked in play.
11. **Bystanders still die on main, and the launch planner still scores people.** `WorldCollateral.kill` is called from building damage (`structures.gd:478, 484`), floor hits (`brunt.gd:1209, 1219, 1288`) and blasts (`blast.gd:182, 189`). The planner adds a care term times the people near a landing (`launch.gd:275, 319-320, 882`). Both go against your 2026-11-07 rule and Legal's RL-257. Window 1 of the fix is built and parked (`docs/world/pending/bystanders`). Window 2, which takes people out of the planner and feeds the meters from destruction, isn't built yet (that README, lines 25-29).
12. **Launch aiming and world turns see the line only.** The mountain and cliff checks look along the line (`launch.gd:236-241`). The turn picker reads only baked heights, so it's blind to craters and slopes (`director/swing.gd:351-357`).
13. **A hidden boost** makes launches travel 6× further sideways (`TRAV_LAUNCH`). The packet's call is that it goes (section 9, #12).
14. **Base knock-backs leave no trench.** An upright carry under 4 body heights skips the trench (`physics-packet.html:205`). The packet's call is that it goes.

## 3. The target, by measure

Every row has a number for today. Where today's number isn't known yet, step 0 records it with the tool named, so each goal has something to beat.

| Measure | Today | Goal | How it's measured |
|---|---|---|---|
| **Readability** | Not measured. Planet trenches and beam scars aren't drawn, and only the 16 newest craters are (`look.gd:596`) | Every hit that ends in a sudden stop leaves a crater or trench where it happened, drawn within 0.25 s. Drawn and stood-on height agree within 8 units under each foot (*first value*). No mark in view pops in or out | QA's outcome counter (new, step 0) matches stops to marks. Rendering's web-build probe (new, step 0) compares drawn and stood-on height every tick over 10 seeds, and counts marks that appear or vanish in view with no sim event. Each look change gets a side-by-side (ADR 0010) |
| **Escalation by tier** | With the power model off in your build, ordinary blows stop at radius 600, so base and max leave the same crater. Trench half width is a fixed 32 | Crater radius from the force at impact: 356 at base to 1,244 at max, signatures 3× (`power-scale.md:54-57`), with no ordinary cap. The meteor's crater comes from its own force at impact, like any send. Trench half width 109 to 242, longer with force, and a base knock-back leaves a small one. A repeat on one spot grows the crater 1.25× at most twice, so ten base hits on one spot stay under 560. Tiers 1 and 2 mark under 0.5% of the surface in a match (*first value*) | A headless batch of 40 seeds × 4 tiers sums record sizes by tier (World). A probe of 10 hits on one spot |
| **Variety** | Not measured. You saw 6 or 7 bounces off one outcrop | No one landing outcome takes more than half of the sends that touch ground. A 5-minute match shows at least 6 of these 7: crater, trench, skim, water entry, into or through a building, outcrop, tree line (*first values*). Beam style and crater material come from the spot itself | QA's outcome counter (new, step 0) gives every landing one class, over 40 seeds |
| **Persistence** | Heaps, trench banks, beam aftermath, fight water and trees slide with the line (code read, not seen in play). Every round-planet match writes the old strip | Land scars stay all match and water closes in seconds (`vision.md:447`). After 15 turns (your 11-07 match had 15), every mark sits exactly where it was made, with one fight and with two. Nothing writes or reads the old strip on a round-planet match: not the sim, the camera or the sound | A round-trip check (new) compares mark positions before and after 15 turns. Counters of strip writes and strip reads must be zero |
| **World turns** | Step 0 records turns per minute and the peak turning speed | The new kinds of turn (downhill, into a street) keep turns per minute and peak degrees per second within Accessibility's limits against today. The "cut" setting (`world_turning`) covers them | A swing log over 40 seeds (Encounter, Accessibility) |
| **Performance** | Sim tick 0.31 ms mean, 0.83 ms p99 (`budgets.md`). Meteor dig 12.9-17.1 ms. 2,305 marks in an 11-minute match. Worst late frame 26 ms | The tick stays within budget: 0.4 ms mean, 1.0 ms p99, and digging 0.05 ms a tick, measured on its own for the first time. Meteor dig under 3 ms (*first value*). Under 600 marks in 11 minutes (*first value*). Worst late frame no worse | Performance's late-tick and frame benches on scratch exports, in a quiet window |
| **LAN and rollback** | Save 1.57 ms and restore 2.45 ms, measured on a cloud machine that's retired, so not comparable. Restore plus the first replayed tick has never been measured | Restore plus the first replayed tick, and 8 replayed ticks, fit 3 ms on your PC on a round-planet world with a full match of marks (`budgets.md:25`). A peer that rolls back and one that doesn't read the same ground. The digest stays one number, replays are byte-identical and 1,000 headless matches run clean | Netcode's rollback bench, extended to time the first replayed tick, against step 0's number. A two-peer ground check (new). The golden, parity and CI runs |
| **Light safety** | One register per screen (RL-249) | A crater, a collapse and a scar share one light budget per screen. A catastrophe's light rises over at least 0.3 s and falls over at least 1 s (RL-232) | The flash checks, both modes, before any look report |
| **Sound and rumble** | Sound reads the biome and new water by old strip column (`docs/audio/biomes.md:31, 68`). Rumble has only a landing thud scaled by speed (`haptics.md:67`) | The ground the sound plays matches the ground in each sim landing event, over 40 seeds after 15 turns. Rumble for crater, trench, skim and ground type | Audio's and Controls' checks |
| **Bystanders** | People still die on main, and the launch planner scores people near a landing | Nobody dies. People pop out to the rim when a crater opens, then scatter (`bystanders.md:16`). Nothing reads people: with every person removed, every meter, planner pick and match result comes out identical. Menace reads wrecks and evacuation (RL-257), and +1 for a crater or trench his own send or beam digs 3 body heights or wider (`bystanders.md:45`) | The civilians-removed run, plus the negative control that shows the check would catch a breach (`bystanders.md` §2). Zero death events over 40 seeds. The retired-words lint (c11). Legal reviews harm to people |

## 4. The design (engineering)

### 4.1 One rule: the planet holds every mark

On a gen 3 world with a frame, the planet store (`S.store`) becomes the only place a fight changes the ground. `S.deform`, `S.rubble`, `S.water`, `S.scorch` and `S.crack` are no longer written there. They stay for gen 1 and 2 worlds and, if Rendering needs one, as an unhashed draw cache. This changes the hash, so it lands in a planned window (EP and Simulation decide).

What replaces columns:
- **The base** is the unchanged cube-sphere field (128-unit nodes).
- **Marks** are analytic records at planet points, one profile shared by the sim and the GPU (`crater.gd:120-132`, `tile_read.gdshaderinc:88-101`).
- **The line** (`S.frame`) is the fighters' and camera's view. It reads the ground through the same function as everything else.

Only this shape fits rollback: a 2D grid costs 2.2 to 29 MB per layer, copied every save, while a record is 128 B at any size.

**The memo rule every change keeps.** SimField's column and building memos live outside the state. When a record joins the store, only what that record can reach is read again (`sim/core/field.gd:249-252`, `_clearColumns` 290-330). That's only correct if a record changes the ground inside its own reach and nowhere else, and if old records never change. So:
- A record that supersedes another clears the union of both reaches.
- No record is ever edited. At the cap, a merge record is appended and the memos are laid again whole (`_serial += 1`).
- A check rolls back one peer and not the other, then compares the ground column by column.

### 4.2 Record kinds (same 16-float stride)

The record list and its shapes are fixed in the sim in step 2, before Rendering bakes them, so the bake is built once.

| Kind | Shape | Status |
|---|---|---|
| CRATER | Bowl, rim and apron. Gains a material class (`craters.json`), a repeat count, a slot for the record it supersedes and a water level slot | exists; slots (new) |
| TRENCH | A swept capsule from A to B. Half width from force (56 + 24·√E), depth cut to target (min, never sum). Raised lips replace the strip's banks, a berm grows ahead on soft ground, and there's a mound where the body stops. Water level slot | exists; width, lips, berm and mound (new) |
| SCAR | A directed beam groove from A to B with burn width (240 + 176P) and groove depth. One per beam pulse or sweep step, replacing the row of round scorch discs (86% of records today) | (new) |
| CRACK | A paving crack segment, half width 24 | exists |
| HEAP | A rubble cone at the building's own planet point. Volume from footprint × `leaveFrac`, slope capped at 1:1 | (new) |
| MERGE | Appended at the 16,384 cap. Stands for older small marks far from every fighter, reproducing their ground within 8 units | (new) |

**Trees need no records.** Whether a tree is down, and which way it lies, is read from the crater and blast records with keyed draws. On a gen 3 world each tree gets an id and a planet point when the world is made (constant for the match, shared like `fieldRecs`, not hashed). Today a tree holds only `x` and `h` (`state.gd:738-744`). A fallen trunk counts as rough ground (packet idea "The forest falls in a ring").

### 4.3 The treadmill's rules in round form

- **Shaft cap, the treadmill's way.** The new crater's depth is held to 0.26R minus the relief: the mean height of a ring at 1.2R (8 fixed bearings) against the height at the centre, both read without the record it supersedes. If the depth comes out under `MIN_DEPTH`, the dig is refused, returns -1 and supersedes nothing. `heightDelta` is clamped to a floor and ceiling (*first values* −2,080 and +960, the strip's; World rescales for big bowls).
- **Repeat blows grow one crater (homework 30).** Impacts only, not beams or power-ups. A new impact within 0.5 of a recent impact crater's radius moves to that crater's centre and supersedes it with a radius of the larger of its own and 1.25× the old one (`brunt.json:70`; a max, never a sum of energies). After `repeatMarks` repeats it grows no more (homework 30 reads two). The store stays append-only, and the index skips superseded records as a pure function of the store.
- **Settling when the crater is added.** Sample the wall at 8 fixed bearings. Where the steepest is over 1.25, widen R by k and shallow the depth by k² (volume kept, `SimDetMath.pow`). Then clamp R to the cap again and the depth to the shaft cap again: at the cap the bowl only gets shallower, so 160·√E stays the ceiling. There's no per-tick pass.
- **The furrow.** A shallow-angle impact makes a crater plus a short TRENCH along the true heading.
- **Water, as ruled (B1, `low-impact-water.md` §3).** When a crater, trench or groove is dug at least `fill.minDug` (6 units) deep, it looks once for a source: the sea (base field under the shore line), a lake (`recordWater`) or the biome's water table, at 8 bearings and 4 radii out to `near.reach` (about 1,150 units). It also takes the level of any overlapping record that already holds water, so a trench chain cut from the coast fills along its length and a bowl dug in a flooded crater fills: the treadmill's "joined by a run of low ground" rule in round form. The level goes in the record's slot, so it's hashed and truncates on rollback. A hole with no source stays dry. The parted sea lasts 90 ticks, a fighter surfaces within 30 ticks, a filled trench plays as water, and water never traps or slows anyone (`rulings-2026-10-23b.md:15-30`). World builds it behind a switch.
- **Footings.** Whatever stands in a big enough bowl falls in, driven only by the energy (RL-232 (1), `power-scale.md:70`). Only schools, hospitals, places of worship (c09) and the barred landmarks stop the dig at the footing (RL-242). A spared building never hovers: the ground under its footprint is left level, or lowered with it standing and nothing marked, whichever the look gate shows as ordinary (RL-246 (3)).

### 4.4 What fighters do with it

Fighters stay on the line and the camera stays side-on. The globe reaches the fight through the ground's true shape and by turning the line. "The world turns as a solid thing" (`ring-any-angle/game-design.md:24`).

- **Landings** are classed against the true surface normal, using the field's gradient both along and across the line. A steep landing makes a crater plus at most one hop (`power-scale.md:36`). A shallow one makes a trench along the heading, as wide as its force. The upright carry under 4 body heights goes, so a base knock-back leaves a small trench (packet §9 #9). The ground settle (`contact.json:34`) goes on, and a send gets at most one terrain bounce. Skims keep their own count (packet §9 #8).
- **Across a slope.** Landings are classed in the pure step that the launch predictor shares (`contact.gd:8-10`, `journey` 911-922), so the pure step never turns the world. When the ground under a sliding or tumbling body tilts across the line by more than a threshold (*first value* tan 0.27, about 15°), it emits a `downhill` event. Only the runtime acts on it (`_apply`, `contact.gd:1146`), calling `SimSwing.ask` with `deg` and `pivotX` set to the body. A turn is refused while a beam is out (`swing.gd:32`) and in 2v2 while anyone is past `apartReach`. Its speed is capped by the standing limit, 75 u/s at the farthest fighter (`game-design.md:19, 54`): about 2° a second at 2,000 units apart. So step 0 measures how far a turn really gets during a slide. If it's only a few degrees, the other option is laying trench segments on a sideways heading taken from the gradient, with no turn. Encounter and World pick by the numbers in step 7.
- **Slams and burial.** CRATER SLAM stays. The buried fighter's follow-up finds its crater through the planet store's index.
- **Walls and buildings.** Buildings get a face angle from their street (`bA` (new), from `plan.gd:124-127`). A body deflects off the true face. When a building stands off the line, the line turns into the street (`streetAxis`, `structures.gd:709`), so the fight presses into the city instead of bouncing back. The brunt chain stays. Each building takes force out of a body going through it (house 1, low tower 5, tall tower 15, `power-scale.md:35`).
- **Guards and mashes.** A guard hit above footing slides the blocker back and carves a trench, and an even mash craters under both fighters (packet §9 #1-2).
- **Beams.** A SCAR is laid along the beam's real path. This ties into your beam overhaul (`vision.md:1675`). The rule refusing a turn while a beam is out stays until that overhaul decides.
- **Trees** fall by surface distance from the blast and lie along its direction, read from the records (4.2).
- **Cover** reads the planet around the fighter. Hiding waits for a future stealth fighter (`hiding.gd:5-7`).
- **Launch aim reads terrain and standing buildings only.** No AI, picker or score reads people or who stands near a target (RL-257 (4); this replaces `rulings-2026-10-23b.md` row 6). Mountains, cliffs and buildings are probed at the ±30/60/90° bearings the turn picker already scores (`director/swing.gd:371-392`), and the turn picker sees craters and slopes through `heightDelta`.
- **When depth comes on:** the mark is recorded at the body's own point and area damage reads the body that landed, not the launcher.

### 4.5 Draw what's stood on

- Rendering bakes planet records into tile heights, once, on the record list fixed in step 2. Tiles are already keyed to the planet (`tile_field.gd:1-19`), and a record marks the tiles its reach touches for a rebuild.
- The 16-bowl shader list stays only for the newest bowls opening on the render clock, then hands them to the tile.
- Feet (`keep_off`) and props read the same function the tiles do.
- Strip rows stop being drawn on round-planet worlds.
- Paving cracks and shatters while dirt craters (`vision.md:557`; `?craterlook`).
- The cost of rebaking tiles on the web, which has one thread, is unmeasured. Step 4 measures it on the reduced store (SCAR segments in), not today's 2,305 records.

### 4.6 Camera, sound and rumble

- **Camera** (`docs/camera/swing-view.md:26, 28, 34`). Every mark gets a planet anchor, so no rig reads a mark by its strip x. The tall-land probe reads the ground plus the marks, not the baked heights alone. The high-angle shot keeps scorch and cracks after a turn, read from records.
- **Sound** (`docs/audio/biomes.md:31, 45, 68`). The biome and the ground are read at the landing's planet point, after any number of turns. New water is counted by area from the records, not by columns newly wet.
- **Rumble** (`haptics.md:67`). Controls adds rows for crater, trench, skim and ground type beside the landing thud.

### 4.7 Two fights (2v2)

- Fight 1's marks sit at its own planet points, never at the shared line's centre (`fight-swap.md:23-25`).
- The 15-turn round trip runs with two fights as well as one.
- A downhill or street turn is refused while anyone is past `apartReach` (4,000 units), the rule every swing already follows (`fight-swap.md:25`).
- `aftermathT` is shared across columns today. It becomes per record.
- The partner brace (packet idea "The anvil and the partner brace"): a guard braced by a partner digs a trench twice as wide. Netcode and Encounter own these rows.

### 4.8 What folds in, and what's left behind

**Folded in:** everything in 2.1, and the switched-off repeat rule. Beam styles by biome are now picked at the mark's own point.

**Left behind:** per-column deform on round-planet worlds, the 1D water windows, the ×6 sideways boost, the upright carry under 4 body heights, the ordinary 600 cap (as `crater.gd:285` already drops it when the power model is on), the meteor's own crater multiplier and radius ceiling (`meteor-crater.md:8`; the meteor is an ordinary send now), deaths and every people term in pickers and meters, and depth rows as the model of depth.

### 4.9 Keeping the store cheap

- SCAR segments cut scorch records (step 2).
- Craters with R ≥ 3,000 (*first value*; full memo re-lays start near 3,050, `field.gd:299-301`) go on a short list that every read checks, in a second loop with no Array concatenation. Today they're listed in 14k-36k grid boxes.
- The derived index keeps one entry per record count, so a rollback that truncates to n keeps the entries below n instead of rebuilding the whole grid, the column memos and the contact table (`store.gd:91-95`, `field.gd:208-213`, `contact.gd:451-454`).
- At the 16,384 cap, a MERGE record is appended for the oldest small marks farther than view reach from every fighter. It never edits them, and it's never in view, so nothing pops. Nothing falls back to strip writes.
- Already on main, so not in the work: the incremental grid (`store.gd:107-123`) and the field static memo (`sim/core/field.gd`, commit 3c9005ac).
- Not planned: chunked saves. A full store of 16,384 records copies about 2 MB, and chunking would change a flat layout read by `store.gd`, `field.gd`, `swing.gd:436-475` and `tile_ground.gd:265`. It comes back only if step 0 shows saves are the problem, costed across all of those readers.

### 4.10 What's hashed

Every new piece of state goes in the snapshot and the hash in the same change:
- store slots: material class, repeat count, superseded record, water level (in `storeHash` as part of each record)
- body fields: `lastQ` (the furrow's last point, three floats) and any downhill-turn timer
- per-record aftermath times (2v2)

Tree ids and planet points are made from the seed when the world is made and aren't hashed, like `fieldRecs`.

## 5. Pseudocode (GDScript-shaped)

All numbers are float64. Planet points are three floats, never `Vector3`. Powers, roots and logs go through `SimDetMath`. The determinism lint learns `pow`, `exp`, `log` and `Vector3` in step 2, before any of this lands (`tools/lint-determinism.mjs:24-36` doesn't catch them today). Randomness is keyed only. Every record goes into the hashed store.

```gdscript
# sim/world/store.gd
const KIND_SCAR := 5            # (new) directed beam groove A->B
const KIND_HEAP := 6            # (new) rubble cone
const KIND_MERGE := 7           # (new) appended at the cap; never edits an older record
const O_WATER := 14             # (new) slot: the level this record's water stands at, NAN when dry (B1)
const O_SUP := 15               # (new) slot: record this one supersedes, -1 none
const BIG_R := 3000.0           # (new, first value)

## Height the marks add at unit direction (qx,qy,qz). Pure: reads S.store only.
static func heightDelta(S, qx: float, qy: float, qz: float) -> float:
	if int(S.storeN) == 0:
		return 0.0
	var R: float = _R()
	var ent: Dictionary = _index(S)        # grid (on main) + ent.big + ent.sup (new), kept per record count
	var acc := PackedFloat64Array([0.0, 0.0, 0.0])                     # bowls, cut, lip
	_sum(S, ent, _near(ent, qx * R, qy * R, qz * R), qx, qy, qz, R, acc)   # two loops, no Array concatenation
	_sum(S, ent, ent.big, qx, qy, qz, R, acc)
	var h: float = (minf(acc[0], acc[1]) if acc[1] < 0.0 else acc[0]) + acc[2]
	return clampf(h, FLOOR, CEIL)          # (new) first values -2080 / +960

static func _sum(S, ent, ks, qx, qy, qz, R, acc) -> void:
	for k in ks:
		if ent.sup.has(k):
			continue                       # superseded or merged: a pure function of the store
		var o: int = k * STRIDE
		match int(S.store[o]):
			KIND_CRATER, KIND_MERGE: acc[0] += _bowl(S, o, qx, qy, qz, R)
			KIND_HEAP:               acc[0] += _heap(S, o, qx, qy, qz, R)    # (new) slope <= 1
			KIND_TRENCH, KIND_SCAR, KIND_SCORCH:
				var c: Array = _capsule(S, o, qx, qy, qz, R)                   # (new) [groove, lip]
				acc[1] = minf(acc[1], c[0])    # grooves never sum
				acc[2] = maxf(acc[2], c[1])
```

```gdscript
# sim/world/crater.gd
## A crater on a round-planet world, at the body's own point q. Returns the record, or -1 when refused.
static func addCraterGlobe(S, q: Array, E: float, kind: int, cause, special: bool) -> int:   # (new)
	var cap: float = _cap(S, special, kind)          # crater.gd:285: no ordinary cap with the power model; the meteor's limit is perf data
	var R: float = minf(R_BASE * sqrt(E), cap)       # 160·√E
	var j: int = -1
	if kind == KIND_IMPACT:                          # repeats: impacts only (crater.gd:138-155)
		j = WorldStore.recentImpact(S, q, 0.5, S.T - MERGE_T)            # (new)
		if j >= 0 and WorldStore.repeatsOf(S, j) < int(WorldBrunt.cfg().repeatMarks):
			q = WorldStore.centreOf(S, j)                                # the dig moves to the old centre
			R = minf(maxf(R, WorldStore.radiusOf(S, j) * float(WorldBrunt.cfg().repeatCraterGrow)), cap)   # x1.25, a max
		else:
			j = -1
	var relief: float = _ringRelief(S, q, RING_K * R, j)   # (new) ring at 1.2R minus centre, read without record j
	var d: float = minf(DEPTH_RATIO * R, RELIEF_MAX_RATIO * R - relief)   # 0.22R, held to 0.26R less the relief
	if d < MIN_DEPTH:
		return -1                                    # refused: supersedes nothing
	var s: float = _steepestWall(S, q, R, d, j)      # (new) 8 fixed bearings, no RNG
	if s > REPOSE:                                   # 1.25
		var k: float = SimDetMath.pow(s / REPOSE, 1.0 / 3.0)   # R·k, d/k²: volume kept
		R = minf(R * k, cap)                         # never past 160·√E's ceiling
		d = minf(d / (k * k), RELIEF_MAX_RATIO * R - relief)   # at the cap the bowl only gets shallower
	var hr: float = _rimFor(E, d)                    # rim grows with E, <= 0.4d
	var lv: float = WorldFill.levelFor(S, q, R, d)   # (new) B1, below
	return WorldStore.add(S, q[0], q[1], q[2], R, d, hr, E, kind,
		int(_slot(S, cause)), S.T, 1 if special else 0, j, lv)   # store clears the union of j's reach and this one's
```

```gdscript
# sim/world/slide.gd
## Each tick of a slide: append a trench segment once the body has gone a half width or turned.
static func furrow(S, b, E: float) -> void:                           # (new)
	var hw: float = 56.0 + 24.0 * sqrt(E)                             # half width, slide.gd:25-27, now stored (today 32)
	var depth: float = minf(trenchDepth(E), DEPTH_CAP)               # cap: World picks
	var q: Array = WorldCrater.pointOfBody(S, b)                       # (new) x and the body's z
	if _arc(b.lastQ, q) >= hw or _turned(b, q, TURN_TAN):             # (new) TURN_TAN first value
		var lv: float = WorldFill.levelForSegment(S, b.lastQ, q, depth, hw)
		WorldStore.addTrench(S, b.lastQ, q, depth, hw, S.T, b.slot, lv)   # lips and berm from hw and ground (new)
		b.lastQ = q                                                    # new body field: snapshot and hash (4.10)
```

```gdscript
# sim/world/contact.gd
## Class a landing against the true surface. Pure: shared with the launch predictor, so it never turns the world.
static func landClass(S, b, ev: Array) -> int:
	if b.speed <= MIN_IMPACT:                                          # 350
		return STOP
	var g: Array = SimField.gradAt(S, b.x, b.z)                        # (new) [dg/dx, dg/dz]
	var nx: float = -g[0]
	var nz: float = -g[1]
	var vn: float = b.vx * nx + b.vy                                   # normal (nx, 1, nz); no vz
	var s2: float = vn * vn / ((b.vx * b.vx + b.vy * b.vy) * (nx * nx + 1.0 + nz * nz))
	if seaAtPoint(S, b):                                               # (new) sea at body's point
		return SKIM if _skims(b, s2) else ENTRY
	if s2 >= SLAM_S2:                                                  # 0.883
		return SLAM                                                    # crater + at most one hop
	if absf(g[1]) > CROSS_TAN:                                         # (new) first value 0.27
		ev.append({"k": "downhill", "x": b.x, "tan": absf(g[1]), "dir": _downhill(g, b)})   # an event, not a turn
	return SKID                                                        # trench along heading

## Runtime only (_apply, contact.gd:1146). journey() ignores "downhill", so a predicted journey stays the played one.
static func _onDownhill(S, b, e: Dictionary) -> void:
	SimSwing.ask(S, {"deg": _turnDeg(e), "cause": "launch", "pivotX": b.x})   # refused with a beam out or 2v2 apart
```

```gdscript
# sim/world/fill.gd (B1, low-impact-water.md §3): found once when a dug record is made, stored in its slot, hashed
static func levelFor(S, q: Array, R: float, d: float) -> float:
	if d < float(cfg().minDug):                                        # 6 units
		return NAN
	var lv: float = NAN
	for j in WorldStore.overlapping(S, q, R):                          # a record joined to water carries it on
		lv = _higher(lv, WorldStore.waterOf(S, j))
	for p in _ring(q, R, 8, 4, float(cfg().near.reach)):              # 8 bearings x 4 radii, out to about 1,150
		lv = _higher(lv, _source(S, p))                                # sea (base field under the shore line), lake (recordWater), water table
	return lv                                                          # NAN: no source, stays dry

# trees: down or standing is read from the records; no record per tree
static func treeDown(S, t) -> Array:                                   # t.id, t.q made from the seed at world build (new)
	for k in WorldStore.within(S, t.q, FELL_REACH_MAX):               # craters and blasts only
		if WorldStore.fells(S, k, t.q):                                # surface distance inside the record's fell reach (from its energy)
			var jit: float = SimRng.keyed(S.seed, "fell", t.id) - 0.5  # keyed, never a stream
			return [true] + _awayDir(WorldStore.centreOf(S, k), t.q, 0.2 * jit)
	return [false]
```

## 6. Steps, in order

**Order.** Step 0 and step 1 start together. Step 1 lands first and on its own, and nothing that adds or widens destruction (steps 2, 3, 5, 7 and 8) lands before it. Step 2 needs steps 0 and 1. Steps 3, 4 and 5 need step 2 and can run side by side. Step 6 needs step 5. Step 7 needs steps 3 and 5. Step 8 needs steps 5 and 6, and step 7 for anything that turns the world. Hash changes are bundled where steps finish together (2 with 3, 5 with 6), and nightly seeds re-run on the new commit before any site pin moves.

**Gates.** Each step lands with the full world checks (`--run`), the render gates, the golden and CI. Any change to the look also needs the side-by-side and both flash modes.

**Costs** come from each step's file list and gate runs: about 0.1M tokens a file touched, 0.25M a full gate pass, 0.3M a look gate, 0.4M a hash window, and 0.3M for the EP's review and landing. They're estimates, not meters.

| # | Step: what you'll see | Measure | Owners | Cost (basis) |
|---|---|---|---|---|
| 0 | **Measure first.** Stills of the flat brown crater and the ocean hump on seed 3687423, after quiet time, through Tools' launcher. Today's number for every row of section 3. The tools that later steps use: the terrain audit ported to sample `heightDelta` on a planet grid around each record; QA's outcome counter with one class per landing; Rendering's drawn-versus-stood-on probe; the round-trip check; restore plus the first replayed tick on your PC; turns per minute and peak turn speed; how far a downhill turn really gets during a slide | Every section 3 row has a today value from a named tool. The ported audit fails if it finds zero marks on a globe match. The five questions (shafts, inland sea, flat crater, ocean hump, snapshot and grid cost with a big bowl) answered with a still or a number | QA, World, Rendering, Performance, Netcode, Accessibility, Tools | ~2.5M (8 tool files, 1 gate pass, baseline batches, stills) |
| 1 | **Nobody gets hurt.** Window 1 of the bystander fix (scatter, the no-casualty feed, civilians removed) and window 2 (meters fed from destruction, the planner on structure mass, the people term out of `launch.gd`, the counter retired) land together. Window 1 isn't landed alone into a build people play (bystanders README) | The civilians-removed run gives identical meters, planner picks and match results. The negative control fails when a people term is put back. Zero death events over 40 seeds. The retired-words lint passes | World, Simulation, Encounter, UI, Legal (harm to people), QA | ~3M (parked window 1, about 8 files for window 2, a hash window, 2 gate passes) |
| 2 | **No shafts, and water where it could come from.** The record list fixed in code (SCAR, HEAP, MERGE, trench lips and berm, the new slots). The shaft cap against the ring relief, `MIN_DEPTH`, floor and ceiling, repeat growth at 1.25× up to the limit, settling with the re-clamp, the furrow. B1 water fill as ruled, behind its switch. Superseding clears both reaches. The lint learns `pow`, `exp`, `log` and `Vector3` first | 20 hits on one spot never go deeper than 0.26R. 10 base hits on one spot stay under 560. 0-6 steps over 1 body height a match over 40 seeds (ported audit). No record without a source holds water, and a trench cut from the coast fills along its length. The two-peer ground check passes. Changes the hash | World (lead), Simulation, QA | ~3M (about 10 files, 3 new checks, 2 gate passes, shared hash window) |
| 3 | **Trenches you can see, at every power.** The ×6 boost goes (clips decide only whether even ×2 is needed). The upright carry under 4 body heights goes. Trenches as wide as their force (half width 109 to 242), longer with force, with lips, a berm on soft ground and an end mound, and a deeper depth cap. Craters from the force at impact with no ordinary cap. The meteor's crater from its force at impact. The settle on, at most one terrain bounce | Every SKID landing leaves a trench record, base knock-backs included. No send has more than one terrain bounce over 40 seeds. Skim counts unchanged. No base or tier 2 send ever glows. Crater sizes by tier match section 3 | World, Encounter, Game Design (numbers), Performance (meteor limit), QA | ~2.5M (about 7 files, 2 gate passes, look gate, clips for ×2) |
| 4 | **Feet on the ground you see.** Planet trenches and scars are drawn, craters bake into tiles once, nothing pops, and feet see new craters | Drawn and stood-on height within 8 units under feet over 10 seeds. Zero pops in view. Web rebake cost measured on the reduced store | Rendering (lead), Animation, QA | ~2.5M (about 7 files, look gate, web bench, 2 gate passes) |
| 5 | **Nothing slides with the line.** Heaps, banks and aftermath become planet records, trees read from records, strip writes stop, follow-ups find craters through the store. Camera rigs read marks by anchor and the tall-land probe reads the marks. Sound reads ground and biome at the planet point. 2v2: fight 1's marks at its own points, aftermath per record | The 15-turn round trip is exact with one fight and with two. Zero strip writes. Zero strip-position reads in the camera rigs. The ground in each sim landing event matches the ground the sound plays over 40 seeds after 15 turns. Changes the hash | World (lead), Simulation, Rendering, Camera, Audio, Netcode, QA | ~4M (about 14 files across five directors, 3 gate passes, shared hash window, look gate) |
| 6 | **A store that stays cheap.** The big-crater list, the index kept per record count, the MERGE record at the cap | Under 600 marks in 11 minutes. Meteor dig under 3 ms. Restore plus the first replayed tick, and 8 replayed ticks, inside 3 ms on your PC. The two-peer ground check. Budgets met | Simulation (lead), Netcode, Performance, World | ~2.5M (about 5 files, rollback and perf benches, 2 gate passes) |
| 7 | **Slopes, walls and streets in 2D.** Landings read the true slope, a downhill event turns the world (or trenches bend downhill, by step 0's numbers), buildings face their streets, off-line buildings turn the fight into the street, and the turn picker and launch aim see craters, slopes and materials | No outcome over half of ground sends. At least 6 kinds a match. Zero rebounds off off-line buildings. Turns eased. Turns per minute and peak turn speed within Accessibility's limits against step 0, and the cut setting covers the new turns. No turn is started inside the launch predictor. A downhill turn is refused in 2v2 while anyone is past `apartReach` | Encounter (lead), Camera, World, Rendering, Game Design, Accessibility, Netcode, QA | ~4M (about 12 files, 3 gate passes, look gate, motion review) |
| 8 | **The landscape answers back.** Each item behind its own switch, with its own target in section 7: ground hardness and grip, the ice class, craters by material, the city block falling into a big bowl, force costs through skyscrapers, floors and pancaking, heaps as ramps and rough ground, power-up force pushing debris, fire, beam aftermath, the beam-meeting crater, the beam-catch trench, clash and mash craters, spray walls, the paid-forward debris front, the burn-line streak, rumble rows | Each switch meets its section 7 target, its world check, the side-by-side and the light budget | World (lead), VFX, Art (looks), Encounter, Controls, Audio, Legal (light, harm to people), QA | ~7M (about 12 switches at about 0.5M each, plus reviews) |
| 9 | **Tier 4 and the planet's scale.** A design page first: rifts, lava, quakes, ash, destruction kept across a run | Orb picks from the page | Game Design, World, Legal | ~1.5M, then build cost |

Total through step 8 is about 31M tokens, the EP's reviews included.

## 7. Coverage: the physics packet's ground, building and world rows

Every row of the packet's section 7 tables for Ground and water, Buildings and World reacting, and the matching ideas, has a step and a measure, or says why it waits.

| Packet row | Step | Measure, or why it waits |
|---|---|---|
| Pebble skip | 3 | Skim counts unchanged over 40 seeds; no bounce fix cuts them |
| Trench from a slide | 3 | Length, width and depth from the force at touch-down; base knock-backs leave one |
| Bounces | 3 | At most one terrain bounce a send, only what hard ground can't absorb |
| Craters and rims | 2, 3 | Radius from force at impact, no ordinary cap; section 3 sizes by tier |
| Buried in a big crater | 5 | Burials appear from tier 3 up and never at base, over 40 seeds; the follow-up finds its crater after turns |
| Water filling holes | 2, 8 | No source, no water; a coast trench fills along its length; the first fill fits the frame budget (it costs 19-27 ms today) |
| Ground materials (hardness and grip) | 8 | Each ground has the two numbers in data; slide length differs by ground as the packet's table |
| Powering up on the ground | 8 | The released force pushes debris and a close rival by distance; its limits re-read by whoever owns them after the 11-07 split |
| Through several skyscrapers | 8 | A maximum send goes through 4 skyscrapers and a base send stops in a low tower (`power-scale.md` table) |
| Wall slam and lodged fighter | 7 | The rebound leaves the true face; zero rebounds off off-line buildings |
| Floor, ceiling, floor inside a tower | 8 | Built and off: each slab costs force; on behind its switch |
| Collapse and pancaking | 8 | The pancake rule fires at tiers 3 and 4 over 40 seeds |
| A city block into the crater | 8 | What stands in a big enough bowl falls in; c09 places and barred landmarks spared and never hovering; one catastrophe-class light event |
| Rubble heaps | 5, 8 | A planet record (5); a ramp or rough ground you tumble on (8) |
| Megastructures | waits | Concept art only, and no picker may steer toward them |
| Fire | 8 | Heat reaching a tree against its resistance, not a fixed chance |
| Smoke, landslides, quakes | 9 | On the design page |
| Rubble rises, windows blow, clouds part | 8 | Driven by the force carried, not the tier (VFX) |
| Ash that darkens the planet | 9 | On the design page |
| Damage that stays across a run | 9 | Orb's scope decision |
| Repeat launches break more | 2, 8 | Craters grow 1.25× (2); buildings remember their damage (8) |
| Idea: the berm that grows | 3 | The berm grows ahead of a slide on soft ground |
| Idea: the forest falls in a ring | 5 | Trees read from records, toppling over about 0.4 s, never fading; trunks are rough ground |
| Idea: what's under the clash takes the difference | 8 | Clash and mash craters; nobody sinks into water |
| Idea: the anvil and the partner brace | 7, 8 | The anvil is a sudden stop; the brace doubles the trench width (2v2) |
| Idea: paid forward | 8 | The debris front lowers the next building's force cost |
| Idea: spray walls | 8 | Spray sized from the force lost, behind the fighters |
| Idea: the slide that cuts the floe | 8 | The ice class: a slide digs nothing until its force beats the floe's hold, then cuts to the sea |
| Idea: the long way down | waits | The packet parks it until something in the fight lane is tall enough (packet:551-552) |
| The burn line on the ground | 8 | A body past the burn line that grazes ground leaves a scorch streak (a SCAR), a look only (Game Design's call, *first value*) |
| Beam struggle crater, beam catch | 8 | Behind their switches, paced with the beam overhaul |

## 8. Risks, and who decides

**Risks**

- **Hash changes** (steps 1, 2, 3, 5 and 6) re-pin the golden and the round-planet hashes. They're bundled into planned windows, and nightly seeds re-run on the new commit before any site pin moves.
- **Rollback cost** lands in the first replayed tick, when every derived cache misses at once, not in save and restore. Step 0 measures it on your PC, and step 6 keeps the index per record count.
- **Memo drift.** Any record that changes ground outside its own reach, or any edit to an old record, desyncs a peer that didn't roll back. The two-peer ground check guards it from step 2 on.
- **Curvature.** A flat bowl at R_MAX is 19° of arc, and the store measures distance as a chord (`store.gd:152-155`). That's fine at ordinary sizes and needs a check at meteor scale.
- **How far a turn gets.** The standing limit allows about 2° a second at 2,000 units apart, so a downhill turn may be too small to see. Step 0 measures it, and step 7 has the trench-heading option.
- **The web build runs on one thread**, so tile rebakes have to fit inside a frame there.
- **There's no JS oracle for terrain** (`crater.gd:2`). The lint learns `pow`, `exp`, `log` and `Vector3` in step 2.
- **Caves and arches.** The ground is a heightfield and can't have an inside (`planet-overhaul.md:80`), so "through the mountain" (`vision.md:430`) needs a separate answer.

**Already ruled, built as ruled (no question for Orb)**

- Water: fill where it would plausibly come from, the sea, lakes and wet ground (2026-10-23).
- Crater size: a small crater at base, a city block at maximum (2026-11-01), with no cap (the packet's craters row) and the 600 cap gone (`power-scale.md:34`).
- The meteor: the same as any other launch, past the minimum force (2026-11-02), an ordinary launch past the top speed line (packet §9 #3). If its crater needs a limit, that's a performance number in data that World and Performance set.

**Only Orb decides**

1. **Fighters and the world.** Fighters stay on the line and the world turns to follow a body across a slope, or the trench bends downhill while the body stays on the line (recommended, picked by step 0's numbers), or bodies get real sideways movement with depth on.
2. **Big-power scope.** Are rifts, lava and quakes at tier 4, destruction across a run (`vision.md:1367`) and planet destruction in versus (`vision.md:874`) still in scope?
3. **Buildings in front.** Should buildings in front of the fighters be hittable? It needs a camera answer that uses no fades.

**Game Design decides:** the cross-slope threshold, the repeat window and how many repeats grow a crater, trench length per unit of force, the variety targets, the menace values (including whether a grown crater counts as one crater for the +1), and the burn-line streak. **World decides:** the trench depth cap, the floor and ceiling for big bowls, and, with Performance, any meteor crater limit.

**Art decides, under the look gate (ADR 0010; creative rulebook, `creative-rulebook-handover.md`):** the heap, collapse, trench and crater looks, and how a spared building's ground looks.

**Legal reviews** what stays Legal's after 2026-11-07 (`vision.md:1671`): the bystanders' pop and scatter and every people rule (RL-257), block falls driven only by energy with c09 places spared (RL-232 (1), RL-242), no hovering spared buildings (RL-246 (3)), and the shared light budget and catastrophe envelope (RL-249, RL-232).

## 9. Checks and changes

Three checks read the first draft on 2026-11-08. Each finding was checked against the files it cites.

**Rulings**
- R1, deaths before new destruction: fixed. Bystanders move to step 1, and steps 2, 3, 5, 7 and 8 can't land before it (`structures.gd:478, 484`, `brunt.gd:1209, 1219, 1288`, `blast.gd:182, 189` confirmed).
- R2, the planner reads people: fixed. The people term is out of 2.1, window 2 joins step 1, and step 1's measure is the civilians-removed run plus the negative control (`index.html:371`, `launch.gd:275, 319-320, 882`, README lines 25-29 confirmed).
- R3, water narrowed and misquoted: fixed. B1 is built as ruled (sea, lakes, water table, out to about 1,150), Orb's words are quoted exactly, decision 2 is gone, and the treadmill rule now says a coast bay fills (`water.gd:5-11`).
- R4, meteor options against Orb's words: fixed. The meteor's crater comes from its force at impact, any limit is performance data, and decision 4 is gone.
- R5, crater size reopened: fixed. Decision 3 is gone, and the cap is written as `crater.gd:285` does it.
- R6, energy sums, settle past the cap, menace: fixed. Repeats grow 1.25× by a max with a limit, R and depth are clamped again after settling, and menace is his own send or beam with a grown crater for Game Design to count once.
- R7, packet calls weakened: fixed. The ×6 boost goes outright and the upright carry goes in step 3.
- R8, footings, c09, Legal's scope, retired word: fixed. Only c09 places and barred landmarks stop at the footing, looks go to Art under the look gate, Legal keeps light and people, and "toll" is gone.
- Quotes: fixed. The outcrop quote is whole, and the 75 u/s rule cites `game-design.md:19, 54`.
- Merging at the cap could change ground in view: fixed. A MERGE record covers only marks farther than view reach from every fighter.

**Engineering**
- E1, supersede and cap merge break the memo invariant: fixed. Superseding clears both reaches, old records are never edited, the cap appends a MERGE record with a full re-lay, and a two-peer ground check is added (`sim/core/field.gd:249-252`, `store.gd` append-only confirmed).
- E2, the shaft cap fights the merge: fixed. Relief is the ring against the centre, read without the superseded record, and `MIN_DEPTH` refuses without superseding.
- E3, turning from the predictor's pure step: fixed. The pure step emits a `downhill` event, the runtime asks with `deg` and `pivotX`, and step 0 measures how far a turn gets (`contact.gd:8-10`, `swing.gd:32, 209-238` confirmed).
- E4, rollback cost in the first replayed tick: fixed. The measure is restore plus the first replayed tick on Orb's PC, and the index is kept per record count. The detail that the old bench had no frame couldn't be confirmed (it ran on planet 7), but the bench machine is retired either way.
- E5, per-record water isn't the treadmill's rule: fixed, merged with R3. A record takes the level of any overlapping wet record, stored in its hashed slot.
- E6, bare `pow` and unhashed `lastQ`: fixed. `SimDetMath.pow` is used, the lint learns `pow`, `exp`, `log` and `Vector3` in step 2, and 4.10 lists every new field.
- E7, false claims about today: fixed. The repeat rule moves to "built and switched off", the ground-type table claim and the planet-cell cache are dropped, the depth items are marked as waiting for depth, the trench is 64 across, and the static memo and incremental grid are out of the work.
- E8, FELL and chunks: fixed. Trees are read from records with keyed draws and get a seed-made id and point, and chunked saves are dropped unless measured.

**Completeness**
- C1, no baselines and a blind audit tool: fixed. Section 3 has a Today column, step 0 fills every row with a named tool, and the audit is ported to the planet with a zero-marks failure (`terrain_audit.gd:51` confirmed strip-only).
- C2, variety kinds the classifier can't count: fixed. QA's outcome counter gives every landing one class and is built in step 0.
- C3, packet rows missing: fixed. Section 7 maps every row to a step and a measure, or says why it waits.
- C4, sound and rumble: fixed. Audio joins step 5 with the ground-match measure, and Controls' rumble rows join step 8.
- C5, camera reads: fixed. Camera joins step 5 with zero strip reads and the tall-land probe reading marks.
- C6, 2v2 only a risk: fixed. Section 4.7 and steps 5 and 7 carry the rows, with Netcode and Encounter as owners.
- C7, Accessibility: fixed. Accessibility owns step 7's turns-per-minute and peak-speed measure and the cut setting.
- C8, order and costs: fixed in part. The record list is fixed in step 2 before Rendering bakes, rebake is measured on the reduced store, and costs come from file and gate counts. Rejected in part: the bystander park doesn't land "on its own" as window 1 alone, because its README says not to put it in a played build without window 2. Windows 1 and 2 land together, first.

The plan's token cost so far is about 1.9M tokens, estimated and not metered: five readers about 0.75M, one writer about 0.25M, three checkers about 0.6M, and this edit about 0.3M.
