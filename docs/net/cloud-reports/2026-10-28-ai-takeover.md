# Report: the AI takes over a dropped player, and the calm turn under rollback (Netcode and Online, 2026-10-29)

Brief: `docs/ep/cloud-briefs/netcode-ai-takeover.md`, run locally (wave B). The EP's local terms:
- work in the shared tree, own paths only, with no branch, commit or push;
- at most 3 Godot at once, at below-normal priority;
- 3 CPU-hours in all.

Design: `docs/net/rollback.md` section 13 (new). The header and sections 2, 6 and 10 are updated, and section 12 now carries the note on Encounter's ruling and statics audit.

Every Godot run used a scratch export of HEAD with only my `net/` files copied in. The export started at `40d5ee92` and was brought to `85e84452` before the gates; nothing in `sim/` or `net/` changed between the two.

## SUMMARY
- **The takeover.** Either peer can hand a slot to the sim's own AI at an agreed tick T. The proposer picks T as its frame plus the input delay, the first tick whose input it has not sent. Every packet carries the record, so no peer can confirm T without it, and a late takeover rolls back exactly like a late input.
- **A vanished peer.** The survivor drops the slot after a timeout. It fills the missing inputs with what its ticks ran with, so it rolls nothing back.
- **Proof of both.** Every confirmed tick equals a straight run that toggles the slot at T, on lan, p120 and far, for 3 seeds, by either proposer, with the bots and with both AI modes. A peer that switches a tick late is caught wherever tick T is live. The sim is untouched and the golden is byte-identical.
- **The calm turn under rollback.** A re-run warm tick or swap gives the same gameplay state. That holds for the bots, the driven AI and the sim's own AI, with a forced turn, and for the director's own turn, which I switched on in the check's process.
- **Two diagnoses.**
  - **World:** a rollback that re-runs the swap reads its ring cold. Two unhashed counters end at 1, and the rollback frame pays the whole read.
  - **Simulation:** `SimHash` of a past snapshot, read in place, sees the swap's new district numbers. That is a false alarm in checks, not a fault in play. A two-line fix is parked.
- **I went over the CPU cap:** about 4 CPU-hours against 3 (RISKS).

## CHANGES
All in owned paths. Every file is ready, and I freeze them until the EP commits.

**Code.**
- `net/session.gd`:
  - the takeover record (`aiFrom`) and its two entry points, `proposeTakeover` and `dropSlot`;
  - `takeover`, which drops superseded inputs and rolls back if T has already run;
  - `_switch`, which calls `SimCore.toggleAI` before tick T on every run, after the save;
  - helpers: `hasInput`, `confirmedInput`, `ackOf`, `takeoverList`;
  - tests only: `onRollback`, `beforeTick`, `aiLate`, `aiOnce` and `fillWrong`.
- `net/loopback.gd` and `net/host.gd`: takeovers ride in every game packet (`ai`), applied before its inputs. The spectator relay forwards them. The loopback can make a peer vanish (`gone`, `heard`).
- `net/transport.gd`: an optional takeover section in the binary codec: a count, then slot and tick, 6 bytes for one. A packet without takeovers is byte for byte as before.
- `net/handshake.gd`: protocol version 2.
- `net/spectator.gd`: applies forwarded takeovers before tick T.
- `net/desync.gd`:
  - a desync report's replay carries the takeovers as `toggles` (`togglesOf`), and `replayState` plays them;
  - the field walk now compares shared generation records (their `FIELDS`) by value. Before this it could not see a building's district.

**Checks.**
- `net/tools/rollback_check.gd`:
  - new options: `--takeover=T` with `--slot` and `--by`; `--drop=F` with `--timeout`; `--turn-at=N`; `--calm-director`; `--walk-at=B`;
  - new negative controls: `late` (applies when tick T is live), `once` and `fill`;
  - calm-turn tracking: rollbacks restoring inside the window or running the swap again, the full SimHash over the turn, a field walk 60 ticks after it;
  - the full SimHash for 60 ticks after a takeover;
  - the read-only sharing of a decided turn's ring spec, checked in the code and allowed;
  - World's process caches counted and cleared before the leak count.
- `net/tools/transport_check.gd`: codec cases for takeovers.

**Docs.**
- `docs/net/rollback.md`.
- `docs/net/pending/simhash-past-roots.patch` and its `README.md`: Simulation's two lines, parked.
- This report.

