# I-12 Inventory: art, research, marketing, legal

- **Slice:** I-12 (art-research-marketing-legal)
- **Covers:** `art/`, `research/`, `docs/marketing/`, `docs/legal/` (legal as an index only)
- **Tracked files:** 1,172 (`git ls-files art research docs/marketing docs/legal | wc -l`)
- **Total lines:** 1,297,131 (`cat` of all tracked files piped to `wc -l`; includes SVG, JSON run output and binary images, so it overstates text)
- **Uncommitted paths (baseline-status.txt):** 275 = 14 modified (` M`) + 261 untracked (`??`)
  - By kind: 130 png, 87 gif, 31 svg, 25 mjs, 1 json, 1 md
  - By folder: art/animation/review 112; research/planet-gen/img 96; art/concepts/looks 18, biomes 13, faces2 11, picks 8, forms 5, megastructures 3, energy 1; research/rule-of-cool/clips 8
  - The 14 modified are art/concepts/biomes (11 SVG + gen.mjs + spec.mjs) and art/concepts/energy/energy-lanes.svg
- **Bulk output counted, not read:** art/animation/review (295 tracked, 241 images), art/concepts/closeups (175 tracked, 162 images, 9 engine snapshots), research/engine-spike/results (107), research/planet-gen/img (12 tracked + 96 untracked), the art/animation top-level GIF/PNG reels (about 55 files)

## How the game reaches art
`art/concepts/.gdignore` and `art/animation/.gdignore` hide both folders from Godot, so no runtime file loads art directly. Art's generators write `data/art/*.json` (12 files, outside this slice), which the renderer reads. Several render scripts are ports of art code (cited below).

## Systems

