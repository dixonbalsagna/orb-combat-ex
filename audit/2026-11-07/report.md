# Independent Audit of release safety: report for Orb

2026-11-07. Measured against the project as it stood at 22:03 UTC that day (commit 8d9b98a2 plus every uncommitted file), before the EP was told. Nothing in the safety records was changed after that point (post-notice-changes.md).

## 1. The verdict in five lines
1. **Public web, today: not as it is running.** Nothing I found lets anyone run code on a player's PC or take their data. But the public test build at /play/ is up under conditions you set on 18 October that are no longer being met: its flash re-check stopped on 30 October, its take-down switch does not work, and its end date (15 November) will not remove it on its own.
2. **A store: not yet.** Six serious problems (S2) must be fixed first, plus ordinary store paperwork.
3. **What stops it, in plain words:** every automatic check has been switched off since 6 November by a typo in one file; nobody can pull the public build through the documented switch; the game's own flash limiter cannot see camera cuts and scenery sweeps; the villain gets stronger for every civilian he kills, in the public build too; the title has never had a real trademark search.
4. **Most of the team's safety worry is not release safety.** 163 of the 294 recorded concerns are your creative direction, team process or code quality filed as safety, or are overstated or out of date. They bury the six that matter.
5. **The decision that is yours:** the public test build. I recommend taking /play/ down by hand until a fixed build is measured, or renewing it in writing on today's facts (corrective directive CD-03).

## 2. The numbers
- **Claims checked:** 294 distinct safety claims, merged from 428 places in the records. Every one was traced to the code, a commit, a command's output, the live site or the published rule itself. 27 got a blind second read by a reviewer who did not see the first verdict.
- **Held up:** 131 claims are real. 18 of them matter at release (7 rated S2, 11 rated S3). The other 113 are real but negligible, or already handled by something that demonstrably works.
- **False alarms, by kind (163 in all):**
  - 143 misfiled: 74 are your creative direction (mostly pose, gesture and look rules), 34 engineering quality, 21 team process, 13 design rules and 1 business.
  - 16 overstated.
  - 2 unsupported.
  - 2 "contradicted by the code": both are bugs fixed weeks ago that the register still lists as live. Stale, not invented.
- **Gaps found:** 10 real risks the team never recorded. The biggest: CI dead, the take-down blocked, the flash limiter's blind spot, and the power half of the villain's casualty feed.
- **Findings by severity:** S1 none; S2 six; S3 eight; S4 ten notes.
- **Checks reviewed:** 50 families of automated gates and standing safety checks: 12 keep, 22 fix, 2 merge, 2 retire, and 12 that should exist but do not.
- **The EP's answers:** two information requests (nine questions). Every pointer checked held up; nothing was invented. The EP's disclosure pack did not list CI being down, the broken take-down, the lapsed re-check or your personal details in the repo. The EP did not know about the first three.

## 3. What is really wrong (S2)

**F-01: the public test build has scenes the team's own flash check reads over the limit, and the safeguards you approved it on have stopped.** In the only mode players get (Reduce flashing locked on), the team's analyser read three AI-match scenes on the live build at 3.5 flashes in one second. The international web standard (WCAG 2.3.1) fails anything above 3. You approved the build on 18 October on "58 of 60 under 3, 2 at 3.5", with conditions: take it down on any new scene over 3.5, on any report, or on an unmeasured change, and end it unless you renewed in writing. Since then the nightly re-check stopped (30 October), the end date was moved to 15 November in a Tools commit with no written renewal from you on record, and nobody told you any of this. The EP's note against raising flash topics with you assumed those checks were still running. Nobody checked. The readings are the team's own and have never been checked against a recognised analyser. Tools' repeat test reads the same scene at 3.5 at one picture size and 2.0 at another, so your doubt is reasonable. That is a reason to settle the question properly, not to leave the build up on lapsed checks. The build is free, unpromoted, hidden from search and behind a clear warning, which is why this is S2 and not S1.

**F-02: nobody can take the public build down the documented way.** The off switch only edits a file, which takes effect only when CI deploys, and CI cannot deploy (F-03). The 15 November end date is only an error message in a CI run that does not happen. The only working route is unpublishing the site by hand in GitHub's settings, and that is written down nowhere. There is also no contact address on the pages, so nobody could report a problem.

**F-03: every automatic check has been off since 6 November.** Two step names in the CI file have an unquoted colon, so GitHub cannot read the file at all. 37 pushes since then ran no checks: no flash count, data, network or site checks, including on the build you and Orb 2 played. Nobody noticed, because the check that would catch this lives inside the broken file and the EP did not look at CI after pushing.

**F-04: the game's built-in flash limiter cannot see what caused the failures.** It counts only effects that ask it first. Most camera cuts and scenery sweeping past the camera never ask, and those are where the failing scenes came from. The CI "flash gate" only recounts what the limiter allowed, so it cannot fail on them either. On main (your LAN builds and any future public build), Reduce flashing also no longer slows the scenery sweep. That mitigation was dropped on 22 October "while the flash work is paused".

