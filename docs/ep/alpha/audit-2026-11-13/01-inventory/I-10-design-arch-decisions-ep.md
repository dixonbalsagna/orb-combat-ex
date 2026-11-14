# I-10 inventory: design, architecture, decisions, EP records

- **Slice:** I-10 (design-arch-decisions-ep)
- **Covers:** `docs/design/`, `docs/architecture/`, `docs/decisions/`, `docs/ep/` (with `proposals/`; `docs/ep/alpha/audit-2026-11-13/` skipped)
- **Tracked files:** 260 (`git ls-files docs/design docs/architecture docs/decisions docs/ep`, minus the audit folder)
- **Total lines:** 43,055 (`wc -l` over those 260)
- **By folder (tracked):** design 79 (78 top-level .md + `toys/beam-answers-toy.html`); architecture 63 (49 top-level .md, `pending/` 5, `planet-proof/` 7, `cloud-reports/` 2); decisions 13; ep 105 (top-level 15 .md, briefs/wave1 15, cloud-briefs 32, runs 18, prototypes 9, proposals 10, gate 3, alpha 2, ideas 1)
- **Uncommitted (baseline-status.txt):** 20 paths. 12 modified (` M`): 5 architecture .md (field-ground, fight-swap, forms-core, pending/README, power-core), 7 design .md (beam-answers, economy, hero-forms, overnight-2026-11-08, pillars, spec-wounds, stick-lands). 8 untracked (`??`): 2 READMEs + 3 `.patch` files in `docs/architecture/pending/{clock-by-body,power-flip}/`, 3 .md in `docs/ep/proposals/` (morning-build-review, sunday-build-review, terrain-globe-plan).
- **Bulk output counted, not read:** `docs/ep/runs/` 18 files (gate logs and apply scripts for 091dfac9, 1931a0f8, 238bb9e0, 4890bdd9, 6a30b4c9, 6eec6a75, e9216c1a).
- **Owners (DIRECTORS.md):** `docs/design/` game-design (DIRECTORS.md:92); `docs/architecture/` simulation-engine (:170); `docs/decisions/` and `docs/ep/` the Executive Producer (:63, no `docs/directors/` charter file; written below as `ep`).

