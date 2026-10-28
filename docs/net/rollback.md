# Rollback netcode: the core

Owner: Netcode and Online. 2026-10-28, cloud briefs `docs/ep/cloud-briefs/netcode-rollback.md` (sections 1 to 6), `netcode-desync-spectate.md` (sections 7 to 9) and `netcode-transport.md` (section 11). Code: `net/`. The session runs over a transport interface: simulated links in one process (the loopback), or ENet between two processes. WebRTC for the browser is designed, not built (section 11).

## 1. The model

Peer-to-peer rollback on the deterministic sim (GGPO's model). Each peer runs the whole match. Only intents cross the wire, never state.

- **Input delay.** The intent a player gives on frame `f` is applied at tick `f + delay` (default 2 ticks, 33 ms). Ticks below `delay` are neutral for every slot, so both peers start with the same confirmed inputs. On a link whose one-way time is at most the delay, inputs always arrive before they are needed, and nothing is ever predicted or rolled back.
- **Prediction.** A tick whose remote input has not arrived runs on a prediction: that slot's last confirmed input with its edge fields cleared (`NetSession.EDGE_MASK`: attack presses, dodge, guard press, power press and tap, upgrade, special, context, transform, the legacy stance press, escape, waited). A held stick, guard, sprint, power, mode or stance mask carries on. A press does not repeat, because a repeated light attack would be wrong far more often than a missing one.
- **History.** Per slot, the session keeps the confirmed inputs by tick (`inputs`) and the input each tick last ran with (`used`). A confirmed input is final. A used input is a guess until its tick is confirmed.
- **Snapshots.** Before a tick that runs on a prediction, the session saves the whole state (`NetSnapshot`, section 3), at most one save every `saveEvery` ticks (1 by default).
- **Rollback.** An input that arrives for a tick already run, and differs from what that tick used, rolls the state back to the newest save at or before that tick. The session then runs every tick again up to the present, with the corrected inputs and fresh predictions. Several late inputs in one frame cost one rollback, to the earliest of them.
- **Confirmation.** The confirmed frontier is the first tick still missing any slot's input. A save older than the newest one at or before the frontier can never be needed again, and is dropped into a pool that the next save writes into. A tick whose inputs are all confirmed, after ticks that all were, is final. `onConfirmed` reports it with its state and its output digest.
- **Waiting.** A session that is `maxAhead` ticks (20) past the confirmed frontier waits rather than predict further. On every profile tested up to a 400 ms ping, it never had to.
- **Packets.** Each frame a peer sends every input the other has not acknowledged (at most 64), plus its own acknowledgement. A lost packet costs a frame, not an input. Packets may arrive out of order. The wire form of an intent is `SimIntent.pack()`, one integer of 53 bits, the same record a replay stores.

The sim is not touched. `NetSession` drives `SimCore.step(S, inputs)` exactly as a local host does. It drains `S.out` after each tick into a per-tick digest, so a host can show the newest tick's output while it is still a guess.

## 2. The determinism contract (what rollback needs from the sim)

The existing determinism rules (`docs/architecture/determinism.md`) stay in force, and the parity gate and the web parity check enforce them: seeded `SimRng` only, our own trig, binary64, no clock, fixed step. Rollback adds the following.

1. **The state is closed.** Everything a later tick reads lives in the object graph reachable from `S`, as script variables. A static that gameplay writes during a tick would survive a restore and break rollback. The per-match statics that `step()` rebinds from `S` (`SimConst` arena, `WorldBiomes` columns, `WorldClimate.curGen`) are derived from `S`, so they are safe. Planet-match caches (`WorldEpoch._plans`, `_jobs`) are untested here (section 10).
2. **`step(S, inputs)` is a pure function of `S` and `inputs`.** `S.out` is write-only output.
3. **References stay inside the graph.** An object field points at an object of the same state (a fighter, an exchange, a clash), or at immutable data: `FighterData`'s `WoundsDef`, `MetersDef` and `LadderDef`, and `SimForms.FormsDef`, which a snapshot shares instead of copying.
4. **No container is reachable by two paths.** An `Array`, a `Dictionary` or a packed array held in two fields is one value live but two values after a copy. In Godot 4, a packed array assigned to a second field is the same buffer, not a copy. `NetSnapshot.aliasAudit` checks this, and the check runs it at the start, middle and end of every straight run. It finds no sharing today.
5. **No Callables, Nodes or Resources in the state.** A copy would share them.
6. **New fields need nothing from netcode.** The snapshot copies every script variable of every class it meets. The typed copier is generated from the classes' property lists at run time (section 3), so a field the sim adds is copied with no change in `net/`.
7. **Inputs are canonical.** A peer steps with `SimIntent.unpack(packed)`, as the replay recorder does, so the bits a peer runs on are the bits it sends.
8. **The data match.** Both peers must run the same data: `SimReplay.dataHash(setup)` belongs in the handshake, and a mismatch refuses the match.

## 3. Snapshot and restore

`NetSnapshot.take(S, pool)` deep-copies the state graph and keeps object identity. A fighter that `game.ko`, a clash and a rush all point at stays one fighter in the copy. Arrays and dictionaries are copied deep and packed arrays duplicated. `S.out` is skipped. `restore(S, snap, pool)` writes the copy back into the same `SimState` object, so a host's reference to `S` stays good. References a host kept to objects inside `S` (a fighter) must be read again after a rollback. Before a restore, `SimCore.dispose` breaks the reference cycles of the objects being replaced, so they are freed. The check confirms sessions free their objects.

Speed, natively (section 5 has the numbers):
- **A generated, typed copier.** On first use `NetSnapshot` writes a GDScript with one typed copy function per class of the state (SimState's inner classes, `SimRng`, `SimIntent`) and compiles it. A typed field then copies as a plain member assignment instead of `Object.get`/`set` by name. A class it does not know, or a failed compile, falls back to the reflective copy, which gives the same result. `NetSnapshot.generatedSource()` shows the code.
- **A pool.** A new object of the state's classes costs more than copying its fields (a building about 3 µs). A save and a restore therefore write into the objects of dropped saves.
- **Number arrays.** An untyped array of plain numbers, such as a style's 660 buckets, is checked by the engine instead of a loop, and copied whole.

## 4. What the director needs

- **Its decisions are functions of the state and the seed.** Template choice, beat scheduling, the launch planner's noisy scores, parry and chain windows and the AI all draw only from `S.rng` and `SimRng.keyed(match seed, key, S.dirS.exN)`. Their state lives in `S.dirS`, `S.dirS.ex` (beats and their args) and each fighter's `act.dirI`. So a re-simulated exchange is the same exchange. This is measured, not assumed. At every confirmed tick of every session, the tick's feed lines (the director's debug feed: templates, branches, launch scores) and its fx events are digested and compared with the straight run's. `SimHash` includes every beat's op and args.
- **A presenter must treat the newest ticks as provisional.** A tick that ran on a prediction may run again with a different result. Its feed lines, voice lines, camera intents and fx events then come out again, or differently. The fix is the presenter's, not the director's. Big one-shot events (a voice line, a set-piece banner, a slow-motion cue) play when their tick is confirmed, or are keyed by (tick, exchange `n`, beat) so a re-run does not play them twice. Short cosmetic events (sparks, dust) play at once and are not undone. Most director output starts at an exchange's request and plays out over the following beats, so confirmation (about half the ping) usually lands before the beat it scheduled.
- **Re-simulation costs the director nothing special.** Planning an exchange on the re-run path costs what it cost the first time.

## 5. Cost

Measured with `net/tools/rollback_bench.gd` on a quiet machine: seed 1, 1,800 ticks of the bots' inputs, Godot 4.7.2 headless, the cloud container's Xeon at 2.1 GHz with 4 cores. The x4 columns estimate a device four times slower (a phone, an old laptop) as four times the native time.

**The pieces (seed 1, 1,800 ticks, one sim):**

| | mean | p50 | p99 | in ticks (mean) |
| :--- | ---: | ---: | ---: | ---: |
| sim tick (`SimCore.step`) | 0.60 ms | 0.48 ms | 1.53 ms | 1 |
| snapshot take (pooled) | 1.57 ms | | 3.0 ms | 2.6 |
| snapshot restore | 2.45 ms | | 4.4 ms | 4.1 |
| `SimHash.stateHash` (tests and desync checks only) | 25.9 ms | | | 43 |

- **Snapshot size.** About 155 to 159 KB of payload in the hand-made world, and 161 to 165 KB on planet 7. About 120 KB of that is the terrain's packed arrays, which copy as one block each. The rest is about 210 objects (118 of them buildings and 66 trees), about 33 arrays and about 5,000 scalars. Copying those scalars, one field at a time in GDScript, is what costs the time.
- **Headroom.** The sim alone fits about 28 ticks in a 16.7 ms frame natively, and about 7 at x4. A planet match fits 22 and 5 (0.78 ms a tick).

**A peer's frame over the loopback.** A frame is the packets received, any rollback and re-simulation, and one new tick. Both peers' frames of play are counted.

| profile | delay | save every | rollbacks/s | re-sim ticks/frame mean, p99, max | frame mean | p99 | max | x4 mean | x4 p99 | frames over 16.7 ms at x4 |
| :--- | ---: | ---: | ---: | :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| lan | 2 | 1 | 0 | 0, 0, 0 | 0.71 ms | 8.8 ms | 18.1 ms | 2.8 ms | 35 ms | 3% |
| p80j | 2 | 1 | 14.2 | 0.26, 2, 2 | 3.06 | 12.1 | 17.8 | 12.2 | 49 | 22% |
| p80j | 2 | 4 | 14.2 | 0.59, 4, 5 | 2.31 | 12.7 | 56.3 | 9.2 | 51 | 16% |
| p120 | 2 | 1 | 16.2 | 0.58, 3, 4 | 4.21 | 15.6 | 30.2 | 16.8 | 62 | 30% |
| p120 | 2 | 4 | 16.2 | 0.96, 6, 7 | 2.75 | 14.3 | 30.4 | 11.0 | 57 | 23% |
| p120 | 3 | 1 | 13.4 | 0.31, 2, 3 | 3.26 | 12.7 | 17.7 | 13.0 | 51 | 22% |
| p200 | 2 | 1 | 15.3 | 1.17, 6, 8 | 5.73 | 22.4 | 38.0 | 22.9 | 90 | 30% |
| p200 | 2 | 2 | 15.3 | 1.28, 7, 9 | 4.09 | 18.7 | 37.0 | 16.4 | 75 | 29% |
| p200 | 2 | 4 | 15.3 | 1.52, 9, 11 | 4.04 | 21.1 | 42.3 | 16.2 | 84 | 31% |
| p200 | 4 | 1 | 15.3 | 0.66, 4, 6 | 5.04 | 18.8 | 39.8 | 20.2 | 75 | 37% |
| p200c | 2 | 1 | 19.3 | 1.40, 5, 5 | 6.91 | 25.4 | 48.2 | 27.6 | 101 | 36% |
| far | 2 | 1 | 14.5 | 2.49, 13, 15 | 9.64 | 42.7 | 59.7 | 38.6 | 171 | 31% |
| far | 2 | 4 | 14.5 | 2.81, 15, 18 | 4.87 | 25.8 | 40.8 | 19.5 | 103 | 28% |

For p200 with one save a tick, the frame's 5.7 ms divides into 1.4 ms of ticks, 3.1 ms of saves (about two a frame: the new tick, and the re-simulated ticks that are still predictions) and 0.6 ms of restores. The loopback's tails are pessimistic. It keeps two sims in one process, and some of World's caches are keyed by world (for example `WorldContact`'s surface by column), so they rebuild whenever the other peer has stepped. That is why lan, with no rollback at all, shows an 8.8 ms p99 where the sim alone shows 1.5 ms. A real peer has one sim.

