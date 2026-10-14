# The release flash set after Legal's addendum 6 (RL-128): what is built, the scenarios, the cost, how to afford it (2026-10-12)

Owner: Tools and Pipeline. For the EP, Legal and the directors whose scenes the set needs.

## 1. The rules, as built (tools/flash/release-pass.mjs and its self-test, 34 checks)

| Legal's rule | In the tool |
|---|---|
| combined rule: primary at most 2.5; area-15% and stricter memory at most 3 | `verdict.js` (unchanged): PASS, OVER GATE (primary over 2.5), FAIL (any reading over 3). A clip at exactly 3 on the primary reading is OVER GATE: not a pass. |
| a clip whose readings differ by more than 1.0 is **sensitive** and is re-captured at another seed or start | `spreadOf` (primary, area-15%, stricter memory). A sensitive row counts only with a `recapture` row (another `--seed` or `--skip`) that is PASS and not itself sensitive. `--record --recaptures <summary.json> --how "seed 7"` attaches them. |
| no counted change within 15% above the area threshold in the worst second unless the second totals 2.0 or less | `marginalCount` of the row (the analyser's own "marginal" count) against the primary reading. Refused at `--record` and at `--verify`. |
| the pass is on the commit being published, both modes | the four hashes of the record against the commit; every required clip is captured normal and reduced. |
| re-run the whole set when a change touches the camera, lighting, scenery contrast, an effect or the crowd | `node tools/flash/which-set.mjs <base>..<head>` says FULL (render/, art/, ui/, data/biomes/, data/anim/, shaders, input layouts), AI (sim/, data/director, combat, fight, fighters: the AI matches are different matches) or NONE (docs, tools, qa, research). |
| k06: the HUD's crown flicker is in the flash check's frame | the capture is the whole page: the HUD is in every frame already (UI's legend flicker read as the mash's 3 until their gate). What is missing is a scenario that makes the crown flicker (see section 3, `crown`). |

## 2. The required set, scenario by scenario

Today 28 clips: 14 scenarios by 2 modes: mash, mashcity, clash, signature, transform, collapse, and the AI matches at seeds 12345, 4, 7, 1, 3, 5, 38 and 39.

| Legal's list | Scenario (id) | State | What it needs | Ticks | Clips |
|---|---|---|---|---|---|
| the mash at the foot of the towers | `mashcity` | **in** | nothing | 1,800 | 2 |
| a beam clash | `clash` | **in** | nothing | 1,500 | 2 |
| the transformation | `transform` | **in** | nothing | 1,500 | 2 |
| a signature and an explosion in the city | `signature` and `collapse` exist; `signaturecity`: the signature scene started beside the tallest tower | small | `_to_the_city` start for the signature scene, mine, today | 1,500 | 2 |
| camera travel at maximum speed over high-contrast scenery | `rushcity`: P1 sprints (stick and dodge held) along the front street past the downtown towers and the crowd | small | pad script, mine, today | 1,500 | 2 |
| an open-floor building opening and closing in view | `openfloors`: the pair set down at a tower of five floors or more and walked past it and back | small | Rendering to say which building and what makes it open (the pane's cutaway request); the staging is mine | 1,500 | 2 |
| a zip chain and a launch across the city | `zipcity`: a zip chain from the manoeuvre stance, then B on a staggered rival (the launcher) along the street | medium | Controls' pad recipe for a zip chain; the sim's launch is real, not staged | 1,800 | 2 |
| the sky at its extremes with a town in view | `skyextremes`: the sky key driven to its darkest, brightest and the dawn and dusk blends while the pair fight in front of a town | medium | Rendering/Art: the name of `SkyDrive`'s switch (render/core/sky_drive.gd) so the staging can drive it; a scratch hook until then | 1,800 | 2 |
| a flyby of all three streets and the avenues, at depth | `flyby`: the camera and a pair flying along each street lane and across each avenue | **blocked** | fighters in depth on main (Simulation's parked depth core), and Camera's scripted path or a flight the director makes | 2,400 | 2 |
| fighters in depth in AI matches | `aidepth`: four of the AI seeds with the setup's `"depth": true` | **blocked** | depth on main (`S.depthOn` from the setup) and the hook passing the setup | 3,600 | 8 |
| the crown's flicker (k06) | `crown`: the state that makes the HUD's crown flicker, held for 10 seconds, in both modes | needs UI | UI to name the state (a tier, a low health, a pause) | 900 | 2 |
| 20 fixed AI seeds (every pairing and signature) | `ai`: 12 more seeds beyond today's 8, each shown to have both fighters' signature (`seed_scan.gd` lists them) | medium | the seed scan, mine; the roster has one pairing today | 3,600 | 24 |

Scenario ids are written to `tools/flash/sources.json`, the hook (`render/tools/flash_capture.gd`) and `flash_worst.gd` together, and the selftest's drift checks keep the two stagings the same lines.

## 3. What it costs on this PC

Measured today on a loaded machine, one capture at a time, the game's own web build in headless Chrome (it renders on the RTX 5070 Ti, not in software: the incident's browsers forced SwiftShader): the step is about 60 ms and the lossless screenshot about 140 ms, **about 5 frames a second**. With three clips at once under the set's 40% core budget the whole 28-clip run took about 2 hours: about 2.1 times the single-capture rate. (`optimizeForSpeed` on the PNG is 0 to 40% faster and 50% larger: not worth the noise.)

| | ticks | hours at 5 fps, one at a time |
|---|---|---|
| today's 28 clips (12 fixed at about 1,600, 16 AI at 3,600) | 76,800 | 4.3 |
| the new fixed scenarios (7, both modes) | about 22,000 | 1.2 |
| `aidepth` (4 seeds, both modes) | 28,800 | 1.6 |
| 12 more AI seeds, both modes | 86,400 | 4.8 |
| **the full release set** | about 214,000 | **about 12, plus analysis (a minute a clip)** |

At three jobs under the 40% cap: **about 3.9 hours measured** (the first estimate was 5.5), a night. One at a time per session, as the rule says: half a day.

## 4. How to afford it: three tiers

1. **Per change (the fast subset): about 30 minutes.** The windows of the known worst moments: for each clip within 0.5 of the gate or over it, the 3 seconds around its worst second (180 frames), plus the three fixed city scenes at full length (mashcity, rushcity, collapse). `which-set.mjs` decides FULL, AI or NONE for the change; a FULL change queues the nightly set, it does not wait for the subset. It is a tripwire on known worst moments, not a gate: a change that moves the worst second elsewhere is not seen.
2. **Nightly: the full set, three jobs, about 5.5 hours,** on the newest commit, both modes, reported as a table with the margins (`margins.mjs`) and the sources (HUD, camera, world).
3. **Release: the nightly set on the commit being published,** with the sensitive clips re-captured at another seed or start (`--recaptures`), then `release-pass.mjs --record`. Orb's call, not written until then.

To make the windows cheap the hook needs one thing: **`skip`**, the ticks run without drawing before the clip starts (the contract exists in `capture-web.mjs`; the hook has not offered it). Running 600 ticks without a picture costs about 30 seconds against 120 for a drawn clip; with it an AI seed's three worst windows (1,800 drawn ticks) replace its 3,600-tick match in the subset, and a sensitive clip is re-captured from another start for the price of its window. That is a 12-line change in Rendering's hook, written and tested (`docs/tools/pending/flash-capture-skip.patch`, with `--skip N` on run-pixels.mjs: the cross-check reads the register from tick N + 1). **Measured (2026-10-12, mashcity, 300 ticks skipped then 60 drawn, against the same 60 ticks of a 360-tick clip):** the register is identical on all 60 ticks and the frames are not byte-identical: 0.1 to 0.2% of the pixels differ (about 1,000 to 1,500 of 786,432; about 400 to 500 by more than 25 of 255), which is the particles' and effects' view state not having been drawn during the skip. That is under 7% of the area threshold and fine for a tripwire; it is why a window result never stands in for a full clip at release.

## 5. What I need, by owner

- **Rendering:** `skip` in the hook (patch from me); the sky switch's name; which building opens its floors and how to make it open.
- **Simulation:** fighters in depth on main (the setup's `"depth": true`), for `flyby` and `aidepth`.
- **Camera:** a scripted path for the flyby, or the director's flight along a street.
- **Controls:** the pad recipe for a zip chain from the manoeuvre stance.
- **UI:** the state that makes the crown flicker (k06) and a measurement of it in the check's frame.
- **Legal:** whether the nightly window subset may stand in for a per-change check (never for the release), and whether 20 seeds means 20 per pairing or 20 in all; with one pairing today the two agree.
- **Me, now:** `signaturecity` and `rushcity` (small, no dependency), the 12 seeds, `skip`'s patch. I will do them when the running set is reported, unless you say otherwise.

## 6. Legal's answers (RL-131, addendum 7) as built, and what a release night costs now

| Answer | In the tools |
|---|---|
| 1. a per-change subset of 3-second windows: a development check, never the release pass; the windows are the previous full run's worst seconds plus the changed scene's own; labelled per change; a failure stops the change | `run-pixels.mjs --skip N --ticks 180` (needs the skip patch, committed in 7764929c); `windows.json` is the previous run's worst seconds (`analysis.json`'s `general.atTick`). The pass never reads a window. |
| 2. 20 seeds in all; every fighter in at least 5 matches and every signature at least twice; every pairing at least once over a rolling cycle, uncaptured first; a pairing new in a release at least 3 times | `tools/flash/pick-seeds.mjs` (a rule, with unit tests in the release-pass self-test) and `tools/flash/seed-history.json` (failed seeds, the coverage table). |
| 3. re-pick per release by the scan, deterministic, recorded, listed in the pass; the five worst seeds of the previous release stay; a seed that failed in an earlier candidate stays until its cause is fixed and recorded | the pick's JSON (`--out`) is passed to `--record --seed-pick`, and the record holds it; `worstSeedsOf` reads the previous record; `failed` entries stay until `fixed: true`. |
| 4. the guarded launcher on a machine that was not starved is a recorded condition (CPU cap, time limit, owner's tag, load before and after); a starved clip is void; a clip above 2.0 needs a second independent capture, the worse reading counts, captures more than 0.5 apart are flagged and re-run | every `clip.json` now carries `guard` (tag, session, cpuPercent, timeoutS, priority), `loadBefore`, `loadAfter` and `framesPerSecond`; a clip under 1 frame a second is void; `--record --seconds <summary.json>` attaches second captures; `verdictOf` and `effective` take the worse readings; a difference over 0.5 is a problem. |
| 5. a marginal change is each alternation event of the worst second whose area is 1.0 to 1.15 times the threshold; "totals 2.0" is the primary reading | as built (`marginalCount`, the primary reading), on the worse of the two captures. |
| 6. another start for steadiness: 600 ticks later is enough; for a clip flagged sensitive the re-capture is a different run (start position, distance, direction or camera phase), not a later window | `--how "skip N"` is refused for a sensitive clip; `--variant N` (the pair set down N x 450 units further along the world: another place, scenery and camera phase) on `run-pixels.mjs`, `capture-web.mjs` and `flash_worst.gd`, with the hook patch `flash-capture-variant.patch`; an AI clip's different run is another seed. |
| 7. the HUD's own rate as a separate line | `--record --hud-rate <n from ui/tools/hud_check.gd>`: the record has a `hud` line and fails at more than 3 a second. |

**The clips above 2.0 and their second capture.** Section 7 has the measured list for the current build (3198301f, switches off): 4 of 28 clips need the second capture (ai-12345-reduced, ai-7-normal, ai-38-reduced, ai-39-normal), the margin rule is not met on 8, and 4 clips fail (two of them world bursts at a body coming down, one a launch, one a launch and merge).

**A release night, now (measured, replaces the estimate).** The set is 56 clips (28 + 4 city + 24 AI at 20 seeds) plus the scenes that wait on other directors (12 more clips). Measured on the repair run: 28 clips in 1 h 44 min at three jobs under the 40% budget with another session's long run beside them (a fixed clip 5 to 7 minutes, an AI clip 10 to 16 minutes each, three at a time; every capture 7.8 to 13 frames a second, none starved), so 3.7 minutes a clip, not the 5.9 of the estimate. The 56 clips: **about 3.9 hours**; second captures of the 36% above 2.0 (about 20 clips): about 1.5 hours; sensitive re-captures (2 of 28 on this run, about 7%): about 20 minutes. **About 5.7 hours at three jobs, about 12 hours one capture at a time**, and about 6.5 hours at three jobs when the 12 waiting scenes are in. A night, so the nightly set is the unit and the release pass is the nightly run of the commit being published with its second captures.

## 7. The whole set with the camera switches off (2026-10-14, commit 3198301f, 28 clips)

Captured through the guarded launcher (three jobs, 40% of the cores, below normal; QA's long run beside it; every capture 7.7 to 14.4 frames a second, none under the 1.0 that voids a clip) on one web build of 3198301f with the nine cells' chain in. The earlier run of this section (f9469f8a, the repair run) is superseded: the chain moved the seeds and the sim, and its "travel budget on" pass was never on (the page's switch did not reach the hook, retracted 2026-10-13; the hook now reports what it applied and capture-web.mjs refuses a clip where it was not). Readings are primary / area-15% / 2 s memory at the tick the worst second starts. "Kind" is read from a headless per-tick probe of the same sim (slam: the divider's slam; launch: a body launched; merge: the pair closing or opening; ground: a body coming down; blast / brawl: none of those). "Whose" is the analyser's reading of each counted change: the picture moved (camera) or the world's own brightness changed (world: a blast, debris, a beam).

| clip | verdict: primary / area-15% / memory @tick | counted / within 15% of threshold | margin rule | second capture | kind of the worst second | whose changes |
|---|---|---|---|---|---|---|
| mash-normal | 0 / 0 / 0 @0 | 0 / 0 | met | no | blast / brawl | - |
| mash-reduced | 0 / 0 / 0 @0 | 0 / 0 | met | no | blast / brawl | - |
| mashcity-normal | 1 / 1 / 0 @85 | 2 / 2 | met | no | merge | camera (2 of 2) |
| mashcity-reduced | 1 / 1 / 0 @81 | 2 / 2 | met | no | merge | camera (2 of 2) |
| clash-normal | 1.5 / 2.5 / 2 @191 | 3 / 2 | met | no | launch+merge | camera (2 of 3) |
| clash-reduced | 2 / 2 / 2 @182 | 5 / 2 | met | no | launch+merge | mixed (3 world, 2 camera) |
| signature-normal | 2 / 2 / 2 @1400 | 4 / 1 | met | no | launch | world (4 of 4) |
| signature-reduced | 2 / 2 / 2.5 @85 | 4 / 2 | met | no | blast / brawl | mixed (2 world, 2 camera) |
| transform-normal | 1.5 / 2 / 2 @516 | 3 / 1 | met | no | blast / brawl | world (2 of 3) |
| transform-reduced | 2 / 2 / 2 @517 | 4 / 4 | met | no | blast / brawl | world (3 of 4) |
| collapse-normal | 1.5 / 3 / 1 @84 | 4 / 2 | met | no | merge | camera (4 of 4) |
| collapse-reduced | **FAIL** 3 / 4 / 3 @1137 | 11 / 6 | **not met** | fails first | launch+merge | mixed (7 world, 4 camera) |
| ai-12345-normal | 2 / 2.5 / 2 @365 | 5 / 2 | met | no | blast / brawl | world (4 of 5) |
| ai-12345-reduced | 2.5 / 2.5 / 2 @239 | 5 / 2 | **not met** | **yes** | blast / brawl | world (5 of 5) |
| ai-4-normal | **FAIL** 4 / 4 / 2.5 @2505 | 9 / 4 | **not met** | no | ground | world (6 of 9) |
| ai-4-reduced | **FAIL** 4 / 4 / 2 @2505 | 9 / 4 | **not met** | no | ground | world (7 of 9) |
| ai-7-normal | 2.5 / 2.5 / 2 @1102 | 5 / 5 | **not met** | **yes** | blast / brawl | world (5 of 5) |
| ai-7-reduced | 2 / 2 / 2 @856 | 5 / 4 | met | no | blast / brawl | world (5 of 5) |
| ai-1-normal | 1.5 / 1.5 / 2 @153 | 3 / 1 | met | no | launch+merge | world (2 of 3) |
| ai-1-reduced | 1.5 / 2 / 2 @522 | 3 / 2 | met | no | blast / brawl | world (3 of 3) |
| ai-3-normal | 1.5 / 2.5 / 2 @1557 | 5 / 3 | met | no | launch | camera (4 of 5) |
| ai-3-reduced | 1.5 / 1.5 / 1.5 @2018 | 3 / 1 | met | no | slam+merge | world (2 of 3) |
| ai-5-normal | 1.5 / 1.5 / 1.5 @904 | 4 / 2 | met | no | launch+merge | world (3 of 4) |
| ai-5-reduced | 1.5 / 1.5 / 2 @904 | 4 / 2 | met | no | launch+merge | world (4 of 4) |
| ai-38-normal | 1.5 / 2.5 / 1.5 @772 | 4 / 0 | met | no | launch | camera (3 of 4) |
| ai-38-reduced | 2.5 / 2.5 / 1.5 @2084 | 7 / 3 | **not met** | **yes** | launch | mixed (4 world, 3 camera) |
| ai-39-normal | 2.5 / 2.5 / 2.5 @1631 | 7 / 3 | **not met** | **yes** | launch | camera (6 of 7) |
| ai-39-reduced | **FAIL** 3 / 3.5 / 2.5 @2741 | 7 / 4 | **not met** | fails first | launch | camera (6 of 7) |

**24 of 28 clips pass the combined rule. 4 do not:** collapse-reduced (FAIL 3 / 4 / 3; launch+merge, mixed (7 world, 4 camera)); ai-4-normal (FAIL 4 / 4 / 2.5; ground, world (6 of 9)); ai-4-reduced (FAIL 4 / 4 / 2; ground, world (7 of 9)); ai-39-reduced (FAIL 3 / 3.5 / 2.5; launch, camera (6 of 7)).

**Margin rule** (a second with a change within 15% above the threshold must total 2.0 or less): not met by 8 clips: collapse-reduced, ai-12345-reduced, ai-4-normal, ai-4-reduced, ai-7-normal, ai-38-reduced, ai-39-normal, ai-39-reduced.

**Second capture** (primary above 2.0 and up to 3.0, not already failing; RL-131): 4 clips: ai-12345-reduced, ai-7-normal, ai-38-reduced, ai-39-normal.

**What the camera switches did on this commit.** Camera's launch hold and merge-zoom limit (SplitRig.launch_hold, merge_zoom_limit) were run together on all 28 clips. 7 clips read a higher primary reading with them on, and 4 went from a pass to OVER GATE (ai-12345-normal, ai-12345-reduced, ai-39-normal, ai-7-normal); the ones that read lower did so by tenths, on clips that already passed. The cost is a cut a launch (one change at up to 3.2 times the threshold in ai-12345). The EP's decision (2026-10-14): both switches stay off on main and the launch rule is not offered on this evidence. The failing seconds above that are not a launch (a world burst at a body coming down: ai 4, collapse reduced; the divider's slam) are not reached by either switch.
