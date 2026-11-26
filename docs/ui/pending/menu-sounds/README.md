# menu-sounds (UI & UX, 2026-11-25): the menus ask for Audio's three sounds

Parked, not landed. Audio's five call lines (`docs/audio/pending/friends-sound/README.md`) in `ui/hud/ui_hud.gd`, plus three lines for mouse clicks and taps in the pause menu and Settings (the EP's yes, 2026-11-25), which pass through none of the five.

**Do not land this before Audio's `friends-sound.patch`.** `AudioVoices.ui` is added by that patch; without it `ui_hud.gd` does not parse. Land the two together.

## What the player hears (once both are in)

| Menu | Move | Confirm | Back |
| :--- | :--- | :--- | :--- |
| Start menu | arrows, stick, d-pad | Enter or A; a click on a row | Esc or B; a click on Back |
| Pause menu | arrows, stick, d-pad | Enter or A; a click on an entry | Esc or B |
| Settings | rows, tabs, changing a value, by key, pad or click | Enter or A; a click on a switch or button | closing, also by its cross |
| How to play | turning pages | | closing |

A click or tap says what the same choice says on a key. Silent: a click on nothing or on a greyed-out row, and dragging (a slider says one move on the press, not while dragged). The Remap screen and the report panel make no menu sound by any input (they were not in Audio's list).

## Files

`menu-sounds.patch` (sha1 58ba128eb065): `ui/hud/ui_hud.gd` (eight places), `ui/tools/hud_check.gd`. No grant, no words, nothing drawn.

## Order

After the GW1c stack, `pad-recommended`, `howto-licence`, `split-setting` and Audio's `friends-sound.patch` (with its schema grant). The `ui_hud.gd` part also applies on main by itself.

## Proof (data folder pointed away from Orb's)

- Full hud_check on that order plus this patch: `runs/hud-check-full.txt`.
- `runs/gates.txt` was taken on Audio's first cut of `friends-sound`: validate and the content screen are clean, and the two-fighter ratchet fails there (367 against 365) on `audio/audio_scene.gd`, not on this patch. Audio has the fix; check the ratchet again with the re-cut.
- New rows use a stand-in audio node that records the names asked for: nothing with no menu open; move, confirm and back in the start menu and its clicks; one sound for one real key press in the pause menu; Settings and How to play per the table; real mouse events on a pause entry, a Settings tab, arrow, slider, switch and cross, and on nothing; safe with no audio node. Negative controls: without the five lines the seven first rows fail, without the three click lines the three click rows fail.
- Nobody has listened: the rows prove what is asked for, not how it sounds.