This slice is records, not code. The only executable files in it are `docs/ep/gate/*.sh` (the EP's local landing gate) and `docs/architecture/planet-proof/*` (scratch proof scripts). `docs/.gdignore` exists, so no `.gd` under `docs/` is loaded by Godot.

## Systems table

Code-bearing items in the slice first, then the code systems that architecture records describe (implementing file cited; line counts from `wc -l`). Switch values are `data/...` on main as read today.

| System | What it does | Files (lines) | Data/schemas | Switches | Tests / CI job | Reached? | Leftovers | Owner |
|---|---|---|---|---|---|---|---|---|
| EP landing gate | Runs ~100 headless Godot checks, node lints, qa, golden regen and every CI `res://` script on a scratch tree; appends `name exit line` to `$S/$T-sim/r.txt`, ending ALLDONE/CIDONE (run-gate.sh:5-49) | docs/ep/gate/run-gate.sh (51), render-gates.sh (14), README.md (12) | none | env `S`, `T`, `GODOT` required (run-gate.sh:2-3) | itself a gate; not in any workflow | yes, manually by the EP (README.md:6; playbook.md:19 evidence rule); reviewed as K-32 in audit/2026-11-07/checks-review.md:44 | golden_cmp prints only on equal (run-gate.sh:43); hand-listed world loop (:8) | ep |
| Planet proof scripts | Scratch: World's planet function under sim rules in JS and GDScript, plus a comparer | docs/architecture/planet-proof/ README (26), planet.mjs (140), cross64.mjs (99), p64lib.gd (128), planet64.gd (192), planet_flip.gd (40), cmp.py (26) | none | none | none found | unreached (only docs refer: planet-slice-core.md:47, docs/world/planet-module.md:3) | needs `planet_lib.gd` from docs/world/scratch-build (README.md:7,15), not in this folder | simulation-engine |
| Beam answers toy | Browser toy for beam-answers-2 | docs/design/toys/beam-answers-toy.html (220) | none | none | none | unreached (doc artefact) | paper only (beam-answers-2.md:3) | game-design |
| EP prototypes | Single-file HTML feel prototypes Orb played | docs/ep/prototypes/*.html, 9 files (121 to 1158 each) | none | none | none | unreached (doc artefacts) | not evidenced | ep |
| Reference core (overview, module-spec) | Headless deterministic sim; GDScript is truth, JS frozen at 9ac1ea9 | sim/core/sim.gd (468), state.gd (1262), hash.gd (460); JS sim/core/*.js | sim/core/test/golden.json | none | `sim` job (node) and `godot-parity` job parity.gd (ci.yml:47, 178) | yes (whole game) | overview.md/module-spec.md undated; describe the prototype port | simulation-engine |
| Fx event stream (fx-events.md) | Sim's cosmetic output as events | sim/core/fx.gd (749), fx.js | none | none | parity.gd (godot-parity); sim/core/test/fx.test.js (sim job) | yes, sim/core/act.gd:49 | none seen | simulation-engine |
| Shots (shots.md) | Energy blasts as hashed sim state | sim/core/shots.gd (815) | data/fight/shots.json | none | parity.gd | yes, sim/core/cross.gd:162 | none seen | simulation-engine |
| Wounds (wounds-plan.md, brawl-wear-and-mood.md, last-stand.md) | Wear, guard wear, last stand window | sim/core/wounds.gd (471), damage.gd (157), fighter.gd (829) | data/fight/wounds.json | none | parity.gd | yes, sim/core/boons.gd:113; lastStand fighter.gd:530 | wounds-plan.md and last-stand.md still say "plan" (last-stand.md:2) though built | simulation-engine |
| Mood, acts, pauses (mood-style.md, q10-pace-acts-pauses.md) | Fight mood, acts, set-piece pauses | sim/core/mood.gd (601), act.gd (133), pause.gd (215) | data/fight/mood.json, style.json, pause.json | not evidenced | parity.gd | yes, fighter.gd:29 (mood), fighter.gd:581 (pause), cross.gd:266 (act) | both docs headed "plan" (mood-style.md:2, q10:2) though built | simulation-engine |
| Intro (intro-phase.md, dynamic-intros.md) | Crater-landing entrance and composed intro timeline | sim/core/intro.gd (522) | data/fight/intro.json | setup `"intro": true` (intro-phase.md:1) | render determinism `--intro` (run-gate.sh:26) | yes, sim/core/fx.gd:365 | intro-phase.md:3 still "plan, docs only" | simulation-engine |
| Intent (intent-v2.md, intent-v5.md) | Packed per-slot input word | sim/input/intent.gd (301), `VERSION = 4` (:15) | none | none | net job intent second word (ci.yml:340) | yes, sim/core/brake.gd:14 | v5 is paper (intent-v5.md:3) | simulation-engine (doc) |
| Depth (depth-core.md, fight-lanes.md, ADR 0009) | Lanes/depth read from WorldLanes | sim/core/depth.gd (118), sim/world/lanes.gd (334) | data/combat/depth.json | `enabled` false (depth.json:4) | rollback_check `--setup=depth` (run-gate.sh:31) | yes, fighter.gd:329 | fight-lanes.md:3 "nothing here is in the sim yet" (stale) | simulation-engine |
| Forms (forms-core.md) | Protagonist's steps and the coil | sim/core/forms.gd (591) | data/fight/forms.json | `enabled` false (:4) | parity.gd | yes, boons.gd:93 | uncommitted edit to forms-core.md | simulation-engine |
| Boons (boons-core.md) | Run's rare boons in setup | sim/core/boons.gd (126) | data/fight/boons.json | no `enabled` key | parity.gd | yes, sim/core/replay.gd:190 | none seen | simulation-engine |
| Air brake (brake-core.md) | Air brake and `air_brake` event | sim/core/brake.gd (233) | data/fight/brake.json | `enabled` false (:4) | parity.gd | yes, fighter.gd:660 | none seen | simulation-engine |
| Launch flight and hit-stop (feel-core.md) | Launch curve; hit-stop by weight with freeze budget | sim/core/flight.gd (316), hitstop.gd (262) | data/fight/flight.json, hitstop.json | both `enabled` false (:4) | parity.gd | yes, fighter.gd:103; clock.gd:4 | hold-one.md (E102) is paper; nothing in hitstop.gd (grep E102/holdBody: none) | simulation-engine |
| Ricochet (ricochet-core.md) | Glance off surfaces | sim/core/ricochet.gd (172) | data/fight/ricochet.json | `enabled` false (:4) | parity.gd | yes, flight.gd:242 | none seen | simulation-engine |
| Kick (kick.md) | Replaces lag toward stick for free flight | sim/core/kick.gd (203) | data/fight/kick.json | `enabled` false (:3) | kick_check.gd (godot-parity) | yes, fighter.gd:721 | kick.md undated | simulation-engine |
| Run and campaign (run-core.md, campaign-core.md) | Run state/carry; solo episode as run with arc | sim/core/run.gd (570), campaign.gd (480) | data/fight/run.json, campaign.json | run `enabled` false (:5); campaign `enabled` false (:4) | campaign_episode.gd (run-gate.sh:18) | yes, campaign.gd:95; run.gd:391 | run-core.md:1 titled "paper" though run.gd exists | simulation-engine |
| Power (power-core.md) | One energy model | sim/core/power.gd (250) | data/fight/power.json | `enabled` false (:4); flip parked in pending/power-flip (uncommitted) | power_check.gd (godot-parity) | yes, damage.gd:157 | power-flip patch untracked | simulation-engine |
| Field world and swing (field-ground.md, ADR 0012) | Great-circle line and turntable on planetGen 3 | sim/core/field.gd (814), swing.gd (721) | none named | setup `planetGen: 3` (field-ground.md:3) | field_static_check, memo_check, frame_check (ci.yml:215, 257) | yes, flight.gd:289; field.gd:181 | field-ground.md undated, uncommitted edit | simulation-engine |
| 2v2 fights (fight-swap.md, cross-fights.md, cross-end.md) | Two fights on one line; hits across fights; KO'd out | sim/core/cross.gd (508), stage.gd (360) | data/fight/cross.json | setup `{"fights": 2}` (fight-swap.md:3) | cross_check, cross_end_check (godot-parity) | yes, damage.gd:149; cross.gd:22 | two-v-two-lines.md, two-v-two-sim.md, two-v-two-globe.md are paper | simulation-engine |
| Planet load (planet-load.md, load-split.md, match-start.md) | Staged planet load and split script graphs | sim/core/planet_load.gd (206) | none | none | load_split.gd (godot-parity) | yes, campaign.gd:207 | none seen | simulation-engine |
| Snapshot and packed structures | Shared building gen fields, packed per-tick arrays | sim/core/state.gd `BuildingGen` | none | none | rollback_check (net job) | yes, net/desync.gd (grep BuildingGen) | none seen | simulation-engine |
| fork_check (fork-check.md) | Fresh processes on one timeline compare statics | sim/core/tools/fork_check.gd (129) | none | `--negative-control`, `--location` | godot-parity (ci.yml:210-214) | yes, CI | fork-check.md undated | simulation-engine |
| Web parity (web-parity.md) | Native vs web sim bit-for-bit | sim/core/tools/web_parity.mjs, web_parity.gd | none | `--time-limit 2400` | web-parity.yml:59 | yes, CI | none seen | simulation-engine |
| Zip and calm turn (zip-core.md, calm-turn-read.md) | Bowed rush/drop; calm turn ring read | sim/director/zip.gd (1649), calm.gd (381), sim/world/epoch.gd (790) | data/director/interrupts.json (calm-turn-read.md:6) | not evidenced | not evidenced | yes, sim/core/dir.gd:35, :145 | none seen | simulation-engine (doc) |
| Hiding (spec-wounds.md §1c) | Hidden lock and regain | sim/core/hiding.gd (101) | none | not evidenced | parity.gd | yes, fighter.gd:733, :829; director/exchange.gd:333; launch.gd:998 | backburnered system still called; design marks it parked (future-stealth-fighter.md:3) | simulation-engine (code) |

## Records: decisions (ADRs)

| ADR | Title | Status (line 2-4 of file) | Date | Exists in code? |
|---|---|---|---|---|
| 0001 | Engine choice | accepted, confirmed by Orb | 2026-09-29 | EXISTS: project.godot:10 `"4.7"` |
| 0002 | Directors run as separate Claude Code sessions | accepted (Orb) | 2026-09-28 | process, no code |
| 0003 | Director session models, effort and ultracode | accepted (EP) | 2026-09-28 | process, no code |
| 0004 | Seeded matches and the QA harness | accepted (EP) | 2026-09-28 | EXISTS: qa/run-all.js (41), qa/golden-hashes.json; `qa` job ci.yml:30 |
| 0005 | Lean team and token discipline | accepted (EP) | 2026-09-29 | process, no code |
| 0006 | GDScript sim is source of truth; JS core frozen | accepted (EP) | 2026-09-29 | EXISTS: sim/core/*.gd plus frozen *.js, sim/core/test/frozen |
| 0007 | AI-authored content, and where a human hand is required | accepted (Orb) | 2026-09-30 | not evidenced (policy) |
| 0008 | Control scheme, layouts and simple mobile mode | accepted; "work is on hold until Orb gives the go" | 2026-09-30 | EXISTS: sim/input/layout.gd (1351), touch.gd (682); mobile parked by 0011 |
| 0009 | Fight lanes, depth by the choreographer | accepted | 2026-10-01 | EXISTS behind switch: sim/core/depth.gd, depth.json `enabled` false |
| 0010 | The look gate | accepted (Orb) | 2026-10-18 | EXISTS: tools/flash/side-by-side.mjs (138) |
| 0011 | PC first, mobile parked | accepted (Orb); item 3 replaced by 0012 | 2026-10-28 | process |
| 0012 | The arena swings; performance mode to maximum | accepted (Orb); "route is not yet chosen" | 2026-10-31 | partial: sim/core/swing.gd, field.gd behind planetGen 3 |
| 0013 | No target machine during development | accepted (Orb); replaces 0012 item 2, 0011 item 3 | 2026-11-01 | process |

## Records: architecture (`docs/architecture/`, owner simulation-engine)

Status from each file's first lines; "EXISTS" cites the implementing file verified above.

| Record (lines) | Date | Kind | Implementation |
|---|---|---|---|
| boons-core (60) | 2026-10-18 | as built (applied 83405d99) | EXISTS sim/core/boons.gd |
| brake-core (76) | 2026-10-17 | as built | EXISTS sim/core/brake.gd |
| brawl-wear-and-mood (223) | 2026-10-05 | as built | EXISTS sim/core/wounds.gd, damage.gd (`addGuardWear`) |
| calm-turn-read (84) | 2026-10-26 | paper, applied d7647634 | EXISTS sim/world/epoch.gd, sim/director/calm.gd |
| campaign-core (100) | 2026-10-25 | first slice, behind switch | EXISTS sim/core/campaign.gd (off) |
| core-backlog (70) | 2026-10-02 | backlog list | PLAN |
| cross-end (60) | 2026-11-02 | as built | EXISTS sim/core/cross.gd |
| cross-fights (104) | 2026-11-02 | as built | EXISTS sim/core/cross.gd |
| d1-roster-data (290) | 2026-10-12 | plan, partly built (windows 1-3) | EXISTS sim/core/fighter_data.gd (703), roster.gd (65) |
| depth-core (165) | 2026-10-17 | part (a) built, off; rest paper | EXISTS sim/core/depth.gd (off) |
| determinism (179) | 2026-10-29 | analysis for ADR 0001 | EXISTS sim/core/detmath.gd, rng.gd; lint ci.yml:82 |
| dynamic-intros (420) | 2026-10-06 | as built (648c637) | EXISTS sim/core/intro.gd |
| feel-core (137) | 2026-10-19 | as built | EXISTS flight.gd, hitstop.gd (off) |
| field-ground (50) | undated | as built, behind planetGen 3 | EXISTS sim/core/field.gd |
| fight-lanes (323) | 2026-10-01 | plan, "nothing in the sim yet" | partly EXISTS (depth.gd, lanes.gd); header stale |
| fight-swap (66) | 2026-11-01 | as built | EXISTS cross.gd, stage.gd |
| fighters-as-data (126) | 2026-10-12 | windows 1-3 built, 4 paper | EXISTS fighter_data.gd |
| first-crater-sim-share (50) | 2026-10-23 | measurement, nothing changed | n/a |
| fork-check (39) | undated (git 2026-11-01) | as built | EXISTS sim/core/tools/fork_check.gd |
| forms-core (139) | 2026-10-17 | as built | EXISTS sim/core/forms.gd (off) |
| fx-events (206) | 2026-10-12 | implemented both cores | EXISTS fx.gd, fx.js |
| ground-contact-core (72) | 2026-10-02 | review, docs only | not traced (sim/world/contact.gd exists) |
| hold-one (63) | 2026-10-23 | paper, nothing built | PLAN |
| intent-v2 (233) | 2026-10-01 | plan only | superseded; intent.gd is v4 |
| intent-v5 (49) | 2026-10-23 | paper | PLAN (intent.gd:15 VERSION 4) |
| intro-phase (81) | 2026-10-06 | header "plan" then "since 10-06 composed" | EXISTS intro.gd |
| kick (34) | undated | as built, behind switch | EXISTS sim/core/kick.gd (off) |
| last-stand (62) | 2026-10-02 | "plan, docs only" | EXISTS fighter.gd:530 |
| load-split (79) | 2026-10-27 | as built | EXISTS sim/core/tools/load_split.gd in CI |
| match-start (61) | 2026-10-27 | applied | not traced to one file |
| module-spec (230) | undated | port contract | EXISTS sim/ |
| mood-style (297) | 2026-09-30 | "plan, approved" | EXISTS mood.gd, act.gd |
| one-v-many-core (140) | 2026-10-15 | applied 06b0200e | EXISTS roster/state (N bodies) |
| overview (117) | undated | architecture | EXISTS sim/ |
| packed-structures (43) | 2026-10-28 | as built | EXISTS state.gd |
| planet-load (69) | 2026-10-26 | as built | EXISTS planet_load.gd |
| planet-slice-core (125) | 2026-10-16 | paper and scratch | PLAN (proof in planet-proof/) |
| power-core (101) | 2026-11-01 | built, off on main | EXISTS power.gd (off) |
| q10-pace-acts-pauses (244) | 2026-10-01 | "plan, docs only" | EXISTS pause.gd, act.gd; ladder fill fighter_data.gd:625 |
| ricochet-core (82) | 2026-10-22 | applied e09dbbbf | EXISTS ricochet.gd (off) |
| run-core (284) | 2026-10-16 | "paper" | EXISTS run.gd (off) |
| shots (292) | 2026-10-02 | in the tree | EXISTS shots.gd |
| snapshot-tick (54) | 2026-10-28 | as built | EXISTS state.gd |
| two-v-two-globe (68) | 2026-11-01 | sizing | PLAN |
| two-v-two-lines (104) | 2026-11-09 | paper only | PLAN |
| two-v-two-sim (70) | 2026-11-01 | paper only | PLAN (later built as cross.gd) |
| web-parity (69) | 2026-10-23 | measurement + check | EXISTS web_parity.mjs, web-parity.yml |
| wounds-plan (252) | undated | "plan for the EP to route" | EXISTS wounds.gd |
| zip-core (87) | 2026-10-05 | as built | EXISTS director/zip.gd |
| cloud-reports/2026-10-28-packed-structures (129), -snapshot-tick (104) | 2026-10-28 | reports | EXISTS state.gd |
| pending/README (81) | 2026-10-20 | parked slice index, not run by CI (:3) | n/a |
| pending/arena-conditions (63) | 2026-10-22 | conditions | PLAN |
| pending/fighter-split (361) | 2026-10-05 | patch plan (rename) | landed per d1-roster-data.md:4 |
| pending/shots-events-and-kinds (118) | 2026-10-03 | patch plan | not traced |
| pending/zip-and-brawl-core-notes (86) | 2026-10-05 | notes | not traced |
| pending/power-flip/* (untracked: README, 2 patches) | 2026-11-07 | parked | PLAN |
| pending/clock-by-body/* (untracked: README, 1 patch) | 2026-11-01 | prototype, "not for landing" | PLAN |

## Records: design (`docs/design/`, owner game-design)

Nearly every page self-describes as paper, rulings or pitches with "every number is a first value". Implementation is cited only where verified.

| Record (lines) | Date | Kind | Implementation |
|---|---|---|---|
| README (93) | undated | index | n/a |
| agency-pass (1067) | not evidenced | spec, partly superseded by melee-press-feel (:1) | shots.gd (shots.md:1 cites it) |
| background-stats (93) | 2026-10-31 | proposal, paper | PLAN (menace/anguish) |
| balance-targets (969) | 2026-09-29 | P0 draft | not traced |
| beam-answers (175), beam-answers-2 (255) | 2026-11-01 | paper + toy | PLAN; beam-answers uncommitted edit |
| beam-physics (99) | 2026-11-08 | design | not traced |
| beams-third-play (58) | 2026-11-06 | rulings | not traced |
| brawl-second-pass (1446) | 2026-10-06/11 | rulings | not traced (director) |
| buildings (284) | 2026-10-12 | paper | §7.2 EXISTS brake.gd (brake-core.md:2) |
| bystanders (112) | 2026-11-07 | ruling (nobody dies) | not traced |
| campaign (281) | 2026-10-25 | design, paper | campaign.gd (off) |
| combo-builder (106) | 2026-11-01 | paper | PLAN |
| control-rules (266) | not evidenced | rules for ADR 0008 | not traced |
| damage-model (168) | 2026-09-29 | proposal | not traced |
| depth (201) | 2026-10-11/12 | paper | depth.gd (off) |
| economy (239) | 2026-11-07 banner | design (meters) | not traced; uncommitted edit |
| empress-guards (177) | 2026-10-14 | paper | PLAN |
| energy-overhaul (566) | 2026-11-01 | full spec | not traced |
| fight-feel (138) | 2026-10-19 | paper | flight.gd, hitstop.gd, ricochet.gd (off) |
| fighter-pipeline (266) | 2026-10-12 | process | fighter_data.gd |
| future-stealth-fighter (27) | 2026-09-29 | parked | hiding.gd still live (see Notable) |
| gauntlet-plan (164) | 2026-11-07 | plan | PLAN |
| grapple (142) | 2026-10-16 | paper | not traced |
| gravity-well-reading (53) | 2026-11-08 | reading | not traced |
| hero-forms (135) | 2026-11-07 banner | design | forms.gd (off); uncommitted edit |
| launch-anywhere (173) | 2026-10-16 | paper | not traced |
| launch-pair-plan (206) | not evidenced | plan | not traced |
| living-destruction-numbers (140) | 2026-09-29 | starting values | not traced |
| melee-press-feel (1468) | 2026-10-04 | approved prototype rules | not traced |
| minimal-hud (63) | 2026-10-18 | paper | not traced |
| modes (108) | 2026-09-29 | P0 draft | not traced |
| moveset-rules (514) | 2026-09-30 | rulings | not traced |
| open-questions (69) | 2026-09-29 | list | n/a |
| overnight-2026-11-08 (90) | 2026-11-08 | first values for Encounter/Controls | not traced; uncommitted edit |
| pad-first-press (43) | 2026-11-01 | rulings | not traced |
| pillar-2-wordings (23) | 2026-10-30 | paper for Orb | n/a |
| pillars (259) | 2026-11-07 banner | pillars | n/a; uncommitted edit |
| pitch-third-blow (48) | 2026-10-06 | options | PLAN |
| pitches (306) | 2026-09-29 | pitches | PLAN |
| playable-build (261) | 2026-11-06 | rulings | not traced |
| power-scale (333) | 2026-11-01 | paper | power.gd (off) |
| press-decides (118) | 2026-11-01 | rulings | press_decides_check.gd in godot-parity |
| prototype-bugs (21) | 2026-09-29 | P0 list | n/a |
| qa-rows-2026-10-17 (142) | 2026-10-17 | QA rows | not traced |
| right-hand-attacks-rulings (225) | 2026-10-30 | rulings | not traced |
| right-stick-pitches (315) | 2026-10-23 | pitches | PLAN (intent v5 paper) |
| roster-twelve (397) | 2026-10-05 | v3 | PLAN |
| rule-of-cool (180), rule-of-cool-map (410) | not evidenced / 2026-11-01 | feature list / map | §5 kick EXISTS kick.gd (off) |
| rulings-2026-10-18 to -10-30f (21 files, 11 to 118 lines) | as named | one-decision-per-item rulings | 18b §4 EXISTS boons.gd; others not traced |
| run-mode (469) | 2026-10-16 | paper | run.gd (off) |
| slam-and-pace (102) | 2026-11-07 | rulings | not traced |
| spec-wounds (659) | 2026-09-29 | P2/P3 spec | wounds.gd, mood.gd, hiding.gd; uncommitted edit |
| stance-matrix (215) | 2026-09-29 | P0 draft | not traced |
| stick-lands (182) | 2026-11-01 | rulings | not traced; uncommitted edit |
| systems-sketch (211) | 2026-09-29 | P0 sketch | n/a |
| tutorial (53) | 2026-09-30 | plan | PLAN |
| two-v-two (201) | 2026-11-01 | design note | cross.gd, stage.gd |
| unlocks (176) | not evidenced | design | PLAN |
| upgrade-plan (60) | not evidenced | design, "not in the next build" | PLAN |

## Records: EP (`docs/ep/`, owner ep)

| Record (lines) | Date | Kind |
|---|---|---|
| vision.md (1788) | 2026-09-28 to 2026-11-13 | Orb's answers, verbatim log |
| playbook.md (53) | 2026-11-07 | EP operating rules |
| taste.md (36) | 2026-10-15 | look reference (ADR 0010) |
| handoff.md (213) | 2026-09-29 | handoff |
| status-2026-10-01 (126), stance-answers-2026-10-04 (79), roster-twelve-overview (85), orb-review-list (189), wave1-sequencing (71), first-press-list (33), corrective-plan-2026-11-07 (39), right-hand-attacks-pitch (91), standin-controller-brief (159), cloud-pilot-2026-10-28 (29), cloud-workflow (23) | as named / in file | dated EP notes (cloud work retired per memory; records remain) |
| alpha/alpha-audit-specification (779), alpha/stand-in-directive-2026-11-09 (354) | 2026-11-09 | Alpha audit spec and directive |
| briefs/wave1/*.md (15, 41 to 112 lines) | 2026-09-28 | P0 briefs |
| cloud-briefs/*.md (32, 11 to 43 lines) | 2026-10-27/28 | cloud briefs (retired workflow) |
| gate/ (3) | 2026-11-01 | landing gate scripts (systems table) |
| ideas/special-moves.md (116) | undated | Orb's idea sheet |
| proposals/ tracked 10: alpha-feature-brainstorm.html (1425), alpha-feature-workshop.html (398), -workshop-2.html (282), co-op-2v2.md (395), combat-variety-packet.html (573), controller-vision.md (206), gravity-well.html (638), physics-model.html (90), physics-packet.html (573), stick-steals-run.md (126) | 2026-11-01 to 2026-11-09 | stand-in/EP proposals, PLAN |
| proposals/ untracked 3: morning-build-review.md, sunday-build-review.md, terrain-globe-plan.md | 2026-11-07, -08 | read-only reviews / plan |
| prototypes/*.html (9) | 2026-10-04 to 10-28 | playable prototypes |
| runs/ (18) | per sha | gate logs, counted not read |

## Notable

1. The ADRs are all "accepted"; none is marked superseded in its status line, though 0011 item 3 and 0012 item 2 are replaced (docs/decisions/0011-pc-first-mobile-parked.md:3, 0013-no-laptop-target.md:3).
2. ADR 0008's status says work is "on hold until Orb gives the go" (docs/decisions/0008-control-scheme.md:3), yet sim/input/layout.gd (1351 lines) and touch.gd (682) exist.
3. ADR 0012 says "the route is not yet chosen" (docs/decisions/0012-turntable-and-quality-range.md:3) while field.gd/swing.gd ship behind planetGen 3 (docs/architecture/field-ground.md:3).
4. Stale "plan" headers on built systems: last-stand.md:3, intro-phase.md:3, mood-style.md:2, q10-pace-acts-pauses.md:3, wounds-plan.md:3, run-core.md:1, fight-lanes.md:3.
5. Most core features described here are built but off on main: depth.json:4, power.json:4, campaign.json:4, kick.json:3, hitstop.json:4, flight.json:4, ricochet.json:4, forms.json:4, brake.json:4, run.json:5 all `"enabled": false`.
6. Hiding (backburnered) is still called every tick: sim/core/fighter.gd:829 `SimHiding.updateHidden`, plus fighter.gd:733, director/exchange.gd:333, director/launch.gd:998; design calls it parked (docs/design/future-stealth-fighter.md:3).
7. KAI/VORR placeholders appear in 29 slice files (145 lines); d1-roster-data.md:4 tells readers to read KAI and VORR as PROTAGONIST and RIVAL.
8. menace/anguish appears in 46 files (186 lines); docs/design/background-stats.md:3 is the paper proposal to turn them into background stats.
9. "strip" appears in 34 files (87 lines); docs/architecture/two-v-two-lines.md:3 notes LAN 2v2 "plays like the old strip" (paper fix).
10. TODO/FIXME/placeholder in 37 files (99 lines); "ego" in 16 files (48 lines); hiding/ambush in 41 files (117 lines). Counted by `git grep -c`, not read individually.
11. docs/ep/gate/run-gate.sh:43 writes `golden_cmp` only on a match, so a golden mismatch is a missing line (same finding as audit/2026-11-07/checks-review.md:44, K-32).
12. docs/architecture/pending/README.md:3 says nothing there is run by CI; two parked slices (power-flip, clock-by-body) are untracked in the working tree (baseline-status.txt).
13. docs/architecture/planet-proof/README.md:7,15 depends on `planet_lib.gd` that lives outside the folder (docs/world/scratch-build/...), so the proof does not run from its own folder.
14. intent-v5 is paper; intent.gd is `VERSION: int = 4` (sim/input/intent.gd:15).
15. hold-one (E102) is paper (docs/architecture/hold-one.md:3); hitstop.gd has no body-hold path (grep `E102|holdBody` in hitstop.gd/clock.gd: none); a related prototype sits untracked in pending/clock-by-body.

## Not covered

- `docs/ep/runs/` (18 files): counted, not read, per the bulk-output rule.
- HTML proposals and prototypes (19 files): headers only; no claim on their contents.
- The 21 `rulings-*.md` and the long design specs (agency-pass, brawl-second-pass, melee-press-feel, balance-targets, energy-overhaul): headers read; per-rule implementation not traced. "not traced" in the tables means not checked, not absent.
- vision.md (1788 lines): only its date range and section headings sampled.
- No checks were run (read-only audit); CI "job" columns name the workflow step, not a passing result.
