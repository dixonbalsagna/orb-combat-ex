# A1: UI & UX Director

Leads: A-MODES-01, A-MODES-06, A-MODES-11, A-MODES-15, A-UI-01, A-UI-04, A-UI-06, A-UI-09
Supports: A-WORLD-01, A-PERF-08, A-MODES-08, A-UI-02, A-TOOLS-07, A-CODE-03

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: A player with only a pad starts the game on the left-panel menus Orb picked, sees a list of modes, picks a fighter, pauses and sees the pause menu, moves the d-pad evenly, and can quit; and there is a still of every menu at the Steam Deck's screen size.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1; the X-05 and X-22 lines in "Exit criteria this audit proposes to change"); `docs/ep/alpha/audit-2026-11-13/02-areas/UI.md` and `MODES.md`; `docs/ui/menus-rail.md`; `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`; `docs/ep/vision.md` lines 1683 and 1690. "Rail" is the team's name for the menus with the panel down the left.
- A-MODES-01 (blocker): the start menu has no list of modes; six of the eight Alpha modes have no entry. Evidence: `ui/widgets/ui_menu.gd:8`, `:74-86`; `render/core/main.gd:1337-1348`; `ui/hud/ui_hud.gd:1695-1737`.
- A-MODES-06 (blocker): there is no fighter select; player one is always the Protagonist and player two always the rival. Evidence: `sim/core/sim.gd:202`; `data/fighters/roster.json:1`; `ui/widgets/ui_menu.gd:8`.
- A-MODES-11: with a pad alone a player cannot close the game; the only quit is the keyboard's Escape, which closes at once with no question. Evidence: `ui/widgets/ui_pause.gd:8-14`; `render/core/main.gd:1596-1598`.
- A-MODES-15: the Rail menu is off on main and on only in the played build. Evidence: `ui/data/features.json:49`; `ui/widgets/ui_rail.gd:3-5`; `docs/tools/runs/6a30b4c9/build-and-smoke.txt`.
- A-UI-01 (blocker): with the Rail on, the pause menu's slide-in is timed on a HUD clock the game stops while paused, so by reading the code the menu stays off the screen (not reproduced). Evidence: `ui/hud/ui_hud.gd:2116`, `:2149`, `:512`; also `render/core/main.gd:811` and `:1326`, `ui/widgets/ui_rail.gd:27`, `ui/widgets/ui_pause.gd:356`, `ui/tools/hud_check.gd:10961` (the test advances the clock itself, unlike the game).
- A-UI-04: making the Rail the default is unfinished: three older HUD checks fail with it on, its checks leave out 1280 by 800, and only its Start screen has a saved still. Evidence: `ui/data/features.json:49`; `docs/ui/runs/592a807b/menus-rail/gate-switch-pinned-on.txt:1` (3 failed of 8288); `ui/tools/hud_check.gd:10824`; also `docs/ui/menus-rail.md:46`. The smoke mis-click named in the row is already fixed on main (`tools/preview/smoke.mjs:110`).
- A-UI-06: the start menu's d-pad is uneven: Up from the top row jumps to Start while Down from the bottom row stops, and Left or Right on the Players row swaps the row two below it (by reading; not reproduced). Evidence: `ui/hud/ui_hud.gd:1816`; `ui/widgets/ui_menu.gd:302`; `ui/hud/ui_hud.gd:1708`; also `ui/widgets/ui_menu.gd:76`.
- A-UI-09: no still of any screen at 1280 by 800 exists and no tool sweeps every screen at that size. Evidence: `ui/tools/text_size_check.gd:7`; `ui/tools/hud_check.gd:10824`; `docs/ui/runs/397a7adf/menus/today-start-1280x720.png`.

