# windows-local, first dispatch (Tools, 2026-11-21; for the EP)

Run [44896954723](https://github.com/dixonbalsagna/orb-combat-ex/actions/runs/44896954723): `desktop-builds.yml` from main dce749fc, input `ref` d168a518c965887cfa05ad46eb775ca12b6a76c7, `audience` owner-private. Nothing was uploaded and no still was kept (the job has no upload step; RL-262).

| Job | Result |
| :--- | :--- |
| Desktop builds (Windows, Linux, macOS), export, pack and check | success; the Linux bench printed `gameplay hash at tick 2400: cc3a8b1d073bf222` |
| Windows build made and started on a Windows runner | **failure**, at the step "The exported Windows build starts and plays the bench match" |
| Windows build opens a window and one still is taken | skipped (it needs the bench job) |
| Windows build plays the bench match and prints the Linux build's hash | skipped (same) |

**What worked on a hosted `windows-2025` runner:** the Windows editor and the Windows release template downloaded and matched their SHA-512 sums (`godot.zip: OK`, `templates.tpz: OK`); the template installed (109 MB `windows_release_x86_64.exe`); the headless project import and the Windows export ran and wrote `orb-combat-ex.exe` (121 MB, pck embedded).

**What failed:** `./orb-combat-ex.console.exe: No such file or directory` (exit 127). The export wrote `orb-combat-ex.exe` alone. The Windows preset has `debug/export_console_wrapper=1`, which is "debug exports only", and the job exports release; "debug and release" is 2.

**The fix** is parked in `docs/tools/pending/windows-local-fix/`: a step that sets the Windows preset's value to 2 in that runner's checkout only. Not yet proven: whether Godot 4.7.2 then writes the wrapper on a release export, and everything after it (the bench's stdout through the wrapper, the hash comparison with the Linux build, the window and the still under ANGLE/WARP).
