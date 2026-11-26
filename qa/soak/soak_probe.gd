extends Node
## The soak's probe (qa/soak/soak.mjs; EP, path job 14). Scratch only: it is NEVER in the game or a package that leaves this PC. The harness copies it beside the unpacked package and names it in an
## override.cfg there, so the shipped program and its pck are exactly the ones a player gets; only this autoload is added, from outside.
## What it does: lets the game's computer-against-computer match run, starts the next one (the next seed) a few seconds after a KO or a no contest, prints a SOAK line every few seconds, and after
## --soak-seconds asks the tree to quit (what "Close the game" does), so the clean close is part of the run. It reads the game; it never writes the sim.
## Options after "--": --soak-seconds=7200 --soak-sample=10 --soak-seed=1 --soak-cap=600 (a match longer than this many sim seconds is dropped and the next starts), --soak-same-seed (every later match
## the same seed), --soak-census=<names file> (the store census, soak_census.gd).


var secs: float = 7200.0
var every: float = 10.0
var seed_next: int = 1
var cap: float = 600.0

var _main: Node = null
var _t0: int = 0
var _last_sample: int = 0
var _last_usec: int = 0
var _frames: int = 0
var _worst_ms: float = 0.0
var _over_since: int = -1
var _starting: bool = false
var _match: int = 0
var _last_ticks: int = -1
var _tick_moved: int = 0
var _window_ticks: int = 0
var _done: bool = false
var same_seed: bool = false      # --soak-same-seed: every later match uses --soak-seed itself (a planet and openings already seen)
var census_file: String = ""     # --soak-census=<names file>: the store census (soak_census.gd beside this file) 20 s into each match and at its end
var census_every: float = 0.0    # --soak-census-every=<s>: also take it every so many seconds through a match (growth per minute of play)
var _census = null
var _census_at: int = -1         # when the census of the running match is due (msec), -1 for none


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The game's run marker and report logs do nothing in a headless run unless a probe opts in (ui/core/ui_report_logs.gd), the way Tools' forced-crash probe does.
	Engine.set_meta("report_logs_headless", true)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--soak-seconds="):
			secs = float(a.substr(15))
		elif a.begins_with("--soak-sample="):
			every = maxf(1.0, float(a.substr(14)))
		elif a.begins_with("--soak-seed="):
			seed_next = int(a.substr(12))
		elif a.begins_with("--soak-cap="):
			cap = float(a.substr(11))
		elif a == "--soak-same-seed":
			same_seed = true
		elif a.begins_with("--soak-census="):
			census_file = a.substr(14)
		elif a.begins_with("--soak-census-every="):
			census_every = float(a.substr(20))
	_t0 = Time.get_ticks_msec()
	_last_sample = _t0
	_tick_moved = _t0
	print("SOAK start seconds=%d sample=%d seed=%d cap=%d" % [int(secs), int(every), seed_next, int(cap)])


func _process(_delta: float) -> void:
	if _done:
		return
	var now: int = Time.get_ticks_msec()
	var us: int = Time.get_ticks_usec()
	if _last_usec > 0:
		_worst_ms = maxf(_worst_ms, (us - _last_usec) / 1000.0)
	_last_usec = us
	_frames += 1
	if _main == null:
		_find_main()
		if now - _t0 > 120000:
			_end("no-main", 3)
		return
	var host = _main.host
	if host == null or host.S == null:
		return
	var S = host.S
	# A release program checks no array bounds: an index into a match that is still being built kills it (0xC0000005) with no error line. Nothing below runs until both fighters exist.
	if S.fighters.size() < 2 or host.match_job != null or host.load_job != null:
		_tick_moved = now
		return
	if host.ticks != _last_ticks:
		if _last_ticks >= 0:
			_window_ticks += maxi(0, int(host.ticks) - _last_ticks)
		_last_ticks = host.ticks
		_tick_moved = now
	elif now - _tick_moved > 120000:
		_end("stall", 3)   # no sim tick for two minutes: the game is up but not playing
		return
	_drive(S, now)
	if now - _last_sample >= int(every * 1000.0):
		_sample(S, now)
	if now - _t0 >= int(secs * 1000.0):
		_sample(S, now)
		_end("time", 0)


