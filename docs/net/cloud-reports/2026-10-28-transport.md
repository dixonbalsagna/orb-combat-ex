# Cloud report: the transport layer, ENet, and the delay handshake (Netcode and Online, 2026-10-28)

Brief: `docs/ep/cloud-briefs/netcode-transport.md`. Branch: `cloud/netcode-online/transport`. Design: `docs/net/rollback.md` section 11 (new), with sections 5, 9 and 10 updated.

## SUMMARY
- **The transport.** The session now runs on one transport interface, `NetTransport`. It has two implementations: the loopback's simulated links and ENet (Godot's built-in). A compact binary codec carries the existing packets.
- **The handshake.** Each peer measures its round trips with pings, proposes `NetDelay.choose` for its own device, and the larger proposal wins. During play, packets carry a ping echo and frame advantages, and time sync (GGPO's frame advantage) makes the peer that is ahead wait.
- **The proof.** Two headless Godot processes on 127.0.0.1 play a seeded 3,600-tick match over ENet. On LAN, p120, p200 and far (400 ms, 10% loss), they agree with each other and with the straight run on every confirmed tick. The negative control (a perturbed peer) fails, as it should. The rollback check passes with every profile at its handshake's delay.
- **The sim is untouched** and the golden is byte-identical. WebRTC is designed only (rollback.md section 11).

## CHANGES
All changes are in owned paths (`net/`, `docs/net/`).
- **New:**
  - `net/transport.gd` (`NetTransport`: the interface, and the wire codec);
  - `net/link_transport.gd` (`NetLinkTransport`: the loopback; with `wire`, packets go through the codec);
  - `net/enet_transport.gd` (`NetEnetTransport`: `listen` and `dial`, unsequenced, flushed at once, and an `impair()` test hook that injects latency, jitter and loss);
  - `net/handshake.gd` (`NetHandshake`: ping, propose, hello; it refuses another match or another protocol version);
  - `net/timesync.gd` (`NetTimeSync`);
  - `net/host.gd` (`NetHost`: handshake → session at the agreed delay, time sync, ping during play, packets).
- **New checks:**
  - `net/tools/transport_check.gd`: the codec; the handshake on all 9 profiles × 4 device pairs; two hosts through the codec with a 2% fast clock, a late start and a 40-frame freeze;
  - `net/tools/enet_check.gd` and `net/tools/enet_peer.gd`: the two-process ENet proof;
  - `net/tools/net_straight.gd`: the straight run with per-tick digests.

  Each new check has `--negative-control`.
- **Edited:**
  - `net/loopback.gd`: peers send through `NetLinkTransport`. New: `agree()`, which runs the handshake on a profile's links on simulated time, and a `wire` option;
  - `net/tools/rollback_check.gd`: `--delay=auto` and `--devices=a,b`. The straight run is cached per seed and delay;
  - `docs/net/rollback.md`: section 11 is new, and sections 1, 5, 9 and 10 are updated.

## RESULTS
Every row exited 0.
- **ENet, two processes.** `enet_check --ticks=3600 --profiles=lan,p120,p200,far`: "PASS 4 two-process matches over ENet, 3600 ticks each, 0 failure(s)". Each match took about 64 s of wall time at 60 fps. Each row is checked three ways:
  - the per-tick digest and the feed and fx at all 3,600 confirmed ticks;
  - the `SimHash` every 60 ticks and at the end, against each other and against the straight run;
  - and there was no desync.

  | profile | delay (proposals) | handshake RTT | rollbacks host/joiner | max depth | lost | sent B/s | true lead, 2nd half mean / max |
  | :--- | :--- | ---: | ---: | ---: | ---: | ---: | :--- |
  | lan | 2 (2, 2) | 17 ms | 16 / 40 | 14 | 0 | 7.9 K | 0.4 / 3.3 frames |
  | p120 | 3 (3, 2) | 150 ms | 820 / 743 | 20 | 3% | 10.9 K | 0.8 / 4.3 |
  | p200 | 5 (5, 5) | 233 to 249 ms | 767 / 688 | 19 | 10% | 12.0 K | 0.8 / 5.9 |
  | far | 8 (8, 8) | 433 ms | 640 / 615 | 18 | 10% | 15.6 K | 2.4 / 8.3 |
- **Mixed devices and a freeze.** `--profiles=lan,p120 --slowdowns=1,4 --hitch=1200:40`: PASS, 0 failures.
  - At p120 the proposals were 3 (desktop) and 5 (x4), and both peers ran at 5.
  - After the joiner froze for 40 frames, the true lead went to 21 frames, then back to a second-half mean of 0.3 to 0.5 frames (max 2.1 to 3.1).
- **ENet negative control.** `--ticks=1800 --profiles=lan,p200 --negative-control` (the joiner flips one RNG bit at tick 900): "PASS negative control: 2 of 2 perturbed matches caught". On both profiles the digests part at confirmed tick 901, and desync detection fires at checkpoint 960 on both peers.
- **The transport check.** "PASS 0 failure(s)", seed 1, 900 ticks.
  - A game packet is 104 bytes with 3 inputs and 2 digests.
  - The handshake table is in its output. A desktop pair keeps 2 ticks up to p120; x1/x4 at p120 takes 5.
  - Hosts on lan, p120 and p200 match the straight run at every confirmed tick, with a last-third lead of at most 2 frames.

  Negative control: "PASS negative control: 2 of 2 breaks caught". The two breaks are a handshake that takes the smaller proposal (23 failing cases) and time sync turned off (3).
- **The rollback check at each profile's chosen delay.**
  - `--seeds=1 --ticks=1200 --delay=auto`, all 9 profiles, hash every tick: "PASS 9 sessions, 21600 confirmed-tick hash comparisons, 0 failure(s)". Delays: lan, p40, p80j and p120 got 2; p160 3; p200 5; p200c 4; asym 3; far 8.
  - `--seeds=2 --devices=1,4 --hash-every=4`: "PASS 9 sessions, 5400 confirmed-tick hash comparisons, 0 failure(s)". The delays were 4 to 8, the x4 proposal winning each time.
  - Negative control, `--seeds=1 --ticks=240 --delay=auto`: "PASS negative control: 14 break(s) caught, 0 missed".
- **The existing checks over the refactored loopback:**
  - `desync_check --seeds=1 --ticks=600 --profiles=lan,p120`: "PASS 14 runs, 18 checkpoints matched, 0 failure(s)". Its negative control: "24 break(s) caught, 0 missed".
  - `spectator_check --seeds=1 --ticks=600 --profiles=lan,p120,far`: "PASS 3 spectated sessions, 180 spectator hash comparisons, 0 failure(s)". Its negative control: "16 break(s) caught, 0 missed".
  - `delay_check`: "PASS 0 failure(s)". Its negative control: "2 of 2 broken choosers caught".

**Gates** (last line and exit code):
- `node tools/validate.js`: "278 files checked, 0 errors, 0 warnings", 0
- `--self-test`: "parser 283 files + 7 text cases; engine 46 cases + 6 unsupported; schemas 170; data cases 8177", 0
- `node tools/lint-determinism.mjs`: "determinism lint ok: no engine trig, PI/TAU, random numbers or clock in sim/core, sim/director, sim/world, sim/input", 0
- `npm test --prefix sim` (with GODOT): "all 5 stages passed", with "PASS golden" and "golden check passed", 0. The golden is byte-identical: no sim file changed.
- `anim_check.gd`: "anim check passed", 0
- `split_sweep.gd`: "split sweep passed", 0
- `campaign_episode.gd`: "the two plays are the same to the bit (1800 ticks a stage; 8.5 s and 8.0 s)", 0
- `parity.gd`: "golden check passed", 0
- **The `sim/world/tools/*_check.gd` scripts.** All 40 exited 0, and 39 printed "0 check(s) failed" (craters: "CRATERS CHECK: 0 failed"; lane_check: its avenue table, "… across an avenue: 0").
- **`step_check`** printed "STEP: 1 check(s) failed" (exit 0). It failed on 3 of 3 runs here and on 1 of 3 on a clean checkout of main (31ae23e). The failing line differed between runs, and each was a wall-clock budget:
  - "the longest 45.7 ms" against `< 25.0`;
  - "no call of the job is long: the longest 36.9 ms".

  Its bit-for-bit comparisons hold. It is a timing flake on a loaded 4-core container, with nothing from `net/` involved. World should know that the script exits 0 even when it fails.

## DECISIONS
- **The protocol is unreliable and unordered on every transport.** It needs nothing better, since every packet resends whatever has not been acknowledged. This lets ENet unsequenced and a WebRTC channel with `ordered: false, maxRetransmits: 0` behave the same, and the loopback's loss and reordering stay a faithful model.
- **A binary codec for game packets.** Godot's Variant encoding cost about 360 bytes a packet (21 KB/s). The fixed layout is 40 bytes plus 8 per input and 20 per digest. Handshake packets keep Variant encoding, which never decodes objects.
- **Round trips are measured on the sender's own clock** (ts, echo, age), so the peers' clocks never have to agree. They include the wait for the next frame, which inputs pay too.
- **Pings sent before the other peer has been heard from don't count.** Without this rule, a late start made a LAN handshake pick 8 ticks.
- **Time sync waits after a quiet period of one round trip.** It decides on fresh samples only. Without that, at 400 ms both peers took turns waiting.
- **The match's end is a tick cap (3,600 ticks, one minute).** No bot match reaches a KO: in 15,000 ticks the fighters sit at 0 HP and no decisive exchange fires, with AI on or off.
- **The proof hashes every tick cheaply.** The full `SimHash` costs 26 ms, too much for every tick of a match at 60 fps. So the proof compares the digest and the feed and fx at every confirmed tick, and the full `SimHash` every 60 ticks and at the end. The rollback check still compares the full hash at every tick.

## NEEDS FROM EP
1. **A ruling on outside services for internet play (ADR 0005).** WebRTC across the internet needs a STUN server (free public ones exist), and some players also need TURN, which costs money. ENet over the internet needs a reachable port, or hole punching that also needs a rendezvous. Without either, play is limited to LANs and copy-pasted WebRTC offers on a LAN.
2. **A ruling on the `webrtc-native` GDExtension** (a new dependency) if native-to-browser cross-play is wanted. Without it, browsers play browsers and native plays native.
3. **Tools: CI.**
   - `transport_check` and its negative control (about 1 min each);
   - `rollback_check --delay=auto --seeds=1 --ticks=300`;
   - optionally `enet_check --ticks=600 --profiles=lan,p120` (about 30 s; it needs loopback UDP on the runner).

   CI is not mine to change.
4. **World: `step_check`'s time budgets flake under load, and the script exits 0 on a failure** (see Gates).
5. **Encounter.** Is there a way to end a scripted-input match? A KO under rollback still hasn't run (rollback.md section 6).

## RISKS
- **Time sync is loose on long links.** At 400 ms the mean lead is 2.4 frames, with peaks near 8. It is within the check's bounds (a mean of 3, a max of 12), but a tighter estimate, such as filtering the one-way time, would cut rollbacks further.
- **Bandwidth is 8 to 16 KB/s a peer**, mostly the repeated checkpoint digests. That is fine on broadband and wasteful on mobile. Sending only the digests the other side has not matched would cut it by half or more.
- **The frame-time tails in the ENet proof (p99 50 to 78 ms) are the test's own cost:** saves before every tick, and a `SimHash` every 60 ticks. They are not a game's, but they were present while time sync was measured.
- **One machine.** Both processes ran on 127.0.0.1 with injected impairment. Real NATs, real loss bursts and clock drift between machines are untested.
- **WebRTC is only a design.** Its signalling by copy and paste is clumsy.

## NEXT
1. Build `NetWebRtcTransport` and run a two-tab browser test of the web export, locally (no browser runs in the cloud).
2. Cut the bandwidth (send only the digests the other side has not matched; delta-code the inputs), and tighten the time-sync estimate.
3. Change the delay mid-match from `NetHost.rttMs()`, with both peers agreeing on the tick it changes at.

Look: nothing a player sees changed.
