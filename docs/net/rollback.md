# Rollback netcode: the core

Owner: Netcode and Online. 2026-10-28, cloud brief `docs/ep/cloud-briefs/netcode-rollback.md`. Code: `net/`. No transport yet: two peers run in one process over simulated links.

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

1. **The state is closed.** Everything a later tick reads lives in the object graph reachable from `S`, as script variables. A static that gameplay writes during a tick would survive a restore and break rollback. The per-match statics that `step()` rebinds from `S` (`SimConst` arena, `WorldBiomes` columns, `WorldClimate.curGen`) are derived from `S`, so they are safe. Planet-match caches (`WorldEpoch._plans`, `_jobs`) are untested here (section 7).
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
- **Bandwidth.** It is tiny. A packet holds the unacknowledged inputs, 8 bytes each, plus a header: under 1 KB/s each way at 60 packets a second.

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

## 7. Open questions

- **Transport.** Browser peers need WebRTC data channels (unordered, unreliable), and native builds can use ENet or Steam networking. NAT traversal needs a STUN server (free public ones exist) and, for the share of players behind symmetric NATs, a TURN relay, which costs money (ADR 0005: zero budget). One session layer over two transports keeps native and browser players able to meet.
- **Matchmaking.** At zero budget: lobby codes over a small signalling service (free tier), or Steam lobbies on Steam. Ranked play is out of scope until there are players.
- **Time sync.** The loopback runs both peers on one clock. Real peers drift: the peer that is ahead must slow down (skip a frame now and then) by the frame advantage the packets report. Packets already carry the sender's frame for this.
- **Adaptive input delay.** Choose the delay at match start from the measured ping and the device's speed. A slow device should take more delay and roll back less (section 5).
- **Spectators.** A spectator needs only the confirmed inputs, relayed by a player or a server, played with a few seconds of delay and no rollback. A replay file is already that stream (`SimReplay`).
- **Desync reporting.** `SimHash.stateHash` costs about 25 ms, too much to run every tick. Proposal: both peers hash a confirmed tick every few seconds, spread over frames or hashing a cheaper digest, and exchange the hashes. On a mismatch both keep the replay (seed, setup, data hash, inputs) and the last confirmed snapshot for a report. Replays already verify across machines.
- **Presentation under rollback (Rendering, Audio, Encounter).** Which events wait for confirmation, and how a rolled-back effect is hidden (section 4).
- **Holding presses through a freeze (Controls).** `step()` consumes no input during hit-stop and pausing set pieces; the host keeps its presses for the next tick, with `waited`. Online, the local host decides this from its own predicted state. That stays deterministic (whatever it sends is the input), but a press can be held for a freeze that a rollback then removes. Moving that buffer into the sim (into `ActState`) would make it part of the rolled-back state.
- **Platforms not proven bit-identical.** Native x64 and the web are proven (`docs/architecture/web-parity.md`). macOS on ARM, Linux on ARM, Android and iOS are not, and an ARM compiler may contract `a*b+c` into an FMA. The parity gate must run on each before cross-play between them.
- **More than two players.** The session takes any number of slots. One-versus-many bodies past the pair are AI-driven, so they need no input. Co-op online (after versus, per Orb) is two input slots plus AI bodies, which this core already covers.
- **Planet matches and the calm turn.** Those caches are statics keyed by world id (`WorldEpoch._plans`, `_jobs`). They should be pure caches, but no planet setup is in the check yet.
