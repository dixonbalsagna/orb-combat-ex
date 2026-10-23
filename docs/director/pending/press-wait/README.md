# A player's press: acknowledged and started on its tick, and waits at most a beat after an exchange (parked, 2026-10-23)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-22.md` 7a, the fix to press-tick (aa927bb5, whose opening-cooldown skip never ran), and Controls' tightened T1 (`docs/controls/pending/t1-7a/`). Only a player's fighter is written or acknowledged, so the AI v AI golden doesn't move.

## To build it

On main, after the mash run (`../mash-run/`: `DirPress`'s slot follows `DirMash`'s): `node pr2.cjs <root>` from this folder. `--check` reads every anchor and writes nothing. Land it with the tightened T1 over `sim/input/test/t1_latency_test.gd`. 7b (`../calm-7b/`) applies after it.

| File | Change |
| :--- | :--- |
| `sim/director/press.gd` (+ `.uid`) | New: `DirPress`. `held` is the cooldown as it holds a fighter: the AI, all of it; a player, not the match's opening one, and after an exchange at most `capTicks` 6 (`setPieceCapTicks` 12 after a set piece). Also `anyFree`, `onEnd`, `onCool`, `waitTicks`, and `_setPiece` (a signature's exchange, a finisher, a template tagged CLASH, a throw) |
| `sim/director/exchange.gd` | See the four changes below |
| `data/director/interrupts.json` (`press`), its schema (**Tools'**) | `capTicks` 6, `setPieceCapTicks` 12, `setPieceTags` ["CLASH"] |

The four changes in `sim/director/exchange.gd`:
- **`requestAttack` wraps the request with an acknowledgement.** A player's press gets `press_ack` "started" on its tick when it begins an exchange or an approach. It gets "queued" when it waits, with the tick it is due. None is sent when the brawl, the zip or the chase acknowledged it already, or when it was a blow on a running brawl's line.
- **`_drain` no longer goes back on a cooldown while a queued request is free of it.** It returned there before any request reached `_start`, which is why press-tick's opening skip never ran.
- **`_start` tests the cooldown with `DirPress.held`.**
- **`endEx` calls `DirPress.onEnd`.** The lost lock and a live form step call `DirPress.onCool`.

## What was proven (main 1d33277e plus mash-flow, the mash run and this, in scratch)

- **Controls' tightened T1** (62 checks: START, ACK, dodge and guard): **62 of 62.**
- **The mid-match press** (`probes/mid_match.gd`, Performance's bench through the real hub: the claim press at 1.5 s, the press at 9.5 s):
  - at 80 and 150 units the brawl starts, the body moves and `press_ack` "started" comes, all on the press tick;
  - at 250 units (the mid band) the sim starts on the press tick (the rush event, the lunge cue, the ack), and the body moves when the lunge's authored wind-up crouch ends: tick 6 for a light, 10 for a heavy.
  - Performance's mid-match 5 ticks are that crouch, with no anticipation pose drawn. That is Animation's pose to draw from the `lunge_*` cue (it carries the wind-up's ticks), or Game Design's `bands.lunge.windupTicks` to shorten.
- **A press inside the opening cooldown** (`probes/press_tick.gd --at=30`) starts the brawl or the approach on its tick, with the ack.
- **7a by reason** (`probes/press_wait.gd`, 10 matches, a scripted player against medium):
  - the cooldown holds a press at most 5 ticks after an exchange and 11 after a set piece, 0 ticks past the cap;
  - with `capTicks` -1 (as before), up to 32 ticks past.
- **The gate list: 35 of 35 at 0.** The golden's nine AI matches and all its hashes are byte-identical. **Its two human-input replays move** (their presses after an exchange now start at the cap), so regenerate them with this park.
