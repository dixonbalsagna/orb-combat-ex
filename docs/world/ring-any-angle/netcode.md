# The fight's bearing changed at any time: what it does online (Netcode and Online, 2026-10-30)

For the EP, on Orb's ask. Research only: nothing here is built or prototyped.

## The answer
- **Any angle at any moment is fine online, if the ground is ready when the change lands.** Today's warmed swap already works that way, and removing the 10 degree cap adds no rollback problem.
- **Continuous change can't be a whole-ring swap.** One swap a tick overruns the frame from about a 120 ms ping, and one wrong prediction can freeze the game for a tenth of a second or more.
- **Continuous change needs a streamed ground:** the director decides now, the bearing takes effect 20 ticks later, and only a short stretch of columns is read each tick. That would make rollback's cost almost nil.

## How a change reaches rollback
Rollback predicts inputs, not decisions. A "predicted change" is a tick where the director, running on a guessed input, picked a bearing that the real input may not give. So:
- nothing extra goes over the wire, and replays still hold, as long as the bearing stays a director decision inside the sim;
- the only question is how much work a re-run throws away or repeats.

## Snapshot size
Measured on HEAD f19a3523, gen 2, planet 7:

| Ring | Snapshot | Of that, `S.epoch` | `S.base` (shared, not in the snapshot) |
| :--- | ---: | ---: | ---: |
| Half, 2,400 columns | 80 to 82 KB | 1.6 to 1.9 KB | 9.6 KB |
| Whole, 4,800 columns | 141 to 142 KB | 1.9 to 2.6 KB | 19.2 KB |

- **How often the bearing changes does not grow the snapshot.** A swap replaces `S.base` with a new array, and snapshots keep a reference to it.
- **What would grow:**
  - **A pending queue:** at most 20 entries, about 1.1 KB as one packed array.
  - **A streamed `S.base`:** it could no longer be shared, because writing a shared array in place is a desync. That adds one 9.6 or 19.2 KB block to each snapshot.
- **Never keep a bearing history in the state.** At one change a tick, a five-minute match is 18,000 entries, copied into every snapshot.
- **The memory that does grow is outside the snapshot.** Each swap keeps its ring and preparation for 21 ticks, at least 48 KB (Half) or 96 KB (Whole). At one swap a tick that is 1 to 2 MB, plus 123 to 167 new building records per swap.

## Resimulation cost
A rollback frame costs restore + (depth + 1) x (tick + save + change), against a 12.5 ms budget. These are estimates from published numbers (restore 0.3, save 0.2, planet tick 0.78, re-run swap 2 ms), with depths from the bots' p99 in `docs/net/rollback.md` section 5. The 2 ms is World's figure for a gen 1 Half ring, so the swap column is a floor.

| Ping (p99 depth) | No change: native, x4 | A swap every tick: native, x4 |
| :--- | ---: | ---: |
| 120 ms (3) | 4.2, 17 ms | 12.2, 49 ms |
| 200 ms (6) | 7.2, 29 ms | 21.2, 85 ms |
| far (13) | 14.0, 56 ms | 42.0, 168 ms |

Rollbacks come 14 to 19 times a second from an 80 ms ping up, so at one change a tick nearly every rollback crosses changes.

## Predicted, then rolled back
- **The same bearing again:** cheap, because the kept ring and preparation are found. Bots crossed this with the swap re-run up to 6 times a session, with the same gameplay state (section 13).
- **A different bearing, ring not yet read:** the read lands on the rollback frame. For gen 2 that is 122 to 137 ms for Half and 245 to 274 ms for Whole, before the preparation, and about four times that on an old laptop. **This is the case to design out.**
- **The picture:** Rendering's rebuild was 30.5 ms at x1 and about 150 ms at x4 (Performance, 2026-10-23). A flipped change would rebuild twice and could show the wrong ground for a few frames.
- **Pre-reading likely bearings can't fix a flip.** A ring depends on the pivot column as well as the bearing, and the pivot moves with the pair.

