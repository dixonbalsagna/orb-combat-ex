# Park: lan-hash, the saved match's checkpoint hashes leave the frame (Netcode, 2026-11-14)

**What was wrong (found by reading the code).** NetLan turns on `NetSession.hashChecks`, so a saved match's replay carries SimHash's gameplay hash every 60 ticks. The session ran `SimHash.stateHash(S)` in `_checkpoint`, in the frame, **on every run** of a checkpoint tick, a rollback's re-runs included.
- SimHash walks every column of the planet in GDScript. Every `deform` value goes through the hasher one by one, and `water`, `scorch`, `crack`, `rubble`, `lotAcc` and the depth rows are scanned column by column (`sim/core/hash.gd:303-345`).
- In `lan_check` on this machine (loaded, so only indicative): **28.7 ms a hash in 1v1 and 52.5 ms in 2v2 together** (two fights).
- That's a hitch of one to three frames once a second in Orb's LAN build at medium, and again whenever a rollback re-runs a checkpoint tick: 43 hashes for 19 checkpoints on two PCs, where 38 would be one each.
- At huge it grows with the columns.

**The fix, all in `net/`:**
- **`net/session.gd`:** the hash is taken once, when a checkpoint becomes final, from the copy that checkpoint already holds (SimHash reads a snapshot's own arrays, which `two_states_check` already relies on). It runs on a worker thread (`_hashLater`, `WorkerThreadPool`). The copy goes back to the pool only after its job (`_put`). `hashesDone()` waits for every job before a saved file reads `hashFinal`, before a desync report and at `close`.
  - The copy shares only buildings, trees and their records with the live state, and the sim copies those on write, so nothing the job reads changes under it.
  - `hashOld` and `hashLive` are test switches: the old path, and the control.
- **`net/lan.gd`:** `save()` calls `sess.hashesDone()` before reading the hashes.
- **`net/tools/lan_check.gd`:** `_hashRows` plays the same p120 match twice to 1200 ticks, first on the old path, then as shipped, in 1v1 and in 2v2 together.
  - Both PCs' saved replays come out byte for byte the same, with 0 hashes on the game's thread.
  - Control: with the hash taken from the present state instead of the checkpoint's copy, the replays differ.
- **`docs/net/lan-v1.md`:** a paragraph.

The values and their order don't change, so a saved file is byte for byte what it was, and replays and Tools' verify are untouched.

`lan-hash.patch`, sha1 29146f1a3efa70dc963f6edb8215cf74b867029e. **It rides B1, after lan-stamp** (its context includes lan-stamp's lines). Applied in sequence on HEAD 611c1c2b, all five apply:

`git -c core.autocrlf=false apply replay-build.patch grant-netcode-build.patch grant-tools-build.patch lan-stamp.patch lan-hash.patch` (each in turn: `git apply` checks a list of patches against the original tree, not stacked).

**Can a web build, or a desktop build without threads, reach the worker thread? No.** I checked by reading the code (EP's question for the B1 review):
- Only `net/lan.gd:258` turns on `hashChecks`, and `_hashLater` runs only when it's on. No other script in the repository sets it: not rollback, desync, the spectator or any other check.
- `NetLan` is created only by the private LAN kit's patched `render/core/main.gd`, and only when the game starts with `--lan-host`, `--lan-join` or `--lan-loop` (`net/tools/lan_kit.mjs:53-55`).
- Main's `main.gd`, `sim_host.gd` and every other shipped script outside `net/` never create a `NetLan`, a `NetSession` or a transport (the only mentions are comments).
- The kit exports only the Windows Desktop preset, which always has threads. `lan_check` runs on desktop Godot, headless.
- The web page packs `net/`, because the Web preset doesn't exclude it, but nothing on the page starts a LAN session. The desktop builds exclude `net/` entirely.

So no fallback is built. If LAN ever comes to a build without threads (A3's in-game LAN is desktop first, and a browser LAN would be WebRTC), `_hashLater` gets one guard: `if not OS.has_feature("threads")`, hash the checkpoint's copy in the frame, once (the same call, without the thread).

**What it doesn't touch:** the cheap digest every checkpoint (MD5, about 1 ms) and the checkpoint's own snapshot take (1.57 ms), as before. Performance's per-size readings will show the rest.

Runs: `docs/net/runs/29a153f5/lan-hash/` (CD-22).
