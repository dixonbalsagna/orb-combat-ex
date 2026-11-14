# Tools: the A2 list (Tools, 2026-11-14)

What Tools holds for sprint A2, in the order they can be done. The A1 items are in the reports to the EP; this page is only what is waiting.

## From Legal's RL-267 (`docs/legal/outside-tester-gates.md`)

### G22: no tester's raw file or name in a tracked file (the content screen): BUILT, 2026-11-14

`tools/content-screen.json` has a new rule `testerFiles` and `tools/content-screen.mjs` runs it on every screen (it is in CI already: `content-screen.yml` and the self-test in the data job). It fails (severity fail) on:

- a path that is a saved-match file name (`solo-<commit>-...json`, `lan-<commit>-...json`), a `testers` or `playtesters` or `feedback-reports` folder under a tracked `docs/*/runs/`, or anything under `.private/` that is in the file list (the folder must stay git-ignored: `.gitignore` has `.private/`);
- a JSON file whose own `kind` is `orb-lan-match` or `orb-solo-match` (a saved match, whatever it is called or wherever it sits);
- a tester's name: from a local, git-ignored list, `.private/testers/names.txt` (one name or alias a line, `#` comments allowed), a whole word in any case in any file in the list. The screen never prints the name.

**What it cannot do on a runner:** the names list lives on Orb's PC and is not in the repository, so CI cannot check names. The screen prints a note saying so ("tester names are not checked here") and still runs the path and saved-match rules; a pass in CI therefore means "no tester file by path or by kind", not "no name". The names are checked when the screen is run where the list is (the EP's or Orb's PC, before a commit batch that touches docs). The self-test (29 checks) plants every case, including that the name is never printed. The file list the screen reads is git's (`ls-files -co --exclude-standard`), so an ignored `.private/` file is never scanned; the self-test uses a plain folder, where it walks every file.

My tools and briefs write no tester's file under a tracked `docs/*/runs/` (checked on 2026-11-14: `git grep` for the saved kinds finds only code, and docs/tools/runs holds readings and check outputs). The `.gitignore` lines for `solo-*.json` and `lan-*-*.json` under `docs/*/runs/` stay as a second guard.

### G21: a flash reading on the actual desktop package, both modes, before the first outside session: NOT STARTED, design below

The reading must be taken on the program the friends get (the Windows and Linux packages of one commit), name the package file and its checksum, and sit under `docs/tools/runs/<sha>/`. It cannot be the browser clips' way, and the reasons decide the design:

1. **The package refuses the capture hook by design.** `capture_hook` is false and `lock_reduce_flashing` is true in a package (`ui/hud/ui_hud.gd:1529`, `tools/desktop-package.mjs routes`): the page words that pose the worst-case scenes (`flashcap`, `shot`, `study`) do nothing in it. So a worst-case scene cannot be posed in the real package.
2. **What the package can be made to do:** play its own AI match (`--seed=N --bench --frames=N`, which the Linux job already runs headless), and Godot's movie maker (`--write-movie <file> --fixed-fps 60`) writes every rendered frame at a fixed rate, not in real time, so a slow software renderer gives the same frames as a fast one. A PNG sequence out of the real package's own drawing path is a candidate reading source. **Not tried:** whether movie maker works in a release export of this project, whether it needs a display (it does render, so a Linux runner would need Xvfb as in spike S5, or a Windows runner's desktop), and whether the bench match draws in a window.
3. **What it would read:** AI-vs-AI matches (the nightly seeds in `tools/flash/nightly-seeds.json`), frame by frame, with `run-pixels`' analyser. It reads real play, not the worst-case scenes; the worst cases stay on the browser build, which is the same code and data (the pack's data hash can be compared to the browser build's).
4. **Both modes:** the package is locked to Reduce flashing ON. A reading in normal mode needs a package with the lock off, which is not the package the friends get and which a workflow on a public repository must never make or keep (Legal RL-262 section 1, point 5). So the normal-mode half is Legal's call: either a reading of the locked package only, with the normal-mode reading from the browser build stated as such, or a normal-mode reading made on Orb's PC from a locally made unlocked package and never kept in a run file. I will not make that choice.
5. **Where it can run:** the Linux package on a Linux runner under Xvfb with software GL (spike S5 showed the package starts and draws there); the Windows package on a Windows runner (the `windows-still` job drew a window there only in the outside-testers audience, because the Windows zip is not uploaded in owner-private runs: see `docs/tools/desktop-builds.md`). Orb's PC can read the Windows package locally under the long-run rules.

Next step when it is picked up: one local try of `--write-movie` on a locally exported Linux or Windows package for 120 ticks, to see whether it writes frames and whether the analyser reads them. That decides whether G21 is a small job or a new capture path.

## From the A1 reports, still open

- The first desktop build (A-TOOLS-01) after GW1a closes; `audience=owner-private` first (`docs/tools/desktop-builds.md`).
- The coverage probe on every build, and Audio's sets check, when their scripts are on main (`docs/tools/pending/ci-later/README.md`).
- Windows start proven for owner-private builds: needs Legal's word on exporting on the Windows runner (report 6).
- Full local flash readings of signature and collapse to measure their nightly windows, when the EP schedules the quiet window (`docs/tools/flash-nightly.md`).
- `ci-budgets-check --runs 3` after three runs on 047d4037 or later; retire the `splitShare` row after GW1a.
- The preview smoke's start button by row name needs a probe field for the menu rows from Rendering or UI.
