# Alpha audit: inventory (phase 1, merged)

Reading session, baseline 8901d351 (`../00-baseline.md`). Fourteen read-only slice agents wrote one file each in this folder (`I-01` to `I-14`); this page merges their system rows by owner, gives the switch table's summary, and lists the slices' notable facts. **The slice files are the full record:** each has the complete systems table with data, switches and leftovers, plus a "Not covered" list. Cite the slice file, or better the `path:line` it gives, never this summary alone.

Owners are the director slugs from `DIRECTORS.md` "owns" lines as the slice agents placed them; "unplaced" means no owns line covers the path. Eight data folders have no owns line (`data/anim`, `data/art`, `data/camera`, `data/combat`, `data/fight`, `data/input`, `data/narrative`, `data/vfx`; I-08 Notable 12).

## How this was checked

Ten rows spot-checked against the files at the baseline by the reading session (2026-11-13, after the merge):

| # | Row checked | Result |
| --- | --- | --- |
| 1 | I-08: `tools/preview/switches.mjs` has 92 switch rows | **Correct.** `SWITCHES` spans lines 13 to 245, 92 rows. The specification's "98" also counts six trial-variant rows at lines 1042 to 1054 (`kick` x4, `hitstop`, `tier`), which are not build switches. |
| 2 | I-08: no game code reads `data/combat/mixed.json` though the `mixed` row is on in both builds | Correct: `git grep -l 'mixed\.json' -- '*.gd'` returns nothing. |
| 3 | I-01: `SimKeyboard` is unreached | Correct: only `sim/input/keyboard.gd:1` and a comment at `render/core/key_codes.gd:2`. |
| 4 | I-05: the babble voice is reached only from the demo and tools | Correct: callers are `audio/demo/audio_demo.gd` and `audio/tools/*` only. |
| 5 | I-01: campaign has no host caller, only `run.gd:391` | **Imprecise, not wrong:** `render/core/boot_entry.gd:23` also lists `campaign.gd` in its compile warm-up, and `sim/core/tools/campaign_episode.gd` drives it. No gameplay caller found. |
| 6 | I-06: the Windows, Linux and macOS export presets exclude `net/*` | Correct: `export_presets.cfg:55`, `:101`, `:132`; the Web preset (`:11`) does not. (So the LAN program is not made by the plain desktop presets; I-06 says `net/tools/lan_kit.mjs` patches a scratch copy.) |
| 7 | I-01: hit-stop by weight is off in data | Correct: `data/fight/hitstop.json:4` `"enabled": false`. |
| 8 | I-04: the greybox HUD still draws MENACE and ANGUISH bars | Correct: `render/core/hud.gd:228-233`. |
| 9 | I-04: `chase_rush_check` runs in CI | Correct: `.github/workflows/ci.yml:223`. |
| 10 | I-08: the rival's meters data still has `menace` | Correct: `data/fighters/RIVAL/meters.json:5`. |

One imprecise row in ten, none wrong: no slice re-run (the rule is more than one wrong).

## Slices

| Slice | File | Tracked files | Uncommitted paths | Systems | Unreached |
| --- | --- | ---: | ---: | ---: | ---: |
| I-01 | I-01-sim-core-input.md | 332 | 2 | 16 | 1 |
| I-02 | I-02-sim-director.md | 239 | 0 | 30 | 1 |
| I-03 | I-03-sim-world-biomes.md | 348 | 0 | 24 | 2 |
| I-04 | I-04-render.md | 636 | 0 | 25 | 2 |
| I-05 | I-05-ui-audio-loc.md | 394 | 0 | 19 | 5 |
| I-06 | I-06-net-qa-prototype.md | 141 | 3 | 19 | 4 |
| I-07 | I-07-tools-ci.md | 469 | 0 | 23 | 1 |
| I-08 | I-08-data-schemas-switches.md | 481 | 2 | 13 | 0 |
| I-09 | I-09-pending-parks.md | 456 | 494 | 14 | 10 |
| I-10 | I-10-design-arch-decisions-ep.md | 260 | 20 | 12 | 2 |
| I-11 | I-11-builds-evidence-ci.md | 1051 | 260 | 12 | 1 |
| I-12 | I-12-art-research-marketing-legal.md | 1172 | 275 | 20 | 5 |
| I-13 | I-13-other-docs.md | 2118 | 13751 | 21 | 9 |
| I-14 | I-14-claude-audit-directors-root.md | 369 | 3 | 18 | 0 |

Tracked files by slice overlap where slices share paths (I-13 counts all of `docs/` outside the folders others cover; uncommitted counts are from `../baseline-status.txt`). Subagent tokens for the fourteen: 1.93M.

## Switch table (summary; full table in `I-08-data-schemas-switches.md`)

`tools/preview/switches.mjs` `SWITCHES`: **92 rows**, 85 that flip a data key and 7 that are page words or the planet setup. Values were read from the builds' own data (`tree/data/`) and, for `ui/data` and `audio/data` rows, by `grep -a` in `web/index.pck` (solo) and `orb-combat-lan.exe` (LAN).

- **Main differs from Orb's solo build on 72 of 92 rows** (68 data keys and 4 page words: `blackbox`, `go`, `meteor`, `tiles`); one more (`gen3`) is not evidenced either way.
- Solo and LAN agree on all 85 data keys.
- 12 rows are already at their "on" value on main (9 timing switches, `stallKeep`, `hapticImpact`, `nodeWarm`), so their "off" values are stale; 5 rows are held (`wallPush`, `wallPushAi`, `slamTurn`, `cityHold`, `aimCuts`) and off in every build. The `lightStops` row turns a value from true on main to false in the builds.
- `tools/preview/switches-pending.json` has 0 rows.
- The `mixed` row is on in both builds, but no game code reads its file (check 2 above).
- The EP's pointer (AQ-05) to Tools' own record: `docs/tools/runs/6a30b4c9/pck-verify.txt` and `switch-list.txt`; LAN: `docs/net/runs/6a30b4c9/lan-folder/pck-vs-page.txt`. Not re-read here.

## Systems by owner

