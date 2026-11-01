extends SceneTree
## Where a stick press goes in a real fight: a masher flicking every `gap` ticks against the AI, one row per way a press ends.
##   godot --headless --path . --script res://sim/director/tools/stick_soak.gd -- [gap] [seeds] [ticks]

var rows: Dictionary = {}
var total: int = 0


func _init() -> void:
	var u: PackedStringArray = OS.get_cmdline_user_args()
	var gap: int = int(u[0]) if u.size() > 0 else 30
	var seeds: int = int(u[1]) if u.size() > 1 else 6
	var ticks: int = int(u[2]) if u.size() > 2 else 3600
	DirStick.setForce(1)
	for sd in range(1, seeds + 1):
		_one(sd, gap, ticks)
	DirStick.setForce(-1)
	var keys: Array = rows.keys()
	keys.sort_custom(func(a, b): return int(rows[a]) > int(rows[b]))
	print("presses %d" % total)
	var sum: Dictionary = {}
	for k in keys:
		var e: String = String(k).get_slice(" -> ", 1)
		sum[e] = int(sum.get(e, 0)) + int(rows[k])
	for e in sum:
		print("TOTAL %5d  %3.0f%%  %s" % [sum[e], 100.0 * float(sum[e]) / float(maxi(1, total)), e])
	for k in keys:
		print("%5d  %3.0f%%  %s" % [rows[k], 100.0 * float(rows[k]) / float(maxi(1, total)), k])
	quit(0)


func _word(start: bool, release: bool, held: bool, dir: int) -> SimIntent:
	var i := SimIntent.new()
	i.rsStart = start
	i.rsRelease = release
	i.rsHeld = held
	i.rsDir = dir
	i.rsLevel = 0
	return i


func _state(S: SimState, A, D) -> String:
	var ex = S.dirS.ex
	if S.dirS.stop > 0.0:
		return "in a hit-stop"
	if A.stunTicks > 0:
		return "he's stunned"
	if A.state == "launched" or A.state == "down" or A.state == "dropped":
		return "he's " + String(A.state)
	if ex != null:
		if not DirBrawl.isBrawl(ex):
			return "a planned exchange, %s, %s" % ["the rival's" if ex.A == D else "his", String(ex.tpl).substr(0, 18)]
		if ex.branch != "" or DirBrawl._setPiece(ex):
			return "a set piece"
		if not DirBrawl._free(S, A):
			return "brawl, his line busy"
		return "brawl, his line free"
	if DirBands.who(S) >= 0:
		return "an approach running"
	if D.state == "launched" or D.state == "down" or D.state == "dropped":
		return "no exchange, rival " + String(D.state) + (" (far)" if DirBands.band(A, D) == DirBands.FAR else "")
	return "no exchange, band %d" % DirBands.band(A, D)


func _one(sd: int, gap: int, ticks: int) -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, sd, {"p1": false, "p2": true}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false, "startTier": 2})
	var A = S.fighters[0]
	var D = S.fighters[1]
	A.ki = 100.0
	A.act.v2 = true
	var dirs: Array = [SimStrikeRead.UP, SimStrikeRead.RIGHT, SimStrikeRead.DOWN, SimStrikeRead.LEFT]
	var n: int = 0
	var open: Array = []   # [the state as he pressed, pressed at]
	var wait: bool = false   # a press in a hit-stop waits for the live tick, as the hub's does
	for t in range(ticks):
		A.ki = maxf(A.ki, 60.0)
		var w: SimIntent = null
		var ph: int = t % gap
		var d: int = int(dirs[(t / gap) % 4])
		if ph == 0 and S.dirS.stop > 0.0:
			wait = true
		if (ph == 0 or wait) and S.dirS.stop <= 0.0:
			wait = false
			w = _word(true, false, true, d)
			total += 1
			var st: String = _state(S, A, D)
			if not open.is_empty():
				_row(open[0] + " -> replaced by the next press")
			open = [st, t]
		elif ph < 4:
			w = _word(false, false, true, d)
		elif ph == 4:
			w = _word(false, true, false, d)
		else:
			w = SimIntent.new()
		var waiting: bool = DirStick._g(A, DirStick.ST_PEND) != 0
		SimCore.step(S, [w, SimIntent.new()])
		var refused: bool = false
		var started: bool = false
		for e in S.out.fx:
			if e.type == "cue" and e.kind == "stick_refused" and e.actor == 0.0:
				refused = true
			if e.type == "cue" and e.kind == "stick_start" and e.actor == 0.0:
				started = true
		S.out.fx.clear()
		S.out.feed.clear()
		if not open.is_empty():
			if refused:
				_row(open[0] + " -> refused")
				open = []
			elif started:
				_row(open[0] + (" -> thrown at once" if t - int(open[1]) <= 12 else " -> thrown late"))
				open = []
			elif t - int(open[1]) > 4 and DirStick._g(A, DirStick.ST_PEND) == 0 and DirStick._g(A, DirStick.ST_BUF) == 0:
				_row(open[0] + " -> VANISHED")
				open = []
		if S.game.ko != null:
			break
	SimCore.dispose(S)


func _row(k: String) -> void:
	rows[k] = int(rows.get(k, 0)) + 1
