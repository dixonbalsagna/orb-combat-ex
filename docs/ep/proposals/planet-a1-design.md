# The planet for A1: five sizes, terrain, destruction, clipping

From Orb's stand-in, 2026-11-14, for the EP, then World, Rendering, Camera, Simulation, Netcode, Performance and QA. One technical design for the scope Orb added to sprint A1:

> "I do want the planet, terrain, destruction, clipping all worked on heading towards the A1. Five different planet sizes should be achieved along with this." (Orb, 2026-11-13 night, `docs/ep/vision.md:1804`)

Design only. Nothing here is built or decided by me. Three readers mapped the code and the records (on Opus), and the numbers are from the code's own formulas unless a record is named. **No frame, load or memory reading exists for any size but medium, and none on the 9 November build or later**, so every cost below is arithmetic until Performance reads it in a quiet window.

This page builds on what World and Rendering did tonight. It does not repeat it:
- World: `docs/world/planet-sizes.md` (which five), its park `docs/world/pending/planet-sizes/` (the build, committed during the night in 12e656ec), and the re-cut of terrain step 2 (`docs/world/pending/globe-step2/README.md`).
- Rendering: the first half of the feet fix, parked at `docs/rendering/pending/feet-ground/`.

## 1. In plain words

- **Five sizes: tiny, small, medium, big, huge.** Each is about double the one before. Medium is exactly today's planet. I agree with World's five.
- **Colossal is the one that cannot be built yet.** It needs about 240 MB of memory for the planet's ground alone, and two pieces of engineering that are not built. It stays in the data, switched off. Orb named six sizes on 1 November and said five on 13 November, so which one waits is Orb's call (section 10).
- **The game's rules already play all five,** in World's finished and parked build. What is missing is the picture: the ground drawing is written for medium only. That is the biggest piece of work left.
- **Huge is the risky one.** It works, but as written it wants about 180 MB of memory for ground it mostly never reads, and half a minute into a match before launch forecasts are at full quality. Each has a fix. Nobody has measured it yet.
- **Why fighters look like they clip into the ground:** when a slide carves a trench or a beam cuts a groove, the game lowers the real ground but the picture does not draw the trench. So a fighter standing in one is drawn sunk into ground that still looks flat. That is nine tenths of the clipping. Drawing those marks under the fighters fixes it.
- **Why a fighter bounces off a building like a ping-pong ball:** a launch aimed at a building behind the fight pulls the body back toward it, the wall bounces them off at a quarter speed and freezes the whole fight for a moment, and then they slide back to the fight line in a third of a second. A fix is built and switched off. Orb's recorded answer on it is "Wait until I play it", so the next step is a build for Orb to play.
- **The camera jolt that held the terrain work back has a cause now.** World found it tonight. It can land with one setting off.

## 2. Where things stand tonight

| Piece | State | Where |
| :--- | :--- | :--- |
| Five sizes in the sim | Built and parked: each size plays 600 ticks, tiny and big were run twice to the same result, and medium named equals medium unnamed. The park's diff and two grants are on disk (committed in 12e656ec; its README not yet). `sizes.json`, `size.gd` and `size_check.gd` exist only inside the diff. **It applies only on top of the step 2 park and the default-world park** | `docs/world/pending/planet-sizes/`; `docs/world/runs/planet-sizes/` |
| Sizes in the picture | Not started. The tile ground hard-codes medium's face edge (38,400) and 300 cells | `render/core/tile_field.gd:371, 447, 456, 508-522, 624`; `planet_view.gd:570-575` |
| Terrain step 2 | Re-cut tonight. With the trench settling off, Camera's check passes 130 of 130. Then 14 of 40 matches fail the step's own measure (at most 6 steps over one body height in a match), worst step 152 | `docs/world/pending/globe-step2/README.md` |
| Feet on the ground, part 1 | Parked tonight. Where no trench or groove is involved, feet sit within about 3.5 units of the drawn ground | `docs/rendering/pending/feet-ground/` |
| Trenches and grooves drawn | Not started. This is the terrain plan's step 4 | `docs/ep/proposals/terrain-globe-plan.md` |
| The building rebound | The fix (`cityHold`) is built and held off, "waiting on QA city read". No such read is on file, and part of it is Orb's to play first (section 7) | `tools/preview/switches.mjs:159-167`; `data/biomes/brunt.json:47-50` |
| Frame and load readings by size | None valid. World's timings mark themselves void (shared machine) | `docs/world/planet-sizes.md` |

