# Known bugs in Orb Combat EX (the Godot game, and the pinned prototype it is checked against)

Owner: QA and Balance. Subject: `prototype/index.html` at commit `7233c96`, pinned until the port proves parity. Nothing here is fixed in the prototype; each entry says whether the report is true, how to reproduce it, and what it does to the baseline (`baseline-p0.md`). `Line` numbers are at that commit.

Reports come from Combat and Choreography (their IDs `CC-nnn` are in `docs/combat/move-grammar.md`, section 5) and Game Design, forwarded by the EP. All six are **confirmed**, two of them broader than the one-line reports (KB-004, KB-006).

| ID | Bug | Reported by | Verdict | Touches | Effect on the baseline |
| :--- | :--- | :--- | :--- | :--- | :--- |
| KB-001 | Signature vs an ESCAPE defender hits less as the attacker's tier rises | Combat (CC-004), Game Design | confirmed | beam outcomes | none measurable: mean tier gap is 0.01 |
| KB-002 | The 1.35x damage against a charging defender never applies | Combat (CC-003) | confirmed | damage | 0.5% of damage; none measurable |
| KB-003 | A parried exchange still gives the attacker a chain window | Combat (CC-001) | confirmed | chain rate, ki | 13% of reported chains are phantom; chain rate 3.82 is really 3.32 a match |
| KB-004 | The chain strike ignores the defender's stance, not only after GUARD HOLDS | Combat (CC-002) | confirmed, broader | damage, DEFENSIVE | 18.5% of all damage; 76.5 HP a match through a guard |
| KB-005 | A dodged signature freezes the defender 300 units up for 0.87 s | Combat (CC-005) | confirmed | feel | 0.40 s a match, 0.7% of match time |
| KB-006 | The rush flies through terrain, and through standing buildings | Combat (CC-006) | confirmed, broader | feel, collision | 15% of rushes clip terrain, 6.7% pass through a building |

**Horizon tag and closing step (audit CD-23, added 2026-11-07).** Every entry below, and the table that follows, carries two fields. **Horizon** is the earliest release the bug blocks, in the review log's words: `private` (Orb's own PC, the LAN and private tests), `web` (a public page or the public pin) or `store` (a store page, a desktop download or internet play); `none` where it blocks no release (a fact about the pinned prototype only). **Closing step** is what ends the entry: (1) open the thing the entry names (the code, data or file) at its pin and at HEAD, not the entry's own words; (2) if it is met, mark it fixed with the date and the commit or file and line that shows it; (3) if only partly met, leave it open with what is left; (4) at each baseline (a pin move, a store step, or the audit's own re-check) QA reads every open entry against the code again, and nothing stays open because nobody looked. A fix that QA has not seen in play is marked "fixed, not re-verified". The horizons in the table are QA's first reading; the owner of an entry confirms or changes its tag.

| ID | Status at 2026-11-07 | Horizon | Severity | Closing step |
| :--- | :--- | :--- | :--- | :--- |
| KB-001 to KB-006 | open as coded: the prototype is pinned at `7233c96` and "nothing here is fixed in the prototype" | none (the pinned prototype ships nowhere; they bear on parity with the Godot sim) | S4 | The Godot sim is checked for each behaviour at the next parity read; each entry then closes as "not present in the port" or opens as a GB entry. Until then the checks keep asserting the bug is present |
| GB-001 | **fixed 658c95b1**, read at HEAD (`split_view.gd` `attach()`) | private (closed) | S3 | done |
| GB-002 | fixed 8fd6aba, reopened, fixed again 632f6c9; not re-verified in play | web | S3 | QA reads `render/shaders/sky.gdshader` and `_sky_react` at HEAD (reaction off by default), then Orb or a clip on a current build confirms; then closed |
| GB-003 | open, with Camera | web | S3 | Camera names the commit; QA reads it at HEAD and closes it, or asks for a camera-motion band |
| GB-004 | open, a design call, not a fault | private | S4 | Game Design rules; closed as "ruled" with the row |
| GB-005 | open, with World | web | S3 | World names the commit; QA's `5c.bounces` and `5c.long` rows read it at HEAD |
| GB-006 | fixed cce8a59; not re-verified in play | web | S3 | Animation's `lead_scan` passing at HEAD plus a clip of a launch; then closed |
| GB-007 | open, with VFX and Rendering; not reproduced | web | S3 | VFX names the commit (shorter fade or world-space pieces) or shows it does not reproduce; QA reads `rocks.gd` at HEAD |
| GB-008 | **fixed fd381c6**, confirmed df05b9f | private (closed) | S3 | done |
| GB-009 | finish fixed in df05b9f; the blaster's balance is open | private | S3 | Game Design rules whether any shot counts at the brink; closed when E4, E5 are inside their bands or the rule is written |

**Checks.** `qa/tests/known-bugs.test.js` has one check per bug asserting that it is still present. It passes today. When a behaviour changes it fails with "KB-00x appears fixed", and the fix is to set the verdict below to `fixed` (with the commit), then turn the check into a regression test for the corrected behaviour. A last check keeps this register and the test file in step.

**Reproduce and measure.**

```
node qa/known-bugs-repro.js [KB-003 ...]   what each scenario observes today
node qa/tests/known-bugs.test.js           the pass/fail checks
node qa/known-bugs-scan.js                 effect sizes on the baseline (default arm, seeds 100001..101000), writes qa/known-bugs-effects.json
node qa/known-bugs-whatif.js               the baseline with each bug patched in a scratch copy, writes qa/known-bugs-whatif.json
```

The scan and the scenarios use a scratch copy of the prototype with no-op hooks (`qa/lib/instrument.js`). It plays out bit-for-bit like the real file: its 1,000-match digest is `70142afa31be898c`, the baseline's.