| Owner | Slice | System | What it does | Files (lines) | Tests / CI | Reached | Leftovers |
| --- | --- | --- | --- | --- | --- | --- | --- |
| accessibility-localization | I-05 | Pseudo-locale data | Accented, longer, bracketed twins of 10 ui/data files | localization/pseudo/ui/data/* (10 files, 2976 lines) | pseudo_switch_check.gd, tools/l10n/overflow_check.gd; none in CI | yes | menace/anguish, TARGET HIDDEN terms (terms.json:27-28, :137) |
| animation | I-09 | animation/pending | Patches for render/anim: beam-shove, stick-pre, flight-strikes, air-brake-looks, plus their schema patches | README.md (36, M) + 8 untracked .patch | none found | unreached (no code references docs/animation/pending) | All on main (5 reverse-apply; keys _pre_layer, beam_shove, shove1, energy_back in HEAD). README:3 'Parked' is stale (landed 7de33ae4) |
| animation | I-12 | Animation review packs | Pose-tool output sheets, GIFs, exceptions | art/animation/review (295 tracked), records (262) | written by render/anim/tools/review.mjs:37; not in CI | not evidenced (output only) | 112 untracked files |
| animation | I-13 | Animation launch-pair coverage data | Per-fighter move rows checked by the coverage tools | docs/animation/launch-pair-coverage.json, launch-pair-live-status.json | render/anim/tools/coverage.gd; not in ci.yml | yes | none marked |
| art | I-09 | art/pending | Desert tone-on-tone palette patches | desert-tone-on-tone/ 4 files (574) | none found | unreached (no code refs) | Applies clean; README says 'Shelved, not landed' |
| art | I-12 | Biome look generator | Draws biome sheets and writes data/art/biomes.json | art/concepts/biomes/*.mjs (16 scripts, 1180 text lines) | data validated by tools/validate.js (ci.yml:77-81); generator untested | yes | 13 uncommitted edits; 'strip' wording draw.mjs:48 |
| art | I-12 | Sky generator | Writes dynamic sky keys | art/concepts/sky/*.mjs (758) | render/tools/sky_check.gd:101; no CI line found | yes | none found |
| art | I-12 | Damage stages generator | Writes battle-damage stages per outfit | art/concepts/damage/gen.mjs (167) | none found | yes | none found |
| art | I-12 | City looks and cars | Writes city palettes and car silhouettes | art/concepts/city/*.mjs (283) | props_check.gd:21 (ci.yml:273), city_check.gd:40 | yes | none found |
| art | I-12 | Colour-vision presets | Searches/checks colour-blind lane triples | art/concepts/colour-vision/*.mjs (363) | lane_check.gd:50, effects_check.gd:6279 read data; check.mjs not in CI | yes | none found |
| art | I-12 | Marked-aura flashes | Writes 13 head-flash recipes | art/concepts/marked-aura/gen.mjs (771) | audio/tools/host_check.gd:86-97 | yes | ambush 'Primed' flash gen.mjs:83; stale path in flash_cues.json:5 |
| art | I-12 | Energy lanes | Writes each fighter's energy colour lane | art/concepts/energy/*.mjs (276) | none found | unreached (git grep energy-lanes.json in *.gd/*.mjs/*.yml outside art: none) | svg modified uncommitted |
| art | I-12 | World polar/outposts | Writes polar palette and outposts | art/concepts/world/*.mjs (422) | none found | unreached (git grep polar.json/outposts.json: no loader) | none found |
| art | I-12 | Refine/glasses | Fighter refine sheets incl. glasses colours | art/concepts/refine/*.mjs (1146) | none found | yes | none found |
| art | I-12 | Character concept sheets | Concept generators (anti-hero, faces, turnaround, closeups, etc.) | art/concepts/* ~6000 text lines | none found | unreached (no code outside art cites them (git grep)) | KAI/VORR faces/gen.mjs:91; 47 untracked new-group paths |
| audio-music | I-05 | Audio cue reader | Seeded reader of sim events into cues; composes brawl/carry/coop/moments/tug/world | audio/audio_cues.gd (306), audio_brawl (562), audio_carry (284), audio_coop (174), audio_moments (99), audio_tug (265), audio_world (406) | brawl/carry/coop/moments/tug/world/beat checks; none in CI; JSON in CI data job | yes | carry/coop/moments/tug/world all enabled:false (each *_cues.json:4) |
| audio-music | I-05 | Sound bank + synths | Procedurally renders every sound to WAV streams, async warm-up | audio/audio_bank.gd (496), 9 audio/synth files | warm_check, warm_async_check, tone_check; none in CI | yes | none seen |
| audio-music | I-05 | Voice pool + web voices | Plays cues on buses with cap and distance rolloff; browser one-shot path | audio/audio_voices.gd (453), audio_web.gd (248) | host_check, web_policy_check, web_voices_check.mjs; none in CI | yes | none seen |
| audio-music | I-05 | Babble voice | Caption to seeded syllable run in speaker's voice | audio/audio_babble.gd (444), audio_babble_player.gd (71) | babble_check; none in CI | unreached (only audio/demo/audio_demo.gd:47-49 and audio/tools) | not hooked into game |
| audio-music | I-05 | Music sketches | Offline procedural music/riff reference renders | audio/synth/music_sketch.gd (458), metal_sketch.gd (225) | music_check.mjs; none in CI | unreached (tools only: render_sketches.gd:21, render_suno_refs.gd:17) | audio/music has no tracks |
| audio-music | I-05 | Audio demo + render tools + previews | Dev listen scene, offline demo renders, 96 preview WAVs | audio/demo/audio_demo.gd (173), audio/tools/render_* , analyse_wav.py (293), audio/preview/** (96 wav) | none found | unreached (dev only; audio/preview/.gdignore) | bulk WAVs counted not read |
| audio-music | I-09 | audio/pending | 9 parks applied by apply.py with old_hashes.json and full src/ copies | 62 tracked (13080) + 18 untracked | none found | unreached (only comments: audio/audio_voices.gd:270, audio/tools/pad_start_check.mjs:6 cite audio-resume snippet) | water-v2 and press-stunned src identical to HEAD (on main); others partial; audio-resume withdrawn |
| audio-music | I-13 | Audio crackle A/B + proposed recipes | Stall-and-record measurement of web audio holes; proposed cue recipes | docs/audio/tools/crackle-ab.mjs (175); docs/audio/proposed/ 5 files | none | unreached (docs/audio/crackle.md only) | proposal |
| camera | I-04 | Dynamic split screen | Per-tick split decision, framing, shake, launch/KO/peak shots, compositor | camera/split_rig.gd (5750), split_view.gd (520), split_frame.gd (285), camera_params.gd (628), camera_rig.gd (58), pane_shake.gd (31), cam_places.gd (156) | chase_rush_check in CI (ci.yml:223); split_sweep (5203) and 22 others not in CI | yes | hiding hook unused split_rig.gd:20 |
| camera | I-04 | Camera tests | Split sweep, probes, shot checks, digest diff | camera/tests 26 files (9743): split_sweep (5203) | chase_rush_check only (ci.yml:223) | yes | none found |
| camera | I-09 | camera/pending | Swing 1-12, damage-inset, cd04, cross-ko, vkeep, others-frame and other camera parks | 23 tracked (6285) + 30 untracked; 2 deleted | none found | yes | Still waiting: cd04, others-frame, director-21-low-launch, damage-inset (damage_inset absent), swing-12-sky. 'strip' in 5 swing files |
| combat-choreography | I-09 | combat/pending | Combat data parks: waves, movegen, roster, energy, rally, split, stick, mixed-string and more | 92 tracked (59110) + 55 untracked; 13 M | CI data job ci.yml:79 runs tools/movegen/test/run.mjs, which reads movegen and roster | yes | split-refine waiting; energy, rally and roster wait on Orb (audit-2026-10-30.md:36); menace in energy files |
| combat-choreography | I-13 | Combat proposals | Proposed identity/lock data and two movesets | docs/combat/proposals/ 6 files | none | not evidenced (no code caller found) | proposals |
| community-marketing | I-12 | Marketing docs | Go-to-market, store copy, holding page, Steam readiness | docs/marketing/*.md (7 files, 1078) | none | not evidenced (docs) | KAI/VORR go-to-market-plan.md:31,229,319 |
| controls-feel | I-01 | Input control/intent/keyboard | Per-fighter input step; intent record v2; key state to intent | sim/input/control.gd (31), intent.gd (301), keyboard.gd (23) + JS | parity.gd; input tests not in CI | yes | SimKeyboard dead |
| controls-feel | I-01 | Input hub/layout/data/names/remap/swap/left hand | Device to slot, presets to intent v2, data load with fallback, rebinding, left-handed mirror, brace/vanish | hub.gd (931), layout.gd (1351), input_data.gd (413), names.gd (33), remap.gd (446), swap.gd (63), left_hand.gd (192) | hub/layout/remap/left_hand tests; no CI job | yes | timing.json has 25 switches (13 true); built-in timing copy input_data.gd:11 |
| controls-feel | I-01 | Strike stick readers | Strike read, no-claw law, aim latch, press-style reader, stance mask | strike_read.gd (353), strike_law.gd (145), aim.gd (351), press_read.gd (736), stance.gd (94) | strike_gate/strike_read/aim/press_read/stance tests; no CI job | yes | none |
| controls-feel | I-01 | Haptics + touch | Pulse plans from cues; touch gestures to intent v2 | haptics.gd (609), touch.gd (682) | haptics/touch tests; no CI job | yes | phone/touch paths live while mobile parked (ADR 0011) |
| controls-feel | I-01 | Input probes | One-off probes | sim/input/tools 16 tracked + stall_probe.gd (43, untracked) | none found | unreached (no ref in .github, tools/, qa/) | orb_aim_probe, row42_probe one-offs |
| controls-feel | I-09 | controls/pending | About 30 small Controls parks (stick-feel, landing, refusals, haptics) | 51 untracked, 0 tracked | none found | unreached (no code refs) | Whole folder uncommitted; mostly on main (7 reverse-apply, 21/24 all keys) |
| controls-feel | I-13 | Controls paper models | Seeded synthetic-thumb models of right-stick recognizer, dodge direction, claw-bot gate | docs/controls/right-stick-model.py (384), dodge-dir-model.py (104), right-hand-attacks-model.mjs (177, modified) | none found | yes | none marked |
| controls-feel | I-13 | Controls clip tools | Input scripts/thumbs for hit-stop A/B and thumb clips | docs/controls/clips/* (all untracked) | none | yes | tracked code reads untracked data |
| controls-feel / animation / ui-ux / world-environment | I-13 | Patch handoffs outside pending/ | Diffs for the EP to apply (schemas, glue, hash, shader) | docs/controls/*.patch (22), docs/animation/handoff/ (11 patches + 4 schemas), docs/ui/start-menu-main.patch, world diffs | none | not evidenced (landing on main not checked) | stale-handoff risk |
| encounter-systems | I-02 | Exchange director (DirExchange) | Beat scheduler, requestAttack, runBeat, windows, chain, endEx, dirUpdate | sim/director/exchange.gd (1240), exchange.js (105) | indirect sim/core/tools/parity.gd:1441 (godot-parity); JS in sim job | yes | placeholder finisher exchange.gd:808; test hook checkData exchange.gd:1018; ambush exchange.gd:331 |
| encounter-systems | I-02 | Combat data loader (DirData) | Loads Combat templates/finishers as hashed match inputs | data.gd (793); test/combat-parity/*.json (644) | tools/loader_check.gd, local only | yes | generic.placeholder data.gd:678 |
| encounter-systems | I-02 | Melee exchanges (DirMelee) | planMelee beat ops, clashWave, strike, launchBeat | melee.gd (537), melee.js (156) | indirect parity.gd (godot-parity); sim job | yes | ambush refs in melee.js |
| encounter-systems | I-02 | Launch planner (DirLaunch) | Scores launch candidates with flight predictor, applies launch | launch.gd (1383), launch.js (33) | launch_cost/launch_cuts/launchbiome tools, local only | yes | 'strip column' wording launch.gd:70-91 is heightfield cache, not arena |
| encounter-systems | I-02 | Opponent AI (DirAI) | AI tempo, stance picks, location, escape cover | ai.gd (501), ai.js (54) | beam_ai_check local; net rollback --ai (net job) | yes | hiding/cover live ai.gd:108-111 |
| encounter-systems | I-02 | Location variety (DirLocation) | Where the AI leads the fight between exchanges | location.gd (205) | sim/core/tools/fork_check.gd:96 (godot-parity); location_check local | yes | menace-meter role location.gd:105 |
| encounter-systems | I-02 | Bands + follow (DirBands, DirFollow) | Distance bands, approach, far taunt; far tap follows a send | bands.gd (603), follow.gd (61) | follow_check, arrive_check local | yes | none found |
| encounter-systems | I-02 | Brawl (DirBrawl) | Close-band brawl, one press one blow | brawl.gd (4305) | brawl_probe, brawl_cases local | yes | ambush brawl.gd:1387 |
| encounter-systems | I-02 | Control interrupts (DirInterrupt) | Perfect block, dodge cancel, burst, reversal inside an exchange | interrupt.gd (624) | press_answers_check, reads_check local | yes | none found |
| encounter-systems | I-02 | Press handling (DirPress, DirRefuse, DirMash, DirWindows, DirPulse) | Press cap, refusal cues, mash flow, windows vs hit-stop, pulse rule | press.gd (115), refuse.gd (73), mash.gd (46), windows.gd (77), pulse.gd (25) | press_decides_check in godot-parity (ci.yml:229) | yes | none found |
| encounter-systems | I-02 | Signature beams (DirBeam, DirSigAfter) | Beam plan, clash, fire, sweep; signature aftermath by variant | beam.gd (739), beam.js (120), sigafter.gd (202) | beam_front_check, sigvariants_check, sigafter_probe local | yes | biome sig variants live; menace in power beam.gd:208 |
| encounter-systems | I-02 | Beam plays (DirBeamPlay, DirBeamMove, DirBeamAim) | Travelling unanswered signature; stick beam own move; aimed beam | beamplay.gd (626), beam_move.gd (340), beam_aim.gd (93) | beam_move_check local | yes | anguish/menace branch beamplay.gd:508 |
| encounter-systems | I-02 | Blast + Driver (DirBlast, DirDriver) | Bolts, volleys, charged shot; RB+B Driver | blast.gd (538), driver.gd (157) | sim/core/tools/cross_check.gd:104 (godot-parity); driver_check local | yes | none found |
| encounter-systems | I-02 | Zip (DirZip) | LT mid-band dash strike in and out | zip.gd (1649) | zip_probe local | yes | hiding refs |
| encounter-systems | I-02 | Launch chase (DirChase, DirChaseTap, DirArc) | Chase of a launched rival; tap chase; meteor arc | chase.gd (376), chase_tap.gd (386), arc.gd (358) | chase_tap_check godot-parity (ci.yml:221); arc_check local | yes | none found |
| encounter-systems | I-02 | Stick + stances (DirStick, DirStance, DirStanceCost) | Right-stick strike; stance blows; circle price | stick.gd (893), stance.gd (137), stance_cost.gd (35) | stick_check, stance_check etc. local | yes | stick.gd:5 says rightStick false, timing.json:41 true |
| encounter-systems | I-02 | Alchemy/recipes/blur/phrases | Press log, recipe piece picks, blur cadence, phrases | alchemy.gd (462), recipe.gd (263), blur.gd (249), phrase.gd (237) | phrase_check, a_press_check local | yes | none found |
| encounter-systems | I-02 | Grapple (DirGrapple) | Collar catch with tell and pulse contests | grapple.gd (643) | none found | yes | duplicate in docs/director/pending/grapple-g1 |
| encounter-systems | I-02 | Rally/recoil/wallkick/water | Daze-sell-rally, backflip, wall kick, surfacing | rally.gd (847), recoil.gd (337), wallkick.gd (211), water.gd (133) | floorlift_check world job (ci.yml:403) | yes | none found |
| encounter-systems | I-02 | Buried fighter (DirBury) | Follow-up dive on an embedded fighter | bury.gd (248) | none found | yes | none found |
| encounter-systems | I-02 | Match ending (DirEnding) | KO by finisher only, idle wear, time cap | ending.gd (240) | ending_check local | yes | none found |
| encounter-systems | I-02 | 2v2 outside blow (DirOutside) | Blow from outside on an opening across fights | outside.gd (336) | outside_check local | yes | none found |
| encounter-systems | I-02 | Swing (DirSwing, DirSwingRead) | Scores world turn; camera-read score | swing.gd (1138), swing_read.gd (142) | net/tools/swing_check.gd (net job); swing tools local | yes | swing_read.gd:5 claims DirSwing calls it; it does not |
| encounter-systems | I-02 | Calm turn (DirCalm) | Calm-moment world turn decision | calm.gd (381) | net rollback --setup=calm (ci.yml:339) | yes | none found |
| encounter-systems | I-02 | Camera intent (DirCamIntent) | Publishes decided beats as camera cues | camintent.gd (360) | none found | yes | none found |
| encounter-systems | I-02 | Intro composer (DirIntro) | Picks intro scenario, order, gap, parts | intro.gd (214) | none found | yes | none found |
| encounter-systems | I-02 | Plane return (DirPlane) | Eases fighter back to the plane after depth flight | plane.gd (139) | plane_check world job (ci.yml:405) | yes | none found |
| encounter-systems | I-02 | Town levers (DirVisit, DirWalk, DirRelief) | Town visit landing, walk-to-wall carry, building-send factor | visit.gd (109), walk.gd (134), relief.gd (70) | walk_check, relief_check local | yes | none found |
| encounter-systems | I-02 | Pace match (DirPace) | Easy AI tap gap follows player's median | pace.gd (85) | pace_check local | yes | none found |
| encounter-systems | I-02 | Director tools | Checks, probes, tick hash, profiler, tempo stats | sim/director/tools/*.gd 65 files (13984) | 5 in CI (ci.yml:221,229,269,403,405); 60 local only | unreached (git grep director/tools/<name> outside docs: only 5 CI hits, brawl_probe/walk_check mentioned in qa/godot comments, loader_check in exchange.gd comment) | untracked local gate runner |
| encounter-systems | I-08 | Director data | AI levels, interrupts, launch, stick, swing, alchemy, location, rally | data/director 8 (1685) | godot-parity gates chase_tap_check, press_decides_check (ci.yml:221,229) | yes | swing.json:163 anguish |
| encounter-systems | I-09 | director/pending | Encounter parks: grapple, rally, return, one-v-many, chase, beam, charge, two-fights, swing | 74 tracked (10307) + 78 untracked; 5 deleted | probes/*.gd per park, not in CI | yes | one-v-many-s2/s3 waiting (DirRing absent); plan-cost and swing-warm WITHDRAWN but still present |
| ep | I-10 | EP landing gate | Runs ~100 headless checks plus every CI res:// script on a scratch tree, writes r.txt ending ALLDONE/CIDONE | docs/ep/gate/run-gate.sh (51), render-gates.sh (14), README.md (12) | none found (it is the gate; not in any workflow) | yes | golden_cmp only printed on equal (run-gate.sh:43) |
| ep | I-10 | ADR log | 13 ADRs, all status accepted | docs/decisions/0001-0013 (17-51 each) | none found | not evidenced (implementations: project.godot:10 (0001), qa/run-all.js (0004), sim/input/layout.gd (0008), depth.gd (0009), tools/flash/side-by-side.mjs (0010), swing.gd (0012)) | no ADR marked superseded though 0011 item 3 and 0012 item 2 are replaced |
| game-design / ep | I-10 | Design toy and EP prototypes | Single-file HTML toys/prototypes | docs/design/toys/beam-answers-toy.html (220); docs/ep/prototypes/*.html (9) | none found | unreached (doc artefacts; no code references searched beyond docs) | paper only (beam-answers-2.md:3) |
| legal-ip | I-12 | Legal docs | Screens, rulings, licence drafts, review log, banned-move data | docs/legal (68 files) | anim_check.gd:6860 gate reads movegen-banned.json | yes | pose rules left Legal 2026-11-07 yet data still in docs/legal |
| narrative-identity | I-08 | Fighter roster data | Roster (PROTAGONIST, RIVAL, REFERENCE), bench, per-fighter fighter/meters/forms | data/fighters 8 (268); sim/core/fighter_data.gd (703) | parity.gd in godot-parity (ci.yml:191) | yes | RIVAL/meters.json:5 menace, PROTAGONIST/meters.json:5 anguish |
| narrative-identity | I-09 | narrative/pending | 20 JSON content files (titles, planet names, keepsakes, campaign templates) | 20 tracked (12655) | none found | unreached (sampled values absent from HEAD outside docs) | All still waiting; menace in story_beats.json |
| narrative-identity | I-13 | Narrative line lint + beat check | Lints lines against line-lint.json rules; checks beat templates against Legal ln04/ln05 | docs/narrative/line-lint.py (249), beat-check.py (92) | none found | unreached (manual only: data/narrative/live_barks.json:7640; searched .github and tools/) | none marked |
| narrative-identity | I-13 | Voice lab sheets | CSV line batches with Orb-edit column | docs/narrative/voice-lab/ 12 files | none | not evidenced (records only) | kai.csv, vorr.csv placeholder names (kai.csv:2) |
| netcode-online | I-06 | Rollback session | Per-peer rollback over the deterministic sim with snapshots (net/session.gd:3-5) | net/session.gd (635), net/snapshot.gd (408) | net/tools/rollback_check.gd; ci.yml godot-parity :247-263 and net :315-346 | unreached (No caller outside net/ and docs/ except NetSnapshot in qa/godot/ai_compare.gd:55) | takeover/dropSlot only from rollback_check |
| netcode-online | I-06 | Loopback harness | Two peers in one process over simulated lossy links (net/loopback.gd:3-11) | net/loopback.gd (269), net/link_transport.gd (30) | used by all net checks (ci.yml net, godot-parity) | yes | none |
| netcode-online | I-06 | Desync detection | Checkpoint digest exchange and mismatch report (net/desync.gd:3-5) | net/desync.gd (381) | desync_check.gd; ci.yml net :294-300, :365-367 | yes | none |
| netcode-online | I-06 | Spectator | Input-less peer playing confirmed inputs via jitter buffer (net/spectator.gd:3-6) | net/spectator.gd (145) | spectator_check.gd; ci.yml net :302-304 | yes | none |
| netcode-online | I-06 | Adaptive input delay | Pure delay chooser from RTT and device speed (net/delay.gd:3-5) | net/delay.gd (74) | delay_check.gd; ci.yml net :306-308 | yes | peer delay uncapped in handshake (audit/2026-11-07 cold-reviews.json:545) |
| netcode-online | I-06 | Transport, ENet, handshake, time sync, host | Unreliable link abstraction + wire codec, ENet impl, RTT/delay handshake, frame-advantage sync, peer host | net/transport.gd (168), enet_transport.gd (144), handshake.gd (114), timesync.gd (84), host.gd (209) | transport_check.gd ci.yml net :310-312; enet_check.gd+enet_peer.gd ci.yml net :378-382 | unreached (only net/lan.gd and net/tools; desktop presets exclude net/* (export_presets.cfg:55,101,132), Web preset does not (:11)) | unvalidated kind-2 packets, takeover slot unchecked (sweep-a2.json:8) |
| netcode-online | I-06 | LAN 1v1 (private) | Two-PC home-network match stepping sim via NetHost (net/lan.gd:3-6) | net/lan.gd (545), net/tools/lan_kit.mjs (202), lan_words.txt (47) | lan_check.gd ci.yml net :354-356; kit none | unreached (lan_kit.mjs:1-2 patches calls into scratch copy; sim/ mentions NetLan only in comments (sim/core/sim.gd:364)) | none |
| netcode-online | I-06 | Net test players | Seeded scripted bot and AI driver as net players (net/bot.gd:3-6, ai_driver.gd:3-6) | net/bot.gd (205), net/ai_driver.gd (84) | rollback/desync checks; ci.yml net :315-321 | yes | none |
| netcode-online | I-06 | Net straight run | Non-networked reference run with per-tick digests (net_straight.gd:3-5) | net/tools/net_straight.gd (34) | via enet/transport checks | yes | none |
| netcode-online | I-06 | Word and swing checks | Right-stick intent word over wire; forced swing flip under rollback | net/tools/word_check.gd (349), swing_check.gd (492) | ci.yml net :342-344, :359-361 | yes | stand-in swing trigger, no director asks for swing (swing_check.gd:2) |
| netcode-online | I-06 | Two-PC processor check | Writes and compares per-PC match check numbers (two_pc_check.gd:2-5) | net/tools/two_pc_check.gd (279), two_pc_kit.mjs (52) | ci.yml net :349-351; kit none | yes | none |
| netcode-online | I-06 | Rollback bench | Cost of tick, snapshot, per-frame by profile (rollback_bench.gd:2-5) | net/tools/rollback_bench.gd (143) | none found | unreached (git grep in .github and tools: no caller) | phone estimate (rollback_bench.gd:4) while mobile parked |
| per folder | I-13 | Media outputs and md records | 747 tracked stills/gifs/wavs/svgs; 775 md records indexed | see record index in the output file | none | not evidenced (records only) | counted, not read |
| per-area directors; docs/qa, docs/sim, docs/tools unplaced | I-11 | Run records | saved gate output per area and commit (14 areas) | docs/*/runs (1042 tracked, 1307 on disk) | n/a | yes | nothing newer than 6a30b4c9; non-sha folders mms-2026-11-10, globe-step2 |
| performance-platform | I-13 | Phone web shell + head block | Builds/checks the Web preset's phone head block from docs/perf/web-shell; page shell and local-only freeze crumbs | docs/perf/tools/web-head.mjs (120), web-shell/ocx-shell.js (65), ocx-crumbs.js (243), manifest, icons, make-placeholder-icons.mjs (43) | ci.yml job data (ci.yml:99); site job folds crumbs (ci.yml:426-427) | yes | placeholder icons (make-placeholder-icons.mjs:2); crumbs a park, off (tools/site.json has no crumbs key) |
| performance-platform | I-13 | Perf browser benches | Guarded-browser frame/latency/load/freeze/crumbs benches and report writers | docs/perf/tools/frame-bench.mjs (239), latency-bench.mjs (170), load-probe.mjs (153), freeze-probe.mjs (149), crumbs-test.mjs (168), make-audit-sites.mjs (165), stage-*.mjs, phone-emu-check.mjs (142) | none found | unreached (named only in docs/perf/README.md and other docs; searched .github, tools/) | none marked |
| performance-platform | I-13 | Perf scratch hooks | Patch scratch copies of the game with timers/marks | docs/perf/tools/scratch-hooks/ 49 files (hook-stages.mjs 240 largest) | none found | unreached (named in docs/rendering/tools/lake-hook.mjs:3 only) | hook-strip.mjs, hook-dissolve.mjs by name |
| performance-platform | I-13 | Swing bench | GDScript benches and scratch patchers for swing/launch/stage tick cost | docs/perf/tools/swing-bench/ 34 files (swing_bench2.gd 180) | none found | unreached (docs/perf/swing-tick-2026-10-31.md only) | none marked |
| performance-platform | I-13 | Pre-play read tools | Headless Chrome first-play reads and replay benches | docs/perf/tools/preplay/ preplay-read.mjs (187), replay_reads.gd (130), replay_prof.gd (113), perf-run.mjs (46, modified); 2 untracked mjs | none found | unreached (docs/perf/README.md; crackle-ab.mjs:4) | none marked |
| performance-platform | I-13 | Old-PC kit | Serves a build to one LAN PC, collects its report, compares tick timings and hashes | docs/perf/oldpc/oldpc-server.mjs (114), page.html (239), kit/oldpc_sim.gd (120), kit/run-test.template.cmd (183), compare-results.mjs (94) | page-selftest.mjs manual; no CI | unreached (docs/perf/oldpc-test-2026-10-31.md) | none marked |
| qa-balance | I-06 | Legacy prototype regression suite | Node tests on prototype: tables, determinism, seam, soak, diff, known-bugs, selftest (qa/run-all.js:2-6) | qa/run-all.js (41), qa/tests/*.test.js (543), qa/lib/*.js (260) | ci.yml qa job :30-43 | yes | self-labelled LEGACY (run-all.js:2) |
| qa-balance | I-06 | Prototype balance and known-bug tools | Balance report, baseline diff, known-bug repro/scan/whatif, timing-edge | qa/balance-report.js (273), baseline-diff.js (108), known-bugs-*.js (172), timing-edge.js (138) | diff.test.js, known-bugs.test.js in qa job | yes | KAI/VORR in balance-report.js and baseline-p0.* |
| qa-balance | I-06 | Godot QA batch (run-godot) | Headless AI-vs-AI batches, band checks, pending acceptance tests (qa/run-godot.js:4-10) | qa/run-godot.js (164), godot/records.gd (1137), bands.js (791), godot.js (72), pending-tests.js (184), qa_planet.gd (81) | qa/godot/selftest.js (494), not in any workflow | not evidenced (manual; qa_planet.gd preloaded by tools/feel/gauntlet.gd:13) | menace/anguish (records.gd:979-980), hidden/ambush (:450,:1116), biome sig variants (bands.js:359); 3 uncommitted edits |
| qa-balance | I-06 | Godot QA probes and reads | Scripted players, masher, stick, charge, return, downtime, probes, black-box traces | players.gd (1454), stickplay.gd (398), gp.gd (232), lap.gd (233), others under qa/godot | none found | not evidenced (masher.js:14,32,68 and feel.js:11 spawn some; rest manual) | probe_arc_land.gd, probe_meteor_side.gd lack headers |
| qa-balance | I-06 | Godot QA read scripts (Node) | One-off record post-processing tables per brief | masher.js (657), swing-rows.js (158), compare-arms.js (79), ~15 small scripts | none found | not evidenced (manual CLI only) | brief-specific one-offs |
| qa-balance | I-06 | Prototype headless tools | Mock-DOM harness, match runner, stats, batch runner, screenshot | prototype/tools/headless.js (50), match-runner.js (168), stats.js (164), sim-stats.js (47), screenshot.js (10) | qa job via qa/tests | yes | screenshot.js usage path stale (screenshot.js:1) |
| rendering-techart | I-04 | Boot and entry | Boot line, spread shader compile, warm-up draw, then loads main.tscn | render/boot_entry.tscn (6), render/core/boot_entry.gd (104), boot.gd (317), warmup.gd (110) | none found | yes | none found |
| rendering-techart | I-04 | Main scene and sim host | 60 Hz fixed-step SimHost loop, panes, split rig, input and debug keys | render/main.tscn (19), core/main.gd (1779), core/sim_host.gd (685), core/key_codes.gd (24) | render/tools/determinism.gd in CI godot-parity (ci.yml:265) | yes | debug keys F2/F7-F11 in shipped scene main.gd:7-43 |
| rendering-techart | I-04 | Legacy greybox HUD | F2 overlay: HP/ki/power/tier/stance plus MENACE or ANGUISH bar | render/core/hud.gd (328) | hud_words_check.gd, not in CI | yes | menace/anguish hud.gd:228-233; HIDDEN hud.gd:203,208,245 |
| rendering-techart | I-04 | Planet and pane world | Wrapped planet ground/water to horizon, far land, water fill, ground band, optional tile ground | core/planet_view.gd (3004), pane_world.gd (1194), ground_field.gd (671), tile_field.gd (771), tile_ground.gd (709), far_land.gd (259), water_fill.gd (147) | seam_sweep, sweep_check, cover_water_check, lake_water_check in CI godot-parity (ci.yml:267-277) | yes | tile ground off (tile_ground.gd:14) |
| rendering-techart | I-04 | City, props, cover, trees | Re-laid city shapes/lanes, props, biome cover silhouettes, fellable trees | core/shapes.gd (665), lanes.gd (73), prop_view.gd (228), cover_view.gd (215), cover_meshes.gd (808), tree_view.gd (155), biome_look.gd (162) | props_check in CI (ci.yml:273); shape/city/lane/open/stage checks not in CI | yes | none found |
| rendering-techart | I-04 | Crowd | Civilian mesh, chunked crowd, evacuation from evacuate events | core/crowd_mesh.gd (67), crowd_chunks.gd (103), crowd_flight.gd (224) | flight_check, not in CI | yes | none found |
| rendering-techart | I-04 | Fighter greybox view | Fighter primitives plus mannequin, head flashes, damage stages, outline bake | core/fighter_view.gd (627), flash_view.gd (391), flash_set.gd (100), damage_look.gd (82), outline_bake.gd (117) | flash_check, flash_reg_check, outline_check, depth_check: not in CI | yes | hiding fade f.hidden fighter_view.gd:440-530 |
| rendering-techart | I-04 | Beams, particles, impact fx | Beam prisms and clashes, fx particles, crater ejecta/dust/heat | core/beam_view.gd (190), particle_view.gd (227), impact_fx.gd (301) | not evidenced | yes | none found |
| rendering-techart | I-04 | Sky and camera roll | Dynamic sky driver; dutch tilt on climaxes | core/sky_drive.gd (538), camera_roll.gd (107) | sky_check, not in CI | yes | CAMERA_ROLL_ON=false look.gd:539 |
| rendering-techart | I-04 | Look constants, materials, shaders | Greybox colours/dimensions, materials, 57 shader files | core/look.gd (952), mats.gd (234), render/shaders 36 files (3894) | indirect via render checks | yes | look.gd:1 placeholder values |
| rendering-techart | I-09 | rendering/pending | About 50 dated render parks (tiles, craters, water) plus swing-test scratch tooling | 22 tracked (2730) + 100 untracked | none found | unreached (no code refs) | Most on main; crater-look-default, others-near, tile-keys apply clean (waiting) |
| rendering-techart | I-13 | Rendering tool hooks | Scratch hooks for look-gate stills/profiling; shader compile and link timing | docs/rendering/tools/ 6 files (prof-hook.mjs 144, props-hook.mjs 99, lake-hook.mjs 87) | none | yes | none marked |
| research-prototyping | I-12 | engine-spike | Godot/web/C# comparison with golden hashes | research/engine-spike shared/*.mjs (479) + builds, results | none found | yes | none found |
| research-prototyping | I-12 | band-proto | Standalone Godot depth-ground prototype | research/band-proto/main.gd (1058) | built+deployed ci.yml:432-438 | yes | 'strip' main.gd:4 |
| research-prototyping | I-12 | planet-gen | JS climate/plates/erosion prototypes | gen/*.mjs (1480), lib/*.mjs (519) | b_check.gd via tools/world-checks.json:5, ci.yml:384-401 | yes | 96 untracked images |
| research-prototyping | I-12 | ring-any-angle | 3D planet turntable prototypes and benches | sim.js (367), proto-v2.html (568), ~20 files | tools/preview/stack-selftest.mjs:49 copies swing_smoke.gd.txt | not evidenced (code cites docs/world/ring-any-angle/*, not research/) | GEN2PACK blob proto-v2.html:29 |
| research-prototyping | I-12 | rule-of-cool | Feel pitches, pad page, beam-contact bench | feel.html (583), md papers, mjs | none found | yes | 8 untracked clips |
| research-prototyping | I-12 | right-stick/rally/energy protos | Throwaway JS sims and GIF builders | right-stick v3/sim-core.js (721), rally sim.js (506), energy sim.js (989) | right-stick tools harness, not in CI | unreached (git grep outside research/docs: none) | 'strip' in rally sim.js |
| research-prototyping | I-12 | info-hiding | Partial one-screen hiding testbed (parked) | core/*.mjs (466) | none found | unreached (git grep info-hiding: none outside research/docs) | backburnered hiding/ambush sim.mjs:11-12 |
| simulation-engine | I-01 | Sim core tick + state (SimCore, SimState) | Fixed-step tick and newMatch (sim.gd:1-4); the whole state, twin of JS S (state.gd:3-5) | sim/core/sim.gd (468), state.gd (1262), sim.js (102) | parity.gd in godot-parity (ci.yml:191); JS in sim job | yes | menace/ambush fields state.gd:923,1086 |
| simulation-engine | I-01 | Math/wrap/RNG/detmath/hash/replay | Wrap math, JS-exact helpers, mulberry32, deterministic trig, canonical hash, replay v4 | wrap.gd (18), mathx.gd (77), rng.gd (70), detmath.gd (147), hash.gd (460), replay.gd (240), constants.gd (39) + JS twins | parity.gd, replay_xproc_check, rec_check, two_states_check (godot-parity); wrap/seam/replay .test.js (sim job) | yes | hash walks menace/ambush |
| simulation-engine | I-01 | Fighter, damage, roster, wounds | stepFighter/impact, hurt/hit/ko, fighter build from data, region wear | fighter.gd (829), damage.gd (157), roster.gd (65), fighter_data.gd (703), wounds.gd (471) | parity.gd (godot-parity) | yes | menace/anguish live damage.gd:50-56, fighter.gd:686-705; roster.js:5-6 KAI/VORR; placeholder transform fighter.gd:568 |
| simulation-engine | I-01 | Hiding/ambush (SimHiding) | ESCAPE lock-break; canHide-only hiding; ambushUntil after 1.8s | hiding.gd (101), hiding.js (15) | parity.gd | yes | backburnered ambush still live hiding.gd:43, damage.gd:59 |
| simulation-engine | I-01 | Clock/hitstop, act, mood, pause, intro, shots | Hit-stop hold and budget; intent-v2 act rules; mood/style; set-piece pauses; intro fall; energy shots | clock.gd (14), hitstop.gd (262), act.gd (133), mood.gd (601), pause.gd (215), intro.gd (522), shots.gd (815) | parity.gd | yes | hitstop enabled=false |
| simulation-engine | I-01 | Feel switches: forms, power, kick, brake, flight, ricochet, depth | Hero steps, energy model, kick/coin turn, air brake, launch curve, glance, depth lanes | forms.gd (591), power.gd (250), kick.gd (203), brake.gd (233), flight.gd (316), ricochet.gd (172), depth.gd (118) | power_check, kick_check (godot-parity); others via parity.gd | yes | all enabled=false in data |
| simulation-engine | I-01 | Field world + swing, two fights + cross | Great-circle line through a field planet, turntable swing; two fights on one line; hits across fights | field.gd (814), swing.gd (721), stage.gd (360), cross.gd (508) | frame_check, field_static_check, cross_check, cross_end_check (godot-parity) | yes | 'strip' = line coordinate, not flat arena; cross enabled=false |
| simulation-engine | I-01 | Fx emitters + view consumers | FxEvents out of sim; reference camera and cosmetic consumer | fx.gd (749), events.gd (10), view/camera.gd (66), view/fx.gd (334) + JS | parity.gd; fx.test.js (sim job) | yes | camera.gd:5 names Camera as owner |
| simulation-engine | I-01 | Director bridge, planet load, run/boons/cata | Director calls by path; sliced planet load; run state, boons, ash | dir.gd (162), planet_load.gd (206), run.gd (570), boons.gd (126), cata.gd (85) | load_split, places_check (godot-parity) | yes | none |
| simulation-engine | I-01 | Campaign (SimCampaign) | Episode = run + arc block, five columns | campaign.gd (480) | none found in CI | not evidenced (only checkArc at sim/core/run.gd:391; no host caller) | switched off |
| simulation-engine | I-01 | JS frozen core + GDScript gate/tools | Prototype-parity record; parity.gd golden gate; 33 checks/probes | sim/core/tools 34 files, parity.gd (6878), frame_check.gd (1065) | sim job (ci.yml:47-61); godot-parity 13 tools; web-parity.yml:59 | yes | no CI ref: ceil/coop/fights/loop_check, run_ground, tick_prof, batch; HORIZON CLEAVE cross_check.gd:258 |
| simulation-engine | I-09 | architecture/pending | Sim slices: power-flip (energy model data switch), clock-by-body prototype, 4 notes | 5 tracked (709) + 5 untracked | none found | unreached (qa/godot/approach.gd:2 names an absent park, kick-keep-top) | power-flip still waiting (0/8 keys). KAI/VORR in fighter-split.md:5, though the rename is on main |
| simulation-engine | I-10 | Planet proof scripts | Scratch JS/GDScript twins of World's planet function plus comparer | docs/architecture/planet-proof/ 7 files (26-192 each) | none found | unreached (only docs refer: planet-slice-core.md:47, docs/world/planet-module.md:3) | needs planet_lib.gd outside the folder (README.md:7,15) |
| simulation-engine | I-10 | Reference core (overview, module-spec, determinism, fx-events) | Deterministic GDScript sim, JS frozen at 9ac1ea9; fx as events | sim/core/sim.gd (468), state.gd (1262), hash.gd (460), fx.gd (749) | ci.yml sim job (:47), godot-parity parity.gd (:178) | yes | overview.md, module-spec.md undated |
| simulation-engine | I-10 | Built-but-off core features (depth, power, forms, brake, flight, hitstop, ricochet, kick, run, campaign) | Each behind a data switch; with it off the sim is unchanged | depth.gd (118), power.gd (250), forms.gd (591), brake.gd (233), flight.gd (316), hitstop.gd (262), ricochet.gd (172), kick.gd (203), run.gd (570), campaign.gd (480) | godot-parity: parity.gd, power_check, kick_check; campaign_episode in EP gate | yes | stale plan headers: fight-lanes.md:3, run-core.md:1; power-flip parked untracked |
| simulation-engine | I-10 | Wounds, mood, acts, pauses, last stand, intro | Wear and guard wear, fight mood/acts, set-piece pauses, free signature at brink, composed intro | wounds.gd (471), mood.gd (601), act.gd (133), pause.gd (215), intro.gd (522), fighter.gd (829) | godot-parity parity.gd | yes | docs still say plan: last-stand.md:3, intro-phase.md:3, mood-style.md:2, q10:3, wounds-plan.md:3 |
| simulation-engine | I-10 | 2v2 fight swap and cross-fight hits | Two fights on one line, hits across fights, KO'd fighter out | sim/core/cross.gd (508), stage.gd (360) | godot-parity cross_check, cross_end_check | yes | two-v-two-lines/-sim/-globe are paper; 'old strip' noted two-v-two-lines.md:3 |
| simulation-engine | I-10 | Field world and swing (ADR 0012) | Great-circle line and turntable on planetGen 3 | sim/core/field.gd (814), swing.gd (721) | godot-parity field_static_check, memo_check, frame_check (ci.yml:215,257) | yes | field-ground.md undated, uncommitted edit |
| simulation-engine | I-10 | Rollback support (snapshot-tick, packed-structures, fork-check, web-parity, planet-load, load-split) | Cheap snapshots, packed arrays, static-leak check, native/web bit parity, staged loads | state.gd, planet_load.gd (206), tools/fork_check.gd (129), tools/web_parity.mjs | godot-parity fork_check, load_split (ci.yml:210-214); web-parity.yml:59 | yes | fork-check.md undated |
| simulation-engine (code) | I-10 | Hiding (backburnered) | Hidden lock break and regain | sim/core/hiding.gd (101) | godot-parity parity.gd | yes | design says parked (future-stealth-fighter.md:3) but called every tick |
| simulation-engine (doc) | I-10 | Intent record (intent-v2, intent-v5) | Packed per-slot input word, version 4 | sim/input/intent.gd (301) | net job intent second word (ci.yml:340) | yes | v5 paper; intent.gd:15 VERSION 4 |
| simulation-engine (per project.godot:2); unplaced in DIRECTORS.md | I-14 | Project settings | Godot project name, main scene render/boot_entry.tscn, Compatibility renderer, globe_r global | project.godot (26) | web-parity.yml path filter :14,23 | yes | none |
| tools-pipeline | I-07 | CI workflows (9) | ci.yml 9 jobs (qa, sim, data, flash, godot-parity, net, world, site, deploy) on push/PR; content-screen, workflow-lint on push; web-parity path+nightly; player-watch daily; takedown, desktop-builds, flash-pixels-dryrun, web-template manual | .github/workflows/ci.yml (504), desktop-builds.yml (179), web-template.yml (104), flash-pixels-dryrun.yml (77), web-parity.yml (59), takedown.yml (39), player-watch.yml (36), workflow-lint.yml (32), content-screen.yml (30) | self (check-workflows lint in ci.yml data and workflow-lint.yml) | yes | ci.yml:384 comment says 48 world scripts, list has 85; timeouts raised 2026-11-08 (ci.yml:109,181,285,390) |
| tools-pipeline | I-07 | Data validator | Strict JSON parse, schema and cross-reference checks of all data | tools/validate.js (78), lib/core.js (184), lib/schema.js (249), lib/xref.js (887), lib/xref-fight.js (1990), lib/selftest.js (241), 10 xref-*.js | validate.js --self-test, ci.yml data | yes | backburnered anguish/menace fields in schemas (fighter-meters.schema.json:5, director-swing.schema.json:457); sigvariants mapped (map.json:47); NUL bytes in core.js:148 |
| tools-pipeline | I-07 | Moveset generator | JS port of Combat's moveset generator with pools, sheet, names screen | tools/movegen/ (3669 total; lib/generator.mjs 1544) | movegen/test/run.mjs, ci.yml data | yes | none found |
| tools-pipeline | I-07 | Determinism lint | Fails sim files using engine trig/PI/random/clock | tools/lint-determinism.mjs (131), -selftest (63) | ci.yml data | yes | none |
| tools-pipeline | I-07 | Two-fighter ratchet | Counts places code names exactly two fighters; one-way baseline | tools/ratchet-two-fighter.mjs (84), -selftest (58) | ci.yml data | yes | baselines sim/core/hiding.gd (ratchet-two-fighter.json:48) |
| tools-pipeline | I-07 | Gate wrapper | Fails a Godot run with SCRIPT ERROR lines whatever its exit code; --verdict mode | tools/gate.mjs (82), gate-selftest.mjs (56) | ci.yml flash | yes | none |
| tools-pipeline | I-07 | World checks list | Lists and runs sim/world/tools checks through gate --verdict | tools/world-checks.mjs (51) | ci.yml world | yes | stale count comment ci.yml:384 |
| tools-pipeline | I-07 | Flash check (count + pixels + release pass) | Plays worst cases, recounts flash register; captures and analyses WCAG 2.3.1 clips, release pass, signature gate, nightly seeds | tools/flash/ (7505; flash_worst.gd 512, release-pass.mjs 351, wcag.js 374) | 11 self-tests + flash_worst + negative control in ci.yml flash; pixel run manual (flash-pixels-dryrun.yml) | yes | full pixel half not in CI (ci.yml:104); side-by-side.mjs (look gate) in no CI job |
| tools-pipeline | I-07 | Public site builder and checks | Builds Pages site (offline notice or pinned/interim build) and checks offline, interim terms, capture hook, template | tools/build-site.mjs (314), check-site-interim.mjs (458), site-*.mjs, check-site-*.mjs, site_licences.gd (25), write-build-info.mjs (36) | site self-tests in ci.yml flash; ci.yml site job; takedown.yml | yes | site-name-scan hunts KAI/VORR (site-name-scan.mjs:14); template custom vs empty custom_template in export_presets.cfg:23 |
| tools-pipeline | I-07 | Player watch | Reads live /play/ and compares with repo | tools/player-watch.mjs (121), -selftest (56) | player-watch.yml | yes | none |
| tools-pipeline | I-07 | Content screen | Fails a push carrying banned/user-profile content in the public repo | tools/content-screen.mjs (151), -selftest (118) | content-screen.yml | yes | none |
| tools-pipeline | I-07 | Desktop packaging | Desktop download README/notices, Reduce-flashing lock, route refusal, package verify | tools/desktop-package.mjs (409), -selftest (258) | ci.yml flash self-test; desktop-builds.yml | yes | none |
| tools-pipeline | I-07 | Private preview / stack | Local private web build of main or HEAD+parks with switches; smoke, bisect, pck-verify, black box, LAN report | tools/preview/ (5816; switches.mjs 1055, stack.mjs 596, blackbox.mjs 517) | preview/stack/pck-verify self-tests in ci.yml flash; lan-clip-selftest not in CI | yes | clip-script.mjs unreached (git grep clip-script: no caller or doc) |
| tools-pipeline | I-07 | Browser launcher guard | Single guarded headless-browser launcher with Job Object, capture list and cleanup | tools/machine/ (933; browser.mjs 303, capture-job.ps1 157) | machine/selftest.mjs not in CI | yes | none |
| tools-pipeline | I-07 | Feel kit | Replays a saved match with a candidate rule; refusal ledger; scheme gauntlet | tools/feel/ (1384; feel.gd 493, gauntlet.gd 336) | self-tests not in CI | not evidenced (only docs/tools/feel.md references) | none |
| tools-pipeline | I-07 | Clip kit | Clips from a built page with a button strip; GIF/WebM encode; seed scan | tools/clips/ (935; make.mjs 370, encode.py 190) | clips-selftest not in CI | not evidenced (docs/tools/clips.md; mms-scan only in docs/tools/pending) | mockups/*.py one-off image edits |
| tools-pipeline | I-07 | Right-stick capture | Pad capture page and analysis | tools/capture/ (1274) | none in CI | not evidenced (docs/controls/right-stick-capture.md only) | none |
| tools-pipeline | I-07 | Pad lab | Pad tuning maths, page and local server | tools/padlab/ (1528) | padlab-selftest not in CI | not evidenced (docs/tools/padlab.md only) | none |
| tools-pipeline | I-07 | Localisation tools | String extraction, pseudo-locale, overflow report (not a gate) | tools/l10n/ (999) | none found | unreached (no reference in .github or qa/run-all.js; only docs/accessibility and audit/2026-11-07) | none |
| tools-pipeline | I-07 | Engine patch / web template | Godot 4.7.2 lazy-specialisation patch, native link-count A/B, template usage scan | tools/engine/ (115), tools/wasm/usage-scan.mjs (83) | web-template.yml (manual) | yes | usage-scan only in docs/tools/web-template-size.md |
| tools-pipeline | I-07 | Misc root tools | bench-web, setup scripts, director roster generator, pin-child | bench-web.mjs (234), setup.* (4/65/65), gen_directors.py (510), pin-child.mjs (168) | pin-child-selftest in ci.yml flash; others none | yes | gen_directors.py keeps menace/anguish, hiding/ambush, ego (gen_directors.py:26,57,172,185) |
| tools-pipeline | I-08 | Schema validator | Validates all JSON under data/, audio/data, ui/data, audio/music against map.json rules plus cross-refs | tools/validate.js (78), tools/lib/core.js (184), tools/lib/xref.js (887), xref-fight.js (1990), xref-input.js (225) | validate.js --self-test and validate.js, CI job data (ci.yml:77,81) | yes | none; no orphan schemas |
| tools-pipeline | I-08 | Switch table | 92 rows (85 data keys, 7 page words/setup) the private preview flips in a scratch copy | tools/preview/switches.mjs (1055) | preview-selftest.mjs in CI job flash (ci.yml:148); stack-selftest, pck-verify-selftest | yes | 12 rows have stale from (main already at to), e.g. rightStick switches.mjs:30 |
| tools-pipeline | I-11 | CI main pipeline (ci.yml) | 8 check jobs plus a GitHub Pages deploy on main | .github/workflows/ci.yml (504) | qa/run-all.js, npm test sim, Godot gates via tools/gate.mjs | yes | 15/30 cancelled with 0 jobs despite the 'every main run finishes' comment (ci.yml:23-27); no completed run after 3a03e03f |
| tools-pipeline | I-11 | Content screen | content-screen self-test and screen on push | .github/workflows/content-screen.yml (30) | tools/content-screen(-selftest).mjs | yes | none |
| tools-pipeline | I-11 | Desktop builds | dispatch-only desktop package build and verify | .github/workflows/desktop-builds.yml (179) | desktop-package self-test in ci.yml flash job (:133) | unreached (gh run list: 0 runs) | never run; LAN exes come from net/tools/lan_kit.mjs |
| tools-pipeline | I-11 | Flash pixels dry run | dispatch pixel flash run, 120 min | .github/workflows/flash-pixels-dryrun.yml (77) | itself | yes | stale |
| tools-pipeline | I-11 | Player watch | daily cron self-test and watch | .github/workflows/player-watch.yml (36) | tools/player-watch-selftest.mjs | yes | none |
| tools-pipeline | I-11 | Takedown | builds and checks the offline-notice site | .github/workflows/takedown.yml (39) | tools/site-takedown.mjs, check-site-offline.mjs | yes | none |
| tools-pipeline | I-11 | Web parity | web vs native sim parity, push and nightly | .github/workflows/web-parity.yml (59) | sim/core/tools/web_parity.mjs | yes | none |
| tools-pipeline | I-11 | Web template | dispatch custom web template build | .github/workflows/web-template.yml (104) | itself | yes | stale |
| tools-pipeline | I-11 | Workflow lint | parses workflow files on push | .github/workflows/workflow-lint.yml (32) | tools/check-workflows(-selftest).mjs | yes | duplicated in ci.yml:93-96 |
| tools-pipeline | I-14 | Roster generator | Writes DIRECTORS.md, charters and roster README from one table | tools/gen_directors.py (outside slice, not counted) | none found | not evidenced (manual only (README.md:65); no gen_directors ref in .github) | rerun would revert camera.md hand edits |
| ui-ux | I-05 | HUD root (UiHud + UiLayer) | Control drawing the fight HUD as cached signature-gated layers | ui/hud/ui_hud.gd (4484), ui/hud/ui_layer.gd (46), ui_hud.tscn (13) | ui/tools/hud_check.gd; no CI job | yes | none marked |
| ui-ux | I-05 | Event hub + fighter model | Turns host events into per-fighter HUD view models, bark timing, caps | ui/core/ui_event_hub.gd (1696), ui_fighter_model.gd (331), ui_bark_timing.gd (49), ui_stance.gd (174), ui_prefs.gd (38) | hud_check, render/tools/bark_check.gd; no CI | yes | ego/hidden patch keys ui_event_hub.gd:598; ego ui_fighter_model.gd:54 |
| ui-ux | I-05 | Sim bridge | Reads sim state into HUD view models and planet-strip data | ui/core/ui_sim_bridge.gd (292) | hud_check; no CI | yes | menace/anguish ego meters ui_sim_bridge.gd:9, :89 |
| ui-ux | I-05 | UI data loader + pseudo-locale switch | Loads ui/data JSON; --pseudo-locale reads localization/pseudo twins | ui/core/ui_data.gd (437) | validate.js in CI data job (ci.yml:80); pseudo_switch_check.gd not in CI | yes | features.json hiding:false kept |
| ui-ux | I-05 | Layout/look/text core | Layout geometry, palette, fonts, icons, text warm-up, remap model, web clip | ui/core/ui_layout.gd (597), ui_look (176), ui_text (148), ui_icons (354), ui_body (117), ui_warm (74), ui_fast (5), ui_web_clip (153), ui_remap_model (182) | hud_check, text_size_check, tools/l10n/overflow_check.gd; no CI | yes | EGO menace/anguish colours ui_look.gd:43-45 |
| ui-ux | I-05 | In-fight HUD widgets | Static draw helpers: plates, crown, cards, strip, feed, faces, reads, prompts, split, tug, alert, planet map etc. | 21 files in ui/widgets (e.g. ui_plate 530, ui_split 428, ui_glyphs 299) | hud_check; no CI | yes | placeholder portraits ui_faces.gd:12; hidden ring ui_strip.gd:50 gated off; answer_alert/planet_map flags false |
| ui-ux | I-05 | Recipe readout | Press-mix text; PLACEHOLDER, not drawn | ui/widgets/ui_recipe.gd (17) | hud_check.gd:4252 | unreached (only ui/tools/hud_check.gd:4252 (grep UiRecipe over tracked .gd/.tscn)) | PLACEHOLDER ui_recipe.gd:2 |
| ui-ux | I-05 | Menus and overlays | Start, pause, settings, Rail, how-to, licences, loading, notice, join, turn, touch, feedback, hints | 13 ui/widgets files (ui_settings 827, ui_howto 743, ui_menu 719, ui_hints 676) | hud_check, tools/l10n/overflow_check.gd; no CI | yes | menus_rail:false on main |
| ui-ux | I-05 | Narrative barks | Live barks fed to HUD, null while disabled | ui/core/narrative_barks.gd (239) | not evidenced | yes | none seen |
| ui-ux | I-05 | HUD demo + mock feed | HUD over greybox driven by mock events; not part of game | ui/demo/hud_demo.gd (530), ui/mock/ui_mock_feed.gd (340) | none | unreached (UiMockFeed only in ui/demo/hud_demo.gd:15; main scene render/boot_entry.tscn) | greybox placeholders hud_demo.gd:504 |
| ui-ux | I-05 | UI check/bench tools | Headless HUD checks and benches | ui/tools/hud_check.gd (11033) + 11 others | none in CI; release-pass.mjs:315 names hud_check | not evidenced (manual only; grep of workflows/tools found no runner) | KAI/VORR only as negative asserts hud_check.gd:6634 |
| ui-ux | I-05 | Strings inventory | Lists player-facing ui/data strings | ui/tools/strings_inventory.py (188) | none found | not evidenced (manual script) | none |
| ui-ux | I-09 | ui/pending | UI parks: run-mode, run-boons, sound-line, warm-marks, hud-cache and others; 7 parks deleted in WT | 31 tracked (3057) + 16 untracked; 20 deleted | none found | unreached (no code refs) | run-mode, run-boons, sound-line, warm-marks waiting (keys absent); run-mode cites 'World's strip' |
| ui-ux | I-13 | UI mockups + schema drafts | Static HTML mockups (alert, combo builder, three menu styles); draft UI schemas | docs/ui/mockups/ 5 html (combo-builder 376); 3 *.schema.json | none | not evidenced (design source named by ui/widgets/ui_rail.gd:3, ui/hud/ui_hud.gd:1052) | drafts outside tools/schemas |
| unplaced | I-04 | Animation runtime | Per-fighter pose solve on rig R1, ragdoll, joints, zip body | anim/render_anim.gd (619), anim_fighter.gd (5912), anim_data.gd (612), anim_pose.gd (519), anim_joints.gd (582), anim_ragdoll.gd (629), anim_zip.gd (406), anim_rig.gd (212), anim_body.gd (109), anim_joint_lint.gd (124) | anim_check.gd (8300) not in CI; only tools/preview/bisect.mjs:18 | yes | ~45 static switches render_anim.gd:11-107 |
| unplaced | I-04 | Animation test-only libs | Held-pose lint and many-bodies helper | anim/anim_held_lint.gd (270), anim_many.gd (52) | anim_check.gd, not in CI | unreached (only anim_check.gd:1151, :1214 call them (git grep -w *.gd)) | none |
| unplaced | I-04 | Animation tools and wave pipeline | 37 labs/scans/lints/benches; wave_gen writes data/anim/waves | anim/tools 104 files (19258): anim_check.gd (8300), wave_gen.mjs (392), waves/*.mjs 57 | none in CI | not evidenced (manual tools; bisect.mjs:18 names anim_check) | KAI/VORR in a negative test anim_check.gd:6741 |
| unplaced | I-04 | Animation A0 spike | Standalone Godot project measuring skinning and layer costs | anim/spike/ (spike.gd 349, rig.gd 244, solve.gd 207, project.godot 22) | none found | unreached (own project.godot (README.md:3); only tools/ratchet-two-fighter.json:27) | spike kept in game tree |
| unplaced | I-04 | Render check and picture tools | Headless render checks and doc stills; flash_capture pixel hook | render/tools 34 .gd (7311): flash_capture (718), sky_check (504), flash_reg_check (440) | 6 in CI godot-parity (ci.yml:265-277); 28 not | yes | bark_check.gd is Narrative's parked check (line 1) |
| unplaced | I-06 | Browser prototype | Single-file canvas AI-vs-AI prototype, frozen since 7233c967 | prototype/index.html (1202), package.json (11), package-lock.json (281) | oracle for ci.yml sim and qa jobs | yes | KAI/VORR, menace/anguish, hiding/ambush, sig variants, 'planet strip' (index.html:1129) |
| unplaced | I-07 | Godot project settings | Main scene render/boot_entry.tscn, Compatibility renderer, globe_r shader global | project.godot (26) | imported by every Godot CI job | yes | project.godot:2 says Simulation holds it until Tools takes over |
| unplaced | I-07 | Export presets | Web, Windows, Linux, macOS presets excluding tools/docs/qa/test folders | export_presets.cfg (172) | ci.yml site export; desktop-builds.yml; web-parity path trigger | yes | desktop presets exclude net/*, Web does not (export_presets.cfg:55 vs 11) |
| unplaced | I-08 | Animation data | Poses, waves, joints, reactions for the animation layer | data/anim 180 files (17268); render/anim/anim_data.gd (612) | anim_check not in ci.yml run lines | yes | ragdoll_motion.json placeholder hits |
| unplaced | I-08 | Art look data | Biome, sky, damage, flash, city, effect looks for render | data/art 12 (8360) | validate only (data job) | yes | outposts, polar, auras, energy-lanes, vehicles, colour-vision tool/comment-only; 2 files uncommitted |
| unplaced | I-08 | Combat data | Templates, finishers, sigvariants, recipes, enders, phrases, stick, depth | data/combat 11 (13674); sim/director/data.gd (793) | validate (data); director gates in godot-parity (ci.yml:221,229) | yes | recipes.json:5 KAI/VORR; finishers.json:53,76,114 placeholders; sigvariants by biome (backburnered); templates.json:210-298 A.ambush |
| unplaced | I-08 | Fight rules data | Brake, hitstop, kick, power, ladder, wounds, forms, campaign for sim/core | data/fight 20 (1060) | godot-parity: kick_check, power_check, cross_check (ci.yml:205,225,235) | yes | none found |
| unplaced | I-08 | Input data | Actions, layouts, stances, timing incl. switches.* keys | data/input 4 (1500); sim/input/input_data.gd (413) | sim/input/test/layout_test.gd; CI job not evidenced | yes | input-timing.schema.json TODO/placeholder 2 hits |
| unplaced | I-08 | Narrative data | Live barks, opponent grounds; combat barks and hints fix | data/narrative 4 (7974) | validate only | yes | combat_barks.json:3 all lines placeholder |
| unplaced | I-08 | VFX data | Meteor, water, aura, clash, energy, perf for render/vfx | data/vfx 12 (2189) | effects_check not in ci.yml run lines | yes | none found |
| unplaced | I-08 | Camera data | Swing split share | data/camera/swing.json (8) | render/camera tests in godot-parity (ci.yml:223) | yes | none |
| unplaced | I-09 | tools/pending | About 90 apply-*.cjs schema scripts, xref js, 14 flash-capture patches, row parks, ci-tile-check | 105 tracked (20037) + 29 untracked; README.md (303) | README:3 says no CI | yes | README:261 state table stale (parked scripts' keys in HEAD); ci-tile-check and subsoil-faces-schema waiting; mms-tweaks is scratch only |
| unplaced | I-11 | Kept browser builds | 12 frozen web exports with a replay tree, 018b4edf to 6a30b4c9 | homework/Files/builds/orb-first-play-* (README 10-11 lines each) | none found | not evidenced (README instructions only (blackbox-verify.mjs)) | 018b4edf trees rebuilt later (README:10); newest 6a30b4c9, 23 commits behind HEAD |
| unplaced | I-11 | Kept LAN builds | 6 Windows LAN exe folders with Host/Join launchers | homework/Files/builds/orb-lan-* (READMEs 42-47 lines) | none found | not evidenced (README instructions only) | host address hard-coded in Host .cmd; 3d997381 has no tree; a8bc66e2-c tree differs from page (held switches off) |
| unplaced | I-13 | World catastrophe prototype | Standalone throwaway Godot project, four timeline scenes, no sim | docs/research/world-catastrophe/proto/main.gd (829), sim_probe.gd (307), clips.sh, rerun.sh | none | unreached (own project.godot; docs/research/world-catastrophe.md) | throwaway (main.gd:2) |
| unplaced | I-13 | Build shortcuts + saved ledgers | .cmd launchers serving kept builds on 127.0.0.1:8771; gauntlet/ledger outputs | docs/tools/shortcuts/ 11 cmd; docs/tools/*ledger*/gauntlet* 15 | none | not evidenced (hand use only) | point at dated builds |
| unplaced | I-14 | /director command | Makes a session a director: reads charter, renames session, loads SendMessage, waits | .claude/commands/director.md (10) | none found | yes | none |
| unplaced | I-14 | /gate command | EP phase gate: briefs QA/ProdOps/Legal, scores CLAUDE.md exit criteria | .claude/commands/gate.md (5) | none found | not evidenced (user-invoked only; grep for /gate callers found none) | none |
| unplaced | I-14 | /standup command | EP briefs active directors, writes a page for Orb, updates risk register | .claude/commands/standup.md (4) | none found | not evidenced (user-invoked only) | none |
| unplaced | I-14 | /crunch command | Starts Orb's stand-in session messaging the EP with an hourly cron | .claude/commands/crunch.md (80) | none found | not evidenced (user-invoked only) | hard-coded EP session id crunch.md:6; dated 2026-11-01 priorities crunch.md:10-20 |
| unplaced | I-14 | /overnight command | Stand-in forwards homework overnight plan to EP, 15-min cron | .claude/commands/overnight.md (13, untracked) | none found | not evidenced (user-invoked; listed as available skill) | never committed (baseline ??); hard-coded EP id :11 |
| unplaced | I-14 | /sprint-plan command | Stand-in turns Orb's goal into a one-page plan for approval | .claude/commands/sprint-plan.md (96) | none found | not evidenced (user-invoked only (disable-model-invocation :4)) | hard-coded EP id :10 |
| unplaced | I-14 | /sprint command | Stand-in executes the APPROVED sprint plan with the EP | .claude/commands/sprint.md (105) | none found | not evidenced (user-invoked only (disable-model-invocation :4)) | hard-coded EP id :8 |
| unplaced | I-14 | /alpha-audit command | Starts the two-session Alpha audit (reading/judgment) with resume | .claude/commands/alpha-audit.md (73) | none found | yes | none |
| unplaced | I-14 | Director charters | 24 generated role files: title, model, owned paths, duties, report format | docs/directors/*.md (24 files, 50-59 lines each) | none found (no workflow references docs/directors) | yes | menace/anguish, hiding/ambush, ego, signature-variant duties (game-design.md:23, encounter-systems.md:24, ui-ux.md:22 etc.); camera.md hand-edited vs generator |
| unplaced | I-14 | Director roster README | Kickoff table of slugs, models, effort, titles, first phase | docs/directors/README.md (39) | none found | yes | camera row sonnet (:20) vs charter opus |
| unplaced | I-14 | DIRECTORS.md | Roster of EP + 24 directors, report format, activation schedule | DIRECTORS.md (691) | none found | yes | menace/hiding/ego/minimap strip duties (:29,99,152,202,327,331,353,377,380,453); mods/ owned (:672) but absent |
| unplaced | I-14 | Disclosure pack index | EP pointer list for the 2026-11-07 independent audit | audit/disclosure/README.md (16) + 8 files (209) | none found | not evidenced (no caller searched beyond slice) | none |
| unplaced | I-14 | 2026-11-07 audit record | Auditor's report, findings, false alarms, evidence | audit/2026-11-07/*.md (9) + 312 evidence files | none found | not evidenced (not searched) | report.md:9 villain grows from civilian kills |
| unplaced | I-14 | Export presets | Web/Windows/Linux/macOS presets with build paths and exclude filters | export_presets.cfg (172) | ci.yml:97, web-parity.yml:15,24 | yes | Web exclude omits audit/*; net/* excluded on Windows (:55) not Web (:11) |
| unplaced | I-14 | Root docs/config | CLAUDE.md brief, README public page, .gitignore, .gitattributes LF | CLAUDE.md (133), README.md (30), .gitignore (40), .gitattributes (4) | none found | yes | README.md:18 lists 3 of 8 commands; :30 prototype sanity check |
| unplaced | I-14 | Stray root files | a2.txt, a3.txt, empty | a2.txt (0), a3.txt (0), untracked | none | not evidenced (none) | likely accidental redirects |
| vfx | I-04 | VFX hub and layer | Per-match VFX state, per-pane layer, look constants, palette, perf caps, flash registry, ghost tally | vfx/vfx_hub.gd (1089), vfx_layer.gd (89), vfx_look.gd (191), palette.gd (95), perf.gd (37), flash_registry.gd (606), ghost_tally.gd (277) | effects_check (8442), hash_check: not in CI | yes | 12 effects default-off vfx_look.gd:61-85, 173-178 |
| vfx | I-04 | VFX beams and clash | Beam look/front/scar/struggle, beam plays, clash air and shockwave, energy heads | vfx/beam_look (197), beam_front (65), beam_scar (127), scar_view (95), beam_struggle (309), beamplay (322), clash_look (229), clash_view (163), clash_wave (226), energy_head (119), vfx/shaders 19 | effects_check, not in CI | yes | data/vfx/beamplay.json missing, code DEFAULTS beamplay.gd:23 |
| vfx | I-04 | VFX shots, press, zip, reach, glare, trails | Energy blasts, explosions, press styles, LT zip, reach arts, glasses glare, speed lines, trails | vfx/shots (589), shots_view (1971), explode (281), press (573), zip (489), reach (1097), glare (176), speed (209), trail_state (203), trail_view (191) | effects_check, not in CI | yes | VORR in glare.gd:23 WEARERS; KAI comment aura.gd:115 |
| vfx | I-04 | VFX destruction | Debris pool, facade holes, ground cracks, building stages, pane grid | vfx/debris (1079), shard_view (165), hole_view (70), crack_gen (152), crack_mesh (126), crack_view (103), stages (228), panes (92), mock/vfx_mock (74) | effects_check; shot tools; not in CI | yes | sig-variant debris rows debris.gd:436-441; cracks/destruction off vfx_look.gd:61-62 |
| vfx | I-04 | VFX catastrophe and environment | Blast amplification, blast cloud, tremor dust, earth/fire, biome fx, aftermath, forest fire, water | vfx/blast (200), blast_cloud (184), cloud_view (184), tremor (141), dust_view (154), earth (413), biome (575), after (350), forest_fire (290), water (586) | effects_check; earth_shots, water_shots; not in CI | yes | reads sigvariants biome.gd:15, :58 |
| vfx | I-04 | VFX power language | Aura, transformation, world reactions, levitating rocks, pressure rings, meteor trail | vfx/aura (186), transform (205), transform_view (291), react (313), rocks (214), rocks_view (123), pressure (188), meteor (730), meteor_view (279) | effects_check; react/transform shots; not in CI | yes | rocks.gd:1 PROTOTYPE yet ROCKS_DEFAULT true vfx_look.gd:70 |
| vfx | I-04 | VFX other fights feed | Other fights' effects in 2v2 | vfx/stage_feed.gd (119) | effects_check, not in CI | yes | off by default vfx_look.gd:176 |
| vfx | I-04 | VFX tools | Effects check, sim-hash check, pictures, benches, worst-case scene | vfx/tools 13 .gd (10634): effects_check (8442), hash_check (241), worst_case (285) | none in CI | not evidenced (no runner in .github, qa, tools found) | KAI/VORR text effects_check.gd:3143, :3769 |
| vfx | I-09 | vfx/pending | VFX parks: aura3d, beam-front, clash-*, meteor-trail, warm-first-use, power-burn | 11 tracked (2110) + 40 untracked | none found | unreached (no code refs) | aura3d waiting (VfxAura3D absent); warm-first-use and power-burn apply clean; 19 likely landed then drifted |
| world-environment | I-03 | Terrain heightfield (WorldTerrain) | genWorld, groundY, seaAt over float32 columns; twin of terrain.js | sim/world/terrain.gd (503), terrain.js (80) | step/surface checks in CI job world; wrap.test.js in CI job sim | yes | 'strip' wording |
| world-environment | I-03 | Biome layout (WorldBiomes) | static biome spans of the wrapped planet | biomes.gd (51), biomes.js (7) | wrap.test.js in CI job sim | yes | none |
| world-environment | I-03 | Craters (WorldCrater, WorldCraters) | bowl sized by sqrt(energy); slam crater shape by material | crater.gd (667), craters.gd (279) | craters_check, field_crater_check in CI job world | yes | sig-variant scorch crater.gd:439; craters enabled=false |
| world-environment | I-03 | Water and fill (WorldWater, WorldFill) | 1D column water depth; dug holes fill from nearby water | water.gd (412), fill.gd (405) | fill_check, water_read/warm_check in CI job world | yes | all water switches false |
| world-environment | I-03 | Structures (WorldStructures) | buildings, damage, implosion, rubble; twin of structures.js | structures.gd (787), structures.js (75) | blockcheck, stagecheck in CI job world | yes | feeds menace/anguish via collateral structures.gd:477 |
| world-environment | I-03 | Collateral (WorldCollateral) | bystanders scatter, no deaths; budget, ceiling; menace/anguish feed on falls | collateral.gd (505) | collateral_check, bystanders_check in CI job world | yes | backburnered menace/anguish meters written collateral.gd:407-467 |
| world-environment | I-03 | Ground contact and slide (WorldContact, WorldSlide) | skid/bounce/tumble/slam landings; knockback slide trench | contact.gd (1527), slide.gd (207) | surface/skate/field_trench checks in CI job world | yes | skate off, settle off |
| world-environment | I-03 | Building impact (WorldBrunt, WorldInterior) | director-chosen building impact chain and tower-interior chain | brunt.gd (1297), interior.gd (400) | brunt_check, b_check, interior_check in CI job world | yes | none |
| world-environment | I-03 | Shot blast (WorldBlast) | crater, structures, splash at an energy shot's end | blast.gd (209) | blastcheck in CI job world | yes | none |
| world-environment | I-03 | Beam aftermath (WorldAfter) | nine aftermath kinds and parted sea after signature beam | after.gd (707) | after_check in CI job world | yes | enabled=false; sig-variant family |
| world-environment | I-03 | Struggle meet (WorldStruggleMeet) | beam struggle damage at meeting point | struggle_meet.gd (236) | struggle_meet_check, struggle_dir_check in CI job world | yes | off by default |
| world-environment | I-03 | Forest fire (WorldFire) | trees beyond felled ring catch and spread | fire.gd (203) | fire_check in CI job world | yes | enabled=false |
| world-environment | I-03 | Hiding cover (WorldCover) | nearTree, coverAt, nearestCover; twin of cover.js | cover.gd (44), cover.js (24) | ground_check/after_check use it in CI job world | yes | backburnered hiding/ambush |
| world-environment | I-03 | Stored planet (WorldPlanet, WorldPlanetCache, WorldPlanetWorld) | seeded sphere function, places, slice read; cache; match world from slice | planet.gd (1759), planet_cache.gd (108), planet_world.gd (340) | planet_check, planet_cache_check, planet_world_check in CI job world | yes | stale header planet.gd:2; 'DRAFT, scratch' planet_world.gd:2 |
| world-environment | I-03 | Planet gen 2 (climate, ground, land, plates-B, sites, lakes, rivers, density) | climate biomes, ground profiles, landforms, plates, placement, lakes, rivers, density | climate.gd (481), ground.gd (517), land.gd (466), plateb.gd (861), sites.gd (300), lakes.gd (270), rivers.gd (525), density.gd (96) | climate/ground/land/sites/lakes/rivers/density/gen2_state checks in CI job world | yes | climate gen=1, land.b off, rivers off |
| world-environment | I-03 | Planet gen 3 field (field, cache, pool, store, waterrec, plan) | cube-sphere node field, bake cache, node pool, planet-point marks, water records, towns by plan | field.gd (928), field_cache.gd (304), field_pool.gd (111), store.gd (324), waterrec.gd (343), plan.gd (583) | field_* and store_check in CI job world | yes | farAnguish switch plan.gd:49 |
| world-environment | I-03 | Ring picker and calm turn (WorldRingPick, WorldEpoch) | picks fight ring; turns ring at calm moments within limits | ringpick.gd (603), epoch.gd (790) | ringpick_check, epoch_check in CI job world | yes | none |
| world-environment | I-03 | Far map (WorldFarMap) | render-only cached height/biome map | farmap.gd (241) | farmap_check in CI job world | yes | none |
| world-environment | I-03 | Campaign world (WorldCampaign) | keyed campaign ring, columns, wear | campaign.gd (636) | campaign_check in CI job world | yes | enabled=false |
| world-environment | I-03 | Settlements (WorldSettle) | loads settlements data, generates districts and landmarks | settlements.gd (464) | landmark_spare_check, lot_reach_check in CI job world | yes | stale 'NOT YET WIRED' settlements.gd:4 |
| world-environment | I-03 | Fight lanes (WorldLanes) | lane table, nearest clear street, swept-test extents | lanes.gd (334) | lane_check in CI job world | yes | none |
| world-environment | I-03 | Liftable wreck (WorldWrecks) | nearest liftable fallen-building query | wrecks.gd (221) | wrecks_check in CI job world | unreached (git grep -w WorldWrecks: only sim/world/tools/wrecks_check.gd) | no Encounter caller |
| world-environment | I-03 | Prop hold points (WorldProps) | throwable hold point in world frame | props.gd (107) | props_check in CI job world | unreached (only props_check.gd; props.gd:4 says nothing calls it) | waits on S.props |
| world-environment | I-03 | World tools | 115 headless check/probe/profile scripts | sim/world/tools/*.gd (17,421 incl. vectors) | 85 run, 30 leaveOut (tools/world-checks.json), CI job world | yes | ci.yml:384 says 48, list has 85 |
| world-environment | I-08 | World data | Planet, climate, water, rings, craters, settlements for sim/world | data/biomes 26 (3155) | CI job world via tools/world-checks.mjs --run (ci.yml:401) | yes | field.json:17 farAnguish |
| world-environment | I-09 | world/pending | World diffs: globe-step2, meteor-power, places-reached, cancel-keep, civilians-removed, crater-collapse, fire linger | 6 tracked (708) + 18 untracked; 3 M | none found | unreached (no code refs) | 9 patches apply clean (waiting); beam-grid on main |
| world-environment | I-13 | Planet data writer (window 1) | Writes data/biomes/planet.json and its schema | docs/world/planet-window1/mk_planet_data.py (109) | none | unreached (docs/world/planet-module.md) | one-shot generator |
| world-environment | I-13 | World scratch builds | Per-window scratch patchers, checks, dumps and results on HEAD copies | docs/world/scratch-build/ 321 files (94 py, 80 gd; contact.gd 818, mk_slicejob.py 615) | none of its own | yes | KAI/VORR (g1_reach.py:107); strip_time.gd; stale sim copies; 19 mk_wbc_lib.py copies |

## Notable facts from the slices

Each was written by the slice agent with its evidence; only the ten rows above were re-checked by this session.

- **I-01:** No CI job runs the 46 sim/input/test/*.gd scripts; qa/godot/pending-tests.js:145 only looks for c<NN>_*.gd, which don't exist
- **I-01:** SimKeyboard has no code caller: only a comment at render/core/key_codes.gd:2
- **I-01:** SimCampaign is reached only through checkArc at sim/core/run.gd:391; campaign enabled=false
- **I-01:** Menace/anguish (backburnered) still live: sim/core/damage.gd:50-56, sim/core/fighter.gd:686-705; both fighters' meters.json define them
- **I-01:** Ambush still live: sim/core/hiding.gd:43, sim/core/damage.gd:59
- **I-01:** KAI/VORR remain in frozen JS core sim/core/roster.js:5-6
- **I-01:** Biome variant name 'HORIZON CLEAVE' hardcoded at sim/core/tools/cross_check.gd:258
- **I-01:** 'strip' in sim/core/field.gd:177 is the line coordinate; no flat-arena code found
- **I-01:** Placeholder transform comments at sim/core/fighter.gd:568, sim/core/fx.gd:185
- **I-01:** brake/flight/forms/hitstop/kick/power/ricochet/cross/depth/campaign all enabled=false in data/fight/*.json, data/combat/depth.json
- **I-01:** data/input/timing.json: 13 of 25 switches true (rightStick, beamAim, quickRead...)
- **I-01:** Camera header names Camera owner at sim/core/view/camera.gd:5, but path is simulation-engine's (DIRECTORS.md:170)
- **I-01:** sim/core/tools/parity.gd (6878 lines) is the GDScript CI gate, ci.yml:191
- **I-01:** Touch/phone haptics live (render/core/main.gd:1414, sim/input/haptics.gd:5) though mobile parked
- **I-01:** Only uncommitted path: untracked sim/input/tools/stall_probe.gd (+uid)
- **I-02:** Only 5 of 65 director tools are in CI: .github/workflows/ci.yml:221,229,269,403,405
- **I-02:** Combat-parity frozen data checked only by sim/director/tools/loader_check.gd:29, not in CI
- **I-02:** Test-only hook checkData in shipped runtime: sim/director/exchange.gd:1018-1035
- **I-02:** DirSwingRead has no runtime caller; swing_read.gd:5 says DirSwing asks it; only render/camera/tests/swing_read_check.gd:66
- **I-02:** stick.gd:5 says rightStick false; data/input/timing.json:41 has true
- **I-02:** Placeholder finisher: sim/director/exchange.gd:808, sim/director/data.gd:678
- **I-02:** Hiding/ambush live: sim/director/ai.gd:108-111, sim/director/exchange.gd:331-335, sim/director/brawl.gd:1387
- **I-02:** Menace/anguish read: sim/director/beam.gd:208, sim/director/beamplay.gd:508-513, sim/director/location.gd:105
- **I-02:** Biome signature variants live: sim/director/sigafter.gd:1-4 called from sim/director/beam.gd:153
- **I-02:** brawl.gd is 4305 lines (largest): sim/director/brawl.gd
- **I-02:** No KAI/VORR and no TODO/FIXME in sim/director (grep, 0 hits)
- **I-02:** 'strip' in sim/director/launch.gd:70-91 is heightfield column cache, not the retired arena
- **I-02:** Many switches off: data/director/interrupts.json (chase, rally, wallKick, water, outside, grapple, ending, calmTurn, cameraIntent, beamStruggle, stances); swing.json enabled false
- **I-02:** JS twins imported by frozen core: sim/core/sim.js:12-13, sim/input/control.js:3-4; sim CI job ci.yml:60
- **I-02:** Director file copies in docs/director/pending (e.g. docs/director/pending/grapple-g1/files/sim/director/grapple.gd:1) duplicate class_names
- **I-03:** sim/world/settlements.gd:4 says NOT YET WIRED but sim/core/replay.gd:184 and sim/director/arc.gd:125 call it
- **I-03:** sim/world/planet.gd:2 says nothing reads the planet yet, but 54 files name WorldPlanet
- **I-03:** sim/world/planet_world.gd:2 is marked DRAFT, scratch but is in live use (audio/audio_world.gd:74)
- **I-03:** Backburnered menace/anguish meters are still written in sim/world/collateral.gd:407-467, reached from structures.gd:477
- **I-03:** farAnguish switch still exists at sim/world/plan.gd:49
- **I-03:** Hiding cover is still reached: sim/core/hiding.gd:22, sim/director/ai.js:8
- **I-03:** Signature variant data read by World: crater.gd:439, structures.gd:579
- **I-03:** WorldWrecks (wrecks.gd) and WorldProps (props.gd:4) are reached only by their check scripts
- **I-03:** .github/workflows/ci.yml:384 and tools/world-checks.json:2 say 48 checks; run list has 85
- **I-03:** tools/world-checks.json run list includes floor_walk_probe
- **I-03:** World CI job timeout raised to 45 min (ci.yml:390)
- **I-03:** Many features off in data: after, campaign, craters, fire, rivers, skate, water, land.b; climate.json:4 gen=1
- **I-03:** No TODO/FIXME/KAI/VORR in slice; 'vorr' variable only in sim/core/tools/parity.gd:4355
- **I-03:** 'strip' appears in 13 runtime files, e.g. plan.gd (13x), crater.gd (7x)
- **I-03:** All 26 data/biomes files have tools/schemas/biomes-*.schema.json, validated by CI job data (ci.yml:80)
- **I-04:** Seven VFX modules load data files absent from data/vfx/ and fall back to in-code DEFAULTS: beamplay.gd:77, glare.gd:47, press.gd:104, reach.gd:74, shots.gd:105 / explode.gd:36, stages.gd:37, zip.gd:98
- **I-04:** render/anim/, render/tools/ and render/main.tscn, render/boot_entry.tscn have no owner on any DIRECTORS.md owns line (Animation owns art/animation, docs/animation only: DIRECTORS.md:247)
- **I-04:** Largest gates not in CI: render/anim/tools/anim_check.gd (8300), render/vfx/tools/effects_check.gd (8442), render/camera/tests/split_sweep.gd (5203), render/vfx/tools/hash_check.gd; CI runs only 7 render scripts (.github/workflows/ci.yml:223, 265-277)
- **I-04:** Menace/anguish bars still drawn in F2 greybox HUD: render/core/hud.gd:228-233
- **I-04:** Hiding paths remain: render/core/fighter_view.gd:440-530, render/core/hud.gd:203, render/camera/split_rig.gd:20 (hiding hook, unused)
- **I-04:** Signature variants by biome still read: render/vfx/biome.gd:58 (data/combat/sigvariants.json); render/vfx/debris.gd:436-441
- **I-04:** Placeholder VORR is a live wearer id: render/vfx/glare.gd:23; KAI in comment render/vfx/aura.gd:115
- **I-04:** AnimHeldLint and AnimMany reached only from tests: render/anim/tools/anim_check.gd:1151, :1214
- **I-04:** Standalone spike project inside game tree: render/anim/spike/project.godot; README.md:3
- **I-04:** Narrative's bark_check parked in render/tools: render/tools/bark_check.gd:1
- **I-04:** Many effects default-off: render/vfx/vfx_look.gd:61-63, :77, :84-85, :173-178; render/core/look.gd:539 CAMERA_ROLL_ON=false; render/core/tile_ground.gd:14
- **I-04:** rocks self-described PROTOTYPE yet on by default: render/vfx/rocks.gd:1, render/vfx/vfx_look.gd:70
- **I-04:** Shipped main scene has debug keys F2/F7-F11: render/core/main.gd:7-43, :117-118
- **I-04:** No TODO/FIXME in render/ (only a local var ground_field.gd:358); all 57 shader files referenced
- **I-04:** 0 uncommitted paths under render/ in docs/ep/alpha/audit-2026-11-13/baseline-status.txt
- **I-05:** No CI job runs ui/tools or audio/tools checks; hud_check (ui/tools/hud_check.gd, 11033 lines, 1440 _ok) is manual; only named at tools/flash/release-pass.mjs:315
- **I-05:** Five audio sub-readers parked: carry_cues.json:4, coop_cues.json:4, moment_cues.json:4, tug_cues.json:4, world_cues.json:4 enabled:false
- **I-05:** coop_cues.json and moment_cues.json have no schema rule in tools/schemas/map.json (warning only per map.json:2; moment_cues.json:2)
- **I-05:** localization/ not a validate.js root (tools/schemas/map.json:3-8): pseudo twins never schema-checked
- **I-05:** Babble voice unreached in game: only audio/demo/audio_demo.gd:47-49 and tools
- **I-05:** UiRecipe PLACEHOLDER, only caller ui/tools/hud_check.gd:4252 (ui/widgets/ui_recipe.gd:2)
- **I-05:** Ego meters remain: ui/core/ui_sim_bridge.gd:9 and :89 read menace/anguish; ui/core/ui_look.gd:43-45; ui/data/terms.json:9
- **I-05:** Hiding gated off but kept: ui/data/features.json hiding:false; ui/core/ui_event_hub.gd:439,:609; ui/widgets/ui_strip.gd:50,:81
- **I-05:** 'strip' in ui/ is the planet minimap bar (ui/widgets/ui_strip.gd:2), not the retired arena
- **I-05:** KAI/VORR only as negative assertions ui/tools/hud_check.gd:6634,:6692; no TODO/FIXME in slice
- **I-05:** Face cut-ins draw generated placeholder portraits (ui/widgets/ui_faces.gd:12,:146)
- **I-05:** audio/music has no tracks; map.json:163 maps absent audio/music/loops.json
- **I-05:** menus_rail, answer_alert, planet_map false in ui/data/features.json
- **I-05:** Wiring: render/core/sim_host.gd:26 AudioCues; render/core/main.gd:232-234 AudioVoices+bank warm; main.gd:174 HUD
- **I-05:** Zero uncommitted slice paths in baseline-status.txt
- **I-06:** export_presets.cfg:11 Web preset does not exclude net/*, while desktop presets do (:55,101,132)
- **I-06:** net/tools/lan_kit.mjs:1-2 NetLan wired only into a scratch copy; never called on main
- **I-06:** audit/2026-11-07/evidence/cold-reviews.json:545 handshake peer delay uncapped, NetSession allocs range(delay)
- **I-06:** net/delay.gd:27 minDelay 2, maxDelay 8
- **I-06:** net/session.gd:45,46,70 saveEvery 1, maxAhead 20, checkEvery 60
- **I-06:** ci.yml:280 enet_check runs only in CI (ports 47100/47102)
- **I-06:** net/tools/rollback_bench.gd has no CI job or caller
- **I-06:** qa/godot/selftest.js not run by any workflow; CI qa job runs only legacy suite (ci.yml:42-43, qa/run-all.js:2)
- **I-06:** qa/godot/records.gd:979-980 still records menace/anguish; :450 hiddenSec; :1116 ambush
- **I-06:** qa/godot/bands.js:359 biome signature variant names; :411 retired hiding row
- **I-06:** qa/run-godot.js:131,140 reports Rival menace
- **I-06:** KAI/VORR remain in qa/balance-report.js, qa/baseline-p0.md/json, qa/known-bugs.md, prototype/index.html
- **I-06:** tools/build-site.mjs:18 prototype kept unpublished for Legal hold; unchanged since 7233c967
- **I-06:** net/tools/swing_check.gd:2 stand-in swing trigger (no director asks for swing yet)
- **I-06:** No TODO/FIXME/XXX/HACK in slice (git grep)
- **I-07:** tools/site.json:7 template custom while export_presets.cfg:23-24 custom_template empty; site offline (tools/site.json:3), pin 257a766c (tools/site.json:6)
- **I-07:** tools/fixtures/cases.json is 314,043 lines, ~72% of the slice
- **I-07:** Eight Node self-tests are in no workflow (capture x2, clips, feel x2, machine, padlab, preview/lan-clip) — grep .github/workflows/*.yml
- **I-07:** tools/preview/clip-script.mjs has no caller or doc mention (git grep clip-script); usage at clip-script.mjs:4
- **I-07:** tools/l10n/* not run by CI or qa/run-all.js; overflow_check.gd:1 says report, not a gate
- **I-07:** ci.yml:384 comment says 48 world scripts; tools/world-checks.json lists 85 run + 30 left out
- **I-07:** Timeouts raised 2026-11-08: flash 45, godot-parity 75, net 60, world 45 (ci.yml:109,181,285,390)
- **I-07:** Two-process ENet incl. 40 s late host runs in CI net job (ci.yml:377-382)
- **I-07:** check-workflows runs twice per push (ci.yml:93-96 and workflow-lint.yml:29-32)
- **I-07:** tools/ratchet-two-fighter.json:48 baselines sim/core/hiding.gd (backburnered hiding)
- **I-07:** tools/gen_directors.py:3 claims to generate DIRECTORS.md but text still has menace/anguish/hiding/ego (gen_directors.py:26,57,172,185)
- **I-07:** Schemas keep backburnered meters: fighter-meters.schema.json:5, director-swing.schema.json:457; combat-sigvariants mapped map.json:47
- **I-07:** tools/lib/core.js:148 uses literal NUL bytes as a sort-key separator (file detected as binary)
- **I-07:** KAI/VORR only as scan targets: tools/site-name-scan.mjs:14, allow-list tools/site-name-scan.json:6,10
- **I-07:** project.godot and export_presets.cfg in no owns line (DIRECTORS.md:472 tools-pipeline owns tools/, build/, .github/); project.godot:2
- **I-08:** 68 of 85 data-key switches are off on main and on in both Orb builds; solo and LAN agree on all 85 (tools/preview/switches.mjs:13-245)
- **I-08:** Main vs solo differ on 72 of 92 rows (68 data + 4 page words blackbox/go/meteor/tiles from homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/README.txt URL); gen3 not evidenced
- **I-08:** 12 rows already at 'to' on main so their 'from' is stale, e.g. rightStick switches.mjs:30 vs data/input/timing.json switches.rightStick=true
- **I-08:** mixed switch is ON in both builds but no game code reads data/combat/mixed.json (switches.mjs:229; git grep mixed.json)
- **I-08:** data/combat/styles.json has no game reader, only tools/lib/xref-fight.js:5
- **I-08:** data/narrative/combat_barks.json and hints_fix.json are tool-only (tools/l10n/strings.mjs:143, tools/lib/xref.js:725)
- **I-08:** Six data/art files have no game reader; colour-vision only a comment at render/core/look.gd:921
- **I-08:** Backburnered meters still data: data/fighters/RIVAL/meters.json:5 menace, data/fighters/PROTAGONIST/meters.json:5 anguish, data/director/swing.json:163
- **I-08:** Signature variants by biome still loaded: sim/director/data.gd:11 (data/combat/sigvariants.json)
- **I-08:** Ambush terms in data/combat/templates.json:210,287,298
- **I-08:** KAI/VORR named in data/combat/recipes.json:5; placeholder finishers data/combat/finishers.json:53,76,114
- **I-08:** UI/audio switch values read from pck/exe: struggle_push default 'stick', menus_rail true, tug/moment/carry cues enabled true in both builds
- **I-08:** LAN build: --tiles=1 in every .cmd; gen3 via net/lan.gd:30 SETUP planetGen 3 in source, not found as text in exe
- **I-08:** Eight data folders under no owns line: data/anim, art, camera, combat, fight, input, narrative, vfx (DIRECTORS.md); data/atoms and data/exchanges owned by Combat do not exist
- **I-08:** Schema map complete: 195 rules, 286/286 data JSON matched, no orphan schemas (tools/schemas/map.json; ci.yml:81)
- **I-09:** CI data job reads a park: .github/workflows/ci.yml:79 -> tools/movegen/test/run.mjs:179 and tools/movegen/movegen.mjs:35 read docs/combat/pending/movegen and roster
- **I-09:** tools/preview/stack.json:40,44,23 reference untracked docs/combat/pending/mixed-string/mixed.gd, mixed.json and docs/tools/pending/mixed-schema patch
- **I-09:** render/anim/tools/wave_gen.mjs:368 reads docs/combat/pending/golive-step1.picks.json; medium_wind_gen.mjs:20 reads movegen movesets
- **I-09:** docs/tools/pending/README.md:261 state table (2026-10-06) lists scripts as parked whose keys are in HEAD (tools/lib/xref-fight.js, data/input/timing.json, data/fight/mood.json)
- **I-09:** docs/animation/pending/README.md:3 says 'Parked' for patches landed in 7de33ae4
- **I-09:** docs/controls/pending is entirely uncommitted (51 untracked) and mostly already on main
- **I-09:** Withdrawn parks still present: docs/director/pending/plan-cost/README.md:1, docs/director/pending/swing-warm/README.md:3, audio-resume, vfx other-fights
- **I-09:** qa/godot/masher.js:409 cites docs/director/pending/beam-struggle (deleted in WT); qa/godot/approach.gd:2 cites absent architecture/pending/kick-keep-top
- **I-09:** All 20 docs/narrative/pending/*.json absent from data/ (opponent_grounds.json differs)
- **I-09:** KAI/VORR in park files, e.g. docs/architecture/pending/fighter-split.md:5, though data/fighters has PROTAGONIST and RIVAL
- **I-09:** menace in 13 park files (e.g. docs/combat/pending/energy/energy.rival.json); 'World's strip' in docs/ui/pending/run-mode/README.md
- **I-09:** Patch check over 257 patch/diff files against HEAD index: 70 ON MAIN, 28 apply clean, 159 neither (79 all sampled lines in HEAD, 26 none)
- **I-09:** tools/pending/ci-tile-check patch applies clean and edits .github/workflows/ci.yml (still waiting)
- **I-09:** docs/tools/ has no owner: tools-pipeline owns tools/, build/, .github/ (DIRECTORS.md:472)
- **I-09:** No TODO or FIXME in tracked park files (git grep over docs/*/pending/**)
- **I-10:** ADR status lines all 'accepted'; replaced items not marked superseded (docs/decisions/0013-no-laptop-target.md:3, 0011-pc-first-mobile-parked.md:3)
- **I-10:** ADR 0008 says work on hold (0008-control-scheme.md:3) yet sim/input/layout.gd (1351) and touch.gd (682) exist
- **I-10:** ADR 0012 says route not chosen (0012-turntable-and-quality-range.md:3) while field.gd/swing.gd ship behind planetGen 3 (field-ground.md:3)
- **I-10:** Built systems with stale 'plan' headers: last-stand.md:3, intro-phase.md:3, mood-style.md:2, q10-pace-acts-pauses.md:3, wounds-plan.md:3, run-core.md:1, fight-lanes.md:3
- **I-10:** Ten core feature switches are off on main: data/combat/depth.json:4, data/fight/power.json:4, campaign.json:4, kick.json:3, hitstop.json:4, flight.json:4, ricochet.json:4, forms.json:4, brake.json:4, run.json:5
- **I-10:** Backburnered hiding is called every tick: sim/core/fighter.gd:829
- **I-10:** KAI/VORR in 29 slice files (145 lines); d1-roster-data.md:4 maps them to PROTAGONIST/RIVAL
- **I-10:** menace/anguish in 46 files (186 lines); background-stats.md:3 is a paper proposal
- **I-10:** 'strip' in 34 files (87 lines); two-v-two-lines.md:3 says LAN 2v2 plays like the old strip
- **I-10:** TODO/FIXME/placeholder in 37 files (99 lines); hiding/ambush 41 files; ego 16 files (git grep -c)
- **I-10:** run-gate.sh:43 prints golden_cmp only on equal, so a mismatch is a missing line (also audit/2026-11-07/checks-review.md:44)
- **I-10:** Two parked slices untracked: docs/architecture/pending/power-flip/, clock-by-body/ (baseline-status.txt); pending/README.md:3 says nothing there is run by CI
- **I-10:** planet-proof needs planet_lib.gd from outside its folder (docs/architecture/planet-proof/README.md:7,15)
- **I-10:** intent-v5 is paper; sim/input/intent.gd:15 VERSION 4
- **I-10:** hold-one (E102) paper (hold-one.md:3); no body-hold path in hitstop.gd/clock.gd
- **I-11:** ci.yml: no completed run after 3a03e03f; 4 of 5 pushes on 2026-11-13/14 cancelled with 0 jobs, 43553420852 still running (gh run list)
- **I-11:** ci.yml:23-27 says every main run finishes, but 15/30 main runs cancelled with 0 jobs (e.g. 43554229393): queued runs superseded
- **I-11:** Longest job net 49m40s vs timeout 60 (ci.yml:285) in run 42866500996; godot-parity 48m45s vs 75 (ci.yml:181)
- **I-11:** desktop-builds.yml:15-16 dispatch-only, never run
- **I-11:** web-template (2026-10-28) and flash-pixels-dryrun (2026-10-06) stale
- **I-11:** web-parity 3 failures on 2026-11-08 (42477588363, 42471561658, 42470640835); content-screen 1 failure 42673850903
- **I-11:** Newest kept builds 6a30b4c9 (orb-first-play-6a30b4c9-6627cb9d/README.txt:1), HEAD 23 commits later
- **I-11:** orb-lan-a8bc66e2-c/tree/README.txt:2-3: held switches off, main net/ laid over
- **I-11:** orb-first-play-018b4edf-*/README.txt:10: tree rebuilt 2026-11-02, not original
- **I-11:** orb-lan-*/Host (main PC).cmd:3 hard-codes a home-network address (private)
- **I-11:** docs/director/runs 741 of 1307 run files; 135 untracked (baseline-status.txt)
- **I-11:** docs/qa, docs/sim, docs/tools runs unplaced per DIRECTORS.md:447,170,472
- **I-11:** Workflow lint duplicated: workflow-lint.yml:30-32 and ci.yml:93-96
- **I-11:** No KAI/VORR/strip/TODO in .github/workflows (grep)
- **I-12:** Stale path: audio/data/flash_cues.json:5 and audio/synth/flash_synth.gd:3 cite art/concepts/marked-aura/flashes.json, not tracked; canonical is data/art/flashes.json:130
- **I-12:** tools/clips/mockups/pan.py:1 defaults to art/concepts/megastructures/megastructures.png, which is untracked
- **I-12:** data/art energy-lanes/polar/outposts/auras.json have no loader outside art (git grep)
- **I-12:** sim/world/tools/b_vectors.mjs:4-5 imports research/planet-gen code, against research/README.md rule; b_check in CI via tools/world-checks.json:5
- **I-12:** research/band-proto built and deployed by ci.yml:432-438
- **I-12:** render/anim/anim_held_lint.gd:121 reads docs/legal/movegen-banned.json (gate anim_check.gd:6860) though pose rules left Legal 2026-11-07
- **I-12:** render/core/main.gd:1747 bench hook for research/engine-spike/tools/bench-browser.mjs
- **I-12:** Ambush leftover: art/concepts/marked-aura/gen.mjs:83,655
- **I-12:** Hiding/ambush code parked: research/info-hiding/core/sim.mjs:11-12
- **I-12:** KAI/VORR: art/concepts/faces/gen.mjs:91; docs/marketing/go-to-market-plan.md:31,229,319
- **I-12:** 'strip' wording: art/concepts/biomes/draw.mjs:48; research/band-proto/main.gd:4
- **I-12:** sim/core/kick.gd:3 cites research/rule-of-cool/pitches.md section 2
- **I-12:** GEN2PACK base64 blobs: research/ring-any-angle/proto-v2.html:29, research/rule-of-cool/feel.html:29
- **I-12:** Uncommitted biome generator edits (gen.mjs, spec.mjs, 11 SVGs) per baseline-status.txt
- **I-12:** render/core/cover_meshes.gd:4,10,773 hand-port art/concepts/biomes JS with no parity test found
- **I-13:** CI data job runs a docs tool: node docs/perf/tools/web-head.mjs --check (.github/workflows/ci.yml:99); tools/build-site.mjs:118-123 needs docs/perf/web-shell files
- **I-13:** Site icons are placeholders (docs/perf/tools/make-placeholder-icons.mjs:2)
- **I-13:** CI world job's planet_check.gd reads docs/world/scratch-build/planet-slice/planet2.json (sim/world/tools/planet_check.gd:5) and silently skips if absent (:103)
- **I-13:** Tracked probes read untracked data: sim/input/tools/hitstop_script_probe.gd:17, thumb_phantom_probe.gd:13 -> docs/controls/clips/*.json (?? in baseline-status.txt)
- **I-13:** render/anim/tools/coverage.gd:8 reads docs/animation/launch-pair-coverage.json; coverage tools not in ci.yml
- **I-13:** Narrative line-lint (docs/narrative/line-lint.py) not in any CI job; manual per data/narrative/live_barks.json:7640
- **I-13:** KAI/VORR in 99/65 tracked files of the slice, e.g. docs/world/scratch-build/g1_reach.py:107, docs/narrative/voice-lab/kai.csv:2
- **I-13:** Ego meter still drives audio design: docs/audio/direction.md:96; docs/combat/procedural-moves.md:116; menace/anguish/ego in 78 files
- **I-13:** Strip-arena wording in 63 files, e.g. docs/world/after.md:24
- **I-13:** No TODO/FIXME in tracked slice files (git grep empty)
- **I-13:** docs/world/scratch-build holds stale sim copies (city3/files/sim/world/settlements.gd, contact.gd) per README:3 'nothing here is in the tree'
- **I-13:** 36 patch + 44 diff handoffs outside pending/ (docs/controls/*.patch, docs/animation/handoff/); landing not evidenced
- **I-13:** 13,725 untracked paths (docs/tools/img 8,592, docs/rendering/img 4,981) vs 2,118 tracked
- **I-13:** docs/qa, docs/tools, docs/research, docs/setup are on no director's owns line (DIRECTORS.md:447,472,622) though ci.yml:2,63 cite docs/tools docs
- **I-13:** Record index body appended mechanically by shell (cat >>) to save tokens; header and tables written with Write
- **I-14:** .claude/commands/overnight.md is live (shown as a skill) but untracked (baseline-status.txt ??)
- **I-14:** Camera model drift: docs/directors/camera.md:3 opus vs DIRECTORS.md:297 and tools/gen_directors.py:140 sonnet (commit 4bb10168 hand-edited charter only)
- **I-14:** All 24 charter owns lines match DIRECTORS.md owns lines (DIRECTORS.md:92-672)
- **I-14:** Generator rerun would revert camera.md hand edits incl. ADR 0010 anti-goal (tools/gen_directors.py:506-509)
- **I-14:** Backburnered menace/anguish/hiding/ambush/ego duties remain in charters: docs/directors/game-design.md:23, encounter-systems.md:24, ui-ux.md:22, narrative-identity.md:22, world-environment.md:22
- **I-14:** Phase list still names menace: DIRECTORS.md:29
- **I-14:** mods/ owned by modding-extensibility (DIRECTORS.md:672) but folder absent
- **I-14:** Hard-coded EP session id in crunch.md:6, overnight.md:11, sprint-plan.md:10, sprint.md:8
- **I-14:** README.md:18 lists only /director /standup /gate; 8 commands exist
- **I-14:** audit/2026-11-07/report.md:9 records villain strengthening from civilian kills in public build
- **I-14:** export_presets.cfg:11 Web exclude omits audit/*; packing not evidenced
- **I-14:** export_presets.cfg:55 Windows excludes net/* but Web (:11) does not
- **I-14:** project.godot:2 assigns file to Simulation & Engine; DIRECTORS.md:63 gives root files to EP as shared files
- **I-14:** Empty untracked a2.txt, a3.txt at root
- **I-14:** No tracked .claude/settings.json, skills or agents; commands have no tests or CI

COMPLETE 2026-11-13 20:22 PST
