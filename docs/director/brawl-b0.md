# Brawl slice B0: the groundwork

Owner: Encounter Systems Director. Date: 2026-10-04. Status: in the tree on HEAD `fdd7205`, waiting for the EP's commit. Plan: `docs/director/brawl-plan.md` §4. Spec: `docs/design/melee-press-feel.md` §2b.

Everything here runs only in the `dynamic` profile. **One thing changes in play: the mid-band lunge winds up.** The rest is groundwork, and it is neutral: with the wind-up set to 0 the masher's row and 30 AI matches are the same as on the build before.

## What changed

| Part | Rule | Where |
| :--- | :--- | :--- |
| **The lunge winds up** | A lunge from the mid band holds its crouch for 6 ticks (a light) or 10 (a heavy) before it moves. The move itself is as before: 4,000 units a second, 3 to 20 ticks. A charge and a far flight are unchanged | `bands.gd` `begin`, `tick`, `_startRush`, `drop`; `interrupt.gd` `APPR_WIND`; `interrupts.json` `bands.lunge.windupTicks` |
| **A cue at its start,** for Camera and VFX (`docs/camera/lunge-framing.md`) | One `cue` event as a lunge's wind-up or a charge starts. Its name is `lunge_light`, `lunge_heavy`, `charge_light` or `charge_heavy`. On the same event: `actor` the attacker's slot, `target` the rival's slot, `text` the kind (`lunge` or `charge`), `amount` the wind-up's ticks (0 for a charge) and `n` the ticks of the move after it. The `rush` event still goes out on that tick with the tick the whole approach ends. The fighter's own `rush` (its `off` and `end`) is on him only once he moves | `bands.gd` `begin`, `_startCue` |
| **The defender's time to answer** | The AI defender sees the lunge for the wind-up as well as the move | `bands.gd` `begin` |
| **The struggle's stray press** | It costs 0.10 (was 0.15); the floor stays 0.08 (Orb's pick) | `finishers.json` `contest.struggle.scoring.perStray` (Combat's file, that value by the EP's grant) |
| **What each blow tells Animation and VFX** | Every `strike` and `chainStrike` beat carries `style` (speed, tech, heavy), `grade` (Controls' grade of the press's beat: perfect, good, off, or none), `k` and `n` (its place among his strikes of the exchange, and how many there are so far), `closing` (the blur's own closing blow), `charge` (1 for a held press, else 0), `hand` (r, l, r, ... by `k`) and `ender` (a heavy that ends his string). A `chainStrike` also carries `a` and `d`, as a strike does. The fields are written when the beat is planned, so they lead the contact by the blow's whole wind-up | `recipe.gd` `dress`, `_announce`; `alchemy.gd` `gradeOf` |
| **The cooldown is data** | 0.25 s, plus 0.1 for each second of the exchange, at most 0.6: unchanged | `interrupts.json` `pace.cooldown`; `exchange.gd` `cooldownAfter` |
| **The AI's stance numbers are data** | The four stance weights with their thresholds, the re-pick time, the circle (260, 120 by 70, 2.4 radians a second), the sway rate and the evade stance's back-off (500): unchanged | `ai.json` `stance`; `ai.gd` `aiInput` |
| **Two blur patterns** | `pendulum`'s last step goes to the gut, and `undercut` is legs, gut, chest, head, head: Combat's fixed rows for Legal's sequence rule (`docs/legal/movegen-screen.md`). A pattern only names which piece a blow shows, so nothing changes in play | `data/combat/recipes.json` (Combat's file; those two rows from its parked `recipes.brawl.json`, by the EP's grant) |
| **A probe** | `sim/director/tools/brawl_probe.gd`: a pressing player against the AI. Seconds a minute with nothing running, with no exchange, and in flight; press to contact in live and in real ticks; exchanges a minute and blows an exchange | new file |

**State:** one more integer a fighter (`DirInterrupt.APPR_WIND`). **Cues:** `lunge_light`, `lunge_heavy`; `charge_light` and `charge_heavy` now carry the same fields. **No core lines.**

**`hand` is a stand-in.** It alternates by the blow's place in the string. When Combat's cells name the striking side, it comes from the piece.

**Not in, by the EP's ruling:** `pride_threshold` and `seal_break`. Nothing in the sim computes Pride (it is only a meter name Simulation's parity check accepts) or a seal, and On the Chin is not in the director or in Combat's data yet, so `chin_plant` has nothing to attach to.

