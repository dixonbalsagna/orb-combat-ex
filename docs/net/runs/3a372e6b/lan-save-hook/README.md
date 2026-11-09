# Netcode run, 2026-11-08: lan-save's second patch, UI's report-this wired (lan-save-hook) (CD-22)

`docs/net/pending/lan-save/lan-save-hook.patch` (sha1 e9e241b6e7c5) goes on top of `lan-save.patch` (db4afbd3ccca), on HEAD **3a372e6b**:
- The kit sets `ui_hud.lan_report_fn` to `host.lan.report` where it starts the LAN match, when UI's hook exists.
- The kit's own F9 / View + RB handler stands down then, so a press saves once.
- NetLan's REPORT SAVED banner goes quiet then (UI shows "Report saved: <file>").
- A test-only `--lan-press-f9-at=T` sends a real F9 press at tick T.

No socket was opened; no `enet_check`. The profile path is written `<user>`.

| File | What it is | Result |
| :--- | :--- | :--- |
| `a01_lan_check.txt`, `b01_lan_check.txt` | `lan_check.gd -- --ticks=1200`, and with `--negative-control`, through `gate.mjs`, on HEAD with both patches | 0 failed, 0 SCRIPT ERROR |
| `f9ui.txt` | A full stack tree of HEAD with UI's `report-this.patch` (its `features.json` switches set by hand: the stack tree's flipped switches move that hunk) and both patches; the kit with an export; the game headless (`--lan-loop`), F9 pressed at tick 600 | One press, **one** report file (UI's handler calling the hook; the kit's stood down): reason report, 1 mark at tick 600, the replay to tick 600 with 10 checkpoints and the final hash. No script errors |
| `f9own.txt` | The same without UI's patch | One report file, from the kit's own handler: the same contents. No script errors |
