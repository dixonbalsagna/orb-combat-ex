# Wave 1 combat parks: the stand-in's review

2026-11-28, about 05:15 PST. For the EP. Parks read in full: `docs/director/pending/grab-charge/` (brief 1) and `docs/director/pending/beam-trial/` (brief 2), against the directive, Game Design's `grab-and-charges.md` and `beam-physics.md`, and Orb's words of 2026-11-27 in `docs/ep/vision.md`. **Read, not run:** I ran no Godot. Where a finding is from reading the code only, it says so and names the check row that would settle it.

## Verdict

| Park | Land it (switch off)? | Put it in Orb's build? |
| :--- | :--- | :--- |
| **grab-charge** | **Yes.** I found nothing that risks the golden or determinism | **Not yet:** two readings and one small fix first (G1 to G3 below) |
| **beam-trial** | **No, one fix first** (B1). It's harmless while off, but the fix moves saved state, so it's cheaper before landing than after | **Not yet:** B1, B2, and M1 to M5 |

## Blockers

### B1. The beam trial keeps its state in slots that two other systems already use (beam-trial)
- `DirBeamSpace._b()` is `DirBands._hb() + DirBands.AH_N` (`beam_space.gd`, "three integers after DirBands'"). That is exactly `DirBrawl._rtB()` (`sim/director/brawl.gd:3305`). The slots after DirBands' were free when the spike was written; since then RT's window and the visible-hold record were put there.
- So with the switch on, the trial's three numbers sit on top of:
  - **slot 0:** RT's window for RT + B (`RT_LEFT`);
  - **slots 1 and 2:** the computer's record of the rival's last visible holds (`_hvG` 0 and 1), which grab-charge's "never a grab answering two holds running" also reads.
- **What goes wrong in play, switch on** (read, not run):
  - `DirBeamSpace.tick` zeroes slot 0 on every tick the fighter isn't launched, so RT's window closes one tick after RT is pressed.
  - Every guard press writes a tick number into the hold record, so the computer counts holds that never happened and answers more.
  - A held B writes its start into the slot the trial reads as "a fresh guard press", so a beam can be **deflected by a fighter who never pressed guard**.
  - The shooter's planted time is overwritten when the hold record shifts.
- **Why the checks passed:** with the switch off nothing is written (the golden holds), and `beam_trial_check` never holds B, guards or presses RT.
- **Fix:** base the trial's slots after grab-charge's four (`_hvB() + HV_N + SL_N + GC_N`), and add one check row: with the switch on, a guard press and a launch leave `_rtG` and `_hvG` as they were, and a held B leaves the trial's three as they were.

### B2. Nothing has been run the way Orb will play it (both parks; a blocker for the trial build, not for landing)
- The trial build turns **both** switches on (`trial-switches.json`, 3 rows). Each check forces only its own switch. **No run has both on.**
- **No computer match has been run with the beam switch on at all.** The beam's proof is scripted pairs only. The earlier spike measured three beam checks failing 13 rows with space on (`docs/director/s1-beam-in-space-trial.md`); the README doesn't say whether that still holds.
- **Ask before the build:** 200 computer matches with both on, Easy and Medium, against QA's baseline (d0d08177): errors, matches that never end, match length, and per level the beams fired and how each ended (HIT, PART, DODGE, PASS, MISS, struggle). Plus one row for the pair of rules that meet only here: grab-charge says a full charge always loses to a beam, but a charge in place hit by the space beam "only takes the damage" as I read `inPlaceTick` (it ends on a stun or a lock, and the front's touch gives neither).

## The beam trial: what won't read for Orb

**M1. A beam let go in a brawl passes through the rival and does nothing** (read, not run).
- The beam fires 6 ticks after the release and ends the brawl at that moment (`_spaceFire`). The rival has then been free 0 ticks, `_canAct` needs 18, so the front passes through him ("PASS"), and `b.passed` then switches off the tick-by-tick damage for the rest of that beam, even while he stands in it.
- That's Game Design's S1 ruling 2 doing what it says, but its result at arm's length is the opposite of the directive's first rule ("touch is damage") and of Orb's "make energy beams more reliable". Up close is where a new player fires most.
- **I'd ask Game Design for:** passing through skips only the front's 40% and its hit-stop. From the tick he can act, every tick he is still inside counts. Nobody is hit straight out of a lock, and standing in a beam still costs.
- **Check row:** a stage-2 beam let go in a brawl, the rival standing still.

**M2. Two beams that never touch can start a struggle** (read, not run).
- `_clashCheck` tests that the beams point opposite ways within 15 degrees and that the two fronts have together covered the distance between the hands. It never tests how far apart the two lines are.
- Example: one fighter 700 units above the other, both flick the stick level (more than 15 degrees off, so neither is snapped). The beams pass 700 apart and a struggle starts, each beam stopped at a point in empty air.
- The check's meetings are all aimed at each other with `sectorTo`, so it can't see this.
- **Fix:** also need the lines within the two half-widths of each other where they meet. **Check row:** two level beams at different heights never start one.

