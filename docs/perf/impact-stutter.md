# High-speed impacts: why the frames stutter and the sound crackles (Performance and Platform, 2026-11-06)

For the EP. Orb's third play (`homework/Files/orb-first-play-20261106-1934.json`, build `orb-first-play-10d8b8cf-68ee07cc`: commit 10d8b8cf, key 36d1b6a65a4d, 120 parks, **Stream audio**): 63,054 frames in 505 s, 94 over 33 ms, 40 over 50, 4 over 100, worst 162.6 ms at tick 773. Orb: "during high speed impacts the frames stuttered and the audio sounded crackly". The audio snapshot in the file: 2,573 cues, 2,507 taken, 66 dropped (the status line says played 2,432, dropped 48), the sfx bus peaking at 0 dB, the master at -1 dB.

## In plain words

1. **The two are one problem, with a mechanism I proved.** In the web build without threads the game mixes its sound on the main thread and hands it to the browser's audio worklet through a small buffer. When a frame takes longer than about 40 ms the buffer runs dry and **the worklet throws away whole blocks of sound** (`index.audio.worklet.js`: "Output buffer has not enough frames! Skipping output frame"): a gap in the middle of the sound, which is a click. A forced stall right after a tick that plays several sounds: **no stall 0 blocks lost; 40 ms stall 9 blocks (24 ms of silence); 60 ms 13; 100 ms 28 to 32; 150 ms 51** (details below). Orb's 94 slow frames are all over 33 ms and 40 are over 50 ms: each is a lost block of sound when a sound is playing. So the sound crackles **because** the frames stutter, and it crackles most at the moments that stutter most: destruction and flights, where many sounds play at once.
2. **The dropped sounds are not from the stalls.** The 66 (or 48) dropped cues are the audio code's own rule: a cue whose source is more than 2,600 units from the camera is not played (`audio_voices.gd`, `mix.json` `space.max_distance`), or no voice of the 16 is free. In Orb's match, replayed natively, **49 cues are made while both fighters are 5,200 or more units apart** (each is beyond 2,600 of a camera between them): that is the 48 of the status line. The voices never ran out (the most sounding at once was 11 of 16; the most cues in one tick of the whole match 7). Those sounds would be 36 dB down anyway. This is Audio's side, working as designed, not a fault, and not at the stuttering frames.
3. **The stutter is the page, not the sim.** Replayed natively on the build's own tree (final hash reproduced), **81 of the 94 slow frames have a sim tick under 4 ms**; only 3 have 8 ms or more; the worst tick of the whole match is 20.3 ms. What the match was doing: of the 94 slow frames, **36 followed fast movement with afterimages, 31 a building falling or changing stage, 6 a launch, 4 a beam's scorch and fire, 17 nothing in particular.**

## The worst frames, with their events (native sim cost at that tick; events within 6 ticks before; "apart" is the distance between the fighters in world units)

| Tick | Page ms | Seconds in | Sim tick (ms) | Events | 
| ---: | ---: | ---: | ---: | :--- |
| 773 | 162.6 | 13.1 | 4.0 | afterimages x2, a swing to chase; fighters 4,024 apart |
| 767 | 158.2 | 12.9 | 3.1 | (the same chase); 3,337 apart |
| 18474 | 125.0 | 437.2 | 7.2 | beam scorch x36, building stages x36, building falls x18; 1,955 apart |
| 16300 | 104.1 | 400.9 | 7.1 | scorch x36, fire x36, building stages x18, falls x9 |
| 762 | 96.0 | 12.8 | 2.3 | the chase; 2,732 apart |
| 733 | 95.8 | 12.3 | 2.0 | afterimages x9, a fighter leaves the ground, a building's state changes |
| 758 | 87.5 | 12.7 | 2.2 | the chase; 2,226 apart |
| 8038 | 87.5 | 134.1 | 4.5 | building stages x24, scorch x19, falls x8, a crater, a beam's outcome, fire |
| 754 | 75.1 | 12.6 | 2.1 | the chase; 1,699 apart |
| 16304 | 75.1 | 401.0 | 5.9 | scorch x46, fire x46, stages x8, falls x4 |
| 5515 | 70.9 | 92.1 | 4.7 | afterimages x9, a slide, a tumble ends, a flight ends |
| 10013 | 70.8 | 167.0 | 5.0 | afterimages x9; 6,760 apart |
| 18478 | 70.8 | 437.2 | 7.5 | scorch x46, stages x37, falls x18 |
| 725 | 66.7 | 12.1 | 2.7 | afterimages x7, slide dust x6, a swing rests and the next starts, chase |

