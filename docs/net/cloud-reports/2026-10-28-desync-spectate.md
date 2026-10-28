# Cloud report: desync reporting, spectators, adaptive input delay (Netcode and Online, 2026-10-28)

Brief: `docs/ep/cloud-briefs/netcode-desync-spectate.md`. Branch: `cloud/netcode-online/desync-spectate`. Design doc: `docs/net/rollback.md` sections 7 to 9 (new) and 10 (open questions, updated).

## SUMMARY
- **Desync detection.** Peers now exchange a cheap digest of the confirmed state every 60 ticks: about 0.8 ms, about 30 times cheaper than `SimHash`. On a mismatch, both peers keep the replay of their confirmed inputs and their snapshots of that tick and of the last agreed one. Each writes a JSON report with the tick, both digests, and a field walk that names the differing fields, for example `S.fighters[1].x`, shown with its bits.
- **Spectators.** A spectator receives only the confirmed inputs through a relay and plays them through an adaptive jitter buffer. On every profile, including features and planet setups, it stays `SimHash`-equal to the straight run, and its digests agree with the relay's.
- **Adaptive input delay.** `NetDelay.choose` is a pure function of the measured round trips and the device's costs, and it is tested.
- **Results.** Every check passes, each new check's negative control catches every break, and the golden is byte-identical.

## CHANGES
All the changes are in owned paths. No file outside `net/` and `docs/net/` changed.
- `net/desync.gd` (new, `NetDesync`) has five parts:
  - `digest(S)`: MD5 over a packed array of the fields a divergence reaches first, plus the terrain arrays;
  - `replayOf`: the replay of the confirmed inputs, in SimReplay v4 format;
  - `replayState`;
  - `firstDiffs`: the field walk. It is breadth first, so an object gets its shortest path, and it compares floats bit for bit;
  - `report` and `writeReport`.
- `net/session.gd` adds checkpoints:
  - each checkpoint keeps a digest and a snapshot from its last run, so a re-run replaces them;
  - once a checkpoint is confirmed, the session sends it and compares it (`addRemoteCheck`, `chkOut`, `desync`, `onDesync`, `onCheck`);
  - `confirmedSince()` is the spectator stream;
  - `perturb`, `chkCompare` and `chkStale` are test hooks.

  `checkEvery` defaults to 60, and 0 turns detection off.
- `net/spectator.gd` (new, `NetSpectator`): confirmed inputs only, no prediction and no rollback. It has a jitter buffer that prebuffers, plays one tick a frame, grows on an underrun and catches up, and it checks its own digests against the relay's.
- `net/delay.gd` (new, `NetDelay`): `choose(rttSamples, device, opts)` and `device(slowdown)`.
- `net/loopback.gd`: packets carry the newest four checkpoint digests. `addSpectator()` adds a relay link and an acknowledgement link with the profile's latency, jitter and loss.
- `net/tools/desync_check.gd`, `spectator_check.gd` and `delay_check.gd` (new), each with `--negative-control`.
- `net/tools/rollback_check.gd`: it now also fails when detection fires in any session, or when no session ran (before, a script error printed PASS with 0 sessions).
- `docs/net/rollback.md`: sections 7 (desync), 8 (spectators) and 9 (adaptive delay) are new. Section 10's open questions are updated.

## RESULTS
Every row exited 0.
- **The rollback check, all 9 profiles.** Seeds 1 to 4, 1,200 ticks, verify mode: 36 sessions, 86,400 confirmed-tick hash comparisons, "PASS … 0 failure(s)". Sparse saving every 4 ticks (seed 9, all profiles): 9 sessions, 11,755 comparisons, PASS. Negative control (seed 1, 240 ticks): "14 break(s) caught, 0 missed".
- **The desync check, seeds 1 and 2, all 9 profiles, 900 ticks.**
  - Clean runs: 18 runs, no false alarm, and every confirmed checkpoint equals the straight run's digest.
  - Injected divergence: 108 runs (6 injections × 9 profiles × 2 seeds). 99 were detected by both peers at the next checkpoint (360), with 300 as the last agreed checkpoint. In each, the field walk named the injected field: `S.rng.a`, `S.fighters[1].x`, `S.buildings[0].hp`, `S.deform[1600]`, `S.mood.casGiven` or `S.dirS.cool`.
  - 9 runs healed: on seed 2 the sim overwrote the 1-ulp x before the checkpoint, and the full `SimHash` confirms the state was equal again.
  - Totals: "PASS 70 runs … 0 failure(s)" and "PASS 56 runs … 0 failure(s)".
  - The planet setup (seeds 7 to 9): see the gates below.
  - Negative control (seeds 1 and 2, 600 ticks): "48 break(s) caught, 0 missed". The blind detector missed every injection. The stale detector raised a false alarm on every profile where a re-run changed a checkpoint's state. p40 and p80j were skipped because their guesses happened to be right.
- **The spectator check.**
  - Default setup, seeds 1 and 2, all profiles: 18 sessions, 1,620 comparisons, PASS.
  - Features setup, seed 5, all profiles: 9 sessions, 810 comparisons, PASS.
  - Planet: see the gates below.
  - How far behind the players: 5 ticks (83 ms) on a LAN, 11 at 120 ms, 15 to 19 at 200 ms, 26 to 28 at 400 ms. No rebuffer up to 200 ms; one each on asym and far.
  - Negative control (seeds 1 and 2, 600 ticks, all profiles): "32 break(s) caught, 0 missed". The breaks were a relay forwarding predicted inputs, and a stick thrown the other way for 12 ticks.
