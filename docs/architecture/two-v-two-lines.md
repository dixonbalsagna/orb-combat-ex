# 2v2: each fight its own turning line, the sizing

Simulation, 2026-11-09 overnight, for the EP's brief on Orb's order of 2026-11-08 21:52. Orb noticed that a LAN 2v2 plays like the old strip. **Paper only:** nothing was built for this. Counts are from main 397a7adf. **Checked by two read-only skeptics against the code**; their corrections are in (the drawing, the 22 sim lines, memos by zone, the 1v1 gate, the standing limit, the counts). Session counts are guesses; the token figures assume about 1.5M a session for my sessions (build and gates).

## The answer

**Build the bent line.** It's about 7½ to 9½ sessions across five owners, roughly 11 to 14M tokens. One strip still holds all four fighters, and its path on the planet bends: near each pair it follows that pair's own great circle, and in between it blends. **Each fight turns its own world by the same law as a 1v1, and nothing in the sim that measures between bodies changes:** hits across fights, `SimStage`'s gap and middle, NetLan's views and Audio's. The drawing does change: the render places everything on one circle through the camera, so the far fight and anything in the blend need converting (below).

**Two separate lines** (a frame per fight) is the literal reading of "each its own line". It's about **12 to 15 sessions**, roughly 18 to 23M tokens, plus a design nobody has ruled on: how two lines become one when the pairs meet, and what happens where two great circles cross. I'd keep it as the fallback if the bent line's limits show in play.

**Start with a one-session prototype** behind a switch: the path functions, a probe on four AI fighters, and a page build for Orb. Commit to the rest only after Orb plays it.

## Why it plays like the old strip today