**What this means:**
- **Desktop.** The mean fits easily at every ping: 3 to 6 ms of the 16.7 ms frame up to a 200 ms ping, and under 10 ms even at 400 ms. The p99 is the problem. At a 200 ms ping, one frame in a hundred costs 19 to 22 ms, so it needs either a frame of slack or the work spread over frames. Saving every 2 to 4 ticks instead of every tick cuts the mean by a quarter to a half. One more tick of input delay cuts re-simulation by about half.
- **Phones and old laptops (x4).** Rollback as it stands does not fit: the mean alone is 9 to 23 ms from an 80 ms ping up. Rolling back there needs three things together: (1) an input delay close to the one-way time, so that little is predicted (with the delay at least the one-way time, nothing is); (2) a snapshot that costs about one tick, not three or four, which needs the sim changes in the cloud report's NEEDS FROM EP; (3) a cheaper tick (Performance). A browser on a phone is the hardest case.
- **Bandwidth.** The inputs alone are tiny: 8 bytes each, under 1 KB/s each way at 60 packets a second. Measured over ENet with the header and the checkpoint digests, a peer sends 8 to 16 KB/s (section 11).

## 6. How it is tested

`net/tools/rollback_check.gd`. For each seed it plays a straight, non-networked replay of the bots' inputs through `SimReplay`'s recorder (and verifies that replay with `SimReplay.play`). Then, for each network profile, it plays two peers over `NetLoopback`. It passes only if, at every confirmed tick of both peers:
- the gameplay `SimHash` equals the straight run's at that tick;
- the tick's feed and fx digest equals the straight run's;
- both peers' confirmed inputs and final states equal the straight run's.

