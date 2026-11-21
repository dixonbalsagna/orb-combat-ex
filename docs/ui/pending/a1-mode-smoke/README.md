# a1-mode-smoke: the mode smoke drives the new menus with pad presses (UI & UX, 2026-11-20; park for after GW1a)

From the stand-in's A1 exit status (docs/ep/reviews/A1-exit-status.md): the mode smoke drove the old start screen, moved the menu by the game's own calls, and counted a missing Quit row as a pass; and no result file was saved. Tools' files, so this is a grant.

`grant/mode-smoke-pad.patch` (`git apply --check` clean on HEAD b65cdc3b; `tools/smoke/mode_smoke.gd`, `mode-smoke.mjs`, `mode-smoke-selftest.mjs`, `docs/tools/mode-smoke.md`):

- **Real pad buttons.** Every menu step is a pad press through the engine's input path (`Input.parse_input_event`: D-pad, A, B), and the lit row is read back **by name** from the menu's own plan (`menu_plan()`, `pause_menu_plan()`), never by calling the game's own menu functions. The run sets the window to 1280 by 800 first: a headless window starts tiny and the A1 menus show only where the list fits.
- **Through the A1 menus.** The start menu opens on the list of modes; a mode that is not built cannot be started; A on the mode opens the setup; a fighter is picked with the D-pad and the two never match; intros off; Start; a match runs **with the picked fighters**; the match-over card has Quit among its rows; "again" by pad; the pause menu has Quit; "menu" goes back to the list; Quit asks "Close the game?" with Stay lit and B stays. 19 steps a mode.
- **A missing Quit row fails.** The step is `ok` only if the row is there, and the runner now also fails a result with any step marked "not built" or whose `input` is not `"pad"`. The self-test has the new checks (10).
- **A result file per mode and platform.** The runner already wrote `mode-smoke-<mode>-<platform>.json` (default `docs/tools/runs/<commit8>/`); it now prints the path it saved and the file says `input`, `window` and `natural_result`. The files of this run (Windows, headless) are in `runs/`.
- **What it still does not do.** The pause menu is opened with a real **P** key press: a pad's Start opens it only for a pad the host has claimed, and a headless run has no pad connected (the step says so). The match is still ended by the smoke with `SimDamage.ko` when the scripted humans have not finished it (the step and `natural_result` say so): hit points no longer end a match on main.

**Results on a tree of HEAD b65cdc3b with the whole A1 UI stack and the fighter-slots part of the main.gd grant** (`runs/`): solo 19 steps, 0 failed; two people 19 steps, 0 failed. **Without the host grant** the solo run fails exactly one step, "the match starts with the picked fighters" (the host plays the default pair), so the smoke is also the check that the grant landed (`runs/solo-before-the-fighters-grant.txt`). It also fails at once on a build whose menus fall back to the single card (no list, no Quit): that was the first run's 8 failed steps.

Needs the UI stack and the main.gd quit-and-fighters grant (Rendering's) in the build under test; land after GW1a.
