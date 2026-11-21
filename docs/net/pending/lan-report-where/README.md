# Park: lan-report-where, a LAN game says where its reports go (Netcode, 2026-11-20; UI's S-04)

UI's S-04 (`docs/ui/pending/s04-report-where/`) adds `ui_hud.report_lan`, off by default. On a desktop build the HUD now names the folder the recorder writes (`user://reports`). A LAN host must set the flag where it sets its report hook, or the HUD would show the desktop folder instead of "the 'saved' folder beside the game".

| File | Change |
| :--- | :--- |
| `net/tools/lan_kit.mjs` | In the kit's `main.gd` hook, right after `ui_hud.lan_report_fn` (the LAN saver), it sets `ui_hud.report_lan = true` when the HUD has the flag. It writes the HUD's sentence into the LAN log at the match's start (`report where: ...`), which is the row a check reads. `--lan-no-report-lan` (tests only) leaves the flag off: the control |
| `docs/net/lan-v1.md` | A paragraph |

**No grant needed.** The line is in the kit, which patches only its own scratch copy of `main.gd`. Main's `main.gd` is untouched.

`lan-report-where.patch`, sha1 16c503cd3616b6a80a2064e708952d7be5ae95c1. It applies on main b0e20f9a, alone, and works with or without UI's patch: the kit asks the HUD for the flag and for `report_where` before using either. **Land it before the next LAN folder build.**

The rows, on main b0e20f9a with UI's patch and this one (`docs/net/runs/b0e20f9a/lan-report-where/rows.txt`), the kit exported and run headless with `--lan-loop`:
- **The host and the join:** "Saved reports go in the 'saved' folder beside the game."
- **The control** (`--lan-no-report-lan`): the desktop sentence, "Saved reports go in this folder: %APPDATA%\Godot\app_userdata\Orb Combat EX\reports ...".
- 0 script errors in each.

The LAN folder recipe adds this line check to its rows.
