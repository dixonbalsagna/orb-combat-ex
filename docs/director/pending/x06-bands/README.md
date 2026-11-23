# Parked: a Medium candidate for X-06 and A-AI-10, and the computer's answer to a held charge (off main until QA measures them)

Encounter, 2026-11-21, sprint A1. QA found Medium a cliff for a single pad on Orb's scheme (6 of 100) and wide open to charged heavies (60 of 60). Easy is 100 of 100 for the beam pad. This is one Medium candidate in `data/director/ai.json`. **QA measures it with the strike, beam and charge pads.**

**The one line:** Medium matches the player's pace as Easy does (`levels.medium.brawl.paceMatch`, Easy's own floor 12 and ceiling 30), which is what makes a single pad's blows trade evenly; and Medium perfect-blocks a full charge as often as Hard does (`levels.medium.brawl.perfectVsHeavy` 0.15 to 0.3), which closes the charged-heavy hole. Pace matching never touches a charge, and the charge answer never touches the strike-and-beam pad: their runs are tick for tick the same with and without it.

## The readings

On the kept 9 November build's tree (its data is main's since GW1a), QA's `qa/godot/orbs_player.gd --solo` with QA's planet settings. Records are in `docs/director/runs/b0e20f9a/x06-medium/x06-candidates.txt`. My baseline reproduces QA's: Medium as shipped, 4 of 50 for the beam pad.

| Medium | Beam pad (strikes, guard, a beam every 420) | Charge pad | Strike-only pad |
| :--- | ---: | ---: | ---: |
| As shipped | 4 of 50 (8%; QA 6 of 100) | QA: 60 of 60 | QA: 0 of 200 |
| **This candidate** | **9 of 30 (30%)**; hits even (15,064 to 15,800, from 1 to 2.6) | ~~14 of 30~~: wrong pad (see below); QA: 40 of 40 | 0 of 30 |

**Correction (2026-11-21):** my charge-pad cell was measured with an older copy of QA's player whose charge mode held Y, not B, so it measured a different pad. QA's five-pad read on main 17a8dd6c with the candidate (`docs/qa/readings/x06-medium-candidate.md`) has the B charge pad at 40 of 40 with the candidate and without it. The candidate does raise Medium's perfect block against full charges from 14.8% to 30%, as built. That's why the second diff below exists.

**What else I tried, which didn't move the beam pad beyond the noise of 30 matches (about ±17 points):**
- Every numeric Medium knob moved toward Easy's (t 0.4: 0 of 30; t 0.6: 1 of 30; with pace matching, t 0.5: 5 of 30).
- The beam struggle's `aiHit` at Easy's 0.4 (`interrupts.json`): 1 of 30.
- `beamAnswer` 0.25: 16 of 60.
- `perfectBlockMul` 0.35 with `riposte` 0.75: 13 of 60.

## What the candidate doesn't close

- **The beam pad sits at about 30%,** under the 35 to 55% band. Pace matching is the only Medium lever I found that moves it (from 8%).
- **The strike-only pad still wins 0 of 30.** QA's note holds: stick-only pads have lost to Medium in every reading.
- **Easy stays above its band.** The beam pad won 29 of 30 with Easy's `beamAnswer` 0.25 and `beamDodge` 0.55 (not parked). The beam is what wins Easy (61% without it), and Easy's beam knobs barely move it. No Easy candidate is parked.

## Dropped: the lower charge worth

Game Design's first ruling lowered a full charge's worth (`brawl.heavy.charge.worth` [8, 10] to [6, 7]). My read with it: the charge pad still won 20 of 20, and the whole-kit pad fell to 20% (record `docs/director/runs/01367c97/x06-charge-worth/`). Game Design reverted it, and its diff is gone.

## Where X-06 stands: the scripted exit, and the human bands waiting for Orb (2026-11-22)

