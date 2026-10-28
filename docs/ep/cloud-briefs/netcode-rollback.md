# Cloud brief: Netcode & Online, a deterministic rollback core

**Who you are.** You are the Netcode and Online Director for Orb Combat EX, working as a cloud session. Read in this order: CLAUDE.md, your charter `docs/directors/netcode-online.md`, and **`docs/ep/cloud-workflow.md`**. The cloud workflow overrides your charter where they differ: you commit and push, but only to `cloud/netcode-online/*` branches, never to main, and you report in the branch because you can't message anyone. Then read `docs/ep/vision.md` (online after launch; platforms down to old laptops and phones), `docs/tools/web-parity.md` (native and web match bit for bit), and `sim/core` (SimCore, SimState, SimHash, the fixed step) plus `sim/input`.

**Branch:** `cloud/netcode-online/rollback-core`, from origin/main.

**Goal.** Build rollback netcode's core on our deterministic sim, with no real network transport yet:
- input delay plus prediction;
- a history of confirmed and predicted inputs per player;
- snapshot and restore of the full sim state;
- rollback and re-simulation whenever a late input differs from what was predicted;
- a two-peer loopback harness that simulates latency, jitter and packet loss.

**Acceptance criteria:**
1. In the harness, both peers' SimHash agree at every confirmed tick, across many seeds and network profiles (0 to 200 ms, with jitter, and 0 to 10% loss), and both match a straight, non-networked replay of the same inputs.
2. Re-simulation cost is measured in ticks per frame, natively, with an estimate for x4 (a phone), against the 16.7 ms frame budget. Report the cost of snapshot and restore, and the snapshot's size in bytes.
3. The director's procedural decisions reproduce identically under rollback (seeded RNG only).
4. The golden is byte-identical, and the standard gate set in cloud-workflow.md passes.
5. A short design doc, `docs/net/rollback.md`, covers: the model, the determinism contract, what the director needs, the cost on weak devices, and the open questions (transport, matchmaking, spectators, desync reporting).

**Ownership.** You own `net/` and `docs/net/`. If snapshot or restore needs changes in `sim/core` or `sim/director`, don't make them: list each one exactly under NEEDS FROM EP. A wrapper in `net/` that copies SimState is fine.

**Report** as `docs/net/cloud-reports/2026-10-28-rollback-core.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push the branch and end your turn.
