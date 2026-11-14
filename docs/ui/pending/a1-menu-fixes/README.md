# a1-menu-fixes: tiny windows without errors, and the version line (UI & UX, 2026-11-14; park, not landed)

`menu-fixes.patch` (`patch -p1` / `git apply`; dry-run clean on HEAD def3445a plus `a1-pause-clock`, `a1-start-flow` and `a1-replay-words`; apply after those): `ui/widgets/ui_rail.gd`, `ui_menu.gd`, `ui_pause.gd`, `ui_settings.gd`, `ui_turn.gd`, `ui_feedback.gd`, `ui/hud/ui_hud.gd`, `ui/data/terms.json`, the regenerated pseudo-locale and `docs/ui/strings.md`, `ui/tools/hud_check.gd`, `docs/ui/menus-a1.md` (sections 7 and 8).

## 1. "Rect2 size is negative" (Tools' smoke, ERROR on many frames)

**Cause:** the plans of the start menu (`ui_menu.gd` plan), the pause menu, Settings and the turn card ask `Rect2.encloses` or `intersects` of a rectangle whose width or height went negative when the window is too small to lay out (the headless mode smoke's window, a first frame). Godot answers with an ERROR line each time and the HUD asks every frame. Reproduced with a probe that plans at 0x0, 1x1, 64x64, 160x90, 320x180: **2510 ERROR lines before, 0 after**. The turn card was the one left in `hud_check`'s own phone sizes (116 lines in every full gate until now, 0 with this patch).
**Fix:** `UiRail.holds(outer, inner)` and `UiRail.meets(a, b)` say no for a negative rectangle; the plans use them, so such a plan just says `fits` false. `hud_check` plans at those five sizes and in both layouts, and checks the two helpers.

## 2. The version line

`UiFeedback.version_line(with_build)`: "Version 0.1.7" (the `version` key of `build_info.json`, Tools' A-TOOLS-07), or on the match-over card "Version 0.1.7 (build 59c6b195, 14 November 2026)"; nothing when the build has no version. It sits in the quiet colour at the foot of the rail under the hint strip on the pause menu and the start menu's pages (the hints move up by its height; the start menu falls back to the single card where the list no longer fits with it). New words for Orb: `prompt.version_line` "Version {v}" and `prompt.version_build_line` "Version {v} (build {commit}, {date})". Tests: the line, the long date, no line without a version, the plans carry it and still fit, and in the HUD the pause menu, the match-over card and the start menu say the right thing. The saved report's version line is Tools'.
