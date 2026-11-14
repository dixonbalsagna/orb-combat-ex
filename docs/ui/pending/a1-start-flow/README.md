# a1-start-flow: the list of modes, a fighter for each player, Quit, the d-pad (UI & UX, 2026-11-13; sprint A1; park, not landed)

Leads A-MODES-01, A-MODES-06, A-MODES-11, A-UI-06 and the version line of A-TOOLS-07. The design is `docs/ui/menus-a1.md` (in the patch). **Apply after `a1-pause-clock`** (both touch `ui/hud/ui_hud.gd` and `ui/tools/hud_check.gd`). `menu_modes` in `ui/data/features.json` ships **false** in this park, so main is unchanged until the flip; `testers_package` ships false too.

## Files

- `start-flow.patch` (`patch -p1` or `git apply`, on HEAD def3445a plus a1-pause-clock; dry-run clean on that tree): `ui/core/ui_modes.gd` (new class, so the first import after it lands re-reads the class list), `ui/data/modes.json` (new), `ui/data/features.json`, `ui/data/terms.json`, `ui/hud/ui_hud.gd`, `ui/widgets/ui_menu.gd`, `ui/widgets/ui_pause.gd`, `ui/demo/hud_demo.gd` (flags `?modes`, `mpick=`, `mquit`, `mtesters`, `mmid`, `pquit`), `ui/tools/hud_check.gd` (`_menus_a1_rules`), the regenerated pseudo-locale (`localization/pseudo/ui/data/terms.json`, `modes.json`) and `docs/ui/strings.md`, and `docs/ui/menus-a1.md`.
- `grant/main-gd-quit-and-fighters.patch` (**Rendering's `render/core/main.gd`; needs a grant**, 15 changed lines, `git apply --check` clean on HEAD): connects `ui_hud.quit_requested` to `get_tree().quit()`; keeps the menu's two fighters as the match setup's `slots` (`_slots`, `_slots_part()`, merged in `_match_setup` and in the intros-off start, kept for New match and Play again like `_ai_level`); the keyboard's Escape calls `ui_hud.request_quit()` instead of closing at once. The sim already reads and checks `slots` (`sim/core/sim.gd:202`, `SimRoster.slotsOk`), so Simulation needs nothing.
- `grant/schema-ui-modes.patch` (**`tools/schemas/`; needs a grant**): `ui-modes.schema.json` and its `map.json` entry. `node tools/validate.js` passes on the data and the schema fails a mode with no `players` or no `testers` (tried in a scratch copy). No fixtures cases added (Tools owns `tools/fixtures/cases.json`; say if you want them).

## What it does

- The start menu opens on the **list of modes** from data: Against the computer and Two players, one PC start a match; Two against two, Horde, Practice, Custom planet, Play over a network and Campaign say **Coming** and cannot be started. A row becomes playable when its data row says `"state": "ready"` and gives `players`. Each row has `testers`; with `testers_package` on, the network and campaign rows are left out (decisions 13 and 18).
- A on a ready mode opens the **setup**: Player 1 and its fighter, the computer's level (or Player 2) and that player's fighter, the comfort boxes, Legal's notice word for word, I understand start, Back. Fighters are read from the roster file (the practice dummy is left out) with names from `fighter_names.json`; the menu config gains `mode`, `p1_fighter`, `p2_fighter`.
- **Mirror picks are off** (`mirror_pick: false`): two of the same fighter cannot be told apart yet. The setup says so in plain words and a step onto the other player's fighter swaps the two. **Missing for a mirror: Art's second colour for one fighter (decision 17, A4).**
- **Quit** is a row on the list (not in the browser), on the pause list and on the match-over list; it asks "Close the game?" with Stay lit first. The host's Escape asks too (with the grant); with `menu_modes` off it closes as before.
- **D-pad (A-UI-06):** on the start menu Up and Down wrap at both ends (the single card too; the pad-only jump to Start is gone); the setup has no Players row, so Left and Right change only the lit row's own value (the one exception, a fighter step that swaps the two fighters, is in the test). A recorded pad session is in `docs/ui/runs/def3445a/a1-start-flow/pad-session.txt`.
- The version line ("Version <commit>") shows at the foot of the list when the host's report context has a commit.
- Where the Rail is not usable, or the two pages do not fit the screen (the list with Back and Quit needs about 720 pixels of height), the single card is the start menu, as before. Touch is untouched (ADR 0011).

## Tests

`_menus_a1_rules`: the words; modes.json's shape and the roster pick list (no dummy, roster order); the testers' package leaves out two rows and only there; at 1920x1080, 1280x720, 1280x800, 1366x768, 4K and 2560x1080, keyboard and pad hints, the list, Quit's question and the setup (one player, two, mid-match) fit with every control a target and Legal's notice word for word; in the HUD with a pad alone: the list wraps up and down, A on a coming mode does nothing, the setup opens, **every row in all four directions** (rows never change, Up and Down wrap, Left and Right change only the lit row), the fighters never match and the picks step, B goes back with the mode lit, Start tells the host once with mode and both fighters, Quit asks first and Stay is lit, B stays, the second answer closes once, the pause and match-over lists end with Quit, Escape asks, and with the switch off the old card wraps and the lists have no Quit. Whole gate, switch as shipped: 8459 checks, 0 failed (the new rules alone 720 with the Rail and pause-clock rules).

## Words for Orb to see before use (modes.json and terms.json)

"Choose a mode"; the eight mode names and their one-line cards ("Against the computer", "Two players, one PC", "Two against two, one PC", "Horde", "Practice", "Custom planet", "Play over a network", "Campaign"); "Coming"; "This mode is not in the game yet."; "Set up the match"; "Player 1 fighter", "Player 2 fighter", "Computer's fighter"; "Two of the same fighter can't be told apart yet, so each player needs a different one."; "Quit"; "Close the game?", "Close the game", "Stay"; "Version {v}". The mode names are working names until Game Design's come through the EP.

## Not in this park

A-WORLD-01 (the planet key from the menu) needs World's value for the round planet; A-PERF-08 (the window row) needs Rendering's definitions; the report and Save rows follow Tools' hook (A-UI-02, A-CODE-03).
