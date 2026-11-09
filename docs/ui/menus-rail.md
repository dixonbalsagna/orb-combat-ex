# The Rail menus (UI & UX, 2026-11-09; Orb picked mockup A on 2026-11-09: "rail looks great, keep going")

**Status: built behind a switch, off.** `menus_rail` in `ui/data/features.json` (false). With it off every screen is exactly as before. The mockup is `docs/ui/mockups/menus-modern/a-rail.html`; the design pass and the choices behind it are in `docs/ui/menus-modern.md`. This page is what the code does.

## 1. What changed

One frame for four screens: a dark rail down the left edge with the screen's name and its choices, the lit choice a solid bar with a gold notch (a shape as well as a colour), the detail on the right, and the buttons for the player's own device along the foot of the screen.

| Screen | The rail holds | On the right |
| :--- | :--- | :--- |
| **Start** | Players, Player 1, Player 2 or Computer (the ways to play side by side on the row, the chosen one a pill), then Intros, Reduce flashing, Screen shake, Captions, Move guide as switches | Legal's notice word for word in its own card ("Read this first", not shown mid-match); a "This match" card (You, Against, the one-line help that was under the radios); Reduce flashing's line; **I understand, start** in gold; Not now (or Back to the match) quiet |
| **Pause** | Resume, How to play, Settings, Send feedback, About, (Hand player two back), Main menu, New match (the keyboard letters P, F1, N only while the last device was the keyboard) | A "This match" card (buildings lost, craters, and on a LAN build where saved reports go); the join line as a chip |
| **New match?** | Start a new match? with New match and Keep playing | nothing |
| **Match over** | The result as the title, Play again, Save this match, Main menu, Send feedback | The two counts, what a save did, where saved reports go |
| **Options** | (no rail) tabs across the top, one per section, with LB and RB (Q and E) at its ends; the rows in a dark panel on the left | The focused row's name and words, then "Now: X. Default: Y."; a close cross at the top right |

The hint strip draws the buttons of the device the player last used: a pad shows its own marks (the player's glyph style), a keyboard its caps, never both. Pause says Choose, Select and Resume; Start says Choose, Select and Not now; Options says Choose and change, Tabs and Back.

## 2. Motion (ADR 0010: slides and eases only)

- The rail slides in from the left edge in 180 ms (ease-out); the detail slides in from the right edge. On Options the tabs come down from the top, the rows from the left, the help from the right.
- The lit bar slides between rows in 140 ms (ease-out). On Options the focus ring on a row cuts, as it does today.
- With Reduce motion on, both cut. Nothing fades, wipes, blurs, pulses or flashes; the dim over the world is fixed.
- The layers repaint only when their key changes, so each plan's key carries the quantized slide and bar steps (40 steps over their length); a held screen costs nothing.

## 3. Where it does not apply

`UiRail.usable`: the switch on, not a touch screen (phone work is parked, ADR 0011), at least 1000 by 600, and wide (at least 1.3 to 1). Anything else keeps today's layout. Each screen's Rail plan also falls back to today's layout wherever it does not fit (a title over three lines, rows that do not fit above the hints, a file name wider than the card), so no size is ever worse than today. The Remap screen keeps its card.

## 4. Input (unchanged except the tabs)

Each screen's own actions are what they were: the same `menu_action`, `pause_menu_action` and `settings_action` and the same plan keys (`items`, `rows`, `focus`, `row_boxes`, `hit`, `moved`), so the host and the older checks work on either layout. New: on Options **LB and RB** (Q and E) go to the previous and next section (wrapping), focusing its first row and bringing it to the top; a click on a tab does the same. With the Rail off, LB and RB page through the rows as before and Q and E do nothing.

## 5. Words

New terms (`prompt.rail_*`): the kicker, Paused, Match over, This match, Read this first, Start a match, You, Against, The computer, Hand player two back, the hint words (Choose, Select, Resume, Keep playing, Play again, Not now, Back, Tabs, Choose and change) and "Now: {now}. Default: {default}." Every old word (Legal's notice, I understand start, Not now, the pause and match-over entries) is untouched. The strings page and the pseudo-locale are regenerated.

## 6. Try it

The demo's web build takes `?rail` with any screen: `?rail&menu`, `?rail&menu=2&rdevice=pad&rdown=3`, `?rail&pause&lan`, `?rail&ko&over&lan&saved`, `?rail&settings=1`; `rdevice=pad` shows the pad's buttons, `rdown=N` moves the lit row, `rreduced` cuts the motion.

## 7. Tests

`_menus_rail_rules` in hud_check: the switch ships off and the old plans are untouched with it off; every new word exists; the ease and the slide are monotone, 180 and 140 ms, cut under Reduce motion; at eleven sizes, touch on and off, kbd and pad, the pause plan in five states (pause, new match, two people with the join line, match over with a saved file, a LAN pause), the start menu in three (one player, two, mid-match) and Settings all fit, every control is a real target inside its panel, the detail and chip clear the rail, the hints show one device only, Legal's notice is the plan's text word for word, and the narrow or short sizes keep today's layout; the lit bar sits on the focused row, slides and cuts; the plan keys change with the animation step; in the HUD the rail slides in and holds, the D-pad moves the lit row and the hints switch to the pad, Reduce motion cuts, LB, RB, Q, E and a click move between tabs, and with the switch off Q and E do nothing and RB pages as before.

## 8. Left for later

- **Comfort switches** stay on the Start screen (Orb has not answered the question in docs/ui/menus-modern.md section 8).
- **Reset this page (Y)** from the mockup is not built (nothing in the HUD resets a page yet); the hint strip does not show it.
- **Phone layouts** are parked (ADR 0011).
