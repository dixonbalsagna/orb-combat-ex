# Flight strikes: Encounter's build plan (2026-11-07)

The EP's queue item 5, from `docs/design/playable-build.md` section 1 (the twelve moves, the take-back ruling, chaining and price, counters, and its data block). It builds on the zip (`sim/director/zip.gd`, `DirZip`) and on Simulation's `SimFighter.loopRush` and `loopApex` (on main). The take-back reads Controls' `dodgeHeld` intent bit (on main, `switches.dodgeHeld` off). **One switch:** `flightStrikes.enabled`, off. It goes in the zip's own data block as Game Design's JSON has it.

## What's there (DirZip)

- **The press:** `takes(S, A, kind)` (from `DirExchange.requestAttack`). LT held (stanceMask LT) in the band (`band.minBh`..`maxBh`), free to act, with the ki, starts `start(S, A, D, heavy, p)`.
- **The phases** (`PH`): 1 the tell (TELL ticks), 2 the way in (`_inTicks` with Legal's floor `_floor`: minTicks, `bhPerTick`), 3 in reach (the blow as a brawl strike beat with `zip`, via `DirBrawl.beginQuiet`; `RB` before and `RA` after), 4 the way out (`EXIT`: home, far or point; `PASS`: straight, over, round or under).
- **The take-back already in it:** `dodgeConvertTicks` (a face press soon after LT's dodge, not threatened, undoes the dodge).
- **The cues:** `zip_light` / `zip_heavy` at the start (text "zip"; target, amount the tell, n the way in, dur, x and y the reach ticks), then `zip_out` and `zip_end`. QA's flight arm counts slot 0's cues named by `--fscues` (default `zip_light,zip_heavy`).

## The build

1. **The path, read on the face press tick** (relative to the line to him, the left stick): under 0.5 is the zip; within 45° of toward is the line; within 45° of away is the parting shot; otherwise the upper half is the arc over and the lower half the arc under.
2. **The button:**
   - X: quick, tell 6, a medium's worth 2.5, medium hit-stop.
   - Y: heavy, tell 10, the zip heavy's 132, heavy hit-stop.
   - B: biggest, tell 14, a tapped B's stagger, never a send.
3. **Each path's way:**
   - zip: as today, home.
   - line: through him, the blow as he passes, ending 1.5 bh past on his other side (exit far, straight through).
   - arcs: `loopRush` with top 1.3 bh over his head, the blow at `loopApex`, ending behind him 0.5 bh up.
   - parting shot: in, the blow, out to 3 bh further than he started (at least 6, at most 12.5).
   - Travel: the tell, then the zip's floor (at least 4 ticks, at most 3 bh a tick). An arc's loop is about 24 ticks.
4. **The range:** contact to 12.5 bh (`zip.band.minBh` from 3 to 0). Past it, today's long strike.
5. **Price:** X 10, Y 15, B 20, plus up to 10 by distance from 3 to 12.5 bh. "No energy" refuses with the knock (`stick_refused`-style cue, source `ki`), and nothing starts.
6. **The take-back:** a face press 0 to 4 ticks after LT's press, with `dodgeHeld` at the face press, converts. The slip or dodge-cancel is undone, with its 15 ki and 3 s refunded. Button-first never converts. Same tick converts.
7. **Chains:** a press in the last 12 ticks or within 10 after starts the next as it ends, its tell halved (at least 4). Each link costs ×1.5 and is worth ×0.85 (never under 0.5). The same path and button a third time running gets a full tell.
8. **Counters:** a heavy within 6 ticks of the arrival, or a charged stick strike, stops it where it's reached: the striker takes ×1.25 and reels 8, never down. A guard blocks and the path completes. A perfect block is a reversal. A dodge makes it a miss, open 20.
9. **The cues for QA's flight arm and Animation:** the start cue keeps `zip_light` / `zip_heavy` and adds `zip_big` for B. **Its text is the path word:** `zip`, `line`, `over`, `under` or `parting` (Animation's loop tilt reads `over` / `under`). Its source is the button. Each link of a chain is its own start cue.
10. **The check:** `flight_strike_check.gd`, covering every path by bearing, each button's tell and worth, the price by distance, the take-back window, chains, the counters, and off unchanged.

## When it isn't read

- Knocked back or launched: nothing.
- Stunned, dazed, grabbed or in a clinch: refused, with the knock.
- Charging a beam or a stick strike, or in a struggle: not read.
- LB + LT: the vanish.
- Past 12.5 bh: today's long strike.
