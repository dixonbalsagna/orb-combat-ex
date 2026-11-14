# Bystanders: the build (World, 2026-11-07; CD-05, docs/design/bystanders.md, Legal RL-257)

Game Design's page says what; this says in what order and who holds each line. Nobody dies, nobody is counted, no meter reads a person struck. One park, `docs/world/pending/bystanders/`, built in windows; it replaces `pending/no-casualty-feed/` (a subset: its menace and power lines are inside it).

## Status, 2026-11-08 (overnight)

Windows 1 and 2 are one park, built and proven: `docs/world/pending/bystanders/` (README there; runs in `docs/world/runs/c7b0414b/`). Pieces 1 to 4 and 6 of the table below are in it: the lived-in flag is `b.pop > 0` with the occupied rule, `mass0`, the budget and ceiling on structure mass, the meters read destruction, and the planner reads structure mass. Piece 5 (the counter's retirement from state and hash), the second Witness source, the HUD (UI), the drawing (Rendering) and QA's band stay open, listed in the README.

## What the sim does today (HEAD ea8dc190), by the numbers

- `WorldCollateral.kill` is the one place a person dies: 9 files, 20 call sites (structures, blast, brunt, tests). A 60 s budget by tier and a cumulative ceiling by highest tier decide how many of those die; the rest evacuate. `_feed` then pays menace, the villain's power (0.09), and every fighter's anguish by `casualties / pop0`.
- `S.world.casualties` (hashed) is read by: the K.O. feed line (damage.gd:150), the menace hold at the cap (fighter.gd:699), mood's casualty impulse (mood.gd:404), the HUD (`CIVILIANS LOST`, hud.gd:66; ui_sim_bridge.gd:127), the sky (sky_drive.gd:454), the Witness fill (forms.gd `casualty`, `anguishOther`), and the launch planner's `deaths > room` test (launch.gd:833; the planner reads people, which the guards forbid).
- The renderer's crowd drops the "rest, the casualties" (crowd_flight.gd, planet_view.gd:1710).

## The pieces

| # | Piece | Owner of the line | State |
| :--- | :--- | :--- | :--- |
| 1 | `kill` becomes `scatter`: nobody is removed; all people leave, run to a shelter (population is conserved); a hit or a fall flings them (`reason` "flung", keyed speed, bounces), a building's first damage empties it; `casualties` stays 0 | World (sim/world) | window 1 |
| 2 | The check: a hit on people never raises menace, power, anguish or Witness; negative control; CI line | World (builds it for Simulation) | window 1 |
| 3 | The lived-in flag, the structure-mass normaliser (`mass0`), the budget and ceiling on structure mass broken (room, isOver), the scatter radius from data (8 body heights), the district flight no longer waits for a budget | World | window 2 |
| 4 | Menace and anguish and Witness from destruction, craters, emptied buildings and combat trauma (section 3 and 4 of the page), numbers in `meters.json`, the loader, `mass0` in state and hash | Simulation (core); World hooks `fell`, `emptied` | window 2 (grant patch cut by World for review) |
| 5 | Retire the counter: `casualties` and `cbSum`/`cbBuckets`/`evtDead` out of state, hash, K.O. feed, mood, HUD, sky; the menace hold at the cap | Simulation (core), UI, Rendering | after 3 and 4 |
| 6 | The launch planner reads structure mass, not deaths (launch.gd:833) | Encounter | grant line from World, window 2 |
| 7 | The drawing: the run, the fling, the bounce, up within 3 s; the crowd keeps everyone | Rendering, Animation | reads `evacuate` with reason scatter/flung |
| 8 | The civilians-removed identity, the buildings-fallen band by tier, Witness's reach | QA | after 1 to 4 land |

Not in this park: far places' people (their anguish term, `farAnguish`, reads a death: it comes out with `casualties`; piece 5), the Cyborg rows (RL-027, RL-155) and the story lines (RL-147), which are Combat and Narrative.

## Interfaces (so Simulation can work beside me)

- World calls, from `WorldStructures.damageBuilding` and the brunt code: `WorldCollateral.scatter(S, bi, want, cause, evt, cx, floor_, how)` (people leave; returns how many ran), `WorldCollateral.emptied(S, b, cause)` once when a lived-in building takes its first damage, `WorldCollateral.fell(S, b, cause)` once when a building falls.
- Simulation reads, in `fell` and `emptied`, `cause.md` for the numbers (new fields from `meters.json`), applies the gain to the fighters, and owns `mass0`.
