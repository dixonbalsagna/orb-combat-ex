# Recoil flips (parked, 2026-10-19)

Owner: Encounter Systems Director. Game Design's 2a (`docs/design/rulings-2026-10-19.md`; `fight-feel.md` §2), as `../../fight-feel.md` §1 has it built.
- **It sits behind `recoilFlip.enabled` (false)** in `data/director/interrupts.json`. Off, nothing runs, no slot is written and no cue is sent, so play and the golden don't move.
- **Built and read in scratch. Not applied.**

## To build it

`node rc.cjs <root>` from this folder, on main with the grapple G1 and launch anywhere. Then, with World's OK, `node grant_world.cjs <root>`.
- `rc.cjs` copies `files/sim/director/recoil.gd` (`DirRecoil`) and its `.uid`.
- Without the grant an upright slide and a drift flip, and a skid can't be cut short.
- `--check` reads every anchor and writes nothing; any other option is refused.
- No new golden.
- It composes with the camera-intent park and the balance park in any order.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/recoil.gd` | Encounter | New: `DirRecoil`. The window, the flip, the landing, the counter-rush, the AI's taps and presses, the `recoil` cue |
| `sim/director/launch.gd` | Encounter | `knock` opens the window: the skid, the upright slide, the drift |
| `sim/director/exchange.gd` | Encounter | `DirRecoil.tick` once a live tick; a press waits while he is in the air |
| `sim/director/bands.gd` | Encounter | The counter-rush: no crouch, no return, its own speed; from the far band it flies in; no far press while in the air |
| `sim/director/brawl.gd` | Encounter | `recoilFree`: the flip clears his first-move lock and his return |
| `sim/director/ai.gd` | Encounter | The AI's counter press |
| `data/director/interrupts.json` | Encounter | `recoilFlip` |
| `data/director/ai.json` | Encounter | `brawl.recoil` {flip, counter} for each level |
| `tools/schemas/director-interrupts.schema.json`, `director-ai.schema.json` | **Tools** | The same keys |
| `sim/world/contact.gd` | **World** (`grant_world.cjs`) | `recoilEnd`: the skid's journey ends where he is, the slide so far paid and recorded, `journey_end` kind `recoil`. `brakeEnd` takes the kind (default `brake`, so the air brake's call is unchanged) |

## The numbers (`recoilFlip`)

| Key | Value | Says |
| :--- | ---: | :--- |
| `windowTicks` | 10 | live ticks after a knock-back in which a dodge tap flips him (Game Design's) |
| `flipTicks` | 12 | the flip to his landing, set (Game Design's) |
| `flipBh`, `arcBh` | 1, 0.8 | how much further back, and how high it bows |
| `counterTicks` | 20 | after the landing, his next blow is a counter-rush (Game Design's 20, counted from the landing) |
| `counterRush` | 6,000 u/s, 3 to 12 ticks | its approach |
| `flourishOverBh` | 3 | with no press, a knock-back on the ground longer than this ends in the flourish (Game Design's) |
| `aiTapTicks`, `aiCounterTicks` | 3 to 7, 2 to 8 | when the AI taps, and when it presses its counter |
| `ai.json brawl.recoil` | flip 0.2 / 0.45 / 0.7; counter 0.5 / 0.7 / 0.9 | by level, easy to hard (flip shares Game Design's; counter shares mine) |

## What it read (main 09d465c0, in scratch)

- **Off:** the golden is main's, byte for byte, and the probe with the switch as the data has it counts nothing. The full gate list is 34 of 35 at 0. Its one red is anim_check's "a blow within reach ends 5.00 units short", the same as clean main. One gate list over all five parks together (camera intent, recoil flips, balance, interior aim and both World grants, on 5385a86d) reads the same.
- **Forced, each case** (`probes/rcu.gd`; a player knocked back on flat plains):

| Case | Result |
| :--- | :--- |
| The skid (6.5 bh), a tap at live tick 3 | flips. World's `journey_end` says `recoil`; he lands set 12 ticks later; X 2 ticks after is a counter-rush, a 4-tick approach with no crouch |
| The upright slide (3.5 bh), a tap at 3 | flips; counter-rush |
| A tap on the window's 10th live tick | flips (four hit-stop ticks inside the window don't count) |
| A tap on the 11th | nothing |
| No tap | the flourish's cue at the knock; he skids to the end of the journey (`journey_end feet`, then down) |

- **AI v AI, 10 matches to 3 min** (`probes/rcp.gd`): 12 knock-backs in 23.5 minutes of fight (9 drifts, 2 upright slides, 1 skid), and 7 flips (2 and 5 by fighter), each 5 to 8 ticks after its knock-back. Two counter-rushes followed, and 3 flourishes. **0.3 flips a minute, against QA's row of 2 to 6.** The flip works; the knock-backs that feed it are too few (next section).
- **The flourish's landing tick** is the knock-back's estimate. For a slide it is exact. For a skid it is World's journey that decides, 30 ticks sooner in the forced case (`journey_end feet` is the real landing).

## Why 2 to 6 a minute can't be met yet

Game Design's §2 counts on "a heavy that lands clean" knocking him back 1.5 bh, "as now". In the build a clean heavy staggers him in place, and the brawl goes on. So only the rarer knock-backs open a flip: a charged heavy short of full, the blast ender, a throw across, a planned exchange's, a mine's, a charged shot's. That makes 0.5 a minute AI v AI. To reach 2 to 6:
- **a clean heavy recoils him 1.5 bh** inside the brawl (the pull brings them back), which opens a flip;
- **2c's clashes** add their recoils (0.5, 1.5 and 3 bh).

Either is a ruling for Game Design. With the first, I would build the heavy's recoil behind this same switch.

## Probe (`probes/rcp.gd`, from a copy's root)

`rcp.gd -- <matches> <seed0> [--ticks=10800] [--off]`: AI v AI with the switch on in memory. It reads knock-backs by kind, flips by kind and by fighter, flips a minute (QA's row: 2 to 6), flourishes, counter-rushes, World's recoil journey ends, the ticks from knock-back to flip, and one sample flip with what followed. `--off` leaves the data's switch: nothing may count.
