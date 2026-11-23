class_name UiReportLogs
extends RefCounted
## The game's logs in the report folder (path to Alpha 1 job 14, X-28; docs/ui/report-logs.md; docs/tools/report-scan.md). The report folder (`user://reports`, where the match files go) also gets the engine's log, so
## that when the game died, or something looked wrong, a file says why. Two copies, each cut to its last 200 KB and cleaned BEFORE it is written:
##   log-this-run.log   the log of the run that is going now (user://logs/godot.log)
##   log-last-run.log   the log of the run before it (the newest dated file in user://logs: the engine rotates the old log to a dated name at each start)
## Cleaning is data (ui/data/report_clean.json, a mirror of tools/report-scan.json's patterns, which are Tools'): a user's folder becomes <user>, a drive path <path>, a network share, an email, an IPv4 address and a
## network card's address <removed>, and the account name and the PC name of this machine, as whole words in any case, become <user> and <removed>. Tools' report scan (node tools/report-scan.mjs <folder>) is the proof from outside.
## Nothing here reads or writes the sim, and nothing is sent anywhere: a file on the player's own PC, for the player to post if they choose.
## When it runs: a report is saved (the host calls `copy_into` after it, with the folder), and at a start that follows a run that did not close properly (`start`: a marker file written at start and deleted at a clean quit, `stop`).

## HEADLESS RUNS DO NOTHING (EP, 2026-11-23): every headless check by any session starts the game on this PC with the default data folder, which is Orb's own. A headless start writes no marker, copies nothing and
## deletes nothing (`active()`). The one opt-in is an Engine meta (`OPT_IN`) that only a scratch probe sets: Tools' forced-crash check (tools/crash/crash-check.mjs) puts it in the autoload it adds to its scratch
## export. No production code sets it (hud_check scans ui/ and render/ for it), a player cannot reach it (no command-line word, no setting, no file reads it), and it is not in the shipped game.
const OPT_IN: String = "report_logs_headless"
const DATA: String = "res://ui/data/report_clean.json"
const LOGS: String = "user://logs"
const REPORTS: String = "user://reports"   # the match recorder's folder (MatchRecorder.DIR; hud_check holds the two equal)

static var _cfg: Dictionary = {}
static var _rules: Array = []
static var _allow: Array = []


static func _load() -> void:
	if not _cfg.is_empty():
		return
	var j = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	_cfg = j if j is Dictionary else {}
	_rules.clear()
	_allow.clear()
	for p in _cfg.get("patterns", []):
		var rx := RegEx.new()
		if rx.compile(str(p["rx"])) == OK:
			_rules.append({"id": str(p["id"]), "rx": rx, "mark": str(p["mark"])})
	for a in _cfg.get("allow_lines", []):
		var ar := RegEx.new()
		if ar.compile(str(a)) == OK:
			_allow.append(ar)


## The data (for the checks).
static func config() -> Dictionary:
	_load()
	return _cfg


## Whether the game's start, stop and report copy do anything here: not in a headless run (a tool's, never a player's) unless a scratch probe set the opt-in meta.
static func active() -> bool:
	if OS.has_feature("web"):
		return false
	return DisplayServer.get_name() != "headless" or Engine.has_meta(OPT_IN)


## The account name and the PC name of this machine, from the environment (empty when the platform names none).
static func machine_names() -> Dictionary:
	var user: String = OS.get_environment("USERNAME")
	if user == "":
		user = OS.get_environment("USER")
	var pc: String = OS.get_environment("COMPUTERNAME")
	if pc == "":
		pc = OS.get_environment("HOSTNAME")
	if pc == "":
		pc = OS.get_environment("HOST")
	return {"user": user, "pc": pc}


static func _escape(s: String) -> String:
	var out := ""
	var bs: String = char(92)
	for c in s:
		if ".*+?^${}()|[]/-".contains(c) or c == bs:
			out += bs
		out += c
	return out


## A name as a whole word in any case (letters and digits either side keep it a part of a longer word): its expression, or null for a name of fewer than 3 letters.
static func _name_rx(name: String) -> RegEx:
	if name.length() < 3:
		return null
	var rx := RegEx.new()
	if rx.compile("(?i)(?<![A-Za-z0-9])" + _escape(name) + "(?![A-Za-z0-9])") != OK:
		return null
	return rx


## A text with every folder path, address and name of the patterns taken out, line by line. A line the engine's own banner uses (data: allow_lines) is left as it is, as the scan leaves it. `names` is
## {user, pc} (machine_names() when empty).
static func clean(text: String, names: Dictionary = {}) -> String:
	_load()
	var nm: Dictionary = names if not names.is_empty() else machine_names()
	var user_rx: RegEx = _name_rx(str(nm.get("user", "")))
	var pc_rx: RegEx = _name_rx(str(nm.get("pc", "")))
	var user_mark: String = str(_cfg.get("names", {}).get("user", "<user>"))
	var pc_mark: String = str(_cfg.get("names", {}).get("pc", "<removed>"))
	var out := PackedStringArray()
	for line in text.split("\n"):
		var l: String = line
		var allowed := false
		for a in _allow:
			if (a as RegEx).search(l) != null:
				allowed = true
				break
		if not allowed:
			for r in _rules:
				l = (r["rx"] as RegEx).sub(l, str(r["mark"]), true)
			if user_rx != null:
				l = user_rx.sub(l, user_mark, true)
			if pc_rx != null:
				l = pc_rx.sub(l, pc_mark, true)
		out.append(l)
	return "\n".join(out)


