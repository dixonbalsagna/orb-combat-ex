# Beam physics: options for Orb

Owner: Game Design. 2026-11-08, started on Orb's Sunday play (`docs/ep/vision.md`):
- "opponent fired a beam at me, I didn't even see it on my screen, seemed like it was way under me and it still counted and hurt me"
- "another beam way under me that sent me flying. lets get a big overhaul to the beam physics"

**The EP's reading, which these options build on:** a beam that is **seen, aimed and escapable** in space, rather than one that lands from anywhere. **Paper only. Orb picks.**

## What a beam is today, and why it felt arbitrary

- **A beam is an exchange, not a thing in space.** Once it leaves, it "reaches the defender `travelTicks` later, at any distance" (`beamplay.gd`, 20 ticks). What decides the outcome is what he pressed (a late answer, a perfect block, a timed dodge, a guard), read on the tick it reaches him.
- **Aim only matters past the assist.** Within `assistDeg` of the line to him it's a shot at him and it reaches him. Wider than that it misses and carves (`beam_aim.gd`).
- **So in Orb's match** the rival's beams hit from 2,400 to 6,600 units away. Moving didn't help, the drawn beam could pass under Orb and still count, and only a timed dodge got out (QA, `docs/qa/runs/1931a0f8/`).

## The three questions every option answers

| | The question |
| :--- | :--- |
| **Seen** | Can you see it coming, from its source, on your own screen? |
| **Aimed** | Does it go where the shooter pointed it, and hit only what's on that line? |
| **Escapable** | Can you get out of it by moving, not only by a timed press? |

## The options

### A. A beam in space, aimed with the stick (recommended)

The beam is a **column with a front that travels** along a fixed line from the shooter's hand. **It hits what it touches:** a fighter, a building, the ground, another beam.

