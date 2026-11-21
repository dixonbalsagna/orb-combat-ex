# The A1 menus: modes, setup, fighters, Quit (UI & UX, 2026-11-13; sprint A1; park `a1-start-flow`, not landed)

Briefs: A-MODES-01 (a list of modes), A-MODES-06 (a fighter for each player), A-MODES-11 (a Quit a pad can reach), A-UI-06 (the start menu's d-pad), A-TOOLS-07 (the version on the start menu). All on the Rail frame (docs/ui/menus-rail.md). Switch: `menu_modes` in `ui/data/features.json` (false in the park; it goes on with `menus_rail`). The words are for Orb to read before they are used.

## 1. The flow

1. **The list of modes** (the first screen). The rows come from `ui/data/modes.json`, in order: Against the computer, Two players one PC, Two against two one PC, Horde, Practice, Custom planet, Play over a network, Campaign. The first two are `ready`; the rest say **Coming** at the right, are dimmed, and A on them does nothing (their card says "This mode is not in the game yet."). A row appears as playable when its data row says `"state": "ready"` and gives `players`. Under the rows: Back to the match (when the menu was opened mid-match), Not now (the browser) and **Quit** (not in the browser). The card on the right is the lit mode's line. A version line ("Version 6a30b4c9", from the host's report context) sits at the bottom right.
2. **The setup** (A on a ready mode). Rows: Player 1 (Keyboard or Controller), **Player 1 fighter**, the computer's level (one player) or Player 2's device (two players), **Computer's fighter** or **Player 2 fighter**, Intros, Reduce flashing, Screen shake, Captions, Move guide; on the right Legal's notice word for word (not mid-match), "This match" (who plays whom: "Grist, Keyboard, Player 1 / Loupe, The computer, Medium"), Reduce flashing's line, **I understand, start** and **Back**. Back (B) returns to the list with the mode lit.
3. **Quit** asks once: "Close the game?" with **Close the game** and **Stay**, Stay lit first. B stays. The pause list and the match-over list end with Quit too and ask the same way; the keyboard's Escape (the host's) asks the same question and no longer closes the game at once (`UiHud.request_quit`, see the host grant).

## 2. The d-pad (A-UI-06)

On every page of the start menu Up and Down **wrap at both ends** (Up from the top is the last row, Down from the last is the first); the single card before the pages wraps too, and the pad-only shortcut that jumped Up to Start is gone, since Down now wraps the same way. Left and Right change only the lit row's own value: the setup has no Players row any more (the mode is chosen on the list), so nothing below the cursor swaps. The one exception is a fighter step onto the fighter the other player holds, which swaps the two (section 3). `hud_check` walks every row of the setup in all four directions and compares the rows and the values before and after; a recorded pad session on the list and the setup is in `docs/ui/runs/<sha>/a1-start-flow/`.

## 3. Fighters (A-MODES-06)

The picks are read from `data/fighters/roster.json` (the practice dummy, role "reference", is left out); no fighter is named in code and the names shown are `ui/data/fighter_names.json`. Left and Right (or A) step the lit row through the roster. **Mirror picks are off** (`mirror_pick: false` in modes.json) because two of the same fighter cannot be told apart on screen yet (a second colour is decision 17, A4): the setup says so in plain words ("Two of the same fighter can't be told apart yet, so each player needs a different one."), and a step onto the other player's fighter gives that player the one just left, so a roster of two can still be picked from. What is missing for the mirror: Art's second colour for the same fighter. The menu config Start sends gains `mode`, `p1_fighter`, `p2_fighter` (roster ids). The sim already takes `slots` in the match setup; the host does not send it yet (grant in the park).

## 4. The testers' package

`features.json` `testers_package` (false) hides the rows whose `testers` is false: the campaign and the network row (decisions 13 and 18) until Orb answers. Tools' package build sets it.

## 5. Where it applies

Where the Rail is usable (a window of at least 1000 by 600, 1.3 to 1, no touch) **and both pages fit** (the HUD asks the plans at the time the menu opens; the list with Back and Quit needs about 720 pixels of height); otherwise the single card of before is the start menu, with no list. A touch screen keeps it (ADR 0011).

## 6. Not built here

- The planet key from the menu (A-WORLD-01) needs World's value for the round planet; the window row (A-PERF-08) needs Rendering's definitions; the report and "Save this match" rows follow Tools' hook (A-UI-02). Each is listed in the report's NEEDS FROM EP.
- Stable names for every row (A-MODES-08): every row already has a stable id in the plan (`items[].row`: mode ids from the data, `quit`, `quit_yes`, `quit_no`, `p1`, `f1`, `ai`, `p2`, `f2`, the box names, `start`, `back`, `not_now`); the smoke suite can ask the HUD for them (`UiHud.menu_plan()`, `pause_menu_plan()`).

## 7. The version line (A-TOOLS-07; docs/tools/version.md)

One small line in the quiet colour at the foot of the rail, under the hint strip, on the pause menu and on the start menu's pages: **"Version 0.1.7"** (the number is `version` in `build_info.json`, read by `UiFeedback.version_line`). On the match-over card it carries the build: **"Version 0.1.7 (build 59c6b195, 14 November 2026)"**, so a report says which build it came from. A build with no version number shows no line, never "unknown". The line is for Orb to read before it is used; the saved report's line is Tools'.

## 8. Tiny windows

A window too small to lay out can make a width or a height negative; Godot answers `Rect2.encloses` or `intersects` on such a rectangle with an ERROR line on every frame (the headless mode smoke's). The plans of the start menu, the pause menu, Settings and the turn card ask `UiRail.holds` and `UiRail.meets` instead, which say no for a negative rectangle, so such a plan simply does not fit. `hud_check` plans at 0 by 0, 1 by 1, 64 by 64, 160 by 90 and 320 by 180.