Six frames are 93 ms or more: the first stretch (ticks 692 to 785, 22 slow frames in 1.6 s, 11.5 to 13.1 s into the match: a launch and a chase while the fighters fly 1,700 to 4,000 units apart) and two destruction stretches (16284 to 16319, 18461 to 18484: a beam through buildings). Native sim costs at those ticks are 2 to 7.5 ms: the stalls are in the page.

## The crackle test (the page, Orb's match played through Tools' capture hook, the browser's own audio running; a scratch copy of the build's web folder whose worklet reports every skipped block; the shipped files untouched; real GPU; load 12 to 13%: valid)

A tick that plays several cues is stepped, then the main thread is held for L ms in the same call, and the blocks the worklet skipped in the next 800 ms are counted (`docs/perf/tools/preplay/audio-stall-test.mjs`):

| Stall | Voices sounding | Blocks skipped | Silence |
| ---: | ---: | ---: | ---: |
| none (control, tick 1547) | 1 | **0** | 0 |
| 40 ms (tick 1602) | 0 | 9 | 24 ms |
| 60 ms (tick 1735) | 3 | 13 | 35 ms |
| 100 ms (tick 1821) | 3 | 32 | 85 ms |
| 150 ms (tick 2015) | 4 | 51 | 136 ms |
| 100 ms (tick 2283) | 0 | 28 | 75 ms |

Each block is 128 samples (2.7 ms). A skipped block with a sound playing is a hard gap; with nothing sounding (the 0-voice rows) it is silence in silence. **Stalls of 40 ms, which are everyday in Orb's play (94 frames over 33 ms), already lose sound; there is almost no headroom** (the 93 ms the game reports as output latency is not the buffer's headroom). A longer probe over the first 1,500 ticks of the match saw the same thing in play: the skips come in bursts at the slow frames (at tick 713, 137 blocks behind a 71 ms frame; at ticks 601, 694, 834, 874, 968, 998 and 1201, 2 to 10 blocks behind frames of 41 to 58 ms) and none between them once the match is running. (Not verified by ear: that the gap is audible as a click is a property of cutting a waveform off mid-sound; I did not record the output.)

