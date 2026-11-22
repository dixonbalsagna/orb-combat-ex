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
- **The chances move:** `holdAnswer` Easy 0.5 to 0.65, Medium 0.8 to 0.5; Hard stays 0.95. That's this re-cut's only data change.

**The human bands: not met, waiting for Orb's play.** These are QA's final read at the previous chances (Easy 0.5, Medium 0.8, Hard 0.95; `docs/qa/readings/x06-final-read.md`, 40 matches a cell, main b04de5d5 with the three diffs):

| Pad | Easy | Medium | Hard |
| :--- | ---: | ---: | ---: |
| Whole kit (band: Easy 60 to 80, Medium 35 to 55, Hard 10 to 30) | 32 of 40 (80.0%) | 5 of 40 (12.5%) | 0 of 40 |
| Strike only | 18 of 40 (45.0%) | 0 of 40 | 0 of 40 |
| X masher | 16 of 40 (40.0%) | 6 of 40 (15.0%) | 0 of 40 |
| Beams only | 21 of 40 (52.5%) | 0 of 40 | 0 of 40 |
| B charge only (ceiling: Easy 80, Medium 55) | 38 of 40 (95.0%) | 1 of 40 (2.5%) | 0 of 40 |

QA reads Easy and Medium again at the new chances against the scripted exit.

## The hold answer (Game Design's combined ruling, 2026-11-21; chances re-cut 2026-11-22)

The worth-cut record showed that all 1,256 full charges reached their release. The computer never interrupted or evaded during a 44-tick hold. Game Design's ruling (`docs/design/gauntlet-plan.md`) is that **the computer answers a visible hold during the hold.** It never relies on the perfect block alone, never guards and never steps out.

