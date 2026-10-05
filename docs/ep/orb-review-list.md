# Everything waiting for Orb, and where it is

Written by the EP on 2026-10-01. Paths are from the project folder. The fuller state of the build is in docs/ep/status-2026-10-01.md.

## Play and watch

- The game: https://dixonbalsagna.github.io/orb-combat-ex/play/
- The opening (entrance and staredown), off by default: https://dixonbalsagna.github.io/orb-combat-ex/play/?intro=1 . Decide whether it becomes the default.
- Two-controller test checklist: docs/controls/local-two-player.md. Phone checklist: docs/controls/phone-test-checklist.md. Old-laptop benchmark: /bench/ on the live site.

## Sound

- Music, three 30 s sketches to choose from by ear: audio/preview/sketch-a-town-band.wav, sketch-b-furnace.wav, sketch-c-kitchen-drums.wav. The pitch behind them: docs/audio/direction.md section 3.
- Fighter voices (babble): audio/preview/babble-protagonist.wav, babble-anti_hero.wav, babble-empress.wav, babble-cyborg.wav.
- Grunts, two versions each: audio/preview/voice.protagonist.*.wav and voice.anti_hero.*.wav. Notes: docs/audio/grunts.md.
- Impacts, two versions each: audio/preview/impact.light, impact.heavy, impact.crater (v0 and v1).
- Face cut-in stings: audio/preview/flash-circles-*.wav.
- How to hear them in the engine: audio/README.md.

## Art

- Close-up faces, the three directions (A and B are the mask directions Orb has now parked): art/concepts/closeups/closeups-comparison.svg, others-C.svg, anti-hero-C.svg. Notes: docs/art/closeup-directions.md.
- Faces and portraits: art/concepts/faces/faces-1-anti-hero.svg, faces-2-others.svg.
- Silhouettes: art/concepts/silhouettes/ragdoll-silhouettes.svg.
- Turnarounds: art/concepts/turnaround/ (cyborg, empress, protagonist, coil). Notes: docs/art/cyborg-turnaround.md and the others beside it.
- Coming: the refinement sheets, Cyborg first, in art/concepts/refine/ (README.md is the index).
- Open: whether the Anti-hero's tail stays; the Anti-hero's aura colour (violet range is Legal-safe, amber is not).

## Animation

- Review packs, five A/B letters each: art/animation/review/wave1/README.md and wave2/README.md; three A/B pairs in art/animation/review/step3/README.md.
- Reels: art/animation/overhaul-L-showcase-reel.gif, golive1-before-after.gif, intro-reel.gif, ground-*.gif, laststand-*.gif, tumble-broken-arm-before-after.gif.
- The joint-limit fix for the unnatural bends is live: docs/animation/joint-limits.md; before and after in art/animation/joint-limits/ (four GIFs). 150 of 359 poses changed, including wave 1 and 2 poses, and the wave 1, wave 2 and step 3 packs are now rebuilt on the new rig (each README has a "What changed" section). A new pack covers the knock-back slides, the buried fighter, the taunt and the charges: art/animation/review/agency1/README.md. The list of changed poses: art/animation/records/joint-limits.md; old against new, side by side: art/animation/joint-limits/changed-poses-1.png to -5.png.
- Decide: go or no go on the rich moveset (docs/combat/m0-rich.md, docs/combat/pending/waves-index.md, docs/animation/review-plan.md), and switching on wave 1's strikes.
- Decide: whether the transformation's "draw in, snap, hold still" staging is what Orb wanted.

## Writing

- The voice-lab packet to edit: docs/narrative/voice-lab/ (read known-tells.md and README.md first; one CSV per fighter, plus staredown-last-stand.csv).

## Design questions

- The third rule-of-cool questionnaire (the EP shows it as a form on request). The first two are recorded in docs/ep/vision.md; the feature list is docs/design/rule-of-cool.md.
- Simple layouts transforming automatically: docs/controls/auto-form-spec.md (the EP recommends yes).
- Depth: what happens when a fighter flying freely meets a building at his depth (docs/world/fight-lanes-world.md section 14).
- The EP's rulings made in Orb's absence, to overrule or keep: the last section of docs/ep/status-2026-10-01.md.

