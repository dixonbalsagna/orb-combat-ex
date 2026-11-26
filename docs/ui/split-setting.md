# The Split screen setting (UI & UX, the EP, 2026-11-25)

Orb wants to try "split the screen sooner" in play. Camera builds what the camera does with it; UI owns the setting.

## The row

- Settings, Camera section, after "Split screen against the computer".
- Label: **Split screen**. Values: **Later**, **Standard** (the default), **Sooner**.
- Help: "When the screen splits in two as the fighters fly apart. Sooner keeps the fighters bigger; Later keeps both in one picture longer."
- Listed only while the feature `split_line_choice` (`ui/data/features.json`) is on. It is off on main and on in Orb's build.

## For Camera

- The option's key is `camera_split_line`; its values are the strings `later`, `standard` and `sooner`.
- Read it where the other camera options are read: `ui_hud.opts.get("camera_split_line", "standard")` in the host's `_sync_split_options` (`render/core/main.gd`), which runs every frame, so a change in the pause menu takes effect at once. The factor each value stands for is Camera's data.
- With the flag off the value is always `standard`, whatever the settings file holds.

## Saved

Through the Settings screen's usual path (`UiHud.settings_set`, `UiPrefs` "options"), applied at the next start by `load_saved_options`. A build without the flag leaves a saved choice in the file and does not apply it.
