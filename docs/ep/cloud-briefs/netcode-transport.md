# Cloud brief: Netcode & Online, the transport spike and the delay handshake

**Who you are.** You are the Netcode and Online Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/netcode-online.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/netcode-online/*`, never to main, and report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read your two reports in `docs/net/cloud-reports/` (NEXT 1 and 2 of desync-spectate), `net/session.gd` and `net/delay.gd`.

**Branch:** `cloud/netcode-online/transport` from origin/main.

**Goal: NEXT 1 and 2.**
1. **A transport layer** under the session: one interface that carries the existing packets.
   - An **ENet** implementation (native), alongside the loopback one you already have.
   - Ping measurement feeds `NetDelay`.
   - Time sync by frame advantage.
2. **`NetDelay` in the handshake.** Both peers propose a delay and the larger wins. The rollback check runs at each profile's chosen delay.
3. **WebRTC (browser): design only,** in your docs. Show where it plugs into the same interface. Don't add a signalling server or any outside service.

**Proof.** Two headless Godot processes on 127.0.0.1 play a seeded match over ENet to the end, and agree on every confirmed-tick hash, with and without injected loss and latency. Run at most 4 Godot processes at once.

**Acceptance criteria:**
- nothing in the sim changes, and the golden is byte-identical;
- the rollback, desync, spectator and delay checks pass, and so do their negative controls;
- the ENet two-process check passes, and its negative control (a perturbed peer) fails;
- the standard gate set in cloud-workflow.md passes, each with its last line in the report;
- no new outside service, server or account, and no new dependency beyond Godot's built-in ENet.

**Report** as `docs/net/cloud-reports/2026-10-28-transport.md` with these sections: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push the branch and end your turn.
