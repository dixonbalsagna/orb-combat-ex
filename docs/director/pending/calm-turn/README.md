# The calm-moment turn, the director's part (parked, re-cut 2026-10-22)

Owner: Encounter Systems Director. `DirCalm`, wired to World's window 3 (`WorldEpoch`, `docs/world/scratch-build/calm-turn/calm-turn-window3.diff`, sha1 e41118069cea). It follows:
- my `../../calm-turn.md`;
- Game Design's `rulings-2026-10-19b.md` §1 with 1e, and `rulings-2026-10-22.md` 5a;
- the EP's rulings of 2026-10-22: no ring read on the swap tick; the warm budget 32 columns a tick; the warm inside the sim; a fallback ring only for a landing pick.

It sits behind `calmTurn.enabled` (false) in `data/director/interrupts.json`, and behind World's own switch. With either off nothing runs, and the golden doesn't move.

## To build it

On main plus World's window 3 (e41118069cea):
1. `node ct.cjs <root>` from this folder;
2. `node grant_sim.cjs <root>` (Simulation's YES, 2026-10-22).

`--check` reads every anchor and writes nothing. World's old grant (`grant_world.cjs`) is gone: World folded choose's tick and due and `cancel(S)` into window 3.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/calm.gd` (+ `.uid`) | Encounter | New: `DirCalm`. `atPause` and `atSend` (the asks), `pick`, `hold`, `why` (the hold's reason, for probes) |
| `sim/director/exchange.gd` | Encounter | `DirCalm.atPause` in `_transforms`, after the pause's request |
| `sim/director/melee.gd` | Encounter | `DirCalm.atSend` after the send |
| `data/director/interrupts.json`, `tools/schemas/director-interrupts.schema.json` (**Tools'**) | Encounter | `calmTurn` |
| `sim/core/sim.gd` | **Simulation** (`grant_sim.cjs`) | `WorldEpoch.tick(S, DirCalm.hold(S))` on a live tick, and `WorldEpoch.tick(S, false)` (warm only) on a pause's and a hit-stop's frozen ticks, so a form step's ring is read under its pause |

## The rules as built

**Two moments.**
- **A pausing form step** (full or short; a live one freezes nothing). The pivot is the pair's midpoint exactly as the pause starts; nothing moves under it, so one ring is warmed, and only a bearing that keeps the ground rule there is taken. Its moment is the first `formTicks` (30) live ticks after the pause.
- **A landing.** At a launch's send, the pivot is predicted, between the planner's rest point and the launcher, on the side the send went. A bearing that keeps the ground rule at the predicted spread plus `predictMargin` (1,500) is preferred; with none, the smallest. The chosen ring and World's smallest bearing's (2.5°, the fallback) are warmed. Its moment is a fighter at rest from a send within `landedTicks` (45), both down or set (under 60 u/s).

**The warm** is the sim's: World's tick reads k columns of each ring a tick, passed at `choose(S, i, k, fallbackDeg)`. k is the ring's columns over the ticks to the moment (Rendering's rule), inside the budget of `warmCols` 16 to `warmColsMax` 32 a tick shared by the rings:
- a landing's two rings: 8 to 16 each;
- a form step's one: 16 to 32.

A pause whose new ring would need more than 32 is not a moment for one. When the warm can't be done by the moment, the pick waits, warming, for a later one. A new send or pause keeps a waiting pick whose pair keeps its ground rule (its warm work kept), and otherwise cancels it and asks again.

**The ground rule** (5a, World's `moveMax`): the ground under each fighter moves at most 300 units (his distance from the pivot times the sine of the angle). The hold needs a read ring whose angle keeps it where they stand; World swaps to the largest such.

**The hold**, all at once:
- the warm read done;
- the ground rule;
- no exchange, approach, beam clash, taunt, flip or counter-rush, no waiting attack, no open finisher;
- a moment.

World then adds its own calm check and swaps.

**The pick.** Each place a candidate brings into view scores: a rival's home 5, a landmark 4, a city 3, his own home 2, a town 1. A tie goes to the smaller bearing.

## What it read (HEAD e2f5d2ea plus window 3 e41118069cea plus this park and the grant, in scratch; 6 AI matches each on planet 7, about 20 minutes)

| Ring | Turns | Per match | At | Most ground moved | Bad swaps, cold reads, refused |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Whole (4,800) | 3 | 1, 0, 1, 0, 0, 1 | 3 at a form pause (1 of them a landing's pick that waited) | 148 | 0, 0, 0 |
| Half (2,400) | 7 | 2, 1, 1, 1, 1, 1 | 3 at a landing, 4 at a form pause | 242 | 0, 0, 0 |
| Close (1,200) | 7 | 2, 1, 1, 1, 1, 1 | 1 at a landing, 6 at a form pause | 277 | 0, 0, 0 |

- **Game Design's 1 to 3 a match is met on the Half and Close rings.** The Whole ring gives 0.5 a match. Its landings can't be read in time: two rings of 4,800 at 16 a tick take 300 ticks, against a landing's 1 to 2 s. So only form pauses (a full pause: 4,800 at 27 a tick, 178 ticks) turn it.
- Levers for the Whole ring are the EP's and Game Design's: a larger budget, or a moment kind after a landing that lasts longer.
- **The gate list** (off, on that copy): 34 of 35 at 0, anim_check main's known red; the golden is main's, byte for byte. `node tools/validate.js` 0 errors, 0 warnings.
- **Off** (`calmTurn` as the data has it): no ask, no turn.

## Probe (`probes/ctp.gd`, from a copy's root, with window 3)

`ctp.gd -- <matches> <seed0> [--ticks=14400] [--cols=4800] [--off]`. It reads:
- asks and their k;
- turns by moment, with the bearing and the ground moved;
- the state at each swap (each condition must be none);
- whether a ring was read on the swap tick (cold, must be 0);
- World's waited and refused counts;
- why the hold was off.
