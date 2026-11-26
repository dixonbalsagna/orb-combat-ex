# split-setting (UI & UX, 2026-11-25): the "Split screen" row on Settings

Parked, not landed. Design and the note for Camera: `docs/ui/split-setting.md` (in the patch).

## What the player sees (only with the flag on)

Settings, Camera section, last row: **Split screen**, with **Later**, **Standard** (the default) and **Sooner**.

Help: "When the screen splits in two as the fighters fly apart. Sooner keeps the fighters bigger; Later keeps both in one picture longer."

Still: `runs/stills/settings-camera-flag-on.png`.

## Names

- Option `camera_split_line` (choice: `later`, `standard`, `sooner`; default `standard`; group display). Camera's names.
- Flag `split_line_choice` in `ui/data/features.json`, **off**. The EP turns it on in Orb's build.
- Camera reads `ui_hud.opts.get("camera_split_line", "standard")` in `_sync_split_options` (`render/core/main.gd`, Camera's grant, not in this patch).

## How the flag hides the row

`settings.json`'s `needs` only dims a row and marks it "Soon", so the row is also in `UiSettings.HIDE_UNTIL`: with the flag off it is not listed at all. The `needs` entry stays so the validator checks the flag exists. With the flag off a saved choice is not applied (the camera hears `standard`) and is kept in the settings file.

## Files

`split-setting.patch` (sha1 ebd0a426a0ac): `ui/data/options.json`, `settings.json`, `features.json`, `ui/widgets/ui_settings.gd`, `ui/hud/ui_hud.gd`, `ui/tools/hud_check.gd`, the pseudo-locale `options.json` and `settings.json`, `docs/ui/strings.md`, `docs/ui/split-setting.md`. **No schema change and no grant.**

## Order

Waits for Camera's switch. Applies strictly after the next landing (`pad-recommended`, `howto-licence`, `menu-sounds`, `menus-a1-sizes`) on ac4ba152; re-cut 2026-11-25 for that order (no change to what it does). Until Camera's line lands, the flag should stay off: the row would do nothing.

## Proof (data folder pointed away from Orb's)

- Full hud_check, first cut (on the GW1c stack and pad-recommended): 8670 checks, 0 failed (`runs/hud-check-full.txt`). Re-cut: its rows and the Settings rows on the new order, 237 checks, 0 failed.
- New rows: hidden with the flag off; shown, live and reading Standard with it on; remembered in a later session; a saved choice is not applied but kept with the flag off; the screen fits at 1280x720, 1280x800 and 1920x1080. Negative control (without the hiding entry and the saved-choice guard): the two flag-off rows fail, and the existing "every row is live" row.
- Mode smoke, solo and two: pass (24 steps each).
- Ratchets 365/365 and 0/0; validate 0 errors; content screen 0 failing hits (`runs/gates.txt`).
- One still. It is the HUD demo on its stand-in background (no fighter art), with the flag on in a scratch copy.