Profiles (`NetLoopback.PROFILES`; ping is the round trip, and each way is half):

| profile | ping | jitter (one way) | loss |
| :--- | ---: | ---: | ---: |
| lan | 0 ms | 0 | 0 |
| p40 | 40 ms | ±4 ms | 0 |
| p80j | 80 ms | ±12 ms | 1% |
| p120 | 120 ms | ±20 ms | 3% |
| p160 | 160 ms | ±25 ms | 5% |
| p200 | 200 ms | ±30 ms | 10% |
| p200c | 200 ms | 0 | 0 |
| asym | 140 ms, split 80/20 | ±40 ms | 2% |
| far | 400 ms (200 ms one way) | ±40 ms | 10% |

`--sparse=K` runs the sessions as a game would (a save only before a predicted tick, at most every K ticks). `--negative-control` breaks the session on purpose, once with a restore that leaves one RNG bit wrong and once with late inputs that never roll back. It passes only if the check catches both. Results are in the cloud report (`docs/net/cloud-reports/2026-10-28-rollback-core.md`).

Not covered yet: no bot match reached a KO (the bots are not fighters), so the KO and its slow motion have not run under rollback. Depth (`"depth": true`) is not in the features setup either.

## 7. Desync detection and reports

Code: `net/desync.gd` (`NetDesync`) and the checkpoint half of `net/session.gd`. Still no transport: the checkpoints ride in the loopback's input packets.

