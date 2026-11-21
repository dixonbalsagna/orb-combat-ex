# The Horde trial: steps T1 to T6 (S3)

Encounter, 2026-11-14, sprint A1. The design is `docs/ep/proposals/horde-trial-design.md`, with Game Design's rulings in `docs/design/horde-trial.md`.
- **Scratch only; nothing lands.** The tree was a clean export of 5263c1a6, with the trial's build and the 87 ON rows of Orb's build's switch list (`docs/tools/runs/6a30b4c9/switch-list.txt`; 81 flip in data, 6 are page words).
- Every match set the energy model, the dash, the slip and the kick on by setup, with flat-out flight at 3,500.
- The data is Game Design's arm G: the lane gap 113 at medium (easy 170, hard 68), pack blows of 2, 4 and 2, and `bodyShare` 1.0. The body is the old hp until A3.

The sources are kept as reference for A4 in `horde-trial/src/` (not a park; nothing there applies to main). Records are in `runs/5263c1a6/horde-t3/` and `runs/5263c1a6/horde-t6/`.

## What was built

| Step | What | Done when | Result |
| ---: | :--- | :--- | :--- |
| T1 | The state, `horde.json` and `SimHorde`, the five slots, `ended`, the hash and replay lines; an away body not stepped, given no input and taking no hit | The golden byte-identical with the switch off; on, two runs one hash | **Golden passed** (and again after T3); one hash |
| T2 | Falls, refills, `fresh` and its one-body set-ups, the wave table, the run's end, the 12:00 backstop | Readings 3, 4, 20 | **Pass:** 621 refills match a new match's body; never more than 3 places in; nothing lands on an away body. Eight waves are 621 bodies, 934 with two seats |
| T3 | The mark (`SimRoster.opp` returns it), the player's pack blow (X, Y, B with their own wind-ups, the lunge, the kept press), the side rule for shots and mines, and every guard: the exchange's three sites, the hold's edge, the stick's beam (`horde_sig`), the grab (`horde_grab`), the ending and the time cap, the bands, the knock-out, the hold | A scripted pad clears wave 1; readings 14, 19 | **Pass:** 0 exchanges, 0 locked ticks and 0 late refusals with every button and two pads; 0 hits on one's own side |
| T4 | The pack's play: the entrance at 3.2× flat-out, the crowd, lanes and gap, the wind-up and its step in, the strike, the spacing, the strong block, the clean dodge | Readings 5, 6, 7, 21, 22 | **Pass** (below) |
| T5 | Going down and getting up (400 back at the wave's end); the second seat joining, leaving and coming back | Reading 15 | **Pass:** in the list and reading its pad the tick after the join; a leave keeps the body; coming back never raises it or lifts a downed seat; a replay with three toggles reproduces |
| T6 | The probe: medium ×10 alone and ×10 with two; 3-a-second, mash, slow, idle, guard-tapper and dodge-tapper ×3; the medium pad on the page's 240 arm and on row D, ×5 each | Readings 8 to 11 | Below |
| T7 | Frame cost at two and five bodies | | **Waits for the EP's quiet window** |
| T8 | The clip | Match files that replay exactly | **Match files done** (`horde-trial/clips/`); Tools cuts them. Not in the clip: B through a building (below) and the design's beat 5 (the recorder's own fault, see "One player left up") |

`horde_check` passes 44 of 44. With the switch off: load split passes, and the two-fighter count is 365 of 365.

## The readings (arm G unless named)

| # | Line | Reading | Verdict |
| ---: | :--- | :--- | :--- |
| 5 | 0 pairs within 8 ticks; wind-ups ≤ lanes (hard) | 0 and 0 in every run | Pass |
| 6 | ≥ 30 wind-ups a minute, ≥ 2 while one is in flight, all three only circling ≤ 60% | 70 a minute, 5 to 7 while one is in flight, all three only circling about 25% (model: 43, 3, 45%) | Pass |
| 7 | No push against a held stick; lunges ≤ 30 ticks; every press after a landed blow answered (hard) | 0 in every run, after a fix (see the findings) | Pass |
| 8 | Medium alone 7:00 to 9:00; two 6:00 to 8:00 | 7:29 to 7:43 (model 7:52); two 6:17 to 6:31 (model 6:43) | Pass |
| 9 | Medium loses 20 to 45% and never goes down; 3-a-second 30 to 60%; mash finishes; slow reaches wave 6 | 29 to 35%, 0 downs; 42 to 45%; mash clears in 4:38 having lost 10%; slow reaches wave 8 but meets the 12:00 cap with 72% lost. The idle pad lasts 8:59 (model 8:25) | Pass |
| 10 | Two medium pads each lose 10 to 35%; no body in reach ≤ 35% of a wave | **Each loses 8 to 14%** (model 20%); no body in reach up to **38%** of a wave, worst in wave 1 | **Fail** |
| 11 | Twelve fodder in 10 to 20 s | 3.8 to 5.6 s alone, about 3 s with two (model 5.4) | Fail, fast, as the model said |
| 21 | One pad: two in the fight ≥ 60% of each wave, none ≤ 10% | 91 to 98%, none at most 1% (model 95%, 1%). Two pads, for information: 57 to 64% in wave 1 rising to 85 to 88% (model 68 to 88%) | Pass |
| 22 | Tappers fell 0 in wave 1, last ≤ a third longer than idle | 0 fallen; 9:38 and 10:03 against 8:59 | Pass |

