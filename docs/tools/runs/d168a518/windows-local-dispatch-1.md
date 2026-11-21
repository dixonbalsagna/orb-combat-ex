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

## Second dispatch (run 44897597667, main 5bf9ff46, same inputs): failed at the same step

With the wrapper step landed the preset reads `debug/export_console_wrapper=2` for Windows (the log lines show 69:=2, 115:=1, 148:=1), the export ran, and again only `orb-combat-ex.exe` (121 MB) was written; the bench step failed with the same "No such file" (exit 127). Cause: the console wrapper is a separate template (`windows_release_x86_64_console.exe`) and the job's `7z e` installed only the windowed one. Fix parked: `docs/tools/pending/windows-local-fix-2/`. First failed run of the EP's allowance of three after it.

## Third dispatch (run 44898139674, main 575bf093, same inputs): GREEN

All four jobs: the first job success, `windows-local` **success** (about 2 minutes 18 seconds on the windows-2025 runner), the old `windows-bench` and `windows-still` skipped as designed (they need the Windows zip an owner-private run never uploads). Nothing was uploaded and no still was kept.

What the log proves, step by step on the hosted Windows runner:

- the Windows editor and release template, plus the console template, downloaded and matched their SHA-512 sums; the console template is present (`test -f`);
- the Windows preset's console wrapper was set to 2 in that checkout only (log: line 69 `=2`, lines 115 and 148 still `=1`), and the export wrote the exe and `orb-combat-ex.console.exe`;
- the console wrapper ran the bench headless on Windows (`BENCH gl_compatibility | Windows | 64x64 | 2340 frames after 60 warm-up | sim ticks 2400`; frame mean 10.9 ms, sim tick mean 0.73 ms, audio 294 played 0 dropped) and printed **`gameplay hash at tick 2400: cc3a8b1d073bf222`**, identical to the Linux build's in the first job: the Windows build plays the same match;
- the windowed exe was started on the runner's desktop and the still step passed. That step throws if the game is not running after 30 seconds or if the sampled screen has fewer than 8 distinct colours; it did not throw. The exact screen size and colour count are in the run's summary page, not in the log, so I do not quote them here.

Not proven by this run: that the picture shows the game rather than something else coloured (the step counts colours, it does not look at the frame; the still is not kept by rule), real GPU rendering (the runner is software WARP), and anything about the shipped zip for outside testers. The end of the log shows Godot's usual leak warnings at exit on the console wrapper (8,186 ObjectDB instances, 13 resources, 6 RIDs of the dummy renderer); the Linux build prints the same kind at exit and the bench result is not affected.
