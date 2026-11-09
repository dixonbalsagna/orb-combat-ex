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
  - **On your screen:** a beam fired at you brings its source into your frame, or shows Camera's steady edge cue (RL-227). It's never a marker over a fighter (ADR 0010).
- **Escapable:** get off the line before the front arrives. The timed dodge (through the front), the perfect block's deflect, the guard (chip) and an answer of your own all stay.
  - **Two fronts that meet in space start a struggle at the point where they met,** so the struggle comes from the geometry, not from a late-press window.
- **A miss still wrecks:** the column carves along its real line (`power-scale.md`'s groove). A beam that passes under you digs the ground under you, not you, which turns Orb's "way under me" into scenery, and feeds the villain's destruction (`bystanders.md`).

| First values (as data) | Stage 1 | Stage 6 | Rule |
| :--- | ---: | ---: | :--- |
| **Front speed** | 8,000 a second | 18,000 | +2,000 a stage |
| **Time to cross 3,000 units** | 0.38 s | 0.17 s | |
| **Time to cross 6,000 units** | 0.75 s | 0.33 s | |
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
