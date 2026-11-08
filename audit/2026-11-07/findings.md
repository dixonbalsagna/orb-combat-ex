# Findings

Independent Audit of 2026-11-07. Baseline 8d9b98a2 (HEAD 53b6df82 adds one doc). The public /play/ build is pin 257a766c; the private LAN builds are a8bc66e2. Only CONFIRMED claims and gaps (GAP: the team never recorded it) appear here, worst first. Every S1 and S2 finding had a blind second read by a reviewer who did not see the verdict (`evidence/cold-reviews.json`). Verifier reasoning for each AC is in `evidence/verify-v01.json` to `verify-v20.json`.

**No S1 finding survived.** Six S2 findings need action; three of them (F-01, F-02, F-03) are about the public site and must be acted on before the owner interim expires on 2026-11-15.

| ID | Sev | What it is, in plain words | Origin | Horizon |
|---|---|---|---|---|
| F-01 | S2 | The public test build has scenes the team's own flash check reads over the limit, and the safeguards it was approved on have stopped | AC-002, AC-003, AC-005, AC-021, GAP G-02 | already public |
| F-02 | S2 | Nobody can take the public build down through the documented switch, and its end date will not take it down either | GAP G-05, AC-212 | already public |
| F-03 | S2 | Every automated check has been off since 2026-11-06 and nobody noticed | GAP G-01, AC-238 | already public |
| F-04 | S2 | The game's own flash limiter cannot see the camera and scenery changes that caused the failures; main has also dropped one of its mitigations | GAP G-04, GAP G-03 | already public; main |
| F-05 | S2 | The villain grows stronger for every civilian he kills, in the public build too, against Orb's written rule | AC-169, GAP G-06 | already public; store |
| F-06 | S2 | The title has only been web-screened and collides with an earlier game called OrbCombat | AC-073, AC-086 | store |
| F-07 | S3 | Personal details about Orb are in the public repo and its history | AC-239, AC-151 | already public |
| F-08 | S3 | Public text says things that are not true (offline, "we are fixing them", "open source", "official" engine) | GAP G-09, AC-007, AC-049, AC-199, AC-202 | already public |
| F-09 | S3 | The flash measurement chain has holes: an analyser defect, no calibration, a gate that passes by exception, a coverage gap | AC-005, AC-021, AC-028, AC-038, GAP | already public; store |
| F-10 | S3 | In the private LAN build the other PC can freeze or crash your game | GAP G-07, GAP G-08 | private |
| F-11 | S3 | The public repo has no safety net: no secret scanning, no protected main, no recorded review of AI-written code | GAP, AC-248 | already public |
| F-12 | S3 | A desktop workflow could publish a game binary with full flashing on, for 14 days | AC-240, GAP | already public (never run) |
| F-13 | S3 | Store readiness: ratings answers, provenance rows, music terms, signing and icon are not ready | AC-093, AC-170, AC-273, GAP | store |
| F-14 | S3 | Accessibility: the public build lacks fixes main already has; sounds are not captioned; one setting does nothing | AC-251 to AC-257, AC-264, AC-252, GAP | already public; private |
| S4 notes | S4 | Ten smaller items | various | various |

---

### F-01 [S2] A photosensitive visitor who clicks through the warning on /play/ can meet scenes the project's own flash check reads above the three-a-second limit, and the safeguards that build was approved on have stopped
- Origin: AC-002, AC-003, AC-005, AC-021 (team raised it); GAP G-02 (the reduced-mode readings of the exact live pin were never pulled together).
- Where (at baseline 8d9b98a2):
  - tools/site.json:5-11: pin 257a766c; interim "owner Orb 2026-10-18", expires 2026-11-15.
  - Reduce flashing locked on in the live pack (evidence/AC-001.txt: curl of /play/index.pck shows `"lock_reduce_flashing": true`, build commit 257a766).
  - In that only available mode, the team's analyser recorded a primary reading of 3.5 on seed clips ai-1047, ai-1049 and ai-1050 (tools/web-template.json:55-75, 2026-10-28; docs/tools/pin-child.md:39). The signature clip reads 3 / 3 / 3 (tools/flash/signature-gate.json:6-8).
  - docs/legal/review-log.md:183 (RL-161): Orb's decision was made on "58 of 60 clips under 3, 2 at 3.5", with these conditions: "take-down on any new scene over 3.5, any report, or an unmeasured commit change"; the interim ends "2026-10-25 without Orb renewing in writing".
