# Park: lan-example-address, no real network address in net/ or docs/net (Netcode, 2026-11-21)

Orb's rule: no network address is written into any file. The main PC's home address was the worked example in four places, and a member-network address was a test value. They become documentation examples.

| File | Change |
| :--- | :--- |
| `net/lan.gd` | `prefixOf`'s comment: `"192.168.1."` for `192.168.1.20` |
| `net/tools/lan_kit.mjs` | The usage line: `--host-ip=192.168.1.20`. The kit still takes the real address on its command line and checks it's the PC's own; nothing is written |
| `net/tools/lan_check.gd` | The /24 rows: the prefix of `192.168.1.20`. The filter lets in `192.168.1.7`, and refuses `192.168.2.7` (another network, in place of the member-network address), `192.168.11.7` (in place of `10.0.01.7`: a network whose name shares the prefix's first characters, which a plain "starts with" would wrongly let in) and `203.0.113.5` (unchanged, the RFC 5737 documentation range) |
| `docs/net/lan-v1.md`, `docs/net/two-v-two-lan.md` | The usage line and two sentences: build the folder with the main PC's own address; `192.168.1.20` is only an example |

**Why 192.168.1.20 and not RFC 5737:** the 5737 ranges are documentation-only, but they aren't home-network addresses. The kit refuses any `--host-ip` outside the private ranges (Legal RL-230: the home network only), so an example from 5737 would be one the kit itself turns down.

`lan-example-address.patch`, sha1 ac4b3e77280a5ffb8053f87618678fdc6219da5e. It applies on HEAD cb8d7934, alone, and before or after `desync-marks` and `desync-fdmg` (checked in turn both ways).

Run records already committed were redacted separately (the kit's "host ..." line, `<home address>`). Nothing outside `net/` and `docs/net` was searched or changed. Scratch scripts outside the repository keep the real address, because the kit needs it to run.

**What was run:** `lan_check` (`--ticks=1200`) and its negative control, through `tools/gate.mjs`, locally and headless on a scratch tree of b0e20f9a with this patch (`lan_check.gd` is the same on cb8d7934). Both exit 0, 0 SCRIPT ERROR lines, 0 checks failed, the /24 rows included. `lan_check` opens no socket (the second PC is simulated in the same process), so it runs on this PC. Only `enet_check`, which opens a real port, is CI-only.

Runs: `docs/net/runs/b0e20f9a/lan-example-address/` (CD-22).
