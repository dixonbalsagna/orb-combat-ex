# False alarms

Every claim that did not hold up as a release-safety concern: 2 HALLUCINATED, 2 UNSUPPORTED, 16 OVERSTATED, 143 MISFILED, 163 of 294 in all. A false alarm here is not a judgement that the work was wasted. Many of these records protect real things (Orb's originality direction, Orb's PC, code quality). But they are filed as safety, so they compete for attention with the six S2 findings and make the safety record hard to read.

## The biggest false alarms, and what they cost

1. **Pose, gesture and look rules filed as legal safety (most of the 74 MISFILED under Orb's creative direction, plus AC-090 OVERSTATED).** Legal's screens set numeric limits on hands, arms, glows, ghosts and rings: "under 32 in depth", "never palm up", "opacity 0.35 or less", "no more than two of seven marks". They present breaches as NO-GO or CONDITIONAL. The screens call themselves "not legal advice" and cite no law. The US Copyright Office says single movements and gestures are not protected (Copyright Office Circular 52 as read by verifier v09; 37 CFR 202.1(a) as read through Cornell LII by verifier v08; the auditor did not re-read either). These are Orb's originality direction (CLAUDE.md; vision.md), and they are worth keeping as that. **Cost:** dozens of Open rows that block phase gates on paper (originality-rules.md:70 lets no flag stay open at a gate). Lints and look checks are tied to them, every new pose needs a Legal row, and the six real problems are buried among them. **Fix:** move them to a creative rulebook owned by Art and Animation under Orb. Keep Legal's role to names, likeness of whole characters, trademarks and copied assets.
2. **"Counsel before the repo goes public" and "keep it private until the must-fix list" (AC-070, AC-071 OVERSTATED).** The repo went public on its first day by Orb's ruling (vision.md:80), and M1 to M5 of the must-fix list are done. **Cost:** the records still read as if the repo is in breach, and the real remaining items (a licence choice, a contributor note) are lost among them. **Fix:** close RL-020 for M1 to M5, and fold the rest into the licence decision.
3. **Stale known bugs presented as live (AC-228 and AC-237 HALLUCINATED: true when written, fixed since).** GB-001 (F9 grey screen) was fixed in 658c95b1 on 2026-10-01, and the dispose leak in fbdbe7b6 on 2026-10-30. The register never changed. **Cost:** a fixed bug invites a re-fix or a new gate. **Fix:** mark both fixed, with their commits, and add a "re-verify on every baseline" step to the register.
4. **A store "needs" a Harding report (AC-018 OVERSTATED).** No store the project names requires one. It is prudent, and this audit recommends calibrating against a recognised analyser before a store release (F-09), but as a calibration and not as a platform rule.
5. **Debug routes bypass the lock on the live pin (AC-054 OVERSTATED).** The capture route is shut on a public host. Only F8 is live, and it changes flash shapes with Reduce flashing still on. It is an S4 note, fixed at HEAD.
6. **Team process filed as safety (21 MISFILED).** Machine discipline, "never put a prompt in front of Orb", token rules, phase sign-offs and the risk register protect Orb's PC and the team's way of working, not players. **Cost:** they make the safety record look three times larger than it is. **Fix:** keep them in CLAUDE.md and the playbook, not in safety records.
7. **Engineering quality filed as safety (34 MISFILED).** LAN rough edges, prototype bugs KB-001 to KB-006 (reproduced, but in the retired HTML prototype), harness rules and parity gates are QA and Netcode work. **Fix:** keep them in qa/known-bugs.md and the owners' docs, with a horizon tag.

## How to read the entries
Each entry gives the claim as the team recorded it, with its first sources (all sources are in evidence/claims-inventory.json), what the primary evidence shows, what the false alarm costs and the fix. The verifier's full reasoning and proof files are in evidence/verify-v01.json to verify-v20.json and evidence/AC-###.txt. AC-208 was first rated HALLUCINATED and changed to CONFIRMED-MINOR after the cold review (evidence/verdict-overrides.json), so it is not listed here.

## HALLUCINATED (2)

#### AC-228 GB-001: pressing F9 twice leaves the game permanently grey (split-screen re-attach), and only a restart gets out.
- Verdict: HALLUCINATED
- What the record says: GB-001: pressing F9 twice leaves the game permanently grey (split-screen re-attach), and only a restart gets out. (qa/known-bugs.md:147-154)
- What is actually true: This is a stale claim. GB-001 was fixed on 2026-10-01 in 658c95b1 ('F9 grey screen fixed'). attach() now reuses its viewports (split_view.gd:98-103), and pane_check case 8 asserts that attach, detach, attach keeps two panes. The guard is in both the public pin 257a766c and a8bc66e2. F9 is matched as a code string at main.gd:1560, so the search for KEY_F9 was the wrong probe. The register entry was never marked fixed. I did not run pane_check (no Godot). Proof: evidence/AC-228.txt; git log -S"QA's GB-001" -> 658c95b1 2026-10-01; 257a766c and a8bc66e2 split_view.gd both carry the GB-001 guard
- Cost of the false alarm: A fixed bug stays open on the web list and invites a re-fix or a new gate.
- Fix: Correct the record: mark GB-001 fixed in 658c95b1 and name pane_check case 8 as its regression test.

#### AC-237 SimCore.dispose leaves a disposed sim's _plans and _jobs behind, a small leak for a host playing many planet matches in one process.
- Verdict: HALLUCINATED
- What the record says: SimCore.dispose leaves a disposed sim's _plans and _jobs behind, a small leak for a host playing many planet matches in one process. (docs/net/cloud-reports/2026-10-28-ai-takeover.md:152)
- What is actually true: This is a stale claim, fixed on 2026-10-30 in fbdbe7b6. SimCore.dispose now calls WorldEpoch.release(S) unless keepWorld is set (sim.gd:38), and release drops the sim's _plans and _jobs. The only keepWorld caller is the rollback restore (net/snapshot.gd:69), where the state plays on. a8bc66e2 includes the fix, and the public pin 257a766c has no epoch.gd at all. Proof: evidence/AC-237.txt
- Cost of the false alarm: A fixed leak stays listed as open work for World.
- Fix: Retire it: mark it fixed in fbdbe7b6.

## UNSUPPORTED (2)

#### AC-010 The camera swing must pass the flash clips before any public pin. A full 360-degree swing reads 3.5 at 960x540, which fails the release gate.
- Verdict: UNSUPPORTED
- What the record says: The camera swing must pass the flash clips before any public pin. A full 360-degree swing reads 3.5 at 960x540, which fails the release gate. (docs/legal/photosensitivity-note.md:165)
- What is actually true: The 3.5 figure is a table in docs/world/ring-any-angle/rendering.md:359, measured in a scratch copy of the game, with no saved output. DirSwing is switched off ("enabled": false) at HEAD and at a8bc66e2, and the pin predates the swing data, so no build anyone plays carries it; 'private build only' overstates its reach. The rule itself is sound but already covered by AC-005's re-run-on-camera-change rule. I did not check other swing paths in the LAN build. Proof: audit/2026-11-07/evidence/AC-010.txt; data/director/swing.json:36; docs/world/ring-any-angle/rendering.md:332-336,359,362
- Cost of the false alarm: Small: an open row, plus a reading that could lead to a swing-rate cap before the real feature has been measured.
- Fix: Retire the separate row. When DirSwing is turned on, run the swing clips under the release rule and save the output.

#### AC-248 AI-written code is reviewed before merge. Long verbatim snippets and foreign licence headers are rejected, and a licence scanner is used when in doubt.
- Verdict: UNSUPPORTED
- What the record says: AI-written code is reviewed before merge. Long verbatim snippets and foreign licence headers are rejected, and a licence scanner is used when in doubt. (docs/legal/licence-recommendation.md:143; docs/legal/licence-recommendation.md:152)
- What is actually true: Nothing shows the review happens. There have been 0 PRs and 0 merges: 2744 commits went straight to an unprotected main, 2695 with a Claude co-author line. No licence scanner exists, and no record shows a check for verbatim snippets. A header grep of the code folders finds no foreign licence headers. The cited case is real: the Ninth Circuit affirmed in Doe v. GitHub, No. 24-7700, filed 2026-09-16. Proof: audit/2026-11-07/evidence/AC-248.txt; docs/legal/licence-recommendation.md:143; docs/legal/licence-recommendation.md:152. External: https://cdn.ca9.uscourts.gov/datastore/opinions/2026/09/16/24-7700.pdf (accessed 2026-11-07): "plaintiffs did not state a claim under the DMCA"
- Cost of the false alarm: The record gives false comfort that the code's provenance is checked when no test exists.
- Fix: Write the missing test: a CI grep for foreign licence, SPDX and copyright headers in shipped folders, plus one snippet-scanner pass before any store build.

## OVERSTATED (16)

#### AC-009 The camera cut's whole-screen dip and the building fly-past count as full-screen flashes and must be capped or fixed before public release, whatever the Reduce flashing default; the README names the camera fly-past of collapsing buildings as over the limit.
- Verdict: OVERSTATED
- What the record says: The camera cut's whole-screen dip and the building fly-past count as full-screen flashes and must be capped or fixed before public release, whatever the Reduce flashing default; the README names the camera fly-past of collapsing buildings as over the limit. (docs/legal/review-log.md:139; README.md:9 (HEAD); docs/legal/photosensitivity-note.md:39; +4 more)
- What is actually true: Under WCAG, a whole-screen luminance change does count across the whole area. But at the live pin the cut's dip is CUT_DIM 0.09, under the 0.10 flash step, and pane cuts are held to one a second. The collapse (fly-past) clip on the pin reads 2 on the primary reading in both modes; its 3.5 is the stricter area reading in full effects, which are locked away. So README's naming of the fly-past is stale. Addendum 10's 'prefer a dissolve' clashes with Orb's 2026-10-18 ban on dissolves, though it was marked as advice, not a ruling. Proof: audit/2026-11-07/evidence/AC-009.txt; git show 257a766c:render/camera/camera_params.gd:98,208-213; git show 257a766c:render/camera/split_rig.gd:1833-1841. External: https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html (accessed 2026-11-07): "anything that flashes more than three times in any one second period"
- Cost of the false alarm: It keeps RL-117 open 'until Camera fixes', shows the public a stale finding in README, and could push Camera toward the dissolves Orb banned.
- Fix: Correct the record. Close the dip item against CUT_DIM 0.09 at the pin and update README to the page-fixed-lines.md words. Keep the cut and collapse clips in the release set, and drop the dissolve advice.

#### AC-018 A store release needs an independent photosensitivity analyser report (Harding FPA, an equivalent recognised tool or a paid test house) on the worst-case recordings, and console makers' requirements must be asked for in their programmes; the public notices say none has been run.
- Verdict: OVERSTATED
- What the record says: A store release needs an independent photosensitivity analyser report (Harding FPA, an equivalent recognised tool or a paid test house) on the worst-case recordings, and console makers' requirements must be asked for in their programmes; the public notices say none has been run. (docs/legal/review-log.md:137; docs/legal/photosensitivity-note.md:21; docs/legal/photosensitivity-note.md:27; +5 more)
- What is actually true: The kernel is sound: the own analyser is unvalidated (flash-proof.md: 'not an independent check') and console terms are unread, so an outside check before a store release is prudent, and the notices do say none has been run. But no standard or store found requires a Harding report: WCAG lists it for information only and no Steamworks rule turned up, yet photosensitivity-note.md:21 calls a recognised tool 'the standard'; steam-readiness.md:39 already accepts the honest 'none has been run' line instead, with no ruling reconciling the two. Proof: audit/2026-11-07/evidence/AC-018.txt. External: https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html (accessed 2026-11-07): Harding FPA and PEAT listed as resources "for information only"; WebSearch 2026-11-07: no Steamworks photosensitivity-analyser requirement found; the Steamworks partner docs themselves were not reached
- Cost of the false alarm: A paid test house becomes a hard store gate under a zero budget, and two contradictory Legal records leave the store gate undefined.
- Fix: Correct the record: state the independent check as Legal's recommended margin, reconcile it with steam-readiness D4, and have Tools finish flash-proof.md's accuracy comparison (PEAT or equivalent); ask console makers only if a console port is planned.

#### AC-054 Debug routes must not reach full effects or skip the flashing notice under the lock: two routes (?flashcap=1 with a console call, and F8 flash_legacy) bypass the Reduce flashing lock on the live public pin, and the required fix puts the capture hook behind a build-time capture_hook feature that is false in public exports, refuses F8 under the lock, drops debug URL words on public hostnames, stops six desktop command-line words (bench, frames, shot, nonotice, flashcap, study) skipping the notice, and adds a standing route scan.
- Verdict: OVERSTATED
- What the record says: Debug routes must not reach full effects or skip the flashing notice under the lock: two routes (?flashcap=1 with a console call, and F8 flash_legacy) bypass the Reduce flashing lock on the live public pin, and the required fix puts the capture hook behind a build-time capture_hook feature that is false in public exports, refuses F8 under the lock, drops debug URL words on public hostnames, stops six desktop command-line words (bench, frames, shot, nonotice, flashcap, study) skipping the notice, and adds a standing route scan. (docs/legal/review-log.md:218 (HEAD); docs/legal/review-log.md:228 (HEAD); docs/legal/review-log.md:225 (HEAD); +6 more)
- What is actually true: On the live pin, gate_args drops flashcap on any public hostname, so route 1 is shut on /play/; only F8 is live, and it switches the flashes to their older shapes with no lock check while Reduce flashing stays on (Tools' reading of no change was not re-measured here). HEAD has every fix in code (capture_hook gate, F8 refused under the lock, bypass words refused under the lock), but the exported-build hook check sits in the dead CI and the fix reaches /play/ only when the pin moves. Proof: evidence/AC-054.txt: pin main.gd:1155 'if code == "F8":' toggles flash_legacy with no lock test; evidence/AC-054.txt: pin gate_args erases LOCAL_ONLY_ARGS (incl. flashcap) when bypass_allowed() is false; pin bypass_allowed() is true on the web only for localhost/127.0.0.1/[::1]/file:; evidence/AC-054.txt: HEAD main.gd:1588 'if code == "F8" and not UiData.rf_locked()'; HEAD bypass_allowed returns false when locked and capture_hook is off
- Cost of the false alarm: RL-196 stays open as a High blocker covering a route (?flashcap) that the code already shuts on the live host. That drives more route-scan tooling while the one real live route (F8) just waits on a pin move.
- Fix: Correct the record: route 1 is shut at run time on the live host, and F8 is the only live route, fixed at HEAD. Close RL-196 when the pin moves, and get CI running so the export hook check actually runs.

#### AC-070 Counsel was to read the licence files, the README and the homage wording, and clear the name, before the repo went public or anything was revealed.
- Verdict: OVERSTATED
- What the record says: Counsel was to read the licence files, the README and the homage wording, and clear the name, before the repo went public or anything was revealed. (docs/legal/licence-recommendation.md:3; docs/legal/licence-recommendation.md:161; docs/legal/name-screening.md:83; +6 more)
- What is actually true: The repo was made public on its creation day by Orb's ruling (vision.md:80), and no file records any counsel review. Only forward-looking 'have counsel read' lines exist. Legal's later docs move the counsel read to before the store page (pre-store-checklist.md:37) or the first sale (steam-readiness.md:52, guide-licence-rundown.md:3), and the homage lines are gone from README and CLAUDE.md. The 'before public' precondition can no longer be met. Proof: audit/2026-11-07/evidence/AC-070.txt; docs/ep/vision.md:80; docs/legal/pre-store-checklist.md:37
- Cost of the false alarm: It keeps alive a 'breached' precondition that nobody can ever close, which adds worry and phase-gate noise.
- Fix: Retire the 'before the repo goes public' counsel wording in licence-recommendation.md:3/161, public-readiness-edits.md:3, drafts/README.md:3/31, drafts/LICENSE-ASSETS:5 and suno-music.md:3. Keep one pre-sale counsel sitting, and settle whether it comes before the store page or before the first sale.

#### AC-071 The repo was to stay private until a Must-fix list of repo text edits and a rename were done and Orb approved a licence and a name: 'Do not make the repo public without a licence file', with Must M6 placing LICENSE, LICENSE-ASSETS, NOTICE, CONTRIBUTING and a PR template first.
- Verdict: OVERSTATED
- What the record says: The repo was to stay private until a Must-fix list of repo text edits and a rename were done and Orb approved a licence and a name: 'Do not make the repo public without a licence file', with Must M6 placing LICENSE, LICENSE-ASSETS, NOTICE, CONTRIBUTING and a PR template first. (docs/legal/review-log.md:42; docs/legal/review-log.md:437-438; docs/legal/licence-register.md:86; +5 more)
- What is actually true: The repo is public with no LICENSE, NOTICE, CONTRIBUTING or PR template; licence files were added and then removed on 2026-09-29 (701c76a0, 31664705). Musts M1 to M5 are done: the repo is renamed, and the franchise, fan-game and old repo names are gone from the README, CLAUDE.md, the charters and the setup docs. README.md:7 reserves all rights and asks visitors not to copy. The repo has had 0 pull requests, and Legal's own go-to-market.md:350 says 'None of this is urgent'. Proof: audit/2026-11-07/evidence/AC-071.txt; docs/legal/public-readiness-edits.md:32; docs/legal/go-to-market.md:350
- Cost of the false alarm: A breached 'do not make public' blocker reads as a live violation, even though no licence means all rights reserved, the most protective state for Orb.
- Fix: Correct the record: close RL-020 for M1 to M5, fold M6 into the licence decision (AC-074) and a contributor note (AC-083), and drop 'Do not make the repo public without a licence file' from licence-register.md:86.

#### AC-074 No licence is chosen, so all rights are reserved; Legal recommends shape A (MIT code with content and name reserved, CC BY 4.0 for content withdrawn), the README must say what visitors may do and carry a do-not-redistribute line, and the missing licence blocks tips, sales, Steam and any 'open source' wording.
- Verdict: OVERSTATED
- What the record says: No licence is chosen, so all rights are reserved; Legal recommends shape A (MIT code with content and name reserved, CC BY 4.0 for content withdrawn), the README must say what visitors may do and carry a do-not-redistribute line, and the missing licence blocks tips, sales, Steam and any 'open source' wording. (docs/legal/review-log.md:110; docs/legal/review-log.md:115; README.md:7 (HEAD); +19 more)
- What is actually true: There is no licence (GitHub's license field is null), and README.md:7 reserves all rights and asks visitors not to copy. An owner can sell or list an all-rights-reserved game without a licence file, and Legal's steam-readiness.md:37 calls the licence 'Orb's call', not a block. Only the 'open source' wording is truly barred, yet CLAUDE.md:3, which is public, says 'Free and open source'. The record contradicts itself (licence-recommendation.md:13, drafts/README.md:3 and vision.md:43 against vision.md:81), and README.md:7 says the hosted build is offline while /play/ serves a playable build. Proof: audit/2026-11-07/evidence/AC-074.txt; CLAUDE.md:3; docs/ep/vision.md:81
- Cost of the false alarm: Marketing treats a business choice as a hard block on Steam, sales and tips, which can stall plans while the real gaps (wrong public wording) go unfixed.
- Fix: Correct the record: make the four licence statements agree with vision.md:81, drop 'Free and open source' from CLAUDE.md:3, fix README.md:7's 'offline' sentence, and keep 'licence first' only for outside contributions and open-source wording.

#### AC-078 No asset merges or ships without an origin row in asset-origins.md (tool, model, date, prompt) and, for audio, a recorded licence; file-level rows are required before a store build, 'edited by Orb' claims need the diff named first, and dev tools, CI actions and npm packages are registered.
- Verdict: OVERSTATED
- What the record says: No asset merges or ships without an origin row in asset-origins.md (tool, model, date, prompt) and, for audio, a recorded licence; file-level rows are required before a store build, 'edited by Orb' claims need the diff named first, and dev tools, CI actions and npm packages are registered. (docs/legal/asset-origins.md:6; docs/legal/asset-origins.md:9; docs/legal/asset-origins.md:47; +10 more)
- What is actually true: The file-by-file log did stop on 2026-09-29, and the fake EXAMPLE-000 row is still there, but class-level rows cover every class of shipped content. The live index.pck holds only scripts, scenes, JSON and shaders, with no font, audio, image or model file, so no unlogged third-party asset ships. Steam asks for a description of AI content, which the class rows give, so file-level rows are Legal's margin. The tools and npm register part (A8) was not checked. Proof: audit/2026-11-07/evidence/AC-078.txt; docs/legal/asset-origins.md:47
- Cost of the false alarm: A 'breached' gate on every merge implies unlicensed assets ship when none do, and file-level rows for thousands of AI-written code files would be busywork.
- Fix: Correct the record to the class-level practice plus a row for any imported third-party file. Write the missing test: fail the site build when the pack holds a font, audio or image file with no register row (packFiles() already reads the pack). Delete EXAMPLE-000.

#### AC-079 Text from any AI tool other than Claude (Gemini) needs a provenance record (model, date, brief, returned file) kept apart from Orb's lines and complete before main goes public or any store page; Gemini output is for creative writing only, Google's Gemini API terms claim no ownership of output but the paid consumer app's terms are unconfirmed, and no private notes, unreleased art or NDA material go into a consumer AI app.
- Verdict: OVERSTATED
- What the record says: Text from any AI tool other than Claude (Gemini) needs a provenance record (model, date, brief, returned file) kept apart from Orb's lines and complete before main goes public or any store page; Gemini output is for creative writing only, Google's Gemini API terms claim no ownership of output but the paid consumer app's terms are unconfirmed, and no private notes, unreleased art or NDA material go into a consumer AI app. (docs/legal/movegen-banned.json:790; docs/legal/gemini-lines-screen.md:12; docs/legal/go-to-market.md:48; +8 more)
- What is actually true: Provenance records exist, though still parked under pending: provenance_hw11.json gives the tool, the model as named, the date and a per-line source, and provenance_mc.json has 244 Gemini mentions. Google's Terms of Service (effective 2026-07-30) say Google will not claim ownership of generated content, which answers the consumer-app question. The Gemini-session names Grist and Loupe are in HEAD's fighter_names.json (public repo, LAN builds) but not in the live pin. A provenance row for the naming session was not checked. Proof: audit/2026-11-07/evidence/AC-079.txt; docs/legal/gemini-lines-screen.md:12. External: https://policies.google.com/terms (accessed 2026-11-07, effective 2026-07-30): 'Google won't claim ownership over that content.'
- Cost of the false alarm: It keeps an 'unconfirmed terms' item and a pre-public gate open after the repo is already public, which prompts more review work.
- Fix: Correct the record with the Google ToS clause, land the two provenance files out of pending, and add a provenance row for the core-four naming session.

#### AC-084 'Meridian' is High risk as a public title: CONDITIONAL, working name only, never in store pages, logos, domains or the repo name.
- Verdict: OVERSTATED
- What the record says: 'Meridian' is High risk as a public title: CONDITIONAL, working name only, never in store pages, logos, domains or the repo name. (docs/legal/review-log.md:23; docs/legal/review-log.md:274-278; docs/legal/review-log.md:453-454; +2 more)
- What is actually true: The condition is met. The repo is orb-combat-ex, the Pages domain has no 'Meridian', the live pages have 0 hits, the live pack has it only in an allowlisted test fixture, and the README calls it the internal codename. Legal's own rating rests on crowding and protectability. The title moved to Orb Combat EX, yet RL-001 is still an Open P0 gate flag. Proof: audit/2026-11-07/evidence/AC-084.txt; docs/legal/review-log.md:23
- Cost of the false alarm: An open P0 gate flag on a satisfied condition adds gate work and makes the Legal backlog look larger than it is.
- Fix: Close RL-001 with a pointer to the pack and page scan. Keep 'Meridian' on never-use-words.md for public copy, and rename the 'Meridian Warden' and 'Meridian Lance' source fields with the KAI rename (S4).

#### AC-090 Standing rule: movegen-banned.json's pose, motion and energy bans (b01-b14, s01-s07, m01-m12, e01-e12, h01-h10, k01-k04) bar the franchise's best-known wind-ups, beam poses, vanish steps and barrages; the generator must refuse them, the build must fail if one slips through, the rows only grow, and 'a person screens every signature frame, new vocabulary and stance tell'.
- Verdict: OVERSTATED
- What the record says: Standing rule: movegen-banned.json's pose, motion and energy bans (b01-b14, s01-s07, m01-m12, e01-e12, h01-h10, k01-k04) bar the franchise's best-known wind-ups, beam poses, vanish steps and barrages; the generator must refuse them, the build must fail if one slips through, the rows only grow, and 'a person screens every signature frame, new vocabulary and stance tell'. (docs/legal/review-log.md:95; docs/legal/movegen-banned.json:3; docs/legal/movegen-banned.json:6; +5 more)
- What is actually true: The rows exist and have grown past the stated counts (s01-s09, e01-e16, k01-k06), and the pending generator refuses matching shapes. But nothing fails a build today. CI has run no job since 3c9005ac, the held lint covers only h01-h03 inside anim_check, which no workflow runs, and new rows refuse nothing until they get a machine form (legal.mjs:8-10). The 'person' who screens is the Legal AI session, and single poses carry little legal weight. Proof: docs/legal/review-log.md:95; docs/legal/movegen-banned.json:3; tools/movegen/lib/legal.mjs:8-10
- Cost of the false alarm: It gives false assurance that a human screens and that the build blocks lookalikes, and a growing ban list constrains Combat's generator and costs a Legal pass on every frame.
- Fix: Correct the record: the Legal session screens, and some rows have no machine form, so list them. Fix CI and wire the held lint into a workflow, and treat the pose bans as originality rules under Orb's direction.

#### AC-095 Energy hands, releases, deliveries, gestures and stance moves are clear, but the short beam is conditional, not yet drawn, and must be seen drawn before it goes live; a held-pose check on Legal's rules gates the animation data.
- Verdict: OVERSTATED
- What the record says: Energy hands, releases, deliveries, gestures and stance moves are clear, but the short beam is conditional, not yet drawn, and must be seen drawn before it goes live; a held-pose check on Legal's rules gates the animation data. (docs/legal/review-log.md:106; docs/ep/orb-review-list.md:116; docs/ep/orb-review-list.md:120)
- What is actually true: The short beam is now drawn as PROVISIONAL poses (beam2.mjs:27, :39) and used in anim_fighter.gd:5360, and Legal passed the Anti-hero's thin short beam on 2026-10-16, yet RL-084 still says 'not yet drawn'. The held-pose check exists, but it covers h01-h03 only and runs inside anim_check, which no workflow runs, so it gates nothing automatically. Proof: docs/legal/review-log.md:106; docs/ep/orb-review-list.md:116; docs/ep/orb-review-list.md:120
- Cost of the false alarm: The stale row suggests an undrawn item is waiting on Legal, and the word 'gates' overstates a check that is run by hand.
- Fix: Legal screens the drawn snap-beam poses and closes RL-084. Correct orb-review-list.md:120 to call the held lint a local check, or wire it into CI.

#### AC-223 At least 4 Steam screenshots must be marked suitable for all ages, which is Legal's call because the game shows violence.
- Verdict: OVERSTATED
- What the record says: At least 4 Steam screenshots must be marked suitable for all ages, which is Legal's call because the game shows violence. (docs/marketing/steam-readiness.md:15)
- What is actually true: Valve's Graphical Assets page says you 'should' mark at least four screenshots, and only ones that really are suitable for all ages. Shots with violence should not be marked. If none are marked, the game may be left out of some placements, such as the front-page hover. It is a store-visibility recommendation, not a requirement and not a safety matter. Proof: docs/marketing/steam-readiness.md:15; audit/2026-11-07/evidence/AC-223.txt. External: https://partner.steamgames.com/doc/store/assets/standard (accessed 2026-11-07): 'you should mark at least four screenshots'
- Cost of the false alarm: It turns a visibility tip into a must, which could block store prep or push a violent game toward staging all-ages shots.
- Fix: Correct the record to 'should, for visibility' and move it to Marketing's store-asset list. Legal still reviews which shots are marked.

#### AC-238 CI's data job gates the deploy, so a data-shape change without its schema cannot ship.
- Verdict: OVERSTATED
- What the record says: CI's data job gates the deploy, so a data-shape change without its schema cannot ship. (CLAUDE.md:112; docs/ep/handoff.md:52)
- What is actually true: The wiring is real: deploy needs data (ci.yml:528), so the gate fails closed. But ci.yml has run 0 jobs on every push since 3c9005ac (latest run 42419094149: 0 jobs), and the data job checks HEAD's data, not the pinned 257a766c tree that /play/ serves (tools/site-pin.mjs never calls the validator). So 'cannot ship' holds only because nothing ships at all. handoff.md:52 does not mention the gate. Proof: audit/2026-11-07/evidence/AC-238.txt; .github/workflows/ci.yml:528; .github/workflows/ci.yml:93-96
- Cost of the false alarm: It reads as a live check, so nobody noticed 37 unvalidated pushes. The lint that catches the YAML break sits inside the same dead data job.
- Fix: Correct CLAUDE.md:112: the data job checks HEAD only and is dead until the four step names are quoted. Run node tools/check-workflows.mjs before every push, and validate the pinned tree in the site job.

#### AC-244 World's step_check exits 0 even when it fails, which hides failures behind a passing gate.
- Verdict: OVERSTATED
- What the record says: World's step_check exits 0 even when it fails, which hides failures behind a passing gate. (docs/net/cloud-reports/2026-10-28-transport.md:73-77; docs/net/cloud-reports/2026-10-28-transport.md:97)
- What is actually true: It does exit 0 every time (step_check.gd:149-150 ends on a plain quit()). Since 0ca00c3e (2026-10-30), CI runs it through tools/gate.mjs --verdict, which reads 'STEP: 1 check(s) failed' as a failure (reproduced with verdictProblems). So it hides nothing in CI. Its failures were wall-clock budget flakes under load. Proof: audit/2026-11-07/evidence/AC-244.txt; sim/world/tools/step_check.gd:149-150; tools/world-checks.mjs:41
- Cost of the false alarm: It suggests a hole in the gates that the verdict wrapper already closes, inviting rework, and it is a QA tooling note carried as a safety bug.
- Fix: Retire it from the safety records. Record step_check's timing flake under World/QA, and note that it is safe only through gate.mjs --verdict.

#### AC-254 The audit rated 'no volume controls of any kind' and no mono option as P1, the most common accessibility ask.
- Verdict: OVERSTATED
- What the record says: The audit rated 'no volume controls of any kind' and no mono option as P1, the most common accessibility ask. (docs/accessibility/audit-2026-10-28.md:134; docs/accessibility/audit-2026-10-28.md:138; docs/accessibility/cloud-reports/2026-10-28-foundation.md:41)
- What is actually true: The public pin plays sound but has no volume or mono settings, so the gap is real on /play/. HEAD and the LAN builds have had Master, Effects and Voice volume plus Mono since 9979146a, a few hours after the audit, and these are wired to the audio buses. Browser and OS volume still work, so this is a gap against a basic guideline, not a P1 on a level with Legal's flash conditions. Proof: evidence/AC-254.txt; 257a766c options.json: 0 volume/mono keys; ui/hud/ui_hud.gd:632 AudioVoices.set_user_volume. External: https://gameaccessibilityguidelines.com/basic/ (accessed 2026-11-07): Basic includes "Provide separate volume controls or mutes for effects, speech and background / music"
- Cost of the false alarm: A stale P1 'blocker' keeps an item that is already fixed on the release-blocker list, and ranks a volume slider with seizure conditions.
- Fix: Correct the record: fixed at 9979146a, still open on /play/ until the pin moves, rated S3.

#### AC-291 A human player can switch stance while locked in an exchange and take only 0.38x damage.
- Verdict: OVERSTATED
- What the record says: A human player can switch stance while locked in an exchange and take only 0.38x damage. (docs/ep/handoff.md:40)
- What is actually true: Fixed in the GDScript game. Since 7fdfbe75 (2026-09-29) damage.gd:70-73 uses the stances frozen at requestAttack (exchange.gd:159, 340, 853), and the live pin has the same code. Only the frozen JS oracle (damage.js:16) and the prototype still read the live stance. The 'status unknown' handoff line is stale, and the matter is balance, not safety. Proof: audit/2026-11-07/evidence/AC-291.txt
- Cost of the false alarm: An open 'needs a ruling' item for Game Design and Controls on something already fixed in the game.
- Fix: Correct sim/README.md row 3 and docs/ep/handoff.md:40 to say the GDScript stance freeze (7fdfbe75) fixed it and the JS oracle keeps it, then retire the item.

## MISFILED (143)

### Orb's creative direction (originality, look, tone, marketing) (74)

#### AC-015 Look gate (ADR 0010): no test result (flash, performance) justifies a worse look, dissolves, fades and full-screen blur are banned, and "Safety concerns are met with warnings and settings, not by degrading the default look"; the warning, the Reduce flashing lock and the nightly seeds stay as safeguards while flash work is paused.
- Verdict: MISFILED (belongs to: Orb's creative direction; the nightly safeguard to Tools)
- What the record says: Look gate (ADR 0010): no test result (flash, performance) justifies a worse look, dissolves, fades and full-screen blur are banned, and "Safety concerns are met with warnings and settings, not by degrading the default look"; the warning, the Reduce flashing lock and the nightly seeds stay as safeguards while flash work is paused. (docs/decisions/0010-look-gate.md:10; docs/decisions/0010-look-gate.md:18; CLAUDE.md:115; +8 more)
- What is actually true: ADR 0010 says this and the six charters carry it; it is Orb's look direction and does not lower the release gate (RL-226 keeps primary at most 2.5 in both modes), so main stays blocked rather than shipping worse. Of its safeguards, the warning and locked Reduce flashing are live on /play/, but the 'nightly seeds' are run by hand (nightly-seeds.mjs:2), with no schedule in ci.yml and 6 runs ever, the last on 2026-10-30. Proof: audit/2026-11-07/evidence/AC-015.txt
- Cost of the false alarm: Filing the look gate as a safety waiver suggests Orb traded safety for looks and invites re-arguing taste, while the real gap (a 'nightly' that has not run for a week) hides behind the word.
- Fix: Take the look gate out of the safety records, keeping only the clause that safety is met by warnings and settings; Tools schedules the nightly or ADR 0010:18 is corrected to 'run by hand, last run 2026-10-30'.

#### AC-047 Blast amplification for power-up craters is GO on eight conditions.
- Verdict: MISFILED (belongs to: Legal (originality; Orb's originality rule))
- What the record says: Blast amplification for power-up craters is GO on eight conditions. (docs/legal/review-log.md:81)
- What is actually true: The eight conditions exist (agency-pass-screen.md:82-90, a file the log row does not name) and VFX built and tested them (POWERUP_OFF, blast_powerup_enabled, effects_check _blast). Most are staging distance from a well-known franchise's transformation (scream, crouch, aura, hair change, levitating rocks). Condition 3's 'no gold, white or red flash' is the one light rule, and the flash register already refuses red (flash_registry.gd:20). So this is an originality ruling, not a flash condition. Proof: evidence/AC-047.txt; docs/legal/agency-pass-screen.md:85 condition 3: no lightning, flame aura, hair change, gold, white or red flash
- Cost of the false alarm: It reads as an open flash condition 'until the first transformation cinematic' and keeps a flash re-screen on the list for what is really an originality check.
- Fix: Move to Legal's originality record and correct the log row to name agency-pass-screen.md; the flash side is already covered by the register.

#### AC-050 Wind-up, counter, caught and guard-broken marks: a hollow thin shrinking ring with no text, no face marks and no gold, white or red flash.
- Verdict: MISFILED (belongs to: Legal (originality; Orb's originality rule))
- What the record says: Wind-up, counter, caught and guard-broken marks: a hollow thin shrinking ring with no text, no face marks and no gold, white or red flash. (docs/legal/review-log.md:100; docs/legal/review-log.md:268; docs/legal/review-log.md:462)
- What is actually true: The rule exists as m07 and m08 and is built and tested (shots_view.gd:708, effects_check.gd:3937,4232). Its stated reason is 'no readout or scanner look, no mark 7', which is distance from a well-known franchise, so it is originality. The claim also overstates the rule: m08 bans only a full-screen or body-wide gold, white or red flash, not every such flash. Red is separately refused by the flash register (flash_registry.gd:20). RL-246 and RL-248 cite RL-240, RL-227 and k03 for colour, not RL-078. Proof: evidence/AC-050.txt; docs/legal/movegen-banned.json m08 why: "no readout or scanner look, no mark 7"
- Cost of the false alarm: A colour taboo read as flash-safety law makes later look choices (such as RL-248's gold ring) need Legal rulings they would not need on safety grounds.
- Fix: Move to Legal's originality record and quote m08's real scope (full-screen or body-wide only); leave red-flash safety to the register.

#### AC-076 Everything must be original (no characters, names, designs, catchphrases, music or code from existing franchises): the 'would a fan say that's the one from the show' test governs every name, design, sound and line, grey-zone defaults apply (no hair-colour power cue, no 'power level', no iconic poses, no franchise attack-name patterns, no Easter eggs), fan-game material is off limits, nothing flagged ships, and Legal reviews every locked design, name, bark and audio asset.
- Verdict: MISFILED (belongs to: Orb's creative direction (Legal for the copying floor))
- What the record says: Everything must be original (no characters, names, designs, catchphrases, music or code from existing franchises): the 'would a fan say that's the one from the show' test governs every name, design, sound and line, grey-zone defaults apply (no hair-colour power cue, no 'power level', no iconic poses, no franchise attack-name patterns, no Easter eggs), fan-game material is off limits, nothing flagged ships, and Legal reviews every locked design, name, bark and audio asset. (docs/legal/originality-rules.md:9; docs/legal/originality-rules.md:39; docs/legal/originality-rules.md:49; +16 more)
- What is actually true: The legal floor (no copied names, characters, art, music or code) is real IP exposure and holds: the franchise name has 0 hits in the live pin's player data, and 'power level' has 0 hits in its UI text. The fan-recognition test, the hair, pose and Easter-egg defaults, and 'no flag open at a phase gate' are Orb's originality direction, stricter than infringement law. The franchise is named in 5 docs/legal files and 4 other docs by choice. Proof: audit/2026-11-07/evidence/AC-076.txt; docs/legal/originality-rules.md:9; docs/legal/originality-rules.md:70
- Cost of the false alarm: Carrying taste-level margins as release blockers turns every grey-zone call into a phase-gate item and a Legal review.
- Fix: Move the rule to Orb's creative direction, with Legal enforcing only the copying floor, and keep risk-register row 1 for actual copying.

#### AC-088 No in-progress character art on any public page, HUD mock sheets stay private, and store frames show only the build as it ships.
- Verdict: MISFILED (belongs to: Orb's creative direction (Marketing))
- What the record says: No in-progress character art on any public page, HUD mock sheets stay private, and store frames show only the build as it ships. (docs/ep/vision.md:850; docs/ep/vision.md:1399; docs/marketing/steam-readiness.md:21)
- What is actually true: This is Orb's marketing preference in Orb's own words (vision.md:844-850). The live holding page has no images, and /play/ shows the build's fighters, which Orb allowed. The public repo holds 351 concept files, fighter close-ups among them, under Orb's ruling that the repo stays public. Steam's rule that screenshots show gameplay only is real. Proof: docs/ep/vision.md:850; docs/ep/vision.md:1399; docs/ep/vision.md:80. External: https://partner.steamgames.com/doc/store/assets/standard (accessed 2026-11-07): 'Screenshots should exclusively show the gameplay of your game.'
- Cost of the false alarm: As a safety rule it invites scrubbing art from a public repo or holding the site over a marketing preference.
- Fix: Move it to Orb's creative and marketing direction (Marketing). Ask Orb once whether committed concept sheets in the public repo are acceptable, and keep Steam's screenshot rule in the store checklist.

#### AC-091 The Anti-hero's glasses stay generic: angular lenses and a pale-violet wedge glare held 0.4 s at most, at key moments only and never at a transformation break, no bridge-finger push or folded hands, no stock 'as planned' lines; five glare frames are GO and frame 3 (chamfer plates) must change or be dropped.
- Verdict: MISFILED (belongs to: Orb's creative direction (Art, VFX))
- What the record says: The Anti-hero's glasses stay generic: angular lenses and a pale-violet wedge glare held 0.4 s at most, at key moments only and never at a transformation break, no bridge-finger push or folded hands, no stock 'as planned' lines; five glare frames are GO and frame 3 (chamfer plates) must change or be dropped. (docs/legal/review-log.md:88; docs/legal/glasses-rules.md:5; docs/legal/glasses-rules.md:15; +6 more)
- What is actually true: Legal itself calls the glare trope free to use (glasses-rules.md:5), so these are originality rules. render/vfx/glare.gd implements them: a pale-violet wedge, hold capped at 24 ticks (0.4 s), blocked in transformations, charges and rubble rings, with a 200-tick cooldown, and it ships in the public build. Orb picked frame C, the bare wedge (glare.gd:3), so the open item on frame 3 is moot. I did not measure the glare's luminance. Proof: docs/legal/glasses-rules.md:5; docs/legal/glasses-rules.md:26-27; docs/legal/glasses-rules.md:46
- Cost of the false alarm: It keeps an RL row open, and a gate condition alive, for a frame nobody uses.
- Fix: Close RL-066 (Orb chose frame C) and move the glasses look rules to Art and VFX under Orb's direction.

#### AC-101 The Full Circle fusion look is CONDITIONAL: no synchronised pose or dance, the merged fighter is a new design, rings rather than a halo, no earrings or accessory, and no franchise-style fusion name.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality; Art))
- What the record says: The Full Circle fusion look is CONDITIONAL: no synchronised pose or dance, the merged fighter is a new design, rings rather than a halo, no earrings or accessory, and no franchise-style fusion name. (docs/legal/review-log.md:51; docs/legal/q3-screen.md:74-81)
- What is actually true: The conditions are recorded as stated. The fusion is not built: no fusion code or data exists in sim, data, render or ui, and finishers.json:211 names it only as a possible variant. Matching poses, halos, earrings and merged outfits are genre ideas, not protectable expression on their own, so these conditions serve Orb's originality rule. Proof: git grep for fusion or Full Circle in data, sim, render and ui finds only finishers.json:211 and a ui comment (AC-101.txt); docs/legal/review-log.md:279 lists RL-029 as an open P0 gate flag. External: https://www.law.cornell.edu/uscode/text/17/102 (accessed 2026-11-07): "In no case does copyright protection ... extend to any idea"
- Cost of the false alarm: It holds an open P0 gate flag for a feature with no code, so a reviewer can read it as a release blocker.
- Fix: Take it off the P0 gate list and keep it as a look checklist for Art and Legal when the fusion is designed.

#### AC-102 O2 The Bloom is CONDITIONAL: no vertical pillar of light into the sky, no darkening sky, the fold opens inward. The round-4 storyboard (RL-034) is said to meet these conditions.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality))
- What the record says: O2 The Bloom is CONDITIONAL: no vertical pillar of light into the sky, no darkening sky, the fold opens inward. The round-4 storyboard (RL-034) is said to meet these conditions. (docs/legal/review-log.md:52; docs/legal/review-log.md:56; docs/legal/q3-screen.md:118)
- What is actually true: The O2 conditions are recorded, and RL-034 says the storyboard meets them. Yet RL-030 is marked 'Closed until final art' at review-log.md:52 and also listed as an open P0 gate flag at :279 (not :270 as the inventory says). The Bloom is not built anywhere in sim or data. A pillar of light or a darkening sky is staging, not protectable expression. Proof: review-log.md:52 'Closed until final art' and :279 'RL-027 to RL-030' open P0 flags (AC-102.txt); no Bloom or fold code in data/combat, data/fight, data/director, sim/core or sim/director. External: https://www.law.cornell.edu/uscode/text/17/102 (accessed 2026-11-07): "In no case does copyright protection ... extend to any idea"
- Cost of the false alarm: A status that is both closed and an open P0 flag invites a second review of a scene that has no code.
- Fix: Correct the record: take RL-030 off the P0 list and keep the planned re-screen at final art.

#### AC-103 The Marked plus Aura character style (sigils, dome mask, head flashes) is GO with conditions. The Anti-hero pride flash must use the round-tipped fallback, and the dome mask gets no eye or mouth slots.
- Verdict: MISFILED (belongs to: Orb's creative direction (Art))
- What the record says: The Marked plus Aura character style (sigils, dome mask, head flashes) is GO with conditions. The Anti-hero pride flash must use the round-tipped fallback, and the dome mask gets no eye or mouth slots. (docs/legal/review-log.md:57; docs/legal/q3-screen.md:193-197; docs/legal/q3-screen.md:206)
- What is actually true: Legal screened from Art's descriptions only (q3-screen.md:189, :221) and on 2026-09-29 confirmed Art had applied every condition. Art's record shows the round-tipped flash, a dome with no slots and the ma-5 checks sheet (committed 2026-09-29). Orb then parked masks for a future fighter (vision.md:476), yet the row still says Open and sits on the P0 list. I did not render the SVGs. Proof: q3-screen.md:221 'All conditions above are applied as described' (AC-103.txt); marked-aura.md:143-144: dome with no slots; round tips are the default for his pride flash; vision.md:476: masks parked as a seed for a future fighter
- Cost of the false alarm: A stale open P0 flag on a style Orb has since parked, asking Art for checks it already made.
- Fix: Close RL-035 as superseded by Orb's 2026-10-01 ruling and re-screen if a masked fighter comes back.

#### AC-104 Turnarounds and the Hazard/Primed/Respect flashes are GO, pending front-view ring and Empress crescent checks.
- Verdict: MISFILED (belongs to: Orb's creative direction (Art))
- What the record says: Turnarounds and the Hazard/Primed/Respect flashes are GO, pending front-view ring and Empress crescent checks. (docs/legal/review-log.md:58; docs/legal/review-log.md:270; docs/legal/q3-screen.md:241)
- What is actually true: The conditions are recorded. Art already changed the Protagonist's sigil to an open arc at the temple (protagonist-turnaround.md:63), which meets the front-view condition. I found no record of the Empress's 12 px crescent check. The Empress has no data/fighters entry, so nothing has shipped; the sheets are public concept SVGs I did not render. The claim's cited :270 is RL-248; the P0 list is at :279. Proof: protagonist-turnaround.md:63: sigil is an open arc at the temple (AC-104.txt); git ls-files data/fighters: PROTAGONIST, REFERENCE, RIVAL only
- Cost of the false alarm: An open P0 flag for a modelling-sheet check, half of which is already done.
- Fix: Close the ring half, move the crescent check to Art's checklist before key art, and take the row off the P0 list.

#### AC-105 Animation data rule and pose screen (section 3.7): GO, except the beam release pose, which is CONDITIONAL.
- Verdict: MISFILED (belongs to: Orb's creative direction (Animation))
- What the record says: Animation data rule and pose screen (section 3.7): GO, except the beam release pose, which is CONDITIONAL. (docs/legal/review-log.md:60)
- What is actually true: The log row still says Open, but Legal's own rule doc closed RL-038 on 2026-10-16 (animation-data-rule.md:40). The cast pose keeps the free hand far from the firing wrist, at HEAD and at the /play/ pin (hand_r [58,62,9] against hand_l [10,48,-12], tagged wrists_apart). A pose is not protectable expression, so this is an originality margin, and it is already met. Proof: animation-data-rule.md:40 'RL-038 closed 2026-10-16' (AC-105.txt); beam1.poses.json:7 bm.hold.fire_protagonist hand_l [10,48,-12], the same at 257a766c. External: https://www.law.cornell.edu/uscode/text/17/102 (accessed 2026-11-07): "In no case does copyright protection ... extend to any idea"
- Cost of the false alarm: A condition that is met shows as open in the log, so audits and gates count an item that is closed.
- Fix: Correct the log row to Closed 2026-10-16 to match animation-data-rule.md:40.

#### AC-106 The rule-of-cool plan (25 features) is Medium: CLEAR or CONSTRAINT per feature, feature 12 changed, plus the two-marks stacking cap.
- Verdict: MISFILED (belongs to: Orb's creative direction)
- What the record says: The rule-of-cool plan (25 features) is Medium: CLEAR or CONSTRAINT per feature, feature 12 changed, plus the two-marks stacking cap. (docs/legal/review-log.md:63)
- What is actually true: The screen and the cap of two of seven marks are recorded. Orb adopted the cap as his own rule on 2026-10-01 (vision.md:463), and stacking_lint.gd checks it during pose reviews via review.mjs, not in CI. Later rows call k01 binding, but Legal labels its screens 'not legal advice' and no law sets a mark count; the only legal point is avoiding a recognisable combination. The first-build review is still pending. Proof: vision.md:463 'Legal's stacking rule: accepted' (AC-106.txt); stacking_lint.gd is run by render/anim/tools/review.mjs; no .github workflow references it
- Cost of the false alarm: If read as law, every new VFX or Animation moment gets a legal gate for what is a design margin; the cost is mild.
- Fix: Record k01 as Orb's adopted design rule with Legal as adviser, not as a legal requirement.

#### AC-107 Close-up faces are CONDITIONAL: Protagonist direction A and the Cyborg split face must change, and the Cyborg display cluster drops its scan bars and pips and turns paler peach.
- Verdict: MISFILED (belongs to: Orb's creative direction (Art))
- What the record says: Close-up faces are CONDITIONAL: Protagonist direction A and the Cyborg split face must change, and the Cyborg display cluster drops its scan bars and pips and turns paler peach. (docs/legal/review-log.md:66-67; docs/legal/q3-screen.md:269-271)
- What is actually true: Art applied the conditions in rounds 8 and 9: a plain pale cream-peach eye with the scan bars and pips gone. Legal passed the round 9 Cyborg mask (q3-screen.md:315, RL-046 Closed), yet RL-044 and RL-045 still say Open, and Orb has parked masks. All nine rounds stay public in the repo, including round 8 with the eye Legal flagged; a scanner eye is a trope, so the harm is negligible. Proof: q3-screen.md:315 round 9 Cyborg A mask GO (AC-107.txt); closeup-directions.md:67 'The scan bars, pips and halo are gone from the eye'; git ls-files: art/concepts/closeups/rounds/round-1 to round-9 committed
- Cost of the false alarm: Two stale open rows ask Art for revisions it has already made and Legal has already passed.
- Fix: Close RL-044 and RL-045, citing RL-046 and Orb's mask ruling.

#### AC-108 The Anti-hero barrage volley gather is CONDITIONAL and must change.
- Verdict: MISFILED (belongs to: Orb's creative direction (Combat))
- What the record says: The Anti-hero barrage volley gather is CONDITIONAL and must change. (docs/legal/review-log.md:73)
- What is actually true: The condition is recorded. Combat changed the gather the same day to Legal's second option, arms apart with one forearm high and one low (wave7-first-kit.md:30, commit e7e64462 on 2026-10-01). The kit is parked and not loaded: data/combat has no kit file. RL-051 still says Open. A wind-up pose is not protectable expression. Proof: wave7-first-kit.md:30 'the arms apart, one forearm high and one low' (AC-108.txt); kit.antihero.wave7.json:3 'PARKED ... Not loaded, not hashed'. External: https://www.law.cornell.edu/uscode/text/17/102 (accessed 2026-11-07): "In no case does copyright protection ... extend to any idea"
- Cost of the false alarm: A stale open row on a change that was already made.
- Fix: Close RL-051, citing wave7-first-kit.md:30, and re-screen when the kit is built.

#### AC-109 The 'Blow for Blow' name is GO as a label. Its staging is CONDITIONAL on twelve rules (tightened 2026-10-02).
- Verdict: MISFILED (belongs to: Orb's creative direction (Combat))
- What the record says: The 'Blow for Blow' name is GO as a label. Its staging is CONDITIONAL on twelve rules (tightened 2026-10-02). (docs/legal/review-log.md:75; docs/legal/review-log.md:80; docs/legal/agency-pass-screen.md:8)
- What is actually true: The label ruling and the twelve rules are recorded. RL-058 passed the poses on paper, and RL-053 waits for a build; the two rows are consistent. No Blow for Blow set piece exists in sim, data, ui, render/core or render/vfx; only parked Animation wave scripts mention it. Two fighters trading body blows is a scene idea, and the rules keep it from echoing one famous scene, which is Orb's originality aim. Proof: git grep for blow for blow in data, sim, ui, render/core and render/vfx: no matches (AC-109.txt); agency-pass-screen.md:17: the inspiration is a well-known anime scene. External: https://www.law.cornell.edu/uscode/text/17/102 (accessed 2026-11-07): "In no case does copyright protection ... extend to any idea"
- Cost of the false alarm: Twelve rules gate a set piece with no code; the cost is low while it stays unbuilt.
- Fix: Keep the twelve rules as Combat's build checklist; a safety record is not needed.

#### AC-110 The 208 draft taunt lines are not rated. They wait on Orb's edit under an agreed lean search protocol.
- Verdict: MISFILED (belongs to: Orb's creative direction (Narrative))
- What the record says: The 208 draft taunt lines are not rated. They wait on Orb's edit under an agreed lean search protocol. (docs/legal/review-log.md:78; docs/legal/agency-pass-screen.md:43)
- What is actually true: RL-056 is open, and the protocol is written out at agency-pass-screen.md:43-48 (the inventory says it is not). The 208-row draft is committed, but no game code reads it; live barks are off and not in the /play/ pin. The pin ships 24 taunt lines from combat_barks.json, one of which also appears in the draft; I did not screen the wording. Short phrases are not copyrightable, so the real risk is a recognisable catchphrase, which Orb's originality rule already covers. Proof: taunts-draft.csv has 208 rows and is referenced by no file in data, sim, render or ui (AC-110.txt); live_barks.json enabled false and absent at 257a766c; 257a766c combat_barks.json: 24 taunt lines, 1 also in the draft. External: https://www.law.cornell.edu/cfr/text/37/202.1 (accessed 2026-11-07): "Words and short phrases such as names, titles, and slogans"
- Cost of the false alarm: Low: an open row for drafts that have not shipped.
- Fix: Keep the protocol as a Narrative step before shipping, and run it on any draft line before it moves into data.

#### AC-111 Levitating rocks are GO on conditions, motes are GO, and desaturating the world is CONDITIONAL.
- Verdict: MISFILED (belongs to: Orb's creative direction (VFX))
- What the record says: Levitating rocks are GO on conditions, motes are GO, and desaturating the world is CONDITIONAL. (docs/legal/review-log.md:79; docs/legal/review-log.md:81; docs/legal/agency-pass-screen.md:52; +1 more)
- What is actually true: The rocks are switched on at HEAD and in the /play/ pin, and they keep to the screened limits: 5 at tier 3, 10 at tier 4, never an even ring or a spiral. RL-059 says the motion re-check passed, but RL-057 still says Open. Desaturation has no code. Floating rocks and motes are genre ideas, so the conditions are originality margins. Proof: vfx_look.gd:70 ROCKS_DEFAULT true at HEAD and at 257a766c (AC-111.txt); rocks.gd:16 count_t3 5, count_t4 10; no desaturation code in data/vfx, render/vfx or render/core
- Cost of the false alarm: A stale open row on an effect that is live and conforms.
- Fix: Close RL-057, citing RL-059, and re-open it only if desaturation is built.

#### AC-112 Mines are GO: a hexagonal plate, no set of spheres, never surrounding the foe.
- Verdict: MISFILED (belongs to: Orb's creative direction (VFX))
- What the record says: Mines are GO: a hexagonal plate, no set of spheres, never surrounding the foe. (docs/legal/review-log.md:83)
- What is actually true: Mines are built and live: the sim has a MINE shot mode and the AI lays them. They are drawn as a hexagonal plate or a faceted caltrop, never a sphere, one per spot, and the same code is in the /play/ pin. So 'Open until looks exist' is stale. I did not check whether AI play can place several mines around a foe. A mine is a game idea, and the look rules are originality margins. Proof: shots.gd:27 const MINE (AC-112.txt); shots_view.gd:1839 'never a sphere (Legal, RL-062): the others' is a hexagonal plate'; 257a766c shots_view.gd:1690 has the same comment
- Cost of the false alarm: A stale open row on a look that already exists and conforms.
- Fix: Close RL-061. Add a test only if Orb wants the 'never surround' line enforced.

#### AC-113 The burning wake is CONDITIONAL: scattered embers fading in 3 s, never a solid neon line or wall that destroys on touch. The shield orb is CONDITIONAL: one faceted shield, never a smooth sphere, a set, several orbiting, seven, or one with a face or markings.
- Verdict: MISFILED (belongs to: Orb's creative direction (Game Design))
- What the record says: The burning wake is CONDITIONAL: scattered embers fading in 3 s, never a solid neon line or wall that destroys on touch. The shield orb is CONDITIONAL: one faceted shield, never a smooth sphere, a set, several orbiting, seven, or one with a face or markings. (docs/legal/review-log.md:84; docs/legal/agency-pass-screen.md:105-106; docs/legal/agency-pass-screen.md:108; +1 more)
- What is actually true: The conditions are recorded as stated. Neither kind exists: the sim's shot modes are only LINE, SEEK, LOB and MINE, and there is no wake or shield code in data, sim, render or ui (the water wake is unrelated). Ember trails and a shield bubble are genre ideas. Proof: shots.gd:24-27 LINE, SEEK, LOB, MINE (AC-113.txt); git grep for burning wake or shield orb: no matches
- Cost of the false alarm: An open row on two shot kinds that have no code.
- Fix: Keep it as a design checklist for when these kinds are built; it is not a safety record.

#### AC-114 The Protagonist sheet is CONDITIONAL: fists solid and plated, the forelock a swept tuft.
- Verdict: MISFILED (belongs to: Orb's creative direction (Art))
- What the record says: The Protagonist sheet is CONDITIONAL: fists solid and plated, the forelock a swept tuft. (docs/legal/review-log.md:91; docs/legal/agency-pass-screen.md:170; docs/legal/agency-pass-screen.md:177)
- What is actually true: The conditions are recorded. Art applied them, and Orb approved the design on 2026-10-04 with 'dark plated fists, short swept tuft' (approved.mjs:3). RL-069 still says Open until Art revises. A single curl or round fists is not protectable on its own. I did not render the SVGs. Proof: approved.mjs:3 'Approved by Orb (2026-10-04): the Protagonist (broad body, dark plated fists, short swept tuft)' (AC-114.txt); refine/README.md:15: approved turnaround 'with the Legal conditions'
- Cost of the false alarm: A stale open row on a design Orb has already approved.
- Fix: Close RL-069, citing the approved turnaround.

#### AC-115 The 36 generated moveset shapes are Clear, with conditions on rising and palm strikes, drops, spins and held heavies.
- Verdict: MISFILED (belongs to: Orb's creative direction (Combat))
- What the record says: The 36 generated moveset shapes are Clear, with conditions on rising and palm strikes, drops, spins and held heavies. (docs/legal/review-log.md:94)
- What is actually true: The conditions and the banned rows are recorded. Combat keeps Legal's file whole in the parked movegen parts.json, with a --check that fails on drift. Live recipes.json:551 cites Legal's string rules, and the sim enforces the no-two-gut-blows rule (recipe.gd:145). I did not trace every banned row into the sim. Move shapes are not protectable; the risk Legal names, a recognisable signature combination, is an originality aim. Proof: movegen/README.md:191: parts.json holds Legal's file whole and --check fails on drift (AC-115.txt); recipes.json:551 'breaks none of Legal's string rules'; recipe.gd:145 'never to the gut when noGut (Legal's rule)'. External: https://www.law.cornell.edu/uscode/text/17/102 (accessed 2026-11-07): "In no case does copyright protection ... extend to any idea"
- Cost of the false alarm: An open row with no clear meaning of 'merged' keeps the item open indefinitely.
- Fix: Say what 'merged' means and close RL-072 against the --check; keep the banned rows as Combat's lint.

#### AC-116 The five stance tells are Clear. The energy-arts lit hand and the charging aura are conditional.
- Verdict: MISFILED (belongs to: Orb's creative direction (VFX))
- What the record says: The five stance tells are Clear. The energy-arts lit hand and the charging aura are conditional. (docs/legal/review-log.md:96)
- What is actually true: The ruling is recorded as stated. The lit hand is drawn as a small hollow ring with two short streaks, never a filled disc (reach.gd:7), and Orb ruled that the charging aura is a thin outline in the game's own shapes (vision.md:463). No re-screen of a first render is on record, and I did not render one. Glowing hands and auras are genre ideas. Proof: reach.gd:7 'a small hollow ring and two short streaks forward, never a filled disc' (AC-116.txt); vision.md:463 'the charging aura is a thin outline in our own shapes'
- Cost of the false alarm: Low: a re-screen item with no deadline.
- Fix: Re-screen at the first render as planned, as a look check, not a safety item.

#### AC-117 The LT zip at 2 ticks of travel reads as a franchise technique: AVOID as built. It is CLEAR at 4 or more drawn ticks with the body visible every tick, echoes trailing behind and the far-side exit drawn.
- Verdict: MISFILED (belongs to: Orb's creative direction (VFX, Encounter))
- What the record says: The LT zip at 2 ticks of travel reads as a franchise technique: AVOID as built. It is CLEAR at 4 or more drawn ticks with the body visible every tick, echoes trailing behind and the far-side exit drawn. (docs/legal/review-log.md:98)
- What is actually true: The tick floor is set and enforced: zip.floor is minTicks 4 and bhPerTick 3 with the zip enabled, at HEAD and in the /play/ pin, and zip.gd:236-252 applies it, citing RL-076. So 'Open until VFX and Encounter set the tick floor' is stale. The drawing conditions (body visible every tick, trailing echoes, far-side exit) are render work I did not check. A fast dash or blink is a genre idea. Proof: HEAD and 257a766c: zip.enabled true, floor {minTicks 4, bhPerTick 3} (AC-117.txt); zip.gd:252 return maxi(int(c.floor.minTicks), ...); 257a766c zip.gd:250 the same. External: https://www.law.cornell.edu/uscode/text/17/102 (accessed 2026-11-07): "In no case does copyright protection ... extend to any idea"
- Cost of the false alarm: A stale open row; it may prompt VFX and Encounter to set a floor that is already in data.
- Fix: Close the floor half of RL-076 and leave the drawing half to the look gate.

#### AC-118 Zip ghosts are CONDITIONAL: flat lane colour, opacity 0.35 or less, 5 or fewer, on the real path, never a ring, gone in 8 ticks, body on top. Body ghost budget: 5 per fighter from all sources (10 on screen) is a hard gate.
- Verdict: MISFILED (belongs to: Orb's creative direction (VFX and Rendering look spec))
- What the record says: Zip ghosts are CONDITIONAL: flat lane colour, opacity 0.35 or less, 5 or fewer, on the real path, never a ring, gone in 8 ticks, body on top. Body ghost budget: 5 per fighter from all sources (10 on screen) is a hard gate. (docs/legal/review-log.md:74; docs/legal/review-log.md:99; docs/legal/review-log.md:147)
- What is actually true: These are originality look rules for afterimages, and m12 itself says the 5 is 'a bright line for the build's gate, not a legal cliff'. The budget is in code (ghost_tally.gd BUDGET 5 with enforce on; ParticleView caps after-images at AFTER_MAX 5, also at pinned 257a766c), so the inventory's 'no check' note is wrong. But Rendering's after-images start at opacity 0.5 (look.gd:811), above the 0.35 the rule requires, and RL-125 was never closed after ghost-budget.md gave the per-tick breakdown. Proof: audit/2026-11-07/evidence/AC-118.txt; render/vfx/ghost_tally.gd:18,21; render/core/look.gd:809,811
- Cost of the false alarm: Two Open Legal rows can hold a phase gate (originality-rules.md:70) over an afterimage look that the genre shares. The 0.5 opacity breach has stood unflagged, which shows nobody treats it as a legal line anyway.
- Fix: Move m05/m12 into the VFX and Rendering look spec under Orb's originality direction, and close RL-077 and RL-125. Either lower AFTER_ALPHA to 0.35 or restate the rule for outline after-images.

#### AC-119 Signature sketches are CONDITIONAL: tell poses need hands apart and the wide hip zone (8 for closed-fist transients, 14 for open hands and held poses).
- Verdict: MISFILED (belongs to: Orb's creative direction (Animation))
- What the record says: Signature sketches are CONDITIONAL: tell poses need hands apart and the wide hip zone (8 for closed-fist transients, 14 for open hands and held poses). (docs/legal/review-log.md:102)
- What is actually true: RL-080 comes from a self-described originality screen ('not legal advice'). It enforces the 'Iconic poses' grey-zone default, which originality-rules.md:43-51 leaves to Orb. The zone is in code (anim_held_lint.gd HIP_X 14, EMIT_WRIST_X 8) and gated in anim_check _test_held, which is not in ci.yml. US copyright does not protect single movements, so 8 versus 14 units is a design margin, not a legal line. Proof: audit/2026-11-07/evidence/AC-119.txt; render/anim/anim_held_lint.gd:24-25; render/anim/tools/anim_check.gd:6718-6724. External: https://www.copyright.gov/circs/circ52.pdf (US Copyright Office Circular 52, accessed 2026-11-07): "Individual movements or dance steps by themselves are not copyrightable"
- Cost of the false alarm: An Open Legal flag that blocks a phase gate (originality-rules.md:70), and Legal review spent per pose on a look margin.
- Fix: Move the rule into Animation's pose spec as Orb's originality direction, keep the lint, and retire RL-080 as a Legal row.

#### AC-120 The ten intro gestures are Clear, with conditions: pi.claim gets no crouch, aura, shake or shout, and ri.check gets no readout.
- Verdict: MISFILED (belongs to: Orb's creative direction (Animation))
- What the record says: The ten intro gestures are Clear, with conditions: pi.claim gets no crouch, aura, shake or shout, and ri.check gets no readout. (docs/legal/review-log.md:103)
- What is actually true: The conditions keep pi.claim from looking like the genre's power-up stance and ri.check from looking like a scanner readout. Both are grey-zone echoes that originality-rules.md:50-51 leaves to Orb. Both gestures are in the public pinned build's source as parked waves that play on an intro_gesture event. I did not check what is drawn live. Proof: audit/2026-11-07/evidence/AC-120.txt; docs/legal/stances-and-gestures-screen.md:24-25. External: See AC-119: US Copyright Office Circular 52 on individual movements (accessed 2026-11-07)
- Cost of the false alarm: An Open Legal flag ('until seen live') waiting on a look check that has no legal stake.
- Fix: Move the conditions into the Animation and UI look spec under Orb's direction, and retire the Legal row.

#### AC-121 The five signature frames are clear only as generic. Each fighter's version needs a person screen, with k01 applied at every tick of a 45-tick charge.
- Verdict: MISFILED (belongs to: Orb's creative direction (Combat, VFX); the 'person' wording is process)
- What the record says: The five signature frames are clear only as generic. Each fighter's version needs a person screen, with k01 applied at every tick of a 45-tick charge. (docs/legal/review-log.md:105)
- What is actually true: k01 (no more than two of seven power-up marks at any tick) is an originality stacking rule. No check enforces it; the code only mentions it in comments (reach.gd:411). The 'person' who screens is the Legal Claude session (CLAUDE.md), not a human reviewer or a lawyer. Proof: docs/legal/review-log.md:105; docs/legal/stances-and-gestures-screen.md:39; render/vfx/reach.gd:411. External: See AC-119: US Copyright Office Circular 52 (accessed 2026-11-07)
- Cost of the false alarm: A per-fighter Open flag that never closes. The word 'person' reads as human legal review that does not happen.
- Fix: Move the rule into the Combat and VFX spec under Orb's direction, and change the record to say 'Legal session screen'. If Orb wants k01 kept, write a check for it.

#### AC-122 Specials' frames and the Protagonist's three placeholders are clear only as placeholders. New grabs fall under g01-g03 on holds.
- Verdict: MISFILED (belongs to: Orb's creative direction (Combat))
- What the record says: Specials' frames and the Protagonist's three placeholders are clear only as placeholders. New grabs fall under g01-g03 on holds. (docs/legal/review-log.md:107)
- What is actually true: g01-g03 set hold points, ban laced hands and glowing hands, and require a carry to be drawn whole. Their own stated reasons are 'grip rules', 'the test-of-strength image' and 'no vanish step'. None cites a law, a rating or a platform rule. Proof: docs/legal/review-log.md:107; docs/legal/movegen-banned.json grabs g01, g02, g03. External: See AC-119: US Copyright Office Circular 52 (accessed 2026-11-07)
- Cost of the false alarm: A Legal re-screen loop before every special and every grab design.
- Fix: Move g01-g03 into the Combat and Animation spec under Orb's originality direction.

#### AC-124 The held-pose lint scope (h01-h03) is set by class. None of the 14 non-rest failures needs redrawing.
- Verdict: MISFILED (belongs to: Orb's creative direction (Animation))
- What the record says: The held-pose lint scope (h01-h03) is set by class. None of the 14 non-rest failures needs redrawing. (docs/legal/review-log.md:109)
- What is actually true: The scoped lint became a gate in 01f486df (2026-10-04, anim_check _test_held). The generated held-lint.md reports 197 held poses and 0 failures. RL-087 still reads 'Open until the lint is re-run on the scope', so the row is stale. The '14 failures' figure has no saved output and no longer matters. h01-h03 are originality pose rules. Proof: audit/2026-11-07/evidence/AC-124.txt; docs/animation/held-lint.md:3,7; render/anim/tools/anim_check.gd:6718-6724
- Cost of the false alarm: A stale Open Legal row that can hold a phase gate (originality-rules.md:70) after the condition was met.
- Fix: Close RL-087 citing 01f486df, and move h01-h03 into Animation's spec under Orb's direction.

#### AC-125 The re-laid city and seven landmarks pass, with a crown tower nudge (short corner stubs, not pale horns) under w03.
- Verdict: MISFILED (belongs to: Orb's creative direction (Art, World))
- What the record says: The re-laid city and seven landmarks pass, with a crown tower nudge (short corner stubs, not pale horns) under w03. (docs/legal/review-log.md:149)
- What is actually true: The 'not pale horns' nudge guards against echoing a franchise villain's silhouette. w03's own reason calls the horns reading 'a recommendation, not a condition'. RL-144 (review-log.md:166) records 'RL-127 closed', yet RL-127's row still reads 'Open until redrawn'. I did not inspect the drawn city. Proof: audit/2026-11-07/evidence/AC-125.txt; docs/legal/review-log.md:166
- Cost of the false alarm: A stale Open row, and a recommendation carried as a gating condition.
- Fix: Mark RL-127 Closed per RL-144, and move w03's look items into the Art and World spec. Only the real-landmark-likeness item stays with Legal.

#### AC-126 Brawl A: shove and clinch are clear. The tackle is conditional and must be seen drawn (coil, carry, crater).
- Verdict: MISFILED (belongs to: Orb's creative direction (Game Design, Animation))
- What the record says: Brawl A: shove and clinch are clear. The tackle is conditional and must be seen drawn (coil, carry, crater). (docs/legal/review-log.md:120)
- What is actually true: The tackle's conditions are hold points, a drawn carry, a local crater without the rubble-ring and aura stack, and a coil that is not the clenched-fist crouch (brawl-screen.md:29). All are originality stacking and pose rules, and none cites a legal basis. Proof: docs/legal/brawl-screen.md:29. External: See AC-119: US Copyright Office Circular 52 (accessed 2026-11-07)
- Cost of the false alarm: An Open Legal row that waits on a drawn look.
- Fix: Move the conditions into the Game Design and Animation spec under Orb's originality direction.

#### AC-127 Brawl B recast is conditional: one open or blade hand, a varied flurry, thin lane-colour flashes (k03), a straight steered beam (e07), and tell poses seen drawn.
- Verdict: MISFILED (belongs to: Orb's creative direction (VFX, Combat); flash safety belongs to Accessibility)
- What the record says: Brawl B recast is conditional: one open or blade hand, a varied flurry, thin lane-colour flashes (k03), a straight steered beam (e07), and tell poses seen drawn. (docs/legal/review-log.md:121)
- What is actually true: k03's own stated reason is the stacking marks (originality), not seizures, and e07 bars the 'drilling and whipping beams'. Flash safety for these flashes goes through the separate flash register: the code asks it before drawing (shots_view.gd:955, reach.gd:477). So k03 is not the safety control. Proof: docs/legal/review-log.md:121; docs/legal/movegen-banned.json k03, e07; render/vfx/shots_view.gd:955. External: See AC-119: US Copyright Office Circular 52 (accessed 2026-11-07)
- Cost of the false alarm: Readers may assume an originality row covers flash safety, when that is the flash gate's job.
- Fix: Move the conditions into the VFX and Combat look spec, and leave flash safety with the flash gate.

#### AC-128 Charged X and Y and the power attacks are conditional on chamber and flash rules. The breaker gets lit plate edges only, and the seize gets no glow in a hold.
- Verdict: MISFILED (belongs to: Orb's creative direction (Game Design, VFX))
- What the record says: Charged X and Y and the power attacks are conditional on chamber and flash rules. The breaker gets lit plate edges only, and the seize gets no glow in a hold. (docs/legal/review-log.md:122)
- What is actually true: The screen sets an arm drawn back at shoulder height with no open hand at the hip (L6), lit plate or knuckle edges for the breaker with k03 on its tell, and no glow at the hands in the seize, after g02's test-of-strength image. The 'flash rules' are k03's look rule. No law or flash standard is involved. Proof: docs/legal/brawl-screen.md:40; docs/legal/brawl-screen.md:49-50. External: See AC-119: US Copyright Office Circular 52 (accessed 2026-11-07)
- Cost of the false alarm: An Open Legal row whose 'flash' wording can be mistaken for a photosensitivity condition.
- Fix: Move the conditions into the Game Design and VFX spec under Orb's direction, and replace 'flash rules' in the row with k03.

#### AC-129 Even mash, gamble taunt, zip chase and chains, and the LT+RB hybrid are clear or conditional (m09-m11, f01-f03). The hybrid's tell must be seen drawn first.
- Verdict: MISFILED (belongs to: Orb's creative direction (Combat, VFX))
- What the record says: Even mash, gamble taunt, zip chase and chains, and the LT+RB hybrid are clear or conditional (m09-m11, f01-f03). The hybrid's tell must be seen drawn first. (docs/legal/review-log.md:123)
- What is actually true: m09-m11 ban a flicker-teleport barrage, a snap to the landing spot and the appear-behind beat. f01 bans the many-armed barrage blur. Their stated reasons are franchise images, not law. f01's caps are in code (ghost_tally.gd LIMB_MAX 2, LIMB_ALL_MAX 4). I did not check the hybrid's tell as drawn. Proof: docs/legal/movegen-banned.json m09, m10, m11, f01; render/vfx/ghost_tally.gd:16-17. External: See AC-119: US Copyright Office Circular 52 (accessed 2026-11-07)
- Cost of the false alarm: An Open Legal row waiting on a drawn tell.
- Fix: Move the rules into the Combat and VFX spec under Orb's originality direction, and keep the f01 caps in code.

#### AC-130 Three-strength movesets: PASS for four drives and the 20 heavies. The heave and fall drives must be seen drawn first.
- Verdict: MISFILED (belongs to: Orb's creative direction (Combat, Animation))
- What the record says: Three-strength movesets: PASS for four drives and the 20 heavies. The heave and fall drives must be seen drawn first. (docs/legal/review-log.md:124)
- What is actually true: D4 and D5 bar the clenched-fist crouch, the scream, the aura, ground cracking and a two-handed fall for the heave and fall drives. These are originality pose rules with no legal basis cited. I did not check whether the drives are now drawn. Proof: docs/legal/review-log.md:124; docs/combat/proposals/review-sheet.md D4, D5. External: See AC-119: US Copyright Office Circular 52 (accessed 2026-11-07)
- Cost of the false alarm: An Open Legal row ('until drawn') on pose margins.
- Fix: Move D4 and D5 into the Combat and Animation spec under Orb's originality direction.

#### AC-131 Stand-ins, the burst and the flurry study: the double hammer, double palm and ram gathers are re-judged, and f01 is restated by instant (new f04 and f05). Nudges are owed: double-hammer hands to shoulder width, the ram's gather one forearm only.
- Verdict: MISFILED (belongs to: Orb's creative direction (Animation, Combat))
- What the record says: Stand-ins, the burst and the flurry study: the double hammer, double palm and ram gathers are re-judged, and f01 is restated by instant (new f04 and f05). Nudges are owed: double-hammer hands to shoulder width, the ram's gather one forearm only. (docs/legal/review-log.md:125; docs/legal/review-log.md:126; docs/legal/review-log.md:127; +1 more)
- What is actually true: RL-106 (Closed) accepted the hammer and ram crops at 22 and 25.9/31.0 apart, which met RL-105's nudges. RL-103 to RL-105 still read Open, so those rows are stale. All of these are originality pose and flurry margins (B1, f01, f04, f05). Proof: audit/2026-11-07/evidence/AC-131.txt; docs/legal/review-log.md:127-128. External: See AC-119: US Copyright Office Circular 52 (accessed 2026-11-07)
- Cost of the false alarm: Three stale Open Legal rows that can hold a phase gate (originality-rules.md:70).
- Fix: Close RL-103 to RL-105 against RL-106, and move the margins into Animation's spec under Orb's direction.

#### AC-132 Super-heavy key sets: PASS 10 and NUDGE 6 (no follow-through arms raised above the head, no hands together on the ball heave).
- Verdict: MISFILED (belongs to: Orb's creative direction (Animation))
- What the record says: Super-heavy key sets: PASS 10 and NUDGE 6 (no follow-through arms raised above the head, no hands together on the ball heave). (docs/legal/review-log.md:129; docs/legal/review-log.md:134)
- What is actually true: RL-107 still reads 'Open until nudges drawn', but RL-112 (review-log.md:134) closed all six nudges, so RL-107 is stale. The nudges themselves are originality pose margins. Proof: audit/2026-11-07/evidence/AC-132.txt. External: See AC-119: US Copyright Office Circular 52 (accessed 2026-11-07)
- Cost of the false alarm: A stale Open Legal row after its nudges were passed.
- Fix: Close RL-107 citing RL-112, and move the pose margins into Animation's spec.

#### AC-133 Launcher and energy in reach: PASS with conditions. The launcher adds no new shape, and bolts and blasts need their contact and shot seen drawn.
- Verdict: MISFILED (belongs to: Orb's creative direction (Combat, VFX))
- What the record says: Launcher and energy in reach: PASS with conditions. The launcher adds no new shape, and bolts and blasts need their contact and shot seen drawn. (docs/legal/review-log.md:131)
- What is actually true: e08 (R1) requires one lit hand edge at shoulder height or lower, a shot that is a thin edge or short cone and never a ball, and a rim rather than a body-wide flash. These are originality look rules. I did not check whether the bolts and blasts are drawn. Proof: docs/legal/review-log.md:131; docs/legal/movegen-banned.json e08. External: See AC-119: US Copyright Office Circular 52 (accessed 2026-11-07)
- Cost of the false alarm: An Open Legal row waiting on drawn energy looks.
- Fix: Move e08 into the Combat and VFX spec under Orb's originality direction.

#### AC-134 Roster sketches (Press, Courier, Hopper, Empress): row 48 'both arms' contradicts D5; Hopper's hop limited to knee or foot to gut, chest or legs (b14); grabs and the mantle screened when drawn.
- Verdict: MISFILED (belongs to: Orb's creative direction (Combat))
- What the record says: Roster sketches (Press, Courier, Hopper, Empress): row 48 'both arms' contradicts D5; Hopper's hop limited to knee or foot to gut, chest or legs (b14); grabs and the mantle screened when drawn. (docs/legal/review-log.md:155 (HEAD))
- What is actually true: The row-48 correction is done: no sheet under docs/combat still labels the falling palm '(both arms)', and the row now carries D5 (roster review-sheet.md:807, 1973). b14 is a banned row that the generator refuses. All three items are originality pose rules. The stomp's ratings point in the same screen is a separate matter. Proof: audit/2026-11-07/evidence/AC-134.txt; docs/combat/pending/roster/review-sheet.md:807. External: See AC-119: US Copyright Office Circular 52 (accessed 2026-11-07)
- Cost of the false alarm: An Open row still names a correction that was already applied.
- Fix: Record the row-48 correction as done in RL-133, and move b14 and the grab and mantle screens into the Combat spec under Orb's direction.

#### AC-136 Art's hybrid picks pass with a plain ring, no orange-over-blue, folded arms per h09, an aura without strobing and steady dummy squares, to be confirmed on the turnarounds.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality), via Art; flash sub-points to Accessibility/VFX)
- What the record says: Art's hybrid picks pass with a plain ring, no orange-over-blue, folded arms per h09, an aura without strobing and steady dummy squares, to be confirmed on the turnarounds. (docs/legal/review-log.md:173 (HEAD))
- What is actually true: The ring, colour and folded-arms points keep unbuilt art away from a franchise's look, which is Orb's originality direction. The live Protagonist is blue with teal hair and has no orange. The flash points are real but already enforced: the worn aura drops out at most once per 40 ticks (1.5 a second per fighter) and holds steady under Reduce flashing, which is locked on in /play/. Proof: 257a766c:data/fighters/PROTAGONIST/fighter.json:8; 257a766c:render/vfx/react.gd:106-119; docs/legal/homework8-review-screen.md:41-60
- Cost of the false alarm: A Legal store record stays open until turnarounds arrive that Legal may never receive. That adds screening work for points no law requires.
- Fix: Move the ring, colour and pose points to Art's originality checklist under Orb. Leave the aura and dummy flicker points in the flash register, which already enforces them.

#### AC-137 Finisher styles (Open Palm, Held Breath, Both Roads): the offered hand is not a beckon and the raised hand is at shoulder height or lower (h10); the aura rework and h10 clips were never received.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality), Animation/Art)
- What the record says: Finisher styles (Open Palm, Held Breath, Both Roads): the offered hand is not a beckon and the raised hand is at shoulder height or lower (h10); the aura rework and h10 clips were never received. (docs/legal/review-log.md:181 (HEAD); docs/legal/review-log.md:189 (HEAD))
- What is actually true: The finisher poses landed in b36f5fe6 on 2026-10-22, after the live pin 257a766c of 2026-10-19, so only private builds have them. The generator already encodes h10: Open Palm one hand at hip height or lower, Both Roads at or below 82. A beckon or a raised hand is a question of looking like a franchise, not of law. The missing clips are a process gap. Proof: 8d9b98a2:render/anim/tools/waves/fin1.mjs:3-5; 8d9b98a2:data/anim/waves/fin1.poses.json; evidence/AC-137.txt
- Cost of the false alarm: Two open Legal rows (RL-159 and RL-167) keep Art and VFX in a screening loop for an originality rule.
- Fix: Move h10 to Animation/Art's originality checklist under Orb's direction. Close RL-167 as a process item.

#### AC-138 Energy overhaul and four kits pass with conditions: e11-e13 and fx08, kit poses (no hip wind-up, no crown on the palm, no thin disc), red read by the analyser, the barrage capped at 3 white bursts a second (e15, fx09), grab call-outs once per grab (ln06), 29 legalAsks (e16).
- Verdict: MISFILED (belongs to: Orb's creative direction (originality) / Combat; flash sub-points Accessibility)
- What the record says: Energy overhaul and four kits pass with conditions: e11-e13 and fx08, kit poses (no hip wind-up, no crown on the palm, no thin disc), red read by the analyser, the barrage capped at 3 white bursts a second (e15, fx09), grab call-outs once per grab (ln06), 29 legalAsks (e16). (docs/legal/review-log.md:199 (HEAD); docs/legal/review-log.md:201 (HEAD); docs/legal/review-log.md:202 (HEAD))
- What is actually true: The kits from 2c954dfa exist only in docs/combat/pending/energy, and docs/* is left out of every export, so no kit data ships. The pose and shape points are originality rules. The flash points are real, but the shipped register already refuses red and grants the barrage one flash of at most 0.5 weight. I did not run an export to check switches; I only confirmed no kit data sits under data/. Proof: git show --stat 2c954dfa; 8d9b98a2:export_presets.cfg exclude_filter; 8d9b98a2:render/vfx/shots_view.gd:1239
- Cost of the false alarm: A High-ranked open store record makes parked design paper look like a blocker and ties up repeated Legal screens.
- Fix: Split the record: the flash points go to the flash register (already met), the pose and name points to Orb's originality checklist. Reopen only when kit data lands in data/.

#### AC-143 Movegen allows 'ball of the foot' as anatomy only, never in a title or beside an energy word, with 'ball' alone banned (n01); the proposals screen (about 330 KB) is not done.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality) / Combat / Tools)
- What the record says: Movegen allows 'ball of the foot' as anatomy only, never in a title or beside an energy word, with 'ball' alone banned (n01); the proposals screen (about 330 KB) is not done. (docs/legal/review-log.md:220 (HEAD))
- What is actually true: The rule exists. The movegen and the 331,275-byte proposals live only under docs/ (pending/movegen and proposals), which is left out of every export, so nothing ships. Banning 'ball' keeps away from a well-known franchise's ball device and energy-ball image. That is Orb's originality direction, not a legal requirement. Proof: 8d9b98a2:docs/legal/movegen-banned.json:875; git ls-tree -r -l 8d9b98a2 docs/combat/proposals; evidence/AC-143.txt
- Cost of the false alarm: An open Legal store row asks for a generated 330 KB screen with its own brief, which is work no law needs.
- Fix: Move the banned-word list into Combat/Tools' movegen lint under Orb's originality rules, and retire the proposals screen as a Legal item.

#### AC-144 Beam answers 1: no aim assist toward towns, and the AI swats by terrain and buildings, never people; catch and block use one plated forearm (Grist's flat palm is out as the genre's own picture); the Cyborg 'eat it' as pitched is refused; Hem Sweep never splits round a body; c09 places give no cover.
- Verdict: MISFILED (belongs to: Orb's creative direction / Game Design)
- What the record says: Beam answers 1: no aim assist toward towns, and the AI swats by terrain and buildings, never people; catch and block use one plated forearm (Grist's flat palm is out as the genre's own picture); the Cyborg 'eat it' as pitched is refused; Hem Sweep never splits round a body; c09 places give no cover. (docs/legal/review-log.md:253 (HEAD))
- What is actually true: The page is paper, and Orb has since replaced it with beam-answers-2.md. The swat already ships, in the live pin and at HEAD. Its direction follows a fixed rule (sky, nearest standing building or ground) and reads no people. The sim has no school, hospital or place-of-worship building type, so c09 binds nothing. The forearm, eat-it and Hem Sweep points are originality and tone rules. Proof: 8d9b98a2:sim/director/beamplay.gd:488-533; 257a766c:sim/director/beamplay.gd:269; docs/design/beam-answers.md:3
- Cost of the false alarm: A store record stays open 'until built and the look gate and held-pose lint are read', over design paper that has since been replaced.
- Fix: Move the record to Game Design under Orb's pillar 5 and originality direction. If QA wants it, add a sim test that the swat never reads people.

#### AC-145 RT power-up: ground and sky count as one mark; 'the sky opens' must change (no round pale disc over his head, no light from heaven); townspeople stop and look and never flee, fall or get hurt, with no camera shake; pose stills and a 1,050-tick held-pose test come before live.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality) / VFX)
- What the record says: RT power-up: ground and sky count as one mark; 'the sky opens' must change (no round pale disc over his head, no light from heaven); townspeople stop and look and never flee, fall or get hurt, with no camera shake; pose stills and a 1,050-tick held-pose test come before live. (docs/legal/review-log.md:262 (HEAD))
- What is actually true: The RT power-up is paper only: no 'sky opens', 'takes notice' or power-up pose code exists in render, sim, data or ui. The disc, light-from-heaven and mark-count points keep away from a well-known franchise scene. The no-flee point follows pillar 5's menace rule, and the camera-shake point is a comfort choice. Proof: docs/vfx/power-up-ideas.md:1; git grep in 8d9b98a2 render sim data ui (none); evidence/AC-145.txt
- Cost of the false alarm: An open store record waits on stills and a 1,050-tick test for a feature nobody has built.
- Fix: Move it to VFX/Animation under Orb's originality direction. If the feature is built, the flash register and the motion options cover the safety side.

#### AC-153 The Anti-hero's aura moved from red-orange to the orchid lane and must stay in the violet range; amber is not Legal-safe. Last stand B and the bravado line are clear.
- Verdict: MISFILED (belongs to: Orb's creative direction (Art palette); Legal log hygiene)
- What the record says: The Anti-hero's aura moved from red-orange to the orchid lane and must stay in the violet range; amber is not Legal-safe. Last stand B and the bravado line are clear. (docs/legal/review-log.md:64; docs/ep/orb-review-list.md:27)
- What is actually true: The data change RL-042 waits for has happened: the RIVAL aura is #9a80d8 (a violet, L* 59) in HEAD, the LAN build a8bc66e2 and the live pin 257a766c, yet the row still reads 'Open until the data changes'. Violet versus amber is an originality look choice (avoiding the genre's golden aura); no record gives a legal basis for 'amber is not Legal-safe'. Proof: docs/legal/review-log.md:64; docs/ep/orb-review-list.md:27; data/fighters/RIVAL/fighter.json:8 at HEAD, a8bc66e2 and 257a766c
- Cost of the false alarm: An Open Legal row and an open item on Orb's review list keep a settled colour choice in the safety backlog.
- Fix: Close RL-042 as met by data; move the violet-range note to Art's palette rules as Orb's creative direction.

#### AC-157 Bundle of Low/GO/Closed Q3 design screens: RL-026 (Overcommit, Rail chip, Stylus tail) and RL-033 (Anti-hero pride options).
- Verdict: MISFILED (belongs to: Orb's creative direction (originality), Legal advising)
- What the record says: Bundle of Low/GO/Closed Q3 design screens: RL-026 (Overcommit, Rail chip, Stylus tail) and RL-033 (Anti-hero pride options). (docs/legal/review-log.md:48; docs/legal/review-log.md:55; docs/legal/q3-screen.md:55)
- What is actually true: Both rows are Low/GO/Closed, and q3-screen.md:55 adds a condition the table hides (the Rail chip never inside a translucent sphere). No Rail chip or Stylus tail exists in game data or code ('overcommit' appears only as an unrelated animation flag). These are originality shape rules, not release safety. Proof: docs/legal/review-log.md:48, 55; docs/legal/q3-screen.md:53-55; git grep rail chip / stylus in data, sim, render, ui: no hits
- Cost of the false alarm: Small: design-shape conditions sit in the safety log, where the hidden Rail-chip condition is easy to miss.
- Fix: Move the Q3 shape conditions to Art's originality checklist and quote the Rail-chip condition in the log row.

#### AC-158 Bundle of Low/Closed pose and move originality screens with minor pose conditions: RL-048, RL-049, RL-050, RL-054, RL-055, RL-058, RL-063 (air roll never a spinning ball), RL-064 (no flat cross, no head thrown back), RL-065, RL-067, RL-075, RL-079, RL-082, RL-108, RL-112.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality), Animation)
- What the record says: Bundle of Low/Closed pose and move originality screens with minor pose conditions: RL-048, RL-049, RL-050, RL-054, RL-055, RL-058, RL-063 (air roll never a spinning ball), RL-064 (no flat cross, no head thrown back), RL-065, RL-067, RL-075, RL-079, RL-082, RL-108, RL-112. (docs/legal/review-log.md:70-72; docs/legal/review-log.md:76-77; docs/legal/review-log.md:80; +7 more)
- What is actually true: All 15 rows read Low and Closed with pose conditions, and RL-082 (review-log.md:104) closes RL-079's full-size look. They are originality pose margins from Legal's held rows, partly enforced by AnimHeldLint (render/anim/anim_held_lint.gd:3, 23-30), not release-safety matters. Proof: docs/legal/review-log.md:70-72, 76-77, 80, 85-87, 89, 97, 101, 104, 130, 134; render/anim/anim_held_lint.gd:3, 23-30; evidence/AC-158.txt
- Cost of the false alarm: Fifteen look rows inflate the safety record and make Legal a gate for Animation's taste work.
- Fix: File the pose conditions as Animation's originality rules (the held lint is their test); keep Legal as adviser.

#### AC-159 Bundle of Low/Closed art, VFX and narrative looks: RL-040 landmarks (light conditions), RL-043 narrative placeholders, RL-046 guard arc and Cyborg A mask, RL-052 dash afterimage (three constraints), RL-068 glasses (D avoid), RL-070 rival sheet, RL-118 double-hit marks.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality and look))
- What the record says: Bundle of Low/Closed art, VFX and narrative looks: RL-040 landmarks (light conditions), RL-043 narrative placeholders, RL-046 guard arc and Cyborg A mask, RL-052 dash afterimage (three constraints), RL-068 glasses (D avoid), RL-070 rival sheet, RL-118 double-hit marks. (docs/legal/review-log.md:62; docs/legal/review-log.md:65; docs/legal/review-log.md:68; +4 more)
- What is actually true: The seven rows are Low and Closed and concern originality of landmarks, placeholder text, the guard arc and mask, the dash afterimage, glasses, the rival sheet and hit marks. RL-118 judges marks on fighters under a franchise-look row (k04), while the ban on markers over fighters is Orb's own look rule (ADR 0010); neither is release safety. Proof: docs/legal/review-log.md:62, 65, 68, 74, 90, 92, 140; docs/legal/movegen-banned.json stacking k04; evidence/AC-159.txt
- Cost of the false alarm: Look reviews carried as safety sign-offs.
- Fix: Move to Art's and VFX's originality checklists; keep ADR 0010 as the look gate.

#### AC-160 Agency 15.1-15.4 (explosions, wild deflect, buildings, spray cone) is GO with look rules.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality), Game Design and VFX)
- What the record says: Agency 15.1-15.4 (explosions, wild deflect, buildings, spray cone) is GO with look rules. (docs/legal/review-log.md:82)
- What is actually true: The log row omits them, but the look rules are written in agency-pass-screen.md:110-116 (a local flame column, never a sky pillar or a mushroom cloud staged like a known scene, no real landmark as a target, no palms-pumping or scream). They are originality rules, so the inventory's 'look rules are not stated' is wrong; flash limits for explosions are a separate matter, not part of this row. Proof: docs/legal/review-log.md:82; docs/legal/agency-pass-screen.md:92-101, 110-116; evidence/AC-160.txt
- Cost of the false alarm: It invites a hunt for unstated flash or collateral limits that this row never carried.
- Fix: Point RL-060 at agency-pass-screen.md section 15 and file the rules as originality looks.

#### AC-161 Stick-class poses: chambers stay under 80 beside the head with no glow or scream (h05), the rival keeps no palm, forward hands are flat blades and never beckon (h07), head targets never land on a downed foe (s09), and fire_back stays short of arms wide (h02).
- Verdict: MISFILED (belongs to: Orb's creative direction (originality), Animation; s09 to Legal (ratings))
- What the record says: Stick-class poses: chambers stay under 80 beside the head with no glow or scream (h05), the rival keeps no palm, forward hands are flat blades and never beckon (h07), head targets never land on a downed foe (s09), and fire_back stays short of arms wide (h02). (docs/legal/review-log.md:240 (HEAD))
- What is actually true: The stick class ships in the LAN build a8bc66e2 (7de33ae4), not the live pin. The five named drop pieces target the chest, so s09 holds by data; but flick_rise and lift_fist target the jaw, so RL-218's 'all land on the chest' is loose. The h-row conditions are originality pose margins; only s09 is a ratings matter, and its basis is real (PEGI 18 wording). Proof: docs/legal/review-log.md:240; data/anim/waves/protag13.manifest.json and rival10.manifest.json strike targets; docs/legal/movegen-banned.json bannedSequences s09. External: https://pegi.info/what-do-the-labels-mean (accessed 2026-11-07): "violence towards defenceless characters"
- Cost of the false alarm: Pose taste is carried as a store-horizon legal condition with a full-size-look gate before live.
- Fix: File the h-row conditions as Animation's originality lint; keep s09 as a ratings rule with a data test (no head target on a downed foe); correct RL-218's 'all land on the chest'.

#### AC-162 Flight strikes: the tilt is never a head-first dive or somersault, nothing targets the head, leg hits never trap a limb, the Anti-hero has no open hand, and holds stay within h05.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality), Animation)
- What the record says: Flight strikes: the tilt is never a head-first dive or somersault, nothing targets the head, leg hits never trap a limb, the Anti-hero has no open hand, and holds stay within h05. (docs/legal/review-log.md:464 (HEAD))
- What is actually true: The row is RL-250 at review-log.md:272 (the inventory's :464 is wrong). The flight-strike poses landed in a8bc66e2, the LAN build, although the patch still sits in docs/animation/pending/, so 'not shipped' is wrong for private builds. The four blows target legs and chest, so 'nothing targets the head' holds by data; the tilt, hand and hold conditions are originality pose margins. Proof: docs/legal/review-log.md:272; git log -- docs/animation/flight-strikes.md: a8bc66e2; data/anim/waves/protag14.manifest.json and rival11.manifest.json targets
- Cost of the false alarm: A pose-taste condition is held as a store-horizon legal gate, and the stale pending folder misstates what shipped.
- Fix: File as Animation's originality conditions; remove the stale flight-strikes.patch from pending; fix the record's source line.

#### AC-163 Air-brake: the plant is a brake and never a chamber, lowering within 5 ticks; the Anti-hero keeps no open hand; the sweep stays under 32 in depth; the landing arm is a guard, never a beckon. A full-size look with hands and the longest-brake number are owed before it goes live.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality), Animation)
- What the record says: Air-brake: the plant is a brake and never a chamber, lowering within 5 ticks; the Anti-hero keeps no open hand; the sweep stays under 32 in depth; the landing arm is a guard, never a beckon. A full-size look with hands and the longest-brake number are owed before it goes live. (docs/legal/review-log.md:469 (HEAD))
- What is actually true: The row is RL-255 at review-log.md:277 (the inventory's :469 is wrong). The air-brake looks are not committed (no docs/animation/air-brake-looks.md, no ax.* poses in data), and the sim's air brake is off in HEAD and a8bc66e2 (data/fight/brake.json:4). The conditions are originality pose margins plus owed checks before it goes live. Proof: docs/legal/review-log.md:277; data/fight/brake.json:4 at HEAD and a8bc66e2; git ls-files docs/animation/air-brake-looks.md: none
- Cost of the false alarm: Look checks for an unbuilt, switched-off feature sit in the safety record as owed items.
- Fix: File as Animation's originality conditions on the parked patch; drop it from the safety record.

#### AC-164 Orza's gold is a thin rim line only (never fill or core), and her aura is moss with the core at most L* 86; a burning trail that reads as flame on the body counts as stacking mark 3 under the two-marks cap.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality), Art and VFX)
- What the record says: Orza's gold is a thin rim line only (never fill or core), and her aura is moss with the core at most L* 86; a burning trail that reads as flame on the body counts as stacking mark 3 under the two-marks cap. (docs/legal/review-log.md:243 (HEAD); docs/legal/review-log.md:244 (HEAD))
- What is actually true: Orza is not on the roster: data/fighters holds only PROTAGONIST, RIVAL and REFERENCE, and data/vfx/meteor.json:143 says she is 'not on the roster'. Her rim (#c9a227) and moss palette sit in data. The L* 86 cap is a project figure (#dfe8a8 computes to L* 90.0, against the record's 'about 89'); the gold, moss and mark-3 rules avoid the genre's transformation look, which is originality. Proof: docs/legal/review-log.md:243-244; data/vfx/meteor.json:142-152; data/art/flashes.json:148-151
- Cost of the false alarm: Look rules for an unbuilt fighter add to the safety record and the look-gate queue.
- Fix: Move to Art's and VFX's originality rules for the Empress kit; drop it from the safety record.

#### AC-165 The Driver: the charge look is steady (no pulse over 1 Hz), shots are never a sphere, disc or column, the recoil is brief with no arms wide, and level-2 aims score fighters, buildings and terrain, never people or c09 places.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality); Game Design for the level-2 targeting rule)
- What the record says: The Driver: the charge look is steady (no pulse over 1 Hz), shots are never a sphere, disc or column, the recoil is brief with no arms wide, and level-2 aims score fighters, buildings and terrain, never people or c09 places. (docs/legal/review-log.md:247 (HEAD))
- What is actually true: The Driver exists (sim/director/driver.gd, first commit 6c492086) but is switched off in HEAD and the LAN build and is absent from the live pin; its code has no level-2 bounce, pierce or ground-line aims. The pulse cap, shot shapes and recoil are originality look rules in RL-225's charge-look clause, not flash rules. Only the 'never score people or c09 places' part touches ratings and Pillar 5, and nothing is built for it yet. Proof: docs/legal/review-log.md:247; sim/director/driver.gd:1-30; data/director/interrupts.json blast.driver.enabled false at HEAD and a8bc66e2
- Cost of the false alarm: Look rules for a switched-off feature are carried as store-horizon safety conditions.
- Fix: File the look parts as originality rules; give the no-people targeting rule to Game Design's level-2 spec with a test before it is built.

#### AC-166 Bundle (Low, Closed, pass): RL-142, Animation's eight pieces and beam casts pass; RL-038 closed (no wrist grip, e10); the launch opening is a 7-tick reaction.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality), Animation)
- What the record says: Bundle (Low, Closed, pass): RL-142, Animation's eight pieces and beam casts pass; RL-038 closed (no wrist grip, e10); the launch opening is a 7-tick reaction. (docs/legal/review-log.md:164 (HEAD))
- What is actually true: The RL-142 row reads Low, Pass, Closed, and energy-and-pieces-screen.md:17 records RL-038 closed because the cast has no wrist grip (the e10 row). These are originality pose checks. The 7-tick launch opening was not checked in data. Proof: docs/legal/review-log.md:164; docs/legal/energy-and-pieces-screen.md:17; docs/legal/movegen-banned.json energy e10
- Cost of the false alarm: Small: a closed look pass counted as a safety sign-off.
- Fix: File as Animation's originality record.

#### AC-171 1,800 civilians and the CIVILIANS LOST count pass in game, with a rule never to show the count above zero in public (w02).
- Verdict: MISFILED (belongs to: Orb's creative direction; UI)
- What the record says: 1,800 civilians and the CIVILIANS LOST count pass in game, with a rule never to show the count above zero in public (w02). (docs/legal/review-log.md:151; docs/legal/review-log.md:154; render/core/hud.gd:66 (HEAD); +1 more)
- What is actually true: pop0 is 1,800, and the live /play/ build shows 'Civilians lost: n of 1800' on the pause screen and the results card. hud.gd:66 draws its line only in the F2 legacy HUD. w02 was withdrawn on 2026-10-12 (RL-132 and the withdrawn list), so the record's rule is not in force. Whether to show a count at all is Orb's call ("no death counters", vision.md:1585), which waits on the RL-247 hold. Proof: audit/2026-11-07/evidence/AC-171.txt; ui/hud/ui_hud.gd:1716-1724 (257a766c); docs/legal/movegen-banned.json:647-650
- Cost of the false alarm: The row keeps a withdrawn public-screenshot rule marked Open, while nobody flags that the live count conflicts with Orb's later 'no death counters' direction.
- Fix: Correct RL-129: w02 is withdrawn, and the amendment pasted on it is generic. After Orb's RL-247 follow-up, send removing the count to UI. Survey honesty stays under AC-170.

#### AC-173 RL-247 (not committed): Orb's bystander-comedy decisions (bystanders bounce harmlessly, hostile soldiers vaporized, no death counter, no children) sit under a HOLD: nothing is briefed, built or changed until Orb's follow-up; predicted ESRB Teen, PEGI 12, USK 12.
- Verdict: MISFILED (belongs to: process (EP record-keeping); Orb's creative direction)
- What the record says: RL-247 (not committed): Orb's bystander-comedy decisions (bystanders bounce harmlessly, hostile soldiers vaporized, no death counter, no children) sit under a HOLD: nothing is briefed, built or changed until Orb's follow-up; predicted ESRB Teen, PEGI 12, USK 12. (docs/legal/review-log.md:269 (working copy, uncommitted); docs/legal/review-log.md:463,465 (HEAD, cite 'the RL-247 hold'))
- What is actually true: RL-247 exists only in the uncommitted working copy, next to the untracked bystander-comedy-screen.md, yet committed rows (HEAD :463, :465) cite 'the RL-247 hold'. At HEAD, RL-248 to RL-255 sit after the Sources section. Orb's 2026-11-02 bystander decisions are not in vision.md. The predicted tiers cite no board source. Proof: audit/2026-11-07/evidence/AC-173.txt
- Cost of the false alarm: A hold that nobody can read in the public repo blocks bystander, toll and UI work, and committed rulings depend on it. The predicted tiers could be quoted as settled.
- Fix: The EP commits RL-247 and its screen, moves the rows back inside the table, and records Orb's decisions in vision.md. Label the tiers as predictions until the survey result replaces them.

#### AC-180 Pass-Through (civilians become food) is CONDITIONAL: no beam or zap, people walk or are pulled through, sandwiches come from a machine, frames are mechanical. Store and mobile content ratings are unchecked and must be confirmed before submission. Its replacement, Press, is GO with two conditions (mechanical, no victim transformed in place; sandwiches, not sweets).
- Verdict: MISFILED (belongs to: Orb's creative direction (originality); Legal record)
- What the record says: Pass-Through (civilians become food) is CONDITIONAL: no beam or zap, people walk or are pulled through, sandwiches come from a machine, frames are mechanical. Store and mobile content ratings are unchecked and must be confirmed before submission. Its replacement, Press, is GO with two conditions (mechanical, no victim transformed in place; sandwiches, not sweets). (docs/legal/review-log.md:49; docs/legal/review-log.md:53; docs/legal/q3-screen.md:45-51; +2 more)
- What is actually true: q3-screen.md sets Pass-Through's conditions on franchise-echo grounds, and lines 110 and 136 replace it with Press (GO), yet RL-027 is still Open and on the P0 open-flag list. Neither is built. Orb's later lore lock (vision.md:1585, RL-220) has the Cyborg ignore civilians. The ratings note is the general survey duty (AC-170), and mobile is parked. Proof: docs/legal/q3-screen.md:45-51; docs/legal/q3-screen.md:136; docs/legal/review-log.md:49
- Cost of the false alarm: A stale, Open P0 flag keeps a dead design on the gate list.
- Fix: Close RL-027 as superseded and keep originality under Legal's IP screen.

#### AC-181 The blood-heat power stage is GO, with conditions in the screen: limbs, veins and steam only, never red or gold, no hair or eye change. Mobile store content ratings for graphic 'boiling blood' imagery are unchecked.
- Verdict: MISFILED (belongs to: Orb's creative direction (originality); Art)
- What the record says: The blood-heat power stage is GO, with conditions in the screen: limbs, veins and steam only, never red or gold, no hair or eye change. Mobile store content ratings for graphic 'boiling blood' imagery are unchecked. (docs/legal/review-log.md:54; docs/legal/q3-screen.md:154)
- What is actually true: The conditions avoid franchise echoes (no red or gold, no hair or eye change), and the stage's look is not built: the data holds only heat numbers (styles.json:248). The mobile rating question is moot while mobile is parked (ADR 0011), and desktop ratings sit under AC-170. Proof: docs/legal/q3-screen.md:154
- Cost of the false alarm: Small: one extra 'unchecked ratings' item for a parked platform.
- Fix: Move it to Art and Legal's originality screen and drop the mobile item.

#### AC-182 Vicious blows: s08 applies (arm as three places, two per place). Orb confirmed vicious blows inside the clinch, the launch pair has no bite, gouge or claw, and the rating question stays open for the Cyborg.
- Verdict: MISFILED (belongs to: Combat; Orb's creative direction (originality))
- What the record says: Vicious blows: s08 applies (arm as three places, two per place). Orb confirmed vicious blows inside the clinch, the launch pair has no bite, gouge or claw, and the rating question stays open for the Cyborg. (docs/legal/review-log.md:132; docs/legal/review-log.md:133)
- What is actually true: s08 extends s02 to clinch taps, and s02's stated basis is a franchise echo ('keeps Blow for Blow ours'). Vicious blows are not built ('Not in G1', grapple.gd:30). The Cyborg rating question repeats AC-170 and AC-176. Proof: docs/legal/movegen-banned.json:237-238; docs/legal/movegen-banned.json:267-268
- Cost of the false alarm: An Open row, on originality grounds, waits for poses that do not exist.
- Fix: Move it to Combat's originality checklist and fold the Cyborg ratings item into AC-170.

#### AC-184 Swing timing may read anguish, menace and mood within the swing budget, but direction may not read menace and crowd is barred; QA must show no link between the toll and swing count or time, and a civilians-removed run swings the same number of times within one.
- Verdict: MISFILED (belongs to: Game Design (pillar 5, Orb's creative direction); QA for the batch)
- What the record says: Swing timing may read anguish, menace and mood within the swing budget, but direction may not read menace and crowd is barred; QA must show no link between the toll and swing count or time, and a civilians-removed run swings the same number of times within one. (docs/legal/review-log.md:237 (HEAD))
- What is actually true: The rule is in the code: timing reads the three scalars behind a tension switch (off), _direction names no menace or mood, and a source lint bars crowd and pop terms. The swing is off at HEAD and a8bc66e2 and absent from the public pin. QA's toll-association and civilians-removed rows exist but read PENDING, so the batch has never run. This is the pillar-5 design invariant (the villain never feeds on deaths), not a law or rating rule. Proof: audit/2026-11-07/evidence/AC-184.txt; swing.json enabled false and tension.enabled false at HEAD and a8bc66e2; pin lacks swing.gd; swing_legal_check.gd:9-10 BARRED and NOT_IN_DIRECTION lists
- Cost of the false alarm: Holds a QA statistical batch and an open Legal row over a design invariant, and it reads to Orb as a legal blocker on the swing.
- Fix: Move to Game Design as a pillar-5 invariant, with QA's swing.toll.assoc and swing.civless rows kept as design checks. Retire it from Legal's open list.

#### AC-190 Megastructures: no real-tower outlines, no matched twin towers with a bridge, no straight-down pancake collapse with figures, no aircraft-shaped strike, no 'ground zero'; unpopulated with no crowd; no blinking beacons or red-white stripes; dim static lights fading slowly in falls; Anchor and Heat Wall fixes outstanding.
- Verdict: MISFILED (belongs to: Art (originality, Orb's creative direction); Legal only for real-tower likeness)
- What the record says: Megastructures: no real-tower outlines, no matched twin towers with a bridge, no straight-down pancake collapse with figures, no aircraft-shaped strike, no 'ground zero'; unpopulated with no crowd; no blinking beacons or red-white stripes; dim static lights fading slowly in falls; Anchor and Heat Wall fixes outstanding. (docs/legal/review-log.md:255-259 (HEAD))
- What is actually true: Megastructures exist only as untracked concept files (art/concepts/megastructures/, docs/art/megastructures.md): not committed, not public, and absent from sim, data, render and ui. The limits are mostly originality and real-disaster sensitivity (Orb's creative direction) plus a light margin stricter than the flash standard. Only 'no outline copied from a real tower' has a genuine IP kernel. Proof: audit/2026-11-07/evidence/AC-190.txt; git ls-files | grep -i mega: none; git status: ?? art/concepts/megastructures/
- Cost of the false alarm: Five Legal rows of screening over unbuilt concept art, which hold Art's sheet open on drawing details.
- Fix: Move to Art as originality and look direction. Keep a one-line real-structure IP check with Legal, and put the light limits under the flash gates when built.

#### AC-192 Mid-combat barks: MC-255 'pack up the leftovers' reads as remains and is swapped or never plays after a KO; the Empress's threats only target a fighter, never civilians; all lines go into the ratings answers.
- Verdict: MISFILED (belongs to: Narrative (Orb's creative direction); store-release checklist for ratings answers)
- What the record says: Mid-combat barks: MC-255 'pack up the leftovers' reads as remains and is swapped or never plays after a KO; the Empress's threats only target a fighter, never civilians; all lines go into the ratings answers. (docs/legal/review-log.md:232 (HEAD))
- What is actually true: MC-255 is unchanged in live_barks.json on the finisher_landed beat (the winner speaks), so the condition is unmet. Live barks are off at HEAD and a8bc66e2 and absent from the pin. The issue is tone in a Mature-target game. Accurate ratings answers are a store-release process step, not a reason to hold a line. Proof: audit/2026-11-07/evidence/AC-192.txt; live_barks.enabled false (HEAD, a8bc66e2); pin lacks live_barks
- Cost of the false alarm: A Legal row holds a writing choice open alongside the real provenance item in RL-210.
- Fix: Hand MC-255 to Narrative and Orb as a writing call. Move 'lines into the ratings answers' to the store-release checklist.

#### AC-195 Empress and rival lines: 'glass' is a review-tier word, so the approved Cyborg line 'Glass the whole street' has its word swapped or is kept at the review tier, and area threats play only on their own trigger (ln01).
- Verdict: MISFILED (belongs to: Narrative (Orb's creative direction))
- What the record says: Empress and rival lines: 'glass' is a review-tier word, so the approved Cyborg line 'Glass the whole street' has its word swapped or is kept at the review tier, and area threats play only on their own trigger (ln01). (docs/legal/review-log.md:176 (HEAD); homework/2 Up Next/09 Business - Legal's open questions (10 min).md:16)
- What is actually true: The line is the Empress's, not the Cyborg's: the Legal screen, the provenance file and live_barks excluded_lines all say Empress, and only the EP's homework says 'a Cyborg line'. It is excluded from live barks pending Orb's swap, and 'glass' is in the lint's review tier. Legal calls the swap 'Caution, not a rule'. Proof: audit/2026-11-07/evidence/AC-195.txt; gemini-lines-screen.md:20 'Empress: ...glass the whole street'; live_barks.json:7610 hw11.19 excluded
- Cost of the false alarm: It puts a wording choice in front of Orb as Legal homework, with the wrong speaker named.
- Fix: Correct the homework item to the Empress and hand it to Narrative and Orb as a writing choice. Retire it from Legal's open list.

#### AC-196 Open floors are conditional: sturdy regular columns, a deep beam and a lit lobby. The 'never on a damaged building' and 'never in public with debris' (w01) limits were later withdrawn.
- Verdict: MISFILED (belongs to: Orb's creative direction (Rendering and Art))
- What the record says: Open floors are conditional: sturdy regular columns, a deep beam and a lit lobby. The 'never on a damaged building' and 'never in public with debris' (w01) limits were later withdrawn. (docs/legal/review-log.md:150; docs/legal/review-log.md:154)
- What is actually true: Legal's revised screen says open floors carry 'No Legal condition', and that the columns, beam and lobby are Orb's own design requirement. RL-128's row still prints all five conditions, including the withdrawn ones, beside an amendment that names only the wording guard. Whether open floors are built was not checked. Proof: audit/2026-11-07/evidence/AC-196.txt; city-and-open-floors-screen.md:12 'No Legal condition ... Design, not Legal'
- Cost of the false alarm: A stale Legal row with withdrawn limits can be read as live and block Rendering's open floors.
- Fix: Correct RL-128 to strike the withdrawn limits and mark the rest as Orb's design requirement. Close it as Legal.

#### AC-198 Run endings meet c07/c08; the two rival lines after deaths are no legal block, but alternates are recommended as a caution and it is Orb's call.
- Verdict: MISFILED (belongs to: Narrative (Orb's creative direction))
- What the record says: Run endings meet c07/c08; the two rival lines after deaths are no legal block, but alternates are recommended as a caution and it is Orb's call. (docs/legal/review-log.md:168 (HEAD); docs/legal/review-log.md:169 (HEAD))
- What is actually true: Legal's screen itself says the two rival lines are 'a writing choice, not a legal condition'. They sit only in docs/narrative/pending/story_beats.json, not in shipped data. The run-ending pass (RL-146) is a screen of paper lines against Legal's own c07 and c08 cautions. Proof: audit/2026-11-07/evidence/AC-198.txt; homework8-review-screen.md:18 'a writing choice, not a legal condition'
- Cost of the false alarm: RL-147 stays open on Legal's list waiting for Orb over a writing choice.
- Fix: Close RL-147 as Legal and hand the line pick to Narrative and Orb.

#### AC-215 Any text the public will see is written with care and seen by Orb before it is used.
- Verdict: MISFILED (belongs to: Orb's creative direction (Marketing))
- What the record says: Any text the public will see is written with care and seen by Orb before it is used. (docs/ep/vision.md:951; docs/marketing/public-page-drafts.md:3)
- What is actually true: vision.md:951 records Orb's ruling: forward-facing writing seemed 'rushed and bizarre', so it is to be written with care and seen by Orb first. That is Orb's quality direction for copy, not a safety rule. Side finding: the public README.md:7 still says 'The hosted build is offline for now' while /play/ serves a playable build of 257a766c. The README last changed on 2026-10-12 (92c9c94f). Proof: docs/ep/vision.md:951; docs/marketing/public-page-drafts.md:3; README.md:7
- Cost of the false alarm: Filed as a safety rule, it suggests public text is kept reviewed, which hides that the public README misstates the live build.
- Fix: Move the rule to Orb's creative direction and Marketing's process. Separately, correct README.md:7 to describe /play/ as it is now.

#### AC-220 Keepsakes: rename Jar of Ash; Fused Sand Chip keeps 'blast' only; no paid hidden rewards (ln03).
- Verdict: MISFILED (belongs to: Narrative (Orb's creative direction); ln03 to Legal)
- What the record says: Keepsakes: rename Jar of Ash; Fused Sand Chip keeps 'blast' only; no paid hidden rewards (ln03). (docs/legal/review-log.md:180 (HEAD))
- What is actually true: The rename is already done. rewards-words.md v2 (2c493910, 2026-10-18) and the parked keepsakes.json use 'Sky Jar' and 'Blast Sand Chip', so the row's 'Open until renamed' is stale. Keepsakes are a parked draft that is in no build, and the name is a tone call. ln03 guards a real loot-box concern, but the game sells nothing. Proof: docs/legal/review-log.md:180; docs/legal/rewards-and-lock-screen.md:16-17; docs/narrative/rewards-words.md:3,73
- Cost of the false alarm: A stale open row keeps a finished tone fix on the store-gate list and suggests unfinished Legal work.
- Fix: Close RL-158 in the review log. Keep ln03 as Legal's monetisation rule in case anything is ever sold. The tone of names belongs to Narrative and Orb.

#### AC-225 PlayStation needs a legal entity (sole traders accepted in Europe only), so nobody is told a console version is coming.
- Verdict: MISFILED (belongs to: Performance & Platform (Marketing))
- What the record says: PlayStation needs a legal entity (sole traders accepted in Europe only), so nobody is told a console version is coming. (docs/ep/orb-review-list.md:145; docs/marketing/go-to-market-plan.md:309)
- What is actually true: Platform's own doc marks the entity and sole-trader rule as [S] secondary (stores-and-consoles.md:5, 47). I could not check it: partners.playstation.net shows nothing without a login. Not promising a console version is marketing honesty and business planning, not release safety, and no console port exists. Proof: docs/ep/orb-review-list.md:145; docs/marketing/go-to-market-plan.md:309; docs/perf/stores-and-consoles.md:5,47. External: https://partners.playstation.net/ (accessed 2026-11-07): only the page heading is shown without login; no primary rule found
- Cost of the false alarm: Small: an unverified platform fact sits on a safety list and in Orb's review list as if settled.
- Fix: Move it to Performance & Platform and Marketing's stage-5 plan, and mark the entity rule unverified until it is read on Sony's partner site.

#### AC-241 Before each re-pin of the public demo Orb gets the link and a 30-second clip, a re-pin that changes the look waits for Orb's word or a day's notice, and a visible change needs a side-by-side before commit; on 2026-10-05 an EP docs push put an unready slice live for about an hour.
- Verdict: MISFILED (belongs to: Orb's creative direction)
- What the record says: Before each re-pin of the public demo Orb gets the link and a 30-second clip, a re-pin that changes the look waits for Orb's word or a day's notice, and a visible change needs a side-by-side before commit; on 2026-10-05 an EP docs push put an unready slice live for about an hour. (docs/decisions/0010-look-gate.md:8; docs/decisions/0010-look-gate.md:13; docs/ep/playbook.md:13; +2 more)
- What is actually true: The rule is real (ADR 0010 item 6, playbook 8), but it is Orb's look and creative direction, and the 2026-10-05 slip was about balance, not safety. Since 2026-10-18 the pinned deploy (ci.yml:476-486) stops a main push from changing /play/. The pin has been 257a766c since 45869fac (2026-10-19, on Orb's word), so the 2026-11-05 deploy was not a re-pin. Proof: audit/2026-11-07/evidence/AC-241.txt; docs/decisions/0010-look-gate.md:13; docs/ep/playbook.md:13
- Cost of the false alarm: A taste rule pads the safety ledger. The inventory's note that the 2026-11-05 deploy lacked Orb's clip treats a rebuild of the same pin as a re-pin.
- Fix: Move it to EP process under ADR 0010. Correct the note: the 2026-11-05 deploy did not move the pin.

#### AC-259 Orb's rule: accessibility settings and customizable controls are assumed, including a left-handed swap. Eight rules follow, among them role words, full remap, routes to every move class, no speed gesture without a plain form, and the no-claw gate run on swapped presets.
- Verdict: MISFILED (belongs to: Orb's creative direction (Accessibility, Controls))
- What the record says: Orb's rule: accessibility settings and customizable controls are assumed, including a left-handed swap. Eight rules follow, among them role words, full remap, routes to every move class, no speed gesture without a plain form, and the no-claw gate run on swapped presets. (docs/accessibility/right-hand-controls.md:3; docs/accessibility/right-hand-controls.md:5-14; docs/accessibility/swing-motion.md:54)
- What is actually true: Orb's rule is real (2026-10-30) and mostly built: hand layout, D-pad mirror, strike and brace styles, one-stick mode, a swapped keyboard preset, SimSwap, and the claw gate run on the swapped pad. On a pad, rule 5 is not met by default, because no brace or vanish button is bound (see AC-252). Rule 1 still has 'Left thumb' in howto.json:50, and the checklist (row 12) does not exist. Proof: evidence/AC-259.txt
- Cost of the false alarm: It puts a product requirement on the release-safety list. Its one real defect is already AC-252.
- Fix: Move it to Accessibility and Controls as Orb's product requirement, and track rows 2, 9, 11 and 12 there.

#### AC-262 Colour-blind options are wanted without a stylistic palette change: no cue is colour-only, three colour-blind presets (protan, deutan, tritan) add a second route, never the only one, and lane colours are chosen CIEDE2000 20 or more apart.
- Verdict: MISFILED (belongs to: Orb's creative direction (UI, Art))
- What the record says: Colour-blind options are wanted without a stylistic palette change: no cue is colour-only, three colour-blind presets (protan, deutan, tritan) add a second route, never the only one, and lane colours are chosen CIEDE2000 20 or more apart. (docs/accessibility/audit-2026-10-28.md:59-62; docs/ep/vision.md:817; ui/data/options.json:91; +1 more)
- What is actually true: Orb's direction is real (vision.md:817), and the presets are wired in both the pin and HEAD. I re-measured with the repo's own colour-vision matrices: the two fighters' lane colours are 34.9, 36.6 and 31.0 apart (CIEDE2000). But under deutan the closest wound-stage colour sits 19.6 from a lane colour, and UI's own note gives 19.9 while claiming 'at least 20'. The 20 is the project's own margin, not a standard. Proof: evidence/AC-262.txt (de00 re-measure; readers of colour_vision at HEAD and 257a766c)
- Cost of the false alarm: Little. A design rule that is already met adds review load when carried as safety.
- Fix: Move it to UI and Art. Either change the note's 'at least 20' to the measured deutan minimum, or adjust one deutan stage colour.

#### AC-279 Every public string uses American spelling (Orb's rule of 2026-10-18), enforced by Tools' scan over public strings and ui/data/*.json; the scan reads ui/data only, so it misses code strings ('Licence' in ui_licences.gd) and lacks 'manoeuvre' and 'armour'.
- Verdict: MISFILED (belongs to: Orb's creative direction (house style); Tools for the scan)
- What the record says: Every public string uses American spelling (Orb's rule of 2026-10-18), enforced by Tools' scan over public strings and ui/data/*.json; the scan reads ui/data only, so it misses code strings ('Licence' in ui_licences.gd) and lacks 'manoeuvre' and 'armour'. (docs/legal/movegen-banned.json:667; docs/legal/page-fixed-lines.md:25; docs/legal/page-fixed-lines.md:58; +2 more)
- What is actually true: The scan (check-site-interim.mjs:57) runs only over site pages, ui/data/*.json and the words file (lines 331, 389, 454). So 'Licence:' and 'Licence texts' in ui_licences.gd:24,26 ship in the live pin 257a766c, MANOEUVRE (stances.json) and 'ARMOUR OPEN' (terms.json:34) pass because the regex lacks them, and README.md:7,9 carry 'Licence' and 'analyser'. This is Orb's house style, not release safety. Proof: audit/2026-11-07/evidence/AC-279.txt
- Cost of the false alarm: A style rule sits in Legal's records (RL-162/192/193) and fails the interim site check, so a spelling slip can fail the same export that carries the real safety checks.
- Fix: Move the rule to Orb's style guide and Localization. Make the scan a lint that does not block, or widen it to .gd strings, README, 'manoeuvre' and 'armour' as Tools' own check, outside Legal's records.

### Engineering and quality: QA, Netcode, Simulation, Performance, Accessibility, UI (34)

#### AC-044 GB-003: the split-screen camera jolts when a player is knocked away.
- Verdict: MISFILED (belongs to: Camera)
- What the record says: GB-003: the split-screen camera jolts when a player is knocked away. (qa/known-bugs.md:173)
- What is actually true: Orb's report is real, and Camera answered it the same day: d7323551 (2026-10-02, two hours after GB-003 was logged) added a jolt pass and a per-tick jolt scan to split_sweep, whose doc records 4,636 jolts cut to 1,572 and later 1,546 still counted. So known-bugs.md:179's 'no metric exists' is stale. A camera jolt is a feel and comfort bug, not a seizure or legal risk. Proof: evidence/AC-044.txt; git log: 965cdbc2 2026-10-02 02:19 adds GB-003; d7323551 2026-10-02 04:22 Camera split-screen jolt pass
- Cost of the false alarm: Carried as a flash-theme item with 'no metric', it can make QA build a camera metric that Camera's sweep already has.
- Fix: Move to Camera's queue; QA re-reads it against split_sweep's jolt scan and closes or re-opens it with a number.

#### AC-046 Open asks: seed Reduced motion from the platform's preference, and ask Legal whether a motion line with its own buttons may sit beside the flash notice on first run.
- Verdict: MISFILED (belongs to: Accessibility (UI, Tools))
- What the record says: Open asks: seed Reduced motion from the platform's preference, and ask Legal whether a motion line with its own buttons may sit beside the flash notice on first run. (docs/accessibility/swing-motion.md:61; docs/accessibility/swing-motion.md:68)
- What is actually true: Both asks are real and open: no code in ui, render, tools, sim or net reads prefers-reduced-motion, and the review log has no answer on a motion line. Seeding the setting is an accessibility feature, and where a motion line sits beside the notice is a UI layout choice that no cited law or standard governs. Neither is a release-safety finding. Proof: evidence/AC-046.txt; git grep prefers-reduced-motion over ui render tools sim net: 0 files
- Cost of the false alarm: A Legal ask in the safety queue for a UI layout question, and a feature request that looks like a safety gap.
- Fix: Move both to the Accessibility and UI backlog as a feature ticket (seed reduced_motion from the browser's preference on web); retire the Legal question or make it the EP's UI call.

#### AC-056 The snapshot copier compiles GDScript at run time, which is untested in exported builds, the web included.
- Verdict: MISFILED (belongs to: Netcode)
- What the record says: The snapshot copier compiles GDScript at run time, which is untested in exported builds, the web included. (docs/net/cloud-reports/2026-10-28-rollback-core.md:67)
- What is actually true: snapshot.gd:212-221 compiles a GDScript generated from the engine's own property list and falls back to a reflective copy if compiling fails. No outside input reaches that source, so it is no code-execution path. It runs only in LAN builds: the live pin has no net/, and nothing outside net/ calls it. So it is a speed and robustness risk, not a safety one. Proof: evidence/AC-055.txt: snapshot.gd GDScript.new / source_code / reload() with 'the reflective copy is used' fallback; evidence/AC-055.txt: 0 net/ files in 257a766c; 0 references to Net* classes outside net/ at HEAD
- Cost of the false alarm: Filed as an A2 security risk, it suggests run-time code injection in the web build, and no such path exists.
- Fix: Move it to Netcode's engineering risks. Make the LAN log record whether the generated copier compiled in the exported build.

#### AC-058 The handshake refuses a peer on another protocol version or match key, which includes the data hash and AI level, so mismatched builds can't play and desync.
- Verdict: MISFILED (belongs to: Netcode)
- What the record says: The handshake refuses a peer on another protocol version or match key, which includes the data hash and AI level, so mismatched builds can't play and desync. (docs/net/rollback.md:240; docs/net/rollback.md:308; docs/net/rollback.md:349; +2 more)
- What is actually true: handshake.gd:79-82 fails on a protocol mismatch (PROTO 5) or a match-key mismatch, and keyOf adds SimReplay.dataHash to the key. That is a guard against desyncs, not a safety control. .gitattributes forces LF line endings, which narrows the cross-platform line-ending risk for git checkouts. Proof: evidence/AC-057.txt: handshake.gd:79 'protocol %s, this peer speaks %d'; :81 match key compare; :106 key + SimReplay.dataHash(setup)
- Cost of the false alarm: Listing a correctness check under security makes the security record look broader than it is.
- Fix: Move it to Netcode's netplay correctness notes.

#### AC-059 The desync digest 'is not a security hash', since 'a peer that lies can lie about anything': there is no trust boundary or anti-cheat between peers.
- Verdict: MISFILED (belongs to: Netcode)
- What the record says: The desync digest 'is not a security hash', since 'a peer that lies can lie about anything': there is no trust boundary or anti-cheat between peers. (docs/net/rollback.md:127)
- What is actually true: rollback.md:127 says the MD5 digest is for catching desyncs and 'is not a security hash'. Cheating between peers is a game-integrity question for future internet play, which doesn't exist yet (Orb: online after launch). Hostile-packet safety is covered by the decoder (AC-057). Proof: grep of docs/net/rollback.md:127 shows 'It is not a security hash and does not need to be'
- Cost of the false alarm: Small: it is filed as an accepted security risk but asks for no work.
- Fix: Move it to Netcode's online-play design list (trust model, anti-cheat) for when internet play is planned.

#### AC-065 On a desync each peer writes a JSON report (replay, snapshots, field walk) to disk. An online upload to a crash-report bucket needs a place at zero budget and is not built.
- Verdict: MISFILED (belongs to: Netcode)
- What the record says: On a desync each peer writes a JSON report (replay, snapshots, field walk) to disk. An online upload to a crash-report bucket needs a place at zero budget and is not built. (docs/net/rollback.md:134; docs/net/rollback.md:209; docs/net/cloud-reports/2026-10-28-desync-spectate.md:87)
- What is actually true: writeReport writes JSON to whatever path it is given, but only test tools call it (desync_check.gd:338); the LAN game writes no desync report. The report holds sim state and field paths, no identifiers, and no upload exists. Proof: evidence/AC-065.txt: writeReport callers at HEAD are desync.gd (definition) and net/tools/desync_check.gd only
- Cost of the false alarm: It suggests peers write files on desync in the shipped LAN build, which they don't, and it files a missing upload as a privacy risk.
- Fix: Correct the record: only test tools write the report. Send any future upload design to Legal for a privacy review.

#### AC-174 Civilian and hazard hard tests are pending: H1 (hazards never break a region), H2 (zero tier-1 hazard casualties), H5 (chain tier cap and casualty budget). They stay PENDING until LD1 and World's work land.
- Verdict: MISFILED (belongs to: QA & Balance)
- What the record says: Civilian and hazard hard tests are pending: H1 (hazards never break a region), H2 (zero tier-1 hazard casualties), H5 (chain tier cap and casualty budget). They stay PENDING until LD1 and World's work land. (docs/qa/README.md:46; docs/qa/README.md:56-57)
- What is actually true: pending-tests.js defines H1, H2 and H5. H4 and H5 have no body (run: null), and a test whose events are missing is reported PENDING. A hazard_telegraph event now exists (fx.gd:632) and matches the 'hazard*' prefix, so H1 and H2 may already run; I did not run them. They test casualty budgets and tier escalation, which is a design target (the P3 exit), not harm to players. Proof: audit/2026-11-07/evidence/AC-174.txt
- Cost of the false alarm: Carrying balance tests as safety gates makes the civilian share look like a release blocker and spends QA time under a safety label.
- Fix: Move these to QA & Balance's design gates, write H5's body, and check whether H1 and H2 now run.

#### AC-214 No machine is a target during development, and minimum specs are measured and set before launch.
- Verdict: MISFILED (belongs to: Performance & Platform (Orb's direction, ADR 0013))
- What the record says: No machine is a target during development, and minimum specs are measured and set before launch. (docs/decisions/0013-no-laptop-target.md:8-10)
- What is actually true: ADR 0013 (Orb, 2026-11-01), lines 8-10, says exactly this. It is a performance planning decision with no player-safety or legal content. Setting minimum specs before launch would also fill any store field for them; I did not check Valve's rule on that. Proof: docs/decisions/0013-no-laptop-target.md:3; docs/decisions/0013-no-laptop-target.md:8-10; audit/2026-11-07/evidence/AC-214.txt
- Cost of the false alarm: It adds a store-gate row that no safety check can pass or fail. The cost is a little worry, nothing more.
- Fix: Retire it from the safety records and keep it on Performance & Platform's pre-launch checklist.

#### AC-226 A bug in the played LAN build: a pause's rollback left fight 0 in the state, so a paused PC showed the wrong fight. The fix is parked unfinished with its gates part-run.
- Verdict: MISFILED (belongs to: Netcode)
- What the record says: A bug in the played LAN build: a pause's rollback left fight 0 in the state, so a paused PC showed the wrong fight. The fix is parked unfinished with its gates part-run. (docs/net/pending/lan-n4/README.md:1-3; docs/net/pending/lan-n4/README.md:16; docs/net/pending/lan-n4/README.md:33-37)
- What is actually true: In a8bc66e2, NetHost.idle calls frame(), which runs session.sync() and can roll back and re-run ticks. NetLan.idle never calls _follow, which only tick() does (lan.gd:99), so a paused 2v2 PC can be left holding fight 0. The fix exists only in the untracked docs/net/pending/lan-n4, where transport_check and the exported --lan-loop rows are 'Not run'. LAN code is absent from the public pin, and the bug is a display fault while paused with no player-harm path. Proof: evidence/AC-226.txt; docs/net/pending/lan-n4/README.md:35,37 ('Not run'); a8bc66e2:net/lan.gd:3-4 (private builds only; public desktop builds exclude net/)
- Cost of the false alarm: A LAN view bug sits on the safety ledger even though it can only show the wrong fight while a private build is paused.
- Fix: Move to Netcode's bug queue and finish lan-n4's remaining runs there.

#### AC-227 Orb reported faults in the LAN and 2v2 tests: intermittent stutter, both screens following only the main PC's fight, crackly audio on high-speed impacts, no sound until the first pause, and fighters clipping into the ground.
- Verdict: MISFILED (belongs to: QA)
- What the record says: Orb reported faults in the LAN and 2v2 tests: intermittent stutter, both screens following only the main PC's fight, crackly audio on high-speed impacts, no sound until the first pause, and fighters clipping into the ground. (docs/ep/vision.md:1654; docs/ep/vision.md:1660; docs/ep/vision.md:1662; +1 more)
- What is actually true: Orb did say these things. The silence until the first pause comes from the a8bc66e2 play file, and the 2v2 stutter and camera quotes are recorded in vision.md:1660-1663. The crackly audio came from the 2026-11-06 solo play on build 10d8b8cf (vision.md:1654), not from the LAN tests. The ground-clipping quote appears only in vision.md. None of these is a player-safety fault, and none was reproduced. Proof: evidence/AC-227.txt; orb-first-play-20261106-1934.json 'Did the hits sound right?': crackly audio, build 10d8b8cf; orb-first-play-20261107-1229.json: sound not audible until first pause, build a8bc66e2
- Cost of the false alarm: Five QA and feel bugs from private tests sit on the safety ledger and compete with real safety work.
- Fix: Move to QA's bug register with Audio, Netcode, Camera and World as owners, and correct the record so the crackle is dated to the 2026-11-06 solo play.

#### AC-229 The legacy suite (node qa/run-all.js) gates determinism, the seam, and a 1,000-match soak with no NaN, no crash, no fighter outside the world and casualties never above population. Golden hashes are pinned to Node 24, and 'CI should pin the Node version'.
- Verdict: MISFILED (belongs to: QA)
- What the record says: The legacy suite (node qa/run-all.js) gates determinism, the seam, and a 1,000-match soak with no NaN, no crash, no fighter outside the world and casualties never above population. Golden hashes are pinned to Node 24, and 'CI should pin the Node version'. (qa/README.md:15; qa/README.md:30; qa/README.md:39; +1 more)
- What is actually true: I ran the suite: all 7 test files pass on Node v24.19.0, including the 1,000-match soak and the 11 golden hashes. It tests only the legacy HTML prototype and the frozen JS core (run-all.js:2), not the Godot game at /play/. CI already pins Node 24.19.0 (ci.yml:40), but CI has run no job since 3c9005ac, so the suite gates nothing today. Proof: evidence/AC-229.txt (run-all --quick: all 7 passed; --only=soak,determinism: 1000 matches, 0 timeouts, golden 11 match; exit 0)
- Cost of the false alarm: Listing this suite as a stability gate suggests it soak-tests the shipped Godot game, which it does not.
- Fix: Move to QA's process docs, mark the Node pin done, and stop counting the suite as a release gate for the Godot build.

#### AC-230 Cross-processor agreement gates the LAN plan: if the two PCs disagree, everything else waits.
- Verdict: MISFILED (belongs to: Netcode)
- What the record says: Cross-processor agreement gates the LAN plan: if the two PCs disagree, everything else waits. (docs/net/two-pc-check.md:74; docs/net/two-v-two-lan.md:86; docs/net/lan-v1.md:83)
- What is actually true: The gate is written at two-v-two-lan.md:86, and the records disagree. two-pc-check.md:74 says the check has only run on this PC, while lan-v1.md:83 says it ran on both. The old-PC result file shows the i5-6600K ran the check with twopc_exit 0. I did not compare that report against the Ryzen's. A desync is a netcode correctness issue in private LAN builds, not player harm. Proof: evidence/AC-230.txt; oldpc-result-20261101-1813.json: cpu i5-6600K, twopc_exit 0, build dafc348f
- Cost of the false alarm: Small: the stale line can make the LAN plan look blocked on a check that has already run.
- Fix: Correct two-pc-check.md:74 and keep the gate in Netcode's plan rather than the safety records.

#### AC-231 Known LAN rough edges, with no drop policy for a vanished peer: one match only with no rematch, a lost link just stops (the test uses 30 frames where a game needs seconds and a notice, no rejoin, two peers only), a pause holds the other PC, and in 2v2 the other fight is not drawn but can still reach you.
- Verdict: MISFILED (belongs to: Netcode)
- What the record says: Known LAN rough edges, with no drop policy for a vanished peer: one match only with no rematch, a lost link just stops (the test uses 30 frames where a game needs seconds and a notice, no rejoin, two peers only), a pause holds the other PC, and in 2v2 the other fight is not drawn but can still reach you. (docs/net/lan-v1.md:85; docs/net/rollback.md:312-316; docs/net/cloud-reports/2026-10-28-ai-takeover.md:165-166)
- What is actually true: In a8bc66e2 no LAN host calls NetSession.dropSlot. A closed link only sets the title to 'The other PC has gone' (lan.gd:246), and rollback.md:312-316 states there is no rejoin and only two peers. SETUP2X turns cross-fight hits on (lan.gd:17), so in 2v2 a blow can come from a fight that is not drawn. LAN is private-only and absent from the public pin. These are missing features and UX issues, not safety ones, and online play comes after launch. Proof: evidence/AC-231.txt
- Cost of the false alarm: A feature backlog ends up on the safety ledger.
- Fix: Move to Netcode's backlog: build a drop policy and notice before any online release, and send the undrawn-fight hit to Camera and Encounter as a design item.

#### AC-232 The Godot QA run exits non-zero only if the run broke (no Godot, NaN, a fighter outside the world) or a hard acceptance test failed. Band FAILs fail it only with --fail.
- Verdict: MISFILED (belongs to: QA)
- What the record says: The Godot QA run exits non-zero only if the run broke (no Godot, NaN, a fighter outside the world) or a hard acceptance test failed. Band FAILs fail it only with --fail. (docs/qa/README.md:19)
- What is actually true: Traced as written. The run exits 1 on a bad record (:61-62) or a hard test FAIL (:89), and on band FAILs only with --fail (:99). A missing Godot exits 2. The feel, level, crossing and masher probes catch their own errors and print 'skipped' without failing the run (:72-81), and no workflow runs run-godot.js. This is a QA tool's exit policy, not a release-safety matter. Proof: evidence/AC-232.txt
- Cost of the false alarm: Small: it implies a release gate where there is only a manual QA tool.
- Fix: Move to QA's docs. If the run is meant to gate, add it to CI and make skipped probes fail it.

#### AC-233 Cross-play is only as wide as the parity proof: macOS ARM, Linux ARM, Android and iOS are not proven bit-identical (FMA). The parity gate must run on each, and the web and macOS/ARM must be added to CI before those platforms ship.
- Verdict: MISFILED (belongs to: Simulation)
- What the record says: Cross-play is only as wide as the parity proof: macOS ARM, Linux ARM, Android and iOS are not proven bit-identical (FMA). The parity gate must run on each, and the web and macOS/ARM must be added to CI before those platforms ship. (docs/net/rollback.md:214; docs/net/cloud-reports/2026-10-28-rollback-core.md:68; docs/decisions/0006-gdscript-source-of-truth.md:29)
- What is actually true: Every CI job runs on ubuntu-24.04 x64, so macOS and ARM go unchecked, and macOS is a launch platform (ADR 0011:8). ADR 0006:29 is partly stale because web-parity.yml now checks the web build. The FMA risk is plausible but unproven. Android and iOS are parked, and cross-play is post-launch. A desync is a correctness issue, not player harm. Proof: evidence/AC-233.txt
- Cost of the false alarm: As a safety gate it could block a macOS release that has no cross-play at launch.
- Fix: Move to Simulation and Netcode as a precondition for cross-platform play and replays, and correct ADR 0006:29 to say the web is now checked.

#### AC-234 Mutable statics outside the snapshot (DirBrawl._fr*, DirExchange.planEntry and others) are unaudited and could desync only under rollback. DirAlchemy's memo can be read across two fights.
- Verdict: MISFILED (belongs to: Netcode)
- What the record says: Mutable statics outside the snapshot (DirBrawl._fr*, DirExchange.planEntry and others) are unaudited and could desync only under rollback. DirAlchemy's memo can be read across two fights. (docs/net/cloud-reports/2026-10-28-ai-depth.md:78; docs/net/two-v-two-lan.md:30)
- What is actually true: The named statics exist, and sim/ holds about 948 non-tool static vars. I spot-checked two. planEntry is set before _start and reset to 0 right after (exchange.gd:201-205). DirAlchemy's memo is keyed by S's id, the tick and the log bits, so a cross-fight read returns what it would compute, if its stated purity holds. The rest are unaudited, and only rollback in private LAN builds could expose them. It is a desync risk, not player harm. Proof: evidence/AC-234.txt
- Cost of the false alarm: Low: an engineering audit item sits on the safety ledger.
- Fix: Move to Netcode and Simulation, and write the statics audit (a set-before-read lint for per-tick statics) before online play.

#### AC-236 The web build's first start takes 22 to 57 s on this PC and possibly 1.5 to 2.5 minutes on a low-end phone, and the page may look stuck meanwhile.
- Verdict: MISFILED (belongs to: Performance)
- What the record says: The web build's first start takes 22 to 57 s on this PC and possibly 1.5 to 2.5 minutes on a low-end phone, and the page may look stuck meanwhile. (docs/marketing/phone-freeze-words.md:20; docs/marketing/phone-freeze-words.md:27)
- What is actually true: Performance measured 22.8 s at x1 and 57.0 s at a 6x CPU throttle on 257a766c, so '57 s on this PC' is really an emulated slower CPU. The 1.5 to 2.5 minutes is an extrapolation. The live /play/ serves a 38.4 MB wasm and a 9.0 MB pck and shows no start-state line, because the crumbs switch is off (no 'crumbs' key in tools/site.json). A slow start that looks frozen is a UX problem, not player harm. Proof: evidence/AC-236.txt
- Cost of the false alarm: Low: it keeps a performance and UX item on the safety ledger.
- Fix: Move to Performance, with Tools for the site switch, and correct the record to say the 57 s was at a 6x throttle.

#### AC-242 The native link (ENet) is 'built and tested between two programs in CI', and enet_check runs only in CI, never on Orb's PC, because a socket there could raise a firewall prompt.
- Verdict: MISFILED (belongs to: Netcode)
- What the record says: The native link (ENet) is 'built and tested between two programs in CI', and enet_check runs only in CI, never on Orb's PC, because a socket there could raise a firewall prompt. (docs/net/two-v-two-lan.md:117; docs/net/two-v-two-lan.md:121; docs/net/lan-v1.md:74; +2 more)
- What is actually true: The two-process ENet steps (added cf90189c) passed in the last green CI run, 41956488028 at 72a4d1e4. net/enet_transport.gd gained redial() in 3c9005ac, after that run, so the LAN build a8bc66e2 ships ENet code CI never ran. The --late-host step has never run and appears twice (ci.yml:417, 419). The firewall-prompt rule is machine discipline; I could not check whether it was followed. Proof: audit/2026-11-07/evidence/AC-242.txt; .github/workflows/ci.yml:314-315; .github/workflows/ci.yml:411-420
- Cost of the false alarm: A test-coverage statement and a dev-PC rule sit in the safety records, and the record overstates coverage of the build Orb and Orb 2 have.
- Fix: Move it to Netcode's test record. Correct it to 'two-process tested at 72a4d1e4; redial and late host untested'. Drop the duplicate step.

#### AC-243 The GDScript goldens are checked by tools/parity.gd on every push (CI, Linux) and locally.
- Verdict: MISFILED (belongs to: QA)
- What the record says: The GDScript goldens are checked by tools/parity.gd on every push (CI, Linux) and locally. (docs/decisions/0006-gdscript-source-of-truth.md:14)
- What is actually true: The step exists (ci.yml:188-189) and last passed in run 41956488028 at 72a4d1e4 (2026-11-05). Since then sim/core/test/golden.json changed in 3c9005ac and a8bc66e2 with no CI check, because CI runs no jobs. Local runs leave no record. It is a determinism gate, not a release-safety one. Proof: audit/2026-11-07/evidence/AC-243.txt; docs/decisions/0006-gdscript-source-of-truth.md:14; sim/core/tools/parity.gd:2-7
- Cost of the false alarm: It adds a determinism gate to the safety ledger, and 'every push' hides that two golden regenerations went unchecked.
- Fix: Move it to Simulation/QA. Once ci.yml parses again, re-run parity on HEAD and say the gate was down from 3c9005ac.

#### AC-249 The webrtc-native GDExtension would be a new dependency and needs approval before native-to-browser cross-play.
- Verdict: MISFILED (belongs to: Netcode)
- What the record says: The webrtc-native GDExtension would be a new dependency and needs approval before native-to-browser cross-play. (docs/net/rollback.md:257; docs/net/cloud-reports/2026-10-28-transport.md:90)
- What is actually true: This is accurate: Godot's docs say native WebRTC needs an external GDExtension. No WebRTC file, GDExtension or register row exists, and no GDScript uses WebRTC classes. Online play is after launch (vision.md:32). It is a dependency and scope decision, already covered by register rule 1, not a safety matter. Proof: audit/2026-11-07/evidence/AC-249.txt; docs/net/rollback.md:257; docs/net/cloud-reports/2026-10-28-transport.md:90. External: https://docs.godotengine.org/en/stable/tutorials/networking/webrtc.html (accessed 2026-11-07): "require an external GDExtension plugin on native (non-HTML5) platforms"
- Cost of the false alarm: A future-feature dependency question adds a line to the safety ledger and nothing else.
- Fix: Move it to Netcode's open items, and route it through a licence-register row when cross-play is scoped.

#### AC-260 Beam alert accessibility: marks sit on a solid plate with 4.5:1 text contrast, visual, sound and buzz strength are split, the sound is captioned, presets come first (Calm, Standard, Full), and a dodge-zone notch is drawn so the alert does not teach the wrong timing.
- Verdict: MISFILED (belongs to: Accessibility, UI)
- What the record says: Beam alert accessibility: marks sit on a solid plate with 4.5:1 text contrast, visual, sound and buzz strength are split, the sound is captioned, presets come first (Calm, Standard, Full), and a dodge-zone notch is drawn so the alert does not teach the wrong timing. (docs/accessibility/beam-alert-review.md:16-17; docs/accessibility/beam-alert-review.md:24-27; docs/accessibility/beam-alert-review.md:32-33)
- What is actually true: The record's 'not built' is stale. The alert was built at d5582dbd (2026-11-07) with a solid backing plate, Calm/Standard/Full presets, separate sound and buzz rows and a dodge-zone notch, but it is switched off (answer_alert false). The 4.5:1 figure matches WCAG SC 1.4.3 for web text and works here as a design margin. It is not measured, and the alert sound has no caption. Proof: evidence/AC-260.txt. External: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html (accessed 2026-11-07): SC 1.4.3, Level AA, "contrast ratio of at least 4.5:1"
- Cost of the false alarm: Small: a design brief for a feature that is off, sitting in the safety records. It implies a contrast check runs when none does.
- Fix: Move it to the UI and Accessibility design notes. Before answer_alert is switched on, measure the contrast of the plate text and add the sound caption.

#### AC-263 Three controller layouts plus full keyboard and pad remapping for both players ship, every layout producing the same actions; the system keys N, T, Y, P and Escape are reserved, and it is unverified whether each has a menu route for players who cannot reach them.
- Verdict: MISFILED (belongs to: Controls, UI (Orb's ADR 0008))
- What the record says: Three controller layouts plus full keyboard and pad remapping for both players ship, every layout producing the same actions; the system keys N, T, Y, P and Escape are reserved, and it is unverified whether each has a menu route for players who cannot reach them. (docs/accessibility/audit-2026-10-28.md:29-35; docs/decisions/0008-control-scheme.md:31; docs/decisions/0008-control-scheme.md:51)
- What is actually true: Remapping is on, and N, T, Y, P and Escape are reserved. But the pin and HEAD have only two pad layouts (arena and simple-pad, no Brawler), so ADR 0008's 'three layouts ship' is not what ships. Menu routes mostly exist: the pause menu has New match and Resume, the start menu sets 1 or 2 players, and any key hands P1 to the player. Proof: evidence/AC-263.txt
- Cost of the false alarm: Low. A P3 about 'unverified routes' stays open although the routes exist, and the ADR's three-layout promise reads as shipped.
- Fix: Move it to Controls and UI and correct the record: two pad layouts, routes found for N, P, T and Y. Ask Orb whether a Brawler layout is still wanted.

#### AC-269 Combat's CC-007 to CC-013 were never added to the register, and the register-agreement check is meant to fail until entries are added.
- Verdict: MISFILED (belongs to: QA (backlog on the retired prototype))
- What the record says: Combat's CC-007 to CC-013 were never added to the register, and the register-agreement check is meant to fail until entries are added. (qa/known-bugs.md:198-200)
- What is actually true: It is true that CC-007 to CC-013 were never added, but the register covers the retired JS prototype (prototype/index.html at 7233c96), not the shipped Godot game. The agreement check passes today and fails only once a KB-007+ entry is added without a matching check, so the claim has it backwards. move-grammar.md already tracks CC-007 to CC-011, and CC-009 is marked resolved there. Proof: evidence/AC-269.txt: the check's parsing logic replayed on HEAD qa/known-bugs.md (6 confirmed entries, wanted=[], stale=[]); grep of CC-007..013
- Cost of the false alarm: It suggests an open QA failure and unscreened bugs in the product, when it is backlog against a retired prototype.
- Fix: Retire the note, or point it to Combat's move-grammar.md list. Not a safety record.

#### AC-280 Prototype bug KB-001: a signature against an ESCAPE defender hits less as the attacker's tier rises (a sign error), an accidental rubber band once fighters differ.
- Verdict: MISFILED (belongs to: QA & Balance / Combat)
- What the record says: Prototype bug KB-001: a signature against an ESCAPE defender hits less as the attacker's tier rises (a sign error), an accidental rubber band once fighters differ. (qa/known-bugs.md:9; qa/known-bugs.md:45-59)
- What is actually true: Reproduced: known-bugs.test.js passes KB-001 (36.4% hit at a 3-tier lead, 65.8% trailing). Line 589 has the sign error, and the prototype is unchanged since 7233c96. The mean tier gap is 0.008, so no metric moves. The same formula is in the frozen JS oracle (beam.js:21). The GDScript game's beam outcome is data-driven (sim/director/data.gd:638); I did not check whether it has the same sign. Proof: audit/2026-11-07/evidence/AC-280.txt
- Cost of the false alarm: None as a QA register entry. In the safety inventory it is noise that dilutes real items.
- Fix: Keep it in qa/known-bugs.md as a gameplay register and drop it from the safety inventory. Combat to check whether the data rule in the GDScript game has the same sign.

#### AC-281 Prototype bug KB-002: the 1.35x damage against a charging defender never applies.
- Verdict: MISFILED (belongs to: QA & Balance / Combat)
- What the record says: Prototype bug KB-002: the 1.35x damage against a charging defender never applies. (qa/known-bugs.md:10; qa/known-bugs.md:61-75)
- What is actually true: Reproduced: the test passes. A light hit does 36.4 (26 x 1.4) and a signature 230, neither with x1.35, because line 411 sets the defender 'locked' before hit() reads 'charging' at line 326. The effects file kb2 shows 118 hits on charging defenders, 0 read as charging, and 0.5% of damage. This is a balance bug in the legacy prototype. Proof: audit/2026-11-07/evidence/AC-281.txt; audit/2026-11-07/evidence/AC-280.txt
- Cost of the false alarm: Noise in the safety inventory. No gate depends on it.
- Fix: Keep it in QA's prototype register and drop it from the safety inventory.

#### AC-282 Prototype bug KB-003: a parried exchange still gives the attacker a chain window, so 13% of counted chains are phantom.
- Verdict: MISFILED (belongs to: QA & Balance / Combat)
- What the record says: Prototype bug KB-003: a parried exchange still gives the attacker a chain window, so 13% of counted chains are phantom. (qa/known-bugs.md:11; qa/known-bugs.md:77-91)
- What is actually true: Reproduced: after a parry (seed 1) the test sees '2 HIT CHAIN', -6 ki, 0 damage. openWindow (544-546) never checks ex.cancel and dirUpdate (572-574) then chains. The effects file kb3 shows 499 of 3,817 chain events phantom (13.1%), 3.817 reported against 3.318 real. This distorts a legacy baseline metric. Proof: audit/2026-11-07/evidence/AC-282.txt
- Cost of the false alarm: Noise in the safety inventory.
- Fix: Keep it in QA's prototype register and drop it from the safety inventory.

#### AC-283 Prototype bug KB-004: every chain strike ignores the defender's stance, putting 76.5 HP a match through a guard.
- Verdict: MISFILED (belongs to: QA & Balance / Combat)
- What the record says: Prototype bug KB-004: every chain strike ignores the defender's stance, putting 76.5 HP a match through a guard. (qa/known-bugs.md:12; qa/known-bugs.md:93-107)
- What is actually true: Reproduced: the guarded hits do 9.88 each, then the chain strike does 73.92 (seed 1). Line 554 passes ignoreStance:true. The effects file kb4 shows guardedExtraDamagePerMatch 76.54 and chain strikes at 18.5% of all damage. This is a balance bug in the legacy prototype. Proof: audit/2026-11-07/evidence/AC-283.txt
- Cost of the false alarm: Noise in the safety inventory.
- Fix: Keep it in QA's prototype register and drop it from the safety inventory.

#### AC-284 Prototype bug KB-005: a dodged signature freezes the defender 300 units up for 0.87 s.
- Verdict: MISFILED (belongs to: Combat)
- What the record says: Prototype bug KB-005: a dodged signature freezes the defender 300 units up for 0.87 s. (qa/known-bugs.md:13; qa/known-bugs.md:109-123)
- What is actually true: Reproduced (seed 4): the defender jumps +300 in one step at 0.82 s, then stays still for 52 steps (0.87 s). Line 616 sets D.y += 300 with zero velocity. The effects file kb5 shows 0.40 s a match. This is a feel issue, and whether it is a bug or the design is Combat's call. Proof: audit/2026-11-07/evidence/AC-284.txt
- Cost of the false alarm: Noise in the safety inventory.
- Fix: Keep it in QA's prototype register for Combat's call and drop it from the safety inventory.

#### AC-285 Prototype bug KB-006: the rush flies through terrain (15% of rushes) and through standing buildings (6.7%).
- Verdict: MISFILED (belongs to: QA & Balance / Combat)
- What the record says: Prototype bug KB-006: the rush flies through terrain (15% of rushes) and through standing buildings (6.7%). (qa/known-bugs.md:14; qa/known-bugs.md:125-139)
- What is actually true: Reproduced: in the mountains 25 of 36 rush steps are inside the ground (up to 547 units), and in the city 25 of 38 steps are inside towers. stepRush clamps only the last frame (748, 751). The effects file kb6 shows 14.8% and 6.7%. The test asserts all six bugs are present (8 passed). This is a collision and look issue in the legacy prototype. Proof: audit/2026-11-07/evidence/AC-285.txt
- Cost of the false alarm: Noise in the safety inventory.
- Fix: Keep it in QA's prototype register and drop it from the safety inventory.

#### AC-286 GB-002: the high-tier sky reaction read as a glowing patch, and the clouds shimmered as fighters moved. It was turned off by default in 632f6c9, and the shimmer above 4,800 units was fixed.
- Verdict: MISFILED (belongs to: Rendering)
- What the record says: GB-002: the high-tier sky reaction read as a glowing patch, and the clouds shimmered as fighters moved. It was turned off by default in 632f6c9, and the shimmer above 4,800 units was fixed. (qa/known-bugs.md:156-165)
- What is actually true: 632f6c9 makes sky_react_on false by default and reads the cloud pattern at the plain height (sky.gdshader cp line). Both are in the live pin 257a766c and at HEAD. The 4,800-unit figure comes from the commit's own README text. /play/?skyreact=1 can still turn the reaction on (URL_ARGS at the pin). Nobody has re-verified it in play, and I did not run Godot. A slow cloud crawl is a look fault, not a flash event. Proof: audit/2026-11-07/evidence/AC-286.txt
- Cost of the false alarm: Small. Carrying a look fix in safety records invites a flash re-check it does not need.
- Fix: Retire it from the safety records and keep it in Rendering's and QA's register. QA re-verifies it on a web capture when convenient.

#### AC-290 A setting may change only what is drawn, never what the sim computes, so players on different settings can still play each other and replays stay valid.
- Verdict: MISFILED (belongs to: Simulation & Engine / Netcode (architecture ADR))
- What the record says: A setting may change only what is drawn, never what the sim computes, so players on different settings can still play each other and replays stay valid. (docs/decisions/0012-turntable-and-quality-range.md:10; docs/decisions/0013-no-laptop-target.md:11)
- What is actually true: ADR 0012 item 3 and ADR 0013 item 4 state the rule. No sim .gd file outside tools reads reduced_motion, reduce_flashing or quality (grep empty), and the swing reduction exists only in render (split_rig.gd:1071). swing-motion.md:29 only recommends a sim flag agreed in the lobby and carried in the match header, which keeps the sim shared, and it is not built. I did not trace every settings path. Proof: audit/2026-11-07/evidence/AC-290.txt
- Cost of the false alarm: Small. The 'contradiction' note could prompt rework of an unbuilt proposal that already keeps the sim shared.
- Fix: Retire it from the safety records as a Simulation and Netcode architecture rule. If the swing flag is ever built, record it in an ADR as a match-header flag rather than a per-player setting.

#### AC-292 GB-008: a launch or charge cleared a lock-broken fighter's flag without the found event or the 6 s guard.
- Verdict: MISFILED (belongs to: Simulation & Engine / QA & Balance)
- What the record says: GB-008: a launch or charge cleared a lock-broken fighter's flag without the found event or the 6 s guard. (qa/known-bugs.md:181-187)
- What is actually true: fd381c6 replaces both direct clears with SimHiding.regainLock (now fighter.gd:730 and launch.gd:926). The remaining direct clear at exchange.gd:313 is for cover-hiding (canHide) fighters, and the lock-break branch next to it calls regainLock. I did not re-run QA's confirmation on df05b9f. It was an event-stream bug, now fixed. Proof: audit/2026-11-07/evidence/AC-292.txt
- Cost of the false alarm: Noise only. The record is accurate and closed.
- Fix: Keep it as a closed entry in QA's register and drop it from the safety inventory.

#### AC-293 The harness refuses a win share for a scripted player that pressed fewer than 100 times a match (SCRIPT BLIND), so a blind script cannot report a quiet 0 of 40.
- Verdict: MISFILED (belongs to: QA & Balance (harness))
- What the record says: The harness refuses a win share for a scripted player that pressed fewer than 100 times a match (SCRIPT BLIND), so a blind script cannot report a quiet 0 of 40. (docs/qa/brawl-qa-plan.md:76; docs/qa/brawl-qa-plan.md:82)
- What is actually true: timing-edge.js:130-131 replaces only the Verdict cell with 'SCRIPT BLIND (not a reading)'. The same row still prints the win share and interval (line 132), and the JSON keeps aWins. So the share is labeled, not refused. This is a QA harness matter for private test runs. Proof: audit/2026-11-07/evidence/AC-293.txt
- Cost of the false alarm: Small. A reader could take a printed 0 of 40 at face value if they miss the verdict cell.
- Fix: QA either blanks the win-share cell for blind rows or rewords the plan to 'marks the row not a reading'. Keep it out of the safety records.

#### AC-294 Six baselines printed launches 'by him' and 'on him' the wrong way round (the launch actor is the body sent), so their first-launch times are void.
- Verdict: MISFILED (belongs to: QA & Balance)
- What the record says: Six baselines printed launches 'by him' and 'on him' the wrong way round (the launch actor is the body sent), so their first-launch times are void. (docs/qa/README.md:73-74)
- What is actually true: SimFx.launch(S, f, by) sets actor to the body sent (fx.gd:702-704). players.gd:1076-1088 now reads the actor as sent and the target as launcher, with a comment dating the error to 2026-10-17. The rerun file exists. I did not open the correction blocks in the older documents. This is QA data hygiene. Proof: audit/2026-11-07/evidence/AC-294.txt
- Cost of the false alarm: Noise only. It is corrected and private.
- Fix: Keep it in QA's README changelog and drop it from the safety inventory.

### Team process, record-keeping and dev-machine hygiene (21)

#### AC-025 The records conflict on a reduced-motion dissolve: the audit wants it kept as an opt-in exception and camera_params.gd:226 says Legal asks for at least 0.3 s, while the swing review says a plain cut, ADR 0010 bans dissolves, and Legal withdrew the 0.3 s cross-dissolve as a preference, with a hard cut after a bright event counted by the clip readings.
- Verdict: MISFILED (belongs to: Camera (comments), Accessibility (audit doc); process)
- What the record says: The records conflict on a reduced-motion dissolve: the audit wants it kept as an opt-in exception and camera_params.gd:226 says Legal asks for at least 0.3 s, while the swing review says a plain cut, ADR 0010 bans dissolves, and Legal withdrew the 0.3 s cross-dissolve as a preference, with a hard cut after a bright event counted by the clip readings. (docs/accessibility/audit-2026-10-28.md:92; docs/accessibility/swing-motion.md:20; docs/decisions/0010-look-gate.md:11; +2 more)
- What is actually true: The records disagree, but no build dissolves: cut_dissolve is false at HEAD and the pin, and the only caller of set_cut_dissolve passes false. What is left is stale text: camera_params.gd:226 still says 'Legal asks at least 0.3', split_view.gd:314 still says '(default on)' though RL-229 asked for that fix, and audit-2026-10-28.md:88-92 describes a fade the help text now calls 'one step'. Proof: audit/2026-11-07/evidence/AC-025.txt
- Cost of the false alarm: Reviewers chase a conflict with no player effect, and the stale comment could be used to revive a dissolve Orb banned on the strength of a withdrawn Legal ask.
- Fix: Camera fixes the two code comments, Accessibility corrects the audit lines, and the item leaves the safety records.

#### AC-051 f01 echo ceiling: the earlier pass rested on VFX's false claim of at most two echoes alive at once. It was fixed in 868c15ee to two echoes; a staggered third is acceptable only if a tick-by-tick strip shows at most two alive.
- Verdict: MISFILED (belongs to: Legal (originality); process)
- What the record says: f01 echo ceiling: the earlier pass rested on VFX's false claim of at most two echoes alive at once. It was fixed in 868c15ee to two echoes; a staggered third is acceptable only if a tick-by-tick strip shows at most two alive. (docs/legal/review-log.md:128; docs/legal/review-log.md:144; git commit 868c15ee)
- What is actually true: The facts hold: 868c15ee (2026-10-06, VFX) says a perfect timed blow draws two echoes, not three, and ghost_tally.gd counts after-images at every instant. f01's stated reason is 'the many-armed barrage blur', so this is an originality ceiling, not a flash limit. The real lesson is process: Legal ruled on a director's unmeasured claim. Not checked: whether a tick-by-tick strip exists for a staggered third. Proof: evidence/AC-051.txt; 868c15ee subject: a perfect timed blow draws two echoes, not three
- Cost of the false alarm: An originality ghost cap filed under flash safety suggests a photosensitivity limit that does not exist.
- Fix: Move to Legal's originality record; as process, Legal rulings that rest on a director's numbers should cite a measurement or strip.

#### AC-060 Mods load under defined format, loading and validation rules.
- Verdict: MISFILED (belongs to: process (Modding director charter))
- What the record says: Mods load under defined format, loading and validation rules. (DIRECTORS.md:683; DIRECTORS.md:685; docs/directors/modding-extensibility.md:28; +1 more)
- What is actually true: The charter lines list mod format, loading and validation rules as deliverables still to be written. No docs/modding/ or mods/ exists, and no code loads packs or user content (no load_resource_pack). Nothing loads mods, so there is no release risk; the claim turns a charter line into a rule in force. Proof: evidence/AC-065.txt: 0 hits for load_resource_pack|user://mods|res://mods in HEAD .gd; 0 files under docs/modding or mods
- Cost of the false alarm: It suggests a mod security surface that rules already govern, when there is no surface and no rule.
- Fix: Retire it from the safety records. Add to the Modding charter that any mod loading must treat packed scripts as code execution and go to Legal and Tools before it ships.

#### AC-066 Internet play needs outside services (STUN, plus a paid TURN relay, or a forwarded port), so a ruling is required under ADR 0005 before any internet play.
- Verdict: MISFILED (belongs to: process (EP; Orb's scope and spend call))
- What the record says: Internet play needs outside services (STUN, plus a paid TURN relay, or a forwarded port), so a ruling is required under ADR 0005 before any internet play. (docs/net/rollback.md:206; docs/net/rollback.md:263; docs/net/cloud-reports/2026-10-28-transport.md:89)
- What is actually true: Netcode is right that internet play needs STUN, sometimes a paid TURN relay, or a reachable port, and ADR 0005 records the zero-budget and token-discipline decision. That is a budget and scope call for Orb, not safety. The privacy point, that a third-party STUN or TURN host sees player IP addresses, is not named. Proof: rollback.md:206 'a TURN relay, which costs money (ADR 0005: zero budget)'
- Cost of the false alarm: Small: it parks a budget question in the safety record and misses the real privacy duty.
- Fix: Move it to the EP's scope list for Orb. Add a Legal item: any STUN, TURN or relay host sees player IP addresses, which are personal data.

#### AC-154 Low-risk fallback titles Skyburden, Splendid Wreckage, Sky Arsonists and Redline Sky (RL-016, RL-017, RL-022, RL-023) are 'GO to counsel/next stage': stage 1-3 screens, not clearances, and whichever is picked goes through stages 4 and 5.
- Verdict: MISFILED (belongs to: process (Legal log hygiene))
- What the record says: Low-risk fallback titles Skyburden, Splendid Wreckage, Sky Arsonists and Redline Sky (RL-016, RL-017, RL-022, RL-023) are 'GO to counsel/next stage': stage 1-3 screens, not clearances, and whichever is picked goes through stages 4 and 5. (docs/legal/review-log.md:38-39; docs/legal/review-log.md:44-45; docs/legal/review-log.md:405-429; +4 more)
- What is actually true: The rows say this and the procedure is sound (review-log.md:431; name-screening.md:98), but Orb picked Orb Combat EX on 2026-09-29 (RL-024). The four rows still read 'Open until Orb picks' and are counted among the P0 gate's open flags at review-log.md:279 (the inventory's :270 pointer is stale). Their only live use is as fallbacks (go-to-market.md:111), which must be re-screened before use anyway. Proof: docs/legal/review-log.md:38-39, 44-45, 279, 414-438; docs/legal/name-screening.md:98, 136-145; docs/legal/go-to-market.md:111
- Cost of the false alarm: Stale title rows inflate the P0 gate's open-flag list and suggest legal exposure on names nobody is using.
- Fix: Mark RL-016, RL-017, RL-022 and RL-023 'Superseded by RL-024; kept as fallbacks' and drop them from the P0 flags at review-log.md:279.

#### AC-155 Title candidates Glorious Ruin and Sunburners are Medium and CONDITIONAL (album or .com collisions, confusion with live games Sunburnt and Sunburn and a band of near-identical name).
- Verdict: MISFILED (belongs to: process (Legal log hygiene))
- What the record says: Title candidates Glorious Ruin and Sunburners are Medium and CONDITIONAL (album or .com collisions, confusion with live games Sunburnt and Sunburn and a band of near-identical name). (docs/legal/review-log.md:40; docs/legal/review-log.md:43; docs/legal/review-log.md:410-421; +4 more)
- What is actually true: The rows match their detail (an album of near-identical name and a taken .com for Glorious Ruin; Sunburnt, Sunburn, a live band and a taken .com for Sunburners: name-screening.md:134-139). Both are superseded by Orb's 2026-09-29 pick yet stay 'Open until Orb picks' and in the P0 flags (review-log.md:279); the 2026-09-29 snapshot (including .com expiry dates now past) was not re-checked. Proof: docs/legal/review-log.md:40, 43, 279, 418-438; docs/legal/name-screening.md:134-139; evidence/AC-155.txt
- Cost of the false alarm: Two dead candidates count as open legal flags at the P0 gate.
- Fix: Close RL-018 and RL-021 as superseded by RL-024 (Sunburners stays last in the fallback order) and drop them from review-log.md:279.

#### AC-177 The 2026-10-06 rule against showing or describing buildings falling (w01, w02, RL-124 guard words, RL-127/RL-128 public-picture limits, 'never on a damaged building') was withdrawn on 2026-10-12 as the EP's over-literal reading of a sarcastic remark by Orb; originality, truthful claims, AI disclosure, photosensitivity, GitHub's rules (p01) and labelling (p02) stand, and ratings are re-read against a Mature target.
- Verdict: MISFILED (belongs to: process (EP and Legal record hygiene))
- What the record says: The 2026-10-06 rule against showing or describing buildings falling (w01, w02, RL-124 guard words, RL-127/RL-128 public-picture limits, 'never on a damaged building') was withdrawn on 2026-10-12 as the EP's over-literal reading of a sarcastic remark by Orb; originality, truthful claims, AI disclosure, photosensitivity, GitHub's rules (p01) and labelling (p02) stand, and ratings are re-read against a Mature target. (docs/legal/review-log.md:146; docs/legal/review-log.md:149; docs/legal/review-log.md:150; +8 more)
- What is actually true: RL-132 and movegen-banned.json's withdrawn list record the withdrawal, and vision.md:943-948 quotes Orb. The same amendment text is pasted on RL-124, RL-127, RL-128 and RL-129. The withdrawn rule was never a safety rule, and the rules that stand are tracked elsewhere. I did not check that every dependent ruling was re-made. Proof: docs/legal/review-log.md:154; docs/ep/vision.md:945-948
- Cost of the false alarm: It keeps an invented rule that was never about safety in the safety log. The pasted amendment misdescribes RL-129, whose guard was a public-count rule, not wording about towers.
- Fix: Keep it as a process lesson, correct RL-129's amendment text, and gate nothing on it.

#### AC-235 Before Orb's first play: the warning shows first, the match record saves even when a match is cut short, ten minutes of sim on several seeds runs with no errors, stuck states or hangs, the median frame is under 16.7 ms, and the exact build is kept outside the repo.
- Verdict: MISFILED (belongs to: process)
- What the record says: Before Orb's first play: the warning shows first, the match record saves even when a match is cut short, ten minutes of sim on several seeds runs with no errors, stuck states or hangs, the median frame is under 16.7 ms, and the exact build is kept outside the repo. (docs/ep/first-press-list.md:13; docs/ep/first-press-list.md:14; docs/ep/first-press-list.md:16; +1 more)
- What is actually true: The list says this (first-press-list.md:13-17). It was written on 2026-11-01 for Orb's private first play, which has since happened (vision.md:1654-1660). The warning is in force: the photo notice words are in a8bc66e2 terms.json. I found no saved result for the ten-minute run or the 16.7 ms median in docs/ep. It is a spent handover checklist, not a safety record. Proof: evidence/AC-235.txt
- Cost of the false alarm: Keeping a spent private checklist as a gate implies pass results that were never filed.
- Fix: Retire it as a safety item, and keep it as EP process with its results filed or the list closed.

#### AC-253 Accessibility options (remapping, timing assist, colour-blind palettes, shake and flash reduction, subtitles) are audited at each gate, and the checklist must pass at the P5 gate.
- Verdict: MISFILED (belongs to: process (Accessibility charter, EP's /gate))
- What the record says: Accessibility options (remapping, timing assist, colour-blind palettes, shake and flash reduction, subtitles) are audited at each gate, and the checklist must pass at the P5 gate. (DIRECTORS.md:602; DIRECTORS.md:605; DIRECTORS.md:614; +5 more)
- What is actually true: The charter and CLAUDE.md:107 do set an accessibility audit at each gate and a checklist pass at P5. But docs/accessibility/checklist.md has never been committed, and /gate briefs only QA, Production Operations and Legal, so no gate audits accessibility. Only one audit exists (2026-10-28), and hold-to-flurry is still 'Not built'. Proof: evidence/AC-253.txt (checklist.md absent in HEAD and in all history); .claude/commands/gate.md:5 lists QA, Production Operations, Legal only
- Cost of the false alarm: Carried as a safety gate, it gives false assurance: it reads as an enforced check, but the checklist does not exist and no gate runs it.
- Fix: Move it to process. Accessibility writes checklist.md, and the EP adds Accessibility to the /gate briefing list. Track it as P5 work.

#### AC-265 Open Legal flags for the P0 gate: RL-001, RL-002, RL-012, RL-014, RL-016 to RL-025, RL-027 to RL-030, RL-035, RL-036.
- Verdict: MISFILED (belongs to: process (EP and Legal bookkeeping))
- What the record says: Open Legal flags for the P0 gate: RL-001, RL-002, RL-012, RL-014, RL-016 to RL-025, RL-027 to RL-030, RL-035, RL-036. (docs/legal/review-log.md:270)
- What is actually true: The line lists 20 rows: 19 are still Open (several 'until Orb picks'), but RL-030 reads 'Closed until final art', so the list is not even accurate. No P0 gate was ever recorded (no gate packet; handoff.md:6 last says 'P0 is in progress') while later-phase work went ahead. RL-012 and RL-020 still say 'rename before public' though the repo is already public as orb-combat-ex. Not checked: whether RL-020's Must edits were made, or each flag's own release merits (other claims). Proof: evidence/AC-265.txt: git show HEAD:docs/legal/review-log.md, status column of each listed row, ls docs/production, handoff.md:6, git remote
- Cost of the false alarm: A stale gate list suggests the project is held at P0 and makes 20 rows of mixed age look like current blockers, hiding which ones matter for the web build or a store.
- Fix: Retire the P0 line. Legal reissues one open-flags list keyed by horizon (already-public, web, store) and closes rows whose condition is met (RL-012: repo renamed).

#### AC-266 Never put a prompt in front of Orb: sessions run in bypass mode and write commands that never trip the built-in safety check.
- Verdict: MISFILED (belongs to: process (EP; dev-machine hygiene))
- What the record says: Never put a prompt in front of Orb: sessions run in bypass mode and write commands that never trip the built-in safety check. (CLAUDE.md:19-23; CLAUDE.md:13)
- What is actually true: The rule is in force (commit 9631fc75). Its content, guarding every variable in rm -rf and telling the EP rather than waiting on Orb, protects Orb's PC and nothing a player touches. The records contradict each other: CLAUDE.md:13, DIRECTORS.md:7, playbook.md:19 and ADR 0002:11 say Auto mode, while CLAUDE.md:19 says bypass mode. Proof: evidence/AC-266.txt: CLAUDE.md lines 13 and 19-23 (no diff vs HEAD), DIRECTORS.md:7, playbook.md:19, ADR 0002:11, git log 9631fc75
- Cost of the false alarm: Filed as safety, it pads the safety record with dev-machine hygiene. The Auto-vs-bypass contradiction can lead a restarted session into the wrong mode.
- Fix: Move to a process or machine-rules section and state one permission mode in CLAUDE.md, DIRECTORS.md, the playbook and ADR 0002.

#### AC-267 Every risk has an owner and a mitigation, and the risk register is kept as a live document.
- Verdict: MISFILED (belongs to: process (Production Operations))
- What the record says: Every risk has an owner and a mitigation, and the risk register is kept as a live document. (DIRECTORS.md:514; docs/ep/playbook.md:33; docs/production/risk-register.md:3-15)
- What is actually true: Each of the 11 rows has an owner and a mitigation, but the register is titled 'starting set' and has not changed since 2026-09-28 (f9ec6ac6, 111b1a17). It has no photosensitivity, privacy, licence, title, rating or AI-disclosure row. DIRECTORS.md:510 also names docs/production/roadmap.md and gate packets as deliverables, and neither exists. The real release controls live in Legal's log and the build gates, not here. Proof: evidence/AC-267.txt: risk-register.md in full, git log -- docs/production/, a grep for safety topics (none)
- Cost of the false alarm: Readers may take the register as the project's risk picture and miss release risks tracked only in Legal's log.
- Fix: Either retire the register and point to Legal's review log and this audit, or have Production add the release risks with owners. It is a governance document, not a safety control.

#### AC-268 Only the EP changes git state (reviews, commits and pushes); directors edit only the paths they own, and every session runs in Auto permission mode.
- Verdict: MISFILED (belongs to: process (EP))
- What the record says: Only the EP changes git state (reviews, commits and pushes); directors edit only the paths they own, and every session runs in Auto permission mode. (docs/decisions/0002-directors-as-sessions.md:11-12; CLAUDE.md:14; DIRECTORS.md:8; +3 more)
- What is actually true: The rule is stated the same way in every cited source, and the many uncommitted director edits in the working tree fit it. Who made each commit can't be checked, because one git user made them all. The committed Legal log lags the live one: HEAD has no RL-247 row (a HOLD on Orb's bystander decisions) and leaves RL-248 to RL-255 below the detail section. 'Auto mode' conflicts with CLAUDE.md:19, which says 'bypass mode'. Proof: evidence/AC-268.txt: the rule lines, git diff --stat HEAD -- docs/legal/review-log.md (9+/8-), row line numbers in HEAD vs working tree, RL-247 status
- Cost of the false alarm: Filing a workflow rule as safety adds noise. The public repo's Legal log is one held row behind the live copy, which has no player effect.
- Fix: Keep as process. The EP commits Legal's reordered log with RL-247, and fixes the Auto/bypass wording.

#### AC-270 LAN version 1 is 'Ready, not started' and must not run until Orb says so, because the firewall step needs Orb's real yes.
- Verdict: MISFILED (belongs to: Netcode (process; Orb's PC hygiene))
- What the record says: LAN version 1 is 'Ready, not started' and must not run until Orb says so, because the firewall step needs Orb's real yes. (docs/net/lan-v1.md:3; docs/net/two-v-two-lan.md:12; docs/net/two-v-two-lan.md:50)
- What is actually true: The committed docs (last touched by a8bc66e2) still say LAN v1 has never run, but vision.md records Orb on 2026-11-07: 'both lan tests worked right out of the box', plus a first 2v2 with Orb 2. So the condition was met and the record is stale. The firewall step (one inbound UDP 47100 rule limited to the /24, removed afterwards) really does protect Orb's PC, at private horizon only. Not checked in code: whether the LAN kit is off in public builds. Proof: evidence/AC-270.txt: lan-v1.md:3,45,51; two-v-two-lan.md:12,50; git log; grep of vision.md for the LAN play; lan-n4 README:1
- Cost of the false alarm: A stale 'never run' condition makes LAN play look unapproved and can stall Netcode's next step. No player is at risk.
- Fix: Netcode marks lan-v1.md and two-v-two-lan.md as played on 2026-11-07 on Orb's word and keeps the remove-the-rule step. Not a safety record.

#### AC-271 Netcode exceeded its CPU cap (about 4 CPU-hours against 3), including a run at normal priority as a fourth Godot job.
- Verdict: MISFILED (belongs to: process (EP; machine discipline))
- What the record says: Netcode exceeded its CPU cap (about 4 CPU-hours against 3), including a run at normal priority as a fourth Godot job. (docs/net/cloud-reports/2026-10-28-ai-takeover.md:20; docs/net/cloud-reports/2026-10-28-ai-takeover.md:160-164)
- What is actually true: The self-report says exactly this (commit 9b111d15): 3.6 to 4.7 CPU-hours against 3, a 9-minute run that started without its arguments, and parity.gd for about 5 minutes at normal priority as a 4th Godot job. It also says nothing was left running. It is a machine-budget overrun with no player or release effect. Proof: evidence/AC-271.txt: report lines 20, 157, 160-164 and git log
- Cost of the false alarm: Filed as safety, it adds noise. At most it costs one EP ruling.
- Fix: Close it in the EP's process log and drop it from the safety records.

#### AC-272 Old-PC test of the private build: same warning before play, Orb alone watches, home address only with a /24 filter and 45-minute self-stop, no forwarding or tunnel, nothing recorded, and no flash number from it counts.
- Verdict: MISFILED (belongs to: process (Performance/Netcode private-test logistics; Orb's own risk acceptance))
- What the record says: Old-PC test of the private build: same warning before play, Orb alone watches, home address only with a /24 filter and 45-minute self-stop, no forwarding or tunnel, nothing recorded, and no flash number from it counts. (docs/legal/review-log.md:246 (HEAD))
- What is actually true: RL-224 sets these six conditions for a private performance test and is marked closed on the ruling. Condition (2), 'Orb alone watches', no longer holds for Orb 2: RL-253 and Orb's 2026-11-07 ruling let Orb 2 see what Orb sees. The network terms (home /24, no forwarding or tunnel) stand and protect Orb's home network. No public build is involved. Proof: evidence/AC-272.txt: HEAD review-log lines 246 and 467, vision.md last block
- Cost of the false alarm: It reads as a live safety condition, and applied literally it contradicts RL-253 and Orb's ruling on Orb 2.
- Fix: Mark RL-224 (2) as superseded by RL-253. Keep the network terms as private-test logistics owned by Performance and Netcode.

#### AC-274 The EP escalates every Legal flag to Orb, one clear question at a time, and directors never message each other.
- Verdict: MISFILED (belongs to: process (EP))
- What the record says: The EP escalates every Legal flag to Orb, one clear question at a time, and directors never message each other. (CLAUDE.md:12; CLAUDE.md:16; docs/ep/playbook.md:14; +1 more)
- What is actually true: All four sources state the rule. But Orb handed flash decisions to the team on 2026-10-18 ('You handle this', vision.md:1458), and RL-253 (1) says flash questions are not to be put to Orb, so 'every Legal flag' is no longer literally true. Directors never messaging each other is a chain-of-command rule with no release effect. Proof: evidence/AC-274.txt: the rule lines, vision.md:1458, RL-253 (1) excerpt
- Cost of the false alarm: As written, it would push flash questions to Orb against Orb's own instruction, or make the EP look non-compliant for not escalating them.
- Fix: Amend CLAUDE.md:16 and playbook.md:14 to carve out Orb's flash delegation (Legal and the EP decide; Orb is informed). Keep it as process.

#### AC-275 No phase closes until its exit criteria are met and QA, Production and Legal have signed off.
- Verdict: MISFILED (belongs to: process (EP and Production))
- What the record says: No phase closes until its exit criteria are met and QA, Production and Legal have signed off. (docs/ep/playbook.md:12; DIRECTORS.md:74; docs/directors/legal-ip.md:38)
- What is actually true: The rule is stated, but no phase gate was ever recorded. docs/production holds only risk-register.md (no roadmap or gate packets), handoff.md:6 last says 'P0 is in progress', and 19 of the 20 P0 Legal flags are still Open while later-phase work ships. In practice the rule is not in force. Release safety actually rests on Legal's per-item rows and the public-build gates. Proof: evidence/AC-275.txt: the rule lines, ls docs/production, a grep for gate packets, HEAD review-log:270
- Cost of the false alarm: It implies Legal and QA signed off each phase when none of that happened, which gives false comfort about screening.
- Fix: Either run /gate for the phases already passed, or retire phase gating in favour of release gates (web, store) with Legal and QA sign-off.

#### AC-276 QA harness hard caps so a run cannot hang the machine: --capsec 900, --wall 300 s, --budget, and godot.js guard() killing by PID after 100 minutes. Scripts run at most 3 jobs, headless only.
- Verdict: MISFILED (belongs to: QA (machine discipline))
- What the record says: QA harness hard caps so a run cannot hang the machine: --capsec 900, --wall 300 s, --budget, and godot.js guard() killing by PID after 100 minutes. Scripts run at most 3 jobs, headless only. (docs/qa/brawl-qa-plan.md:67; docs/qa/brawl-qa-plan.md:84-91; docs/qa/timing-edge-plan.md:92)
- What is actually true: Traced at HEAD: guard() kills by PID after QA_PROC_MS (default 100 min) and wraps the spawns in masher.js. players.gd, masher.gd and records.gd take --wall and --budget, and downtime.gd hard-codes 900 s of sim and 300 s of wall time. masher.js and timing-edge.js default to 3 jobs, but godot.js runRecords defaults to min(6, cpus-1), so 'at most 3' is a convention there, not a limit. This is dev-machine hygiene with no player effect. Proof: evidence/AC-276.txt: git show HEAD of godot.js, masher.js, timing-edge.js, players/masher/records/downtime.gd
- Cost of the false alarm: No player cost; it only inflates the safety count.
- Fix: Move it to QA/Tools machine docs, and optionally default runRecords to 3 jobs.

#### AC-277 Machine discipline: at most 6 Godot processes per session, never the same batch twice, stop only your own processes by PID, make sure test runs exit, start runs longer than about ten minutes at below-normal priority (measurements on a saturated machine are invalid), and start headless Chrome only through Tools' launcher with a time limit, below-normal priority and one software capture per session.
- Verdict: MISFILED (belongs to: Tools / process (dev-machine hygiene))
- What the record says: Machine discipline: at most 6 Godot processes per session, never the same batch twice, stop only your own processes by PID, make sure test runs exit, start runs longer than about ten minutes at below-normal priority (measurements on a saturated machine are invalid), and start headless Chrome only through Tools' launcher with a time limit, below-normal priority and one software capture per session. (CLAUDE.md:18; CLAUDE.md:24; CLAUDE.md:25)
- What is actually true: CLAUDE.md states the rules, and the browser launcher enforces part of them in code (below-normal or idle priority, a CPU cap, a hard deadline). They protect Orb's shared PC and the validity of measurements, not players or the release. Proof: evidence/AC-277.txt: CLAUDE.md:18,24,25; browser.mjs:8,202; capture-web.mjs:70
- Cost of the false alarm: No player cost; it inflates the safety records with dev-machine hygiene.
- Fix: Keep these under the process/machine rules owned by Tools and the EP, outside the safety records.

#### AC-278 Token discipline under ADR 0005 (Pro plan, zero budget, workflows or ultracode only with Orb's per-task approval) still stands in CLAUDE.md and the ADR, although Orb ordered on 2026-11-06 that all token limits be purged.
- Verdict: MISFILED (belongs to: process (EP; Orb's direction on spend))
- What the record says: Token discipline under ADR 0005 (Pro plan, zero budget, workflows or ultracode only with Orb's per-task approval) still stands in CLAUDE.md and the ADR, although Orb ordered on 2026-11-06 that all token limits be purged. (docs/decisions/0005-lean-team-and-token-discipline.md:10; docs/decisions/0005-lean-team-and-token-discipline.md:23; CLAUDE.md:17; +4 more)
- What is actually true: This is true and stale. CLAUDE.md:17 and ADR 0005:10 still require Orb's per-task OK for workflows (the ADR was amended only for the 2026-10-23 push), and vision.md:47 still says 'Pro plan only'. vision.md:1656 records Orb's 2026-11-06 order: 'PURGE ALL FLOATING TOKEN-RELATED LIMITS'. It is a spending matter with no player or release effect, and the machine rules are separate and still stand. Proof: evidence/AC-278.txt: CLAUDE.md:17, ADR 0005 lines 3, 10, 21-23, vision.md:47, 73 and Orb's 1656 order, handoff.md:94, git log of ADR 0005
- Cost of the false alarm: Sessions that follow CLAUDE.md under-use the budget Orb wants used, against Orb's direction. No safety effect.
- Fix: The EP adds an ADR 0005 amendment for Orb's 2026-11-06 order and updates CLAUDE.md:17 and vision.md:47 and :73, keeping the machine rules.

### Design rules (pillar 5, tone, tuning): Game Design, Narrative, World (13)

#### AC-178 The civilian band (12 to 30% of civilians lost at the KO, reported with the split by fighter) is re-based on places reached by a rule fixed in data (9,000 reach); the whole-planet total is reported at every read with surprises going to Legal, the band is never a design input, and any change to the reach comes back to Legal.
- Verdict: MISFILED (belongs to: QA & Balance; Game Design)
- What the record says: The civilian band (12 to 30% of civilians lost at the KO, reported with the split by fighter) is re-based on places reached by a rule fixed in data (9,000 reach); the whole-planet total is reported at every read with surprises going to Legal, the band is never a design input, and any change to the reach comes back to Legal. (docs/qa/three-strength-qa-plan.md:152; docs/legal/review-log.md:266 (HEAD); docs/legal/review-log.md:267 (HEAD))
- What is actually true: farReach 9000 is in field.json:21, but plans.placesReached and WorldCollateral.placesReached are not on main: they exist only in docs, the parked places-reached diff and an optional read in records.gd. The band is a balance band that Legal itself says is never a target. Proof: audit/2026-11-07/evidence/AC-178.txt
- Cost of the false alarm: Treating a balance band and an unlanded denominator as safety rulings sends every reach change back to Legal and implies the band protects players.
- Fix: Move the band to QA & Balance and Game Design. Correct RL-245's 'written in data' until the park lands.

#### AC-185 The landmark nudge reads structures only, the same for every fighter, and the player's input wins; the Cyborg's meter is fed only by objects counted by mass, never people or c09 places; labs count only as unmanned structures; no real station, agency, flag or company is named.
- Verdict: MISFILED (belongs to: Game Design and Narrative (pillar 5); Legal only for real-entity names)
- What the record says: The landmark nudge reads structures only, the same for every fighter, and the player's input wins; the Cyborg's meter is fed only by objects counted by mass, never people or c09 places; labs count only as unmanned structures; no real station, agency, flag or company is named. (docs/legal/review-log.md:238 (HEAD))
- What is actually true: nudgeList scores places by placeBuildings[kind] and turn angle only, the same for every fighter, and any stick change ends a nudge (swing.gd:1049). The Cyborg's hunger exists only as a +5 taunt entry in combat_barks.json, with no hunger stat in sim/, so the object-only feed is unbuilt. The rule is pillar-5 and tone design. Only 'no real company or agency named' has a real (trademark) kernel, and nothing names one yet; labs were not checked because none are built. Proof: audit/2026-11-07/evidence/AC-185.txt; git grep hunger -- sim data: only data/narrative/combat_barks.json:101
- Cost of the false alarm: Keeps an open Legal row and a QA batch over a design rule for a meter that does not exist, and Narrative and Game Design wait on Legal's sign-off.
- Fix: Move the nudge and fuel rules to Game Design and Narrative as pillar-5 design rules. Keep only a one-line trademark check (no real agency or company names) for Legal.

#### AC-186 Hero care-relief lever: the trigger counts sends only, relief scales the mark-down by one factor with a data floor of at least half, the hero's populated landings stay below the villain's, the 30% band binds, and it never reaches c09 places.
- Verdict: MISFILED (belongs to: Game Design (AI tuning, pillar 5); QA)
- What the record says: Hero care-relief lever: the trigger counts sends only, relief scales the mark-down by one factor with a data floor of at least half, the hero's populated landings stay below the villain's, the 30% band binds, and it never reaches c09 places. (docs/legal/review-log.md:241 (HEAD))
- What is actually true: DirRelief is built and off (relief.enabled false). The trigger counts building sends only, applies to AI fighters with care only, and returns max(scale, floor) with floor 0.5. The schema holds scale and floor at 0.5 or more. QA's rows (3) to (5) have not been read. This is AI tuning under pillar 5, and the 12 to 30% band is the team's own band, not a rating rule. Proof: audit/2026-11-07/evidence/AC-186.txt; launch.json relief: enabled false, floor 0.5; schema minimum 0.5
- Cost of the false alarm: Gates an AI tuning lever behind a Legal row and three QA batch rows, and it frames ordinary hero-AI tuning as legal exposure.
- Fix: Move to Game Design as a balance and pillar-5 check, with QA's rows as design checks. Close the Legal row.

#### AC-187 Far-town people feed only the hero's anguish as a cost, with no counter shown and no menace, power, Witness or aggression sink; QA reads the band over places reached and the absolute tour total, and repeats the civilians-removed run.
- Verdict: MISFILED (belongs to: Game Design and World (pillar 5); QA)
- What the record says: Far-town people feed only the hero's anguish as a cost, with no counter shown and no menace, power, Witness or aggression sink; QA reads the band over places reached and the absolute tour total, and repeats the civilians-removed run. (docs/legal/review-log.md:250 (HEAD))
- What is actually true: The far branch in WorldCollateral.kill writes only anguish, and only on fighters with hasAnguish, then returns before the budget, popHist and _feed paths. It is behind plans.farPeople and farAnguish, both false. No QA band read was found. This is pillar-5 design (the hero is pressured by losses, the villain gains nothing). Proof: audit/2026-11-07/evidence/AC-187.txt; field.json farPeople false, farAnguish false
- Cost of the false alarm: An open Legal row and two QA reads gate a World feature that is a design choice.
- Fix: Move to Game Design and World as a pillar-5 rule. QA's band and civilians-removed reads stay as design checks.

#### AC-188 Power scale: a block collapse reads no occupancy, shows no one dying and has no ceremony; its light is one catastrophe-class event; the burning trail never chars the body; beam damage to buildings is capped at x1.5; QA re-reads the band at maximum tier.
- Verdict: MISFILED (belongs to: Game Design (tone); Accessibility for the light event)
- What the record says: Power scale: a block collapse reads no occupancy, shows no one dying and has no ceremony; its light is one catastrophe-class event; the burning trail never chars the body; beam damage to buildings is capped at x1.5; QA re-reads the band at maximum tier. (docs/legal/review-log.md:254 (HEAD))
- What is actually true: The block collapse into the crater is not built (no levelIn in sim at HEAD), and power.json, which holds the burn glow, is off. The x1.5 is already the tier-4 beam.structure value in ladder.json at HEAD and in the public pin. The schema bounds it only at a minimum of 0, so the 'cap' lives in Legal's record alone. Most of the claim is tone (no ceremony, no charring). The light condition is already covered by the general flash rules and gates. Proof: audit/2026-11-07/evidence/AC-188.txt; ladder.json beam.structure [0.25,0.5,1.0,1.5] at HEAD and 257a766c; schema items minimum 0 only; power.json enabled false
- Cost of the false alarm: It adds a Legal sign-off to a number that has shipped since the pin, and it pulls tone choices into the safety records.
- Fix: Move the tone limits to Game Design and the light limit to the existing flash checks (Accessibility, VFX). If the 1.5 matters, add a schema maximum.

#### AC-189 The struggle meeting crater makes a large fall part of most matches: QA reads the band at every tier with overwhelm endings as their own row, over 30% means numbers come down with no exemption, barred places are spared and not left hovering, and at most three special craters fall per step.
- Verdict: MISFILED (belongs to: Game Design and World (tuning); QA)
- What the record says: The struggle meeting crater makes a large fall part of most matches: QA reads the band at every tier with overwhelm endings as their own row, over 30% means numbers come down with no exemption, barred places are spared and not left hovering, and at most three special craters fall per step. (docs/legal/review-log.md:268 (HEAD); docs/legal/review-log.md:465 (HEAD); docs/legal/review-log.md:468 (HEAD))
- What is actually true: WorldStruggleMeet is built and off (struggleMeet.enabled false at HEAD and a8bc66e2) and is absent from the public pin. It skips barred landmarks at lines 155 and 180. No code caps special craters at three: that is a 'come back to Legal' rule. The 30% band is the team's own design band. The 'not hovering' dig and the band reads were not checked. Proof: audit/2026-11-07/evidence/AC-189.txt
- Cost of the false alarm: An every-tier band batch plus an overwhelm row are held as Legal gates over a crater-size tuning question.
- Fix: Move the band and crater limits to Game Design, World and QA as tuning checks. Keep only the flash envelope (RL-246 (4)) in the safety records, under the flash gates.

#### AC-191 Wreck Toss counts every living civilian within 3 bh, indoors or out, and never aims a landing near people.
- Verdict: MISFILED (belongs to: Game Design and World (pillar 5))
- What the record says: Wreck Toss counts every living civilian within 3 bh, indoors or out, and never aims a landing near people. (docs/legal/review-log.md:208 (HEAD))
- What is actually true: The query is built: nearBh is 3, and livingNear counts standing buildings' popAlive plus a running district flight. No gameplay code calls WorldWrecks (tools only), so Wreck Toss and its aiming planner are not wired. 'Never aim near people' is the pillar-5 design rule, not a legal one. Proof: audit/2026-11-07/evidence/AC-191.txt; no WorldWrecks. callers outside /tools/
- Cost of the false alarm: An open Legal row on an unwired move, which makes a design rule look like a legal requirement.
- Fix: Move to Game Design and World as a pillar-5 rule for the planner when it is built.

#### AC-193 Cyborg ground claims and co-op beat lines read wear state, never casualty counts, with no people, no remains and no toll-scaled advantage (ln04), enforced in the picker and lint (ln05).
- Verdict: MISFILED (belongs to: Narrative (pillar 5))
- What the record says: Cyborg ground claims and co-op beat lines read wear state, never casualty counts, with no people, no remains and no toll-scaled advantage (ln04), enforced in the picker and lint (ln05). (docs/legal/review-log.md:187 (HEAD); docs/legal/review-log.md:195 (HEAD))
- What is actually true: The line lint already carries ln04 and ln05 for Cyborg lines (line-lint.py:67-78). The ground picker (ringpick.gd) names no people or toll term. The beat templates are pending only and not wired into sim or data, so that picker is unbuilt. The 'until the lint carries ln05' part of the record is stale, and the rule itself is pillar-5 tone. Proof: audit/2026-11-07/evidence/AC-193.txt
- Cost of the false alarm: Two Legal rows stay open, one on a condition already met.
- Fix: Close the lint part. Move the remaining picker rule to Narrative as a pillar-5 writing rule.

#### AC-197 Places barred by c09 (school, hospital, place of worship) take no damage from any blast, fall or unaimed body hit, with no shield, glow or marker shown.
- Verdict: MISFILED (belongs to: World (consistency rule))
- What the record says: Places barred by c09 (school, hospital, place of worship) take no damage from any blast, fall or unaimed body hit, with no shield, glow or marker shown. (docs/legal/review-log.md:264 (HEAD); docs/legal/review-log.md:265 (HEAD); sim/director/arc.gd:125 (HEAD))
- What is actually true: At HEAD the noTarget spare covers the meteor blast, area damage, brunt splash, body strikes and the struggle crater. A straight or lobbed energy shot that hits the chapel still damages it, because shots.gd and blast.gd shotBuilding have no noTarget check and shots.structures is true at HEAD and a8bc66e2. The public pin has no noTarget at all. Legal itself says c09 does not need the spare ('one rule beats two') and accepts incidental hits (RL-243), so this is a World consistency rule. Proof: audit/2026-11-07/evidence/AC-197.txt; grep -c noTarget sim/core/shots.gd sim/world/blast.gd = 0 and 0; shots.json structures true
- Cost of the false alarm: A closed Legal row claims 'any blast' coverage the code does not have, so a later audit or the look gate may treat a shot hit on the chapel as a legal breach.
- Fix: Move to World. Either add the noTarget check to shots._building, or record direct shot hits as accepted incidental hits under RL-243.

#### AC-261 Gameplay assists that change outcomes (late-answer grace, wider chord and slip windows, a single-button vanish) must be deterministic and recorded in the match settings and replay header. Their use in versus, ranked and online play is Orb's call.
- Verdict: MISFILED (belongs to: Game Design / Orb's direction)
- What the record says: Gameplay assists that change outcomes (late-answer grace, wider chord and slip windows, a single-button vanish) must be deterministic and recorded in the match settings and replay header. Their use in versus, ranked and online play is Orb's call. (docs/accessibility/beam-alert-review.md:41-45; docs/accessibility/right-hand-controls.md:48; docs/accessibility/right-hand-controls.md:58)
- What is actually true: None of the named assists exists: there is no late-answer grace and no wider chord or slip window in data or sim. The principle already holds for today's assists, because the setup's 'assists' list is copied into the replay header. Allowing them in versus or ranked is a fairness decision for Orb and Game Design, not release safety. Proof: evidence/AC-261.txt
- Cost of the false alarm: It keeps a fairness policy for features that do not exist on the safety list.
- Fix: Move it to Game Design's open questions for Orb, and raise it again when an assist that changes outcomes is built.

#### AC-287 GB-004 to GB-007, playtest observations: a ranged press locks both fighters (a design question), mountain tumbles gain too much momentum, launched fighters flew feet first (fixed cce8a59), and levitating rocks ride along with a fast fighter.
- Verdict: MISFILED (belongs to: QA & Balance (register); Game Design, World, Animation, VFX)
- What the record says: GB-004 to GB-007, playtest observations: a ranged press locks both fighters (a design question), mountain tumbles gain too much momentum, launched fighters flew feet first (fixed cce8a59), and levitating rocks ride along with a fast fighter. (qa/known-bugs.md:174-177)
- What is actually true: cce8a59 exists: head-first launch flight plus lead_scan.gd. GB-007 is already fixed in code by 0c1d39f7: rocks.gd:144-156 lets the pieces go in world space when the fighter speeds up, so the register's 'open' is stale. I did not check GB-004 or GB-005 in code. All four are feel or look matters. Proof: audit/2026-11-07/evidence/AC-287.txt
- Cost of the false alarm: A stale 'open' on GB-007 can send VFX to re-fix something already fixed. None of the four bears on release safety.
- Fix: Retire them from the safety records. QA marks GB-007 fixed in 0c1d39f7 and re-verifies it. GB-004 goes to Game Design and GB-005 to World.

#### AC-288 GB-009: a brink fighter could not be finished by bolts alone. The finish was fixed in df05b9f, but the blaster's win rate (82 to 88% against scripts) is open balance.
- Verdict: MISFILED (belongs to: Game Design / QA & Balance)
- What the record says: GB-009: a brink fighter could not be finished by bolts alone. The finish was fixed in df05b9f, but the blaster's win rate (82 to 88% against scripts) is open balance. (qa/known-bugs.md:189-194)
- What is actually true: df05b9f exists ('the barrage counts every clean shot of any kind, window 120 (GB-009)'), and timing-edge.js has the E4 and E5 rows with a 95% finish bar. The 82.5 to 87.5% win rates are QA's reported numbers. I did not re-run them, because that needs Godot. This is a balance question. Proof: audit/2026-11-07/evidence/AC-288.txt
- Cost of the false alarm: Noise in the safety inventory.
- Fix: Keep it as an open balance item for Game Design, outside the safety records.

#### AC-289 A drifting brawl must never pass through a building face or damage a building (hard row C5).
- Verdict: MISFILED (belongs to: QA & Balance / Encounter / World)
- What the record says: A drifting brawl must never pass through a building face or damage a building (hard row C5). (docs/qa/three-strength-qa-plan.md:49; docs/qa/three-strength-qa-plan.md:97)
- What is actually true: C5 is a planned hard row, and plan:97 says it is not built. WorldStructures.blockedAt exists (structures.gd:143). Nothing shows whether brawls clip buildings today. It is a collision and feel rule, not release safety. Proof: audit/2026-11-07/evidence/AC-289.txt
- Cost of the false alarm: Noise in the safety inventory, and an unbuilt gate that could read as a release blocker.
- Fix: Keep C5 as a QA gameplay gate and build the nudging script with Encounter. Drop it from the safety inventory.

### Business and other (1)

#### AC-219 Legal's four guides for Orb (licence, selling, company or individual in <state>, the stomp and ratings) are general information; the <state> fee and tax figures are unverified and must be checked on the state's site and by a lawyer and an accountant, and an LLC limits liability only if money and records are kept separate.
- Verdict: MISFILED (belongs to: Orb's business decisions (Legal as adviser))
- What the record says: Legal's four guides for Orb (licence, selling, company or individual in <state>, the stomp and ratings) are general information; the <state> fee and tax figures are unverified and must be checked on the state's site and by a lawyer and an accountant, and an LLC limits liability only if money and records are kept separate. (docs/legal/review-log.md:174 (HEAD); docs/legal/guide-company-or-individual-<state>.md:3; docs/legal/guide-company-or-individual-<state>.md:7; +1 more)
- What is actually true: review-log.md:174 and the guide (lines 3 and 7) say this. It is business-formation advice for Orb, not release safety. One figure checks out on the state's own site: an <state> LLC annual report costs $100. The $100 filing fee appeared only in search snippets and was not opened. Proof: docs/legal/review-log.md:174; docs/legal/guide-company-or-individual-<state>.md:3,7; audit/2026-11-07/evidence/AC-219.txt. External: https://sos.<state>.gov/business/pages/dont-be-misled.aspx (accessed 2026-11-07): 'limited liability company (LLC) annual report is only $100'
- Cost of the false alarm: An open 'risk' row on the store gate that is really Orb's business paperwork, which keeps it on safety lists until a lawyer and an accountant are paid.
- Fix: Move it to Orb's business to-do list (homework) with Legal as adviser, and mark the annual-report fee as checked.
