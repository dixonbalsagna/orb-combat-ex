# The mode smoke (A-MODES-08, Tools, 2026-11-14)

One mode a run, through the real main scene, headless, **by row name** (never by screen points): the start menu, the row "players" (one person, two people), intros off, the row "start", a match that runs, scripted humans playing, a result card, a rematch ("again"), the pause menu, "menu" back to the start menu, and a look for the start menu's "quit" row.

```
node tools/smoke/mode-smoke.mjs --godot <exe> [--mode solo|two|both] [--path <project>] [--out <dir>]
```

Files: `tools/smoke/mode_smoke.gd` (the run), `tools/smoke/mode-smoke.mjs` (the runner), `tools/smoke/mode-smoke-selftest.mjs` (9 checks, in CI's data job). The runner moves the game's data folder (`APPDATA`, `XDG_DATA_HOME`, `HOME`) to a scratch one, because the game saves its menu choices as it is played; it stops a hung run at 240 s by its own PID; a run that writes no result file exits 2 (not a pass). One result file per mode and platform: `docs/tools/runs/<commit8>/mode-smoke-<mode>-<platform>.json`.

## What a pass means, and what it does not

- The step "the match plays N ticks, then the smoke ends it with SimDamage.ko" is honest about itself: hit points no longer end a match on main (wounds and finishers do), so the smoke plays 600 ticks and then calls the sim's own KO, the call the sim's checks use. **The result card, the rematch and the way back are under test; the finisher and balance are not.** The finisher has its own checks.
- A row the build does not have is listed in the result as `not built` and counts as ok. Today: the start menu's "quit" row (the start menu ends on "start", then "back"). When UI builds it, the smoke reads it with no change.
- Three modes of the X-05 first reading are not here yet: the training mode, a LAN or lobby entry, a 2v2 stage. Each needs its row to exist in `UiHud._menu_rows()`; the smoke names rows, so each is one more step when the row is there.
- The smoke runs headless, so the first-run How-to-play card and the start menu are opened by the smoke (a headless run has no window, and the game opens its start menu itself only when it has one). The step says so.

## Reading of 2026-11-14 (HEAD 97df40b8 as an export, Windows, headless)

solo: 14 steps, 0 failed. two people: 14 steps, 0 failed. Linux runs in CI's third Godot job (`godot-roll-render`, step "Mode smoke", results kept as the `mode-smoke` artifact); Windows with the Windows jobs (A-TOOLS-13). Not run on macOS.

## One thing the run showed (for UI, not a smoke failure)

`ui/widgets/ui_menu.gd:271` (`plan`), reached from `UiHud._paint_notice`, raises "Rect2 size is negative" on frames where the start menu is drawn in the smoke's headless run (many lines in the log). It is an ERROR line, not a SCRIPT ERROR, so `tools/gate.mjs` does not count it. The cause is not found: I did not test whether it depends on the window's size, and I have not seen it in a played window. Reported to the EP for UI.