**Game Design's ruling after QA's final read** (`docs/design/gauntlet-plan.md` section 10, with the stand-in's advice agreeing):
- The scripted pads now judge exploits, ceilings, floors and order, not the human bands.
- **X-06's A1 exit, by scripts:**
  - no one-note pad above 80% at Easy, or above 55% at Medium;
  - the whole kit beats each one-note pad at every level;
  - every pad does better at Easy than at Medium, and better at Medium than at Hard;
  - the whole kit at Medium wins at least 25%.
- Hard is reported only.
- **The chances moved:** `holdAnswer` Easy 0.5 to 0.65, Medium 0.8 to 0.5; Hard stayed 0.95.

**QA's re-read at those chances** (`docs/qa/readings/x06-reread-hold-answer-recut.md`, main 7b69eafc, 40 a cell):
- Lines 1, 2 and 4 passed: the charge pad 57.5% at Easy and 50.0% at Medium, and every pad did better at Easy.
- Lines 3 and 5 failed at Medium: the kit won 4 of 40 (10.0%), under the masher and the charge pad, and under 25%.
- QA's isolation: the kit is 32.5% with the candidate alone, 27.5% with the hold answer at 0, and 10.0% at 0.5. **The hold answer itself takes the kit down.** No flat chance fixed both: at 0.25 the kit read 17.5% and the charge pad 97.5%.

**Game Design's ruling that ends the X-06 loop (2026-11-22): the answer reads repetition.**
- At Medium the chance depends on how many visible holds that fighter has started in the last 300 ticks, this one included: the first 0, the second 0.4, the third or more 0.9.
- Data: `levels.medium.brawl.holdAnswer` `{windowTicks 300, byCount [0, 0.4, 0.9]}`. Hard stays 0.95.
- **Game Design's Easy ruling (2026-11-22), re-ruled after Encounter's probe:** Easy reads repetition too, gentler, with a longer memory: `{windowTicks 420, byCount [0, 0.3, 0.65]}`. It was `{300, [0, 0.3, 0.75]}` before that, and a flat 0.65 before that. The pad's real holds come about 187 live ticks apart, so a 300-tick window mostly counted 2. A lone hold goes unanswered at every level. **QA reads the Easy charge pad:** the target is 60 to 75%. The lever is the third value: 0.8 if the pad is over 80%, 0.7 if it's under 50%.
- A lone hold, like the kit's one every 300 to 390 ticks, isn't answered at Medium. The charge pad's repeats, about every 100 ticks, are answered at 0.9.
- **QA reads once:** the kit at Medium at least 25%, the charge pad at Medium at most 55%, and the order.
- **If it fails, the fallback is to land at a flat 0.5 with the floor marked.**

**The human bands: not met, waiting for Orb's play.** These are QA's final read at the previous chances (Easy 0.5, Medium 0.8, Hard 0.95; `docs/qa/readings/x06-final-read.md`, 40 matches a cell, main b04de5d5 with the three diffs):

| Pad | Easy | Medium | Hard |
| :--- | ---: | ---: | ---: |
| Whole kit (band: Easy 60 to 80, Medium 35 to 55, Hard 10 to 30) | 32 of 40 (80.0%) | 5 of 40 (12.5%) | 0 of 40 |
| Strike only | 18 of 40 (45.0%) | 0 of 40 | 0 of 40 |
| X masher | 16 of 40 (40.0%) | 6 of 40 (15.0%) | 0 of 40 |
| Beams only | 21 of 40 (52.5%) | 0 of 40 | 0 of 40 |
| B charge only (ceiling: Easy 80, Medium 55) | 38 of 40 (95.0%) | 1 of 40 (2.5%) | 0 of 40 |


## The hold answer (Game Design's combined ruling, 2026-11-21; chances re-cut 2026-11-22)

The worth-cut record showed that all 1,256 full charges reached their release. The computer never interrupted or evaded during a 44-tick hold. Game Design's ruling (`docs/design/gauntlet-plan.md`) is that **the computer answers a visible hold during the hold.** It never relies on the perfect block alone, never guards and never steps out.

**What `x06-hold-answer.diff` builds** (`DirBrawl._aiVsHold` and `_aiHoldDodge`, called from the brawl's `aiInput`):
1. **The trigger is a visible hold:** the rival holds B on a fist's heavy, winding or charging, and his B is still down when the computer's reaction time comes. A tap, or a press let go sooner, isn't one. There's one draw a hold, keyed by the hold's start tick, at the level's new `brawl.holdAnswer`: **Easy 0.65, Hard 0.95, and at Medium `{windowTicks 300, byCount [0, 0.4, 0.9]}`** (Game Design, 2026-11-22). The repetition is counted from a record on the holder: the start ticks of his last three visible holds, in three slots after the brawl's RT-window slot at the end of `f.act.dirI`. It's written only while the computer's level has a `holdAnswer`; a read never sizes it. It acts only once its reaction time (`reactTicks`, 14) has passed since the press.
2. **Drawn, in a light's reach (the catch's own), it grabs.** It presses A as soon as its line is free. The catch's tell beats the armour, and its landing stops the wind-up; the clinch starts one ahead.
3. **The grab is a hold-break** (`interrupts.json` `grapple.throw.holdBreak`, `DirGrapple`). Its clinch's throw is worth `worthMul` 1.5 times a throw (6 to 9), with its usual opening, and `noRegrab` doesn't start. This applies only when the catch stopped a held B; any other throw is unchanged. The mark lives on the caught fighter's `noRegrab` slot as -1, which never refuses a catch, so no new state slot is needed.
4. **Drawn, out of reach,** it closes in on its stick (the brawl's giving-ground step, straight at him) when that brings it into reach before the charge's first flash (`heavy.charge.fromTicks`, 32, from the press). Then it grabs.
5. **Otherwise it slips, timed to the release** (Game Design, 2026-11-22: the computer plays by the player's rules, so it's the slip, not the dodge-cancel). That covers being too far to close in time, or no catch to be had (a lockout, or the grapple off).
   - The slip is LT tapped with a flick straight away from him. It sets the computer's dodge state, at no energy and with no cooldown. It waits until the blow's contact falls inside the slip's protection (`SimAct.dodgeWindow`, Controls' 12 ticks).
   - The released blow meets nothing (the miss cue says `dodged`), he is open for its 20-tick `recoverWhiff`, and the existing open-rival rule punishes him.
   - **The slip's own rule** (right-hand-attacks-rulings.md, R34): the third slip of one direction inside 3 s keeps its movement and loses its slip frames, so that charge lands. The 3 s is `ai.json` `holdSlip.thirdInTicks` (180). The computer's last two slips are kept after the hold record.
   - The rule isn't built for a player's slips; R34's slip frames aren't in the sim yet.
6. **No new state.** It never guards or gives ground against a hold it answers. With the chances at 0 and `holdBreak` absent, the golden is identical (below).

**A fault I found and fixed in this cut:** the previous build treated "his B is up" as a release whenever it looked. So a B tap (let go at 3 ticks, landing at 28) could be dodged at the answer's chance, though it was never a visible hold. Now only a hold noted with its button down at the reaction time is answered or dodged. A row checks it. It touched every pad that taps B, and QA's earlier reads include it.

**What the player sees:** the computer's dodge state (Animation's Dodge), an afterimage, and a `hold_dodge` cue (text `slip`, or `slip_no_frames` for a third slip; target the charger). **Animation and VFX: no pose for a slip inside a brawl yet,** beyond the dodge state.