## What fixing them would do

`known-bugs-whatif.js` patches one bug at a time in a scratch copy (the obvious one-line change) and re-runs the baseline's 1,000 default-arm matches. It is an indication of importance, not a fix proposal. One thousand matches resolve about 3 points on win rate, so smaller shifts are invisible.

| Patch | Win rate P1 (baseline 42.3%) | Match length (55.4 s) | Civilians lost (38.7%) | Chain rate (3.82 a match) | Metrics beyond the 99.9% interval |
| :--- | :--- | :--- | :--- | :--- | :--- |
| KB-001 sign fixed | 42.1% | 55.4 s | 38.7% | 3.81 | none |
| KB-002 1.35x applied | 42.2% | 55.3 s | 38.7% | 3.81 | none |
| KB-003 no window after a parry | 43.3% | 55.3 s | 39.9% | 3.44 | chain per match, chain per melee exchange |
| KB-004 chain respects stance | 40.4% (z -0.9) | 57.1 s (z 1.9) | 38.9% | 3.97 | none |
| KB-006 rush stays above ground | 42.2% | 55.4 s | 38.7% | 3.83 | none |

None of the six moves win rate, length or collateral beyond sampling noise. KB-003 changes only the chain metrics. KB-004 leans toward longer matches (+1.7 s, z 1.9) and a lower KAI win rate (z -0.9), neither significant at this sample size. KB-005 has no obvious one-line fix; its cost is the dead time given in its entry.

---

## KB-001: Signature vs an ESCAPE defender hits less as the attacker's tier rises

**Reported by:** Combat (CC-004); Game Design found it independently.
**Verdict:** confirmed. It is a sign error.
**Line:** 589, in `planBeam`.

**Expected.** A higher-tier attacker should be more likely to catch an escaping defender. The rest of the code agrees: the melee pursuit (`pEsc = 0.5 + 0.07*(D.tier - A.tier)`, line 441) and the beam dodge (`0.55 - 0.06*(A.tier - D.tier)`, line 588) both move against the defender as the attacker's tier rises.

**Actual.** `rng() < clamp(0.5 - 0.05*(A.tier - D.tier) + (dist < 500 ? 0.3 : 0), 0.15, 0.9)` decides HIT, so every tier of attacker lead lowers the hit chance by 5 points. At a 3-tier lead the beam hits 35% of the time (at 1,000 units); trailing by 3 tiers it hits 65%.

**Repro.** Scripted, 500 seeded trials per row (seeds 1 to 500). Start a match, take both fighters off AI, put the attacker (P1) at x = 2500 and the defender (P2) at x = 3500 with y = 60, set the defender's stance to ESCAPE, set tiers by setting `tier` and `power` (0, 26, 51, 76 for tiers 1 to 4), give the attacker 100 ki, wait out the director's 0.6 s cool-down, press the signature key (R), read the feed line `KAI SIG vs ESCAPE` for `→ HIT` or `→ ESCAPE`. `node qa/known-bugs-repro.js KB-001` gives HIT 36.4% (tier 4 vs 1), about 51% (2 vs 2) and 65.8% (1 vs 4). The formula predicts 35%, 50% and 65%.

**Effect on the baseline.** ESCAPE defenders receive 504 of 3,648 beams (0.50 a match, 13.8% of beams). The mean tier gap in those exchanges is 0.01 and only 13% of them have any gap at all, so the hit probability is off by 1.3 points on average and the errors cancel: 74.1% as coded against 74.1% with the sign corrected. No baseline metric moves (whatif: none of 60). It will matter once fighters differ in how fast they gain power (P4), because as coded the tier leader is the one who misses, an accidental rubber band. Beam outcome shares in section 6 are unaffected today.

**Check:** `KB-001 present` in `tests/known-bugs.test.js` (hit rate at a 3-tier lead is at least 15 points below the rate at a 3-tier deficit, and both match the coded formula).

## KB-002: The 1.35x damage against a charging defender never applies

**Reported by:** Combat (CC-003).
**Verdict:** confirmed, for two independent reasons.
**Lines:** 326 (`hit`), 411 (`requestAttack`), 436 to 437 (CHARGE INTERRUPT).

**Expected.** Hitting a defender who is charging ki deals 1.35x damage (`if (D.state === 'charging') sm = 1.35`).

**Actual.** (1) `requestAttack` sets the defender's state to `locked` (remembering `charging` only in `dPrev`) before any strike lands, so `D.state === 'charging'` is false when `hit()` runs. (2) Every path that meets a charging defender passes `ignoreStance: true` (CHARGE INTERRUPT, the beam hit, chain strikes), which skips the whole block anyway. The intended punish survives only as CHARGE INTERRUPT's built-in base x 1.4.

**Repro.** Take both fighters off AI, attacker (P1) at x = 2500, defender (P2) at x = 3400, y = 60, both tier 1 and at full HP. Hold the defender's charge key (`;`) for 2 steps, wait out the 0.6 s cool-down, tap the attacker's light key (F). Right after the request the defender's state is `locked` and `dPrev` is `charging`. The first HP loss is **36.40**, which is 26 x 1.4 with no 1.35 (with it, 49.14). Repeat with the signature key (R): the first HP loss is **230**, again with no multiplier. `node qa/known-bugs-repro.js KB-002`.

**Effect on the baseline.** 118 hits in 1,000 matches land on a charging defender (0.12 a match, 0.5% of the damage dealt). The multiplier would add 3.9 HP a match, split between both fighters. Hits where the defender's state read `charging`: 0 of 43,573. CHARGE INTERRUPT is 0.4% of melee exchanges (section 7). No metric moves.

**Check:** `KB-002 present`.

## KB-003: A parried exchange still gives the attacker a chain window