**The arms (medium pad, 5 seeds):**
- The page's 240 arm (blows 4/8/4): 7:13 to 7:29, 29 to 34% lost, **36 wind-ups a minute against G's 70**. GD's rule is that the busier arm wins when they feel alike; on these numbers they are alike and G is twice as busy.
- Row D (blows 24/48/24, the whole body back in each breather): 7:17 to 7:29, 29 to 49% lost. One seed is past 45%.

## After Game Design's rulings (2026-11-15, `docs/design/horde-trial.md` section 4)

- **Arm G** is ruled.
- **Reading 11's band is now 4 to 8 s for twelve alone.** The 10 seeds above read 3.8 to 5.6 s, so nine pass and seed 3 is 0.2 s fast. The data is unchanged, so this was re-read, not re-run.
- **Two players:** `pack.twoPlayers.toughMul` 1.5 (each body's toughness at its refill) and `gapMul` 0.8 (the lane gap 113 becomes 90 at medium), both only with two pads. Two medium pads were re-probed over 10 seeds; records are in `runs/1c19d81d/horde-two/`, and `horde_check` is 44 of 44.

| Reading | Line | Before | With the keys |
| :--- | :--- | :--- | :--- |
| 10 | Each loses 10 to 35% | 8 to 14% | **21 to 25%** |
| 10 | Nobody in reach at most 35% of a wave | up to 38% | **up to 26%** |
| 11 (two) | Twelve fodder in 3 to 6 s between two | about 3 s | **4.3 to 5.5 s** |
| 21 (two, information) | | 57 to 64% in wave 1, rising to 85 to 88% | **74 to 82% in wave 1, rising to 91 to 95%** |
| 8 (two) | Each run 6:00 to 8:00 | 6:17 to 6:31 | **9:04 to 9:13: fails** |
| 5, 6, 7 | | pass | pass |

- **The new trade-off is run length.** A tougher pack with ×1.5 bodies makes the two-player run about 1:30 longer than playing alone (7:37), and outside reading 8's band.
- If Game Design wants the band kept, the count multiplier is the lever: by proportion, ×1.2 instead of ×1.5 gives a run of about 7:40. That's an estimate, not a run.

**Game Design's second ruling (2026-11-15):**
- The two-player count is **×1.2** (toughMul and gapMul stay).
- Reading 11 reads on the median, with at least 9 seeds in 10 inside the band. Seed 3 alone then passes.

**At 1.2, with a fix the run found, every reading passes** (10 seeds, records in `runs/1c19d81d/horde-two/`; `horde_check` is 44 of 44):

| Reading (two medium pads) | Line | ×1.2 |
| :--- | :--- | :--- |
| 8 | Each run 6:00 to 8:00 | 7:25 to 7:35 (mean 7:31) |
| 10 | Each loses 10 to 35% | 15 to 21% |
| 10 | Nobody in reach at most 35% of a wave | worst wave 28% |
| 11 | Twelve fodder in 3 to 6 s between two | median 5.2 s (4.3 to 5.9) |
| 5, 6, 7 | | pass |

8. **The fix: the leash's re-mark.** At 1.2 before the fix, seed 1's wave 3 reached 46% with nobody in reach.
   - The traced run showed one seat's pad up near 22,000 units and the other near 4,000. One body hung between them for the whole wave.
   - Past the 30 bh leash it re-marked by "fewer bodies", which could pick the farther seat. It re-checked every tick, flipping between the two.
   - Past the leash a place now re-marks to the nearest seat that is up. Alone nothing changes: there is one seat.

The scripted pads chase the nearest body in height too, so one can climb toward the 24,000 ceiling; a person may not. This bug lives in the pack, not the pads.

## Findings

1. **The dash's arrival ease held the pack outside its own reach.** `bands.arrive`, which is on in Orb's build, eases any dashing body to `engageBh` (2.5 bh) from its rival and never closer. The pack dashes, and its reach is 1.5 bh, so every pack blow missed. In the trial a pack body is exempt; seats keep the ease toward their mark. The A4 build needs this line.
2. **Seats are stepped before the pack.** A player's blow, timed to its weight's tick, landed where the body was a tick ago, and 36% of blows whiffed. In the trial a blow steps in at once and follows its body, and the landing allows one tick of the body's own motion. That brought whiffs to 16% for a pad that presses at whoever is nearest.
3. **The mark's tie-break.** Three places over two seats always leave one seat with two. A tie going to the lower slot kept the pack 2 to 1 on seat 0 for the whole run (4 to 6% lost against 13 to 17%). Ties now go to the seat whose latest pack blow is oldest.
4. **The flinch dropped a kept press without a word,** against "their next press untouched". It now throws it.
5. **The side rule needed more than shots in flight.** A partner's mine blast, and a deflected (wild) shot owned by the partner, both hit the other seat. A shot now passes its owner's side wild or not, and a mine's blast passes its layer's partner. A fighter's own blast still hits itself, as in one-on-one.
6. **Two players have thin fights** (question 4, reading 10). Three places shared by two players, ×1.5 bodies, give each player about half the pressure of playing alone. This is for Game Design. The levers are the places for two (the five-body limit, section 3.12), the count multiplier, or `perPlayer`.
7. **Twelve fodder in 4 s, not 10 to 20.** The model said so too. This is Game Design's call: the band, or the fodder.

## The two-body rule's walk, sized at T3

- **The sim has 35 shipped slot-number sites** (director 22, core 13; input's 65 are all in tests) and 98 opponent-rule callers.
- With the exchange guarded off, most are dead in a Horde match.
- **The live ones** are: the location stats (the pair's midpoint); core swing `_pair` (the ring's pivot); arc.gd and visit.gd keeping match memory on slot 0 (safe, since seat 0 is never made fresh); forms.gd:407; and the intro.
- About 0.3M tokens for Encounter and Simulation.
- The render side (Camera 37, audio 18, host and HUD 13, VFX 12, animation 6, net 3) is as the design says, and not walked.

## One player left up (built 2026-11-20, Game Design's ruling of 2026-11-15)

Built in the trial tree (scratch commit `751eb0a` on `1aadbbd`). The step is `src/lone_build.py`, after `t4_build.py`; the check is `src/horde_lone_check.gd`.
- **The rule:** while only one played seat is up (in the run, not away, not down), in a wave sized for two or with two played, the pack plays one-player values at once and until the next wave:
  - the lane gap goes back to the one-player value, and a lane waiting out the two-player gap waits the difference;
  - new spawns come at one-player toughness;
  - the wave's remaining count × 1/`countMul`, taken from the bodies still to send, the largest kind first;
  - the live bodies keep their toughness.
- **The state:** two new hashed fields on the run, `size2` and `lone`. The data switch is `two.lone` (`true`); the check turns it off for its negative control.

**`horde_lone_check`:** two medium pads play to the middle of wave 3, and seat 0 goes down there.

| | Seat 1 clears the wave | Time to clear |
| :--- | ---: | :--- |
| **The rule on** (QA's row: at least 8 of 10) | **10 of 10** | 19.5 to 25.8 s |
| The rule off (negative control) | 10 of 10 | 36.0 to 44.6 s |
| Seat 0 stops playing but stays up (the rule can't trigger) | 10 of 10 | 70.7 to 88.0 s |

- At the down: the gap goes from 90 to 113, the wave's remaining count from 40 to 33, the live bodies keep their toughness, and a new spawn comes at one-player toughness. At the next wave, two-player values are back and seat 0 is up.
- Two runs give one hash. `horde_check` passes 44 of 44. With the switch off, the golden is byte-identical to the tree before the change.
- Records are in `runs/5263c1a6/horde-lone/`.

**The finding behind the ruling was my clip script's, not the game's.** In the T8 recordings the remaining pad never cleared the wave because of the script:
- After its scripted blast (RB + X), the script's pad sent the "auto" family (-1), which keeps the last family. So every later X was an energy shot.
- A shot lowers a weak fighter's hit points but doesn't spend its toughness (the shot as a pack blow is left out, below). Bodies at 0 hit points fought on, and the wave never fell (`stall-trace.txt`).
- A real pad sends the physical family once RB is released (`layout.gd`), so a player doesn't meet this.
- With the script's fault out of the way, the remaining pad clears the wave even without the rule, as the table shows. The rule still halves the time.

## Not done

- T7 (the EP's quiet window). T8's capture is Tools' (the film variant of the capture hook, and Camera's many-body frame).
- **A Horde B never strikes a building.** It launches the body by the knock-out fallback's plain launch (`DirHorde._fell`), with no aimed building, and a building is struck only by an aimed flight (`WorldBrunt.checkHit` reads `f.aimB`). Routing the Horde's B through the launch planner is A4 work, after the launch-cone rider lands, so it honours the cone.
- `net/desync.gd`'s horde lines (the design's 6.1) are not written. The trial's hash lines are in `hash.gd` only.
- The A3 body share, the beam in space, the shot as a pack blow (`blow.shot`), energy for a fall, and the result screen are left out, as the design leaves them for later or for other owners.
  - **What leaving out the shot means in play:** a player's energy shot lowers a weak fighter's hit points but never spends its toughness, so it never fells one, and a body at 0 hit points fights on. A player who only blasts can't clear a wave.
