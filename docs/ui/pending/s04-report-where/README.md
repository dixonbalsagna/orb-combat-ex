# s04-report-where: a desktop build names the folder reports really go in (UI & UX, 2026-11-20; park; the EP's S-04, docs/ep/reviews/GW1a-standin.md)

**The fault.** `render/core/main.gd:192` sets `ui_hud.lan_report_fn = _record_report` on every non-web build, and the HUD took a set hook to mean a LAN host. So after SAVE REPORT (the panel) and on the pause screen a desktop player was told "Saved reports go in the 'saved' folder beside the game." (the LAN build's folder) while `MatchRecorder` writes `user://reports`. A tester was sent to a folder that is never written.

**The fix (UI only; no grant, main.gd is untouched).**

- New HUD flag `report_lan` (off by default). The HUD says the LAN sentence only when it is on; a LAN host sets it with its hook (`hud_demo.gd --lan` now does). `UiHud.report_where()` picks: no hook, nothing; `report_lan`, the LAN sentence; otherwise the real folder.
- `UiFeedback.report_place(os_name, user_dir, appdata, home)` writes the real folder (`ProjectSettings.globalize_path("user://reports")`). The project sets no custom user dir (project.godot has no `use_custom_user_dir`), so the folder is Godot's default: `%APPDATA%\Godot\app_userdata\Orb Combat EX\reports` on Windows, `~/.local/share/godot/app_userdata/Orb Combat EX/reports` on Linux, `~/Library/Application Support/Godot/app_userdata/Orb Combat EX/reports` on macOS. The start that is the player's `%APPDATA%` (Windows) or home folder is abbreviated, so the sentence is short, carries no user name, and the Windows one pastes into a folder window's address bar. A folder outside both is written in full.
- Both places that said the folder use it: the pause screen's card and the feedback panel's saved state.

**The words (Orb sees them before they ship; two new lines in `ui/data/terms.json`, `prompt.report_where_pc` and `prompt.report_where_pc_win`):**

- Windows: "Saved reports go in this folder: %APPDATA%\Godot\app_userdata\Orb Combat EX\reports Paste it into the address bar of a folder window to open it."
- Linux and macOS: "Saved reports go in this folder: ~/.local/share/godot/app_userdata/Orb Combat EX/reports" (macOS: ~/Library/Application Support/...).
- LAN builds: unchanged, "Saved reports go in the 'saved' folder beside the game."

**Tests (hud_check, `_report_where_rules`, 9 checks; the report rules around it set `report_lan` where they play a LAN hook).** The sentence for Windows, Linux, macOS, a folder outside the home folder and no folder; the desktop sentence is not the LAN one; in the HUD: no hook says nothing, a desktop build says the folder and equals the sentence built from `MatchRecorder.DIR` (so it cannot drift from where the recorder writes), the pause screen and the panel's saved state say it; with `report_lan` on both keep the LAN sentence; the longest sentence fits on the pause card and the panel at five sizes, Rail on and off.

**Apply:** `git apply docs/ui/pending/s04-report-where/s04-report-where.patch` on main b0e20f9a (checked clean; sha1 of the patch in the report). Touches `ui/data/terms.json`, `ui/widgets/ui_feedback.gd`, `ui/hud/ui_hud.gd`, `ui/demo/hud_demo.gd`, `ui/tools/hud_check.gd`, `docs/ui/lan-report.md` (new section 4a), `docs/ui/strings.md` (regenerated), `localization/pseudo/ui/data/terms.json` and `options.json` (`pseudo.mjs --write`; options.json also carries a drift already on main: the right-stick default "stick" the pseudo file still had as "face").

**For others (through the EP).**

- A LAN host must set `ui_hud.report_lan = true` with its hook, or it will show the desktop folder. Nothing sets it today but the demo (main.gd has no LAN path yet).
- Tools: the same hook switches SEND for SAVE REPORT in the feedback panel on every desktop build, and `docs/tools/pending/code-03/README.md` lines 10 and 44 still say "no UI change".
- The pause card and the panel's saved state now carry a longer line on desktop. It is the existing foot-text slot, no new element, nothing over the fighters; whether it needs the side-by-side under the look gate is the EP's call.