## Can heavy reads run off the sim's clock?
Yes. `WorldEpoch.readAhead` already does it between ticks, and the same state comes out whatever a host does. These rules must hold:
1. **The read is a pure function** of the planet seed and the ring.
2. **The state counts progress, and only the count decides when a ring is used.** "The read has finished" must never affect the sim, because peers finish at different times.
3. **If a read is behind when the sim needs it, the sim does the rest on that tick.** That costs a hitch, never a desync.
4. **Rollback never discards a read.** Key the cache by what was read (seed and ring). Today's key is `worldId/str(deg)`: the world id changes with each swap, and text from a float is a poor key for arbitrary angles.

**The limit is time, not safety.** The web build has no threads (`thread_support=false`), and on the current path online play in a browser would get only leftover frame time, which a rollback frame doesn't have. Native could use a worker thread, but `WorldPlanet`'s static caches aren't thread-safe, so a worker must own its job until hand-off. At the sim's own gen 2 rate of 12 columns a tick (about 0.65 ms), a new ring takes 3.3 s (Half) or 6.7 s (Whole). That is the top rate for whole-ring changes, unless reads get cheaper.

## What must be decided on confirmed input only
The sim can't ask "is this confirmed?", because peers have different answers at the same tick. **A fixed lead gives the same result.** `NetSession` never runs tick T until inputs through T - 20 are confirmed (`maxAhead`). So a change decided on tick D and taking effect on D + 20 or later is final before it first runs: re-runs always reach the same bearing, and the player never sees it flip. The cost is a third of a second between decision and ground.

| Must be final when it takes effect (use the lead) | Free to run on prediction |
| :--- | :--- |
| The bearing taking effect, and the ring it reads | The director's exchanges, beats and camera intent |
| Fresh places, and the people they hold | The pending queue itself (a few bytes, and a re-run replaces it) |
| The ground rebuild, far land and `arena_turn` presentation | Reading ahead, since a wasted read costs only time |

- **A warmed swap already has the lead.** Warming outlasts 20 ticks, so the ring is final. Only the swap's tick can flip, through calm and hold. Fix that tick at the decision and that flip goes too.
- **The lead must follow `maxAhead`.** Put it in the match setup, which the match key already compares, and have the host refuse a setup whose lead is below its `maxAhead`.
- **Never use as a decision input:** frontiers, ping, read progress or anything from the renderer.

## What each option needs
| Option | Rate | Netcode's work |
| :--- | :--- | :--- |
| **Any angle, warmed swap** | One per 3.3 to 6.7 s | The ring in the desync digest (`NetDesync.digest` doesn't read `S.epoch` today), then `PROTO` 4 |
| **Streamed ground with the lead** | Up to every tick | The same, plus: `S.base` out of `SNAPSHOT.share`; the lead in the setup; a test with a forced flip |
| **Whole-ring swap every tick** | Every tick | Refused: it fails the budget above |

- **The test:** a tests-only choreographer picks its bearing from a hash of recent inputs, so every misprediction flips it. It must pass `rollback_check` on lan, p120 and far, with a negative control where the bearing takes effect with no lead.
- **World owns the streamed design.** I've only said what rollback needs from it. `WorldLanes.build`, `buildIndex` and `bindStructures` work on whole arrays today, so they would have to become incremental as well.

## A bug to fix first (World's, read in the code, not run)
`WorldEpoch.cancel` drops the ring job at once. A rollback to before a cancel restores a state that counts the ring as read, and `_jobFor` then re-reads all of it on the rollback frame: up to 274 ms for a gen 2 Whole ring. W8 fixed this for the swap but not for cancel, and `choose` drops jobs the same way. The turn is off in the data, so nothing live is hit, but frequent changes would hit it often.

## What this rests on
- **Sizes** are measured.
- **Frame costs** are arithmetic. The machine was at 100% load throughout, so I took no timings.
- **Mixed machines:** the tick figure is from the cloud Xeon, the column and swap figures from Orb's PC.
- **No network run:** no ENet, and no run with a changing bearing.
