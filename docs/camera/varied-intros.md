# The camera's part of varied introductions (Camera, 2026-10-16)

Owner: Camera and Cinematography. **Paper.** Nothing here is built. Asked by the EP from Orb's homework 5: "I want dynamic fighter introductions, I want them to play out different every time based on who is fighting, where they spawn in at, any other variables we can think of." The staredown question waits until Orb plays it. This is the camera's part: touch-down shots by place, by matchup and by time of day, deterministic from the match seed. Encounter and Narrative own the beats and the lines (`docs/narrative/dynamic-intros.md`: eleven templates over seven axes); section 6 lists what I need from them. Every number is a first value.

## 0. The short version

1. **Today every opening is one shot list.** Eight hard cuts in five seconds, always the same: the camera falls with the faller, a low wide frame at the crater, a level two-shot with a 10% push, two face cuts, a bell (rule-of-cool-shots.md row 7). Narrative's templates already vary the beats (who lands first, a wait, a retinue); the camera does not vary with them.
2. **The camera's part is a small grammar of shot families per phase**, picked per fighter and per phase from a seeded hash of what the match is: the place, the time of day, the matchup's tone, the arrival kind, the template and the history hook. Four families for a drop, three for a descent, five for a landing, one for a wait, four for the staredown, two for the closing.
3. **It is deterministic and write-free**: a hash of the match seed and the event's fields, no draw from the sim's stream, so a replay plays the same shots and the golden does not move.
4. **It varies inside the flash and pace rules**: at most 3 hard cuts in any second and 8 in the intro (today's count), no family that makes the world scroll faster than today's, and the reduced-motion set is fixed (a few still frames, dissolves) whatever the roll.
5. **It needs the events to say more**: the arrival kind, the template and the roles, the biome and the settlement at each spot, the time of day. Today the intro events carry the actor, the position and the fall's length only.

## 1. What it is today, measured

`render/camera/tests/intro_probe.gd` plays the opening through the real scene (the host's intro record, eight seeds: two lengths came up, 299 ticks and 419):

- **One fighter at a time** by design: each grounded fighter is off the picture for one 60-tick shot and one 24-tick shot (the other's landing and face), 108 ticks in all; never under 71 px tall.
- **Seven hard cuts**, as the plan.
- **The descent is a fast pan.** The camera falls with the faller, so over the last 25 ticks of a fall the picture changes by 0.06 to 0.29 of the width a tick (the bound for the fight is 0.045): sky that becomes ground. It is the designed shot, and sky is smooth until the ground comes up in the last 10 ticks. If the opening becomes the default, Tools' pixel gate should read it first; nothing here makes it faster.
- **The known gap of the split being off** (the camera loses the fighter on the ground in the longest intro) does not reproduce at this build: with one human and the split off the numbers equal the AI's.

## 2. The variables, and what each changes in a shot

| Variable | Source | What it can change |
| :--- | :--- | :--- |
| **Place**: the biome at each spot (plains, desert, mountain foothills), a settlement in view, the ground's slope and height | the world's start spots | the landing frame: a wide low frame under a big sky in a desert, a ridge for the horizon in the foothills, the town in the background where one is in view; whether an overhead frame is possible |
| **Time of day** | the sky (Rendering) | the angle against the sun: a low sun gives a silhouette on the crater's lip; a high sun a flat wide frame; night keeps the faller's glow and the crater's embers as the key |
| **The pair** | the matchup's stakes and tone (Narrative: `light`, `neutral`, `grave`; `sparring`, `rivalry`, `world_at_stake`, `appetite`) | cut density (grave: fewer, longer; light: quicker), the staredown family, whether the face cuts play |
| **How each arrives** | the template's `arrival` (`drop`, `descend`, `retinue`, `host`) | the arrival family: a fall chase, a slow crane down, a guard-first wide, a held medium on the one already there |
| **The template** | Narrative's eleven | the wait (the Latecomer's empty spot and sky), the order |
| **The history hook** | the pair's record (a rematch, who won last) | the staredown's emphasis: the last winner given the low angle |
| **Humans** | how many are playing | nothing in the shot (the frames are solo or merged; two humans get the same cameras), but the skip stays |
| **The fall's height** | the setup (`fallHeight`, 6,000 today) | the length of the descent shot |

## 3. The shot families

Each family is a short list of keyframes (a camera position relative to the subject or a point, a zoom as a share of the screen height, a pitch, a push), with its cuts and its worst picture change given, so the budget is checked in data.

**A fall (`drop`)**
| Family | The shot | Cuts | World scroll |
| :--- | :--- | ---: | :--- |
| F1 *ride-along* (today) | the camera falls with him, 10% of the height, ground rising | 1 | 0.06 to 0.29 of the width a tick over the last 25 ticks |
| F2 *from the ground* | a fixed low frame at the landing spot, pitched up 15 degrees, the faller streaking into the top and onto the crater | 1 | none (a body moving over a still background) |
| F3 *high wide* | the camera beside him at a third of the fall's height, wide (6% of the height), the planet's curve and the other spot in the frame, then a cut to the crater | 2 | the world is far: 0.01 of the width a tick |
| F4 *profile track* | a level side-on track moving along the line of the two spots, him dropping through it | 1 | 0.02 |

**A descent (`descend`)**: D1 *crane down* (the camera lowers beside him, steady, 2 s); D2 *eye-level approach* (a level frame, a slow dolly in as he settles, no crater).

**A landing**
| Family | The shot |
| :--- | :--- |
| L1 *low wide* (today) | pitch -6, the crater filling 55% of the width |
| L2 *crater lip* | the camera on the rim at ground level, him a silhouette against the sky in the dust, a slow 5% push; the sun behind him when it is low |
| L3 *overhead* | a high pitch (45 to 60 degrees) as the crater forms, the ring of dust; needs open ground and a camera pitch the ground rule allows |
| L4 *over the shoulder* | behind and above the lander, looking toward the other spot (previews the opponent) |
| L5 *in the town* | a settlement in view: the lander against it so scale reads, never the overhead |

**A wait (the Latecomer)**: W1 *the empty spot and the sky* (a held wide, 1.2 s); W2 *slow push on the one who waits*.

**A staredown**
| Family | The shot |
| :--- | :--- |
| S1 *level two-shot* (today) | the fit, a 10% push |
| S2 *low hero* | a low camera, the favoured fighter large in the foreground (the history hook's winner), the other behind |
| S3 *long lens profile* | side-on, the two close in the frame by a long lens (a narrower field), parallax compressed |
| S4 *slow orbit* | 4 degrees a second around the pair, at most 12 degrees, no cuts |
| the faces | today's two face cuts, or two *eyes* inserts (15% of the height on the eyes), or none for a `grave` pair |

**The closing**: the bell as today (a 5% punch-in), or for `dare` and `rush` a 3% push to the first move.

## 4. How a shot is picked, deterministically

- **Keys.** A hash of the match seed, the phase (fall, landing, wait, stare, closing) and the actor, with the context's fields: `h = hash(seed, phase, actor, biome, tod_band, tone, arrival, template)`. No call to the sim's random stream, so the sim's state and the golden do not move; a replay (which carries the seed and the setup) plays the same shots, and a rematch on the same seed does too.
- **Weights.** Each family lists tags and a weight table: a family has weight 0 where it cannot work (L3 and L5 together, L3 with a settlement in view, F3 at night where the curve is not lit), and the rest are weighted by the place, the time of day and the tone (a table in data, `data/fight/intro_shots.json`, schema in `tools/schemas/`). `h` picks by weight; the same context always gives the same family.
- **A no-repeat memory.** The host keeps the last two families used per phase (the intro record's `avoid`, which Narrative already keeps for scenarios), so two matches in a row do not open alike.
- **Constraints, always.** At most 3 hard cuts in any second, at most 8 in the intro; each family's worst picture change is in its data, and a family that would exceed the bound is not selectable (F1 stays as it is today, the only one over it, and is the family the reduced-flashing set drops); the faller or the lander is on the screen at every tick of his own shot.
- **The fixed sets.** *Reduced motion*: the five cuts of today's set (the spot, the landing, the second spot, the second landing, the two-shot), 0.3 s dissolves, no pitch, no push, whatever the roll. *Reduce flashing* (the default): F1 is replaced by F2 (no scrolling world), and the faces are off.
- **Skip** is as today.

## 5. What it costs the code

The shots are now constants in `camera_params.gd` and a hand-written timeline in `split_rig.gd` (`_intro_fall`, `_intro_land`, `_intro_stare`, `_intro_faces`, `_intro_clock`). The change is a data-driven shot player: a family is a keyframe list, the rig plays a list (the keyframe interpolation is the same ease and the same cut/dip machinery), and the picker reads the hash and the data. About the size of the shot-list code that exists. Tests: a sweep row per family (the subject on screen at every tick, the cuts, the worst travel against its data), the picker (the same context always gives the same family; 1,000 seeds give every allowed family; none of weight 0), the reduced sets, a skip at any tick, two humans equal to the AI.

## 6. What I need

| Who | What |
| :--- | :--- |
| **Encounter** (`sim/director/intro.gd`) | in `intro_start`: the template id, and for each fighter his arrival kind and role (`first`, `second`, `host`, `guest`, `lead`, `retinue`), the closing (`hold`, `look-away`, `dare`, `rush`), the tone and the stakes; in `entrance_fall` / `entrance_land`: the arrival kind of that fighter and, for a retinue, the guards' ids and positions; a `staredown_start` that names the closing's tick (the dare, the look-away, the rush); a `wait_start` / `wait_end` for the Latecomer so the camera holds on the empty spot; the history hook as flags (`rematch`, `last_winner` slot) |
| **Narrative** | which families each template allows (a tag list per template, in their file), the tone of each template, and the voice slots' ticks (`intro_line {actor, start, dur}`) so the cuts do not land across the first word of a line; whether a template wants a particular shot (the Latecomer's W1, a `dare`'s S2) |
| **Simulation / World** | at each spot: the biome id, the ground's height and slope, a settlement-in-view flag, the distance to the nearest structure; the spawn place when Orb's "random spot on the planet" lands (the shots read the place, they do not choose it) |
| **Rendering** | the time of day and the sun's direction as a value the camera can read at the intro (a band: dawn, day, dusk, night, and an azimuth); a pitch up to 60 degrees and a narrower field of view for S3 from the camera rig; the sky and the planet's curve from a third of the fall's height (F3) |
| **Animation** | the poses the shots lean on: a landing crouch seen from behind (L4), a silhouette-readable stand (L2), the staredown idle seen side-on, the eyes (S-faces) |
| **Tools** | the flash and pixel gate for every family (a clip per family, normal and reduced), and the opening on the pinned build if it becomes the default |
| **UI** | nothing new; the HUD stays hidden until the clock; skip as today |

## 7. Build order, behind a switch (`varied_intros`, default off)

1. **The data and the player**: families as keyframe lists in `data/fight/intro_shots.json`, today's shot list reproduced exactly as the default family set (a test: the cut ticks and the cameras equal today's, tick by tick).
2. **The picker** with the context from the events that exist now (the biome by a World read, the actor, the time of day by a stand-in), and the sweep rows.
3. **The new families** F2, L2, S2, S3 (the cheapest, no new data).
4. **The rest** (F3, F4, L3 to L5, D1, D2, W1, W2, S4) once Encounter's fields and Rendering's pitch and time of day are in.

## 8. Open for Orb

- Whether the opening becomes the default before the variety, since a first-time viewer sees F1 either way.
- How far "different every time" goes: with the no-repeat memory a pair sees a different family each of the first two matches; with ten or so families and the place and the time of day, a hundred matches do not repeat a whole opening. Whether he wants the staredown varied as much as the landing (the staredown question is waiting on him).
