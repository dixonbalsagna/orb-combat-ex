# A player's press waits at most a beat after an exchange (parked, FROZEN for the break, 2026-10-22)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-22.md` 7a, and the fix to press-tick (aa927bb5), whose opening-cooldown skip never ran. Only a player's fighter is written, so the AI v AI golden doesn't move.

## To build it

On main, after the mash run (`../mash-run/`: `DirPress`'s slot follows `DirMash`'s): `node pr2.cjs <root>` from this folder. `--check` reads every anchor and writes nothing. 7b (`../calm-7b/`) applies after it.

| File | Change |
| :--- | :--- |
| `sim/director/press.gd` (+ `.uid`) | New: `DirPress`. `held` (the cooldown as it holds a fighter: the AI, all of it; a player, not the match's opening one, and after an exchange at most `capTicks` 6, `setPieceCapTicks` 12 after a set piece), `anyFree`, `onEnd`, `onCool`, `waitTicks`, `_setPiece` (a signature's exchange, a finisher, a template tagged CLASH, a throw) |
| `sim/director/exchange.gd` | `endEx`: `DirPress.onEnd`. The lost lock and a live form step: `DirPress.onCool`. `_start`: the cooldown's test is `DirPress.held`. **`_drain` no longer goes back on a cooldown while a queued request is free of it**: it returned there before any request reached `_start`, so press-tick's opening skip never ran. The queued ack carries the capped due tick |
| `data/director/interrupts.json` (`press`), its schema (**Tools'**) | `capTicks` 6, `setPieceCapTicks` 12, `setPieceTags` ["CLASH"] |

## What was proven (main 44877a1c plus mash-flow, the mash run and this, in scratch)

- **A press at tick 30, inside the opening cooldown** (`probes/press_tick.gd --at=30`), starts on the press tick:
  - at 80 units, the brawl itself (brawl_start, the blow, the rush event; locked) for a light and a heavy;
  - at 250 units, the approach (the rush event, the lunge cue; the approach running).
- **7a by reason** (`probes/press_wait.gd`, 10 matches, a scripted player against medium):
  - the cooldown holds a press at most 5 ticks after an exchange and 11 after a set piece, 0 ticks past the cap, and nothing waits after the cap;
  - with `capTicks` -1 (as before), up to 32 ticks past.
  - What else holds a press after an exchange is positional (the rival in flight: 144 ticks).
- **Main's T1** (38 checks): 38 of 38.

## What was not proven

- **Controls' tightened T1** (`docs/controls/pending/t1-7a/`, 62 checks) read **24 failed: its 24 ACK rows.** A press that now starts at once gets no `press_ack`, since only a request that waits is acknowledged. Every START row passed. **The fix, for after the break:** a `press_ack` (`started`) on the press tick of every player's attack press, beside `queued` for one that waits.
- **The gate list** was stopped at its last gate (the loader) for Orb's break. All the gates before it passed on an earlier copy of this park (35 of 35, its two human replays moved). Re-gate after the ack fix.
- **The golden:** the two human-input replays move with this park (a player's later presses now start at the cap); the nine AI matches are byte-identical. Regen with it.
- **Performance's mid-match light** (about 9 s in, after a claim press, on aa927bb5: still 5 ticks late) isn't explained yet. To read after the break: what holds it (the cooldown this caps, or something else), with a mid-match case in T1 if it lacks one.
