# The AI chases a launch it threw (parked, 2026-10-22)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-22.md` 5d and `fight-feel.md` §1 (the glide: the attacker can chase or zip). It sits behind `data/director/ai.json` `chase.enabled` (false). Off, nothing runs, no slot is written and no cue is sent, so play and the golden don't move.

## To build it

After the wall kick (`../wall-kick/`; its slots follow the kick's): `node ch.cjs <root>` from this folder. `--check` reads every anchor and writes nothing.

| File | Change |
| :--- | :--- |
| `sim/director/chase.gd` (+ `.uid`) | New: `DirChase.steer` (the draw, the start, the stick), `_sky`, the cue |
| `sim/director/ai.gd` | `DirChase.steer` before 4d's cap, which a chase lifts. Not in the Escape stance |
| `data/director/ai.json`, `tools/schemas/director-ai.schema.json` (**Tools'**) | `chase` {`enabled` false, `skyMul` 1.5, `maxTicks` 90}; each level's `chaseShare` (0.1, 0.25, 0.4) |

## The rules as built

- **At a send of its own** (the rival launched by it, not a set piece's), the AI draws once (keyed) against its level's `chaseShare`. The share is times `skyMul` when the send goes up into open sky: he rises faster than he travels, and no building stands over him.
- **Only with the zip's ki** (the zip strike's 20). It is a gate and is not paid: the chase is free flight, and a zip at the arrival pays as ever. This is my reading of "only with the zip's ki"; Game Design can rule otherwise.
- **The chase starts** no sooner than its reaction time after the send. It is dashed free flight straight at the sent body, with the approach cap of 4d lifted, while he is launched, at most `maxTicks` (90). It ends when he lands, when he is caught, or when the AI is not free.
- **The cue:** `chase`, text `start` or `end`, target the sent fighter's slot, n his launch number.

## What it read (main 372c327b plus the wall kick and this, in scratch; 10 AI matches a level)

| Level | Sends | Chases | A match | Of them on a sky send |
| :--- | :--- | :--- | :--- | :--- |
| Easy | 77 | 3 | 0.3 (0, 1) | 1 |
| Medium | 77 | 11 | **1.1** (0 to 3; 7 of 10 matches in QA's 1 to 4) | 5 |
| Hard | 127 | 31 | 3.1 (1 to 6) | 7 |

With `chase` off: none.

**The chase rarely catches.**
- The chaser's top speed is mostly 800 to 1,400 u/s, his dash, against a glide of about 1,500. So 7 of medium's 11 chases ran out at 90 ticks with the body still in flight.
- At the landing he is a median 4,000 units behind (1,100 to 11,500).

That is the open question for Game Design: chase at the glide's speed, for example by paying the zip's ki for it, or let it stay a gesture the camera rides.

**The gate list** (switches off, with the wall kick): 34 of 35 at 0, anim_check main's known red then. The golden is main's, byte for byte.

## Probe (`probes/chp.gd`, from a copy's root)

`chp.gd -- <matches> <seed0> [--level=easy|medium|hard] [--off]`. It reads:
- sends, chases, the sky share and chases a match;
- the chaser's top speed;
- the gap at the landing;
- how each chase ended.
