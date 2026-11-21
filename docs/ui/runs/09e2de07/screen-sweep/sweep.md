# Screen sweep at 1280x800

Floor 9 px (fails), aim 12 px. A clipped or small text is listed here and not fixed (A1). Stills through tools/machine/capture.mjs.

| State | Still | Lines | Smallest text | Its line | Off screen | Verdict |
| :--- | :--- | ---: | ---: | :--- | ---: | :--- |
| menu-modes | menu-modes-1280x800.png | 24 | 14 px | ORB COMBAT EX | 0 | ok |
| menu-modes-midmatch | menu-modes-midmatch-1280x800.png | 27 | 14 px | ORB COMBAT EX | 0 | ok |
| menu-setup-solo | menu-setup-solo-1280x800.png | 39 | 14 px | ORB COMBAT EX | 0 | ok |
| menu-setup-two | menu-setup-two-1280x800.png | 38 | 14 px | ORB COMBAT EX | 0 | ok |
| menu-quit | menu-quit-1280x800.png | 11 | 14 px | ORB COMBAT EX | 0 | ok |
| menu-single-card | (held back: not the measured state) | 34 | 14 px | ORB COMBAT EX | 0 | ok |
| pause | (held back: a fighter shows) | 19 | 14 px | ORB COMBAT EX | 0 | ok |
| pause-lan | (held back: a fighter shows) | 25 | 14 px | ORB COMBAT EX | 0 | ok |
| pause-new-match-question | (held back: a fighter shows) | 10 | 14 px | ORB COMBAT EX | 0 | ok |
| pause-quit-question | (held back: a fighter shows) | 10 | 14 px | ORB COMBAT EX | 0 | ok |
| match-over | (held back: a fighter shows) | 16 | 14 px | MATCH OVER | 0 | ok |
| match-over-saved | (held back: a fighter shows) | 20 | 14 px | MATCH OVER | 0 | ok |
| settings | (held back: a fighter shows) | 43 | 14 px | Q | 0 | ok |
| settings-old-card | (held back: a fighter shows) | 25 | 14 px | Arena: triggers dodge and charge power,  | 0 | ok |
| hud-hero-vs-proud | (held back: a fighter shows) | 197 | 14 px | Shift | 0 | ok |
| hud-empress-vs-cyborg | (held back: a fighter shows) | 112 | 14 px | CPU | 0 | ok |
| hud-placeholders | (held back: a fighter shows) | 102 | 14 px | CPU | 0 | ok |
| hud-stress | (held back: a fighter shows) | 145 | 14 px | CPU | 0 | ok |
| hud-controls | (held back: a fighter shows) | 161 | 14 px | LB | 0 | ok |
| howto | (held back: a fighter shows) | 68 | 14 px | Shift | 0 | ok |
| howto-about | (held back: a fighter shows) | 68 | 14 px | Shift | 0 | ok |
| feedback | (held back: a fighter shows) | 61 | 14 px | Shift | 0 | ok |
| remap | (held back: a fighter shows) | 81 | 14 px | Shift | 0 | ok |
| first-run-notice | (held back: not the measured state) | 62 | 14 px | Shift | 0 | ok |


Taken 2026-11-21 on Tools' demo-scene web export of 09e2de07 (hud_demo.tscn as main) through tools/machine/capture.mjs, one capture at a time; the text half ran headless on a clean copy of 09e2de07. 24 states, 24 stills taken, **5 kept** (the start menu's pages, which show no fighter). **19 are held back and not in the commit**: 17 show a fighter's body or the speech portrait behind the card (the pause, match-over, settings, how-to, feedback and remap pages sit over the demo's match, and the five HUD scenes are matches), and 2 (`menu-single-card`, `first-run-notice`) are the same picture as `menu-modes`: with the Rail on by default the web page draws the Rail menu for the old single card and the old first-run notice, so their rows (34 and 62 lines) measure a card the page no longer shows. The text half is complete for all 24: none under the 12 px aim, none with text off the screen.
