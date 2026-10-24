# Hit-stop that holds one body (Game Design's E102): what the core would take

Owner: Simulation and Engine. 2026-10-23, paper only, on the EP's brief (`docs/design/energy-overhaul.md` E102 and E103). Nothing is built.

## The rule, and why it is new

**E102:**
- At range, a hit holds only the body that was struck. The shooter is never frozen, so his stream or beam keeps flowing.
- In reach, the brawl's rule stands: both freeze.
- The table gives each energy hit its ticks and who it holds (a lob 4, 6 or 8; the heavy blast 8; a beam's end 6 or 10, its level-3 carry 14; mines 3, 5 or 8; a grab's catch 5, both; a struggle's end 20, both; the KO 24, both).

**Today every hit-stop is the whole sim's** (`S.dirS.stop`): `SimCore.step` returns at its top, so both bodies, every shot, the director and the clock (`S.T`) hold together, and the budget counts those frozen ticks. "Both" in E102's table is exactly that and stays as it is. **"The one hit" is new:** one body held while the clock, the other body, the shots and the world run on.

## What it would take

| Piece | What | Whose files |
| :--- | :--- | :--- |
| **The weights and who they hold** | `data/fight/hitstop.json` gains E102's energy weights (with their ticks), each with `holds`: one or both. A `reach` sets in-reach as both: the brawl's distance, Encounter's number, read into the core's data | Mine; Tools' schema |
| **A body's hold** | `f.holdT`, a whole number of ticks, merged by the longer and never added, as stops are. Hashed only while hit-stop by weight is on, so the golden does not move | Mine (`state.gd`, `hash.gd`, `hitstop.gd`, `damage.gd`) |
| **Who the hit holds** | `SimHitstop.forHit` returns the ticks and who. "Both", or anything in reach, is today's `S.dirS.stop`; "one" at range is the struck body's `holdT` | Mine |
| **The step** | A held body skips its control and its `stepFighter` (motion, the launch's curve, the brake, ki), and its `holdT` counts down; everything else steps. The systems that advance by their calls pause with him for free: the curve's paced leg, the slide, the brake window | Mine (`sim.gd`) |
| **His clock-stamped windows** | The catch. Much of a fighter's timing is stamped on the shared clock, not counted by calls: a rush's end (`r.end`), `hurtT`, `breathT`, the wounds' overtime, and the director's windows in 16 of Encounter's files. While he is held the clock runs on, so those windows run out under him. Three ways, below | Mine and Encounter's |
| **Shots** | The bolt, lob, blast and mines name their weights. Today they deal damage through `SimDamage.hurt` with no stop, so they gain one through the same door as a blow's | Mine (`shots.gd`) |
| **The beam's end and carry** | Name `beam_1`, `beam_2` and `beam_3` | Encounter's (`sim/director/beam.gd`) |
| **Input** | A held player's presses must be kept for his first free tick, as a whole-sim stop keeps them today. But the host's `hub.consumed()` runs on every live tick, for every slot. It needs the slots held this tick (the sim says, from `holdT`) and a consumed that passes them over | Controls' (`sim/input/hub.gd`) and Rendering's host |
| **The views** | The damage event names `hold` and `holds`. Animation holds and shakes the one body; Camera and VFX must not freeze at range | Animation, Camera, VFX |

## His clock-stamped windows: three ways

1. **Pin, and let the clock run (the smallest).** He is held in place, takes no input and his calls pause, but his stamped windows elapse. Holds at range are short (3 to 14 ticks, a quarter of a second at most), but a rush cut short under a lob, or a cooldown that ends while he is pinned, is a real change of play.
2. **Shift his motion windows at the release (recommended).** As (1), and when his hold ends every stamp that drives his motion moves on by the ticks he was held. That is a rush's end and its recoil's in the core, plus whatever Encounter's windows Encounter names. It needs a list of those fields, kept as fields are added.
3. **A body's own clock.** Each fighter keeps `f.T`, advanced only while he is free, and his timers read it. That is the cleanest in principle, but it is a rewrite of every stamp in 16 director files and the core, with a golden regeneration.

## Questions for Game Design

1. **The budget (E103).** Does a one-body hold count toward the 18% and the 40% blocks? The budget guards against the screen freezing, and a one-body hold freezes one figure, not the screen. I would count it at half, or not at all.
2. **A stream that keeps landing.** A held body that is hit again has his hold merged by the longer, so mines, lobs or a stream could pin him over and over. Give him a guard after a hold (say 6 free ticks before another hold can start), or a share of a window he can be held for?
3. **"A bolt at range: 0, with a 4-tick reel."** Is the reel a hit-stop (a hold of 4) or a reaction (a 4-tick stagger in which he still moves)? If a reaction, it is Encounter's and Animation's, not the core's.
4. **In reach.** Is "in reach" the brawl's engage distance (Encounter's), or a number of its own?

## The cost, roughly

- **The core:** about 200 lines (hold, step, shots' weights, the stamps' shift) and a parity check:
  - the shooter's stream advances while the struck body stays put;
  - in reach, both freeze;
  - a hold merges and never adds;
  - the budget's count;
  - a replay;
  - the golden unchanged with hit-stop by weight off.
- **Plus lines from others:** Encounter (the beam's weights, the windows to shift), Controls (input by slot), Animation (the held pose) and Tools (the schema).

It can be built behind the hit-stop switch, which is off, once Game Design answers the four questions.
