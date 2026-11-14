# Park: lan-stamp, a LAN save names its build (A-NET-05's LAN side; Netcode, 2026-11-14)

Sprint A1 wave 2, item 1 of `docs/ep/alpha/audit-2026-11-13/05-directives/A1/netcode-online.md`. With Simulation's replay build id, a LAN save names its build once, with Tools' page stamp's id. A LAN save from another build is refused with the same reason as a solo replay. The stand-in's B1 review, finding 1, is answered here: Orb's LAN report clips keep working.

| File | Change |
| :--- | :--- |
| `net/tools/lan_kit.mjs` | Reads the page stamp from the tree's `build_info.json` (Tools' 047d4037) and writes the kit's stamp: `{commit (7), date (the commit's), stack, lan: true, built (the kit's UTC time), id}`. **The id is the page's own** (`<commit8>-<key8>`), as the EP agreed. The kit changes only render and UI files, so the sim, data and net a replay runs on are the page's, and a LAN save plays on the page (`lan-clip`), on its kept tree and on the folder's `tree/`. `built` tells one LAN folder from another. The same stamp goes into the export and into a new read-only `tree/` in the folder (sim, data, net, project, class cache, README), so the folder recipe no longer copies Tools' kept tree. `--build` is needed only for a tree with no page stamp |
| `net/lan.gd` | `NetLan.commit8(stamp)`: a saved file's name keeps the commit's first 8 from the stamp's id (the stamp's `commit` has 7). `NetLan.stampFor` (tests) stands in for `build_info.json`. The file's `build` is the stamp; its replay's `build` is `SimReplay.buildId()`, the same file's id |
| `net/tools/lan_check.gd` | `_stampRows`: both PCs' stamped saves name the build once, keep commit8 and play back. A foreign LAN save loaded from disk is refused as `build` before tick 1, with both ids (`play`, `refusal` and `NetDesync.replayState`), and so is an unstamped save. Control: with `SimReplay.blindBuild`, the foreign save plays to its last tick |
| `docs/net/lan-v1.md` | The build's stamp; the verify line points at the folder's own `tree/` (it also had a stray tab character) |

`lan-stamp.patch`, sha1 5d7f7be0a7de319d576aca100a1580f57eec0cbb.

**Apply it after Simulation's replay-build,** in one batch (B1). This applies to Simulation's re-cut (replay-build.patch 73b9862a, grant-netcode-build.patch 3cd1b355, Tools' grant withdrawn), on HEAD 00925b89, each patch in turn:

`git -c core.autocrlf=false apply replay-build.patch grant-netcode-build.patch lan-stamp.patch lan-hash.patch`

The whole stack is proven in `docs/net/runs/00925b89/b1-stack/`.

It touches no file the replay-build patches touch, so it also applies alone. But `lan_check` calls `SimReplay.refusal` and sets `SimReplay._bid`, so it fails to parse without replay-build. Don't land it first.

**After landing:** the LAN folder recipe takes the kit's own `tree/` (no hand copy of the kept tree). Saves from folders made before this (`orb-lan-6a30b4c9` and older) carry no build id. They verify on their own folder's `tree/`, and a stamped build refuses them, by design.

Runs: `docs/net/runs/97df40b8/lan-stamp/` (CD-22).