## Results (pass unless marked)

**The takeover and the drop** (`net/tools/rollback_check.gd`):

| run | last line |
| :--- | :--- |
| `--takeover=600 --seeds=1,2,3 --ticks=1200 --profiles=lan,p120,far` (bots, both proposers) | `PASS  18 sessions, 43200 confirmed-tick hash comparisons, 0 failure(s)` |
| the same with `--negative-control` | `PASS  takeover negative control: 13 break(s) caught, 0 missed, 5 not applicable` (the 5: no rollback re-ran T) |
| the same with `--sparse=2` (saving as a game does) | `PASS  18 sessions, 32145 confirmed-tick hash comparisons, 0 failure(s)` |
| `--ai --takeover=900 --seeds=1,2,3 --ticks=1800 --profiles=lan,p120,far` | `PASS  9 AI sessions, ... 32400 confirmed-tick digest and 1602 SimHash comparisons ..., 0 failure(s)` |
| the same with `--negative-control` | `PASS  takeover negative control: 8 break(s) caught, 0 missed, 10 not applicable` (late caught at tick 901 on every live T; T frozen 3 times; no re-run of T 7 times) |
| `--ai=sim --takeover=900`, same arguments | `PASS  9 AI sessions, ... 32400 confirmed-tick digest and 540 SimHash comparisons ..., 0 failure(s)` |
| `--drop=600 --seeds=1,2,3 --ticks=1200 --profiles=lan,p120,far` | `PASS  9 sessions, 10800 confirmed-tick digest and 10800 SimHash comparisons, 0 failure(s)` (the survivor dropped at tick 624 in all 9) |
| the same with `--negative-control` | `PASS  takeover negative control: 9 break(s) caught, 0 missed, 0 not applicable` |
| `--ai --drop=900 --seeds=1,2 --ticks=1800` | `PASS  6 AI sessions, ... 10800 confirmed-tick digest and 180 SimHash comparisons ..., 0 failure(s)` |

On p120 and far, the takeover reached one of the two peers after that peer had already run tick T. Its rollback made it exact.

**The calm turn** (`--setup=calm`):

