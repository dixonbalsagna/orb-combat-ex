# I-08 data-schemas-switches (inventory)

- **Slice:** I-08, data-schemas-switches
- **Covers:** `data/` (every data file, grouped by folder, with its reader), `tools/schemas/`, and the switch table `tools/preview/switches.mjs` (main vs Orb's solo build vs Orb's LAN build)
- **Tracked files:** 481 (`git ls-files data tools/schemas tools/preview/switches.mjs`): data 286 (all `.json`), tools/schemas 194, switches.mjs 1
- **Total lines:** 128,869 (data 57,141; tools/schemas 70,673; switches.mjs 1,055)
- **Uncommitted paths in slice (baseline-status.txt):** 2, both modified, both data: `data/art/biomes.json`, `data/art/energy-lanes.json`. 0 untracked, 0 deleted.
- **Builds read:** solo `homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/` (tree/data, README.txt, web/index.pck via `grep -a`); LAN `homework/Files/builds/orb-lan-6a30b4c9/` (tree/data, *.cmd, orb-combat-lan.exe via `grep -a`). Nothing was run.

## Data folders

| Folder | Files (lines) | Reader (game code unless marked) | Schemas |
|---|---|---|---|
| data/anim | 48 top-level + 132 in waves/ (7,469 + 9,799) | `render/anim/anim_data.gd` (612) DIR `res://data/anim/` at :7; waves also `render/anim/anim_held_lint.gd:64` | 57 `anim-*.schema.json` |
| data/art | 12 (8,360) | game: biomes `render/core/biome_look.gd:19`, damage `render/core/damage_look.gd:17`, flashes `render/core/flash_set.gd:7`, city-looks `render/core/shapes.gd:24`, sky `render/core/sky_drive.gd:20`, effects `render/vfx/palette.gd:20`. Concept-tool only: auras, outposts, polar, energy-lanes, vehicles (art/concepts/*.mjs, props_check), colour-vision (only a comment ref, `render/core/look.gd:921`) | 12 `art-*` |
| data/biomes | 26 (3,155) | sim/world/*.gd, one file each (e.g. `sim/world/planet.gd:13` planet.json; water.json in `sim/core/fighter.gd`); several also hashed via `sim/core/replay.gd` | 26 `biomes-*` |
| data/camera | 1 (8) | swing.json: `render/camera/cam_places.gd` | camera-swing |
| data/combat | 11 (13,674) | `sim/director/data.gd` (793) :9-11 templates/finishers/sigvariants, :48 phrases, :56 recipes, :57 enders; stick `sim/director/stick.gd`; depth `sim/core/depth.gd`; launch_biome `sim/director/launch.gd`. **No game reader found:** mixed.json (only switches.mjs, schema, fixtures), styles.json (only `tools/lib/xref-fight.js:5`) | 11 `combat-*` |
| data/director | 8 (1,685) | sim/director/*.gd (data.gd, stick.gd, swing.gd, location.gd, rally.gd); ai.json `sim/core/sim.gd` | 8 `director-*` |
| data/fight | 20 (1,060) | sim/core/*.gd one each (brake.gd, hitstop.gd, kick.gd, power.gd ...); wounds+ladder via `sim/core/fighter_data.gd:17` | 18 `fight-*` + fighter-ladder, fighter-wounds |
| data/fighters | 8 (268) | `sim/core/fighter_data.gd:16` ROOT `res://data/fighters/` + id; roster lists PROTAGONIST, RIVAL, REFERENCE | fighter, fighter-meters, fighter-roster, fighter-bench, fighters-forms |
| data/input | 4 (1,500) | `sim/input/input_data.gd:9` DIR `res://data/input/` (actions.json at :70) | 5 `input-*` (incl. input-feel) |
| data/narrative | 4 (7,974) | live_barks `ui/core/narrative_barks.gd`, `render/core/main.gd`; opponent_grounds `sim/core/run.gd`. **No game reader found:** combat_barks.json (`tools/l10n/strings.mjs:143`, xref only), hints_fix.json (`tools/lib/xref.js:725` only) | 4 `narrative-*` |
| data/vfx | 12 (2,189) | render/vfx/*.gd one each (meteor.gd, water.gd, aura.gd ...) | 12 `vfx-*` |

`tools/schemas/map.json`: 195 rules (163 for data/, 32 for audio/data, ui/data, audio/music); roots at map.json:3-8. Every one of the 286 data JSON files matches a rule; every schema file is named by a rule and every rule's schema exists (read-only node check).

## Systems

| System | What it does | Files (lines) | Data/schemas | Switches | Tests / CI job | Reached? | Leftovers | Owner |
|---|---|---|---|---|---|---|---|---|
| Schema validator | Validates every JSON under the map's roots against its schema, plus cross-refs (tools/validate.js; rules from map.json "used by tools/validate.js", map.json:2) | tools/validate.js (78), tools/lib/core.js (184), tools/lib/xref.js (887), xref-fight.js (1,990), xref-input.js (225) | tools/schemas/*.schema.json (193) + map.json | none | `validate.js --self-test` and `validate.js`, CI job `data` (.github/workflows/ci.yml:77, :81) | yes, ci.yml:81 | 0 unmapped data files | tools-pipeline |
| Switch table | 92 rows naming a data key (85) or a page word / setup (7) the private preview flips in a scratch copy; `flip`, `resolve`, `patchMain` | tools/preview/switches.mjs (1,055); SWITCHES at :13-245 | flips data/*, ui/data/options.json, ui/data/features.json, audio/data/*_cues.json; tools/preview/switches-pending.json (0 rows) | the table itself (below) | `tools/preview/preview-selftest.mjs`, CI job `flash` (ci.yml:148); also stack-selftest (:150), pck-verify-selftest (:152) | yes, imported by tools/preview/preview.mjs, stack.mjs, smoke.mjs, pck-verify.mjs | `from` values stale for 12 rows (main already at `to`) | tools-pipeline |
| Animation data | Poses, waves, joints, reactions read by the animation layer | data/anim (17,268) ; reader render/anim/anim_data.gd (612) | 57 anim-* | none in table | anim_check not found in ci.yml run lines (grep) | yes, anim_data.gd:7 | ragdoll_motion.json has "placeholder" (2 hits) | unplaced (Animation owns art/animation/, not data/anim) |
| Art look data | Biome, sky, damage, flash, city and effect looks for render | data/art (8,360) | 12 art-* | none | validate only (`data` job) | partly: 6 of 12 have game readers (table above) | 2 files uncommitted; outposts/polar/auras/energy-lanes/vehicles/colour-vision tool or comment only | unplaced (Art owns art/, docs/art/) |
| World data | Planet, climate, water, rings, craters, settlements, etc. for sim/world | data/biomes (3,155) | 26 biomes-* | gen2, water, surface, floor, turn, settle, waterWarm, nodeWarm, everywhere, cityHold | `world` job via tools/world-checks.mjs --run (ci.yml:399-401); water floor step after | yes, e.g. sim/world/planet.gd:13 | field.json:17 `farAnguish`: false | world-environment |
| Combat data | Templates, finishers, signature variants, recipes, enders, phrases, stick, depth | data/combat (13,674); reader sim/director/data.gd (793) | 11 combat-* | biome, phrases, mixed | validate (`data`); director checks in `godot-parity` (e.g. ci.yml:221, :229) | mostly; mixed.json and styles.json unreached | finishers.json placeholder ids/names (:53, :76, :114); recipes.json:5 names KAI and VORR; sigvariants.json = signature variants by biome (backburnered), read by sim/director/beam.gd; templates.json:210-298 `A.ambush` terms | unplaced (Combat owns data/atoms/, data/exchanges/) |
| Director data | AI levels, interrupts, launch, stick, swing, alchemy, location, rally | data/director (1,685) | 8 director-* | ~45 rows (interrupts, stick, launch, swing, ai) | `godot-parity` gates e.g. chase_tap_check (ci.yml:221), press_decides_check (:229) | yes, sim/director/data.gd | swing.json:163 `anguish`: 2.0; interrupts.json mentions menace (:273, :343) | encounter-systems |
| Fight rules data | Brake, hitstop, kick, power, ladder, wounds, forms, campaign etc. for sim/core | data/fight (1,060) | 18 fight-* + 2 fighter-* | powerPace, slip, hitstopAny, airBrake, kick | `godot-parity`: kick_check (ci.yml:205), power_check (:225), cross_check (:235) | yes (sim/core/*.gd; fighter_data.gd:17) | none found by grep | unplaced (Simulation owns sim/core/, not data/fight) |
| Fighter roster data | Roster, bench, per-fighter fighter/meters/forms | data/fighters (268); reader sim/core/fighter_data.gd (703) | 5 fighter* schemas | none | parity gates (sim/core/tools/parity.gd, ci.yml:191) | yes, fighter_data.gd:16 | RIVAL/meters.json:5 `menace`, PROTAGONIST/meters.json:5 `anguish` (backburnered meters still data-driven); fighter.json "placeholder" 2 hits each | narrative-identity |
| Input data | Actions, layouts, stances, timing (incl. 30-odd `switches.*` keys) | data/input (1,500); reader sim/input/input_data.gd (413) | 5 input-* | 22 rows on timing.json switches.* | sim/input/test/layout_test.gd (CI job not evidenced in ci.yml run lines) | yes, input_data.gd:9 | input-timing.schema.json "TODO/placeholder" 2 hits | unplaced (Controls owns sim/input/, not data/input) |
| Narrative data | Live barks, opponent grounds; combat barks and hints fix for tools | data/narrative (7,974) | 4 narrative-* | none | validate only | partly: live_barks, opponent_grounds yes; combat_barks, hints_fix tool-only | combat_barks.json:3 "every name and line is a placeholder" | unplaced (Narrative owns docs/narrative/, data/fighters/) |
| VFX data | Meteor, water, aura, clash, energy, perf etc. for render/vfx | data/vfx (2,189) | 12 vfx-* | meteor (page word) | effects_check.gd not in ci.yml run lines (grep) | yes, render/vfx/*.gd | none found | unplaced (VFX owns render/vfx/, art/vfx/) |
| Camera data | Swing split share etc. | data/camera/swing.json (8) | camera-swing | splitShare | render/camera tests in `godot-parity` (e.g. chase_rush_check ci.yml:223) | yes, render/camera/cam_places.gd | none | unplaced (Camera owns render/camera/, docs/camera/) |

## Switch table (tools/preview/switches.mjs, 92 rows)

Values read by a read-only node one-liner that parsed each build's JSON at the row's path. "main" is the working tree (data/input, data/director, data/fight, data/biomes, data/combat, data/camera are unmodified vs HEAD per baseline-status.txt). Solo = `orb-first-play-6a30b4c9-6627cb9d/tree/data`; LAN = `orb-lan-6a30b4c9/tree/data`. Rows on ui/data and audio/data are not in either tree (tree/README.txt: "no art, no render, no ui"), so they were read with `grep -a` from `web/index.pck` (solo) and `orb-combat-lan.exe` (LAN).

| id (line) | key | main | solo | LAN |
|---|---|---|---|---|
| gen2 (:14) | data/biomes/climate.json gen | 1 | 2 | 2 |
| biome (:16) | data/combat/launch_biome.json biome.enabled | false | true | true |
| water (:18) | data/biomes/water.json enabled | false | true | true |
| surface (:20) | water.json surface.enabled | false | true | true |
| interrupts (:22) | data/director/interrupts.json water.enabled | false | true | true |
| floor (:24) | water.json floor.enabled | false | true | true |
| calmTurn (:26) | interrupts.json calmTurn.enabled | false | true | true |
| turn (:28) | data/biomes/rings.json turn.on | 0 | 1 | 1 |
| rightStick (:30) | data/input/timing.json switches.rightStick | true | true | true |
| quickRead (:33) | timing switches.quickRead | true | true | true |
| hapticLadder (:36) | timing switches.hapticLadder | true | true | true |
| specialsOff (:39) | timing switches.specialsOff | true | true | true |
| signatureRtOnly (:42) | timing switches.signatureRtOnly | true | true | true |
| beamAim (:45) | timing switches.beamAim | true | true | true |
| hapticRefused (:48) | timing switches.hapticRefused | true | true | true |
| hapticIncoming (:51) | timing switches.hapticIncoming | true | true | true |
| webRumble (:54) | timing switches.webRumble | true | true | true |
| settle (:57) | data/biomes/contact.json settle.enabled | false | true | true |
| splitShare (:60) | data/camera/swing.json splitShare | 0 | 0.7 | 0.7 |
| chaseTap (:63) | interrupts chase.tap.enabled | false | true | true |
| chargeArmour (:66) | data/director/stick.json armour.enabled | false | true | true |
| powerPace (:69) | data/fight/ladder.json chargePerSec | 0.5 | 2 | 2 |
| waterWarm (:71) | water.json flowWarm.cols | 0 | 48 | 48 |
| chargeClose (:73) | interrupts brawl.chargeClose.enabled | false | true | true |
| pressWait (:75) | interrupts brawl.pressWait.enabled | false | true | true |
| oneRuleB (:77) | interrupts brawl.oneRuleB.enabled | false | true | true |
| beamAim2 (:79) | interrupts beamPlays.front.aim.enabled | false | true | true |
| nodeWarm (:81) | data/biomes/field.json warm.radius | 10000 | 10000 | 10000 |
| stickPend (:83) | stick.json pendFollow.enabled | false | true | true |
| joltYield (:85) | data/director/swing.json jolt.yieldToLaunch | false | true | true |
| brawlShareCap (:87) | swing.json brawl.shareCap.enabled | false | true | true |
| gen3 (:89) | setup planetGen 3 | off (no setup) | not evidenced directly (URL carries planet=7, README.txt) | source net/lan.gd:30 SETUP has "planetGen": 3; not found as text in exe |
| blackbox (:91) | page word blackbox=1 | off | on (README.txt URL) | not evidenced |
| go (:93) | page word go=1 | off | on (README.txt URL) | not evidenced |
| meteor (:95) | page word meteor=loud | off | on, loud (README.txt URL) | not evidenced |
| tiles (:98) | page word tiles=1 / --tiles | off | on (README.txt URL) | on (`--tiles=1` in every *.cmd) |
| swing (:100) | swing.json enabled | false | true | true |
| everywhere (:106) | field.json plans.everywhere | false | true | true |
| arc (:109) | data/director/launch.json arc.enabled | false | true | true |
| ending (:112) | interrupts ending.enabled | false | true | true |
| follow (:115) | interrupts bands.follow.enabled | false | true | true |
| lightStops (:118) | stick.json lightStops | true | false | false |
| grapple (:121) | interrupts grapple.enabled | false | true | true |
| driver (:124) | interrupts blast.driver.enabled | false | true | true |
| driverOnRb (:127) | timing switches.driverOnRb | false | true | true |
| beamMove (:130) | interrupts beamPlays.front.ownMove.enabled | false | true | true |
| stallKeep (:132) | timing switches.stallKeep | true | true | true |
| hapticImpact (:135) | timing switches.hapticImpact | true | true | true |
| dodgeHeld (:138) | timing switches.dodgeHeld | false | true | true |
| hapticStages (:141) | timing switches.hapticStages | false | true | true |
| refusedCue (:144) | interrupts press.refusedCue | false | true | true |
| strikeStages (:146) | stick.json strikeStages.enabled | false | true | true |
| beamMoveAi (:148) | interrupts beamPlays.front.ownMove.ai | false | true | true |
| pushMode (:150) | interrupts beamStruggle.pushMode.enabled | false | true | true |
| pushUi (:153) | ui/data/options.json options.struggle_push.default | "face" | "stick" (pck) | "stick" (exe) |
| pushUi2 (:155) | options.struggle_push_p2.default | "face" | "stick" (pck) | "stick" (exe) |
| wallPush (:157, held) | launch.json walk.enabled | false | false | false |
| wallPushAi (:159, held) | launch.json walk.ai.enabled | false | false | false |
| slamTurn (:161, held) | swing.json slam.enabled | false | false | false |
| cityHold (:163, held) | data/biomes/brunt.json lodgeHold | "world" | "world" | "world" |
| flightStrikes (:166) | interrupts zip.flightStrikes.enabled | false | true | true |
| aimCuts (:169, held) | launch.json aimCuts.enabled | false | false | false |
| stickLungeLight (:171) | stick.json lungeLight.enabled | false | true | true |
| flickKeep (:173) | stick.json flickKeep.enabled | false | true | true |
| flickRun (:176) | stick.json flickRun.enabled | false | true | true |
| fullSend (:178) | stick.json fullSend.enabled | false | true | true |
| chordPick (:181) | timing switches.chordPick | false | true | true |
| bNoBeam (:183) | timing switches.bNoBeam | false | true | true |
| bNoBeamKeepRt (:185) | timing switches.bNoBeamKeepRt | false | true | true |
| arrive (:187) | interrupts bands.arrive.enabled | false | true | true |
| slip (:190) | data/fight/power.json dash.slip.enabled | false | true | true |
| dashHandover (:192) | timing switches.dashHandover | false | true | true |
| carryRound (:194) | interrupts carryRound.enabled | false | true | true |
| paceMatch (:196) | data/director/ai.json levels.easy.brawl.paceMatch.enabled | false | true | true |
| inertKnock (:198) | timing switches.inertKnock | false | true | true |
| sideFromBlowOnly (:200) | launch.json sideFromBlowOnly | false | true | true |
| chargeLostCue (:202) | timing switches.chargeLostCue | false | true | true |
| menusRail (:205) | ui/data/features.json features.menus_rail | false | true (pck) | true (exe) |
| hitstopAny (:207) | data/fight/hitstop.json budgetAny.enabled | false | true | true |
| airBrake (:209) | data/fight/brake.json enabled | false | true | true |
| stances (:211) | interrupts stances.enabled | false | true | true |
| phrases (:214) | data/combat/phrases.json enabled | false | true | true |
| craterlook (:217) | page word craterlook=1 | off | off (not in README.txt URL) | not evidenced |
| vsHuman (:219) | ai.json vsHuman.enabled | false | true | true |
| firstMeteor (:221) | launch.json arc.firstMeteor | false | true | true |
| beamFront (:223) | interrupts beamPlays.front.enabled | false | true | true |
| kick (:226) | data/fight/kick.json enabled | false | true | true |
| mixed (:229) | data/combat/mixed.json enabled | false | true | true |
| struggle (:232) | interrupts beamStruggle.enabled | false | true | true |
| soundTug (:236) | audio/data/tug_cues.json enabled | false | true (pck) | true (exe) |
| soundMoments (:239) | audio/data/moment_cues.json enabled | false | true (pck) | true (exe) |
| soundCarry (:242) | audio/data/carry_cues.json enabled | false | true (pck) | true (exe) |

**Counts.** Data-key rows: 85. Main differs from the solo build on 68 of them (63 read from tree/data, 5 from the pck); the same 17 are equal (12 already at their `to` value on main: the 9 timing switches rightStick to webRumble, stallKeep, hapticImpact, and nodeWarm; 5 `held` rows still at `from`). Solo and LAN agree on all 85. Page/setup rows: 7; solo turns on 4 (blackbox, go, meteor, tiles), gen3 not evidenced, craterlook off; LAN turns on tiles, the rest not evidenced (gen3 is in source net/lan.gd:30). Total main vs solo differing: 72 of 92 (68 + 4), with 1 more not evidenced.

## Notable

1. 68 of 85 data-key switches are off on main but on in both of Orb's builds; main does not play like what Orb played (switches.mjs:13-245; read-back above).
2. Twelve rows are at `to` on main already, so their `from` values are stale (e.g. rightStick `from: false` at switches.mjs:30, main data/input/timing.json switches.rightStick = true).
3. `mixed` is switched on in both builds, but no game code reads data/combat/mixed.json: on main, `git grep 'mixed\.json'` hits only switches.mjs, schema, map.json, fixtures and docs; neither build's tree/sim names it (switches.mjs:229; docs/tools/runs/6a30b4c9/switch-list.txt:88 lists it ON).
4. data/combat/styles.json has no game reader, only tools/lib/xref-fight.js:5; data/narrative/combat_barks.json only tools/l10n/strings.mjs:143 and xref; hints_fix.json only tools/lib/xref.js:725.
5. Six data/art files have no game reader (outposts, polar, auras, energy-lanes, vehicles, colour-vision): art/concepts/*.mjs, props_check and a comment ref at render/core/look.gd:921 only.
6. Backburnered meters are still live data: data/fighters/RIVAL/meters.json:5 `menace`, data/fighters/PROTAGONIST/meters.json:5 `anguish`, data/director/swing.json:163 `anguish`, data/biomes/field.json:17 `farAnguish`.
7. Signature variants by biome (backburnered) are still loaded: data/combat/sigvariants.json, `SIGVARIANTS_PATH` at sim/director/data.gd:11, also render/vfx/biome.gd.
8. Hiding/ambush terms remain in exchange templates: data/combat/templates.json:210, :214, :287, :298 (`A.ambush`).
9. Placeholder name KAI and VORR in data: data/combat/recipes.json:5. Placeholder finishers: data/combat/finishers.json:53 (`generic.placeholder`), :76, :114 (`"placeholder": true`).
10. combat_barks.json:3 says every name and line is a placeholder.
11. The "strip" hits in the slice are terrain strips (e.g. data/combat/sigvariants.json:22-24, launch_biome.json:50), not the retired flat arena.
12. Eight data folders are covered by no director's owns line: data/anim, data/art, data/camera, data/combat, data/fight, data/input, data/narrative, data/vfx (DIRECTORS.md owns lines; Combat owns data/atoms/ and data/exchanges/, which do not exist in git ls-files).
13. Schema map is complete: 195 rules, 286 of 286 data JSON matched, no orphan schemas (tools/schemas/map.json; validator in CI job `data`, ci.yml:77-81).
14. Builds' sim trees differ from main's sim files by name (e.g. sim/core/sim.js) per `diff -rq`; cause not checked (possibly line endings), not evidenced either way.
15. switches-pending.json has 0 rows (tools/preview/switches-pending.json), so the build table is SWITCHES alone (tableWith, switches.mjs:250).

## Not covered

- The 132 files in data/anim/waves/ and the 193 schema files were counted and matched to readers/rules, not read one by one.
- gen3, blackbox, go and meteor in the LAN build: no plain-text evidence in the exe or the .cmd files; gen3 for the solo build: only `planet=7` in the URL, the planet function is not plain text.
- Whether anim_check, effects_check and layout_test run in some CI job other than by name in ci.yml run lines: grep found none; qa/run-all.js (ci.yml:43) not opened.
- Per-row behaviour of each switch's code was not read (only the data value and the row's own text).
