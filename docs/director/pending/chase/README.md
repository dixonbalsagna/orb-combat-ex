# The chase of a launch is the zip (parked, FROZEN for the break, 2026-10-22: built, NOT read)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-22.md` 7c (and 5d's shares) and `brawl-second-pass.md` §16 ("chasing your own launch": a zip at a launched rival that follows the body and lands a blow that sends him on, nudged by the stick). It sits behind `data/director/interrupts.json` `chase.enabled` (false). Off, nothing runs, no slot is written and no cue is sent.

## To build it

After the wall kick (`../wall-kick/`; its slots follow the kick's): `node ch.cjs <root>` from this folder. `--check` reads every anchor and writes nothing.

The whole chain on main is press-tick (on main), the mash run, 7a (`../press-wait/`), 7b (`../calm-7b/`), the wall kick and World's grant, then this. It composes and validates (245 files, 0 errors).

| File | Change |
| :--- | :--- |
| `sim/director/chase.gd` (+ `.uid`) | Rewritten for 7c: `DirChase.takes` (a player's press), `steer` (the AI's draw and start), `tick` (the rush re-aimed each live tick, the catch, the landing), `_catch` (the zip's blow and the send on), `_tilt`, `_sky` |
| `sim/director/exchange.gd` | `DirChase.takes` before the zip's in `requestAttack`; `DirChase.tick` after the wall kick's |
| `sim/director/ai.gd` | `DirChase.steer` before 4d's cap, which a chase doesn't meet. Not in the Escape stance |
| `data/director/interrupts.json` (`chase`), `data/director/ai.json` (each level's `chaseShare` 0.1, 0.25, 0.4), their schemas (**Tools'**) | `chase` {`enabled` false, `speedMul` 1.25, `minSpeed` 1900, `catchBh` 1.5, `sendForce` 1600, `skyMul` 1.5, `maxTicks` 120} |

## The rules as built

- **Who:** a player pressing X or Y with LT held while his own launch flies, or the AI at a send of its own on its level's `chaseShare`. The share is times `skyMul` for a send up into open sky, and the AI starts no sooner than its reaction time.
- **The price:** the zip's ki, the strike's 20 or the heavy's 30. Without it there is no chase.
- **The flight:** the director's rush at the body, re-aimed each live tick, at 1.25 times his speed and never under 1,900 u/s. **No Simulation lines.**
- **The catch:** within 1.5 bh of him while he flies, the zip's blow lands (26 for the strike, 132 for the heavy) and sends him on, through the launch planner from where he is, at `sendForce`, with the chaser's stick as its tilt. The chaser is free in the air and may chase again with the ki.
- **Too late:** when his landing comes before the catch, the chase flies to beside his landing and arrives with it, for the first move.

## Not proven

The probe (`probes/chp.gd`: the AI's catch share by level against QA's 60%, and a player's chase) and the gate list were queued and **didn't run** before the break. The 5d reads of the earlier build (a dash chase that rarely caught) are superseded.