| run | result |
| :--- | :--- |
| bots, `--turn-at=300`, seeds 1 to 3, lan, p120, far, on HEAD | **FAIL** 6 of 9: SimHash differs at the last ticks before the swap on p120 and far (the past-root misread; the field walk of those states is clean) |
| the same with the parked `hash.gd` patch (scratch only) | `PASS  9 sessions, 16200 confirmed-tick hash comparisons, 0 failure(s)`; per session on p120 and far, 17 to 34 rollbacks restored inside the warm window and up to 6 ran the swap again |
| `--ai --turn-at=600 --seeds=1,2 --ticks=1500`, lan, p120, far (patched) | `PASS  6 AI sessions, ..., 4966 SimHash comparisons ..., 0 failure(s)` (4 swapped at 643 to 739; far's 2 stayed waiting for calm) |
| `--ai=sim`, the same (patched) | `PASS  6 AI sessions, ..., 2502 SimHash comparisons ..., 0 failure(s)` (all 6 swapped, at 671 and 782) |
| `--ai=sim --calm-director --seeds=1 --ticks=7200` (patched) | `PASS  3 AI sessions, ..., 9504 SimHash comparisons ..., 0 failure(s)` (decided 4923, swapped 6350 on all three; 208 to 259 rollbacks restored inside the window) |
| `--ai --calm-director --seeds=1 --ticks=9300` (patched) | `PASS  3 AI sessions ...` (lan swapped at 8783; p120 and far decided no turn) |
| field walk 60 ticks after each swap | clean in every AI run. A swap re-run by a rollback (`--walk-at`, bots, p120) differs only in `S.epoch.cold` 1 vs 0 and `S.epoch.unprep` 1 vs 0 |

**The standard gates**, on the HEAD `85e84452` export plus my `net/`:
- `node tools/validate.js`: `280 files checked, 0 errors, 0 warnings`, exit 0
- `node tools/validate.js --self-test`: `parser 285 files + 7 text cases; engine 46 cases + 6 unsupported; schemas 172; data cases 8198`, exit 0
- `node tools/lint-determinism.mjs`: `determinism lint ok: no engine trig, PI/TAU, random numbers or clock in sim/core, sim/director, sim/world, sim/input`, exit 0
- `npm test --prefix sim -- --only=unit,parity,soak,golden`: `all 4 stages passed` (golden PASS), exit 0. Its Godot stage is `parity.gd`, listed next. An earlier full `npm test` on `40d5ee92` gave `all 5 stages passed`.
- `sim/core/tools/parity.gd`: `golden check passed`, exit 0. The same line again with the parked patch applied in scratch.
- `render/anim/tools/anim_check.gd`: `anim check passed`, exit 0
- `render/camera/tests/split_sweep.gd`: `split sweep passed`, exit 0
- `sim/core/tools/campaign_episode.gd`: `the two plays are the same to the bit (1800 ticks a stage; 3.6 s and 2.8 s)`, exit 0
- `sim/world/tools/*_check.gd`, all 41: each `0 check(s) failed` (LANES: `buildings of row 1 or 2 across an avenue: 0`; CRATERS: `0 failed`), all exit 0

**Net, CI's arguments:**

| check | last line |
| :--- | :--- |
| rollback | `PASS  3 sessions, 1800 confirmed-tick hash comparisons, 0 failure(s)` |
| rollback, negative control | `PASS  negative control: 4 break(s) caught, 0 missed` |
| desync | `PASS  14 runs, 18 checkpoints matched, 0 failure(s)` |
| desync, negative control | `5 break(s) caught, 0 missed` |
| spectator | `PASS  3 spectated sessions, 180 spectator hash comparisons, 0 failure(s)` |
| spectator, negative control | `5 break(s) caught, 0 missed` |
| delay | `PASS  0 failure(s)` |
| delay, negative control | `2 of 2 broken choosers caught` |
| transport | `PASS  0 failure(s)` (with the new codec cases) |
| transport, negative control | `2 of 2 breaks caught` |
| enet | `PASS  2 two-process matches over ENet, 1800 ticks each, 0 failure(s)` |
| enet, negative control | `2 of 2 perturbed matches caught` |
| `--ai` | `PASS  3 AI sessions, ..., 0 failure(s)` |
| `--ai`, negative control | `7 break(s) caught, 0 missed` |
| `--ai=sim` | `PASS  3 AI sessions, ..., 0 failure(s)` |
| `--ai=sim`, negative control | `7 break(s) caught, 0 missed` |
| depth | `PASS  3 sessions, 1800 confirmed-tick hash comparisons, 0 failure(s)` |
| depth, negative control | `4 break(s) caught, 0 missed` |
| planet2 | `PASS  3 sessions, 1800 confirmed-tick hash comparisons, 0 failure(s)` |
| planet2, negative control | `4 break(s) caught, 0 missed` |
| Simulation's `two_states_check` | `PASS  0 failure(s)` |
| `two_states_check`, negative control | `3 of 3 breaks caught` |

All exit 0.

**Which version each result ran on.** The gate set ran on my files at 05:14. Two later edits to `rollback_check.gd` are check-only:
- the "late" control applies when tick T is live, and the straight run records frozen ticks;
- the full SimHash for 60 ticks after a takeover.

`--ai --takeover` (both ways) and the bot takeover's negative control were rerun on the final files, as the table shows. `desync.gd` is the gated version.

## DECISIONS
1. **The takeover is a toggle at an agreed tick, at least the input delay ahead.** It uses the sim's existing `SimCore.toggleAI` and the replay format's `toggles`, so no sim line was needed. Choosing T as the proposer's frame plus delay makes a late takeover a late input. The earliest proposal wins, so peers that heard two converge.
2. **A dropped peer's missing inputs are the ones the survivor's ticks ran with.** No rollback, no visible jump. Only the survivor carries on. A vanished peer cannot rejoin the same timeline without a state transfer, which is not built.
3. **Handing the slot back to a human is not built.** The same record with an "off" tick would carry it. A reconnecting player needs the state first.
4. **The calm turn was crossed two ways**, because the director's part is off in the data (`calmTurn.enabled: false`):
   - a decision forced on every run, as Simulation's `two_states_check` does;
   - the director's own turn, switched on in the check's process only, as `parity.gd` does for its gen 2 case.
   The data file is untouched.
5. **A field-walk difference after a swap is printed, not failed.** The only one found, the two counters of a re-run swap, is unhashed diagnostics with the same gameplay state. SimHash, the digest and the feed decide pass or fail.
6. **A one-tick-late takeover on a frozen tick is not a break.** No control runs on that tick, so the late peer's state is identical, and the control reports it as not applicable. In AI mode a late sim AI can converge back within 60 ticks, so the check hashes every tick for 60 ticks after T.
7. **I stopped and reverted one improvement to stay near the cap.** Adding the AI's timers to the desync digest would catch that late start on every tick, but it would need every net check rerun. It is listed under NEXT.

## NEEDS FROM EP
1. **Simulation: apply `docs/net/pending/simhash-past-roots.patch`** (2 lines in `sim/core/hash.gd`).
   - What it does: when structures are bound, it reads a building's and a tree's generation fields through `S.bG` and `S.tG`.
   - Why: without it, `SimHash.stateHash` of a past snapshot read after a calm turn's swap sees the new districts, because a copy-on-write gave the live record a new `BuildingGen`.
   - Evidence: `rollback_check --setup=calm --turn-at=300` fails on HEAD (p120 and far) and passes with the patch. `parity.gd` with the patch: `golden check passed`. A live state hashes exactly as before.
   - Details: `docs/net/pending/README.md`.
2. **World: keep the swapped ring's job and preparation for a while after the swap**, at least `maxAhead` + 1 = 21 ticks, or until the next pick.
   - Today `swap()` drops them (`_dropJobs`). A rollback that runs the swap again then reads the ring cold on the rollback frame: World's own notes put the swap tick at 8.7 ms, and 38 to 46 ms at x4, before the warm-up spread it. It also leaves `S.epoch.cold` and `S.epoch.unprep` at 1 where a straight run has 0.
   - Moving those two counters out of the state, as process diagnostics like the caches, would make a re-run state identical.
   - Related: `SimCore.dispose` leaves a disposed sim's `_plans` and `_jobs`, a small leak for a host that plays many planet matches in one process. The check clears them and reports them.
3. **Tools (CI)**: add to the `net` job, a minute or two each:
   - `rollback_check.gd -- --takeover=150 --seeds=1 --ticks=300 --profiles=lan,p120,far`, plus the same with `--negative-control`;
   - `--drop=150` with the same arguments, plus the same with `--negative-control`;
   - after Simulation's patch: `--setup=calm --turn-at=300 --seeds=1 --ticks=600 --profiles=lan,p120,far`.
4. **The EP's ruling:** whether the 1-hour overrun of the CPU cap needs anything more from me.

## RISKS
- **The CPU cap was exceeded.** About 4 CPU-hours were used (3.6 to 4.7 by two ways of counting; each job's CPU time was within a second of its wall time) against 3. The full gate set on the clean export alone was about 2.5. Three things added to it:
  - one run started without its arguments (my wrapper dropped the `--`) and played the full default set for about 9 minutes before I stopped it;
  - early on, `npm test` found Godot on its own and ran `parity.gd` for about 5 minutes at normal priority, a 4th Godot job beside my three;
  - after the gates I started a full net rerun for the digest change, then stopped my three jobs, checked by parent and path, and reverted the change.
  Every other job ran at below-normal priority, at most 3 at once, and nothing of mine is still running.
- **More than two peers.** With more than two peers, a drop's fill must travel with the record so that every survivor uses the same inputs. Two-peer only today.
- **The host's drop policy is not built.** The check uses 30 frames; a game wants seconds and a notice to the player. A peer that is only partitioned and comes back must be told it was dropped, because its own last ticks may disagree with the fill.
- **The director's calm turn is off in the data.** These runs prove the rollback, not the feature. A change to `calmTurn.enabled` should rerun the `--calm-director` set.
- **No AI run re-ran a swap.** The AI's swaps came at calm moments that no late input contradicted. The cold re-run is proven with the bots only.

## NEXT
1. Simulation's patch and World's keep-after-swap, then the calm set in CI.
2. The AI's timers in the desync digest (a 5-line change in `net/desync.gd`), with a rerun of every net check.
3. The host's drop policy: a timeout in `NetHost` that calls `dropSlot` and shows a notice, tested over ENet with a killed peer process.
4. Then the transport report's NEXT: WebRTC, bandwidth, and changing the delay mid-match.

Look: nothing a player sees changed.
