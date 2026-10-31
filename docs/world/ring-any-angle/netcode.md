# A visible swing online: what the turntable does to rollback (Netcode and Online, 2026-10-31)

For the EP, on Orb's pick of the turntable (E and E2). Paper only: nothing was built or run. This replaces my page of 2026-10-30, which assumed a change nobody sees. What still holds from it is in "Carried over".

## The answer
- **A rollback across a swing can stay under budget.** The condition is that a re-simulated tick re-lays only the ground the sim reads, about 170 columns at most. Drawing the view is then done once per rendered frame, however deep the rollback.
- **A gradual swing doesn't need the 20-tick lead.** Its turn rate limits how wrong a prediction can get. A late correction looks like the world slowing or easing back a little, not a pop. Hard steps and cuts keep the lead.
- **A launch's ask doesn't have to come before the blow lands.** Take it on the blow or in the stop, and start moving on the first live tick (section 3).
- **Reduced motion as a setup value works,** once a lobby agrees the value before the match key is made (section 3).
- **I prefer the narrow sim strip with coarse far ground.** Re-laying the whole view fails the budget at a 200 ms ping, and a true 2D sim is far more work than a swing needs.

Revised the same day for Game Design's rulings (`game-design.md`): peak rates up to 60°/s, a moving pivot, reduced motion.

## 1. What a swing's state is
**Thirteen numbers, about 104 bytes, kept as one packed block:**

| Numbers | What |
| :--- | :--- |
| 6 | The frame: the pair's point on the planet and the heading |
| 3 | The swing: the angle left to turn, how far through its ease it is, and its cause's peak rate |
| 2 | The pivot: which way it is leaning (a standing fighter or the midpoint), and how far through its 20-tick ease |
| 2 | The planet store of marks: its length and a running hash |

