# Report: the AI's timers in the desync digest, and the computer's level in the match key (Netcode and Online, 2026-10-30)

Brief: the EP's message of 2026-10-30, run locally. Terms: own paths, no commit, at most 3 Godot jobs at below-normal priority, no local `enet_check`, 2 CPU-hours.

Design: `docs/net/rollback.md`, sections 2, 6, 7, 11 and 13 (new subsection "The computer's level online").

Every Godot run used a scratch export of HEAD `553ac274` with only my `net/` files copied in.

## SUMMARY
- **The AI's timers are in the digest.** `NetDesync.digest` now reads `f.ai`'s five timers, and a slot with no AI adds a marker. A change to any one timer on the tick before a checkpoint is reported by both peers at that checkpoint, and the field walk names it.
- **The negative control found the old digest was blinder than the doc said.** With the timers left out, the four 1e-6 changes were never reported in the rest of the 600-tick run, and the stance change only at the next checkpoint. The doc said a divergence shows within a tick or two. I corrected it.
- **The takeover's late switch is now caught by the digest.** All 8 live breaks in `take_ai_neg` read "the state's digest differs". Before, some were found only by the SimHash window after T.
- **Does the online setup carry `aiLevel`? It does when the host passes it.** There were two gaps, and the fix closes both:
  - the handshake did not compare `SimReplay.dataHash` (UI's question, and contract point 8);
  - a setup with no level runs at whatever `DirAI.level` the process last held, so a peer fresh from a Hard match offline had the same key as a fresh peer, and they would have played different AIs from the first takeover.
- **The fix is one line:** `NetHandshake.keyOf` appends `SimReplay.dataHash(setup)`. No sim line is touched.
- **Still true:** no game code starts an online match yet, and the setup does not go over the wire. The future online host must send it in the lobby.

## CHANGES
All in owned paths, ready and frozen until the EP commits. Nothing is parked outside `net/` and `docs/net/`.
- `net/desync.gd`: the timers in `digest`; `aiBlind`, a tests-only switch.
- `net/handshake.gd`: `keyOf` holds the data hash; `keyPlain`, a tests-only switch; `PROTO` 3.
- `net/tools/desync_check.gd`: `--ai-timers`, with `--negative-control`.
- `net/tools/transport_check.gd`: `_levelKeys` (two peers at Hard agree; Hard against Easy is refused; a setup with no level against a process left at Hard is refused), and a third negative-control break.
- `net/tools/rollback_check.gd`: `--ai-level=`.
- `docs/net/rollback.md`: the sections above.
- Deleted `docs/net/pending/README.md` (untracked): it described the simhash patch, which is on main as 8591e30a.

## Gate last lines (all exit 0)
| check | last line |
| :--- | :--- |
| `desync_check --ai-timers --seeds=1 --ticks=600 --profiles=lan,p120` | `PASS  AI timers: 0 failure(s)` |
| ... `--negative-control` | `PASS  AI timers negative control: 10 break(s) caught, 0 missed` |
| `transport_check` | `PASS  0 failure(s)` |
| ... `--negative-control` | `PASS  negative control: 3 of 3 breaks caught` |
| `--ai=sim --ai-level=hard --takeover=900 --seeds=1 --ticks=1800`, lan, p120, far | `PASS  3 AI sessions, ... 10800 confirmed-tick digest and 534 SimHash comparisons` |
| same, `--ai-level=easy` | `PASS  3 AI sessions, ... 10800 confirmed-tick digest and 534 SimHash comparisons` |
| `--ai --takeover=900 --seeds=1,2,3 --ticks=1800 --negative-control` | `PASS  takeover negative control: 8 break(s) caught, 0 missed, 10 not applicable` |
| every other net step in CI, at CI's arguments, with its negative control (rollback, desync, spectator, delay, `--ai`, `--ai=sim`, depth, planet2, `--takeover`, `--drop`, calm turn) | all PASS |
| `two_states_check` and its negative control | `PASS  0 failure(s)`; `PASS  negative control: 3 of 3 breaks caught` |
| `--ai` and `--ai=sim` with `--takeover=900`, seeds 1 to 3 | each `PASS  9 AI sessions, ... 32400 confirmed-tick digest and 1602 SimHash comparisons (every 60 ticks), 0 failure(s)` |
| `npm test --prefix sim -- --only=unit,parity,soak,golden`, below-normal priority | `all 4 stages passed` |
| `tools/validate.js`, its self-test, `tools/lint-determinism.mjs` | `281 files checked, 0 errors, 0 warnings`; self-test ok; `determinism lint ok` |

Not run:
- `enet_check`, by the rule. It is CI's, and it is the one check that exercises `PROTO` 3 and the longer key across two real processes.
- The render, World and QA gates: no file they read changed.

## DECISIONS
1. **The whole data hash goes into the key, not only the level.** It closes contract point 8 with the same line, and it refuses peers on different data files. Those peers would otherwise pass the handshake and desync.
2. **`PROTO` goes to 3.** A peer on the old digest would raise false desyncs against a new one, so it is refused with a clear reason. Nothing has shipped, so this costs nothing.
3. **A stale level is refused, not corrected.** Silently setting the level inside the handshake would write a sim static from `net/`. The future host names the level, as `_match_setup` already does.
4. **The SimHash window after T stays.** SimHash holds more than the digest does.
5. **Medium against no key is refused.** They run the same match on two fresh processes, but the setups differ. It is the safe way round, and a host that sends one setup never meets it.

## NEEDS FROM EP
1. **CI (Tools' file):** two new steps in the net job:
   - `desync_check.gd -- --ai-timers --seeds=1 --ticks=600 --profiles=lan,p120`
   - `desync_check.gd -- --ai-timers --seeds=1 --ticks=600 --profiles=lan,p120 --negative-control`
2. **UI:** the answer above for its parked question (`docs/ui/pending/ai-level-hash/README.md`): the handshake now compares `SimReplay.dataHash(setup)` of the session's setup, so it carries the level. Medium and no key give the same data hash but different keys.

## RISKS
- **Cross-platform data hash.** If two builds hash the data files differently (line endings, for example), they now refuse each other. Peers from one export hold the same bytes, and `SimReplay` already relies on this. CI's ENet run uses one checkout, so it won't show this. The first cross-platform online test will.
- **A key made before `newMatch`** reads the process's old level. The contract is written on `keyOf`, and `enet_peer` already calls it after `newMatch`. `rollback_check`'s and `transport_check`'s keys are made in one process, so they can't show the difference.

## CPU
About 45 CPU-minutes at most against the 2-hour cap (3 jobs for about 15 minutes of wall time). Nothing of mine is still running.

## NEXT
Idle and frozen. The NetHost drop policy and WebRTC wait for a brief.