- **What is hashed, and when.** Every `checkEvery` ticks (60, one second; 0 turns it off) each peer takes a digest of the state before that tick, `NetDesync.digest(S)`, and a snapshot of it. A re-run of the tick by a rollback replaces both, so what is kept is always the last run. Once the tick is confirmed, the digest is final and goes into every packet with the three before it (`chkOut`), so a lost packet costs nothing.
- **The cheap digest.** `SimHash.stateHash` costs about 25 ms. The digest is MD5 (the engine's `HashingContext`, which the web build has too) over one `PackedFloat64Array` of the fields a divergence reaches first, plus the terrain's packed arrays read as blocks. Those fields are the clock, the RNG, every fighter's hashed fields, the director's counters, the mood and the pause, each building's and tree's damage, and the shots. It costs about 0.8 ms, against 24 to 35 ms for `stateHash` (about 30 times cheaper), plus a pooled snapshot take (1.6 ms) once a second. That is under 0.05 ms a tick on average. A divergence in a field outside the digest is caught once it reaches one inside, which in this sim is a tick or two later: most state feeds the fighters or the RNG. It is not a security hash and does not need to be, since a peer that lies can lie about anything.
- **On a mismatch.** The first confirmed checkpoint whose digests differ sets `NetSession.desync` (and calls `onDesync`) on both peers. Each peer keeps:
  - the tick, both digests and the last agreed checkpoint;
  - the replay of its confirmed inputs up to that tick (`NetDesync.replayOf`, SimReplay format v4, with the data hash);
  - its snapshot at that tick, and the one at the last agreed checkpoint.

  Detection then stops, and later checkpoints keep no snapshots.
- **The report.** `NetDesync.report(session, peerSnapshot)` returns a JSON-able record, and `writeReport` writes it. It holds the tick, both digests, the last agreed tick, the replay, and two field walks:
  - `vsReplay` walks this peer's snapshot against the state its own replay re-simulates. If they differ, this peer drifted from its own inputs (a sim bug, a static that a restore did not cover, memory gone bad). If they agree, the other peer or the platform did.
  - `vsPeer` walks it against the other peer's snapshot of the same tick, when that is at hand. The loopback always has it; online it needs the other side's snapshot in a crash-report upload (section 10).
- **The field walk.** `NetDesync.firstDiffs(a, b)` goes breadth first in property-list order, so an object is named by its shortest path (the second fighter is `S.fighters[1]`, not `S.fighters[0].launchBy`). It compares floats by their bits, and lists up to 8 paths with both values, for example `S.fighters[1].x (89067.3017581505 (bits 40f5beb4d4005ab9) vs … ab8)` or `S.deform[1600]`. It skips `S.out` and `worldId`, which is a per-process counter.

**The check** (`net/tools/desync_check.gd`) runs as a game would (not in verify mode):
- **Clean runs, every profile.** It passes only if no desync is raised, every confirmed checkpoint equals the straight run's digest, and the peers agreed on all of them.
- **Injected divergence.** Peer 1's state is changed after every run of one tick that is not a checkpoint (tick 307 of 900). The injections are one RNG bit, one ulp of a fighter's x, 1 hp off a building, 0.001 on a terrain column, the mood's casualty count, and 1e-6 on the director's cool-down. Every one must be reported by both peers at the next checkpoint (360), with 300 as the last agreed checkpoint. The two digests must cross, and the field walk must find the difference against the other peer and against the divergent peer's own replay, and find none on the clean peer's replay. An injection the sim erases before the checkpoint counts as healed, not missed. That happened to the 1-ulp x on seed 2, where the sim overwrote x before the checkpoint: the divergent peer's full `SimHash` at the checkpoint equals the straight run's. Each injection must still be detected in at least one run.
- **Negative control (`--negative-control`).** A blind detector, which exchanges digests and never compares them, must miss the injections. A stale detector, which keeps a checkpoint's first run (a guess) instead of its last, must raise a false alarm on a clean run that re-ran a checkpoint. Both breaks must be caught.

`rollback_check.gd` now also fails if detection fires on any of its sessions, because `checkEvery` is on at its default there.

## 8. Spectators

Code: `net/spectator.gd` (`NetSpectator`), `NetSession.confirmedSince`, and the spectator half of `net/loopback.gd`.

- **The stream.** A spectator has no input slot. A relay (one player's session today, a server later) sends it every slot's confirmed inputs: only ticks below the relay's confirmed frontier, at most 64 a packet, from the spectator's acknowledgement on. It also forwards the relay's checkpoint digests. The spectator acknowledges what it holds, so a lost packet is resent. It never predicts and never rolls back, so every tick it runs is final.
- **The jitter buffer.** It starts once it holds `lag` ticks (6, 100 ms), then plays one tick a frame. If the buffer runs dry it stops, raises `lag` by 2 (at most 60) and fills up again. If the buffer holds more than twice `lag`, it catches up by up to 3 ticks a frame.
- **It checks itself.** It takes the same digests at the same ticks as the players and compares them with the forwarded ones. So a spectator that drifted, or a relay that sent anything other than the confirmed stream, shows up as a spectator desync.
- **How far behind.** The spectator runs about the relay's confirmation lag plus the buffer behind the players: about 5 ticks (83 ms) on a LAN, 11 (180 ms) at a 120 ms ping, 15 to 19 (250 to 310 ms) at 200 ms, and 26 to 28 (440 to 470 ms) at 400 ms. The buffer never ran dry up to a 200 ms ping with 10% loss. On asym and far it ran dry once, and grew from 6 ticks to 8. A broadcast would add seconds of delay on purpose, which is just a larger `lag`.
- **Cost to the relay.** Its packet holds two 8-byte inputs a tick and its last four digests: about 1 KB/s at 60 packets a second. A relay serving many spectators should be a server, not a player (section 10).

**The check** (`net/tools/spectator_check.gd`). Two players play over the loopback as a game would, and a spectator hangs off peer 0 over a link with the same profile. It passes only if all of these hold:
- the spectator's `SimHash` equals the straight run's every 10 ticks and at the end;
- every tick's feed and fx digest equals the straight run's;
- every checkpoint it compared agreed with the relay's;
- it ran every tick, and the players saw no desync.

The negative control breaks the relay in two ways. One relay forwards the inputs its ticks ran with, guesses included (the obvious bug). The other stream throws one slot's stick the other way for 12 ticks. Each break must show as a state that differs from the straight run's and as a spectator desync.

## 9. Adaptive input delay

Code: `net/delay.gd` (`NetDelay.choose`). It is a pure function, with no clock and no state, so both peers and a test get the same answer from the same numbers. Each peer chooses for itself from its measured round trips, and the session takes the larger of the two in the handshake.

- **The rule.** Choose the smallest delay whose usual worst rollback frame fits the device's budget.
  - **The link.** The 75th percentile of the round-trip samples, so one spike does not set the delay. Negative, NaN and infinite samples are ignored. A rollback reaches back about (one-way ticks − delay) ticks.
  - **The device.** The cost of a tick, a snapshot take and a restore on it. `NetDelay.device(k)` scales the reference device's (0.60, 1.57 and 2.45 ms, section 5) by a slowdown k. A rollback frame of depth D costs restore + (D + 1) × (tick + save).
  - **The budget.** 75% of a 60 Hz frame (12.5 ms). The rest goes to drawing and the host.
  - **The limits.** The delay is never below 2 ticks (the tested default), never above 8 (133 ms, past which the stick feels late), and never above the delay that removes rollback on that link. If even that does not fit, the answer is the most it may be, with `fits = false`, so the host can warn or keep the match out of ranked play.
- **What it picks** for the loopback's profiles (`delay_check.gd` prints this table; * means it does not fit):

| profile | ping | jitter (round trip) | reference | x2 | x4 |
| :--- | ---: | ---: | ---: | ---: | ---: |
| lan | 0 | 0 | 2 | 2 | 2 |
| p40 | 40 | ±8 | 2 | 2 | 2 |
| p80j | 80 | ±24 | 2 | 3 | 3 |
| p120 | 120 | ±40 | 2 | 5 | 5 |
| p160 | 160 | ±50 | 3 | 6 | 6 |
| p200 | 200 | ±60 | 4 | 7 | 7 |
| p200c | 200 | 0 | 3 | 6 | 6 |
| asym | 140 | ±80 | 3 | 6 | 6 |
| far | 400 | ±80 | 8* | 8* | 8* |

  On a desktop it keeps the tested 2 ticks up to a 120 ms ping, and takes 3 or 4 at 160 to 200 ms, where the bench's p99 frames ran over. On a device four times slower it asks for about the one-way time, as section 5 said it must. At a 400 ms ping nothing fits: 8 ticks is the cap.
- **The tests** (`net/tools/delay_check.gd`):
  - the floor and the cap;
  - the delay that removes rollback;
  - it is monotone in ping and in device slowness;
  - a x4 device takes more delay than the reference;
  - a delay that fits stays within the budget, and one tick less would not;
  - outliers, junk and empty input;
  - the samples' order does not matter, and the same input gives the same answer;
  - the options;
  - a NaN speed.

  The negative control runs the same tests against a chooser that ignores the device and one that reads only the first sample, and both must fail.
- **In the handshake.** Each peer measures its round trips with the handshake's pings and proposes `NetDelay.choose` for its own device. The match runs at the larger proposal (section 11). `rollback_check.gd --delay=auto` runs every profile at the delay its handshake agrees.
- **Not yet.** It runs once, at match start. Changing the delay mid-match, between exchanges with hysteresis, needs both peers to agree on the tick it changes at. The host already keeps a rolling round trip during play (`NetHost.rttMs`) for that.

## 10. Open questions

- **Transport.** ENet (native) is built and the WebRTC design is in section 11. What is still open is NAT traversal over the internet. It needs a STUN server (free public ones exist) and, for the share of players behind symmetric NATs, a TURN relay, which costs money (ADR 0005: zero budget). Both are outside services, so they need a ruling. ENet over the internet also needs one side to be reachable (a forwarded port), or the same STUN-style hole punching.
- **Matchmaking.** At zero budget: lobby codes over a small signalling service (free tier), or Steam lobbies on Steam. Ranked play is out of scope until there are players.
- **Time sync.** Built (section 11). Its tolerance at long pings is loose: at a 400 ms ping the peers stay about 2 frames apart on average, with peaks near 8.
- **Desync reports online.** The `vsPeer` walk needs the other peer's snapshot of the mismatched tick. Online, that is an upload of the snapshot (about 160 KB) beside the replay, to a crash-report bucket or straight to the other peer after the match. That needs a transport and somewhere to put the reports, at zero budget. Until then `vsReplay` runs on one side only.
- **A spectator relay server.** One player relaying to one spectator costs about 1 KB/s. Many spectators need a relay that is not a player. That can be a free-tier server, or a spectator relaying to further spectators: the stream is the same, and every spectator checks the digests.
- **Changing the delay mid-match.** `NetDelay` chooses once, at match start. Changing the delay between exchanges needs both peers to agree on the tick the change lands at, with hysteresis. That is a transport-protocol item.
- **Presentation under rollback (Rendering, Audio, Encounter).** Which events wait for confirmation, and how a rolled-back effect is hidden (section 4).
- **Holding presses through a freeze (Controls).** `step()` consumes no input during hit-stop and pausing set pieces; the host keeps its presses for the next tick, with `waited`. Online, the local host decides this from its own predicted state. That stays deterministic (whatever it sends is the input), but a press can be held for a freeze that a rollback then removes. Moving that buffer into the sim (into `ActState`) would make it part of the rolled-back state.
- **Platforms not proven bit-identical.** Native x64 and the web are proven (`docs/architecture/web-parity.md`). macOS on ARM, Linux on ARM, Android and iOS are not, and an ARM compiler may contract `a*b+c` into an FMA. The parity gate must run on each before cross-play between them.
- **More than two players.** The session takes any number of slots. One-versus-many bodies past the pair are AI-driven, so they need no input. Co-op online (after versus, per Orb) is two input slots plus AI bodies, which this core already covers.
- **Planet matches and the calm turn.** Those caches are statics keyed by world id (`WorldEpoch._plans`, `_jobs`). They should be pure caches, but no planet setup is in the check yet.

## 11. Transport, handshake and time sync

Code: `net/transport.gd` (`NetTransport`, the interface and the wire codec), `net/link_transport.gd` (`NetLinkTransport`, the loopback), `net/enet_transport.gd` (`NetEnetTransport`), `net/handshake.gd` (`NetHandshake`), `net/timesync.gd` (`NetTimeSync`) and `net/host.gd` (`NetHost`). The sim is not touched, and neither is `NetSession`.

```
NetSession            the rollback core (sections 1 to 9): no clock, no sockets
   ^
NetHost               one peer: handshake -> session at the agreed delay; time sync; ping; packets
   ^
NetTransport          send(now, packet) / receive(now) / isOpen() / close(), unreliable and unordered
   |-- NetLinkTransport    the loopback's simulated links (one process, simulated time)
   |-- NetEnetTransport    ENet, one peer, one unsequenced channel (native)
   '-- NetWebRtcTransport  a WebRTC data channel (browser): designed below, not built
```

- **The interface.** `send(now, packet)` and `receive(now)`, where `now` is the host's clock in ms (simulated in the loopback, the wall clock in a real process), plus `isOpen()` and `close()`. Delivery is promised to be no better than UDP: a packet may be lost, delayed or reordered. The protocol needs no more, because every packet resends all the inputs the other side has not acknowledged and every field is idempotent. `NetLoopback` now sends through `NetLinkTransport`, so the rollback, desync and spectator checks run over the same interface.
- **The wire.** `NetTransport.encode` and `decode`. A game packet has a fixed little-endian layout: 40 bytes, plus 8 per unacknowledged input and 20 per checkpoint digest. The handshake's packets use Godot's Variant encoding (`var_to_bytes`, which never decodes objects). Malformed bytes decode to null. Measured over ENet, a peer sends 8 KB/s on a LAN and 11 to 16 KB/s at 120 to 400 ms: most of it is the four newest checkpoint digests that every packet repeats, and the unacknowledged inputs, which grow with the ping. Section 5's estimate of under 1 KB/s left out the digests and the headers.
- **ENet.** Godot's built-in `ENetConnection`, so there is no new dependency. One side calls `listen(addr, port)` and the other calls `dial(addr, port)`. Every packet is sent unsequenced on channel 0 and flushed at once: otherwise ENet would send it on the next service, a frame later. For tests, `impair(oneWay, jitter, loss, seed)` puts a loopback `Link` in front of the socket on the sending side, so the loopback's profiles apply over real sockets.
- **The handshake** (`NetHandshake`, on any transport):
  1. **Ping.** Each peer sends `{hs: ping, ts}` every frame until it has 16 round trips, or 3 s have passed. The other side answers each ping at once, during the match too. Only pings sent after the other peer was first heard from count. In a first version, pings that waited for the other process to start set the delay to 8 on a LAN.
  2. **Propose.** Each peer proposes `NetDelay.choose(its round trips, its own device)`.
  3. **Hello.** Each peer sends `{hs: hello, v, match, delay, got}` every frame. `v` is the protocol version and `match` is the match key (seed, AI flags and setup), and a mismatch in either fails the handshake. The delay is the larger of the two proposals. A peer that has finished answers any hello still marked `got = false`, so a lost last hello costs a frame.

  Packets from a peer that has started playing are dropped until this one has started too. Everything in them comes again.
- **Ping during play.** Each game packet carries `ts`, `echo` (the newest `ts` received) and `age` (how long it was held). The round trip is now − echo − age, on the sender's own clock, so the two clocks never have to agree. `NetHost.rttMs()` is the median of the last 64 samples. Time sync uses it now, and a mid-match delay change could use it later.
- **Time sync** (`NetTimeSync`, GGPO's frame advantage). Each packet carries the sender's frame and its own advantage. A peer estimates the other's frame now as the packet's frame plus half the round trip, and its own advantage as its frame minus that. A packet overtaken by a newer one is skipped. Every 30 frames, if this peer's mean advantage over 32 samples exceeds the other's, it waits half the difference, between 1 and 8 frames. The other peer sees the same numbers reversed, so it does not wait. A wait reaches the other side's reports one round trip later, so after a wait the means start afresh and take no samples until then. Without that quiet period, at 400 ms both peers took turns waiting. A waiting host calls `session.sync()`, so packets still go out and rollbacks still happen.
- **What the proof showed.** The numbers are in the cloud report `docs/net/cloud-reports/2026-10-28-transport.md`.
  - Two processes over ENet on 127.0.0.1 agree on every confirmed tick from a LAN to a 400 ms ping with 10% loss. With one peer frozen for 40 frames, time sync brings the peers back to under a frame apart on average.
  - In the frame times there, a p99 of 50 to 78 ms is the test's own cost: verify mode saves before every tick, and a full `SimHash` runs every 60 ticks (26 ms). A game does neither.

### WebRTC (the browser): the design, not built

- **Where it plugs in.** `NetWebRtcTransport extends NetTransport`. It holds Godot's `WebRTCPeerConnection` and one data channel made with `create_data_channel("game", {"negotiated": true, "id": 1, "ordered": false, "maxRetransmits": 0})`, which is unordered and unreliable: the same promise as ENet unsequenced. The methods map directly:
  - `send` is `channel.put_packet(NetTransport.encode(pk))`;
  - `receive` calls `peer.poll()`, then drains `channel.get_packet()` through `NetTransport.decode`;
  - `isOpen` is `channel.get_ready_state() == STATE_OPEN`.

  `NetHost`, `NetHandshake`, `NetTimeSync`, `NetSession` and the codec are unchanged. The bytes are the same as ENet's, so a relay or a recorded packet log works for both.
- **Godot's support.** WebRTC is built into the web export, which uses the browser's own implementation. Native builds need the `webrtc-native` GDExtension, which is a new dependency and is not in this spike. Until that is approved, browsers play browsers over WebRTC and native builds play native builds over ENet. Cross-play would need the extension, or a relay that speaks both, which is a server.
- **Signalling with no server.** A connection needs one offer and one answer exchanged out of band: each is SDP with its ICE candidates gathered in, a few hundred bytes compressed. With no signalling service, a lobby is copy and paste:
  1. the host shows its offer as a code;
  2. the joiner pastes it and shows its answer;
  3. the host pastes that.

  It is clumsy but costs nothing. On a LAN, host candidates connect with no STUN. Over the internet, a STUN server is needed and sometimes TURN too. Both are outside services, so they are left for a ruling (NEEDS FROM EP in the report).
- **Tests when built.** The same `transport_check` parts run on any transport. A two-tab browser test of the web export, with the offer and answer passed through the page, has to run locally, because browser captures do not run in the cloud. `impair()` would wrap the channel as it wraps ENet.
