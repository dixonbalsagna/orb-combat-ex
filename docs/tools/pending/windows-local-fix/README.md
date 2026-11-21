# windows-local-fix (park, Tools, 2026-11-21)

First dispatch of `windows-local` (run 44896954723, record in `docs/tools/runs/d168a518/windows-local-dispatch-1.md`): the Windows export worked on the hosted runner, then the bench step found no `orb-combat-ex.console.exe`, because the preset's `debug/export_console_wrapper=1` means "debug exports only" and the job exports release.

`windows-local-fix.patch` (sha1 aa6b919273fd7137ea5e3c82cd929f0b3f0237f8, one file: `.github/workflows/desktop-builds.yml`; `git apply --check` passes on dce749fc): a step before the export that sets the **Windows** preset's value to 2 ("debug and release") in the runner's checkout only, and fails if it did not change exactly one line; the comment above the bench step is corrected. The preset in the repository, the desktop package, the Linux and macOS exports and the upload gates are untouched (`check-desktop-audience` ok, `check-workflows` ok, `check-workflow-shell` ok on a scratch copy).

Not proven: that Godot 4.7.2 writes the wrapper for a release export at 2 (the run decides), and every step after it. Expect to iterate on the still step.

After landing and pushing, the next dispatch is `gh workflow run desktop-builds.yml --ref main -f ref=d168a518c965887cfa05ad46eb775ca12b6a76c7 -f audience=owner-private`.
