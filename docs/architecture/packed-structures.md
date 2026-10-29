# Buildings and trees as packed arrays (Simulation and Engine, 2026-10-28)

Follows `snapshot-tick.md`. A rollback snapshot used to copy every building and tree as an object: about 5 µs of bookkeeping each, 80% of a take. Now the records are shared and their per-tick fields are packed arrays on `SimState`, which a snapshot copies as arrays.

## The layout
- `S.buildings` and `S.trees` hold the same `Building` and `TreeState` records as before, and every field reads and writes as before (`b.hp`, `t.burn`).
- **Per-tick fields** live in `SimState`, by index:
  - buildings: `bHp`, `bAlive`, `bFmask`, `bFdmg`, `bMarks`, `bFled`, `bPopAlive`, `bWear`;
  - trees: `tAlive`, `tBurn`.
- **Generation records** (`g`, sealed, copy on write, as before) are listed in `bG` and `tG` too, so a restore can put back the ones a tick had.
- A bound record reads and writes through its `Hold` (`_h`, `_i`): one small object per binding that points at the state's arrays. It holds no record, so there is no reference cycle.
- A record that is not bound (a world being generated, a tool's test record) keeps its fields in its own `_` fields, so `Building.new()` works as before.

## Binding
- `SimState.bindStructures()` makes a new `Hold` and new arrays, and new `S.buildings` and `S.trees` arrays.
  - An unbound record is bound in place, and so is a record bound to this state's hold, which marks the old hold `moved` (see restore).
  - A record bound to another hold is copied first (it keeps the same `g`).
  - With `fresh`, an unbound record is copied too, so a record a cached plan holds keeps its values for a replay.
- SimCore binds at the end of a match's start (`_mEnd`). `SimCore.step` calls `bindCheck()`, which binds again only when either array is not the one bound (a world tool). The calm turn's swap binds with `fresh` right after it replaces both arrays, so the plan's prepared buildings stay pristine for a replay.

## Snapshots (`net/snapshot.gd`)
- `SimState.SNAPSHOT` shares `buildings`, `trees`, `hold`, `bBound` and `tBound`, and copies `bFdmg`, `bG` and `tG` one level deep ("shallow").
- `Building`, `TreeState`, `Hold`, `BuildingGen` and `TreeGen` say `{"shared": true}`: the copier, `measure()`, `aliasAudit()` and the desync field walk treat them like data definitions.
- `restore()` calls `S.afterRestore()`. It points the hold at the restored arrays. When the restored `bG` or `tG` differs from the hold's (one engine compare of references), it puts the restored `g` back on each record. When a later bind moved some of the hold's records to another hold (the calm turn rebinds its kept buildings in place, so they stay the same objects), it binds every record back and marks the other hold `moved`.
- Nothing in the arrays is per-process, so the desync field walk finds no difference between two peers' states that agree.
- **Contracts:**
  - a `bFdmg` element is written in place only in the tick that made it. World's two floor writers copy it first (`brunt.gd`, `blast.gd`).
  - `S.buildings` and `S.trees` are never changed in place during play.
  - A snapshot is restored into the state it was taken from. Any other state gets records of its own (`_rebuildRecords`; the check below restores one into another state).

## Reading a snapshot
A snapshot's records are bound to the live state's hold, so reading `root.buildings[i].hp` gives the live value. **Anything that reads a snapshot reads the per-tick fields from the state's arrays when `S.bound()`**, in the same order and with the same types:
- `SimHash` does, so a snapshot hashes as itself and the hash is unchanged.
- `NetDesync.digest` does too (Netcode's `net/desync.gd`, 2026-10-28). A session's `onConfirmed` hands over a snapshot's root for a tick behind the present, and the transport check and the ENet peer digest it. While the digest read the records, a joiner that had run ahead reported the live buildings for a confirmed tick, and `transport_check` failed at ticks 366 to 374 (the sim itself never differed: the final SimHash matched).
- The desync field walk reads the arrays and leaves the records alone, as it does data definitions. It names a building's difference `S.bHp[i]` (it was `S.buildings[i].hp`).

## The check: `sim/core/tools/two_states_check.gd`
`godot --headless --path . --script res://sim/core/tools/two_states_check.gd -- [--seeds=1,2] [--ticks=600] [--setups=default,planet,calm,turn] [--negative-control]`
- Three states run the same bots' inputs in one process, interleaved tick by tick: R straight; A saving before every tick and rolling back 5 ticks every 7th; C, a fresh match made at the half, given A's snapshot of 12 ticks earlier.
- Every 3 ticks the check hits a building and a tree itself, through the records, so every run has changes for a snapshot to miss.
- It passes only if, after every tick, A's and C's digests equal R's and a live state's records read what its arrays hold. Every snapshot of A, read 12 ticks after it was taken, must give R's digest of that tick; every 30 ticks, R's SimHash and an empty field walk against R's snapshot too. C must start as R did, and the three full SimHash must agree at the end.
- **Negative control:** a snapshot read through its records (the old digest), a restore that leaves the records on their old arrays, and a snapshot restored into another state that keeps the first state's records. Each is caught on all 8 runs (4 setups, 2 seeds). With the old digest the check failed all 6 runs of its first default list, which had no `turn`.
- **The setup `turn`** (the calm setup with a turn decided at tick 30, swapping at tick 73) is in the default list. Until World's fix (e14757c5), a rollback into the turn's preparation waited forever: the swap drops the ring jobs (`WorldEpoch._dropJobs`), and a ring counted as read whose preparation was not yet due never made its job again. World's three lines in `WorldEpoch._prep` make it again, and `turn` passes, packed structures or not.
