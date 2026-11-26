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

## 9. The first match, across sessions (GW1b; World's A-WORLD-01, decision 2)

The host plays the fixed planet for the first match a player ever starts and draws the planet for the later ones. The flag is kept in the settings store (`UiPrefs`, key `played_match`), not for the session: `UiHud.first_match_played()` says whether a match has been started before, and the HUD sets it right after the host has been told (Start, and Play again), so the host still reads "no match yet" while it makes the first one. The host's grant uses it in place of its session flag.

## 10. Which planet (GW1b)

The host's report context gains `world` (`WorldDefault.describe(S)`: planet seed or 0 for the hand-made arena, generation, columns). The pause menu's and the match-over card's detail card say "Planet 7" (quiet colour, with the other lines); the saved match record carries `world`; the report says "World: Planet 7, generator 3, 4800 columns around" (or "The hand-made arena", or "unknown" where the host gave none). Words for Orb: "Planet {planet}", "The hand-made arena", "Planet {planet}, generator {gen}, {cols} columns around".

## 11. The planet size row (GW1c)

A cycle row "Planet size" in "Set up the match", after the fighters: the sizes World offers (`data/biomes/sizes.json`, `offered` true, in its order; today Medium alone, the file's other sizes being held), Medium first, with Left and Right (or A) stepping and wrapping and "Planet size: Medium" in the "This match" card. The choice is `planet_size` in the menu config (saved with the other choices) and the host sets the setup key `planetSize` from it. The row and its line in the "This match" card appear only when there is a choice: two offered sizes or more (`UiModes.size_row()`). With no sizes file, or with ONE offered size (GW1c lands with Medium alone; the others are `offered: false`), there is no row and no line: a cycle row of one choice would step to itself and look like a control that does nothing. The menu config still carries `planet_size` (the one size, Medium), which the host sends as `planetSize`; a named Medium plays the same as an unnamed one (World). Words for Orb: "Planet size", "Tiny", "Small", "Medium", "Big", "Huge".

## 12. Keyboard or controller (decision 20, second half)

Both work. The first visit to the list of modes (only) carries one quiet line under the list, in the help text's ink, with no box, icon or button: "You can play with a keyboard or a controller. A controller feels best." It is not shown with a controller plugged in, goes once the player goes on (and as soon as a controller is used), is remembered (`pad_tip_seen`), and is left out where the screen has no room for it (it never makes the list stop fitting). It is not on the flashing-effects warning. The start menu's button hints now follow the device last used (a key: keys; a button or a stick push: controller), and a menu opened with a controller plugged in starts with the controller's hints. In a match the unplug pause is the controller side (docs/ui/unplug-pause.md).
