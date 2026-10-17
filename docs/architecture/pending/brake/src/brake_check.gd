

## The air brake (buildings.md section 7.2; docs/architecture/brake-core.md). Off (the committed switch), a match has no
## brake state and a replay carries no brake data. On: the start window runs straight-line from 8 to 20 ticks by the
## send's power, 25% sooner a mark; a sent fighter who holds the brake starts on the window's tick and not before, slows
## at the rate and pays ki, and under a third of the send's speed has control back in the air (World's journey_end, kind
## brake); with no ki the brake is half as fast; letting go ends it; a set piece's send never brakes; the events say so;
## a brake match replays.
func _brake() -> String:
	if not SimBrake.errors().is_empty():
		return "the brake data: " + "; ".join(SimBrake.errors())
	if SimBrake.enabled():
		return "the brake is on in the committed data"
	var d0: String = SimReplay.dataHash()
	if SimReplay.dataHash({"brake": false}) != d0 or SimReplay.dataHash({"brake": true}) == d0:
		return "the brake data is not in a replay's data hash exactly when it is on"
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 5, {"p1": false, "p2": false})
	if S0.brakeOn or S0.fighters[1].brk != null:
		return "a match without the brake has brake state"
	SimCore.dispose(S0)
	var fs: float = SimBrake.fullSpeed
	var w: Array = [SimBrake.window(0.3 * fs, 0), SimBrake.window(0.55 * fs, 0), SimBrake.window(0.775 * fs, 0), SimBrake.window(fs, 0), SimBrake.window(2.0 * fs, 0), SimBrake.window(fs, 1)]
	if w != [8, 8, 14, 20, 20, 15]:
		return "the start window by power: %s (want [8, 8, 14, 20, 20, 15])" % str(w)
	var runs: Dictionary = {}
	for mode in ["full", "noKi", "release", "special"]:
		var M := SimCore.createSim()
		SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"brake": true})
		var A = M.fighters[0]
		var D = M.fighters[1]
		D.y = WorldTerrain.groundY(M, D.x) + 400.0
		if mode == "noKi":
			D.ki = 0.0
		M.out.fx.clear()
		DirLaunch.doLaunch(M, A, D, {"ux": 0.6, "uy": 0.8}, 2400.0, mode == "special")
		var v0: float = SimBrake.speed(D)
		var held := SimIntent.new()
		held.stanceMask = SimBrake.BIT
		var r := {"v0": v0, "start": -1, "end": -1, "why": "", "free": -1, "je": "", "ki0": D.ki, "kiEnd": -1.0, "vEnd": -1.0, "slowing": true, "at": -1}
		var last: float = v0
		for t in range(1, 120):
			var it = held
			if mode == "release" and r.start >= 0 and t >= r.start + 3:
				it = null
			SimCore.step(M, [null, it])
			if t == 1:
				r.at = D.brk.at
			for e in M.out.fx:
				if e.type == "air_brake" and e.text == "start":
					r.start = t
				elif e.type == "air_brake" and e.text == "end" and r.end < 0:
					r.end = t
					r.why = e.kind
					r.vEnd = e.amount
				elif e.type == "journey_end":
					r.je = e.kind
			if D.brk.on:
				var v: float = SimBrake.speed(D)
				r.slowing = r.slowing and v < last
				last = v
			if r.end >= 0 and r.kiEnd < 0.0:
				r.kiEnd = D.ki
			if D.state == "free" and r.free < 0:
				r.free = t
			M.out.fx.clear()
			M.out.feed.clear()
			if r.end >= 0 and t > r.end + 2:
				break
		runs[mode] = r
		SimCore.dispose(M)
	var f: Dictionary = runs.full
	if f.start != f.at or f.at != SimBrake.window(f.v0, 0) or f.at < 8 or f.at > 20:
		return "the brake started at tick %d after the send, its window %d (by the send's speed %.0f)" % [f.start, f.at, f.v0]
	if f.why != "speed" or f.free != f.end or f.je != "brake" or not f.slowing or f.vEnd >= f.v0 / 3.0:
		return "the full brake: it ended '%s' at tick %d (free at %d, journey_end '%s', slowing %s, speed %.0f of %.0f)" % [f.why, f.end, f.free, f.je, str(f.slowing), f.vEnd, f.v0]
	var ticks: int = f.end - f.start
	if float(ticks) * SimConst.DT > SimBrake.maxBrakeS + 0.05:
		return "the full brake took %d ticks, past %.1f s" % [ticks, SimBrake.maxBrakeS]
	if absf((f.ki0 - f.kiEnd) - SimBrake.kiPerSec * SimConst.DT * float(ticks)) > SimBrake.kiPerSec * SimConst.DT * 1.01:
		return "the brake's ki: %.2f paid over %d ticks (want %.2f a second)" % [f.ki0 - f.kiEnd, ticks, SimBrake.kiPerSec]
	var n: Dictionary = runs.noKi
	var nt: int = n.end - n.start
	if n.why != "speed" or nt < 2 * ticks - 2 or nt > 2 * ticks + 2:
		return "with no ki the brake took %d ticks, the full one %d (want about twice)" % [nt, ticks]
	var rl: Dictionary = runs.release
	if rl.why != "released" or rl.free >= 0 and rl.free <= rl.end:
		return "letting go: it ended '%s' (free at %d, end at %d)" % [rl.why, rl.free, rl.end]
	if runs.special.start >= 0:
		return "a set piece's send was braked"
	# a brake match replays
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 13, {}, {"brake": true})
	for t in range(2400):
		rec.step([null, null])
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	if rp.data != SimReplay.dataHash({"brake": true}) or not SimReplay.play(JSON.parse_string(JSON.stringify(rp))).ok:
		return "a brake match does not carry the brake data, or does not play back"
	return ""
