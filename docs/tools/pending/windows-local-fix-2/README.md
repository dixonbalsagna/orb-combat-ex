# windows-local-fix-2 (park, Tools, 2026-11-21)

Second dispatch of `windows-local` (run 44897597667, main 5bf9ff46, ref d168a518): the step that sets the Windows preset's console wrapper to 2 worked (the log shows `69:debug/export_console_wrapper=2`, the other two presets still 1), the export ran, and still only `orb-combat-ex.exe` was written, so the bench step failed again with `orb-combat-ex.console.exe: No such file or directory`.

Cause: the console wrapper is its own template, `windows_release_x86_64_console.exe` (the Godot template folder on this PC has the debug and release pairs for every Windows architecture), and the job's `7z e` extracted only `windows_release_x86_64.exe` and `version.txt`. The export copies the console template beside the exe when the preset asks for it.

`windows-local-fix-2.patch` (sha1 eaf615da96fbd8d13627a268978b842744a694fe, one file, the `windows-local` job only; `git apply --check` passes on 5bf9ff46): the `7z e` also extracts `templates/windows_release_x86_64_console.exe`, and a `test -f` fails the step at once if it is missing. `check-workflows`, `check-workflow-shell` and `check-desktop-audience` ok on a scratch copy.

Not proven: that the export then writes the wrapper (the run decides), and the steps after it. This is the second failed run of the three the EP allowed after the first; one more patch is parked here, not two.
