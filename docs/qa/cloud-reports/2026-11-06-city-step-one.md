# City step one: the two gate reads, the stick refusals by reason, and the flight-strike harness (QA, 2026-11-06)

EP brief of 2026-11-06. Numbers are from clean exports of HEAD b33b5c9c in scratch (nothing in the repo was applied), loaded machine, `--jobs=3`, below-normal priority. A result here is a test result, never a target (RL-247 keeps the toll a design guard and not a public figure).

## 1. The city gate: civilian band and match length with the two levers on

**The levers** (both data switches, off at HEAD): the town visit (`data/director/launch.json` `town.visit.enabled`) and the wall push (`walk.enabled`, "walk him to the wall"). **The wall push reads only a human slot:** `DirWalk.landed` returns when the fighter is the AI (`sim/director/walk.gd`). An AI-vs-AI batch cannot show it, so the push arms use a scripted human on slot 0 (new in `qa/godot/records.gd`: `QA_HUMAN=mash|push`; `QA_FORCE=walk=1;visit=1` sets the two switches; both documented in the file).

**Build.** HEAD export, with the page's switches flipped (`flipall.mjs`, 28 switches, as in the earlier kept-build reads), World's places-reached park applied and `plans.farPeople` on (the RL-245 base). Whole ring: `QA_PLANET=gen=3;planets=3,7,11,13,17,19,23,25,37,31;touches=0,1,2,3;cols=4800`, 60 matches a column, seeds 1 to 60, the AI at the default level. The human is a bot: X every 8 ticks, left stick toward the foe; **push** leans the stick toward the nearest standing building within 6,000 units of the pair's midpoint. Table from `node qa/godot/city-read.js name=records.json ...`.