You own: `ui/`, `docs/ui/`.
- ask under NEEDS FROM EP for a grant: `render/core/main.gd` (Rendering's path: the routing at lines 1337-1348, the Escape quit at 1596-1598, the clock passed while paused at 811; name the exact lines you need changed)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (the mode list and the fighter pick are new data shapes; the schema moves in the same commit)
- The fighter a match starts with is read in `sim/core/sim.gd:202` (Simulation's): if the pick needs more than the match setup already takes, list it under NEEDS FROM EP.

Acceptance criteria:
1. (A-UI-01) One still of the pause screen from a Rail build with Reduce motion off and one with it on settles the cause first. Then: pausing in a match shows the pause menu and its detail card, and `hud_check` has a case that opens the pause menu the way the game does (clock stopped). Result saved under `docs/ui/runs/<sha>/`.
2. (A-UI-06) On the start menu the d-pad either wraps at both ends or stops at both ends, and Left or Right on one row never changes which row sits elsewhere under the cursor. A `hud_check` case walks every row in all four directions; a recorded pad session on the start menu is saved beside it.
3. (A-UI-04, A-MODES-15) With items 1 and 2 done: the three older HUD checks pass or are rewritten with a reason each; the Rail's checks include 1280 by 800; every Rail screen has a saved still; then `menus_rail` is on in `ui/data/features.json` and the switch row is gone from the build tool's table (Tools). Checked by reading the first desktop build's packed `features.json`.
4. (A-MODES-01, X-05, X-19) The start menu opens on a list of modes built from a data file, so a row appears when its mode lands. Today's two (solo against the computer, two players on one PC) start a match; the unbuilt ones are shown as "coming" and cannot be started. Reached and started with a pad alone. A `hud_check` case covers the list.
5. (A-MODES-06, X-05, X-19) Each player picks a fighter from the roster file before the match, with a pad alone, and the match starts with those fighters; the list is read from data, with no fighter named in code. A mirror pick (two of the same fighter) is offered only if the two can be told apart on screen; if not, the menu says so in plain words and your report says what is missing (the second colour is decision 17, A4).
6. (A-MODES-11, X-05, X-19) The start menu, the pause list and the match-over list each have a Quit row a pad can reach, and it asks once before closing. The keyboard's Escape no longer closes the game with no question.
7. (A-UI-09, X-22, first reading) A sweep tool produces a still of every menu and HUD state at 1280 by 800 and lists the smallest text on each (proposed: 9 px is the floor that fails, 12 px the aim). The tool existing and one full set saved under `docs/ui/runs/<sha>/` closes this item; clipped or small text is expected and is listed, not fixed, in A1. Stills are captured only through Tools' launcher.
8. (Look gate, ADR 0010) Items 1 to 6 all change what a player sees: each ships with a side-by-side against the reference build (`node tools/flash/side-by-side.mjs`; stills plus a short GIF) before the EP commits. The Rail's slide-in stays a quick slide: no dissolve, no fade, no slow wipe.
9. (Supports) A-WORLD-01: the menu sets the planet key so a menu match plays the round planet. A-PERF-08: one options row for the window (fullscreen and the frame cap, as Rendering defines them). A-MODES-08: every menu row has a stable name the smoke suite can find, so it never clicks fixed screen points. A-UI-02 and A-CODE-03: the report and "Save this match" rows work once Tools moves the hook onto main. A-TOOLS-07: the version number shows on the start menu.

Constraints:
- Tokens: about 4.85M as an estimate (three rows of size M at 1.2M, five of size S at 0.25M).
- State hash: none of this changes the sim's state fingerprint. The HUD and menus never write sim state; a "getter" that resizes a hashed field counts as a write.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; long runs at below-normal priority; no browser of your own (stills only through Tools' launcher; one capture at a time; check nothing you started is still running before you end a turn).
- Determinism and data: menu rows, mode names and options live in data files; a data shape change updates its schema in the same commit.
- Originality: nothing from an existing franchise, in layout, wording or icons.
- Orb's rules: a minimalist UI; nothing drawn on, over or between the fighters; no health bar; no dissolves or fades; no debug or key-help text in a build; plain words; every line of forward-facing text (mode names, "coming", the quit question) is seen by Orb before use; the AI disclosure stays where it is on the way to the menu.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before the Rail flip: Orb's yes to decision 1, the working tree committed or deliberately ignored (A-PROCESS-03), then A-UI-01 and A-UI-06, then A-UI-04, then A-MODES-15. A-MODES-06 follows A-MODES-01. The mode list needs Game Design's mode names (through the EP). The mode list, the pick, the Quit row and the sweep are built on a scratch copy from day one. Waiting on this: A-CODE-01 (no row differs); Tools' mode smoke suite (A-MODES-08) and the first desktop build (A-TOOLS-01); later, the fixes the sweep's list calls for.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- The mode list is data, and each mode row carries a "shown in the testers' package" flag; the campaign and LAN rows are off in a tester's package until Orb answers decisions 13 and 18. (ORB-10)