## Legal and business

- The licence: docs/legal/licence-recommendation.md (the repo is all rights reserved until Orb picks).
- The title clash, before any store page: docs/legal/name-screening.md and docs/legal/pre-store-checklist.md.
- Legal's review of the fighter concepts: docs/legal/fighter-concepts-review.md.
- The private feedback target (where players' feedback goes; never Orb's personal email without Orb's say).
- The launch roster size.

## Housekeeping

- Delete the empty folder C:\AppData (made by mistake by a director session).

## Added 2026-10-02

- The sky reaction at tiers 3 and 4 (the "strange aura" Orb saw): fixed to a gap in the clouds with a lit edge. It is now subtle, and shows nothing under clear sky. Before and after: docs/rendering/img/sky-gb002-high-before.png and sky-gb002-high-after.png. Decide whether it is now too faint (a stronger lit edge, or clouds gathering round the fighter).
- Cyborg directions and the refine sheets: art/concepts/refine/README.md.
- Player agency (from the two-player playtest): docs/design/agency-pass.md (rules and two pitches), docs/controls/agency-input.md, docs/director/agency-evidence.md, docs/combat/alchemist-content.md.
- Taunt lines that stay fresh: docs/narrative/taunt-system.md (five questions for Orb in section 12) and 208 draft lines to edit in docs/narrative/voice-lab/taunts-draft.csv.
- Energy (2026-10-02): the rules are docs/design/agency-pass.md sections 15 and 16. Pictures of the explosions and the mine looks: docs/vfx/img/explode-charged-after.jpg, explode-bolt-after.jpg, explode-knocked-loose.jpg, mine-kai-armed.jpg, mine-vorr-armed.jpg, mine-fuse.jpg, mine-blast.jpg. Poses for the swat, laying a mine and the spray: art/animation/review/energy1/README.md. Decide: which extra blast kinds to build (splitting shot, rain, curving shot, ricochet, burning wake, shield orb); six mines a fighter; the signature limit (the switch is on: 15 s).
- The sky: docs/rendering/sky-gap-anchored.md (accept a world-anchored cloud gap, or drop it).
- The launch pair plan (the Protagonist and the rival): docs/design/launch-pair-plan.md. Decide: the rival gains +2 Pride per building he levels (yes or no); names for both.
- The rival's glasses: art/concepts/refine/anti-hero-glasses.svg. Decide: the frame (Art's lead: blade lenses; second: cut hex), whether the glare hides his eyes completely, and whether the glasses are always on.
- The launch pair's look (2026-10-03), three sheets in art/concepts/refine/: glasses-compare.svg (frame A lead blade lenses with a lit top line, B bevelled with hinge tabs, C bare wedge, D the earlier plates; Art picks A), launch-pair-protagonist.svg (big fists and a broader body with the forelock, or the long swept tuft?), launch-pair-rival.svg (long tail and coat blades, or the swept shoulder blade?).
- The Protagonist's strikes (42 slots, 12 re-posed, 8 of his own): art/animation/review/protag1/README.md.

## Decisions waiting on Orb (2026-10-03, after slices 8 to 12 went live)