**Reported by:** Combat (CC-001); the EP added that QA's harness counts it.
**Verdict:** confirmed, including the harness point.
**Lines:** 526 (parry sets `ex.cancel`), 544 (`openWindow`), 572 to 574 (`dirUpdate`), 548 to 555 (`chain`).

**Expected.** A parry cancels the rest of the exchange, including the chance to chain.

**Actual.** `strike` and `launchBeat` check `ex.cancel`, but the `WIN` beat calls `openWindow`, which does not, and `dirUpdate` then honours an attack press. `chain()` runs: combo goes up, the attacker pays 6 ki, the "N HIT CHAIN" banner shows and the attacker rushes, but its strike and launch return early, so no damage is dealt. The exchange ends with the feed line `CHAIN xN ended`, which is what QA's parser counts as a chain. Up to four phantom links can stack on one parry.

**Repro.** Seed 1. Attacker (P1) x = 2500, defender (P2) x = 3400 in DEFENSIVE stance, both at y = 60. Wait 0.6 s and tap the attacker's light key (F). When the exchange's `windowStart` is set (the wind-up), tap the defender's light key (`,`): the feed shows `VORR PARRIES`. Step until the exchange offers a window (`ex.ext`), tap F again. Observed: banner `2 HIT CHAIN`, attacker ki down by 6, defender HP unchanged, feed `CHAIN x2 ended`, `ex.cancel` still true. `node qa/known-bugs-repro.js KB-003`.

**Effect on the baseline.** Of 3,817 chain events in 1,000 matches, 499 (13.1%) follow a parry: 0.50 a match. There were 720 phantom links, which waste 4.3 ki a match. Distorted metrics in `baseline-p0.md` section 8: chains per match 3.82 is really **3.32**; chains per 100 melee exchanges 23.8 is really **20.7**; the chain-length histogram and mean (2.41) include the phantoms (real 2.40, phantom 2.44). With the window closed (whatif) chains fall to 3.44 a match, and nothing else moves significantly.

**Check:** `KB-003 present`.

## KB-004: The chain strike ignores the defender's stance, not only after GUARD HOLDS

**Reported by:** Combat (CC-002).
**Verdict:** confirmed, and broader than reported: every chain strike ignores stance, whatever the defender chose.
**Lines:** 476 to 480 (GUARD HOLDS ends on `WIN` at line 480), 554 (`ignoreStance: true`).

**Expected.** A guard that "holds" reduces later strikes in the same exchange, as it reduces the first three.

**Actual.** After the three guarded hits (each 26 x 0.38 = 9.88) the exchange ends on a chain window. The chain strike is `52 + combo x 7` with `ignoreStance: true`, so it lands at full value, and it also skips the guard's ki drain, then launches. Against DEFENSIVE it deals 2.6 times what the guard would allow. The same flag also removes the +12% against AGGRESSIVE and the +25% against ESCAPE, so the chain is about 11% and 20% too weak there.

**Repro.** Seed 1. Attacker (P1) x = 2500, defender (P2) x = 3400 in DEFENSIVE stance with 60 ki, attacker at full HP and tier 1. Tap F after the cool-down; the feed reads `PRESSURE — GUARD HOLDS` with no counter (seeds where the defender counters are skipped by the scenario). Record the defender's HP after each hit: three drops of **9.88**. When the exchange opens its window tap F again: the next drop is **73.92** (66 x 1.12 combo bonus), 7.5 times a guarded hit, followed by a launch. `node qa/known-bugs-repro.js KB-004`.

**Effect on the baseline.** 4,659 chain strikes in 1,000 matches (4.7 a match) are 18.5% of all attack damage dealt (2,254 HP a match, both fighters). By defender stance: AGGRESSIVE 1,592 (mean 88 HP), DEFENSIVE 1,367 (90 HP), EVASIVE 1,174 (88 HP), ESCAPE 526 (96 HP). The DEFENSIVE chains put **76.5 HP a match** through a guard that should have reduced them (3.4% of all attack damage); the AGGRESSIVE and ESCAPE chains are 16.9 and 12.6 HP a match too weak; net +47 HP a match of extra damage. This bears on the baseline finding that aggression wins (section 9): a DEFENSIVE stance whose guard is bypassed by a press of the attack key is weaker than designed. Whatif: respecting stance moves KAI's win rate from 42.3% to 40.4% and match length from 55.4 to 57.1 s, both within noise.

**Check:** `KB-004 present`.

## KB-005: A dodged signature freezes the defender 300 units up for 0.87 s

