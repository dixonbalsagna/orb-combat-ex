# The wall kick (parked, re-cut 2026-10-22 for Game Design's 5c)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-22.md` 2b and 5c (the after side), and `fight-feel.md` §3: the part that runs on the wall contact World has today, a sent body meeting a building's face that holds (`WorldBrunt.hit`, the wall slam).

It sits behind `wallKick.enabled` (false) in `data/director/interrupts.json`. Off, nothing runs, no slot is written and no cue is sent, so play and the golden don't move.

## To build it

On main (the recoil flips are on it; the kick's slots follow theirs):
1. `node wk.cjs <root>` from this folder;
2. `node grant_world.cjs <root>` (World's YES, 2026-10-22; unchanged by the re-cut).

`--check` reads every anchor and writes nothing. The AI chase (`../chase/`) applies after it.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/wallkick.gd` (+ `.uid`) | Encounter | New: `DirWallKick`. `tick` (the arming, the push's end, the windows), `atWall` (the kick), `pushing`, `due`, `rushBlow`, `aiPress`, `damageMul` |
| `sim/director/exchange.gd` | Encounter | `DirWallKick.tick` beside the recoil flips' tick. In `_start`, a press during the push waits |
| `sim/director/bands.gd` | Encounter | The rush blow is a counter-rush in `begin`. During the push no far press fires; a far press inside the rush-blow window flies in |
| `sim/director/ai.gd` | Encounter | The AI presses the rush blow |
| `data/director/interrupts.json`, `data/director/ai.json` and their schemas (**Tools'**) | Encounter | `wallKick`; the levels' `wallKick` share |
| `sim/world/brunt.gd` | **World** (`grant_world.cjs`) | An armed kick takes the contact: `damageMul` of the slam's damage, no hold, rebound or stagger; the journey ends at the face (`journey_end` kind `kick`) |

## The rules as built

- **The arming:** a dodge tap in the last `beforeTicks` (4) live ticks before he meets a face that holds. The AI arms on its level's `wallKick` share (15, 35, 55%), one keyed draw a send, never sooner than its reaction time after the send.
- **The contact** (into the face at `minIntoWall` 1,500 u/s or more; under it, Combat's plant, not built). The kick replaces the slam's stagger:
  - half the slam's damage (`damageMul` 0.5), no stagger;
  - the rival's first move after a wall slam (`brawl.firstMove`, 45 ticks) is void.
- **The push:** toward his stick at `keep` (0.6) of his arrival speed. With the stick neutral or into the face he goes straight off it; the AI pushes at the rival. It lasts `pushTicks` (8) live ticks, his presses waiting, and then he has control again in free flight at the push's speed.
- **Toward the rival** (within `towardDot` 0.5 of the way to him): his first blow within `rushBlowTicks` (20) of the push's start is a rush blow, as the recoil flip's counter-rush is: `recoilFlip.counterRush`'s speed, no crouch, no return, no first-move lock. The AI presses it on its level's `brawl.recoil.counter` share. **Into open air:** plain free flight.
- **The cue:** `wall_kick`, text `rush` (toward the rival) or `push`.

## What it read (main 372c327b plus this and World's grant, in scratch)

| Read | Result |
| :--- | :--- |
| A forced send into a city face at 1,730 u/s, no tap | The slam: 41.1 to 48.7 damage, stunned 55, the first move locked |
| With the tap | **20.6 damage, no stun.** Control back **7 live ticks** after the contact, at the push's 1,028 u/s. **The first move is not locked** |
| A light pressed at live tick 4 (in the push) or 12, the push toward the rival | **A rush blow** |
| Pressed at live tick 26, or pushed up into open air | No rush blow (free flight; the press is a plain blow) |
| AI v AI, 10 matches from the city | 9 wall slams, 2 kicks, no rush blow pressed. Walls are rare, so QA's row (1 to 4 a match) can't be read in AI play |

**The gate list** (switches off): 34 of 35 at 0, anim_check main's known red then. The golden is main's, byte for byte.

## Probe (`probes/wkp.gd`, from a copy's root)

`wkp.gd -- <matches> <seed0> [--mode=forced|ai]`. The forced mode reads presses and control back in live ticks: a scripted press on a frozen tick is lost.