## Results

**What the wind-up did** (before is HEAD without this slice; "no wind-up" is this slice with `windupTicks` 0):

| Row | Before | No wind-up | With the wind-up | Band |
| :--- | ---: | ---: | ---: | :--- |
| The masher against the medium AI, his press carrying `waited` | 49 of 100 | | 42 of 100 | 35 to 50% |
| The same with QA's `masher.gd` before its patch (it did not carry `waited`) | 33 of 100 | 33 of 100 | 52 of 100 | |
| Timed masher against plain masher (QA's F6) | 30 of 40 | | 29 of 40 | 62 to 82% |
| Bolt-only against the medium AI | 32 of 100 | | 32 of 100 | 20 to 40% |
| Blasts' share of damage (30 AI matches) | 10.9% | 10.9% | 10.3% | 10 to 25% |
| AI match mean length (30 matches) | 450 s | 450 s | 474 s | |

- **The masher goes from 49 to 42,** inside his band. The defender sees the lunge for longer. No AI number moves: `guardRepeat` stays 6.5.
- **QA's masher script read wrong from 85685a5 until its patch (daf081e).** A press that a hit-stop held is graded at `S.tick` less the intent's `waited`. `qa/godot/players.gd` carried `waited` for such a press and `qa/godot/masher.gd` did not, so its press was graded late by the whole freeze and off the beat: 33 of 100 on HEAD, where the same masher carrying `waited` reads 49, the figure from before that commit. The first row was measured with a scratch copy of the script that carries it.
- **Everything but the wind-up is neutral:** with `windupTicks` 0 the masher's row and 30 AI matches are the same as before.
- **On the final build:** the masher carrying `waited` reads 100, 42 and 0 of 100 against the easy, medium and hard AI; F6 29 of 40; bolt-only 32 of 100.
**The probe, a pressing player against the medium AI** (20 matches; his press carries `waited`):

| Measure | Before | With the wind-up | The spec's target for the brawl |
| :--- | ---: | ---: | :--- |
| Nothing running (no exchange, no approach, nobody launched or down) | 13.1 s a minute | 13.4 | at most 12 |
| No exchange running | 22.9 s a minute | 24.7 | |
| A fighter launched or down, outside an exchange | 8.2 s a minute | 8.3 | about 5 |
| Exchanges a minute; blows an exchange | 38.3; 2.34 | 36.5; 2.34 | a brawl of 10 blows or more |
| Press to contact, live ticks: median, 95th percentile | 60, 452 | 65, 547 | 2 for a mash blow |
| Press to contact, real ticks: median, 95th percentile | 64, 484 | 69, 581 | |
| Presses that become a blow within 10 live ticks | 16.3% | 15.4% | at least 95% in a brawl |

These are the "before" for B1.

**QA's harness** (`node qa/run-godot.js`, four arms, 100 matches an arm; before is QA's baseline on 9fcdf87 at 400 an arm, `docs/qa/baseline-9fcdf87.md`):

| Row | Before | After | Band |
| :--- | ---: | ---: | :--- |
| Match length, median | 471.9 s | 486.9 s | 360 to 480 s |
| Match length, 90th percentile | | 583.8 s | at most 600 s |
| KAI over both slots | 49.8% | 53.5% (50.0% from P1, 57.0% from P2) | 45 to 55% |
| Blasts' share of damage | 11.0% | 10.8% | 10 to 25% |
| First brink, median | 388.7 s | 404.9 s | 270 to 420 s |
| Brink to KO, median | 69.2 s | 84.0 s | 45 to 90 s |
| Finisher survival rate | | 31.5% | 25 to 40% |
| Front-row structures lost | 54.0% | 54.7% | 25 to 50% |
| Perfect blocks per 100 melee exchanges | | 13.5 | 5 to 15 |
| Exchanges that end in a knock-back | | 32.2% | 25 to 35% |
| Launches of the exchanges that separate | | 39.2% | 25 to 40% |
| Lights-only mirror, brink to KO | | 53.8 s | 30 to 55 s |
| Bolt-only against the medium AI | | 32 of 100 | 20 to 40% |