**Reported by:** Combat (CC-005).
**Verdict:** confirmed as behaviour. Whether it is a bug or an unfinished dodge is Combat's call.
**Lines:** 616 (the DODGE beat), 620 (the exchange's closing beat).

**Expected.** A dodge is a movement: the defender leaves the beam's line and is free to act.

**Actual.** At the dodge beat the defender teleports up by exactly 300 units (`D.y += 300; D.vx = 0; D.vy = 0`) in one step, is still `locked` from the exchange start, and stays motionless until the exchange's closing beat at 1.7 s. The attacker is locked for the same time, and no other attack can be requested.

**Repro.** Seed 4. Attacker (P1) x = 2500, defender (P2) x = 3400 in EVASIVE stance, y = 60, attacker at 100 ki. Wait 0.6 s and tap the signature key (R). The feed reads `... → DODGE`. Watch the defender's `y`: at 0.82 s it rises by 300 in one step, then its position and velocity do not change for 52 steps (0.87 s) until the exchange ends at 1.70 s. `node qa/known-bugs-repro.js KB-005`.

**Effect on the baseline.** 457 of 3,648 beams are dodged (12.5%, 0.46 a match). That is 0.40 s a match with a frozen defender, 0.7% of match time. Beam outcome shares (section 6) are correct; the cost is dead time and how it reads.

**Check:** `KB-005 present`.

## KB-006: The rush flies through terrain, and through standing buildings

**Reported by:** Combat (CC-006), for terrain.
**Verdict:** confirmed, and broader than reported: buildings too.
**Lines:** `stepRush`, 745 to 751 (unclamped step at 751, final clamp at 748).

**Expected.** A rush follows the ground and stops at buildings, or goes over them.

**Actual.** `stepRush` interpolates straight from the current position to the target, `f.y += (ty - f.y)*k`, with no terrain or building test. Only the last frame is clamped (`Math.max(ty, groundY(tx))`).

**Repro.** Seed 5, attacker (P1) and defender (P2) at y = 60, attacker light attack. Mountains: attacker at x = 6200, defender at x = 7800, a 1,600 unit rush across the range: 25 of 36 rush steps are below the ground, up to 547 units inside it. City: attacker at x = 2100, defender at x = 4000: 25 of 38 steps are inside standing towers, up to 473 units deep. Control on flat plains (x 1500 to 1900): 0. The check uses the scratch copy's `groundY`. `node qa/known-bugs-repro.js KB-006`.

**Effect on the baseline.** 25 rushes a match. 3,700 of 25,051 (14.8%) spend time below the ground; most are shallow clips of crater rims (1,528 are deeper than 20 units, 191 deeper than 100, 23 deeper than 300, deepest 639). Together that is 0.40 s a match. 1,682 (6.7%) pass through a standing building, 0.10 s a match. Nothing in the baseline metrics depends on it (whatif on the terrain part: none), but it is visible on screen and would matter to the Camera and VFX directors.

**Check:** `KB-006 present`.

---

## Godot game bugs (found in play)

Separate from the prototype register above (and from its test). IDs are `GB-nnn`.

### GB-001: F9 pressed twice leaves the game grey (split screen re-attach)

**Reported by:** Orb, playing the Godot game, 2026-09-30 (screenshot: the diagonal split divider still draws, both halves flat grey, action carries on underneath, pause menu works).
**Verdict:** **fixed in 658c95b1** (Rendering, 2026-10-01, ADR 0009; CD-16, closed by QA 2026-11-07). Read at HEAD: `render/camera/split_view.gd` `attach()` makes the panes once (`if viewports[0] == null`) and takes the ones it has on a second attach, with a comment naming this bug. Not re-run in a window (Godot runs here are headless only); a Godot scene test for attach, detach, attach is still the check to add.
**Horizon:** private (closed). **Closing step:** done, with the commit above.
**Was:** confirmed by reading the code; not yet reproduced in Godot.
**Cause.** `render/core/main.gd` (F9) calls `split_view.detach()` then, on the next press, `split_view.attach(self)`. `detach()` leaves pane 0 inside its old SubViewport, but `attach()` has no re-entry guard beyond `_attached`: it calls `main.move_pane0()` again (`remove_child(pane)` on a node that is no longer main's child, then `add_child` on a node that already has a parent, so both fail and the new SubViewport is empty) and `main.make_pane()` again (a third pane is appended to `panes`). The compositor then masks two empty viewports: flat grey with the divider. Owner of the fix: Camera (`render/camera/split_view.gd`), with Rendering for `move_pane0` / `make_pane`.
**Suggested fix.** Make `attach()` re-use `viewports` when they exist (set `main.compositor = self`, `_attached = true`, restore the update modes) instead of creating new panes; or make F9 toggle only the mask and keep the panes.
**Effect.** Any session where F9 is pressed an even number of times after the first press (detach, attach) ends grey for good; restart is the only way out. Not a sim bug: determinism and the baseline are unaffected.
**Test to add once fixed.** A Godot scene test: attach, detach, attach, then assert `panes.size() == 2` and that pane 0's parent is `viewports[0]`.

### GB-002: A pale vertical "aura" in the far sky when flying high (tier 3 and 4 sky reaction) (reopened 2026-10-02, fixed again 632f6c9)

**Reported by:** Orb, playing the Godot game, 2026-10-02 (two screenshots: a soft blue-white column near the horizon, off to one side of the fighter, with vertical streaks; it moves with the fighters; both fighters at tier 4).
**Verdict:** not a rendering fault: it is the designed sky reaction (`docs/design/rule-of-cool.md` feature 12), which reads as a smear.
**Cause.** From tier 3 `render/core/pane_world.gd` `_sky_react` gives `render/shaders/sky.gdshader` the direction to each fighter and a strength (half at tier 3, full at tier 4). The shader clears the clouds in a tall opening above him (taller than wide, lifted to the horizon, radius `RenderLook.SKY_REACT_R` 0.2) and pales the sky inside it toward his aura colour, with the edge lit in his colour. Because it is anchored to the fighter's direction it slides across the sky as he or the camera moves, and from a high camera the opening sits against the horizon glow with nothing to explain it: a pale blurred pillar. In the screenshots both fighters are at tier 4 and the column is near the far one (the P2 marker is off screen right).
**Not QA's to change** (Rendering, Camera and VFX own the look; Game Design the feature). Options for them: shrink or soften the opening (`SKY_REACT_R`, the strength curve), show it only while the fighter is on screen, give it a visible cause (a ring or the cloud edge lit more than the pale fill), or put it behind the reduced-motion `sky_calm` option and a settings toggle.
**Effect.** Looks like a bug to a first-time player; no effect on the sim or the baselines.
**Status: fixed in 8fd6aba** (Rendering): the sky reaction is a cloud gap with a lit edge, no pale fill, and only for a fighter on screen. Not re-verified by QA in play.
**Reopened 2026-10-02 (Orb, two screenshots on the live web build, both fighters tier 4).** The cloud gap with a lit edge still reads as a big glowing texture over each fighter in the clouds at high altitude (top right in the first shot, top left in the second), and as the fighter moves left and right the clouds shimmer. So the fix removed the pale pillar but not the complaint: a gap and lit rim that follow a fighter's direction across the sky are the problem, not the fill. Not verified in the current source (`render/shaders/sky.gdshader` at 8fd6aba still lights the clouds' edge round the gap, `tint` and `rim`); Orb's build may or may not include 8fd6aba. Options for the owners: drop the reaction (the feature is rule-of-cool 12 and was never in Orb's pitch list), make it a still, world-anchored effect that does not track a fighter (a fixed cloud parting that does not move with him), or fade it out above a height where it only shows as a patch; if it stays, put it behind a setting and `sky_calm`. Status: open, with Rendering and Game Design.
**Fixed again in 632f6c9** (Rendering, per the EP's status line): the sky reaction is off by default, plain clouds at every tier, and a cloud shimmer above 4,800 units is fixed. Not yet seen by Orb; QA has not re-verified in play.

### Open observations from Orb's two-player playtest (2026-10-02; direction in `docs/ep/vision.md`, last section)

Reported through the EP. QA has not reproduced or measured these; each has an owner. IDs follow GB-002.

| ID | Observation | Owner | Status |
| :--- | :--- | :--- | :--- |
| GB-003 | The split-screen camera jolts when a player is knocked away. | Camera | open, with Camera |
| GB-004 | A ranged attack press locks both fighters during the fly-in. Raised as a design question, not a fault. | Game Design | open, design call |
| GB-005 | Mountain tumbles gain too much momentum from a glancing bounce. | World | open, with World |
| GB-006 | A launched fighter flies at speed feet first, laid out along the flight line (Orb, 2026-10-02, a screenshot of VORR on the live web build: body horizontal, legs leading, a bright speed streak behind). Looks silly in motion | Animation (the `launch` body profile and spin, `anim_fighter.gd`), with Rendering (the pivot's rotation from `f.rot` and the pose) | **fixed in cce8a59** (a launched body flies head first once its spin dies; Animation's `lead_scan` guards it); not re-verified by QA in play |
| GB-007 | Levitating rocks stay fixed round a fast-moving tier 3 or 4 fighter: a few stay locked in a field round a standing fighter, and a fighter who crosses the screen quickly drags the rocks round his head along with him in the same relative position (Orb, 2026-10-02, a screenshot on the live web build). Expected: rocks float only while he is near the ground and still; in fast flight they should be left behind or gone | VFX / Rendering (`render/vfx/rocks.gd`: pieces are a function of the fighter's position and the clock, eased out over 0.5 s once he leaves the state) | open; QA has not reproduced it. By the header's own rule they should not show for a fast mover, so the likely cause is the 0.5 s ease-out running while he is already moving fast: a few pieces ride along; a shorter fade (or leaving the pieces in world space as he leaves) would fix it |

QA has no band for any of the three yet. For GB-005 the harness already counts bounces per bounced journey and journeys longer than 4,000 units (`5c.bounces`, `5c.long`); a per-journey momentum or speed-gain row would need a field from World's journey events. For GB-003 a camera-motion metric would need Camera's rig output; ask the EP when a band is wanted.

### GB-008: A launch (or a charge) clears a lock-broken fighter's flag without telling anyone

**Found by QA, 2026-10-03** while chasing a hard-test failure (`8.lock.max`: longest lock break 21.88 s over 747 breaks, c1714b5 default arm seed 46).
**Cause.** Lock breaks are `hidden` in the ESCAPE stance (`sim/core/hiding.gd`, `_lockBreak`); `regainLock` emits `found`, sets `lockBackT` (the 6 s no-rebreak guard) and clears the flag, within 4 s at most. Two other places clear the flag directly: `sim/director/launch.gd:316` (`tgt.hidden = false` when the lock-broken fighter is launched) and `sim/core/fighter.gd:319` (`f.hidden = false` when a hidden fighter starts charging). Neither calls `regainLock`, so no `found` event is emitted, `lockBackT` stays unset (the 6 s guard is skipped) and the harness' episode stays open until that fighter's next `found`. Probe on the c1714b5 export, seed 46 default arm: both fighters broke lock on the same tick (525.35 s, tick 34043); fighter 1 was launched at 526.88 s (tick 34138), 1.53 s into the break; the next `found` for fighter 1 came at 547.23 s. The real lock break lasted 1.53 s. Same chain for mirror-villain seed 181 (128 s) and seed 319 (49 s). On a56187a: swap seeds 350 (45.8 s) and 97 (16.1 s), mirror-villain seed 109 (209.8 s).
**Effect.** Event stream only: no `found` after a launch, and the 6 s rebreak spacing is not applied after a launch-ended break (the gap row passes anyway, 6.90 s). The default-arm row `8.lock.max` passes or fails by chance (a56187a baseline 4.02 s; two scratch variants showed 41.82 s and 20.77 s). QA now also reads all four arms (`8.lock.max.all`: 4 of 2,544 breaks over 4 s on a56187a).
**Fix, for Simulation or the Director's owner (two lines):** in both places call `SimHiding.regainLock(S, f)` when `f.hidden` is true, instead of clearing the flag. `8.lock.max.all` then passes with no harness change.
**Status: fixed in fd381c6** (Simulation). Confirmed by QA on df05b9f: `8.lock.max.all` passes (longest 4.02 s over all eight arms, 3,200 matches).

### GB-009: A brink fighter cannot be finished by a player who only fires bolts at range

**Found by QA, 2026-10-03** in the energy plan on a56187a (E3, E4, E5 of `qa/timing-edge.js`). A timed blaster (`tapper:energy=1`, a bolt about every 24 ticks) against a timed melee player: 40 of 40 matches reach the 900 s cap (E4, E5), and a probe of four matches with and without the stick-up on heavies does the same. In the traced match the melee player reached the brink at 222.7 s (`brink_enter`, `last_stand_ready`, `last_stand_end` expired at 242.7 s) and then flew off; the blaster hit it about 2,100 times a match (72,000 damage) and no finisher ever started, because bolts do not open one.
**Not the same as** the "bolt-only cannot finish" finding of the energy baseline: E1 (a bolt-only masher against a melee masher) finishes 40 of 40, because the melee masher closes in and ends up in a finisher; E2 (against the medium AI) wins 57.5%, above its 20 to 40% band.
**Question for Game Design / Combat:** should a brink fighter be finishable by blasts alone (a last blast at the brink, a charged shot, a signature)? If not, the E4/E5 script needs to close in for the finisher, and QA will add a `chase` option to the scripted players; the band for E5 (40 to 60%) cannot be measured until one of the two happens.
**Status: finish fixed in slice 12 (df05b9f), balance open.** E4, E5 and the slow mix finish 40 of 40. The blaster now wins 87.5% (fast) and 82.5% (slow mix) against a timed melee script that never guards or dodges, and a mixed blaster 57.5% against the medium AI (starting band 25 to 45). Whether that is the rule (any shot counts, window 120) or the unresponsive script is for Game Design; QA has no answer from the scripts alone.

### GB-010: From the second match on, the ground loses its link to the tile field

**Reported by:** QA, 2026-11-26, while measuring memory (not reported by a player).
**Verdict:** **fixed in 7efff59e** (Rendering's ground-link, 2026-11-26; closed by QA the same day). QA's link probe on d9bc2f07, headless editor build: matches 1, 2 and 3, both panes' `ground.tile_field` set and the same as the pane's `tile_field` (`docs/qa/runs/d9bc2f07/ground-link-three-matches.txt`). `render/tools/ground_link_check.gd` holds it in the render gates (46ab9572). No one has looked at what changes on screen.
**Was:** confirmed on ac4ba152 (0.1.1): match 1 linked; matches 2 and 3, both panes `ground.tile_field` null (`docs/qa/runs/ac4ba152/hunt/ground-link-three-matches.txt`, `link_probe.gd.txt`). The 0.1.1 build has the bug.
**Horizon:** web (closed). **Closing step:** done, with the commit above.
**Cause (read, not tested by a fix).** `render/core/planet_view.gd` `_bs_begin` does `if ground != null: ground.tile_field = null`. From the second match the second pane's `ground` is the first pane's (`ground = source.ground`), so its begin clears the link the first pane has just made, and its `_bs_tiles` returns early (`tile_field = source.tile_field`) without setting it again. In match 1 the second pane still had its own ground at that point.
**Effect (from the code; no one has looked at a screen).** `render/core/ground_field.gd` `ground_at()` off the fighter plane then reads the old arena heights in place of the tile ground's, and `_store_holds()` answers false. `ground_at()` is used for heights in depth by `pane_world.gd` (around lines 992 and 1100 to 1122), `planet_view.gd` and `crowd_flight.gd`. What a player sees from this is **not verified**; any session of two matches or more has it.
**Test to add once fixed.** Start two matches headless; assert every pane's `ground.tile_field == tile_field`.

### GB-011: Lakes end in standing walls of water, with houses under them ("large cubes of water where it shouldn't be")

**Reported by:** Orb, 2026-11-27, playing (screenshot: a town with a flat-topped, stepped block of water standing among and over the houses). The build, seed and place of the screenshot are not known.
**Verdict:** **the fault is in the world data; that it is what Orb saw is likely, not proven.** On 5dbd89ca, the default planet (planet 7, touch 3, generation 3, the one every match plays), before any fight (`docs/qa/runs/5dbd89ca/water/water-scan.txt`, scripts beside it):
- near line x 22,400 to 23,300, houses 243 to 469 tall stand under 576 to 611 units of lake water; near x 50,800, 30 buildings stand in lake or river water up to 456 deep;
- sampled every 50 units, the water stops over lower dry ground in 128 places near the first site (faces up to about 1,500 high, level 2,062) and 84 near the second (about 490 high, level 689);
- apart from these, 85 buildings of 3,835 have ground below sea level.
**Horizon:** web. **Closing step:** World bounds or drains lakes so no water face stands over dry ground and no building is under a lake, with a check over the planet pool.
**Cause (read, not tested by a fix).** `sim/world/waterrec.gd` `lakeOf` floods a lake from its lowest cell and cuts the flood at `maxr` (twice the lake's width on the line, 800 to 6,000 units; its comment: "a leak is cut here"), at `MAX_NODES`, and at nodes another lake claimed. Beyond the cut the ground can be far below the lake's level and is dry, so the water ends in a face. `recordWater` is what both the sim and the tile renderer read.
**Effect.** Visible slabs of water in towns, in every match that goes there. Whether fighters or bodies behave wrongly inside that water is not checked.

## Problems Orb reported in play, 2026-11-01 to 2026-11-09 (the 52 of `docs/ep/alpha/audit-2026-11-13/reads/RR-08.md`)

Added 2026-11-14 (A-QA-03). Numbers `PR-001` to `PR-052` are RR-08's rows 1 to 52. Statuses are QA's reading from the records named; "not re-read at HEAD" means QA has not opened the thing since the report, so the status is the report's. **Severity** (A-QA-07): **S1 Blocker** a tester cannot start, finish, leave or report (a menu or pause that does not show, a crash, a lost save); **S2 Major** a fight moment the game promises fails or misleads, or control is taken from the player; **S3 Minor** looks or feels wrong and play goes on; **S4 Polish**. The proposed criterion X-35 reads S1 as "no open one on the candidate" and S2 as "every open one seen by Orb and carried by name". **Horizon** is the earliest release the bug blocks (private: Orb's own PC and LAN; web: a public page or pin; store: a store page). **Closing step** for every row: open it at its pin and at HEAD (read the code, data or a replay), mark it fixed with the commit, or leave it open with what is left.

| ID | Date | Build | The problem (shortened) | Severity | Horizon | Status | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| PR-001 | 2026-11-01 | not stated | a green tube popped up behind him after he hit the ground | S3 | web | open: not re-read at HEAD | Rendering, VFX |
| PR-002 | 2026-11-01 | not stated | the mountain with a house on the hill is opened up, its hollow interior shows | S3 | web | open: not re-read at HEAD | World |
| PR-003 | 2026-11-01 | not stated | flight overtuned, way too fast; the split screen takes half the screen | S2 | private | open: flight 3,500 is the planned default (Orb 2026-11-09 felt it manageable; GW1b), the split-screen part is Camera's | Game Design, Camera |
| PR-004 | 2026-11-01 | not stated | firing a beam, the character slowly drifts, then fires | S3 | private | open: not re-read at HEAD; the beam-still park (docs/director/pending/beam-still) is the fix, not landed | Encounter |
| PR-005 | 2026-11-01 | not stated | player 1 should always be on the left, player 2 on the right | S3 | private | open: a design rule, not read at HEAD | Game Design, Camera |
| PR-006 | 2026-11-01 | not stated | a charge with the right stick is interrupted by a small attack | S2 | private | fixed in part: chargeArmour is on in 6a30b4c9 (heavy charges are armoured); on Orb's 1726 file 3 of 17 heavy charges were still lost to a stagger or the brawl's end (docs/qa/runs/c974e451/README.md section 3) | Encounter |
| PR-007 | 2026-11-01 | not stated | rumble works, no sound effects | S2 | private | fixed by 2026-11-08: Orb, in the 1726 file, "sounds were working just fine"; commit not named | Audio |
| PR-008 | 2026-11-01 | not stated | the first match against a player who did not fight back ended quickly, no chance to power up | S3 | private | open: design (Game Design) | Game Design |
| PR-009 | 2026-11-01 | not stated | excessive terrain bounces: six or seven off an outcrop | S3 | web | open: this is GB-005, with World | World |
| PR-010 | 2026-11-01 | not stated | launches seem to cause frame spikes | S2 | private | open: cause found (Performance 3a489e73: PROP SMASH's flight aim), the benched fix has not landed | Performance, Encounter |
| PR-011 | 2026-11-01 | old PC test | the same frame drops from impacts on the old PC | S2 | private | open: as row 10 | Performance |
| PR-012 | 2026-11-01 | old PC test | the ground draws much higher than where the fighter seems to impact | S3 | web | open: the A1 clipping scope | Rendering, World |
| PR-013 | 2026-11-01 | old PC test | the skyscrapers look like townhouses stretched extremely high | S4 | web | open: not re-read at HEAD | Rendering, World |
| PR-014 | 2026-11-01 | second play | getting knockbacks feels very arbitrary | S2 | private | open: not re-read at HEAD | Encounter, Game Design |
| PR-015 | 2026-11-01 | second play | hard to charge up an attack when every hit seems to interrupt | S2 | private | fixed in part: as row 6 | Encounter |
| PR-016 | 2026-11-01 | second play | still no sound effects (all sound settings on) | S2 | private | fixed by 2026-11-08: as row 7; commit not named | Audio |
| PR-017 | 2026-11-02 | 10d8b8cf | a "Confusing" tag on a match, no sentence | S4 | private | cannot reproduce: a tag with no description to act on | QA |
| PR-018 | 2026-11-06 | 10d8b8cf | control taken away: forced into a side switch, then a beam fired at me | S2 | private | fixed in part: the 0.3 s free rule for a beam and the carryRound switch are in 6a30b4c9's list; QA has not measured it | Encounter |
| PR-019 | 2026-11-06 | 10d8b8cf | could not fire a beam at close range, the opponent could | S2 | private | fixed: the stick beam is thrown at contact in Orb's 1646 file (6a30b4c9) and half the computer's beams in the c974e451 baseline start at 58 units | Encounter |
| PR-020 | 2026-11-06 | 10d8b8cf | at high speed impacts the frames stutter and the audio crackles | S2 | private | open: not re-read at HEAD | Performance, Audio |
| PR-021 | 2026-11-06 | 10d8b8cf | the fighter kept attacking up a mountainside after Orb let go | S2 | private | cannot reproduce: QA's replay (2026-11-06) shows the sim never made slot 0 attack on its own; the recorded intent carried input | QA |
| PR-022 | 2026-11-06 | circle=1 page | LT + Y worked very strangely | S3 | private | fixed by 2026-11-09: Orb, "zip attacks have improved the most" (1646 answers); commit not named | Controls, Combat |
| PR-023 | 2026-11-06 | circle=1 page | the fighter that hit a building bounced back like a ping pong ball | S2 | private | open: Encounter's cityHold is the fix (A1); QA's city read waits for it | Encounter |
| PR-024 | 2026-11-07 | LAN a8bc66e2 | slam with the right stick, did not give the mega slam | S3 | private | open: not re-read at HEAD | Encounter |
| PR-025 | 2026-11-07 | LAN a8bc66e2 | fighter speed confusing; high speed launches a little too fast | S3 | private | open: flight 3,500 and travel 1.5 are the levers (GW1b) | Game Design |
| PR-026 | 2026-11-07 | LAN a8bc66e2 | sound effects not audible until the first pause | S2 | private | open: the web page's audio starts after a first gesture; not re-read at HEAD | Audio, Tools |
| PR-027 | 2026-11-07 | LAN a8bc66e2 | terrain does not match the characters' hitboxes; clipping into the ground | S3 | web | open: the A1 clipping scope | Rendering, World |
| PR-028 | 2026-11-07 | LAN a8bc66e2 | ripples on the right of the screen crawl toward the left | S4 | web | open: not re-read at HEAD | Rendering, VFX |
| PR-029 | 2026-11-07 | first 2v2 | stuttering, inconsistent | S2 | private | open: frame spikes track rollbacks (docs/qa/runs/091dfac9/lan-log-seed77-read.md) | Netcode, Performance |
| PR-030 | 2026-11-07 | first 2v2 | the old PC's camera locked onto one player; never saw all four fighters | S3 | private | open: Camera's others-frame park is not landed | Camera |
| PR-031 | 2026-11-08 | 091dfac9 LAN | background buildings disappear and reappear | S3 | private | open: hypothesis (not tested) that it is the picture after a rollback re-run | Netcode, Rendering |
| PR-032 | 2026-11-08 | 091dfac9 LAN | a patch of air forced me upwards, like an invisible wall | S2 | private | cannot reproduce: the LAN match was not saved, nothing to replay | Netcode, QA |
| PR-033 | 2026-11-08 | 1931a0f8 | firing beams without intending to, not RB + right stick | S2 | private | fixed in part: B never fires a beam, 6eec6a75 (bNoBeam); the late stick beam is the stray-beams park, not landed | Controls, Encounter |
| PR-034 | 2026-11-08 | 1931a0f8 | the opponent's beam hit me from far below, off my screen | S2 | private | open: by design today (a beam always arrives); the A3 beam rebuild | Game Design, Encounter, Camera |
| PR-035 | 2026-11-08 | 1931a0f8 | another beam from far under me sent me flying | S2 | private | open: as row 34 | Game Design, Encounter |
| PR-036 | 2026-11-08 | 1931a0f8 | the first meteor knocked the opponent opposite to the punch | S2 | private | fixed in 6eec6a75 (sideFromBlowOnly); QA's side-from-blow arms not yet read | Encounter |
| PR-037 | 2026-11-08 | 1931a0f8 | the trail arc does not match the flight; the trail is too long | S3 | web | open: the drawing (QA: the sim's landing prediction ends within 630 units) | VFX, Rendering |
| PR-038 | 2026-11-08 | 1931a0f8 | textures gone to a flat brown inside a crater | S3 | web | open: cause found, the black crater is beam scorch (Rendering bf29f9ba); the look fix is held | Rendering |
| PR-039 | 2026-11-08 | 1931a0f8 | a distorted landscape and a hump of ocean water | S3 | web | open: needs a still of seed 3687423 | World, Rendering |
| PR-040 | 2026-11-08 | 1931a0f8 | beams feel arbitrary | S2 | private | open: the baseline is read (docs/qa/runs/c974e451); the A3 beam rebuild | Game Design, Encounter |
| PR-041 | 2026-11-08 | 1931a0f8 | charge attacks interrupted arbitrarily | S2 | private | fixed in part: as row 6 | Encounter |
| PR-042 | 2026-11-08 21:52 | not stated | LT high speed not quite fast enough, but it sped up when further apart | S3 | private | open: not re-read at HEAD | Game Design |
| PR-043 | 2026-11-08 21:52 | not stated | in close-up fights we did not feel in control of our fighter | S2 | private | open: Encounter's control audit | Encounter |
| PR-044 | 2026-11-09 | 6a30b4c9 | a combination of face buttons fired a beam, without the stick | S2 | private | open: a stick beam fired late into a brawl (tick 5220); the stray-beams park fixes it (acceptance 3: late 12.8% to 0.5%), not landed | Encounter |
| PR-045 | 2026-11-09 | 6a30b4c9 | the game is paused with no menu; the feedback form cannot be seen | S1 | web | open: not re-read at HEAD | UI |
| PR-046 | 2026-11-09 | 6a30b4c9 | wants to knock the opponent back and chain more hits while they fly | S3 | private | open: a design request | Game Design, Combat |
| PR-047 | 2026-11-09 | 6a30b4c9 | knocked into a building, they bounce back to the strip like a ping pong ball | S2 | private | open: as row 23 | Encounter |
| PR-048 | 2026-11-09 | 6a30b4c9 | ground clipping with the character models | S3 | web | open: the A1 clipping scope (as rows 12 and 27) | Rendering, World |
| PR-049 | 2026-11-09 | 6a30b4c9 | a row of three humps in a crater | S3 | web | open: not re-read at HEAD | VFX, Rendering |
| PR-050 | 2026-11-09 | 6a30b4c9 | the start menu's d-pad: up and down inconsistent, left and right move the option underneath | S2 | web | open: not re-read at HEAD; the Rail menus are in 6a30b4c9 | UI |
| PR-051 | 2026-11-09 | not stated | the black crater looks out of place | S3 | web | open: as row 38 | Rendering |
| PR-052 | 2026-11-09 | not stated | the crackles sounded bad | S3 | private | open: as row 20 | Audio |

Counts: 52 accounted for. Status: fixed 5, fixed in part 5, open 39, cannot reproduce 3. Severity: S1 1, S2 26, S3 22, S4 3. A row that names a fix as "not landed" or "held" stays open. Row 9 is GB-005; rows 6, 15 and 41 are one subject; rows 23 and 47 are one subject; rows 34 and 35 are one subject; rows 38 and 51 are one subject; rows 20 and 52 are one subject; rows 33 and 44 are two causes of one report.

---

## Not checked yet

Combat's CC-007 to CC-013 and Game Design's other notes were not in this brief. CC-009 (a dodge parry window that can never parry) and CC-010 (signature never parries) would be quick to confirm. Add entries here as KB-007 onward and add a matching check to `qa/tests/known-bugs.test.js`; the last check in that file fails until you do.
