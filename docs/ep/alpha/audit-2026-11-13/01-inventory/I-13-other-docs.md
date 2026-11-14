# I-13 other-docs: inventory

- **Slice:** I-13 (other-docs), read-only audit, 2026-11-13.
- **Covers:** every `docs/` folder except docs/design, docs/architecture, docs/decisions, docs/ep, docs/marketing, docs/legal, docs/directors, and except every `docs/*/pending/` and `docs/*/runs/` folder (at any depth). That leaves: accessibility, animation, art, audio, camera, combat, controls, director, narrative, net, perf, production, qa, rendering, research, setup, tools, ui, vfx, world, plus `docs/.gdignore`. (`docs/sim/` holds only `runs/`, so nothing of it is in this slice.)
- **Tracked files:** 2118 (`git ls-files docs` minus the excluded paths). By kind: 806 md, 542 png, 118 jpg, 117 py, 97 gd, 88 mjs, 71 json, 54 txt, 44 diff, 40 svg, 36 patch, 35 gif, 14 cmd, 12 wav, 10 csv, 8 html, 6 uid, 5 sh, 3 ps1, 2 js, 2 cjs, others.
- **Total lines:** 234,541 lines across the 1,371 non-media tracked files (media = png/jpg/gif/wav/svg, 747 files, not counted as lines; 941,097 if every tracked file is fed to `wc -l`).
- **By folder (tracked):** world 498 (of which scratch-build 321), vfx 250, rendering 216, ui 215, perf 189, animation 132, controls 90, tools 87, camera 75, narrative 71, director 59, art 59, combat 49, qa 49, audio 37, research 23, net 10, accessibility 6, production 1, setup 1, .gdignore 1.
- **Uncommitted paths in this slice** (from baseline-status.txt): **13,751** = 26 modified (` M`) + 13,725 untracked (`??`).
  - Untracked by kind: 9,104 jpg, 3,542 webp, 832 png, 108 json, 56 gif, 45 md, 11 html, 8 txt, 4 cjs, 3 mjs, 1 py, 2 cmd and 9 more whose names hold spaces (all under docs/tools/img/b1-wake-* and docs/tools/shortcuts/).
  - Untracked by folder: tools 8,592 (almost all docs/tools/img/*: hitstop-ab 1,524, clip-meteor-route 902, clip-meteor-route-peakfloor2 902, page-reel-* reels, morning-1107-* stills), rendering 4,981 (img/lanes 2,993, img/sky 1,752, img/lookgate 214), camera 51, vfx 44, controls 30, world 20, animation 16, director 7, perf 5, art 3, combat 1, qa 1.
  - Untracked non-media records: 45 md (for example docs/world/meteor-crater.md, docs/controls/refusals.md, docs/director/two-v-two-plan.md, docs/tools/planet-cache-shipping-plan.md) and the controls clip tools (docs/controls/clips/*: export-thumbs.py, make-overlay.mjs, read-*.cjs, hitstop-ab.json, thumbs.json), docs/perf/tools/preplay/audio-stall-test.mjs, audio-underrun.mjs.
  - Modified: docs/art/README.md, biomes-pages.md; docs/camera/damage-inset-build.md, damage-inset.md, launch-director.md, split-vision.md; docs/combat/energy-movesets.md; docs/controls/README.md, beam-answers-input.md, haptics.md, responsiveness.md, right-hand-attacks-model.mjs, right-hand-interface.md; docs/perf/node-warm-radius-2026-11-07.md, perf/tools/preplay/perf-run.mjs, two-fights-kit-2026-11-07.md; docs/qa/cloud-reports/2026-10-31-swing-rows.md; docs/tools/img/look-refusal-compact/2 pngs, docs/tools/pad-steps.md; docs/vfx/clash-shockwave.md, power-up-ideas.md, img/power-up-ideas/three-ways-to-power-up.png; docs/world/lot-reach.md, power-world.md, struggle-meeting-point.md.

This slice is mostly records (design notes, reports, measurements, stills). The code that lives here is tools, probes, paper models and scratch builds; none of it is shipped game code. The systems table lists every piece of code or data in the slice that something can run or read; the record index at the end lists every markdown record one line each.

## Systems

| System | What it does | Files (lines) | Data/schemas | Switches | Tests / CI job | Reached? | Leftovers | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Phone web shell + head block | Builds the phone block of the Web preset's html/head_include from docs/perf/web-shell and writes/checks it in export_presets.cfg (web-head.mjs:2-6); ocx-shell.js is the page shell, ocx-crumbs.js the local-only freeze breadcrumbs (ocx-crumbs.js:1-5) | docs/perf/tools/web-head.mjs (120), docs/perf/web-shell/ocx-shell.js (65), ocx-crumbs.js (243), build-site.patch, manifest.webmanifest, icons/icon-192.png, icon-512.png; docs/perf/tools/make-placeholder-icons.mjs (43) | manifest.webmanifest; no schema | crumbs off unless tools/site.json has "crumbs": true (tools/site-crumbs.mjs:1); key absent in tools/site.json today | `web-head.mjs --check` in ci.yml job `data` (ci.yml:99); site job folds crumbs (ci.yml:426-427) | yes: ci.yml:99; tools/build-site.mjs:118-123 copies the manifest and icons; render/core/main.gd:734 names the crumbs | icons are PLACEHOLDER (make-placeholder-icons.mjs:2); crumbs described as "a PARK, off until the EP lands it" (ocx-crumbs.js:1) | performance-platform |
| Perf browser benches | Guarded-browser frame, latency, load, freeze and crumbs benches over built web sites, plus report writers (frame-bench.mjs:2-5) | docs/perf/tools/frame-bench.mjs (239), latency-bench.mjs (170), load-probe.mjs (153), load-report.mjs (78), freeze-probe.mjs (149), crumbs-test.mjs (168), audit-run.mjs (68), audit-summary.mjs (105), make-audit-sites.mjs (165), bench-page.mjs (45), phone-emu-check.mjs (142), stage-run.mjs (41), stage-web.mjs (90), stage-report.mjs (153), gl-fetch-bench/index.html (133) | outputs only (run json) | CLI flags only (frame-bench.mjs:4-5) | none found (searched .github/workflows) | unreached by code: named only in docs (docs/perf/README.md, docs/perf/budgets.md, docs/tools/load-and-captures.md) | none marked | performance-platform |
| Perf scratch hooks | Edit a scratch copy of the game to add timers/marks for a measurement (lake-hook.mjs:2-4 describes the pattern; applied after hook-perf/hook-slice/hook-pbiome) | docs/perf/tools/scratch-hooks/ 49 files (hook-*.mjs, hook-*.py, make-late-tree.py; largest hook-stages.mjs 240, hook-latency.mjs 165, hook-gen2.mjs 153) | none | none | none found | unreached by code; named in docs/rendering/tools/lake-hook.mjs:3 | hook-strip.mjs (27) and hook-dissolve.mjs (12) by name (strip arena / dissolve era; contents not read) | performance-platform |
| Swing bench | GDScript benches and scratch patchers for swing/launch/stage tick cost | docs/perf/tools/swing-bench/ 34 files (swing_bench2.gd 180, swing_bench.gd 165, meteor_ground.gd 127, stage_bench.gd 99, hook-*.py, fix-*.py) | none | none | none found | unreached by code; named in docs/perf/swing-tick-2026-10-31.md | none marked | performance-platform |
| Pre-play read tools | Guarded headless Chrome reads of a first playthrough on the real GPU, replay benches (preplay/README.md:1-5) | docs/perf/tools/preplay/ preplay-read.mjs (187), replay-bench.mjs (81), replay_prof.gd (113), replay_reads.gd (130), replay_firsts.gd (74), long_2v2.gd (100), layer-bisect*.mjs (73, 56), perf-run.mjs (46, modified), perf-stretch.mjs (65); untracked audio-stall-test.mjs, audio-underrun.mjs | meteor-scene.json | CLI flags | none found | unreached by code; docs/perf/README.md; crackle-ab.mjs:4 reuses its set-up | none marked | performance-platform |
| Old-PC kit | Serves one build and a test page to one LAN PC, takes its report back, compares two PCs' sim-tick timings and hashes (oldpc-server.mjs:2-6; kit/oldpc_sim.gd:2-4) | docs/perf/oldpc/oldpc-server.mjs (114), page.html (239), page-selftest.mjs (41), proxy.ps1 (59), start-test.cmd (21), words-trial.mjs (40), kit/build-kit.mjs (69), compare-results.mjs (94), kit-trial.mjs (41), oldpc_sim.gd (120), read-two-fights.mjs (32), run-test.template.cmd (183) | outputs only | --site/--bind/--go (oldpc-server.mjs:5-6) | page-selftest.mjs (manual); no CI | unreached by code; docs/perf/oldpc-test-2026-10-31.md, two-fights-kit-2026-11-07.md | none marked | performance-platform |
| Perf export helpers | One-off writers: scratch web-parity template runner, desktop export, stage tree; native CPU bench scripts | docs/perf/tools/make-web-parity-template.cjs (12), make-desktop-export.mjs (45), make-stage-tree.mjs (54), native-cpu-bench.ps1 (19), orb-native-bench.ps1 (85), orb-native-bench.cmd (5) | none | none | none found | unreached by code (docs/perf/web-template-2026-10-28.md, desktop-boot-2026-10-27.md) | none marked | performance-platform |
| Narrative line lint + beat check | Lints forward-facing lines against rules in line-lint.json (--live mode for live barks, --names); beat-check validates beat-template libraries against Legal's ln04/ln05 (line-lint.py:2-6, beat-check.py:2-6) | docs/narrative/line-lint.py (249), beat-check.py (92) | docs/narrative/line-lint.json; reads data/narrative/live_barks.json, docs/narrative/pending/*.json | rule set in line-lint.json | none found (searched .github/workflows, tools/) | manual tool: data/narrative/live_barks.json:7640 tells the reader to run it; no code caller | none marked | narrative-identity |
| Voice lab sheets | CSV line batches with an Orb-edit column (kai.csv header row) | docs/narrative/voice-lab/ 12 files (9 csv + README, known-tells.md, mid-combat-lines.md); docs/narrative/move-names-draft.csv; style.draft.json, taunts.draft.json | csv, draft json | none | none | records only | kai.csv and vorr.csv carry placeholder names (kai.csv:2 "KAI") | narrative-identity |
| Controls paper models | Seeded synthetic-thumb models of the right-stick recognizer, LT dodge direction, and the right-hand-attacks claw-bot gate (right-stick-model.py:1-2, dodge-dir-model.py:1, right-hand-attacks-model.mjs:1-2) | docs/controls/right-stick-model.py (384), dodge-dir-model.py (104), right-hand-attacks-model.mjs (177, modified) | constants in code (right-stick-model.py:5-6 DZ 0.25, ON 0.60, OFF 0.35; dodge-dir-model.py:4-6) | constants above | none found | right-stick-model.py: yes, run by tools/capture/right-stick-run.py:1; other two unreached (docs only) | none marked | controls-feel |
| Controls clip tools | Input scripts and thumbnails for the hit-stop A/B and thumb clips, read back by sim/input probes | docs/controls/clips/ ALL UNTRACKED: hitstop-ab.json, hitstop-ab.overlay.json, thumbs.json, export-thumbs.py, make-overlay.mjs, read-orb-*.cjs, read-stick-log.cjs | hitstop-ab.json, thumbs.json | none | none | yes: sim/input/tools/hitstop_script_probe.gd:17 and thumb_phantom_probe.gd:13 (tracked) read these untracked files | tracked code depends on untracked data | controls-feel |
| Controls pad packet | Static HTML page of the pad scheme | docs/controls/pad-packet.html (250) | none | none | none | unreached by code (docs/controls/beam-answers-input.md, docs/ep/standin-controller-brief.md) | none marked | controls-feel |
| Patch handoffs outside pending/ | Diffs handed to the EP to apply (schemas, glue, hash, touch bridge, shader) | docs/controls/*.patch 22 files (e.g. intent-hash.patch, touch-bridge.patch, i2c-glue.patch); docs/animation/handoff/ 11 patches + 4 *.schema.json; docs/ui/start-menu-main.patch; docs/world/planet-window1/tools-fixtures.diff, tools-map.diff | 4 anim schemas | none | none | whether applied: not evidenced (not checked against main) | stale-handoff risk | controls-feel / animation / ui-ux / world-environment |
| Animation launch-pair coverage data | Rows of every move per fighter and the pose/sequence that plays it, checked by the coverage tools (coverage.gd:2-4) | docs/animation/launch-pair-coverage.json, launch-pair-live-status.json (+ .md) | anim-pairlive.schema.json (handoff) | --strict, --list (coverage.gd:5) | render/anim/tools/coverage.gd, coverage_live.gd; not in ci.yml (searched) | yes: render/anim/tools/coverage.gd:8 | none marked | animation |
| Animation schema drafts | Draft JSON schemas | docs/animation/schema-drafts/ 4 files (bake-order, follow-through, joints, lead-in) | the schemas | none | none | not evidenced | drafts beside tools/schemas | animation |
| Audio crackle A/B | Forces main-thread stalls in a scratch web build and records AudioContext output to measure holes (crackle-ab.mjs:2-5) | docs/audio/tools/crackle-ab.mjs (175) | docs/audio/img/crackle/*.json, 6 wav | --stalls, --ticks, --query (crackle-ab.mjs:6) | none | unreached by code (docs/audio/crackle.md) | none marked | audio-music |
| Audio proposed recipes | Proposed cue recipes and a schema, with sketch wavs | docs/audio/proposed/ 5 files | audio-beat-cues.schema.json, catastrophe-recipes.json, launch-and-tug-recipes.json | none | none | not evidenced | proposal | audio-music |
| Rendering tool hooks | Scratch hooks for look-gate stills and profiling (lake, props, prof), shader compile timing (fxc_time.py, hlsl.mjs), link time | docs/rendering/tools/lake-hook.mjs (87), props-hook.mjs (99), prof-hook.mjs (144), linktime.mjs (57), hlsl.mjs (60), fxc_time.py (78) | none | --floor (lake-hook.mjs:6) | none run by CI; render/tools/lake_water_check.gd (CI godot-parity, ci.yml:277) only names lake-hook for its stills (lake_water_check.gd:13) | named by render/tools/lake_water_check.gd:13; others docs only | none marked | rendering-techart |
| World catastrophe prototype | Standalone throwaway Godot project: four fixed-timeline scenes (magma cut, mushroom cloud, orbit blasts, collapse), no sim (main.gd:2-6); sim_probe.gd | docs/research/world-catastrophe/proto/main.gd (829), main.tscn (6), project.godot, export_presets.cfg; sim_probe.gd (307); tools/clips.sh (22), rerun.sh (22) | none | none | none | unreached: own project.godot; docs/research/world-catastrophe.md | throwaway by its own header (main.gd:2) | unplaced (Research owns research/, not docs/research/) |
| Planet data writer (window 1) | Writes data/biomes/planet.json and tools/schemas/biomes-planet.schema.json for WorldPlanet (mk_planet_data.py:1) | docs/world/planet-window1/mk_planet_data.py (109), planet_fixture_cases.json, measure.txt, 2 diffs | writes data/biomes/planet.json + schema | none | none | unreached by code (docs/world/planet-module.md) | one-shot generator kept beside its outputs | world-environment |
| World scratch builds | Per-window scratch copies of HEAD: Python patchers (mk_*.py, a shared mk_wbc_lib.py copied 19 times), GDScript checks and dumps, stills, results (scratch-build/README.md:3-8) | docs/world/scratch-build/ 321 files: 94 py, 80 gd, 42 diff, 37 txt, 31 README, 25 json; largest contact.gd (818), mk_slicejob.py (615), gen_svgs.py (493), t/t_rows.py (436), city3/files/sim/world/settlements.gd (404) | planet-slice/planet2.json, planet_12.json and others | build.py [enable] (README:7) | none of its own | yes, one file: sim/world/tools/planet_check.gd:5 reads planet-slice/planet2.json; planet_check runs in CI job `world` via tools/world-checks.json:9 and ci.yml:401 (skips if absent, planet_check.gd:103) | KAI/VORR in g1_reach.py:107, stage1/mk_stage1.py:26, mk_stage12.py:27; strip_time.gd, strip_time2.gd (strip era); stale copies of sim/world files (city3/files/sim/world/*.gd, contact.gd) | world-environment |
| Ring-any-angle probes | Saved GDScript probes as .gd.txt and results | docs/world/ring-any-angle/ 30 files (8 probe .gd.txt, probe-results-2026-10-31.txt, stills) | none | none | none | not runnable as saved (.txt) | research record | world-environment |
| UI mockups | Static HTML mockups: beam answer alert, combo builder, three modern menu styles | docs/ui/mockups/beam-answer-alert.html (248), combo-builder.html (376), menus-modern/a-rail.html (134), b-tiles.html (63), c-strip.html (45) | none | none | none | design source only: ui/widgets/ui_rail.gd:3 names a-rail.html as the pick; ui/hud/ui_hud.gd:1052 names the alert spec | c-strip.html by name (menu style, not the arena) | ui-ux |
| UI schema drafts | Draft schemas for colour vision, fighter names, stances | docs/ui/ui-colour-vision.schema.json, ui-fighter-names.schema.json, ui-stances.schema.json | the schemas | none | none | not evidenced | drafts outside tools/schemas | ui-ux |
| Combat proposals | Proposed identity/lock data and two movesets | docs/combat/proposals/ 4 json + 2 md (identity, lock, moveset.colossus, moveset.prodigy) | json | none | none | not evidenced | proposals | combat-choreography |
| Build shortcuts | Windows .cmd launchers that serve a kept build from homework\Files\builds on 127.0.0.1:8771 with URL switches (Open - Monday build.cmd:3-6) | docs/tools/shortcuts/ 11 tracked .cmd (36-39 each) + README; 2 untracked | URL args (planet=7, meteor=loud, travel=1.5, ...) | URL switches | none | for the owner's hand use; no code caller | point at dated builds | unplaced (Tools owns tools/, not docs/tools/) |
| Tools saved ledgers | Gauntlet, ledger and switch-list outputs of the feel kit for named builds | docs/tools/gauntlet-*.json (2), morning-1107-* (json/txt, 9), orb-play-1229-ledger* (4) | outputs | none | none | records only | none | unplaced |
| Media outputs (tracked) | Stills, gifs, wavs, svgs supporting the records | 747 files: vfx 199, rendering 173, ui 163, world 78, camera 35, animation 23, tools 20, art 18, perf 15, audio 12, controls 5, research 5, director 1 | clip json beside stills (e.g. docs/vfx/img/biome-fx/plumedesert-clips.json) | none | none | records only | counted, not read | per folder |

## Notable

1. CI's data job runs a tool that lives in docs: `node docs/perf/tools/web-head.mjs --check` (.github/workflows/ci.yml:99), and tools/build-site.mjs:118-123 refuses to build without docs/perf/web-shell/manifest.webmanifest and icons. Release-critical files sit in a records folder.
2. The site's Home Screen icons are placeholders by their generator's own words (docs/perf/tools/make-placeholder-icons.mjs:2).
3. CI job `world` runs sim/world/tools/planet_check.gd (tools/world-checks.json:9, ci.yml:401), which reads docs/world/scratch-build/planet-slice/planet2.json (planet_check.gd:5) and silently skips that comparison if the file is gone (planet_check.gd:103).
4. Tracked probes read untracked data: sim/input/tools/hitstop_script_probe.gd:17 reads docs/controls/clips/hitstop-ab.json and thumb_phantom_probe.gd:13 reads docs/controls/clips/thumbs.json; both JSON files are `??` in baseline-status.txt.
5. render/anim/tools/coverage.gd:8 reads docs/animation/launch-pair-coverage.json; neither coverage.gd nor coverage_live.gd appears in .github/workflows/ci.yml (searched by name).
6. The narrative line lint (docs/narrative/line-lint.py, 249 lines) is not run by any CI job or tools/ runner (searched .github/workflows and tools/ for "line-lint"); data/narrative/live_barks.json:7640 tells the reader to run it by hand.
7. Placeholder fighter names KAI/VORR appear in 99 and 65 tracked files of the slice (git grep `\bKAI\b` / `\bVORR\b`), heaviest in docs/director (31 files), docs/qa (22), docs/narrative (15), docs/world (13); also in scratch code (docs/world/scratch-build/g1_reach.py:107) and as files docs/narrative/voice-lab/kai.csv, vorr.csv.
8. Backburnered systems still documented: menace/anguish/ego meter in 78 files (world 22, narrative 21, combat 9, director 8); e.g. docs/audio/direction.md:96 drives an audio input from "the leading fighter's ego meter"; docs/combat/procedural-moves.md:116,135 bends style by ego meters. "hiding" in 63 files, "ambush" in 42.
9. Retired flat strip arena wording ("the strip", "strip arena", "flat strip") in 63 files (world 13, camera 11, ui 9, perf 9); e.g. docs/world/after.md:24,42. Scratch code by name: docs/world/scratch-build/planet-slice/strip_time.gd, docs/perf/tools/scratch-hooks/hook-strip.mjs.
10. No TODO/FIXME marks in any tracked file of the slice (git grep `TODO|FIXME` returned nothing).
11. docs/world/scratch-build holds stale copies of shipped sim files (city3/files/sim/world/lanes.gd 204, settlements.gd 404; contact.gd 818) and 19 copies of mk_wbc_lib.py (44 lines each); its README says "nothing here is in the tree" (docs/world/scratch-build/README.md:3).
12. 36 .patch and 44 .diff handoff files live outside pending/ folders (docs/controls/*.patch 22, docs/animation/handoff/ 11, docs/ui/start-menu-main.patch, docs/world/scratch-build 42 diff, docs/world/planet-window1 2 diff); whether each has landed is not evidenced.
13. Untracked bulk dwarfs the tracked slice: 13,725 untracked paths vs 2,118 tracked, almost all stills/reels under docs/tools/img (8,592) and docs/rendering/img (4,981), per baseline-status.txt.
14. Ownership gaps: docs/qa (49 files), docs/tools (87), docs/research (23) and docs/setup (1) are not on any director's owns line (DIRECTORS.md:447 QA owns qa/, :472 Tools owns tools/, :622 Research owns research/), yet ci.yml:2,63,82,87 cite docs/tools/*.md as the docs for CI steps.
15. docs/.gdignore makes Godot skip importing all of docs/; code that reads docs files does so by raw FileAccess (planet_check.gd:94-95, coverage.gd:8), which works in headless checkouts and would not exist in an export.

## Not covered

- Media (747 tracked images/gifs/wavs/svgs; 13,725 untracked files) counted, not opened.
- Markdown records: each indexed by its first heading only (index below); bodies not read except where cited. The built/plan column in the index is a keyword hint from the first 40 lines, not a verdict.
- docs/world/scratch-build: 321 files counted and grouped; individual scripts not read beyond the top README, file names and line counts.
- docs/perf/tools/scratch-hooks and swing-bench: headers not read file by file; described from names, line counts and the hook pattern in docs/rendering/tools/lake-hook.mjs:2-4.
- Whether each patch/diff handoff landed on main: not checked.
- 9 untracked paths with spaces in their names (docs/tools/img/b1-wake-*, docs/tools/shortcuts/) counted only.

## Record index (markdown, tracked, one line each)

Columns: path under docs/ | lines | first heading | keyword hint (plan/park? = proposal, park or plan words in the first 40 lines; built? = landed, shipped, on main or committed) | date from the file name or first 15 lines. Generated mechanically from `git ls-files`; docs/world/scratch-build's 31 READMEs are grouped above and not listed.

| Record | Lines | Title | Hint | Date |
| :--- | ---: | :--- | :--- | :--- |
| accessibility/audit-2026-10-28.md | 162 | Accessibility audit, 2026-10-28 | - | 2026-10-28 |
| accessibility/beam-alert-review.md | 63 | Beam answer alert: accessibility review (2026-11-01) | - | 2026-11-01 |
| accessibility/cloud-reports/2026-10-28-foundation.md | 69 | Accessibility & Localization, cloud report: the foundation (2026-10-28) | plan/park? | 2026-10-28 |
| accessibility/l10n-plan.md | 102 | How Orb Combat EX would be translated | plan/park? | 2026-10-28 |
| accessibility/right-hand-controls.md | 62 | Right-hand attacks: what accessibility needs to hold (2026-10-30) | built? | 2026-10-30 |
| accessibility/swing-motion.md | 75 | The swing and motion sensitivity (Accessibility, 2026-10-31) | plan/park?/built? | 2026-10-31 |
| animation/air-brake-looks-plan.md | 41 | The air brake, the skid landing and the regain: a plan for readable looks (Animation, 2026 | plan/park? | 2026-11-07 |
| animation/air-brake-looks.md | 37 | The air brake's looks, built (Animation, 2026-11-07) | plan/park? | 2026-11-07 |
| animation/air-recovery.md | 36 | Air recovery (Animation, 2026-10-23) | - | 2026-10-23 |
| animation/bake-pace.md | 52 | The bake's pace: the animation drain's p95 (Animation, 2026-10-31) | - | 2026-10-31 |
| animation/beam-shove.md | 46 | The beam's shove, and the catch (Animation, 2026-11-01) | plan/park?/built? | 2026-11-01 |
| animation/body-tint.md | 29 | The body's tint and palette: the sky's light on the fighters, and the colour-vision preset | - | 2026-10-06 |
| animation/brawl-second-pass-view.md | 76 | The brawl's second pass: Animation's view (2026-10-08) | - | 2026-10-08 |
| animation/clinch-sizing.md | 148 | The clinch and the catch on A, sized (2026-10-16) | - | 2026-10-16 |
| animation/clip-list.md | 147 | Clip list: atoms to key sets | plan/park? | 2026-09-30 |
| animation/cloud-reports/2026-10-28-pair-ready.md | 71 | Cloud report: pair_ready from a fighter's own waves (Animation, 2026-10-28) | built? | 2026-10-28 |
| animation/cloud-reports/2026-10-28-pose-drain.md | 81 | Cloud report: the pose_exists drain (Animation, 2026-10-28) | built? | 2026-10-28 |
| animation/combat-pieces.md | 77 | Combat's new pieces, the cash-in row, the beam's cast poses, the opening and the chase cue | - | 2026-10-16 |
| animation/creative-rulebook-rows.md | 134 | The creative rulebook's rows (Animation, 2026-11-07) | - | 2026-11-07 |
| animation/creative-rulebook.md | 52 | Creative rulebook: pose, gesture and look rules (Animation, 2026-11-07) | plan/park? | 2026-11-07 |
| animation/cues-c2.md | 51 | The next chain's cues, the closing rule and the held charge: what Animation built against  | plan/park? | 2026-10-06 |
| animation/energy-reach.md | 58 | Energy in reach: the point-blank bolts and the blast, as blows (slice C2t) | - | 2026-10-06 |
| animation/fight-view.md | 27 | Drawing the other fight's bodies (Animation, 2026-11-02) | - | 2026-11-02 |
| animation/fighter-onboarding.md | 73 | Bringing a fighter into the animation: what he is in my data, the steps, the costs | built? | 2026-10-12 |
| animation/fighters-in-depth.md | 127 | Fighters in depth: what the bodies need at an angle (Animation's side) | - | 2026-10-12 |
| animation/finisher-styles-motion.md | 8 | The three finisher styles in motion (2026-10-18) | plan/park? | 2026-10-18 |
| animation/flight-locomotion.md | 36 | Flight locomotion (Animation, 2026-10-23) | plan/park? | 2026-10-23 |
| animation/flight-strikes-plan.md | 45 | Flight strikes: a look per path (Animation, 2026-11-07, plan) | plan/park? | 2026-11-07 |
| animation/flight-strikes.md | 29 | Flight strikes, built (Animation, 2026-11-07) | plan/park?/built? | 2026-11-07 |
| animation/flurry-study.md | 75 | The flurry look study (2026-10-06): X, Y and B moving, view only | - | 2026-10-06 |
| animation/follow-through.md | 39 | The follow-through: the handover and the weight carried on (Animation, 2026-10-30) | plan/park? | 2026-10-30 |
| animation/glasses-part.md | 35 | The rival's glasses: the part, planned with Rendering (2026-10-05) | plan/park? | 2026-10-05 |
| animation/grip-stages.md | 45 | The grip as five stages in the bodies (Animation, 2026-10-23) | built? | 2026-10-23 |
| animation/ground-locomotion.md | 41 | Ground locomotion (Animation, 2026-10-23) | - | 2026-10-23 |
| animation/guard-pass.md | 82 | The contact-key pass: the free arm stays near the guard (2026-10-16) | - | 2026-10-16 |
| animation/hair-and-tail.md | 60 | Hair, topknot, cloth and the Anti-hero's tail: what the rig needs | - | 2026-10-01 |
| animation/handoff/anim-medium-wind.map.md | 12 | Tools: the map entry for `anim-medium-wind.schema.json` (Animation, 2026-10-06) | - | 2026-10-06 |
| animation/handoff/protag1-schema.md | 8 | Schema handoff for the Protagonist's waves (Tools) | - | 2026-10-03 |
| animation/held-lint.md | 27 | Held-pose lint: Legal's h01 to h03, scoped (RL-087) | - | - |
| animation/hit-reactions.md | 54 | Hit reactions with variety (Animation, 2026-10-23) | - | 2026-10-23 |
| animation/homework4.md | 65 | Homework 4 for Animation: the arms that bend wrong, the styles, the tech's legs, three pos | - | 2026-10-16 |
| animation/homework4b.md | 104 | Homework 4, the second pass: the pulled frames at their source, the wide net for bad bends | - | 2026-10-16 |
| animation/hook-ready.md | 96 | Ready for the recipes window: what Animation's tree does, and how it was proved | - | 2026-10-12 |
| animation/incremental-bake.md | 49 | The incremental bake (Animation, 2026-10-27) | plan/park? | 2026-10-27 |
| animation/intro-gestures.md | 69 | The intro gestures: Narrative's ten intents, for the launch pair (2026-10-06) | - | 2026-10-06 |
| animation/joint-limits.md | 98 | Joint limits: no knee or elbow can bend the wrong way | - | 2026-10-01 |
| animation/joint-posing.md | 31 | Joint posing through the moves: the stomp, and what the measures say (Animation, 2026-10-3 | - | 2026-10-30 |
| animation/launch-pair-coverage.md | 219 | The launch pair: animation coverage (2026-10-03) | plan/park? | 2026-10-03 |
| animation/lead-in.md | 59 | The body's lead-in: weight and arm paths on the split's blows (Animation, 2026-10-30) | - | 2026-10-30 |
| animation/lunge-crouch.md | 24 | The mid-band lunge's crouch (Animation, 2026-10-23) | - | 2026-10-23 |
| animation/many-bodies-and-runs.md | 73 | Many bodies, the lead scan's five frames, and the runs' look (Animation, 2026-10-15; parke | plan/park? | 2026-10-15 |
| animation/move-pool-sizing.md | 62 | Move-pool sizing (Animation, 2026-11-01) | plan/park? | 2026-11-01 |
| animation/moveset-parts.md | 126 | Animation's side of the moveset generator (2026-10-05) | plan/park? | 2026-10-05 |
| animation/next-waves-sizing.md | 69 | The next waves, sized (2026-10-06) | - | 2026-10-06 |
| animation/nine-cells-look.md | 84 | The nine cells: what the body does, how readable the three styles are, and what would make | built? | 2026-10-14 |
| animation/nine-cells.md | 85 | The nine cells: what the body shows, what plays today, what is built | plan/park?/built? | 2026-10-12 |
| animation/overhaul-plan.md | 50 | Animation overhaul plan: maximally dynamic on the 27-bone mannequin | plan/park? | 2026-10-02 |
| animation/pair-live.md | 66 | The launch pair live (2026-10-03) | - | 2026-10-03 |
| animation/pieces23.md | 55 | The 23 pieces of protag7 and rival4, live (Animation, 2026-10-31) | - | 2026-10-31 |
| animation/pop-juggle.md | 37 | The pop and the juggle (Animation, 2026-10-23) | plan/park?/built? | 2026-10-23 |
| animation/pose-pipeline.md | 1360 | Pose pipeline: hand-made key poses, procedural in-betweens | plan/park?/built? | 2026-09-30 |
| animation/power-up-pose.md | 48 | Powering up on RT: the pose (Animation, 2026-11-01, paper) | plan/park? | 2026-11-01 |
| animation/press-ack.md | 39 | The press-tick anticipation (Animation, 2026-10-23) | built? | 2026-10-23 |
| animation/press-styles.md | 206 | Press styles: how the body moves for tech, speed and heavy blows (2026-10-04) | plan/park?/built? | 2026-10-04 |
| animation/pulled-frames.md | 37 | The pulled frames: what the last pass was correcting, and what is fixed (Animation, 2026-1 | - | 2026-10-16 |
| animation/ragdoll-families.md | 34 | Ragdoll: out-of-plane on, flail families, weight you can see, the skid's judder (Animation | - | 2026-10-25 |
| animation/ragdoll-physics-paper.md | 129 | Ragdoll physics for entertaining combat: the paper (2026-10-16) | - | 2026-10-16 |
| animation/ragdoll-slices.md | 76 | The ragdoll slices and the su_hammer hunt (2026-10-17) | plan/park?/built? | 2026-10-17 |
| animation/recoil-flips.md | 20 | Recoil exits and flips (Animation, 2026-10-22) | plan/park? | 2026-10-22 |
| animation/review-plan.md | 65 | Pose estimates for the rich moveset, and how Orb's review drops from about 35 hours to abo | - | 2026-10-02 |
| animation/secondary-motion.md | 35 | Secondary motion (Animation, 2026-10-23) | - | 2026-10-23 |
| animation/set-pieces-plan.md | 58 | Set pieces: the entrance, the staredown, the winner in the wreckage (plan, not built) | plan/park? | 2026-10-01 |
| animation/shiver-by-weight.md | 32 | The shake by weight (Animation, 2026-10-22) | built? | 2026-10-22 |
| animation/solve-carry.md | 48 | The solve's carry and the striking arm's release (Animation, 2026-10-30) | plan/park?/built? | 2026-10-30 |
| animation/solve-cost.md | 55 | What the fighters' solve costs, and the first cut (Animation, 2026-10-31) | - | 2026-10-31 |
| animation/split-bake-plan.md | 36 | The split bake: a plan (2026-10-03), not built | plan/park? | 2026-10-03 |
| animation/stamp.md | 30 | The stamp: the Y-mashed stomp as a stamp (Animation, 2026-10-31) | plan/park?/built? | 2026-10-31 |
| animation/standing-beats.md | 27 | Standing beats (Animation, 2026-10-31) | plan/park? | 2026-10-31 |
| animation/stick-class.md | 66 | The right stick's class: Animation's side (Animation, 2026-10-31) | - | 2026-10-31 |
| animation/stick-pre.md | 22 | The stick's pre-read, drawn (Animation, 2026-11-01) | built? | 2026-11-01 |
| animation/struggle-dig-in.md | 31 | The beam struggle's dig-in (Animation, 2026-10-23) | - | 2026-10-23 |
| animation/super-heavy.md | 74 | The super-heavy tier: the first sixteen key sets (B), and the mediums on 12 ticks | - | 2026-10-06 |
| animation/tenth-round.md | 58 | The tenth round's moves, the moveset distinction, and the interjection's tell (Animation,  | - | 2026-10-15 |
| animation/throwables-sizing.md | 49 | Throwables: Animation's figure (2026-10-18) | - | 2026-10-18 |
| animation/tick-cost.md | 57 | The tick's cost: the per-tick cuts and the frame-aware bake slice (Animation, 2026-10-27) | - | 2026-10-27 |
| animation/warping-rules.md | 109 | Warping rules | plan/park? | 2026-09-30 |
| animation/water-family-checks.md | 27 | The water family and anim_check: wrong setup, not lost animation (Animation, 2026-10-31) | built? | 2026-10-31 |
| animation/water-stance.md | 39 | Standing on deep water (Animation, 2026-10-30) | - | 2026-10-30 |
| animation/zip.md | 225 | The LT zip: the body side (2026-10-05) | - | 2026-10-05 |
| art/README.md | 49 | Art: index | plan/park?/built? | 2026-09-29 |
| art/ai-prompt-policy.md | 110 | AI-assisted art: prompt policy | plan/park? | 2026-09-29 |
| art/anti-hero-concepts.md | 206 | The Anti-hero: three silhouettes | - | 2026-09-29 |
| art/anti-hero-round2.md | 89 | The Anti-hero, round 2: five silhouettes | plan/park? | 2026-09-29 |
| art/beam-colours.md | 20 | Beam colours: Art's answer on VFX's families (2026-10-16) | - | 2026-10-16 |
| art/biomes-cover.md | 45 | Biome cover: the 35 silhouettes with triangle counts | - | 2026-10-24 |
| art/biomes-pages.md | 486 | Biome pages: the fifteen biomes, one by one | - | 2026-10-23 |
| art/biomes.md | 128 | The biome look bible | - | 2026-10-23 |
| art/blank-variations.md | 73 | Blank, five ways | - | 2026-09-29 |
| art/cars.md | 15 | The city's cars: four silhouettes and a wreck (2026-10-18) | - | 2026-10-18 |
| art/city-facades.md | 40 | The city's towers up close: palettes, facade types and the crown tower's stubs | - | 2026-10-16 |
| art/closeup-directions.md | 71 | Close-ups of the fighters' faces: three directions, a recommendation | - | 2026-10-02 |
| art/coil-turnaround.md | 60 | The Coil: turnaround | - | 2026-09-29 |
| art/colour-vision.md | 41 | Colour-blind options: the lane colours | - | 2026-10-06 |
| art/cosmetics-plan.md | 70 | Cosmetics plan: a vast unlock set, by data | plan/park? | 2026-09-30 |
| art/crater-look.md | 45 | The crater's look (Art, 2026-11-01) | - | 2026-11-01 |
| art/cyborg-turnaround.md | 72 | The Cyborg: turnaround | - | 2026-09-29 |
| art/directions.md | 112 | Character art directions | plan/park? | 2026-09-29 |
| art/district-looks.md | 87 | District looks, building shapes and landmarks: the visual brief | plan/park? | 2026-09-30 |
| art/dynamic-sky.md | 73 | The dynamic sky | - | 2026-10-06 |
| art/empress-turnaround.md | 73 | The Empress: turnaround | - | 2026-09-29 |
| art/energy-lanes.md | 88 | Energy colour lanes | plan/park? | 2026-10-24 |
| art/faces-hair-coat.md | 29 | Faces, hair, forms and shoulders: the round after Orb's picks (2026-10-18) | built? | 2026-10-18 |
| art/fighter-design-workflow.md | 129 | Fighter design workflow: from Orb's one-page brief to a fighter on rig R1 | plan/park? | 2026-10-12 |
| art/fighter-picks-round1.md | 56 | Fighter picks, round 1: the Cyborg and the Empress | plan/park? | 2026-10-12 |
| art/flash-prototype-spec.md | 107 | Head-flash prototype: spec for Rendering | - | 2026-09-29 |
| art/hero-forms-look.md | 33 | The Protagonist's five forms, the run's keepsakes and finisher styles | built? | 2026-10-17 |
| art/homework-3-sheets.md | 79 | Homework 3 sheets: the aura, the glasses, the look pass | - | 2026-10-15 |
| art/launch-pair-look.md | 23 | The launch pair's look | - | 2026-10-03 |
| art/marked-aura.md | 187 | Marked plus flashes: the character style | - | 2026-09-29 |
| art/polar-outposts.md | 15 | The polar outposts: a research station and a mining camp (2026-10-18) | - | 2026-10-18 |
| art/polar-palette.md | 38 | The polar cold palette (for World's ice, 2026-10-17) | - | 2026-10-17 |
| art/props-review.md | 30 | The sim's props, as drawn: Art's rulings (2026-10-29) | - | 2026-10-29 |
| art/protagonist-turnaround.md | 69 | The Protagonist: turnaround | - | 2026-09-29 |
| art/red-shade.md | 30 | The Anti-hero's red against the saturated-red test | - | 2026-10-17 |
| art/rock-look.md | 18 | Close rock that reads as a mountain (Art, 2026-11-01) | - | 2026-11-01 |
| art/rule-of-cool-art.md | 68 | Rule of cool: the art side | plan/park? | 2026-10-01 |
| art/shell-cover.md | 9 | The beach shell (cover shape for World's `shell` prop) | - | 2026-10-29 |
| art/sky-and-distance.md | 49 | Sky and distance: an audit and a target | plan/park? | 2026-10-15 |
| art/style-guide.md | 360 | Style guide v1: faceted cel, Marked plus flashes | plan/park? | 2026-09-29 |
| art/tile-ground-look.md | 24 | The tiled 3D ground: look check (Art, 2026-10-31) | - | 2026-10-31 |
| audio/babble-vs-gemini.md | 100 | Our babble voice and Gemini's mumble-speech suggestion (paper, 2026-10-16) | plan/park? | 2026-10-16 |
| audio/biomes.md | 111 | Biome sound (2026-10-23) | - | 2026-10-23 |
| audio/brawl-beat.md | 139 | The beat, the nine cells and depth, by ear | - | 2026-10-12 |
| audio/brawl-cues.md | 105 | Brawl cues: the sounds the three strengths and the launcher need | plan/park? | 2026-10-06 |
| audio/brawl-rework.md | 55 | The brawl's sounds, lower and chunkier (rework of 2026-10-16) | - | 2026-10-16 |
| audio/carry.md | 60 | Sound that carries what the HUD no longer draws (2026-10-18) | built? | 2026-10-18 |
| audio/catastrophe.md | 97 | The catastrophe tier's sound (paper, 2026-10-16) | - | 2026-10-16 |
| audio/coop-sound.md | 78 | The co-op and controller sounds (Audio and Music, 2026-11-07) | plan/park? | 2026-11-07 |
| audio/crackle.md | 68 | The web crackle: one-shots played by the browser (Audio and Music, 2026-11-06) | plan/park? | 2026-11-06 |
| audio/direction.md | 420 | Sound direction for Orb Combat EX | plan/park? | 2026-09-29 |
| audio/first-play-sound.md | 81 | What a player hears in the candidate build (Audio and Music, 2026-11-01) | built? | 2026-11-01 |
| audio/grunts.md | 170 | Grunt palettes and how to make them for free | plan/park? | 2026-09-29 |
| audio/launch-and-tug.md | 130 | The launch opening and the beam struggle, by ear (paper, 2026-10-16) | plan/park?/built? | 2026-10-16 |
| audio/pad-start.md | 47 | Sound after a start with the pad alone (Audio and Music, 2026-11-07) | plan/park? | 2026-11-07 |
| audio/suno-direction.md | 207 | Suno direction: a tongue-in-cheek speed-metal soundtrack | plan/park? | 2026-10-04 |
| audio/suno-prompts.md | 380 | Suno prompts: paste-ready blocks | plan/park? | 2026-10-04 |
| audio/warm-async.md | 59 | The audio warm-up across frames (2026-10-26, re-cut the same day) | plan/park? | 2026-10-26 |
| camera/beam-struggle.md | 41 | The beam struggle's framing, and the opening (Camera, 2026-10-16) | plan/park? | 2026-10-16 |
| camera/blinks.md | 60 | Camera: blinks and blink clashes | plan/park? | 2026-09-30 |
| camera/buildings-in-frame.md | 278 | Buildings in frame: a chain, a lodge, a wall slam, a falling stack (Camera, 2026-10-12) | - | 2026-10-12 |
| camera/camera-v2.md | 256 | Camera v2: bigger fighters, a lag bound, launch following, cuts and lanes | plan/park? | 2026-10-01 |
| camera/city-in-depth.md | 179 | The re-laid city in depth: what the camera gives Rendering so the fight is never hidden (C | - | 2026-10-12 |
| camera/crossing-start.md | 62 | The opening at a crossing: the first two seconds (Camera, 2026-10-12) | - | 2026-10-12 |
| camera/damage-inset-build.md | 68 | The damage inset: the build plan (Camera, 2026-10-17) | plan/park? | 2026-10-17 |
| camera/damage-inset.md | 105 | A live inset of the damage: a dodged beam that hits a skyscraper behind you (Camera, 2026- | - | 2026-10-16 |
| camera/depth-and-chains.md | 74 | Camera: fighters in depth, building hits and chains | plan/park? | 2026-10-01 |
| camera/director.md | 505 | The camera director (Camera, 2026-10-19, design) | built? | 2026-10-19 |
| camera/exosphere.md | 82 | The exosphere: the camera for the run mode's 60 seconds above the atmosphere (Camera, 2026 | - | 2026-10-16 |
| camera/feel.md | 47 | The camera's feel (Camera, 2026-10-19) | built? | 2026-10-19 |
| camera/img/flight-mass/README.md | 3 |  | - | - |
| camera/img/landscape-shot/README.md | 3 |  | - | - |
| camera/img/low-launch/README.md | 4 |  | - | - |
| camera/img/rally/README.md | 10 |  | built? | 2026-10-27 |
| camera/img/shot-grammar/README.md | 3 |  | - | - |
| camera/img/slam-whip/README.md | 3 |  | built? | - |
| camera/img/smooth-before-after/README.md | 3 |  | - | - |
| camera/img/takeover-divider/README.md | 3 |  | built? | - |
| camera/interior-chain-cutaway.md | 28 | The cutaway that follows a body inside a building chain (Camera, 2026-10-17, paper) | - | 2026-10-17 |
| camera/launch-cinematography.md | 195 | Shooting extreme velocity: launches and high-stakes moments | - | 2026-11-01 |
| camera/launch-director.md | 86 | The camera director at high velocity: what's built (Camera, 2026-11-01) | plan/park? | 2026-11-01 |
| camera/launch-follow.md | 45 | After a launch: the player always knows where the opponent is (Camera, 2026-10-16) | - | 2026-10-16 |
| camera/lean-step.md | 27 | A leaner SplitRig.step (director-20, on main in d235af1c) | built? | 2026-10-27 |
| camera/lunge-framing.md | 135 | Framing a lunge that goes out and comes back (a plan; no code yet) | plan/park? | 2026-10-05 |
| camera/one-v-many.md | 176 | One versus many: framing three to five bodies (Camera, 2026-10-14) | built? | 2026-10-14 |
| camera/panel-flash.md | 62 | The record's camera-led clips: the signature strip under Reduce flashing, and one report f | built? | 2026-10-17 |
| camera/rally-framing.md | 61 | The rally's camera (on main, behind Encounter's rally.enabled) | built? | 2026-10-25 |
| camera/rule-of-cool-shots.md | 230 | Rule of cool: the camera's rows | plan/park? | - |
| camera/rushcity.md | 53 | rushcity reduced: the standing area failure (Camera, 2026-10-16) | - | 2026-10-16 |
| camera/split-screen.md | 651 | Orb Combat EX: the dynamic split screen | built? | 2026-09-29 |
| camera/split-vision.md | 103 | How split screen should work: a proposal for Orb (Camera, 2026-11-01) | plan/park? | 2026-11-01 |
| camera/swing-view.md | 143 | The camera in a swing: what's built (Camera, 2026-10-31) | plan/park? | 2026-10-31 |
| camera/travel-ordinary.md | 69 | The travel budget in the ordinary mode (Camera, 2026-10-18) | built? | 2026-10-18 |
| camera/two-v-two.md | 14 | 2v2 over LAN: what the camera needs (Camera, 2026-11-01) | - | 2026-11-01 |
| camera/varied-intros-data.md | 59 | The varied intros' shot grammar as data (Camera, 2026-10-17) | - | 2026-10-17 |
| camera/varied-intros.md | 106 | The camera's part of varied introductions (Camera, 2026-10-16) | plan/park? | 2026-10-16 |
| camera/whip-pan.md | 29 | The whip pan: signaturecity (2026-10-15) | plan/park? | 2026-10-15 |
| camera/zip-framing.md | 120 | Framing the zip (a plan against Encounter's final cue names; no code until its commit) | plan/park? | 2026-10-05 |
| combat/alchemist-content.md | 194 | The fight alchemist: the content it mixes | plan/park?/built? | 2026-10-02 |
| combat/alchemist-recipes.md | 270 | The alchemist's recipes, the traded-blows set piece and the charges at range | - | 2026-10-02 |
| combat/barrage-signature.md | 27 | The Anti-hero's barrage as his signature: what it needs | built? | 2026-10-12 |
| combat/beam-answers-moves.md | 132 | Beam answers, as moves | - | 2026-11-01 |
| combat/biomes-sampler.md | 108 | How a fight reads in each biome | - | 2026-10-23 |
| combat/biomes.md | 294 | Biomes that change the fight: signatures, launches and the ground | - | 2026-10-23 |
| combat/blitz.md | 148 | Speed blitzes: ping-pong, teleport spam, no pass-through, full contact | plan/park? | 2026-10-01 |
| combat/brawl-hook.md | 118 | The brawl asks for a piece by its cell: the hook, for Encounter | - | 2026-10-12 |
| combat/choreography-feel.md | 201 | Back and forth: recoil exits, ricochets, clash meets and turns | - | 2026-10-19 |
| combat/cloud-reports/2026-10-28-movegen.md | 78 | Cloud report: the moveset generator as a tool (2026-10-28) | plan/park?/built? | 2026-10-28 |
| combat/contact-spacing.md | 160 | Contact spacing and sides: the data side | - | 2026-10-01 |
| combat/control-scheme-data.md | 142 | Control-scheme data plan (Encounter's step 2) | plan/park? | 2026-09-30 |
| combat/data-fields.md | 319 | Data fields for atoms, exchanges and signatures | plan/park? | - |
| combat/dynamic-feel.md | 143 | Dynamic feel pass | - | 2026-09-29 |
| combat/energy-movesets.md | 161 | Energy movesets: four fighters, and how the director composes energy exchanges | - | 2026-10-23 |
| combat/exchange-templates.md | 351 | Exchange templates | plan/park? | - |
| combat/fighter-cards.md | 104 | A fighter's card, and the pool builder for any number of fighters | built? | 2026-10-12 |
| combat/fighter-onboarding.md | 111 | Bringing a fighter into Combat's data | - | 2026-10-12 |
| combat/grapple-hybrid.md | 102 | Grappling on A: the hybrid of the catch and the clinch, the moveset side | - | 2026-10-16 |
| combat/grapple-pitches.md | 113 | Grappling on A: three pitches | - | 2026-10-14 |
| combat/henchmen-grades.md | 312 | Henchmen in grades: the moveset side | - | 2026-10-23 |
| combat/lane-sweep-for-orb.md | 5 | LANE SWEEP: the village's own signature | - | - |
| combat/launch-enders.md | 125 | A launch from any blow: launch enders by piece family, aimed by the stick | - | 2026-10-17 |
| combat/launch-pair-movesets.md | 240 | The launch pair: what each fighter ships with | plan/park? | 2026-10-02 |
| combat/launch-vectors.md | 71 | Launch vectors and landings: what Combat's pieces must change | plan/park? | 2026-10-01 |
| combat/m0-rich.md | 259 | M0 at the rich end: the Anti-hero's first real moveset | plan/park? | 2026-10-01 |
| combat/move-grammar.md | 331 | Move grammar | plan/park? | 2026-09-28 |
| combat/moveset-generator.md | 414 | The moveset generator | - | 2026-10-04 |
| combat/moveset-system.md | 434 | Moveset system | plan/park? | 2026-09-30 |
| combat/nine-cells-look.md | 61 | The nine cells: what each looks like, and what would make it its own | built? | 2026-10-14 |
| combat/press-read.md | 128 | "Better combo control": what a press does | built? | 2026-11-01 |
| combat/procedural-moves.md | 404 | Procedural moves | - | 2026-09-29 |
| combat/proposals/README.md | 45 | Proposals: generated movesets for two fighters who are not in the build | plan/park? | 2026-10-28 |
| combat/proposals/review-sheet.md | 1368 | Review sheet: the five stances, both fighters | built? | - |
| combat/roster-rows.md | 97 | Rows for the Demon Cyborg and the Empress, the floors of a fighter's own, and the gate on  | plan/park? | 2026-10-12 |
| combat/rule-of-cool-pitches.md | 126 | Rule-of-cool pitches: procedural combos, the right hand and the planet | - | 2026-10-31 |
| combat/s3b-loader-note.md | 66 | S3b loader note for Encounter Systems | plan/park? | 2026-09-29 |
| combat/signature-variants.md | 114 | Signature variants | - | - |
| combat/signatures-on-stick.md | 124 | The four signatures on the stick, and making Loupe memorable | plan/park? | 2026-11-01 |
| combat/split-and-pieces.md | 211 | The split by path, the tenth round's pieces, the guards, and the two apart | - | 2026-10-15 |
| combat/struggle-scoring.md | 86 | The finisher's struggle: scoring that does not reward mashing | plan/park? | 2026-10-03 |
| combat/throwable-cars.md | 63 | Throwables: the moveset side | - | 2026-10-17 |
| combat/tools/README.md | 10 | Combat feel probes: moved to QA | - | - |
| combat/variety-pass.md | 239 | Variety pass | plan/park? | 2026-09-30 |
| combat/wall-slam.md | 30 | The wall slam's damage: Combat's number | built? | 2026-10-12 |
| controls/README.md | 51 | docs/controls: Controls and Game Feel | plan/park? | 2026-09-29 |
| controls/agency-input.md | 314 | Input for the agency pass: the press reader, energy hold, boost and escape, air recovery,  | plan/park?/built? | 2026-10-02 |
| controls/auto-form-spec.md | 60 | Parked spec: `autoForm`, the Simple layouts take a ready form for the player | - | 2026-10-01 |
| controls/b-no-beam.md | 50 | B never fires a beam (switches.bNoBeam) | plan/park? | 2026-11-08 |
| controls/beam-aim-feel.md | 118 | Beam aim and the charge, read off Orb's thumb (Controls, 2026-11-01; proposal, nothing lan | plan/park?/built? | 2026-11-01 |
| controls/beam-answers-input.md | 57 | Beam answers on the pad: the fit check (Controls, 2026-11-01; paper only, nothing run) | plan/park? | 2026-11-01 |
| controls/brake-and-grapple.md | 35 | The air brake's bit, the clinch's "A only", and the grapple's reads: built and parked behi | - | 2026-10-17 |
| controls/claw-bot-gate.md | 90 | The claw-bot gate, and the dodge's left-stick read (spec, paper) | plan/park? | 2026-10-25 |
| controls/cloud-reports/2026-10-28-hold-toggles.md | 59 | Hold toggles: report, 2026-10-28 | built? | 2026-10-28 |
| controls/dash-handover.md | 89 | LT's dash handover (switches.dashHandover) | plan/park? | 2026-11-08 |
| controls/energy-build-plan.md | 59 | Energy overhaul, Controls' build plan (paper; held until Orb answers GD's section 18) | plan/park? | 2026-10-23 |
| controls/energy-input.md | 99 | Energy attacks overhaul: the input grammar (paper) | - | 2026-10-23 |
| controls/feel-schema.md | 113 | Schema proposal for `data/input/feel.json` (for Tools) | plan/park? | 2026-09-30 |
| controls/flick-kept.md | 46 | A held flick is not "Didn't start" (switches.flickKept) | plan/park?/built? | - |
| controls/grapple-input.md | 74 | The grapple's inputs: the catch and the clinch, A on every layout (paper) | - | 2026-10-16 |
| controls/haptics.md | 74 | Haptics: the rumble that carries the cues, one set of numbers, and what the host does | plan/park? | 2026-10-16 |
| controls/hold-to-flurry.md | 45 | Hold to flurry: an accessibility option for the mash (a question for Orb; nothing is built | built? | 2026-10-05 |
| controls/hold-toggles.md | 66 | Hold or toggle: Guard, the manoeuvre and charging stances, Transform | - | 2026-10-28 |
| controls/i2c.md | 59 | I2c: the layout layer produces intent v2 (keyboard, pad, touch) | built? | 2026-10-01 |
| controls/inert-knock.md | 37 | A push on a layer where the right stick is inert is told (switches.inertKnock) | plan/park? | 2026-11-08 |
| controls/input-gates.md | 46 | The input gates: what a sim/input or data/input window must run | built? | 2026-10-22 |
| controls/input-map.md | 133 | Input map: keyboard (P1 and P2) and gamepad | plan/park? | 2026-09-30 |
| controls/input-schema.md | 446 | Remap data, presets and schemas for Tools (ADR 0008) | plan/park? | 2026-09-30 |
| controls/input-scheme.md | 344 | Input scheme (ADR 0008): actions, layouts, tap and hold rules, keyboard, touch, intent | plan/park? | 2026-09-30 |
| controls/intent-queue-plan.md | 100 | Plan: input map revision for intent queuing (no timing presses) | plan/park? | 2026-09-30 |
| controls/local-two-player.md | 71 | Local two-player: the join rule, the pairings, what to wire, what to check | - | 2026-10-01 |
| controls/lt-speed.md | 38 | LT high-speed flight: is the pad slow to start it up close? (Controls' check, 2026-11-08) | plan/park? | 2026-11-08 |
| controls/lunge-control.md | 360 | Stances on the controls, and lunge control in the manoeuvre stance | plan/park?/built? | 2026-10-04 |
| controls/pair-actions-plan.md | 36 | One-key pair actions: a plan (nothing built; Orb's item is still open) | plan/park? | 2026-10-06 |
| controls/palm-turn-overtake-read.md | 24 | The Palm Turn and the overtake: the left stick's read at the 45-degree edge | - | 2026-10-25 |
| controls/params-cache.md | 30 | The kept `params()` of the press reader and the aim helper | - | 2026-10-28 |
| controls/phone-feasibility.md | 63 | Is the phone control scheme feasible? (for Orb) | plan/park?/built? | 2026-10-23 |
| controls/phone-test-checklist.md | 77 | Phone test checklist (for Orb) | - | - |
| controls/phone-touch.md | 80 | Simple touch on a phone: what it measures, what a phone player feels, and the plan | plan/park? | 2026-10-06 |
| controls/platform-plan.md | 128 | Plan: gamepad support in the web build and on desktop, and mobile's two schemes | plan/park? | 2026-09-30 |
| controls/prompt-glyphs.md | 90 | Prompt glyphs per device | plan/park? | 2026-09-30 |
| controls/q19-input.md | 178 | Questionnaire 19 and the play notes: the input side | plan/park?/built? | 2026-10-05 |
| controls/remap.md | 64 | Remap support and the Full touch preset | built? | 2026-10-01 |
| controls/responsiveness.md | 181 | Responsiveness: where the ticks go between a thumb and the screen (Controls, 2026-11-01) | built? | 2026-11-01 |
| controls/right-hand-attacks.md | 240 | Right-hand attacks: "the left hand survives, the right hand hurts" (pitch 4a, built behind | - | 2026-10-28 |
| controls/right-hand-interface.md | 67 | Right-hand attacks: the interface for everyone else (Controls, 2026-10-31) | - | 2026-10-31 |
| controls/right-stick-capture.md | 55 | Real-thumb capture for the right stick: the tool spec (one page, paper) | plan/park? | 2026-10-23 |
| controls/right-stick.md | 185 | The right stick: the input side of every pitch (paper) | - | 2026-10-23 |
| controls/right-thumb.md | 98 | The right thumb: no grip beats the standard grip (paper) | - | 2026-10-25 |
| controls/rule-of-cool-pitches.md | 106 | Rule of cool: ten controller pitches for right-hand 4a on the arena (Controls, 2026-11-01) | - | 2026-11-01 |
| controls/rulings.md | 318 | Controls and Game Feel: rulings on windows, buffering, hit-stop and the finisher struggle | plan/park? | 2026-09-30 |
| controls/shake-pass.md | 63 | Shake pass: per-event values and the split's per-pane shake | - | 2026-09-29 |
| controls/skill-strike-input.md | 52 | Brawl slice B2, the skill strike: what the input layer says | built? | 2026-10-05 |
| controls/stage-a-proof.md | 63 | Stage A proof checklist (for QA) | plan/park?/built? | 2026-09-30 |
| controls/stage-c-spec.md | 118 | Stage C spec: sticky weight and the signature intent | plan/park? | 2026-09-30 |
| controls/stage-c-tests.md | 69 | Stage C test scripts (sticky weight and signature intent) | plan/park? | 2026-09-30 |
| controls/stance-key-help.md | 51 | Stances on touch, and the specials: answers for the key-help legend | plan/park? | 2026-10-05 |
| controls/stance-questionnaire.md | 52 | Stance questionnaire for Orb (Controls, 2026-10-04) | built? | 2026-10-04 |
| controls/stoke-and-chin.md | 67 | Bolus's stoke, Loupe's On the Chin, and the universal release on a real pad (Controls, 202 | plan/park?/built? | 2026-11-01 |
| controls/struggle-input.md | 53 | The beam struggle's inputs: the surge, the stray and the let-go, on every layout (paper) | plan/park? | 2026-10-16 |
| controls/tech-and-pulse-input.md | 85 | Input specs: the tech, the pulse-clash and the beam answer | - | 2026-10-01 |
| controls/touch-bridge.md | 93 | Touch Simple bridge to today's intents | - | 2026-10-01 |
| controls/two-player-feel.md | 57 | Two players at once: latency, the queue, fairness and the shared keyboard | - | 2026-10-01 |
| controls/two-v-two-input.md | 51 | 2v2 on the pad: the focus, the extra bits and the claw-grip check (Controls, 2026-11-01; p | - | 2026-11-01 |
| controls/windup-read.md | 82 | The wind-up read: the release in a freeze, `press_read.gd` on paper, the burst, and the nu | - | 2026-10-06 |
| director/agency-evidence.md | 182 | Agency: evidence and architecture for the director | built? | 2026-10-02 |
| director/agency-plan.md | 56 | Agency: the director's slice plan after Orb's picks | plan/park? | 2026-10-02 |
| director/agency-slice-1.md | 82 | Agency, slice 1: the earned launch, the knock-back, the attacker's cancel and the press lo | plan/park?/built? | 2026-10-02 |
| director/agency-slice-10.md | 67 | Agency, slice 10: the alchemy layer's framework (A1 and A2) | plan/park? | 2026-10-03 |
| director/agency-slice-11.md | 118 | Agency, slice 11: the blur's cadence and lock, flow and the string's ender (A4 and A3) | plan/park?/built? | 2026-10-03 |
| director/agency-slice-12.md | 61 | Agency, slice 12: the barrage counts every clean shot | - | 2026-10-03 |
| director/agency-slice-13.md | 93 | Agency, slice 13: timing paid on every press, flow paid in set-ups and contests | - | 2026-10-03 |
| director/agency-slice-14.md | 64 | Agency, slice 14: the tapped shot's share, and a floor under the flow's cut | - | 2026-10-04 |
| director/agency-slice-2.md | 100 | Agency, slice 2: the exchange starts at the wind-up, and the three bands | plan/park? | 2026-10-02 |
| director/agency-slice-3.md | 124 | Agency, slice 3: the far taunt as a challenge, the held charge, the AI's use of the free t | plan/park?/built? | 2026-10-02 |
| director/agency-slice-4.md | 83 | Agency, slice 4: a light-only player can always finish | built? | 2026-10-03 |
| director/agency-slice-5.md | 97 | Agency, slice 5: blasts (the first energy slice, 3a) and the provisional signature limit | - | 2026-10-03 |
| director/agency-slice-6.md | 83 | Agency, slice 6: the buried fighter, and the hook for the slide's bump | plan/park? | 2026-10-02 |
| director/agency-slice-7.md | 116 | Agency, slice 7: Game Design's rulings on the slice 4 and energy baselines | plan/park? | 2026-10-02 |
| director/agency-slice-8.md | 102 | Agency, slice 8: the beam plays | plan/park? | 2026-10-03 |
| director/agency-slice-9.md | 91 | Agency, slice 9: the wild deflect, the spray cone and mines (the director's side) | plan/park?/built? | 2026-10-03 |
| director/alchemy-plan.md | 62 | The combat alchemy layer: the director's slice plan | plan/park?/built? | 2026-10-02 |
| director/bark-reads.md | 37 | The bark reads | built? | - |
| director/brawl-b0.md | 98 | Brawl slice B0: the groundwork | plan/park? | 2026-10-04 |
| director/brawl-b1.md | 205 | Brawl slice B1: the first brawl | plan/park?/built? | 2026-10-05 |
| director/brawl-b1b.md | 148 | Brawl slice B1b: the even mash, the AI until B2, shots against the brawl's scale | built? | 2026-10-05 |
| director/brawl-b1c.md | 135 | Brawl slice B1c: the perfect block and the reversal inside the brawl | plan/park?/built? | 2026-10-05 |
| director/brawl-c1.md | 166 | Brawl slice C1: control and the even mash | plan/park? | 2026-10-06 |
| director/brawl-c2.md | 495 | The brawl, slices C2a and C2t with the heavy's hold: as built | plan/park?/built? | 2026-10-06 |
| director/brawl-plan.md | 583 | The brawl: a build plan for the director | plan/park? | 2026-10-04 |
| director/brink-chapter.md | 45 | The brink chapter | - | - |
| director/calm-turn.md | 81 | The calm turn: the director's calm moments and steering, for World's window 3 (paper, 2026 | built? | 2026-10-22 |
| director/camera-intent.md | 121 | The camera-intent feed: what the choreographer knows ahead, for the camera (paper, 2026-10 | plan/park? | 2026-10-19 |
| director/cloud-reports/2026-10-28-biomes-w2.md | 108 | Biomes W2: the twists and the aftermaths (Encounter, cloud, 2026-10-28) | - | 2026-10-28 |
| director/cloud-reports/2026-10-28-biomes-w3.md | 129 | Biomes W3: the eight launch candidates (Encounter, cloud, 2026-10-28) | plan/park? | 2026-10-28 |
| director/cloud-reports/2026-10-28-prop-reach.md | 222 | Prop reach, the zip.price lead, a cheaper logOf (Encounter, local, 2026-10-28) | plan/park?/built? | 2026-10-28 |
| director/cloud-reports/2026-10-28-tick-skip.md | 152 | Cloud report: the director's tick, accessors then idle work skipped (Encounter Systems, 20 | - | 2026-10-28 |
| director/contact-plan.md | 93 | Contact: full contact on every hit, and no passing through | - | 2026-10-01 |
| director/control-scheme-plan.md | 396 | Plan: the director under the new control scheme (ADR 0008) | plan/park? | - |
| director/cool-awareness.md | 111 | The choreographer's eye for cool: what it watches, how it picks, where it may steer (paper | - | 2026-10-16 |
| director/depth-d1.md | 164 | Depth, slice D1: the director's part, sized | plan/park? | 2026-10-12 |
| director/dynamic-feel-slice.md | 89 | Dynamic-feel slice | built? | 2026-09-30 |
| director/dynamic-intros-plan.md | 204 | Dynamic intros: a plan for an intro composer | plan/park? | 2026-10-04 |
| director/fight-feel.md | 59 | The fight's feel in the director: recoil flips, ricochets, clashes (build notes, 2026-10-1 | plan/park? | 2026-10-19 |
| director/fight-lanes-director.md | 137 | Fight lanes: the director's part (ADR 0009) | plan/park? | - |
| director/grapple-director.md | 124 | The grapple's director side: the catch, the clinch and the carry (sketch) | - | 2026-10-16 |
| director/lake-floor-lines.md | 26 | The director on the floor of a lake or the sea (Encounter, 2026-10-30) | - | 2026-10-30 |
| director/landing-mix.md | 82 | The landing mix: the drive and the gated crater slam | - | 2026-10-01 |
| director/location-variety-plan.md | 104 | Plan: location variety (G0 triage §14, group C) | plan/park? | - |
| director/m0-director-plan.md | 45 | What the director owes the first real moveset (M0), and what fits before it | plan/park? | 2026-10-02 |
| director/masher-probes.md | 78 | The masher: why QA's probe and mine disagree | plan/park? | 2026-10-02 |
| director/one-v-many.md | 158 | One versus many: what the fight director can take (paper) | - | 2026-10-14 |
| director/pace-measurements.md | 50 | Pace measurements before the dynamic-feel pass | - | - |
| director/q4-director-control-plan.md | 147 | Plan: the director takes the timing (Q4) | plan/park?/built? | 2026-09-30 |
| director/right-stick-step1-notes.md | 27 | The right stick's step 1 against today's director (notes, 2026-10-23) | - | 2026-10-23 |
| director/s3b-data-and-penalties.md | 98 | S3b: Combat's data, spaced timing, stage penalties and the struggle | plan/park?/built? | - |
| director/second-play-read.md | 150 | Orb's second play: the circle, knock-backs and combo control | plan/park?/built? | 2026-11-01 |
| director/tempo-and-location.md | 94 | Tempo and fight location: director and AI changes | built? | - |
| director/town-levers.md | 71 | The planner's levers for buildings: staying in town, and aiming for one | plan/park?/built? | 2026-10-13 |
| director/two-fights-sizing.md | 87 | Two fights on one globe: sizing | - | 2026-11-01 |
| director/update-apply-order.md | 32 | The next big update: the director's apply order | plan/park?/built? | 2026-10-03 |
| director/wounds-s2.md | 69 | Wounds S2: matches end through finishers | plan/park?/built? | - |
| director/zip-z1.md | 186 | Zip slice Z1: the zip strike and the zip heavy | plan/park? | 2026-10-05 |
| narrative/anguish-branches.md | 118 | Anguish reworked: the Protagonist's two branches, in his voice | - | 2026-10-16 |
| narrative/backstory-skeleton.md | 139 | Backstory skeleton: the questions the power system needs answered | - | 2026-10-04 |
| narrative/beat-templates.md | 369 | Story-beat templates for the co-op campaign: 30 templates, 45 samples | plan/park? | 2026-10-23 |
| narrative/brink-lines.md | 43 | Brink lines: a short bark that repeats while a fighter stays nearly beaten | - | 2026-11-01 |
| narrative/campaign-templates.md | 232 | Campaign templates: the rescue, "Previously on", training, rematch, threads and cliffhange | - | 2026-10-25 |
| narrative/cloud-reports/2026-10-28-live-barks.md | 63 | Live barks: report (Narrative & Fighter Identity, 2026-10-28) | built? | 2026-10-28 |
| narrative/dialogue-director.md | 382 | The dialogue director | - | 2026-09-30 |
| narrative/dynamic-intros.md | 649 | Dynamic intros: the content side | - | 2026-10-06 |
| narrative/energy-names.md | 77 | Energy techniques: names, flavour and call-outs | - | 2026-10-23 |
| narrative/evacuation-barks.md | 84 | Evacuation barks | - | 2026-09-29 |
| narrative/fighter-identity-workflow.md | 146 | Fighter identity workflow: what a fighter needs from Narrative | built? | 2026-10-12 |
| narrative/fighter-sketches.md | 167 | Fighter sketches: the Hero and VORR | plan/park? | 2026-09-28 |
| narrative/filler-templates.md | 245 | Filler episodes: four families of beat templates, the "Episode 12.5" card, and the side-st | - | 2026-10-25 |
| narrative/finishers.md | 79 | Finishers: placeholder names and barks | built? | 2026-09-29 |
| narrative/glossary.md | 188 | Player-facing glossary | - | 2026-09-28 |
| narrative/hero-name-longlist.md | 69 | Hero name longlist (replacements for KAI) | - | 2026-09-28 |
| narrative/identity.md | 103 | Fighter identity text (for `data/fighters/<id>/fighter.json`) | - | 2026-10-06 |
| narrative/intro-lines.md | 98 | Dynamic introduction lines: what they say, keyed by who, where, when and what happened | - | 2026-10-16 |
| narrative/launch-hint.md | 36 | The first-time launch hint: options | - | 2026-10-16 |
| narrative/line-system.md | 277 | The line system | built? | 2026-09-29 |
| narrative/lore-core-options.md | 138 | The universe's core idea: three options for where power comes from | - | 2026-10-18 |
| narrative/matchups.md | 372 | Matchups: who is facing whom | - | 2026-09-29 |
| narrative/move-names-draft.md | 235 | Move names: a vocabulary for generated moves (draft) | - | 2026-10-06 |
| narrative/name-longlist.md | 133 | Game name longlist | - | 2026-09-28 |
| narrative/nudge-lines.md | 92 | Nudge lines: the voice line that justifies a gentle turn | - | 2026-10-31 |
| narrative/opponent-grounds.md | 126 | The ground each opponent claims, and the heavy's full-charge hint | - | 2026-10-19 |
| narrative/pitches-q3.md | 563 | Pitches from questionnaire 3 | - | 2026-09-29 |
| narrative/place-names.md | 165 | Place names for the stored planet: a grammar | - | 2026-10-16 |
| narrative/places.md | 107 | Places: the planet and its regions | plan/park? | 2026-09-28 |
| narrative/plain-words.md | 54 | Plain words for the HUD: Narrative's proposals | plan/park? | 2026-10-16 |
| narrative/planet-and-homes.md | 71 | A new planet every run: the name workshop, the naming rule and the four home areas | - | 2026-10-19 |
| narrative/rally-names.md | 33 | Rally links: names, alternates and call-outs | - | 2026-10-25 |
| narrative/rewards-words.md | 183 | Titles, keepsakes and the run, boons and haul wording | - | 2026-10-18 |
| narrative/roster-twelve-identity.md | 358 | A roster of twelve: the identity half | plan/park? | 2026-10-06 |
| narrative/rule-of-cool-narrative.md | 112 | Rule of cool: the narrative side | - | 2026-10-01 |
| narrative/run-lines.md | 115 | Run lines: offer cards, the boss's lines and the endings | - | 2026-10-16 |
| narrative/skeletons-protagonist-v-anti-hero.md | 181 | Skeleton set 1: Protagonist v Anti-hero | - | 2026-09-30 |
| narrative/story-beats.md | 186 | Between-stage story beats: a grammar that reads the run | - | 2026-10-16 |
| narrative/style-thresholds.md | 184 | Style labels: thresholds, hold times and the mixer | plan/park? | 2026-09-30 |
| narrative/taunt-system.md | 241 | The taunt system: lines that stay fresh | - | 2026-10-02 |
| narrative/time-cap-endings.md | 35 | Time-cap endings: a story event forces the finish | - | 2026-09-30 |
| narrative/title-pitch.md | 116 | Title pitch | plan/park? | 2026-09-29 |
| narrative/tutorial-hints.md | 57 | Tutorial hint lines | - | 2026-09-30 |
| narrative/voice-bibles.md | 87 | The four voice bibles, after the Gemini review | - | 2026-10-30 |
| narrative/voice-lab/README.md | 125 | Voice lab: the packet for Orb | - | 2026-10-16 |
| narrative/voice-lab/known-tells.md | 43 | Known tells: patterns that read as machine-written | - | 2026-10-01 |
| narrative/voice-lab/mid-combat-lines.md | 388 | Voice: mid-combat lines (the live barks) | built? | 2026-10-30 |
| narrative/voices/anti-hero.md | 85 | Voice bible: the Anti-hero | - | 2026-09-29 |
| narrative/voices/cyborg.md | 83 | Voice bible: the Cyborg | - | 2026-09-29 |
| narrative/voices/empress.md | 151 | Voice bible: the Empress | - | 2026-09-29 |
| narrative/voices/protagonist.md | 75 | Voice bible: the Protagonist | - | 2026-09-29 |
| narrative/waiting-game-lines.md | 121 | The waiting game and the slingshot: flavour lines | - | 2026-10-16 |
| narrative/waiting-lines.md | 49 | Waiting lines: the opponent waits while you transform | - | 2026-09-29 |
| narrative/world-abilities.md | 48 | World-changing abilities: who each fighter is | - | 2026-09-30 |
| narrative/worlds-and-forms-pass-2.md | 109 | World changes and transformations: second pass | - | 2026-09-30 |
| narrative/writing-quality.md | 126 | Writing quality: why it reads rushed, and what a line must pass | - | 2026-10-15 |
| net/cloud-reports/2026-10-28-ai-depth.md | 87 | Cloud report: rollback under fighter AIs to the KO, with depth and gen 2 rings (Netcode an | built? | 2026-10-28 |
| net/cloud-reports/2026-10-28-ai-takeover.md | 176 | Report: the AI takes over a dropped player, and the calm turn under rollback (Netcode and  | - | 2026-10-28 |
| net/cloud-reports/2026-10-28-desync-spectate.md | 102 | Cloud report: desync reporting, spectators, adaptive input delay (Netcode and Online, 2026 | - | 2026-10-28 |
| net/cloud-reports/2026-10-28-rollback-core.md | 78 | Cloud report: the rollback core (Netcode and Online, 2026-10-28) | - | 2026-10-28 |
| net/cloud-reports/2026-10-28-transport.md | 112 | Cloud report: the transport layer, ENet, and the delay handshake (Netcode and Online, 2026 | plan/park? | 2026-10-28 |
| net/cloud-reports/2026-10-30-ai-timers-level.md | 70 | Report: the AI's timers in the desync digest, and the computer's level in the match key (N | built? | 2026-10-30 |
| net/lan-v1.md | 150 | LAN test, version 1: a match between two PCs | plan/park?/built? | 2026-11-01 |
| net/rollback.md | 410 | Rollback netcode: the core | plan/park? | 2026-10-28 |
| net/two-pc-check.md | 78 | Do two PCs' processors agree? | - | 2026-11-01 |
| net/two-v-two-lan.md | 160 | 2v2 over LAN: can Orb's two PCs do it? | plan/park?/built? | 2026-11-01 |
| perf/README.md | 71 | docs/perf: Performance and Platform | plan/park?/built? | 2026-10-16 |
| perf/arena-turn-2026-10-23.md | 93 | The arena turn's cost, and the first crater in the web build (2026-10-23) | built? | 2026-10-23 |
| perf/audio-warm-async-2-2026-10-26.md | 37 | Audio's re-cut warm-up (warm-async-2) on the phone-freeze probe, against HEAD with the fir | plan/park? | 2026-10-26 |
| perf/audio-warm-async-2026-10-26.md | 53 | Audio's warm-async park against plain HEAD 89e34ec8, on the phone-freeze probe (2026-10-26 | plan/park? | 2026-10-26 |
| perf/audio-warm-async-3-2026-10-27.md | 28 | Audio's warm-async 3 on the phone-freeze probe, HEAD 19e56ab3 (2026-10-27) | plan/park?/built? | 2026-10-27 |
| perf/audit-2026-10-16.md | 292 | Performance audit of main, 2026-10-16 | built? | 2026-10-16 |
| perf/batch-1b66c4bb-2026-10-23.md | 20 | Item 3 on 1b66c4bb (Encounter's four parks) against 89b604de (2026-10-23) | built? | 2026-10-23 |
| perf/batch-e09dbbbf-2026-10-22.md | 46 | Re-run on e09dbbbf: the hitches and the ring read (2026-10-22) | plan/park?/built? | 2026-10-22 |
| perf/boot-start-block-2026-10-27.md | 54 | What is in the start block, and the full boot, on main 3d276d57 (2026-10-27) | plan/park?/built? | 2026-10-27 |
| perf/budgets.md | 75 | Performance budgets (first table, 2026-10-16) | plan/park? | 2026-10-16 |
| perf/clash-press-2026-10-31.md | 46 | The clash press: shader cost per level on the Radeon iGPU, against the old flare (Performa | - | 2026-10-31 |
| perf/coast-layer-cut-2026-10-27.md | 49 | The gen 2 coast, layer by layer, on the Radeon (HEAD f50e9902, 2026-10-27) | - | 2026-10-27 |
| perf/desktop-boot-2026-10-27.md | 73 | Desktop start-up for Steam: the Windows export of d7647634, the web side, platform notes ( | - | 2026-10-27 |
| perf/fighter-pieces-2026-10-31.md | 55 | Where the fighters' frame time goes, by piece (Performance and Platform, 2026-10-31) | built? | 2026-10-31 |
| perf/frame-pacing-2026-10-22.md | 52 | Frame pacing: a 2-minute AI match and a 2-player brawl (2026-10-22) | - | 2026-10-22 |
| perf/gen2-bench-2026-10-26.md | 55 | Gen 2 (planet generation 2) benches in the web build (2026-10-26) | - | 2026-10-26 |
| perf/ground-by-band-and-heat-2026-10-23.md | 48 | The ground by band (22f) and the scorch and heat texture (22h), before and after (2026-10- | plan/park?/built? | 2026-10-23 |
| perf/hitch-table-2026-10-31.md | 181 | Every tick over 16 ms in a real match on the stack, by cause (Performance and Platform, 20 | plan/park?/built? | 2026-10-31 |
| perf/impact-stutter.md | 99 | High-speed impacts: why the frames stutter and the sound crackles (Performance and Platfor | built? | 2026-11-06 |
| perf/input-latency-2026-10-22.md | 90 | Input-to-screen latency of the web build (2026-10-22) | built? | 2026-10-22 |
| perf/inset-hitches-aura-2026-10-22.md | 55 | The inset warm-up, the tick-131 hitch and the aura's cost (2026-10-22) | - | 2026-10-22 |
| perf/late-ticks-2026-11-07.md | 33 | Why two-fights ticks get dearer late in a match (Performance and Platform, 2026-11-07) | - | 2026-11-07 |
| perf/launch-ticks-2026-11-01.md | 56 | Launch ticks on the stack: what is left that is cheap (Performance and Platform, 2026-11-0 | - | 2026-11-01 |
| perf/live-demo-5c46feca.md | 55 | The live demo's framerate in combat: 5c46feca and 728596d0 against d3f1ca0e (2026-10-19) | built? | 2026-10-19 |
| perf/meteor-ground-2026-10-31.md | 48 | Is the far ground ready when the meteor lands, and what does a read there cost? (Performan | plan/park? | 2026-10-31 |
| perf/node-warm-radius-2026-11-07.md | 24 | Node warm radius: a bigger disc or earlier timing? (Performance and Platform, 2026-11-07) | - | 2026-11-07 |
| perf/oldpc-kit-2026-11-01.md | 104 | The old-PC kit: one click, one result file (Performance and Platform, 2026-11-01) | built? | 2026-11-01 |
| perf/oldpc-result-2026-11-01.md | 58 | The old-PC test, Orb's result (Performance and Platform, 2026-11-01) | - | 2026-11-01 |
| perf/oldpc-test-2026-10-31.md | 64 | The old-PC test: page, plain steps, and what a LAN address does (Performance and Platform, | plan/park?/built? | 2026-10-31 |
| perf/orb-first-play-spikes-2026-11-01.md | 118 | Orb's first play: where the frame spikes come from (Performance and Platform, 2026-11-01) | plan/park? | 2026-11-01 |
| perf/orb-second-play-2026-11-01.md | 95 | Orb's second first-play: where the frame spikes come from (Performance and Platform, 2026- | plan/park? | 2026-11-01 |
| perf/page-load-2026-10-31.md | 58 | The first load of Orb's private page, phase by phase (Performance and Platform, 2026-10-31 | - | 2026-10-31 |
| perf/page-load-cache-2026-10-31.md | 51 | The page's load with World's caches and the custom template, and the proof that a warm vis | built? | 2026-10-31 |
| perf/phone-freeze-2026-10-26.md | 75 | The live demo froze on a friend's Android phone: what the boot does, and how to catch it n | plan/park? | 2026-10-26 |
| perf/phone-web-fullscreen.md | 125 | Phones: full screen, Home Screen install and landscape for the web build | built? | 2026-10-06 |
| perf/preplay-read-2026-11-01.md | 26 | Pre-play read: what Orb's first match costs on this PC (Performance and Platform, 2026-11- | - | 2026-11-01 |
| perf/preview-deform-launch-2026-10-30.md | 94 | Terrain deformation and fast launches in the private preview: cost by stage (2026-10-30) | plan/park? | 2026-10-30 |
| perf/quality-range.md | 184 | Quality range: what scales, what each level may spend, how a level is picked (Performance  | - | 2026-10-31 |
| perf/render-chain-22k-22o-2026-10-23.md | 78 | Rendering's chain 22k to 22o, and UI's warm-marks (2026-10-23) | - | 2026-10-23 |
| perf/stores-and-consoles.md | 239 | Where this game can be listed, consoles included | plan/park? | 2026-10-05 |
| perf/swing-tick-2026-10-31.md | 95 | The swing tick, benched (Performance and Platform, 2026-10-31) | - | 2026-10-31 |
| perf/swing-tick-recut-2026-10-31.md | 57 | The swing tick on Simulation's re-cut field-frame, in whole AI matches (Performance and Pl | plan/park? | 2026-10-31 |
| perf/tools/preplay/README.md | 8 | Pre-play read tools (Performance and Platform, 2026-11-01) | - | 2026-11-01 |
| perf/two-fights-kit-2026-11-07.md | 26 | The two-fights old-PC kit (Performance and Platform, 2026-11-07; co-op 2v2 A7) | - | 2026-11-07 |
| perf/web-template-2026-10-28.md | 40 | The custom web template (lazy shader specialization), standard against custom (2026-10-28) | - | 2026-10-28 |
| perf/web-template-readings-2026-10-28.md | 61 | The custom web engine's four readings, on the live pin (2026-10-28) | - | 2026-10-28 |
| production/risk-register.md | 15 | Risk register (starting set) | - | - |
| qa/README.md | 74 | QA on the GDScript sim | plan/park?/built? | - |
| qa/baseline-4bc5ff1.md | 310 | Baseline on the GDScript sim | - | - |
| qa/baseline-53d13b5.md | 426 | Baseline on the GDScript sim | - | - |
| qa/baseline-54e9f9d.md | 406 | Baseline on the GDScript sim | - | - |
| qa/baseline-738add7.md | 198 | Baseline on the GDScript sim | - | - |
| qa/baseline-9da6e07.md | 325 | Baseline on the GDScript sim | - | - |
| qa/baseline-9fcdf87.md | 298 | Baseline on the GDScript sim | - | - |
| qa/baseline-a56187a.md | 284 | Baseline on the GDScript sim | - | - |
| qa/baseline-agency1.md | 219 | Baseline on the GDScript sim | - | - |
| qa/baseline-agency4.md | 220 | Baseline on the GDScript sim | - | - |
| qa/baseline-contact.md | 215 | Baseline on the GDScript sim | - | - |
| qa/baseline-df05b9f.md | 362 | Baseline on the GDScript sim | - | - |
| qa/baseline-energy.md | 257 | Baseline on the GDScript sim | - | - |
| qa/baseline-f32a7a8.md | 348 | Baseline on the GDScript sim | - | - |
| qa/baseline-fb8aafac.md | 262 | Baseline on the GDScript sim | - | - |
| qa/baseline-g0.md | 178 | Baseline on the GDScript sim | - | - |
| qa/baseline-intro.md | 215 | Baseline on the GDScript sim | - | - |
| qa/baseline-q10.md | 192 | Baseline on the GDScript sim | built? | - |
| qa/baseline-step3.md | 205 | Baseline on the GDScript sim | - | - |
| qa/brawl-qa-plan.md | 95 | QA for the brawl: the scripts, the three new rows and what QA needs from the build | plan/park? | 2026-10-05 |
| qa/brawl-rebase.md | 42 | Rows counted per exchange, re-based for the brawl, and the brawl harness (QA, 2026-10-05) | plan/park? | 2026-10-05 |
| qa/c2-chain-2e0f3b2.md | 447 | Baseline on the GDScript sim | - | - |
| qa/c2-followup-b1b2ed6a.md | 430 | The C2 chain after the follow-up and the stick slice: b1b2ed6a (QA, 2026-10-12) | - | 2026-10-12 |
| qa/c2-second-round-f9469f8a.md | 475 | The second-round tune measured: f9469f8a (QA, 2026-10-12) | - | 2026-10-12 |
| qa/candidate-m1b.md | 181 | Candidate M1b data set (full report) | - | - |
| qa/candidate-q10.md | 195 | Candidate Q10 data set (full report) | built? | - |
| qa/chain-3198301f.md | 140 | The nine-cells chain measured: 3198301f (QA, 2026-10-14) | plan/park?/built? | 2026-10-14 |
| qa/cloud-reports/2026-10-28-gen2-baseline.md | 72 | Gen 2 baseline: the arm-3 bands on procedural planets (QA, cloud, 2026-10-28) | - | 2026-10-28 |
| qa/cloud-reports/2026-10-30-gen2-reread.md | 66 | Gen 2 re-read on HEAD: W7's density, the fallback fix, the PROP SMASH share (QA, 2026-10-3 | built? | 2026-10-30 |
| qa/cloud-reports/2026-10-30-lake-floor.md | 64 | Gen 2 with the biome candidates and the lake floor on (QA, 2026-10-30) | built? | 2026-10-30 |
| qa/cloud-reports/2026-10-31-swing-rows.md | 64 | The turntable rows, and a read of what stacks now (QA, 2026-10-31) | - | 2026-10-31 |
| qa/cloud-reports/2026-11-01-stack-read.md | 56 | The stack, read for the pad and the globe (QA, 2026-11-01) | - | 2026-11-01 |
| qa/cloud-reports/2026-11-02-kept-build.md | 27 | The kept build, read as Orb played it (QA, 2026-11-02) | plan/park? | 2026-11-02 |
| qa/cloud-reports/2026-11-06-city-step-one.md | 77 | City step one: the two gate reads, the stick refusals by reason, and the flight-strike har | plan/park?/built? | 2026-11-06 |
| qa/cloud-reports/2026-11-07-city-step-one-reread.md | 75 | City step one, the re-reads after Game Design's rulings (QA, 2026-11-07) | plan/park? | 2026-11-07 |
| qa/launch-anywhere-77ca29a4.md | 46 | The newcomer and the route with launch anywhere on: a scratch read on 77ca29a4 (QA, 2026-1 | built? | 2026-10-19 |
| qa/launch-rerun-f15d7de3.md | 44 | The route and the newcomer measured again, with the launch counts the right way round: f15 | - | 2026-10-18 |
| qa/main-0ca6f670.md | 61 | Main at 0ca6f670 measured, in part: the eleventh-round rows, the masher stage and four arm | built? | 2026-10-16 |
| qa/rally-campaign-rows.md | 78 | QA's rows for the rally and the campaign (2026-10-26) | plan/park?/built? | 2026-10-26 |
| qa/rally-read-fa6f727a.md | 196 | The full rally read and the p10 bisect: fa6f727a (QA, 2026-10-26) | - | 2026-10-26 |
| qa/reread-2026-10-23.md | 84 | The re-reads of 2026-10-22/23: newcomer, route, masher, AI v AI, flips, the clinch, the fr | built? | 2026-10-23 |
| qa/reread-2026-10-24.md | 81 | The re-read after Encounter's balance park: main 1b66c4bb (QA) | plan/park?/built? | 2026-10-24 |
| qa/retune-intro.md | 68 | Intro-phase re-tune: mood and wound spread (QA, 2026-10-02) | built? | 2026-10-02 |
| qa/retune-q10.md | 84 | Q10 re-tune: recommended data (QA, 2026-10-02) | built? | 2026-10-02 |
| qa/switches-alone-7229e3db.md | 69 | The switches read one at a time, launch anywhere off: main 7229e3db (QA) | built? | 2026-10-24 |
| qa/three-strength-qa-plan.md | 257 | QA plan: the three-strength brawl and the walk-out (paper only, 2026-10-06) | plan/park? | 2026-10-06 |
| qa/timing-edge-baseline.md | 77 | Timing-edge baseline on today's sim (QA, 2026-10-02) | plan/park? | 2026-10-02 |
| qa/timing-edge-plan.md | 109 | The timing-edge test plan (QA, 2026-10-02) | plan/park? | 2026-10-02 |
| qa/tuning-m1b.md | 81 | M1b tuning: recommended data (QA, 2026-10-01) | - | 2026-10-01 |
| rendering/2v2-drawn-plan.md | 35 | Seeing all four in a 2v2: the plan (Legal RL-249's drawn case) | plan/park?/built? | 2026-11-07 |
| rendering/README.md | 817 | Rendering: the greybox | - | 2026-09-29 |
| rendering/arena.md | 81 | The arena's length (Rendering, 2026-10-22) | built? | 2026-10-22 |
| rendering/biomes.md | 118 | Biome rendering (Rendering, 2026-10-23) | - | 2026-10-23 |
| rendering/body-tint.md | 20 | The body's tint, and a lane colour changed in place (2026-10-11) | built? | 2026-10-11 |
| rendering/boot.md | 148 | The boot on old GPUs and phones (Rendering, 2026-10-27) | plan/park? | 2026-10-27 |
| rendering/building-stages.md | 132 | Buildings by damage stage | plan/park? | 2026-10-04 |
| rendering/camera-roll.md | 61 | The camera roll on climaxes (Rendering, 2026-10-22) | - | 2026-10-22 |
| rendering/city-variety.md | 122 | City variety up close (Rendering, 2026-10-16) | plan/park?/built? | 2026-10-16 |
| rendering/cloud-reports/2026-10-28-broken-props.md | 92 | Broken props leave the view (Rendering, 2026-10-29) | plan/park?/built? | 2026-10-28 |
| rendering/cloud-reports/2026-10-28-pane-sweep.md | 108 | The view update's bigger cut: the building sweep by view (Rendering, 2026-10-29) | built? | 2026-10-28 |
| rendering/cloud-reports/2026-10-29-props-follow-up.md | 94 | The props follow-up: Art's sizes and the foot (Rendering, 2026-10-29) | plan/park?/built? | 2026-10-29 |
| rendering/destruction-look.md | 171 | The destruction look: what the picture reads from a building's state (2026-10-12) | plan/park? | 2026-10-12 |
| rendering/dynamic-sky.md | 85 | The dynamic sky | - | 2026-10-06 |
| rendering/fight-lanes-render.md | 134 | Fight lanes: Rendering's section (ADR 0009) | plan/park? | 2026-10-01 |
| rendering/fighters-in-depth.md | 178 | Fighters in depth: what the renderer has, what breaks, what to build (2026-10-12) | built? | 2026-10-12 |
| rendering/flash-sources.md | 486 | Rendering's flashes and the shared flash register | - | 2026-10-06 |
| rendering/foreground-patch.md | 60 | The foreground row's patch (2026-10-11) | built? | 2026-10-11 |
| rendering/geometry-and-warmup.md | 196 | Geometry the picture does not need, and the warm-up draw (Rendering, 2026-10-17) | - | 2026-10-17 |
| rendering/homework4-pitch.md | 29 | Homework 4: two pitches before building (Rendering, 2026-10-16) | - | 2026-10-16 |
| rendering/lanes-camera-flash.md | 73 | The re-laid city: what Camera must do, and what the flash check should watch (2026-10-11) | plan/park?/built? | 2026-10-11 |
| rendering/lanes-look.md | 150 | The re-laid city's look (2026-10-11; the shorter city, fuller tops and street grid 2026-10 | - | 2026-10-11 |
| rendering/open-floors.md | 131 | The lobby: how a tower lets a fight behind it be seen (2026-10-12) | - | 2026-10-12 |
| rendering/outline-normals-plan.md | 50 | Fighter outlines: smoothed hull normals | plan/park? | 2026-09-30 |
| rendering/props.md | 69 | The match's props (Rendering, 2026-10-29) | built? | 2026-10-29 |
| rendering/rule-of-cool-render.md | 50 | Rule of cool: Rendering's plan-only items | plan/park? | 2026-10-01 |
| rendering/sky-and-distance.md | 40 | Sky, fog and mountains: Rendering's pass | built? | 2026-10-15 |
| rendering/sky-gap-anchored.md | 31 | A gap in the clouds that stays where it opened | - | 2026-10-02 |
| rendering/slow-drift.md | 66 | The slow drift (Rendering, 2026-10-22) | - | 2026-10-22 |
| rendering/split-culling.md | 23 | The split's culling (Rendering, 2026-10-23) | plan/park? | 2026-10-23 |
| rendering/trees.md | 29 | The fellable trees (Rendering, 2026-10-27) | plan/park?/built? | 2026-10-27 |
| rendering/tumble-intro-render.md | 202 | The tumble and the intro's sky shot: Rendering's plan | plan/park?/built? | 2026-10-02 |
| rendering/variety-cues-plan.md | 78 | Variety pass: how the priority-1 cues read on screen | plan/park? | 2026-09-30 |
| rendering/view-update.md | 116 | The view update on the gen 2 coast (Rendering, 2026-10-27) | - | 2026-10-27 |
| rendering/water-fill.md | 51 | The water fill (Rendering, 2026-10-23; on water v2 2026-10-27) | - | 2026-10-23 |
| research/cinematic-storytelling.md | 383 | Cinematic storytelling: a camera director that is always spot on, even at high speed | plan/park? | 2026-10-19 |
| research/co-op-brawler-part-2.md | 187 | Co-op brawler mode, part 2: can the director carry a multi-fighter fight? | - | 2026-10-11 |
| research/co-op-brawler.md | 183 | Co-op brawler mode: a research study | - | 2026-10-11 |
| research/cuts-and-eases.md | 101 | Cuts and eases: when the camera may move instantly | - | 2026-10-23 |
| research/planet-gen-tables.md | 186 | Planet generation: the tables | - | 2026-10-23 |
| research/planet-gen.md | 242 | Planet generation: three techniques, pictured | built? | 2026-10-23 |
| research/readable-speed.md | 98 | Readable speed: high-speed combat with nothing over the fighters | built? | 2026-10-18 |
| research/world-catastrophe.md | 247 | World catastrophe: can our engine do Orb's boss fight, and how? | - | 2026-10-16 |
| setup/git-and-github.md | 32 | Git and GitHub setup (Windows, Git Bash) | - | - |
| tools/README.md | 304 | Tools: CI, setup and the web build | - | - |
| tools/ci-guards.md | 19 | The CI guards that do not depend on ci.yml (Tools, 2026-11-07) | - | 2026-11-07 |
| tools/clip-capture-audit.md | 44 | Capturing clips and GIFs: audit and plan (EP, 2026-11-04) | plan/park?/built? | 2026-11-04 |
| tools/clips.md | 64 | Making clips (Tools, 2026-11-06) | - | 2026-11-06 |
| tools/cloud-reports/2026-10-28-ci-linux.md | 53 | Cloud report: CI gates and a Linux / Steam Deck export (Tools, 2026-10-28) | built? | 2026-10-28 |
| tools/cloud-reports/2026-10-28-desktop-builds.md | 38 | Desktop test builds for Windows, Linux and macOS (Tools, 2026-10-28; re-cut for RL-203 to  | plan/park? | 2026-10-28 |
| tools/cloud-reports/2026-10-28-web-template.md | 110 | Cloud report: the custom web template (Tools, 2026-10-28) | - | 2026-10-28 |
| tools/desktop-builds.md | 80 | Desktop test builds: Windows, Linux and macOS (Tools, 2026-10-28) | - | 2026-10-28 |
| tools/determinism-lint.md | 49 | The determinism lint (wired into CI, data job) | built? | 2026-10-23 |
| tools/dummy-ring-scenes.md | 111 | The dummy, ring and launch scenes of the flash set (2026-10-16) | plan/park? | 2026-10-16 |
| tools/feel.md | 71 | Feel replays, the refusal ledger and the scheme gauntlet (Tools, 2026-11-06) | built? | 2026-11-06 |
| tools/flash-check.md | 255 | The photosensitivity check (2026-10-06) | - | 2026-10-06 |
| tools/flash-proof.md | 45 | Are the flash numbers real? (Tools, 2026-11-01; unfinished, gaps marked) | - | 2026-11-01 |
| tools/gauntlet-build1.md | 16 | The scheme gauntlet on Sunday's build 1 (Tools, 2026-11-08) | built? | 2026-11-08 |
| tools/gauntlet-e80b8e3d.md | 30 | The scheme gauntlet on the morning page e80b8e3d (Tools, 2026-11-07) | built? | 2026-11-07 |
| tools/gauntlet-orbs-scheme-e80b8e3d.md | 41 | The gauntlet's "Orb's scheme" pad next to stick-only, on e80b8e3d (Tools, 2026-11-07) | built? | 2026-11-07 |
| tools/lan-report.md | 34 | LAN report tools (Tools, 2026-11-08; Orb's overnight order: the next LAN play-test has eve | - | 2026-11-08 |
| tools/load-and-captures.md | 49 | Does machine load change a flash reading? (Tools, 2026-10-30) | plan/park?/built? | 2026-10-30 |
| tools/machine-captures.md | 67 | Capturing pictures without taking the machine (2026-10-12) | - | 2026-10-12 |
| tools/movegen-ci.md | 40 | Gating CI on the moveset generator's `--check` (a recommendation, nothing ported) | built? | 2026-10-05 |
| tools/music-encode-proposal.md | 50 | Offline WAV to OGG encoding for music hand-backs (a proposal, nothing installed) | plan/park? | 2026-10-04 |
| tools/orb-play-1229-build1.md | 26 | Orb's 1229 play against Sunday's build 1 (Tools, 2026-11-08) | - | 2026-11-08 |
| tools/orb-play-1229-counted.md | 23 | Orb's 1229 play again, counted as presses (Tools, 2026-11-07) | - | 2026-11-07 |
| tools/orb-play-1229-report.md | 79 | Orb's morning play, the ledger and the slow frames (Tools, 2026-11-07) | - | 2026-11-07 |
| tools/pad-steps.md | 57 | Orb's page with a pad: what you press and what the pad does (Tools, 2026-11-01) | built? | 2026-11-01 |
| tools/padlab.md | 63 | Pad lab | - | - |
| tools/pin-child.md | 41 | The words-only child of the pin, and the four readings (Legal RL-209) | plan/park?/built? | 2026-10-30 |
| tools/preview.md | 181 | The private preview: the new planet, playable in Orb's own browser (Tools, 2026-10-30) | built? | 2026-10-30 |
| tools/ratchet-two-fighter.md | 11 | The two-fighter ratchet (Tools, 2026-11-01) | plan/park?/built? | 2026-11-01 |
| tools/rehearsal-f15d7de3.md | 130 | The dress rehearsal on f15d7de3 (interim export, lock_reduce_flashing true), 2026-10-18 | - | 2026-10-18 |
| tools/release-set-plan.md | 126 | The release flash set after Legal's addendum 6 (RL-128): what is built, the scenarios, the | built? | 2026-10-12 |
| tools/reread-ff68e994.md | 37 | The re-read on ff68e994 with the Reduce flashing hook fix (2026-10-17) | built? | 2026-10-17 |
| tools/right-stick-capture.md | 58 | The right-stick capture page and its analysis | built? | 2026-10-23 |
| tools/seeds-1008-1009.md | 18 | Seeds 1008 and 1009 reproduced on d3f1ca0e (2026-10-17) | - | 2026-10-17 |
| tools/shortcuts/README.md | 16 | Shortcuts for the private page (Tools, 2026-11-01) | plan/park? | 2026-11-01 |
| tools/signature-bisect-2026-10-27.md | 40 | The signature clip, bisected (Tools, 2026-10-27) | - | 2026-10-27 |
| tools/site-interim.md | 226 | The interim playable site (Orb's word 2026-10-14; Legal's ruling RL-136, seven days) | - | 2026-10-14 |
| tools/site-template.md | 77 | The custom Web template in the site build (Tools, 2026-10-28) | built? | 2026-10-28 |
| tools/steam-deck.md | 25 | Steam Deck readiness (Tools, 2026-10-28) | - | 2026-10-28 |
| tools/sunday-build.md | 60 | The kept build, step by step (Tools, 2026-11-07; for Sunday's checked build and every one  | plan/park?/built? | 2026-11-07 |
| tools/web-template-size.md | 106 | A smaller web engine: what a custom export template could drop, and what it would buy (202 | built? | 2026-10-26 |
| ui/b-and-the-signature.md | 7 | Words that tie B to the signature (UI & UX, 2026-11-08; the EP's check after Game Design's | - | 2026-11-08 |
| ui/beam-answer-alert.md | 56 | The beam answer alert (UI & UX, 2026-11-01, second version) | - | 2026-11-01 |
| ui/brawl-teaching.md | 96 | The brawl's teaching marks: the nine cells, the perfect follow-up, and the small marks (UI | - | 2026-10-12 |
| ui/charge-stages.md | 50 | Reading the charge stages without anything over the fighter (UI & UX, paper, 2026-11-01) | - | 2026-11-01 |
| ui/civilian-bar.md | 25 | The civilian bar: no running count in the fight (UI, 2026-10-16) | plan/park? | 2026-10-16 |
| ui/cloud-reports/2026-10-28-difficulty-textsize.md | 75 | UI & UX: the computer's level on the start menu, and the Text size option (2026-10-28) | plan/park? | 2026-10-28 |
| ui/cloud-reports/2026-10-28-settings-access.md | 60 | UI/UX, cloud report: volume controls, the uncut Settings help and the pseudo-locale switch | plan/park? | 2026-10-28 |
| ui/cloud-reports/2026-10-29-rl206-toggle-words-level-hash.md | 46 | UI & UX: RL-206, the toggle words, and the level in the replay header (2026-10-29) | built? | 2026-10-29 |
| ui/cloud-reports/2026-10-30-core-four-names.md | 36 | UI & UX: Orb's four names on the screen (2026-10-30, RL-211) | - | 2026-10-30 |
| ui/damage-chip.md | 20 | The damage chip and the card's facts: no counter of people anywhere (UI & UX, 2026-11-07;  | plan/park?/built? | 2026-11-07 |
| ui/fighter-select.md | 40 | A fighter select: what exists, what the smallest one needs, and its size (UI & UX, 2026-10 | plan/park? | 2026-10-12 |
| ui/font-note.md | 25 | Font note: the missing arrow, and the licence position | - | 2026-09-29 |
| ui/frame-cost.md | 51 | The HUD's frame cost | plan/park? | 2026-10-27 |
| ui/grapple-hud.md | 85 | The grapple on the screen: the grip's five steps, the refused cue, and the labels (UI, pap | - | 2026-10-17 |
| ui/grey-circles.md | 16 | The two grey circles, cut behind switches (UI, 2026-10-18) | built? | 2026-10-18 |
| ui/hint-rewrites.md | 32 | The three on-screen hints: two rewrites for Orb to pick (UI, 2026-10-15) | - | 2026-10-15 |
| ui/how-to-play-stances-plan.md | 51 | How to play's stances page, and the Remap and Settings words: a plan (nothing built) | plan/park? | 2026-10-05 |
| ui/hud-cache.md | 77 | The HUD's draw calls: a texture cache for the steady layers (UI, 2026-10-17) | plan/park? | 2026-10-17 |
| ui/hud-hitch.md | 17 | VFX's 7.3 ms HUD frame near tick 1546 (seed 4): not reproduced, and what the HUD costs (UI | - | 2026-10-17 |
| ui/hud-spec.md | 1665 | HUD spec: the fight with no health bars | - | 2026-09-29 |
| ui/image-inventory.md | 188 | Image inventory: mocks and build stills in docs/ui (UI, 2026-10-17) | - | 2026-10-17 |
| ui/key-help-plan.md | 96 | The key help for five stances: a plan (nothing built) | plan/park? | 2026-10-05 |
| ui/lan-friend.md | 50 | What the screen shows for a LAN friend (UI & UX, paper, 2026-11-01) | - | 2026-11-01 |
| ui/lan-report.md | 45 | Report this: one press saves a report in a LAN match, and "Save this match" (UI & UX, 2026 | - | 2026-11-08 |
| ui/launch-marks-no-rest.md | 48 | The launch marks with no RECHARGING state (UI, paper, 2026-10-17) | built? | 2026-10-17 |
| ui/launch-teaching.md | 63 | Teaching the launch: how the HUD and the first-run hint would show Game Design's ruling (U | plan/park? | 2026-10-16 |
| ui/menus-modern.md | 79 | Modern menus: a design pass (UI & UX, 2026-11-08; Orb's overnight order: "enhance the menu | plan/park? | 2026-11-08 |
| ui/menus-rail.md | 50 | The Rail menus (UI & UX, 2026-11-09; Orb picked mockup A on 2026-11-09: "rail looks great, | plan/park? | 2026-11-09 |
| ui/minimal-hud.md | 73 | The minimal HUD: nothing on, over or between the fighters (UI, 2026-10-18) | plan/park?/built? | 2026-10-18 |
| ui/plain-words.md | 37 | Plain words in the HUD and menus (UI, 2026-10-16) | - | 2026-10-16 |
| ui/planet-load.md | 46 | The planet loading screen | plan/park? | 2026-10-26 |
| ui/planet-map.md | 54 | The planet map: how it fits the HUD (UI & UX, 2026-10-31) | - | 2026-10-31 |
| ui/read-ahead.md | 21 | The host's read-ahead of the calm turn's rings | plan/park? | 2026-10-26 |
| ui/reduce-flashing-lock.md | 38 | Reduce flashing locked on, behind a flag (UI, 2026-10-17) | - | 2026-10-17 |
| ui/refusal-reasons.md | 23 | Words for Encounter's refusal reasons (UI & UX, 2026-11-07; the EP's brief, from docs/dire | plan/park? | 2026-11-07 |
| ui/run-mode-screens.md | 123 | The run mode's screens: the offers, the beats between stages, the results (UI, 2026-10-17) | - | 2026-10-17 |
| ui/slam-hint.md | 11 | "Hold to slam": a one-time hint for the stick's slam (UI & UX, 2026-11-07; the EP's brief  | plan/park?/built? | 2026-11-07 |
| ui/split-unequal-fit.md | 57 | The HUD in a 70/30 split, and the legend when RB is held (UI & UX, paper, 2026-11-01) | - | 2026-11-01 |
| ui/stance-ui-needs.md | 81 | What the stance layout needs from UI: costs and data (a note, nothing built) | - | 2026-10-05 |
| ui/start-menu.md | 48 | The start menu (UI & UX, 2026-10-14) | plan/park? | 2026-10-14 |
| ui/strings.md | 1751 | Every player-facing string in ui/data, by where it shows | - | 2026-10-12 |
| ui/text-warm.md | 11 | The HUD's text warm-up (UI, 2026-10-23) | - | 2026-10-23 |
| ui/tutorial-proposal.md | 53 | Proposal: a guided first match | plan/park? | 2026-09-30 |
| vfx/README.md | 269 | VFX: as built | plan/park?/built? | 2026-09-29 |
| vfx/after-fx.md | 32 | What a beam leaves in the ground (VFX, the aftermath looks) | plan/park? | - |
| vfx/aura-plan.md | 42 | VFX standing aura | plan/park? | 2026-10-01 |
| vfx/barrage-flash-plan.md | 19 | The barrage signature: the flash plan (2026-10-12) | plan/park? | 2026-10-12 |
| vfx/beam-front.md | 28 | A beam's front (VFX, 2026-11-01) | plan/park? | 2026-11-01 |
| vfx/beam-look.md | 131 | The energy look: beams with a real width and a flavour, and explosions with flames (2026-1 | - | 2026-10-16 |
| vfx/beam-scar.md | 24 | The scar a beam leaves in the air (2026-10-19) | - | 2026-10-19 |
| vfx/beam-shove.md | 18 | The beam shove: a hit on the cue `beam_shove` (VFX, 2026-11-01) | - | 2026-11-01 |
| vfx/beam-struggle.md | 36 | The beam struggle, carried by the beams (2026-10-19) | built? | 2026-10-19 |
| vfx/biome-fx.md | 101 | Biome effects (VFX, 2026-10-23) | built? | 2026-10-23 |
| vfx/blast-cloud.md | 55 | The blast cloud (catastrophe tier, step 3) | plan/park?/built? | 2026-10-18 |
| vfx/brawl-three-strength-plan.md | 76 | The three-strength brawl: sizing on paper (2026-10-06) | plan/park?/built? | 2026-10-06 |
| vfx/building-stages-plan.md | 64 | Building stages: what VFX will draw (plan, 2026-10-05) | plan/park?/built? | 2026-10-05 |
| vfx/catastrophe-plan.md | 172 | The catastrophe tier's VFX (paper) | plan/park?/built? | 2026-10-16 |
| vfx/clash-look.md | 81 | The beam clash's air (2026-10-30) | - | 2026-10-30 |
| vfx/clash-shockwave.md | 56 | The beam clash's shockwave at the meeting point, growing through the struggle (a sketch, V | plan/park?/built? | 2026-11-02 |
| vfx/cloud-reports/2026-10-28-variant-debris.md | 66 | VFX cloud report: the ten variant debris looks (2026-10-28) | - | 2026-10-28 |
| vfx/depth.md | 124 | VFX in depth: an audit of every layer for a fight off the plane (2026-10-12) | - | 2026-10-12 |
| vfx/earth-plan.md | 56 | VFX earth, material and fire | plan/park? | 2026-10-01 |
| vfx/effect-budgets.md | 114 | VFX effect budgets | - | 2026-09-29 |
| vfx/energy-language.md | 18 | One energy, in every beam, blast and impact (2026-11-01) | plan/park?/built? | 2026-11-01 |
| vfx/flash-registry.md | 219 | The shared flash registry (2026-10-06) | - | 2026-10-06 |
| vfx/flight-lines.md | 53 | Flight lines (VFX, 2026-11-01) | plan/park? | 2026-11-01 |
| vfx/floors-plan.md | 39 | VFX plan for floors (Rampage-style skyscrapers) | plan/park? | 2026-09-30 |
| vfx/forest-fire.md | 31 | Forest fire (VFX, window 4 of the biome effects) | - | - |
| vfx/ghost-budget.md | 39 | The ghost budget (RL-122, RL-125; movegen-banned.json f01, m05, m12) | - | 2026-10-11 |
| vfx/glare.md | 51 | The rival's glasses glare (2026-10-04) | - | 2026-10-04 |
| vfx/meteor-trail.md | 213 | The meteor trail: a fighter's own burn, from close up to a view 53,000 wide (2026-10-31) | plan/park? | 2026-10-31 |
| vfx/multi-fight-plan.md | 109 | Multi-fighting and choreography: what VFX draws, and the cues it needs (2026-10-15) | plan/park?/built? | 2026-10-15 |
| vfx/other-fights.md | 25 | The other fight's effects (2v2, VFX, 2026-11-02): read only, behind a switch, off | plan/park? | 2026-11-02 |
| vfx/panes.md | 31 | Glass from the panes (the re-laid city, 2026-10-11) | - | 2026-10-11 |
| vfx/perf-level.md | 42 | The VFX script cost, profiled, and the Performance level (2026-11-01) | plan/park? | 2026-11-01 |
| vfx/plan.md | 174 | VFX plan: speed you can read, destruction that hits | plan/park? | 2026-09-29 |
| vfx/power-language.md | 158 | Power language: showing a higher tier without more speed | plan/park? | 2026-10-02 |
| vfx/power-up-ideas.md | 28 | Powering up on RT: three answers of our own (VFX, paper, 2026-11-01) | plan/park? | 2026-11-01 |
| vfx/press-styles.md | 86 | The melee press styles on screen (2026-10-04) | - | 2026-10-04 |
| vfx/reach.md | 69 | Energy arts in reach, and the launcher's marks (2026-10-06) | plan/park? | 2026-10-06 |
| vfx/react-plan.md | 64 | VFX reactions to power | plan/park?/built? | 2026-10-01 |
| vfx/riposte-plan.md | 40 | The riposte and the sure blow: what VFX will draw (plan, 2026-10-07; docs only, no build) | plan/park?/built? | 2026-10-07 |
| vfx/shared-register.md | 47 | One flash register for a screen with two fights on it (VFX, 2026-11-07; Legal RL-249) | plan/park? | 2026-11-07 |
| vfx/shots-plan.md | 169 | Energy blasts on screen | - | 2026-10-03 |
| vfx/trail-variety-plan.md | 38 | Trail changes for the variety pass | plan/park? | 2026-09-30 |
| vfx/transform-plan.md | 51 | VFX transformation effects | - | 2026-10-01 |
| vfx/tremor-dust.md | 41 | The tremor's dust (catastrophe tier, step 2) | plan/park? | 2026-10-17 |
| vfx/warm-up.md | 82 | The first-use hitches, the headless probe and the dense-burst thinning | plan/park? | 2026-10-17 |
| vfx/water-plan.md | 61 | VFX water effects | - | 2026-10-01 |
| vfx/windows-bc.md | 44 | World's wall slam, breaches and failing state: what VFX needs and what it costs (2026-10-1 | built? | 2026-10-12 |
| vfx/zip.md | 101 | The LT zip on screen (2026-10-05) | - | 2026-10-05 |
| world/after.md | 71 | What a beam leaves in the ground: the aftermaths (World, window 21, 2026-10-27) | - | 2026-10-27 |
| world/arena-shift-research.md | 43 | Can the arena shift during a fight? (World, research, 2026-10-16) | plan/park? | 2026-10-16 |
| world/arenas-status.md | 52 | The reworked arenas: where the band, the depth rows and the districts stand (status, 2026- | plan/park?/built? | 2026-10-11 |
| world/b2-plan.md | 184 | B2: the brunt and chains, implementation plan | plan/park? | 2026-09-29 |
| world/backdrop.md | 31 | The backdrop: what the world gives it, and what would make the far ranges read as mountain | built? | 2026-10-15 |
| world/building-pass-through.md | 31 | A building pass-through for the meteor (World, 2026-11-01) | plan/park? | 2026-11-01 |
| world/buildings-in-depth.md | 307 | Buildings in depth, and the director's building impact | - | 2026-09-29 |
| world/calm-turn-world.md | 80 | The calm-moment turn: World's side (window 3, 2026-10-22) | plan/park? | 2026-10-22 |
| world/campaign-route.md | 43 | The campaign's route on the ring: World's part of the first slice (2026-10-25) | - | 2026-10-25 |
| world/canon-planet.md | 57 | A canon planet: Everhold (World, proposal, 2026-10-16) | plan/park? | 2026-10-16 |
| world/cars-plan.md | 37 | Cars: scenery first, then throwable (World, plan, 2026-10-16) | plan/park? | 2026-10-16 |
| world/cities.md | 135 | Cities: varied, expansive, busy | plan/park? | 2026-09-30 |
| world/civilians-removed.md | 11 | QA's civilians-removed run: a setup key (World, 2026-11-02) | plan/park? | 2026-11-02 |
| world/cloud-reports/2026-10-28-biomes-w4.md | 127 | World: biomes W4 (cloud, 2026-10-28) | plan/park? | 2026-10-28 |
| world/cloud-reports/2026-10-28-biomes-w5.md | 133 | World: biomes W5, props on gen 2 planets (cloud, 2026-10-28) | - | 2026-10-28 |
| world/cloud-reports/2026-10-28-biomes-w6.md | 125 | World: biomes W6, the launch candidates' flight hooks and a prop query the sim owns (cloud | plan/park? | 2026-10-28 |
| world/cloud-reports/2026-10-28-biomes-w7.md | 120 | World: biomes W7, more buildings on a planet ring (local, 2026-10-29) | built? | 2026-10-28 |
| world/collateral-caps.md | 136 | The collateral cap and the casualty ramp: how they are built | plan/park? | 2026-09-29 |
| world/collateral-run.md | 90 | What the run asks of the collateral and the buildings: World's side (paper, 2026-10-16) | plan/park?/built? | 2026-10-16 |
| world/craters-by-material.md | 48 | A slam's crater by material (World, biomes W4, 2026-10-28) | plan/park? | 2026-10-28 |
| world/craters-scorch-water.md | 174 | Craters, beam scorch and water | - | 2026-09-29 |
| world/crowd-cars-buildings.md | 63 | The crowd, cars, and the building rules from homework 5 (World, 2026-10-16) | plan/park?/built? | 2026-10-16 |
| world/density.md | 41 | Density: more buildings on a planet ring (World, W7, 2026-10-29) | built? | 2026-10-29 |
| world/depth-streets.md | 143 | The street grid and the depth API (D, E, F of Orb's depth addition) | plan/park?/built? | 2026-10-12 |
| world/destruction-hook.md | 201 | Destruction as the hook: smashing through buildings (World, 2026-10-12) | plan/park? | 2026-10-12 |
| world/destruction-state.md | 52 | The destruction state: what the sim holds, what each look reads (World's proposal to agree | plan/park? | 2026-10-12 |
| world/destruction-windows-bc.md | 98 | The wall slam, breaches and the failing state: built in scratch and parked (World, 2026-10 | built? | 2026-10-12 |
| world/districts-plan.md | 175 | Districts, streets, landmarks and the two big cities: the build plan | plan/park? | 2026-09-30 |
| world/fight-lanes-world.md | 227 | Fight lanes: World's section (ADR 0009) | plan/park? | 2026-10-01 |
| world/flight-hooks-w6.md | 44 | Biomes W6: the launch candidates' flight hooks, and the prop query the sim owns | plan/park? | 2026-10-28 |
| world/forest-fire.md | 15 | Fires in the forests (World, window 18, 2026-10-26) | built? | 2026-10-26 |
| world/gen2-read-speed.md | 51 | The gen 2 ring read and the planet's load in steps (World, window 20, 2026-10-26) | built? | 2026-10-26 |
| world/gen2-readiness.md | 43 | What it takes to switch gen 2, water v2, B and rivers on by default (World, 2026-10-26) | plan/park?/built? | 2026-10-26 |
| world/ground-contact.md | 517 | Ground contact: leaving the ground, landing, bouncing, rims (plan) | plan/park? | 2026-10-01 |
| world/home-set-pieces.md | 120 | Home set pieces: four classes, as layouts (World, 2026-10-23) | plan/park? | 2026-10-23 |
| world/homes-and-arenas.md | 60 | Arena sizes and the fighters' homes (World, 2026-10-19) | plan/park? | 2026-10-19 |
| world/img/overhaul-b/README.md | 23 | Planet 7, today against B on gen 3 (World, 2026-11-02) | plan/park?/built? | 2026-11-02 |
| world/knockback-slide.md | 89 | The knockback slide: ground impacts that skid, and water that skips | - | 2026-09-29 |
| world/lake-floor.md | 73 | The floor of a lake or the sea (World, 2026-10-30) | - | 2026-10-30 |
| world/landmark-spare.md | 9 | A barred landmark is out of every blast and fall (World, 2026-11-02) | plan/park? | 2026-11-02 |
| world/lanes-remeasure-plan.md | 261 | The lanes window: what is ready and what the re-lay moves (re-measure plan) | plan/park? | 2026-10-05 |
| world/lanes-schema-proposal.md | 30 | Schemas for the lanes window: the proposal for Tools (2026-10-11) | plan/park? | 2026-10-11 |
| world/living-destruction.md | 179 | Living destruction: a landscape that pushes back | - | 2026-09-29 |
| world/lot-reach.md | 13 | A lot answers only near itself (World, 2026-11-02) | plan/park? | 2026-11-02 |
| world/low-impact-water.md | 76 | Low-impact water on gen 3 (World, 2026-11-01) | - | 2026-11-01 |
| world/node-warm.md | 34 | Warming the ground's nodes at the match start (World, 2026-11-02) | plan/park?/built? | 2026-11-02 |
| world/orb-looks-1107.md | 23 | Orb's two looks from the morning play (World, 2026-11-07) | plan/park? | 2026-11-07 |
| world/outposts.md | 29 | Polar research outposts (World, 2026-10-16) | plan/park? | 2026-10-16 |
| world/places-everywhere.md | 66 | Buildings at every place (World, 2026-11-01) | plan/park? | 2026-11-01 |
| world/places-reached.md | 42 | The places the fight reached: the test and the records (World, 2026-11-02) | plan/park? | 2026-11-02 |
| world/planet-gen2.md | 110 | Planet generation 2 (World, 2026-10-23) | - | 2026-10-23 |
| world/planet-ice.md | 52 | The stored planet, version 2: polar ice (World, 2026-10-16) | plan/park? | 2026-10-16 |
| world/planet-module.md | 117 | WorldPlanet: planet window 1 (World, 2026-10-16) | - | 2026-10-16 |
| world/planet-overhaul.md | 200 | The planet, engineered: a plan (World, 2026-11-01) | plan/park?/built? | 2026-11-01 |
| world/planet-slice.md | 60 | A stored planet and a slice of it for every fight (World, 2026-10-16) | plan/park? | 2026-10-16 |
| world/planet-window2.md | 37 | Planet window 2: a draft (World, 2026-10-17) | plan/park?/built? | 2026-10-17 |
| world/plates-b.md | 34 | Research's B plates in gen 2 (World, window 12, 2026-10-23) | plan/park?/built? | 2026-10-23 |
| world/point-clear.md | 19 | A read for the zip: is this point inside ground or a building, with 1 bh to spare | - | 2026-10-04 |
| world/power-world.md | 30 | The power model, World's half (World, 2026-11-02) | plan/park? | 2026-11-02 |
| world/prop-hold-points.md | 10 | Hold points on the throwable objects (World, 2026-10-18) | plan/park? | 2026-10-18 |
| world/props-w5.md | 33 | Props on gen 2 planets (W5) | - | 2026-10-28 |
| world/rendering-brief-lanes.md | 33 | Brief for Rendering: piece 2, the re-laid city's look (district looks, shapes, row fog, la | plan/park? | 2026-10-11 |
| world/ring-any-angle/camera.md | 420 | The ring at any angle: how a swing is shot | plan/park? | 2026-10-31 |
| world/ring-any-angle/encounter.md | 207 | A swing and the choreographer: what drives it and what it breaks (Encounter, 2026-10-31) | plan/park?/built? | 2026-10-31 |
| world/ring-any-angle/game-design.md | 657 | The ring at any angle: what a swing does in play | plan/park? | 2026-10-31 |
| world/ring-any-angle/meteor-arc.md | 114 | The meteor's arc: one curve, written down | - | 2026-11-01 |
| world/ring-any-angle/netcode.md | 161 | A visible swing online: what the turntable does to rollback (Netcode and Online, 2026-10-3 | built? | 2026-10-31 |
| world/ring-any-angle/performance.md | 206 | A bearing change at any time: the performance budget (Performance and Platform, 2026-10-30 | - | 2026-10-30 |
| world/ring-any-angle/quality-range.md | 202 | The turntable from a performance mode to maximum graphics | - | 2026-10-31 |
| world/ring-any-angle/rendering.md | 408 | Drawing a ground that swings (Rendering, 2026-10-31) | - | 2026-10-31 |
| world/ring-any-angle/research.md | 537 | The fight at any angle: the turntable route, with the ribbon as fallback | - | 2026-10-31 |
| world/ring-any-angle/simulation.md | 667 | The turntable: what the sim has to know during a swing (Simulation, research only, 2026-10 | - | 2026-10-31 |
| world/ring-any-angle/world.md | 558 | A bearing change at any time: what the world layer blocks (World, research only, 2026-10-3 | plan/park? | 2026-10-30 |
| world/rivers.md | 49 | Rivers for gen 2 (World, 2026-10-23 design; built as window 14, 2026-10-26) | - | 2026-10-23 |
| world/scale.md | 122 | World scale: making the world life-size against the fighters | plan/park? | 2026-09-29 |
| world/shifting-arena-design.md | 82 | The shifting arena: design and windows (World, 2026-10-19) | plan/park?/built? | 2026-10-19 |
| world/small-circles.md | 33 | Small-circle arenas: a loop round a centre point (World, 2026-10-16) | - | 2026-10-16 |
| world/staged-destruction.md | 178 | The front-row hybrid, staged destruction and ground materials: plan and measurements | plan/park? | 2026-10-04 |
| world/structure-reach.md | 68 | High-tier structure reach (balance-targets section 21): plan | plan/park? | 2026-10-02 |
| world/struggle-meeting-point.md | 74 | The beam struggle's meeting point: what it does today, and a crater beneath it (World, 202 | plan/park? | 2026-11-02 |
| world/surfacing.md | 9 | The surfacing rule (World, 2026-10-26) | plan/park?/built? | 2026-10-26 |
| world/terrain-audit.md | 50 | Terrain deformation audit (Orb's playtest 8: "weird unexpected behaviour") | - | 2026-09-30 |
| world/water-cost.md | 21 | The rest of the beam's ticks: the second window, the scorch and a building's heap (World,  | plan/park? | 2026-11-02 |
| world/water-read.md | 42 | What is slow in a beam's water window tick, and the fix (World, 2026-11-02) | plan/park? | 2026-11-02 |
| world/water-v2.md | 51 | Water v2: holes fill, the pebble skip stays | plan/park? | 2026-10-23 |
| world/window-blowouts.md | 48 | The window blow-out record (a sim record for replay seeks): plan | plan/park? | 2026-10-03 |
| world/wreck-toss.md | 16 | The liftable wreck: World's query for Wreck Toss (2026-10-25) | - | 2026-10-25 |