| System | What it does | Files (lines) | Data/schemas | Switches | Tests / CI job | Reached? | Leftovers | Owner |
|---|---|---|---|---|---|---|---|---|
| Biome look generator | Node generator that draws the biome sheets and writes the biome look bible as data | art/concepts/biomes/*.mjs (16 scripts) + README, 1,180 text lines; 23 images | writes data/art/biomes.json (data/art/biomes.json:3), schema tools/schemas/art-biomes.schema.json:5 | none found | data/art/biomes.json validated by tools/validate.js (ci.yml:77-81, data job); generator itself untested | yes: render/core/biome_look.gd:19 reads the data; cover_meshes.gd:4,10,773 ports draw.mjs/covers.mjs/shell.mjs | gen.mjs, spec.mjs and 11 SVGs modified uncommitted; "strip" wording in draw.mjs:48,201,307 | art |
| Sky generator | Writes the dynamic sky keys and slew rule | art/concepts/sky/*.mjs (6) + README, 758 lines; 7 images | writes data/art/sky.json (sky.json:3) | none found | render/tools/sky_check.gd:101 compares against keys.mjs reference; no CI line found for sky_check in ci.yml | yes: render/core/sky_drive.gd:4,20 | none found | art |
| Damage stages generator | Writes battle-damage stages per outfit | art/concepts/damage/gen.mjs + README, 167 lines | writes data/art/damage.json (damage.json:3) | none found | none found | yes: render/core/damage_look.gd:3,17 | none found | art |
| City looks and cars | Writes city palettes/facades and car silhouettes | art/concepts/city/gen.mjs, cars.mjs, 283 lines | writes data/art/city-looks.json, data/art/vehicles.json | none found | sim/world/tools/props_check.gd:21 reads vehicles.json; render/tools/city_check.gd:40 | yes: render/core/shapes.gd:24 (city-looks) | none found | art |
| Colour-vision presets | Searches and checks protan/deutan/tritan lane triples | art/concepts/colour-vision/*.mjs (6) + README, 363 lines | writes data/art/colour-vision.json (colour-vision.json:3,405) | none found | check.mjs (not in CI); render/tools/lane_check.gd:50 and render/vfx/tools/effects_check.gd:6279 read the data | yes: render/core/look.gd:921 | none found | art |
| Marked-aura head flashes | Writes the 13 head-flash recipes | art/concepts/marked-aura/gen.mjs + README, 771 lines; 6 SVG | writes data/art/flashes.json (flashes.json:130) | none found | audio/tools/host_check.gd:86-97 compares pulse numbers | yes, via audio host_check; audio/synth/flash_synth.gd:3 | backburnered ambush window in gen.mjs:83,655 ("Primed" flash); stale path, see Notable | art |
| Energy lanes | Searches and writes each fighter's energy colour lane | art/concepts/energy/*.mjs (4), 276 lines; 1 SVG | writes data/art/energy-lanes.json (energy-lanes.json:3, "Proposal pending") | none found | none found | unreached: no .gd/.mjs/.yml outside art loads energy-lanes.json (git grep) | energy-lanes.svg modified uncommitted | art |
| World (polar, outposts) | Writes polar palette and polar outposts | art/concepts/world/*.mjs (3), 422 lines | writes data/art/polar.json, data/art/outposts.json | none found | none found | unreached: no loader of polar.json/outposts.json found (git grep in *.gd, *.mjs, *.yml) | none found | art |
| Glasses / refine / launch pair | Fighter refinement sheets incl. the Anti-hero's glasses colours | art/concepts/refine/*.mjs (9) + README, 1,146 lines; 13 images | none (data/art/auras.json has no loader found) | none found | none found | ported: render/vfx/glare.gd:68 cites refine/glasses.mjs colours | none found | art |
| Character concept sheets | Concept generators: anti-hero, blank, directions, faces, forms, silhouettes, turnaround, closeups, shared marks | art/concepts/{anti-hero 1,418; blank 417; directions 539; faces 112; forms 195; silhouettes 121; turnaround 541; closeups 2,484; shared 190} lines | none | none found | none found | unreached (concept-only; no code outside art cites them, git grep) | KAI and VORR named in faces/gen.mjs:91; menace/anguish words in shared/marks.mjs (grep hit) | art |
| Uncommitted concept groups | New generators/sheets: faces2, looks, picks, megastructures, forms extras | 47 untracked paths (baseline-status.txt) | picks/picks-numbers.json | none found | faces2/test.mjs (not in CI) | megastructures.png is cited by tools/clips/mockups/pan.py:1 but is untracked | all uncommitted | art |
| Art prompt records | Numbered art briefs ART-0001 to ART-0024 plus TEMPLATE | art/prompts/*.md (25 files) | none | n/a | n/a | n/a (records) | none found | art |
| Animation review packs | Before/after sheets, GIFs, exceptions and summaries from the pose tools | art/animation/review (295 tracked, 2,795 text lines), records (9 md, 262), a0, joint-limits, flight-lead, ~55 top-level reels | raw/*.json run output | none | written by render/anim/tools/review.mjs:6,37 (not run in CI) | output only | 112 untracked review files | animation |
| Research: engine-spike | Godot vs web vs C# comparison with golden-hash sim reference | research/engine-spike: shared/*.mjs (479), tools (3), godot/web/csharp builds (77 files), results (107) | shared/golden.json | none | none in CI | led to ADR 0001 (RESULT.md:10-13); bench hook kept in render/core/main.gd:1747 | none found | research-prototyping |
| Research: band-proto | Standalone Godot prototype of a ground with depth | research/band-proto/main.gd (1,058), project.godot, results (4 json), shots (10) | none | none | built and deployed by ci.yml:432-438 (/band/) | reached by CI deploy only; not in the game (export_presets.cfg:11 excludes research/*) | "strip" axes wording main.gd:4 | research-prototyping |
| Research: planet-gen | JS prototypes of climate (A), plates (B), erosion (C) | gen/*.mjs (1,480), lib/*.mjs (519), check/bench/run scripts, stats (5) | stats/*.json | none | b_check.gd (in tools/world-checks.json:5, CI "World's checks" ci.yml:384-401) compares the port with vectors made from plates.mjs | yes: sim/world/tools/b_vectors.mjs:4-5 imports plates.mjs and det.mjs; plates ported to sim/world/plateb.gd:3 (gated by land.json b.enabled); climate.mjs not cited by sim/world/climate.gd:1-4 | 96 untracked images | research-prototyping |
| Research: ring-any-angle | 3D planet turntable prototypes, level benches, cuts | sim.js (367), proto-v2.html (568), ~20 mjs/html/json files | levels.json, cuts.json, results.json | five quality levels (RESULT.md) | tools/preview/stack-selftest.mjs:49 copies swing_smoke.gd.txt | design carried via docs/world/ring-any-angle/* (cited by render/camera/camera_params.gd:443 etc.), no code imports research/ring-any-angle | embedded GEN2PACK blob proto-v2.html:29 | research-prototyping |
| Research: rule-of-cool | Pitch papers, pad feel page, beam-contact bench, driver clips | feel.html (583), pitches.md, beam-contact*, driver-*, build.mjs | none | none | none | idea shipped: sim/core/kick.gd:3 cites pitches.md section 2; no code import | 8 untracked clips; GEN2PACK blob feel.html:29 | research-prototyping |
| Research: right-stick, rally, energy protos | Throwaway JS sims and GIF builders for controls, rally links, energy | right-stick-proto (v3/sim-core.js 721, tools 12), rally-proto/work/sim.js (506), energy-proto/work/sim.js (989) | none | none | right-stick tools/*.js harness (not in CI) | unreached: no reference outside research/docs (git grep) | "strip" in rally-proto/work/sim.js, right-stick-proto/gif.mjs (grep hit) | research-prototyping |
| Research: info-hiding | Partial testbed for one-screen hiding (parked) | core/{world 147, sim 174, camera 51, localize 94}.mjs | none | ambushMinHidden 1.8, ambushWindow 2.5 (sim.mjs:11-12) | none | unreached (git grep); parked per research/README.md | backburnered hiding/ambush system | research-prototyping |
| Marketing docs | Go-to-market, store copy, holding page, Steam readiness, first-month projection, phone-freeze words | docs/marketing/*.md, 7 files, 1,078 lines | none | n/a | none | n/a (docs) | KAI/VORR in go-to-market-plan.md:31,229,319 | community-marketing |
| Legal docs | Screens, rulings, licence drafts, review log, banned-move data | docs/legal: 68 files (index below) | movegen-banned.json (884) | n/a | movegen-banned.json read by render/anim/anim_held_lint.gd:121 (gate in render/anim/tools/anim_check.gd:6860) | yes (tools only) | see Notable | legal-ip |

## Legal index (one line per file: lines, title)
- agency-pass-screen.md (182): Agency pass originality screen
- alpha-discord-flags.md (16): Discord for Alpha reports, items for Orb
- alpha-tester-note.md (36): Note for Alpha testers
- animation-data-rule.md (40): Animation data origin rule and pose screen
- asset-origins.md (59): Asset origins
- aura3d-screen.md (25): 3D auras screen
- beat-templates-screen.md (24): Co-op story-beat library screen
- biome-fx-screen.md (30): Biome plumes, ambient life, beam scars screen
- bolus-predator-screen.md (24): Predator ruling (RL-220)
- brawl-screen.md (76): Brawl second pass screen
- bystander-comedy-screen.md (49): Bystanders and comic collateral ruling (RL-247)
- campaign-screen.md (55): Campaign memory, rematch, ledger screen
- catastrophe-and-city-screen.md (37): City tints, catastrophe boss, run mode screen
- city-and-open-floors-screen.md (24): Re-laid city and casualty count screen
- contributor-rules.md (45): Contributor rules for .github/
- core-four-names-screen.md (29): Core four names screen
- creative-rulebook-handover.md (43): Hand-over of the creative rulebook (CD-15)
- crumbs-screen.md (47): Freeze breadcrumbs privacy wording
- drafts/LICENSE (9), drafts/LICENSE-ASSETS (27), drafts/NOTICE (24), drafts/README.md (31): MIT + CC BY 4.0 + DCO drafts
- energy-and-pieces-screen.md (35): Beams, explosions, pieces, launch marks screen
- energy-overhaul-screen.md (169): Energy overhaul screen
- fighter-concepts-review.md (86): Fighter concepts IP review
- gemini-lines-screen.md (48): Homework 11 via Gemini provenance screen
- glasses-rules.md (57): Anti-hero glasses and glare rules
- go-to-market.md (388): What Orb must settle and disclose
- guide-licence-rundown.md (56): Licence rundown v2
- guide-selling-your-first-game.md (61): Beginner's selling guide
- guide-stomp-and-ratings.md (42): Rating boards and violent blows
- holding-page-screen.md (40): Holding page screen
- homework-renewal-note.md (30): Demo renewal note
- homework8-review-screen.md (69): Homework 8 reviews
- launcher-and-reach-screen.md (55): Launcher and energy reach screen
- licence-recommendation.md (179): Licence recommendation
- licence-register.md (90): Licence register
- movegen-banned.json (884): Banned move/held-pose rules as data
- movegen-screen.md (64): Generated movesets screen
- name-screening.md (188): Name screening
- names-grounds-and-gifs-screen.md (41): Planet/home names, Cyborg ground, GIFs screen
- never-use-words.md (22): Never-use words for public text
- originality-rules.md (74): Originality rules
- page-fixed-lines.md (91): Fixed lines for public page and gate
- photosensitivity-note.md (165): Photosensitivity adequacy
- pre-store-checklist.md (37): Pre-store checklist
- public-contact-wording.md (31): Public contact wording (CD-02, RL-256)
- public-readiness-edits.md (88): Public-readiness edits
- q3-screen.md (318): Questionnaire 3 screen
- rally-names-and-elites-screen.md (22): Rally names and elite henchman screen
- rally-screen.md (48): Rally links, sells, variety screen
- rehome-index-2026-11-07.md (96): Re-home index for misfiled safety items (CD-18)
- review-log.md (488): Review log
- rewards-and-lock-screen.md (42): Reduce-flashing lock, keepsakes, finishers screen
- roster-sketches-screen.md (27): Four sketched movesets screen
- rule-of-cool-screen.md (217): Rule of cool screen
- sigvariants-screen.md (23): Ten biome signature variants name screen
- stances-and-gestures-screen.md (93): Intro gestures, stances, roster of twelve screen
- steam-readiness.md (59): Steam readiness, Legal's half
- store-copy-screen.md (108): Store copy screen
- suno-music.md (72): Suno music ruling note
- super-heavy-screen.md (41): Super-heavy key sets screen
- three-strengths-screen.md (70): Three strengths screen
- tribute-vs-parody.md (39): Tribute, parody, fair use
- tropes-and-folklore.md (40): Tropes and folklore
- writing-note.md (23): Plain public copy note
- zip-screen.md (58): LT zip, looks, poses screen

## Notable
1. Stale path: audio/data/flash_cues.json:5 and audio/synth/flash_synth.gd:3 cite `art/concepts/marked-aura/flashes.json`, which is not tracked (git ls-files art/concepts/marked-aura lists no JSON); the canonical file is data/art/flashes.json:130.
2. tools/clips/mockups/pan.py:1 defaults to art/concepts/megastructures/megastructures.png, which is untracked (baseline-status.txt `??`; `git ls-files art/concepts/megastructures` = 0).
3. data/art/energy-lanes.json, polar.json, outposts.json and auras.json (written by art generators, e.g. energy-lanes.json:3) have no loader in any .gd/.mjs/.yml outside art (git grep).
4. The planet-gen spike is a live test oracle: sim/world/tools/b_vectors.mjs:4-5 imports research/planet-gen/gen/plates.mjs and lib/det.mjs, against research/README.md's "nothing outside research/ imports it" rule; b_check runs in CI via tools/world-checks.json:5 (ci.yml:384-401).
5. research/band-proto is built and deployed by CI (ci.yml:432-438), the only research spike in CI.
6. Legal data drives a tool gate: render/anim/anim_held_lint.gd:121 reads docs/legal/movegen-banned.json, gated by render/anim/tools/anim_check.gd:6860, though pose/look rules left Legal on 2026-11-07 (CLAUDE.md; docs/legal/creative-rulebook-handover.md). export_presets.cfg:11 excludes docs/*, so this is tools-only.
7. render/core/main.gd:1747 keeps a browser bench hook for research/engine-spike/tools/bench-browser.mjs.
8. Backburnered ambush survives in art: art/concepts/marked-aura/gen.mjs:83,655 ("Primed" flash on leaving cover with the x1.5 ambush window).
9. Backburnered hiding/ambush code in research/info-hiding/core/sim.mjs:11-12,50 (parked, unreached).
10. Placeholder names: art/concepts/faces/gen.mjs:91 ("KAI and VORR use these"); docs/marketing/go-to-market-plan.md:31,229,319 (KAI/VORR as public-name blockers, written 2026-10-05 per line 377).
11. Retired "strip" wording in art/concepts/biomes/draw.mjs:48,201,307 and research/band-proto/main.gd:4.
12. sim/core/kick.gd:3 cites research/rule-of-cool/pitches.md section 2: the one research pitch that shipped as sim code.
13. Large base64 GEN2PACK blobs embedded in research/ring-any-angle/proto-v2.html:29 and research/rule-of-cool/feel.html:29.
14. Biome generator has uncommitted edits (gen.mjs, spec.mjs, 11 SVGs) alongside data/art/biomes.json modified outside this slice (baseline-status.txt).
15. render/core/cover_meshes.gd:4,10,773 and render/core/biome_look.gd:37 are hand ports of art/concepts/biomes/draw.mjs, covers.mjs and shell.mjs: art JS is the reference for shipped render code, with no parity test found.

## Not covered
- Images (PNG/GIF/SVG/JPG), about 900 tracked plus 248 untracked, were counted, not opened.
- Bulk run output: research/engine-spike/results (107), art/animation/review raw/*.json and summaries, art/concepts/closeups/rounds snapshots: counted, not read.
- research/engine-spike/{godot,web,csharp} build sources (77 files): not read beyond RESULT.md.
- Legal and marketing contents: indexed by title only, per the brief.
- Whether render/tools/sky_check.gd, city_check.gd and render/tools/lane_check.gd run in CI: no match in ci.yml for those names; they may run through another runner not traced (not evidenced).
