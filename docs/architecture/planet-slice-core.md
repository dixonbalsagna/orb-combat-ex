# The planet slice: the sim's side (paper, with a scratch proof)

Owner: Simulation and Engine. 2026-10-16. This is the core's answer to World's `docs/world/planet-slice.md` (63865612): what a match on a slice of a stored planet needs from the replay, the hash, the golden and the determinism rules, and how a run's damage can enter a match. **Paper and scratch only: nothing in `sim/` or `data/` changed.** The proof scripts are in `planet-proof/`, beside this page.

## 1. The answers in short

| Question | Answer |
| :--- | :--- |
| What moves into the replay | **World generation's inputs move into `setup`, which the replay already stores verbatim, so the world becomes a function of the setup.** Three keys, each an integer or an id: `planet` (the seed, or a story planet's id), `touch` (the touch-down draw) and `pick` (the candidate circle the picker chose, kept as a check). One new header field, `world`: the hash of the slice as read at tick 0. The planet's data file joins the replay's data hash. No float in the header |
| Bit-exact across GDScript and JS | **Yes, with zero tolerance, if the planet function follows the core's rules** (float64 scalars, SimDetMath, integer hashing; no `Vector3`, no inverse trig). The scratch port agrees on **1,000 of 1,000 points to the bit** (each point's three coordinates, its elevation and its biome) and on a full 4,800-column slice, both as computed and as stored (float32) |
| The tolerance we need | **Zero: bit for bit.** World's 0.003 is float32 noise from `Vector3` arithmetic, not a property of the function: in float64 the same point reached along two circles agrees to 7.5e-12 units. Read through `Vector3`, every column's height differs from the float64 read, and 1 slice in 40 has a column whose biome flips |
| The golden across World's windows 2 and 3 | **The setups without a planet keep today's `genWorld` (Bellgate), so no existing match, replay or tick-0 vector moves in windows 1 to 3.** Each window adds its own keys in one regeneration. Making a planet the default match is a separate commit that does nothing else: the one re-baseline, with QA's before-and-after |
| A run's damage | **Outside the match, as data: a wear list per place, in the place's own frame, in whole numbers.** A stage's setup carries it; `newMatch` lays it on the slice before tick 0, so a stage's start state is still a pure function of its replay header. At a stage's end, the match's marks are turned back into place-frame records by a pure function with its own golden vectors |

## 2. What a match on a planet is, for the core

Today `SimCore.newMatch` calls `WorldTerrain.genWorld(S)` before it reads the setup. `genWorld` is fixed: its own `SimRng(4242)`, the hand-made biome order of `WorldBiomes.biomeAt`, the settlements and lanes from their data. The world is the same in every match, so a replay says nothing about it: the code and the data hash define it.

With a planet, the world is a function of three things, all in `setup`:

| Key | What | Type |
| :--- | :--- | :--- |
| `planet` | The planet: a seed (a procedural planet), or a story planet's id in World's `data/biomes/planet.json` (a fixed seed and a hand-placed list of places). Absent: today's Bellgate, through `genWorld` as it is | integer below 2^32, or a string id |
| `touch` | The touch-down: the draw the picker starts from (a story level names a place instead: `{"place": id}`) | integer below 2^32, or a dictionary of ids and integers |
| `pick` | The candidate circle the picker chose: its index in the picker's seeded order. The picker is re-run on playback; this is the check that it chose the same | small integer |

