extends SceneTree
## The host's read-ahead of a calm turn's rings (docs/ui/read-ahead.md), headless: SimHost.advance, after a frame's ticks, spends the frame's leftover time (at most 2 ms) on WorldEpoch.readAhead while a calm turn is
## warming. It must change no state: a turn played to its swap through advance() with the read-ahead on is the same match, the same swap tick and the same gameplay hash all the way, as with it off. And it reads only
## when a turn is warming, on a frame that is not late, and not while paused. Run from the repo root (import once first):
##   godot --headless --path . --script res://ui/tools/read_ahead_check.gd
## Exits 0 when every check passes.

var fails: int = 0
var checks: int = 0


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL  ", what)


func _initialize() -> void:
	_run.call_deferred()


## A host on a gen `gen` planet with a turning arena, 30 ticks in, a turn decided at k (0 = none decided).
func _host(gen: int, k: int, ahead: bool) -> SimHost:
	WorldClimate.useGen(gen)
	var h := SimHost.new()
	h.read_ahead = ahead
	h.new_match(1, {"p1": true, "p2": true}, {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}, "planetGen": gen, "intro": false})
	for t in range(30):
		h.advance(SimConst.DT, 1280.0, 720.0)
	if k > 0:
		var S: SimState = h.S
		S.T = 100.0
		var px: float = 0.5 * (S.fighters[0].x + S.fighters[1].x)
		var c: Array = WorldEpoch.ask(S, "read-ahead-check", px, 1, 0)
		WorldEpoch.choose(S, c.size() - 1, k, 2.5)
	return h


## Plays the turn to its swap one tick a frame; returns "swap tick: gameplay hash at every 100 ticks".
func _play(h: SimHost, total: bool) -> String:
	WorldRingPick.cfg().turn["warmTotal"] = 1 if total else 0
	var g: int = 0
	var hs: String = ""
	while h.S.epoch.next != null and g < 3000:
		h.advance(SimConst.DT, 1280.0, 720.0)
		g += 1
		if g % 100 == 0:
			hs += " %d:%s" % [g, str(SimHash.stateHash(h.S).gameplay).substr(0, 10)]
	return "swapped after %d%s final %s" % [g, hs, str(SimHash.stateHash(h.S).gameplay).substr(0, 16)]


func _run() -> void:
	for gen in [1, 2]:
		for k in [32, 12]:
			for total in [false, true]:
				var off := _host(gen, k, false)
				var a: String = _play(off, total)
				var on := _host(gen, k, true)
				var b: String = _play(on, total)
				var tag: String = "gen %d k %d total %s" % [gen, k, str(total)]
				_ok(a == b, "%s: the turn with read-ahead is the same turn (%s | %s)" % [tag, a.substr(0, 40), b.substr(0, 40)])
				_ok(off.read_ahead_cols == 0, "%s: off reads nothing" % tag)
				_ok(on.read_ahead_cols > 0, "%s: on reads ahead (%d columns)" % [tag, on.read_ahead_cols])

	# Frame pacing changes how much is read ahead each frame, never the match: a turn played at a jittering frame time (2 to 50 ms, a late frame reads nothing) on and off.
	for gen in [1, 2]:
		var ends: Array = []
		for ahead in [false, true]:
			var jh := _host(gen, 12, ahead)
			WorldRingPick.cfg().turn["warmTotal"] = 1
			var r := SimRng.new(SimRng.deriveSeed(77, "test.jitter"))
			var frames: int = 0
			while jh.S.epoch.next != null and frames < 6000:
				jh.advance(r.range_(0.002, 0.05), 1280.0, 720.0)
				frames += 1
			ends.append("%d ticks %s" % [jh.ticks, str(SimHash.stateHash(jh.S).gameplay).substr(0, 16)])
		_ok(ends[0] == ends[1], "gen %d: at a jittering frame time the turn is the same with read-ahead on (%s | %s)" % [gen, ends[0], ends[1]])

	# Only while a turn is warming, on a frame that is not late, and not while paused.
	var h := _host(2, 0, true)
	for t in range(20):
		h.advance(SimConst.DT, 1280.0, 720.0)
	_ok(h.read_ahead_cols == 0, "no turn decided: nothing is read ahead")
	var S: SimState = h.S
	S.T = 100.0
	var c: Array = WorldEpoch.ask(S, "read-ahead-check", 0.5 * (S.fighters[0].x + S.fighters[1].x), 1, 0)
	WorldEpoch.choose(S, c.size() - 1, 12, 2.5)
	h.advance(0.05, 1280.0, 720.0)   # a late frame (three ticks)
	_ok(h.read_ahead_cols == 0, "a late frame reads nothing")
	h.paused = true
	h.advance(SimConst.DT, 1280.0, 720.0)
	_ok(h.read_ahead_cols == 0, "a paused frame reads nothing")
	h.paused = false
	h.advance(SimConst.DT, 1280.0, 720.0)
	var first: int = h.read_ahead_cols
	_ok(first > 0 and first <= SimHost.READ_AHEAD_CAP_US / SimHost.READ_AHEAD_UNIT_US, "a frame reads within its cap (%d columns of units for %d us)" % [first, SimHost.READ_AHEAD_CAP_US])
	_ok(h._read_ahead(SimConst.DT, SimHost.READ_AHEAD_FRAME_US) == 0, "a frame whose ticks used all of it reads nothing")
	print("read_ahead_check: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)