**M3. The computer never steps out of a beam.** The spike said so ("it never sidesteps, and its answers are never reached"); this README doesn't. Against the computer, any beam aimed within 15 degrees is a full hit and a launch unless it happens to be moving. Orb will read "is the beam fair to dodge?" only from the receiving side. At least say it on Orb's play page; better, give it a sidestep on the warning at its level's rate, as the two-against-two warning already has (`sim/director/outside.gd:282`).

**M4. Holding wins only 55 in 100 against Easy; 40 are draws.** Orb: "I still don't think i've won any beam struggles". A draw won't feel like the first win. The 40-to-60 band was mine (the directive's), and it was wrong not to count draws. **I'd change the target to: only holding beats Easy at least 70 in 100, with at most 15 draws.** It's data only: put a narrower `drawBand` (try 0.04) in `beamPlays.space.struggle`, which already overrides any key. Encounter flagged the draws; it's Game Design's lever.

**M5. Nothing on screen teaches the new struggle yet.** The hold, the count-in and the drain have cues and no look; the old tug widget and prompt still show, describing the old rule. The README says this plainly. Hold the trial out of Orb's build until at least these are in: the prompt in the new words (hold toward, flick on the pulse), the count-in's on-time or late answer, and a visible drain while inside a beam.

**Smaller:**
- **`beam_warn` is reused with a different payload.** The HUD's reader (`ui/core/ui_event_hub.gd:957`) expects the shooter in `text` and left or right in `source`; the trial sends a tick count and "space". It will show a warning on both edges, which is useful, but tell UI, or send what the reader expects.
- **Twelve new beam fields decide damage and aren't hashed** (`touched`, `dealt`, `whole`, `passed` and the rest). Fine for a trial, since health and positions are hashed and nothing restores a beam mid-flight today. They join `hash.gd`'s BEAM list before the trial is adopted.
- **The 60% is given as about 55 separate small hurts,** each with its own damage event and its own wound-region pick (`sim/core/damage.gd:21-34`). Have the batch in B2 read wounds per beam on against off, and have Audio and VFX look and listen once with the switch on.
- **Guarding at the front's touch sets the beam's whole to the guarded amount** for the rest of that beam, even if the guard is dropped. Small.

## Grab and charges

It matches Game Design's page rule for rule, and the departures from the directive (clinch 45, grab-proof in place of the counter-hit) are ruled with reasons I agree with. Its four new state slots sit after the slips, which nothing else uses (`brawl.gd:3339`), and are written only with the switch on.

**G1. "Does the full charge land?" isn't measured** (before Orb's build).
- Orb: "had a hard time trying to slam the opponent". Under the switch, the computer **gives ground** on 30 in 100 of its answers that aren't a grab. The leash rule (C2) isn't built and waits on a timing table that isn't in this proof. The check counts what the computer answered, never whether the charge then hit.
- **Ask:** on Easy and Medium, switch on, 100 on-time full charges from arm's length and 100 from 8 bh: how many land, by the computer's answer. Then Game Design's timing table (their section 5), and QA's charge-only pad, which their page says is read "before the clip goes to Orb".

**G2. An early release from range pays for a charge and lands a plain heavy** (small fix).
- In `inPlaceTick` the charge's price is taken at tick 32. Let go between 32 and 43 and it lunges as a tapped heavy (the README says R5 for B isn't "as the stage it reached" yet). The player pays and gets nothing for it.
- **Fix:** land it at its stage, or take the price only when the charge is used.

**G3. A tapped B from range gets slower, and Orb will feel it** (ruled; a watch item for the clip).
- With R7 and the slower lunge together, B tapped at 8 to 12 bh lands about 48 to 56 ticks after the press (crouch 10, travel 10 to 18, then the 28-tick wind-up at arm's length), against about 32 today. Orb's approved feel is that each press is a blow.
- Game Design chose this on purpose and names the cost. Put a tapped B from range in the clip beside the held one, and keep `heavyWindOnArrival` as the named lever if Orb says it feels late.

**Smaller:**
- The README's "not built" list leaves out C2 (the leash); only the data note says it.
- I read the computer as never charging in place (its B is held only inside a brawl). Worth one line on Orb's play page, so the new move isn't expected back.

## Order I'd take
1. Land grab-charge, off.
2. Encounter: B1, M2 and G2 (all small), and the three check rows.
3. Game Design: M1 and M4.
4. The B2 batch and G1's rows, both switches on.
5. UI's three pieces (M5), then the trial build and Orb's clips.