- **Why the picker's inputs and not its outputs.** The outputs are a point and a circle (six float64 numbers). A JSON number round-trips a float64 only if it is written with 17 significant digits, and the replay already avoids that question for intents (it splits them into two integers). The picker is pure and costs 70 to 110 ms, so re-running it is cheap.
- **The host draws `touch`, not the sim.** It is outside the match's seed, as the slots are: QA's fixed-planet baselines keep one touch-down and vary the seed, and a story level names its place.
- **`world` in the header.** The hash of what the read produced at tick 0: every column's height (as stored, float32) and biome, and the buildings placed. Playback rebuilds the slice and refuses a replay whose `world` differs, with the reason `"world"`, as it refuses changed data with `"data"`. It is the guard that catches a build reading the planet differently: a platform, a compiler or a changed function. A replay without the field (every replay today) is not checked, so the format stays at v4.
- **The data hash** gains `WorldPlanet.dataHash()` (World's generator numbers and story planets), as World's other files are folded in today.
- **The gameplay hash** already covers `S.deform` and the buildings each tick. `S.base` is not hashed, because today it is a constant. With a planet it varies by match, so it gets **a world hash of its own** (`S.base` as stored, the columns' biomes and the buildings at tick 0): the golden's planet keys and the replay's `world` field read it. It does not join the per-tick gameplay hash: that would add the same 4,800 values to every vector and move the whole golden, Bellgate's included, for no gain (the base never changes during a match).
- **Order in `newMatch`:** the setup is read first, then the world is built from it: today's call order changes in window 2.
- **Cost.** The read is about 1 s in GDScript on this PC while busy (the scratch's float64 read of 4,800 columns, height and biome: 1.04 s; World measured 0.9 s with `Vector3`). `newMatch` runs for every golden case, every parity check and every QA match (`batch.gd` plays about 350 a minute today), so the slice is **memoised outside the sim state**, keyed by the planet, the touch-down and the data hash: the read is pure, so a cache cannot change a match. A host can read the slice during the touch-down's cinematic, before tick 0, since nothing in it depends on the match's seed.

## 3. Bit-exact: the rules for the planet function, and the proof

The planet function becomes sim code (World's `WorldPlanet`), so it follows the determinism rules (`determinism.md` section 0). World's prototype (`docs/world/scratch-build/planet-slice/planet_lib.gd`) breaks three of them, and the proof shows what each costs.

| Rule | In the prototype | In the sim |
| :--- | :--- | :--- |
| **float64 scalars, no engine vector types.** `Vector3` is float32 in a standard Godot build, and its operations are engine C++, whose compiler flags and vector paths are not ours | Points, rotations and crosses as `Vector3` | A point is three `float`s. Cross, dot and normalise are written out, as `planet.mjs` and `p64lib.gd` do |
| **Only + - * / sqrt floor in arithmetic; `SimDetMath` for sin and cos; no inverse trig** (engine libm differs by platform) | The picker uses `asin`, `atan2` and `acos`; the crossing test `atan2` | Distance from the line: compare `n · o` with `SimDetMath.sin(reach / R)`. Position along the line: the column whose point is nearest the place (largest dot; ties to the lower column). A city's rings: chord distance `R * |p - o|` (sqrt only), which differs from the arc by under 0.3% within a city's 6,500 units. If arcs are wanted, a `SimDetMath.atan2` built like `sin` (with golden vectors) is the alternative |
| **The JS-exact helpers** | `clampf`, `absf` | `SimMathx.jclamp`; `absf` is exact and stays |
| **Integers** | The lattice hash on 64-bit ints, masked to 32 bits | As is. A port to a language whose bitwise operators are 32-bit (JS) masks with `>>> 0`, and the lattice coordinates must stay below 2^31 in magnitude (today they reach about 11; even a detail octave at the 32-unit column scale stays far below) |
| **Storage** | | Heights computed in float64 and stored as today, float32 (`S.base`): IEEE's round-to-nearest, the same everywhere (`Math.fround` in JS) |

**The proof** (`planet-proof/`). World's function (its four noises and its thresholds), written three ways: in JS under the core's rules (`planet.mjs`, the frozen core's own `detmath.js`), in GDScript under the same rules (`p64lib.gd`), and World's prototype as it is (`planet_lib.gd`, `Vector3`). Ten great circles through ten hashed touch-downs, 100 columns each, spread over the 4,800 (the five biomes: 292 ocean, 292 plains, 228 forest, 78 desert, 110 mountains):

| Compared | Result |
| :--- | :--- |
| JS against GDScript, float64 scalars | **1,000 of 1,000 points bit-identical**: the point's three coordinates, the elevation and the biome. A full 4,800-column slice hashes the same (`3ff71909`), and so does the slice stored as float32 as `S.base` stores it (`6e41e11e`) |
| World's `Vector3` read against the float64 read | **Every one of the 1,000 elevations differs,** by up to 0.0026 units (the point by up to 1.5e-7 of the radius, 0.0036 units). No biome flipped among these 1,000 points; the nearest was 0.024 units from the sea line |
| The same, over 40 full slices (192,000 columns) | **1 column changes biome,** in 1 slice of the 40; the largest height difference is 0.0052 units |
| World's crossing test (one point reached along two circles), in float64 | Elevations agree to **7.5e-12 units** (World's `Vector3` test: 0.003) |

**The tolerance we need is zero.** The slice's heights and biomes are tick-0 state. Every ground contact, crater, slide and building placement reads them, so a one-ulp difference in a stored height changes the gameplay hash, and a biome is a threshold of a continuous value: near the line, any error flips the column's kind, and with it its buildings and people. "Close" is not a property a lockstep can use. Bit-exactness is what the rules above give, and the proof shows it holds across two languages.

The two-circle agreement is not a parity question (parity is the same point computed the same way on two machines). It matters only where two different slices must agree on one place, which is the run's damage (section 5): there the damage lives in the place's frame and is sampled, so no rule asks two circles for the same bits.

**Where the oracle lives (ADR 0006).** The JS core is frozen and is not a gate. The planet does not get a JS twin in `sim/core`. The gate is the golden file: `WorldPlanet`'s elevation and biome bits on fixed points and the slice hashes, checked by `parity.gd` on Windows locally and on Linux in CI, which build Godot differently. The JS port here is a one-time proof that the function is portable: a future second implementation (a native sim for rollback, a web-only build: ADR 0006's "revisit if") needs exactly that. The web build and an ARM or macOS runner are still unproven targets for the whole sim (ADR 0006), and a planet makes the world part of what they must agree on.

## 4. The golden across World's windows

The rule: **no window regenerates for two reasons, and the default match does not change in the same commit as code.** With the planet behind `setup.planet`, and its absence meaning today's Bellgate, the existing golden stays byte-identical through windows 1 to 3; each window adds keys.

| Window (World's) | What the golden gains | What moves | Proof |
| :--- | :--- | :--- | :--- |
| 1: the planet function, places and picker (`WorldPlanet`, pure) | `planet`: the elevation and biome bits of 64 fixed points on two planet seeds; the picker's choice for 8 touch-downs; the places list's hash | Nothing else | Every existing check passes on the committed golden, unregenerated; after the one regeneration, `golden_cmp` lists only the new key |
| 2: the slice read for setups with a planet (heights, biomes, mountains, settlements by their list) | `planetSlice`: three (planet, touch) slices' hashes; tick-0 states for two planet setups; one AI match of 3,600 ticks on a fixed planet | Nothing else: Bellgate is `genWorld` as today | As window 1. The new match's light digest is read twice (two runs, same bits) |
| 3: a city from its plan (rings, wedges, landmarks into the lanes and rows) | Nothing new | **Window 2's keys only** (their buildings change) | `golden_cmp`: only window 2's keys move |
| 4: the touch-down in the setup, `world` in the header, the demo as a story touch-down | A human-input replay on a planet, with `world` in its header | Nothing else, if the demo stays a setup without a planet | A replay with a wrong `world` is refused; one from today plays |
| **Later, its own commit: a planet becomes the default match** | | **Every match, replay and tick-0 vector.** The one re-baseline, alone, with QA's before-and-after on the fixed planet | |

If instead `genWorld` is removed in window 2 (World's table reads that way), every key moves in window 2 and again in window 3, and each regeneration mixes the new world with whatever else that window changes. Keeping Bellgate as a setup without a planet costs nothing (it is today's code) and makes each window's proof clean.

QA's measurements are per planet seed (World: one fixed planet for baselines, a random-planet arm for coverage). `batch.gd` would take `--planet=` and `--touch=` like its `--a` and `--b`.

## 5. A run's damage: outside the match, entering at a stage's start

Orb's run mode (`docs/ep/vision.md`; Game Design is designing it): stages on different slices of one planet, cities staying damaged until the final fight. The core's constraint is one sentence: **a match's state at tick 0 is a pure function of its replay header.** So a run's damage cannot live in a match; it enters each match as data, and a replay carries it.

**The wear list.** For each place (a city or a town of the planet's list, by its id), the marks it carries, in the place's own frame and in whole numbers:

| Record | Fields (integers) | Laid on a slice as |
| :--- | :--- | :--- |
| Crater | offset east and north of the place's centre (units); radius, depth and rim (in 1/16 units); cause | Each column within reach of it on the line samples its bowl at its distance from the crater's centre; a crater off the line falls in a depth row (`deformZ`) or the backdrop |
| Building | the building's index in the place's plan (the plan is seeded, so the same buildings recur), its stage (standing, damaged, levelled, a heap) | The building, where the slice places it, starts at that stage |
| Scorch and crack | offset, length, width, the biome variant | As the craters, on the columns they reach |
| The people | the place's living share, in thousandths | The place's people, scaled (Game Design's to rule; see below) |

- **The frame.** A place's frame is its centre and an east and north tangent at the centre, built from the centre and the pole by the rules above (float64, sqrt only). A column's offset in it is the dot of its point with the two tangents, times R. Two slices through one city read the same records at their own columns; nothing asks them for the same point. World's 0.003 between two circles (float32) or our 7.5e-12 (float64) never enters.
- **Whole numbers** make the list exact in JSON, trivial to hash, and the same in any language.
- **Size:** a crater record is about 7 integers; with a cap per place like the craters' 400, a place carries at most a few KB, and a run touches a handful of places.
- **Into a match:** the stage's setup carries `wear` (the list for the places the slice crosses, embedded, so a replay plays without the save file). `newMatch` lays it after the slice is read and before the people are placed. `world` in the header then covers its effect.
- **Out of a match:** at a stage's end, the match's persistent marks (`S.craters`, `S.slides`, `S.crack`, the buildings' stages, the casualties) are turned into place-frame records and merged into the run's list: a pure function of the final state, written by the core's rules and given golden vectors, so that a whole run replays (each stage's replay, then the extraction, then the next stage) on any machine. Merging keeps the list bounded: past the cap, the oldest craters of a place fold into one shallow record.
- **Where the run lives:** a run state (the run mode's save, outside `S`): the planet, the wear list, the stage and the story's flags. The sim never reads it; the host builds each stage's setup from it.

**For Game Design** (the run's rules are theirs): whether a damaged city's people are fewer in later stages, which moves the collateral budget (`pop0` is 1,800 an arena today) and with it the menace and the anguish; whether the meters or the forms carry over between stages; and what the final fight's "world-catastrophe" marks (a crust beam, a darkened sky) leave in the list, since a mark that reaches past the slice (the sky) is a planet-wide record, not a place's.

## 6. What it costs the core, by window

| Window | Core lines | Golden |
| :--- | :--- | :--- |
| 1 | None in `sim/core`: `WorldPlanet` is World's. Parity gains its vectors check | New key |
| 2 | `newMatch` reads the setup before the world; the slice memo; the world hash (section 2); the data hash gains the planet's file | New keys |
| 3 | None | Window 2's keys |
| 4 | The replay's `world` field and its refusal; `batch.gd`'s `--planet` and `--touch` | New replay |
| Run mode | `setup.wear` laid in `newMatch`; the extraction at a match's end (with its vectors); the run state is the host's | New keys |

## 7. Open

| For | Question |
| :--- | :--- |
| World | The picker without inverse trig (dot thresholds, the nearest column, chord distance in the city plan), or a `SimDetMath.atan2` with golden vectors. The function rewritten in float64 scalars (`p64lib.gd` is the pattern) |
| World and the EP | Keep Bellgate as the setup without a planet through windows 1 to 4 (recommended), or replace `genWorld` in window 2 |
| Game Design | The run's people, meters and planet-wide marks (section 5) |
| Tools | `--planet` and `--touch` in QA's runner; a schema for `setup.wear` when the run mode is built |
| The EP | A web-build and an ARM or macOS determinism run before the planet ships: the world becomes part of what every platform must agree on |
