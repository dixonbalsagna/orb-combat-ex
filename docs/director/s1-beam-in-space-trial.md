# Spike S1: the beam in space, the trial (Encounter, 2026-11-14)

A throwaway trial on a scratch copy of main def3445a. **Nothing lands.** It was built from the stand-in's design (`docs/ep/proposals/beam-in-space-trial-design.html`) with Game Design's rulings (`docs/design/beam-physics.md`, "Spike S1's rulings").

## What was tried

The stick beam's own move fires **a beam that is a thing in space, not an exchange**. A new `DirBeamSpace` (about 200 lines) and about 60 lines across `beam.gd`, `beam_move.gd`, `stick.gd` and `exchange.gd` do it, plus three fields on the beam in `state.gd`, behind `beamPlays.space` (off). In the trial:
- **It fires 6 ticks after the release, never later,** or is refused at once with a word (no ki, the KO, something else playing). No wait for the target. The shooter is planted for the tell and the stage's lit time.
- **The front moves at 6,000 + 2,400 a stage** a second, along the line it left on. **Only the front hits, each body once,** within its half-width (45 + 25 a stage) plus a body (40). Off the line, nothing.
- **Reach 4,200 + 1,200 a stage** (72 bh at base, 136 full). It spends itself past its reach and **stops where it enters the ground.** Towers it goes through, since the carve breaks them.
- **What a touch does:**
  - a body that can't act (down, stunned, free under 18 ticks) is passed through, except a launched body, which takes one beam touch per launch;
  - a dodge tap in the 12 ticks before contact is passed through;
  - a fresh guard press in the 12 before is the powerful block's stop;
  - a held guard is GUARD;
  - otherwise HIT, launched along the beam's own line.
- **Assist 15°** for the player and the computer. **The shove is off** (it lives only on the old path).
- **The computer** points its stick at its rival (the nearest of 32 directions) and doesn't start a hold past its stage's reach. It doesn't sidestep yet.

## The escape probe: QA's X-16 isn't built yet, so the trial has its own

A scripted full-power shooter whose stick tracks the defender fires stages 1, 3 and 6 from three ranges inside each stage's reach. Both fighters are 600 above the ground. There are four defenders:
- **stands**;
- **flying**: has been flying straight up (across a level line) at plain speed;
- **dash15**: stands, then dashes up 15 ticks (0.25 s) after the fire;
- **dashing**: has been dashing up.

Each cell is the outcome, then the ticks from the fire to contact, or for a miss how far off the line he was as the front passed.

| Stage | Range | stands | flying | dash15 | dashing |
| ---: | ---: | :--- | :--- | :--- | :--- |
| 1 | 1,500 | hit, 15 | miss, 85 off (it hits within 85: one unit) | hit, 15 | miss, 211 off |
| 1 | 3,000 | hit, 30 | miss, 172 off | miss, 240 off | miss |
| 1 | 4,000 | hit, 40 | miss, 230 off | miss, 721 off | miss |
| 3 | 1,500 | hit, 8 | hit, 8 | hit, 8 | hit, 11 |
| 3 | 3,000 | hit, 16 | hit, 16 | hit, 16 | miss, 583 off |
| 3 | 6,000 | hit, 33 | miss, 190 off | miss, 742 off | miss |
| 6 | 1,500 | hit, 5 | hit, 5 | hit, 5 | hit, 9 |
| 6 | 3,000 | hit, 10 | hit, 10 | hit, 10 | miss, 337 off |
| 6 | 6,000 | hit, 20 | hit, 20 | hit, 19 | miss |

