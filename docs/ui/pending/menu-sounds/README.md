# menu-sounds (UI & UX, 2026-11-25): the menus ask for Audio's three sounds

Parked, not landed. Audio's five call lines (`docs/audio/friends-sound.md`) in `ui/hud/ui_hud.gd`, plus three lines for mouse clicks and taps in the pause menu and Settings (the EP's yes, 2026-11-25), which pass through none of the five.

**Needs Audio's `AudioVoices.ui`, which is on main since 7bfbfe6a.** Lands right after GW1c (the EP).

## What the player hears (once this is in)

| Menu | Move | Confirm | Back |
| :--- | :--- | :--- | :--- |
| Start menu | arrows, stick, d-pad | Enter or A; a click on a row | Esc or B; a click on Back |
| Pause menu | arrows, stick, d-pad | Enter or A; a click on an entry | Esc or B |
| Settings | rows, tabs, changing a value, by key, pad or click | Enter or A; a click on a switch or button | closing, also by its cross |
| How to play | turning pages | | closing |

A click or tap says what the same choice says on a key. Silent: a click on nothing or on a greyed-out row, and dragging (a slider says one move on the press, not while dragged). The Remap screen and the report panel make no menu sound by any input (they were not in Audio's list).

## Files

`menu-sounds.patch` (sha1 f685617ca70b): `ui/hud/ui_hud.gd` (eight places), `ui/tools/hud_check.gd`. No grant, no words, nothing drawn.

## Order

Next landing, third of four: after `pad-recommended` and `howto-licence`, strictly, on ac4ba152. Re-cut 2026-11-25 without `split-setting` under it (the code lines are unchanged; only the place the checks are added moved).

## Proof (data folder pointed away from Orb's)

- Full hud_check on ac4ba152 plus the four parks of the next landing: 8677 checks, 0 failed (`runs/hud-check-full.txt`).
- The sound rows alone on that state: 57 checks, 0 failed.
- `runs/gates.txt`, on that state: both ratchets pass (365/365, 0/0), validate 0 errors; the content screen on the repo is clean.
- New rows use a stand-in audio node that records the names asked for: nothing with no menu open; move, confirm and back in the start menu and its clicks; one sound for one real key press in the pause menu; Settings and How to play per the table; real mouse events on a pause entry, a Settings tab, arrow, slider, switch and cross, and on nothing; safe with no audio node. Negative controls: without the five lines the seven first rows fail, without the three click lines the three click rows fail.
- Nobody has listened: the rows prove what is asked for, not how it sounds.