**What `x06-hold-answer.diff` builds** (`DirBrawl._aiVsHold` and `_aiHoldDodge`, called from the brawl's `aiInput`):
1. **The trigger is a visible hold:** the rival holds B on a fist's heavy, winding or charging. There's one draw a hold, keyed by the hold's start tick, at the level's new `brawl.holdAnswer`: **Easy 0.65, Medium 0.5, Hard 0.95** (Game Design's section 10; it was 0.5, 0.8, 0.95). It acts only once its reaction time (`reactTicks`, 14) has passed since the press.
2. **Drawn, in a light's reach (the catch's own), it grabs.** It presses A as soon as its line is free. The catch's tell beats the armour, and its landing stops the wind-up; the clinch starts one ahead.
3. **The grab is a hold-break** (`interrupts.json` `grapple.throw.holdBreak`, `DirGrapple`). Its clinch's throw is worth `worthMul` 1.5 times a throw (6 to 9), with its usual opening, and `noRegrab` doesn't start. This applies only when the catch stopped a held B; any other throw is unchanged. The mark lives on the caught fighter's `noRegrab` slot as -1, which never refuses a catch, so no new state slot is needed.
4. **Drawn, out of reach,** it closes in on its stick (the brawl's giving-ground step, straight at him) when that brings it into reach before the charge's first flash (`heavy.charge.fromTicks`, 32, from the press). Then it grabs.
5. **Otherwise it dodges, timed to the release.** That covers being too far to close in time, or no catch to be had (a lockout, or the grapple off). The dodge costs the dodge-cancel's price (`dodgeCancel`: 15 ki and its cooldown). The released blow meets nothing (the miss cue says `dodged`), he is open for its 20-tick `recoverWhiff`, and the existing open-rival rule punishes him.
6. **No new state.** It never guards or gives ground against a hold it answers. With the chances at 0 and `holdBreak` absent, the golden is identical (below).

**My implementation choice, for Game Design and Animation:** a real dodge in a brawl (the dodge-cancel) ends the brawl and clears his line, which leaves nothing to punish. So this dodge is a new one inside the brawl. It costs the dodge-cancel's price, and the brawl goes on. It shows only an afterimage and a `hold_dodge` cue (text `release`, target the charger). **Animation and VFX have no pose for it yet.**

**The check:** `sim/director/tools/hold_answer_check.gd`, **13 of 13** (about 2 minutes). A player holds B at the computer, at Medium:

| Row | Result |
| :--- | :--- |
| Drawn, in reach: it grabs after its reaction time, never sooner | ok (+14 against 14) |
| ... the clinch starts one ahead and the charge never lands | ok |
| The hold-break's throw is worth 1.5 times the throw: the same staging with `holdBreak` absent | ok (72.5 against 48.4 damage) |
| ... and leaves no `noRegrab` (without the rule, 120 ticks) | ok |
| Drawn, 1.2 bh out: it closes in and grabs before the first flash | ok (closes from +14, grabs at +28; the flash at +32) |
| Drawn, 2.3 bh out (too far to close in time): no close-in, no grab; it dodges the release at 15 ki | ok (the dodge on the release tick, +50) |
| ... the charge meets nothing and the computer punishes him while he is open | ok (the miss cue says `dodged`) |
| Drawn, no catch to be had (a lockout): the same dodge, miss and punish | ok |
| In every drawn hold it never guards and never gives ground | ok |
| One draw a hold, keyed by its start: each level's share of 2,000 holds within 3 points | ok (0.642, 0.496, 0.948) |
| **The exploit is closed:** a charge-only pad doesn't win every Medium match. It's QA's charge pad played by the check, on QA's planet settings, seeds 1 to 6. | ok (the pad 1, the computer 5) |
| Negative control: `holdAnswer` 0 and the old answers at 0; nothing answers, and the charge reaches its release at full | ok |

**The exploit row can fail.** With Medium's `holdAnswer` at 0 (the exploit open), the same six matches go 6 of 6 to the pad, and the row fails (record `hold_answer_check.txt`).

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
- It all lands in its own window after GW1b, with a re-record.

## Director checks

**45 of 45 on main with the three diffs at today's chances** (2026-11-22): every `sim/director/tools/*_check.gd`, including `hold_answer_check` with its exploit row. Parity fails only its three golden rows (matches, human-input replays, planet worlds): the expected move, re-recorded in the landing window. Main's sim, data, schemas and `qa/godot` are unchanged from 01367c97 to 7b69eafc, and the parked diffs are byte for byte the tree the checks ran on (record `director_checks.txt`).

**Earlier, at the previous chances** (Medium 0.8): 45 of 45, and my sanity read of the charge pad at Medium went 0 of 20 (under the 20% floor). QA's final read confirmed it with 1 of 40, and the chances moved.

## Apply

On main, in this order (all with `git -c core.autocrlf=false -c core.eol=lf apply`):
1. `x06-medium.diff` (re-cut): two keys on Medium's line, `noHuman` 8, and the `chase_tap_check` off row.
2. `x06-hold-answer.diff`:
   - `sim/director/brawl.gd` and `sim/director/grapple.gd`;
   - `data/director/ai.json` (`holdAnswer` on each level, a `_holdAnswer` note);
   - `data/director/interrupts.json` (`grapple.throw.holdBreak`, the grapple note);
   - the new check.
3. `x06-hold-answer-schema.diff`: Tools' two schema files, `holdAnswer` in `director-ai.schema.json` and `throw.holdBreak` in `director-interrupts.schema.json`. Without it, validate fails.

With all three on main 01367c97 (its sim, data and schemas are 7b69eafc's): validate 322 files, 0 errors; determinism lint ok. The tree is byte for byte the one the checks ran on.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `x06-medium.diff` (`data/director/ai.json`, `levels.medium.brawl`: `paceMatch` with `noHuman` 8, `perfectVsHeavy` 0.3; `sim/director/tools/chase_tap_check.gd`). Re-cut from 6fe839ae. | Encounter | ccea61aa4a4ad224712ce88f6f8778e497e1dee9 |
| `x06-hold-answer.diff` (the answer, the hold-break, their data and the check; chances re-cut from 187686f1) | Encounter (Game Design's rulings) | 78d529310b111dc6283ea1287bd6e8d84244853f |
| `x06-hold-answer-schema.diff` (`tools/schemas/director-ai.schema.json`, `tools/schemas/director-interrupts.schema.json`) | **Tools** (the EP routes the grant) | 16d8e330d9979e077f1099ac6523eaf63eba839a |

## NEEDS FROM EP

- **Tools:** the grant for `x06-hold-answer-schema.diff`.
- **QA:** Easy and Medium, five pads each, on main with the three diffs, read against the scripted exit above. Hard is reported only.
- **Animation and VFX:** a pose for the computer's dodge of a release (the `hold_dodge` cue). Today it shows only an afterimage.
- **Game Design, to confirm:** the dodge stays inside the brawl, at the dodge-cancel's price (my choice, above). The hold-break throw applies to any catch of a held B, the player's too.
- **CI:** add `hold_answer_check` to the director checks.
- **World, for the record:** the first cut's slower computer fight in `floorlift_check` reached a free fighter lifted 85.99 units in one tick (limit 7.5). Main's fight never gets there, but the floor case is real (`recut_split.txt`).
