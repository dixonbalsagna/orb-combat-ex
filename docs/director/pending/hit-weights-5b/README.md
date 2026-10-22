# Hit weights re-cut for Game Design's 5b, and the whole-tick count (parked, 2026-10-22)

Owner: Encounter Systems Director. On top of main's hit weights (7a79d0e0) and Simulation's hitstop2 (`docs/architecture/pending/hitstop2`: Game Design's `rulings-2026-10-22.md` 5b table, the 18% rolling budget with its x0.75 second step, a stop of n ticks freezing n). Only while hit-stop by weight is on (`S.hitstopOn`; `data/fight/hitstop.json`, off): off, nothing is written and the golden doesn't move.

## To build it

On main plus hitstop2 (its `hitstop2.py` and Tools' `grant_tools.py`):
1. `node hw2.cjs <root>`;
2. `node stw.cjs <root>`. It refuses without hitstop2's `SimFx.stopTicks(stop, whole)`.

`--check` reads every anchor and writes nothing.

| File | Change |
| :--- | :--- |
| `sim/director/brawl.gd` | `weightOf`: a burst's light names `light_mash` (5b: "mash or burst light 2") |
| `sim/director/melee.gd` | New `weightOfClass(o)`: a planned strike's weight by its atom's class. A heavy or an ender is a heavy's, a mid a medium's (was a light's), an opener a light's. The launch after an ender holds its own stop at the send |
| `sim/director/exchange.gd` | The planned strike names `DirMelee.weightOfClass(a.o)` |
| `sim/director/windows.gd` (4c) | The freeze ahead and the held window's tick are counted whole (`stopTicks(stop, true)`): the core now freezes n, so the old count over-read by one for n of 3 or more |
| `sim/director/camintent.gd` | The launch cue's touchdown after the stop: whole with the switch on, as before with it off |

`brawl.gd`'s double hit (`ceil` of the stop in ticks) already counts n, the whole count, so it stays. With the switch off the core still freezes n + 1 for n of 3 or more, as it always has (the golden). Making the off path match would move the golden: that is the EP's call.

## What it read (main 84c772c1 plus hitstop2 plus this, in scratch; 10 AI matches of 3 minutes, 108,000 ticks)

Each frozen tick is put down to what froze it: a hit-stop, or a pausing set piece.

| | Hit-stop share of all ticks | Of live and hit-stop ticks | Pause share | 10 s blocks over 18% | Worst block | Longest stop |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| By weight on (5b table, hitstop2) | **20.2%** | 20.5% | 1.7% | 96 of 136 | 298 ticks | 30 |
| By weight off (the director's own stops) | 20.3% | 20.6% | 1.8% | 103 of 135 | 301 ticks | 31 |

The old cut on the old table froze 30% of all ticks, pauses (about 2%) included (2026-10-22's hit-weights read). With 5b, hit-stop by weight costs the same as the director's own stops.

**Game Design's 18% budget isn't met, and the table can't meet it as cut.**
- The mash and burst lights are the bulk: 7,996 brawl blows at 2 ticks in 10 matches, 14.8% of all ticks by themselves.
- The second step (x0.75, at least `cutFloor` 2) can't cut a stop already at 2.
- So when a mash runs, a 10 s block passes 18% whatever the rest do.

The levers are Game Design's and Simulation's:
- a cut floor of 1 for a mashed light over the budget;
- no stop at all for a mash's later blows;
- a budget that counts only stops of 3 or more.

**Gate list** (off, on that copy): 34 of 35 at 0, anim_check main's known red. The golden is main's, byte for byte. `node tools/validate.js` 0 errors, 0 warnings.

## Probe (`probes/hwp.gd`, from a copy's root, with hitstop2)

`hwp.gd -- <matches> <seed0> [--off] [--ticks=10800]`. It reads:
- the hit-stop, pause and other shares;
- 10 s blocks of live ticks whose hit-stop ticks pass 108 (18%), and the worst block;
- the longest stop;
- each damage event's stop by its ticks and form.