**The check:** `sim/director/tools/hold_answer_check.gd`, **21 of 21** (about 2 minutes). A player holds B at the computer, at Medium:

| Row | Result |
| :--- | :--- |
| Drawn, in reach: it grabs after its reaction time, never sooner | ok (+14 against 14) |
| ... the clinch starts one ahead and the charge never lands | ok |
| The hold-break's throw is worth 1.5 times the throw: the same staging with `holdBreak` absent | ok (72.5 against 48.4 damage) |
| ... and leaves no `noRegrab` (without the rule, 120 ticks) | ok |
| Drawn, 1.2 bh out: it closes in and grabs before the first flash | ok (closes from +14, grabs at +28; the flash at +32) |
| Drawn, 2.3 bh out (too far to close in time): no close-in, no grab; it slips the release at no energy | ok (the slip at +51, the release at +50) |
| ... the charge meets nothing and the computer punishes him while he is open | ok (the miss cue says `dodged`) |
| Drawn, no catch to be had (a lockout): the same slip, miss and punish | ok |
| ... with the dodge's cooldown running and no ki it still slips, and the charge meets nothing (the slip is never refused by the dodge-cancel's cooldown) | ok |
| ... the third slip of one direction inside 3 s keeps its movement and loses its frames: the charge isn't made to miss (R34) | ok |
| In every drawn hold it never guards and never gives ground | ok |
| One draw a hold, keyed by its start: each level's share of 2,000 holds within 3 points (each count's at Easy and Medium) | ok (Easy 0, 0.300, 0.642; Medium 0, 0.400, 0.912; Hard 0.948) |
| **Repetition at Medium:** a lone hold isn't answered (count 1, chance 0) and the charge reaches its release at full | ok |
| ... a lone hold isn't answered at Easy either (count 1, byCount's first entry) | ok |
| Easy's window (420): two earlier holds 200 and 360 ticks back count 3 at Easy, and 2 at Medium (300) | ok |
| ... a third hold in the window (two before it, 100 and 220 ticks earlier) is answered: count 3, chance 0.9, keyed and deterministic | ok (its draw 0.177) |
| ... holds older than the window don't count (two at 320 and 380 ticks earlier: count 1, unanswered) | ok |
| ... the record counts real holds: three visible holds count 1, 2, 3 | ok |
| A tap isn't a visible hold: B let go at 3 ticks is never noted, grabbed or dodged, with the answer at 1.0 | ok |
| **The exploit is closed:** a charge-only pad doesn't win every Medium match. It's QA's charge pad played by the check, on QA's planet settings, seeds 1 to 6. | ok (the pad 2, the computer 4) |
| Negative control: `holdAnswer` 0 and the old answers at 0; nothing answers, and the charge reaches its release at full | ok |