The audit's A1 brief files do not carry this scope; the sprint page does, and the parks show World was briefed on sizes ("A1 brief item 2") and step 2 ("item 3"), and Rendering on clipping. Whether anyone has been briefed on the picture per size, and whether Animation has an A1 brief at all, is not on file. The EP should confirm.

## 3. The five sizes and what each costs

### 3.1 Which five

Tiny, small, medium, big, huge, as World proposes. Colossal off.

| | Tiny | Small | **Medium** | Big | Huge | Colossal (off) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Columns round | 1,280 | 2,560 | **4,800** | 9,600 | 19,200 | 38,400 |
| Radius, units | 6,519 | 13,038 | **24,446** | 48,892 | 97,785 | 195,570 |
| A lap flat out at base (3,500 a second) | 12 s | 23 s | **44 s** | 88 s | 176 s | 351 s |
| A lap at full power (8,068) | 5 s | 10 s | **19 s** | 38 s | 76 s | 152 s |
| Cities and towns (World's count) | 2 / 4 | 4 / 12 | **12 / 44** | 24 / 88 | 48 / 176 | 96 / 352 |

- World's page gives laps at 5,000 a second. Orb's decision is 3,500 (`docs/design/flight-3500.md`), so the laps are longer than World's table says.
- Orb's first word on scale (29 September) was a lap of "10 to 20 s: anime-fast". At 3,500 that is tiny and small at base power, and medium at full power.
- Tiny and small are 1,280 and 2,560 columns, not the plan's 1,200 and 2,400, because a size must be a multiple of 64 columns for the far ground's grid.
- Places grow with the square root of the area, not the area. A big planet has twice medium's cities, not four times.

### 3.2 Memory

| | Tiny | Small | **Medium** | Big | Huge | Colossal |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Per-column state in a match | 33 KB | 65 KB | **122 KB** | 244 KB | 488 KB | 975 KB |
| One rollback snapshot, columns | 28 KB | 55 KB | **103 KB** | 206 KB | 413 KB | 825 KB |
| One rollback snapshot, buildings (my estimate) | 0.06 MB | 0.15 MB | **0.5 MB** | 1.0 MB | 2.1 MB | 4.1 MB |
| About 21 snapshots held in a LAN match | 2 MB | 4 MB | **13 MB** | 26 MB | 52 MB | 104 MB |
| The ground lattice, one planet | 0.3 MB | 1.1 MB | **3.8 MB** | 15 MB | **61 MB** | **242 MB** |
| The ground lattice as kept today (three planets) | 0.8 MB | 3.3 MB | **11 MB** | 46 MB | **182 MB** | **726 MB** |

- **The lattice is the memory risk, not the match.** `WorldField.of` reserves the whole planet's lattice up front (6 bytes a node, and a byte a cell for refinement) and keeps up to three planets (`sim/world/field.gd:151-167`). It grows with the area. Most of those nodes are never read.
- The per-column figures use 26 bytes a column, counted from the arrays the played build has on. World's page says 35 (672 KB at huge), which counts switches that are off today. Netcode should price from one of the two, and say which.
- **Fix, for World:** keep one planet's lattice from big upward (or reserve a face only when it is first read). That takes huge from 182 MB to 61 MB at once.
- Buildings outweigh columns in a snapshot from medium upward: about 117 bytes a building, and planet 7 holds about 4,400 at medium. The building counts for other sizes are my estimate from World's place counts; Netcode should price them from a real run.
- A snapshot is taken before every predicted tick and about 21 are alive at once (`net/session.gd:45-46`). At huge that is about 2.5 MB copied a tick. I expect that to be fine, and it needs Netcode's reading.

### 3.3 Ticks

**No loop in a normal tick covers the whole planet** on the path the played build takes, which fits World's flat tick times (0.3 to 1.2 ms at every size, void as a measurement). What grows:

| Work | Why it grows | Tiny | Small | **Medium** | Big | Huge |
| :--- | :--- | ---: | ---: | ---: | ---: | ---: |
| The launch ceiling table is ready after | It fills 8 tiles a tick; tiles grow with the area, less at huge because its far grid is coarser (`sim/core/field.gd:674-716`) | 0.2 s | 0.8 s | **2.8 s** | 11 s | **about 31 s** |
| The warm-up sweep finishes after | 8 coarse columns a tick (`field.gd:496-535`) | 0.3 s | 0.7 s | **1.3 s** | 2.5 s | 5 s |
| Marks re-laid after the world turns | 100 columns a tick (`sim/core/swing.gd:464-500`) | 13 ticks | 26 | **49** | 97 | 193 |
| The state check at each LAN checkpoint (every 60 ticks) | It reads every ground column and every building (`hash.gd:303-350`) | | | 190 to 206 ms with 3,565 buildings, measured before a later speed-up; today's cost not on file | | about 4 times medium's |
| Loops over every building | The swing's pose list every 8 swing ticks; the launch planner's line scan | | | | 2 times | 4 times |

- **Until the ceiling table is ready, launch forecasts fall back to a simpler ground read.** At huge that is the first half minute of a match. Fix: fill it during loading, or fill the tiles near the fighters first.
- **The LAN state check is the one tick cost that could be felt.** If today's medium cost is still near 200 ms, huge would stall for most of a second once a second in a checked LAN match. Netcode should measure it at medium first; the fix is to check only what changed.

### 3.4 Loading

| | Tiny | Small | **Medium** | Big | Huge | Colossal |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Far-ground grid spacing in World's park | 512 units | 512 | **512** | 512 | 1,024 | 2,048 |
| Far-ground grid nodes to bake | 2,646 | 10,086 | **34,656** | 136,806 | 136,806 | 136,806 |
| First bake, the desktop game (47 to 68 millionths of a second a node) | 0.1 to 0.2 s | 0.5 to 0.7 s | **1.6 to 2.4 s** | 6 to 9 s | 6 to 9 s | 6 to 9 s |
| The same in a browser (2 to 3 times slower, an estimate) | under 1 s | 1 to 2 s | **3 to 7 s** | 13 to 28 s | 13 to 28 s | 13 to 28 s |

- The bake grows with the area, so World's park already bakes huge on a grid twice as coarse and colossal on one four times as coarse (`sizes.json` `bakeStride`). That keeps their first bake at big's. The coarser far ground is a look to check at huge.
- It is cached on disk after the first time, per planet. World's own cold starts at huge (7.9 to 9.7 s, void as measurements) fit these figures.
- **A random planet each quick match (Orb's accepted decision 2) means a first bake every match.** At medium that is 2 seconds. At big and huge it is 6 to 9 seconds before every match, more in a browser.
- **A fix, for World:** give quick match a small pool of planets per size so the cache hits. World's default-planet work already draws from a pool of 5 planets by 3 landing spots.
- **A trap for replays:** reading a saved match's header finishes the whole bake before it can say whether the file plays here (`sim/core/field.gd:99-124`, `keyHash`). At big and huge that is 6 to 9 seconds just to refuse a file.
- Records for scale: the desktop game's last measured start was 14.5 to 15.2 s cold and 5.1 s warm (27 October, before the globe ground and the menus). The audit's working target is 15 s from "start match" to control on Orb's PC.

### 3.5 Frames

- **Nothing is measured.** No size but medium has ever been drawn, so nobody knows.
- **What I expect, to be proved:** near the fighters the frame cost should be about flat, because the tile ground draws a fixed set of rings around the camera whatever the planet's size. What may grow: far-city counts and the whole-planet view (both hard-coded to medium today).
- Orb tied sizes to frame rate on 9 November: "lets see how the impact to framerates work". So the reading is part of the feature, not an extra.
- ADR 0013 names no target machine, so "holds the shipped quality on Orb's PC" has no number in the sprint. The nearest are the audit's working targets: 60 frames a second held and no frame over 50 ms outside loading. I would read each size against those and report, not gate.

### 3.6 What must be true before a size is offered in a menu

1. **World's park is reviewed and applied,** on top of the step 2 and default-world parks it stacks on, with `size_check` wired where it runs.
2. **One stale number is fixed.** `sim/world/waterrec.gd:106` has medium's face edge, 38,400, written as a number, and the park's diff does not touch it. (The park does fix the two other values that were computed once at load: `SimField.R` and the meteor's `R_PLANET`.)
3. **The lookup grids hold.** The store's and the water records' grids mix up distant boxes past a radius of 65,536 (huge is 97,785); World's page says its build takes the offset from the radius and has a negative control for it. `SimField._boxKey` breaks past 131,072, which is why colossal is off.
4. **Six cache keys carry the size** (planet, field, slice, the match-key hash, two disk caches). World's page says they do when the size is not medium.
5. **Rendering draws it** (section 3.7).
6. **Performance has read it** in a quiet window on the desktop build: frame record, first and later load, memory.
7. **Netcode has priced it:** the snapshot, the state check, and that two PCs with different sizes cannot connect (the setup is in the handshake key already, so a `planetSize` key rides along).
8. **LAN can pick a size, or stays on medium.** `net/lan.gd:30` fixes the LAN setup with planet 7 and no size. Either it gains `planetSize`, or LAN stays medium for Alpha (decision 13 limits Alpha LAN to the trusted two PCs).
9. **Camera has looked at big and huge.** The peak-launch shot widens with the ring: `PEAK_RING` is 153,600 (`render/camera/camera_params.gd:357`) and `split_rig.gd:5180, 5258, 5353` scale by the ring over it. At huge that is 4 times wider; at tiny about a quarter.
10. **There is a way to pick one.** A menu row is UI's; and someone rules how a random quick match chooses its size.
11. **The tests that pin medium stay on medium.** The golden record, `arena_check`, `parity` and `qa_planet` name today's planet. That is right, as long as medium named plays exactly like medium unnamed.

### 3.7 The picture at each size (the biggest unbuilt piece)

- `render/core/tile_field.gd` writes medium's face edge and cell count as numbers in at least eight places, `planet_view.gd` at `:570-575`, and `render/core/look.gd` has far-city counts for medium.
- **Step one is mechanical:** read the size from the match, as the sim now does. I would expect big and huge to draw correctly after that, because the tiles are rings around the camera.
- **Tiny and small are a look question, not a code one.** A tower 4,875 units tall on a planet of radius 6,519 will read as a spike on a ball, and the horizon will curve hard. World's plan said tiny waits for a cap on relief from Art. Somebody has to look at a still of tiny before it is offered.
- Every size's first picture goes through the look gate, with a side-by-side for medium to show nothing changed.

### 3.8 Distances that do not scale

Every gameplay distance is absolute, so a bigger planet is simply more ground. Most of that is right. Three to rule on, for Game Design:
- **Launches.** A top-tier launch that crosses a fifth of medium crosses a twentieth of huge. On tiny the same launch can lap the planet.
- **A 2v2's second fight** is placed half a lap away: 307,200 units on huge, a minute and a half of flat-out flight to reach your partner.
- **The beam.** Today's beam reaches up to 33,600 units, which is 82% of the way round tiny. (The beam-in-space design shortens it to at most 10,200.)

## 4. Terrain step 2 and the camera jolt

**What happened.** With step 2 applied, Camera's `chase_rush_check` failed 4 of 130 rows: a jolt of 0.137 to 0.153 at the tick-96 split, against a limit of 0.10 (`docs/ep/runs/6a30b4c9/chase-rush-fail-with-globe.log`).

**World's finding tonight:** the cause is the trench settling. A slide's trench is stored 121 to 152 deep and 64 across; settling widens it to about 70 and shallows it to about 60, so the ground the landing body slides on is about 65 units higher. With `globe.settleGrooves` off, the check passes 130 of 130.

**One step further, from reading the code (plausible, not run):** the jolt is not a jump in the drawn ground. The check never draws; it reads fighter positions through the camera rig. World puts it the same way: "the jolt is the camera splitting harder at the landing, not a wrong picture". Two of the four failing rows also show the world turning; the other two do not, so a turn is not the whole cause. What all four share is that the settled trench changes where the sliding body ends up.

Why the trench's shape can move a slide at all:
- `WorldSlide.step` puts the slider on the ground at its new place, then carves the trench segment behind it (`sim/world/slide.gd:121-141`).
- The stored segment has rounded ends that reach half its width past the slider's own position (`sim/world/store.gd:309-323`).
- Late in a slide, when a tick's movement is shorter than that half width, the next tick's ground read lands inside the end of the slider's own trench. The slope test compares two points on that rounded end, so it only just passes the "cliff" limit (about 1.03 against 1.0 for a 121-deep trench at 8 then 6 units a tick), and only very late in a slide. When it does, the slider is thrown into the air (`slide.gd:126-132`).
- A second trigger: a tick that stays inside one column carves nothing (`crater.gd:611-613`), so the end of a slow slide is a chain of short trenches with gaps and ridges between them.
- A wider trench pushes that end further ahead. That fits World's note that widening alone also failed.
- **This behaviour is already on main** with the unsettled trench. Nothing tests for it.

**What I would do:**
1. **Land the re-cut as it is** (settling off). It meets the sprint's line, "re-cut so Camera's check passes", and it brings in the capped shafts.
2. **Then find out, before fixing:** log the slope test tick by tick on the four failing rows, settling on, with the check's own trace switch. That says whether the trench's end or the one-column gaps throw the slider.
3. **Two candidate fixes, each with a cost to weigh:** (a) the slider's ground read ignores the last segment of its own trench: but then the slider's height differs from the ground every other reader sees (shadow, feet, camera, checks), and once trenches are drawn the slider floats over its own trench and fails the feet gate; (b) the segment is carved only up to the slider less half a width: but the trench then ends 32 units short unless the next segment starts where the last ended and the slide's finish carves the last piece. Either changes the store, so the hash of every round-planet match with a slide and the globe audit's counts, even with settling off. If one passes the four rows, settling can come back on and the step's own measure (at most 6 steps over a body height: 0 of 40 matches over with settling on, 14 of 40 with it off) is met too.
4. **Add the missing test:** a slide on flat ground never leaves the ground because of its own trench.
5. If neither candidate works, the fallback is the terrain plan's step 3, where trench widths are set by force and Camera re-tunes in the same window. The sizes park stacks on the step 2 park, so a re-cut of step 2 means a re-cut of sizes.

Both steps change the hash for the round planet, so both land in a window after the golden record is proven.

## 5. Destruction drawn where you stand

Decision 3, accepted by Orb: Alpha gets craters and trenches drawn where you stand; the mesh and tessellation overhaul is after Alpha.

**What is drawn today, against what the game stands fighters on:**

| Mark | In the game's ground | In the picture |
| :--- | :--- | :--- |
| A crater | The whole bowl, at once | Only the 16 craters nearest the camera's pivot (`render/core/look.gd:596`), re-picked every 15 frames, each opening over a quarter second. So bowls pop in and out, and a far crater a fighter flies to may not be drawn |
| A slide's trench | Up to 152 deep (two body heights) | **Not drawn** |
| A beam's groove | 33 to 103 deep | **The shape is not drawn.** Only its burn colour is |
| The black crater | | That burn colour, filled one tone a vertex on coarse tiles. Art's crater look fixes it; it is on in Orb's builds and off on main |

**So the design for A1 is narrow: draw the marks that are under the fighters.**
1. **Pick craters by the fighters, not only by the camera.** Every bowl within a few body heights of any fighter is always in the drawn set of 16, before the nearest-to-camera ones. That ends the pop under a fighter.
2. **Draw the trench and the groove.** One trench is not one shape: a slide adds a stored segment on every tick that crosses a column, so a trench is dozens of records (`sim/world/store.gd:287-288`). Two ways:
   - **Rendering's own plan, and the main option:** bake the store's marks into the tile heights, with the feet lift reading the same function (`docs/rendering/pending/feet-ground/README.md`, its last section). It has no cap on the number of marks.
   - **The alternative:** add a capsule to the shapes the vertex stage already evaluates for bowls. Bowls go up as two arrays of 16 (`render/shaders/tile_read.gdshaderinc:17-19`; set at `render/core/tile_ground.gd:283-286`), so this only works with segments merged into a few long capsules, and it has to be priced against the browser's limit on vertex-stage values.
   Either way the depth profile should come from one table that both the sim and the drawing read, so they cannot drift apart.
3. **Keep the quarter-second opening for the look, but not under a standing fighter.** A mark that opens under a fighter is drawn at full depth at once.
4. **Collapsed buildings' rubble** is laid on the old strip columns with no stored record, so it slides with the fight line when the world turns. It stays consistent with itself. Fixing it properly is the terrain plan's step 5 and is after A1.

**What it costs and risks:**
- It is vertex-stage work on meshes that exist: no new passes and no reading back from the graphics card. ADR 0010 still wants Performance's timing on the browser build before it lands.
- It changes what the player sees, so it goes through the look gate with a side-by-side, and through the EP's safety readings as any look change does.
- The audit placed this work (A-WORLD-05) at the fifth milestone, under Rendering. The sprint places it in A1, under World with VFX. Rendering's feet park already says part 2 is its next job. **Someone should write down that it is Rendering's, in A1, cut down to "under the fighters".**

## 6. Feet on the drawn ground

- **Part 1 is done and parked** (Rendering, tonight). Three causes fixed: the lift table was not read for the fighter's own column; the lift was measured against a coarser ground read than the sim's; a crater made before the first frame was drawn twice. Where no trench or groove is involved, feet sit within about 3.5 units of the drawn ground. It changes no hash.
- **Part 2 is section 5.** Of the 875 bad samples left, 796 are fighters standing in a trench or a groove that is not drawn, sunk by up to 216 units.
- **Make the probe a gate.** Rendering's `feet_check.gd` is a scratch script. In the repo, as a render gate: 10 seeds, 1,800 ticks each; no standing fighter's drawn feet more than 8 units from the drawn ground. Today no gate compares the drawn ground with the game's ground during play: `tile_check` reads the base field once at the start, within 30 units, and `ground_check` covers only the old strip ground.
- **Sinking into a crater or a building** is three different things, and only one is a bug:
  - A hard impact that buries a fighter in a crater is a feature Orb asked for (2 October).
  - A crater dug under a standing fighter: the game drops them to the new ground on the next tick. With section 5's point 3 the picture drops at the same time.
  - A fighter inside a drawn building: the game's building boxes and the drawn buildings are checked against each other by `shape_check` (no drawn wall taller or wider than the game's). I found no report of this one from Orb's play; QA should name a case before anyone builds for it.
- The shadow and the foot placement read the game's ground, so they also sit below the drawn surface in an undrawn trench. Section 5 fixes them with no further work.

## 7. Buildings: the rebound

Orb, 14 November: "the behavior where a fighter bounces off something in the background and then ricochets in an unrealistic and immersion-breaking trajectory is something I want squashed as we head to A1." (The knock, zip round, knock again chain in the air is the feature to keep. It is a different system and nothing here touches it.)

**It is not the ricochet code,** which is switched off. From the code:
1. A launch aimed at a building up to about 2,200 units behind the fight line eases the body's depth toward that building's face (`sim/world/brunt.gd:855-868`). This runs even with depth off, because `stepZ` has no depth test (`brunt.gd:871-880`).
2. At a face that holds, the body's speed is reversed at a quarter (`wallRebound` 0.25) and the whole fight freezes for the hit (`wallStop` 1, `lodgeHold` "world") (`brunt.gd:1027, 1087-1088, 1144`).
3. The flight ends, and the body's depth eases home to the line in about a third of a second (`brunt.gd:876-879`).

So the body comes off a building drawn far behind the fight, flying back toward the camera and backward along the line at once. No wall gives that path.

**The fix exists.** `cityHold` sets the rebound to 0, holds the body's depth at the face, stuns only the body and not the fight, drops the whole-fight freeze, and sets repeat marks to 2 (five values in one switch row: `tools/preview/switches.mjs:165-166`). It has its own test (`sim/world/tools/wall_hold_check.gd`). It is held "waiting on QA city read", and I could find no such read in `docs/qa` or `docs/ep`.

**And part of it is Orb's to play first.** On what the other fighter does while one is lodged in a building, Orb's recorded answer is "Wait until I play it", with the note that holding only the lodged fighter is good if it gives the attacker openings (`docs/ep/vision.md:1862`, `:1355`). The code calls that setting "Orb's homework". So this is not the team's to switch on.

**What I would do:**
1. **QA does the city read now,** on a scratch copy with `cityHold` on: 40 matches on planet 7, counting rebounds off a building behind the line (pass: 0), bodies left stuck in a wall for more than a second (pass: 0), and match length.
2. **A private build with `cityHold` on goes to Orb to play,** with a side-by-side clip of one launch into a tower. It is switched on for main only on Orb's word, in a window after the golden record. The audit recommended the same: one private build with the held rows on and one play session.
3. **Then Orb's other half:** on 6 November Orb hoped "the camera angle [would] change and then be able to press the fight into the city". That is `slamTurn` (a wall slam turns the fight line up to 45 degrees into the street behind), built and held with `cityHold`. It moves the camera, so Camera judges it first. I would not put it in A1.
4. **Buildings breaking at every tier** already has rules by tier in data (`brunt.json`: a house always collapses; a tower dents, cracks or is punched through by the ratio of force to floors, and base-tier bodies punch through none). The audit's measure for it (no base-tier fight wrecks the planet; a top-tier blow leaves a measurably bigger mark) is set for the third milestone. Nothing to add for A1.

## 8. The order of work

Everything here that changes the game's state lands **after the golden record is proven** (GW1a), each in its own window, as the sprint says.

| When | What | Who | Hash | Look gate |
| :--- | :--- | :--- | :--- | :--- |
| Now, on scratch copies | The sizes park reviewed (section 3.6, points 1 to 4); it applies only on top of the step 2 and default-world parks | World, then the landing review | | |
| | The city read for `cityHold` | QA | | |
| | The slope log on the four failing rows, then the slide trial | World, with Camera | | |
| | Tile ground reads the size; stills of all five | Rendering, Art for tiny | | |
| First window after GW1b | Feet, part 1 | Rendering | no | yes |
| | Terrain step 2 re-cut, settling off | World | yes | no change meant |
| | A private build with `cityHold` on, for Orb to play (not on main until Orb says) | World, Tools | | |
| Second window | Sizes in the sim, medium the default, the others reachable by a setup key only | World, Simulation, Netcode | yes for the other sizes; medium identical | |
| | Marks under the fighters (section 5) and the feet gate | Rendering | no | yes |
| | The slide fix and settling back on, if the trial passed | World, Camera | yes | yes |
| After the first desktop build | Frame, load and memory per size in a quiet window; the snapshot and state-check prices | Performance, Netcode | | |
| Then | Sizes in the picture; the menu row; huge's three fixes or its warning | Rendering, UI, World | | yes |

**What can be reached in A1, as I see it:** all five generate and play in the sim and can be picked; medium, big and small are drawn and read; tiny and huge are drawn, with their open problems written down. That is short of the sprint's own line, that each size "generates, plays and holds the shipped quality on Orb's PC", and short of the EP's proposed done test ("five sizes selectable, each generates and plays, frame cost read in a quiet window") until Performance can read frames. Shipping tiny and huge with open problems would be a change of scope, so it is a question the EP would put to Orb, not a reading for anyone else to settle. Either way the picture per size is the piece that needs briefing first.

## 9. Risks

1. **The picture per size has no owner in any brief.** It is the largest piece.
2. **Huge's memory and its first half minute** (182 MB of lattice as kept today; launch forecasts at reduced quality for about 31 s). Fixes exist; none is built.
3. **A random planet every quick match pays the first bake every time:** 2 seconds at medium, 6 to 9 at big and huge, more in a browser.
4. **No valid reading exists at any size.** Performance's bench waits for the first desktop build, which waits for the golden window. The sizes can be built before they can be measured.
5. **The LAN state check** may already be near 200 ms at medium. It should be measured before sizes multiply it.
6. **Step 2's settling trade.** Landing it with settling off passes Camera and fails terrain's own measure. That is acceptable only if the follow-up trial is real work with an owner.
7. **Drawing marks under the fighters is a look change on the globe ground,** which has open safety readings of its own. The EP holds that thread.
8. **Three hash windows** for this scope beside the sprint's own. Each needs its gate run and its saved matches re-recorded.
9. **Tiny may not look like a planet** until Art caps its relief.
10. **What I could not verify:** today's cost of the LAN state check; building counts at sizes other than medium; anything about frames; whether the coarser far ground at huge shows.

## 10. For Orb

A draft for the EP. One question.

> **Which five planet sizes?** You named six on 1 November: tiny, small, medium, big, huge and colossal. Five can be built now: tiny to huge. Each is about double the last; medium is today's planet. Colossal is the one that cannot be built yet: it needs about 240 MB of memory for its ground alone, and two pieces of engineering that are not built.
>
> **A. Tiny to huge now, colossal later** (what I think you would want). Colossal stays on the list for after Alpha.
>
> **B. Small to colossal.** Tiny is dropped, though you named tiny as the way for the least powerful laptop to play. Colossal waits anyway until it can be built, so for now you would have four.

Two things to tell Orb with it, in plain words: flying once round at normal top speed takes about 12 seconds on tiny, 44 on today's planet and nearly three minutes on huge; and a big or huge planet takes several seconds to make the first time, which nobody has measured yet.

## 11. Checks, and the cost of this page

One independent reviewer (on Opus) read the draft against the code, the parks and the records, and returned 12 findings. I checked the three largest against the files myself before using them. All 12 were used:

| Finding | What changed |
| :--- | :--- |
| World's park already bakes huge and colossal on a coarser grid, so my load times for both were four and sixteen times too long | Section 3.4 redone; huge's ceiling time corrected; colossal's reasons restated |
| Orb's recorded answer on a fighter lodged in a building is "Wait until I play it"; I had the team switching the fix on | The fix goes to Orb as a private build; the switch's fifth value is listed |
| World's park was on disk (it was committed while I wrote), and it fixes two of the three stale values | Sections 2, 3.6 and 8 corrected; the park's stacking order added |
| I misread the failing log: only two of the four rows turn the world | Section 4's reading corrected |
| My slide fix had side effects and missed a second trigger | The mechanism softened; a log first; both candidates listed with their costs |
| A trench is dozens of stored segments, and Rendering already has a plan for drawing them | Rendering's plan is the main option |
| "No brief carries this scope" contradicted the parks | Restated as what is and is not on file |
| My narrower reading of "achieved" was a scope change | Said so; it is the EP's to put to Orb |
| The question for Orb had a wrong fact, an unmeasured one, and left out Orb's reason for tiny | Rewritten |
| Three things a selectable size needs were missing: LAN, the camera's launch shot, a way to pick | Added to 3.6 |
| The first window is after GW1b, not GW1a | Corrected |
| Small slips: the step measure's wording, three feet figures, which sizes ran twice, 26 against 35 bytes a column, team words in section 1 | Corrected |

Cost: about 1.9M tokens. Three readers (0.9M) and one reviewer (0.2M), all on Opus; the rest was this session.
