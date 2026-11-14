# COMBAT: combat and the director

Alpha audit, phase 2, baseline 8901d351 (game code as build 6a30b4c9). Read-only review; nothing was run. "Main" means the files on disk at the baseline. "The played build" means the data in `homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/tree/` (git-ignored; Orb's last solo copy). "Switch" means a true/false key in a data file that turns a built feature on.

## Summary

- **Works:** the close fight (the brawl) with nine ways to press X, Y and B per fighter; energy bolts, blasts and the Driver on RB; the right stick's strikes and a staged, stick-aimed beam; the tier ladder with a paused, frozen transformation; the chase after a launch by a plain tap.
- **Does not:** beams still always arrive and are decided by a timed press, not by where the defender is; signatures are still on the interim RT + B; there is no gravity well in code; RT + X, Y and A are the plain blow; both stray-beam bugs are open.
- **Biggest gap:** beam option A (a beam that travels in space and misses a defender who moves off its line) is paper only, and X-13, X-16 and X-17 all rest on it and on the new signature inputs.
- **Under everything:** most of the combat Orb played is off in main's data and on only through the build page's switch rows, so "the Alpha candidate" has no single committed set of combat data yet.
- No tool exists for X-03, X-04, X-13 or X-16; X-17 has a trace tool but no count.

## Questions and answers

**Q1. Is every stance pairing covered by at least two authored outcomes?**
The planned-exchange templates are still keyed on the prototype's derived defender states, not on the five held-button stances (`sim/director/data.gd:134`, `data/combat/templates.json:161-924`). Pairings and outcomes as the data has them:

| Attack | Defender state | Template | Outcomes |
| --- | --- | --- | --- |
| light or heavy | CHARGING | charge_interrupt | interrupt (one) |
| light or heavy | ESCAPE | pursuit | slips, caught |
| light or heavy | EVASIVE | dodge | read, counter, clean |
| light | DEFENSIVE | pressure | holds, counter |
| heavy | DEFENSIVE | guard_break | break (one) |
| light | AGGRESSIVE | trade_blows | won, lost |
| heavy | AGGRESSIVE | heavy_clash | won, countered, shockwave |
| light | NEUTRAL | clean_hit | clean, clipped |
| heavy | NEUTRAL | clean_hit_heavy | clean, clipped |
| any | riposte (context) | riposte | lands (one) |

So two pairings have one outcome (`templates.json:161-166`, `:512-517`). In the close band a light or heavy against a standing or guarding rival starts the brawl instead of a planned exchange (`sim/director/brawl.gd:3-5`), so these templates cover a shrinking share of play. **What the criterion should now mean:** the roadmap's "every stance pairing" is about the four retired stances; with Orb's five held-button stances (`docs/ep/vision.md:595-601`) the live test is X-03's move table (every held button by every face button by every way of pressing has its own outcome). Recommend the audit treats X-03 as the successor and records the two single-outcome templates as a minor leftover.

**Q2. Does every cell of the move table exist for both fighters?**
No. There is no data table of cells; a cell is a branch in code plus, for some rows, a pool of pieces per fighter. What was read:

| Held | X | Y | B | A | Per fighter? |
| --- | --- | --- | --- | --- | --- |
| none (martial) | light: tap, mash (flurry), hold (burst) | medium: tap, mash, hold | heavy: tap, mash, hold (charge, launch at full) (`brawl.gd:18-24`) | grab reach in a brawl, behind `grapple.enabled` (`grapple.gd:4-8`; off on main, on in the played build) | Yes: pools `brawl.light`, `brawl.flurry`, `burst.*`, `brawl.medium*`, `brawl.heavy*` for rival and protagonist (`data/combat/recipes.json:1878-1879`, `:3149`) |
| RB (energy) | bolt, taps queue a volley (`blast.gd:4`); point-blank bolt in reach (`brawl.gd:31`) | charged shot or blast (`blast.gd:5-6`) | the Driver, tap and three hold levels (`driver.gd:3-4`), behind `blast.driver.enabled` and `driverOnRb` (off on main: `data/input/timing.json:50`; on in the played build) | not found | Pools `reach.bolt` (4) and `reach.blast` (2) per fighter; the Driver's kit line per fighter is in `data/fight/power.json` (per RR-02) |
| LB (defensive) | the check (`stance.gd:3`, `:56`) | the push (`stance.gd:4`, `:56`) | no stance blow (`stance.gd:51` returns for B) | not found | Shared; behind `stances.enabled` (`data/director/interrupts.json:259` false on main; true in the played build) |
| LT (manoeuvre) | flight strike or zip (`zip.gd:174`, `:246-262`) | flight strike or zip | the flight strike's biggest blow (`zip.gd:178-179`) | not found | Shared; `zip.flightStrikes.enabled` off on main, on in the played build |
| RT (charging) | the plain blow, charge drops (`sim/input/layout.gd:522`; `docs/design/pad-first-press.md:23`) | the plain blow | the signature, interim (`brawl.gd:3178-3179`) | the plain action | Duplicates of the martial row |
| right stick | flick: quick strike; hold: three charge levels; four directions (`stick.gd:2-5`, `:21`) | | with RB: the beam, six stages (`beam_move.gd:5-9`; `data/input/timing.json:82`) | | Shared numbers; per-fighter pieces not evidenced |

Missing or duplicated: **RT + X, Y, A** (three cells times the ways of pressing, both fighters) are the plain blow by a switch that is on in main and in the played build (`data/input/timing.json:48`). **LB + B, RB + A, LB + A, LT + A**: no distinct outcome found. **Tap, mash and hold inside the LB, LT and RB rows**: not evidenced cell by cell (RR-01 was not on file; this read is by code branch only). Combat's generated movesets for the other four stances are parked and need poses and sim actions that do not exist (`docs/ep/proposals/combat-variety-packet.html:232`).

**Q3. Beam option A: what must change?**
Today a beam is an exchange with a named target. It "reaches the defender travelTicks later, at any distance" (`sim/director/beamplay.gd:2-4`), its flight time is capped "so it always arrives" (`beamplay.gd:55-58`), and the outcome is read from what the defender pressed (perfect block, dodge tap, guard), never from where he is (`beamplay.gd:398-420`). The stick's aim already makes a wide shot miss, but only outside an assist cone of 35 degrees (`sim/director/beam_aim.gd:8-9`; `data/director/interrupts.json:308-309`). Option A as written (`docs/design/beam-physics.md:25-37`) needs: a front that travels along a fixed line at a speed in data; a hit test of that column against bodies, buildings and ground; escape by leaving the line; a struggle where two fronts meet; the 15-degree assist; and the source in frame or an edge cue. None of it is in code: the keys the design names (`beamPhysics`, `frontSpeed`, `hitHalfWidth`; `beam-physics.md:99`) return nothing from `git grep` in `sim/`, `data/` or `render/`.

**Q4. Signatures on Orb's new inputs.**
Orb's ruling: RT + RB + flick is the energy signature, RT + flick the martial one (`docs/ep/vision.md:1710`). Neither exists. The only signature input is the interim RT + B, and the code says so: "still the signature until RT + right stick lands" (`sim/director/brawl.gd:3179`). There is one signature per fighter (the key `<ID>.SIG`, `data/fighters/PROTAGONIST/fighter.json:5`), which is the beam (`data/combat/templates.json:964`); no martial signature was found in data or code. So the replacement needs an input read (Controls), a second signature per fighter (Combat, Game Design), and the removal of RT + B.

**Q5. The two stray-beam bugs: open?**
Both open. No commit since 6a30b4c9 touches `sim/`, `data/`, `render/`, `ui/`, `net/` or `audio/` (`git log 6a30b4c9..8901d351` over those paths is empty). (1) A released stick beam that cannot start still waits up to 90 ticks and then fires whatever the player is doing (`sim/director/beam_move.gd:266-272`; `data/director/interrupts.json:296`; record `docs/qa/runs/6a30b4c9/README.md`, tick 5220). (2) RT + B past the 12-tick window still beams because the rule reads the fighter's state, not ticks since RT (`sim/director/brawl.gd:3178`; same record, tick 6617).

**Q6. The gravity well: which increments landed?**
The packet says "nothing is built" and plans nine increments, 0 to 8, about 28M tokens (`docs/ep/proposals/gravity-well.html:444`). At the baseline: no well, zone, draw, snap or intent reader exists (`git grep` for `SimWell`, `DirIntent`, "gravity well" in `sim/`, `data/`, `render/`, `tools/`, `qa/`: nothing). What did land are pieces of Game Design's ruling (c) on LT's speed that the packet's increment 1 builds on: the arrival ease (`data/director/interrupts.json:81`, `bands.arrive`, off on main, on in the played build) and the dash slip (`data/fight/power.json:113`, `dash.slip`, off on main, on in the played build), while `dash.enabled` itself is off in both. Increment 0's press-to-motion counter: not found in `tools/`, `qa/` or `sim/`. Orb's "close fights: your stick moves just you" is still "workshop this" (`docs/ep/vision.md:1694`).

**Q7. Transformations: how many forms, and is "respected" built?**
In data: the Protagonist has five own steps with two branch points, switched off (`data/fight/forms.json:4`; RR-02); the rival has no forms file (RR-02). In play both use the shared ladder: three tiers beyond base at power 35, 65 and 100, taken by hand (`data/fight/ladder.json:10`, `:13`). In Orb's last full match the computer reached tier 3 and Orb's fighter was still tier 1 at tick 18,516 of 19,388 (`docs/qa/runs/6a30b4c9/beam-trace-orb-1646.txt`, the BEAM lines at t=12120, 16625, 18516). The look per tier is an aura shape only, with placeholder poses (`data/anim/forms.json:3`; RR-02). "Respected": a transformation starts only between exchanges (`sim/director/exchange.gd:948`); the full and short versions freeze the whole sim (`sim/core/pause.gd:2-5`); the live version holds exchanges and the transformer for 0.8 s (`exchange.gd:961-968`) but `sim/core/damage.gd` has no transformation guard (grep: none), so whether a shot already in flight can land during a live hold is not evidenced.

**Q8. Launches.**
- *Ping pong off buildings:* open. The settings that would hold a body in a building are one held switch row, off in every build: "cityHold OFF (waiting on QA city read)" (`docs/tools/runs/6a30b4c9/switch-list.txt:60`; `data/biomes/brunt.json:47-50`). The knock-back that aims at a wall and the walk to a wall are off too (`data/director/launch.json:94-95`, `:134-135`). Orb raised it on 2026-11-06 and again on 2026-11-09 (`docs/ep/vision.md:1656`, `:1687`).
- *Opposite way to the blow:* fixed behind a switch that is off on main and on in the played build (`data/director/launch.json:4-5`; `switch-list.txt:76`). Not evidenced by a saved record on 6a30b4c9.
- *Physics-based:* no. The meteor and the tier-4 high launch are "one authored curve, not physics" (`sim/director/arc.gd:3`); no force or weight term per attack or fighter exists (`git grep -i "kinetic\|heft"` over `sim/` and `data/`: nothing). The physics model is a packet only (`docs/ep/proposals/physics-packet.html`).

**Q9. Chains and flurries on a flying foe.**
Partly built. A plain tap after a send starts a chase whose press is the blow (`sim/director/chase_tap.gd:3-10`), on in the played build (`switch-list.txt:20`), and it is one of five director checks in CI (`.github/workflows/ci.yml:221`). Orb asked for more after playing with it on (`docs/ep/vision.md:1686`). The LT chase is off (`data/director/interrupts.json:653`), a chain window after a knock-back is off (`data/director/launch.json:89`), and a flurry on a body in the air was not found. Whether Orb's presses reached a chase in that match is not evidenced.

**Q10. Orb's "workshop this" combat items.**

| Item | State at the baseline | Place |
| --- | --- | --- |
| Beam stages | Built: six stages by hold time and energy (`data/director/interrupts.json:297-301`); Orb: "I'm not sure, workshop it" (`vision.md:1707`) | Before Alpha, settled with option A's widths and speeds |
| Walking into a beam | A look on a perfect block or guard with the stick toward (`beamplay.gd:7-12`, `:415`) | Before Alpha only as it stands; Orb's toy version after |
| The swat | A look on a perfect block with the stick away (`beamplay.gd:415`); Orb's timed-charge swat not found | After Alpha |
| The catch | Not found in `sim/director/` | After Alpha |
| High Intensity on RT | Not found; RT held is the ki charge | Before Alpha as a decision (what RT held does once signatures sit on RT + flick), build after |
| Taunt before a signature | Not found | After Alpha |
| Close fights: stick moves just you | Open (`vision.md:1694`) | Before Alpha: it sets the gravity well's rules |

**Q11. The combat-variety packet: which increments landed?**
Six increments, 48M tokens (`docs/ep/proposals/combat-variety-packet.html:223`). By the switches and code at the baseline: increment 1 (responsive) partly, as switches on in the played build and off on main (refusal cue, press wait, chord pick, flight strikes, stick lunge; `switch-list.txt`), with no press-to-motion counter found; increment 2 (stick depth and the slam) partly (strike stages, full send, flick run on in the played build; `data/director/stick.json:38-91` all false on main); increment 3 (the composer) not started (no composer or COMPOSE feed in `sim/`); increment 4 not evidenced; increment 5 only the "carried round" fix (`data/director/interrupts.json:3`); increment 6 phrases switched on in the played build (`data/combat/phrases.json:4` false on main) and the mixed string, whose data file no game code reads (`git grep -l "mixed\.json" -- "*.gd"`: nothing).

**Q12. What remains of the retired prototype behaviours?**
Hiding and ambush code is live but inert: the AI still weighs cover (`sim/director/ai.gd:108-111`) and the ambush timer still runs (`sim/director/exchange.gd:329-335`), while both fighters have `canHide` false (`data/fighters/PROTAGONIST/fighter.json:11`, `data/fighters/RIVAL/fighter.json:11`). Signature variants by biome are live: the aftermath twist is read at `sim/director/beam.gd:153` from `data/combat/sigvariants.json`. The backburnered meters still act: the rival's menace adds to beam clash power (`beam.gd:208`, `:245`; `data/fighters/RIVAL/meters.json:76`) and both meters steer a deflected beam (`sim/director/beamplay.gd:508-513`).

## Exit criteria

| Id | Status | Proof or gap | Measuring tool |
| --- | --- | --- | --- |
| X-03 | Gap | RT + X, Y, A duplicate the plain blow; several A and B cells have no outcome; stance rows are shared code, not per fighter (Q2). **The proposed table should change:** Orb's ruling is three ways of pressing for X, Y, B and "a press and a hold" for A (`vision.md:638-643`), so 5 stances x (3 buttons x 3 + A x 2) = 55 cells a fighter, plus the stick's strikes and beams, not 60 | Moveset coverage probe: missing. `qa/godot/players.gd` and `sim/director/tools/stance_check.gd`, `brawl_cases.gd` cover parts, none walks every cell |
| X-04 | Not evidenced, leaning gap | Three shared tiers exist and the computer reached tier 3 in play; the player stayed at tier 1; tier 4 in a match and the per-form look are not evidenced; the rival has no forms of his own. **Proposed "two forms beyond base":** keep it only if the shared tiers count as forms; Orb's "about three" (`vision.md:423`) matches the ladder's three steps | Transformation probe: missing (no forms check in `sim/core/tools/` or CI) |
| X-13 | Gap | Missing from any build: a beam dodged by moving off its line, both signatures on Orb's inputs, the gravity well's pull. Player transformation not seen in Orb's last match | Alpha match checklist probe: missing; the cue feed and `qa/godot/trace_replay.gd` exist to build on |
| X-16 | Gap | Beams always arrive; position never decides (Q3). **Proposed "more than the beam's width":** use option A's half-widths, 45 units at stage 1 to 170 at stage 6 (`docs/design/beam-physics.md` table), and its three hit-rate bands | Beam escape probe: missing |
| X-17 | Gap | One late stick beam and RT + B past its window in Orb's last match (Q5); RT + B itself is not an input Orb named. The earlier B-alone beams are fixed only where `bNoBeam` is on (off on main, `data/input/timing.json:57`) | `qa/godot/beam_trace.gd` exists and lists each beam's inputs; the count over many matches is not built |

## Findings

| id | kind | statement | evidence | criterion | severity | alpha | owner | cost | hash |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-COMBAT-01 | gap | Beam option A is not built: a beam is still an exchange that always reaches its target and is decided by a timed press, not by position. | `sim/director/beamplay.gd:2-4`, `:55-58`, `:398-420`; `docs/design/beam-physics.md:25-37`, `:99` | X-16, X-13 | blocker | required | encounter-systems | L | yes |
| F-COMBAT-02 | gap | Signatures are not on Orb's inputs: RT + RB + flick and RT + flick do not exist, RT + B is the only input, and no martial signature exists for either fighter. | `sim/director/brawl.gd:3178-3179`; `data/input/timing.json:49`; `data/combat/templates.json:964`; `docs/ep/vision.md:1710` | X-13, X-17, X-03 | blocker | required | encounter-systems | L | yes |
| F-COMBAT-03 | gap | No gravity well exists in code: no well, zones, draw, snap or intent read, only two pieces of the LT speed ruling behind switches. | `docs/ep/proposals/gravity-well.html:444`; `data/director/interrupts.json:81`; `data/fight/power.json:113`; `git grep SimWell` (none) | X-13 | blocker | required | simulation-engine | XL | yes |
| F-COMBAT-04 | gap | The move table is incomplete for both fighters: RT + X, Y and A are the plain blow, several A and B cells have no outcome, and the LB, LT and RB rows are shared code with no per-fighter content. | `sim/input/layout.gd:522`; `data/input/timing.json:48`; `docs/design/pad-first-press.md:23`; `sim/director/stance.gd:51-60`; `docs/ep/proposals/combat-variety-packet.html:232` | X-03 | blocker | required | combat-choreography | XL | yes |
| F-COMBAT-05 | gap | Most of the combat Orb played is off in main's data and on only through the build page's switch rows, so no committed data set is the Alpha's combat. | `data/director/interrupts.json:259`, `:277`, `:294`, `:308`; `data/input/timing.json:50-58`; `data/director/stick.json:38-91`; `docs/tools/runs/6a30b4c9/switch-list.txt` | X-03, X-13, X-17 | major | required | ep | M | yes |
| F-COMBAT-06 | gap | A released stick beam that cannot start waits up to 90 ticks and then fires into whatever the player is doing; open since Orb's last play. | `sim/director/beam_move.gd:266-272`; `data/director/interrupts.json:296`; record `docs/qa/runs/6a30b4c9/README.md` | X-17 | major | required | encounter-systems | S | yes |
| F-COMBAT-07 | gap | RT + B stays a signature for as long as the fighter is not channelling, not for 12 ticks, because the rule reads state and not time. | `sim/director/brawl.gd:3178`; record `docs/qa/runs/6a30b4c9/README.md` | X-17 | minor | required | encounter-systems | S | yes |
| F-COMBAT-08 | gap | Transformations are the shared three-tier ladder for both fighters: the Protagonist's own forms are switched off, the rival has none, and the only per-tier look is an aura with placeholder poses. | `data/fight/forms.json:4`; `data/fight/ladder.json:10-13`; `data/anim/forms.json:3`; `reads/RR-02.md:18-36` | X-04 | major | required | game-design | L | yes |
| F-COMBAT-09 | gap | In Orb's last full match the player's fighter never left tier 1 while the computer reached tier 3; the transform chord has no hint. | record `docs/qa/runs/6a30b4c9/beam-trace-orb-1646.txt` (t=12120, 16625, 18516); `docs/design/pad-first-press.md:26`; `data/fight/ladder.json:13` | X-04, X-13 | major | required | controls-feel | S | no |
| F-COMBAT-10 | gap | A body that hits a building still bounces back; the settings that would hold it are one switch row held off waiting on a QA read. | `docs/tools/runs/6a30b4c9/switch-list.txt:60`; `data/biomes/brunt.json:47-50`; `data/director/launch.json:94-95`; `docs/ep/vision.md:1656`, `:1687` | X-13 | major | required | world-environment | M | yes |
| F-COMBAT-11 | gap | No tool measures X-03, X-04, X-13 or X-16, and X-17's trace tool has no count. | `qa/godot/beam_trace.gd:1-4`; `sim/director/tools/stance_check.gd:1-3`; `.github/workflows/ci.yml:221-405` | X-03, X-04, X-13, X-16, X-17 | major | required | qa-balance | M | no |
| F-COMBAT-12 | gap | Launches are not physics-based: the meteor is an authored curve and no attack has a force or any fighter a weight. | `sim/director/arc.gd:3`; `data/director/launch.json:110-131`; `docs/ep/vision.md:1650` | none | major | nice | game-design | XL | yes |
| F-COMBAT-13 | gap | Chaining hits on a flying foe is only the tap chase; the LT chase, a chain window after a knock-back and a midair flurry are off or absent. | `sim/director/chase_tap.gd:3-13`; `data/director/interrupts.json:653`; `data/director/launch.json:89`; `docs/ep/vision.md:1686` | none | major | nice | encounter-systems | M | yes |
| F-COMBAT-14 | gap | A live transformation blocks new exchanges but damage has no transformation guard, so "respected" is not proven for shots already in flight. | `sim/director/exchange.gd:961-968`; `sim/core/damage.gd` (grep: no guard); `reads/RR-02.md:105-106` | X-04 | minor | required | simulation-engine | S | yes |
| F-COMBAT-15 | gap | Backburnered systems still act in the director: menace adds to beam clash power, both meters steer a deflected beam, biome variants shape the signature's aftermath, and hiding code runs inert. | `sim/director/beam.gd:153`, `:208`, `:245`; `sim/director/beamplay.gd:508-513`; `sim/director/ai.gd:108-111`; `sim/director/exchange.gd:329-335` | X-15 | minor | nice | encounter-systems | S | yes |
| F-COMBAT-16 | gap | Only 5 of 65 director checks run in CI; the beam, stick, stance and brawl checks run only on a local stack that is not in the repository. | `.github/workflows/ci.yml:221`, `:229`, `:269`, `:403`, `:405`; `01-inventory/I-02-sim-director.md:12` | none | minor | required | tools-pipeline | M | no |
| F-COMBAT-17 | gap | Two planned-exchange templates have a single outcome, and all templates key on the retired four-stance states. | `data/combat/templates.json:161-166`, `:512-517`; `sim/director/data.gd:134` | none | minor | after | combat-choreography | S | yes |
| F-COMBAT-18 | gap | The mixed string's switch reads "on" in the played build but no game code reads its data file; the feature comes from parked files outside main. | `data/combat/mixed.json:4`; `docs/tools/runs/6a30b4c9/switch-list.txt:88`; `01-inventory/inventory.md:14` | none | minor | nice | combat-choreography | S | yes |
| F-COMBAT-19 | gap | Six of Orb's "workshop this" combat items have no decision: beam stages, the timed swat, the catch, what RT held does, the taunt before a signature, and whose stick moves whom up close. | `docs/ep/vision.md:1635-1642`, `:1694`, `:1707-1712` | X-13 | minor | required | game-design | S | no |
| F-COMBAT-20 | works | Each fighter has his own pools for all nine ways to press X, Y and B in the close fight. | `data/combat/recipes.json:307`, `:1878-1879`, `:3149`; `sim/director/brawl.gd:18-24` | X-03 | none | n/a | combat-choreography | n/a | no |
| F-COMBAT-21 | works | The stick beam is its own staged move, aimed by the stick, and a shot wider than the assist misses and carves; on in the played build. | `sim/director/beam_move.gd:5-17`; `sim/director/beam_aim.gd:5-9`; `docs/tools/runs/6a30b4c9/switch-list.txt:46` | X-16 | none | n/a | encounter-systems | n/a | no |
| F-COMBAT-22 | works | A player's B alone no longer starts a beam where the fix is on: six of slot 0's eight beams in Orb's last match came from RB and the stick. | `sim/director/brawl.gd:3178`; record `docs/qa/runs/6a30b4c9/README.md`; `docs/tools/runs/6a30b4c9/switch-list.txt:68` | X-17 | none | n/a | controls-feel | n/a | no |
| F-COMBAT-23 | works | A transformation starts only between exchanges and its full and short versions freeze the whole sim. | `sim/director/exchange.gd:948-959`; `sim/core/pause.gd:2-5`; `data/fight/pause.json` | X-04 | none | n/a | simulation-engine | n/a | no |
| F-COMBAT-24 | works | The energy row exists: bolts and volleys on RB + X, a charged shot on RB + Y, and the Driver on RB + B. | `sim/director/blast.gd:2-6`; `sim/director/driver.gd:3-4`; `docs/tools/runs/6a30b4c9/switch-list.txt:44` | X-03 | none | n/a | encounter-systems | n/a | no |
| F-COMBAT-25 | works | A launch now goes the way of the blow unless the stick picks the far side, behind a switch that is on in the played build. | `data/director/launch.json:4-5`; `docs/tools/runs/6a30b4c9/switch-list.txt:76` | X-13 | none | n/a | encounter-systems | n/a | no |
| F-COMBAT-26 | works | The tap chase after a launch is built and is checked in CI. | `sim/director/chase_tap.gd:3-13`; `.github/workflows/ci.yml:221` | X-13 | none | n/a | encounter-systems | n/a | no |

Owner notes: `data/combat/` has no "owns" line; Combat & Choreography's charter gives it the exchange templates (`docs/directors/combat-choreography.md:18-22`), so combat data findings go to combat-choreography. `data/fight/` and `data/input/` have none either; forms and the ladder are placed with game-design (the rules) and the input read with controls-feel (`sim/input/`). Cost bases: F-01 and F-08 are estimates with the gravity-well packet's "about 1M a session, 3 to 5 sessions an increment" as the nearest comparable (`gravity-well.html`, section 7); F-03 is that packet's own total (28M; increments 0, 3 and 4 alone are about 9M); F-04 rests on the variety packet's 13M for the stick's depth alone (`combat-variety-packet.html`, increment 2); the rest are "estimate, no comparable".

## Gaps the questions missed

1. **Main is not the game** (F-COMBAT-05). Of the switches this area depends on, at least 40 differ between main and the played build (read key by key from both trees: stances, the beam's own move, its aim and front, the struggle, the Driver, the grapple, flight strikes, the tap chase, the arc, the match ending, `bNoBeam`, and every stick refinement). An audit of "what exists" has two answers until those are landed or dropped.
2. **The player did not transform in a 5-minute match** (F-COMBAT-09). X-04 and X-13 both need it, and nothing on the pad says how.
3. **Measurement** (F-COMBAT-11). Five criteria, four missing tools.
4. **CI covers 5 of 65 director checks** (F-COMBAT-16). After a feature freeze the uncovered checks are what would catch a regression in a cell.
5. **A stale header:** `sim/director/stick.gd:5` says the right-stick switch is false; `data/input/timing.json:41` has it true.

## Not evidenced

| What | One measurement that would settle it |
| --- | --- |
| Every cell of the move table, per fighter, per way of pressing (RR-01 was not on file) | The moveset coverage probe: a scripted pad presses each of the 55 cells per fighter on the played build's data and lists the cue each produces |
| Whether tier 4 is reached in a normal 6 to 8 minute match, by a player and by the computer | A scripted match that takes each form when ready and logs the tick of each tier |
| Whether a shot in flight can hit a fighter during a live (unpaused) transformation | One scripted case: a bolt fired, then the target transforms with the pause bank empty |
| Whether the opposite-way launch is gone on 6a30b4c9 | `qa/godot/side-from-blow.js` rows on the played build's tree |
| Whether Orb's presses after a send reached a chase in the 16:46 match | A count of chase cues in `trace_replay.gd` on that file |
| How often a waiting stick beam fires after a new face press (QA offered it) | The one-line cue count in `docs/qa/runs/6a30b4c9/README.md`, item 3 |
| CI status on 8901d351 | `gh run list` returned nothing in this session |

## Decisions for Orb

1. **The move table's size.** Should Alpha's bar be every stance by every button by every way of pressing (55 cells a fighter), or the martial and energy rows complete with the LB, LT and RT rows shared between fighters? Recommendation: the second for Alpha, with RT + X, Y, A either given one special each or left as the plain blow and said so on the controls screen; the full table for Beta with four fighters.
2. **What RT held does.** Once signatures are RT + flick and RT + RB + flick, is RT held still the ki charge, or the "High Intensity" switch? Recommendation: keep the charge for Alpha and decide High Intensity with the energy and stamina page.
3. **Up close, whose body does your stick move?** Recommendation: answer before the gravity well is built, since every zone rule depends on it; the packet's default (the stick moves the pair in a brawl, pulls never beat a held stick) is the safe start.
4. **Physics-based launches in Alpha or after?** Recommendation: after; for Alpha only put a force per attack and a weight per fighter in data, which the energy, stamina and health page needs anyway.
5. **How much gravity well is enough for Alpha?** Recommendation: the well's size, zones and the snap (the packet's increments 0, 3 and 4, about 9M), with the far kit and the other collisions after.