98 bands pass, 17 fail, 21 pending; no hard test fails. The harness's own masher row read 52 of 100 on this run, with QA's script from before its patch (daf081e).

**Outside its band: the match median, by 7 s.** The wind-up adds 6 or 10 ticks to every mid-band attack: 30 AI matches run 24 s longer on the same seeds, and the four-arm median is 15 s over QA's baseline. Front-row structures are over as before. The levers for the median that are now data: the cooldown's `min` (0.25 s), or a shorter wind-up.
**Gates** on a clean copy of HEAD with exactly the tree's changes (no sim or data file of the director's, Combat's or Simulation's differs between that copy's base and `fdd7205`; parity again in the tree): goldens regenerated (9 matches, 172,441 ticks); parity, the loader check at 200 matches, `npm test` 5 of 5, determinism, seam, the cue check, Controls' input tests (hub 50, touch 167, agency input 113, press read 262 checks) and its mash probe pass.

**One gate fails: Animation's `anim_check`,** in its pair live test: "the energy events did not start his own poses". It is the test's own assumption, not a fault in the energy poses. The test runs a seed-4 AI match for 1,500 ticks and then drives the energy poses on fighter 0 "outside an exchange", but it takes the match as it stands at that tick, and the poses do not start for a fighter in an exchange (`_en_busy`). On HEAD no exchange runs at tick 1,500; with the lunge's wind-up the match has moved and a CLEAN HIT is running there. With `windupTicks` 0 the check passes on this slice. The fix is in `render/anim/tools/anim_check.gd` (Animation's): step on until no exchange runs before the energy block, or use a fresh state.

## What B1 needs from Simulation (a patch plan for its own window)

1. **A hashed home for the brawl's shared integers.** `sim/core/state.gd`, class `DirS` (line 139): one field, `var brawlI: PackedInt32Array = PackedInt32Array()` (the director's shared integers for a brawl). `sim/core/hash.gd`, beside `out.append(float(d.exN))` (line 109): its size and its values, as line 156 does for a fighter's `act.dirI`. One golden regeneration; the matches' ticks do not change, because nothing writes it yet.
2. **The fighter's step.** Probably no change. B1 keeps both brawling fighters `locked`, the state an exchange uses today: `sim/core/fighter.gd` line 373 damps a locked fighter's velocity and moves him by it, and reads no stick. The director places him, as `DirMelee.contactTick` does now, and reads his stick itself for the damped walk. **To confirm:** nothing else moves or frees a locked fighter while an exchange of the new kind `brawl` is held in `S.dirS.ex` for many seconds.

## Data keys for Tools

| File | Keys |
| :--- | :--- |
| `data/director/interrupts.json` | `bands.lunge.windupTicks` {`light`, `heavy`} (integers); `pace` {`cooldown` {`min`, `perSec`, `max`} (numbers), `_note`} |
| `data/director/ai.json` | `stance` {`repick` [2 numbers], `press` {`fresh`, `hurt`, `hurtBelow`}, `guard` {`hurt`, `fresh`, `hurtBelow`}, `evade`, `escape` {`hurt`, `hurtBelow`, `lowKi`, `lowKiBelow`, `rest`}, `circle` {`r`, `x`, `y`, `rate`}, `swayRate`, `evadeBackoff`, `_note`}. None may be negative; the weights are not shares; the three `hurtBelow` are 0 to 1 |
| `data/combat/finishers.json` | value only: `contest.struggle.scoring.perStray` −0.10 |

## Left in code, for a later slice

The AI's chance to attack on a beat by stance, its attack cadence ranges, the urge after 6 s, the heavy share, and its closing distances are still constants in `ai.gd`.