## The last `keep` bytes of a file as text, whole lines only (a cut that lands inside a line drops that partial line), or "" when the file cannot be read.
static func tail(path: String, keep: int) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var n: int = f.get_length()
	var cut: bool = n > keep
	if cut:
		f.seek(n - keep)
	var bytes: PackedByteArray = f.get_buffer(mini(n, keep))
	f.close()
	var s: String = bytes.get_string_from_utf8()
	if cut:
		var nl: int = s.find("\n")
		s = s.substr(nl + 1) if nl >= 0 else ""
	return s


## The newest dated log in a folder (the engine names them godot<date>.log; the current one is godot.log), or "".
static func newest_dated(logs_dir: String) -> String:
	var best := ""
	if not DirAccess.dir_exists_absolute(logs_dir):
		return best
	for n in DirAccess.get_files_at(logs_dir):
		if n.begins_with("godot") and n.ends_with(".log") and n != "godot.log" and n > best:
			best = n
	return best


## Writes the two cleaned, cut copies into `dir` (made if it is not there). Returns the names written (empty when there is no log: a web build, a first run in a folder with logging off).
static func copy_into(dir: String = REPORTS, logs_dir: String = LOGS, names: Dictionary = {}) -> Array:
	_load()
	var written: Array = []
	var keep: int = int(_cfg.get("tail_bytes", 204800))
	var header: String = str(_cfg.get("header", ""))
	var jobs := [[logs_dir.path_join("godot.log"), str(_cfg.get("this_run", "log-this-run.log"))]]
	var dated: String = newest_dated(logs_dir)
	if dated != "":
		jobs.append([logs_dir.path_join(dated), str(_cfg.get("last_run", "log-last-run.log"))])
	for j in jobs:
		if not FileAccess.file_exists(str(j[0])):
			continue
		var raw: String = tail(str(j[0]), keep)
		if raw == "":
			continue
		if DirAccess.make_dir_recursive_absolute(dir) != OK:
			return written
		var f := FileAccess.open(dir.path_join(str(j[1])), FileAccess.WRITE)
		if f == null:
			continue
		f.store_string(header + "\n" + clean(raw, names))
		f.close()
		written.append(str(j[1]))
	return written


## A report was saved (the host calls this after the match file is written): the logs go beside it. Nothing in a headless run (see `active`).
static func report_saved(dir: String = REPORTS) -> Array:
	if not active():
		return []
	return copy_into(dir)


## The marker of one run: `run-marker-<process id>.txt` in `marker_dir`. One file per running game, so two copies of the game on one PC (a local network test) never read each other as a dead run.
static func marker_path(pid: int, marker_dir: String = "user://") -> String:
	_load()
	return marker_dir.path_join("%s-%d.txt" % [str(_cfg.get("marker", "run-marker")), pid])


## Whether a process is still running. Asked only when a marker from another run is found (rare), never in the game's loop. Windows asks tasklist; Linux looks for /proc/<id>, and any other system (and a Linux
## without /proc) asks `kill -0`. A probe that cannot run says "not running": the worst that does is copy the logs once for a run that was in fact alive.
static func pid_alive(pid: int) -> bool:
	if pid <= 0:
		return false
	if pid == OS.get_process_id():
		return true
	if OS.get_name() == "Windows":
		var out: Array = []
		var code: int = OS.execute("tasklist", ["/FI", "PID eq %d" % pid, "/NH", "/FO", "CSV"], out, false, false)
		return code == 0 and not out.is_empty() and str(out[0]).contains("\"%d\"" % pid)
	if DirAccess.dir_exists_absolute("/proc/%d" % pid):
		return true
	if DirAccess.dir_exists_absolute("/proc/self"):
		return false   # /proc is there and has no such process
	return OS.execute("kill", ["-0", str(pid)], [], false, false) == 0


## The game starts: says whether a run before it did NOT close properly, then writes the marker for this run. A marker of a process that is still running is another copy of the game and is left alone; a marker of one
## that is not (or of this very process id, a dead run whose id came round again) is a dead run: it is deleted, and the report folder gets the logs at once, so the dead run's log is in it before anyone has to ask.
## Web builds and headless runs do nothing.
static func start(dir: String = REPORTS, marker_dir: String = "user://", logs_dir: String = LOGS) -> bool:
	if not active():
		return false
	_load()
	var prefix: String = str(_cfg.get("marker", "run-marker")) + "-"
	var me: int = OS.get_process_id()
	var died: bool = false
	if DirAccess.dir_exists_absolute(marker_dir):
		for n in DirAccess.get_files_at(marker_dir):
			if not (n.begins_with(prefix) and n.ends_with(".txt")):
				continue
			var id_text: String = n.substr(prefix.length(), n.length() - prefix.length() - 4)
			if not id_text.is_valid_int():
				continue
			var pid: int = int(id_text)
			if pid != me and pid_alive(pid):
				continue
			died = true
			DirAccess.remove_absolute(ProjectSettings.globalize_path(marker_dir.path_join(n)))
	var f := FileAccess.open(marker_path(me, marker_dir), FileAccess.WRITE)
	if f != null:
		f.store_string("%d\nThis file is here while the game runs (the number is its process id) and is deleted when it closes. If it is here at a later start and that process is gone, the run did not close properly.\n" % me)
		f.close()
	if died:
		copy_into(dir, logs_dir)
	return died


## The game closes cleanly: its own marker goes (never another run's). Nothing in a headless run: a tool that frees the game's scene at its end must not delete the marker of a game being played.
static func stop(marker_dir: String = "user://") -> void:
	if not active():
		return
	var mk: String = marker_path(OS.get_process_id(), marker_dir)
	if FileAccess.file_exists(mk):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(mk))
