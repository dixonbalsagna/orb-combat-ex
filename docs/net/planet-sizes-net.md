# Planet sizes and the netcode (2026-11-14)

World's five sizes (`docs/world/pending/planet-sizes/`, setup key `planetSize`, landing GW1c) seen from `net/`. This is paper only: nothing was built or run. The figures are World's (168 KB of per-column state at medium, 672 KB at huge) and the rollback core's measured costs on the reference PC (`docs/net/rollback.md` section 5: a tick 0.60 ms, a snapshot take 1.57 ms, a restore 2.45 ms, about 160 KB, about 120 KB of it terrain arrays).

## 1. Does the handshake carry the size?

**It compares it. It doesn't send it.**
- The match key is `seed | ai | setup` as sorted JSON, plus `SimReplay.dataHash(setup)` (`net/handshake.gd:112`). A `planetSize` in the setup is in the key, so two PCs on different sizes refuse each other at the handshake, before tick 0.
- The setup itself never goes over the wire. NetLan's setups are constants in the game on both PCs, so LAN plays whatever size those constants name. Today they name none, which is medium (World: "a size the data does not have plays medium").
- A saved match's replay carries the setup, so a report replays at its own size with no change.

**What's missing,** for A3, when the host chooses (LAN inside the game, A-NET-02): the hello carries the agreed setup (size and planet seed), and the joiner adopts it. That's the same PROTO 6 change already priced for the planet seed (`docs/net/a1-wave2.md` §3). The size is one more field: about 0.1M tokens for both together, with `lan_check` rows for a joiner on another size (refused today, adopted after) and a control.

**A smaller gap:** `dataHash` covers the combat and roster data, not `data/biomes/sizes.json`. Two PCs with the same size key but different size data would build different planets. The first checkpoint (60 ticks) would catch that as a desync, not the handshake as a refusal. Both PCs run one LAN folder, so it can't happen on LAN today. The clean fix is for the hello to compare the build id (A-NET-05's `SimReplay.buildId()`), which covers all data and code; I can park that with the PROTO 6 work.

## 2. The snapshot at huge: join and rollback

**Join: no change on the wire.** No state is sent when a PC joins. Each PC builds the planet from the seed and setup, and the link opens after its own world is made. So the cost of a bigger planet at join is each PC's own make: World measured 4 to 10 s cold at big and huge on a loaded machine, and the old PC will be slower. The host waits ("Waiting for the other PC") with no timer running.
- **One risk to check:** the drop rule hands a silent PC's seat to the computer after 8 s (`NetLan.DROP_MS`). If a PC's first frames after the session starts take that long (a lazy build at match start, the first tiles drawn), the other PC would drop it. Performance should read the first-frame time at huge on the old PC.
- **If it's long,** the fix is in `net/` and small: the drop timer starts only after both PCs report their first tick drawn (a "ready" field in the hello's last step).

**Rollback: more copying, but not 4x the cost.**
- A save copies the whole state. The per-column arrays copy as one block each, so their cost is memory bandwidth: 672 KB is about 0.1 to 0.3 ms per take and the same per restore, against 0.03 to 0.08 ms for 168 KB.
- Most of today's 1.57 ms take and 2.45 ms restore is the object graph (about 5,000 fields, the fighters, the director). That doesn't grow with the size, because buildings and trees keep their per-tick fields in the state's packed arrays (more places only make those arrays longer). World also finds the tick doesn't grow with the size.
- A rollback of depth D costs restore + (D + 1) × (tick + save every `saveEvery`). On LAN (`saveEvery` 2, at most 8 deep) huge adds about 1 to 1.5 ms to the worst rollback frame. That's inside the frame on the main PC.
- On LAN a rollback happens only when the other PC is late (none on a clean link; on the old PC's hitches, 16 to 20 ticks deep was the old, unverified figure before N1 to N4 capped it at 8).
- **Memory:** about six live saves, 4 MB at huge against 1 MB at medium.
- **One thing that may matter more:** NetLan keeps `SimHash`'s gameplay hash at every checkpoint (every 60 ticks) for the saved match's replay. `rollback.md` measured a full `SimHash.stateHash` at about 25 ms long ago. If it walks the per-column arrays, it grows with the size and is a once-a-second spike, at medium already over a frame. It needs a fresh reading at medium and huge before anything else here. The cheap digest (MD5 over the same arrays) is about 1 ms at huge, once a second.

**If it's too big, in order of cost:**
1. **Save less often at big and huge:** `NetLan.tune` sets `saveEvery` 3 or 4 by size. Fewer copies, a few more re-run ticks (a tick is the cheap part). One line in `net/`, with a `lan_check` row.
2. **Copy only the columns that changed:** the per-column arrays kept in chunks of, say, 256 columns, with a dirty mark per chunk set where terrain is written (craters, scorch, rubble). A save copies the dirty chunks and shares the rest with the previous save. That's a layout change in Simulation's and World's state (the digest and `SimHash` read the chunks as before), with `NetSnapshot` copying chunks. About 0.2M tokens across the three areas, and it makes a save's terrain cost a few KB at any size.
3. **An undo log instead of copies:** terrain writes record (column, old value) while a save is live, and a restore plays them back. It's the smallest at run time, but every writer of terrain must go through one function. It's more invasive than (2).
- **For a future rejoin** (not built), the state to send is the snapshot: about 700 KB at huge, under a second on a LAN. Sending only what differs from the generated planet (the deformation, since both PCs regenerate the base from seed and size) makes it tens of KB.

**What I'd do now:** nothing in code. Performance's quiet-window readings per size (World's park lists them) should include `net/tools/rollback_bench.gd --planet` at medium and huge (take, restore, a rollback frame), `SimHash.stateHash` at each, and the first-frame time at huge on the old PC. If the take at huge is under about 2.5 ms and SimHash is not a spike, LAN at huge needs no change. If SimHash is the spike, NetLan can hash only when it writes a saved file (match end, a pause, a report) instead of at every checkpoint: a `net/` change, the replay keeping its final hash.