**The exploit row can fail.** With Medium's `holdAnswer` at 0 (the exploit open), the same six matches go 6 of 6 to the pad, and the row fails (the previous cut's record, `hold_answer_check.txt`).

**Computer-against-computer pace** (part 4 of the ruling): Easy's `noHuman` stays 27, and Medium's is 8 (the candidate's re-cut, below). **Hard has no pace matching,** so its computer fights already keep its tapGap of 6. A `noHuman` of 6 would only be read if Hard got pace matching. Nothing changed there.

**What the first build read** (0.25 / 0.5 / 0.8, a grab or a step out; record `docs/director/runs/01367c97/x06-hold-answer/`), which led to this ruling:
- At Medium the charge pad won 35 of 40. At Easy it won 20 of 20, and still 20 of 20 at 0.5.
- At Medium, 0.8 read 6 of 20.
- The reasons:
  - The grabs worked, but a throw (6 plus an opening) gave less than a landed full charge (8 to 10 plus a launch).
  - The 120-tick `noRegrab` after each throw shielded the pad's next hold.
  - The step out can't beat a released charge: it closes 3 body heights, or 6 at full (press-decides.md section 2).
- Where the computer stands when its reaction time is up: in grab reach for 163 of 171 holds.

## The Medium candidate, re-cut: three director checks failed with it

Running every director check for the hold answer showed that **`x06-medium.diff` as first parked (6fe839ae) failed three checks that pass on main 01367c97:** `chase_tap_check`, `floorlift_check` (its fight row) and `match_end_check` (the finisher row). Parity failed too, which is expected: the candidate moves the golden. I had validated the candidate with validate only; this is the gap.

A split run puts all three on `paceMatch`; `perfectVsHeavy` 0.3 alone passes them. **The re-cut (ccea61aa) changes two things:**
- **Medium's `paceMatch.noHuman` goes from 27 to 8,** Medium's own tapGap floor. `noHuman` sets the gap a computer keeps against another computer (`max(drawn gap, noHuman)`). Easy's 27, which I had copied, slowed every computer-against-computer string at Medium. At 8 they keep Medium's pace as shipped (Game Design confirmed).
- **`chase_tap_check`'s off row** ("no slot is sized") now measures with the level's `paceMatch` off. With pace matching on at Medium, a player's press is noted on him (`DirPace`), which sizes his slots.

**Every reading on this page stands.** `noHuman` is read only when the computer's rival is another computer, and the solo pads drive slot 0 as a player.

## The golden

All runs used `sim/core/tools/golden.gd` (record `golden.txt`):
- **All off (`holdAnswer` 0 at every level, `holdBreak` absent):** identical to the re-cut candidate alone, with all 21 sections, 9 of 9 matches and 2 of 2 replays.
- **As parked at the previous chances** (0.5, 0.8, 0.95): all 9 matches, one of the two replays and the planet section move against the candidate alone. The answer fires in computer fights. At today's chances it moves too; the landing window re-records it either way.
- **The re-cut candidate against main's golden:** 8 of 9 matches, both replays and the planet section move (`perfectVsHeavy` 0.3 in computer fights, and the player's pace notes in the replays). The intro sections don't.
- **Not re-run for the repetition cut.** With `holdAnswer` absent the answer returns on its first line and writes nothing, the hold record included. It lands in its own window with a re-record.