- Evidence (what was read or run):
  - The live /play/ page and pack (evidence/live-play-index.html, evidence/AC-001.txt).
  - The readings files above.
  - The nightly history: tools/flash/nightly-seeds.json:115, last run 2026-10-30, none since.
  - IR-02 (ir-log.md): the extension to 2026-11-15 was made by a Tools commit (9b293cce), with no written renewal from Orb shown. Since 2026-10-18 nobody has told Orb of a reading over 3 on this pin, or that the nightly lapsed. The block is the EP's own note that flash topics are not raised with Orb, which itself says "nothing public without the existing gates (demo pin, RL-209, RL-212 tripwires)". Nobody checked those gates kept running.
- Why it matters at release: WCAG 2.3.1 fails anything that "flashes more than three times in any one second period" (https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html, accessed 2026-11-07). The build is free, unpromoted, noindex and behind an explicit warning, which is why this is S2 rather than S1. But the risk Orb accepted on 2026-10-18 was a measured, watched, time-limited one. Today it is unmeasured, unwatched and running past its own conditions, and Orb has not been told.
- How certain the readings are: the analyser is the team's own and has never been calibrated (tools/flash/wcag.js:3). Tools' own repeat test reads the same collapse at 3.5 at 960x540 and 2.0 at 1024x768 (docs/tools/flash-proof.md). A defect can also under-count (F-09). So whether the live build really fails 2.3.1 is not known either way. Orb's doubt is reasonable, and it is a reason to settle the question with a recognised measurement, not to leave the build up on lapsed checks.
- Likelihood: low (few visitors, explicit warning, Reduce flashing locked on). Evidence strength: documented only (recorded readings); the lock and the gate are reproduced from the live site.
- Cold review: agreed, S2 (AC-002: partly; the older 4.5 figures are stale, but the 3.5 reduced seeds on this pin hold. AC-003: partly; the waiver is real and the enforcement half is not working. G-02: yes).

