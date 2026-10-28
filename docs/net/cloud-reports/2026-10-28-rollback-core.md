# Cloud report: the rollback core (Netcode and Online, 2026-10-28)

Brief: `docs/ep/cloud-briefs/netcode-rollback.md`. Design doc: `docs/net/rollback.md`.

## SUMMARY
Rollback netcode's core now runs on the unchanged sim, with no transport. It covers input delay, prediction, a confirmed and predicted input history per player, snapshot and restore of the whole SimState, rollback and re-simulation, and a two-peer loopback with latency, jitter and loss. Across 99 sessions (13 seeds, 5 setups, 9 network profiles from 0 to 400 ms ping with up to 10% loss), both peers' SimHash equals a straight replay's at every confirmed tick, and so does each tick's feed and fx (the director's decisions): 198,457 hash comparisons, 0 differences. A negative control catches all 28 deliberate breaks. On a desktop the frame's mean fits easily at every ping. At a 200 ms ping, 1% of frames cost 19 to 22 ms, and a phone (x4) does not fit without more input delay, a cheaper snapshot and a cheaper tick.

## CHANGES
All in owned paths. No file outside `net/` and `docs/net/` changed.
- `net/session.gd` (`NetSession`): input delay, edge-clearing prediction, the input history, saves, rollback and re-simulation, confirmation, waiting, statistics. It reads no clock.
- `net/snapshot.gd` (`NetSnapshot`): a deep copy of the state graph that keeps object identity. A typed copier is generated at run time from the classes' property lists, so a field the sim adds needs no change here. It also has a pool for reusing objects, `measure()` for size, and `aliasAudit()`.
- `net/loopback.gd` (`NetLoopback`): two peers, links with latency, jitter, loss and reordering, redundant input packets with acknowledgements, and 9 profiles.
- `net/bot.gd` (`NetBot`): a seeded scripted player, one stream per slot.
- `net/tools/rollback_check.gd`: the determinism check. Options: `--setup=default|features|planet|calm`, `--sparse=K`, `--negative-control`.
- `net/tools/rollback_bench.gd`: the cost bench.
- `docs/net/rollback.md`: the model, the determinism contract, the snapshot, what the director needs, the cost, the tests, and the open questions.

Results by criterion:
1. **Sync** (`rollback_check.gd`). Every row is exit 0 and PASS.
   - default setup, seeds 1 to 4, all 9 profiles, 1,200 ticks, every tick hashed: 36 sessions, 86,400 comparisons;
   - features (v2 intents, forms, brake, flight, hit-stop, ricochet), seeds 5 and 6: 18 sessions, 43,200;
   - planet 7, seed 7, and the calm turn, seed 8, 6 profiles each: 12 sessions, 28,800;
   - sparse saving every 4 (seeds 9 and 10) and every 2 (seed 11): 27 sessions, 37,897;
   - 3-minute matches (10,800 ticks, 115 to 155 exchanges), seeds 12 and 13, hashed every 60 ticks, with feed and fx every tick: 6 sessions, 2,160.

   Each straight run also plays back as a `SimReplay` and verifies. No session stalled. Sessions free their objects (+12 objects after up to 18 sessions).
2. **Cost** (quiet machine, Xeon 2.1 GHz):
   - a sim tick costs 0.60 ms mean (1.53 ms p99), so a frame holds 28 ticks natively and 7 at x4;
   - a snapshot take costs 1.57 ms (2.6 ticks) and a restore 2.45 ms;
   - a snapshot holds 155 to 165 KB of payload: 120 KB of packed terrain plus about 210 objects and 5,000 scalars;
   - a peer's frame averages 0.7 ms on a LAN, 3.1 ms at 80 ms ping, 4.2 ms at 120 ms, 4.0 to 5.7 ms at 200 ms, and 4.9 to 9.6 ms at 400 ms;
   - the p99 is 12 to 22 ms up to a 200 ms ping;
   - x4 means 9 to 23 ms, over budget. The full table is in rollback.md section 5.
3. **The director.** Feed lines (templates, branches, launch scores) and fx events are identical at every confirmed tick. SimHash includes every beat's op and args.
4. **Golden and gates.** The golden is byte-identical, since no sim file changed. Gates, with each one's last line and exit code:
   - `node tools/validate.js`: "277 files checked, 0 errors, 0 warnings", 0
   - `--self-test`: "parser 282 files + 7 text cases; engine 46 cases + 6 unsupported; schemas 169; data cases 8149", 0
   - `node tools/lint-determinism.mjs`: "determinism lint ok", 0
   - `npm test --prefix sim`: "all 5 stages passed", 0
   - `anim_check.gd`: "anim check passed", 0
   - all 41 `sim/world/tools/*_check.gd`: each "0 check(s) failed" or its pass line, 0
   - `split_sweep.gd`: "split sweep passed", 0
   - `campaign_episode.gd`: "the two plays are the same to the bit", 0
   - `parity.gd`: "golden check passed", 0. It ran with net/ in the tree, so the literal lint covers net/.
   - net/'s own checks: the rollback check (above) and the negative control: "28 break(s) caught, 0 missed", 0.
5. **Design doc.** `docs/net/rollback.md`.

## DECISIONS
- **GGPO-style peer-to-peer rollback, inputs only on the wire.** The wire form is the packed `SimIntent`, the same integer a replay stores.
- **Prediction repeats the last confirmed input with its edges cleared.** A held stick or guard carries on, and a press never repeats.
- **The snapshot is a wrapper in `net/`, not a sim API.** The brief allows that. Its typed copier is generated at run time from the property lists, so the sim's authors need not maintain anything for netcode. A reflective fallback covers a failed compile.
- **The contract adds no shared containers to the existing determinism rules.** The audit finds one read-only sharing in planet matches, World's ring axis vectors (`S.planetRing.c/t`, `S.epoch.c0/ring`), and the check allowlists it by name.
- **Defaults: 2 ticks of input delay, a save before every predicted tick, wait at 20 ticks ahead.** The bench favours saving every 2 to 4 ticks at 120 ms and above (a quarter to a half off the mean). The default stays at 1 until a real transport measures the tails.
- **The presenter, not the director, handles provisional ticks.** One-shot events wait for confirmation or are keyed by (tick, exchange, beat). rollback.md section 4 has the details.

## NEEDS FROM EP
1. **Simulation and Engine, with World: a cheaper snapshot.** Per-match constants should move out of the per-tick state into one immutable object that every snapshot shares. These are a building's generation fields (x, w, h, kind, seed, district, shape, landmark, floors, idx, place, plan, z, d, row, maxhp, pop), a tree's x and h, `S.bIdx` and `S.base`. Buildings are 118 of about 210 objects and about 3,000 of 5,000 scalars, so this should roughly halve a save. Saves are about half a peer's frame at 120 ms ping and above.
2. **Performance: the tick's cost.** It is 0.60 ms mean and 1.5 ms p99 natively (0.78 ms on a planet). At x4 that leaves 5 to 7 ticks a frame. Rollback on phones needs a tick around 0.3 ms native or less.
3. **World: keep the ring axis vectors read-only.** `S.planetRing.c/t` and `S.epoch.c0` and `ring.c/t` share arrays. Either confirm they are never written in place, or copy them on assignment.
4. **Controls: holding presses through a freeze.** The host-side carry of presses through hit-stop and pauses (`waited`) reads the local predicted state. Consider moving that buffer into `ActState` so it rolls back with the state.
5. **Rendering, Audio and Encounter: presentation under rollback.** Which feed, voice, camera and fx events wait for confirmation, and how a rolled-back effect is hidden.
6. **Tools: CI.** Should a short rollback check be a CI gate (`--seeds=1 --ticks=300 --profiles=lan,p80j,p200`, about 1 minute, plus `--negative-control` at 240 ticks)? CI's workflow is not mine to change.

## RISKS
- **KO, slow motion and depth are untested under rollback.** No bot match reached a KO, and depth was not in the features setup.
- **The loopback's tails are pessimistic.** Two sims in one process rebuild World's per-world caches (for example `WorldContact`'s surface by column) when the peers alternate. A real peer has one sim, but the real tails are not measured yet.
- **The copier compiles a GDScript at run time.** That should work in exported builds, including the web, but it is untested there. The reflective fallback is about 2x slower.
- **Cross-play is only as wide as the parity proof.** Native x64 and the web are proven bit-identical. macOS ARM, Android and iOS are not (FMA contraction).
- **A restore replaces S's inner objects.** A host that keeps references to fighters or buildings must read them from `S` again after a rollback.
- **Rollback depth is about half the ping.** That is 13 to 15 ticks at a 400 ms ping. The 20-tick wait is never reached in tests, but a real link's spikes may reach it.

## NEXT
1. Simulation's snapshot split (NEEDS 1) and Performance's tick (NEEDS 2), then re-bench with `net/tools/rollback_bench.gd`.
2. A transport spike: one session layer over WebRTC data channels (browser) and ENet (native), plus time sync (frame advantage) and adaptive input delay from measured ping and device speed.
3. Desync reporting: a periodic cheap confirmed hash, exchanged between peers, with the replay and last snapshot kept on a mismatch. Spectators then come from the confirmed input stream.
4. Extend the check to fighter AIs driving the inputs (to reach KOs) and to depth.

Branch note: the session's harness designated `claude/cool-volta-93a1sv`, and the brief names `cloud/netcode-online/rollback-core`. The work is pushed to both when the remote allows it.
