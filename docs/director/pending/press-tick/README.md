# A player's attack press reacts on its own tick (parked, 2026-10-22)

Owner: Encounter Systems Director. The fix for Performance's finding (`docs/perf/input-latency-2026-10-22.md`): a light took 5 ticks (83 ms) from press to sim reaction, about 135 ms to screen. Target: Controls' T1 test (`docs/controls/pending/t1-latency/t1_latency_test.gd`): a tap's sim reaction is on the same tick as the press.

## Where the 5 ticks came from

**Not the press path, and not an authored lead.** `SimCore.newMatch` sets the director's cooldown to 0.6 s (`S.dirS.cool = 0.6`, 36 live ticks). `DirExchange._start` holds every request while a cooldown runs, and nothing is shown while it waits.
- Performance's bench and Controls' test both press about 30 ticks into a fresh match, so every trial waited the cooldown's last 5 or 6 ticks.
- The probe (`probes/press_tick.gd`) presses 90 ticks in. There the director reacts on the press tick at 80, 150 and 250 units, for a light, a heavy and a signature:
  - in reach, the brawl's start, blow and rush events and the locked state;
  - at 250 units, the lunge cue and rush event, with the wind-up crouch before the move as designed.
- The input layer (hub and layout) passes the edge on the press tick.

The same silent wait hits any press made during a cooldown after an exchange: 0.25 to 0.6 s, after a planned exchange or a brawl's launch, break or finisher.

## What it changes (`node pr.cjs <root>`, on main; `--check` writes nothing)

Only a player's presses (`f.ai` null). The AI's are as before, so the AI v AI golden doesn't move. It sits behind `data/director/interrupts.json` `press`, on.

| File | Change |
| :--- | :--- |
| `sim/director/exchange.gd` | `_start`: with `skipOpenCool`, a player's request is not held by the match's opening cooldown while no exchange has started this match (the opening beat is the intro's). `requestAttack`: with `ackQueued`, a player's request still waiting after the drain is acknowledged on its press tick (below) |
| `data/director/interrupts.json`, `tools/schemas/director-interrupts.schema.json` (**Tools'**) | `press`: `skipOpenCool` true, `ackQueued` true |

**A cooldown after an exchange still holds the request**: that beat is the choreography's. Its commitment shows on the press tick instead: the cue `press_ack`, text `queued`, source the button's cell (x, y, b, which the HUD marks), `n` the tick it is due to start when the wait is a cooldown (else -1), `amount` the ticks to it, `target` the rival's slot. Animation can show the anticipation pose from it.

## What it read (HEAD 9cb5b6ba, in scratch)

- **Controls' T1** (copied to `sim/input/test/`): on main **24 of 38 failed**, every light, heavy and signature at tick 5. With the fix, **38 of 38**: the exchange or the approach starts on the press tick.
- **The gate list** (on, as it ships): **35 of 35 at 0** (npm, parity, validate and its self-test, both determinism runs, seam, anim, the three scans, cue, reads, HUD, brawl cases, the world checks, the input tests, QA's run-all, mash, the loader).
- **The golden moves in its two input replays only.** `replay 0` and `replay 1` are scripted player presses at a match's start; they now start at once and part from the second checkpoint. The nine AI v AI matches are byte-identical, as are tick0, wounds, rally, cripple, mood, keyed, the roster and fight hashes. **The golden needs a regen with this park.**
- With `skipOpenCool` false (and `ackQueued` on), by the code (not run): the golden would stay byte-identical, and T1 would still see the `press_ack` on the press tick. But the exchange would still wait out the opening cooldown: an acknowledgement, not the start.

## For the others

- **Controls:** T1 can move to `sim/input/test/` and into the gates with this park.
- **Animation:** `press_ack` `queued` is the anticipation's cue for a press that waits on a cooldown.
- **Performance:** the web bench (`latency-bench.mjs`) re-measure belongs on this park's build.
- **Simulation:** the opening cooldown in `SimCore.newMatch` stays; with this park only the AI waits it.