`SimStage.together`: a swing starts only while all four are within `apartReach` (4,000 units, `data/fight/swing.json`) of their middle, and one under way rests when anyone leaves (`fight-swap.md`, Game Design's rule).

A beam in either fight also rests a swing (`SimStage.halts`).

From the 2026-11-01 proxy (`two-v-two-globe.md`): two AI fights on one planet, 6 worlds, 43,200 ticks.

| Pairs farther apart than | 1,000 | 2,000 | 5,000 | 10,000 | 20,000 | 40,000 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Share of the time | 85% | 82% | 60% | 43% | 22% | 7% |

**So the world can turn only about half the time at best.** It needs everyone within about 8,000 of each other, and less while a fight is swinging. These are far-end numbers: nothing pulled those fights together.

## The three ways, against today's code

| | **Bent line** (recommended) | **Two lines** | **Today's one line** |
| :--- | :--- | :--- | :--- |
| **When a fight can turn** | **About 80%** of the time on the proxy: together (about 50%) or 14,000+ apart (about 30%). Between those, the lines converge rather than turn | **Always**, except while two lines are being made one | About 50%, together only |
| **Coordinates** | **One strip:** `x`, `z` and gaps mean the same for all four | One per fight: every read between bodies of different fights converts through a planet point | One |
| **Hits across fights** (`cross.gd`, `outside.gd`: 13 distance sites; shots that go over, beams stopping at the first enemy, mailed blows) | **Unchanged** | Each converts. Near the two crossings of two great circles (about 12,000 units of each line), bodies share space but not coordinates: a new rule is needed | — |
| **Ground reads** (`SimField`'s column memos, keyed on the frame) | **One set,** keyed by zone, so one fight's turn doesn't wipe the other's columns | A set per line; two frames alternating would miss on every swap otherwise | One |
| **Strip arrays** (deform, water, scorch, crack and low: about 275 reads in the game itself, 158 of them in World, plus about 25 of the depth rows and 67 of the heaps, `S.rubble`; checks add about 160 more) | **One set.** A turn re-lays the turning zone, as a swing re-lays today | A set per line, swapped with the fight. Water, the heaps and (when `after.json` is on) the beam aftermath's kinds and their deform writes are strip-only: World would move them to planet records first, or a flood on one line is dry on the other. Only craters, cracks, scorch and trenches are planet records today | One |
| **Building poses** (`S.bX`, `S.bZ`: 13 reads in the game, 22 in checks) | One set; a turn re-poses its zone | A set per line, and two pose walks on a swing tick, the costliest part of one today | One |
| **Hash, digest, snapshot** | The frame gains a second anchor and a blend (a few numbers); each fight's swing state is hashed | Two frames, two swings, the strip arrays and poses per line. A swing tick's snapshot gains about 65 KB of poses and up to about 19 KB per changed array | — |
| **Rollback** | The path is plain state: restored, it's whole. Memos by zone stay exact (no history) | The same, times two lines, plus statics rebound on every fight swap | — |
| **The camera and the drawing** | Each PC frames its fight on the path's local circle. **But the render places every strip point on one great circle through the camera** (`tile_ground.gd`'s `frame_at` and one world matrix; the shader's `globe_dir` in `bend.gdshaderinc`). The far fight's bodies and this fight's beams or effects that reach into the blend are drawn away from where the sim has them. Each needs the bent `pointIn`, then the camera circle's `stripIn`, or the shader learns the bend: per-site work like two lines' | Each PC renders its fight's frame (it comes with the fight swap), and the other fight's bodies convert (`sim_host`, 5 sites). Split views of two fights need two frames at once | — |
| **When the pairs meet** | **Built in:** below about 14,000 apart the bend can't hold, so the two circles converge by the law as the pairs close. **The law is the hard one when anyone stands:** any standing body off the pivot caps the turn at 75 units a second at his distance (`swing.gd`'s `_limit`; its comment that bodies past the pair don't slow it is wrong in a stage), and the rise backstop also slows it. So the converge has to be ruled with that in mind | **Unruled:** one line turns onto the other, a slow visible swing of that pair's world, or a cut | — |
| **Its own limits** | Flying through the bend runs faster on the planet than on the strip: 1.41 times at 20,000 apart and 40°, 2.35 times at 90°. The two circles' difference needs a cap of about 120°. Two fights can be close on the planet but far along the strip, and then they can't touch | The crossings and the meeting | — |
| **Sessions** | **7½ to 9½** | **12 to 15**, plus World's records | — |

## The bent line, as it would be built

**The path.** `S.frame` holds, for each pair, an anchor: a point and a heading, the great circle that pair turns. Along the strip:
- within about 4,000 units of a pair, the strip is exactly that pair's circle;
- in the stretch between pairs, the strip blends from one circle to the other, as a fixed function of the strip coordinate.

**Every planet read goes through two functions,** `SimField.pointIn` (strip to planet) and `stripIn` (planet to strip), which already carry most of it. The work:
- `pointIn` gets the blend.
- `stripIn` in a blend zone becomes a fixed-iteration solve: deterministic, the same iterations on every machine.
- The frame math done outside `SimField` is routed through them: **22 lines in the sim.** That includes `swing.gd`'s `_applyTurn` and `_poseThese`, a hand-inlined `stripIn` run over every building on a swing tick, which then pays the blend's solve. The others are `structures.gd`, `planet_world.gd`, and the director's `location.gd` and `swing.gd`. **In the render, 17 GDScript lines** (`meteor.gd`, `tile_field.gd`, `tile_ground.gd`, `cam_places.gd`) **and the shader's single-circle placement** (`bend.gdshaderinc`'s `globe_dir` and `globe_sag`). My 2026-11-01 note listed exactly this refactor as the one line that keeps the door open.

**The swing, per pair.** Each pair's swing state turns its own anchor.
- **The law as a 1v1:** distance from its own pivot, its own two fighters.
- The other pair's zone doesn't move, so `together` stops being the gate. The new gate is "**this pair is together, and the other pair is either within the same reach or at least the bend distance away**".
- **Converging:** as the pairs close below the bend distance, the difference between the two circles must shrink in step, under the law. It's the one new rule, and the one Game Design and Orb should see in play.

**Memos and poses by zone.** A zone is keyed on its own anchor. A turn of one fight wipes and re-poses only its zone and the blend, so the other fight keeps its warm ground. That's what Performance's late-tick work fought for: the re-anchor fix of 1931a0f8, which has to stay true.
- **More than the column memos are keyed on the one frame:** `_changes` (World's contact memo), `warmStep`'s restart, `location.gd`'s keys and `swung()` (biomes, contact) all need a zone too.
- **`storeGrew`'s reach pad** was derived for a great circle, and must be re-proved for the blend. A stale column that differs from a cold read breaks "the same bits, warm or cold", and shows as a desync on rollback.

**What doesn't change:** hits across fights, `SimStage`'s gap and middle, NetLan's per-PC view, Audio's co-op calls, the hash of everything but the frame and swing, and the planet's own records (store, field, bDir).

## Two lines, as it would be built

As planned on 2026-11-01 (`two-v-two-sim.md`, option B), with what's landed since:
- **A line becomes a bundle** of the frame, the swing, the strip arrays and the poses, swapped with each fight in `SimStage._swap`, so the 280 or so sites that read them don't change. The world's statics (`SimField`'s key, the arena's) are bound again at every swap.
- **Every reach between fights converts through a planet point:** `SimCross`'s shooter and mail, `DirOutside`'s distances, the stage's gap and middle, `sim_host`'s other fight.
- **World moves water and heaps to planet records** first, or a flood on one line is dry on the other.
- **Two rulings nobody has made:** the meeting (turn one line onto the other, or cut), and the crossings.
- **The world stages about double on a field world:** reads, poses, lays, water.

## The step plan (bent line)

| Step | Owner | Sessions | Tokens, rough | Done when |
| :--- | :--- | ---: | ---: | :--- |
| 0. **Rulings:** the converge rule, and whether "close on the planet, far on the strip" is acceptable | Game Design, then Orb | — | small | Written down |
| 1. **Prototype** behind a switch: the path functions, both anchors, a probe on four AI fighters (each fight's turning share, the speed factor seen, close-on-planet cases, the tick's cost), and a page build | **Me**, Tools for the page | 1 + ½ | 2M | **Orb plays it** |
| 2. **The core:** `pointIn`/`stripIn` with the blend and the pose walk on it; the frame's anchors; the swing per pair, with its law and the converge rule; memos, poses and the other frame-keyed memos by zone, with `storeGrew` re-proved; hash, digest, snapshot. Checks: `frame_check`'s rows, `fights_check`, `two_states --setups=fights`, `rollback_check --setup=fights2`, determinism across processes | **Me** | 3 to 4 | 4.5 to 6M | All gates, **field-world 1v1 hashes unchanged** (one fight never bends) |
| 3. **World's own frame math** and the windows and marks re-laid by zone | World | 1 | 1.5M | World's checks |
| 4. **The render and the camera:** the render's 17 lines and the shader's placement learn the bend (or each far-fight and blend site converts); the turntable at each PC's local circle (LAN); the look gate | Rendering, Camera | 2 to 2½ | 3 to 3.5M | Look gate, both flash modes |
| 5. **QA's read:** turning share, speed in the bend, rescues across the gap | QA | ½ | 0.5M | Bands |
| **Total** | | **About 7½ to 9½** | **About 11 to 14M** | |

**A 1v1 must never see any of it:** with one pair there's one anchor and no blend. The new anchor and blend fields are hashed only when a second anchor exists, and the per-pair swing keeps the 1v1's hashed layout. **The golden proves nothing here, because it has no field world** (its planets are generation 1, with no frame). So step 2 is gated on field-world 1v1 hashes: `frame_check`, `swing_check`, the replay seeds and `fork_check`.

## Two lines, if Orb wants it instead

| Step | Owner | Sessions |
| :--- | :--- | ---: |
| Rulings on the meeting and the crossings | Game Design, Orb | — |
| The line bundle and its swap; statics per swap; memos and poses per line; hash, digest, snapshot | Me | 3 to 4 |
| Conversion at every reach between fights (cross, outside, stage) | Me, Encounter | 2 |
| Water, heaps and the beam aftermath to planet records; windows and marks per line | World | 3 to 4 |
| The meeting, built | Me, Encounter, Camera | 1 to 2 |
| The render: other-fight bodies converted; two frames in split views | Rendering, Camera | 2 |
| QA, the look gate | QA, Rendering | 1 |
| **Total** | | **About 12 to 15, roughly 18 to 23M tokens** |

## For Orb, when it's time

**Does it matter that two fights can be near on the planet and far along the strip?** That's the bent line's one odd case. It only happens once both have turned far apart, and then they can see each other but not touch. If that's fine, the bent line is the build. If not, it's two lines and the meeting rule.