| Reading | The trial | Today's beam (the same probe, the trial off) | Band |
| :--- | ---: | ---: | :--- |
| A moving target beyond 3,000, hit | **2 of 9 (22%)** | 9 of 9 | 10 to 30% |
| A moving target inside 1,500, hit | **7 of 9 (78%)** | 9 of 9 | 40 to 70% |
| Beams fired later than 6 ticks after the release, or a target held before the beam reached him | **0** | **36 of 36** (today the defender is locked in the beam's exchange from the release) | 0 |

**What the table says:**
- **Standing still gets you hit,** at every range a beam reaches.
- **A small beam at range is for making someone move.** Anyone already moving across gets out from 1,500 out at stage 1, and at 6,000 at stage 3.
- **Up close, stages 3 and 6 arrive before anyone can leave the line** (5 to 16 ticks). That's why the near band reads 78%, above its 40 to 70%. Game Design's X-16 wording ("near range passes only for a defender already moving") holds at stage 1 only.
- **A full beam catches everyone but the fighter already dashing,** out to 6,000.
- **Nothing is late or held,** where today's beam held all 36 targets.

## What it cost

About 0.3M tokens. The beam itself was a medium-sized build: the line, the front, the body test, the carve and the hit outside an exchange all existed in some form. One fault was found in the trial and fixed: the reach was first multiplied by the feature scale (8), so beams reached 33,600 units, today's "from anywhere". It's plain units now.

## Is A-COMBAT-01 still a large job?

**Yes: large at least, extra-large if every answer is kept.** The beam itself is medium (above). The weight is elsewhere:
- the computer (its sidestep and shot choice; it aims already in the trial);
- the struggle's new way in, where fronts meet (`startMeet`, not built);
- the powerful block's three looks and the wade, re-homed onto the contact tick;
- the cue readers in five other directors' code;
- the beam checks to rewrite (below).

## What breaks (measured: the beam checks with the trial on)

Twelve beam and press checks were run with the beam switches on (the front, the own move, the aim): first with space off, where all 12 pass, then with space on.

| Check | Space on | What it asserts that the beam in space changes |
| :--- | :--- | :--- |
| `beam_move_check` | **6 rows fail** | The release starts the beam's exchange; it ends a brawl and starts the exchange; the shove ("the firing throws him back"); the lit hand waits till the target's been free 0.3 s, says "soon", and is refused past its wait. All of it is today's wait and exchange, which the beam in space removes. (Its `_gate` and `_late` rows, as the EP said) |
| `beam_ai_check` | **4 rows fail** | The computer's beam: its exchange at the release, nobody locked while it charges, paying its stage at the release, its signature wait. They read an exchange that no longer exists. The "nobody locked" row also counted its rival locked for 29 ticks during the charge, which needs a look before A-COMBAT-01 is built |
| `beam_front_check` | **3 rows fail** | Fires on the release through the front's exchange (two rows), and a stick two directions off (22.5°) is "a shot at him": that's the old 35° assist, where Game Design's ruling 5 is 15° |
| `push_mode_check`, `strike_stages_check`, `morning_fixes_check`, `flight_strike_check`, `stick_check`, `press_decides_check`, `a_press_check`, `refusal_reasons_check`, `press_answers_check` | all pass | |

**So, measured, what breaks is the three beam checks (13 rows). Each needs rewriting for the beam in space**, and none of them runs in CI today. Not measured, because the trial doesn't build it:
- **The struggle:** today's three ways in (an answer in the tell, a late answer, the fire-back) all come from the exchange. In space there's only the meeting of two fronts, which needs a new way into an exchange from two free fighters (`startMeet`).
- **The computer's beam play:** it aims and holds its reach in the trial, but it never sidesteps, and its answers (`aiPlan`, `aiMayDodge`) are never reached, because no exchange is planned against it. Its pacing (`vsHuman`) was set for beams that always land.
- **The cue readers:** `beam_window` (UI's alert, the rumble), `beam_shove`, `beam_late` and `beam_arrive` stop. `beam_outcome` gains PASS and MISS. Five directors each have a reader to move.

## For Orb

- **A clip is needed:** the same small beam at a fighter who stands and at one who flies off its line (it passes and digs the ground); a small, a middle and a full beam from one spot; the computer firing at the pad and the pad stepping out. This needs Tools' launcher on the scratch copy and VFX's stage pulses, so it's asked for under NEEDS FROM EP.
- **The questions** (the stand-in's, for the EP to put under the clip, one at a time): keep the beam stages (a longer hold is wider, faster and longer)? And fast as shown, where you move on the charge's glow, or slower, so there's time to react to the beam itself?