- **The delay check.** "PASS 0 failure(s)". Negative control: "2 of 2 broken choosers caught". Its table is in rollback.md section 9: on a desktop, 2 ticks up to a 120 ms ping and 4 at 200 ms; on a x4 device, about the one-way time.

**Gates** (last line and exit code):
- `node tools/validate.js`: "278 files checked, 0 errors, 0 warnings", 0
- `--self-test`: "parser 283 files + 7 text cases; engine 46 cases + 6 unsupported; schemas 170; data cases 8153", 0
- `node tools/lint-determinism.mjs`: "determinism lint ok: …", 0
- `npm test --prefix sim`: "all 4 stages passed" (golden: "the frozen JS core reproduces its golden record"), 0. The golden is byte-identical: no sim file changed.
- `anim_check.gd`: "anim check passed", 0
- all 40 `sim/world/tools/*_check.gd` scripts exited 0. Each printed its "0 check(s) failed" line ("CRATERS CHECK: 0 failed"; lane_check prints its avenue table, "… across an avenue: 0").
- `split_sweep.gd`: "split sweep passed", 0
- `campaign_episode.gd`: "the two plays are the same to the bit (1800 ticks a stage …)", 0
- `parity.gd`: "golden check passed", 0. It ran with the new net/ files in the tree.
- **The planet setup.**
  - `spectator_check --setup=planet --seeds=7`, on lan, p80j, p200 and far: 4 sessions, 360 comparisons, PASS, 0.
  - `desync_check --setup=planet`, on lan, p120 and far, 3 seeds × 21 runs: 0 false alarms and 0 missed divergences. The 1-ulp x and the 1e-6 cool-down healed on seeds 7 and 8, confirmed by `SimHash`, and were detected on seed 9. Seed 9 exited 0 with "PASS 21 runs … 0 failure(s)". Seeds 7 and 8 each exit 1 alone, under the check's rule that every injection be detected at least once per invocation. That rule is why the check should run with more than one seed.
- One change landed after the long runs: `chkStaleWrong`, which is test-only and computed only under `chkStale`. The desync negative control and all the desync checks ran after it. The rollback check's sessions never set `chkStale`.

## DECISIONS
- **The digest is MD5 over a packed array of chosen fields, not `SimHash`.** It costs one GDScript append per value, and the engine hashes the blocks. The chosen fields are the ones every divergence reaches within a tick or two. `SimHash` stays the full check, and the field walk is the diagnosis.
- **A checkpoint is taken from the last run of its tick and published only once confirmed.** The stale-detector control shows why: a digest of a first run, a guess, raises false alarms under rollback.
- **The field walk is breadth first, and it skips `worldId`.** `worldId` is a per-process counter, so it differs between two sims in one process.
- **The spectator uses a jitter buffer of 6 ticks that grows on an underrun.** With a fixed threshold, the buffer was dry on half the frames at 120 ms.
- **`NetDelay`:**
  - the delay is sized from the 75th-percentile round trip;
  - the budget is 75% of the frame;
  - the delay stays between 2 (the tested default) and 8 ticks;
  - the session takes the larger of the two peers' choices.

  It is calibrated so a desktop keeps 2 ticks up to 120 ms, which matches the bench. It is not yet wired into the loopback checks, which run at a fixed delay.

## NEEDS FROM EP
1. **Tools: CI.** This is the request from the last report, now with the short new checks:
   - `desync_check --seeds=1 --ticks=600 --profiles=lan,p120` (about 40 s). Seed 1 detects every injection; a seed where a small injection heals fails the run's at-least-once rule (RESULTS);
   - `spectator_check --seeds=1 --ticks=600 --profiles=lan,p120,far` (about 25 s);
   - `delay_check` (about 1 s);
   - each check's `--negative-control` at 600 ticks.

   CI's workflow is not mine to change.
2. **A place for desync reports online, at zero budget.** It needs room for the replay and the snapshot (about 160 KB). This is needed before the `vsPeer` walk can run outside the loopback.
3. **Simulation: no change needed.** `perturb` is a test hook in `net/`, and the sim is untouched.

## RISKS
- **The digest covers chosen fields.** A divergence that stays in a field outside it, and never reaches the fighters, RNG, buildings, trees, shots or terrain, is caught only by `SimHash`. In tests every injection reached the digest within the first checkpoint.
- **Byte order.** The MD5 reads packed arrays as little-endian bytes. That holds on every target, but an unproven platform would need the parity gate anyway.
- **One relay per spectator, and a player as the relay.** Many spectators need a server (open question).
- **The delay chooser is calibrated on the loopback's costs.** Real devices' tick, save and restore costs and real round trips should feed it once a transport exists.
- **Healed injections.** A small enough divergence can vanish on its own (the 1-ulp x on seed 2). That is correct behaviour, but it means detection guarantees hold for divergences that persist to a checkpoint.

## NEXT
1. A transport spike: WebRTC data channels (browser) and ENet (native), carrying the same packets, with ping measurement feeding `NetDelay` and frame-advantage time sync.
2. Wire `NetDelay` into the session handshake (taking the larger choice), and run the rollback check at each profile's chosen delay.
3. Snapshot upload for `vsPeer` reports (NEEDS 2), and a spectator relay that is not a player.

Look: nothing a player sees changed.
