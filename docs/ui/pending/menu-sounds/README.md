# menu-sounds (UI & UX, 2026-11-25): the menus ask for Audio's three sounds

Parked, not landed. Audio's five call lines (`docs/audio/pending/friends-sound/README.md`) in `ui/hud/ui_hud.gd`.

**Do not land this before Audio's `friends-sound.patch`.** `AudioVoices.ui` is added by that patch; without it `ui_hud.gd` does not parse. Land the two together.

## What the player hears (once both are in)

| Menu | Move | Confirm | Back |
| :--- | :--- | :--- | :--- |
| Start menu | arrows, stick, d-pad | Enter or A; a click on a row | Esc or B; a click on Back |
| Pause menu | arrows, stick, d-pad | Enter or A | Esc or B |
| Settings | rows, tabs, changing a value | Enter or A | closing |
| How to play | turning pages | | closing |

## Gap: some clicks stay silent

A mouse click or a tap in the **pause menu** or in **Settings** goes straight to the choice and passes through none of the five functions, so it makes no sound. The keyboard and the controller are covered. I kept to Audio's five lines; two more would cover the clicks, if wanted.

## Files

`menu-sounds.patch` (sha1 4a4e62a6e218): `ui/hud/ui_hud.gd` (five lines), `ui/tools/hud_check.gd`. No grant, no words, nothing drawn.

## Order

After the GW1c stack, `pad-recommended`, `howto-licence`, `split-setting` and Audio's `friends-sound.patch` (with its schema grant). The `ui_hud.gd` part also applies on main by itself.

## Proof (data folder pointed away from Orb's)

- Full hud_check on that order plus this patch: 8681 checks, 0 failed (`runs/hud-check-full.txt`).
- `runs/gates.txt`: validate and the content screen are clean. **The two-fighter ratchet fails on that tree, 367 against 365, and it is not this patch:** `audio/audio_scene.gd` lines 113 and 116 (`S.fighters[0]`, `S.fighters[1]`), from Audio's park. It would turn CI red when that lands.
- New rows use a stand-in audio node that records the names asked for: nothing with no menu open; move, confirm and back in the start menu and its clicks; one sound for one real key press in the pause menu; Settings and How to play per the table; safe with no audio node. Negative control (the five lines removed): the seven sound rows fail.
- Nobody has listened: the rows prove what is asked for, not how it sounds.
