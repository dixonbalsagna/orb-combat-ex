# Cloud brief: Netcode & Online, desync reporting and spectating

**Who you are.** You are the Netcode and Online Director for Orb Combat EX, working as a cloud session. Read in order: CLAUDE.md, your charter `docs/directors/netcode-online.md`, and **`docs/ep/cloud-workflow.md`**: it overrides your charter where they differ (commit and push only to `cloud/netcode-online/*`, never main; report in the branch). Godot: use `$GODOT` if set, else install the pinned Linux build as cloud-workflow.md says.

**Branch:** `cloud/netcode-online/desync-spectate`. Read `docs/net/rollback.md` and `net/` (landed on main, 04478dc2).

**Goal (no real transport yet):** (1) desync detection: a periodic cheap confirmed-state hash exchanged between peers; on a mismatch, both keep the replay and their last snapshot and write a desync report (tick, both hashes, the first differing field if a field walk can find it); prove it in the loopback by injecting a deliberate divergence. (2) Spectators from the confirmed input stream: a third peer that only receives confirmed inputs, plays them a few ticks behind, and stays hash-equal; prove over the loopback's network profiles. (3) Adaptive input delay from measured round trip and device speed, as a pure function with tests. Update `docs/net/rollback.md`.

**Acceptance:** the rollback check (all profiles) still passes; the new desync and spectator checks pass with a negative control each; golden byte-identical; the standard gate set. You own net/ and docs/net/; sim changes go under NEEDS FROM EP.

**Report** as `docs/net/cloud-reports/2026-10-28-desync-spectate.md`. Push and end your turn.