func _find_main() -> void:
	var cs = get_tree().current_scene
	if cs != null and "host" in cs and cs.host != null and cs.host.S != null and cs.host.S.fighters.size() >= 2 and cs.host.match_job == null and cs.host.load_job == null:
		_main = cs
		var f = cs.host.S.fighters
		print("SOAK main found after %d ms; computer plays both: %s" % [Time.get_ticks_msec() - _t0, str(f[0].ai != null and f[1].ai != null)])
		_match = 1
		print("SOAK match 1 started seed=%d (the game's own boot match)" % int(cs.host.seed))
		if census_file != "":
			var here: String = get_script().resource_path.get_base_dir()
			_census = load(here.path_join("soak_census.gd")).new()
			print("SOAK census ready statics=%d" % _census.setup(FileAccess.get_file_as_string(census_file).split("\n", false)))
			_census_at = Time.get_ticks_msec() + 20000


func _take_census(when: String, now: int) -> void:
	if _census == null:
		return
	var t0: int = Time.get_ticks_msec()
	var data: Dictionary = _census.take(_main)
	print("SOAK census t=%.0f match=%d when=%s ms=%d data=%s" % [(now - _t0) / 1000.0, _match, when, Time.get_ticks_msec() - t0, JSON.stringify(data)])
	_tick_moved = Time.get_ticks_msec()
	_last_usec = 0   # the census's own long frame is not the game's worst frame


## Whether the match ended without a KO: UI's event hub reads the ending (ui/core/ui_event_hub.gd no_contest). The director's own getter is not called from here (see above).
func _no_contest() -> bool:
	var uh = _main.get("ui_hud")
	return uh != null and uh.get("hub") != null and bool(uh.hub.no_contest)


## A few seconds after the match ends (or at the cap), the next seed.
func _drive(S, now: int) -> void:
	var over: bool = S.game.ko != null or _no_contest()
	if _starting:
		if not over and float(S.T) < 5.0:
			_starting = false
			_census_at = now + 20000
			var f = S.fighters
			print("SOAK match %d started t=%.0f seed=%d objects=%d computer plays both: %s" % [_match, (now - _t0) / 1000.0, int(_main.host.seed), int(Performance.get_monitor(Performance.OBJECT_COUNT)), str(f[0].ai != null and f[1].ai != null)])
		return
	if _census_at >= 0 and now >= _census_at:
		_census_at = now + int(census_every * 1000.0) if census_every > 0.0 else -1
		_take_census("start" if float(S.T) < 30.0 else "mid", now)
	var capped: bool = float(S.T) >= cap
	if not over and not capped:
		_over_since = -1
		return
	if _over_since < 0:
		_over_since = now
		var how: String = "capped" if capped and not over else ("no-contest" if S.game.ko == null else "ko")
		var who: int = -1
		if S.game.ko != null:
			who = 1 if S.game.ko == S.fighters[0] else 0
		print("SOAK match %d ended how=%s winnerSlot=%d simSeconds=%.1f t=%.0f" % [_match, how, who, float(S.T), (now - _t0) / 1000.0])
		_take_census("end", now)
	if now - _over_since < 4000:
		return
	_over_since = -1
	_starting = true
	_match += 1
	if not same_seed:
		seed_next += 1
	_main.start_match(seed_next)


func _sample(S, now: int) -> void:
	var win: float = maxf(0.001, (now - _last_sample) / 1000.0)
	print("SOAK sample t=%.0f match=%d simT=%.1f fps=%.1f ticksPerSec=%.1f worstFrameMs=%.1f processMs=%.2f objects=%d nodes=%d resources=%d orphans=%d staticMiB=%.1f" % [
		(now - _t0) / 1000.0, _match, float(S.T), _frames / win, _window_ticks / win, _worst_ms,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		int(Performance.get_monitor(Performance.OBJECT_COUNT)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		OS.get_static_memory_usage() / 1048576.0])
	_last_sample = now
	_frames = 0
	_window_ticks = 0
	_worst_ms = 0.0


func _end(why: String, code: int) -> void:
	_done = true
	print("SOAK quit why=%s matches=%d wallSeconds=%.0f" % [why, _match, (Time.get_ticks_msec() - _t0) / 1000.0])
	get_tree().quit(code)
