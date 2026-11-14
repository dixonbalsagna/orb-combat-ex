# Parked: main's director data made the 9 November build's (GW1a: the computer opponent, the match-ending rules, and the rest)

Encounter, 2026-11-13, sprint A1 wave 1 (A-AI-05, with A-MODES-07's row and the other director rows), for GW1a's turn. **The golden moves: GW1a re-records it.**

## What differs, read from the build's own data

Main's `data/director/` (def3445a) was compared value by value with the played build's packed data (`homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/tree/data/director`), not with a switch list.
- **37 values differ, all switch rows.** `alchemy.json`, `location.json` and `rally.json` are equal.
- The four held rows (`wallPush`, `wallPushAi`, `slamTurn`, `aimCuts`) are off in both, so they're equal.
- No `_note` text differs.

| Group | Rows | Patch |
| :--- | :--- | :--- |
| **The computer opponent (A-AI-05)** | `ai.json` `levels.easy.brawl.paceMatch.enabled` (Easy matches your pace), `vsHuman.enabled` (its beam pacing against a human), `interrupts.json` `beamPlays.front.ownMove.ai` (its hold-and-release beam) | `rows-ai.patch`, 3 lines |
| **The match-ending rules (A-MODES-07)** | `interrupts.json` `ending.enabled` | `rows-ending.patch`, 1 line |
| **The rest: no group is named for them in the path** | `interrupts.json`: `bands.arrive`, `bands.follow`, `beamPlays.front.aim`, `beamPlays.front` (the front), `beamPlays.front.ownMove` (the stick beam's own move), `beamStruggle` and its `pushMode`, `blast.driver`, `brawl.chargeClose`, `brawl.oneRuleB`, `brawl.pressWait`, `calmTurn`, `carryRound`, `chase.tap`, `grapple`, `press.refusedCue`, `stances`, `water`, `zip.flightStrikes`. `launch.json`: `arc`, `arc.firstMeteor`, `sideFromBlowOnly`. `stick.json`: `armour`, `flickKeep`, `flickRun`, `fullSend`, `lightStops` (true to false), `lungeLight`, `pendFollow`, `strikeStages`. `swing.json`: `brawl.shareCap`, `enabled`, `jolt.yieldToLaunch` | `rows-fight.patch`, 32 lines (33 values) |
| All 37 | | `rows-all.patch`, 36 lines |

**My recommendation: the 33 go with the computer opponent's turn.** The computer Orb played is made of them: the brawl's rules, the stick beam's own move (which its hold-and-release beam needs), the stances. `ownMove.ai` does nothing without `ownMove` and the front.

Each patch changes only the values' own text (`rows_flip.py`, kept here: it finds each value's place in the file, writes the build's value, and checks nothing else moved). Each applies on main alone, and the three stack. With all 37 applied, main's `data/director/` equals the build's value for value. `node tools/validate.js` passes (321 files, 0 errors).

## Apply

On main def3445a: `git -c core.autocrlf=false -c core.eol=lf apply rows-ai.patch` (then `rows-ending.patch`, `rows-fight.patch`), or `rows-all.patch` alone. If main moves, `python rows_flip.py <tree> <build data/director> ai|ending|fight|all` re-cuts them from the build's data.

| Patch | sha1 |
| :--- | :--- |
| `rows-ai.patch` | 8a574fcd9b6f76f0915c5bea7e00e27cd7827e3a |
| `rows-ending.patch` | 6e5f78df91c8fa387160775208784e4f46ac9157 |
| `rows-fight.patch` | 61fa3a06f2c29dd66ee2c1a37523d2290999c3d7 |
| `rows-all.patch` | 241d2e3499db354625a34aa6c957a91a906a3f61 |

| `note-they.patch` (the signature limit's note in `interrupts.json` called Orb "he": now "they"; text only, at the EP's word) | 06d234996e65f34b9cbaf41762322035f2648051 |
| `check-pin.patch` (`sim/director/tools/city_push_check.gd`: the slam turn's three scenes are set up with the director's swing forced off and turned on just before the slam, so the check doesn't depend on `swing.json` being off in the data; a check only) | 9dd1ed7d29cd2dda664adfb32b21e9212f942be9 |

No schema changes and no grants: values only, plus the one note's word.

## Proof

The gates ran on main def3445a plus `rows-all.patch`, so `data/director/` equals the build's. Records are in `docs/director/runs/def3445a/director-rows/`, and every output went through `tools/gate.mjs` with no SCRIPT ERROR.
- **Parity: the golden check fails, as it must** (the data changed). Only its golden rows differ: the intros, the matches, the human-input replays and the planet worlds. GW1a re-records the golden on the 9 November build's data.
- Validate 0 errors; self-test 10,093 of 10,093; ratchet 365.
- **41 of 42 director checks pass** (all but `loader_check`). `city_push_check` failed two rows, "a slam starts a big swing" and "a lodge starts it". The check set its scenes up with the director's swing at the data's switch, which the 9 November rows turn on, so a swing already running or resting blocked the slam's. `check-pin.patch` sets them up with the swing forced off. Its own runs, with the rows and on main's data, are in the queue.
- The core checks `two_states` and `load_split` pass.
- **Determinism (the planet setup):** passed. **Rollback (the planet, lan and p120):** 2 sessions, 4,800 confirmed-tick hash comparisons, 0 failures.

## NEEDS FROM EP

- **Which group the 33 rows ride with** (recommendation above).
- **The side-by-side** (ADR 0010) against the 9 November build at the group's landing, as GW1a has it.
- **QA (acceptance 6):** the first X-06 win-rate reading for Orb's scheme on this data.
- **A-MODES-07's check** (acceptance 2: a scripted match ended each of the three ways on main's own data) is not in this park. It's next if you want it before the ending row lands.
- **Tools:** `tools/preview/switches.mjs` can drop each of these rows once main carries it (I name them, Tools edits).