- Match length: widen the median band to 6:00 to 8:30 (Game Design, agency-pass.md section 19), or keep 8:00. QA is re-measuring a wear lever on df05b9f that may hold 8:00 without shortening the last stand.
- Front-row buildings (52.7% lost, ceiling 50): raise the ceiling, soften landing blasts to about a third (World, ground-contact.md section 32), or reduce top-tier reach into buildings (QA's lever, being re-measured).
- Which extra blast kinds ship: curving shot (Protagonist), splitting shot and rain (rival); whether rain can hit its thrower; rain on a roof (launch-pair-plan.md section 9).
- The look picks: glasses frame A, B or C (art/concepts/refine/glasses-compare.svg), launch-pair-protagonist.svg, launch-pair-rival.svg.
- The landing ring that shows where a deflected shot will explode: keep, or make the landing a surprise.
- The rush jolt in split screen (Camera: docs/camera/split-screen.md section 21c): tackle in this update or later.
- The beat-pace metronome earning the perfect blur about a quarter of the time: build Controls' fix (docs/controls/agency-input.md, option B) or leave it.
- The fighters' names; the split to PROTAGONIST and RIVAL can run on neutral ids meanwhile.

## New for Orb (2026-10-04)

- Dynamic intros: docs/narrative/dynamic-intros.md (eleven scenario templates; Orb's questions are at the end of section 10) and docs/director/dynamic-intros-plan.md (how it is built; first cut is 3 templates and 9 parts).
- Backstory: docs/narrative/backstory-skeleton.md (ten questions the power system needs answered, three options each, and three bundles: the Living World, the Proving Ground, the Tide).
- QA's confirmation of the retuned build: docs/qa/baseline-9fcdf87.md.
- Music for Suno: docs/audio/suno-prompts.md (12 paste-ready prompts; start with M01 title, M02 fight act 1, M05 fight act 4), docs/audio/suno-direction.md (the sound bible; Orb's decisions are in section 7), reference clips to upload in audio/preview/suno-reference/ (150, 180 and 210 BPM), and where to drop the results: audio/music/incoming/ (see audio/music/README.md).
- Approved launch pair references (2026-10-04), in art/concepts/refine/: approved-protagonist-turnaround.svg, approved-rival-turnaround.svg, approved-protagonist-faces.svg, approved-rival-faces.svg, rival-glare-c.svg. One question left: are the rival's glasses always on, or only for the taunt and the seal break?
- Moveset generator design: docs/combat/moveset-generator.md (samples per stance for both fighters). Questions: are the identity weights the split wanted; the rival's posed hand strikes are mostly open blade hands, not fists (swap them?).
- Generated martial-stance movesets (parked, for review): docs/combat/pending/movegen/review-sheet.md (92 rows: 30 lights and 16 heavies per fighter).
- Roster of twelve (2026-10-05): start with docs/ep/roster-twelve-overview.md; detail in docs/design/roster-twelve.md and docs/narrative/roster-twelve-identity.md. Eleven questions for Orb are listed in the overview.
- Move names for the voice lab: docs/narrative/move-names-draft.csv (60 rows, the voice lab's eight columns; pull it in and edit) with the rules in docs/narrative/move-names-draft.md.
- Intro plotlines: docs/narrative/dynamic-intros.md section 11 (the generative layer; Orb's questions at 11.11; what Orb authors: the canon ledger rows and about 32 lines a fighter).

## Morning summary for Orb (night of 2026-10-05; the EP updates this as work lands)

Live on the play page (pushed, build green, checks passed on an export):
- Lunges wind up before they move (6 ticks light, 10 heavy), with a tell.
- The stance input: the game now reads which stance button is held, a held A and a held B. Replays recorded before this no longer play back. The Brawler control layout is retired (a saved choice loads as Arena).
- The finisher struggle at strictness 2; the rival's heavies land with a fist; the deflect landing ring is gone; the glasses glare; split-screen camera fixes and an incoming-attacker marker.
- Press styles and the zip's looks are in but switched off: Shift+F7 turns the body motion and effects on together. Nothing drives a zip yet.

Written and waiting for Orb to read:
- Roster of twelve: docs/ep/roster-twelve-overview.md (one open disagreement: leave out the Harbinger or the Showman).
- Intro plotlines: docs/narrative/dynamic-intros.md section 11.
- Move names to pull into the voice lab: docs/narrative/move-names-draft.csv.
- All five stances' generated movesets (100 moves a fighter, parked): docs/combat/pending/movegen/review-sheet.md.
- The melee spec with every ruling: docs/design/melee-press-feel.md. New tonight in section 11: one chart of the signature kinds per stance with alternatives (one worth your eye: the rival's energy signature as a barrage in place of a beam), and what answers each finisher (a launch: the defensive stance; a melee: the manoeuvre stance; a beam: your own signature press).
- QA's interim on the wind-up build (3,200 matches): the median match is 478.9 s, inside the band by about a second; KAI wins 49.4% with no slot split.

Landed later in the night (pushed; checks passed on an export):
- Buildings break in four stages (windows out, cracked with a cut floor, shell, fallen), and a first blast can no longer flatten a building outright. On World's 160-match measure the front row's losses fall from 51.5% to 36.0% and all rows from 40.4% to 27.7%. The stages have no effects of their own yet: VFX is building them.
- Animation's zip entries, the far-side pass (over or round the rival), the check's guard and the push style, and ten intro gestures for the launch pair. GIFs: art/animation/review/gestures/, art/animation/review/zip/, art/animation/review/press-styles/. Nothing drives them in a match yet.
- Legal screened the gestures, the pass and the other four stances' moves: nothing ruled out (docs/legal/stances-and-gestures-screen.md). The short beam must be seen drawn before it goes live.

- Effects for each building stage: glass showers, falling cladding, dust, and smoke rising from a shell (stills: docs/vfx/img/bs-*.jpg). The building itself still looks intact at every stage until Rendering's per-stage look lands.
- Dynamic intros are in the sim: an intro is composed from parts and templates, with gestures. A match still opens with the classic intro until the match start asks for a composed one (UI has that task).
- A held-pose check on Legal's rules now gates the animation data. Three poses changed for it: the shrug's elbows bend, the last stand's rise brings its arms forward, the energy ready's hand moved off the hip (docs/animation/held-lint.md).

- Each building now looks its stage: windows out with soot, cracked with a sheared corner, a stripped dark shell (stills: docs/rendering/building-stages.md). Pavement cracking differently from dirt needs one more World slice.
- A match now opens with a composed intro: one of three openings by seed (both drop in, a long stare-down, one arrives late). Skipping works as before; `?nointro=1` on the play page starts in the fight. Known gaps: no gestures play in them yet, a rematch on the same seed opens the same way, and with split screen off the camera loses the fighter on the ground for part of the longest intro. All three have a fix planned for Simulation's next slice.
- The HUD shows the five stances: a badge on both plates (the rival's always), a five-chip row with the button that holds each stance, a legend whose button names follow the held stance, and a Stances page in How to play. Only the energy stance shows new names (bolt, charged shot, mine, beam), because only its moves exist today; the others show what the buttons do now. An optional beat ring (Settings, Controls; off by default) closes on whoever is about to be struck.
- Controls fixed two touch faults (an armed charging stance now throws a special; the energy latch no longer re-arms itself).

In the queue, in order: Encounter's first brawl slice (every press a blow; being applied); Simulation's next slice (default intro gestures, a rematch counter, the one-view camera); the fighter rename to PROTAGONIST and RIVAL; the zip.

New small questions for you:
- Simple touch cannot reach the third (utility) special directly. A context button under Power would fix it. Build it?
- Intro plots for the launch pair have three placeholders that are yours: who carries the old injury in their grudge (set to the Protagonist for now), the two past events they refer to, and each fighter's vetoed stances (docs/narrative/pending/intro_plots.json).
- The stance names and every button name per stance are drafts in ui/data/stances.json for you to edit.
- Mash against mash (Game Design's new rule, docs/design/melee-press-feel.md section 3): the faster tapper wins the trade and closes with the stagger; a trade cannot pass 90 ticks; a dead-even one is settled by a seeded draw the player cannot see. Is that how you want it to feel? Encounter is building the brawl to it.
- Hold to flurry (docs/controls/hold-to-flurry.md): since tap speed now decides a mash, do you want an accessibility switch where holding X throws a light every 10 ticks (6 a second, no damage bonus, never graded as timed)? Controls recommends doing it in the brawl itself so replays and inputs do not change. Not built.

To watch: time at power tier 4 is 7.05% a minute after the building change, against a floor of 6. QA's overnight baseline will say whether it holds.
