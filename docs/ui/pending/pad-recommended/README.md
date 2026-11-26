# pad-recommended (UI & UX, 2026-11-25): the keyboard works, a controller is recommended (decision 20, second half)

Parked, not landed. GW1c has landed (ac4ba152). **Next landing, first of four:** this, then `howto-licence`, `menu-sounds`, `menus-a1-sizes`; all four apply strictly in that order on ac4ba152 (checked 2026-11-25; patch unchanged).

## What the player sees

On the first visit to the list of modes only, one quiet line under the list, in the help text's ink, with no box, icon or button:

> You can play with a keyboard or a controller.
> A controller feels best.

- Not shown with a controller plugged in. It goes as soon as a controller is used or the player goes on, and does not come back (remembered as `pad_tip_seen`). Left out where the screen has no room; it never makes the menu stop fitting. Not on the flashing-effects warning.
- The start menu's button hints now follow the device last used (a key: keys; a button or stick push: controller). This was a gap: they stayed on keys until the pause menu or Settings had seen the pad. A menu opened with a controller plugged in starts with the controller's hints.
- The controller side of the decision (the unplug pause) has landed already.

## Files

`pad-recommended.patch` (7 files): `ui/hud/ui_hud.gd`, `ui/widgets/ui_menu.gd`, `ui/data/terms.json` (one word, `prompt.pad_tip`), the pseudo-locale, `docs/ui/strings.md`, `docs/ui/menus-a1.md` (section 12), `ui/tools/hud_check.gd` (`_pad_tip_rules`). No grant.

**Applies:** strictly on ac4ba152 (GW1c landed). The proof below was taken on the GW1c stack on 7720b10b, before it landed.

## Proof (GW1c stack plus this patch; data folder pointed away from Orb's)

- Full hud_check: 8663 checks, 0 failed. `_pad_tip_rules`: shown once and remembered (setup and Back, the next open, a later session); not shown with a controller plugged in; it sits under the list; the hints follow a controller press and a key; the menu opens with controller hints when one is plugged in; it never changes whether the list fits, and is shown at 1280x720, 1280x800 and 1920x1080. Negative control, run: without the "seen" flag and the pad-press hint, 5 rows fail.
- Mode smoke, solo and two: 24 steps each, pass.
- Both ratchets: two-fighter 365 against 365, fighter-specific 0 against 0.
- Look gate stills in `runs/stills/`: the list of modes before and after (the demo scene's web build, 1280x800, no controller). No fighter is in either.

## Words for Orb (one new)

"You can play with a keyboard or a controller. A controller feels best." (shown as two lines)