**F-05: the villain gets stronger for every civilian he kills, in the public build and on main.** Each death adds to his menace (more energy regeneration, up to 5% more damage, a stronger beam clash) and to his power toward his next form. That breaks your pillar 5 ("never on civilian deaths"). You were told it is on main, not that the public build has it. Before a store, it must be fixed or declared: rating questionnaires ask about rewards for violence against civilians. Both second readers confirmed the facts and rated it lower (S3). I keep it at S2 because it breaks your written rule in the build the public can play.

**F-06: the title has only been web-screened, and an earlier Godot game called "OrbCombat" exists.** No trademark register search (US, EU, UK, Japan) has been run. Before any store or itch.io page, a professional search is needed. This is not legal advice; only a trademark attorney settles it.

The S3 findings are in findings.md:
- Personal details about you in the public repo: a name, your state and your Windows account name in 52 files.
- Public text that is untrue: README says "offline" and "we are fixing them".
- Holes in the flash measurement chain.
- The LAN build can be frozen by the other PC.
- No secret scanning or protected main on the public repo.
- A desktop workflow that could publish an unlocked build.
- Store paperwork.
- Accessibility gaps.

## 4. What the team worries about that isn't real
- **Pose and gesture rules treated as legal danger.** Legal's screens set exact limits on hands, arms, glows and after-images ("under 32 in depth", "never palm up", "opacity 0.35 or less") and call breaches NO-GO. The screens themselves say they are not legal advice, cite no law, and single gestures are not protected by copyright. These are your originality direction, worth keeping as that. But filed as safety, they keep dozens of rows Open that block phase gates on paper, and they bury the real problems.
- **"The repo must stay private until counsel reads it."** You made it public on day one, and most of the must-fix list is done. The records still read as if the repo is in breach.
- **Fixed bugs listed as live.** The F9 grey screen was fixed on 1 October and a memory leak on 30 October. The register never changed.
- **"A store needs a Harding report."** No store you named requires one. A check against a recognised analyser is still wise before a store, as a calibration.
- **Team process and PC housekeeping filed as safety** (machine caps, "no prompts in front of Orb", token rules, phase sign-offs): 21 items. They protect your PC and the way the team works, not players.
- **Cost:** the safety record looks about three times bigger than it is, many Legal rows stay Open long after their condition was met, and the six things that matter were not on anyone's list.

## 5. How the internal safety checks should change (the five most important)
1. **Check what players get, not the latest code.** Every check today tests main, while /play/ is an older pinned build. Add a daily job that checks the pinned build, the interim end date and the age of the last flash re-check, and tells the EP (CD-19).
2. **Someone must watch CI, and CI must not be able to die quietly.** The YAML check needs its own small workflow, and the EP's standup should read the run list first (CD-01, CD-20).
3. **A delegated safety decision needs a named owner and written conditions.** When you said "You handle this" on 18 October, nobody became responsible for checking the conditions. A "don't raise this with Orb" rule must never cover a safeguard that has stopped. In that case you get one plain question (CD-24).
4. **Keep the evidence.** Gate results for three landings were deleted, and many recorded figures have no saved output. Results should be kept as small files beside the records (CD-22).
5. **Separate taste from safety.** Move the originality, pose and look rules to a creative rulebook under you, and process and code quality to their owners. Keep the safety record to what protects players, you and the project at release (CD-15, CD-18).

## 6. Limits of this audit
- **Nothing was run.** No Godot, browser or game run was made (house rules for your PC). Runtime claims are traced in code, not reproduced. The LAN folders on the old PC were judged from the kit that builds them, not inspected.
- **No independent flash measurement.** Every flash figure here is the team's own, from a tool that has never been checked against a recognised one. This audit is not a certified flash test. For a store release, a recognised analyser or a test house is still the right step.
- **Not legal advice.** Trademark, copyright, ratings and store-terms points are screenings of published rules. External rules were mostly read by helpers through web fetches, a few through secondary pages; each is cited with its link in the verify files.
- **How the reading was done.** 62 helper agents did most of the reading: 14 for the inventory and sweep, 48 for verification and second reads. I re-checked the most important facts myself: the CI failure, the live site, the interim records, the IR pointers and the personal-data counts. I did not re-run every verifier's proof. Blind second reads covered every S1, S2 and "contradicted" verdict and the ten serious gaps, not every claim.
- **Snapshot.** The audit judges the project as of 22:03 UTC on 2026-11-07. Anything built later needs a fresh look.
- **Cost.** About 11 million helper tokens (3.4 million for inventory and sweep, 7.3 million for verification and second reads), plus this session's own reading. That is well above the 1 to 1.5 million estimated at the start, because the full workflow verified every claim individually.

Files: findings.md (the real problems, with proof), false-alarms.md (all 163, with what each costs), checks-review.md (every gate), claims.md (all 294 with verdicts), corrective-directive.md (27 numbered actions for the EP), ir-log.md, post-notice-changes.md, evidence/.