Also in the file: the sfx bus reaches 0 dB and the master limiter (`AudioEffectLimiter`, threshold -6 dB, ceiling -1 dB; Godot's older soft-clipping limiter) holds the output at -1 dB (`peak 0.891`), so stacked impacts can also be distorted; I did not separate that from the gaps. It would be there at every loud stack, not only at stalls; Orb ties the crackle to high-speed impacts, which is where the stalls are.

## What I measured on main 3c9005ac (the page, a scratch export of main with Tools' preview patches and my timers; Orb's inputs played through the hook, so a different fight; load 10 to 15%: valid)

The overnight batch is in: **12,100 frames, p50 12.5 ms, p99 32.8, worst 112 ms; 71 over 33 ms, 25 over 50.** (The hooked page runs about 2 frames a step: only the shape carries.) Of the 71: **29 are the planet view update (`PlanetView.update`) over 15 ms (10 of them over 30 ms, the worst 63 ms)**, 7 the tile ground over 10 ms, 35 in neither (the engine's own draw, the browser). The planet-update spikes come at ticks 1808, 1853, 1997, 5247, 6128, 8227 and 11004 to 11008 and are **not preceded by destruction events** (a building falling, scorch, fire: none in the 8 ticks before): at the moments of a building falling, a launch, a crater or fire the frame is within 1 to 2 ms of the median (12.5 ms; 13.8 to 14.9 at falls and launches). So on main the destruction itself no longer costs; what stutters is the planet view update on its own, in bursts. (Inside it, I have not looked yet.) The tile ground's standing cost is 4.6 ms a frame, 3.0 to 4.9 at the event classes: not the problem in this match.

## Top three causes, owners, fixes ranked by gain

1. **Main-thread stalls of over 40 ms at destruction and fast flights, in the page** (94 slow frames, 40 over 50 ms in Orb's build; on main 71 over 33 ms in the same kind of play): **Rendering** (`PlanetView.update` in bursts of 20 to 63 ms on main; the tile ground's work at wide separations in Orb's build), with **VFX** (afterimages: 36 of the 94 slow frames sit right after them; scorch and fire at beams) and **World** (building stage and fall changes: 31 of 94). Gain: every stall removed removes a click.
2. **The audio worklet starves at any stall over about 40 ms and loses whole blocks** (the proof above): **Audio** (with Tools for the project setting). It is the part that turns a hitch into a crackle, so it can be fixed on its own: (a) **a larger buffer**: `audio/driver/output_latency.web` raised so the ring holds 100 to 150 ms, at the price of late sound by that much (a hit lands 100 ms after its picture: probably too much for impacts, acceptable for ambience: Audio's call; I have not tried it); (b) **Sample playback for short sounds** (`default_playback_type.web` Sample: the browser plays them itself, independent of the main thread, but the bus effects, the muffled buses and the limiter do not apply to them: Audio's call; the first play on the Sample build had its own slow frames, not attributable to the mode); (c) stop stalling (cause 1).
3. **The first stretch of every match, 11 to 13 s in** (22 slow frames, 162.6 and 158.2 ms, ticks 692 to 785: a launch while the fighters chase 1,700 to 4,000 units apart, with afterimages): **Simulation and Encounter** for the launch tick (20.3 ms natively, of which `chooseLaunch` 10.7 and `DirSwing.atLaunch` 6.3) and **Rendering** for the wide view of two fighters thousands of units apart (the tile-ground finding of 2026-11-01). The first big stall of a match is also the first time Orb hears the impacts.

Fixes by gain: **(1) Audio's buffer or sample mode: removes the crackle that stalls cause without removing a single stall; a quick change** (not measured in the sound itself); **(2) the planet view update's bursts on main (Rendering): the largest single piece of the stutter that is left (29 of 71 frames over 33 ms)**, inside it still to be timed; **(3) VFX's afterimages and the scorch/fire layers, World's building stage changes: the biggest piece in Orb's build (36 + 31 of 94), but on main they no longer show at their ticks;** (4) the launch tick (20 ms natively, 8 ms of it atLaunch and `_launchPick`).

## Limits

- Orb's build is gone (no patched tree survives): the page counters are from main 3c9005ac on Orb's inputs, which diverge into another fight; the sim attribution is from the replay on Orb's own build tree, which reproduces his final hash.
- Native replay at load 12 to 38% (valid); the crackle test and the main recording at 10 to 15% (valid).
- The hook page is slower than Orb's real page (7 to 11 ms a frame): shapes and ratios carry, not milliseconds.
- The crackle is not heard here: what is proved is the skipped blocks, their size and when they come.
- The first page measurement attempts failed on my export settings (threads template, a duplicated key in the preview patch); fixed, the numbers above are from the working export only.

## Files

`docs/perf/tools/preplay/audio-stall-test.mjs` (the forced-stall test), `audio-underrun.mjs` (skipped blocks against frame gaps over a stretch of the match), `perf-run.mjs` (per-frame counters, now with the particle and beam timers), `replay_prof.gd`; `docs/perf/tools/scratch-hooks/hook-simtimers.py`, `hook-viewtimers.mjs`.

## Second round (2026-11-06): the calls behind the planet-view bursts, and the launch tick's hot loops

### 1. The planet view's bursts on main are `PlanetView._startle`, then the building sweep (Rendering)

Timers inside `PlanetView.update`, `refresh` and `GroundField.update` (`docs/perf/tools/scratch-hooks/hook-planettimers.mjs`, on top of `hook-viewtimers.mjs`), main 3c9005ac, Orb's inputs through the hook (a different fight), 11,100 ticks, load 9 to 11% (valid). Of 11,100 frames, **58 have the planet update over 8 ms** (13 of them over 30). Inside those 58 (mean ms, max): **`_startle` 14.9 (52.7)**, `refresh` 4.8 (23.3), of which `_visit` 4.1 (22.6), `ground.update` 1.1 (5.8; `_shore_near` 0.5). Everything else is under 0.2. At the 10 worst spikes `_startle` is 17 to 53 ms of 35 to 68; at ticks 1997, 5247, 1808 and 11004 to 11008 the building sweep adds 10 to 22.

- **The hot loop (`_startle`, render/core/planet_view.gd):** for every blow this frame (the `crater`, `scorch` and `debris` events `consume` collects: every impact that throws debris, and a beam's scorch in runs) it walks **every building** (`for bi in range(S.buildings.size())`: 3,000 and more with buildings everywhere), computing `SimWrap.sdx` for each, to find the crowd figures to startle. Cost = blows x buildings, every frame with a blow. (My earlier note that the bursts were not preceded by destruction was wrong in what it counted: I had filtered `debris` out of the events as noise, and debris is the very event that sets a blow.)
- **Fix sketch, tried:** ask the sweep's sorted building index (`_along(bx, STARTLE_R + _wmax + CROWD_SPREAD, out)`, a bsearch the file already uses for debris and for the evacuation zone) for the buildings near the blow instead of all of them, keep the same exact test (and test `_shown[bi]` first, it is the cheaper), fall back to the full scan if the index is stale. **The same set, the same behaviour: render only.** Measured on the same 11,100 ticks: frames with the planet update over 30 ms **13 -> 0**, over 15 ms **28 -> 8**, the worst **68 -> 26 ms**; `_startle` in the spike frames **14.9 -> 0.4 ms**; frames over 50 ms **24 -> 11**; spike ticks 1997 **68 -> 23**, 5247 **64 -> 24**, 1853 **58 -> 6**, 6128 **40 -> 2**, 1808 **50 -> 16**. p50 and p99 unchanged (12.5, 29.2: the rest of the frame is not it). Patch: `docs/perf/tools/preplay/startle-index.patch` (checked to apply on HEAD with `git apply --check`; **a scratch test, for Rendering to review and take**).
- **What is left (the 8 spikes of 16 to 26 ms):** `refresh` -> `_visit`: after a blow, `_dirty_feet` and the touched sets put every building near the damage on the visit list, and each `_visit` can rebuild the building's multimesh transform and its crowd (`_set_building`, `_set_crowd`). **Sketch (Rendering):** a per-frame budget on visits (a queue: the visible ones first, the rest over the next frames), and skip a visit whose building did not change (`seen` already compares height, floors and hit points; the footing test `_foot_dirty` is what adds the buildings along dirty ground). Not tried.

### 2. The launch tick's hot loops (Encounter)

Statement-level timers inside `chooseLaunch`, `_biomeCands`, `DirSwing.atLaunch`, `_launchPick`, `candidates`, `scored`, `_standing`, `WorldBrunt.aim`, `DirVisit` and `WorldContact.lookAt` (`hook-launchtimers.py`), Orb's own build tree, the whole third-play replay (final hash reproduced), load 13 to 21% (valid). **12 launch ticks** (`chooseLaunch` over 3 ms: ticks 692, 736, 832, 872, 5432, 7768, 12088, 14774, 16635, 16725, 18903, 19989): whole tick 11.3 ms mean, `chooseLaunch` 6.8, `DirSwing.atLaunch` 1.8 (the first, tick 692: 23.3 whole, `chooseLaunch` 11.8, `atLaunch` 7.4).

| Hot call | ms a launch | calls a launch | What it is | Fix sketch |
| :--- | ---: | ---: | :--- | :--- |
| `_biomeCands` -> `_biomeCandsRead` | 2.3 | 1 | the biome's candidates: `_cliff` 0.66 (92 `WorldTerrain.groundY` reads a call: 1,112 over the 12), `_propsNear` 0.6, `_propFlight` 0.12 x 5 (30 `moveAir` steps each), 86 more `groundY` | one bulk read of the ground columns ahead (a typed array slice of the heightfield, or the field's coarse memo) in place of ~175 `groundY` calls at 6 us; a sorted prop index with bsearch for `_propsNear`; cache the cliff scan per (tick, x) |
| `WorldBrunt.aim` | 1.3 | 2.3 | each building candidate re-flies the launch for several `AIM_UY` values (0.56 ms a building; 5.75 ms for 6 at tick 692) | reject by the cheap score before aiming, cap aimed buildings at 3, reuse one flight across `AIM_UY` values (a design call for the director) |
| `predictFlight` | 1.6 | 3.75 | one flight for each of the 3 to 4 candidates and a re-fly when the force is raised (long haul, street) | solve the haul force from the first flight's travel without a second `predictFlight`; the ceil table of Simulation's park (cuts the cold reads) |
| `_landTerms` -> `WorldContact.lookAt` -> `surfaceAt` | 0.9 | 3.6 | the surface at each candidate's landing: 0.2 ms a lookup | memoize `surfaceAt` per column for the tick |
| `DirSwing._standing` (from `candidates`, 1 to 2 calls an offer) | 0.9 | 1.25 | rebuilds the list of standing places (about 270 appends a call) | build it once per offer and pass it to `candidates` and `_launchPick`; take the window from the sorted index and not by walking all |
| `DirSwing.scored` / `_direction` | 0.8 | 0.4 / 2.3 | scores each swing candidate; 15 `_direction` calls at tick 692, 0.04 ms each | cheap; leave |
| `DirSwing._planOn` | 0.3 | 0.33 | 0.87 ms a call (4 calls) | not looked into |

The first launch of a match is the dearest because the memos are cold (23 ms against the 11 mean). If the five biggest of these land (biome candidates, aim, landing terms, `_standing`, the re-flies) the launch tick falls from about 11 to about 7 ms mean (my estimate from the table: about 4 ms off) and the first one from 23 to about 15: **worth doing, but not the cause of Orb's stutter** (the 20 ms native tick at tick 692 is one frame of the 22 slow ones of the first stretch; the page costs were 100 to 160 ms there). **Owners:** Encounter for `DirLaunch` and `DirSwing`; Simulation for the ceil table and `predictFlight`; World for `WorldContact.surfaceAt`.

Limits of this round: the page timers are from main on Orb's inputs (another fight); the startle-fix gain is one 11,100-tick recording each side (load 11/9 and 12/14%, valid), p50 and p99 identical between them; the launch timers are statement timers with a clock read each (a few percent of overhead on the small ones: `groundY` at 6 us a call includes about 1 us of it).
