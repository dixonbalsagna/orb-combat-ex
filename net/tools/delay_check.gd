extends SceneTree
## Tests for adaptive input delay (net/delay.gd, docs/net/rollback.md section 9). NetDelay.choose is a pure function, so
## these are table cases and properties over a grid of links and devices, with no sim. Exit 0 only if every case passes.
## --negative-control runs the same properties against two broken choosers (one ignores the device, one reads only the
## first sample) and passes only if the tests catch both.
##   godot --headless --path . --script res://net/tools/delay_check.gd -- [--negative-control]

var failures: int = 0
var chooser: Callable = NetDelay.choose
var quiet: bool = false


func _init() -> void:
	if OS.get_cmdline_user_args().has("--negative-control"):
		var caught: int = 0
		var broken: Dictionary = {
			"ignores the device": func(r: Array, dev: Dictionary, o: Dictionary = {}) -> Dictionary: return NetDelay.choose(r, NetDelay.device(1.0), o),
			"reads one sample": func(r: Array, dev: Dictionary, o: Dictionary = {}) -> Dictionary: return NetDelay.choose(r.slice(0, 1), dev, o),
		}
		quiet = true
		for name in broken:
			chooser = broken[name]
			failures = 0
			_all()
			print("  %s  %s: %d failing case(s)" % ["caught" if failures > 0 else "MISSED", name, failures])
			if failures > 0:
				caught += 1
		print("%s  negative control: %d of %d broken choosers caught" % ["PASS" if caught == broken.size() else "FAIL", caught, broken.size()])
		quit(0 if caught == broken.size() else 1)
		return
	print("Orb Combat EX adaptive input delay check   Godot %s" % Engine.get_version_info().string)
	_all()
	_table()
	print("%s  %d failure(s)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)


func _expect(cond: bool, what: String) -> void:
	if not cond:
		failures += 1
		if not quiet:
			print("  FAIL  " + what)


## A link's samples: a round trip of `ping` ms with `jitter` ms either way, n samples, from a fixed sequence.
func _link(ping: float, jitter: float, n: int = 40, seed: int = 1) -> Array:
	var r := SimRng.new(seed)
	var out: Array = []
	for i in range(n):
		out.append(maxf(0.0, ping + (r.next() * 2.0 - 1.0) * jitter))
	return out


func _d(rtt: Array, slow: float, o: Dictionary = {}) -> Dictionary:
	return chooser.call(rtt, NetDelay.device(slow), o)


func _all() -> void:
	# the floor and the ceiling
	_expect(int(_d(_link(0.0, 0.0), 1.0).delay) == 2, "a LAN on the reference device takes the minimum delay, 2")
	_expect(int(_d(_link(0.0, 0.0), 4.0).delay) == 2, "a LAN on a slow device takes the minimum too (nothing to roll back)")
	var huge := _d(_link(900.0, 50.0), 4.0)
	_expect(int(huge.delay) == 8 and not huge.fits, "a 900 ms link on a slow device is capped at 8 ticks and does not fit")
	_expect(int(_d(_link(900.0, 50.0), 1.0).delay) <= 8, "the delay never exceeds maxDelay")
	# a delay that removes rollback is enough: never more than the one-way time in ticks
	for ping in [40.0, 80.0, 120.0, 200.0]:
		var r := _d(_link(ping, 0.0), 1000.0)
		_expect(int(r.delay) == maxi(2, int(ceil(ping * 0.5 / NetDelay.FRAME_MS))) and int(r.depth) == 0, "at %.0f ms on a hopeless device the delay is the one that removes rollback" % ping)
	# monotone: a longer link or a slower device never lowers the delay
	for slow in [0.5, 1.0, 2.0, 4.0, 8.0]:
		var last: int = 0
		for ping in [0.0, 20.0, 40.0, 60.0, 80.0, 100.0, 120.0, 160.0, 200.0, 250.0, 300.0, 400.0]:
			var d: int = int(_d(_link(ping, ping * 0.15), slow).delay)
			_expect(d >= last, "delay falls from %d to %d as the ping rises to %.0f ms (device x%.1f)" % [last, d, ping, slow])
			last = d
	for ping in [40.0, 80.0, 120.0, 200.0, 300.0]:
		var last: int = 0
		for slow in [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0]:
			var d: int = int(_d(_link(ping, ping * 0.15), slow).delay)
			_expect(d >= last, "delay falls from %d to %d as the device slows to x%.1f (%.0f ms)" % [last, d, slow, ping])
			last = d
	# the device matters: at 200 ms a phone takes more delay than the reference
	_expect(int(_d(_link(200.0, 30.0), 4.0).delay) > int(_d(_link(200.0, 30.0), 1.0).delay), "at 200 ms a x4 device takes more delay than the reference")
	# whenever it fits, the rollback frame it plans for is within the budget, and one tick less would not be
	for slow in [1.0, 2.0, 4.0]:
		for ping in [60.0, 120.0, 200.0, 300.0]:
			var r := _d(_link(ping, 20.0), slow)
			if r.fits:
				_expect(float(r.frameMs) <= NetDelay.FRAME_MS * 0.75 + 1e-9, "the planned frame fits the budget (%.0f ms, x%.1f)" % [ping, slow])
				if int(r.delay) > 2:
					var less := _d(_link(ping, 20.0), slow, {"maxDelay": int(r.delay) - 1})
					_expect(not less.fits or int(less.delay) == int(r.delay) - 1 and float(less.frameMs) > NetDelay.FRAME_MS * 0.75, "one tick less would not fit (%.0f ms, x%.1f)" % [ping, slow])
	# robust to outliers and junk: one spike in forty samples does not move it; NaN, infinity, negatives and text are ignored
	var clean := _link(120.0, 15.0)
	var spiked := clean.duplicate()
	spiked[7] = 2500.0
	_expect(absi(int(_d(spiked, 1.0).delay) - int(_d(clean, 1.0).delay)) <= 1, "one 2.5 s spike in forty samples moves the delay by a tick at most")
	_expect(int(_d([2500.0], 1.0).delay) == 8, "a 2.5 s link alone would take the maximum")
	var junk := clean.duplicate()
	junk.append_array([NAN, INF, -5.0, "x", null])
	_expect(int(_d(junk, 1.0).delay) == int(_d(clean, 1.0).delay), "junk samples are ignored")
	_expect(int(_d([], 1.0).delay) == 2 and _d([], 1.0).reason == "no samples", "no samples gives the default delay")
	_expect(int(_d([NAN, -1.0], 4.0).delay) == 2, "only junk samples gives the default delay")
	# order does not matter, and it is a pure function: the same input twice gives the same answer
	var rev := clean.duplicate()
	rev.reverse()
	_expect(_d(rev, 2.0) == _d(clean, 2.0), "the samples' order does not matter")
	_expect(_d(clean, 2.0) == _d(clean, 2.0), "the same input gives the same answer")
	# options: a larger budget share never raises the delay, minDelay and maxDelay hold
	_expect(int(_d(clean, 2.0, {"share": 0.9}).delay) <= int(_d(clean, 2.0, {"share": 0.4}).delay), "a larger budget never raises the delay")
	_expect(int(_d(_link(0.0, 0.0), 1.0, {"minDelay": 1}).delay) == 1, "minDelay 1 is honoured on a LAN")
	_expect(int(_d(_link(400.0, 40.0), 8.0, {"maxDelay": 5}).delay) == 5, "maxDelay 5 is honoured")
	# a bad device speed does not break it
	_expect(int(_d(clean, NAN).delay) == int(_d(clean, 1.0).delay), "a NaN slowdown counts as the reference device")


## The delays it picks for the network profiles the loopback tests (printed for the doc), checked against the bench:
## at 80 ms on the reference device the default 2 stays.
func _table() -> void:
	print("  profile   ping  jitter   ref x1   x2   x4   (delay in ticks; * = does not fit)")
	for pname in NetLoopback.PROFILES:
		var p: Dictionary = NetLoopback.PROFILES[pname]
		var row: String = "  %-7s %5.0f  %5.0f   " % [pname, p.ping, p.jitter * 2.0]
		for slow in [1.0, 2.0, 4.0]:
			var r := _d(_link(float(p.ping), float(p.jitter) * 2.0), slow)
			row += "%5s" % ("%d%s" % [r.delay, "" if r.fits else "*"])
		print(row)
	_expect(int(_d(_link(80.0, 24.0), 1.0).delay) == 2, "p80j on the reference device keeps the default delay 2")
	_expect(int(_d(_link(120.0, 40.0), 1.0).delay) == 2, "p120 on the reference device keeps the default delay 2")
	_expect(int(_d(_link(120.0, 40.0), 4.0).delay) >= int(ceil(60.0 / NetDelay.FRAME_MS)), "p120 on a x4 device takes at least the one-way time")