### F-02 [S2] If a visitor reports a seizure or a rights holder complains, the documented take-down does nothing, and the 2026-11-15 end date will not remove the build either
- Origin: GAP G-05; AC-212 (Legal's take-down plan, which assumes a working kill switch).
- Where:
  - tools/site-offline.mjs:1-5, 33-35: it only rewrites tools/site.json ("Commit and push tools/site.json to publish it").
  - .github/workflows/ci.yml:528: the only Pages deploy needs all eight CI jobs, and they cannot run (F-03).
  - .github/workflows/ci.yml:15-18: no schedule.
  - tools/check-site-interim.mjs:78: the expiry is a CI failure message, not a take-down.
  - Pages build_type is "workflow" (gh api).
- Evidence: traced in code, plus the gh API. The live /play/ and index.pck still carry Last-Modified 2026-11-05 (cold review G-05). No contact address exists on /, /play/ or /about/ (cold review AC-212).
- Why it matters: RL-161's own condition is a take-down on any report. Today the only working route is a manual GitHub Pages unpublish (repository Settings, or the Pages API), which is written down nowhere, and nobody outside can reach the project to report anything.
- Likelihood: certain that the end date passes on 2026-11-15 with the build still up unless someone acts; a report is unlikely. Evidence strength: traced in code.
- Cold review: agreed, S2 (G-05: yes; AC-212: partly, and it adds that the missing contact address already applies to the public pages, not just a future store build).

### F-03 [S2] Since 2026-11-06 not one automated safety check has run, on 58 commits, and nobody noticed for a day and a half
- Origin: GAP G-01; AC-238 (the data gate it switched off).
- Where:
  - .github/workflows/ci.yml:226 and :240, duplicated at :263 and :277: step names with an unquoted ": " (invalid YAML), from 3c9005ac (2026-11-06) and 85884449.
  - GitHub's run page says "Invalid workflow file ... error in your yaml syntax on line 226" (cold review G-01).
- Evidence: evidence/ci-dead-root-cause.txt (37 runs, 0 jobs each; last success 72a4d1e4 on 2026-11-05). tools/check-workflows.mjs flags exactly these four lines, but it runs inside ci.yml, so it cannot run (gates-other.json). IR-01b: the EP did not check CI after pushing. Its local gate ran on scratch trees, skipped the site and ENet checks, and its outputs were deleted before the notice.
- Why it matters: the flash count, data schemas, site checks, network checks and parity have not run on any commit since. That includes a8bc66e2, the build handed to Orb and Orb 2. The deploy is blocked as a result, which by luck has frozen the public site, but it also blocks the take-down (F-02). And fixes already on main (accessibility, the in-game notice words, the F8 lock) cannot reach the public build.
- Likelihood: high (it is happening). Evidence strength: reproduced (gh API, GitHub's own error page, the lint run).
- Cold review: agreed, S2 (G-01: yes in every particular).

### F-04 [S2] The game's built-in flash limiter cannot see the camera cuts and scenery sweeps that produced the recorded failures, and on main Reduce flashing no longer slows the scenery sweep
- Origin: GAP G-04; GAP G-03.
- Where:
  - render/vfx/flash_registry.gd:24-25, same text in 257a766c: it "cannot see scenery sweeping past a moving camera, a panel wiping open or a whole-screen dip unless the system that makes it asks"; "the analyser on the recorded clips stays the test".
  - Only four camera or UI changes ask it: split_view.gd:144 cut_dip, split_view.gd:393 cut_in_panel, split_rig.gd:2290 transform_cut, ui_hud.gd:4234 divider_slam.
  - split_rig.gd:5017-5019: _mark_cut asks nothing, for side_swap, relocate and the other hard cuts.
  - render/camera/camera_params.gd:147-148 (HEAD and a8bc66e2): SCROLL_MAX_REDUCED 0.045, equal to SCROLL_MAX. At 257a766c:139 it was 0.03, with the comment "collapse, 4.5 flashes a second"; it was changed in 5fe08207 (2026-10-22) "while the flash work is paused".
- Evidence: traced in code at HEAD, the pin and a8bc66e2 (cold reviews G-03, G-04; gates-flash.json rows 6 and 20).
- Why it matters: the limiter and the Reduce flashing lock are the only flash mitigations that act inside a build. The CI flash "gate" only recounts what the limiter granted, so it cannot catch what the limiter cannot see (F-09). Any future public pin taken from main loses the scroll mitigation, and the LAN builds already have.
- Likelihood: medium (camera motion is in every match). Evidence strength: traced in code.
- Cold review: G-04 agreed S2, noting that a few camera changes do ask; G-03 rated S3 on its own (main and private only). The auditor keeps them together at S2 because both sit under the only in-build mitigation.

### F-05 [S2] The villain gets stronger for every civilian he kills, in the public build and on main, which breaks Orb's written rule; Orb was told it is on main but not that the public build has it
- Origin: AC-169; GAP G-06 (the power half is in no record).
- Where:
  - sim/world/collateral.gd:330 and :351-358 (HEAD): `cause.menace += n * md.menaceCas * norm` and `cause.power += n * 0.09 * norm`. The same lines are at 257a766c:sim/world/collateral.gd:244 and :265-272, and in a8bc66e2.
  - data/fighters/RIVAL/meters.json:13-17 (casualty source 0.9) and :32-47 (effects).
  - sim/core/fighter.gd:684-688.
  - Orb's pillar 5 (CLAUDE.md design pillar 5; vision.md, 2026-10-31): "never on civilian deaths".
- Evidence: traced in code at all three commits (cold reviews AC-169, G-06). Menace gives up to +1 ki regen a second, up to x1.05 damage and up to +8 beam clash power; power counts toward his form tiers. IR-02d: Orb was told the breach is live on main, not that /play/ has it. The fix is held under Orb's bystander hold (RL-247, uncommitted).
- Why it matters: it breaks one of the seven design pillars in the build the public can play. A store's content survey and an IARC-style questionnaire would have to declare a game reward for killing civilians, which can raise the rating. It must be fixed, or knowingly kept and declared, before any store release.
- Likelihood: high (casualties happen in every match at every tier). Evidence strength: traced in code.
- Cold review: both reviewers confirm the facts in full; both rate it S3. The auditor keeps S2 for the reasons above. Both reads are recorded in evidence/verdict-overrides.json.

### F-06 [S2] Before any store page the title needs a real trademark search: it has only ever been web-screened, and it collides with an earlier Godot game called OrbCombat
- Origin: AC-073, AC-086.
- Where:
  - docs/legal/name-screening.md:152: CONDITIONAL (Medium); "OrbCombat is a direct name clash to resolve before any store page".
  - name-screening.md:161: EUIPO, UK and Japan "Not run".
  - name-screening.md:180-188: Orb's ruling that the title stays; the formal search still not run on 2026-10-11.
  - docs/legal/review-log.md:3 and :454-457: screens, not clearance; US-only search tool.
  - https://github.com/Cascachu/OrbCombat: GDScript, GPL-3.0, public (gh API, 2026-11-07).
- Evidence: the gh API and the records (sweep-a4.json risk 1; cold reviews AC-073, AC-086).
- Why it matters: a store release under a name with a prior user risks a forced rename after launch. This is not legal advice, and only a trademark attorney's clearance settles it.
- Likelihood: low to medium. Evidence strength: documented (screening).
- Cold review: agreed, S2 (AC-073: yes; AC-086: partly, noting a later USPTO search on the title's two words that the Limits section undersells).

### F-07 [S3] Personal details about Orb, a pseudonymous owner, are readable in the public repo and its history
- Origin: AC-239, AC-151 (the team's own rule that the owner stays pseudonymous).
- Where:
  - docs/ep/vision.md:71: a "Copyright holder" row with a first name and surname initial.
  - docs/ep/vision.md:1403: a US state of residence. The same state is in a public file name under docs/legal/.
  - Commit 701c76a0 (2026-09-29, in public history): a LICENSE copyright line with the same name.
  - 52 committed files (67 lines) hold the local Windows profile path.
- Evidence: evidence/F-07.txt (counts and masked lines only; this audit reproduces none of the values).
- Why it matters: it weakens Orb's pseudonymity now, and git history keeps it even after an edit. Stores will need the legal name privately anyway (AC-147); whether it should be public is Orb's call.
- Likelihood: certain that it is readable; the harm depends on Orb. Evidence strength: reproduced.
- Cold review: not required (S3).

### F-08 [S3] The public pages and repo say things that are not true about the build and the project
- Origin: GAP G-09; AC-007, AC-049, AC-199, AC-202; the sweep (sweep-a3.json risk 4).
- Where:
  - README.md:7 says "The hosted build is offline for now while its flashing effects are fixed", but /play/ returns 200 with a playable build. The line has been wrong since 2026-10-22.
  - README.md:9 and the in-game notice in the live pack say "We are fixing them" while flash work is paused. RL-200's grace for the old words ends 2026-11-08, and dead CI will not flag it.
  - CLAUDE.md:3 says "Free and open source" with no licence (GitHub's licence field is null).
  - The live /about/ page calls the engine "Godot Engine 4.7.2-stable (official)", while the served wasm is the project's custom build (it matches tools/web-template.json:15).
- Evidence: curl of the live pages and pack; cold review G-09 (yes).
- Why it matters: the warning only protects people if the public story around it is true. A parent reading the README is told there is nothing to play.
- Likelihood: high (it is live). Evidence strength: reproduced.

### F-09 [S3] The flash measurement chain has holes that make its passes and failures less certain than the records say
- Origin: AC-005, AC-021, AC-028, AC-038; GAP (gates-flash.json).
- Where:
  - tools/flash/wcag.js:272-274: each frame keeps only the dominant direction and a tie goes to "up", so two equal regions strobing in counter-phase read about 0.5 (a pass) while either alone reads 10. Reproduced in a node one-liner (gates-flash.json notes).
  - wcag.js:3: not a recognised analyser; nothing has calibrated it.
  - tools/flash/signature-gate.mjs:94: the live pin's 3 / 3 / 3 record passes only through `grandfathered: true`.
  - tools/flash/nightly-seeds.mjs:34 and :54: the owner take-down line is 3.5, above the standard's 3, and the 4.5 area trip was set at a reading of this pin.
  - tools/flash/release-pass.json:3-4: the only full-set pass is for d3f1ca0e (2026-10-15); no commit has met the release rule since. `release-pass.mjs --verify` fails against HEAD.
  - Night by place ships in the live pin with no night clip (AC-038).
  - Effect-level margins are only partly in force (AC-028).
- Evidence: code read and self-tests run (gates-flash.json); cold reviews AC-005, AC-028, AC-038.
- Why it matters: every public flash statement rests on this chain. A store release needs it fixed and checked against a recognised measurement.
- Likelihood: medium. Evidence strength: reproduced (the tie); traced (the rest).

### F-10 [S3] In the private LAN build, the other PC (or any device that gets the seat) can freeze or exhaust your game, and a dropped PC freezes the remaining player's match
- Origin: GAP G-07, GAP G-08; the sweep (sweep-a2.json risks 1 to 3).
- Where:
  - net/handshake.gd:84 and :91-93: the peer's delay is never capped and drives `for t in range(delay)` in net/session.gd:120-134.
  - net/host.gd:120-129: an unchecked takeover slot and inputs loop.
  - net/enet_transport.gd:38: plain ENet, no DTLS.
  - net/session.gd:146-147 and net/lan.gd:245-269: a stall freezes the match, with only a window-title notice.
  - No code execution is possible: only bytes_to_var is used (net/transport.gd:68).
- Evidence: traced in code at a8bc66e2 (net/ unchanged at HEAD). Not reproduced (no Godot runs).
- Why it matters: private builds only, on a home network with a /24 filter, so the harm is low today. It becomes a real security item before any internet play.
- Likelihood: low. Cold review: G-07 S3, G-08 S4 (agreed).

### F-11 [S3] The public repo has no safety net if a session commits something it should not
- Origin: GAP (sweep-a78.json risk 2; gates-other.json rows 27 and 31); AC-248 (UNSUPPORTED: "AI-written code is reviewed before merge").
- Where (gh API, 2026-11-07): secret_scanning, secret_scanning_push_protection and dependabot_security_updates are "disabled"; main is "Branch not protected"; 0 rulesets. 2,744 commits went straight to main, with 0 pull requests.
- Evidence: gh API. The HEAD and history scans found no live secret today (sweep-a78.json).
- Why it matters: many automated sessions push to a public repo with nothing to stop a leaked key, a private path (F-07) or a failing build (F-03). The setting is free and takes minutes.
- Likelihood: low today. Evidence strength: reproduced.

### F-12 [S3] A desktop workflow could put a game binary with full flashing on in front of anyone with a GitHub account, for 14 days
- Origin: AC-240; GAP (gates-other.json rows 13, 20, 21).
- Where:
  - .github/workflows/linux-export.yml:58-63: export, boot hash, artifact kept 14 days; no Reduce flashing lock and no route scan.
  - desktop-builds.yml:40-46: "Orb's yes" is only a date-format check.
  - desktop-builds.yml:96, 99 and linux-export.yml:47, 50: gate.mjs is piped into tee, which loses its exit code (GitHub's default shell runs with -e and no pipefail).
- Evidence: workflow files read; neither workflow has ever run (gh run list).
- Why it matters: one manual dispatch publishes an unlocked build outside the public-site safeguards. Low likelihood, easy fix.

### F-13 [S3] Store readiness: what a store will ask for is not yet true
- Origin: AC-093, AC-170, AC-273; GAP (sweep-a3.json risk 8, sweep-a4.json risks 2 and 4, verify-v12 note).
- What:
  - The records disagree on the target rating: vision.md:63 says Mature, Legal's later screens Mature or AO, and the uncommitted RL-247 says Teen. data/combat/finishers.json still names a graphic devour finisher that RL-220 bars.
  - File-level origin rows stop at 2026-09-29 (docs/legal/asset-origins.md:47), and provenance for Gemini lines sits in pending folders.
  - audio/music/README.md:18 plans a re-encode that drops Suno's metadata, while Suno's terms say not to remove it (https://suno.com/terms, per the sweep; quote to re-check before music ships).
  - Desktop builds are unsigned with blank copyright and company fields, and the web build uses the Godot logo as its icon (export_presets.cfg:74, 76-85, 149, 164-169).
- Why it matters: each is a store-day correction or a terms problem, not player harm.

### F-14 [S3] Accessibility: the public build lacks options main already has, sounds are not captioned, and one setting does nothing
- Origin: AC-251, AC-254, AC-255, AC-256, AC-257, AC-264 (public pin only; fixed on main, blocked by F-03); AC-252 (private); GAP (sweep-a5.json risks 4 and 5).
- Where:
  - The pin 257a766c has no volume, mono, text-size or computer-level options, has hold-only stances, and truncates help text.
  - Captions cover only barks, which are off (ui/widgets/ui_barks.gd:159, 180; audio/audio_cues.gd:245).
  - The Hit pause slider has no consumer (ui/data/settings.json:56; no reader of hitstop_scale).
  - "Button only" brace leaves pad players with no brace in a8bc66e2 (AC-252).
- Why it matters: this is quality, not legal exposure. No accessibility law was found that binds a free game here, and US CVAA is not triggered because there is no chat (sweep-a5.json checked_ok).

### S4 notes (no action required; worth knowing)
- The live /play/ build shows "Civilians lost: n of 1800" on the pause screen and results card, and F2 (no debug gate) shows a running count and the menace bar, against Orb's "no death counters" (GAP G-10, AC-171).
- On the live pin, F8 switches flashes to their older shapes with no lock check; fixed at HEAD (AC-054).
- The live pack carries 259 tool and test files, including the capture scene; its routes are shut on a public host (sweep-a2.json risk 4).
- /play/ sends no anti-framing header or script, so the warning gate could be framed and clicked through by a hostile page (sweep-a2.json risk 6).
- The Web export preset does not exclude net/, unlike the desktop presets (AC-061). It is harmless today, because the pin has no net/.
- At HEAD, straight and lobbed energy shots damage the protected chapel (verify-v13 note).
- The LAN kit's firewall rule applies on every network profile until removed (sweep-a2.json risk 3).
- 351 concept files, including fighter close-ups, are public in the repo, against Orb's "no WIP character art in public" marketing rule (AC-088). This is Orb's call.
- Small runtime costs: the prefs file is re-parsed every frame after 45 s, two logs are uncapped, and a desktop window keeps full rate when unfocused (sweep-a78.json risks 5, 6 and 12).
- A home LAN address (10.0.0.135) and HUD mock sheets removed in 83cda4a1 remain in public files and history (sweep-a2.json risk 7, sweep-a78.json risk 11).

---

## Practice findings (causes, not separately rated)
These are why the findings above happened. They drive Part 3 of the corrective directive.
1. **Nobody watches the build players get.** Gates test HEAD while players get a pin. In owner mode the release pass becomes a printed report, the signature gate passes by grandfathering, and the one check aimed at the pin (the nightly) is run by hand and lapsed. (F-01, F-09; checks K-06, K-07, K-08)
2. **The owner is not told, and the delegation has no watcher.** Orb handed the flash call to the team on 2026-10-18 ("You handle this", vision.md). The EP's note then stopped flash talk with Orb while relying on gates that nobody checked. (F-01; IR-02b; AC-274)
3. **Evidence is not kept.** The EP's gate outputs for three landings were deleted. Many figures in the records come from scratch runs with no saved output (for example AC-010). The verdicts survive only in commit messages. (IR-01b; post-notice-changes.md)
4. **The records lag the code.** Dozens of Legal rows are still Open after their condition was met. Two "known bugs" were fixed weeks ago (AC-228, AC-237). Inventory line numbers drift, RL-247 is cited but uncommitted, and the review log has no step for closing a row. (false-alarms.md)
5. **Safety records carry taste.** 143 of 294 claims are Orb's originality or look direction, team process or engineering quality, filed as safety. That buries the six S2 items. (false-alarms.md)
