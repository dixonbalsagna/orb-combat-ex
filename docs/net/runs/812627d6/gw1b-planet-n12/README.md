# Netcode run, 2026-11-21: gw1b-planet re-cut for N-1 and N-2 (CD-22)

The tree was a copy of the EP's GW1b stack s426, which already had the first cut of gw1b-planet, with the re-cut applied by hand: PROTO 6, `NetDesync._fighterRest`, desync_check's coverage row and control, and the two docs' PROTO 7. Its class cache came with it. At most 3 Godot processes, below normal; no socket was opened and no `enet_check` ran. The profile path is written `<user>`.

| File | What it is |
| :--- | :--- |
| `gates.txt`, `checks/*.txt` | All 45 of my CI lines (every `res://net/tools` line in s426's ci.yml but `enet_check`), through `node tools/gate.mjs`, in three streams. All exit 0 with 0 SCRIPT ERROR lines |

What they read:
- **Coverage** (desync default, field and kick runs: `checks/c03`, `d02`, `e03` and their controls): "ok coverage: 56 of 56 fighter fields SimHash reads move the digest". With `restBlind`: "caught rest-blind digest: 56 of 56 fighter fields don't move it".
- **The first cut's fixes still pass:** the spectator control catches 5 of 5, and desync's director is detected on the planet.
- **PROTO 6:** `transport_check` refuses a hello one version up, as before, and `word_check` and `two_pc_check` print the new number.
