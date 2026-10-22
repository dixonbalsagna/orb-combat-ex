# The wall kick (parked, 2026-10-22)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-22.md` 2b and `fight-feel.md` §3: the part that runs on the wall contact World has today, a sent body meeting a building's face that holds (`WorldBrunt.hit`, the wall slam).
- **It sits behind `wallKick.enabled` (false)** in `data/director/interrupts.json`. Off, nothing runs, no slot is written and no cue is sent, so play and the golden don't move.
- **Built and read in scratch. Not applied.**

## To build it

After the recoil-flip park and its World grant (its slots follow theirs, and it ends the journey with `brakeEnd`'s kind): `node wk.cjs <root>` from this folder, then, with World's OK, `node grant_world.cjs <root>`. `--check` reads every anchor and writes nothing. It composes with the 4c/4d, balance and interior-aim parks.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/wallkick.gd` | Encounter | New: `DirWallKick`. The arm, the AI's draw, `atWall`, the kick-off, the cue |
| `sim/director/exchange.gd` | Encounter | `DirWallKick.tick` once a live tick |
| `data/director/interrupts.json` | Encounter | `wallKick` |
| `data/director/ai.json` | Encounter | `wallKick` by level: 0.15, 0.35, 0.55 (Game Design's 2e) |
| `tools/schemas/director-interrupts.schema.json`, `director-ai.schema.json` | **Tools** | The same keys |
| `sim/world/brunt.gd` | **World** (`grant_world.cjs`) | In `hit`, at a face that holds: `DirWallKick.atWall` is asked before the fighter's damage. When the kick takes it, both parts of the slam's damage to him are halved, and there is no hold, no rebound and no stagger. His journey ends at the face (`journey_end` kind `kick`). The face takes its hit as ever |

## The rules as built

- **The arm.** A dodge tap in the last 4 live ticks before he meets the face. The AI kicks on its level's share, with one keyed draw a send. It taps 2 ticks out, never sooner than its reaction time after the send.
- **The line.** Only at 1,500 u/s or more into the face. Below it is Combat's plant, which is not built, so the wall slam plays as ever.
- **The kick-off,** at 0.6 of his arrival speed:
  - with the stick neutral, into the wall or toward the rival: a rush back to striking distance of him, 3 to 30 ticks, so he arrives to strike;
  - with it any other way: a push along it.
- **The after side.** A wall slam staggers him on contact, and a stagger drops every press. So "4 ticks either side" is the 4 before, until Game Design rules on the after side.
- **The cue:** `wall_kick`. `text` rush or push; `target` the rival; `x`, `y` where he leaves the face; `n` the tick he arrives (a rush); `dur` its ticks; `amount` his speed.

## What it read (main a3aac46d, in scratch)

| Read | Result |
| :--- | :--- |
| **Forced** (`probes/wkp.gd --mode=forced`): a player sent into a city tower's face at 1,800 force, meeting it at 1,730 u/s | Without the tap: the wall slam, 41.1 damage, stunned 55 ticks. With a tap 3 ticks out: the kick. **20.6 damage** (half), **no stun**, `journey_end kick`, and a rush back at 1,027 u/s |
| **AI v AI from a city start** (10 matches, 23.7 min) | 8 wall slams (1 and 7 by the fighter sent); **the AI kicked 3**, all rushes |

- **QA's row (1 to 4 wall kicks a match) can't be met yet.** Wall slams are rare: 8 in 24 minutes, even starting in the city. Combat's plant (the slower contacts) and Simulation's glance will add the rest.
- **Off** (a3aac46d, with the recoil flips and both World grants): the golden is main's, byte for byte, and the full gate list is 34 of 35. Its one red is anim_check's "a blow within reach ends 5.00 units short", the same as clean main. The anchors still check on 645386e1, where the recoil flips are on main.

## Probe (`probes/wkp.gd`, from a copy's root)

`wkp.gd -- <matches> <seed0> [--mode=forced|ai]`: the forced send with and without the tap, and AI v AI from a city start.