The rate actually turned each tick comes from these and the fighters' positions (`min(cause's rate, sweep limit / distance)`), so it needs no number of its own.

**In the snapshot**
- **The swing's cost in size is nil.** These numbers replace the epoch's ring, and a swing never grows them. No history is kept.
- **The ground drops out of the state.** It becomes a pure function of the frame and the store, drawn from a node cache outside the state. `S.base` no longer has to be copied or shared.
- **The snapshot could shrink.** On a Whole ring it is 141 to 142 KB today (measured at f19a3523), and `deform`, `rubble`, `scorch` and `crack` are 76.8 KB of that. If those become store records, as Research proposes, a snapshot holds only the log's length and a rollback truncates the log.
- **Anything that changes every tick stays in the state.** A log only works for records that never change after they are written. `S.water`, and any mark that fades or burns, stay as they are unless World finds another way.

**In the digest**
- `NetDesync.digest` adds the thirteen numbers, plus the ground height under each fighter, read through the same cache the sim uses. That second part catches a wrong node on one peer at the next checkpoint. It needs a `PROTO` bump when built.
- `S.base` can't be hashed once it is derived. Simulation's running hash of what is read doesn't work either, because peers read nodes at different times. So a test sweep samples columns through the field instead.

**Three traps**
- **The log is shared by snapshots.** The AI driver runs on a snapshot copy, so a write there mustn't reach the live log. Two sims in one process each need their own.
- **Node values must never depend on the bearing,** which the cube-sphere key already gives. That is what makes the cache safe across a rollback: Research's 90 rollbacks re-read nothing (JS only).
- **Eviction from the cache must only cost time.** A node read again gives the same value.

## 2. Can a rollback across a swing stay under budget?
**Yes, if view and sim are separated.** There are two kinds of derived work, and only one is paid per re-simulated tick:

| Work | Paid | Depends on rollback depth? |
| :--- | :--- | :--- |
| The ground the sim reads | Each tick, including re-runs | **Yes** |
| The ground the view draws | Once a rendered frame | **No** |
| First reads of nodes | Once ever, until evicted | No, they are cached |

A re-run can't skip the first kind, because it must see the same ground as the straight run. So the number of columns the sim re-lays per tick decides everything.

A rollback frame costs restore + (depth + 1) x (tick + save + re-lay), against 12.5 ms. The inputs are published figures (restore 0.3, save 0.2, planet tick 0.78). Re-lay is Research's estimate of 1.7 to 3 ms for the view's 669 columns, which they mark as unmeasured.

| Ping (p99 depth) | No swing | Sim re-lays the view, 669 columns | Sim re-lays 170 columns |
| :--- | ---: | ---: | ---: |
| 120 ms (3) | 4.2 ms | 11.0 to 16.2 ms | 5.9 to 7.3 ms |
| 200 ms (6) | 7.2 ms | **19.1 to 28.2 ms** | 10.2 to 12.6 ms |
| far (13) | 14.0 ms | **37.8 to 56.0 ms** | 20.0 to 24.8 ms |

- **The limit is about 170 to 300 columns** (5,400 to 9,800 units) at a 200 ms ping. If re-lay costs three times the estimate, it falls to about 60 to 100.
- **The far profile is already over budget with no swing,** so the swing doesn't change the answer there: input delay does.
- **An old laptop costs about four times these.** As today, it needs an input delay near the one-way time, which makes rollbacks shallower.
- **Buildings aren't in these numbers.** Their `x` and index must follow the frame while it turns. The prototype doesn't model them, so this is the largest unknown in the re-lay cost.
- **The view's cost is Performance's limit, not rollback's.** Its limit is 0.5 to 1 ms a frame, and 1.7 to 3 ms of re-lay misses that. If the view's near ground is a 2D height texture and the heading is a shader value, a turn uploads nothing and a correction is one number. Rendering would need to confirm that on the Compatibility renderer.

## 3. Is the 20-tick lead still needed?
**Not for a gradual swing.** The lead existed for two reasons, and a field removes both:
- **Cost:** a flip used to land a whole ring read on the rollback frame. Nodes don't depend on the bearing, so with the disc round the pair read ahead, a flip needs no reads.
- **The picture:** a flip used to rebuild the world. A swing's error is capped by its rate, and it corrects like any other motion.

Keeping the lead would also delay every swing by a third of a second, for no gain.

**What a late correction looks like.** At a launch's peak of 60° a second (1° a tick), a wrong prediction leaves the heading off by the amounts below. Game Design's 20-tick ease applies to every decision to start or stop, assumed linear here, so the eased column is the usual case. The instant column is the bound, for a rate that changes with no ease, such as a mispredicted landing clamping it. Ground shift is sideways on the planet, not on the screen. The view's edge is 10,688 units out.

| Depth | Off, eased decision | Shift at 1,000 u, at the edge | Off, instant change | Shift at 1,000 u, at the edge |
| :--- | ---: | ---: | ---: | ---: |
| 3 | 0.23° | 4 u, 42 u | 3° | 52 u, 559 u |
| 6 | 0.9° | 16 u, 168 u | 6° | 105 u, 1,117 u |
| 13 | 4.2° | 74 u, 787 u | 13° | 225 u, 2,404 u |
| 20 (`maxAhead`, the worst possible) | 10° | 174 u, 1,856 u | 20° | 342 u, 3,655 u |

A prediction that swung the opposite way doubles the eased column. A brawl's 10° a second is a sixth of these, and reduced motion halves them.

- **How to show it.** The renderer keeps its own displayed heading and moves it toward the sim's, no faster than the cause's peak rate. It only reads the sim. A 3° correction then takes 3 ticks and reads as the world hesitating or easing back. There's no dissolve or fade, and it follows Orb's rule of easing camera moves.
- **Keep the ease-in.** A swing's start is the likeliest thing to flip, and the ease makes its first ticks almost nothing. It costs nothing on screen, because the swing is visibly under way within about a third of a second.
- **Feet.** A standing fighter is safe by Game Design's rules: he is the pivot, or his ground moves at most 75 units a second, so even a 13-tick correction is about 16 units under him. An airborne one has no ground to float over. The view near the pair should still draw the sim's own nodes and heading: a 512-unit node is up to 60 units off on gen 1 ground, and a fighter is about 75 tall. Gen 2 may be worse.
- **The worst case.** An instant change at far depth is 13° and will be visible, as the world swinging back for about a fifth of a second. It should be rare, and only that profile reaches it.

**A launch's ask and its stop.** The ask doesn't have to come before the blow lands, and earlier would be worse: a blow that hasn't landed is exactly what a rollback can take away, so that ask would flip more often, and it could leave a swing with no launch. Take it on the blow or during the stop, and start moving on the first live tick.

The stop then works as a free partial lead. A frozen tick moves nothing and takes no input, and the peer's confirmed inputs keep arriving, so by the first moved tick the blow is final whenever the rollback depth is within the stop:

| Depth | Heading off at the depth, no stop | Stop of 12 (a launch; a full one is 14) | Stop cut to 6 (the freeze budget's deepest cut) |
| :--- | ---: | ---: | ---: |
| 3 (120 ms) | 0.23° | 0 | 0 |
| 6 (200 ms) | 0.9° | 0 | 0 |
| 13 (far) | 4.2° | Under 0.01° | 1.2° |
| 20 (the worst possible) | 10° | 1.6° | 4.9° |

Nothing depends on this: a stop shorter than the rollback only means a small eased correction. That matters because `data/fight/hitstop.json` has `enabled: false`, so these stops apply only with hit-stop by weight switched on. The swing must also freeze on frozen ticks, which Game Design already rules.

**Reduced motion as a setup value: confirmed, with these conditions.** A fixed value in the setup needs nothing per tick, adds nothing to the state or the digest, lowers the error bound above, and is written into every replay. The match key holds the setup, so peers on different values are refused rather than desynced.
1. **Agree it before the key is made.** The setup doesn't go over the wire and the handshake only compares keys, so each player's setting must cross in the lobby and both must build the same setup from it. No game code starts an online match yet, so this goes on the list for the future online host, beside `aiLevel`.
2. **Always name it, as a yes or no.** Use a flag such as `"swingReduced": true`, with the multiplier in data, so no float formatting reaches the key. The setup without it means full rates, which keeps the golden. Always read it fresh at `newMatch`: `aiLevel` shows the trap, a static applied only when the key is present keeps the last match's value.
3. **It is fixed for the match.** A player who changes the setting mid-match gets it next match, because the sim's rate can't change on one peer. A setting that only affects the renderer, like Reduce flashing, stays each player's own.

**Two limits to know about:**
- **Spectators and replays play at the recorded rate.** Changing it would change the fight. A viewer who needs reduced motion gets no help from this value, so Accessibility may want a render-side answer for them.
- **Choosing the lower setting shows the other player that someone turned it on,** as slower swings. It seems harmless, but it is Orb's call as a disclosure of an accessibility setting.

A test sits beside `transport_check`'s level keys: two peers with different values are refused, and two with the same value agree.

**What keeps the lead**
- A hard step or a cut at a whip: anything instant has no rate to bound it.
- Any world change that can't be derived and undone by a re-run, if World adds one.

**What stays as it is**
- One-shot presentation (voice, a shake, a banner) still waits for its tick to be confirmed (`docs/net/rollback.md` section 4).
- Nothing in the sim may read frontiers, ping, read progress or the renderer.
- The swing stays a director decision, so nothing new goes over the wire and replays hold.

**A rule to enforce.** Turn rate x `maxAhead` is the largest error possible. Keep that rate in data, which the match key already covers, and have a data test check that the product stays within a limit. At Game Design's 60° a second it is 20°, 10° with reduced motion. Orb and Game Design can judge that in the prototype.

## 4. Which shape
| | Strip re-laid | **Narrow sim strip, coarse far ground** | True 2D sim |
| :--- | :--- | :--- | :--- |
| **Rollback** | Fails at 200 ms if it covers the view | **Fits at 200 ms** | Fits: point reads only |
| **Snapshot** | About +19 KB (`S.base` copied) | Can shrink | Can shrink most |
| **Bearing flip** | Re-lays again, no reads | No reads | No reads |
| **Far readers** | Stale outside the view | Get coarse ground, audit needed | Rewritten |
| **Wrap math, `x`** | Kept | **Kept** | All 1,335 sites go |
| **Risk to determinism gates** | Low | Medium: a far-reader audit | High: golden, parity and every net check start again |
| **Fighters** | On the band | **On the band** | Off the line unless constrained |

**My preference is the narrow strip, for three reasons:**
1. **It is the only strip that fits the budget.** A strip that re-lays only what the sim reads, and leaves drawing to the view, is this shape. The first shape can't get there by skipping work on re-runs.
2. **It keeps what the fight relies on.** `x`, `sdx`, the shared band and attacks closing the gap all stay.
3. **It leaves the door open.** The frame, the store and the node cache are what a 2D sim would need too. Orb asked for the world to swing round the fighters, not for fighters to leave the line.

**Its cost:**
- Every far reader must accept coarse ground that a later swing may change (469 ground reads and 170 `S.base` reads, unaudited). That audit is the real work, and it belongs to Simulation, World and Encounter.
- The strip's exact width is World's call, within the column limit above.

## What I'd build, when briefed
- The thirteen numbers and the two heights in the digest, then `PROTO` bump.
- The reduced-motion key test.
- The AI driver's copy made safe with the shared log.
- A forced-flip test: a tests-only choreographer picks its direction from a hash of recent inputs. It runs on lan, p120 and far, and the heading's largest error must stay within the rate rule. The negative control lifts the rate cap and must break the bound.

## Carried over from 2026-10-30
- **Read off the sim's clock: yes.** With a pure field it is simpler than before: a node has one value whenever it is read. If the sim needs a node not yet read, it reads it on that tick: a hitch, never a desync. The web build has no threads, so it reads in leftover frame time, and a rollback frame has none. That is why the disc must already be resident.
- **The job-cache bug in `WorldEpoch`:** `cancel` and `choose` drop ring jobs that a rollback then needs. Simulation measured 130 ms on a Half ring. It only matters if the swap stays in use, as a fallback or for campaign turns.
- **The ribbon (D3), if it comes back as the fallback,** keeps the lead, since its bends must be final before columns are laid.

## What this rests on
- **Measured:** the snapshot sizes, at f19a3523.
- **Arithmetic:** every frame cost, from figures taken on mixed machines. The re-lay cost is the weak one: it comes from Research's estimate, whose speed factor was measured on noise code, not arrays.
- **Not run:** no swing has run under rollback in GDScript, and no ENet run was made. Research's 90 rollbacks are JS, in a keep, run, restore loop.
- **A judgement, not a test:** whether a correction reads as easing back. It should be tried in the prototype with forced flips.
