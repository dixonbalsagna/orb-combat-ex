# The game's logs in the report folder (path to Alpha 1 job 14, X-28; Tools' `docs/tools/report-scan.md` and the crash-file park)

When the game dies, or something looked wrong, a file in the report folder says why. The report folder is `user://reports` (the folder the pause screen names: "Saved reports go in this folder: ..."), the one the match recorder writes its files to. It now also holds two copies of the engine's log.

## What goes in

| File | What | From |
| :--- | :--- | :--- |
| `log-this-run.log` | the log of the run that is going now | `user://logs/godot.log` |
| `log-last-run.log` | the log of the run before it (the one a crash leaves) | the newest dated file in `user://logs` (the engine rotates the old log to a dated name at each start; it keeps five) |

Each copy is cut to its last 200 KB (whole lines only; a cut that lands inside a line drops that line), starts with one line that says what was done to it, and is cleaned BEFORE it is written (below). A copy is overwritten by the next one; the match files keep their own names and their own prune.

## When it happens

- A report is saved (F9, the feedback panel's save, "Save this match"): after the match file is written, the host calls `UiReportLogs.copy_into`. The logs sit beside the match file.
- A start that follows a run that did not close properly: at every start the game writes a marker file for itself (`user://run-marker-<process id>.txt`, the id inside too) and deletes it at a clean close (`main.gd` `_exit_tree`, which `get_tree().quit()` reaches). A start that finds a marker whose process is gone knows that run died or was killed: it deletes it and copies the logs into the report folder at once, so the dead run's log is there before anyone has to ask. A marker whose process is still running is another copy of the game (a local network test on one PC) and is left alone. Whether a process runs is asked only when such a marker is found: `tasklist` on Windows, `/proc` on Linux (else `kill -0`); a probe that cannot run counts as not running, and the worst that does is one extra copy. An id that came round again for a new game reads as a dead run (a missed crash is possible only if another process holds a dead run's id). A web build has no log folder and does nothing.

Nothing is sent anywhere. The files are on the player's own PC, for the player to post if they choose.

## Headless runs do nothing

Every headless check any session runs (render gates, hud_check, QA batches) starts the game on a PC whose default data folder is the player's own. So a headless start (`DisplayServer.get_name() == "headless"`) writes no marker, copies no logs and deletes nothing, `stop` included (a tool that frees the game's scene at its end must not delete the marker of a game being played), and a saved report copies no logs (`UiReportLogs.active()`; the three hooks go through `start`, `stop` and `report_saved`, which all ask it). A killed or timed-out headless run therefore leaves no marker for the player's next start to find.

The one opt-in is an Engine meta, `report_logs_headless`, that only a scratch probe sets: Tools' forced-crash check (`tools/crash/crash-check.mjs`) puts it at the top of the autoload it adds to its scratch export (`grant/crash-check-x28.patch`), because that check runs the exported program headless and needs the marker and the copy. Nothing a player can reach reads or sets it: no command-line word, no setting, no file. hud_check scans the shipped scripts (`ui/` and `render/`, outside tools, tests and demos) and fails if any sets the meta or if any script but `UiReportLogs` mentions it. The meta is in a scratch autoload, never in the repository's game.

## What cleaning does

`ui/data/report_clean.json` (a mirror of `tools/report-scan.json`'s patterns, because `tools/` is not in an export; `hud_check` fails if the two differ), applied line by line in this order:

| Match | Becomes |
| :--- | :--- |
| a Windows user folder (`C:\Users\<name>`, also with `/`), a home folder (`/home/<name>`, `/Users/<name>`, `/c/Users/<name>`) | `<user>` (the rest of the path stays) |
| a path on a drive | `<path>` |
| a network share, an email address, an IPv4 address (not 127.0.0.1 or 0.0.0.0), a network card's address | `<removed>` |
| the account name of this machine, as a whole word in any case (3 letters or more) | `<user>` |
| the PC name of this machine, the same way | `<removed>` |

The engine's own banner lines (`Godot Engine v...`, `Vulkan ...`, `OpenGL ES ...`, `Mesa ...`, `Requested V-Sync`) are left as they are, as the scan leaves them. The account and PC names come from the environment (`USERNAME` or `USER`; `COMPUTERNAME` or `HOSTNAME`).

## Hooks (Rendering's `render/core/main.gd`: a grant patch)

- `_ready`: `UiReportLogs.start(MatchRecorder.DIR)` (desktop only).
- `_exit_tree`: `UiReportLogs.stop()`.
- `_record_report`: after the match file is written, `UiReportLogs.report_saved(MatchRecorder.DIR)`.

## Checks

- `ui/tools/hud_check.gd` `_report_logs_rules`: a headless run does nothing (and the opt-in turns it on); no shipped script sets the opt-in; the data equals Tools' scan file; each pattern by example with made-up names (never a real one); whole-word names, any case, short names left; banner lines left; the cut; the two copies from the right files; no log folder gives nothing; the marker flow (first start, a start that finds the marker, a clean stop, a start again).
- Real runs, data folder pointed away: a match, a report through the host's own hook (the folder holds the match file and both logs, with no account or PC name in them), the marker gone after a clean tree exit and after the game's own `--frames` quit; `node tools/crash/crash-check.mjs --expect-report` (row 6); `node tools/report-scan.mjs <the report folder>`.
- `tools/schemas/ui-report-clean.schema.json` (Tools' folder: a grant patch) is the file's shape.
- Real runs headless, data folder pointed away, with and without the opt-in (`runs/x28-probe-*.txt`): without it a match and a saved report leave only the match file and no marker; with it the marker, the copies and the clean exit work.

## Not done

- A hang leaves no reason line in a log (Tools' note); nothing here changes that. The marker only says that the run did not end properly.
- No words for the player: the game does not say "the last run did not close properly" anywhere yet. If Orb wants it said, it is a line on the first screen or the pause card, and Orb sees the words first.