- **Aimed:** the line is the right stick's direction at the release, as the beam controls already read it. **A small assist snaps the line onto him if it's within 15° of the stick,** for the shooter and the computer alike (pads are imprecise). Past 15° it goes where you pointed. **No sweeping after it's fired** (Orb marked "the hose" doubtful).
- **Seen:** the charge shows (the hand's glow and the stage pulses), the release flashes, and the front visibly travels.
  - **On your screen:** a beam fired at you shows UI's steady edge cue (`docs/ui/beam-answer-alert.md`; RL-227). Camera doesn't frame a shooter today. Bringing the source into your frame is a later Camera piece, not the baseline (corrected 2026-11-14). It's never a marker over a fighter (ADR 0010).
- **Escapable:** get off the line before the front arrives. The timed dodge (through the front), the perfect block's deflect, the guard (chip) and an answer of your own all stay.
  - **Two fronts that meet in space start a struggle at the point where they met,** so the struggle comes from the geometry, not from a late-press window.
- **A miss still wrecks:** the column carves along its real line (`power-scale.md`'s groove). A beam that passes under you digs the ground under you, not you, which turns Orb's "way under me" into scenery, and feeds the villain's destruction (`bystanders.md`).

| First values (as data) | Stage 1 | Stage 6 | Rule |
| :--- | ---: | ---: | :--- |
| **Front speed** | 6,000 a second | 18,000 | +2,400 a stage (re-ruled 2026-11-14, spike S1; was 8,000 + 2,000) |
| **Time to cross 3,000 units** | 0.5 s | 0.17 s | |
| **Time to cross 6,000 units** | out of reach (4,200) | 0.33 s | |
| **Width that hits a fighter** (half) | 45 units (0.6 bh) | 170 (2.3 bh) | +25 a stage. A bigger beam is harder to get out of |
| **Length** | 4,200 | 10,200 | 3,000 + 1,200 a stage. Past it, the beam spends itself into the sky or the ground |

- **How it plays:**
  - **At long range,** a moving fighter can usually get out of a small beam, so beams there are for making someone move, or for catching someone who's committed (charging, recovering, brawling with a partner).
  - **Up close** the front arrives too soon to leave the line: the answers decide it, and the point-blank throw-back stands.
  - **A full stage-6 beam** is wide and fast enough to catch most people who don't answer it.
  - That's the gravity well's split (Orb, 21:52): long range outside the well, the snap inside it.

### B. A beam in space, aimed for you

The same column and front, with the same widths, speeds and answers as A. But **the line points at where he is on the tick you fire,** whatever the stick says.
- **Easier to fire:** you only choose when.
- **Escapable the same way:** move after the release. A fighter standing still gets hit, and a moving one usually doesn't at range.
- **What you lose:** aiming as a skill, and shots placed on purpose (at the building he's standing on, or ahead of a fighter on the move).

### C. Today's beam, made honest

It's still an exchange that reaches him, with three gates added:
- he must be in front of the shooter and within its length;
- the beam is drawn to where he actually is, never under him;
- moving 2 bh or more off the line in the 20 ticks of travel counts as an escape.

It's the smallest change and keeps today's answers exactly. **But it's still a beam that finds you rather than one that flies.** It fixes "it counted though it was under me", not the feeling that it's arbitrary.

## My recommendation

**A.** It's the only one that's physical in the way Orb asked for launches to be: it goes where it's aimed, it's seen, you can fly out of it, and two of them meeting is a struggle you can see. B is a fallback if stick aiming proves too hard on a pad. C is a patch, not the overhaul Orb asked for.

## What QA measures first (today's beams, as the baseline)

On Orb's two Sunday files and the scripted arms, for each beam fired:
- the distance at the fire;
- whether he was in the drawn beam's path at the reach tick;
- hit, dodge, block, guard or struggle;
- whether the shooter was on the target's screen at the fire;
- what he pressed.

Then the same rows with A behind its switch.

**Bands to read A against:**
- beams that hit someone they didn't visibly touch: **0**;
- hit rate on a moving target farther than 3,000 units: **10 to 30%**;
- hit rate inside 1,500 units: **40 to 70%**;
- beams whose source wasn't on the target's own screen and gave no edge cue: **0**;
- struggles from fronts meeting: a share of all beams, read without a band at first.

## Who would build A

- **Encounter:** the beam as a column instead of an exchange; the answers on contact; the struggle where fronts meet; the assist.
- **Simulation:** the front, the widths and the geometry, deterministic.
- **World:** carving along the real line, which is mostly built.
- **Camera:** the source in frame, or the edge cue.
- **Controls:** the stick's line at the release.
- **VFX:** a front you can see travel.
- **QA:** the baseline and the bands.
- **Legal:** RL-227's limits for the edge cue and the beam's own light.

**Data:** `data/fight/power.json` `beam`, with `frontSpeed`, `hitHalfWidth`, `length`, `assistDeg` 15 and `struggleOnMeet`, behind `beamPhysics.enabled`, off.

## Spike S1's rulings (2026-11-14, on the stand-in's `docs/ep/proposals/beam-in-space-trial-design.html`)

Orb picked A on 9 November ("A sounds good"). These settle the trial's five departures before Encounter builds it.

| # | The trial asks | Ruling | Reason |
| ---: | :--- | :--- | :--- |
| 1 | **The point-blank shove** (inside 9 bh, the target thrown back to 9 with no damage). Off, on, or a longer tell up close | **Off in the beam in space.** It stays only as the trial's filmed comparison. **No longer tell up close** | The shove moves a body that nothing touched: that's the agency rule, and the solid bodies of S2. Its old reason was reaction time, back when a beam took at least 0.6 s to arrive. With a beam in space **the warning is the charge:** the hand's glow and the stage pulses, at least 12 ticks plus the 6-tick fire. **Up close you answer on the charge,** by snapping in (a medium stops a charge in its first 28 ticks), slipping or blocking. A longer tell would put a wait before the fire, which Orb disliked on 11-01 ("slowly drifts ... then fires"). This replaces `playable-build.md` §2's throw-back for the beam in space. **VFX's stage pulses become required** for the trial's clip |
| 2 | **"A beam never comes at a target who can't act"** (amended 2026-11-28, see "S1 ruling 2 amended" below), kept with no wait: the beam passes through a body that can't act | **Yes, it passes through,** never a refused fire (a refused press breaks "each press is a blow"), **with one exception: a launched body takes one beam touch per launch** | Down, stunned, or free less than 18 ticks: it passes through, so nobody is fired on straight out of a lock (the 11-06 ruling's purpose). **A launched body is a juggle the shooter earned.** One beam as the in-air chain's finish is the rule of cool Orb asked about on 10-06 ("do energy attacks look cool as part of close-range combos?"), and it belongs to the in-air chain Orb wants explored. Never twice in one launch |
| 3 | **The reach:** a base beam ends at 72 bh and a full one at 136, where today a hit lands at any distance | **Confirmed.** A beam spends itself past its reach, visibly, carving to its end | **Pillar 3 is about attacks that close the gap, and those all still do:** the snap, the long strike, LT flat out (6,000 units in 1.9 s at 3,500). A beam is the one attack that doesn't close the gap, so it has a reach, and the reach grows with its stages (power has weight). "Lands from anywhere" is exactly what Orb complained about ("way under me and it still counted"). **The computer doesn't fire past its own reach** |
| 4 | **First speeds** (40 bh in 0.17 to 0.38 s): X-16's "near range" passes only for a defender already moving | **Both: slow the bottom of the curve, and agree X-16's wording.** Front speed **6,000 + 2,400 a stage** (stage 1 6,000, stage 2 8,400, stage 3 10,800, stage 6 18,000, unchanged at the top) | The bottom two stages are what a base fighter fires. They should be escapable on reaction from middle range, or option A's "escapable" doesn't hold at base. The top stays fast, so a full beam catches a late reactor: power has weight. **X-16's dodge by moving, in the trial's model:** near (20 to 40 bh), a stage-1 beam, by a defender reacting to the release; middle (40 to 60), a base fighter's full beam (stage 2), reacting; far (60 and out), a stage-3 beam, reacting; any beam, by a defender already moving. **Inside 20 bh, the answers and the charge decide,** as this page has said from the start ("up close the answers decide it"). QA reads each row on the escape probe |
| 5 | **The assist angle:** 15° on this page, 35° in data | **15° for the beam in space,** for the player and the computer alike. 35 stays for the old path | With 32 stick directions (11.25° apart), 15 already forgives the neighbouring direction, so pointing at him finds him. 35 forgives three directions off, which is option B (aimed for you) by the back door. Orb picked aimed. **Controls reads** Orb's next file for releases that land two directions off. If they're common, 20 before anything wider |

**Also, from the trial's risks:**
- **The ground stops a beam.** A beam aimed into the ground spends itself where it enters, carving a groove and crater there. It doesn't run on underground, so nobody is hit through a hill or mountain: "it hits only what it touches". Towers it goes through, as Orb agreed on 11-01, because a building is a thing it breaks.
- **The signature** joins the beam in space at its top stage, with the inputs Orb named (RT + RB + a flick for the energy signature). It goes in A-COMBAT-02 (GW2), so it isn't the one beam that still finds you.

## The trial's struggle: a band that settles (2026-11-28, Encounter's beam trial)

**Encounter's finding:** with the trial's numbers, 40 of 100 held struggles against Easy end in a draw (the beams detonate), by today's `drawBand` 0.1. That band is too wide for the trial's steps. A held pulse moves the point 0.03 and a surge 0.10, so a fighter a whole surge ahead (0.6) still ends inside 0.1 of the middle, and that counts as a draw.

**Ruling: under the trial, `drawBand` 0.015, half a held pulse.**
- **The beams detonate only when the struggle is truly even:** both holding at equal power, or every surge traded.
- **Otherwise the side the point is on when the pulses run out loses:** half the other beam, no launch (today's "time" ending). The point reaching him is the overwhelm, as today.
- **Data:** `interrupts.json` `beamPlays.space.struggle.drawBand` 0.015 (Encounter's file; the trial's struggle numbers lay over `beamStruggle`'s). `beamStruggle.drawBand` stays 0.1 on main, because the trial replaces today's struggle and moving the golden for it isn't worth it.
- **Why:** Orb's question for the clip is "Can you tell who is winning, and why?" A draw answers neither. The point's side at the end does: the meeting point shows it, and holding and catching pulses are what moved it. The detonation stays as the even struggle's set piece, rare enough now to mean something.
- **The acceptance (re-targeted the same day on the stand-in's M4, `docs/ep/reviews/wave1-combat-parks-review.md`):**
  - **Against Easy, a script that only holds wins at least 70 in 100, with at most 10 draws.** This replaces the directive's 40 to 60, which didn't count draws.
  - **A script that holds and flicks on every pulse** (inside the good window, not the sharp one) **wins at least 90 against Easy, and more often than only holding against Medium.** That's the directive's "holding keeps you in it; catching pulses wins it", put where it belongs, above Easy.
  - Flooding presses does no better than holding, and doing nothing wins none.
  - The check reports its draws.
- **Why 70:** Easy is where a newcomer learns. The obvious thing (pushing toward him) should clearly win there, so a first win comes early. Orb: "I still don't think I've won any." The pulse is what wins above Easy.
- **The lever is Easy's `aiHit`, down 0.05 at a time, never below 0.10,** so Easy still surges often enough for the pulse to be seen to matter. It's Easy's own number, so Medium and Hard don't move.
  - **The band stays 0.015.** The band decides whether a lead counts, not who leads, and any visible lead should count. The stand-in's 0.04 would make one held pulse ahead a draw again.
  - **If holding still wins fewer than 70 at 0.10, it comes back to me.** The next lever is the hold's push, and that touches every level.

## S1 ruling 2 amended: a beam let go in a brawl (2026-11-28, the stand-in's M1)

**The finding** (the stand-in's review, read in the code, not run): a stick beam let go in a brawl fires 6 ticks after the release and ends the brawl at that moment. The rival has then been free 0 of the 18 ticks, so the front passes through him, and `b.passed` turns off the damage for every tick after, even while he stands in it. At arm's length, where a new player fires most, a beam does nothing. That's ruling 2 as written, and it's the opposite of "touch is damage".

**Ruling: two changes, both under the trial's switch.**
1. **A brawl isn't a lock.** The 18 free ticks count from his last real lock (down, stunned, held, a launch's recovery), not from a brawl's end.
   - Time in a brawl while he isn't stunned or held counts as free.
   - So a rival who was acting in the brawl is touched by the front as anywhere else: 40% and its hit-stop. If he stands in all of it, he takes the whole hit and the launch.
   - A rival still in a brawl blow's stun is in a lock, and point 2 applies.
2. **Passing through skips only the front.** A beam that meets a body that can't act skips the front's 40% and its hit-stop.
   - **From the tick he can act, every tick he is still inside counts** (the 60% spread over the hold).
   - He can't take "all of it", so there's no launch. A launched body still takes one beam touch per launch, as ruling 2 says.
- **Why:** ruling 2's purpose was that nobody is fired on straight out of a lock (the 11-06 ruling). Neither change breaks it:
  - A brawl is two fighters acting, not a lock.
  - A locked body takes nothing until he can move. From then, standing in the beam is his choice, which is "touch is damage" and agency at once.
  - It also answers Orb's "make energy beams more reliable" where a newcomer fires most.
- **Check rows:**
  - a stage-2 beam let go in a brawl, the rival standing still: the front touches, every tick counts, and standing in all of it launches;
  - the same with the rival in a brawl blow's stun: the front passes, ticks count from the tick he can act, no launch;
  - a rival who dashes out the tick he can act: he takes only the ticks before it.