## Director checks

**On main 74c03fdb (its sim, data and schemas are 52aa1708's) with the three diffs, at the slip re-cut: 48 of 48 pass**, `hold_answer_check` (21 of 21), `loader_check`, `floorlift_check` and `match_end_check` among them. Parity fails only its golden rows (matches, human-input replays): the expected move, re-recorded in the landing window. Record `director_checks.txt`.

**At the Easy ruling's earlier data (300, the dodge-cancel):** 48 of 48 on 74c03fdb as well.

**On bce578a7, before the follow-up landed:** 42 of 48; the other six failed the same rows on clean main, and the follow-up (`docs/director/pending/gw1b-director-checks/`, landed 74c03fdb) fixed them.

**Earlier cuts:** 45 of 45 at 0.65 / 0.5 / 0.95 on 7b69eafc, and 45 of 45 at Medium 0.8. At Medium 0.8 my sanity read of the charge pad went 0 of 20, and QA's final read gave 1 of 40.

## Apply

On main, in this order (all with `git -c core.autocrlf=false -c core.eol=lf apply`):
1. `x06-medium.diff` (re-cut): two keys on Medium's line, `noHuman` 8, and the `chase_tap_check` off row.
2. `x06-hold-answer.diff`:
   - `sim/director/brawl.gd` and `sim/director/grapple.gd`;
   - `data/director/ai.json` (`holdAnswer` on each level, Medium's by repetition, a `_holdAnswer` note);
   - `data/director/interrupts.json` (`grapple.throw.holdBreak`, the grapple note);
   - the new check and its `.uid`.
3. `x06-hold-answer-schema.diff`: Tools' two schema files, `holdAnswer` (a number or `{windowTicks, byCount}`) in `director-ai.schema.json` and `throw.holdBreak` in `director-interrupts.schema.json`. Without it, validate fails.

With all three on main 74c03fdb: validate 323 files, 0 errors; determinism lint ok. The checks ran on that tree.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `x06-medium.diff` (`data/director/ai.json`, `levels.medium.brawl`: `paceMatch` with `noHuman` 8, `perfectVsHeavy` 0.3; `sim/director/tools/chase_tap_check.gd`). Re-cut from 6fe839ae. | Encounter | ccea61aa4a4ad224712ce88f6f8778e497e1dee9 |
| `x06-hold-answer.diff` (the answer, the hold-break, repetition at Medium, visible holds only, their data and the check; re-cut from 78d52931 for GW1b's main; Easy by repetition from 9a8b3f47; the slip and Easy's 420 window from 6368caa9) | Encounter (Game Design's rulings) | b19a27cf4895f9d4e8a68de46e2bb52a9141ec0e |
| `x06-hold-answer-schema.diff` (`tools/schemas/director-ai.schema.json`: `holdAnswer` and the top-level `holdSlip`; `tools/schemas/director-interrupts.schema.json`) | **Tools** (the EP routes the grant) | 1e83ef347849dc1edc7b7712e0896dbe02b0d17b |

## NEEDS FROM EP

- **Tools:** the grant for `x06-hold-answer-schema.diff`, now with the repetition object in `holdAnswer` and the top-level `holdSlip`.
- **QA:** three cells on main with the three diffs: the Easy charge pad (target 60 to 75%), the Medium charge pad (at most 55%) and the Medium kit.
- **Animation and VFX:** a pose for the computer's slip of a release inside a brawl (the `hold_dodge` cue). Today it shows the dodge state and an afterimage.
- **Game Design, to confirm:** the hold-break throw applies to any catch of a held B, the player's too. R34's third-slip rule is built for the computer's slip of a release only; a player's slips have no slip frames in the sim yet.
- **CI:** add `hold_answer_check` to the director checks.
- **World, for the record:** the first cut's slower computer fight in `floorlift_check` reached a free fighter lifted 85.99 units in one tick (limit 7.5). Main's fight never gets there, but the floor case is real (`recut_split.txt`).