| Measure | AI v AI, levers off | AI v AI, town visit on | Human, no push (mash) | Human push, wall push off | Human push, wall push on | Human push, both levers on | Target |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Length median, s (95% interval) | 480 (447 to 502) | 483 (457 to 528) | 236 (223 to 248) | 235 (229 to 253) | 235 (224 to 259) | 247 (226 to 265) | 360 to 480 |
| Length p10, s | 364 (329 to 392) | 361 (335 to 385) | 188 | 208 (201 to 219) | 194 (192 to 206) | 194 (192 to 206) | at least 300 |
| Length p90, s | 585 (543 to 631) | 620 (587 to 641) | 310 | 307 (284 to 335) | 317 (281 to 335) | 331 (301 to 379) | at most 660 |
| Civilians lost in the places reached, mean % | 8.0 (7.1 to 8.8) | 7.2 (6.4 to 8.0) | 4.8 (4.0 to 5.5) | 4.4 (3.9 to 5.0) | 5.2 (4.5 to 6.1) | 5.5 (4.7 to 6.3) | 12 to 30 |
| ... a match's p90 / matches over 30% | 12.8 / 0 of 60 | 11.2 / 0 | 8.7 / 0 | 7.0 / 0 | 9.0 / 0 | 9.0 / 0 | |
| Whole-planet total, % (information) | 4.65 | 4.29 | 1.89 | 1.77 | 2.10 | | information |
| Places reached a match (far ones) | 30.4 (23.5) | 30.6 (23.6) | 19.6 (12.6) | 19.4 (12.4) | 19.9 (12.9) | 19.9 (13.0) | |
| Structures lost a match | 100 (89 to 112) | 96 (84 to 108) | 49 (41 to 58) | 52 (45 to 59) | 57 (49 to 65) | 62 (53 to 70) | |
| Sends into a building a match | 3.95 (3.42 to 4.48) | 3.60 (3.13 to 4.08) | 0.80 | 0.87 (0.65 to 1.08) | 0.78 (0.55 to 1.02) | 0.78 (0.57 to 1.00) | 4 to 8 (GD) |
| Time near a building, % of samples | 57.6 | 55.0 | 61.1 | 75.3 | 75.1 | 75.3 | 20 to 35 (GD) |
| Swings of 30 degrees or more a match (not the swing rows' own count, over 15 degrees: see 2026-11-07) | 5.7 | 5.8 | 3.0 | 3.2 | 3.2 | 3.3 | 6 to 12 |

**What it says, plainly.**
- **Match length: both AI-vs-AI columns are inside the band,** and the town visit moves the median by 3 s and the p90 by 35 s (still under 660). The human columns are about 235 s because the scripted human is knocked out in about two matches in three (it wins 15 to 21 of 60), so their absolute length is not a read of the band. **Compared with each other the human columns do not move with the levers** (235, 235, 247).
- **Civilians: no column is near the top of the band,** and none of the 360 matches passed 30%. The levers do not push the toll up: the town visit reads 7.2% against 8.0% (the intervals overlap), the wall push 5.2% against 4.4%, both 5.5%. **The floor is the other finding: the AI-vs-AI base is 8.0%, under the 12% floor before any lever is on.** That is a result to hand to Game Design, not something QA tunes toward.
- **Neither lever raises the number the city step is for.** Sends into a building stay at 3.95 (base) and 3.60 (visit on), and 0.87 / 0.78 / 0.78 for the push arms; the 4 to 8 band is not reached by either lever as built. Structures lost rise with the push (52, 57, 62) but the intervals overlap.
- **Caveats.** The push is one bot's idea of leaning toward a building (the stick only; no walk-in presses), so a person may use the lever more. The record's wall-slam class reads 0 in every arm on this build; it is not read here. The near-a-building share (QA's definition: pair midpoint within 1,500 units of a standing structure, sampled twice a second) reads 55 to 75% against Game Design's 20 to 35, which says the two definitions differ: asked of Game Design below.
- Gate verdict for step one: **length is not a blocker; the civilian band is not exceeded at the top, and is under at the floor with or without the levers.**

Records: scratchpad `c_aibase.json`, `c_aivisit.json`, `c_hmash.json`, `c_hpush.json`, `c_hpushw.json`, `c_hpushwv.json` (60 matches each); tools: `qa/godot/records.gd` (QA_HUMAN, QA_FORCE), `qa/godot/city-read.js`.

## 2. The stick-only arm, refusal counts by reason, on HEAD

HEAD with the page's switches flipped (the right stick is off in the data and on in the page), slice world `gen=2; cols=2400`, 60 matches a level (seeds 1 to 60), the pad on slot 0 flicks the right stick every 8 to 24 ticks and walks at the foe (`qa/godot/stickplay.gd --arm=stick`; counts summed by `qa/godot/stick-refusals.js`).

| | Easy | Medium |
| :--- | ---: | ---: |
| Pad's record | won 8, lost 52 | won 0, lost 60 |
| Flicks thrown | 60,392 | 60,602 |
| Started (`stick_start`) | 36,934 | 33,942 |
| Landed (`stick_hit`), of which stunning | 29,368 / 306 | 22,856 / 510 |
| **Refused (all reasons)** | **20,228 (33.5% of thrown)** | **23,371 (38.6%)** |
| No start, no buffer (cannot start now) | 7,670 (37.9%) | 9,572 (41.0%) |
| **Late** (the charge waited with no blow to carry it) | **6,069 (30.0%)** | **6,819 (29.2%)** |
| Replaced by a newer press | 5,665 (28.0%) | 6,845 (29.3%) |
| Not enough energy | 817 (4.0%) | 130 (0.6%) |
| Cancelled by a guard or dodge press | 7 | 5 |

**On the stand-in's "1,162 of 1,417 late":** I cannot find that figure in a QA document and it does not match this read. On HEAD, late is **30% of refusals** (about 1 flick in 10 thrown), behind the no-start refusals (about 40%) and level with replaced (about 29%). It may come from an older tree, before the pending-hold work; I would not cite it.

## 3. The flight-strike share read: ready for Encounter's park

Nothing to read yet (the park is not in a build). Harness built and proved on HEAD, where LT + a face press reaches today's zip:

- `stickplay.gd --arm=flight [--fsmix=<0..1>] [--fscues=<cue kinds>]`: a press is, with chance `fsmix`, LT held for 8 ticks, the left stick at one of five bearings to the foe (neutral, toward, up, down, away) and X 60%, Y 25%, B 15%; otherwise X. `fsmix=1` is the ceiling (every press a flight strike).
- Counts: `fsPress:<bearing>` (the presses), `fsBlows` (flight-strike blows: slot 0's cues named in `--fscues`, default `zip_light,zip_heavy`), `blowAll` (slot 0's `blow` cues), and each cue kind. **The share is `fsBlows / (blowAll + fsBlows)` if the park's blows do not also emit a `blow` cue, and `fsBlows / blowAll` if they do; I will check which on the park's tree before reporting.** Encounter names the park's cue kinds so I can pass them.
- Smoke on HEAD (6 matches, medium): `fsmix=1`: 10,491 presses, 87 zips against 4,598 blows (1.9%); `fsmix=0.25`: 68 zips against 5,686 blows (1.2%). Today's zip needs range and energy, so most presses do nothing; that is the baseline the new moves replace.
- Reported when the park lands, at `fsmix` 1.0 and 0.25: share of blows, per bearing and per face button, energy refusals ("No energy" knocks), and the target of at most 25% of blows.

## 4. Open findings, with owners

| Finding | Owner |
| :--- | :--- |
| Civilians-removed run: swings +1.87 a match over the within-1 row (the director's terms that read people differ in that run) | World (civilians-removed switch) and Game Design to rule whether the row stands |
| flickRun 1.5 and 2 give identical results in every cell (rounding, or a cliff below 1.5) | Encounter |
| Masher on medium reads 52 against the 35 to 50 band (the EP's figure) | Game Design owns the band; Encounter holds the AI's answer lever; QA does not tune |
| Stick-only still loses far more than the X mash (gap about 77 points on easy, 20 on medium; band within 10) | Encounter; the refusals above are the thing to look at (no-start and replaced are 68 to 70%) |
| The meteor bot never produced an `arc_send` (holds register late) | Encounter (EP said keep the arm as is) |
| Far places "visited" reads 21.8 to 23.5 reached against the band's 2 to 4; the near-a-building share reads 55 to 75% against 20 to 35 | Game Design: state what a visit and what near mean (QA's definitions are in `clean-rows.js`) |
| Wall push is invisible to AI-vs-AI (human slot only) | Encounter / Game Design: decide whether the AI should lean for it |
| The civilian band floor: base 8.0% against 12% | Game Design (a result, not a QA target) |
| Whole-ring brawl swings are 44.9% of big swings against the 40% cap | Encounter |
| ~~Black box lacks raw buttons, triggers and the left stick~~ | Struck 2026-11-06 (EP): already recorded (fcd2cf58; every pad's right stick in ea5dbeb1) |
| Hero-relief rows (RL-219 3 to 5) need a firing cue and per-landing population | Encounter |
| RL-232 (power scale) and RL-246 (meeting-point crater) civilian re-reads | Wait for the parks; EP says when |
